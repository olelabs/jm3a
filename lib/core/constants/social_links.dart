/// Centralized official Jma3a social account links — the single place a
/// real handle/URL should be filled in once one exists, so nothing in the
/// UI ever hardcodes a social URL directly.
///
/// IMPORTANT: as of this file's creation, no real TikTok, Snapchat, or
/// Facebook account for Jma3a exists anywhere else in this project (no
/// constants, config, launch links, or app-store listing metadata
/// reference one). These are intentionally left empty rather than
/// invented — [AboutUsScreen]'s social tiles only render as tappable once
/// a non-empty URL is filled in here; see its own doc comment.
abstract final class SocialLinks {
  /// TODO: fill in with the real official Jma3a TikTok profile URL.
  static const String tiktok = '';

  /// TODO: fill in with the real official Jma3a Snapchat profile URL.
  static const String snapchat = '';

  /// TODO: fill in with the real official Jma3a Facebook page URL.
  static const String facebook = '';
}
