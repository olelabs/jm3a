import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../config/app_config.dart';

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

  /// Pack cover image widget with rounded corners.
  Widget packCover({
    required String? url,
    required double width,
    required double height,
    double borderRadius = 12,
  }) {
    if (url == null || url.isEmpty) {
      return _packPlaceholder(width, height, borderRadius);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        cacheKey: _cacheKey(url),
        placeholder: (_, __) => _packShimmer(width, height),
        errorWidget: (_, __, ___) => _packPlaceholder(width, height, borderRadius),
      ),
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

  Widget _packPlaceholder(double width, double height, double radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const Icon(Icons.photo_library_outlined),
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
