// Follow-up to Item 2 (TOD settings: enable/disable dares) — two related
// fixes:
//
// 1. The "Add Custom Card" sheet (tod_card_screen.dart) has its own
//    Truth/Dare selector, independent of the normal question-selection
//    flow, and previously still allowed creating/injecting a Dare custom
//    card even when GameConfig.daresEnabled was false. Fixed by reusing
//    the same daresEnabled setting (no second flag) at every layer of the
//    trace: UI selector (isCustomCardTypeAllowed), TodGameProvider.
//    addCustomCard, and — the deepest, most authoritative layer, mirroring
//    TruthOrDareEngine._onChoice's own dare->truth coercion —
//    TruthOrDareEngine.injectCard itself.
//
// 2. Premium Plus injecting a custom card into an ALREADY-ONGOING game is
//    a V2 feature; disabled for V1 via
//    TodGameProvider.ongoingGameCustomCardInjectionEnabledV1 (hardcoded
//    false) and the pure ongoingGameCustomCardActionAvailable predicate
//    the "Add Custom Card" button's visibility now also checks.
//
// TodGameProvider requires a live RealtimeService/TodRepository
// (Supabase-backed, not injectable) to construct, so — matching this
// project's established testing boundary for every other
// Supabase-singleton-backed provider — it is not pumped/constructed
// directly here. Instead: the pure decision functions
// (isCustomCardTypeAllowed, ongoingGameCustomCardActionAvailable) are
// unit-tested directly, and the real enforcement at the engine level
// (TruthOrDareEngine.injectCard, the one path that IS constructible
// without Supabase — see tod_dares_enabled_engine_test.dart's own
// precedent) is tested against actual engine state.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
import 'package:jma3a/features/games/truth_or_dare/presentation/screens/tod_card_screen.dart';
import 'package:jma3a/features/games/truth_or_dare/truth_or_dare_engine.dart';

TruthOrDareEngine _engine({bool daresEnabled = true}) {
  final e = TruthOrDareEngine(
    GameConfig(
      maxRounds: 10,
      turnTimerSeconds: 0,
      allowSkip: true,
      allowSpicy: false,
      daresEnabled: daresEnabled,
    ),
    cards: [
      TodCard(
        id: 'seed',
        content: 'seed',
        type: TodCardType.truth,
        difficulty: TodDifficulty.mild,
      ),
    ],
  );
  e.init(playerOrder: ['p1', 'p2']);
  return e;
}

TodCard _card(TodCardType type, {String id = 'custom1'}) => TodCard(
  id: id,
  content: 'a custom card',
  type: type,
  difficulty: TodDifficulty.mild,
);

void main() {
  group('isCustomCardTypeAllowed — Custom Card sheet type selection', () {
    // Test 1
    test('daresEnabled=true -> Truth can be selected', () {
      expect(
        isCustomCardTypeAllowed(
          type: TodCardType.truth,
          daresEnabled: true,
        ),
        isTrue,
      );
    });

    // Test 2
    test('daresEnabled=true -> Dare can be selected (unchanged behavior)', () {
      expect(
        isCustomCardTypeAllowed(type: TodCardType.dare, daresEnabled: true),
        isTrue,
      );
    });

    // Test 3
    test('daresEnabled=false -> Truth can still be selected', () {
      expect(
        isCustomCardTypeAllowed(
          type: TodCardType.truth,
          daresEnabled: false,
        ),
        isTrue,
      );
    });

    // Test 4
    test('daresEnabled=false -> Dare is unavailable', () {
      expect(
        isCustomCardTypeAllowed(type: TodCardType.dare, daresEnabled: false),
        isFalse,
      );
    });
  });

  group(
    'TruthOrDareEngine.injectCard — the underlying injection path (test 5)',
    () {
      test('daresEnabled=true -> an injected Dare custom card enters the deck', () {
        final e = _engine(daresEnabled: true);
        final before = e.deckLength;
        e.injectCard(_card(TodCardType.dare));
        expect(e.deckLength, before + 1);
      });

      test(
        'daresEnabled=false -> injecting a Dare custom card is rejected, '
        'never enters the deck',
        () {
          final e = _engine(daresEnabled: false);
          final before = e.deckLength;
          e.injectCard(_card(TodCardType.dare));
          expect(e.deckLength, before);
        },
      );

      test(
        'daresEnabled=false -> injecting a Truth custom card still works',
        () {
          final e = _engine(daresEnabled: false);
          final before = e.deckLength;
          e.injectCard(_card(TodCardType.truth));
          expect(e.deckLength, before + 1);
        },
      );
    },
  );

  group(
    'ongoingGameCustomCardActionAvailable — V1 ongoing-game restriction',
    () {
      // Test 6
      test('featureEnabledV1=false (V1) -> unavailable even for the owner', () {
        expect(
          ongoingGameCustomCardActionAvailable(
            isOwner: true,
            isPremium: false,
            featureEnabledV1: false,
          ),
          isFalse,
        );
      });

      // Test 7
      test(
        'featureEnabledV1=false (V1) -> unavailable even for an owner with '
        'an active Premium Plus subscription',
        () {
          expect(
            ongoingGameCustomCardActionAvailable(
              isOwner: true,
              isPremium: true,
              featureEnabledV1: false,
            ),
            isFalse,
          );
        },
      );

      test('non-owner is never offered the action regardless of the flag', () {
        expect(
          ongoingGameCustomCardActionAvailable(
            isOwner: false,
            isPremium: true,
            featureEnabledV1: true,
          ),
          isFalse,
        );
      });

      test(
        'the predicate itself is not hardcoded false — a future V2 flip of '
        'featureEnabledV1 to true correctly re-enables it for an owner '
        'with Premium Plus',
        () {
          expect(
            ongoingGameCustomCardActionAvailable(
              isOwner: true,
              isPremium: true,
              featureEnabledV1: true,
            ),
            isTrue,
          );
        },
      );
    },
  );
}
