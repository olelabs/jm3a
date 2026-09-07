// Tests for item 1 — round timer for NHIE and Meme, exercised at the
// engine level (the same authoritative layer TodGameProvider/
// NhieGameProvider/MemeGameProvider's identical `_syncTimer()` all defer
// to for actual timeout behavior — see truth_or_dare_engine.dart's
// _onTimerExpired for the pattern this mirrors).
//
// The DEADLINE lives in state.timerStartedAt (epoch ms), set/cleared by
// the engine itself, never in a raw countdown number — so "rebuild does
// not restart the timer" and "reconnect does not reset the timer" are
// really the same property: nothing except a genuine new round ever
// changes timerStartedAt. That's what's verified directly against the
// engine here; the provider-level ticker (which only ever *reads*
// timerStartedAt to compute a display countdown, and dispatches exactly
// one timeout event when it locally reaches zero) needs a live app/timer
// harness to exercise end-to-end — see the final report.

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
  group('1/2 — round timer starts correctly', () {
    test('1. NHIE: a 5-second round timer starts the instant the round '
        'begins', () {
      final e = _nhie(['p1', 'p2'], timerSecs: 5);
      expect(e.currentState.timerStartedAt, isNotNull);
    });

    test('2. Meme: a 5-second round timer starts the instant the round '
        'begins', () {
      final e = _meme(['p1', 'p2'], timerSecs: 5);
      expect(e.currentState.timerStartedAt, isNotNull);
    });

    test('no timer is started when the room\'s configured timer is off '
        '(turnTimerSeconds = 0) for either game', () {
      final nhie = _nhie(['p1', 'p2'], timerSecs: 0);
      final meme = _meme(['p1', 'p2'], timerSecs: 0);
      expect(nhie.currentState.timerStartedAt, isNull);
      expect(meme.currentState.timerStartedAt, isNull);
    });
  });

  group('3/4/8 — timeout happens exactly once; late actions rejected', () {
    test('3. NHIE: timeout force-closes voting exactly once — a second '
        'timeout event after that is a no-op', () {
      final e = _nhie(['p1', 'p2']);
      expect(e.currentState.isVotingOpen, isTrue);
      e.handleEvent(NhieTimerExpiredEvent(userId: 'p1', ts: 1));
      expect(e.currentState.isVotingOpen, isFalse);
      expect(e.currentState.timerStartedAt, isNull);
      final afterFirst = e.currentState;
      // A duplicate timeout event (e.g. a race between the owner's local
      // tick and a stale timer) must change nothing further.
      e.handleEvent(NhieTimerExpiredEvent(userId: 'p1', ts: 2));
      expect(e.currentState.isVotingOpen, afterFirst.isVotingOpen);
      expect(e.currentState.voteEntries, afterFirst.voteEntries);
    });

    test('4. Meme: timeout force-closes submissions exactly once — a '
        'second timeout event after that is a no-op', () {
      final e = _meme(['p1', 'p2']);
      expect(e.currentState.phase, MemePhase.submitting);
      e.handleEvent(MemeTimerExpiredEvent(userId: 'p1', ts: 1));
      expect(e.currentState.phase, MemePhase.voting);
      expect(e.currentState.timerStartedAt, isNull);
      final afterFirst = e.currentState;
      e.handleEvent(MemeTimerExpiredEvent(userId: 'p1', ts: 2));
      expect(e.currentState.phase, afterFirst.phase);
      expect(e.currentState.submissions, afterFirst.submissions);
    });

    test('8. NHIE: a vote arriving after timeout is rejected — no vote '
        'recorded, no points awarded', () {
      final e = _nhie(['p1', 'p2']);
      e.handleEvent(NhieTimerExpiredEvent(userId: 'p1', ts: 1));
      e.handleEvent(NhieVoteEvent(userId: 'p1', ts: 2, haveI: true));
      expect(e.currentState.voteEntries, isEmpty);
      expect(e.currentState.scores['p1'], 0);
    });

    test('8. Meme: a submission arriving after timeout is rejected — no '
        'submission recorded', () {
      final e = _meme(['p1', 'p2']);
      e.handleEvent(MemeTimerExpiredEvent(userId: 'p1', ts: 1));
      e.handleEvent(
        MemeSubmitEvent(userId: 'p1', ts: 2, stickerChoice: 'late'),
      );
      expect(e.currentState.submissions, isEmpty);
    });

    test('timeout never fires while a round is already resolved — closing '
        'naturally (everyone responded) also clears the timer, so a '
        'delayed timeout event afterward is a no-op', () {
      final nhie = _nhie(['p1', 'p2']);
      nhie.handleEvent(NhieVoteEvent(userId: 'p1', ts: 1, haveI: true));
      nhie.handleEvent(NhieVoteEvent(userId: 'p2', ts: 2, haveI: false));
      expect(nhie.currentState.isVotingOpen, isFalse);
      expect(nhie.currentState.timerStartedAt, isNull);
      final before = nhie.currentState;
      nhie.handleEvent(NhieTimerExpiredEvent(userId: 'p1', ts: 3));
      expect(nhie.currentState.voteEntries, before.voteEntries);

      final meme = _meme(['p1', 'p2']);
      meme.handleEvent(
        MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'),
      );
      meme.handleEvent(
        MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'),
      );
      expect(meme.currentState.phase, MemePhase.voting);
      expect(meme.currentState.timerStartedAt, isNull);
      final beforeMeme = meme.currentState;
      meme.handleEvent(MemeTimerExpiredEvent(userId: 'p1', ts: 3));
      expect(meme.currentState.submissions, beforeMeme.submissions);
    });
  });

  group('5/6 — the deadline is immune to rebuilds and reconnects', () {
    test('5. NHIE: timerStartedAt is untouched by an unrelated/no-op '
        'event — nothing "restarts" it on a mere rebuild-equivalent '
        'action', () {
      final e = _nhie(['p1', 'p2']);
      final started = e.currentState.timerStartedAt;
      // A rejected action (wrong player, or a duplicate) must not touch
      // timerStartedAt at all.
      e.handleEvent(NhieVoteEvent(userId: 'ghost', ts: 1, haveI: true));
      expect(e.currentState.timerStartedAt, started);
    });

    test('5. Meme: timerStartedAt is untouched by an unrelated/no-op '
        'event', () {
      final e = _meme(['p1', 'p2']);
      final started = e.currentState.timerStartedAt;
      e.handleEvent(
        MemeSubmitEvent(userId: 'ghost', ts: 1, stickerChoice: 'x'),
      );
      expect(e.currentState.timerStartedAt, started);
    });

    test('6. NHIE: serialize/restore (reconnect path) preserves the exact '
        'same timerStartedAt — never a new one', () {
      final e = _nhie(['p1', 'p2']);
      final started = e.currentState.timerStartedAt;
      final restored = NhieState.fromMap(e.serializeState());
      expect(restored.timerStartedAt, started);
    });

    test('6. Meme: serialize/restore (reconnect path) preserves the exact '
        'same timerStartedAt — never a new one', () {
      final e = _meme(['p1', 'p2']);
      final started = e.currentState.timerStartedAt;
      final restored = MemeState.fromMap(e.serializeState());
      expect(restored.timerStartedAt, started);
    });
  });

  group('7 — the NEXT round always gets a fresh timer', () {
    test('7. NHIE: advanceTurn() sets a new, running timer for the next '
        'card, independent of whether the previous one had expired', () {
      final e = _nhie(['p1', 'p2']);
      e.handleEvent(NhieTimerExpiredEvent(userId: 'p1', ts: 1));
      expect(e.currentState.timerStartedAt, isNull);
      e.advanceTurn();
      expect(e.currentState.timerStartedAt, isNotNull);
      expect(e.currentState.isVotingOpen, isTrue);
    });

    test('7. Meme: advanceTurn() sets a new, running timer for the next '
        'round, independent of whether the previous one had expired', () {
      final e = _meme(['p1', 'p2']);
      e.handleEvent(MemeTimerExpiredEvent(userId: 'p1', ts: 1));
      expect(e.currentState.timerStartedAt, isNull);
      e.advanceTurn();
      expect(e.currentState.timerStartedAt, isNotNull);
      expect(e.currentState.phase, MemePhase.submitting);
    });

    test('a completed (not timed-out) round also gets a fresh timer next '
        'round', () {
      final e = _meme(['p1', 'p2']);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      e.handleEvent(MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'));
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 3, targetUserId: 'p2'));
      e.handleEvent(MemeVoteEvent(userId: 'p2', ts: 4, targetUserId: 'p1'));
      expect(e.currentState.timerStartedAt, isNull);
      e.advanceTurn();
      expect(e.currentState.timerStartedAt, isNotNull);
    });
  });
}
