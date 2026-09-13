import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/packs/domain/pack_entity.dart';
import 'j_card.dart';

/// Compact horizontal-carousel pack card shared by both profile screens
/// (ProfileScreen's own-profile packs, UserProfileScreen's other-user
/// packs). See PackCard (pack_card_widget.dart) for the FULL marketplace/
/// Discover grid tile (rating, price, promoted/spicy/official badges) —
/// that one doesn't fit this compact horizontal strip's size, so this is
/// a deliberately smaller sibling sharing the same "cover on top, name in
/// its own card section below — never a background behind the text"
/// design language, not a competing implementation.
///
/// Root cause this widget fixes/consolidates: three independent pack-card
/// implementations existed across the app before this — ProfileScreen had
/// a bare Image+Text Column with no card container around either (the
/// exact "name looks detached from the card" bug this replaces),
/// UserProfileScreen had its own separate bordered-Container card, and
/// neither reused ImageCacheService's signed/cached cover fetch + built-in
/// empty-cover fallback (PackCard's own mechanism). Extracted here so both
/// profile screens render identically and any future card-language change
/// only needs one edit.
class ProfilePackCard extends StatelessWidget {
  const ProfilePackCard({
    super.key,
    required this.pack,
    required this.onTap,
    this.width = 104,
    this.coverHeight = 82,
    this.showStats = false,
  });

  final PackEntity pack;
  final VoidCallback onTap;
  final double width;
  final double coverHeight;

  /// Rating + play-count row, shown under the name. Off by default — the
  /// own-profile card is cover+name only by design. UserProfileScreen
  /// turns this on to preserve the rating/plays info its previous card
  /// already showed (removing it would be removing useful information).
  final bool showStats;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final rawTitle = pack.titleFor(
      Localizations.localeOf(context).languageCode,
    );
    final displayTitle = rawTitle.isNotEmpty
        ? rawTitle
        : context.l10n.defaultPackName;

    return SizedBox(
      width: width,
      child: JCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // borderRadius: 0 — the outer JCard's own Material clips its
            // child to the card's rounded rect, so the cover's top corners
            // already come out rounded without a second, redundant clip.
            ImageCacheService.instance.packCover(
              url: pack.coverImageUrl,
              width: width,
              height: coverHeight,
              borderRadius: 0,
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayTitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showStats) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: AppColors.amberOrangeLight,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            pack.avgRating.toStringAsFixed(1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.videogame_asset_rounded,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '${pack.totalPlays}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
