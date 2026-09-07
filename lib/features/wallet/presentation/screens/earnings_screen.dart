import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../wallet_provider.dart';
// ── Earnings screen ────────────────────────────────────────────────────────────

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WalletProvider>().loadEarnings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.walletCreatorEarningsTitle)),
      body: Consumer<WalletProvider>(
        builder: (ctx, wallet, _) {
          final earnings = wallet.earnings;

          if (wallet.isLoading && earnings == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (earnings == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📦',
                      style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(ctx.l10n.walletNoEarningsYet,
                      style: ctx.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(ctx.l10n.walletCreateSellPacksHint,
                      style: ctx.textTheme.bodyMedium?.copyWith(
                          color: ctx.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Commission rate banner ───────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.tealGreen, AppColors.tealGreenLight],
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text('💰', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ctx.l10n.walletCreatorEarningsRateLabel,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text(
                            '${((1 - earnings.commissionRate) * 100).round()}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800),
                          ),
                          Text(
                            ctx.l10n.walletOfEveryPackSale((earnings.commissionRate * 100).round()),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 20),

              // ── Stats grid ──────────────────────────────────────────
              GridView.count(
                shrinkWrap: true,
                physics:    const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing:  12,
                childAspectRatio: 1.5,
                children: [
                  _EarningStatCard(
                      label: ctx.l10n.walletEarningsTotal,
                      value: earnings.formatted,
                      icon:  '📈',
                      color: AppColors.successGreen),
                  _EarningStatCard(
                      label: ctx.l10n.walletEarningsThisMonth,
                      value: earnings.thisMonthFormatted,
                      icon:  '📅',
                      color: AppColors.infoBlue),
                  _EarningStatCard(
                      label: ctx.l10n.pendingLabel,
                      value: earnings.pendingFormatted,
                      icon:  '⏳',
                      color: AppColors.warningAmber),
                  _EarningStatCard(
                      label: ctx.l10n.walletEarningsTotalSales,
                      value: '${earnings.totalSales}',
                      icon:  '🛒',
                      color: AppColors.purple),
                ],
              ).animate(delay: 80.ms).fadeIn(),

              const SizedBox(height: 24),

              // ── Available for withdrawal ─────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:        AppColors.successGreen.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.successGreen.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_outlined,
                        color: AppColors.successGreen),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ctx.l10n.walletAvailableForWithdrawal,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(earnings.availableFormatted,
                              style: const TextStyle(
                                  color:      AppColors.successGreen,
                                  fontSize:   22,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 120.ms).fadeIn(),

              const SizedBox(height: 16),

              // ── How earnings work ────────────────────────────────────
              const _HowEarningsWork(),
            ],
          );
        },
      ),
    );
  }
}

class _EarningStatCard extends StatelessWidget {
  const _EarningStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final String icon;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:  MainAxisAlignment.spaceBetween,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color:      color,
                      fontWeight: FontWeight.w800,
                      fontSize:   18)),
              Text(label,
                  style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HowEarningsWork extends StatelessWidget {
  const _HowEarningsWork();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.walletHowEarningsWork,
            style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _BulletItem(
            text: context.l10n.walletBulletEarn85),
        _BulletItem(
            text: context.l10n.walletBulletPlatformFee),
        _BulletItem(
            text: context.l10n.walletBulletCreditedAfterConfirm),
        _BulletItem(
            text: context.l10n.walletBulletMinWithdrawal),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded,
                size: 14, color: AppColors.successGreen),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: context.textTheme.bodySmall?.copyWith(height: 1.5)),
          ),
        ],
      ),
    );
  }
}
