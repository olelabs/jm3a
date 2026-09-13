// Regression coverage for "muted = temporary spectator for turn purposes":
// exercises the REAL engines (TruthOrDareEngine / NeverHaveIEverEngine)
// together with TurnQueue exactly the way TodGameProvider.ownerAdvanceTurn
// / NhieGameProvider.ownerAdvanceTurn actually drive them — compute the
// next eligible id via TurnQueue.nextEligible(currentId, skipIds), then
// call engine.advanceTurn(forcePlayerId: nextId). A full TodGameProvider/
// NhieGameProvider can't be constructed in an offline suite (both require
// a live Supabase-backed repository/RealtimeService/RoomProvider — see
// tod_punishment_sync_regression_test.dart's own doc comment for this
// project's established boundary), so this is the actual shared decision
// point (TurnQueue + the real engine's forcePlayerId handling) tested at
// the layer that's genuinely offline-testable, rather than re-deriving
// index math in the test itself.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/engine/turn_queue.dart';
import 'package:jma3a/features/games/never_have_i_ever/never_have_i_ever_engine.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
import 'package:jma3a/features/games/truth_or_dare/truth_or_dare_engine.dart';

List<TodCard> _todDeck() => [
  for (var i = 0; i < 20; i++)
    TodCard(
      id: 'truth$i',
      content: 'truth $i',
      type: TodCardType.truth,
      difficulty: TodDifficulty.mild,
    ),
  for (var i = 0; i < 20; i++)
    TodCard(
      id: 'dare$i',
      content: 'dare $i',
      type: TodCardType.dare,
      difficulty: TodDifficulty.mild,
    ),
];

TruthOrDareEngine _tod(List<String> players) {
  final config = GameConfig(
    maxRounds: 20,
    turnTimerSeconds: 0,
    allowSkip: true,
    allowSpicy: false,
  );
  final e = TruthOrDareEngine(config, cards: _todDeck());
  e.init(playerOrder: players);
  return e;
}

NeverHaveIEverEngine _nhie(List<String> players) {
  final config = GameConfig(
    maxRounds: 20,
    turnTimerSeconds: 0,
    allowSkip: true,
    allowSpicy: false,
  );
  final e = NeverHaveIEverEngine(
    config,
    cards: [
      for (var i = 0; i < 20; i++)
        NhieCard(id: 'c$i', content: 'card $i', difficulty: 'mild'),
    ],
  );
  e.init(players);
  return e;
}

/// Mirrors ownerAdvanceTurn's own logic exactly: ask the TurnQueue who's
/// next given the current skip set, then force the engine to land there.
/// Returns the resulting currentPlayerId, or null if nobody was eligible
/// (in which case the engine is left untouched, matching both providers'
/// own "don't advance if nobody is eligible" guard).
String? _advance(BaseGameEngine engine, TurnQueue q, Set<String> skip) {
  final state = engine.currentState;
  final currentId = (state as dynamic).currentPlayerId as String;
  final nextId = q.nextEligible(currentId, skip);
  if (nextId == null) return null;
  (engine as dynamic).advanceTurn(forcePlayerId: nextId);
  return (engine.currentState as dynamic).currentPlayerId as String;
}

