import 'package:flutter/material.dart';

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
        if (!rp.hasNoActivePlayers) return const SizedBox.shrink();
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
                        'Every other player has left. The game cannot '
                        'continue — end it when you\'re ready.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                      onPressed: onEndGame,
                      child: const Text('End Game'),
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
