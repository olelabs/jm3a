import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import 'image_url_signer.dart';

/// Centralized image caching configuration and factory methods.
///
/// All image display in the app goes through this service to ensure
/// consistent placeholder, error state, and cache key behavior.
class ImageCacheService {
  ImageCacheService._();
  static final ImageCacheService _instance = ImageCacheService._();
  static ImageCacheService get instance => _instance;

  void configure() {
    // Flutter's in-memory image cache
    PaintingBinding.instance.imageCache
      ..maximumSize = 1000
      ..maximumSizeBytes = 200 * 1024 * 1024; // 200MB
  }

  // ── Pre-built image widgets ────────────────────────────────────────────

  /// User avatar widget with circular clip.
  Widget avatar({
    required String? url,
    required double size,
    Widget? placeholder,
  }) {
    if (url == null || url.isEmpty) {
      return _avatarPlaceholder(size);
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheKey: _cacheKey(url),
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: size / 2,
        backgroundImage: imageProvider,
      ),
      placeholder: (_, __) => placeholder ?? _avatarShimmer(size),
      errorWidget: (_, __, ___) => _avatarPlaceholder(size),
      memCacheWidth: (size * 2).toInt(), // 2x for retina
    );
  }

  /// Pack cover image widget with rounded corners. [color]/[colorBlendMode]
  /// are for callers that need a tint/darken overlay (e.g. a promoted
  /// banner with text on top) without falling back to a raw `Image.network`
  /// that skips caching/placeholder/error handling entirely.
  ///
  /// [url] is the raw value stored on the pack row — a Wasabi object
  /// reference the bucket won't serve unsigned (kept private, not made
  /// public), or occasionally an external URL (e.g. a stock-photo cover),
  /// which a signing request passes through unchanged. Resolved once via
  /// [ImageUrlSigner] (cached ~50 min) before the actual `CachedNetworkImage`
  /// mounts, so every caller gets this for free without touching its own
  /// call site.
  Widget packCover({
    required String? url,
    required double width,
    required double height,
    double borderRadius = 12,
    Color? color,
    BlendMode? colorBlendMode,
  }) {
    if (url == null || url.isEmpty) {
      return _packPlaceholder(width, height, borderRadius);
    }

    return _SignedPackCover(
      url: url,
      width: width,
      height: height,
      borderRadius: borderRadius,
      color: color,
      colorBlendMode: colorBlendMode,
    );
  }

  // ── Cache key ────────────────────────────────────────────────────────
  /// Strip query params — Wasabi URLs include version hashes in the path,
  /// so the URL itself is a stable cache key without query parameters.
  String _cacheKey(String url) => url.split('?').first;

  // ── Placeholders ───────────────────────────────────────────────────────
  Widget _avatarPlaceholder(double size) {
    return CircleAvatar(
      radius: size / 2,
      child: Icon(Icons.person_rounded, size: size * 0.55),
    );
  }

  Widget _avatarShimmer(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  /// Branded Jma3a cover fallback — shown for a missing/empty cover URL AND
  /// for any load failure (offline, timeout, 404, invalid URL). A designed,
  /// on-brand gradient card with the Jma3a mark, never the generic
  /// broken-image / grey box. Purely local (gradient + a bundled asset), so
  /// it renders identically whether the device is online or offline.
  Widget _packPlaceholder(double width, double height, double radius) {
    // Scale the mark to the smaller side so it never overflows a thin cover.
    final shortest = width.isFinite && height.isFinite
        ? (width < height ? width : height)
        : 96.0;
    final markSize = shortest.clamp(24.0, 200.0) * 0.42;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandPurpleMid, AppColors.brandBlueMid],
        ),
      ),
      child: Center(
        child: Image.asset(
          'assets/images/backgrounds/jma3a_logo_white.png',
          width: markSize * 1.6,
          height: markSize * 1.6,
          fit: BoxFit.contain,
          opacity: const AlwaysStoppedAnimation(0.92),
          // Bundled assets don't 404, but guard defensively so a stripped
          // build still shows an on-brand mark rather than a broken box.
          errorBuilder: (_, _, _) => Icon(
            Icons.style_rounded,
            color: Colors.white.withValues(alpha: 0.92),
            size: markSize,
          ),
        ),
      ),
    );
  }

  Widget _packShimmer(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
    );
  }
}

/// Resolves [url] via [ImageUrlSigner] before mounting the actual
/// `CachedNetworkImage` — shows the same shimmer placeholder while
/// resolving as `CachedNetworkImage` shows while loading, so there's no
/// visible difference from the caller's point of view versus the
/// previous synchronous implementation.
class _SignedPackCover extends StatefulWidget {
  const _SignedPackCover({
    required this.url,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.color,
    required this.colorBlendMode,
  });

  final String url;
  final double width;
  final double height;
  final double borderRadius;
  final Color? color;
  final BlendMode? colorBlendMode;

  @override
  State<_SignedPackCover> createState() => _SignedPackCoverState();
}

class _SignedPackCoverState extends State<_SignedPackCover> {
  late Future<String?> _future = ImageUrlSigner.instance.sign(widget.url);

  @override
  void didUpdateWidget(_SignedPackCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _future = ImageUrlSigner.instance.sign(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ImageCacheService.instance;
    return FutureBuilder<String?>(
      future: _future,
      builder: (context, snapshot) {
        final resolvedUrl = snapshot.data ?? widget.url;
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: CachedNetworkImage(
            imageUrl: resolvedUrl,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.cover,
            color: widget.color,
            colorBlendMode: widget.colorBlendMode,
            cacheKey: service._cacheKey(widget.url),
            placeholder: (_, __) => service._packShimmer(widget.width, widget.height),
            errorWidget: (_, __, ___) =>
                service._packPlaceholder(widget.width, widget.height, widget.borderRadius),
          ),
        );
      },
    );
  }
}
