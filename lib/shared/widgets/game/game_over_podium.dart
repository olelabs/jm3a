import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Ranked, medal-based standings list for a game-over screen — replacing a
/// flat `ListTile` list of "name — score" rows with a proportional-bar
/// podium feel. Shared by NHIE and Meme's game-over screens so the same
/// visual treatment isn't rebuilt twice; purely presentational, reads
/// scores it's given and never recomputes/derives them.
class GameOverPodium extends StatelessWidget {
  const GameOverPodium({
    super.key,
    required this.entries,
    required this.nameOf,
    required this.scoreLabelOf,
    required this.accentColor,
  });

  /// Already sorted, highest score first.
  final List<MapEntry<String, int>> entries;
  final String Function(String userId) nameOf;
  final String Function(int score) scoreLabelOf;
  final Color accentColor;

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final maxScore = entries.first.value <= 0 ? 1 : entries.first.value;

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        // Tie-aware rank: how many players scored strictly higher — ties
        // share a medal, a 0-score board crowns nobody. Mirrors the
        // pre-existing denseRankForScore logic each screen already used.
        var rank = 0;
        for (final other in entries) {
          if (other.value > e.value) rank++;
        }
        final isTop = e.value > 0 && rank == 0;
        final medal = e.value <= 0
            ? '•'
            : (rank < _medals.length ? _medals[rank] : '${rank + 1}');
        final fraction = (e.value / maxScore).clamp(0.0, 1.0);

        return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isTop
                    ? accentColor.withValues(alpha: 0.12)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: isTop
                    ? Border.all(color: accentColor.withValues(alpha: 0.5))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          medal,
                          style: const TextStyle(fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          nameOf(e.key),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        scoreLabelOf(e.value),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isTop ? accentColor : null,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: fraction),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        color: isTop
                            ? accentColor
                            : theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.4,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate(delay: (i * 60).ms)
            .fadeIn()
            .slideX(begin: 0.04, end: 0);
      },
    );
  }
}
