// Tests for item 18.2's persistence layer — RoomSettingsEntity's new
// forceDareMode/maxTruths fields, the durable store _syncGameRoute's
// GameConfig reconstruction (lobby_screen.dart) now reads instead of
// silently defaulting to 'unlimited'/2 on every navigation into the game
// screen (including the owner's own first navigation).

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';

void main() {
  group('15/16. RoomSettingsEntity forceDareMode/maxTruths round-trip', () {
    test('defaults match GameConfig defaults (unlimited / 2)', () {
      const s = RoomSettingsEntity();
      expect(s.forceDareMode, 'unlimited');
      expect(s.maxTruths, 2);
    });

    test('toMap/fromMap round-trips both fields unchanged — the exact '
        'mechanism room.settings persistence and reconnect reconstruction '
        'both use', () {
      const s = RoomSettingsEntity(forceDareMode: 'per_player', maxTruths: 3);
      final restored = RoomSettingsEntity.fromMap(s.toMap());
      expect(restored.forceDareMode, 'per_player');
      expect(restored.maxTruths, 3);
    });

    test('fromMap tolerates a legacy row with neither key present — '
        'defaults to unlimited/2, never throws', () {
      final restored = RoomSettingsEntity.fromMap({
        'turn_timer_secs': 60,
        'max_rounds': 10,
      });
      expect(restored.forceDareMode, 'unlimited');
      expect(restored.maxTruths, 2);
    });

    test('copyWith updates only the targeted field', () {
      const s = RoomSettingsEntity();
      final updated = s.copyWith(forceDareMode: 'per_turn');
      expect(updated.forceDareMode, 'per_turn');
      expect(updated.maxTruths, 2); // untouched
    });

    test('toMap uses the exact snake_case keys the DB column/RPC field '
        'names expect', () {
      const s = RoomSettingsEntity(forceDareMode: 'per_turn', maxTruths: 4);
      final map = s.toMap();
      expect(map['force_dare_mode'], 'per_turn');
      expect(map['max_truths'], 4);
    });
  });
}
