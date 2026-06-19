import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jma3a/core/theme/app_text_styles.dart';

import '../../../core/theme/app_colors.dart';

/// ═══════════════════════════════════════════════════════════════
/// JButton — Primary action button
/// ═══════════════════════════════════════════════════════════════
///
/// Full-width by default. Loading + disabled states built-in.
/// Supports: primary, destructive, secondary (outlined), ghost variants.
class JButton extends StatelessWidget {
  const JButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDestructive = false,
    this.icon,
    this.minimumSize,
    this.variant = JButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDestructive;
  final IconData? icon;
  final Size? minimumSize;
  final JButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = minimumSize ?? const Size(double.infinity, 52);

    final bgColor = isDestructive
        ? cs.error
        : switch (variant) {
            JButtonVariant.primary => cs.primary,
            JButtonVariant.secondary => Colors.transparent,
            JButtonVariant.ghost => Colors.transparent,
            JButtonVariant.surface => cs.surfaceContainerHighest,
          };

    final fgColor = isDestructive
        ? cs.onError
        : switch (variant) {
            JButtonVariant.primary => cs.onPrimary,
            JButtonVariant.secondary => cs.primary,
            JButtonVariant.ghost => cs.onSurfaceVariant,
            JButtonVariant.surface => cs.onSurface,
          };

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fgColor),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    return switch (variant) {
      JButtonVariant.secondary => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: size,
          foregroundColor: fgColor,
          side: BorderSide(color: isDestructive ? cs.error : cs.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        child: child,
      ),
      JButtonVariant.ghost || JButtonVariant.surface => TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          minimumSize: size,
          foregroundColor: fgColor,
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        child: child,
      ),
      _ => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          minimumSize: size,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        child: child,
      ),
    };
  }
}

enum JButtonVariant { primary, secondary, ghost, surface }

/// ═══════════════════════════════════════════════════════════════
/// JIconButton — Compact icon-only button
/// ═══════════════════════════════════════════════════════════════
class JIconButton extends StatelessWidget {
  const JIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.size = 40,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (filled) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: (color ?? cs.primary).withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: IconButton(
          icon: Icon(icon, size: size * 0.45),
          onPressed: onPressed,
          color: color ?? cs.primary,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
      );
    }

    return IconButton(
      icon: Icon(icon, size: size * 0.45),
      onPressed: onPressed,
      color: color ?? cs.onSurfaceVariant,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: Size(size, size),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// JGameChoiceButton — TRUTH / DARE / NHIE choice buttons
/// ═══════════════════════════════════════════════════════════════
/// Full-width, gradient, glow shadow, spring-bounce animation.
class JGameChoiceButton extends StatefulWidget {
  const JGameChoiceButton({
    super.key,
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
    this.height = 88,
    this.disabled = false,
  });

  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;
  final double height;
  final bool disabled;

  @override
  State<JGameChoiceButton> createState() => _JGameChoiceButtonState();
}

class _JGameChoiceButtonState extends State<JGameChoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        if (!widget.disabled) widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color, widget.color.withOpacity(0.82)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.prominent(widget.color),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Text(
                widget.label,
                style: AppTextStyles.gameChoiceLabel(color: AppColors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
