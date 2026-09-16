// Trial Packs — pure coverage for PackTrialStatus.fromConsumeResult, the
// function that turns try_consume_trial_card()'s RPC response (see
// migration_2026_pack_trial.sql) into the client-facing PackTrialState
// every game provider (TodGameProvider/NhieGameProvider/MemeGameProvider)
// gates ownerAdvanceTurn on. The actual atomic increment/limit
// enforcement lives in the database (row-locked UPDATE ... WHERE
// cards_played < trial_card_count) and cannot be exercised without a
// live Supabase instance — not available in this test environment (see
// this project's established Supabase-singleton testing boundary,
// documented repeatedly elsewhere in this test suite). This file proves
// the one genuinely pure decision on the client side: given an RPC
// response, what PackTrialState/cardsRemaining does the UI see.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/packs/domain/pack_trial_state.dart';

void main() {
  group('PackTrialStatus.fromConsumeResult', () {
    test("reason 'not_trial_pack' -> notTrialPack, gating never applies", () {
      final s = PackTrialStatus.fromConsumeResult(
        allowed: true,
        reason: 'not_trial_pack',
        cardsPlayed: 0,
        trialCardCount: 0,
      );
      expect(s.state, PackTrialState.notTrialPack);
      expect(s.isExhausted, isFalse);
    });

    test("reason 'owned' -> owned, no trial limitation applies", () {
      final s = PackTrialStatus.fromConsumeResult(
        allowed: true,
        reason: 'owned',
        cardsPlayed: 0,
        trialCardCount: 5,
      );
      expect(s.state, PackTrialState.owned);
      expect(s.isExhausted, isFalse);
    });

    test(
      "reason 'trial' with cardsPlayed below the limit -> active, cards "
      'remaining is exact',
      () {
        final s = PackTrialStatus.fromConsumeResult(
          allowed: true,
          reason: 'trial',
          cardsPlayed: 3,
          trialCardCount: 5,
        );
        expect(s.state, PackTrialState.active);
        expect(s.cardsRemaining, 2);
        expect(s.isActive, isTrue);
      },
    );

    test(
      // Real-device bug fix: reason 'trial' means the RPC's own
      // `allowed` was true — this exact card (even the one that brings
      // cardsPlayed to trialCardCount, e.g. the 5th of 5) WAS
      // legitimately granted and must be treated as active/revealable,
      // never exhausted. Exhaustion is only ever reported by the RPC's
      // own distinct 'trial_exhausted' reason (see the next test) — the
      // response to the NEXT call, the one that tries to go past the
      // limit. Getting this wrong previously made the gate refuse to
      // reveal the LAST allowed card, stopping the trial one card early
      // (4 shown instead of 5).
      "reason 'trial' with cardsPlayed == the limit (the card that just "
      'legitimately reached it) -> still active, not exhausted',
      () {
        final s = PackTrialStatus.fromConsumeResult(
          allowed: true,
          reason: 'trial',
          cardsPlayed: 5,
          trialCardCount: 5,
        );
        expect(s.state, PackTrialState.active);
        expect(s.cardsRemaining, 0);
        expect(s.isExhausted, isFalse);
      },
    );

    test(
      "reason 'trial_exhausted' (the blocked attempt after the limit) -> "
      'exhausted, allowed is irrelevant to the mapped state',
      () {
        final s = PackTrialStatus.fromConsumeResult(
          allowed: false,
          reason: 'trial_exhausted',
          cardsPlayed: 5,
          trialCardCount: 5,
        );
        expect(s.state, PackTrialState.exhausted);
        expect(s.isExhausted, isTrue);
      },
    );

    test(
      "reason 'no_active_trial' -> eligible (caller should have called "
      'startPackTrial first; never silently treated as exhausted or owned)',
      () {
        final s = PackTrialStatus.fromConsumeResult(
          allowed: false,
          reason: 'no_active_trial',
          cardsPlayed: 0,
          trialCardCount: 5,
        );
        expect(s.state, PackTrialState.eligible);
      },
    );

    test('an unrecognized reason falls back to notTrialPack, never crashes', () {
      final s = PackTrialStatus.fromConsumeResult(
        allowed: true,
        reason: 'something_unexpected',
        cardsPlayed: 0,
        trialCardCount: 0,
      );
      expect(s.state, PackTrialState.notTrialPack);
    });
  });

  group('PackTrialStatus.cardsRemaining', () {
    test('never negative even if cardsPlayed somehow exceeds the count', () {
      const s = PackTrialStatus(
        state: PackTrialState.exhausted,
        cardsPlayed: 7,
        trialCardCount: 5,
      );
      expect(s.cardsRemaining, 0);
    });

    test('the default (no-args) status is notTrialPack with zero counts', () {
      const s = PackTrialStatus();
      expect(s.state, PackTrialState.notTrialPack);
      expect(s.cardsPlayed, 0);
      expect(s.trialCardCount, 0);
      expect(s.cardsRemaining, 0);
    });
  });
}
