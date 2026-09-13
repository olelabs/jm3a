/// App-wide constant values. No magic numbers in feature code.
abstract final class AppConstants {
  static const int maxRoomPlayers = 12;
  static const int minPackCards = 50;
  static const int maxPackCards = 100;
  static const int otpLength = 6;
  static const int otpTtlSeconds = 300;
  static const int packAccessMonths = 3;
  static const int minWithdrawalMru = 500;
  static const double platformCommission = 0.15;
  static const int chatMaxLength = 500;
  static const int bioMaxLength = 280;
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

  static String roomInviteUrl({
    required String code,
    required String invitedBy,
  }) => 'https://$inviteWebHost/join?code=$code&invited_by=$invitedBy';

  /// Item 7 (QR codes) — the jma3a:// custom-scheme form of a room
  /// invite, same "custom scheme is for internal routing (QR codes,
  /// other in-app surfaces) only, never for external sharing" rule as
  /// [appProfileLink] below (see its own doc comment) — the
  /// AndroidManifest.xml intent-filter for `jma3a://join` explicitly
  /// calls out "QR codes" as its reason for existing. [invitedBy] is
  /// optional here (unlike [roomInviteUrl]): a room QR is meant to be
  /// scanned by someone who ISN'T already personally invited — DO NOT
  /// pass the revealer's own id as invitedBy, since that would let a
  /// scan silently bypass the room's own approval-request gate
  /// (joinByCode only skips approval when invitedBy is a genuine,
  /// server-recorded invite) — the room's real visibility/closed/
  /// capacity/approval rules are enforced by joinByCode exactly the same
  /// way whether invitedBy is present or not.
  static String appRoomInviteLink(String code) => 'jma3a://join?code=$code';

  /// Dedicated public-profile web host — deliberately a separate constant
  /// from [inviteWebHost] rather than reusing it, per product decision:
  /// profile links are shared/branded under www.moujgroup.jma3a.com while
  /// room invites stay on jma3a.com. Requires the SAME kind of native App
  /// Link wiring [inviteWebHost] already has (assetlinks.json / apple-app-
  /// site-association hosted at this host's own /.well-known/ path, plus
  /// the AndroidManifest.xml intent-filter <data> entry and iOS
  /// associated-domains entry — see Runner.entitlements) for a tapped link
  /// to open the app instead of a browser; this repo cannot verify that
  /// hosting exists.
  static const String profileWebHost = 'www.moujgroup.jma3a.com';

  /// The ONLY URL form a profile should ever be shared/opened with
  /// externally — HTTPS, same "never a custom scheme" reasoning as
  /// [roomInviteUrl] (a jma3a:// link renders as plain, non-tappable text
  /// in WhatsApp/SMS/etc. — see shareProfile's own history of getting this
  /// wrong). Deliberately keyed on the account's public `username`
  /// (profiles.username — unique, already user-chosen/visible wherever the
  /// profile is shown, see ProfileRepository.getProfileByUsername), NEVER
  /// the internal Supabase user id: a raw UUID in a shared/visible link is
  /// an internal identifier leaking into a public surface, independent of
  /// whether the profile's *content* is otherwise already visible.
  /// Resolved back to the real profile by the `/u/:username` route
  /// (UsernameProfileResolverScreen) — a genuine registered GoRoute, not a
  /// redirect-rewrite hack, so it works uniformly for cold start (native
  /// App Link URI parsing) and warm in-app navigation alike. [username]
  /// must be non-empty — callers without one yet (profiles.username can be
  /// null) must not fall back to a userId-keyed link; see shareProfile's
  /// own handling of that case.
  static String publicProfileUrl(String username) =>
      'https://$profileWebHost/u/$username';

  /// The app's own deep-link scheme (see DeepLinkService/parseProfileLink
  /// for the existing `jma3a://join`/`jma3a://profile/<uuid>` precedent —
  /// registered host-agnostically in both AndroidManifest.xml's
  /// `<data android:scheme="jma3a" />` intent-filter and iOS's
  /// `CFBundleURLSchemes`, so no native config change was needed to add
  /// this `u` host). Same UUID-free, username-keyed identifier as
  /// [publicProfileUrl] — only the URL FORM differs. Resolved back to the
  /// real profile by DeepLinkService's parseUsernameProfileLink + an async
  /// getProfileByUsername lookup (see deep_links.dart), the same as any
  /// other jma3a:// deep link.
  ///
  /// NOT used for the profile link a user explicitly shares (shareProfile
  /// uses [publicProfileUrl] instead) — that was tried and reverted: most
  /// chat apps (WhatsApp, SMS, etc.) do NOT auto-linkify a custom scheme,
  /// so it rendered as plain, non-tappable text wherever it was shared,
  /// and had no "opens the website" fallback when the app isn't installed.
  /// Kept as a working internal-routing form (e.g. for a QR code or an
  /// in-app-only copy action) since [parseUsernameProfileLink] already
  /// resolves it identically to the HTTPS form.
  static String appProfileLink(String username) => 'jma3a://u/$username';
}
