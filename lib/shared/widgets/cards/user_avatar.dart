import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/j_theme_extension.dart';

/// UserAvatar with presence indicator using JThemeExtension tokens
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.size,
    this.displayName,
    this.showOnlineStatus  = false,
    this.isOnline          = false,
    this.isInGame          = false,
    this.onTap,
    this.borderWidth       = 0,
    this.borderColor,
  });

  final String? avatarUrl;
  final double  size;
  final String? displayName;
  final bool    showOnlineStatus;
  final bool    isOnline;
  final bool    isInGame;
  final VoidCallback? onTap;
  final double  borderWidth;
  final Color?  borderColor;

  @override
  Widget build(BuildContext context) {
    final jc = context.jColors;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width:  size, height: size,
            decoration: BoxDecoration(
              shape:  BoxShape.circle,
              border: borderWidth > 0
                  ? Border.all(
                      color: borderColor ?? Theme.of(context).colorScheme.surface,
                      width: borderWidth)
                  : null,
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _InitialsAvatar(displayName: displayName, size: size),
                    )
                  : _InitialsAvatar(displayName: displayName, size: size),
            ),
          ),
          if (showOnlineStatus)
            Positioned(
              right: -1, bottom: -1,
              child: _PresenceDot(
                size:  size * 0.28,
                color: isInGame  ? jc.inGameDot
                     : isOnline  ? jc.onlineDot
                     :              jc.offlineDot,
              ),
            ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({this.displayName, required this.size});
  final String? displayName;
  final double  size;

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final initial = displayName?.isNotEmpty == true
        ? displayName![0].toUpperCase() : '?';
    return Container(
      color: cs.primaryContainer,
      child: Center(
        child: Text(initial, style: TextStyle(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        )),
      ),
    );
  }
}

class _PresenceDot extends StatelessWidget {
  const _PresenceDot({required this.size, required this.color});
  final double size;
  final Color  color;

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(
          color: Theme.of(context).colorScheme.surface, width: 1.5),
    ),
  );
}

/// Row of stacked avatars — room member preview
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.avatarUrls,
    required this.size,
    this.maxVisible = 4,
    this.overlap    = 0.35,
  });

  final List<String?> avatarUrls;
  final double        size;
  final int           maxVisible;
  final double        overlap;

  @override
  Widget build(BuildContext context) {
    final visible   = avatarUrls.take(maxVisible).toList();
    final extra     = avatarUrls.length - maxVisible;
    final itemWidth = size * (1 - overlap);
    final totalWidth = size + (visible.length - 1) * itemWidth
        + (extra > 0 ? itemWidth : 0);

    return SizedBox(
      width: totalWidth, height: size,
      child: Stack(children: [
        for (var i = 0; i < visible.length; i++)
          Positioned(
            left: i * itemWidth,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Theme.of(context).colorScheme.surface, width: 1.5),
              ),
              child: UserAvatar(avatarUrl: visible[i], size: size),
            ),
          ),
        if (extra > 0)
          Positioned(
            left: visible.length * itemWidth,
            child: Container(
              width: size, height: size,
              decoration: BoxDecoration(
                color:  Theme.of(context).colorScheme.surfaceContainerHighest,
                shape:  BoxShape.circle,
                border: Border.all(
                    color: Theme.of(context).colorScheme.surface, width: 1.5),
              ),
              child: Center(
                child: Text('+$extra',
                    style: TextStyle(fontWeight: FontWeight.w700,
                        fontSize: size * 0.28)),
              ),
            ),
          ),
      ]),
    );
  }
}
