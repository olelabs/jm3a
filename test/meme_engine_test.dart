// Authoritative Meme engine tests for the optional-voting redesign. These
// exercise MemeGameEngine directly (the same reducer the host runs), proving
// the rules hold in the game logic itself — not just in the UI:
//   - one submission / one response (vote OR pass) per player per round
//   - voting is optional; a pass completes the round without a vote or points
//   - duplicate vote/pass and cross (vote-after-pass / pass-after-vote) rejected
//   - a round finishes when everyone has voted OR passed
//   - all-pass => no winner, no points
//   - stale / wrong-phase / non-player actions rejected
//   - one reaction per (reactor, target); duplicates rejected

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/meme_game/meme_game_engine.dart';

const _config = GameConfig(
  maxRounds: 5,
  turnTimerSeconds: 60,
  allowSkip: true,
  allowSpicy: false,
);

MemeGameEngine _engine(List<String> players) {
  final e = MemeGameEngine(
    _config,
    prompts: [for (var i = 0; i < 10; i++) MemePrompt(id: 'p$i', caption: 'c$i')],
  );
  e.init(players);
  return e;
}

void _allSubmit(MemeGameEngine e, List<String> players) {
  for (final p in players) {
    e.handleEvent(MemeSubmitEvent(userId: p, ts: 1, stickerChoice: 's-$p'));
  }
}

