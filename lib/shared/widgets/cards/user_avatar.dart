import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/j_theme_extension.dart';
import '../../../features/avatar/presentation/avatar_creator_screen.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.size,
    this.displayName,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.isInGame = false,
    this.onTap,
    this.borderWidth = 0,
    this.borderColor,
    this.avatarConfig,
    this.isPremium = false,
    this.avatarReactionKey,
    this.isOfficial = false,
    this.isBackgroundedAway = false,
  });

  final String? avatarUrl;
  final double size;
  final String? displayName;
  final bool showOnlineStatus;
  final bool isOnline;
  final bool isInGame;
  final VoidCallback? onTap;
  final double borderWidth;
  final Color? borderColor;
  final Map<String, dynamic>? avatarConfig;
  final bool isPremium;

  /// The official Jma3a system creator profile (profiles.is_official_account)
  /// — renders the bundled Jma3a logo instead of avatarUrl/initials,
  /// regardless of what those are set to. Takes priority over every other
  /// avatar source; there's never a meaningful avatarUrl/avatarConfig for
  /// this account (see jma3a-api/scripts/createOfficialCreatorAccount.js).
  final bool isOfficial;

  /// Optional generated-avatar reaction expression (e.g. 'laugh', 'fire' —
  /// see AvatarConfig.reactionExpressions). Only has an effect for a
  /// premium generated avatar (isPremium + avatarConfig); everywhere else
  /// this is null and rendering is unchanged. Kept here instead of a
  /// separate widget so avatar reactions (floating or static) go through
  /// the exact same URL-resolution/SVG-vs-raster/fallback logic as every
  /// other avatar in the app, and automatically pick up frames/borders/
  /// future avatar features without a second implementation to maintain.
  final String? avatarReactionKey;

  /// Premium Plus "away from app while in this room/game" indicator — a
  /// small coffee-cup badge, distinct from the online/in-game/offline dot
  /// below. Callers are responsible for gating this to Premium Plus
  /// members only (see PresenceService.UserPresenceStatus.backgrounded);
  /// this widget just renders whatever it's told.
  final bool isBackgroundedAway;

  String? get _resolvedUrl {
    if (isPremium && avatarConfig != null && avatarConfig!.isNotEmpty) {
      final cfg = AvatarConfig.fromMap(avatarConfig!);
      return avatarReactionKey != null
          ? cfg.reactionUrl(avatarReactionKey!)
          : cfg.avatarUrl;
    }
    return avatarUrl;
  }

  @override
  Widget build(BuildContext context) {
    final jc = context.jColors;
    final url = _resolvedUrl;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: borderWidth > 0
                  ? Border.all(
                      color:
                          borderColor ?? Theme.of(context).colorScheme.surface,
                      width: borderWidth,
                    )
                  : null,
            ),
            child: ClipOval(
              child: isOfficial
                  ? _OfficialLogoAvatar(size: size)
                  : url != null && url.contains('avataaars.io')
                  ? SvgPicture.network(
                      url,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      headers: const {'Accept': 'image/svg+xml'},
                      placeholderBuilder: (_) =>
                          _InitialsAvatar(displayName: displayName, size: size),
                    )
                  : url != null
                  ? Image.network(
                      url,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _InitialsAvatar(displayName: displayName, size: size),
                    )
                  : _InitialsAvatar(displayName: displayName, size: size),
            ),
          ),
          if (showOnlineStatus)
            Positioned(
              right: -1,
              bottom: -1,
              child: _PresenceDot(
                size: size * 0.28,
                color: isInGame
                    ? jc.inGameDot
                    : isOnline
                    ? jc.onlineDot
                    : jc.offlineDot,
              ),
            ),
          if (isBackgroundedAway)
            Positioned(left: -2, top: -2, child: _AwayBadge(size: size * 0.34)),
        ],
      ),
    );
  }
}

class _OfficialLogoAvatar extends StatelessWidget {
  const _OfficialLogoAvatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.brandPurpleMid,
    padding: EdgeInsets.all(size * 0.2),
    child: Image.asset(
      'assets/images/backgrounds/jma3a_logo_white.png',
      fit: BoxFit.contain,
    ),
  );
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({this.displayName, required this.size});
  final String? displayName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = displayName?.isNotEmpty == true
        ? displayName![0].toUpperCase()
        : '?';
    return Container(
      color: cs.primaryContainer,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.38,
          ),
        ),
      ),
    );
  }
}

class _PresenceDot extends StatelessWidget {
  const _PresenceDot({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(
        color: Theme.of(context).colorScheme.surface,
        width: 1.5,
      ),
    ),
  );
}

/// Small coffee-cup badge for [UserAvatar.isBackgroundedAway] — deliberately
/// tiny and unobtrusive (per the "not a large disruptive badge" design
/// requirement), same visual weight as [_PresenceDot].
class _AwayBadge extends StatelessWidget {
  const _AwayBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.amberOrangeLight,
      shape: BoxShape.circle,
      border: Border.all(
        color: Theme.of(context).colorScheme.surface,
        width: 1.5,
      ),
    ),
    child: Icon(Icons.coffee_rounded, size: size * 0.62, color: Colors.white),
  );
}

class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.avatarUrls,
    required this.size,
    this.maxVisible = 4,
    this.overlap = 0.35,
  });

  final List<String?> avatarUrls;
  final double size;
  final int maxVisible;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final visible = avatarUrls.take(maxVisible).toList();
    final extra = avatarUrls.length - maxVisible;
    final itemWidth = size * (1 - overlap);
    final totalWidth =
        size + (visible.length - 1) * itemWidth + (extra > 0 ? itemWidth : 0);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * itemWidth,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 1.5,
                  ),
                ),
                child: UserAvatar(avatarUrl: visible[i], size: size),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: visible.length * itemWidth,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: size * 0.28,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
