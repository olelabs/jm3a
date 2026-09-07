import '../../features/packs/data/pack_repository.dart';
import '../utils/app_logger.dart';

/// Client-side cache + batching in front of [PackRepository.signImageUrls].
/// The server signs for 1 hour; cached here for 50 minutes to leave margin
/// so a URL never expires mid-render. A signing failure (offline, server
/// error) falls back to the raw, unsigned URL rather than throwing — the
/// caller's own image widget already has its own placeholder/error
/// handling for a URL that turns out not to load.
class ImageUrlSigner {
  ImageUrlSigner._();
  static final ImageUrlSigner instance = ImageUrlSigner._();

  /// Test-only constructor: injects the actual network call and clock so
  /// the caching/batching logic below is testable without a live
  /// Supabase/API connection (this codebase has no injectable mock seam
  /// on PackRepository itself, being a Supabase-backed singleton).
  ImageUrlSigner.forTest({
    required Future<Map<String, String>> Function(List<String>) fetch,
    DateTime Function()? now,
  }) : _fetch = fetch,
       _now = now ?? DateTime.now;

  Future<Map<String, String>> Function(List<String>) _fetch =
      (urls) => PackRepository.instance.signImageUrls(urls);
  DateTime Function() _now = DateTime.now;

  final Map<String, _CacheEntry> _cache = {};
  static const _cacheDuration = Duration(minutes: 50);

  /// Resolves one URL. Prefer [signAll] when resolving several at once
  /// (e.g. a list of packs) to batch them into a single request.
  Future<String?> sign(String? url) async {
    if (url == null || url.isEmpty) return url;
    final resolved = await signAll([url]);
    return resolved[url] ?? url;
  }

  Future<Map<String, String>> signAll(List<String> urls) async {
    final now = _now();
    final result = <String, String>{};
    final toFetch = <String>[];

    for (final url in urls.toSet()) {
      final cached = _cache[url];
      if (cached != null && cached.expiresAt.isAfter(now)) {
        result[url] = cached.signedUrl;
      } else {
        toFetch.add(url);
      }
    }

    if (toFetch.isNotEmpty) {
      try {
        final signed = await _fetch(toFetch);
        final expiresAt = now.add(_cacheDuration);
        for (final url in toFetch) {
          final signedUrl = signed[url] ?? url;
          result[url] = signedUrl;
          _cache[url] = _CacheEntry(signedUrl, expiresAt);
        }
      } catch (e) {
        AppLogger.debug('ImageUrlSigner: signing failed, using raw URLs — $e');
        for (final url in toFetch) {
          result[url] = url;
        }
      }
    }

    return result;
  }
}

class _CacheEntry {
  const _CacheEntry(this.signedUrl, this.expiresAt);
  final String signedUrl;
  final DateTime expiresAt;
}
