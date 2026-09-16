// Phase 3 (Friends room Join eligibility) — the Friends screen already
// had a "Join" button (FriendTile/friends_screen.dart) gated purely on
// "is this friend's presence showing a roomId at all" — no capacity,
// visibility, approval, or game-started check. This tests the pure
// predicate (isDirectlyJoinableRoom, in room_repository.dart) that now
// decides whether the button renders, one condition at a time, matching
// explore_person_completion_test.dart's established style.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/rooms/data/room_repository.dart';

bool _eligible({
  bool isOwnedByDisplayedUser = true,
  bool isPublic = true,
  bool hasCapacity = true,
  bool gameStarted = false,
  bool requiresApproval = false,
}) => isDirectlyJoinableRoom(
  isOwnedByDisplayedUser: isOwnedByDisplayedUser,
  isPublic: isPublic,
  hasCapacity: hasCapacity,
  gameStarted: gameStarted,
  requiresApproval: requiresApproval,
);

void main() {
  group('isDirectlyJoinableRoom', () {
    test('true when every condition passes', () {
      expect(_eligible(), isTrue);
    });

    test('false when the displayed user does not own the room', () {
      expect(_eligible(isOwnedByDisplayedUser: false), isFalse);
    });

    test('false when the room is not public', () {
      expect(_eligible(isPublic: false), isFalse);
    });

    test('false when the room has no capacity', () {
      expect(_eligible(hasCapacity: false), isFalse);
    });

    test('false when the game has already started', () {
      expect(_eligible(gameStarted: true), isFalse);
    });

    test('false when approval is required', () {
      expect(_eligible(requiresApproval: true), isFalse);
    });

    test('false when multiple conditions fail at once (private and full)', () {
      expect(_eligible(isPublic: false, hasCapacity: false), isFalse);
    });

    test(
      'false when every condition fails — never accidentally true from '
      'double negatives',
      () {
        expect(
          _eligible(
            isOwnedByDisplayedUser: false,
            isPublic: false,
            hasCapacity: false,
            gameStarted: true,
            requiresApproval: true,
          ),
          isFalse,
        );
      },
    );
  });
}
