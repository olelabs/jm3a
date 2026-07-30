import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/extensions/context_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/buttons/j_button.dart';
import '../../domain/tod_models.dart';

/// End-of-game summary screen.
/// Shows final scores, per-player stats, and a confetti-style celebration.
class TodEndScreen extends StatelessWidget {
  const TodEndScreen({
    super.key,
    required this.state,
    required this.displayNames,
    required this.onLeave,
  });

  final TodState            state;
  final Map<String, String> displayNames;
  final VoidCallback        onLeave;

  @override
  Widget build(BuildContext context) {
    final theme  = context.theme;
    final scores = state.sortedScores;
    final reason = _endLabel(state.endReason);
    final winner = scores.isNotEmpty ? scores.first : null;
    final winnerName = winner != null
        ? (displayNames[winner.userId] ??
            'Player ${winner.userId.substring(0, 4)}')
        : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Trophy + title
              const Text('🏆', style: TextStyle(fontSize: 80))
                  .animate()
                  .scale(
                    begin:    const Offset(0.2, 0.2),
                    end:      const Offset(1, 1),
                    duration: 700.ms,
                    curve:    Curves.elasticOut,
                  ),

              const SizedBox(height: 12),

              Text('Game Over!',
                  style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800))
                  .animate(delay: 200.ms).fadeIn().slideY(begin: 0.15, end: 0),

              Text(reason,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant))
                  .animate(delay: 280.ms).fadeIn(),

              const SizedBox(height: 20),

              // Winner banner
              if (winnerName != null)
                Container(
                  width:   double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.ownerBadge.withOpacity(0.15),
                        AppColors.ownerBadge.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.ownerBadge.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('👑', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Text('$winnerName wins!',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ownerBadge)),
                      const SizedBox(width: 8),
                      Text('${winner!.points} pts',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ownerBadge)),
                    ],
                  ),
                ).animate(delay: 350.ms).fadeIn(),

              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  _StatBox(label: 'Rounds', value: '${state.roundNumber}', icon: '🔄'),
                  const SizedBox(width: 12),
                  _StatBox(label: 'Players', value: '${state.playerOrder.length}', icon: '👥'),
                  const SizedBox(width: 12),
                  _StatBox(
                    label: 'Total Turns',
                    value: '${state.scores.values.fold(0, (s, e) => s + e.totalCompleted)}',
                    icon: '🎯',
                  ),
                ],
              ).animate(delay: 420.ms).fadeIn(),

              const SizedBox(height: 20),

              // Leaderboard
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color:        theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Text('Leaderboard',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: scores.length,
                          itemBuilder: (_, i) => _LeaderboardRow(
                            rank:        i + 1,
                            score:       scores[i],
                            displayName: displayNames[scores[i].userId] ??
                                'Player ${scores[i].userId.substring(0, 4)}',
                            isWinner:    i == 0,
                          ).animate(delay: (500 + i * 50).ms)
                              .fadeIn()
                              .slideX(begin: 0.06, end: 0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              JButton(
                label:     'Go to Home',
                onPressed: onLeave,
                icon:      Icons.home_rounded,
              ).animate(delay: 700.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  String _endLabel(String? reason) => switch (reason) {
    'round_limit' => 'All rounds completed',
    'manual'      => 'Game ended by host',
    'score_limit' => 'Score limit reached',
    _             => 'Game finished',
  };
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(value,
                style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.score,
    required this.displayName,
    this.isWinner = false,
  });
  final int           rank;
  final TodPlayerScore score;
  final String        displayName;
  final bool          isWinner;

  @override
  Widget build(BuildContext context) {
    final theme     = context.theme;
    final rankEmoji = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '  ${rank.toString().padLeft(2)}',
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: isWinner
          ? BoxDecoration(
              color: AppColors.ownerBadge.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(rankEmoji,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Text(displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600)),
          ),

          // Per-player micro-stats
          _MiniStat(icon: '✅', value: score.totalCompleted),
          const SizedBox(width: 6),
          _MiniStat(icon: '⏭', value: score.skips),
          const SizedBox(width: 10),

          Text('${score.points} pts',
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color:      theme.colorScheme.primary)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value});
  final String icon;
  final int    value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:        context.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$icon$value',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
