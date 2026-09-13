import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/context_ext.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/avatar/presentation/avatar_creator_screen.dart'
    show AvatarConfig;
import '../widgets/profile_share_card.dart';

/// Profile sharing: generates an isolated, purpose-built share-card image
/// (see ProfileShareCard) and shares it alongside the same real, tappable
/// HTTPS deep link — same "HTTPS, not jma3a://" reasoning LobbyScreen's
/// own room-invite share already documents (a custom scheme renders as
/// plain, non-tappable text in WhatsApp/SMS/etc., and the https link still
/// falls back to the website when the app isn't installed). Only
/// publicly-visible profile fields are used — nothing beyond what's
/// already shown to anyone who opens this profile in-app (no email,
/// phone, or auth identifier). [generalScore]/[honestyPoints] must come
/// from the caller's own already-fetched ProfileStats — this file does
/// not fetch or duplicate that data.
Future<void> shareProfile(
  BuildContext context, {
  required UserEntity user,
  required int generalScore,
  required int honestyPoints,
}) async {
  final l10n = context.l10n;
  // ROOT CAUSE of the "share isn't clickable" regression this fixes: this
  // used to share AppConstants.appProfileLink (the jma3a:// custom scheme)
  // instead of the HTTPS publicProfileUrl — despite this very file's own
  // class doc comment already stating the opposite ("same real, tappable
  // HTTPS deep link"). Most chat apps (WhatsApp, SMS, etc.) do NOT
  // auto-linkify a custom scheme, so the shared text rendered as plain,
  // non-tappable characters. publicProfileUrl (https://www.moujgroup.
  // jma3a.com/u/<username> — see AppConstants.profileWebHost) is a real
  // tappable link and still falls back to the website when the app isn't
  // installed. Still never a userId-keyed link either way. A user who
  // hasn't set a username yet (profiles.username is nullable) still gets a
  // working share (name + a generic app link), just without a
  // profile-specific deep link, rather than falling back to exposing
  // their internal id.
  final username = user.username;
  final link = (username != null && username.isNotEmpty)
      ? AppConstants.publicProfileUrl(username)
      : 'https://${AppConstants.profileWebHost}';
  final name = user.displayName ?? user.username ?? l10n.packPlayer;
  final shareText = l10n.profileShareMessage(name, link);
  final shareSubject = l10n.profileShareSubject(name);

  final imagePath = await _renderProfileShareCard(
    context,
    user: user,
    generalScore: generalScore,
    honestyPoints: honestyPoints,
    profileLink: link,
  );

  if (!context.mounted) return;

  await SharePlus.instance.share(
    ShareParams(
      text: shareText,
      subject: shareSubject,
      files: imagePath != null ? [XFile(imagePath)] : null,
    ),
  );
}

/// Renders [ProfileShareCard] off-screen via a RepaintBoundary and returns
/// the PNG's temp-file path, or null if rendering fails for any reason
/// (network avatar fetch, etc.) — in which case [shareProfile] still
/// falls back to text-only sharing rather than failing the whole action.
Future<String?> _renderProfileShareCard(
  BuildContext context, {
  required UserEntity user,
  required int generalScore,
  required int honestyPoints,
  required String profileLink,
}) async {
  try {
    final avatarChild = await _loadAvatarWidget(user);
    if (!context.mounted) return null;

    final boundaryKey = GlobalKey();
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -ProfileShareCard.width - 100,
        top: 0,
        child: RepaintBoundary(
          key: boundaryKey,
          child: ProfileShareCard(
            user: user,
            generalScore: generalScore,
            honestyPoints: honestyPoints,
            profileLink: profileLink,
            avatarChild: avatarChild,
          ),
        ),
      ),
    );
    overlay.insert(entry);

    try {
      // Two frames: the first lays out and paints the newly-inserted
      // overlay entry; toImage() must run after that paint has actually
      // happened, which endOfFrame guarantees (unlike a fixed delay).
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/jma3a_profile_share_${user.id}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());
      return file.path;
    } finally {
      entry.remove();
    }
  } catch (_) {
    // Image generation is a best-effort enhancement — text+link sharing
    // must never be blocked by an avatar fetch/render failure.
    return null;
  }
}

/// Resolves the same premium-avatar-config-first, plain-avatarUrl-fallback
/// priority UserAvatar._resolvedUrl uses (never a second avatar system),
/// but fully AWAITS the image bytes first instead of handing a
/// still-loading Image.network/SvgPicture.network to the widget tree —
/// required because RepaintBoundary.toImage() captures whatever has
/// already painted, and a still-loading network image would be captured
/// as blank/placeholder.
Future<Widget> _loadAvatarWidget(UserEntity user) async {
  String? url;
  if (user.isPremium &&
      user.avatarConfig != null &&
      user.avatarConfig!.isNotEmpty) {
    url = AvatarConfig.fromMap(user.avatarConfig!).avatarUrl;
  } else {
    url = user.avatarUrl;
  }

  if (url == null) {
    return ShareCardInitialsAvatar(displayName: user.displayName);
  }

  final dio = Dio();
  try {
    if (url.contains('avataaars.io')) {
      final response = await dio.get<String>(
        url,
        options: Options(
          headers: {'Accept': 'image/svg+xml'},
          responseType: ResponseType.plain,
        ),
      );
      final svg = response.data;
      if (svg == null || svg.isEmpty) {
        return ShareCardInitialsAvatar(displayName: user.displayName);
      }
      return ShareCardSvgAvatar(svgString: svg);
    }

    final response = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      return ShareCardInitialsAvatar(displayName: user.displayName);
    }
    return Image.memory(
      Uint8List.fromList(data),
      width: 128,
      height: 128,
      fit: BoxFit.cover,
    );
  } catch (_) {
    return ShareCardInitialsAvatar(displayName: user.displayName);
  } finally {
    dio.close();
  }
}
