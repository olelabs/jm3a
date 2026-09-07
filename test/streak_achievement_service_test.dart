import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/services/streak_achievement_service.dart';
import 'package:jma3a/core/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Correction pass — "New streak started" / "Streak extended" dialogs.
/// This is the authoritative event source (see the service's own doc
/// comment): a listening widget shows a dialog once per event this
/// returns non-null, so THIS is where "never shown twice for the same
/// state" actually has to be proven.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // AppLogger (used by LocalStorageService.initialize) reads
  // AppConfig.isDevelopment -> dotenv, never loaded in a bare unit test.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  setUp(() async {
    // Fresh in-memory SharedPreferences per test — LocalStorageService is
    // a real singleton, so without this, state would bleed between tests
    // in this same file (though never across files — each runs in its
    // own isolate).
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.instance.initialize();
  });

  test('the very first time streak data is ever seen for a user, no dialog fires (avoids a false "new streak" for a long-standing one on a fresh device)', () async {
    final event = await StreakAchievementService.instance.checkForNewAchievement(userId: 'u1', currentStreak: 15);
    expect(event, isNull);
  });

  test('after the baseline is set, going from 0 to 1 fires newStreak', () async {
    await StreakAchievementService.instance.checkForNewAchievement(userId: 'u2', currentStreak: 0);
    final event = await StreakAchievementService.instance.checkForNewAchievement(userId: 'u2', currentStreak: 1);
    expect(event?.type, StreakAchievementType.newStreak);
    expect(event?.streakCount, 1);
  });

  test('going from N to N+1 (N>0) fires extended, not newStreak', () async {
    await StreakAchievementService.instance.checkForNewAchievement(userId: 'u3', currentStreak: 3);
    final event = await StreakAchievementService.instance.checkForNewAchievement(userId: 'u3', currentStreak: 4);
    expect(event?.type, StreakAchievementType.extended);
    expect(event?.streakCount, 4);
  });

  // The actual "duplicate state update" regression guard.
  test('calling again with the SAME value never fires a second dialog — provider rebuilds/resume/reconnect never re-trigger it', () async {
    await StreakAchievementService.instance.checkForNewAchievement(userId: 'u4', currentStreak: 0);
    final first = await StreakAchievementService.instance.checkForNewAchievement(userId: 'u4', currentStreak: 1);
    expect(first, isNotNull);

    final second = await StreakAchievementService.instance.checkForNewAchievement(userId: 'u4', currentStreak: 1);
    final third = await StreakAchievementService.instance.checkForNewAchievement(userId: 'u4', currentStreak: 1);
    expect(second, isNull);
    expect(third, isNull);
  });

  test('a decrease (streak broken/reset) never fires a dialog, and silently re-baselines', () async {
    await StreakAchievementService.instance.checkForNewAchievement(userId: 'u5', currentStreak: 5);
    final event = await StreakAchievementService.instance.checkForNewAchievement(userId: 'u5', currentStreak: 0);
    expect(event, isNull);
  });

  test('after a reset to 0, the next day-1 increment correctly fires newStreak again (not suppressed by the old higher baseline)', () async {
    await StreakAchievementService.instance.checkForNewAchievement(userId: 'u6', currentStreak: 5);
    await StreakAchievementService.instance.checkForNewAchievement(userId: 'u6', currentStreak: 0); // broke
    final event = await StreakAchievementService.instance.checkForNewAchievement(userId: 'u6', currentStreak: 1); // restarted
    expect(event?.type, StreakAchievementType.newStreak);
  });

  test('two different users are tracked independently — one\'s streak never affects the other\'s baseline', () async {
    await StreakAchievementService.instance.checkForNewAchievement(userId: 'alice', currentStreak: 0);
    await StreakAchievementService.instance.checkForNewAchievement(userId: 'alice', currentStreak: 1);

    // bob has never been seen before — his first check must still be a
    // silent baseline, not treated as already "at 1".
    final bobFirst = await StreakAchievementService.instance.checkForNewAchievement(userId: 'bob', currentStreak: 1);
    expect(bobFirst, isNull);
    final bobSecond = await StreakAchievementService.instance.checkForNewAchievement(userId: 'bob', currentStreak: 2);
    expect(bobSecond?.type, StreakAchievementType.extended);
  });
}
