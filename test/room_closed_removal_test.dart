// Regression test for "admin closes room but players aren't removed".
//
// Root cause: the session-participant exemption added for the RECONNECT case
// ("let a participant re-enter a room they belong to that was already closed")
// also fired for a participant who was PRESENT when the host closed the room.
// Because the owner_left handler won't re-fire the roomClosed dialog once the
// status is already 'closed', a participant who learned of the close via the
// reconcile poll then got the exemption and was never removed.
//
// RoomProvider.shouldRemoveOnRoomClosed re-separates the two cases via
// `wasRoomOpenWhileConnected` (did this client ever see the room OPEN while
// connected — i.e. was it a live close, not a reconnect).

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/rooms/presentation/room_provider.dart';

void main() {
  group('shouldRemoveOnRoomClosed', () {
    bool decide({
      bool owner = false,
      bool participant = false,
      bool wasOpen = false,
    }) => RoomProvider.shouldRemoveOnRoomClosed(
      isOwner: owner,
      isSessionParticipant: participant,
      wasRoomOpenWhileConnected: wasOpen,
    );

    test('the owner is never removed from their own room', () {
      expect(decide(owner: true, participant: true, wasOpen: true), isFalse);
      expect(decide(owner: true, participant: false, wasOpen: false), isFalse);
    });

    test('a participant PRESENT when the host closes IS removed (live close)',
        () {
      // Saw the room open while connected → the host closed it on them.
      expect(decide(participant: true, wasOpen: true), isTrue);
    });

    test('a non-participant present when the host closes IS removed', () {
      expect(decide(participant: false, wasOpen: true), isTrue);
    });

    test('a participant RECONNECTING into an already-closed room stays', () {
      // Never saw the room open on this client → genuine reconnect exemption.
      expect(decide(participant: true, wasOpen: false), isFalse);
    });

    test('a NON-participant reconnecting into a closed room is still removed',
        () {
      expect(decide(participant: false, wasOpen: false), isTrue);
    });
  });
}
