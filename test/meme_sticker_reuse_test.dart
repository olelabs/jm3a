// Tests for item 5 — Meme: prevent a player from reusing the same sticker
// every round. Exercises MemeGameEngine directly (the same reducer the
// host runs, and the same one that serializes/restores for reconnect and
// host migration), proving:
//   - a used sticker is rejected engine-side for that SAME player, silently
//     (matching the existing invalid-action rejection pattern), not merely
//     hidden in the UI
//   - a used sticker remains fully available to every OTHER player
//   - the used-sticker history persists across rounds (advanceTurn) within
//     one game, but resets on a brand-new game (init)
//   - it survives serialize/restore (reconnect / host migration)
//   - unrelated Meme behavior (voting/pass/reactions, captions-only
//     submissions) is untouched

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/meme_game/meme_game_engine.dart';

GameConfig _config({int maxRounds = 5}) => GameConfig(
  maxRounds: maxRounds,
  turnTimerSeconds: 60,
  allowSkip: true,
  allowSpicy: false,
);

MemeGameEngine _engine(List<String> players, {int maxRounds = 5}) {
  final e = MemeGameEngine(
    _config(maxRounds: maxRounds),
    prompts: [for (var i = 0; i < 10; i++) MemePrompt(id: 'p$i', caption: 'c$i')],
  );
  e.init(players);
  return e;
}

void main() {
  group('Item 5 — engine-side (authoritative) sticker reuse rejection', () {
    test('a player reusing a sticker they already submitted this game is '
        'silently rejected — no submission recorded, phase unchanged', () {
      final e = _engine(['p1', 'p2']);
      e.handleEvent(
        MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'sticker-a'),
      );
      e.handleEvent(
        MemeVoteEvent(userId: 'p1', ts: 2, targetUserId: 'p1'),
      ); // no-op, wrong phase, just sanity
      e.handleEvent(
        MemeSubmitEvent(userId: 'p2', ts: 3, stickerChoice: 'sticker-b'),
      );
      // Round 1 complete (both submitted) -> voting.
      expect(e.currentState.phase, MemePhase.voting);
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 4, targetUserId: 'p2'));
      e.handleEvent(MemeVoteEvent(userId: 'p2', ts: 5, targetUserId: 'p1'));
      expect(e.currentState.phase, MemePhase.results);
      e.advanceTurn();
      expect(e.currentState.phase, MemePhase.submitting);
      expect(e.currentState.submissions, isEmpty); // per-round reset

      // p1 tries to reuse 'sticker-a' in round 2 — rejected.
      e.handleEvent(
        MemeSubmitEvent(userId: 'p1', ts: 10, stickerChoice: 'sticker-a'),
      );
      expect(e.currentState.submissions.containsKey('p1'), isFalse);
      expect(e.currentState.phase, MemePhase.submitting);

      // p1 picks a fresh sticker instead — accepted.
      e.handleEvent(
        MemeSubmitEvent(userId: 'p1', ts: 11, stickerChoice: 'sticker-c'),
      );
      expect(e.currentState.submissions['p1']!.stickerChoice, 'sticker-c');
    });

    test('a used sticker for ONE player never blocks a different player from '
        'using that exact same sticker', () {
      final e = _engine(['p1', 'p2']);
      e.handleEvent(
        MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'shared'),
      );
      e.handleEvent(
        MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'shared'),
      );
      // Both accepted in the SAME round even though the sticker string is
      // identical — this rule is per-player, never global.
      expect(e.currentState.submissions['p1']!.stickerChoice, 'shared');
      expect(e.currentState.submissions['p2']!.stickerChoice, 'shared');
    });

    test('a caption-only submission (no sticker) never touches used-sticker '
        'history and is accepted normally', () {
      final e = _engine(['p1', 'p2']);
      e.handleEvent(
        MemeSubmitEvent(userId: 'p1', ts: 1, caption: 'just words'),
      );
      expect(e.currentState.submissions['p1']!.caption, 'just words');
      expect(e.currentState.submissions['p1']!.stickerChoice, isEmpty);
    });
  });

  group('Item 5 — persistence across the lifecycle', () {
    test('used-sticker history persists across rounds (advanceTurn) within '
        'the same game', () {
      final e = _engine(['p1', 'p2'], maxRounds: 10);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      e.handleEvent(MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'));
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 3, targetUserId: 'p2'));
      e.handleEvent(MemeVoteEvent(userId: 'p2', ts: 4, targetUserId: 'p1'));
      e.advanceTurn();
      // Still rejected two rounds later.
      e.handleEvent(MemeSubmitEvent(userId: 'p2', ts: 5, stickerChoice: 'c'));
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 6, targetUserId: 'p2'));
      e.handleEvent(
        MemeSubmitEvent(userId: 'p1', ts: 7, stickerChoice: 'a'),
      ); // still blocked
      expect(e.currentState.submissions.containsKey('p1'), isFalse);
    });

    test('starting a brand-new game (init) clears every player\'s '
        'used-sticker history', () {
      final e = _engine(['p1', 'p2']);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      e.init(['p1', 'p2']); // fresh game
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 2, stickerChoice: 'a'));
      expect(e.currentState.submissions['p1']!.stickerChoice, 'a');
    });

    test('used-sticker history survives serialize/restore — reconnect and '
        'host-migration path', () {
      final e = _engine(['p1', 'p2']);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      e.handleEvent(MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'));
      final snapshot = e.serializeState();

      // Simulate a reconnect / new host device restoring from the
      // persisted snapshot.
      final restored = MemeGameEngine(
        _config(),
        prompts: [MemePrompt(id: 'x', caption: 'x')],
      );
      restored.restoreFromSnapshot(snapshot);
      expect(
        restored.currentState.usedStickersByPlayer['p1'],
        contains('a'),
      );
      expect(
        restored.currentState.usedStickersByPlayer['p2'],
        contains('b'),
      );
    });

    test('a pre-migration snapshot with no used_stickers_by_player key '
        'restores cleanly with empty history (no crash, no false rejects)',
        () {
      final e = _engine(['p1', 'p2']);
      final snapshot = e.serializeState()
        ..remove('used_stickers_by_player');
      final restored = MemeState.fromMap(snapshot);
      expect(restored.usedStickersByPlayer, isEmpty);
    });
  });

  group('Item 5 — unrelated behavior untouched', () {
    test('duplicate submission from the same player is still rejected '
        '(pre-existing rule, not part of this change)', () {
      final e = _engine(['p1', 'p2']);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 2, stickerChoice: 'z'));
      expect(e.currentState.submissions['p1']!.stickerChoice, 'a');
    });

    test('voting/pass/reactions are unaffected by used-sticker tracking',
        () {
      final e = _engine(['p1', 'p2']);
      e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
      e.handleEvent(MemeSubmitEvent(userId: 'p2', ts: 2, stickerChoice: 'b'));
      e.handleEvent(MemeVoteEvent(userId: 'p1', ts: 3, targetUserId: 'p2'));
      e.handleEvent(MemePassEvent(userId: 'p2', ts: 4));
      expect(e.currentState.phase, MemePhase.results);
      expect(e.currentState.passes, {'p2'});
    });
  });
}
