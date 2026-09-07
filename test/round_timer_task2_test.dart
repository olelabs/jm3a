// Additive coverage for the 15-section timer/UI task — engine-level items
// not already covered by test/round_timer_test.dart (which already covers:
// timer starts on/off, timeout-fires-exactly-once, late-action rejection,
// no-restart-on-no-op-event, serialize/restore preserving timerStartedAt,
// and fresh-timer-on-advanceTurn). This file fills the remaining gaps:
// response-before-timeout accepted, exact skipped/no-response
// representation + scoring, double-response rejection, expired timer
// surviving reconnect, and timer-vs-response race resolving to exactly one
// outcome — for both NHIE and Meme.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/meme_game/meme_game_engine.dart';
import 'package:jma3a/features/games/never_have_i_ever/never_have_i_ever_engine.dart';

GameConfig _timedConfig({int turnTimerSeconds = 5}) => GameConfig(
  maxRounds: 5,
  turnTimerSeconds: turnTimerSeconds,
  allowSkip: true,
  allowSpicy: false,
);

NeverHaveIEverEngine _nhie(List<String> players, {int timerSecs = 5}) {
  final e = NeverHaveIEverEngine(
    _timedConfig(turnTimerSeconds: timerSecs),
    cards: [
      for (var i = 0; i < 10; i++)
        NhieCard(id: 'c$i', content: 'card $i', difficulty: 'mild'),
    ],
  );
  e.init(players);
  return e;
}

MemeGameEngine _meme(List<String> players, {int timerSecs = 5}) {
  final e = MemeGameEngine(
    _timedConfig(turnTimerSeconds: timerSecs),
    prompts: [for (var i = 0; i < 10; i++) MemePrompt(id: 'p$i', caption: 'c$i')],
  );
  e.init(players);
  return e;
}

