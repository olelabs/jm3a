
import 'package:flutter/material.dart';
import 'package:jma3a/core/services/subscription_service.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/auth_provider.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _loading = false;
  bool _plansLoading = true;
  String? _selectedPlanId;
  List<_PremiumPlan> _plans = [];

  static const Color _gold = Color(0xFFF5A623);

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _loadPlans();
  }

  Future<void> _loadStatus() async {
    final uid = context.read<AuthProvider>().currentUser?.id;
    if (uid == null) return;
    await SubscriptionService.instance.getActiveSubscription(uid);
    if (mounted) setState(() {});
  }

  /// Loaded from subscription_plans (DB) via GET /v1/wallet/plans instead
  /// of a hardcoded constant — pricing/plan set updates automatically when
  /// the table changes, no client release needed.
  Future<void> _loadPlans() async {
    try {
      final api = ApiClient.instance;
      final resp = await api.get<Map<String, dynamic>>('/v1/wallet/plans');
      final rows = (resp.data?['plans'] as List?) ?? const [];
      final locale = context.mounted
          ? Localizations.localeOf(context).languageCode
          : 'en';
      final plans = rows.map((r) {
        final row = r as Map<String, dynamic>;
        final nameJson = (row['name_json'] as Map?)?.cast<String, dynamic>() ?? {};
        final descriptionJson =
            (row['description_json'] as Map?)?.cast<String, dynamic>() ?? {};
        final featuresJson = (row['features_json'] as Map?)?.cast<String, dynamic>() ?? {};
        final priceMru = (row['price_mru'] as num?)?.toInt() ?? 0;
        final features =
            (featuresJson[locale] as List?) ?? (featuresJson['en'] as List?) ?? const [];
        return _PremiumPlan(
          id: row['id'] as String,
          label: nameJson[locale] as String? ?? nameJson['en'] as String? ?? row['id'] as String,
          description:
              descriptionJson[locale] as String? ?? descriptionJson['en'] as String?,
          tier: row['tier'] as String,
          priceMru: priceMru,
          durationDays: (row['duration_days'] as num?)?.toInt() ?? 30,
          features: features.cast<String>(),
        );
      }).toList();
      if (mounted) setState(() => _plans = plans);
    } catch (_) {
      // Leave _plans empty — the screen shows an empty plan list rather
      // than falling back to stale hardcoded prices a user could be
      // charged incorrectly against.
    } finally {
      if (mounted) setState(() => _plansLoading = false);
    }
  }

  Future<void> _purchase(_PremiumPlan plan) async {
    if (_loading) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final currentTier = user.premiumTier;
    final isCurrentlyPlus =
        user.isPremiumActive && currentTier == 'premium_plus';
    final isDowngrade = isCurrentlyPlus && plan.tier == 'premium';
    if (isDowngrade) {
      final expiresAt = user.premiumExpiresAt;
      final dateStr = expiresAt != null
          ? '${expiresAt.day}/${expiresAt.month}/${expiresAt.year}'
          : context.l10n.premiumCurrentTermEnds;
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (dCtx) => AlertDialog(
            title: Text(dCtx.l10n.premiumCannotDowngradeTitle),
            content: Text(
              dCtx.l10n.premiumCannotDowngradeBody(dateStr),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dCtx).pop(),
                child: Text(dCtx.l10n.ok),
              ),
            ],
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(dCtx.l10n.premiumPurchasePlan(plan.label)),
        content: Text(
          dCtx.l10n.premiumPurchaseConfirmBody(
            plan.label,
            plan.priceLabel,
            plan.periodLabel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: Text(dCtx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: Text(dCtx.l10n.premiumConfirmPurchase),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _loading = true;
      _selectedPlanId = plan.id;
    });
    try {
      final api = ApiClient.instance;
      await api.post('/v1/wallet/subscribe', data: {'planId': plan.id});
      if (!mounted) return;
      await context.read<AuthProvider>().refreshCurrentUser();
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.premiumPlanActivated(plan.label)),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      final l10n = context.l10n;
      final msg = raw.contains('insufficient_balance')
          ? l10n.premiumErrorInsufficientBalance
          : raw.contains('wallet_not_found')
          ? l10n.premiumErrorWalletNotFound
          : raw.contains('wallet_frozen')
          ? l10n.premiumErrorWalletFrozen
          : raw.contains('invalid_plan')
          ? l10n.premiumErrorInvalidPlan
          : raw.contains('downgrade_blocked')
          ? l10n.premiumErrorDowngradeBlocked
          : l10n.premiumErrorPurchaseFailed(raw);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
          _selectedPlanId = null;
        });
    }
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
            const SizedBox(height: 24),
            if (_plansLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ..._plans.map((plan) {
                final isDowngradeOption =
                    isPremium && tier == 'premium_plus' && plan.tier == 'premium';
                return _PlanCard(
                  plan: plan,
                  isActive: isPremium && tier == plan.tier,
                  isLoading: _loading && _selectedPlanId == plan.id,
                  isLocked: isDowngradeOption,
                  onTap: () => _purchase(plan),
                );
              }),
            const SizedBox(height: 24),
            if (_plans.isNotEmpty) _FeatureLists(plans: _plans),
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

class _PremiumPlan {
  const _PremiumPlan({
    required this.id,
    required this.label,
    required this.description,
    required this.tier,
    required this.priceMru,
    required this.durationDays,
    required this.features,
  });
  final String id, label, tier;
  final String? description;
  final int priceMru;
  final int durationDays;
  final List<String> features;

  /// price_mru is a literal whole-MRU amount — matches every other price
  /// column in this schema (physical packs, deposits, withdrawals) and,
  /// critically, matches what purchaseSubscription() in walletService.js
  /// actually debits from the wallet (`-plan.price_mru`, unscaled). An
  /// earlier migration's comment wrongly assumed a "hundredths of MRU"
  /// convention here, which made this label show a fabricated decimal
  /// value that never matched the real deduction.
  String get priceLabel => '$priceMru MRU';

  /// Only monthly plans exist today, but this stays duration-driven
  /// rather than hardcoded so a differently-timed plan added later
  /// (e.g. a future promo) displays correctly without a client change.
  String get periodLabel => durationDays >= 28 && durationDays <= 31
      ? 'month'
      : '$durationDays days';
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
    this.isLocked = false,
  });
  final _PremiumPlan plan;
  final bool isActive;
  final bool isLoading;
  final bool isLocked;
  final VoidCallback onTap;

  Color get _accent => plan.tier == 'premium_plus'
      ? const Color(0xFF7B68EE)
      : const Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: isLocked ? 0.5 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? _accent.withOpacity(0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? _accent : theme.colorScheme.outlineVariant,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (plan.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          plan.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.premiumPricePerPeriod(
                          plan.priceLabel,
                          plan.periodLabel,
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (isLocked) ...[
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.premiumLockedUntilExpires,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.l10n.activeLabel,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  )
                else if (isLocked)
                  Icon(
                    Icons.lock_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  )
                else
                  SizedBox(
                    width: 72,
                    height: 36,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isLoading ? null : onTap,
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(context.l10n.getButton),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders each plan's own feature list, sourced from
/// subscription_plans.features_json (per-locale) instead of the previous
/// static English-only 3-column comparison table hardcoded into this file.
class _FeatureLists extends StatelessWidget {
  const _FeatureLists({required this.plans});
  final List<_PremiumPlan> plans;

  Color _accentFor(String tier) =>
      tier == 'premium_plus' ? const Color(0xFF7B68EE) : const Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.premiumWhatYouGet,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (final plan in plans)
          if (plan.features.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _accentFor(plan.tier),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final feature in plan.features)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: _accentFor(plan.tier),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
