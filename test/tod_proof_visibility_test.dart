// Tests for item 3 — ToD proof visibility modes (Everyone / Players only /
// Spectators only / Personalized), including the personalized/selected-
// users case. Pure domain-model logic — mirrors exactly what
// record_proof_view enforces server-side (see
// migration_2026_tod_per_turn_proof_metadata.sql), which cannot be
// exercised from this offline test suite.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';

void main() {
  group('TodProofVisibility.everyone', () {
    test('players and spectators can both view by default', () {
      const settings = TodProofVisibilitySettings();
      expect(settings.canView('player-1', false), isTrue);
      expect(settings.canView('spectator-1', true), isTrue);
    });

    test('allowSpectators:false excludes spectators only', () {
      const settings = TodProofVisibilitySettings(allowSpectators: false);
      expect(settings.canView('player-1', false), isTrue);
      expect(settings.canView('spectator-1', true), isFalse);
    });
  });

  group('TodProofVisibility.playersOnly', () {
    const settings = TodProofVisibilitySettings(
      visibility: TodProofVisibility.playersOnly,
    );
    test('players can view', () => expect(settings.canView('p1', false), isTrue));
    test(
      'spectators cannot view',
      () => expect(settings.canView('s1', true), isFalse),
    );
  });

  group('TodProofVisibility.spectatorsOnly', () {
    const settings = TodProofVisibilitySettings(
      visibility: TodProofVisibility.spectatorsOnly,
    );
    test(
      'spectators can view',
      () => expect(settings.canView('s1', true), isTrue),
    );
    test(
      'players cannot view',
      () => expect(settings.canView('p1', false), isFalse),
    );
  });

  group('TodProofVisibility.selectedPlayers (Personalized)', () {
    const settings = TodProofVisibilitySettings(
      visibility: TodProofVisibility.selectedPlayers,
      visibleToIds: ['alice', 'bob'],
    );

    test('a selected user (player or spectator) can view', () {
      expect(settings.canView('alice', false), isTrue);
      expect(settings.canView('bob', true), isTrue);
    });

    test('an unauthorized user — not in the selected list — cannot view', () {
      expect(settings.canView('carol', false), isFalse);
      expect(settings.canView('carol', true), isFalse);
    });

    test('an empty selection authorizes nobody', () {
      const empty = TodProofVisibilitySettings(
        visibility: TodProofVisibility.selectedPlayers,
      );
      expect(empty.canView('alice', false), isFalse);
    });
  });

  group('serialization round-trips exactly (persisted as part of the '
      'submission, per item 3/4)', () {
    test('toMap/fromMap preserves visibility, ids, and defaults', () {
      const original = TodProofVisibilitySettings(
        visibility: TodProofVisibility.selectedPlayers,
        visibleToIds: ['u1', 'u2'],
        allowSpectators: false,
      );
      final restored = TodProofVisibilitySettings.fromMap(original.toMap());
      expect(restored.visibility, TodProofVisibility.selectedPlayers);
      expect(restored.visibleToIds, ['u1', 'u2']);
      expect(restored.allowSpectators, isFalse);
    });

    test('an unrecognized visibility value falls back to everyone', () {
      final restored = TodProofVisibilitySettings.fromMap({
        'visibility': 'not_a_real_mode',
      });
      expect(restored.visibility, TodProofVisibility.everyone);
    });
  });

  group('TodProofViewMode — image-only viewing timer (item 4)', () {
    test('once/replayOnce/timed are distinct modes', () {
      expect(TodProofViewMode.once, isNot(TodProofViewMode.timed));
      expect(TodProofViewMode.replayOnce, isNot(TodProofViewMode.timed));
    });
  });
}
