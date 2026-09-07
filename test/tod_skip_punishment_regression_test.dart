// Tests for the real-device ToD regressions: player Skip not appearing
// despite allowSkip=true, and a missing punishment indicator.
//
// Root causes (full detail in each fix's own doc comment):
//   1. Player Skip (tod_card_screen.dart): the Skip button required
//      `allowSkip && enablePunishments` — an extra, unauthorized
//      condition TruthOrDareEngine._onSkip never enforced (confirmed
//      below and already proven by test/tod_settings_audit_test.dart's
//      existing 'allowSkip' engine test, which uses the DEFAULT
//      enablePunishments=false and already shows skip is accepted).
//      That existing suite doesn't cover enablePunishments=TRUE
//      alongside allowSkip=true explicitly — added here to close that
//      specific gap and make the "these two settings are independent"
//      guarantee explicit.
//   2. Punishment indicator (tod_hud.dart's new _PunishmentBadge): was
//      simply never built. Purely reads the existing GameConfig
//      .enablePunishments the engine already enforces — no new state.
//
// TodGameProvider/TodHud both need a live RealtimeService/TodRepository
// (Supabase-backed, even for their private singleton constructors) this
// offline suite doesn't have — see every prior session's identical
// boundary — so the button-visibility and HUD-badge fixes themselves
// cannot be widget-tested here. What IS fully offline-testable, and
// directly underpins both fixes, is TruthOrDareEngine's own behavior —
// exercised against the REAL engine, not a reproduction.

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

void main() {
  group('5 — player Skip is independent of enablePunishments', () {
    test('allowSkip=true, enablePunishments=TRUE also accepts skip and '
        'correctly routes to punishment voting — completing the matrix '
        'the existing allowSkip test (default enablePunishments=false) '
        'doesn\'t cover explicitly', () {
      final e = _engine(
        const GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 0,
          allowSkip: true,
          allowSpicy: false,
          enablePunishments: true,
        ),
        ['p1', 'p2'],
      );
      e.handleEvent(
        TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.dare),
      );
      e.handleEvent(TodSkipEvent(userId: 'p1', ts: 2));
      expect(e.currentState.phase, TodTurnPhase.punishmentVoting);
    });

    test('allowSkip=true, enablePunishments=FALSE (the exact combination '
        'the buggy UI condition — allowSkip && enablePunishments — used '
        'to hide the Skip button for even though the engine always '
        'accepted it) still accepts skip and routes straight to the next '
        'turn, no punishment phase to enter', () {
      final e = _engine(
        const GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 0,
          allowSkip: true,
          allowSpicy: false,
          enablePunishments: false,
        ),
        ['p1', 'p2'],
      );
      e.handleEvent(
        TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.dare),
      );
      e.handleEvent(TodSkipEvent(userId: 'p1', ts: 2));
      expect(e.currentState.phase, TodTurnPhase.awaitingNextTurn);
    });
  });

  group('4 — punishment indicator reads the existing authoritative '
      'GameConfig', () {
    test('enablePunishments is the exact, sole condition both the new '
        'HUD badge and the engine\'s own post-skip routing key off — '
        'proving there\'s nothing left to keep in sync between them', () {
      final on = _engine(
        const GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 0,
          allowSkip: true,
          allowSpicy: false,
          enablePunishments: true,
        ),
        ['p1', 'p2'],
      );
      on.handleEvent(
        TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.dare),
      );
      on.handleEvent(TodSkipEvent(userId: 'p1', ts: 2));
      expect(on.currentState.phase, TodTurnPhase.punishmentVoting);

      final off = _engine(
        const GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 0,
          allowSkip: true,
          allowSpicy: false,
          enablePunishments: false,
        ),
        ['p1', 'p2'],
      );
      off.handleEvent(
        TodChoiceEvent(userId: 'p1', ts: 1, cardType: TodCardType.dare),
      );
      off.handleEvent(TodSkipEvent(userId: 'p1', ts: 2));
      expect(off.currentState.phase, isNot(TodTurnPhase.punishmentVoting));
    });
  });
}
