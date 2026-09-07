// Section 2 of the current audit: user_streaks.current_streak is never
// zeroed by a cleanup job (on_game_session_completed only changes it on the
// next qualifying completion), so the flame is a purely-derived, always
// freshly-computed signal — see lib/core/utils/streak_flame.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/utils/streak_flame.dart';

void main() {
  group('isStreakFlameOn', () {
    final today = DateTime.utc(2026, 6, 15);

    test('no streak ever started -> flame off', () {
      expect(isStreakFlameOn(lastIncrementDate: null, nowUtc: today), isFalse);
    });

    test('completed today -> flame on (active streak)', () {
      expect(
        isStreakFlameOn(lastIncrementDate: today, nowUtc: today),
        isTrue,
      );
    });

    test('completed within the active window (yesterday, exactly 24h ago) -> flame on', () {
      final yesterday = today.subtract(const Duration(days: 1));
      expect(
        isStreakFlameOn(lastIncrementDate: yesterday, nowUtc: today),
        isTrue,
      );
    });

    test('exactly 24h boundary — same-instant UTC day check, not wall-clock hours', () {
      // last_increment_date is a plain UTC calendar date. A completion at
      // 23:59 UTC yesterday, checked at 00:01 UTC today, is ~2 minutes of
      // wall-clock time but a full calendar-day apart — still within the
      // one-day grace window (flame on), matching on_game_session_completed's
      // own `last_increment_date = today - 1` continuation rule.
      final justAfterMidnight = DateTime.utc(2026, 6, 15, 0, 1);
      final yesterday = DateTime.utc(2026, 6, 14);
      expect(
        isStreakFlameOn(lastIncrementDate: yesterday, nowUtc: justAfterMidnight),
        isTrue,
      );
    });

    test('slightly over 24h — two calendar days back -> flame off, stored streak untouched by this check', () {
      final twoDaysAgo = today.subtract(const Duration(days: 2));
      expect(
        isStreakFlameOn(lastIncrementDate: twoDaysAgo, nowUtc: today),
        isFalse,
      );
    });

    test('multiple missed days -> flame off', () {
      final aWeekAgo = today.subtract(const Duration(days: 7));
      expect(
        isStreakFlameOn(lastIncrementDate: aWeekAgo, nowUtc: today),
        isFalse,
      );
    });

    test('restart after a missed day: fresh completion today -> flame on', () {
      // Mirrors on_game_session_completed's restart-to-1 behavior — this
      // function only cares whether the LAST increment is recent, so a
      // freshly-reset streak (current_streak back to 1) reads as active
      // exactly like a long-running one, with no special-casing needed.
      expect(
        isStreakFlameOn(lastIncrementDate: today, nowUtc: today),
        isTrue,
      );
    });

    test('consecutive daily completion after restart stays on each day', () {
      var last = today;
      for (var i = 0; i < 5; i++) {
        final now = today.add(Duration(days: i));
        expect(isStreakFlameOn(lastIncrementDate: last, nowUtc: now), isTrue);
        last = now; // simulates today's completion becoming the new last-increment
      }
    });

    test('a future last_increment_date (clock skew / bad data) is treated as off, not trusted', () {
      final tomorrow = today.add(const Duration(days: 1));
      expect(
        isStreakFlameOn(lastIncrementDate: tomorrow, nowUtc: today),
        isFalse,
      );
    });
  });
}