void main() {
  group('Truth or Dare — engine + TurnQueue integration', () {
    test('1&4: muting the current player skips them immediately, a muted '
        'candidate is never selected', () {
      final e = _tod(['A', 'B', 'C']);
      final q = TurnQueue(['A', 'B', 'C']);
      expect(e.currentState.currentPlayerId, 'A');
      // A's turn, A gets muted.
      expect(_advance(e, q, {'A'}), 'B');
      expect(_advance(e, q, {'A'}), 'C');
      // Wraps back to A's fixed slot — still muted -> skipped again.
      expect(_advance(e, q, {'A'}), 'B');
    });

    test('2: A muted before their turn ever comes -> B/C alternate forever',
        () {
      final e = _tod(['A', 'B', 'C']);
      final q = TurnQueue(['A', 'B', 'C']);
      const skip = {'A'};
      expect(_advance(e, q, skip), 'B');
      expect(_advance(e, q, skip), 'C');
      expect(_advance(e, q, skip), 'B');
      expect(_advance(e, q, skip), 'C');
    });

    test('5: unmute places the player at the end of the active rotation, '
        'not their original fixed slot — the brief\'s own worked example',
        () {
      final e = _tod(['A', 'B', 'C']);
      final q = TurnQueue(['A', 'B', 'C']);
      expect(_advance(e, q, {'A'}), 'B'); // A muted at their own turn
      expect(_advance(e, q, {'A'}), 'C');
      q.markReturned('A'); // unmute
      expect(_advance(e, q, {}), 'A');
      expect(_advance(e, q, {}), 'B');
      expect(_advance(e, q, {}), 'C');
    });

    test('7: multiple muted players are both skipped; the sole remaining '
        'player keeps getting turns (all-but-one-muted)', () {
      final e = _tod(['A', 'B', 'C']);
      final q = TurnQueue(['A', 'B', 'C']);
      const skip = {'A', 'C'};
      expect(_advance(e, q, skip), 'B');
      expect(_advance(e, q, skip), 'B');
      expect(_advance(e, q, skip), 'B');
    });

    test('6: repeated mute/unmute of the same player does not duplicate '
        'them in the rotation or break subsequent turns', () {
      final e = _tod(['A', 'B', 'C']);
      final q = TurnQueue(['A', 'B', 'C']);
      expect(_advance(e, q, {'A'}), 'B');
      q.markReturned('A');
      q.markReturned('A'); // repeat, must be a no-op the second time
      expect(q.order, ['B', 'C', 'A']);
      expect(_advance(e, q, {}), 'C');
      expect(_advance(e, q, {}), 'A');
      expect(_advance(e, q, {}), 'B');
    });

    test('everyone (including current) muted -> advance is a no-op, the '
        'game does not crash or invent a destination', () {
      final e = _tod(['A', 'B', 'C']);
      final q = TurnQueue(['A', 'B', 'C']);
      expect(_advance(e, q, {'A', 'B', 'C'}), isNull);
      expect(e.currentState.currentPlayerId, 'A'); // untouched
    });

    test('round number only advances once per full lap even when players '
        'are skipped mid-lap (sanity check on the generalized wrap '
        'detection used for forcePlayerId)', () {
      final e = _tod(['A', 'B', 'C']);
      final q = TurnQueue(['A', 'B', 'C']);
      expect(e.currentState.roundNumber, 1);
      _advance(e, q, {'A'}); // -> B, still round 1
      expect(e.currentState.roundNumber, 1);
      _advance(e, q, {'A'}); // -> C, still round 1
      expect(e.currentState.roundNumber, 1);
      _advance(e, q, {'A'}); // wraps back toward A (skipped) -> B, round 2
      expect(e.currentState.roundNumber, 2);
    });
  });

  group('Never Have I Ever — engine + TurnQueue integration', () {
    test('1&2&4: a muted revealer candidate is never selected, before or '
        'during their slot', () {
      final e = _nhie(['A', 'B', 'C']);
      final q = TurnQueue(['A', 'B', 'C']);
      expect(e.currentState.currentPlayerId, 'A');
      expect(_advance(e, q, {'A'}), 'B');
      expect(_advance(e, q, {'A'}), 'C');
      expect(_advance(e, q, {'A'}), 'B');
    });

    test('5: unmute places the player at the end of the active rotation',
        () {
      final e = _nhie(['A', 'B', 'C']);
      final q = TurnQueue(['A', 'B', 'C']);
      expect(_advance(e, q, {'A'}), 'B');
      expect(_advance(e, q, {'A'}), 'C');
      q.markReturned('A');
      expect(_advance(e, q, {}), 'A');
      expect(_advance(e, q, {}), 'B');
    });

    test('NHIE\'s round always advances exactly once per advanceTurn call '
        'regardless of forcePlayerId (the one-call-one-round invariant is '
        'unaffected by the mute fix)', () {
      final e = _nhie(['A', 'B', 'C']);
      final q = TurnQueue(['A', 'B', 'C']);
      expect(e.currentState.roundNumber, 1);
      _advance(e, q, {'A'});
      expect(e.currentState.roundNumber, 2);
      _advance(e, q, {'A'});
      expect(e.currentState.roundNumber, 3);
    });

    test('7: multiple muted revealer candidates are skipped', () {
      final e = _nhie(['A', 'B', 'C']);
      final q = TurnQueue(['A', 'B', 'C']);
      const skip = {'A', 'C'};
      expect(_advance(e, q, skip), 'B');
      expect(_advance(e, q, skip), 'B');
    });
  });
}
