import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/social_links.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_version.dart';
import '../../../../shared/utils/external_link_launcher.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/mouj_tech_brand.dart';

/// Placeholder company/contact info — see l10n keys aboutUsCompanyInfo /
/// aboutUsContactEmail / aboutUsWebsite for the actual displayed text,
/// which is what to replace once real details are finalized. The social
/// tiles below are real, tappable ListTiles wired to [SocialLinks] — see
/// that file's own doc comment for why they render disabled today (no
/// real Jma3a TikTok/Snapchat/Facebook URL exists anywhere in this
/// project yet); each one activates automatically the moment its URL is
/// filled in there, with no further UI changes needed.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  void _copyToClipboard(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    context.showSnackBar(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutUsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.navyBlue,
                  AppColors.navyBlue.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/backgrounds/jma3a_logo_white.png',
                  height: 72,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.groups_rounded,
                    size: 72,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<String>(
                  future: formattedAppVersion(),
                  builder: (context, snapshot) {
                    final version = snapshot.data;
                    if (version == null) return const SizedBox.shrink();
                    return Text(
                      '${l10n.aboutUsVersionLabel} $version',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          JCard(
            child: Text(
              l10n.aboutUsDescription,
              style: theme.textTheme.bodyMedium,
            ),
          ),

          const SizedBox(height: 16),
          _SectionHeader(l10n.aboutUsCompanySectionTitle),
          JCard(
            child: Text(
              l10n.aboutUsCompanyInfo,
              style: theme.textTheme.bodyMedium,
            ),
          ),

          const SizedBox(height: 16),
          _SectionHeader(l10n.aboutUsContactTitle),
          JCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(l10n.aboutUsContactTitle),
                  subtitle: Text(l10n.aboutUsContactEmail),
                  trailing: const Icon(Icons.copy_rounded, size: 18),
                  onTap: () =>
                      _copyToClipboard(context, l10n.aboutUsContactEmail),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(l10n.aboutUsWebsiteTitle),
                  subtitle: Text(l10n.aboutUsWebsite),
                  trailing: const Icon(Icons.copy_rounded, size: 18),
                  onTap: () => _copyToClipboard(context, l10n.aboutUsWebsite),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _SectionHeader(l10n.aboutUsFollowUsTitle),
          JCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SocialTile(
                  icon: Icons.music_note_rounded,
                  label: l10n.aboutUsSocialTiktok,
                  url: SocialLinks.tiktok,
                ),
                const Divider(height: 1),
                _SocialTile(
                  icon: Icons.camera_alt_rounded,
                  label: l10n.aboutUsSocialSnapchat,
                  url: SocialLinks.snapchat,
                ),
                const Divider(height: 1),
                _SocialTile(
                  icon: Icons.facebook_rounded,
                  label: l10n.aboutUsSocialFacebook,
                  url: SocialLinks.facebook,
                ),
              ],
            ),
          ),

          const MoujTechBrand(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(
      title,
      style: context.textTheme.labelLarge?.copyWith(
        color: context.colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// A single official-account row. Disabled (dimmed, no tap) whenever
/// [url] is empty — see SocialLinks' own doc comment for why that's the
/// case for all three today; this widget itself is fully wired to
/// launch the moment a real URL is filled in there.
class _SocialTile extends StatelessWidget {
  const _SocialTile({
    required this.icon,
    required this.label,
    required this.url,
  });
  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final enabled = url.isNotEmpty;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: ListTile(
        leading: Icon(icon, color: context.colorScheme.primary),
        title: Text(label),
        trailing: enabled
            ? const Icon(Icons.open_in_new_rounded, size: 18)
            : null,
        onTap: enabled ? () => launchExternalUrl(url) : null,
      ),
    );
  }
}
