import 'package:flutter/material.dart';
import 'package:jma3a/core/theme/app_text_styles.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';

/// ═══════════════════════════════════════════════════════════════
/// JCard — Standard card container
/// ═══════════════════════════════════════════════════════════════
class JCard extends StatelessWidget {
  const JCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.radius,
    this.shadows,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final double? radius;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor =
        color ?? (isDark ? AppColors.darkSurface : AppColors.white);
    final effectiveBorder = borderColor ?? cs.outlineVariant;
    final effectiveRadius = radius ?? AppRadius.card;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(color: effectiveBorder, width: borderWidth),
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(effectiveRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(effectiveRadius),
          splashColor: cs.primary.withOpacity(0.06),
          highlightColor: cs.primary.withOpacity(0.04),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// JGradientCard — Card with branded gradient background
/// ═══════════════════════════════════════════════════════════════
class JGradientCard extends StatelessWidget {
  const JGradientCard({
    super.key,
    required this.child,
    required this.gradientColors,
    this.padding,
    this.radius,
    this.onTap,
    this.height,
    this.shadows,
  });

  final Widget child;
  final List<Color> gradientColors;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final VoidCallback? onTap;
  final double? height;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppRadius.xl.toDouble();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(r),
          boxShadow: shadows ?? AppShadows.elevated(gradientColors.first),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// JGameCard — Truth/Dare/NHIE content card
/// ═══════════════════════════════════════════════════════════════
class JGameCard extends StatelessWidget {
  const JGameCard({
    super.key,
    required this.content,
    required this.type,
    required this.typeLabel,
    required this.typeEmoji,
    required this.cardColor,
    this.isSpicy = false,
    this.difficulty,
    this.imageUrl,
  });

  final String content;
  final String type; // 'truth' | 'dare' | 'nhie' etc.
  final String typeLabel;
  final String typeEmoji;
  final Color cardColor;
  final bool isSpicy;
  final String? difficulty;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.prominent(cardColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: Stack(
          children: [
            // Subtle geometric decoration
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withOpacity(0.04),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge + spicy
                  Row(
                    children: [
                      _TypeBadge(label: typeLabel, emoji: typeEmoji),
                      if (isSpicy) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _SpicyBadge(),
                      ],
                      if (difficulty != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _DifficultyBadge(difficulty: difficulty!),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Main content
                  Flexible(
                    child: Text(
                      content,
                      style: AppTextStyles.gameCardContent(
                        color: AppColors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.emoji});
  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpicyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.spicyOrange,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: const Text(
        '🌶 SPICY',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final stars = difficulty == 'mild'
        ? '★'
        : difficulty == 'medium'
        ? '★★'
        : '★★★';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        stars,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// JPackCard — Marketplace pack card
/// ═══════════════════════════════════════════════════════════════
class JPackCard extends StatelessWidget {
  const JPackCard({
    super.key,
    required this.title,
    required this.coverUrl,
    required this.gameType,
    required this.cardCount,
    required this.priceMru,
    this.avgRating = 0,
    this.isOwned = false,
    this.isFeatured = false,
    this.isSpicy = false,
    this.onTap,
  });

  final String title;
  final String? coverUrl;
  final String gameType;
  final int cardCount;
  final int priceMru;
  final double avgRating;
  final bool isOwned;
  final bool isFeatured;
  final bool isSpicy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return JCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      shadows: AppShadows.card(theme.colorScheme.shadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image (aspect ratio 3:2)
          AspectRatio(
            aspectRatio: 3 / 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Cover / fallback
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.card),
                  ),
                  child: coverUrl != null
                      ? Image.network(
                          coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _PackCoverFallback(gameType: gameType),
                        )
                      : _PackCoverFallback(gameType: gameType),
                ),

                // Featured ribbon
                if (isFeatured)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ownerGold,
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: const Text(
                        '⭐ Featured',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                // Spicy flag
                if (isSpicy)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.spicyOrange,
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: const Text('🌶', style: TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm + 4,
              AppSpacing.sm,
              AppSpacing.sm + 4,
              AppSpacing.sm + 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    // Rating
                    if (avgRating > 0) ...[
                      Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: AppColors.ownerGold,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],

                    Icon(
                      Icons.layers_rounded,
                      size: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$cardCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const Spacer(),

                    // Price / owned
                    isOwned
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppRadius.badge,
                              ),
                            ),
                            child: Text(
                              'Owned',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.successGreen,
                              ),
                            ),
                          )
                        : Text(
                            priceMru == 0 ? 'Free' : '$priceMru MRU',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: priceMru == 0
                                  ? AppColors.successGreen
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackCoverFallback extends StatelessWidget {
  const _PackCoverFallback({required this.gameType});
  final String gameType;

  @override
  Widget build(BuildContext context) {
    final emoji = switch (gameType) {
      'truth_or_dare' => '🎯',
      'never_have_i_ever' => '🍹',
      'meme_game' => '😂',
      _ => '🎮',
    };
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 44))),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// ShimmerBox — Loading placeholder
/// ═══════════════════════════════════════════════════════════════
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final jc = Theme.of(context).extension<dynamic>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkElevated : AppColors.neutral200;
    final highlight = isDark ? AppColors.darkHighest : AppColors.neutral100;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// JRoomTile — Room browser list item
/// ═══════════════════════════════════════════════════════════════
class JRoomTile extends StatelessWidget {
  const JRoomTile({
    super.key,
    required this.roomName,
    required this.ownerName,
    required this.gameType,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.avatarUrls,
    this.isLocked = false,
    this.isPrivate = false,
    this.onTap,
    this.badge,
  });

  final String roomName;
  final String ownerName;
  final String gameType;
  final int currentPlayers;
  final int maxPlayers;
  final List<String?> avatarUrls;
  final bool isLocked;
  final bool isPrivate;
  final VoidCallback? onTap;
  final String? badge; // e.g. 'LIVE' | 'FULL' | 'JOINING'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = currentPlayers >= maxPlayers;
    final gameEmoji = switch (gameType) {
      'truth_or_dare' => '🎯',
      'never_have_i_ever' => '🍹',
      'meme_game' => '😂',
      _ => '🎮',
    };

    return JCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      child: Row(
        children: [
          // Game type emoji
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text(gameEmoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Room info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        roomName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLocked) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.lock_rounded,
                        size: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      _RoomBadge(label: badge!),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'by $ownerName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Player count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currentPlayers/$maxPlayers',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isFull
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'players',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomBadge extends StatelessWidget {
  const _RoomBadge({required this.label});
  final String label;

  Color _color(String l) => switch (l) {
    'LIVE' => AppColors.errorRed,
    'FULL' => AppColors.neutral500,
    'JOINING' => AppColors.successGreen,
    _ => AppColors.brandBlueElectric,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// JEmptyState — Empty/zero-data state
/// ═══════════════════════════════════════════════════════════════
class JEmptyState extends StatelessWidget {
  const JEmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.action,
    this.compact = false,
  });

  final String emoji;
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
