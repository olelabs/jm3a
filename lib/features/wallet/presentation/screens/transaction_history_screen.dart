// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/feedback/error_view.dart';
// import '../wallet_provider.dart';
// import '../widgets/transaction_tile.dart';

// // ── Transaction history ───────────────────────────────────────────────────────

// class TransactionHistoryScreen extends StatefulWidget {
//   const TransactionHistoryScreen({super.key});

//   @override
//   State<TransactionHistoryScreen> createState() =>
//       _TransactionHistoryScreenState();
// }

// class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
//   final _scrollCtrl = ScrollController();
//   TransactionType? _typeFilter;

//   @override
//   void initState() {
//     super.initState();
//     context.read<WalletProvider>().loadTransactions(reset: true);
//     _scrollCtrl.addListener(_onScroll);
//   }

//   @override
//   void dispose() {
//     _scrollCtrl.dispose();
//     super.dispose();
//   }

//   void _onScroll() {
//     if (_scrollCtrl.position.pixels >=
//         _scrollCtrl.position.maxScrollExtent - 100) {
//       context.read<WalletProvider>().loadMoreTransactions();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Transaction History'),
//       ),
//       body: Consumer<WalletProvider>(
//         builder: (ctx, wallet, _) {
//           if (wallet.isLoading && wallet.transactions.isEmpty) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (wallet.failure != null && wallet.transactions.isEmpty) {
//             return ErrorView(
//               message: wallet.failure!.message,
//               onRetry: () => wallet.loadTransactions(reset: true),
//             );
//           }

//           // Filter
//           final filtered = _typeFilter != null
//               ? wallet.transactions
//                   .where((t) => t.type == _typeFilter)
//                   .toList()
//               : wallet.transactions;

//           return Column(
//             children: [
//               // Filter chips
//               _TypeFilterBar(
//                 selected: _typeFilter,
//                 onChanged: (t) {
//                   setState(() => _typeFilter = t);
//                   if (t == null) {
//                     wallet.loadTransactions(reset: true);
//                   }
//                 },
//               ),

//               // List
//               Expanded(
//                 child: RefreshIndicator(
//                   onRefresh: () => wallet.loadTransactions(reset: true),
//                   child: filtered.isEmpty
//                       ? Center(
//                           child: Text('No transactions',
//                               style: ctx.textTheme.bodyMedium?.copyWith(
//                                   color: ctx.colorScheme.onSurfaceVariant)),
//                         )
//                       : ListView.separated(
//                           controller: _scrollCtrl,
//                           padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//                           itemCount: filtered.length +
//                               (wallet.isLoadingMore ? 1 : 0),
//                           separatorBuilder: (_, __) =>
//                               const Divider(height: 1, indent: 60),
//                           itemBuilder: (_, i) {
//                             if (i == filtered.length) {
//                               return const Padding(
//                                 padding: EdgeInsets.all(16),
//                                 child: Center(
//                                     child: CircularProgressIndicator()),
//                               );
//                             }
//                             return TransactionTile(transaction: filtered[i])
//                                 .animate(delay: (i * 20).ms).fadeIn();
//                           },
//                         ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// class _TypeFilterBar extends StatelessWidget {
//   const _TypeFilterBar({required this.selected, required this.onChanged});
//   final TransactionType? selected;
//   final void Function(TransactionType?) onChanged;

//   static const _filters = [
//     (null,                    'All'),
//     (TransactionType.deposit, 'Deposits'),
//     (TransactionType.withdrawal, 'Withdrawals'),
//     (TransactionType.purchase,   'Purchases'),
//     (TransactionType.commission, 'Earnings'),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
//       child: Row(
//         children: _filters.asMap().entries.map((e) {
//           final (type, label) = e.value;
//           final isSelected = selected == type;
//           return Padding(
//             padding: EdgeInsets.only(right: e.key < _filters.length - 1 ? 8 : 0),
//             child: FilterChip(
//               label:       Text(label),
//               selected:    isSelected,
//               onSelected:  (_) => onChanged(isSelected ? null : type),
//               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//               visualDensity: VisualDensity.compact,
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
// }

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
      appBar: AppBar(title: const Text('Transaction History')),
      body: Consumer<WalletProvider>(
        builder: (ctx, wallet, _) {
          if (wallet.isLoading && wallet.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (wallet.failure != null && wallet.transactions.isEmpty) {
            return ErrorView(
              message: wallet.failure!.message,
              onRetry: () => wallet.loadTransactions(reset: true),
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
                  onRefresh: () => wallet.loadTransactions(reset: true),
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No transactions',
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

  static const _filters = [
    (null, 'All'),
    (TransactionType.deposit, 'Deposits'),
    (TransactionType.withdrawal, 'Withdrawals'),
    (TransactionType.purchase, 'Purchases'),
    (TransactionType.commission, 'Earnings'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: _filters.asMap().entries.map((e) {
          final (type, label) = e.value;
          final isSelected = selected == type;
          return Padding(
            padding: EdgeInsets.only(
              right: e.key < _filters.length - 1 ? 8 : 0,
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
