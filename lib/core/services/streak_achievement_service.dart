import '../storage/local_storage_service.dart';

/// Correction pass — "New streak started" / "Streak extended" in-app
/// congratulations. Reuses [LocalStorageService] (the same thin
/// SharedPreferences wrapper AppTutorialService already uses for one-time
/// per-device flags) rather than a new persistence layer.
enum StreakAchievementType { newStreak, extended }

class StreakAchievementEvent {
  const StreakAchievementEvent({required this.type, required this.streakCount});
  final StreakAchievementType type;
  final int streakCount;
}

/// The authoritative event this fires on is "the user's current_streak
/// (user_streaks, read via ProfileRepository.getProfileStats) increased
/// since the last value we ever acknowledged on THIS device for THIS
/// user" — never "the app refreshed stats" or "the screen rebuilt".
/// [checkForNewAchievement] is the single gate: it persists the new
/// baseline synchronously before returning, so a second call with the
/// same value (a provider rebuild, app resume, a realtime stats refresh
/// that didn't actually change the number, a reconnect) always returns
/// null — this is what makes the dialog fire exactly once per genuine
/// increase, regardless of how many times the caller re-checks.
class StreakAchievementService {
  StreakAchievementService._();
  static final StreakAchievementService instance = StreakAchievementService._();

  String _key(String userId) => 'streak_ack_$userId';

  /// Returns the achievement to show, or null if nothing new happened.
  ///
  /// - First time EVER seeing streak data for this user on this device
  ///   (no stored baseline): silently records [currentStreak] as the
  ///   baseline and returns null. This deliberately avoids a false
  ///   "New Streak!" celebration for a long-standing streak the user
  ///   already had when they first open the app on a new device, or on
  ///   a fresh install.
  /// - A decrease (streak broken/reset, or a stats correction): silently
  ///   re-baselines to the lower value, no dialog — so the NEXT genuine
  ///   day-1 increment correctly reports [StreakAchievementType.newStreak]
  ///   again rather than being suppressed by a stale higher baseline.
  /// - An unchanged value: null.
  /// - currentStreak == 1 coming from a baseline of 0: [newStreak].
  /// - Any other increase: [extended].
  Future<StreakAchievementEvent?> checkForNewAchievement({
    required String userId,
    required int currentStreak,
  }) async {
    final storage = LocalStorageService.instance;
    final key = _key(userId);
    final hadBaseline = storage.containsKey(key);
    final last = storage.getInt(key) ?? 0;

    await storage.setInt(key, currentStreak);

    if (!hadBaseline) return null;
    if (currentStreak <= last) return null;

    return StreakAchievementEvent(
      type: last == 0 ? StreakAchievementType.newStreak : StreakAchievementType.extended,
      streakCount: currentStreak,
    );
  }
}
