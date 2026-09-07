import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/rooms/domain/room_entity.dart';
import '../../features/rooms/presentation/room_provider.dart';
import '../di/service_locator.dart';
import '../router/route_names.dart';
import 'app_logger.dart';

/// Shared "Go to Home" behavior for every game's end/results screen.
///
/// If the room still exists, the game-ended status is reset to `waiting`
/// and the player is sent back to the room's lobby. If the room has since
/// been closed/deleted (owner left, room expired, etc.), there's nowhere
/// to go back to, so the player is sent straight to the app's Home screen
/// instead. One implementation shared by Tod/Meme/NHIE so the three games
/// can't drift into inconsistent behavior here again.
///
/// [roomProvider] (the game screen's live RoomProvider) is used to reflect
/// the ended state locally BEFORE popping so the lobby's first rebuild
/// shows the normal lobby instead of flashing the "Preparing" placeholder
/// (see RoomProvider.markReturnedToLobby). Optional so callers without a
/// provider still work.
Future<void> goToLobbyOrHome(
  BuildContext context,
  String roomId, {
  RoomProvider? roomProvider,
}) async {
  // AUTHORITATIVE room context. The live RoomProvider is the lobby that
  // started/joined this game and survives underneath the pushed game route;
  // its loaded `room` is the source of truth for "which room am I a valid
  // member of", not the id the game screen happened to be constructed with
  // (which can be stale). If the provider has a room loaded, RLS already let
  // this client read it — i.e. it IS a legitimate member — so it returns
  // there unconditionally.
  final liveRoom = roomProvider?.room;
  final targetRoomId = (liveRoom?.id.isNotEmpty ?? false) ? liveRoom!.id : roomId;

  final bool canReturn;
  if (liveRoom != null) {
    canReturn = true;
  } else if (targetRoomId.isEmpty) {
    canReturn = false;
  } else {
    // No live provider (defensive) — fall back to a terminal-deleted probe.
    // A keep-game-closed room (closed_at set, deleted_at NULL) is very much
    // alive; roomStillExists checks deleted_at directly and treats a transient
    // read error as "still exists".
    canReturn = await sl.roomRepository.roomStillExists(targetRoomId);
    if (!canReturn) {
      AppLogger.debug('goToLobbyOrHome: room $targetRoomId is deleted/gone');
    }
  }

  if (canReturn) {
    try {
      await sl.roomRepository.updateStatus(targetRoomId, RoomStatus.waiting);
    } catch (e) {
      AppLogger.warning('goToLobbyOrHome: failed to reset room status: $e');
    }
    // Reflect the ended state in local room status now (after the
    // authoritative DB write above) so the revealed lobby renders the normal
    // lobby immediately — not the STARTING/"Preparing" placeholder that would
    // otherwise flash until the reconcile catches up.
    roomProvider?.markReturnedToLobby();
    if (!context.mounted) return;
    // Return DIRECTLY to the canonical room lobby route. This is deterministic
    // regardless of how the game route was entered (start-from-lobby,
    // reconnect, relaunch, notification). context.pop() was the bug: it lands
    // on whatever route sits beneath the game route in the navigation stack —
    // the LobbyScreen only when the game was started from the lobby in the
    // foreground; for every other entry the route beneath is `/home`
    // (HomeShell → Browse Rooms), so a valid member was dumped on Browse
    // instead of their own room. Navigating to `/home/room/$id` reuses the
    // existing LobbyScreen page (go_router matches by path key) when it is
    // still in the stack — no teardown, no duplicate RoomProvider — and
    // rebuilds it cleanly when it is not, either way ending on the room lobby.
    context.go('/home/room/$targetRoomId');
  } else {
    if (context.mounted) context.go(RouteNames.home);
  }
}
