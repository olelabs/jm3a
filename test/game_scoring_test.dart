// Tests for the shared scoreboard helpers (lib/features/games/engine/
// game_scoring.dart) that every game's results screen uses to rank players and
// decide the winner. These lock in the fix for the "admin always wins"
// artefact: a tied or all-zero board must NOT crown the first-seated (host)
// player, and a genuine tie must be reported as such.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/game_scoring.dart';

void main() {
  group('denseRankForScore', () {
    test('ranks by score, tied players share a rank', () {
      final all = [5, 5, 3, 0];
      expect(denseRankForScore(5, all), 0); // both 5s are rank 0
      expect(denseRankForScore(3, all), 2); // two players scored higher
      expect(denseRankForScore(0, all), 3);
    });

    test('a strict leader is rank 0, the rest follow', () {
      final all = [9, 4, 1];
      expect(denseRankForScore(9, all), 0);
      expect(denseRankForScore(4, all), 1);
      expect(denseRankForScore(1, all), 2);
    });
  });

  group('topScorers — the authoritative winner set', () {
    test('a single leader with points is the sole winner', () {
      expect(topScorers({'host': 1, 'p1': 3, 'p2': 2}), {'p1'});
    });

    test('an ALL-ZERO board has NO winner (host is never crowned by default)',
        () {
      // This is exactly the "admin always wins" case: nobody scored, and the
      // old display crowned whoever sat first (the host). Now: no winner.
      expect(topScorers({'host': 0, 'p1': 0, 'p2': 0}), isEmpty);
    });

    test('a genuine tie returns EVERY tied player, not just the first', () {
      expect(topScorers({'host': 2, 'p1': 2, 'p2': 1}), {'host', 'p1'});
    });

    test('empty scores → no winner', () {
      expect(topScorers(const {}), isEmpty);
    });

    test('negative/zero top is treated as no winner', () {
      expect(topScorers({'a': 0, 'b': -1}), isEmpty);
    });
  });

  group('hasSoleWinner', () {
    test('true only for exactly one positive top scorer', () {
      expect(hasSoleWinner({'a': 3, 'b': 1}), isTrue);
      expect(hasSoleWinner({'a': 2, 'b': 2}), isFalse); // tie
      expect(hasSoleWinner({'a': 0, 'b': 0}), isFalse); // all zero
      expect(hasSoleWinner(const {}), isFalse);
    });
  });
}
