// Tests for items 18.4/18.5/18.6 — premium custom cards and the round
// capacity they must correctly extend.
//
// Two real, distinct engine-level bugs were found and fixed here:
//   1. NeverHaveIEverEngine.advanceTurn() only incremented roundNumber
//      once every full cycle of currentPlayerIndex (a leftover from a
//      per-player-turn model that was never actually true for NHIE's
//      simultaneous voting) — an N-player game silently needed N times as
//      many cards as maxRounds implied. Meme's own advanceTurn() was
//      already correct (unconditional +1 per call); this file proves NHIE
//      now matches it, and matches round_capacity.dart's own documented/
//      tested "one card per round, player count irrelevant" model.
//   2. Both NeverHaveIEverEngine.injectCard and MemeGameEngine.injectCard
//      computed their maxRounds bump as `(cards.length / playerCount)
//      .ceil()` — dividing by player count when the actual per-round cost
//      for these two games is 1, regardless of player count (see
//      round_capacity.dart's cardsConsumedPerRound). Both now reuse the
//      one shared calculateMaxPossibleRounds instead of a second,
//      duplicated (and wrong) formula.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/engine/round_capacity.dart';
import 'package:jma3a/features/games/meme_game/meme_game_engine.dart';
import 'package:jma3a/features/games/never_have_i_ever/never_have_i_ever_engine.dart';

GameConfig _config({int maxRounds = 5}) => GameConfig(
  maxRounds: maxRounds,
  turnTimerSeconds: 0,
  allowSkip: true,
  allowSpicy: false,
);

NeverHaveIEverEngine _nhie(List<String> players, {int maxRounds = 5, int cardCount = 20}) {
  final e = NeverHaveIEverEngine(
    _config(maxRounds: maxRounds),
    cards: [
      for (var i = 0; i < cardCount; i++)
        NhieCard(id: 'c$i', content: 'card $i', difficulty: 'mild'),
    ],
  );
  e.init(players);
  return e;
}

MemeGameEngine _meme(List<String> players, {int maxRounds = 5, int cardCount = 20}) {
  final e = MemeGameEngine(
    _config(maxRounds: maxRounds),
    prompts: [for (var i = 0; i < cardCount; i++) MemePrompt(id: 'p$i', caption: 'c$i')],
  );
  e.init(players);
  return e;
}

