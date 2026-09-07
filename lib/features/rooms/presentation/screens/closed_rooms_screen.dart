import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/router/app_router.dart';
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
  // Ids of rooms that are keep-game-closed but still ALIVE (closed_at set,
  // deleted_at NULL) — the ONLY ones eligible for re-enter/reopen. Everything
  // else in the list is a terminal, permanently-deleted room and stays
  // strictly read-only. get_my_closed_rooms returns both (coalescing their
  // timestamps), so this owner-scoped id set is what tells them apart.
  Set<String> _reopenable = {};
  bool _loading = true;
  bool _busy = false;
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
      // Non-fatal: if this probe fails, every row simply falls back to the
      // read-only terminal path (never wrongly offering reopen on a dead room).
      Set<String> reopenable = {};
      try {
        reopenable = await sl.roomRepository.getReopenableClosedRoomIds();
      } catch (_) {}
      if (mounted)
        setState(() {
          _rooms = rooms;
          _reopenable = reopenable;
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

  /// Re-enter a keep-game-closed-but-alive room: opens the SAME existing room's
  /// lobby (never creates a new room/session, never resets game state). The
  /// live game and its game_sessions.player_ids continue untouched; the reopen
  /// control lives in that lobby. Owner-only rooms reach here (owner-scoped id
  /// set), and RoomProvider never blocks the owner from their own room.
  void _reenter(String roomId) {
    AppRouter.router.push('/home/room/$roomId');
  }

  /// Reopen (clear closed_at) then drop the owner straight into the room. Uses
  /// the existing reopen_room_keep_game RPC via RoomRepository.reopenRoom —
  /// touches ONLY closed_at, so no new session, no game/state/score/turn reset.
  Future<void> _reopen(String roomId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await sl.roomRepository.reopenRoom(roomId);
      if (!mounted) return;
      AppRouter.router.push('/home/room/$roomId');
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e is Failure ? e.message : e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.roomsMyClosedRooms)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ErrorView(message: _error!, onRetry: _load)
            : _rooms.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      context.l10n.roomsNoClosedRooms,
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
                  final roomId = r['room_id'] as String;
                  final closedAt = DateTime.tryParse(
                    r['closed_at'] as String? ?? '',
                  );
                  // Keep-game-closed BUT still alive -> re-enter/reopen.
                  // Terminal/deleted -> strictly read-only history.
                  final isAlive = _reopenable.contains(roomId);
                  final agoText = closedAt != null
                      ? context.l10n.roomsClosedAgo(_formatAgo(context, closedAt))
                      : context.l10n.roomsClosed;

                  if (isAlive) {
                    return Card(
                      child: ListTile(
                        leading: Text(
                          r['cover_emoji'] as String? ?? '🎮',
                          style: const TextStyle(fontSize: 28),
                        ),
                        title: Text(
                          r['name'] as String? ?? context.l10n.roomsFallbackRoom,
                        ),
                        // The game is still live for its active players — this
                        // room can be re-entered and reopened, not just viewed.
                        subtitle: Text(agoText),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: _busy ? null : () => _reopen(roomId),
                              child: Text(context.l10n.lobbyReopenCta),
                            ),
                            const Icon(Icons.login_rounded),
                          ],
                        ),
                        // Tapping the row re-enters the existing room (its
                        // lobby also exposes the reopen control).
                        onTap: _busy ? null : () => _reenter(roomId),
                      ),
                    );
                  }

                  return Card(
                    child: ListTile(
                      leading: Text(
                        r['cover_emoji'] as String? ?? '🎮',
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(r['name'] as String? ?? context.l10n.roomsFallbackRoom),
                      subtitle: Text(agoText),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClosedRoomDetailScreen(
                            roomId: roomId,
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

  String _formatAgo(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    final l10n = context.l10n;
    if (diff.inHours < 1) return l10n.roomsAgoMinutes(diff.inMinutes);
    if (diff.inDays < 1) return l10n.roomsAgoHours(diff.inHours);
    return l10n.roomsAgoDays(diff.inDays);
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
      appBar: AppBar(title: Text(room?['name'] as String? ?? context.l10n.roomsClosedRoomFallback)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _buildContent(context),
    );
  }

  String _gameTypeLabel(dynamic raw) {
    final l10n = context.l10n;
    return switch (raw as String?) {
      'truth_or_dare' => l10n.gameNameTruthOrDare,
      'never_have_i_ever' => l10n.gameNameNeverHaveIEverFull,
      'meme_game' => l10n.gameNameMeme,
      // Never expose a raw DB game_type string to the user (item 9) — an
      // unrecognized value falls back to the same generic label as null.
      final String? _ => l10n.defaultGameName,
    };
  }

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
        p['user_id'] as String: p['display_name'] as String? ?? context.l10n.defaultPlayerName,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: context.l10n.roomsRoomInfo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.roomsGameLabel(_gameTypeLabel(room['game_type']))),
              Text(context.l10n.roomsMaxPlayersLabel('${room['max_players'] ?? '—'}')),
              Text(
                context.l10n.roomsDurationLabel(
                  _formatDuration(room['game_started_at'] as String?, room['game_ended_at'] as String?),
                ),
              ),
              Text(context.l10n.roomsPlayedLabel(_formatDateTime(room['created_at'] as String?))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: context.l10n.roomsParticipantsCount(participants.length),
          child: Column(
            children: participants.map((p) {
              final name = p['display_name'] as String? ?? context.l10n.defaultPlayerName;
              final role = p['role'] as String? ?? 'player';
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                ),
                title: Text(name),
                subtitle: Text(role == 'spectator' ? context.l10n.roleLabelSpectator : context.l10n.roleLabelPlayer),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: context.l10n.roomsResults,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sessions.isEmpty
                ? [Text(context.l10n.roomsNoGameData)]
                : sessions.map((s) {
                    final snapshot =
                        s['state_snapshot'] as Map<String, dynamic>?;
                    final rawScores =
                        snapshot?['scores'] as Map<String, dynamic>?;
                    final scores = <String, int>{
                      for (final e in (rawScores ?? {}).entries)
                        (namesByUserId[e.key] ?? context.l10n.defaultPlayerName): _scoreValue(
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
                            context.l10n.roomsDurationLabel(
                              _formatDuration(s['started_at'] as String?, s['ended_at'] as String?),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (winner != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                context.l10n.roomsWinnerLabel(winner),
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
          title: context.l10n.roomsPlayedPacksCount(playedPacks.length),
          child: playedPacks.isEmpty
              ? Text(context.l10n.none)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: playedPacks.map((p) {
                    final title = p['title'] as Map<String, dynamic>?;
                    final name =
                        title?['en'] as String? ??
                        (title?.values.firstOrNull as String?) ??
                        context.l10n.defaultPackName;
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
