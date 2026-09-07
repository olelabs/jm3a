// Regression tests for this session's two UI/lifecycle bugs:
//   - NHIE getting permanently stuck on "Time's Up" after a timeout with
//     zero or partial responses (nhie_game_screen.dart's `allVoted` local
//     var and NhieGameProvider.allPlayersVoted getter — both now read
//     `!state.isVotingOpen` instead of counting vote entries).
//   - Meme rendering a blank screen after a no-submission timeout
//     (meme_game_screen.dart's `_buildContent` switch, now routing
//     `MemePhase.voting when state.submissions.isEmpty` to _ResultsScreen
//     instead of falling into _VotingScreen's empty-list rendering).
//
// Both bugs were purely in how the SCREEN/PROVIDER derived a UI decision
// from engine state — the engine's own isVotingOpen/phase fields were
// already flipping correctly (see round_timer_test.dart). What was missing
// there is coverage of the exact zero-response state combination these UI
// fixes depend on: proving it's reachable, and pinning down its shape, so
// a future change to the engine can't silently reintroduce either bug
// without a broken assertion here.
//
// The screens' own provider classes require a live RealtimeService/DI
// stack this offline suite doesn't have (see final report), so these
// assertions operate at the engine level — the same authoritative layer
// both fixed getters/switches ultimately read from.

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
  group('NHIE — the "stuck at Time\'s Up" precondition', () {
    test(
      '1/4/5. two players, NEITHER responds before timeout: isVotingOpen '
      'flips false and voteEntries stays empty — exactly the state '
      '`allVoted = !state.isVotingOpen` (not a vote-count check) must '
      'read as "everyone is done", so the screen can leave the timed-out '
      'view and reach the ready-for-next-round state',
      () {
        final e = _nhie(['p1', 'p2']);
        expect(e.currentState.isVotingOpen, isTrue);
        e.handleEvent(NhieTimerExpiredEvent(userId: 'p1', ts: 1));

        // This is the exact combination that broke the old vote-count-based
        // `allVoted` check: isVotingOpen is false (round is over) while
        // voteEntries is EMPTY (nobody actually answered) — a naive
        // "did everyone vote" count would stay stuck at false forever,
        // since it can never reach playerOrder.length responses.
        expect(e.currentState.isVotingOpen, isFalse);
        expect(e.currentState.voteEntries, isEmpty);
      },
    );

    test(
      '1/4/5. partial response before timeout (one of two players) '
      'resolves the same way — isVotingOpen false regardless of how '
      'many players actually answered',
      () {
        final e = _nhie(['p1', 'p2']);
        e.handleEvent(NhieVoteEvent(userId: 'p1', ts: 1, haveI: true));
        e.handleEvent(NhieTimerExpiredEvent(userId: 'p1', ts: 2));
        expect(e.currentState.isVotingOpen, isFalse);
        expect(e.currentState.voteEntries.length, 1);
      },
    );
  });

  group('Meme — the "blank screen after timeout" precondition', () {
    test(
      '6. two players, NEITHER submits before timeout: phase becomes '
      '`voting` with EMPTY submissions — exactly the state combination '
      '_buildContent\'s `MemePhase.voting when state.submissions.isEmpty` '
      'guard exists to catch, routing to the results/ready screen instead '
      'of _VotingScreen\'s empty-list (blank) rendering',
      () {
        final e = _meme(['p1', 'p2']);
        expect(e.currentState.phase, MemePhase.submitting);
        e.handleEvent(MemeTimerExpiredEvent(userId: 'p1', ts: 1));

        expect(e.currentState.phase, MemePhase.voting);
        expect(e.currentState.submissions, isEmpty);
      },
    );

    test(
      '6. once at least one submission exists, the same timeout instead '
      'produces the normal (non-empty) voting phase — confirming the '
      'empty-submissions routing guard only fires for the genuinely '
      'empty case, never hiding the real voting screen when there is '
      'something to vote on',
      () {
        final e = _meme(['p1', 'p2']);
        e.handleEvent(MemeSubmitEvent(userId: 'p1', ts: 1, stickerChoice: 'a'));
        e.handleEvent(MemeTimerExpiredEvent(userId: 'p2', ts: 2));

        expect(e.currentState.phase, MemePhase.voting);
        expect(e.currentState.submissions, isNotEmpty);
      },
    );
  });
}
