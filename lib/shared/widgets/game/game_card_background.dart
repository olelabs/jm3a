import 'package:flutter/material.dart';

import '../../../core/services/image_url_signer.dart';

/// Resolves and renders the background image for an in-game prompt card
/// (NHIE's question card, Meme's prompt card), with a single, centralized
/// fallback chain so `jma3a_card_cover_playful.png` is referenced in
/// exactly one place instead of once per screen:
///
///   1. [imageUrl] — the specific pack/card's own cover, if it has one.
///      Resolved through [ImageUrlSigner] first — this is a stored Wasabi
///      object reference (kept private, not made public), not directly
///      viewable, same as a pack's own cover image.
///   2. `assets/images/backgrounds/jma3a_card_cover_playful.png` — the
///      shared default game-card background asset.
///   3. [fallbackColor] — a flat color, only if the bundled asset itself
///      somehow fails to load (stripped build, etc).
///
/// Purely presentational — never chooses which pack/card is active, never
/// touches game state.
class GameCardBackground extends StatefulWidget {
  const GameCardBackground({
    super.key,
    required this.imageUrl,
    required this.fallbackColor,
  });

  final String? imageUrl;
  final Color fallbackColor;

  @override
  State<GameCardBackground> createState() => _GameCardBackgroundState();
}

class _GameCardBackgroundState extends State<GameCardBackground> {
  static const _defaultAsset =
      'assets/images/backgrounds/jma3a_card_cover_playful.png';

  late Future<String?> _future = ImageUrlSigner.instance.sign(widget.imageUrl);

  @override
  void didUpdateWidget(GameCardBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _future = ImageUrlSigner.instance.sign(widget.imageUrl);
    }
  }

  Widget _defaultOrFallback() => Image.asset(
    _defaultAsset,
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
    errorBuilder: (_, _, _) => Container(color: widget.fallbackColor),
  );

  @override
  Widget build(BuildContext context) {
    final hasCover = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;
    if (!hasCover) return _defaultOrFallback();
    return FutureBuilder<String?>(
      future: _future,
      builder: (context, snapshot) {
        final resolvedUrl = snapshot.data ?? widget.imageUrl!;
        return Image.network(
          resolvedUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => _defaultOrFallback(),
        );
      },
    );
  }
}
