import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../cards/user_avatar.dart';

/// Item 7 (QR codes) — who may reveal a room's QR code. The admin
/// (owner) always can; any other player only when the room is genuinely
/// safe to advertise to a scanner who isn't personally invited: public,
/// not closed, and not already full. This mirrors — does NOT replace —
/// the real server-side authorization RoomRepository.joinByCode/joinRoom
/// already enforces on every join attempt (see AppConstants.
/// appRoomInviteLink's own doc comment): this function only decides
/// whether to show the reveal UI at all, never whether a resulting scan
/// is allowed to actually join — the QR itself carries no special
/// authorization, a scan is subject to the exact same rules typing the
/// code would be.
bool canRevealRoomQr({
  required bool isOwner,
  required bool isPrivate,
  required bool isClosed,
  required bool isFull,
}) {
  if (isOwner) return true;
  return !isPrivate && !isClosed && !isFull;
}

class _QrPanel extends StatelessWidget {
  const _QrPanel({
    required this.data,
    required this.title,
    required this.instruction,
    required this.shareText,
    this.roomCoverEmoji,
    this.avatarUrl,
    this.avatarConfig,
    this.displayName,
  });

  final String data;
  final String title;
  final String instruction;
  final String shareText;

  /// Room identity (mutually exclusive with the avatar fields below —
  /// only one of "room" or "profile" mode is ever used per sheet).
  final String? roomCoverEmoji;
  final String? avatarUrl;
  final Map<String, dynamic>? avatarConfig;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF1B1140)
              : theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Circular identity badge — room icon or inviter avatar,
            // same "compact circular identity" visual language as
            // RoomShareCard (item 5's share-preview pass).
            if (roomCoverEmoji != null)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandPurpleDark.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.brandPurpleDark.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    roomCoverEmoji!,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              )
            else
              UserAvatar(
                avatarUrl: avatarUrl,
                avatarConfig: avatarConfig,
                displayName: displayName,
                size: 64,
                borderWidth: 2,
                borderColor: AppColors.brandPurpleDark,
              ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              instruction,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // QR codes need a solidly light backdrop to stay scannable
            // regardless of the app's own dark/light theme.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandPurpleDark.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: QrImageView(
                data: data,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.circle,
                  color: AppColors.brandPurpleDark,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.l10n.qrClose),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        SharePlus.instance.share(ShareParams(text: shareText)),
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: Text(context.l10n.qrShareLink),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Reveals a room's QR code (item 7) — encodes [AppConstants.
/// appRoomInviteLink], the same "join" destination `AppConstants.
/// roomInviteUrl`/typing the code manually resolve to, so a scan is
/// subject to the exact same server-side authorization
/// (RoomRepository.joinByCode) either way. Call [show] rather than
/// constructing this directly — it also gates on [canRevealRoomQr].
class RoomQrSheet extends StatelessWidget {
  const RoomQrSheet({
    super.key,
    required this.inviteCode,
    required this.roomName,
    required this.roomCoverEmoji,
    required this.shareText,
  });

  final String inviteCode;
  final String roomName;
  final String roomCoverEmoji;
  final String shareText;

  static Future<void> show(
    BuildContext context, {
    required bool isOwner,
    required bool isPrivate,
    required bool isClosed,
    required bool isFull,
    required String inviteCode,
    required String roomName,
    required String roomCoverEmoji,
    required String shareText,
  }) {
    if (!canRevealRoomQr(
      isOwner: isOwner,
      isPrivate: isPrivate,
      isClosed: isClosed,
      isFull: isFull,
    )) {
      return Future.value();
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoomQrSheet(
        inviteCode: inviteCode,
        roomName: roomName,
        roomCoverEmoji: roomCoverEmoji,
        shareText: shareText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _QrPanel(
      data: AppConstants.appRoomInviteLink(inviteCode),
      title: roomName,
      instruction: context.l10n.qrRoomRevealInstruction,
      shareText: shareText,
      roomCoverEmoji: roomCoverEmoji,
    );
  }
}

/// Reveals the current user's own profile QR code (item 7) — encodes
/// [AppConstants.appProfileLink] (username-keyed, never a raw UUID —
/// see that constant's own doc comment for why).
class ProfileQrSheet extends StatelessWidget {
  const ProfileQrSheet({
    super.key,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.avatarConfig,
    required this.shareText,
  });

  final String username;
  final String displayName;
  final String? avatarUrl;
  final Map<String, dynamic>? avatarConfig;
  final String shareText;

  static Future<void> show(
    BuildContext context, {
    required String username,
    required String displayName,
    String? avatarUrl,
    Map<String, dynamic>? avatarConfig,
    required String shareText,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProfileQrSheet(
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      avatarConfig: avatarConfig,
      shareText: shareText,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return _QrPanel(
      data: AppConstants.appProfileLink(username),
      title: displayName,
      instruction: context.l10n.qrProfileRevealInstruction,
      shareText: shareText,
      avatarUrl: avatarUrl,
      avatarConfig: avatarConfig,
      displayName: displayName,
    );
  }
}
