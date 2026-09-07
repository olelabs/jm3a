// Regression coverage for the real-device bug: after a player selects
// Punishment and submits their response/proof, the performer sees it but
// other players in the same ToD game see nothing.
//
// ROOT CAUSE (full detail in TruthOrDareEngine._now()'s own doc comment):
// TodState.snapshotAt was generated from plain DateTime.now().
// millisecondsSinceEpoch. TodGameProvider.onStateBroadcast (the follower
// receive path) discards any incoming broadcast whose snapshot_at is <=
// what it already has — a deliberate guard against an out-of-order/stale
// broadcast winning over a newer one. Millisecond resolution isn't fine
// enough: a punishment turn is the one ToD flow that fires several state
// mutations back-to-back with no human think-time between them (each
// other player's punishment proposal, then the pick/resolve, then —
// once typed — the completion), so two consecutive snapshotAt values
// landing in the same millisecond is common, not a rare edge case. The
// loser of that tie is silently dropped by every follower — including,
// when the collision lands on the completion step, the punished
// player's own response/proof. The performer never notices, because the
// OWNER's client applies its own engine mutations directly and
// synchronously and never runs its own actions through
// onStateBroadcast's staleness guard at all — only followers depend on
// it, so only they can silently lose an update. A plain Truth/Dare turn
// has only two human-paced mutations (choice, then completion) and
// rarely collides, which is why the symptom reads as
// punishment-specific even though the underlying flaw was general.
//
// The fix makes TruthOrDareEngine._now() strictly monotonic per engine
// instance instead of a raw wall-clock read, so two calls can never tie
// — closing the bug at its source without weakening or duplicating
// onStateBroadcast's own (otherwise correct) ordering guard.
//
// This suite tests at the actual shared-state boundary: it drives the
// REAL TruthOrDareEngine (the owner-side authority) through a full
// punishment lifecycle, captures serializeState() after every single
// mutation exactly as TodGameProvider._broadcastState() would send it,
// and replays those broadcasts through the EXACT same staleness-guard
// condition TodGameProvider.onStateBroadcast uses (reproduced inline
// below — a full TodGameProvider can't be constructed in an offline
// suite; it requires a live Supabase-backed TodRepository/
// RealtimeService/RoomProvider, the same boundary every other ToD
// provider-level test in this project already documents). This proves
// the fix at the point real followers actually apply state, not just
// inside the engine's own in-memory object.

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

/// A minimal stand-in for a follower client applying broadcasts — mirrors
/// TodGameProvider.onStateBroadcast's exact staleness guard:
/// `if (incomingTs <= currentTs && hasSyncedState) discard`.
class _FakeFollower {
  TodState? state;
  bool hasSynced = false;
  final List<Map<String, dynamic>> discarded = [];

  void receive(Map<String, dynamic> snapshot) {
    final incoming = TodState.fromMap(snapshot);
    final currentTs = state?.snapshotAt ?? 0;
    if (hasSynced && incoming.snapshotAt <= currentTs) {
      discarded.add(snapshot);
      return;
    }
    state = incoming;
    hasSynced = true;
  }
}

/// Drives a full skip → punishment-proposal → pick → completion sequence
/// on [engine], capturing (and "broadcasting" to [follower]) the exact
/// wire payload (serializeState()) after every single mutation, exactly
/// as TodGameProvider._broadcastState() does after every onPlayerAction.
Map<String, dynamic> _runPunishmentTurn(
  TruthOrDareEngine engine,
  _FakeFollower follower, {
  required String response,
  String proofImageB64 = '',
  String proofVoiceB64 = '',
}) {
  void step(GameEngineEvent e) {
    engine.handleEvent(e);
    final snap = engine.serializeState();
    follower.receive(snap);
  }

  step(TodChoiceEvent(userId: 'p1', ts: 0, cardType: TodCardType.dare));
  step(TodSkipEvent(userId: 'p1', ts: 0));
  step(TodProposePunishmentEvent(userId: 'p2', ts: 0, text: 'do 10 pushups'));
  step(TodProposePunishmentEvent(userId: 'p3', ts: 0, text: 'sing a song'));
  step(TodProposePunishmentEvent(userId: 'p4', ts: 0, text: 'dance'));
  final voteState = engine.currentState.currentPunishmentVote!;
  final chosenId = voteState.options.first.id;
  step(TodVotePunishmentEvent(userId: 'p1', ts: 0, optionId: chosenId));
  step(
    TodCompleteEvent(
      userId: 'p1',
      ts: 0,
      response: response,
      proofImageB64: proofImageB64,
      proofVoiceB64: proofVoiceB64,
    ),
  );
  return engine.serializeState();
}

