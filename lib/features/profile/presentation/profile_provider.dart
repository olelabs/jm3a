import 'dart:io';
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/base_provider.dart';
import '../../../core/services/streak_achievement_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../packs/data/pack_repository.dart';
import '../data/profile_repository.dart';

/// Manages profile-specific state: editing, avatar upload, username change.
///
/// Scoped to the authenticated user's own profile.
/// The global user identity lives in AuthProvider — ProfileProvider syncs
/// any changes back to AuthProvider via [_syncToAuth].
class ProfileProvider extends BaseProvider {
  ProfileProvider({
    required ProfileRepository profileRepository,
    required AuthProvider authProvider,
  })  : _repository = profileRepository,
        _authProvider = authProvider;

  final ProfileRepository _repository;
  final AuthProvider _authProvider;

  // ── Edit form state ───────────────────────────────────────────────────────
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  // ── Avatar upload ─────────────────────────────────────────────────────────
  bool _isUploadingAvatar = false;
  bool get isUploadingAvatar => _isUploadingAvatar;

  // ── Username change ───────────────────────────────────────────────────────
  bool _isChangingUsername = false;
  bool get isChangingUsername => _isChangingUsername;

  // For returning results to UI after operations
  Failure? _lastFailure;
  Failure? get lastFailure => _lastFailure;

  // ── Profile-home data (stats + packs) ───────────────────────────────────
  // Single owner of everything the user's own Profile screen shows beyond
  // the base UserEntity fields already on AuthProvider — the counters and
  // pack lists used to be fetched ad-hoc by two separate StatefulWidgets
  // inside ProfileScreen itself, each fetching once and never refreshing.
  ProfileStats _stats = const ProfileStats();
  ProfileStats get stats => _stats;

  List<PackEntity> _mostPlayedPacks = const [];
  List<PackEntity> get mostPlayedPacks => _mostPlayedPacks;

  List<PackEntity> _createdPacks = const [];
  List<PackEntity> get createdPacks => _createdPacks;

  bool _hasLoadedProfileHome = false;
  bool get hasLoadedProfileHome => _hasLoadedProfileHome;

  bool _isLoadingProfileHome = false;
  bool get isLoadingProfileHome => _isLoadingProfileHome;

  // ── Streak congratulations (one-shot) ────────────────────────────────
  // The authoritative event is StreakAchievementService.checkForNewAchievement
  // detecting a genuine increase since the last value acknowledged on this
  // device for this user — never merely "stats were refreshed" (a provider
  // rebuild, app resume, a realtime stats push, or reconnect all call
  // through _applyStats below, but only a real increase ever sets this).
  // A listening widget (HomeShellScreen) shows the dialog once and calls
  // [consumeStreakAchievement], which must happen before the next
  // notifyListeners a caller could observe, or the dialog would re-fire.
  StreakAchievementEvent? _pendingStreakAchievement;
  StreakAchievementEvent? get pendingStreakAchievement => _pendingStreakAchievement;

  void consumeStreakAchievement() {
    _pendingStreakAchievement = null;
  }

  Future<void> _applyStats(ProfileStats newStats) async {
    _stats = newStats;
    final userId = _authProvider.currentUser?.id;
    if (userId == null) return;
    _pendingStreakAchievement = await StreakAchievementService.instance.checkForNewAchievement(
      userId: userId,
      currentStreak: newStats.currentStreak,
    );
  }

  RealtimeChannel? _followsChannel;
  RealtimeChannel? _packsChannel;
  RealtimeChannel? _moderationChannel;

  // Keyed de-dupe: concurrent callers of the *same* refresh scope (e.g. two
  // pull-to-refresh triggers, or a realtime event landing mid pull-to-
  // refresh) share the one in-flight Future instead of firing duplicate
  // API calls. Different scopes (e.g. 'all' vs 'stats') are allowed to
  // overlap — they're cheap, independent reads.
  final Map<String, Future<void>> _inFlightRefreshes = {};

  Future<void> _runOnce(String tag, Future<void> Function() op) {
    final existing = _inFlightRefreshes[tag];
    if (existing != null) return existing;
    final future = op();
    _inFlightRefreshes[tag] = future;
    future.whenComplete(() => _inFlightRefreshes.remove(tag));
    return future;
  }

  @override
  void onUserLoggedIn(String userId) {
    _lastFailure = null;
    _subscribeRealtime(userId);
    // Covers both "first time the Profile tab is built after login" and
    // plain app launch — HomeShellScreen's IndexedStack builds every tab
    // eagerly, so this is the actual first-load trigger, not ProfileScreen
    // ever calling its own separate loader.
    refreshAll();
  }

