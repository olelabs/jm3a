/// App-wide constant values. No magic numbers in feature code.
abstract final class AppConstants {
  static const int maxRoomPlayers    = 12;
  static const int minPackCards      = 50;
  static const int maxPackCards      = 100;
  static const int otpLength         = 6;
  static const int otpTtlSeconds     = 300;
  static const int packAccessMonths  = 3;
  static const int minWithdrawalMru  = 500;
  static const double platformCommission = 0.15;
  static const int chatMaxLength     = 500;
  static const int bioMaxLength      = 280;
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 30;
  static const int reconnectGraceSeconds = 30;

  /// A paid pack (price_mru > 0) must be priced at least this much — a
  /// price of 0 (free) is unaffected. Mirrored server-side by packRoutes.js
  /// (_validatePriceFloor) and by the packs_price_mru_check DB constraint
  /// (supabase/migrations/20260811090000_pack_min_price.sql) — this is the
  /// single source of truth all three read from conceptually, even though
  /// Dart/JS/SQL can't literally share one constant.
  static const int minPaidPackPriceMru = 300;

  /// Universal/App Link host for room invites — must match the
  /// assetlinks.json (Android) / apple-app-site-association (iOS) files
  /// hosted at this domain's /.well-known/ path, and the intent-filter /
  /// associated-domains entries in the native platform configs. The
  /// jma3a:// custom scheme (see DeepLinkService) still works as an
  /// internal-routing fallback, but every SHARED link must use this HTTPS
  /// host so it renders as a tappable link in WhatsApp/SMS/etc., and so it
  /// still lands the user somewhere useful (the website) when the app
  /// isn't installed.
  static const String inviteWebHost = 'jma3a.com';

  static String roomInviteUrl({required String code, required String invitedBy}) =>
      'https://$inviteWebHost/join?code=$code&invited_by=$invitedBy';

  /// Profile sharing correction pass — same host, same HTTPS-over-custom-
  /// scheme reasoning as [roomInviteUrl] (a jma3a:// link renders as
  /// plain, non-tappable text in WhatsApp/SMS/etc.). [userId] is the
  /// profile's id — already the exact identifier `/user/:userId`
  /// (UserProfileScreen) uses for viewing another user's profile
  /// in-app, and already shown to any user who can already see that
  /// profile; nothing more sensitive than what in-app browsing already
  /// exposes goes into this link (no email, phone, or auth identifier).
  static String profileShareUrl(String userId) => 'https://$inviteWebHost/profile/$userId';
}
