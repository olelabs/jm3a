import 'package:flutter/material.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../shared/widgets/cards/j_card.dart';

/// Placeholder Privacy Policy — every section body is placeholder text
/// (see the privacySection*Body l10n keys) pending the real legal copy.
/// Structured as one [_PolicySection] per required topic specifically so
/// swapping placeholder text for final copy later is a pure l10n-file
/// edit, with no layout/widget changes needed.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.privacyPolicyIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _PolicySection(
            title: l10n.privacySectionInfoCollected,
            body: l10n.privacySectionInfoCollectedBody,
          ),
          _PolicySection(
            title: l10n.privacySectionHowUsed,
            body: l10n.privacySectionHowUsedBody,
          ),
          _PolicySection(
            title: l10n.privacySectionNotifications,
            body: l10n.privacySectionNotificationsBody,
          ),
          _PolicySection(
            title: l10n.privacySectionPurchases,
            body: l10n.privacySectionPurchasesBody,
          ),
          _PolicySection(
            title: l10n.privacySectionUserContent,
            body: l10n.privacySectionUserContentBody,
          ),
          _PolicySection(
            title: l10n.privacySectionAccountDeletion,
            body: l10n.privacySectionAccountDeletionBody,
          ),
          _PolicySection(
            title: l10n.privacySectionContact,
            body: l10n.privacySectionContactBody,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.body,
    this.isLast = false,
  });

  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: JCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
