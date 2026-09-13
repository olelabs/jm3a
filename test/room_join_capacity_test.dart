// Regression coverage for "room owner must always be able to rejoin their
// own room" — see RoomRepository.joinRoom's own capacity-check comment.
//
// roomJoinExceedsCapacity is the pure decision extracted from that check
// (deliberately free of any Supabase/DB call) specifically so this exact
// scenario can be verified without a live database:
//
//   Room max_players = 3. Owner + Player B + Player C are all active
//   (3/3). The owner force-closes the app without formally leaving, then
//   later tries to return. activePlayers is always computed EXCLUDING the
//   joining user (see joinRoom), so from the owner's own perspective there
//   are only 2 other active players — but even if that exclusion were
//   somehow wrong, isOwnerJoining alone must still let them back in.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/rooms/data/room_repository.dart';

void main() {
  group('roomJoinExceedsCapacity — owner rejoin', () {
    test('owner is NEVER rejected, even when active players already equal '
        'max_players (their own seat is one of those counted elsewhere)', () {
      expect(
        roomJoinExceedsCapacity(
          isOwnerJoining: true,
          activePlayers: 3,
          maxPlayers: 3,
        ),
        isFalse,
      );
    });

    test('owner is NEVER rejected even if active players somehow exceed '
        'max_players', () {
      expect(
        roomJoinExceedsCapacity(
          isOwnerJoining: true,
          activePlayers: 5,
          maxPlayers: 3,
        ),
        isFalse,
      );
    });

    test('owner joining a room with free seats is unaffected either way', () {
      expect(
        roomJoinExceedsCapacity(
          isOwnerJoining: true,
          activePlayers: 1,
          maxPlayers: 3,
        ),
        isFalse,
      );
    });
  });

  group('roomJoinExceedsCapacity — normal player capacity enforcement '
      '(must NOT be weakened by the owner fix)', () {
    test(
      'a normal player is rejected once active players reach max_players',
      () {
        expect(
          roomJoinExceedsCapacity(
            isOwnerJoining: false,
            activePlayers: 3,
            maxPlayers: 3,
          ),
          isTrue,
        );
      },
    );

    test('a normal player is rejected if somehow already over max_players', () {
      expect(
        roomJoinExceedsCapacity(
          isOwnerJoining: false,
          activePlayers: 4,
          maxPlayers: 3,
        ),
        isTrue,
      );
    });

    test('a normal player is allowed while a seat remains free', () {
      expect(
        roomJoinExceedsCapacity(
          isOwnerJoining: false,
          activePlayers: 2,
          maxPlayers: 3,
        ),
        isFalse,
      );
    });
  });
}
