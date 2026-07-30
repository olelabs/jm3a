import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/feedback/error_view.dart';

/// Premium-only, read-only archive of the caller's own rooms that closed
/// within the last 5 days — auto-disappears after that (server-enforced
/// query window in `get_my_closed_rooms`, nothing is ever deleted).
class ClosedRoomsScreen extends StatefulWidget {
  const ClosedRoomsScreen({super.key});

  @override
  State<ClosedRoomsScreen> createState() => _ClosedRoomsScreenState();
}

class _ClosedRoomsScreenState extends State<ClosedRoomsScreen> {
  List<Map<String, dynamic>> _rooms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rooms = await sl.roomRepository.getMyClosedRooms();
      if (mounted)
        setState(() {
          _rooms = rooms;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = '$e';
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Closed Rooms')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ErrorView(message: _error!, onRetry: _load)
            : _rooms.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No rooms closed in the last 5 days.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _rooms.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final r = _rooms[i];
                  final closedAt = DateTime.tryParse(
                    r['closed_at'] as String? ?? '',
                  );
                  return Card(
                    child: ListTile(
                      leading: Text(
                        r['cover_emoji'] as String? ?? '🎮',
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(r['name'] as String? ?? 'Room'),
                      subtitle: Text(
                        closedAt != null
                            ? 'Closed ${_formatAgo(closedAt)}'
                            : 'Closed',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClosedRoomDetailScreen(
                            roomId: r['room_id'] as String,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _formatAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// Strictly read-only — no controls that could reopen, restart, continue,
/// or edit anything. Just displays what happened.
class ClosedRoomDetailScreen extends StatefulWidget {
  const ClosedRoomDetailScreen({super.key, required this.roomId});
  final String roomId;

  @override
  State<ClosedRoomDetailScreen> createState() => _ClosedRoomDetailScreenState();
}

class _ClosedRoomDetailScreenState extends State<ClosedRoomDetailScreen> {
  Map<String, dynamic>? _details;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final details = await sl.roomRepository.getClosedRoomDetails(
        widget.roomId,
      );
      if (mounted)
        setState(() {
          _details = details;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = '$e';
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = _details?['room'] as Map<String, dynamic>?;
    return Scaffold(
      appBar: AppBar(title: Text(room?['name'] as String? ?? 'Closed Room')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _buildContent(context),
    );
  }

  static const _gameTypeLabels = {
    'truth_or_dare': 'Truth or Dare',
    'never_have_i_ever': 'Never Have I Ever',
    'meme_game': 'Meme Game',
  };

  String _gameTypeLabel(dynamic raw) =>
      _gameTypeLabels[raw as String?] ?? (raw as String? ?? 'Game');

  // Truth or Dare stores a structured per-player score object
  // (TodPlayerScore.toMap() — completed_truths/dares/skips/points) while
  // NHIE/Meme store a plain number — this history view is generic across
  // game types, so it needs to read whichever shape shows up.
  int _scoreValue(dynamic raw) {
    if (raw is Map) return (raw['points'] as num?)?.toInt() ?? 0;
    return (raw as num?)?.toInt() ?? 0;
  }

  String _formatDateTime(String? iso) {
    final dt = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '—';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $h:$min';
  }

  String _formatDuration(String? startIso, String? endIso) {
    final start = startIso == null ? null : DateTime.tryParse(startIso);
    final end = endIso == null ? null : DateTime.tryParse(endIso);
    if (start == null || end == null) return '—';
    final d = end.difference(start);
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    if (d.inHours < 1) return '${d.inMinutes}m';
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }

  Widget _buildContent(BuildContext context) {
    final theme = context.theme;
    final room = _details!['room'] as Map<String, dynamic>;
    final sessions = (_details!['sessions'] as List)
        .cast<Map<String, dynamic>>();
    final playedPacks = (_details!['played_packs'] as List)
        .cast<Map<String, dynamic>>();
    final participants = (_details!['participants'] as List)
        .cast<Map<String, dynamic>>();

    // userId -> display name, so raw score-map keys never leak to the UI.
    final namesByUserId = {
      for (final p in participants)
        p['user_id'] as String: p['display_name'] as String? ?? 'Player',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Room Info',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Game: ${_gameTypeLabel(room['game_type'])}'),
              Text('Max players: ${room['max_players'] ?? '—'}'),
              Text(
                'Duration: '
                '${_formatDuration(room['game_started_at'] as String?, room['game_ended_at'] as String?)}',
              ),
              Text('Played: ${_formatDateTime(room['created_at'] as String?)}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Participants (${participants.length})',
          child: Column(
            children: participants.map((p) {
              final name = p['display_name'] as String? ?? 'Player';
              final role = p['role'] as String? ?? 'player';
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                ),
                title: Text(name),
                subtitle: Text(role == 'spectator' ? 'Spectator' : 'Player'),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Results',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sessions.isEmpty
                ? const [Text('No game data available.')]
                : sessions.map((s) {
                    final snapshot =
                        s['state_snapshot'] as Map<String, dynamic>?;
                    final rawScores =
                        snapshot?['scores'] as Map<String, dynamic>?;
                    final scores = <String, int>{
                      for (final e in (rawScores ?? {}).entries)
                        (namesByUserId[e.key] ?? 'Player'): _scoreValue(
                          e.value,
                        ),
                    };
                    final sortedScores = scores.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                    final winner =
                        sortedScores.isNotEmpty && sortedScores.first.value > 0
                        ? sortedScores.first.key
                        : null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _gameTypeLabel(s['game_type']),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Duration: '
                            '${_formatDuration(s['started_at'] as String?, s['ended_at'] as String?)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (winner != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '🏆 Winner: $winner',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.amberOrangeLight,
                                ),
                              ),
                            ),
                          if (sortedScores.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                sortedScores
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join('  •  '),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Played Packs (${playedPacks.length})',
          child: playedPacks.isEmpty
              ? const Text('None')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: playedPacks.map((p) {
                    final title = p['title'] as Map<String, dynamic>?;
                    final name =
                        title?['en'] as String? ??
                        (title?.values.firstOrNull as String?) ??
                        'Pack';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $name'),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
