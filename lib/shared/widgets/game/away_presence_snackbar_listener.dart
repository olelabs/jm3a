import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/services/presence_service.dart';
import '../../../features/rooms/presentation/room_provider.dart';

/// Shows one snackbar the moment a Premium Plus room member transitions
/// into the away/backgrounded presence state while an active game is on
/// screen — edge-triggered (fires once on the transition INTO away, never
/// repeatedly while they remain away) and clears itself on their
/// transition back.
///
/// A single shared implementation wrapped around each game screen's body
/// (ToD/NHIE/Meme) instead of three copies of the same diff/dedup logic.
/// Subscribes directly to [PresenceService.presenceStream] — a broadcast
/// stream any number of listeners can attach to — never RealtimeService's
/// per-room callback slot, so this cannot be stolen by/steal from
/// RoomProvider's own realtime subscriptions (see the codebase's known
/// RealtimeService single-callback-slot issue).
class AwayPresenceSnackbarListener extends StatefulWidget {
  const AwayPresenceSnackbarListener({
    super.key,
    required this.roomProvider,
    required this.child,
  });

  final RoomProvider roomProvider;
  final Widget child;

  @override
  State<AwayPresenceSnackbarListener> createState() =>
      _AwayPresenceSnackbarListenerState();
}

class _AwayPresenceSnackbarListenerState
    extends State<AwayPresenceSnackbarListener> {
  StreamSubscription<Map<String, UserPresence>>? _sub;
  Set<String> _awayUserIds = const {};

  @override
  void initState() {
    super.initState();
    _awayUserIds = _computeAway(PresenceService.instance.currentPresence);
    _sub = PresenceService.instance.presenceStream.listen(_onPresenceUpdate);
  }

  Set<String> _computeAway(Map<String, UserPresence> presence) {
    final roomId = widget.roomProvider.room?.id;
    if (roomId == null) return const {};
    final result = <String>{};
    for (final m in widget.roomProvider.members) {
      if (!m.isPremium || m.premiumTier != 'premium_plus') continue;
      final p = presence[m.userId];
      if (p?.status == UserPresenceStatus.backgrounded && p?.roomId == roomId) {
        result.add(m.userId);
      }
    }
    return result;
  }

  void _onPresenceUpdate(Map<String, UserPresence> presence) {
    final updated = _computeAway(presence);
    final newlyAway = updated.difference(_awayUserIds);
    _awayUserIds = updated;
    if (newlyAway.isEmpty || !mounted) return;
    for (final userId in newlyAway) {
      String? displayName;
      for (final m in widget.roomProvider.members) {
        if (m.userId == userId) {
          displayName = m.displayName;
          break;
        }
      }
      if (displayName == null) continue;
      context.showSnackBar(context.l10n.presenceUserAwaySnackbar(displayName));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
