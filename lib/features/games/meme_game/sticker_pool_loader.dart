import 'package:flutter/widgets.dart';

import '../../../core/utils/app_logger.dart';

/// Sticker preloading correction pass.
///
/// Fetched and precached ONCE for this loader's whole lifetime (one
/// Meme game session — MemeGameProvider owns exactly one instance for as
/// long as the game route is on screen), never re-fetched per round the
/// way it used to be: _SubmitScreenState previously called
/// PackRepository.getPackReactions/getPackStickers fresh every time it
/// mounted for a new prompt, re-downloading and re-signing the exact
/// same pack-level pool round after round. [_future] memoizes the
/// in-flight/completed fetch so every caller (the game-start preload
/// trigger and every round's submit screen alike) shares one result
/// instead of racing separate requests.
///
/// [fetch] is injected (rather than this class calling PackRepository/
/// ImageUrlSigner itself) purely so the memoization/precache behavior
/// can be unit-tested without a live Supabase client — MemeGameProvider
/// wires it to the real fetch-and-sign chain.
class StickerPoolLoader {
  StickerPoolLoader({required Future<List<String>> Function(String packId) fetch}) : _fetch = fetch;

  final Future<List<String>> Function(String packId) _fetch;

  Future<List<String>>? _future;
  List<String> _pool = const [];
  List<String> get pool => _pool;
  bool _precached = false;
  bool get isPrecached => _precached;

  Future<List<String>> load(String packId) {
    return _future ??= _loadAndStore(packId);
  }

  Future<List<String>> _loadAndStore(String packId) async {
    try {
      final urls = await _fetch(packId);
      _pool = urls;
      return urls;
    } catch (e) {
      AppLogger.warning('StickerPoolLoader: failed to load pool for $packId: $e');
      _pool = const [];
      return const [];
    }
  }

  /// Pre-caches every sticker image (PNG/JPEG/WebP/GIF alike —
  /// precacheImage decodes and caches the full codec regardless of
  /// format; an animated GIF's multi-frame codec is cached the same way
  /// a static image's single frame is, so playback is unaffected once
  /// Image.network actually renders it later from the same cache) so a
  /// submit screen's sticker grid never shows a blank placeholder for an
  /// image that simply hasn't finished its own individual network fetch
  /// yet. Each image is precached independently — one failed URL (dead
  /// link, expired signature) is caught per-image and never aborts the
  /// rest of the pool.
  Future<void> precache(BuildContext context) async {
    if (_precached) return;
    final urls = await (_future ?? Future.value(_pool));
    if (!context.mounted || urls.isEmpty) {
      _precached = true;
      return;
    }
    await Future.wait([
      for (final url in urls)
        precacheImage(NetworkImage(url), context).catchError((Object e) {
          AppLogger.warning('StickerPoolLoader: failed to precache $url: $e');
        }),
    ]);
    _precached = true;
  }
}
