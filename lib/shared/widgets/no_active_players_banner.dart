import 'package:flutter/material.dart';

import '../../core/extensions/context_ext.dart';
import '../../features/rooms/presentation/room_provider.dart';

/// Shown to the owner when every other active, non-spectator participant
/// has left an in-progress game — the game cannot meaningfully continue,
/// and the owner needs to be told rather than silently sitting alone
/// waiting on votes/submissions that will never come. Never force-ends the
/// game automatically; the owner has to act.
class NoActivePlayersBanner extends StatelessWidget {
  const NoActivePlayersBanner({
    super.key,
    required this.roomProvider,
    required this.isOwner,
    required this.onEndGame,
  });

  final RoomProvider? roomProvider;
  final bool isOwner;
  final VoidCallback onEndGame;

  @override
  Widget build(BuildContext context) {
    final rp = roomProvider;
    if (rp == null || !isOwner) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: rp,
      builder: (context, _) {
        // The pause overlay (HostReconnectOverlay) is painted as an early
        // return from each game screen's own Consumer builder — it does
        // NOT cover sibling Stack children rendered alongside it (this
        // banner, the join-requests panel), which otherwise stay visible
        // and tappable on top of it. onEndGame is a genuine game-state
        // mutation and must not be reachable while the room is paused for
        // a disconnected host (see RoomProvider.isPausedForHostReconnect).
        if (!rp.hasNoActivePlayers || rp.isPausedForHostReconnect) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.sharedEveryoneLeftNotice,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Explicit minimumSize:Size.zero — the app-wide
                    // FilledButton theme sets minimumSize:
                    // Size(double.infinity, 52); a non-Expanded Row child
                    // receives an unbounded max width, so this throws
                    // "BoxConstraints forces an infinite width" without
                    // the override (see lobby_screen.dart's identical
                    // fix/comment for the full explanation).
                    SizedBox(
                      height: 34,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onEndGame,
                        child: Text(context.l10n.sharedEndGame),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
