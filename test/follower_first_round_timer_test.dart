// Tests for the real-device bug: on the FIRST round, a follower (any
// non-owner client) never saw the round timer at all — it only started
// working from the second round onward. The owner was never affected.
//
// Root cause (see NhieGameProvider.onStateBroadcast / MemeGameProvider
// .onStateBroadcast's identical doc comment, both in their respective
// screen files): a follower's very FIRST state broadcast arrives while
// the session's lifecycle_state is still 'starting' — at that moment
// isSessionActive is false, so _syncTimer() correctly (if temporarily)
// leaves the timer off. Once every player confirms ready, the owner's
// _activateSession() flips lifecycle_state to 'active' and rebroadcasts
// — but broadcasts the SAME state object (nothing mutated it since
// engine.init()), so its snapshot_at is IDENTICAL to the first
// broadcast's. onStateBroadcast's own staleness guard
// (incomingTs <= currentTs) treats that as a duplicate and returns
// BEFORE ever reaching the _syncTimer() call at the bottom of the
// method — so the lifecycle transition that was supposed to unblock the
// timer never gets a chance to re-derive it. Nothing else re-evaluates
// the timer until the NEXT round's genuinely-newer snapshot arrives via
// advanceTurn() — exactly matching "works from round 2 onward". The fix
// adds a _syncTimer() call directly inside the lifecycle-transition
// block, BEFORE the staleness check can short-circuit it — safe to call
// unconditionally since _syncTimer() always cancels any existing ticker
// before recomputing (see round_timer_test.dart's existing coverage of
// that idempotency), so this can never create a duplicate timer/ticker.
//
// NhieGameProvider/MemeGameProvider themselves need a live
// RealtimeService (Supabase-backed, even for its private singleton
// constructor) this offline suite doesn't have — see every prior
// session's identical boundary. What's tested here is the exact
// SEQUENCE of engine states + lifecycle transitions a follower's
// broadcast handling goes through, built from the REAL
// NeverHaveIEverEngine/MemeGameEngine (so the state shapes —
// timerStartedAt, snapshotAt — are authentic, not fabricated), driving a
// minimal harness that mirrors onStateBroadcast's exact staleness-check
// + lifecycle-transition + _syncTimer() sequence, INCLUDING this
// session's fix. This is a faithful reproduction of the provider logic,
// not an exercise of the provider class itself — see final report.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/meme_game/meme_game_engine.dart';
import 'package:jma3a/features/games/never_have_i_ever/never_have_i_ever_engine.dart';

/// Mirrors the exact subset of NhieGameProvider/MemeGameProvider relevant
/// to this bug: lifecycle state, config, and the derived timer fields
/// _syncTimer() maintains — including the fix (the _syncTimer() call
/// inside the lifecycle-transition block).
class _FollowerTimerSync {
  _FollowerTimerSync({required this.turnTimerSeconds});
  final int turnTimerSeconds;

  String lifecycleState = 'active'; // same default as both providers
  int? _snapshotAt;
  int? _timerStartedAt;
  int timerRemaining = 0;
  bool timerIsRunning = false;

  bool get isSessionActive => lifecycleState == 'active';

  void _syncTimer(int nowMs) {
    if (!isSessionActive) {
      timerIsRunning = false;
      return;
    }
    if (_timerStartedAt == null || turnTimerSeconds <= 0) {
      timerRemaining = 0;
      timerIsRunning = false;
      return;
    }
    final elapsed = (nowMs - _timerStartedAt!) ~/ 1000;
    timerRemaining = (turnTimerSeconds - elapsed).clamp(0, turnTimerSeconds);
    timerIsRunning = timerRemaining > 0;
  }

