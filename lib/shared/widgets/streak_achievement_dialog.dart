import 'package:flutter/material.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/services/streak_achievement_service.dart';
import '../../core/theme/app_colors.dart';

/// Correction pass — the actual congratulations UI for
/// [StreakAchievementEvent]. Shown exactly once per genuine event by the
/// caller (see ProfileProvider.pendingStreakAchievement's own doc comment
/// for how duplicates are prevented) — this widget itself has no
/// deduplication logic of its own, it just renders whatever event it's
/// given.
Future<void> showStreakAchievementDialog(
  BuildContext context,
  StreakAchievementEvent event,
) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: context.l10n.streakAchievementBarrierLabel,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) => _StreakAchievementDialog(event: event),
    transitionBuilder: (context, animation, _, child) {
      // Respects the platform's reduced-motion setting — a plain fade
      // instead of the scale/bounce when disableAnimations is set.
      if (MediaQuery.disableAnimationsOf(context)) {
        return FadeTransition(opacity: animation, child: child);
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
  );
}

class _StreakAchievementDialog extends StatelessWidget {
  const _StreakAchievementDialog({required this.event});
  final StreakAchievementEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isNew = event.type == StreakAchievementType.newStreak;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Semantics(
        label: isNew
            ? l10n.streakNewTitle
            : l10n.streakExtendedTitle(event.streakCount),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.darkElevated, AppColors.darkSurface],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.brandOrangeMid.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandOrangeMid.withValues(alpha: 0.25),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🔥', style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                isNew
                    ? l10n.streakNewTitle
                    : l10n.streakExtendedTitle(event.streakCount),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isNew
                    ? l10n.streakNewBody
                    : l10n.streakExtendedBody(event.streakCount),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandOrangeMid,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(
                    isNew ? l10n.streakNewCta : l10n.streakExtendedCta,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
