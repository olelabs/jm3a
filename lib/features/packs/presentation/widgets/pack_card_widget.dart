import 'package:flutter/material.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/services/image_cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/cards/pack_cover_fallback.dart';
import '../../domain/pack_entity.dart';

/// The pack's own title in the viewer's language if available, else in the
/// pack's declared language, else in whatever language it actually has —
/// [PackEntity.titleFor] never returns a raw id. Only truly empty title
/// data (a corrupt/incomplete pack row) falls through to the generic
/// localized "Pack" placeholder — never the pack's UUID.
String _displayTitle(BuildContext context, PackEntity pack) {
  final title = pack.titleFor(Localizations.localeOf(context).languageCode);
  return title.isNotEmpty ? title : context.l10n.defaultPackName;
}

/// Pack card for marketplace grid views.
/// Shows: cover image, title, rating, price/owned badge, spicy flag.
class PackCard extends StatelessWidget {
  const PackCard({
    super.key,
    required this.pack,
    required this.onTap,
    this.isOwned = false,
    this.downloadState,
  });

  final PackEntity pack;
  final VoidCallback onTap;
  final bool isOwned;
  final PackDownloadState? downloadState;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return JCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: pack.coverImageUrl != null
                      ? ImageCacheService.instance.packCover(
                          url: pack.coverImageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 0,
                        )
                      : const PackCoverFallback(),
                ),

                // Promoted badge
                if (pack.isPromoted)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amberOrangeLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.l10n.packProBadge,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Spicy badge
                if (pack.hasSpicy)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.spicyColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('🌶', style: TextStyle(fontSize: 10)),
                    ),
                  ),

                // Official Jma3a-managed pack badge — same corner-badge
                // pattern as Promoted/Spicy above, bottom-left so it never
                // collides with the offline-download badge (bottom-right).
                if (pack.isOfficialCreator)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPurpleMid,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            context.l10n.packOfficialBadge,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Offline available badge
                if (downloadState?.isDownloaded == true)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.offline_pin_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Pack info
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayTitle(context, pack),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    // Rating
                    if (pack.avgRating > 0) ...[
                      Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: AppColors.amberOrangeLight,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        pack.avgRating.toStringAsFixed(1),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],

                    // Card count
                    Icon(
                      Icons.layers_rounded,
                      size: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${pack.cardCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const Spacer(),

                    // Price / owned badge
                    if (isOwned)
                      _Badge(
                        label: context.l10n.packOwnedBadge,
                        color: AppColors.successGreen,
                      )
                    else
                      Text(
                        pack.isFree
                            ? context.l10n.packFreeLabel
                            : context.l10n.packPriceMru(pack.priceMru),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: pack.isFree
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


class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
