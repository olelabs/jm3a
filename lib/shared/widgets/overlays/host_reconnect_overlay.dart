import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
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
