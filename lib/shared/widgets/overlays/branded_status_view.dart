import 'dart:math' as math;

import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../animated_reaction_overlay.dart' show kAnimatedEmojiMap;

/// A reusable, on-brand full-screen "status" view for the game's immersive
/// transitional states — preparing, loading, waiting-for-host. Presentation
/// only: it renders a branded gradient, a breathing emoji badge, a playful
/// three-dot loader, a title/subtitle, and an optional footer. It owns no
/// lifecycle/business logic — callers pass the copy and (optionally) a live
/// footer widget (e.g. a countdown) and keep all their own state.
///
/// Deliberately dark-branded regardless of the app theme: these are
/// full-screen game moments where an immersive, consistent premium look is
/// preferable to a theme-following surface. Layout is overflow-safe on any
/// phone size (centred, scrollable, min-sized).
class BrandedStatusView extends StatefulWidget {
  const BrandedStatusView({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.footer,
    this.accent = AppColors.brandPurpleMid,
    this.showLoader = true,
  });

  final String emoji;
  final String title;
  final String? subtitle;

  /// Optional live content under the subtitle (e.g. a countdown chip).
  final Widget? footer;

  /// Accent used for the badge glow and loader dots.
  final Color accent;

  /// Whether to show the animated three-dot loader.
  final bool showLoader;

  @override
  State<BrandedStatusView> createState() => _BrandedStatusViewState();
}

class _BrandedStatusViewState extends State<BrandedStatusView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.brandPurpleDark,
              AppColors.brandBlueDark,
              AppColors.darkBase,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BreathingBadge(controller: _ctrl, accent: widget.accent, emoji: widget.emoji),
                  const SizedBox(height: 32),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.subtitle!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (widget.showLoader) ...[
                    const SizedBox(height: 28),
                    _ThreeDotLoader(controller: _ctrl, color: widget.accent),
                  ],
                  if (widget.footer != null) ...[
                    const SizedBox(height: 24),
                    widget.footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingBadge extends StatelessWidget {
  const _BreathingBadge({
    required this.controller,
    required this.accent,
    required this.emoji,
  });

  final AnimationController controller;
  final Color accent;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Smooth 0..1..0 breathing curve.
        final t = (math.sin(controller.value * 2 * math.pi) + 1) / 2;
        final scale = 1.0 + t * 0.06;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.35),
                  Colors.white.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.30 + t * 0.20),
                  blurRadius: 32 + t * 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      // Built ONCE (AnimatedBuilder's stable `child`, not re-run per tick)
      // — reuses the app's existing animated-emoji mechanism
      // (kAnimatedEmojiMap/AnimatedEmoji, already used by the reaction
      // overlay) when this glyph has an animated counterpart; falls back
      // to the original plain-text glyph otherwise, exactly as before.
      child: Center(
        child: kAnimatedEmojiMap.containsKey(emoji)
            ? AnimatedEmoji(
                kAnimatedEmojiMap[emoji]!,
                size: 52,
                source: AnimatedEmojiSource.asset,
                errorWidget: Text(
                  emoji,
                  style: const TextStyle(fontSize: 52),
                ),
              )
            : Text(emoji, style: const TextStyle(fontSize: 52)),
      ),
    );
  }
}

class _ThreeDotLoader extends StatelessWidget {
  const _ThreeDotLoader({required this.controller, required this.color});

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (controller.value + i * 0.18) % 1.0;
            final lift = math.sin(phase * 2 * math.pi).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.translate(
                offset: Offset(0, -lift * 6),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      color.withValues(alpha: 0.45),
                      Colors.white,
                      lift,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
