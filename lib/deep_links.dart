import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'core/constants/app_constants.dart';
import 'features/profile/data/profile_repository.dart';

/// Handles incoming deep links, in two forms:
///
///   - Universal/App Link (shared links, tappable in WhatsApp/SMS/etc.):
///       `https://jma3a.com/join?code=ABC123&invited_by=<userId>`
///       `https://jma3a.com/profile/<userId>`
///   - jma3a:// custom scheme — kept only as an internal-routing fallback
///     (e.g. QR codes, other in-app surfaces), never used for sharing:
///       `jma3a://join?code=ABC123&invited_by=<userId>`
///       `jma3a://profile/<userId>`
///
/// Emits the parsed payload so the app can navigate. A link that arrives
/// before anything is ready to consume it (cold start before login, or
/// before the router exists) is cached in [pendingInvite]/[pendingProfile]
/// rather than dropped — AppRouter's redirect logic consumes it once the
/// user is actually logged in (see app_router.dart).
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  final _ctrl = StreamController<RoomInvitePayload>.broadcast();
  Stream<RoomInvitePayload> get inviteStream => _ctrl.stream;

  final _profileCtrl = StreamController<ProfileLinkPayload>.broadcast();
  Stream<ProfileLinkPayload> get profileStream => _profileCtrl.stream;

  /// Set whenever a link is parsed but not yet consumed (e.g. the user
  /// wasn't logged in yet). AppRouter's redirect callback clears this once
  /// it routes to `/join` with these values.
  RoomInvitePayload? pendingInvite;

  void clearPendingInvite() => pendingInvite = null;

  /// Profile sharing correction pass — same "arrived before we could act
  /// on it" caching as [pendingInvite]. The router opens `/user/:userId`
  /// directly (never the generic home screen) once auth allows it — see
  /// app_router.dart's own comment on this rule.
  ProfileLinkPayload? pendingProfile;

  void clearPendingProfile() => pendingProfile = null;

  Future<void> init() async {
    // Handle link that launched the app (cold start)
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) await _handle(initial);
    } catch (_) {}

    // Handle links while app is running (warm start)
    _sub = _appLinks.uriLinkStream.listen(_handle, onError: (_) {});
  }

  Future<void> _handle(Uri uri) async {
    final invite = parseInviteLink(uri);
    if (invite != null) {
      pendingInvite = invite;
      _ctrl.add(invite);
      debugPrint(
        'DeepLinkService: invite code=${invite.code} '
        'invitedBy=${invite.invitedBy}',
      );
      return;
    }

    final profile = parseProfileLink(uri);
    if (profile != null) {
      pendingProfile = profile;
      _profileCtrl.add(profile);
      debugPrint('DeepLinkService: profile userId=${profile.userId}');
      return;
    }

    // AppConstants.appProfileLink's current, UUID-free form —
    // jma3a://u/<username> — carries a username, not a userId, so it
    // needs a lookup before it can become the same ProfileLinkPayload{
    // userId} every downstream consumer (AppRouter's redirect, the
    // profileStream listener) already expects. A miss (deleted/renamed
    // account, or any lookup failure) is silently dropped — same "don't
    // strand the user on a broken deep link" behavior as an unresolvable
    // legacy jma3a://profile/<uuid> link one row up, which also has
    // nothing to fall back to.
    final username = parseUsernameProfileLink(uri);
    if (username != null) {
      try {
        final user = await ProfileRepository.instance.getProfileByUsername(
          username,
        );
        if (user == null) return;
        final resolved = ProfileLinkPayload(userId: user.id);
        pendingProfile = resolved;
        _profileCtrl.add(resolved);
        debugPrint(
          'DeepLinkService: profile username=$username -> userId=${user.id}',
        );
      } catch (e) {
        debugPrint('DeepLinkService: username profile lookup failed: $e');
      }
    }
  }

  void dispose() {
    _sub?.cancel();
    _ctrl.close();
    _profileCtrl.close();
  }
}

