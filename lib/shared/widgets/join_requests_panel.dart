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
    this.floatingCard = false,
  });
  final String roomId;
  final bool showAlways;

  /// True when the room is currently in_game — swaps the copy to make
  /// clear the request is to join the CURRENT game, not just the lobby.
  final bool inGame;

  /// The three game screens mount this as a floating overlay over live
  /// gameplay (not inline in a settings-style list like the lobby's own
  /// usage), so it needs its own elevated card chrome — but ONLY when
  /// there's actually a request to show. Previously the game screens
  /// applied that Material/padding chrome at the CALL SITE, unconditionally
  /// wrapping this panel — so even though the panel itself already
  /// collapsed to SizedBox.shrink() when empty, the wrapper's own
  /// SingleChildScrollView(padding: 8) still had a non-zero size around
  /// that empty child, rendering a persistent, contentless, elevated
  /// rounded strip near the top of every game screen for every admin/
  /// moderator (the only ones canAcceptJoins gates this to) for the
  /// entire session. Setting this true moves the SAME chrome inside this
  /// widget, where it can be skipped together with the content instead of
  /// only the content — true zero footprint when there's nothing pending.
  final bool floatingCard;

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
    // This is the periodic refresh keeping the panel fresh — there's no
    // realtime subscription on room_join_requests to drive it instead, so
    // polling stays. The bug was _load() unconditionally flipping
    // `_loading` back to true on every tick, including this background
    // one: with no pending requests, that repainted a LinearProgressIndicator
    // at the top of every game screen (this panel sits at top:8, right by
    // the AppBar) every 5 seconds for the room's whole owner/moderator
    // gameplay session, even though nothing was actually changing.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _load(showLoading: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
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
      // resolveJoinRequest -> decide_join_request RPC updates
      // room_join_requests.status server-side, which alone is enough to
      // fire trg_notify_room_join_accepted/trg_notify_room_join_rejected
      // (see supabase/migrations/20260801120300_room_notification_triggers.sql)
      // — no separate notify call needed here; one used to exist
      // (notifyJoinDecision) but it duplicated this trigger's notification
      // and used invalid enum values, so it was removed rather than fixed.
      await sl.roomRepository.resolveJoinRequest(
        requestId: requestId,
        approve: approve,
        roomId: widget.roomId,
        targetUserId: userId,
      );
      await _load();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(context.l10n.sharedJoinRequestFailed(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (content == null) return const SizedBox.shrink();
    if (!widget.floatingCard) return content;
    // Item 11 root-cause fix: this elevated card chrome used to live at
    // the call site in every game screen, UNCONDITIONALLY wrapping this
    // panel — so even on the (overwhelmingly common) empty-content path,
    // the wrapper's own padding gave a zero-size child a non-zero visible
    // footprint: a persistent, purposeless elevated strip near the top of
    // every game screen, for every admin/moderator, for the entire
    // session. Now the chrome only exists at all when [content] is
    // non-null (i.e. there's a real pending request to show).
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: content,
      ),
    );
  }

  /// Returns null when there is nothing to show at all (the common case
  /// during live gameplay) — the ONLY signal [build] needs to decide
  /// whether to render anything, chrome included.
  Widget? _buildContent(BuildContext context) {
    final theme = context.theme;
    // The initial join-requests fetch is a background poll, not a game/room
    // sync. Only surface a progress bar for it where this panel is a permanent,
    // always-visible section (showAlways — the lobby's requires-approval case).
    // In the game screens (showAlways:false) this panel is an on-demand overlay
    // that collapses to nothing when there are no requests, so a full-width
    // LinearProgressIndicator pinned at the top of the game — the misleading
    // "game loading bar" — must NOT appear for it: render nothing until real
    // requests arrive. This removes the bar without hiding any real game-sync
    // state (the game screens have their own turn-timer/loading UI).
    if (_loading && _requests.isEmpty) {
      return widget.showAlways ? const LinearProgressIndicator() : null;
    }
    if (_requests.isEmpty && !widget.showAlways) return null;
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
              context.l10n.sharedNoPendingJoinRequests,
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
              context.l10n.sharedJoinRequestsCount(_requests.length),
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
          final name = profile['display_name'] as String? ?? context.l10n.packPlayer;
          final msg = req['message'] as String?;
          final subtitle = widget.inGame
              ? context.l10n.sharedWantsToJoinCurrentGame(name)
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
                    tooltip: context.l10n.sharedApprove,
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                    onPressed: () => _resolve(
                      req['id'] as String,
                      req['user_id'] as String,
                      false,
                    ),
                    tooltip: context.l10n.sharedReject,
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
