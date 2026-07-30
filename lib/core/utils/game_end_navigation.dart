import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/rooms/domain/room_entity.dart';
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
Future<void> goToLobbyOrHome(BuildContext context, String roomId) async {
  var roomExists = true;
  try {
    await sl.roomRepository.getRoomWithDetails(roomId);
  } catch (e) {
    roomExists = false;
    AppLogger.debug('goToLobbyOrHome: room $roomId no longer exists ($e)');
  }

  if (roomExists) {
    try {
      await sl.roomRepository.updateStatus(roomId, RoomStatus.waiting);
    } catch (e) {
      AppLogger.warning('goToLobbyOrHome: failed to reset room status: $e');
    }
    if (context.mounted) context.go('/home/room/$roomId');
  } else {
    if (context.mounted) context.go(RouteNames.home);
  }
}
