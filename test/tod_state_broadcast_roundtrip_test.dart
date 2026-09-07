// Regression coverage for the "Player B sees a blank screen after Player A
// submits a ToD response" report. The owner's client never round-trips its
// own state through serialization (it reads TruthOrDareEngine.currentState
// directly) — only a non-owner client does, via
// TodGameProvider.onStateBroadcast -> TodState.fromMap(snapshot['snapshot']).
// These tests reproduce exactly that owner-serializes / follower-
// deserializes path for Truth, Dare+proof, and Punishment, and confirm the
// response/proof data survives it intact. This determinism test found the
// TodState/TodRoundRecord model layer itself round-trips cleanly for every
// scenario tried — the fix applied alongside this test is in
// TodGameProvider.onStateBroadcast, which previously had NO error handling
// around this exact call: if fromMap ever DOES throw (a future field
// mismatch, a corrupted broadcast, etc.), a non-owner client must not be
// silently and permanently stranded — see the try/catch and immediate
// resync request added there.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
import 'package:jma3a/features/games/truth_or_dare/truth_or_dare_engine.dart';

List<TodCard> _deck() => [
  for (var i = 0; i < 10; i++)
    TodCard(id: 'truth$i', content: 'truth $i', type: TodCardType.truth, difficulty: TodDifficulty.mild),
  for (var i = 0; i < 10; i++)
    TodCard(id: 'dare$i', content: 'dare $i', type: TodCardType.dare, difficulty: TodDifficulty.mild),
];

void main() {
  test('owner-serialize -> follower-deserialize round trip: Truth', () {
    final e = TruthOrDareEngine(
      const GameConfig(maxRounds: 10, turnTimerSeconds: 0, allowSkip: true, allowSpicy: false),
      cards: _deck(),
    );
    e.init(playerOrder: ['p1', 'p2']);
    e.handleEvent(TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.truth));
    e.handleEvent(TodCompleteEvent(userId: 'p1', ts: 2, response: 'a real truth answer'));
    final map = e.currentState.toMap();
    final restored = TodState.fromMap(map);
    expect(restored.turnResponse, 'a real truth answer');
    expect(restored.phase, TodTurnPhase.awaitingNextTurn);
  });

  test('owner-serialize -> follower-deserialize round trip: Dare + image proof', () {
    final e = TruthOrDareEngine(
      const GameConfig(maxRounds: 10, turnTimerSeconds: 0, allowSkip: true, allowSpicy: false),
      cards: _deck(),
    );
    e.init(playerOrder: ['p1', 'p2']);
    e.handleEvent(TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.dare));
    e.handleEvent(TodCompleteEvent(userId: 'p1', ts: 2, response: '', proofImageB64: 'imgdata123'));
    final map = e.currentState.toMap();
    final restored = TodState.fromMap(map);
    expect(restored.turnProofImageB64, 'imgdata123');
    expect(restored.phase, TodTurnPhase.awaitingNextTurn);
  });

  test('owner-serialize -> follower-deserialize round trip: punishment', () {
    final e = TruthOrDareEngine(
      const GameConfig(
        maxRounds: 10,
        turnTimerSeconds: 0,
        allowSkip: true,
        allowSpicy: false,
        enablePunishments: true,
        punishmentSource: 'pack',
        suggestedPunishments: ['A', 'B'],
      ),
      cards: _deck(),
    );
    e.init(playerOrder: ['p1', 'p2']);
    e.handleEvent(TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.dare));
    e.handleEvent(TodSkipEvent(userId: 'p1', ts: 2));
    final options = e.currentState.currentPunishmentVote!.options;
    e.handleEvent(TodVotePunishmentEvent(userId: 'p1', ts: 3, optionId: options.first.id));
    e.handleEvent(TodCompleteEvent(userId: 'p1', ts: 4, response: 'did the punishment'));
    final map = e.currentState.toMap();
    final restored = TodState.fromMap(map);
    expect(restored.turnResponse, 'did the punishment');
    expect(restored.phase, TodTurnPhase.awaitingNextTurn);
  });

  test('round trip after advanceTurn (history populated, next round)', () {
    final e = TruthOrDareEngine(
      const GameConfig(maxRounds: 10, turnTimerSeconds: 0, allowSkip: true, allowSpicy: false),
      cards: _deck(),
    );
    e.init(playerOrder: ['p1', 'p2']);
    e.handleEvent(TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.truth));
    e.handleEvent(TodCompleteEvent(userId: 'p1', ts: 2, response: 'answer one'));
    e.advanceTurn();
    final map = e.currentState.toMap();
    final restored = TodState.fromMap(map);
    expect(restored.history.length, 1);
    expect(restored.history.first.response, 'answer one');
  });
}
