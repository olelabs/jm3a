// Trial Packs — real-device bug fix regression.
//
// Real-device report: with trial_card_count = 5, the game played the
// entire pack instead of stopping after 5 cards; the purchase prompt
// never appeared until the pack was exhausted. Root cause (see
// pack_trial_state.dart's PackTrialStatus.fromConsumeResult doc comment
// for the full explanation): the `reason == 'trial'` branch treated
// cardsPlayed reaching trialCardCount as immediate `exhausted`, even
// though the RPC's own `allowed` was true for that exact call — this
// made every provider's ownerAdvanceTurn gate refuse to reveal the LAST
// legitimately-allowed card, stopping the trial one card early. Combined
// with a separate real bug elsewhere in the same call path (now also
// fixed — see PackRepository.startPackTrial's defensive response
// parsing), a failure at game start could silently null out
// TodGameProvider/NhieGameProvider/MemeGameProvider's trialStatus for
// the entire rest of the session, disabling the gate outright — which
// is the more literal match for "played the whole pack."
//
// The actual gating logic (ownerAdvanceTurn's `if (status.state ==
// PackTrialState.exhausted) return;` check, identical across all three
// game providers) lives in ONE shared function this file tests directly
// — PackTrialStatus.fromConsumeResult, driven through a pure-Dart
// simulator (_FakeTrialUsage below) that is a deliberately literal port
// of try_consume_trial_card()'s own SQL branches (migration_2026_
// pack_trial.sql): block without incrementing once cardsPlayed >=
// trialCardCount, otherwise increment and allow. Because ToD/NHIE/Meme
// all call the exact same PackRepository.tryConsumeTrialCard ->
// PackTrialStatus.fromConsumeResult path with no per-engine branching,
// proving the shared logic here covers all three — a live, per-engine
// provider test isn't reachable without a live Supabase instance (this
// project's established testing boundary), and re-deriving the same
// assertions three times against mocked providers would test the mock,
// not the real decision.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/packs/domain/pack_trial_state.dart';

/// A literal Dart port of try_consume_trial_card(p_pack_id)'s own
/// decision (migration_2026_pack_trial.sql): reject without touching
/// cardsPlayed once the limit is already reached, otherwise increment
/// and allow. `owned` short-circuits to the RPC's own 'owned' branch.
class _FakeTrialUsage {
  _FakeTrialUsage(this.trialCardCount);
  final int trialCardCount;
  int cardsPlayed = 0;
  bool owned = false;

  PackTrialStatus consume() {
    if (owned) {
      return PackTrialStatus.fromConsumeResult(
        allowed: true,
        reason: 'owned',
        cardsPlayed: cardsPlayed,
        trialCardCount: trialCardCount,
      );
    }
    if (cardsPlayed >= trialCardCount) {
      return PackTrialStatus.fromConsumeResult(
        allowed: false,
        reason: 'trial_exhausted',
        cardsPlayed: cardsPlayed,
        trialCardCount: trialCardCount,
      );
    }
    cardsPlayed += 1;
    return PackTrialStatus.fromConsumeResult(
      allowed: true,
      reason: 'trial',
      cardsPlayed: cardsPlayed,
      trialCardCount: trialCardCount,
    );
  }
}

/// Mirrors the exact gate every game provider's ownerAdvanceTurn runs
/// immediately before `_engine!.advanceTurn(...)`/`_engine!.init(...)`:
/// consume once, reveal only if the result isn't exhausted.
bool _tryReveal(_FakeTrialUsage usage) =>
    usage.consume().state != PackTrialState.exhausted;

