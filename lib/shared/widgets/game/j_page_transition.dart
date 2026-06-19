import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jma3a/core/theme/app_colors.dart';

// import '../../core/theme/app_colors.dart';

/// ═══════════════════════════════════════════════════════════════
/// Jma3a Page Transition System
/// ═══════════════════════════════════════════════════════════════
///
/// All screens use one of these transition builders. Never call
/// Navigator.push directly with a MaterialPageRoute in feature code.
/// Instead, use context.push() (GoRouter) or these custom transitions.
///
/// Design philosophy:
/// - Standard navigation: subtle slide + fade (feels native, fast)
/// - Game screens: scale-up from center (moment of arrival)
/// - Bottom sheets: slide-up (standard gesture)
/// - Dialogs: scale + fade (focused attention)
/// - Game card reveal: custom flip animation (delightful)

class JPageTransitions {
  /// Standard app navigation — slide from right + fade in.
  /// Used for: home → profile, marketplace → pack detail.
  static CustomTransitionPage<T> slide<T>(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) => CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      final slideIn =
          Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(
            CurvedAnimation(
              parent: animation,
              curve: AppCurves.enter,
              reverseCurve: AppCurves.exit,
            ),
          );

      final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.6, curve: AppCurves.enter),
        ),
      );

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slideIn, child: child),
      );
    },
    transitionDuration: AppDuration.pageEnter,
    reverseTransitionDuration: AppDuration.pageExit,
  );

  /// Game enter transition — scale up from slight shrink + fade.
  /// Used for: room → gameplay.
  static CustomTransitionPage<T> gameEnter<T>(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) => CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      final scale = Tween<double>(
        begin: 0.94,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: AppCurves.spring));
      final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.5, curve: AppCurves.enter),
        ),
      );

      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
    transitionDuration: AppDuration.slow,
    reverseTransitionDuration: AppDuration.medium,
  );

  /// Fade-only — for tab switches, overlay content.
  static CustomTransitionPage<T> fade<T>(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) => CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: AppDuration.normal,
    reverseTransitionDuration: AppDuration.fast,
  );

  /// No transition — for the initial route only.
  static CustomTransitionPage<T> none<T>(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) => CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, __, ___, child) => child,
    transitionDuration: Duration.zero,
  );
}

/// ═══════════════════════════════════════════════════════════════
/// JAnimatedCounter — Animated number change
/// ═══════════════════════════════════════════════════════════════
/// Used for: balance updates, score changes, player count.
class JAnimatedCounter extends StatefulWidget {
  const JAnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = AppDuration.medium,
    this.curve = AppCurves.enter,
  });

  final int value;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final Duration duration;
  final Curve curve;

  @override
  State<JAnimatedCounter> createState() => _JAnimatedCounterState();
}

class _JAnimatedCounterState extends State<JAnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(
      begin: widget.value.toDouble(),
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));
  }

  @override
  void didUpdateWidget(JAnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));
      _ctrl.forward(from: 0);
      _previousValue = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(
        '${widget.prefix}${_anim.value.round()}${widget.suffix}',
        style: widget.style,
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// JVotingProgressBar — Animated voting result bar
/// ═══════════════════════════════════════════════════════════════
class JVotingProgressBar extends StatelessWidget {
  const JVotingProgressBar({
    super.key,
    required this.yesCount,
    required this.noCount,
    required this.yesLabel,
    required this.noLabel,
    this.yesColor = AppColors.successGreen,
    this.noColor = AppColors.errorRed,
  });

  final int yesCount, noCount;
  final String yesLabel, noLabel;
  final Color yesColor, noColor;

  @override
  Widget build(BuildContext context) {
    final total = yesCount + noCount;
    final yesFraction = total == 0 ? 0.5 : yesCount / total;

    return Column(
      children: [
        Row(
          children: [
            Text(
              yesLabel,
              style: TextStyle(
                color: yesColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              noLabel,
              style: TextStyle(
                color: noColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.badge),
          child: Row(
            children: [
              Flexible(
                flex: (yesFraction * 100).round(),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: AppDuration.medium,
                  curve: AppCurves.enter,
                  builder: (_, val, __) => Container(
                    height: 10,
                    color: yesColor.withOpacity(0.8 + 0.2 * val),
                  ),
                ),
              ),
              Flexible(
                flex: ((1 - yesFraction) * 100).round(),
                child: Container(height: 10, color: noColor.withOpacity(0.6)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '$yesCount votes',
              style: TextStyle(color: yesColor, fontSize: 12),
            ),
            const Spacer(),
            Text(
              '$noCount votes',
              style: TextStyle(color: noColor, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// JConfettiOverlay — Celebration particles
/// ═══════════════════════════════════════════════════════════════
/// Pure Flutter — no external package needed for MVP.
/// Uses flutter_animate to drive simple confetti dots.
class JWinnerBadge extends StatelessWidget {
  const JWinnerBadge({super.key, required this.playerName, this.subtitle});
  final String playerName;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.ownerGold, Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.glow(AppColors.ownerGold),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 56)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            playerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
        ],
      ),
    );
  }
}
