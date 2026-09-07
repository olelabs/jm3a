import 'package:flutter/material.dart';

import '../../../core/services/image_url_signer.dart';

/// Drop-in replacement for `Image.network(url)` when [url] may be a stored
/// Wasabi object reference (pack cover, card image, sticker) — the bucket
/// rejects unauthenticated GETs (kept private, not made public), so the
/// raw stored value isn't directly viewable. Resolves a signed URL via
/// [ImageUrlSigner] (cached ~50 min) before rendering; an external URL
/// (e.g. a stock-photo cover) is returned unchanged by the signing
/// endpoint, so this is safe to use unconditionally on any pack-related
/// image URL. Keeps each call site's own placeholder/error chrome instead
/// of imposing one, unlike [ImageCacheService.packCover] which is a full
/// pre-built pack-card widget.
class SignedNetworkImage extends StatefulWidget {
  const SignedNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.errorBuilder,
    this.loadingBuilder,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Color? color;
  final BlendMode? colorBlendMode;
  final WidgetBuilder? errorBuilder;
  final WidgetBuilder? loadingBuilder;

  @override
  State<SignedNetworkImage> createState() => _SignedNetworkImageState();
}

class _SignedNetworkImageState extends State<SignedNetworkImage> {
  late Future<String?> _future = ImageUrlSigner.instance.sign(widget.url);

  @override
  void didUpdateWidget(SignedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _future = ImageUrlSigner.instance.sign(widget.url);
    }
  }

  Widget _loading(BuildContext context) =>
      widget.loadingBuilder?.call(context) ??
      SizedBox(width: widget.width, height: widget.height);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _loading(context);
        return Image.network(
          snapshot.data!,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          color: widget.color,
          colorBlendMode: widget.colorBlendMode,
          errorBuilder: (_, _, _) =>
              widget.errorBuilder?.call(context) ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
