import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/domain/entities/user_entity.dart';

/// Isolated, purpose-built widget for [shareProfile]'s generated image —
/// deliberately NOT a screenshot of any real screen (see profile_share.dart
/// for the RepaintBoundary capture code). Only publicly-visible profile
/// fields are laid out here: avatar, display name, username, general
/// score, honesty points, and the Verified Creator badge — never phone,
/// email, or any other private/auth field.
///
/// Avatar resolution intentionally mirrors UserAvatar's own
/// premium-avatar-config-first, plain-avatarUrl-fallback priority (see
/// UserAvatar._resolvedUrl) rather than inventing a second avatar system;
/// [avatarChild] is expected to already be a fully decoded/loaded circular
/// avatar built via that same priority (see _loadAvatarWidget in
/// profile_share.dart) so the RepaintBoundary capture never races a
/// network image load.
class ProfileShareCard extends StatelessWidget {
  const ProfileShareCard({
    super.key,
    required this.user,
    required this.generalScore,
    required this.honestyPoints,
    required this.profileLink,
    required this.avatarChild,
  });

  final UserEntity user;
  final int generalScore;
  final int honestyPoints;
  final String profileLink;
  final Widget avatarChild;

  static const double width = 380;
  static const double height = 640;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = user.displayName ?? user.username ?? l10n.packPlayer;

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brandBlueDark, AppColors.brandPurpleMid],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/backgrounds/jma3a_logo_white.png',
                      width: 28,
                      height: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 128,
                  height: 128,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: user.isPremium
                          ? AppColors.amberOrangeLight
                          : Colors.white,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(child: avatarChild),
                ),
                const SizedBox(height: 18),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (user.username != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
                if (user.isVerifiedCreator) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: AppColors.amberOrangeLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.profileVerifiedCreator,
                        style: const TextStyle(
                          color: AppColors.amberOrangeLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatPill(label: l10n.profileScore, value: generalScore),
                    const SizedBox(width: 12),
                    _StatPill(
                      label: l10n.profileHonestyPoints,
                      value: honestyPoints,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  l10n.profileShareCardCta,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profileLink,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    ),
  );
}

/// Plain, non-network initials fallback matching UserAvatar's own
/// [_InitialsAvatar] visuals — duplicated only because that class is
/// private to user_avatar.dart; kept trivial and purely presentational so
/// this doesn't constitute a second avatar *system* (no URL-resolution or
/// premium logic lives here, only a glyph).
class ShareCardInitialsAvatar extends StatelessWidget {
  const ShareCardInitialsAvatar({super.key, this.displayName});
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final initial = displayName?.isNotEmpty == true
        ? displayName![0].toUpperCase()
        : '?';
    return Container(
      color: AppColors.brandPurpleDark,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 46,
          ),
        ),
      ),
    );
  }
}

/// Same SVG-vs-raster branch UserAvatar uses, adapted to a pre-fetched
/// SVG string / byte payload so the RepaintBoundary snapshot never races a
/// network load (see _loadAvatarWidget in profile_share.dart).
class ShareCardSvgAvatar extends StatelessWidget {
  const ShareCardSvgAvatar({super.key, required this.svgString});
  final String svgString;

  @override
  Widget build(BuildContext context) => SvgPicture(
    SvgStringLoader(svgString),
    width: 128,
    height: 128,
    fit: BoxFit.cover,
  );
}
