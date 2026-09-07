import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';

class AppUpdateInfo {
  const AppUpdateInfo({required this.forceUpdate, this.title, this.message, this.storeUrl});

  final bool forceUpdate;
  final String? title;
  final String? message;
  final String? storeUrl;
}

/// Database-driven update check — reads app_update_config (a single admin-
/// edited row, see the migration) once per app launch and compares it
/// against the installed version. Not a polling service: one read at
/// startup is enough, since an update becoming available mid-session
/// isn't something the user needs to react to before their next launch.
class AppUpdateService extends ChangeNotifier {
  AppUpdateInfo? _updateInfo;
  AppUpdateInfo? get updateInfo => _updateInfo;
  bool get isForceUpdateRequired => _updateInfo?.forceUpdate ?? false;

  // Session-only — deliberately not persisted. "The reminder should
  // continue appearing until updated" means every fresh launch while
  // still out of date, not silenced forever after one dismissal.
  bool _bannerDismissed = false;
  bool get showOptionalBanner =>
      _updateInfo != null && !_updateInfo!.forceUpdate && !_bannerDismissed;

  void dismissOptionalBanner() {
    if (_bannerDismissed) return;
    _bannerDismissed = true;
    notifyListeners();
  }

  Future<void> checkForUpdate() async {
    try {
      final row = await Supabase.instance.client
          .from('app_update_config')
          .select()
          .eq('id', 1)
          .maybeSingle();
      if (row == null) {
        AppLogger.debug('AppUpdateService: no app_update_config row found');
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : 'other';
      final latestVersion = Platform.isAndroid
          ? row['latest_version_android'] as String?
          : Platform.isIOS
          ? row['latest_version_ios'] as String?
          : null;
      final storeUrl = Platform.isAndroid
          ? row['store_url_android'] as String?
          : Platform.isIOS
          ? row['store_url_ios'] as String?
          : null;
      final minimumSupported = row['minimum_supported_version'] as String?;
      final forceUpdateFlag = row['force_update'] as bool? ?? false;
      final title = (row['update_title'] as String?)?.trim();
      final message = (row['update_message'] as String?)?.trim();

      final resolved = resolveAppUpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        minimumSupported: minimumSupported,
        forceUpdateFlag: forceUpdateFlag,
        storeUrl: storeUrl,
        title: title,
        message: message,
      );

      AppLogger.debug(
        'AppUpdateService: Current version: $currentVersion\n'
        'AppUpdateService: Latest version: $latestVersion\n'
        'AppUpdateService: Minimum supported: $minimumSupported\n'
        'AppUpdateService: Force update: $forceUpdateFlag\n'
        'AppUpdateService: Platform: $platform\n'
        'AppUpdateService: Resolved: ${resolved == null ? 'no update' : resolved.forceUpdate ? 'force' : 'optional'}',
      );

      _updateInfo = resolved;
      notifyListeners();
    } catch (e) {
      AppLogger.warning('AppUpdateService: check failed, $e');
    }
  }
}

/// Plain numeric dot-version comparison ("1.2.10" > "1.2.9") — no new
/// dependency for this; pub_semver would also choke on the odd
/// admin-entered "1.2" (missing patch) that this tolerates by treating
/// missing segments as 0. Top-level (not a private method on
/// AppUpdateService) purely so it's independently testable without
/// mocking Supabase/PackageInfo — behavior is unchanged.
int compareAppVersions(String a, String b) {
  final pa = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final pb = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final length = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < length; i++) {
    final va = i < pa.length ? pa[i] : 0;
    final vb = i < pb.length ? pb[i] : 0;
    if (va != vb) return va.compareTo(vb);
  }
  return 0;
}

/// The force/optional/none decision — pulled out of
/// AppUpdateService.checkForUpdate() into a pure function (same
/// behavior, unchanged) so "no false update when already current" and
/// "below-minimum always forces regardless of the force_update toggle"
/// are independently testable without mocking Supabase/PackageInfo.
AppUpdateInfo? resolveAppUpdateInfo({
  required String currentVersion,
  required String? latestVersion,
  required String? minimumSupported,
  required bool forceUpdateFlag,
  String? storeUrl,
  String? title,
  String? message,
}) {
  final belowMinimum =
      minimumSupported != null &&
      compareAppVersions(currentVersion, minimumSupported) < 0;
  final newerAvailable =
      latestVersion != null &&
      compareAppVersions(currentVersion, latestVersion) < 0;
  // A too-old (below minimum_supported_version) install is always forced
  // regardless of the admin's force_update toggle — that flag is for "we
  // want everyone on the newest build", the minimum-version check is
  // "this build no longer works at all".
  final shouldForceUpdate = forceUpdateFlag || belowMinimum;
  final shouldOptionalUpdate = !shouldForceUpdate && newerAvailable;

  if (!shouldForceUpdate && !shouldOptionalUpdate) return null;

  final trimmedTitle = title?.trim();
  final trimmedMessage = message?.trim();
  return AppUpdateInfo(
    forceUpdate: shouldForceUpdate,
    title: trimmedTitle?.isNotEmpty == true ? trimmedTitle : null,
    message: trimmedMessage?.isNotEmpty == true ? trimmedMessage : null,
    storeUrl: storeUrl,
  );
}