  /// Mirrors onStateBroadcast's exact sequence: lifecycle-transition
  /// block (now including the fix's _syncTimer() call) → staleness check
  /// (which can return early) → normal state restore + _syncTimer().
  void onStateBroadcast({
    required String lifecycle,
    required int snapshotAt,
    required int? timerStartedAt,
    required int nowMs,
  }) {
    if (lifecycleState != lifecycle) {
      final wasStarting = lifecycleState == 'starting';
      lifecycleState = lifecycle;
      if (wasStarting && lifecycle == 'active') {
        _syncTimer(nowMs); // the fix
      }
    }

    if (_snapshotAt != null && snapshotAt <= _snapshotAt!) {
      return; // stale broadcast discarded — exactly as onStateBroadcast does
    }
    _snapshotAt = snapshotAt;
    _timerStartedAt = timerStartedAt;
    _syncTimer(nowMs);
  }
}

void main() {
  group('1/3/5/8 — NHIE follower first-round timer', () {
    test('receives first-round state with timerStartedAt and shows the '
        'timer the instant the session activates, using the SAME '
        'deadline the owner started with — even though the activation '
        'broadcast carries an unchanged (stale-by-timestamp) snapshot', () {
      final engine = NeverHaveIEverEngine(
        const GameConfig(
          maxRounds: 5,
          turnTimerSeconds: 20,
          allowSkip: true,
          allowSpicy: false,
        ),
        cards: [
          for (var i = 0; i < 5; i++)
            NhieCard(id: 'c$i', content: 'card $i', difficulty: 'mild'),
        ],
      );
      engine.init(['admin', 'p2']); // owner's round-1 state
      final ownerDeadline = engine.currentState.timerStartedAt;
      expect(ownerDeadline, isNotNull); // 8. same deadline as the owner

      final follower = _FollowerTimerSync(turnTimerSeconds: 20);
      final t0 = ownerDeadline!;

      // First broadcast: still 'starting' — isSessionActive false.
      follower.onStateBroadcast(
        lifecycle: 'starting',
        snapshotAt: engine.currentState.snapshotAt,
        timerStartedAt: ownerDeadline,
        nowMs: t0,
      );
      expect(follower.timerIsRunning, isFalse); // correct: not active yet

      // Ready barrier completes ~1s later — activation broadcast carries
      // the SAME (unmutated) state snapshot.
      final t1 = t0 + 1000;
      follower.onStateBroadcast(
        lifecycle: 'active',
        snapshotAt: engine.currentState.snapshotAt, // unchanged
        timerStartedAt: ownerDeadline, // same deadline
        nowMs: t1,
      );

      // 1. timer visible. 3. uses the authoritative deadline (not a
      // fresh/local one — remaining reflects the 1s that already passed).
      expect(follower.timerIsRunning, isTrue);
      expect(follower.timerRemaining, 19);
    });

    test('5. does not reset the timer during initialization — the '
        'deadline used is always the one the round actually started '
        'with, never re-derived from "now"', () {
      final engine = NeverHaveIEverEngine(
        const GameConfig(
          maxRounds: 5,
          turnTimerSeconds: 20,
          allowSkip: true,
          allowSpicy: false,
        ),
        cards: [
          for (var i = 0; i < 5; i++)
            NhieCard(id: 'c$i', content: 'card $i', difficulty: 'mild'),
        ],
      );
      engine.init(['admin', 'p2']);
      final deadline = engine.currentState.timerStartedAt!;

      final follower = _FollowerTimerSync(turnTimerSeconds: 20);
      follower.onStateBroadcast(
        lifecycle: 'starting',
        snapshotAt: engine.currentState.snapshotAt,
        timerStartedAt: deadline,
        nowMs: deadline,
      );
      // Several seconds pass before activation — a slow ready barrier.
      final activateAt = deadline + 5000;
      follower.onStateBroadcast(
        lifecycle: 'active',
        snapshotAt: engine.currentState.snapshotAt,
        timerStartedAt: deadline, // still the SAME original deadline
        nowMs: activateAt,
      );
      // Correctly shows 5s already elapsed — not reset back to 20.
      expect(follower.timerRemaining, 15);
    });
  });

  group('2 — Meme follower first-round timer', () {
    test('receives first-round state with timerStartedAt and shows the '
        'timer the instant the session activates', () {
      final engine = MemeGameEngine(
        const GameConfig(
          maxRounds: 5,
          turnTimerSeconds: 25,
          allowSkip: true,
          allowSpicy: false,
        ),
        prompts: [
          for (var i = 0; i < 5; i++) MemePrompt(id: 'p$i', caption: 'c$i'),
        ],
      );
      engine.init(['admin', 'p2']);
      final deadline = engine.currentState.timerStartedAt!;

      final follower = _FollowerTimerSync(turnTimerSeconds: 25);
      follower.onStateBroadcast(
        lifecycle: 'starting',
        snapshotAt: engine.currentState.snapshotAt,
        timerStartedAt: deadline,
        nowMs: deadline,
      );
      expect(follower.timerIsRunning, isFalse);

      follower.onStateBroadcast(
        lifecycle: 'active',
        snapshotAt: engine.currentState.snapshotAt,
        timerStartedAt: deadline,
        nowMs: deadline + 1000,
      );
      expect(follower.timerIsRunning, isTrue);
      expect(follower.timerRemaining, 24);
    });
  });

  group('6 — reconnect during the first round', () {
    test('a follower that (re)connects mid-round after activation already '
        'happened restores the SAME authoritative deadline in one step — '
        'no separate "starting" phase to race, no reset', () {
      final engine = NeverHaveIEverEngine(
        const GameConfig(
          maxRounds: 5,
          turnTimerSeconds: 30,
          allowSkip: true,
          allowSpicy: false,
        ),
        cards: [
          for (var i = 0; i < 5; i++)
            NhieCard(id: 'c$i', content: 'card $i', difficulty: 'mild'),
        ],
      );
      engine.init(['admin', 'p2']);
      final deadline = engine.currentState.timerStartedAt!;

      // Reconnecting follower's local state starts fresh (no prior
      // _snapshotAt), and the room/session is ALREADY 'active' by the
      // time it receives its first (post-reconnect) broadcast.
      final reconnected = _FollowerTimerSync(turnTimerSeconds: 30);
      final reconnectAt = deadline + 8000; // 8s into the round
      reconnected.onStateBroadcast(
        lifecycle: 'active',
        snapshotAt: engine.currentState.snapshotAt,
        timerStartedAt: deadline,
        nowMs: reconnectAt,
      );
      expect(reconnected.timerIsRunning, isTrue);
      expect(reconnected.timerRemaining, 22);
    });
  });

  group('7 — timer OFF remains completely disabled', () {
    test('a follower whose room has the timer disabled never shows a '
        'running timer, even across the exact same starting→active '
        'sequence that triggers the fix for timer-enabled rooms', () {
      final engine = NeverHaveIEverEngine(
        const GameConfig(
          maxRounds: 5,
          turnTimerSeconds: 0, // OFF
          allowSkip: true,
          allowSpicy: false,
        ),
        cards: [
          for (var i = 0; i < 5; i++)
            NhieCard(id: 'c$i', content: 'card $i', difficulty: 'mild'),
        ],
      );
      engine.init(['admin', 'p2']);
      expect(engine.currentState.timerStartedAt, isNull);

      final follower = _FollowerTimerSync(turnTimerSeconds: 0);
      follower.onStateBroadcast(
        lifecycle: 'starting',
        snapshotAt: engine.currentState.snapshotAt,
        timerStartedAt: null,
        nowMs: 1000,
      );
      follower.onStateBroadcast(
        lifecycle: 'active',
        snapshotAt: engine.currentState.snapshotAt,
        timerStartedAt: null,
        nowMs: 2000,
      );
      expect(follower.timerIsRunning, isFalse);
      expect(follower.timerRemaining, 0);
    });
  });
}
