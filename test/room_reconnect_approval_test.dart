// Tests for item 3 — reconnecting to an ongoing NHIE/Meme game must not
// show "Waiting for admin approval" for a player the admin already
// accepted (whose member list still shows Mute/Kick/Ban, not
// Accept/Reject).
//
// Root cause (see room_provider.dart initialize()'s requiresApproval gate):
// that gate checked isActiveMember alone (room_members.left_at IS NULL) —
// but a player who closed the app mid-game gets soft-evicted (left_at set)
// by the disconnect grace period even though they're still a live,
// accepted session participant. The fix ORs in isActiveParticipant
// (RoomProvider.computeSessionParticipant), the same authoritative
// "genuine, non-kicked, non-permanently-left participant of the room's
// current session" signal the arrivedMidGame gate and the two sibling
// approval gates already trust — see game_nav_and_closed_room_test.dart,
// which already covers this same public static method for the
// closed-room-reconnect gate. These tests re-exercise it framed
// specifically around the requiresApproval reconnect scenario the fix
// targets.
//
// computeSessionParticipant is pure/static — the async instance method it
// feeds into (RoomProvider.initialize(), which also calls the Supabase-
// backed _repo.isActiveMember/requestToJoin) needs a live Supabase
// connection or a repository mock this codebase's test harness doesn't
// have; that integration path needs real-device/multi-device verification
// (see final report).

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/rooms/presentation/room_provider.dart';

void main() {
  const sessionPlayers = ['host', 'alice', 'bob'];

  bool isAlreadyMember({
    List<String> ids = sessionPlayers,
    required String user,
    bool hasRow = true,
    bool kicked = false,
    bool left = false,
  }) => RoomProvider.computeSessionParticipant(
    sessionPlayerIds: ids,
    userId: user,
    hasMemberRow: hasRow,
    isKicked: kicked,
    leftDefinitively: left,
  );

  group('Item 3 — accepted player reconnecting mid-game must NOT be routed '
      'into pending-approval', () {
    test('an accepted player who was soft-evicted (left_at set by the '
        'disconnect grace period, hence isActiveMember would read false) '
        'but is still a live session participant counts as already a '
        'member — the exact bug scenario', () {
      // left_at being set is represented upstream (isActiveMember alone
      // would be false here); what this gate now also consults is purely
      // session-membership, which does not depend on left_at at all.
      expect(
        isAlreadyMember(user: 'alice', kicked: false, left: false),
        isTrue,
      );
    });

    test('a player still fully connected (never evicted) is unaffected — '
        'still recognized as already a member, same as before the fix', () {
      expect(isAlreadyMember(user: 'bob'), isTrue);
    });
  });

  group('Item 3 — the fix must not weaken existing blocks', () {
    test('a genuinely pending (never-accepted) user is NOT treated as '
        'already a member — they still require approval', () {
      expect(isAlreadyMember(user: 'stranger'), isFalse);
      expect(isAlreadyMember(ids: const ['host', 'alice'], user: 'carol'),
          isFalse);
    });

    test('a kicked user reconnecting is still blocked, even though they '
        'remain in the session\'s player_ids from before the kick', () {
      expect(isAlreadyMember(user: 'alice', kicked: true), isFalse);
    });

    test('a user who left permanently (not a grace eviction) is still '
        'blocked, distinguishing a real departure from a mid-game '
        'disconnect', () {
      expect(isAlreadyMember(user: 'alice', left: true), isFalse);
    });
  });
}
