// Tests for two ToD server-authoritative (owner-engine) fixes:
//
//  1. Pack-sourced punishment reuse prevention (TruthOrDareEngine._onSkip /
//     _resolvePunishment, TodState.usedPunishmentIndices) — a pack
//     punishment already picked this game is excluded from the options
//     offered on a later skip, until every option has been used at least
//     once, at which point the pool cycles rather than leaving zero
//     eligible options.
//
//  2. Done/complete response-and-proof validation (TruthOrDareEngine.
//     _onComplete) — a modified client sending a 'tod_complete' broadcast
//     directly (bypassing the Flutter UI's own gate) is rejected by the
//     same owner-run engine that already authoritatively enforces every
//     other ToD rule (Force Dare, allowSkip — see the existing doc
//     comments in truth_or_dare_engine.dart), not just hidden client-side.
//
// Exercised against the REAL TruthOrDareEngine, the same offline-testable
// boundary used by test/tod_skip_punishment_regression_test.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
import 'package:jma3a/features/games/truth_or_dare/truth_or_dare_engine.dart';

List<TodCard> _deck() => [
  for (var i = 0; i < 10; i++)
    TodCard(
      id: 'truth$i',
      content: 'truth $i',
      type: TodCardType.truth,
      difficulty: TodDifficulty.mild,
    ),
  for (var i = 0; i < 10; i++)
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

void main() {
  group('Pack punishment reuse prevention', () {
    test(
      'a punishment already picked is excluded from later options; once '
      'every option has been used the pool cycles instead of emptying',
      () {
        final e = _engine(
          const GameConfig(
            maxRounds: 10,
            turnTimerSeconds: 0,
            allowSkip: true,
            allowSpicy: false,
            enablePunishments: true,
            punishmentSource: 'pack',
            suggestedPunishments: ['A', 'B'],
          ),
          ['p1', 'p2'],
        );

        // Round 1 (p1): skip -> both options offered.
        e.handleEvent(
          TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.dare),
        );
        e.handleEvent(TodSkipEvent(userId: 'p1', ts: 2));
        var options = e.currentState.currentPunishmentVote!.options;
        expect(options.length, 2);
        expect(options.map((o) => o.sourceIndex).toSet(), {0, 1});

        // p1 picks index 0 ('A').
        final idA = options.firstWhere((o) => o.sourceIndex == 0).id;
        e.handleEvent(TodVotePunishmentEvent(userId: 'p1', ts: 3, optionId: idA));
        expect(e.currentState.usedPunishmentIndices, [0]);
        e.handleEvent(
          TodCompleteEvent(userId: 'p1', ts: 4, response: 'done'),
        );
        e.advanceTurn(); // -> p2's turn

        // Round 2 (p2): only 'B' (index 1) should be offered now.
        e.handleEvent(
          TodChoiceEvent(userId: 'p2', ts: 5, cardType: TodCardType.dare),
        );
        e.handleEvent(TodSkipEvent(userId: 'p2', ts: 6));
        options = e.currentState.currentPunishmentVote!.options;
        expect(options.length, 1);
        expect(options.single.sourceIndex, 1);

        final idB = options.single.id;
        e.handleEvent(TodVotePunishmentEvent(userId: 'p2', ts: 7, optionId: idB));
        expect(e.currentState.usedPunishmentIndices.toSet(), {0, 1});
        e.handleEvent(
          TodCompleteEvent(userId: 'p2', ts: 8, response: 'done'),
        );
        e.advanceTurn(); // -> p1's turn

        // Round 3 (p1): every option has now been used once — the pool
        // cycles back to both, rather than offering zero options.
        e.handleEvent(
          TodChoiceEvent(userId: 'p1', ts: 9, cardType: TodCardType.dare),
        );
        e.handleEvent(TodSkipEvent(userId: 'p1', ts: 10));
        options = e.currentState.currentPunishmentVote!.options;
        expect(options.length, 2);
      },
    );

    test(
      'peer-proposed punishments (punishmentSource: players, the default) '
      'are entirely unaffected — no sourceIndex, never tracked as used',
      () {
        final e = _engine(
          const GameConfig(
            maxRounds: 10,
            turnTimerSeconds: 0,
            allowSkip: true,
            allowSpicy: false,
            enablePunishments: true,
          ),
          ['p1', 'p2'],
        );
        e.handleEvent(
          TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.dare),
        );
        e.handleEvent(TodSkipEvent(userId: 'p1', ts: 2));
        e.handleEvent(
          TodProposePunishmentEvent(userId: 'p2', ts: 3, text: 'do 10 pushups'),
        );
        final option = e.currentState.currentPunishmentVote!.options.single;
        expect(option.sourceIndex, isNull);
        e.handleEvent(
          TodVotePunishmentEvent(userId: 'p1', ts: 4, optionId: option.id),
        );
        expect(e.currentState.usedPunishmentIndices, isEmpty);
      },
    );
  });

  group('Done/complete server-side validation (_onComplete)', () {
    test('Truth: empty or whitespace-only response is rejected', () {
      final e = _engine(
        const GameConfig(maxRounds: 10, turnTimerSeconds: 0, allowSkip: true, allowSpicy: false),
        ['p1', 'p2'],
      );
      e.handleEvent(
        TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.truth),
      );
      e.handleEvent(TodCompleteEvent(userId: 'p1', ts: 2, response: ''));
      expect(e.currentState.phase, TodTurnPhase.readingCard);
      e.handleEvent(TodCompleteEvent(userId: 'p1', ts: 3, response: '   '));
      expect(e.currentState.phase, TodTurnPhase.readingCard);
      e.handleEvent(
        TodCompleteEvent(userId: 'p1', ts: 4, response: 'a real answer'),
      );
      expect(e.currentState.phase, TodTurnPhase.awaitingNextTurn);
    });

    test(
      'Dare: neither text nor proof is rejected; proof alone (no text) is '
      'accepted, matching a photo-only "response"',
      () {
        final e = _engine(
          const GameConfig(maxRounds: 10, turnTimerSeconds: 0, allowSkip: true, allowSpicy: false),
          ['p1', 'p2'],
        );
        e.handleEvent(
          TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.dare),
        );
        e.handleEvent(TodCompleteEvent(userId: 'p1', ts: 2, response: ''));
        expect(e.currentState.phase, TodTurnPhase.readingCard);

        e.handleEvent(
          TodCompleteEvent(
            userId: 'p1',
            ts: 3,
            response: '',
            proofImageB64: 'imgdata',
          ),
        );
        expect(e.currentState.phase, TodTurnPhase.awaitingNextTurn);
      },
    );

    test(
      'Dare: text alone (no proof) is accepted — unrelated to any proof-'
      'vote requirement',
      () {
        final e = _engine(
          const GameConfig(maxRounds: 10, turnTimerSeconds: 0, allowSkip: true, allowSpicy: false),
          ['p1', 'p2'],
        );
        e.handleEvent(
          TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.dare),
        );
        e.handleEvent(
          TodCompleteEvent(userId: 'p1', ts: 2, response: 'I did it'),
        );
        expect(e.currentState.phase, TodTurnPhase.awaitingNextTurn);
      },
    );

    test(
      'a proof-vote-decided required proof type is enforced regardless of '
      'text — voice required means voice must be attached',
      () {
        final e = _engine(
          const GameConfig(maxRounds: 10, turnTimerSeconds: 0, allowSkip: true, allowSpicy: false),
          ['p1', 'p2', 'p3'],
        );
        e.handleEvent(
          TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.dare),
        );
        e.handleEvent(TodStartProofVoteEvent(userId: 'p1', ts: 2));
        e.handleEvent(
          TodCastProofVoteEvent(
            userId: 'p2',
            ts: 3,
            option: TodProofVoteOption.voiceProof,
          ),
        );
        expect(
          e.currentState.proofVoteState!.winner,
          TodProofVoteOption.voiceProof,
        );

        // Text + image, but no voice: still rejected — the group's proof
        // requirement overrides the general text-or-proof baseline.
        e.handleEvent(
          TodCompleteEvent(
            userId: 'p1',
            ts: 4,
            response: 'done',
            proofImageB64: 'imgdata',
          ),
        );
        expect(e.currentState.phase, TodTurnPhase.readingCard);

        e.handleEvent(
          TodCompleteEvent(
            userId: 'p1',
            ts: 5,
            response: 'done',
            proofVoiceB64: 'voicedata',
          ),
        );
        expect(e.currentState.phase, TodTurnPhase.awaitingNextTurn);
      },
    );

    test(
      'a modified-client replay of a completion for someone else\'s turn, '
      'or outside readingCard phase, is a no-op (pre-existing guard, '
      'unaffected by the new validation)',
      () {
        final e = _engine(
          const GameConfig(maxRounds: 10, turnTimerSeconds: 0, allowSkip: true, allowSpicy: false),
          ['p1', 'p2'],
        );
        e.handleEvent(
          TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.truth),
        );
        e.handleEvent(
          TodCompleteEvent(userId: 'p2', ts: 2, response: 'not my turn'),
        );
        expect(e.currentState.phase, TodTurnPhase.readingCard);
        expect(e.currentState.turnResponse, isEmpty);
      },
    );
  });
}
