// Trial Packs — fix 2 regression: the reveal-time defense-in-depth guard
// at the actual TOD choice/reveal boundary (onPlayerAction's handling of
// 'tod_choice', tod_game_provider.dart). Root cause this closes: the
// previous trial gate lived only in ownerAdvanceTurn — one step removed
// from the actual card reveal (TruthOrDareEngine._onChoice, reached via
// chooseTruth()/chooseDare() -> 'tod_choice' -> the SEPARATE generic
// handleEvent fallthrough, structurally independent of ownerAdvanceTurn).
//
// todChoiceAllowedByTrial is the pure decision this guard is built on —
// it deliberately never consumes a trial slot (that already happened,
// proactively, before phase could return to choosingType: either
// initAsOwner's one-time consume for card 1, or the immediately
// preceding ownerAdvanceTurn call's consume for every card after) —
// this only verifies the already-recorded status. A live test of
// onPlayerAction itself would need a fully-wired TodGameProvider
// (Supabase/realtime-backed) — this project's established testing
// boundary — so this file proves the one genuinely pure decision the
// guard makes.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/truth_or_dare/tod_game_provider.dart';
import 'package:jma3a/features/packs/domain/pack_trial_state.dart';

void main() {
  group('todChoiceAllowedByTrial', () {
    test('null trialStatus (not a trial game) -> allowed', () {
      expect(todChoiceAllowedByTrial(null), isTrue);
    });

    test('notTrialPack -> allowed', () {
      const status = PackTrialStatus(state: PackTrialState.notTrialPack);
      expect(todChoiceAllowedByTrial(status), isTrue);
    });

    test('owned -> allowed, no trial restriction', () {
      const status = PackTrialStatus(state: PackTrialState.owned);
      expect(todChoiceAllowedByTrial(status), isTrue);
    });

    test('active, cards remaining -> allowed', () {
      const status = PackTrialStatus(
        state: PackTrialState.active,
        cardsPlayed: 3,
        trialCardCount: 5,
      );
      expect(todChoiceAllowedByTrial(status), isTrue);
    });

    test(
      'active even at exactly the limit (the 5th card, cardsPlayed == '
      'trialCardCount) -> still allowed — this is the exact real-device '
      'regression: the last legitimately-consumed card must be revealed',
      () {
        const status = PackTrialStatus(
          state: PackTrialState.active,
          cardsPlayed: 5,
          trialCardCount: 5,
        );
        expect(todChoiceAllowedByTrial(status), isTrue);
      },
    );

    test('exhausted -> blocked (the only state this guard ever refuses)', () {
      const status = PackTrialStatus(
        state: PackTrialState.exhausted,
        cardsPlayed: 5,
        trialCardCount: 5,
      );
      expect(todChoiceAllowedByTrial(status), isFalse);
    });

    test('eligible (no active trial yet) -> allowed, never mistaken for blocked', () {
      const status = PackTrialStatus(state: PackTrialState.eligible);
      expect(todChoiceAllowedByTrial(status), isTrue);
    });
  });
}
