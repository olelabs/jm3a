import 'package:flutter/material.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/mouj_tech_brand.dart';

/// Terms & Conditions — mirrors PrivacyPolicyScreen's own
/// _PolicySection/l10n-driven structure so future copy edits stay a pure
/// l10n-file change with no widget/layout changes needed. Every section
/// below describes only functionality that actually exists in this app
/// (rooms, packs, Premium/Premium Plus, creator verification, the
/// wallet, reporting/blocking) — see terms_conditions_screen's own
/// l10n keys (termsSection*) for the exact copy.
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.termsConditionsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.termsConditionsIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _TermsSection(
            title: l10n.termsSectionAccount,
            body: l10n.termsSectionAccountBody,
          ),
          _TermsSection(
            title: l10n.termsSectionAcceptableUse,
            body: l10n.termsSectionAcceptableUseBody,
          ),
          _TermsSection(
            title: l10n.termsSectionContent,
            body: l10n.termsSectionContentBody,
          ),
          _TermsSection(
            title: l10n.termsSectionCreators,
            body: l10n.termsSectionCreatorsBody,
          ),
          _TermsSection(
            title: l10n.termsSectionRoomsGames,
            body: l10n.termsSectionRoomsGamesBody,
          ),
          _TermsSection(
            title: l10n.termsSectionPremium,
            body: l10n.termsSectionPremiumBody,
          ),
          _TermsSection(
            title: l10n.termsSectionWallet,
            body: l10n.termsSectionWalletBody,
          ),
          _TermsSection(
            title: l10n.termsSectionModeration,
            body: l10n.termsSectionModerationBody,
          ),
          _TermsSection(
            title: l10n.termsSectionTermination,
            body: l10n.termsSectionTerminationBody,
          ),
          _TermsSection(
            title: l10n.termsSectionAvailability,
            body: l10n.termsSectionAvailabilityBody,
          ),
          _TermsSection(
            title: l10n.termsSectionChanges,
            body: l10n.termsSectionChangesBody,
          ),
          _TermsSection(
            title: l10n.termsSectionContact,
            body: l10n.termsSectionContactBody(l10n.aboutUsContactEmail),
            isLast: true,
          ),
          const MoujTechBrand(),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({
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