void main() {
  group('26. NHIE round-increment root-cause fix — one card per round, '
      'independent of player count', () {
    test(
      '4 players, maxRounds=5, exactly 5 cards: the 5th advanceTurn() '
      'reaches maxRounds and the game ends — NOT after 5*4=20 cards',
      () {
        final e = _nhie(['p1', 'p2', 'p3', 'p4'], maxRounds: 5, cardCount: 5);
        expect(e.currentState.roundNumber, 1);
        for (var i = 0; i < 4; i++) {
          e.advanceTurn();
          expect(e.currentState.isOver, isFalse, reason: 'round ${i + 2}');
        }
        // 5 advanceTurn() calls total (1 initial + 4 more) have now drawn
        // exactly 5 cards — the deck is exhausted at precisely
        // roundNumber == maxRounds, matching round_capacity.dart's
        // "1 card per round, player count irrelevant" formula exactly.
        expect(e.currentState.roundNumber, 5);
        e.advanceTurn();
        expect(e.currentState.isOver, isTrue);
      },
    );

    test(
      '8 players behave identically to 2 players for round pacing — the '
      'bug this replaces made round pacing scale with player count',
      () {
        final e2 = _nhie(['p1', 'p2'], maxRounds: 3, cardCount: 3);
        final e8 = _nhie(
          ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'],
          maxRounds: 3,
          cardCount: 3,
        );
        e2.advanceTurn();
        e8.advanceTurn();
        expect(e2.currentState.roundNumber, e8.currentState.roundNumber);
        expect(e2.currentState.isOver, e8.currentState.isOver);
      },
    );
  });

  group('24/25/26/27/28 — custom cards enter the real pool and correctly '
      'extend capacity', () {
    test(
      'NHIE: injecting 10 custom cards on top of 20 pack cards raises '
      'maxRounds to the FULL 30 (never divided by player count)',
      () {
        final e = _nhie(['p1', 'p2', 'p3', 'p4'], maxRounds: 5, cardCount: 20);
        for (var i = 0; i < 10; i++) {
          e.injectCard(NhieCard(id: 'custom$i', content: 'x', difficulty: 'mild'));
        }
        expect(e.currentState.maxRounds, 30);
        expect(
          e.currentState.maxRounds,
          calculateMaxPossibleRounds(
            gameType: GameType.neverHaveIEver,
            availableCardCount: 30,
            activePlayers: 4,
            uniqueCards: true,
          ),
        );
      },
    );

    test(
      'Meme: injecting 10 custom prompts on top of 20 pack prompts raises '
      'maxRounds to the FULL 30 (never divided by player count)',
      () {
        final e = _meme(['p1', 'p2', 'p3', 'p4'], maxRounds: 5, cardCount: 20);
        for (var i = 0; i < 10; i++) {
          e.injectCard(MemePrompt(id: 'custom$i', caption: 'x'));
        }
        expect(e.currentState.maxRounds, 30);
      },
    );

    test('injectCard never LOWERS an already-larger maxRounds', () {
      final e = _nhie(['p1', 'p2'], maxRounds: 50, cardCount: 20);
      e.injectCard(NhieCard(id: 'custom0', content: 'x', difficulty: 'mild'));
      expect(e.currentState.maxRounds, 50);
    });

    test(
      '25/29. an injected custom card is actually drawable and '
      'participates in the same used-card tracking as pack cards',
      () {
        final e = _nhie(['p1', 'p2'], maxRounds: 1, cardCount: 1);
        e.injectCard(NhieCard(id: 'custom0', content: 'custom!', difficulty: 'mild'));
        // maxRounds was auto-bumped to 2 (1 pack + 1 custom); advancing
        // once must reach the injected card, never repeat the first.
        final firstId = e.currentState.currentCard?.id;
        e.advanceTurn();
        expect(e.currentState.isOver, isFalse);
        expect(e.currentState.currentCard?.id, isNot(firstId));
        expect(e.currentState.currentCard?.id, 'custom0');
      },
    );

    test('30/31. the custom-extended maxRounds and deck position survive '
        'serialize/restore (reconnect/host-migration path)', () {
      final e = _nhie(['p1', 'p2'], maxRounds: 5, cardCount: 20);
      for (var i = 0; i < 10; i++) {
        e.injectCard(NhieCard(id: 'custom$i', content: 'x', difficulty: 'mild'));
      }
      final snapshot = e.serializeState();
      final restored = NhieState.fromMap(snapshot);
      // maxRounds lives in NhieState itself (not just engine-local memory)
      // — this IS what a reconnecting/newly-promoted-host client actually
      // restores from.
      expect(restored.maxRounds, 30);
    });
  });

  group('32. a brand-new game starts with a fresh, un-extended capacity', () {
    test('re-calling init() on a fresh engine ignores any prior injected '
        'state — maxRounds comes only from GameConfig again', () {
      final e = _nhie(['p1', 'p2'], maxRounds: 5, cardCount: 20);
      e.injectCard(NhieCard(id: 'custom0', content: 'x', difficulty: 'mild'));
      expect(e.currentState.maxRounds, greaterThan(5));
      // A brand-new engine for a brand-new game (the actual real-world
      // "new game" path — see NhieGameProvider.initAsOwner constructing a
      // fresh NeverHaveIEverEngine each time) never carries over the
      // previous game's injected cards or bumped maxRounds.
      final fresh = _nhie(['p1', 'p2'], maxRounds: 5, cardCount: 20);
      expect(fresh.currentState.maxRounds, 5);
    });
  });
}
