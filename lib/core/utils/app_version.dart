import 'package:package_info_plus/package_info_plus.dart';

/// Formats the installed app's version + build number as "X.Y.Z (BUILD)" —
/// the one place this formatting lives, so the About Us screen, Settings
/// screen, and Splash screen can never drift apart or fall back to a stale
/// hardcoded number again. Reads real package/build metadata via
/// PackageInfo.fromPlatform() — the same plugin AppUpdateService already
/// uses for its own version check, works on both Android and iOS; never
/// hardcoded.
Future<String> formattedAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
}
