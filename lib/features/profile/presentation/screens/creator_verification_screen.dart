import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/platform_config_provider.dart';
import '../../../../core/constants/social_links.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/utils/external_link_launcher.dart';
import '../../../premium/presentation/widgets/access_levels_section.dart';
import '../../data/profile_repository.dart';

/// "Become a verified creator" — shows live progress against the
/// DB-driven requirement thresholds (creator_verification_requirements,
/// via get_creator_verification_progress()) and lets an eligible user
/// submit a creator_verifications application. Requirements aren't
/// hardcoded here — everything shown comes from that RPC, so an admin
/// changing a threshold in the database is reflected without a client
/// release.
class CreatorVerificationScreen extends StatefulWidget {
  const CreatorVerificationScreen({super.key});

  @override
  State<CreatorVerificationScreen> createState() =>
      _CreatorVerificationScreenState();
}

class _CreatorVerificationScreenState
    extends State<CreatorVerificationScreen> {
  CreatorVerificationProgress? _progress;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final progress = await ProfileRepository.instance
          .getCreatorVerificationProgress(userId);
      if (mounted) setState(() => _progress = progress);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.errorUnexpected);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Requests are now made via WhatsApp instead of the in-app
  /// applyCreatorVerification() RPC — see SocialLinks.whatsapp's own doc
  /// comment for why the number lives in exactly one place. A short,
  /// non-sensitive prefilled message identifies the request as being for
  /// Verified Creator status; it never includes the user's name, email,
  /// or any other account detail.
  Future<void> _requestViaWhatsApp() async {
    final message = Uri.encodeComponent(context.l10n.creatorWhatsAppMessage);
    await launchExternalUrl('${SocialLinks.whatsapp}?text=$message');
  }

  /// Same WhatsApp channel as [_requestViaWhatsApp], with a message asking
  /// the team to consider the user for an access level. Like that message
  /// it never includes any account detail. No in-app grant or payment.
  Future<void> _requestAccessConsideration() async {
    final message = Uri.encodeComponent(
      context.l10n.accessLevelWhatsAppMessage,
    );
    await launchExternalUrl('${SocialLinks.whatsapp}?text=$message');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.creatorVerificationTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;
    final p = _progress!;
    final user = context.watch<AuthProvider>().currentUser;

    if (user?.canSubmitCreatorRecoveryComplaint ?? false) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.creatorRecoveryBannerTitle,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.creatorRecoveryBannerBody,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      context.push(RouteNames.creatorRecoveryComplaint),
                  child: Text(l10n.creatorRecoveryBannerAction),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final requirements = <_Requirement>[
      if (p.requiresPremiumPlus)
        _Requirement(
          label: l10n.creatorReqPremiumPlus,
          met: p.isPremiumPlus,
        ),
      _Requirement(
        label: l10n.creatorReqGamesPlayed(p.minGamesPlayed),
        met: p.gamesPlayed >= p.minGamesPlayed,
        progressText: '${p.gamesPlayed} / ${p.minGamesPlayed}',
      ),
      _Requirement(
        label: l10n.creatorReqPacksUsed(p.minPacksUsed),
        met: p.packsUsed >= p.minPacksUsed,
        progressText: '${p.packsUsed} / ${p.minPacksUsed}',
      ),
      _Requirement(
        label: l10n.creatorReqFollowers(p.minFollowers),
        met: p.followersCount >= p.minFollowers,
        progressText: '${p.followersCount} / ${p.minFollowers}',
      ),
      _Requirement(
        label: l10n.creatorReqLoginStreak(p.requiredStreakDays),
        met: p.loginStreakDays >= p.requiredStreakDays,
        progressText: '${p.loginStreakDays} / ${p.requiredStreakDays}',
      ),
      _Requirement(
        label: l10n.creatorReqRoomStreak(p.requiredStreakDays),
        met: p.roomCreationStreakDays >= p.requiredStreakDays,
        progressText: '${p.roomCreationStreakDays} / ${p.requiredStreakDays}',
      ),
      _Requirement(
        label: l10n.creatorReqPackGamesStreak(
          p.requiredDailyPackGames,
          p.requiredStreakDays,
        ),
        met: p.packGamesStreakDays >= p.requiredStreakDays,
        progressText: '${p.packGamesStreakDays} / ${p.requiredStreakDays}',
      ),
      if (p.requirePlayedWithOthers)
        _Requirement(
          label: l10n.creatorReqPlayedWithOthers,
          met: p.hasPlayedWithOthers,
        ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.creatorVerificationSubtitle,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        ...requirements.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RequirementTile(requirement: r),
          ),
        ),
        const SizedBox(height: 24),
        if (p.isEligible)
          FilledButton.icon(
            onPressed: _requestViaWhatsApp,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            icon: const Icon(Icons.chat_rounded),
            label: Text(l10n.creatorRequestViaWhatsApp),
          )
        else
          Text(
            l10n.creatorKeepGoing,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 16),
        AccessLevelsSection(
          current: accessLevelOf(user),
          roomsPerDay: context
              .watch<PlatformConfigProvider>()
              .roomCreationDailyLimit(isPremium: true),
          offlinePacks: context
              .watch<PlatformConfigProvider>()
              .offlinePackLimit(isPremium: true),
          includeCreatorEligibility: p.requiresPremiumPlus,
          onRequestConsideration: _requestAccessConsideration,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Requirement {
  const _Requirement({required this.label, required this.met, this.progressText});
  final String label;
  final bool met;
  final String? progressText;
}

class _RequirementTile extends StatelessWidget {
  const _RequirementTile({required this.requirement});
  final _Requirement requirement;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            requirement.met
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: requirement.met ? Colors.green : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(requirement.label)),
          if (requirement.progressText != null)
            Text(
              requirement.progressText!,
              style: context.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
