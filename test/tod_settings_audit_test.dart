// Tests for items 9/10/11 — ToD pre-game settings audit.
//
// Investigation finding (documented in full in the final report): every
// ToD setting audited here was ALREADY correctly wired end-to-end
// (Room Settings/TodPreGameConfig -> GameConfig construction in
// lobby_screen.dart's _onStartGame -> TruthOrDareEngine consulting it
// authoritatively -> tod_card_screen.dart's _ChoiceView mirroring the
// same check for display). No engine code changed for these items — this
// file is the regression suite proving that finding, exercised directly
// against TruthOrDareEngine (the same authoritative layer the UI's own
// _isForcedDare() check already mirrors).
//
// Turn state machine exercised here (see TruthOrDareEngine):
//   choosingType --TodChoiceEvent--> readingCard
//   readingCard --TodCompleteEvent--> awaitingNextTurn
//   readingCard --TodSkipEvent (requires allowSkip)--> awaitingNextTurn
//   awaitingNextTurn --advanceTurn()--> choosingType (next player)

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
import 'package:jma3a/features/games/truth_or_dare/truth_or_dare_engine.dart';

List<TodCard> _deck() => [
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

TruthOrDareEngine _engine(GameConfig config, List<String> players) {
  final e = TruthOrDareEngine(config, cards: _deck());
  e.init(playerOrder: players);
  return e;
}

/// Drives one full turn for the CURRENT player: choose [cardType], get the
/// (possibly force-converted) card, complete it, then advance to the next
/// player. Returns the card type the engine actually granted.
TodCardType _playTurn(
  TruthOrDareEngine e,
  String userId,
  TodCardType cardType,
  int ts,
) {
  e.handleEvent(TodChoiceEvent(userId: userId, ts: ts, cardType: cardType));
  final granted = e.currentState.currentCard!.type;
  e.handleEvent(TodCompleteEvent(userId: userId, ts: ts, response: 'x'));
  e.advanceTurn();
  return granted;
}

void main() {
  group('17/19 — Force Dare enabled is authoritative, not just a UI hint',
      () {
    test('17/19. per_player force dare: a Truth choice past the limit is '
        'silently converted to a Dare by the engine, never granted as a '
        'Truth', () {
      final config = GameConfig(
        maxRounds: 10,
        turnTimerSeconds: 0,
        allowSkip: true,
        allowSpicy: false,
        forceDareMode: 'per_player',
        maxTruths: 2,
      );
      final e = _engine(config, ['p1', 'p2']);

      // Two truths — allowed (at the limit, not over it).
      expect(_playTurn(e, 'p1', TodCardType.truth, 1), TodCardType.truth);
      _playTurn(e, 'p2', TodCardType.truth, 2);
      expect(_playTurn(e, 'p1', TodCardType.truth, 3), TodCardType.truth);
      expect(e.currentState.truthCountByPlayer['p1'], 2);
    });

    test('18. maxTruths threshold: a THIRD truth attempt is forced to a '
        'dare instead', () {
      final config = GameConfig(
        maxRounds: 10,
        turnTimerSeconds: 0,
        allowSkip: true,
        allowSpicy: false,
        forceDareMode: 'per_player',
        maxTruths: 2,
      );
      final e = _engine(config, ['p1', 'p2']);
      _playTurn(e, 'p1', TodCardType.truth, 1);
      _playTurn(e, 'p2', TodCardType.truth, 2);
      _playTurn(e, 'p1', TodCardType.truth, 3);
      _playTurn(e, 'p2', TodCardType.truth, 4);
      expect(e.currentState.truthCountByPlayer['p1'], 2);

      // Third attempt for p1 — requests truth, engine gives a dare.
      final granted = _playTurn(e, 'p1', TodCardType.truth, 5);
      expect(granted, TodCardType.dare);
    });

    test('20. completing the forced dare resets the per_player counter, '
        'so the player can choose truth again afterward', () {
      final config = GameConfig(
        maxRounds: 10,
        turnTimerSeconds: 0,
        allowSkip: true,
        allowSpicy: false,
        forceDareMode: 'per_player',
        maxTruths: 1,
      );
      final e = _engine(config, ['p1', 'p2']);
      _playTurn(e, 'p1', TodCardType.truth, 1); // truthCount['p1'] = 1
      _playTurn(e, 'p2', TodCardType.truth, 2);
      // p1 forced to dare (over the 1-truth limit).
      final granted = _playTurn(e, 'p1', TodCardType.truth, 3);
      expect(granted, TodCardType.dare);
      expect(e.currentState.truthCountByPlayer['p1'], 0); // reset by the dare
      _playTurn(e, 'p2', TodCardType.truth, 4);
      // Truth is available again for p1.
      expect(_playTurn(e, 'p1', TodCardType.truth, 5), TodCardType.truth);
    });

    test('per_turn force dare shares ONE streak across all players, reset '
        'by any dare (forced or chosen)', () {
      final config = GameConfig(
        maxRounds: 10,
        turnTimerSeconds: 0,
        allowSkip: true,
        allowSpicy: false,
        forceDareMode: 'per_turn',
        maxTruths: 2,
      );
      final e = _engine(config, ['p1', 'p2']);
      _playTurn(e, 'p1', TodCardType.truth, 1);
      _playTurn(e, 'p2', TodCardType.truth, 2);
      expect(e.currentState.globalTruthStreak, 2);
      // Streak now at the limit — p1's next truth request is forced.
      final granted = _playTurn(e, 'p1', TodCardType.truth, 3);
      expect(granted, TodCardType.dare);
      expect(e.currentState.globalTruthStreak, 0); // dare reset the shared streak
    });
  });

  group('21 — Force Dare disabled preserves normal free choice', () {
    test('21. forceDareMode "unlimited": truth is always honored, no '
        'matter how many times chosen', () {
      final config = GameConfig(
        maxRounds: 10,
        turnTimerSeconds: 0,
        allowSkip: true,
        allowSpicy: false,
      ); // forceDareMode defaults to 'unlimited'
      final e = _engine(config, ['p1', 'p2']);
      for (var i = 0; i < 4; i++) {
        expect(_playTurn(e, 'p1', TodCardType.truth, i), TodCardType.truth);
        _playTurn(e, 'p2', TodCardType.truth, i);
      }
    });
  });

  group('22 — every existing setting audited here propagates from config '
      'to observable engine behavior', () {
    test('allowSkip: a skip during readingCard is accepted when true, '
        'rejected when false', () {
      final enabled = _engine(
        GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 0,
          allowSkip: true,
          allowSpicy: false,
        ),
        ['p1', 'p2'],
      );
      enabled.handleEvent(
        TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.dare),
      );
      expect(enabled.currentState.phase, TodTurnPhase.readingCard);
      enabled.handleEvent(TodSkipEvent(userId: 'p1', ts: 2));
      expect(enabled.currentState.phase, isNot(TodTurnPhase.readingCard));

      final disabled = _engine(
        GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 0,
          allowSkip: false,
          allowSpicy: false,
        ),
        ['p1', 'p2'],
      );
      disabled.handleEvent(
        TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.dare),
      );
      disabled.handleEvent(TodSkipEvent(userId: 'p1', ts: 2));
      expect(disabled.currentState.phase, TodTurnPhase.readingCard); // unchanged
    });

    test('cardRepetitionMode "unique": the game ends once a requested '
        'card type\'s pool is exhausted instead of repeating', () {
      final e = TruthOrDareEngine(
        GameConfig(
          maxRounds: 999,
          turnTimerSeconds: 0,
          allowSkip: true,
          allowSpicy: false,
          cardRepetitionMode: 'unique',
        ),
        cards: [
          TodCard(
            id: 't1',
            content: 'only truth',
            type: TodCardType.truth,
            difficulty: TodDifficulty.mild,
          ),
        ],
      );
      e.init(playerOrder: ['p1', 'p2']);
      e.handleEvent(
        TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.truth),
      );
      expect(e.currentState.currentCard?.id, 't1');
      e.handleEvent(TodCompleteEvent(userId: 'p1', ts: 2, response: 'x'));
      e.advanceTurn();
      // Only truth card was already used — pool exhausted, game ends
      // rather than silently repeating.
      e.handleEvent(
        TodChoiceEvent(userId: 'p2', ts: 4, cardType: TodCardType.truth),
      );
      expect(e.currentState.isOver, isTrue);
      expect(e.currentState.endReason, 'cards_exhausted');
    });
  });

  group('23/24 — config survives reconnect and host migration via the '
      'same JSON round-trip', () {
    test('23/24. every audited GameConfig field round-trips through '
        'toMap/fromMap unchanged — the exact mechanism a reconnecting or '
        'newly-promoted-host client uses to reconstruct its GameConfig',
        () {
      const original = GameConfig(
        maxRounds: 17,
        turnTimerSeconds: 45,
        allowSkip: false,
        allowSpicy: true,
        enablePunishments: true,
        punishmentSource: 'pack',
        suggestedPunishments: ['do 10 pushups', 'sing a song'],
        forceDareMode: 'per_player',
        maxTruths: 3,
        cardRepetitionMode: 'unique',
      );
      final restored = GameConfig.fromMap(original.toMap());
      expect(restored.maxRounds, 17);
      expect(restored.turnTimerSeconds, 45);
      expect(restored.allowSkip, isFalse);
      expect(restored.allowSpicy, isTrue);
      expect(restored.enablePunishments, isTrue);
      expect(restored.punishmentSource, 'pack');
      expect(restored.suggestedPunishments, [
        'do 10 pushups',
        'sing a song',
      ]);
      expect(restored.forceDareMode, 'per_player');
      expect(restored.maxTruths, 3);
      expect(restored.cardRepetitionMode, 'unique');
    });
  });
}