void main() {
  group('Submission — one per player per round', () {
    test('all submissions open voting; a duplicate submission is rejected', () {
      final e = _engine(['p1', 'p2']);
      expect(e.currentState.phase, MemePhase.submitting);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      // Duplicate submit from p1 — ignored, still one submission for p1.
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 2, stickerChoice: 'b'));
      expect(e.currentState.submissions.length, 1);
      expect(e.currentState.submissions['p1']!.stickerChoice, 'a');
      expect(e.currentState.phase, MemePhase.submitting); // p2 not in yet
      e.handleEvent(MemeSubmitEvent(userId: 'p2', ts: 3, stickerChoice: 'c'));
      expect(e.currentState.phase, MemePhase.voting);
    });
  });

  group('Optional voting + pass', () {
    test('a pass is recorded, awards no points, and does not block the round',
        () {
      final e = _engine(['p1', 'p2']);
      _allSubmit(e, ['p1', 'p2']);
      // p1 votes for p2, p2 passes — everyone has responded → round completes.
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 2, targetUserId: 'p2'));
      expect(e.currentState.phase, MemePhase.voting); // p2 hasn't responded
      e.handleEvent(MemePassEvent(userId: 'p2', ts: 3));
      expect(e.currentState.phase, MemePhase.results);
      expect(e.currentState.passes, {'p2'});
      // p2 won the single vote; p2 (a passer) scored nothing FOR passing.
      expect(e.currentState.scores['p2'], 1);
      expect(e.currentState.scores['p1'], 0);
      expect(e.currentState.roundWinnerId, 'p2');
    });

    test('a round can finish with EVERY player passing — no winner, no points',
        () {
      final e = _engine(['p1', 'p2', 'p3']);
      _allSubmit(e, ['p1', 'p2', 'p3']);
      e.handleEvent(MemePassEvent(userId: 'p1', ts: 2));
      e.handleEvent(MemePassEvent(userId: 'p2', ts: 3));
      expect(e.currentState.phase, MemePhase.voting);
      e.handleEvent(MemePassEvent(userId: 'p3', ts: 4));
      expect(e.currentState.phase, MemePhase.results);
      expect(e.currentState.roundWinnerId, isNull);
      expect(e.currentState.scores.values.every((v) => v == 0), isTrue);
    });

    test('tied top votes = tied winners, each scores (no player-order break)',
        () {
      final e = _engine(['p1', 'p2', 'p3', 'p4']);
      _allSubmit(e, ['p1', 'p2', 'p3', 'p4']);
      // p1,p2 -> vote p3 ; p3,p4 -> vote p1  => p3:2, p1:2 tie.
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 2, targetUserId: 'p3'));
      e.handleEvent(MemeVoteEvent(userId: 'p2', ts: 3, targetUserId: 'p3'));
      e.handleEvent(MemeVoteEvent(userId: 'p3', ts: 4, targetUserId: 'p1'));
      e.handleEvent(MemeVoteEvent(userId: 'p4', ts: 5, targetUserId: 'p1'));
      expect(e.currentState.phase, MemePhase.results);
      expect(e.currentState.scores['p1'], 1);
      expect(e.currentState.scores['p3'], 1);
      expect(e.currentState.roundWinnerId, isNull); // ambiguous → no single
    });
  });

  group('Duplicate / cross / stale rejection', () {
    test('duplicate vote is rejected', () {
      final e = _engine(['p1', 'p2', 'p3']);
      _allSubmit(e, ['p1', 'p2', 'p3']);
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 2, targetUserId: 'p2'));
      // Second vote from p1 (different target) ignored.
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 3, targetUserId: 'p3'));
      expect(e.currentState.votes['p1'], 'p2');
    });

    test('duplicate pass is rejected', () {
      final e = _engine(['p1', 'p2']);
      _allSubmit(e, ['p1', 'p2']);
      e.handleEvent(MemePassEvent(userId: 'p1', ts: 2));
      final before = e.currentState;
      e.handleEvent(MemePassEvent(userId: 'p1', ts: 3));
      expect(e.currentState.passes, {'p1'});
      expect(e.currentState.phase, before.phase); // unchanged
    });

    test('cannot vote after passing, or pass after voting', () {
      final e = _engine(['p1', 'p2', 'p3']);
      _allSubmit(e, ['p1', 'p2', 'p3']);
      e.handleEvent(MemePassEvent(userId: 'p1', ts: 2));
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 3, targetUserId: 'p2'));
      expect(e.currentState.votes.containsKey('p1'), isFalse);
      expect(e.currentState.passes, {'p1'});

      e.handleEvent(MemeVoteEvent(userId: 'p2', ts: 4, targetUserId: 'p3'));
      e.handleEvent(MemePassEvent(userId: 'p2', ts: 5));
      expect(e.currentState.votes['p2'], 'p3');
      expect(e.currentState.passes.contains('p2'), isFalse);
    });

    test('a vote in the wrong phase is rejected (stale/late)', () {
      final e = _engine(['p1', 'p2']);
      // Still submitting — a vote is not valid yet.
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 1, targetUserId: 'p2'));
      expect(e.currentState.votes, isEmpty);

      _allSubmit(e, ['p1', 'p2']);
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 2, targetUserId: 'p2'));
      e.handleEvent(MemeVoteEvent(userId: 'p2', ts: 3, targetUserId: 'p1'));
      expect(e.currentState.phase, MemePhase.results);
      // A late vote after results is rejected.
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 4, targetUserId: 'p2'));
      e.handleEvent(MemePassEvent(userId: 'p1', ts: 5));
      expect(e.currentState.votes.length, 2);
    });

    test('a non-player (spectator) vote or pass is rejected', () {
      final e = _engine(['p1', 'p2']);
      _allSubmit(e, ['p1', 'p2']);
      e.handleEvent(MemeVoteEvent(userId: 'ghost', ts: 2, targetUserId: 'p1'));
      e.handleEvent(MemePassEvent(userId: 'ghost', ts: 3));
      expect(e.currentState.votes.containsKey('ghost'), isFalse);
      expect(e.currentState.passes.contains('ghost'), isFalse);
      expect(e.currentState.phase, MemePhase.voting);
    });

    test('a vote for a non-submitter target is rejected', () {
      final e = _engine(['p1', 'p2']);
      _allSubmit(e, ['p1', 'p2']);
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 2, targetUserId: 'ghost'));
      expect(e.currentState.votes, isEmpty);
    });
  });

  group('Response reactions — one per (reactor, target)', () {
    test('a duplicate reaction from the same reactor to the same target is '
        'rejected', () {
      final e = _engine(['p1', 'p2']);
      _allSubmit(e, ['p1', 'p2']);
      e.handleEvent(
        MemeReactEvent(userId: 'p1', ts: 2, targetUserId: 'p2', emoji: '😂'),
      );
      e.handleEvent(
        MemeReactEvent(userId: 'p1', ts: 3, targetUserId: 'p2', emoji: '🔥'),
      );
      expect(
        e.currentState.reactions
            .where((r) => r.reactorId == 'p1' && r.targetUserId == 'p2')
            .length,
        1,
      );
      // A different target is allowed.
      e.handleEvent(
        MemeReactEvent(userId: 'p1', ts: 4, targetUserId: 'p1', emoji: '👏'),
      );
      expect(e.currentState.reactions.length, 2);
    });
  });

  group('State serialization round-trips passes', () {
    test('passes survive serialize/restore (reconnect/host-migration path)',
        () {
      final e = _engine(['p1', 'p2', 'p3']);
      _allSubmit(e, ['p1', 'p2', 'p3']);
      e.handleEvent(MemePassEvent(userId: 'p1', ts: 2));
      final restored = MemeState.fromMap(e.serializeState());
      expect(restored.passes, {'p1'});
      expect(restored.phase, MemePhase.voting);
    });
  });
}
