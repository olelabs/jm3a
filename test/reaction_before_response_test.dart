// Tests for the real-device bug: a player could tap a gameplay reaction
// before actually submitting their own response (NHIE: before voting
// Never/I Have; Meme: before submitting a caption/sticker), which was
// reachable UI-side and accepted engine-side, and was observed on-device
// to disrupt the round timer.
//
// Fix (see NeverHaveIEverEngine._handleReaction /
// MemeGameEngine._handleReact doc comments): both engines now reject a
// reaction from a player who hasn't yet responded, reusing the EXISTING
// authoritative "did this player respond" state (voteEntries for NHIE,
// submissions for Meme) rather than a second response-tracking field. The
// providers' onPlayerAction (nhie_game_screen.dart / meme_game_screen.dart)
// additionally short-circuit BEFORE _syncTimer()/_broadcastState() when
// the engine's own state didn't change — a rejected reaction is a
// complete no-op end to end, so it can never touch the timer.
//
// The provider-level short-circuit itself needs a live RealtimeService/DI
// stack this offline suite doesn't have (see prior sessions' final
// reports for that same boundary), so these tests exercise the engines
// directly — the authoritative layer both providers' guards ultimately
// defer to, and the one place a stale/malicious client's reaction is
// actually rejected regardless of what the UI allowed.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/meme_game/meme_game_engine.dart';
import 'package:jma3a/features/games/never_have_i_ever/never_have_i_ever_engine.dart';

const _config = GameConfig(
  maxRounds: 5,
  turnTimerSeconds: 30,
  allowSkip: true,
  allowSpicy: false,
);

NeverHaveIEverEngine _nhie(List<String> players) {
  final e = NeverHaveIEverEngine(
    _config,
    cards: [
      for (var i = 0; i < 10; i++)
        NhieCard(id: 'c$i', content: 'card $i', difficulty: 'mild'),
    ],
  );
  e.init(players);
  return e;
}

MemeGameEngine _meme(List<String> players) {
  final e = MemeGameEngine(
    _config,
    prompts: [for (var i = 0; i < 10; i++) MemePrompt(id: 'p$i', caption: 'c$i')],
  );
  e.init(players);
  return e;
}

void main() {
  group('NHIE — reaction before response', () {
    test('1. a reaction from a player who has not yet voted is rejected — '
        'no reaction recorded', () {
      final e = _nhie(['p1', 'p2']);
      expect(e.currentState.voteEntries.containsKey('p1'), isFalse);
      e.handleEvent(NhieReactionEvent(userId: 'p1', ts: 1, sticker: '😂'));
      expect(e.currentState.reactions, isEmpty);
    });

    test('2. the round timer (timerStartedAt) is completely untouched by '
        'a rejected reaction — it keeps counting down exactly as it was', () {
      final e = _nhie(['p1', 'p2']);
      final deadline = e.currentState.timerStartedAt;
      expect(deadline, isNotNull);
      e.handleEvent(NhieReactionEvent(userId: 'p1', ts: 1, sticker: '😂'));
      expect(e.currentState.timerStartedAt, deadline);
      // Also unaffected: isVotingOpen — the round is still fully open,
      // exactly as if the reaction had never been sent.
      expect(e.currentState.isVotingOpen, isTrue);
    });

    test('3. once the player has voted, reacting behaves exactly as '
        'before — the reaction is recorded normally', () {
      final e = _nhie(['p1', 'p2']);
      e.handleEvent(NhieVoteEvent(userId: 'p1', ts: 1, haveI: true));
      e.handleEvent(NhieReactionEvent(userId: 'p1', ts: 2, sticker: '😂'));
      expect(e.currentState.reactions.length, 1);
      expect(e.currentState.reactions.first.userId, 'p1');
    });

    test('7. a stale/duplicate reaction from the same non-responder is '
        'rejected every time, regardless of how many times it is retried '
        '— never changes state, never touches the timer', () {
      final e = _nhie(['p1', 'p2']);
      final deadline = e.currentState.timerStartedAt;
      for (var i = 0; i < 5; i++) {
        e.handleEvent(NhieReactionEvent(userId: 'p1', ts: i, sticker: '😂'));
      }
      expect(e.currentState.reactions, isEmpty);
      expect(e.currentState.timerStartedAt, deadline);
    });

    test('a non-player reaction (spectator/unknown id) is rejected the '
        'same as before — unrelated to this fix, still holds', () {
      final e = _nhie(['p1', 'p2']);
      e.handleEvent(NhieReactionEvent(userId: 'ghost', ts: 1, sticker: '😂'));
      expect(e.currentState.reactions, isEmpty);
    });
  });

  group('Meme — reaction before response', () {
    test('4. a reaction from a player who has not submitted this round is '
        'rejected — no reaction recorded, even once OTHER players have '
        'submitted and the round has moved to voting', () {
      final e = _meme(['p1', 'p2', 'p3']);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      e.handleEvent(MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'));
      e.handleEvent(MemeTimerExpiredEvent(userId: 'p1', ts: 3));
      expect(e.currentState.phase, MemePhase.voting);
      expect(e.currentState.submissions.containsKey('p3'), isFalse);

      // p3 never submitted, but the round is now in voting — p3 tries to
      // react to p1's submission anyway.
      e.handleEvent(
        MemeReactEvent(userId: 'p3', ts: 4, targetUserId: 'p1', emoji: '😂'),
      );
      expect(e.currentState.reactions, isEmpty);
    });

    test('5. the round timer is untouched by a rejected reaction', () {
      final e = _meme(['p1', 'p2']);
      final deadline = e.currentState.timerStartedAt;
      expect(deadline, isNotNull);
      e.handleEvent(
        MemeReactEvent(userId: 'p1', ts: 1, targetUserId: 'p2', emoji: '😂'),
      );
      // p1 hasn't submitted yet either — rejected, timer/phase unchanged.
      expect(e.currentState.timerStartedAt, deadline);
      expect(e.currentState.phase, MemePhase.submitting);
    });

    test('6. once the player has submitted, reacting to another '
        'submitter behaves exactly as before', () {
      final e = _meme(['p1', 'p2']);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      e.handleEvent(MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'));
      expect(e.currentState.phase, MemePhase.voting);
      e.handleEvent(
        MemeReactEvent(userId: 'p1', ts: 3, targetUserId: 'p2', emoji: '😂'),
      );
      expect(e.currentState.reactions.length, 1);
      expect(e.currentState.reactions.first.reactorId, 'p1');
    });

    test('7. a stale/duplicate reaction from a non-submitter is rejected '
        'every time it is retried — never changes state', () {
      final e = _meme(['p1', 'p2', 'p3']);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      e.handleEvent(MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'));
      e.handleEvent(MemeTimerExpiredEvent(userId: 'p1', ts: 3));
      expect(e.currentState.phase, MemePhase.voting);
      for (var i = 0; i < 5; i++) {
        e.handleEvent(
          MemeReactEvent(
            userId: 'p3',
            ts: i,
            targetUserId: 'p1',
            emoji: '😂',
          ),
        );
      }
      expect(e.currentState.reactions, isEmpty);
    });
  });
}