void main() {
  group(
    'A/B: trial_card_count = 5 allows exactly 5 cards, card 6 is blocked',
    () {
      test(
        'cards 1-5 are each individually revealable; the 6th attempt is '
        'the first one blocked',
        () {
          final usage = _FakeTrialUsage(5);
          final revealed = List.generate(6, (_) => _tryReveal(usage));

          expect(
            revealed,
            [true, true, true, true, true, false],
            reason:
                'exactly 5 cards playable (task requirement) — the '
                'previous bug blocked after only 4',
          );
          expect(
            usage.cardsPlayed,
            5,
            reason: 'the blocked 6th attempt must never increment cardsPlayed',
          );
        },
      );

      test(
        'card 5 specifically (the one that reaches the limit) is still '
        'revealed, not treated as already exhausted',
        () {
          final usage = _FakeTrialUsage(5)..cardsPlayed = 4;
          final status = usage.consume();
          expect(
            status.state,
            PackTrialState.active,
            reason:
                'this is the exact real-device regression: the card that '
                'brings cardsPlayed to the limit must still be shown',
          );
          expect(usage.cardsPlayed, 5);
        },
      );

      test('the 6th attempt is reported as exhausted, not active', () {
        final usage = _FakeTrialUsage(5)..cardsPlayed = 5;
        final status = usage.consume();
        expect(status.state, PackTrialState.exhausted);
        expect(usage.cardsPlayed, 5, reason: 'unchanged — never over-incremented');
      });

      test('repeated attempts past the limit never increment further', () {
        final usage = _FakeTrialUsage(5)..cardsPlayed = 5;
        for (var i = 0; i < 10; i++) {
          expect(usage.consume().state, PackTrialState.exhausted);
        }
        expect(usage.cardsPlayed, 5);
      });
    },
  );

  group(
    'C: after a successful purchase, the gate no longer blocks — the '
    'next card is reachable through the normal flow',
    () {
      test(
        'marking the pack owned (mirrors resumeAfterTrialPurchase) makes '
        'every subsequent consume report owned, never exhausted',
        () {
          final usage = _FakeTrialUsage(5)..cardsPlayed = 5; // exhausted
          expect(usage.consume().state, PackTrialState.exhausted);

          usage.owned = true; // purchase succeeded
          final afterPurchase = usage.consume();
          expect(afterPurchase.state, PackTrialState.owned);
          expect(
            afterPurchase.state,
            isNot(PackTrialState.exhausted),
            reason:
                'ownerAdvanceTurn/initAsOwner skip the gate entirely once '
                'state == owned, so the next card (6) is revealed by the '
                'normal, unmodified advance/init call',
          );
        },
      );
    },
  );

  group(
    'D: cancelling/declining leaves the trial consumed — no bypass via '
    'repeated attempts',
    () {
      test(
        'declining after exhaustion does not reset cardsPlayed or state '
        '(mirrors: ending the game never touches pack_trial_usage)',
        () {
          final usage = _FakeTrialUsage(5)..cardsPlayed = 5;
          expect(usage.consume().state, PackTrialState.exhausted);
          // "Decline" in the real app calls requestEndGame()/endGame(),
          // which has no path back into pack_trial_usage at all — this
          // fake has nothing to call, so the absence of any mutation
          // here IS the property under test: nothing resets cardsPlayed.
          expect(usage.consume().state, PackTrialState.exhausted);
          expect(usage.cardsPlayed, 5);
        },
      );
    },
  );

  group('G: purchased users are never blocked by the trial gate', () {
    test(
      'an owned pack always reports owned regardless of how many cards '
      'have been played, including well past any trial limit',
      () {
        final usage = _FakeTrialUsage(5)..owned = true;
        for (var i = 0; i < 20; i++) {
          expect(usage.consume().state, PackTrialState.owned);
        }
      },
    );
  });

  group('non-trial packs are never gated', () {
    test("reason 'not_trial_pack' is always allowed, never exhausted", () {
      final status = PackTrialStatus.fromConsumeResult(
        allowed: true,
        reason: 'not_trial_pack',
        cardsPlayed: 0,
        trialCardCount: 0,
      );
      expect(status.state, isNot(PackTrialState.exhausted));
    });
  });
}