void main() {
  const config = GameConfig(
    maxRounds: 10,
    turnTimerSeconds: 0,
    allowSkip: true,
    allowSpicy: false,
    enablePunishments: true,
    punishmentSource: 'players',
  );

  group('punishment response/proof reaches other players (shared-state boundary)', () {
    test('a real follower reconstructs the performer\'s text response', () {
      final engine = _engine(config, ['p1', 'p2', 'p3', 'p4']);
      final follower = _FakeFollower();

      _runPunishmentTurn(engine, follower, response: 'I really did it!');

      expect(follower.hasSynced, isTrue);
      expect(follower.discarded, isEmpty,
          reason:
              'no broadcast in a correctly-ordered delivery should ever be '
              'discarded as stale — this is exactly what the snapshotAt '
              'collision bug broke');
      expect(follower.state!.phase, TodTurnPhase.awaitingNextTurn);
      expect(follower.state!.currentCard!.id, startsWith('punishment_'));
      expect(follower.state!.turnResponse, 'I really did it!');
    });

    test('a real follower reconstructs the performer\'s proof (image)', () {
      final engine = _engine(config, ['p1', 'p2', 'p3', 'p4']);
      final follower = _FakeFollower();

      _runPunishmentTurn(
        engine,
        follower,
        response: '',
        proofImageB64: 'aGVsbG8td29ybGQ=',
      );

      expect(follower.state!.turnHasImageProof, isTrue);
      expect(follower.state!.turnProofImageB64, 'aGVsbG8td29ybGQ=');
      expect(follower.discarded, isEmpty);
    });

    test('a real follower reconstructs the performer\'s proof (voice)', () {
      final engine = _engine(config, ['p1', 'p2', 'p3', 'p4']);
      final follower = _FakeFollower();

      _runPunishmentTurn(
        engine,
        follower,
        response: '',
        proofVoiceB64: 'dm9pY2Vwcm9vZg==',
      );

      expect(follower.state!.turnHasVoiceProof, isTrue);
      expect(follower.state!.turnProofVoiceB64, 'dm9pY2Vwcm9vZg==');
      expect(follower.discarded, isEmpty);
    });

    test(
      'snapshotAt never collides across a punishment turn\'s rapid-fire '
      'mutations (the actual root cause) — a bare unfixed millisecond '
      'clock reliably collides here (see git history for the failing '
      'baseline reading)',
      () {
        final engine = _engine(config, ['p1', 'p2', 'p3', 'p4']);
        final seen = <int>{};
        final duplicates = <int>[];
        void step(GameEngineEvent e) {
          engine.handleEvent(e);
          final ts = engine.currentState.snapshotAt;
          if (!seen.add(ts)) duplicates.add(ts);
        }

        step(TodChoiceEvent(userId: 'p1', ts: 0, cardType: TodCardType.dare));
        step(TodSkipEvent(userId: 'p1', ts: 0));
        step(TodProposePunishmentEvent(userId: 'p2', ts: 0, text: 'a'));
        step(TodProposePunishmentEvent(userId: 'p3', ts: 0, text: 'b'));
        step(TodProposePunishmentEvent(userId: 'p4', ts: 0, text: 'c'));
        final voteState =
            engine.currentState.currentPunishmentVote!;
        step(
          TodVotePunishmentEvent(
            userId: 'p1',
            ts: 0,
            optionId: voteState.options.first.id,
          ),
        );
        step(
          TodCompleteEvent(userId: 'p1', ts: 0, response: 'done'),
        );

        expect(duplicates, isEmpty);
      },
    );

    test('reconnect: a follower fetching a fresh snapshot after the fact '
        'still sees the punishment response/proof (persistence path, not '
        'just realtime)', () {
      final engine = _engine(config, ['p1', 'p2', 'p3', 'p4']);
      final liveFollower = _FakeFollower();
      final finalSnapshot = _runPunishmentTurn(
        engine,
        liveFollower,
        response: 'reconnect check',
        proofImageB64: 'cHJvb2Y=',
      );

      // Simulate Player B disconnecting (never having synced) and then
      // reconnecting, fetching only the CURRENT persisted snapshot —
      // exactly TodGameProvider's DB-fallback reconnect path
      // (TodState.fromMap(snapshot) with _hasSyncedState starting false).
      final reconnectingFollower = _FakeFollower();
      reconnectingFollower.receive(finalSnapshot);

      expect(reconnectingFollower.hasSynced, isTrue);
      expect(reconnectingFollower.state!.turnResponse, 'reconnect check');
      expect(reconnectingFollower.state!.turnProofImageB64, 'cHJvb2Y=');
      expect(
        reconnectingFollower.state!.currentCard!.id,
        startsWith('punishment_'),
      );
    });

    test('no duplicate history entries from re-delivered/duplicate '
        'broadcasts of the same completion', () {
      final engine = _engine(config, ['p1', 'p2', 'p3', 'p4']);
      final follower = _FakeFollower();
      final finalSnapshot =
          _runPunishmentTurn(engine, follower, response: 'once only');

      // A duplicate/re-delivered copy of the exact same final broadcast
      // (equal snapshotAt) must be discarded, not double-applied.
      follower.receive(finalSnapshot);
      expect(follower.discarded, hasLength(1));
      expect(follower.state!.history, hasLength(1));
    });
  });

  group('Truth/Dare remote visibility — no regression', () {
    test('a real follower reconstructs a Truth response', () {
      final engine = _engine(config, ['p1', 'p2']);
      final follower = _FakeFollower();

      engine.handleEvent(
        TodChoiceEvent(userId: 'p1', ts: 0, cardType: TodCardType.truth),
      );
      follower.receive(engine.serializeState());
      engine.handleEvent(
        TodCompleteEvent(userId: 'p1', ts: 0, response: 'my truth answer'),
      );
      follower.receive(engine.serializeState());

      expect(follower.state!.turnResponse, 'my truth answer');
      expect(follower.discarded, isEmpty);
    });

    test('a real follower reconstructs a Dare response with proof', () {
      final engine = _engine(config, ['p1', 'p2']);
      final follower = _FakeFollower();

      engine.handleEvent(
        TodChoiceEvent(userId: 'p1', ts: 0, cardType: TodCardType.dare),
      );
      follower.receive(engine.serializeState());
      engine.handleEvent(
        TodCompleteEvent(
          userId: 'p1',
          ts: 0,
          response: '',
          proofImageB64: 'ZGFyZXByb29m',
        ),
      );
      follower.receive(engine.serializeState());

      expect(follower.state!.turnProofImageB64, 'ZGFyZXByb29m');
      expect(follower.discarded, isEmpty);
    });
  });

  group('completion validation — server-authoritative, not just UI', () {
    test('empty punishment response with no proof is rejected (turn stays '
        'in readingCard, no state advance)', () {
      final engine = _engine(config, ['p1', 'p2', 'p3', 'p4']);
      engine.handleEvent(
        TodChoiceEvent(userId: 'p1', ts: 0, cardType: TodCardType.dare),
      );
      engine.handleEvent(TodSkipEvent(userId: 'p1', ts: 0));
      engine.handleEvent(
        TodProposePunishmentEvent(userId: 'p2', ts: 0, text: 'a'),
      );
      engine.handleEvent(
        TodProposePunishmentEvent(userId: 'p3', ts: 0, text: 'b'),
      );
      engine.handleEvent(
        TodProposePunishmentEvent(userId: 'p4', ts: 0, text: 'c'),
      );
      final voteState =
          engine.currentState.currentPunishmentVote!;
      engine.handleEvent(
        TodVotePunishmentEvent(
          userId: 'p1',
          ts: 0,
          optionId: voteState.options.first.id,
        ),
      );

      engine.handleEvent(TodCompleteEvent(userId: 'p1', ts: 0, response: ''));
      expect(engine.currentState.phase, TodTurnPhase.readingCard);

      engine.handleEvent(
        TodCompleteEvent(userId: 'p1', ts: 0, response: '   '),
      );
      expect(engine.currentState.phase, TodTurnPhase.readingCard);
    });

    test('duplicate completion for the same turn is a safe no-op', () {
      final engine = _engine(config, ['p1', 'p2']);
      engine.handleEvent(
        TodChoiceEvent(userId: 'p1', ts: 0, cardType: TodCardType.dare),
      );
      engine.handleEvent(
        TodCompleteEvent(userId: 'p1', ts: 0, response: 'first'),
      );
      final afterFirst = engine.currentState;
      expect(afterFirst.history, hasLength(1));

      // A stale/replayed client re-sending the same completion after the
      // phase has already advanced past readingCard must not double-record
      // history or overwrite the response.
      engine.handleEvent(
        TodCompleteEvent(userId: 'p1', ts: 0, response: 'second'),
      );
      final afterSecond = engine.currentState;
      expect(afterSecond.history, hasLength(1));
      expect(afterSecond.history.single.response, 'first');
    });
  });
}
