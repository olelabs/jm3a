import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/rooms/presentation/room_provider.dart';
import 'branded_status_view.dart';

/// Full-screen "waiting for host to reconnect" state, shown identically by
/// Truth or Dare, Never Have I Ever, and Meme whenever [RoomProvider]
/// reports the room paused for a disconnected host (see
/// RoomProvider.isPausedForHostReconnect / hostReconnectRemaining). Replaces
/// the entire game screen — no gameplay UI, no interaction — for exactly as
/// long as the room stays paused; the screen behind this pops or rebuilds
/// into a normal game view on its own once RoomProvider reports 'resume' or
/// the game ends.
class HostReconnectOverlay extends StatefulWidget {
  const HostReconnectOverlay({super.key, required this.roomProvider});

  final RoomProvider roomProvider;

  @override
  State<HostReconnectOverlay> createState() => _HostReconnectOverlayState();
}

class _HostReconnectOverlayState extends State<HostReconnectOverlay> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // hostReconnectRemaining is derived from a wall-clock deadline, not
    // from provider state that changes on its own — nothing calls
    // notifyListeners() once a second, so this widget has to tick itself
    // to keep the countdown live.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UI redesign only — same ticker + hostReconnectRemaining source.
    final seconds = widget.roomProvider.hostReconnectRemaining.inSeconds;
    return BrandedStatusView(
      emoji: '📡',
      title: context.l10n.hostReconnectWaitingTitle,
      subtitle: context.l10n.hostReconnectWaitingBody(seconds),
      accent: AppColors.brandOrangeMid,
      showLoader: false,
      footer: _CountdownChip(seconds: seconds),
      // Players must never be stuck waiting under this countdown with no
      // way out — pinned top-left (see BrandedStatusView.topAction), well
      // clear of the countdown chip in the footer below. This overlay is
      // never shown to the room owner/admin themselves (see every game
      // screen's `roomProvider.isOwner != true` gate before rendering
      // it), so whoever can see this button is always a normal
      // participant — never the admin being waited for.
      topAction: _LeaveGameButton(roomProvider: widget.roomProvider),
    );
  }
}

/// Lets a non-owner participant leave the room while waiting for the host
/// to reconnect, instead of being stuck under the countdown with no way
/// out. Reuses the exact same "normal player leaves the room entirely"
/// sequence already used elsewhere (LobbyScreen._leaveRoom's non-owner
/// branch, memeShowLeaveDialog's non-owner branch) rather than inventing
/// a new leave mechanism — free this player's room slot, tell every
/// other client, then exit to Home. Never touches any other room/game
/// the player may separately be a member of.
class _LeaveGameButton extends StatelessWidget {
  const _LeaveGameButton({required this.roomProvider});

  final RoomProvider roomProvider;

  Future<void> _confirmAndLeave(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(context.l10n.todQuitGameTitle),
        content: Text(context.l10n.todQuitGameBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(d).pop(true),
            child: Text(context.l10n.leaveGame),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final roomId = roomProvider.room?.id;
    final myId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (roomId != null && myId.isNotEmpty) {
      final displayName =
          context.read<AuthProvider>().currentUser?.displayName ??
          context.l10n.defaultPlayerName;
      try {
        await sl.realtimeService.broadcastRoomEvent(roomId, {
          'type': 'player_left',
          'user_id': myId,
          'display_name': displayName,
          'for_good': true,
        });
        await sl.roomRepository.setMemberDefinitiveLeave(roomId, myId);
      } catch (_) {
        // Best-effort, matching every other non-owner leave path in this
        // app: even if either call fails, the player still must not be
        // stuck on this screen — fall through to navigating away.
      }
    }
    if (context.mounted) AppRouter.router.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _confirmAndLeave(context),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.9),
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: const Icon(Icons.logout, size: 18),
      label: Text(context.l10n.leaveGame),
    );
  }
}

/// Large, legible remaining-seconds chip so the wait reads as an intentional
/// countdown rather than an anonymous spinner.
class _CountdownChip extends StatelessWidget {
  const _CountdownChip({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 20,
            color: Colors.white.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 10),
          Text(
            '${seconds}s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
