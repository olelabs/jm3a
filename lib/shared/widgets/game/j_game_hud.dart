import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/j_theme_extension.dart';

/// JGameHud — Persistent HUD strip for any game screen
class JGameHud extends StatelessWidget {
  const JGameHud({
    super.key,
    required this.roundNumber,
    required this.maxRounds,
    required this.playerCount,
    required this.currentPlayerIndex,
    required this.phaseBadgeLabel,
    required this.phaseBadgeColor,
    this.isConnected = true,
    this.timerValue,
    this.connectionLabel,
  });

  final int    roundNumber;
  final int    maxRounds;
  final int    playerCount;
  final int    currentPlayerIndex;
  final String phaseBadgeLabel;
  final Color  phaseBadgeColor;
  final bool   isConnected;
  final double? timerValue;
  final String? connectionLabel;

  @override
  Widget build(BuildContext context) {
    final jc       = context.jColors;
    final progress = (roundNumber / maxRounds).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween:    Tween(begin: 0, end: progress),
          duration: AppDuration.medium,
          curve:    AppCurves.enter,
          builder: (_, val, __) => LinearProgressIndicator(
            value:           val,
            minHeight:       3,
            backgroundColor: jc.gameProgressBg,
            color:           jc.gameProgressActive,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              _RoundCounter(round: roundNumber, max: maxRounds,
                  color: jc.gameProgressActive),
              const SizedBox(width: AppSpacing.sm),
              _PhaseBadge(label: phaseBadgeLabel, color: phaseBadgeColor),
              const Spacer(),
              _TurnDots(count: playerCount,
                  activeIndex: currentPlayerIndex,
                  activeColor: jc.gameProgressActive),
              if (!isConnected) ...[
                const SizedBox(width: AppSpacing.sm),
                _ConnectionDot(isConnected: false,
                    label: connectionLabel ?? 'Reconnecting…'),
              ],
              if (timerValue != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _TimerArc(fraction: timerValue!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundCounter extends StatelessWidget {
  const _RoundCounter({required this.round, required this.max, required this.color});
  final int round, max;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(AppRadius.badge),
    ),
    child: Text('Round $round / $max',
        style: AppTextStyles.hudLabel(color: color)),
  );
}

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.label, required this.color});
  final String label;
  final Color  color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(AppRadius.badge),
    ),
    child: Text(label.toUpperCase(),
        style: AppTextStyles.hudLabel(color: color)),
  ).animate(key: ValueKey(label)).fadeIn(duration: AppDuration.fast);
}

class _TurnDots extends StatelessWidget {
  const _TurnDots({required this.count, required this.activeIndex, required this.activeColor});
  final int count, activeIndex;
  final Color activeColor;
  @override
  Widget build(BuildContext context) {
    final dotColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final dots = count > 8 ? 8 : count;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(dots, (i) {
        final isActive = i == activeIndex % dots;
        return AnimatedContainer(
          duration: AppDuration.normal, curve: AppCurves.spring,
          width: isActive ? 10 : 5, height: isActive ? 10 : 5,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? activeColor : dotColor.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot({required this.isConnected, required this.label});
  final bool isConnected;
  final String label;
  @override
  Widget build(BuildContext context) {
    final color = isConnected ? AppColors.successGreen : AppColors.warningAmber;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 6, height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ).animate(onPlay: (c) => c.repeat())
          .fadeOut(duration: const Duration(milliseconds: 600))
          .then().fadeIn(duration: const Duration(milliseconds: 600)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 11,
          fontWeight: FontWeight.w500)),
    ]);
  }
}

class _TimerArc extends StatelessWidget {
  const _TimerArc({required this.fraction});
  final double fraction;
  @override
  Widget build(BuildContext context) {
    final color = fraction > 0.3 ? AppColors.successGreen : AppColors.errorRed;
    return SizedBox(width: 22, height: 22,
      child: Stack(alignment: Alignment.center, children: [
        CircularProgressIndicator(value: fraction, strokeWidth: 2.5,
            color: color, backgroundColor: color.withOpacity(0.2)),
        Text('${(fraction * 10).round()}',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

/// JPlayerBanner — "It's [Name]'s turn" announcement
class JPlayerBanner extends StatelessWidget {
  const JPlayerBanner({
    super.key,
    required this.playerName,
    required this.avatarUrl,
    required this.isMyTurn,
    this.subtitle,
  });

  final String  playerName;
  final String? avatarUrl;
  final bool    isMyTurn;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: isMyTurn ? LinearGradient(
          colors: [primary.withOpacity(0.15), primary.withOpacity(0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ) : null,
        color: isMyTurn ? null : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: isMyTurn
            ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            backgroundColor: primary.withOpacity(0.2),
            child: avatarUrl == null
                ? Text(playerName.isNotEmpty ? playerName[0].toUpperCase() : '?',
                    style: TextStyle(color: primary, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isMyTurn ? 'Your turn!' : "$playerName's turn",
                style: AppTextStyles.playerName(
                    color: isMyTurn ? primary : theme.colorScheme.onSurface),
              ),
              if (subtitle != null)
                Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppDuration.normal)
        .slideY(begin: -0.04, end: 0, curve: AppCurves.enter);
  }
}
