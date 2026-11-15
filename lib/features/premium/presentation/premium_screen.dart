
import 'package:flutter/material.dart';
import 'package:jma3a/core/services/subscription_service.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';

/// Read-only Premium/Premium Plus status screen — the in-app purchase
/// flow (plan list, "Get" buttons, confirm/downgrade dialogs,
/// /v1/wallet/plans + /v1/wallet/subscribe) has been removed. Premium/
/// Premium Plus is now purchased exclusively through the external Jma3a
/// Store; this screen only reflects the entitlement already on the
/// user's profile (via SubscriptionService/AuthProvider) and is still a
/// valid navigation target for the subscription push-notification
/// deep-link and premium_avatar_service.dart's locked-avatar tile.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  static const Color _gold = Color(0xFFF5A623);

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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isPremium = user?.isPremiumActive ?? false;
    final tier = user?.premiumTier;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.premiumTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gold, Color(0xFFFF8C00)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '✦',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isPremium)
              _ActiveBanner(user: user!, tier: tier)
            else
              const _HeroBanner(),
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
  const _ActiveBanner({required this.user, this.tier});
  final dynamic user;
  final String? tier;
  @override
  Widget build(BuildContext context) {
    final exp = user.premiumExpiresAt;
    final label = exp != null
        ? 'Expires ${exp.day}/${exp.month}/${exp.year}'
        : 'Active — no expiry';
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tier == 'premium_plus'
                    ? 'Premium Plus Active ✦'
                    : 'Premium Active ✦',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade800,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: Colors.green.shade600, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