void main() {
  group('NHIE — response before timeout', () {
    test('3. a response arriving before timeout is accepted normally and '
        'records the vote', () {
      final e = _nhie(['p1', 'p2']);
      e.handleEvent(NhieVoteEvent(userId: 'p1', ts: 1, haveI: true));
      expect(e.currentState.voteEntries.containsKey('p1'), isTrue);
      expect(e.currentState.voteEntries['p1']!.haveI, isTrue);
    });

    test('once every player has responded (before any timeout), the round '
        'timer itself is cleared — nothing left to time out', () {
      final e = _nhie(['p1', 'p2']);
      e.handleEvent(NhieVoteEvent(userId: 'p1', ts: 1, haveI: true));
      e.handleEvent(NhieVoteEvent(userId: 'p2', ts: 2, haveI: false));
      expect(e.currentState.timerStartedAt, isNull);
      expect(e.currentState.isVotingOpen, isFalse);
    });
  });

  group('NHIE — exact skipped/no-response representation + scoring', () {
    test('4. timeout with a non-responder leaves that player with NO vote '
        'entry at all (the engine\'s existing "no response" representation '
        '— not a synthesized vote)', () {
      final e = _nhie(['p1', 'p2']);
      e.handleEvent(NhieVoteEvent(userId: 'p1', ts: 1, haveI: true));
      e.handleEvent(NhieTimerExpiredEvent(userId: 'p1', ts: 2));
      expect(e.currentState.voteEntries.containsKey('p1'), isTrue);
      expect(e.currentState.voteEntries.containsKey('p2'), isFalse);
    });

    test('5. timeout applies the existing scoring rule unchanged — a '
        'non-responder gets no point (same as if they had answered '
        '"Never"), a responder who answered "I Have" keeps their point', () {
      final e = _nhie(['p1', 'p2']);
      e.handleEvent(NhieVoteEvent(userId: 'p1', ts: 1, haveI: true));
      e.handleEvent(NhieTimerExpiredEvent(userId: 'p1', ts: 2));
      expect(e.currentState.scores['p1'], 1);
      expect(e.currentState.scores['p2'] ?? 0, 0);
    });
  });

  group('NHIE — double response rejected', () {
    test('8. a second vote from the same player is rejected — the first '
        'vote and score stand unchanged', () {
      final e = _nhie(['p1', 'p2']);
      e.handleEvent(NhieVoteEvent(userId: 'p1', ts: 1, haveI: true));
      final afterFirst = e.currentState;
      e.handleEvent(NhieVoteEvent(userId: 'p1', ts: 2, haveI: false));
      expect(e.currentState.voteEntries['p1']!.haveI, isTrue);
      expect(e.currentState.scores, afterFirst.scores);
    });
  });

  group('NHIE — expired timer survives reconnect', () {
    test('11. a round that already timed out while disconnected stays '
        'timed out after serialize/restore — voting stays closed, no new '
        'timer, and a late vote after restore is still rejected', () {
      final e = _nhie(['p1', 'p2']);
      e.handleEvent(NhieVoteEvent(userId: 'p1', ts: 1, haveI: true));
      e.handleEvent(NhieTimerExpiredEvent(userId: 'p1', ts: 2));
      final restored = NhieState.fromMap(e.serializeState());
      expect(restored.isVotingOpen, isFalse);
      expect(restored.timerStartedAt, isNull);

      final e2 = _nhie(['p1', 'p2']);
      e2.restoreFromSnapshot(e.serializeState());
      e2.handleEvent(NhieVoteEvent(userId: 'p2', ts: 3, haveI: true));
      expect(e2.currentState.voteEntries.containsKey('p2'), isFalse);
    });
  });

  group('NHIE — timer-vs-response race', () {
    test('12. a timeout event and a same-player vote event both arriving '
        '"simultaneously" resolve to exactly one outcome, whichever the '
        'engine processes first — never both', () {
      // Vote processed first: the vote wins, and the timeout that follows
      // is a no-op against a round that's already fully resolved.
      final voteFirst = _nhie(['p1', 'p2']);
      voteFirst.handleEvent(NhieVoteEvent(userId: 'p1', ts: 1, haveI: true));
      voteFirst.handleEvent(NhieVoteEvent(userId: 'p2', ts: 2, haveI: true));
      voteFirst.handleEvent(NhieTimerExpiredEvent(userId: 'p1', ts: 3));
      expect(voteFirst.currentState.voteEntries.length, 2);
      expect(voteFirst.currentState.scores['p1'], 1);

      // Timeout processed first: the timeout wins, and the vote that
      // follows is rejected by the same isVotingOpen guard.
      final timeoutFirst = _nhie(['p1', 'p2']);
      timeoutFirst.handleEvent(NhieTimerExpiredEvent(userId: 'p1', ts: 1));
      timeoutFirst.handleEvent(NhieVoteEvent(userId: 'p1', ts: 2, haveI: true));
      expect(timeoutFirst.currentState.voteEntries, isEmpty);
      expect(timeoutFirst.currentState.scores['p1'] ?? 0, 0);
    });
  });

  group('Meme — valid action before timeout', () {
    test('15. a submission arriving before timeout is accepted normally', () {
      final e = _meme(['p1', 'p2']);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      expect(e.currentState.submissions.containsKey('p1'), isTrue);
    });

    test('once every player has submitted (before any timeout), the round '
        'timer itself is cleared', () {
      final e = _meme(['p1', 'p2']);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      e.handleEvent(MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'));
      expect(e.currentState.timerStartedAt, isNull);
      expect(e.currentState.phase, MemePhase.voting);
    });
  });

  group('Meme — double submission rejected', () {
    test('a second submission from the same player is rejected — the '
        'first submission stands unchanged', () {
      final e = _meme(['p1', 'p2']);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      final afterFirst = e.currentState;
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 2, stickerChoice: 'b'));
      expect(e.currentState.submissions['p1']!.stickerChoice, 'a');
      expect(e.currentState.submissions, afterFirst.submissions);
    });
  });

  group('Meme — expired timer survives reconnect', () {
    test('21. a round that already timed out while disconnected stays '
        'timed out after serialize/restore — phase stays voting, no new '
        'timer, and a late submission after restore is still rejected', () {
      final e = _meme(['p1', 'p2']);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      e.handleEvent(MemeTimerExpiredEvent(userId: 'p1', ts: 2));
      final restored = MemeState.fromMap(e.serializeState());
      expect(restored.phase, MemePhase.voting);
      expect(restored.timerStartedAt, isNull);

      final e2 = _meme(['p1', 'p2']);
      e2.restoreFromSnapshot(e.serializeState());
      e2.handleEvent(
        MemeSubmitEvent(userId: 'p2', ts: 3, stickerChoice: 'late'),
      );
      expect(e2.currentState.submissions.containsKey('p2'), isFalse);
    });
  });

  group('Meme — timer-vs-action race', () {
    test('22. a timeout event and a same-player submission both arriving '
        '"simultaneously" resolve to exactly one outcome, whichever the '
        'engine processes first — never both', () {
      final submitFirst = _meme(['p1', 'p2']);
      submitFirst.handleEvent(
        MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'),
      );
      submitFirst.handleEvent(
        MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'),
      );
      submitFirst.handleEvent(MemeTimerExpiredEvent(userId: 'p1', ts: 3));
      expect(submitFirst.currentState.submissions.length, 2);
      expect(submitFirst.currentState.phase, MemePhase.voting);

      final timeoutFirst = _meme(['p1', 'p2']);
      timeoutFirst.handleEvent(MemeTimerExpiredEvent(userId: 'p1', ts: 1));
      timeoutFirst.handleEvent(
        MemeSubmitEvent(userId: 'p1', ts: 2, stickerChoice: 'a'),
      );
      expect(timeoutFirst.currentState.submissions, isEmpty);
    });
  });
}
