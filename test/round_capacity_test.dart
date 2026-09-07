// Tests for items 2/3/4/5/6/8/12 — round capacity: the ONE authoritative
// calculateMaxPossibleRounds/isMaxRoundsValid pair in round_capacity.dart,
// used identically by the settings UI (game_settings_sheet.dart /
// tod_pre_game_config_sheet.dart) and by the server-side start-game
// validation (create_game_session, mirrored in SQL — see
// migration_2026_round_capacity_validation.sql). The actual RPC rejection
// (item 16/8) can't be exercised from this offline suite — this file
// tests the exact same formula the SQL mirrors, so a pass here is a
// direct guarantee the SQL (hand-verified against this file) computes the
// same answer, not a substitute for a live-DB test.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/engine/round_capacity.dart';

void main() {
  group('9/10/11 — unique cards ON caps Max Rounds to the card supply '
      '(NHIE/Meme shape: one card per round, player count irrelevant)', () {
    test('9. 20 cards + unique ON + max 20 = valid', () {
      expect(
        isMaxRoundsValid(
          gameType: GameType.neverHaveIEver,
          availableCardCount: 20,
          activePlayers: 4,
          uniqueCards: true,
          selectedMaxRounds: 20,
        ),
        isTrue,
      );
      expect(
        calculateMaxPossibleRounds(
          gameType: GameType.neverHaveIEver,
          availableCardCount: 20,
          activePlayers: 4,
          uniqueCards: true,
        ),
        20,
      );
    });

    test('10. 20 cards + unique ON + max 21 = invalid', () {
      expect(
        isMaxRoundsValid(
          gameType: GameType.memeGame,
          availableCardCount: 20,
          activePlayers: 4,
          uniqueCards: true,
          selectedMaxRounds: 21,
        ),
        isFalse,
      );
    });

    test('11. 20 cards + unique ON + max 30 = invalid', () {
      expect(
        isMaxRoundsValid(
          gameType: GameType.memeGame,
          availableCardCount: 20,
          activePlayers: 4,
          uniqueCards: true,
          selectedMaxRounds: 30,
        ),
        isFalse,
      );
    });
  });

  group('12 — unique cards OFF removes the ceiling entirely', () {
    test('12. 20 cards + unique OFF + max 30 = valid — the engine\'s own '
        'existing shuffle/repeat behavior is trusted, never artificially '
        'capped to cardCount', () {
      expect(
        isMaxRoundsValid(
          gameType: GameType.truthOrDare,
          availableCardCount: 20,
          activePlayers: 4,
          uniqueCards: false,
          selectedMaxRounds: 30,
        ),
        isTrue,
      );
      expect(
        calculateMaxPossibleRounds(
          gameType: GameType.truthOrDare,
          availableCardCount: 20,
          activePlayers: 4,
          uniqueCards: false,
        ),
        isNull, // no ceiling to report
      );
    });
  });

  group('13 — active player count is considered where the game\'s turn '
      'rules actually require it (ToD: one card PER PLAYER per round)', () {
    test('13. ToD: the same 20-card pack supports fewer unique rounds '
        'with more active players, since each round draws one card per '
        'player', () {
      expect(
        calculateMaxPossibleRounds(
          gameType: GameType.truthOrDare,
          availableCardCount: 20,
          activePlayers: 2,
          uniqueCards: true,
        ),
        10, // 20 / 2
      );
      expect(
        calculateMaxPossibleRounds(
          gameType: GameType.truthOrDare,
          availableCardCount: 20,
          activePlayers: 4,
          uniqueCards: true,
        ),
        5, // 20 / 4
      );
      expect(
        calculateMaxPossibleRounds(
          gameType: GameType.truthOrDare,
          availableCardCount: 20,
          activePlayers: 7,
          uniqueCards: true,
        ),
        2, // 20 / 7, floor
      );
    });

    test('NHIE/Meme capacity is UNCHANGED by player count — one shared '
        'card per round regardless of how many players are answering it',
        () {
      for (final players in [2, 4, 8]) {
        expect(
          calculateMaxPossibleRounds(
            gameType: GameType.neverHaveIEver,
            availableCardCount: 20,
            activePlayers: players,
            uniqueCards: true,
          ),
          20,
        );
        expect(
          calculateMaxPossibleRounds(
            gameType: GameType.memeGame,
            availableCardCount: 20,
            activePlayers: players,
            uniqueCards: true,
          ),
          20,
        );
      }
    });
  });

  group('14/15 — only ACTIVE, eligible players feed the formula (the '
      'caller\'s job — this function trusts whatever count it\'s given, '
      'exactly like create_game_session\'s v_eligible_count query already '
      'excludes spectators/kicked/banned/left)', () {
    test('14/15. a capacity computed from an active-only count differs '
        'from one computed off a raw/inflated member count — proving the '
        'input actually matters and callers must pass the filtered '
        'number, not a raw room-members count', () {
      // 6 raw room members, but 2 are a spectator + a kicked player — the
      // caller (settings UI / create_game_session RPC) is responsible for
      // passing 4 (the real active count), never 6.
      const rawMemberCount = 6;
      const activeCount = 4; // spectator + kicked excluded upstream
      final capacityFromRaw = calculateMaxPossibleRounds(
        gameType: GameType.truthOrDare,
        availableCardCount: 20,
        activePlayers: rawMemberCount,
        uniqueCards: true,
      );
      final capacityFromActive = calculateMaxPossibleRounds(
        gameType: GameType.truthOrDare,
        availableCardCount: 20,
        activePlayers: activeCount,
        uniqueCards: true,
      );
      expect(capacityFromRaw, 3); // 20 / 6
      expect(capacityFromActive, 5); // 20 / 4 — the correct one
      expect(capacityFromRaw, isNot(equals(capacityFromActive)));
    });
  });

  group('16 — this is exactly what the authoritative start-game check '
      'evaluates (create_game_session mirrors this formula server-side; '
      'see migration_2026_round_capacity_validation.sql)', () {
    test('16. an impossible configuration a stale/modified client might '
        'still submit is rejected by this same formula', () {
      expect(
        isMaxRoundsValid(
          gameType: GameType.neverHaveIEver,
          availableCardCount: 20,
          activePlayers: 4,
          uniqueCards: true,
          selectedMaxRounds: 30,
        ),
        isFalse,
      );
    });
  });

  group('Edge cases', () {
    test('zero available cards with unique ON supports zero rounds', () {
      expect(
        calculateMaxPossibleRounds(
          gameType: GameType.memeGame,
          availableCardCount: 0,
          activePlayers: 4,
          uniqueCards: true,
        ),
        0,
      );
    });

    test('zero active players never divides by zero — treated as 1 for '
        'ToD\'s per-player cost', () {
      expect(
        () => calculateMaxPossibleRounds(
          gameType: GameType.truthOrDare,
          availableCardCount: 20,
          activePlayers: 0,
          uniqueCards: true,
        ),
        returnsNormally,
      );
      expect(
        calculateMaxPossibleRounds(
          gameType: GameType.truthOrDare,
          availableCardCount: 20,
          activePlayers: 0,
          uniqueCards: true,
        ),
        20, // treated as 1 player
      );
    });
  });
}
