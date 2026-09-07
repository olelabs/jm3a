import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'core/constants/app_constants.dart';

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
      if (initial != null) _handle(initial);
    } catch (_) {}

    // Handle links while app is running (warm start)
    _sub = _appLinks.uriLinkStream.listen(_handle, onError: (_) {});
  }

  void _handle(Uri uri) {
    final invite = _parseInvite(uri);
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
    }
  }

  RoomInvitePayload? _parseInvite(Uri uri) {
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

/// Parses a profile deep link: the jma3a:// custom scheme (host
/// `profile`, first path segment the user id) or the HTTPS App Link
/// (path `/profile/{id}`) — mirrors DeepLinkService's own custom-scheme-
/// vs-web-link shape for room invites. Public (not a DeepLinkService
/// method) so it's unit-testable without a real AppLinks()/platform
/// channel.
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
