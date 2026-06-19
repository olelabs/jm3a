import 'package:flutter/material.dart';
import 'package:jma3a/features/offline/domain/offline_session.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../games/truth_or_dare/domain/tod_models.dart';
import '../../data/offline_game_provider.dart';

/// Persistent HUD strip for offline gameplay.
/// Shows round progress, current player indicator, LAN peer count.
class OfflineHud extends StatelessWidget {
  const OfflineHud({super.key, required this.game});
  final OfflineGameProvider game;

  @override
  Widget build(BuildContext context) {
    final session = game.session;
    final state = game.state;
    if (session == null) return const SizedBox.shrink();

    final maxRounds = session.config.maxRounds;
    final round = state is TodState ? state.roundNumber : 1;
    final progress = (round / maxRounds).clamp(0.0, 1.0);
    final theme = context.theme;

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => LinearProgressIndicator(
              value: val,
              minHeight: 3,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: AppColors.navyBlue,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                // Round counter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navyBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Round $round / $maxRounds',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const Spacer(),

                // Player turn dots
                if (state is TodState)
                  _TurnDots(state: state, session: game.session!),

                // LAN peer count
                if (game.mode == OfflineMode.lan) ...[
                  const SizedBox(width: 10),
                  Icon(
                    Icons.wifi,
                    size: 14,
                    color: game.lanConnected
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${game.lanPeers.length + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: game.lanConnected
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TurnDots extends StatelessWidget {
  const _TurnDots({required this.state, required this.session});
  final TodState state;
  final dynamic session; // OfflineSession

  @override
  Widget build(BuildContext context) {
    final players = state.playerOrder;
    final maxDots = players.length > 8 ? 8 : players.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxDots, (i) {
        final isCurrent = i == state.currentPlayerIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isCurrent ? 10 : 5,
          height: isCurrent ? 10 : 5,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.navyBlue
                : context.colorScheme.onSurfaceVariant.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
