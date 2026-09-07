import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/router/app_router.dart';

/// What the user chose (or what happened) when asked to resolve owning/
/// belonging to another open room.
enum ActiveRoomConflictResult {
  /// User dismissed the dialog without picking an action.
  cancelled,

  /// User chose "Return to My Room" — already navigated there.
  wentToExistingRoom,

  /// User chose "Close and continue" — the old room has been closed;
  /// the caller should proceed with whatever it was about to do (create a
  /// new room, join an invited room, etc).
  closedAndProceed,
}

/// Single source of truth for the "you already have an open room" prompt.
///
/// Originally inlined in [RoomBrowserScreen._doCreateRoom]; extracted so the
/// exact same check + dialog + close sequence can also gate room-invitation
/// notification taps (see NotificationService._handleRoomInviteTap), instead
/// of that path silently dropping the user into a second room.
///
/// [active] is the result of `RoomRepository.getActiveMembership(userId)`.
Future<ActiveRoomConflictResult> resolveActiveRoomConflict(
  BuildContext context,
  Map<String, dynamic> active,
) async {
  final isOwner = active['is_owner'] == true;
  final isPaused = active['status'] == 'paused';

  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.roomsActiveRoomTitle),
      content: Text(
        isOwner
            ? (isPaused
                  ? context.l10n.roomsActiveRoomPausedBody(active['room_name'])
                  : context.l10n.roomsActiveRoomOpenBody(active['room_name']))
            : context.l10n.roomsStillInRoomBody(active['room_name']),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'cancel'),
          child: Text(context.l10n.cancel),
        ),
        if (isOwner)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, 'close'),
            child: Text(context.l10n.roomsCloseAndCreateNew),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, 'go'),
          child: Text(context.l10n.roomsReturnToMyRoom),
        ),
      ],
    ),
  );

  if (choice == 'go') {
    AppRouter.router.push('/home/room/${active['room_id']}');
    return ActiveRoomConflictResult.wentToExistingRoom;
  }

  if (choice == 'close') {
    final roomId = active['room_id'] as String;
    try {
      await sl.realtimeService.broadcastRoomEvent(roomId, {
        'type': 'owner_left',
        'reason': 'host_closed_remotely',
      });
    } catch (_) {}
    await sl.roomRepository.softDeleteRoom(roomId);
    if (context.mounted) {
      context.showSnackBar(context.l10n.roomsClosedSnackbar);
    }
    return ActiveRoomConflictResult.closedAndProceed;
  }

  return ActiveRoomConflictResult.cancelled;
}
