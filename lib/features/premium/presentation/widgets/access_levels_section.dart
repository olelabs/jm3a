import 'package:flutter/material.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../auth/domain/entities/user_entity.dart';

/// User-facing access level. Display-only: derived from the SAME
/// entitlement fields every gate already reads ([UserEntity.isPremiumActive]
/// / [UserEntity.premiumTier]); nothing here grants or checks access.
///
/// Internal identifiers are unchanged for compatibility: tier `premium` is
/// shown as **Jma3a Plus**, tier `premium_plus` as **Jma3a Elite**.
enum AccessLevel { basic, plus, elite }

AccessLevel accessLevelOf(UserEntity? user) {
  if (user == null || !user.isPremiumActive) return AccessLevel.basic;
  return user.premiumTier == 'premium_plus'
      ? AccessLevel.elite
      : AccessLevel.plus;
}

/// Label for a raw tier identifier (`premium` / `premium_plus`).
String accessTierLabel(AppLocalizations l10n, String? tier) =>
    tier == 'premium_plus' ? l10n.premiumPlusLabel : l10n.premiumTitle;

String accessLevelLabel(AppLocalizations l10n, AccessLevel level) =>
    switch (level) {
      AccessLevel.basic => l10n.accessLevelBasic,
      AccessLevel.plus => l10n.premiumTitle,
      AccessLevel.elite => l10n.premiumPlusLabel,
    };

/// Room player caps per level, mirroring [UserEntity.roomPlayerCap] (the
/// display formula for the server-enforced cap in create_room). Kept as
/// constants for this informational list only; a test asserts they match.
const int kPlusRoomPlayerCap = 8;
const int kEliteRoomPlayerCap = 12;

/// Feature lists, in display order. Every entry corresponds to an existing
/// gate in the app (see the pre-release audit report for the file list);
/// no feature here is new or promised beyond what the app already does.
List<String> plusFeatures(
  AppLocalizations l10n, {
  required int roomsPerDay,
  required int offlinePacks,
}) => [
  l10n.accessFeatPlusThemes,
  l10n.accessFeatPlusAvatars,
  l10n.accessFeatPlusManualStatus,
  l10n.accessFeatRoomsPerDay(roomsPerDay.toString()),
  l10n.accessFeatRoomPlayers(kPlusRoomPlayerCap.toString()),
  l10n.accessFeatOfflinePacks(offlinePacks.toString()),
  l10n.accessFeatPlusAnonymousChat,
  l10n.accessFeatPlusHiddenSpectating,
  l10n.accessFeatPlusTransferOwnership,
  l10n.accessFeatPlusClosedRoomHistory,
  l10n.accessFeatPlusCustomCards,
  l10n.accessFeatPlusProofs,
];

List<String> eliteFeatures(
  AppLocalizations l10n, {
  required bool includeCreatorEligibility,
}) => [
  l10n.accessFeatRoomPlayers(kEliteRoomPlayerCap.toString()),
  l10n.accessFeatEliteTargetedChat,
  l10n.accessFeatEliteThemesAvatars,
  l10n.accessFeatEliteRevealSpectators,
  l10n.accessFeatEliteAwayStatus,
  if (includeCreatorEligibility) l10n.accessFeatEliteCreator,
];

/// "Jma3a access levels" explainer: what each level includes, that levels
/// are granted (never sold) by the Jma3a team, and how to ask to be
/// considered. Jma3a Plus first, Jma3a Elite always LAST as the highest.
class AccessLevelsSection extends StatelessWidget {
  const AccessLevelsSection({
    super.key,
    required this.current,
    required this.roomsPerDay,
    required this.offlinePacks,
    this.includeCreatorEligibility = false,
    this.onRequestConsideration,
  });

  final AccessLevel current;
  final int roomsPerDay;
  final int offlinePacks;

  /// Whether Verified Creator applications currently require Elite
  /// (creator_verification_requirements.requires_premium_plus).
  final bool includeCreatorEligibility;

  /// Opens the existing contact channel with the Jma3a team. Hidden when
  /// null or when the user already has the highest level.
  final VoidCallback? onRequestConsideration;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.accessLevelsHeader,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.accessLevelsGrantedNote,
          style: context.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.badge_outlined, size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.accessLevelCurrent(accessLevelLabel(l10n, current)),
                style: context.textTheme.labelLarge,
              ),
            ),
          ],
        ),
        if (onRequestConsideration != null &&
            current != AccessLevel.elite) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRequestConsideration,
            icon: const Icon(Icons.chat_outlined),
            label: Text(l10n.accessLevelRequestConsideration),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _LevelCard(
          key: const ValueKey('access-level-plus'),
          title: l10n.premiumTitle,
          subtitle: l10n.accessLevelPlusSubtitle,
          symbol: '✦',
          color: const Color(0xFFF5A623),
          isCurrent: current == AccessLevel.plus,
          features: plusFeatures(
            l10n,
            roomsPerDay: roomsPerDay,
            offlinePacks: offlinePacks,
          ),
        ),
        const SizedBox(height: 12),
        // Highest level — intentionally the final card.
        _LevelCard(
          key: const ValueKey('access-level-elite'),
          title: l10n.premiumPlusLabel,
          subtitle: l10n.accessLevelEliteSubtitle,
          symbol: '⬡',
          color: const Color(0xFF7B68EE),
          isCurrent: current == AccessLevel.elite,
          highestBadge: l10n.accessLevelHighestBadge,
          intro: l10n.accessLevelEliteIncludesPlus,
          features: eliteFeatures(
            l10n,
            includeCreatorEligibility: includeCreatorEligibility,
          ),
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.symbol,
    required this.color,
    required this.features,
    required this.isCurrent,
    this.highestBadge,
    this.intro,
  });

  final String title;
  final String subtitle;
  final String symbol;
  final Color color;
  final List<String> features;
  final bool isCurrent;
  final String? highestBadge;
  final String? intro;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? color : color.withOpacity(0.35),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color),
                ),
                alignment: Alignment.center,
                child: Text(
                  symbol,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    // Wrap (not extra Row children): "Highest level" plus
                    // "Your level" overflowed a 360dp-wide header.
                    if (highestBadge != null || isCurrent) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (highestBadge != null)
                            _Pill(label: highestBadge!, color: color),
                          if (isCurrent)
                            _Pill(
                              label: context.l10n.accessLevelYourLevelBadge,
                              color: color,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (intro != null) ...[
            const SizedBox(height: 12),
            Text(
              intro!,
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 10),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_rounded, size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: context.textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
