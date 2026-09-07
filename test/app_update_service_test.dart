import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/services/app_update_service.dart';

void main() {
  group('compareAppVersions', () {
    test('equal versions compare as 0', () {
      expect(compareAppVersions('1.0.0', '1.0.0'), 0);
    });

    test('a higher patch version is greater — no lexicographic-string bug (1.2.10 > 1.2.9)', () {
      expect(compareAppVersions('1.2.10', '1.2.9') > 0, isTrue);
      expect(compareAppVersions('1.2.9', '1.2.10') < 0, isTrue);
    });

    test('a higher minor/major version wins regardless of patch', () {
      expect(compareAppVersions('2.0.0', '1.9.9') > 0, isTrue);
      expect(compareAppVersions('1.10.0', '1.9.99') > 0, isTrue);
    });

    test('missing segments are treated as 0 ("1.2" == "1.2.0")', () {
      expect(compareAppVersions('1.2', '1.2.0'), 0);
      expect(compareAppVersions('1.2', '1.2.1') < 0, isTrue);
    });
  });

  group('resolveAppUpdateInfo', () {
    test('current version == latest: no update surfaced (no false positive)', () {
      final info = resolveAppUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        minimumSupported: '1.0.0',
        forceUpdateFlag: false,
      );
      expect(info, isNull);
    });

    test('current version < latest, force_update off: optional update surfaced', () {
      final info = resolveAppUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        minimumSupported: '1.0.0',
        forceUpdateFlag: false,
      );
      expect(info, isNotNull);
      expect(info!.forceUpdate, isFalse);
    });

    test('current version < latest, force_update on: forced update surfaced', () {
      final info = resolveAppUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        minimumSupported: '1.0.0',
        forceUpdateFlag: true,
      );
      expect(info, isNotNull);
      expect(info!.forceUpdate, isTrue);
    });

    test('below minimum_supported_version always forces, even if force_update is off', () {
      final info = resolveAppUpdateInfo(
        currentVersion: '0.9.0',
        latestVersion: '1.1.0',
        minimumSupported: '1.0.0',
        forceUpdateFlag: false,
      );
      expect(info, isNotNull);
      expect(info!.forceUpdate, isTrue);
    });

    test('a newer install than latest_version (e.g. a beta) never surfaces an update', () {
      final info = resolveAppUpdateInfo(
        currentVersion: '2.0.0',
        latestVersion: '1.1.0',
        minimumSupported: '1.0.0',
        forceUpdateFlag: false,
      );
      expect(info, isNull);
    });

    test('null latest/minimum (unconfigured columns) never crashes and never falsely updates', () {
      final info = resolveAppUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: null,
        minimumSupported: null,
        forceUpdateFlag: false,
      );
      expect(info, isNull);
    });

    test('blank title/message are treated as absent, not empty strings', () {
      final info = resolveAppUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        minimumSupported: '1.0.0',
        forceUpdateFlag: false,
        title: '   ',
        message: '',
      );
      expect(info!.title, isNull);
      expect(info.message, isNull);
    });

    test('storeUrl is passed through unchanged', () {
      final info = resolveAppUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        minimumSupported: '1.0.0',
        forceUpdateFlag: false,
        storeUrl: 'https://play.google.com/store/apps/details?id=com.jma3a.app',
      );
      expect(info!.storeUrl, 'https://play.google.com/store/apps/details?id=com.jma3a.app');
    });
  });
}
