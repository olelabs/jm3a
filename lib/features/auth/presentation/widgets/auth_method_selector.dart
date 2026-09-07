import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';

enum AuthMethod { phone, email }

/// Two selectable "how do you want to sign up" cards — replaces the old
/// plain-text "Use email instead" link. Auth redesign, section 8: visually
/// distinct selected state, icons instead of raw emoji (Jma3a already has
/// a Material icon set), RTL-safe (Row auto-mirrors under Directionality),
/// and a large enough tap target that a whole card responds, not just its
/// label.
class AuthMethodSelector extends StatelessWidget {
  const AuthMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AuthMethod selected;
  final ValueChanged<AuthMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _MethodCard(
            icon: Icons.phone_iphone_rounded,
            label: l10n.authMethodPhone,
            hint: l10n.authMethodPhoneHint,
            isSelected: selected == AuthMethod.phone,
            onTap: () => onChanged(AuthMethod.phone),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MethodCard(
            icon: Icons.alternate_email_rounded,
            label: l10n.authMethodEmail,
            hint: l10n.authMethodEmailHint,
            isSelected: selected == AuthMethod.email,
            onTap: () => onChanged(AuthMethod.email),
          ),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.label,
    required this.hint,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 92),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary.withOpacity(0.10)
                  : cs.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isSelected ? cs.primary : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? AppShadows.elevated(AppColors.navyBlue)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  scale: isSelected ? 1.08 : 1.0,
                  curve: Curves.easeOutBack,
                  child: Icon(
                    icon,
                    size: 26,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(target: isSelected ? 1 : 0).scaleXY(
      begin: 1,
      end: 1.02,
      duration: 150.ms,
      curve: Curves.easeOut,
    );
  }
}
