// Item 2 (TOD settings: enable/disable dares) — the actual security
// enforcement, tested at the authoritative engine level (mirrors
// tod_state_broadcast_roundtrip_test.dart's own TruthOrDareEngine
// construction/handleEvent pattern). A client requesting a Dare directly
// (TodChoiceEvent(cardType: TodCardType.dare)) must be silently coerced
// back to Truth by the engine whenever GameConfig.daresEnabled is false
// — this is the one line in TruthOrDareEngine._onChoice that actually
// prevents a modified/tampered client from bypassing the setting.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
import 'package:jma3a/features/games/truth_or_dare/truth_or_dare_engine.dart';

List<TodCard> _mixedDeck() => [
  for (var i = 0; i < 5; i++)
    TodCard(
      id: 'truth$i',
      content: 'truth $i',
      type: TodCardType.truth,
      difficulty: TodDifficulty.mild,
    ),
  for (var i = 0; i < 5; i++)
    TodCard(
      id: 'dare$i',
      content: 'dare $i',
      type: TodCardType.dare,
      difficulty: TodDifficulty.mild,
    ),
];

List<TodCard> _dareOnlyDeck() => [
  for (var i = 0; i < 5; i++)
    TodCard(
      id: 'dare$i',
      content: 'dare $i',
      type: TodCardType.dare,
      difficulty: TodDifficulty.mild,
    ),
];

TruthOrDareEngine _engine({
  required List<TodCard> cards,
  bool daresEnabled = true,
  String forceDareMode = 'unlimited',
  int maxTruths = 2,
}) {
  final e = TruthOrDareEngine(
    GameConfig(
      maxRounds: 10,
      turnTimerSeconds: 0,
      allowSkip: true,
      allowSpicy: false,
      daresEnabled: daresEnabled,
      forceDareMode: forceDareMode,
      maxTruths: maxTruths,
    ),
    cards: cards,
  );
  e.init(playerOrder: ['p1', 'p2']);
  return e;
}

void main() {
  group('daresEnabled: true (default) — existing behavior preserved exactly', () {
    test('choosing dare draws a dare card', () {
      final e = _engine(cards: _mixedDeck());
      e.handleEvent(
        TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.dare),
      );
      expect(e.currentState.currentCard?.type, TodCardType.dare);
    });

    test('choosing truth draws a truth card', () {
      final e = _engine(cards: _mixedDeck());
      e.handleEvent(
        TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.truth),
      );
      expect(e.currentState.currentCard?.type, TodCardType.truth);
    });
  });

  group('daresEnabled: false — only Truth is ever selectable', () {
    test(
      'requesting a dare DIRECTLY is coerced to truth — the actual '
      'bypass this setting must prevent, since a tampered client can '
      'send cardType: dare regardless of what the UI offers',
      () {
        final e = _engine(cards: _mixedDeck(), daresEnabled: false);
        e.handleEvent(
          TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.dare),
        );
        expect(e.currentState.currentCard?.type, TodCardType.truth);
      },
    );

    test('choosing truth still behaves exactly as normal', () {
      final e = _engine(cards: _mixedDeck(), daresEnabled: false);
      e.handleEvent(
        TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.truth),
      );
      expect(e.currentState.currentCard?.type, TodCardType.truth);
    });

    test(
      'daresEnabled=false wins even when forceDareMode would otherwise '
      'coerce truth->dare (per_turn, maxTruths=0 — always "over limit")',
      () {
        final e = _engine(
          cards: _mixedDeck(),
          daresEnabled: false,
          forceDareMode: 'per_turn',
          maxTruths: 0,
        );
        e.handleEvent(
          TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.truth),
        );
        // Without the daresEnabled fix this would be forced to a dare
        // (globalTruthStreak 0 >= maxTruths 0) — the setting must still
        // win and keep it a truth.
        expect(e.currentState.currentCard?.type, TodCardType.truth);
      },
    );

    test(
      'edge case: only dare content remains available -> the game ends '
      'via the existing cards_exhausted path, never returns a dare',
      () {
        final e = _engine(cards: _dareOnlyDeck(), daresEnabled: false);
        e.handleEvent(
          TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.truth),
        );
        expect(e.currentState.isOver, isTrue);
        expect(e.currentState.endReason, 'cards_exhausted');
        expect(e.currentState.currentCard, isNull);
      },
    );
  });
}
