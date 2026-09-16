import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, this.size = 14, this.tier, this.isTrial = false});

  final double size;
  final String? tier;

  /// Trial Packs — a distinct flavor of this same badge for a
  /// trial-enabled pack the user hasn't purchased (see
  /// game_settings_sheet.dart's pack tiles). Mutually exclusive with
  /// [tier]: reuses the exact same badge shape/size/tooltip mechanics
  /// rather than a second visual style, just with its own color/symbol/
  /// localized label.
  final bool isTrial;

  static const Color _goldColor = Color(0xFFF5A623);
  static const Color _platinumColor = Color(0xFF7B68EE);
  static const Color _trialColor = Color(0xFF14B8A6);

  Color get _color => isTrial
      ? _trialColor
      : (tier == 'premium_plus' ? _platinumColor : _goldColor);

  String get _symbol =>
      isTrial ? 'T' : (tier == 'premium_plus' ? '⬡' : '✦');

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isTrial
          ? context.l10n.packTrialBadgeTooltip
          : (tier == 'premium_plus'
                ? context.l10n.premiumPlusLabel
                : context.l10n.premiumTitle),
      child: Container(
        width: size + 6,
        height: size + 6,
        decoration: BoxDecoration(
          color: _color.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: _color, width: 1),
        ),
        child: Center(
          child: Text(
            _symbol,
            style: TextStyle(
              fontSize: size * 0.7,
              color: _color,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class WithPremiumBadge extends StatelessWidget {
  const WithPremiumBadge({
    super.key,
    required this.child,
    required this.isPremium,
    this.tier,
    this.badgeSize = 12,
    this.gap = 4,
  });

  final Widget child;
  final bool isPremium;
  final String? tier;
  final double badgeSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (!isPremium) return child;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        SizedBox(width: gap),
        PremiumBadge(size: badgeSize, tier: tier),
      ],
    );
  }
}
