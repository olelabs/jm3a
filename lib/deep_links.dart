import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Handles incoming deep links of the form:
///   jma3a://join?code=ABC123&invited_by=<userId>
///
/// Emit the parsed invite payload so the app can navigate and auto-join.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  final _ctrl = StreamController<RoomInvitePayload>.broadcast();
  Stream<RoomInvitePayload> get inviteStream => _ctrl.stream;

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
    if (uri.scheme != 'jma3a') return;
    if (uri.host == 'join') {
      final code = uri.queryParameters['code'];
      final invitedBy = uri.queryParameters['invited_by'];
      if (code != null && code.isNotEmpty) {
        _ctrl.add(RoomInvitePayload(code: code, invitedBy: invitedBy));
        debugPrint('DeepLinkService: invite code=$code invitedBy=$invitedBy');
      }
    }
  }

  void dispose() {
    _sub?.cancel();
    _ctrl.close();
  }
}

class RoomInvitePayload {
  const RoomInvitePayload({required this.code, this.invitedBy});
  final String code;
  final String? invitedBy; // userId of the admin who invited
}
