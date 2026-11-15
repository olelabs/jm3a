import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';

/// Small reusable "Verified Creator" checkmark badge for beside a real
/// user's display name — mirrors PremiumBadge's own small-badge shape
/// (a size-parameterized icon with a tooltip), so this doesn't invent a
/// second badge pattern.
///
/// The authoritative condition a caller should pass is
/// [UserEntity.isVerifiedCreator] (verification_status == 'verified'),
/// or another field already confirmed to reflect that exact same
/// underlying check (e.g. SocialProfile.isVerified, populated from the
/// identical `profile['verification_status'] == 'verified'` mapping).
/// This is deliberately NOT the same thing as an official-account flag
/// (isOfficial / is_official_account) or a pack's own creator-
/// verification snapshot (PackEntity.isVerifiedCreator) — this widget
/// only renders a badge, it never decides which flag means what; the
/// caller must verify that first.
class VerifiedCreatorBadge extends StatelessWidget {
  const VerifiedCreatorBadge({
    super.key,
    this.size = 14,
    this.color = AppColors.infoBlue,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.profileVerifiedCreator,
      child: Icon(Icons.verified_rounded, size: size, color: color),
    );
  }
}
