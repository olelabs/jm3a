import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../storage/local_storage_service.dart';
import '../utils/app_logger.dart';
import 'platform_config_repository.dart';

/// Centralized, cached access to [PlatformConfig] for the whole app —
/// loaded once on startup instead of every screen querying `app_settings`
/// independently.
///
/// The last successfully-fetched config is cached to [LocalStorageService]
/// so a cold start / transient network failure has an immediate, non-null
/// value instead of blocking the UI on a network round trip. That cache is
/// **UX-only**: it is never treated as authoritative for anything
/// security-relevant — server-side RPCs always re-read `app_settings` live.
class PlatformConfigProvider extends ChangeNotifier {
  PlatformConfigProvider({PlatformConfigRepository? repository})
    : _repository = repository ?? PlatformConfigRepository.instance;

  final PlatformConfigRepository _repository;

  static const _cacheKey = 'platform_config_cache_v1';

  PlatformConfig _config = PlatformConfig.fromRows(const {});
  PlatformConfig get config => _config;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasLoadedOnce = false;
  bool get hasLoadedOnce => _hasLoadedOnce;

  /// Hydrates from the on-device cache (if any) for an instant first paint,
  /// then always fetches the live values from `app_settings`.
  Future<void> load() async {
    _hydrateFromCache();
    await refresh();
  }

  void _hydrateFromCache() {
    try {
      final raw = LocalStorageService.instance.getString(_cacheKey);
      if (raw == null) return;
      _config = PlatformConfig.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      notifyListeners();
    } catch (e) {
      AppLogger.warning('PlatformConfigProvider: cache hydrate failed: $e');
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      _config = await _repository.getConfig();
      _hasLoadedOnce = true;
      unawaited(
        LocalStorageService.instance.setString(
          _cacheKey,
          jsonEncode(_config.toJson()),
        ),
      );
    } catch (e) {
      // Transient failure (offline, etc.) — keep whatever's already showing
      // (a prior successful fetch, or the cached last-known value from
      // _hydrateFromCache) rather than blanking the UI.
      AppLogger.warning('PlatformConfigProvider: refresh failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int roomCreationDailyLimit({required bool isPremium}) =>
      _config.roomCreationDailyLimit(isPremium: isPremium);

  int offlinePackLimit({required bool isPremium}) =>
      _config.offlinePackLimit(isPremium: isPremium);

  int get packSubmissionFreeMonthlyLimit =>
      _config.packSubmissionFreeMonthlyLimit;
  int get packSubmissionMinGapDays => _config.packSubmissionMinGapDays;
  int get packExtraCreationFeeMru => _config.packExtraCreationFeeMru;
  int get physicalPackPriceMru => _config.physicalPackPriceMru;
  int get packPromotionPrice24hMru => _config.packPromotionPrice24hMru;
  int get packPromotionPrice7dMru => _config.packPromotionPrice7dMru;

  bool get spicyContentEnabled => _config.spicyContentEnabled;

  bool get roomCreationRestrictionsEnabled =>
      _config.roomCreationRestrictionsEnabled;
  int roomCreationMinHours({required bool isPremium}) =>
      _config.roomCreationMinHours(isPremium: isPremium);

  int get scorePointsPerCompletedGame => _config.scorePointsPerCompletedGame;
  int get scorePointsPerPackVote => _config.scorePointsPerPackVote;
  int get scorePointsPerStreakDay => _config.scorePointsPerStreakDay;

  bool get physicalPackRequestsEnabled => _config.physicalPackRequestsEnabled;
  bool get packPromotionsEnabled => _config.packPromotionsEnabled;
  bool get depositsEnabled => _config.depositsEnabled;
  bool get withdrawalsEnabled => _config.withdrawalsEnabled;
}
