import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../cards/j_card.dart';
import '../cards/user_avatar.dart';

/// Item 4/5 (result-screen pass) — what actually happened for this player
/// this round, taken from the game's own state (playerOrder vs. the
/// response map), never inferred from response text. [responded] is the
/// only case with real content to show; [skipped]/[timedOut] are both
/// "no response", kept as separate values (not one shared "noResponse")
/// so a game that genuinely distinguishes them (a real Skip action vs. a
/// timer expiring) can say so precisely once its own state tracks that
/// distinction — see this pass's own report for which games currently
/// can/can't make that distinction from their existing state.
enum PlayerResultStatus { responded, skipped, timedOut }

/// One player's result row for a game's results/history view (Never Have
/// I Ever, Meme — see each screen's own usage). A single shared shell so
/// every game's result list reads consistently (avatar, name, response-
/// or-status area, optional trailing controls) without re-implementing
/// the same card chrome per game — callers only supply what's genuinely
/// game-specific (the response content widget, e.g. NHIE's Never/I Have
/// pill + honesty vote buttons, or Meme's sticker/vote count).
///
/// A [responded] row and a [skipped]/[timedOut] row are deliberately
/// styled differently (solid surface + full opacity vs. a muted, dashed-
/// border, lower-opacity treatment with a status icon) so the two are
/// never visually confusable — the actual point of item 4/5's wording
/// fix, not just correct text.
class PlayerResultTile extends StatelessWidget {
  const PlayerResultTile({
    super.key,
    required this.avatarUrl,
    required this.avatarConfig,
    required this.isPremium,
    required this.displayName,
    required this.status,
    this.isViewer = false,
    this.accentColor,
    this.responseContent,
    this.trailing,
    this.statusLabelOverride,
  });

  final String? avatarUrl;
  final Map<String, dynamic>? avatarConfig;
  final bool isPremium;
  final String displayName;
  final PlayerResultStatus status;

  /// Highlights this row as "you" (a colored border), the same visual
  /// language NHIE's own pre-existing result row already used.
  final bool isViewer;

  /// Per-game accent for the [isViewer] border / status icon tint (e.g.
  /// NHIE's vivid teal, Meme's own theme color). Defaults to the ambient
  /// theme's primary when null.
  final Color? accentColor;

  /// Only rendered when [status] is [PlayerResultStatus.responded] — the
  /// game's own response content (message text, sticker, vote pill,
  /// whatever is genuinely game-specific). Ignored for a skipped/timed-
  /// out row, which shows the status label instead so a real response
  /// and a non-response can never look alike.
  final Widget? responseContent;

  /// Extra game-specific trailing controls (e.g. NHIE's honesty vote
  /// buttons, Meme's vote count) — shown for every status, since e.g.
  /// honesty voting on a skipped turn is still a meaningful action.
  final Widget? trailing;

  /// Overrides the default localized status label/icon for [skipped]/
  /// [timedOut] — leave null to use [PlayerResultStatus]'s own defaults.
  final String? statusLabelOverride;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;
    final accent = accentColor ?? theme.colorScheme.primary;
    final isMuted = status != PlayerResultStatus.responded;

    final statusLabel =
        statusLabelOverride ??
        switch (status) {
          PlayerResultStatus.responded => '',
          PlayerResultStatus.skipped => l10n.gameResultSkipped,
          PlayerResultStatus.timedOut => l10n.gameResultDidNotRespond,
        };
    final statusIcon = switch (status) {
      PlayerResultStatus.responded => Icons.check_circle_rounded,
      PlayerResultStatus.skipped => Icons.skip_next_rounded,
      PlayerResultStatus.timedOut => Icons.hourglass_bottom_rounded,
    };

    return JCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: isMuted
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : null,
      borderColor: isViewer
          ? accent
          : (isMuted ? theme.colorScheme.outlineVariant : null),
      borderWidth: isViewer ? 1.6 : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: isMuted ? 0.6 : 1,
            child: UserAvatar(
              avatarUrl: avatarUrl,
              avatarConfig: avatarConfig,
              isPremium: isPremium,
              displayName: displayName,
              size: 40,
              borderWidth: isViewer ? 2 : 0,
              borderColor: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isViewer ? accent : null,
                        ),
                      ),
                    ),
                    if (isViewer) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.star_rounded, size: 14, color: accent),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (status == PlayerResultStatus.responded)
                  if (responseContent != null)
                    responseContent!
                  else
                    const SizedBox.shrink()
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          statusLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// A compact "N of M responded" chip used by result-screen headers — see
/// item 5's header requirements. Deliberately tiny/standalone (not part
/// of [PlayerResultTile]) so it can sit in an AppBar/header area
/// independent of the player list.
class ResultCompletionChip extends StatelessWidget {
  const ResultCompletionChip({
    super.key,
    required this.responded,
    required this.total,
  });

  final int responded;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final complete = total > 0 && responded >= total;
    final color = complete ? AppColors.successGreen : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete ? Icons.check_circle_rounded : Icons.people_alt_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            '$responded/$total',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
