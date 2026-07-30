import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/extensions/context_ext.dart';

/// Moderator-facing panel of pending join requests for a room, with
/// accept/reject actions. Extracted from the lobby screen so it can also
/// be mounted on the three game screens — the lobby stays mounted
/// underneath a pushed game route, so a moderator actively playing never
/// saw new requests that arrived while a game was already in progress.
class JoinRequestsPanel extends StatefulWidget {
  const JoinRequestsPanel({
    super.key,
    required this.roomId,
    this.showAlways = false,
    this.inGame = false,
  });
  final String roomId;
  final bool showAlways;

  /// True when the room is currently in_game — swaps the copy to make
  /// clear the request is to join the CURRENT game, not just the lobby.
  final bool inGame;

  @override
  State<JoinRequestsPanel> createState() => _JoinRequestsPanelState();
}

class _JoinRequestsPanelState extends State<JoinRequestsPanel> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await sl.roomRepository.getPendingRequests(widget.roomId);
      if (mounted) {
        setState(() {
          _requests = rows;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolve(String requestId, String userId, bool approve) async {
    try {
      await sl.roomRepository.resolveJoinRequest(
        requestId: requestId,
        approve: approve,
        roomId: widget.roomId,
        targetUserId: userId,
      );
      sl.roomRepository
          .notifyJoinDecision(
            roomId: widget.roomId,
            targetUserId: userId,
            approved: approve,
          )
          .ignore();
      await _load();
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    if (_loading && _requests.isEmpty) return const LinearProgressIndicator();
    if (_requests.isEmpty && !widget.showAlways) return const SizedBox.shrink();
    if (_requests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 14,
              color: Colors.green,
            ),
            const SizedBox(width: 6),
            Text(
              'No pending join requests',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Join Requests (${_requests.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _load,
            ),
          ],
        ),
        ..._requests.map((req) {
          final profile = req['profiles'] as Map<String, dynamic>? ?? {};
          final name = profile['display_name'] as String? ?? 'Player';
          final msg = req['message'] as String?;
          final subtitle = widget.inGame
              ? '$name wants to join the current game.'
              : (msg != null && msg.isNotEmpty ? msg : null);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text(name[0].toUpperCase())),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: subtitle != null ? Text(subtitle) : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                    onPressed: () => _resolve(
                      req['id'] as String,
                      req['user_id'] as String,
                      true,
                    ),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                    onPressed: () => _resolve(
                      req['id'] as String,
                      req['user_id'] as String,
                      false,
                    ),
                    tooltip: 'Reject',
                  ),
                ],
              ),
            ),
          );
        }),
        const Divider(),
      ],
    );
  }
}