  @override
  void onUserLoggedOut() {
    _unsubscribeRealtime();
    _stats = const ProfileStats();
    _pendingStreakAchievement = null;
    _mostPlayedPacks = const [];
    _createdPacks = const [];
    _hasLoadedProfileHome = false;
    _isLoadingProfileHome = false;
    _isSaving = false;
    _isUploadingAvatar = false;
    _isChangingUsername = false;
    _lastFailure = null;
    super.onUserLoggedOut();
  }

  @override
  void dispose() {
    _unsubscribeRealtime();
    super.dispose();
  }

  // ── Update profile ────────────────────────────────────────────────────────
  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    String? countryCode,
    int? age,
    String? phoneNumber,
    String? preferredLanguage,
  }) async {
    _isSaving = true;
    _lastFailure = null;
    notifyListeners();

    try {
      final userId = _authProvider.currentUser?.id;
      if (userId == null) throw const AuthFailure();

      final updated = await _repository.updateProfile(
        userId: userId,
        displayName: displayName,
        bio: bio,
        countryCode: countryCode,
        age: age,
        phoneNumber: phoneNumber,
        preferredLanguage: preferredLanguage,
      );

      _syncToAuth(updated);
      return true;
    } on Failure catch (f) {
      _lastFailure = f;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ── Premium background-color customization ─────────────────────────────────
  Future<bool> setThemeBackgroundColor(String? hexColor) async {
    _isSaving = true;
    _lastFailure = null;
    notifyListeners();

    try {
      final updated = await _repository.setThemeBackgroundColor(hexColor);
      _syncToAuth(updated);
      return true;
    } on Failure catch (f) {
      _lastFailure = f;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ── Avatar upload ─────────────────────────────────────────────────────────
  Future<bool> uploadAvatar(File imageFile) async {
    _isUploadingAvatar = true;
    _lastFailure = null;
    notifyListeners();

    try {
      final userId = _authProvider.currentUser?.id;
      if (userId == null) throw const AuthFailure();

      final updated = await _repository.uploadAvatar(
        userId: userId,
        imageFile: imageFile,
      );

      _syncToAuth(updated);
      return true;
    } on Failure catch (f) {
      _lastFailure = f;
      return false;
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  // ── Username change ────────────────────────────────────────────────────────
  Future<({bool success, String? errorMessage, int? daysRemaining})>
      changeUsername(String newUsername) async {
    _isChangingUsername = true;
    _lastFailure = null;
    notifyListeners();

    try {
      final updated = await _repository.changeUsername(newUsername);
      _syncToAuth(updated);
      return (success: true, errorMessage: null, daysRemaining: null);
    } on Failure catch (f) {
      _lastFailure = f;
      final days = f.code == 'username_cooldown'
          ? _parseDaysRemaining(f.message)
          : null;
      return (success: false, errorMessage: f.message, daysRemaining: days);
    } finally {
      _isChangingUsername = false;
      notifyListeners();
    }
  }

  // ── Profile-home refresh ─────────────────────────────────────────────────
  /// Reloads everything the Profile screen shows: base profile fields
  /// (synced into AuthProvider, same as every other mutation below),
  /// stats counters, and both pack lists. The one entry point for every
  /// trigger that should refresh the whole screen — pull-to-refresh,
  /// login, and reopening the Profile tab. Realtime events and
  /// returning-from-a-sub-screen use the narrower helpers below instead,
  /// since they only need to touch the section that could actually have
  /// changed.
  Future<void> refreshAll() => _runOnce('all', _refreshAll);

  Future<void> _refreshAll() async {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) return;
    _isLoadingProfileHome = true;
    notifyListeners();
    try {
      final results = await Future.wait<Object?>([
        _repository.getProfile(userId),
        _repository.getProfileStats(userId),
        PackRepository.instance.getMostPlayedPacksForUser(userId),
        // Own profile shows only published packs — same query already used
        // for viewing another user's public profile (getPublicPacksByCreator
        // filters to status = approved). Drafts / pending-review / rejected
        // packs stay owner-only-visible through the pack-creation workflow
        // (PackProvider.getMyCreatedPacks / my_packs_screen), which is the
        // authoritative place to resume/manage them, not the profile.
        PackRepository.instance.getPublicPacksByCreator(userId),
      ]);
      final profile = results[0] as UserEntity?;
      if (profile != null) _syncToAuth(profile);
      await _applyStats(results[1] as ProfileStats);
      _mostPlayedPacks = results[2] as List<PackEntity>;
      _createdPacks = results[3] as List<PackEntity>;
      _hasLoadedProfileHome = true;
    } catch (e) {
      // A transient failure keeps whatever was last successfully loaded
      // on screen instead of blanking it out — pull-to-refresh callers
      // see the RefreshIndicator simply stop spinning.
      AppLogger.warning('ProfileProvider: refreshAll failed: $e');
    } finally {
      _isLoadingProfileHome = false;
      notifyListeners();
    }
  }

  /// Reloads only the counters row — triggered by a `follows` realtime
  /// event (someone followed/unfollowed this user). Deliberately does not
  /// touch the base profile or pack lists, which that event can't affect.
  Future<void> _refreshStatsOnly() => _runOnce('stats', () async {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) return;
    try {
      await _applyStats(await _repository.getProfileStats(userId));
      notifyListeners();
    } catch (e) {
      AppLogger.warning('ProfileProvider: stats refresh failed: $e');
    }
  });

  /// Reloads the counters row + both pack lists — triggered by a `packs`
  /// realtime event for a pack this user created (published, edited,
  /// approved/rejected, or soft-deleted). packs_count lives in the same
  /// stats query, so both are refreshed together in one pass.
  Future<void> _refreshPacksAndStats() => _runOnce('packs', () async {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) return;
    try {
      final results = await Future.wait<Object?>([
        _repository.getProfileStats(userId),
        PackRepository.instance.getMostPlayedPacksForUser(userId),
        // Published-only — see the same call in _refreshAll above.
        PackRepository.instance.getPublicPacksByCreator(userId),
      ]);
      await _applyStats(results[0] as ProfileStats);
      _mostPlayedPacks = results[1] as List<PackEntity>;
      _createdPacks = results[2] as List<PackEntity>;
      notifyListeners();
    } catch (e) {
      AppLogger.warning('ProfileProvider: packs refresh failed: $e');
    }
  });

  // ── Realtime ──────────────────────────────────────────────────────────────
  /// Mirrors FriendsProvider's `_subscribeFriendshipCDC` pattern: a channel
  /// owned exclusively by this provider, filtered to rows that affect only
  /// this user, so it can't be stolen or collide with any other screen's
  /// subscription (see the RealtimeService singleton-callback pitfall this
  /// avoids entirely by not going through it).
  void _subscribeRealtime(String userId) {
    _unsubscribeRealtime();
    final supabase = Supabase.instance.client;

    _followsChannel = supabase
        .channel('profile-follows:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'follows',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'followee_id',
            value: userId,
          ),
          callback: (_) => _refreshStatsOnly(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'follows',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'followee_id',
            value: userId,
          ),
          callback: (_) => _refreshStatsOnly(),
        )
        .subscribe();

    // Packs are soft-deleted (deleted_at set via UPDATE, never a hard SQL
    // DELETE — see PackRepository.getMyCreatedPacks' deleted_at filter),
    // so INSERT + UPDATE cover publish/edit/approve/reject/delete alike;
    // no DELETE handler needed.
    _packsChannel = supabase
        .channel('profile-packs:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'packs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'creator_id',
            value: userId,
          ),
          callback: (_) => _refreshPacksAndStats(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'packs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'creator_id',
            value: userId,
          ),
          callback: (_) => _refreshPacksAndStats(),
        )
        .subscribe();

    // Immediate ban/suspension enforcement while already inside the app
    // (requirement: "as soon as the suspension/ban is detected... end the
    // current authenticated session"). profiles is a real table (unlike
    // profiles_public), so CDC fires here even though nothing else about
    // this row is otherwise watched by this provider.
    _moderationChannel = supabase
        .channel('profile-moderation:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            // Live honesty_points/general_score for the OWN profile —
            // extends this existing own-profile CDC channel (it already
            // fires on every `profiles` UPDATE for this user id) rather
            // than opening a second subscription. Cheap in-place update
            // from the payload itself, no round trip.
            final newHonesty = (payload.newRecord['honesty_points'] as num?)
                ?.toInt();
            final newScore = (payload.newRecord['general_score'] as num?)
                ?.toInt();
            if (newHonesty != null || newScore != null) {
              _stats = _stats.copyWith(
                honestyPoints: newHonesty,
                generalScore: newScore,
              );
              notifyListeners();
            }

            final isBanned = payload.newRecord['is_banned'] as bool? ?? false;
            if (!isBanned) return;
            final bannedUntilRaw = payload.newRecord['banned_until'] as String?;
            _authProvider.handleAccountSuspended(
              SuspendedFailure(
                isPermanent: bannedUntilRaw == null,
                bannedUntil: bannedUntilRaw != null
                    ? DateTime.tryParse(bannedUntilRaw)
                    : null,
                banReason: payload.newRecord['ban_reason'] as String?,
              ),
            );
          },
        )
        .subscribe();
  }

  void _unsubscribeRealtime() {
    _followsChannel?.unsubscribe();
    _followsChannel = null;
    _packsChannel?.unsubscribe();
    _packsChannel = null;
    _moderationChannel?.unsubscribe();
    _moderationChannel = null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _syncToAuth(UserEntity updated) {
    _authProvider.updateCurrentUser(updated);
    AppLogger.debug('ProfileProvider: synced to AuthProvider');
  }

  int? _parseDaysRemaining(String message) {
    final match = RegExp(r'(\d+) day').firstMatch(message);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  void clearLastFailure() {
    _lastFailure = null;
    notifyListeners();
  }
}
