// Regression coverage for TurnQueue — the shared turn-selection policy
// (lib/features/games/engine/turn_queue.dart) every game's turn-advance
// logic consults to decide who's next once muted/away players must be
// excluded, and to place a just-unmuted player at the END of the active
// rotation rather than resuming their original fixed-order position.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/turn_queue.dart';

void main() {
  group('TurnQueue.nextEligible — no one ineligible (baseline)', () {
    test('plain circular rotation, no skips', () {
      final q = TurnQueue(['A', 'B', 'C']);
      expect(q.nextEligible('A', {}), 'B');
      expect(q.nextEligible('B', {}), 'C');
      expect(q.nextEligible('C', {}), 'A');
    });
  });

  group('TurnQueue.nextEligible — mute current player (case 1)', () {
    test('muting the current player skips straight to the next eligible '
        'player', () {
      final q = TurnQueue(['A', 'B', 'C']);
      // A's turn, A gets muted -> skip set now contains A.
      expect(q.nextEligible('A', {'A'}), 'B');
    });
  });

  group('TurnQueue.nextEligible — mute before a player\'s turn (case 2)', () {
    test('A muted before their turn -> B and C alternate, A never selected',
        () {
      final q = TurnQueue(['A', 'B', 'C']);
      const skip = {'A'};
      // B -> C -> B -> C..., matching the brief's own worked example.
      expect(q.nextEligible('B', skip), 'C');
      expect(q.nextEligible('C', skip), 'B');
      expect(q.nextEligible('B', skip), 'C');
      expect(q.nextEligible('C', skip), 'B');
    });
  });

  group('TurnQueue.nextEligible — muted player cannot be selected (case 4)', () {
    test('a muted candidate is never returned regardless of starting point',
        () {
      final q = TurnQueue(['A', 'B', 'C', 'D']);
      const skip = {'B', 'D'};
      expect(q.nextEligible('A', skip), 'C');
      expect(q.nextEligible('C', skip), 'A');
    });
  });

  group('TurnQueue.markReturned — unmute enters at the end (case 5)', () {
    test('the brief\'s own worked example: A muted then unmuted rejoins at '
        'the end, not their original slot', () {
      final q = TurnQueue(['A', 'B', 'C']);
      const skip = {'A'};
      expect(q.nextEligible('A', skip), 'B'); // A's turn -> skip -> B
      expect(q.nextEligible('B', skip), 'C');
      // Unmute A: moves to the back of the rotation.
      q.markReturned('A');
      expect(q.order, ['B', 'C', 'A']);
      // Continuing WITHOUT A in the skip set anymore:
      expect(q.nextEligible('C', {}), 'A');
      expect(q.nextEligible('A', {}), 'B');
      expect(q.nextEligible('B', {}), 'C');
    });

    test('a middle player (not first in fixed order) still moves to the '
        'true end, not just their own original slot', () {
      final q = TurnQueue(['A', 'B', 'C', 'D']);
      // B is muted; A, C, D rotate normally.
      const skip = {'B'};
      expect(q.nextEligible('A', skip), 'C');
      expect(q.nextEligible('C', skip), 'D');
      // Unmute B while D is current — B must NOT reappear "between A and
      // C" (its original fixed position); it must land after D, at the
      // tail of the rotation.
      q.markReturned('B');
      expect(q.order, ['A', 'C', 'D', 'B']);
      expect(q.nextEligible('D', {}), 'B');
      expect(q.nextEligible('B', {}), 'A');
    });
  });

  group('TurnQueue — repeated mute/unmute does not duplicate (case 6)', () {
    test('markReturned called multiple times for the same id never adds a '
        'duplicate entry', () {
      final q = TurnQueue(['A', 'B', 'C']);
      q.markReturned('A');
      q.markReturned('A');
      q.markReturned('A');
      expect(q.order, ['B', 'C', 'A']);
      expect(q.order.where((id) => id == 'A').length, 1);
    });

    test('mute -> unmute -> mute -> unmute settles correctly each time', () {
      final q = TurnQueue(['A', 'B', 'C']);
      // First mute/unmute cycle.
      expect(q.nextEligible('C', {'A'}), 'B');
      q.markReturned('A');
      expect(q.order, ['B', 'C', 'A']);
      // Second cycle: mute A again, then unmute again.
      expect(q.nextEligible('C', {'A'}), 'B');
      q.markReturned('A');
      expect(q.order, ['B', 'C', 'A']);
      expect(q.order.length, 3);
    });
  });

  group('TurnQueue — multiple muted players are skipped (case 7)', () {
    test('two muted players are both skipped, the remaining player takes '
        'every turn', () {
      final q = TurnQueue(['A', 'B', 'C']);
      const skip = {'A', 'C'};
      expect(q.nextEligible('B', skip), 'B'); // only B is eligible
      expect(q.nextEligible('B', skip), 'B');
    });

    test('unmuting one of several muted players inserts only that one at '
        'the end', () {
      final q = TurnQueue(['A', 'B', 'C', 'D']);
      // B and D muted.
      expect(q.nextEligible('A', {'B', 'D'}), 'C');
      // D unmutes first.
      q.markReturned('D');
      expect(q.order, ['A', 'B', 'C', 'D']);
      expect(q.nextEligible('C', {'B'}), 'D');
      // B unmutes later -> appended after D.
      q.markReturned('B');
      expect(q.order, ['A', 'C', 'D', 'B']);
      expect(q.nextEligible('D', {}), 'B');
      expect(q.nextEligible('B', {}), 'A');
    });
  });

  group('TurnQueue — edge cases', () {
    test('all but one player muted: the sole eligible player keeps '
        'getting turns without the game stalling', () {
      final q = TurnQueue(['A', 'B', 'C']);
      expect(q.nextEligible('A', {'A', 'C'}), 'B');
      expect(q.nextEligible('B', {'A', 'C'}), 'B');
    });

    test('everyone muted (including current) -> null, never a crash, '
        'never a fabricated destination', () {
      final q = TurnQueue(['A', 'B', 'C']);
      expect(q.nextEligible('A', {'A', 'B', 'C'}), isNull);
    });

    test('markReturned for an id no longer in the queue (e.g. left the '
        'game) is a safe no-op', () {
      final q = TurnQueue(['A', 'B', 'C']);
      q.markReturned('ghost');
      expect(q.order, ['A', 'B', 'C']);
    });

    test('a mid-round mute (current player muted, new round starts, they '
        'stay muted) keeps them skipped across the wrap', () {
      final q = TurnQueue(['A', 'B', 'C']);
      const skip = {'A'};
      expect(q.nextEligible('A', skip), 'B');
      expect(q.nextEligible('B', skip), 'C');
      // Wraps back around to A's fixed slot -> still muted -> skipped.
      expect(q.nextEligible('C', skip), 'B');
    });
  });
}
