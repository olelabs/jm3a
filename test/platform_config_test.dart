// Tests for the new database-backed platform configuration model (task
// items 3-9): PlatformConfig.fromRows/toJson/fromJson parsing, the
// fallback values used only when a key is missing or malformed (never
// used for enforcement — every server-side RPC re-reads app_settings
// live), and the basic/premium tier selection helpers.
//
// PlatformConfigRepository/PlatformConfigProvider themselves talk to a
// live Supabase `app_settings` table and this offline suite has no such
// connection (same class of gap already documented for other
// Supabase-backed paths in this codebase, e.g. room_reconnect_approval_
// test.dart) — see final report for what still needs real-device/staging
// verification.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/config/platform_config.dart';

void main() {
  group('PlatformConfig.fromRows — parsing', () {
    test('reads int values straight through', () {
      final config = PlatformConfig.fromRows({
        'room_creation_daily_limit_basic': 5,
        'room_creation_daily_limit_premium': 15,
        'offline_pack_limit_basic': 1,
        'offline_pack_limit_premium': 10,
        'pack_submission_free_monthly_limit': 2,
        'pack_submission_min_gap_days': 15,
        'pack_extra_creation_price_mru': 300,
        'physical_pack_price_mru': 1500,
        'pack_promotion_price_24h_mru': 100,
        'pack_promotion_price_7d_mru': 500,
      });
      expect(config.roomCreationDailyLimitBasic, 5);
      expect(config.roomCreationDailyLimitPremium, 15);
      expect(config.offlinePackLimitBasic, 1);
      expect(config.offlinePackLimitPremium, 10);
      expect(config.packSubmissionFreeMonthlyLimit, 2);
      expect(config.packSubmissionMinGapDays, 15);
      expect(config.packExtraCreationFeeMru, 300);
      expect(config.physicalPackPriceMru, 1500);
      expect(config.packPromotionPrice24hMru, 100);
      expect(config.packPromotionPrice7dMru, 500);
    });

    test('a jsonb-numeric-as-string value (e.g. from a hand-edited row) '
        'still parses', () {
      final config = PlatformConfig.fromRows({
        'room_creation_daily_limit_basic': '7',
      });
      expect(config.roomCreationDailyLimitBasic, 7);
    });

    test('a missing key falls back to the historical shipped default '
        '(presentation-only — never used for server-side enforcement)', () {
      final config = PlatformConfig.fromRows(const {});
      expect(config.roomCreationDailyLimitBasic, 5);
      expect(config.roomCreationDailyLimitPremium, 15);
      expect(config.offlinePackLimitBasic, 1);
      expect(config.offlinePackLimitPremium, 10);
      expect(config.packSubmissionFreeMonthlyLimit, 2);
      expect(config.packSubmissionMinGapDays, 15);
      expect(config.packExtraCreationFeeMru, 300);
    });

    test('an unparseable value falls back rather than throwing', () {
      final config = PlatformConfig.fromRows({
        'room_creation_daily_limit_basic': 'not a number',
      });
      expect(config.roomCreationDailyLimitBasic, 5);
    });
  });

  group('tier-selection helpers', () {
    final config = PlatformConfig.fromRows({
      'room_creation_daily_limit_basic': 5,
      'room_creation_daily_limit_premium': 15,
      'offline_pack_limit_basic': 1,
      'offline_pack_limit_premium': 10,
    });

    test('roomCreationDailyLimit picks basic vs premium', () {
      expect(config.roomCreationDailyLimit(isPremium: false), 5);
      expect(config.roomCreationDailyLimit(isPremium: true), 15);
    });

    test('offlinePackLimit picks basic vs premium', () {
      expect(config.offlinePackLimit(isPremium: false), 1);
      expect(config.offlinePackLimit(isPremium: true), 10);
    });
  });

  group('toJson/fromJson round trip (the on-device cache format)', () {
    test('round-trips every field exactly', () {
      final original = PlatformConfig.fromRows({
        'room_creation_daily_limit_basic': 5,
        'room_creation_daily_limit_premium': 15,
        'offline_pack_limit_basic': 1,
        'offline_pack_limit_premium': 10,
        'pack_submission_free_monthly_limit': 2,
        'pack_submission_min_gap_days': 15,
        'pack_extra_creation_price_mru': 300,
        'physical_pack_price_mru': 1500,
        'pack_promotion_price_24h_mru': 100,
        'pack_promotion_price_7d_mru': 500,
      });
      final restored = PlatformConfig.fromJson(original.toJson());
      expect(restored.toJson(), equals(original.toJson()));
    });
  });

  // This session's additions: feature flags (item 2), room-limit v2
  // (item 7), scoring config (item 6) — same fromRows/fallback/toJson
  // machinery as the pre-existing fields above, just new keys.
  group('feature flags + room-limit v2 + scoring config (this session)', () {
    test('spicyContentEnabled parses true/false and defaults true when '
        'missing (matches today\'s always-on behavior)', () {
      expect(
        PlatformConfig.fromRows({
          'feature_spicy_content_enabled': true,
        }).spicyContentEnabled,
        isTrue,
      );
      expect(
        PlatformConfig.fromRows({
          'feature_spicy_content_enabled': false,
        }).spicyContentEnabled,
        isFalse,
      );
      expect(PlatformConfig.fromRows(const {}).spicyContentEnabled, isTrue);
    });

    test('roomCreationRestrictionsEnabled defaults true (preserves the '
        'daily-limit enforcement added last session) when missing', () {
      expect(
        PlatformConfig.fromRows(const {}).roomCreationRestrictionsEnabled,
        isTrue,
      );
    });

    test('roomCreationMinHours picks basic vs premium and defaults to 0 '
        '(no gate) when missing — matches today\'s actual behavior, no '
        'invented restriction', () {
      final config = PlatformConfig.fromRows(const {});
      expect(config.roomCreationMinHoursBasic, 0);
      expect(config.roomCreationMinHoursPremium, 0);
      expect(config.roomCreationMinHours(isPremium: false), 0);

      final configured = PlatformConfig.fromRows({
        'room_creation_min_hours_basic': 4,
        'room_creation_min_hours_premium': 1,
      });
      expect(configured.roomCreationMinHours(isPremium: false), 4);
      expect(configured.roomCreationMinHours(isPremium: true), 1);
    });

    test('scoring config keys parse with their seeded defaults', () {
      final config = PlatformConfig.fromRows(const {});
      expect(config.scorePointsPerCompletedGame, 10);
      expect(config.scorePointsPerPackVote, 5);
      expect(config.scorePointsPerStreakDay, 5);

      final configured = PlatformConfig.fromRows({
        'score_points_per_completed_game': 20,
        'score_points_per_pack_vote': 8,
        'score_points_per_streak_day': 3,
      });
      expect(configured.scorePointsPerCompletedGame, 20);
      expect(configured.scorePointsPerPackVote, 8);
      expect(configured.scorePointsPerStreakDay, 3);
    });

    test('a jsonb boolean-as-string value still parses', () {
      expect(
        PlatformConfig.fromRows({
          'feature_spicy_content_enabled': 'false',
        }).spicyContentEnabled,
        isFalse,
      );
    });

    test('every new key round-trips through toJson/fromJson', () {
      final original = PlatformConfig.fromRows({
        'feature_spicy_content_enabled': false,
        'room_creation_restrictions_enabled': false,
        'room_creation_min_hours_basic': 6,
        'room_creation_min_hours_premium': 2,
        'score_points_per_completed_game': 25,
        'score_points_per_pack_vote': 9,
        'score_points_per_streak_day': 7,
      });
      final restored = PlatformConfig.fromJson(original.toJson());
      expect(restored.toJson(), equals(original.toJson()));
    });
  });

  // Sections 9-11 of the current audit: physical-pack requests, pack
  // promotions, and deposits/withdrawals — each an independent
  // admin-configurable enable/disable toggle, same fromRows/fallback/toJson
  // machinery as every other flag above.
  group('feature toggles: physical packs / promotions / deposits / '
      'withdrawals (this session)', () {
    test('all four default true (preserve today\'s always-on behavior) '
        'when missing', () {
      final config = PlatformConfig.fromRows(const {});
      expect(config.physicalPackRequestsEnabled, isTrue);
      expect(config.packPromotionsEnabled, isTrue);
      expect(config.depositsEnabled, isTrue);
      expect(config.withdrawalsEnabled, isTrue);
    });

    test('each parses true/false independently of the others', () {
      final config = PlatformConfig.fromRows({
        'physical_pack_requests_enabled': false,
        'pack_promotions_enabled': true,
        'deposits_enabled': false,
        'withdrawals_enabled': true,
      });
      expect(config.physicalPackRequestsEnabled, isFalse);
      expect(config.packPromotionsEnabled, isTrue);
      expect(config.depositsEnabled, isFalse);
      expect(config.withdrawalsEnabled, isTrue);
    });

    test('a jsonb boolean-as-string value still parses for each', () {
      final config = PlatformConfig.fromRows({
        'physical_pack_requests_enabled': 'false',
        'pack_promotions_enabled': 'false',
        'deposits_enabled': 'false',
        'withdrawals_enabled': 'false',
      });
      expect(config.physicalPackRequestsEnabled, isFalse);
      expect(config.packPromotionsEnabled, isFalse);
      expect(config.depositsEnabled, isFalse);
      expect(config.withdrawalsEnabled, isFalse);
    });

    test('round-trips through toJson/fromJson', () {
      final original = PlatformConfig.fromRows({
        'physical_pack_requests_enabled': false,
        'pack_promotions_enabled': false,
        'deposits_enabled': true,
        'withdrawals_enabled': false,
      });
      final restored = PlatformConfig.fromJson(original.toJson());
      expect(restored.toJson(), equals(original.toJson()));
    });
  });
}
