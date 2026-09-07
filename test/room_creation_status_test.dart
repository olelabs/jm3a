// Tests for RoomCreationStatus (task item 7 — room creation limits v2),
// the pure model parsed from get_room_creation_status()'s one-round-trip
// JSON response. This is a UX pre-check only — create_room() itself is
// the actual (SQL, untestable offline) enforcement; see final report.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';

void main() {
  group('RoomCreationStatus.fromMap', () {
    test('parses a normal, under-limit response', () {
      final status = RoomCreationStatus.fromMap({
        'rooms_today': 2,
        'daily_limit': 5,
        'restrictions_enabled': true,
        'next_allowed_at': null,
      });
      expect(status.roomsToday, 2);
      expect(status.dailyLimit, 5);
      expect(status.restrictionsEnabled, isTrue);
      expect(status.nextAllowedAt, isNull);
      expect(status.hasHitDailyLimit, isFalse);
      expect(status.isTooSoon, isFalse);
    });

    test('missing fields fall back safely (never throws)', () {
      final status = RoomCreationStatus.fromMap(const {});
      expect(status.roomsToday, 0);
      expect(status.dailyLimit, 0);
      expect(status.restrictionsEnabled, isTrue);
      expect(status.nextAllowedAt, isNull);
    });
  });

  group('hasHitDailyLimit', () {
    test('true once roomsToday reaches dailyLimit', () {
      expect(
        RoomCreationStatus(
          roomsToday: 5,
          dailyLimit: 5,
          restrictionsEnabled: true,
        ).hasHitDailyLimit,
        isTrue,
      );
    });

    test('false while under the limit', () {
      expect(
        RoomCreationStatus(
          roomsToday: 4,
          dailyLimit: 5,
          restrictionsEnabled: true,
        ).hasHitDailyLimit,
        isFalse,
      );
    });

    test('false when restrictions are globally disabled, even at/over the '
        'limit — the enable/disable switch (item 7) skips this check '
        'entirely', () {
      expect(
        RoomCreationStatus(
          roomsToday: 99,
          dailyLimit: 5,
          restrictionsEnabled: false,
        ).hasHitDailyLimit,
        isFalse,
      );
    });
  });

  group('isTooSoon', () {
    test('true when nextAllowedAt is in the future', () {
      final status = RoomCreationStatus(
        roomsToday: 0,
        dailyLimit: 5,
        restrictionsEnabled: true,
        nextAllowedAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(status.isTooSoon, isTrue);
    });

    test('false when nextAllowedAt has already passed', () {
      final status = RoomCreationStatus(
        roomsToday: 0,
        dailyLimit: 5,
        restrictionsEnabled: true,
        nextAllowedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(status.isTooSoon, isFalse);
    });

    test('false when there is no minimum-hours gate at all (null)', () {
      expect(
        RoomCreationStatus(
          roomsToday: 0,
          dailyLimit: 5,
          restrictionsEnabled: true,
        ).isTooSoon,
        isFalse,
      );
    });

    test('false when restrictions are globally disabled, even with a '
        'future nextAllowedAt', () {
      final status = RoomCreationStatus(
        roomsToday: 0,
        dailyLimit: 5,
        restrictionsEnabled: false,
        nextAllowedAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(status.isTooSoon, isFalse);
    });
  });
}
