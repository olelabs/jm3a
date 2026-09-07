// ToD Dare honesty votes must move honesty_points by exactly ±2,
// independently of the normal Truth/Punishment rate — see
// 20260901090600_honesty_dare_points.sql. The server derives the actual
// point delta from cast_honesty_vote's new p_card_type parameter; this
// covers the ONE piece of client-side logic that decides what value to
// send: TodCard.honestyVoteCardType and honestyVoteCardTypeForRound,
// which read the type from the engine's own broadcast state (history) —
// never chosen ad hoc by the voter.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';

TodCard _card({required String id, required TodCardType type}) => TodCard(
  id: id,
  content: 'content',
  type: type,
  difficulty: TodDifficulty.mild,
);

TodState _stateWithHistory(List<TodRoundRecord> history, int roundNumber) =>
    TodState(
      snapshotAt: 0,
      playerOrder: const ['p1', 'p2'],
      currentPlayerIndex: 0,
      phase: TodTurnPhase.awaitingNextTurn,
      roundNumber: roundNumber,
      maxRounds: 10,
      scores: const {},
      history: history,
    );

void main() {
  group('TodCard.isPunishment / honestyVoteCardType', () {
    test('a real Truth card is truth, never punishment', () {
      final card = _card(id: 'card_1', type: TodCardType.truth);
      expect(card.isPunishment, isFalse);
      expect(card.honestyVoteCardType, 'truth');
    });

    test('a real Dare card (not a punishment id) is dare', () {
      final card = _card(id: 'card_2', type: TodCardType.dare);
      expect(card.isPunishment, isFalse);
      expect(card.honestyVoteCardType, 'dare');
    });

    test('a synthesized punishment card is punishment, not dare, even '
        'though its TodCardType is dare', () {
      final card = _card(id: 'punishment_opt3', type: TodCardType.dare);
      expect(card.isPunishment, isTrue);
      expect(card.honestyVoteCardType, 'punishment');
    });

    test('a punishment-prefixed id can never occur on a Truth (defensive — '
        'the type check wins first regardless)', () {
      final card = _card(id: 'punishment_weird', type: TodCardType.truth);
      expect(card.honestyVoteCardType, 'truth');
    });
  });

  group('honestyVoteCardTypeForRound', () {
    test('finds the matching round\'s card type from history', () {
      final state = _stateWithHistory([
        TodRoundRecord(
          roundNumber: 1,
          playerId: 'p1',
          card: _card(id: 'c1', type: TodCardType.truth),
          response: 'answer',
        ),
        TodRoundRecord(
          roundNumber: 2,
          playerId: 'p2',
          card: _card(id: 'c2', type: TodCardType.dare),
          response: 'did it',
        ),
      ], 2);
      expect(honestyVoteCardTypeForRound(state, 2), 'dare');
      expect(honestyVoteCardTypeForRound(state, 1), 'truth');
    });

    test('identifies a punishment round from history', () {
      final state = _stateWithHistory([
        TodRoundRecord(
          roundNumber: 3,
          playerId: 'p1',
          card: _card(id: 'punishment_x', type: TodCardType.dare),
          response: 'did the punishment',
        ),
      ], 3);
      expect(honestyVoteCardTypeForRound(state, 3), 'punishment');
    });

    test('returns null when no record matches the round (defensive — '
        'server falls back to the existing normal rate on null, unchanged '
        'from before this parameter existed)', () {
      final state = _stateWithHistory(const [], 5);
      expect(honestyVoteCardTypeForRound(state, 5), isNull);
    });

    test('returns null when the matching record has no card (defensive)', () {
      final state = _stateWithHistory([
        const TodRoundRecord(
          roundNumber: 4,
          playerId: 'p1',
          card: null,
          response: 'x',
        ),
      ], 4);
      expect(honestyVoteCardTypeForRound(state, 4), isNull);
    });

    test('picks the LAST matching record when a round number repeats in '
        'history (defensive against any future replay/retry semantics)',
        () {
      final state = _stateWithHistory([
        TodRoundRecord(
          roundNumber: 6,
          playerId: 'p1',
          card: _card(id: 'stale', type: TodCardType.truth),
          response: 'first',
        ),
        TodRoundRecord(
          roundNumber: 6,
          playerId: 'p1',
          card: _card(id: 'fresh', type: TodCardType.dare),
          response: 'second',
        ),
      ], 6);
      expect(honestyVoteCardTypeForRound(state, 6), 'dare');
    });
  });
}