class RoomInvitePayload {
  const RoomInvitePayload({required this.code, this.invitedBy});
  final String code;
  final String? invitedBy; // userId of the admin who invited
}

class ProfileLinkPayload {
  const ProfileLinkPayload({required this.userId});
  final String userId;
}

/// Parses a room-invite deep link — the jma3a:// custom scheme
/// (`jma3a://join?code=...&invited_by=...`, see [AppConstants.
/// appRoomInviteLink] — item 7's QR-code form) or the HTTPS App Link
/// ([AppConstants.roomInviteUrl]). Was DeepLinkService's own private
/// `_parseInvite` — made a public top-level function (same convention as
/// [parseProfileLink]/[parseUsernameProfileLink] below) so item 7's QR
/// scanner can reuse this EXACT parsing logic instead of re-implementing
/// it, and so it stays independently unit-testable without a real
/// AppLinks()/platform channel.
RoomInvitePayload? parseInviteLink(Uri uri) {
  final isCustomScheme = uri.scheme == 'jma3a' && uri.host == 'join';
  final isWebLink =
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host == AppConstants.inviteWebHost &&
      uri.path == '/join';
  if (!isCustomScheme && !isWebLink) return null;

  final code = uri.queryParameters['code'];
  if (code == null || code.isEmpty) return null;
  return RoomInvitePayload(
    code: code,
    invitedBy: uri.queryParameters['invited_by'],
  );
}

/// Parses the LEGACY, userId-keyed profile deep link: the jma3a://
/// custom scheme (host `profile`, first path segment the user id) or the
/// HTTPS App Link (path `/profile/{id}`) — mirrors DeepLinkService's own
/// custom-scheme-vs-web-link shape for room invites. No longer what
/// AppConstants.appProfileLink/publicProfileUrl generate for a NEW
/// shared link (both are username-keyed now — see
/// [parseUsernameProfileLink]), but an old link already shared/bookmarked
/// before that change must keep resolving, so this stays. Public (not a
/// DeepLinkService method) so it's unit-testable without a real
/// AppLinks()/platform channel.
ProfileLinkPayload? parseProfileLink(Uri uri) {
  String? userId;
  if (uri.scheme == 'jma3a' && uri.host == 'profile') {
    userId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  } else if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host == AppConstants.inviteWebHost &&
      uri.pathSegments.length == 2 &&
      uri.pathSegments.first == 'profile') {
    userId = uri.pathSegments[1];
  }
  if (userId == null || userId.isEmpty) return null;
  return ProfileLinkPayload(userId: userId);
}

/// Parses the CURRENT, UUID-free profile deep link — the HTTPS link
/// actually shared now, `https://$profileWebHost/u/<username>` (see
/// [AppConstants.publicProfileUrl]) — or the `jma3a://u/<username>` custom
/// scheme (see [AppConstants.appProfileLink], kept working for internal
/// routing even though it's no longer what's shared externally). Also
/// still accepts the legacy `https://jma3a.com/u/<username>` host
/// ([AppConstants.inviteWebHost]) so a link shared before the
/// www.moujgroup.jma3a.com domain switch keeps resolving — same
/// "old link must keep working" principle [parseProfileLink] follows.
/// Returns the raw username, never a userId — resolving it requires a
/// lookup (ProfileRepository.getProfileByUsername), which only
/// [DeepLinkService] does (it's the only caller here with backend
/// access); kept as a pure function so the URI-shape parsing itself stays
/// unit-testable without a real AppLinks()/platform channel or a live
/// database.
String? parseUsernameProfileLink(Uri uri) {
  String? username;
  if (uri.scheme == 'jma3a' &&
      uri.host == 'u' &&
      uri.pathSegments.length == 1) {
    username = uri.pathSegments.first;
  } else if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      (uri.host == AppConstants.profileWebHost ||
          uri.host == AppConstants.inviteWebHost) &&
      uri.pathSegments.length == 2 &&
      uri.pathSegments.first == 'u') {
    username = uri.pathSegments[1];
  }
  return (username == null || username.isEmpty) ? null : username;
}
