import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
import 'package:jma3a/features/games/truth_or_dare/tod_game_provider.dart';

import '../../../../../../core/extensions/context_ext.dart';
import '../../../../../../core/theme/app_colors.dart';
// import '../../../domain/tod_models.dart';
// import '../../../tod_game_provider.dart';

/// Persistent HUD shown at the top of all gameplay screens.
/// Contains: round progress, round counter, timer badge, player count.
class TodHud extends StatelessWidget {
  const TodHud({
    super.key,
    required this.state,
    required this.game,
    required this.displayNames,
  });

  final TodState state;
  final TodGameProvider game;
  final Map<String, String> displayNames;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final progress = state.maxRounds > 0
        ? state.roundNumber / state.maxRounds
        : 0.0;

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 3,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: AppColors.truthColor,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                // Round badge
                _RoundBadge(
                  round: state.roundNumber,
                  maxRound: state.maxRounds,
                ),

                const Spacer(),

                // Timer badge
                if (game.timerIsRunning || game.timerRemaining > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _TimerBadge(
                      seconds: game.timerRemaining,
                    ).animate().fadeIn(),
                  ),

                // Phase indicator
                _PhaseBadge(phase: state.phase),

                const SizedBox(width: 10),

                // Player count
                Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.playerOrder.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBadge extends StatelessWidget {
  const _RoundBadge({required this.round, required this.maxRound});
  final int round;
  final int maxRound;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.navyBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Round $round / $maxRound',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.phase});
  final TodTurnPhase phase;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (phase) {
      TodTurnPhase.choosingType => ('Choosing', AppColors.infoBlue),
      TodTurnPhase.readingCard => ('In Progress', AppColors.successGreen),
      TodTurnPhase.awaitingResult => ('Completing…', AppColors.warningAmber),
      TodTurnPhase.punishmentVoting => ('⚠️ Voting', AppColors.warningAmber),
      TodTurnPhase.awaitingNextTurn => ('Done', AppColors.successGreen),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.seconds});
  final int seconds;

  Color get _color {
    if (seconds > 30) return AppColors.successGreen;
    if (seconds > 10) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 13, color: _color),
          const SizedBox(width: 3),
          Text(
            '${seconds}s',
            style: TextStyle(
              color: _color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
