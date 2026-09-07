import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/image_cache_service.dart';
import '../../../../core/theme/app_colors.dart';
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

/// Horizontal carousel of currently-active promoted_packs rows. Shared
/// between the marketplace's Featured tab and the Room Browser so both
/// render promotions identically instead of maintaining two copies —
/// [packs] is expected to already be filtered to active promotions
/// (PackProvider.promotedPacks), so this widget does no fetching of its
/// own and never affects whatever paginated list it's placed above.
class PromotedPacksCarousel extends StatelessWidget {
  const PromotedPacksCarousel({super.key, required this.packs});
  final List<PackEntity> packs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: packs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final pack = packs[i];
          return GestureDetector(
            onTap: () => AppRouter.router.push(
              '${RouteNames.marketplace}/pack/${pack.id}',
            ),
            child: Container(
              width: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navyBlue, AppColors.navyBlueLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  if (pack.coverImageUrl != null)
                    ImageCacheService.instance.packCover(
                      url: pack.coverImageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 16,
                      color: Colors.black.withValues(alpha: 0.35),
                      colorBlendMode: BlendMode.darken,
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Jma3a',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amberOrangeLight.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            context.l10n.packPromotedBadge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _displayTitle(context, pack),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate(delay: (i * 40).ms).fadeIn().slideX(begin: 0.08, end: 0),
          );
        },
      ),
    );
  }
}
