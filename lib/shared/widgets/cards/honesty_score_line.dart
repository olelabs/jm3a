import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';

/// Compact "🤝 Honesty +24  ⭐ Score 1,420" identity-adjacent stat line —
/// the ONE shared widget for showing a player's honesty_points +
/// general_score wherever another player's identity is already shown
/// (room lobby member tile, the ToD/NHIE/Meme in-game player UI, and the
/// Explore People card). Deliberately secondary in visual weight (small
/// icons/text, muted color for score) so it never competes with the
/// player's name/avatar for attention — see each call site's own layout
/// for how it's positioned relative to the name.
///
/// Honesty color logic mirrors the existing profile-screen honesty badges
/// (ProfileScreen's `_HonestyBadge`, UserProfileScreen's
/// `_HonestyStatBadge`) exactly: negative = dareRed, zero = neutral,
/// positive = nhieGreen. Never clamps or hides a negative value.
class HonestyScoreLine extends StatelessWidget {
  const HonestyScoreLine({
    super.key,
    required this.honestyPoints,
    required this.generalScore,
    this.iconSize = 12,
  });

  final int honestyPoints;
  final int generalScore;
  final double iconSize;

  static String _groupThousands(int value) {
    final negative = value < 0;
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return negative ? '-$buffer' : buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isNegative = honestyPoints < 0;
    final isZero = honestyPoints == 0;
    final honestyColor = isNegative
        ? AppColors.dareRed
        : isZero
            ? context.colorScheme.onSurfaceVariant
            : AppColors.nhieGreen;
    final honestyDisplay =
        '${honestyPoints > 0 ? '+' : ''}${_groupThousands(honestyPoints)}';
    final baseStyle = context.textTheme.bodySmall?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      fontSize: 11,
    );
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.handshake_rounded, size: iconSize, color: honestyColor),
        const SizedBox(width: 3),
        Text(honestyDisplay, style: baseStyle?.copyWith(color: honestyColor)),
        const SizedBox(width: 10),
        Icon(
          Icons.star_rounded,
          size: iconSize,
          color: context.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 3),
        Text(_groupThousands(generalScore), style: baseStyle),
      ],
    );
    // FittedBox, not Flexible+ellipsis — this line's TWO icons and THREE
    // fixed gaps have no shrinkable content of their own (icons can't
    // ellipsize), so at genuinely tight widths (a narrow device, a long
    // display name pushing this column smaller, a wide Add Friend button
    // next to it) even ellipsized text still wasn't always enough:
    // "A RenderFlex overflowed by N pixels" still fired for whatever
    // residual width the icons+gaps alone required beyond what was
    // available. FittedBox(scaleDown) scales the WHOLE row down as a
    // unit to guarantee it always fits its allocated space, never
    // overflows regardless of how little room is available, and never
    // enlarges past its natural size when there's plenty of room.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: row,
    );
  }
}
