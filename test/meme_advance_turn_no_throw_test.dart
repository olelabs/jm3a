// Tests for the "Meme admin next-round red screen" real-device crash
// report (2 players, admin responds, round completes, admin presses
// Continue → red error screen). An extensive static-code audit of the
// full path (MemeGameProvider.ownerAdvanceTurn → MemeGameEngine
// .advanceTurn() → _ResultsScreen/_GameOverScreen/GameOverPodium/
// _Leaderboard) found every widget already defensively guarded (empty
// lists, null winners, bounded medal indices) and no null-deref/
// index-out-of-range in the engine transition itself — see the final
// report for what this means for the crash's status (NOT confirmed
// fixed; structured logging was added instead — see
// MemeGameProvider.ownerAdvanceTurn and main.dart's FlutterError.onError
// hook — so the actual exception can be captured on the next real-device
// repro).
//
// This exercises MemeGameEngine.advanceTurn() — the one piece of that
// path actually reachable without a live Supabase/DI stack — across the
// exact 2-player scenarios the report describes, to rule out an
// engine-level defect as the cause (a genuine unit-test result, not a
// substitute for reproducing the real crash).

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/meme_game/meme_game_engine.dart';

MemeGameEngine _engine(List<String> players, {int maxRounds = 3}) {
  final e = MemeGameEngine(
    GameConfig(
      maxRounds: maxRounds,
      turnTimerSeconds: 30,
      allowSkip: true,
      allowSpicy: false,
    ),
    prompts: [for (var i = 0; i < 10; i++) MemePrompt(id: 'p$i', caption: 'c$i')],
  );
  e.init(players);
  return e;
}

void main() {
  group('10/13 — 2-player admin Continue path does not throw', () {
    test('both players submit + one votes (the round completes normally) '
        'then advanceTurn() to round 2 does not throw', () {
      final e = _engine(['admin', 'p2']);
      e.handleEvent(MemeSubmitEvent(userId: 'admin', ts: 1, stickerChoice: 'a'));
      e.handleEvent(MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'));
      e.handleEvent(MemeVoteEvent(userId: 'admin', ts: 3, targetUserId: 'p2'));
      e.handleEvent(MemeVoteEvent(userId: 'p2', ts: 4, targetUserId: 'admin'));
      expect(e.currentState.phase, MemePhase.results);

      expect(() => e.advanceTurn(), returnsNormally);
      expect(e.currentState.phase, MemePhase.submitting);
      expect(e.currentState.roundNumber, 2);
    });

    test('one player submits, the other passes on voting (no votes cast) '
        'then advanceTurn() does not throw', () {
      final e = _engine(['admin', 'p2']);
      e.handleEvent(MemeSubmitEvent(userId: 'admin', ts: 1, stickerChoice: 'a'));
      e.handleEvent(MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'));
      e.handleEvent(MemePassEvent(userId: 'admin', ts: 3));
      e.handleEvent(MemePassEvent(userId: 'p2', ts: 4));
      expect(e.currentState.phase, MemePhase.results);
      expect(e.currentState.roundWinnerId, isNull);

      expect(() => e.advanceTurn(), returnsNormally);
    });
  });

  group('12 — no-submission round followed by admin Continue', () {
    test('a timed-out round with ZERO submissions still lets advanceTurn() '
        'run cleanly (the owner force-continuing past a dead round)', () {
      final e = _engine(['admin', 'p2']);
      e.handleEvent(MemeTimerExpiredEvent(userId: 'admin', ts: 1));
      expect(e.currentState.phase, MemePhase.voting);
      expect(e.currentState.submissions, isEmpty);

      expect(() => e.advanceTurn(), returnsNormally);
      expect(e.currentState.phase, MemePhase.submitting);
      expect(e.currentState.submissions, isEmpty);
    });
  });

  group('10/11 — repeated admin Continue presses across a full game', () {
    test('advancing through every round to game-over never throws, for '
        'either a fully-played or an all-pass round each time', () {
      final e = _engine(['admin', 'p2'], maxRounds: 3);
      for (var round = 1; round <= 3; round++) {
        expect(e.currentState.isOver, isFalse, reason: 'round $round');
        // A player can never reuse the same sticker twice in one game
        // (see _handleSubmit's usedStickersByPlayer guard) — a distinct
        // sticker per round is required here for submissions to actually
        // register, exactly as a real multi-round game would need.
        e.handleEvent(
          MemeSubmitEvent(
            userId: 'admin',
            ts: round,
            stickerChoice: 'a$round',
          ),
        );
        e.handleEvent(
          MemeSubmitEvent(userId: 'p2', ts: round, stickerChoice: 'b$round'),
        );
        e.handleEvent(MemePassEvent(userId: 'admin', ts: round));
        e.handleEvent(MemePassEvent(userId: 'p2', ts: round));
        expect(e.currentState.phase, MemePhase.results);
        expect(() => e.advanceTurn(), returnsNormally);
      }
      expect(e.currentState.isOver, isTrue);
    });

    test('advanceTurn() called again after the game is already over is a '
        'safe no-crash no-op shape (mirrors a stray double-tap after '
        'isOver flips)', () {
      final e = _engine(['admin', 'p2'], maxRounds: 1);
      e.handleEvent(MemeSubmitEvent(userId: 'admin', ts: 1, stickerChoice: 'a'));
      e.handleEvent(MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'));
      e.handleEvent(MemePassEvent(userId: 'admin', ts: 3));
      e.handleEvent(MemePassEvent(userId: 'p2', ts: 4));
      expect(() => e.advanceTurn(), returnsNormally);
      expect(e.currentState.isOver, isTrue);
      // The provider guards this with isGameOver/ownerAdvanceTurn checks
      // before ever calling advanceTurn() again — this only proves the
      // ENGINE method itself has no landmine if that guard were ever
      // bypassed.
      expect(() => e.advanceTurn(), returnsNormally);
    });
  });
}
