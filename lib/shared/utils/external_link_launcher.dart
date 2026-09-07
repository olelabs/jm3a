import 'package:url_launcher/url_launcher.dart';

/// Same canLaunchUrl/launchUrl(mode: externalApplication) pattern
/// app.dart's own _openAppStore already uses, extracted here so other
/// features (About Us's social links, etc.) don't each reimplement it.
/// A no-op for an empty/invalid/unlaunchable URL rather than throwing —
/// callers decide whether to show the control at all.
Future<void> launchExternalUrl(String url) async {
  if (url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
