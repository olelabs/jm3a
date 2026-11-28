
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jma3a/core/services/subscription_service.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/platform_config_provider.dart';
import '../../../../core/constants/social_links.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../shared/utils/external_link_launcher.dart';
import 'widgets/access_levels_section.dart';

/// Read-only "Your Jma3a Access" screen (route name kept as /premium for
/// compatibility with existing deep links). Shows the user's current
/// access level — Jma3a Plus (tier `premium`) or Jma3a Elite (tier
/// `premium_plus`) — and what each level includes. Access levels are
/// granted by the Jma3a team; there is no purchase flow here (the old
/// in-app plan list / /v1/wallet/subscribe flow was removed earlier).
/// Still the navigation target for the access-level push-notification
/// deep link and premium_avatar_service.dart's locked-avatar tile.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final uid = context.read<AuthProvider>().currentUser?.id;
    if (uid == null) return;
    await SubscriptionService.instance.getActiveSubscription(uid);
    if (mounted) setState(() {});
  }

  Future<void> _requestAccessConsideration() async {
    final message = Uri.encodeComponent(
      context.l10n.accessLevelWhatsAppMessage,
    );
    await launchExternalUrl('${SocialLinks.whatsapp}?text=$message');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final level = accessLevelOf(user);
    final config = context.watch<PlatformConfigProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.accessLevelScreenTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (level != AccessLevel.basic)
              _ActiveBanner(
                label: accessLevelLabel(context.l10n, level),
                expiresAt: user?.premiumExpiresAt,
              )
            else
              const _HeroBanner(),
            const SizedBox(height: 24),
            AccessLevelsSection(
              current: level,
              roomsPerDay: config.roomCreationDailyLimit(isPremium: true),
              offlinePacks: config.offlinePackLimit(isPremium: true),
              onRequestConsideration: _requestAccessConsideration,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Text('✦', style: TextStyle(color: Colors.white, fontSize: 48)),
        const SizedBox(height: 12),
        Text(
          context.l10n.premiumUnlockTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.premiumFeatureListDescription,
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner({required this.label, this.expiresAt});
  final String label;
  final DateTime? expiresAt;
  @override
  Widget build(BuildContext context) {
    final exp = expiresAt;
    final status = exp != null
        ? context.l10n.accessLevelActiveUntil(
            DateFormat.yMd(context.l10n.localeName).format(exp),
          )
        : context.l10n.accessLevelActiveNoEndDate;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: Colors.green, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label ✦',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(color: Colors.green.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
