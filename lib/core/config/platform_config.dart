/// Admin-configurable platform limits/pricing, read from the `app_settings`
/// table (key/value jsonb — see supabase/migrations/20260823090000_platform_config_limits.sql
/// and the earlier pack-pricing migrations it builds on).
///
/// This is a **presentation-layer** snapshot only. The server-side RPCs
/// (`create_room`, `submit_pack_for_review`, `request_physical_pack`, …)
/// always re-read `app_settings` live at call time — nothing here is ever
/// trusted for enforcement, only for showing the right numbers/prices in
/// the UI before a call is made.
class PlatformConfig {
  const PlatformConfig({
    required this.roomCreationDailyLimitBasic,
    required this.roomCreationDailyLimitPremium,
    required this.offlinePackLimitBasic,
    required this.offlinePackLimitPremium,
    required this.physicalPackPriceMru,
    required this.spicyContentEnabled,
    required this.roomCreationRestrictionsEnabled,
    required this.roomCreationMinHoursBasic,
    required this.roomCreationMinHoursPremium,
    required this.scorePointsPerCompletedGame,
    required this.scorePointsPerPackVote,
    required this.scorePointsPerStreakDay,
    required this.physicalPackRequestsEnabled,
  });

  final int roomCreationDailyLimitBasic;
  final int roomCreationDailyLimitPremium;
  final int offlinePackLimitBasic;
  final int offlinePackLimitPremium;
  final int physicalPackPriceMru;

  /// Section 2 — centralized feature flag. When false, spicy content is
  /// hidden/disabled in the UI AND clamped server-side (see the
  /// game_sessions BEFORE INSERT/UPDATE trigger) regardless of what this
  /// cached value says — this field is presentation-only, same as every
  /// other field on this class.
  final bool spicyContentEnabled;

  /// Section 7 (room creation limits v2). When false, create_room() skips
  /// BOTH the daily-limit and min-hours-between checks entirely — this is
  /// a presentation-layer mirror of the same flag the RPC itself reads.
  final bool roomCreationRestrictionsEnabled;
  final int roomCreationMinHoursBasic;
  final int roomCreationMinHoursPremium;

  /// Section 6 — admin-tunable scoring amounts, read server-side by the
  /// game_sessions-completion and pack_ratings triggers. Exposed here only
  /// so the UI could show "+N points" style copy if ever needed; the
  /// triggers always re-read app_settings live, never this cache.
  final int scorePointsPerCompletedGame;
  final int scorePointsPerPackVote;
  final int scorePointsPerStreakDay;

  /// Section 9 — presentation-layer mirror of the same flag
  /// request_physical_pack re-reads live. Purely for hiding/disabling the
  /// affected UI control — never trusted for enforcement, same as every
  /// other field on this class.
  final bool physicalPackRequestsEnabled;

  int roomCreationDailyLimit({required bool isPremium}) =>
      isPremium ? roomCreationDailyLimitPremium : roomCreationDailyLimitBasic;

  int offlinePackLimit({required bool isPremium}) =>
      isPremium ? offlinePackLimitPremium : offlinePackLimitBasic;

  int roomCreationMinHours({required bool isPremium}) =>
      isPremium ? roomCreationMinHoursPremium : roomCreationMinHoursBasic;

  static const _keys = [
    'room_creation_daily_limit_basic',
    'room_creation_daily_limit_premium',
    'offline_pack_limit_basic',
    'offline_pack_limit_premium',
    'physical_pack_price_mru',
    'feature_spicy_content_enabled',
    'room_creation_restrictions_enabled',
    'room_creation_min_hours_basic',
    'room_creation_min_hours_premium',
    'score_points_per_completed_game',
    'score_points_per_pack_vote',
    'score_points_per_streak_day',
    'physical_pack_requests_enabled',
  ];

  /// The exact `app_settings.key` rows this config reads in one query.
  static List<String> get keys => _keys;

  static int _parseInt(dynamic raw, int fallback) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? fallback;
    return fallback;
  }

  static bool _parseBool(dynamic raw, bool fallback) {
    if (raw is bool) return raw;
    if (raw is String) {
      if (raw == 'true') return true;
      if (raw == 'false') return false;
    }
    return fallback;
  }

  /// Builds from `{key: value}` rows as returned by a
  /// `.select('key, value').inFilter('key', PlatformConfig.keys)` query.
  /// Any key missing from [rows] (e.g. a fresh DB before migrations ran)
  /// falls back to the value the app shipped with historically, purely so
  /// the UI has something reasonable to show — never used for enforcement.
  factory PlatformConfig.fromRows(Map<String, dynamic> rows) {
    int readInt(String key, int fallback) => _parseInt(rows[key], fallback);
    bool readBool(String key, bool fallback) => _parseBool(rows[key], fallback);
    return PlatformConfig(
      roomCreationDailyLimitBasic: readInt(
        'room_creation_daily_limit_basic',
        5,
      ),
      roomCreationDailyLimitPremium: readInt(
        'room_creation_daily_limit_premium',
        15,
      ),
      offlinePackLimitBasic: readInt('offline_pack_limit_basic', 1),
      offlinePackLimitPremium: readInt('offline_pack_limit_premium', 10),
      physicalPackPriceMru: readInt('physical_pack_price_mru', 0),
      // Defaults match today's actual behavior exactly (spicy content
      // always available; no restrictions-disable switch or min-hours gate
      // exist yet) so a missing key never silently changes behavior.
      spicyContentEnabled: readBool('feature_spicy_content_enabled', true),
      roomCreationRestrictionsEnabled: readBool(
        'room_creation_restrictions_enabled',
        true,
      ),
      roomCreationMinHoursBasic: readInt('room_creation_min_hours_basic', 0),
      roomCreationMinHoursPremium: readInt(
        'room_creation_min_hours_premium',
        0,
      ),
      scorePointsPerCompletedGame: readInt(
        'score_points_per_completed_game',
        10,
      ),
      scorePointsPerPackVote: readInt('score_points_per_pack_vote', 5),
      scorePointsPerStreakDay: readInt('score_points_per_streak_day', 5),
      // Defaults match today's actual behavior exactly (all three always
      // available; no such toggle existed before this) so a missing key
      // never silently changes behavior.
      physicalPackRequestsEnabled: readBool(
        'physical_pack_requests_enabled',
        true,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'room_creation_daily_limit_basic': roomCreationDailyLimitBasic,
    'room_creation_daily_limit_premium': roomCreationDailyLimitPremium,
    'offline_pack_limit_basic': offlinePackLimitBasic,
    'offline_pack_limit_premium': offlinePackLimitPremium,
    'physical_pack_price_mru': physicalPackPriceMru,
    'feature_spicy_content_enabled': spicyContentEnabled,
    'room_creation_restrictions_enabled': roomCreationRestrictionsEnabled,
    'room_creation_min_hours_basic': roomCreationMinHoursBasic,
    'room_creation_min_hours_premium': roomCreationMinHoursPremium,
    'score_points_per_completed_game': scorePointsPerCompletedGame,
    'score_points_per_pack_vote': scorePointsPerPackVote,
    'score_points_per_streak_day': scorePointsPerStreakDay,
    'physical_pack_requests_enabled': physicalPackRequestsEnabled,
  };

  factory PlatformConfig.fromJson(Map<String, dynamic> json) =>
      PlatformConfig.fromRows(json);
}
