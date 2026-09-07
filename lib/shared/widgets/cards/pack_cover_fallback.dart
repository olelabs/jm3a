import 'package:flutter/material.dart';

/// The single "no cover uploaded" visual for a pack, used everywhere a
/// pack's cover is rendered — marketplace grid cards, pack detail's hero
/// image, and anywhere else a cover slot exists. CORRECTION PASS §3: a
/// cover image is optional, and before this widget existed each screen
/// had grown its own slightly different placeholder (an emoji switch in
/// PackCard's `_PlaceholderCover`, a DIFFERENT emoji switch inline in
/// pack_detail_screen.dart's FlexibleSpaceBar) — exactly the "same asset
/// duplicated inconsistently" the brief warns against. This is now the
/// one place `jma3a_card_cover_playful.png` is referenced for pack-cover
/// (as opposed to in-game-card) contexts, mirroring
/// GameCardBackground's own fallback asset for the in-game case (same
/// bundled file, deliberately not re-exported from there since that
/// widget also does the ImageUrlSigner/live-cover resolution this one
/// intentionally does NOT — callers here already own the "has a real
/// cover" branch via ImageCacheService for caching, this widget is only
/// ever the ELSE branch).
class PackCoverFallback extends StatelessWidget {
  const PackCoverFallback({super.key, this.fit = BoxFit.cover});

  final BoxFit fit;

  static const _defaultAsset =
      'assets/images/backgrounds/jma3a_card_cover_playful.png';

  @override
  Widget build(BuildContext context) => Image.asset(
    _defaultAsset,
    fit: fit,
    width: double.infinity,
    height: double.infinity,
    errorBuilder: (context, error, stackTrace) => Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
  );
}
