// Item 4 — persistent Honesty-vote enable/disable room setting.
//
// Honesty voting (the shared cast_honesty_vote RPC, rendered via
// CompactHonestyVoteButtons in NHIE/Meme and _HonestyVoteRow/
// DishonestReasonsPanel in ToD) was previously ALWAYS on with no room
// setting to disable it. This adds RoomSettingsEntity.honestyVoteEnabled
// (persisted via the existing room_settings mechanism — see
// migration_2026_honesty_vote_toggle.sql) and GameConfig.honestyVoteEnabled
// (the per-session snapshot the three render sites actually read),
// mirroring exactly how forceDareMode/maxTruths (item 18.2) were added —
// see room_settings_force_dare_test.dart for the same pattern.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';

void main() {
  group('RoomSettingsEntity.honestyVoteEnabled', () {
    test('defaults to true — honesty voting was previously always on; a '
        'new/legacy room must not silently lose the mechanic', () {
      const s = RoomSettingsEntity();
      expect(s.honestyVoteEnabled, isTrue);
    });

    test('toMap/fromMap round-trips true unchanged', () {
      const s = RoomSettingsEntity(honestyVoteEnabled: true);
      final restored = RoomSettingsEntity.fromMap(s.toMap());
      expect(restored.honestyVoteEnabled, isTrue);
    });

    test('toMap/fromMap round-trips false unchanged (the disabled case)', () {
      const s = RoomSettingsEntity(honestyVoteEnabled: false);
      final restored = RoomSettingsEntity.fromMap(s.toMap());
      expect(restored.honestyVoteEnabled, isFalse);
    });

    test('fromMap tolerates a legacy row with no honesty_vote_enabled key '
        'at all — defaults to true, never throws (existing rooms get a '
        'safe default)', () {
      final restored = RoomSettingsEntity.fromMap({
        'turn_timer_secs': 60,
        'max_rounds': 10,
      });
      expect(restored.honestyVoteEnabled, isTrue);
    });

    test('copyWith updates only honestyVoteEnabled, leaving every other '
        'setting untouched', () {
      const s = RoomSettingsEntity();
      final updated = s.copyWith(honestyVoteEnabled: false);
      expect(updated.honestyVoteEnabled, isFalse);
      expect(updated.allowSkip, s.allowSkip);
      expect(updated.maxRounds, s.maxRounds);
    });

    test('toMap uses the exact snake_case key the DB column expects', () {
      const enabled = RoomSettingsEntity(honestyVoteEnabled: true);
      const disabled = RoomSettingsEntity(honestyVoteEnabled: false);
      expect(enabled.toMap()['honesty_vote_enabled'], true);
      expect(disabled.toMap()['honesty_vote_enabled'], false);
    });
  });

  group('GameConfig.honestyVoteEnabled — the per-session value the three '
      'render sites (ToD _HonestyVoteRow/DishonestReasonsPanel, Meme '
      'CompactHonestyVoteButtons, NHIE CompactHonestyVoteButtons) read', () {
    GameConfig config({bool? honestyVoteEnabled}) => GameConfig(
      maxRounds: 10,
      turnTimerSeconds: 60,
      allowSkip: true,
      allowSpicy: false,
      honestyVoteEnabled: honestyVoteEnabled ?? true,
    );

    test('defaults to true', () {
      expect(
        GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 60,
          allowSkip: true,
          allowSpicy: false,
        ).honestyVoteEnabled,
        isTrue,
      );
    });

    test('toMap/fromMap round-trips true', () {
      final restored = GameConfig.fromMap(
        config(honestyVoteEnabled: true).toMap(),
      );
      expect(restored.honestyVoteEnabled, isTrue);
    });

    test('toMap/fromMap round-trips false — the disabled case a reconnect '
        'or a fresh navigation into the game screen must still see', () {
      final restored = GameConfig.fromMap(
        config(honestyVoteEnabled: false).toMap(),
      );
      expect(restored.honestyVoteEnabled, isFalse);
    });

    test('fromMap tolerates a map with no honesty_vote_enabled key — '
        'defaults to true, never throws', () {
      final restored = GameConfig.fromMap({
        'max_rounds': 10,
        'turn_timer_secs': 60,
        'allow_skip': true,
        'allow_spicy': false,
      });
      expect(restored.honestyVoteEnabled, isTrue);
    });
  });
}
