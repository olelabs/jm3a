// Tests for item 3 — Meme game history.
//
// Investigation finding (documented in the final report): Meme's in-game
// history was NOT actually missing. lib/features/games/presentation/
// meme_game_screen.dart's _MemeGameScreenState already has the exact same
// architecture NHIE's top-level scaffold uses — a `_showHistory` overlay,
// a history icon button gated on `hasHistory`, wired into the shared
// GameScreenSecurityGate back-guard, rendering a `_HistoryPanel` that is
// already correctly mapped to Meme's own `MemeRoundRecord` data (prompt,
// submissions, winner, reactions) — not a stale/borrowed NHIE copy. No
// code changed for this item; per the scope rule, an already-correct
// implementation is left alone.
//
// What IS genuinely testable offline, and is exactly the data layer that
// history UI (in any of the three games) depends on: that MemeGameEngine
// actually accumulates `history` as rounds complete, that each record
// carries genuine (not fabricated) round data, and that scoring/voting
// logic is completely unaffected by history bookkeeping.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/meme_game/meme_game_engine.dart';

GameConfig _config() => const GameConfig(
  maxRounds: 5,
  turnTimerSeconds: 60,
  allowSkip: true,
  allowSpicy: false,
);

MemeGameEngine _engine(List<String> players) {
  final e = MemeGameEngine(
    _config(),
    prompts: [for (var i = 0; i < 10; i++) MemePrompt(id: 'p$i', caption: 'c$i')],
  );
  e.init(players);
  return e;
}

void main() {
  group('12/13 — Meme history is accessible and reflects real game data',
      () {
    test('a completed round is appended to history with its real prompt, '
        'submissions, and winner — not a fabricated placeholder', () {
      final e = _engine(['p1', 'p2']);
      e.handleEvent(
        MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'),
      );
      e.handleEvent(
        MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'),
      );
      final promptBeforeAdvance = e.currentState.currentPrompt;
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 3, targetUserId: 'p2'));
      e.handleEvent(MemeVoteEvent(userId: 'p2', ts: 4, targetUserId: 'p2'));
      expect(e.currentState.roundWinnerId, 'p2');

      expect(e.currentState.history, isEmpty); // not recorded until advance
      e.advanceTurn();

      expect(e.currentState.history, hasLength(1));
      final record = e.currentState.history.single;
      expect(record.roundNumber, 1);
      expect(record.prompt.id, promptBeforeAdvance!.id);
      expect(record.winnerId, 'p2');
      expect(record.submissions['p1']!.stickerChoice, 'a');
      expect(record.submissions['p2']!.stickerChoice, 'b');
    });

    test('history accumulates one entry per completed round, oldest '
        'first, across a multi-round game', () {
      final e = _engine(['p1', 'p2']);
      for (var round = 0; round < 3; round++) {
        e.handleEvent(
          MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'r$round-a'),
        );
        e.handleEvent(
          MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'r$round-b'),
        );
        e.handleEvent(MemePassEvent(userId: 'p1', ts: 3));
        e.handleEvent(MemePassEvent(userId: 'p2', ts: 4));
        e.advanceTurn();
      }
      expect(e.currentState.history, hasLength(3));
      expect(
        e.currentState.history.map((r) => r.roundNumber).toList(),
        [1, 2, 3],
      );
    });

    test('history survives serialize/restore — the same reconnect/host-'
        'migration path every game screen\'s history button reads from',
        () {
      final e = _engine(['p1', 'p2']);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      e.handleEvent(MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'));
      e.handleEvent(MemePassEvent(userId: 'p1', ts: 3));
      e.handleEvent(MemePassEvent(userId: 'p2', ts: 4));
      e.advanceTurn();

      final restored = MemeState.fromMap(e.serializeState());
      expect(restored.history, hasLength(1));
      expect(restored.history.single.submissions['p1']!.stickerChoice, 'a');
    });
  });

  group('14 — no gameplay/scoring behavior changes from history '
      'bookkeeping', () {
    test('scores and voting are computed identically whether or not the '
        'round produced a history record', () {
      final e = _engine(['p1', 'p2', 'p3']);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      e.handleEvent(MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'));
      e.handleEvent(MemeSubmitEvent(userId: 'p3', ts: 3, stickerChoice: 'c'));
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 4, targetUserId: 'p2'));
      e.handleEvent(MemeVoteEvent(userId: 'p3', ts: 5, targetUserId: 'p2'));
      e.handleEvent(MemeVoteEvent(userId: 'p2', ts: 6, targetUserId: 'p1'));
      expect(e.currentState.scores['p2'], 1);
      expect(e.currentState.scores['p1'], 0);
      expect(e.currentState.scores['p3'], 0);
      expect(e.currentState.roundWinnerId, 'p2');

      // advanceTurn (which records history) must not retroactively touch
      // the scores the round already settled.
      e.advanceTurn();
      expect(e.currentState.scores['p2'], 1);
      expect(e.currentState.scores['p1'], 0);
      expect(e.currentState.scores['p3'], 0);
    });
  });
}
