
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../wallet_provider.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/transaction_tile.dart';

// ── Transaction history ───────────────────────────────────────────────────────

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _scrollCtrl = ScrollController();
  TransactionType? _typeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final wallet = context.read<WalletProvider>();
      // Ensure wallet is loaded before fetching transactions
      if (wallet.wallet == null) await wallet.refreshWallet();
      if (mounted) wallet.loadTransactions(reset: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 100) {
      context.read<WalletProvider>().loadMoreTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.walletTransactionHistory)),
      body: Consumer<WalletProvider>(
        builder: (ctx, wallet, _) {
          if (wallet.isLoading && wallet.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (wallet.failure != null && wallet.transactions.isEmpty) {
            return ErrorView(
              message: wallet.failure!.message,
              onRetry: () =>
                  wallet.loadTransactions(reset: true, typeFilter: _typeFilter),
            );
          }

          // Filtering happens server-side (WalletProvider forwards
          // typeFilter to the repository query) so pagination always
          // matches the active filter — wallet.transactions is already the
          // correct, complete filtered set for the current page window.
          final filtered = wallet.transactions;

          return Column(
            children: [
              // Filter chips
              _TypeFilterBar(
                selected: _typeFilter,
                onChanged: (t) {
                  setState(() => _typeFilter = t);
                  wallet.loadTransactions(reset: true, typeFilter: t);
                },
              ),

              // List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => wallet.loadTransactions(
                    reset: true,
                    typeFilter: _typeFilter,
                  ),
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            context.l10n.walletNoTransactions,
                            style: ctx.textTheme.bodyMedium?.copyWith(
                              color: ctx.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount:
                              filtered.length + (wallet.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 60),
                          itemBuilder: (_, i) {
                            if (i == filtered.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return TransactionTile(
                              transaction: filtered[i],
                              onTap: () => showTransactionDetailSheet(
                                context,
                                filtered[i],
                              ),
                            ).animate(delay: (i * 20).ms).fadeIn();
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TypeFilterBar extends StatelessWidget {
  const _TypeFilterBar({required this.selected, required this.onChanged});
  final TransactionType? selected;
  final void Function(TransactionType?) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Every TransactionType value gets its own filter chip — "All" plus one
    // per category, so nothing is only reachable by scrolling through the
    // unfiltered list.
    final filters = <(TransactionType?, String)>[
      (null, l10n.walletFilterAll),
      (TransactionType.deposit, l10n.walletFilterDeposits),
      (TransactionType.withdrawal, l10n.walletFilterWithdrawals),
      (TransactionType.purchase, l10n.walletFilterPurchases),
      (TransactionType.commission, l10n.walletFilterEarnings),
      (TransactionType.refund, l10n.walletFilterRefunds),
      (TransactionType.payout, l10n.walletFilterPayouts),
      (TransactionType.bonus, l10n.walletFilterBonuses),
      (TransactionType.adjustment, l10n.walletFilterAdjustments),
      (TransactionType.transfer, l10n.walletFilterTransfers),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: filters.asMap().entries.map((e) {
          final (type, label) = e.value;
          final isSelected = selected == type;
          return Padding(
            padding: EdgeInsets.only(
              right: e.key < filters.length - 1 ? 8 : 0,
            ),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onChanged(isSelected ? null : type),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}
