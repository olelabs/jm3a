// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_animate/flutter_animate.dart';
// // // import 'package:go_router/go_router.dart';
// // // import 'package:provider/provider.dart';

// // // import '../../../../core/extensions/context_ext.dart';
// // // import '../../../../core/theme/app_colors.dart';
// // // import '../../../../shared/widgets/cards/j_card.dart';
// // // import '../../../../shared/widgets/feedback/error_view.dart';
// // // import '../wallet_provider.dart';
// // // import '../widgets/transaction_tile.dart';
// // // import 'deposit_screen.dart';
// // // import 'transaction_history_screen.dart';
// // // import 'withdrawal_screen.dart';
// // // import 'earnings_screen.dart';

// // // /// Wallet home screen.
// // // /// Shows: balance card, quick actions (deposit/withdraw), recent transactions.
// // // class WalletHomeScreen extends StatefulWidget {
// // //   const WalletHomeScreen({super.key});

// // //   @override
// // //   State<WalletHomeScreen> createState() => _WalletHomeScreenState();
// // // }

// // // class _WalletHomeScreenState extends State<WalletHomeScreen> {
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // //       final p = context.read<WalletProvider>();
// // //       p.loadTransactions(reset: true);
// // //       p.loadMyDeposits();
// // //       p.loadMyWithdrawals();
// // //     });
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text('Wallet'),
// // //         actions: [
// // //           IconButton(
// // //             icon: const Icon(Icons.refresh_rounded),
// // //             onPressed: () {
// // //               context.read<WalletProvider>()
// // //                 ..refreshWallet()
// // //                 ..loadTransactions(reset: true);
// // //             },
// // //             tooltip: 'Refresh',
// // //           ),
// // //         ],
// // //       ),
// // //       body: Consumer<WalletProvider>(
// // //         builder: (ctx, wallet, _) {
// // //           if (wallet.isLoading && wallet.wallet == null) {
// // //             return const Center(child: CircularProgressIndicator());
// // //           }
// // //           if (wallet.failure != null && wallet.wallet == null) {
// // //             return ErrorView(
// // //               message: wallet.failure!.message,
// // //               onRetry: wallet.refreshWallet,
// // //             );
// // //           }

// // //           return RefreshIndicator(
// // //             onRefresh: () async {
// // //               await wallet.refreshWallet();
// // //               await wallet.loadTransactions(reset: true);
// // //             },
// // //             child: ListView(
// // //               padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
// // //               children: [
// // //                 const SizedBox(height: 8),

// // //                 // ── Balance card ─────────────────────────────────────────
// // //                 _BalanceCard(wallet: wallet)
// // //                     .animate().fadeIn().slideY(begin: -0.06, end: 0),

// // //                 const SizedBox(height: 20),

// // //                 // ── Quick actions ─────────────────────────────────────────
// // //                 _QuickActions(wallet: wallet)
// // //                     .animate(delay: 80.ms).fadeIn(),

// // //                 const SizedBox(height: 24),

// // //                 // ── Pending items ─────────────────────────────────────────
// // //                 _PendingSection(wallet: wallet),

// // //                 // ── Recent transactions ───────────────────────────────────
// // //                 Row(
// // //                   children: [
// // //                     Text('Recent Transactions',
// // //                         style: ctx.textTheme.titleMedium?.copyWith(
// // //                             fontWeight: FontWeight.w700)),
// // //                     const Spacer(),
// // //                     TextButton(
// // //                       onPressed: () => Navigator.push(
// // //                         ctx,
// // //                         MaterialPageRoute(
// // //                           builder: (_) =>
// // //                               ChangeNotifierProvider.value(
// // //                                 value: wallet,
// // //                                 child: const TransactionHistoryScreen(),
// // //                               ),
// // //                         ),
// // //                       ),
// // //                       child: const Text('See all'),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 const SizedBox(height: 8),

// // //                 if (wallet.transactions.isEmpty && !wallet.isLoading)
// // //                   Padding(
// // //                     padding: const EdgeInsets.symmetric(vertical: 24),
// // //                     child: Center(
// // //                       child: Text('No transactions yet',
// // //                           style: ctx.textTheme.bodyMedium?.copyWith(
// // //                               color: ctx.colorScheme.onSurfaceVariant)),
// // //                     ),
// // //                   )
// // //                 else
// // //                   ...wallet.transactions.take(5).map((tx) =>
// // //                       TransactionTile(transaction: tx)
// // //                           .animate().fadeIn()),
// // //               ],
// // //             ),
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ── Balance card ───────────────────────────────────────────────────────────────
// // // class _BalanceCard extends StatelessWidget {
// // //   const _BalanceCard({required this.wallet});
// // //   final WalletProvider wallet;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final isFrozen = wallet.isWalletFrozen;

// // //     return Container(
// // //       width: double.infinity,
// // //       padding: const EdgeInsets.all(24),
// // //       decoration: BoxDecoration(
// // //         gradient: isFrozen
// // //             ? LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade800])
// // //             : const LinearGradient(
// // //                 colors: [AppColors.navyBlue, AppColors.navyBlueLight],
// // //                 begin: Alignment.topLeft,
// // //                 end: Alignment.bottomRight,
// // //               ),
// // //         borderRadius: BorderRadius.circular(20),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color:  (isFrozen ? Colors.grey : AppColors.navyBlue).withOpacity(0.25),
// // //             blurRadius: 20,
// // //             offset: const Offset(0, 8),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Row(
// // //             children: [
// // //               const Icon(Icons.account_balance_wallet_rounded,
// // //                   color: Colors.white70, size: 18),
// // //               const SizedBox(width: 6),
// // //               Text(
// // //                 isFrozen ? 'Wallet (Frozen)' : 'Available Balance',
// // //                 style: const TextStyle(
// // //                     color: Colors.white70, fontSize: 13,
// // //                     fontWeight: FontWeight.w500),
// // //               ),
// // //               if (isFrozen) ...[
// // //                 const SizedBox(width: 6),
// // //                 const Icon(Icons.lock_outline_rounded,
// // //                     color: Colors.white70, size: 16),
// // //               ],
// // //             ],
// // //           ),
// // //           const SizedBox(height: 12),
// // //           Text(
// // //             wallet.formattedBalance,
// // //             style: const TextStyle(
// // //               color: Colors.white,
// // //               fontSize: 36,
// // //               fontWeight: FontWeight.w800,
// // //               letterSpacing: -1,
// // //             ),
// // //           ),
// // //           const SizedBox(height: 4),
// // //           Text(
// // //             'Mauritanian Ouguiya',
// // //             style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ── Quick actions ─────────────────────────────────────────────────────────────
// // // class _QuickActions extends StatelessWidget {
// // //   const _QuickActions({required this.wallet});
// // //   final WalletProvider wallet;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Row(
// // //       children: [
// // //         Expanded(
// // //           child: _ActionButton(
// // //             icon:  Icons.add_rounded,
// // //             label: 'Deposit',
// // //             color: AppColors.successGreen,
// // //             onTap: wallet.isWalletFrozen ? null : () =>
// // //                 Navigator.push(
// // //                   context,
// // //                   MaterialPageRoute(
// // //                     builder: (_) => ChangeNotifierProvider.value(
// // //                       value: wallet,
// // //                       child: const DepositScreen(),
// // //                     ),
// // //                   ),
// // //                 ),
// // //           ),
// // //         ),
// // //         const SizedBox(width: 12),
// // //         Expanded(
// // //           child: _ActionButton(
// // //             icon:  Icons.arrow_upward_rounded,
// // //             label: 'Withdraw',
// // //             color: AppColors.navyBlue,
// // //             onTap: (wallet.isWalletFrozen ||
// // //                     wallet.balanceMru < 500) ? null : () =>
// // //                 Navigator.push(
// // //                   context,
// // //                   MaterialPageRoute(
// // //                     builder: (_) => ChangeNotifierProvider.value(
// // //                       value: wallet,
// // //                       child: const WithdrawalScreen(),
// // //                     ),
// // //                   ),
// // //                 ),
// // //           ),
// // //         ),
// // //         const SizedBox(width: 12),
// // //         Expanded(
// // //           child: _ActionButton(
// // //             icon:  Icons.bar_chart_rounded,
// // //             label: 'Earnings',
// // //             color: AppColors.amberOrangeLight,
// // //             onTap: () => Navigator.push(
// // //               context,
// // //               MaterialPageRoute(
// // //                 builder: (_) => ChangeNotifierProvider.value(
// // //                   value: wallet,
// // //                   child: const EarningsScreen(),
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // }

// // // class _ActionButton extends StatelessWidget {
// // //   const _ActionButton({
// // //     required this.icon,
// // //     required this.label,
// // //     required this.color,
// // //     required this.onTap,
// // //   });
// // //   final IconData icon;
// // //   final String label;
// // //   final Color color;
// // //   final VoidCallback? onTap;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final isDisabled = onTap == null;
// // //     final effectiveColor = isDisabled
// // //         ? context.colorScheme.onSurfaceVariant.withOpacity(0.4)
// // //         : color;

// // //     return GestureDetector(
// // //       onTap: onTap,
// // //       child: Container(
// // //         padding: const EdgeInsets.symmetric(vertical: 14),
// // //         decoration: BoxDecoration(
// // //           color:        effectiveColor.withOpacity(0.1),
// // //           borderRadius: BorderRadius.circular(14),
// // //           border: Border.all(color: effectiveColor.withOpacity(0.2)),
// // //         ),
// // //         child: Column(
// // //           children: [
// // //             Icon(icon, color: effectiveColor, size: 24),
// // //             const SizedBox(height: 4),
// // //             Text(label,
// // //                 style: TextStyle(
// // //                     color:      effectiveColor,
// // //                     fontSize:   12,
// // //                     fontWeight: FontWeight.w600)),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ── Pending section ───────────────────────────────────────────────────────────
// // // class _PendingSection extends StatelessWidget {
// // //   const _PendingSection({required this.wallet});
// // //   final WalletProvider wallet;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final pendingDeposits = wallet.myDeposits
// // //         .where((d) => d.isPending).toList();
// // //     final pendingWithdrawals = wallet.myWithdrawals
// // //         .where((w) => w.isPending).toList();

// // //     if (pendingDeposits.isEmpty && pendingWithdrawals.isEmpty) {
// // //       return const SizedBox.shrink();
// // //     }

// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text('Pending',
// // //             style: context.textTheme.titleMedium?.copyWith(
// // //                 fontWeight: FontWeight.w700)),
// // //         const SizedBox(height: 8),
// // //         ...pendingDeposits.map((d) => _PendingDepositTile(deposit: d)),
// // //         ...pendingWithdrawals.map((w) => _PendingWithdrawalTile(withdrawal: w)),
// // //         const SizedBox(height: 16),
// // //       ],
// // //     );
// // //   }
// // // }

// // // class _PendingDepositTile extends StatelessWidget {
// // //   const _PendingDepositTile({required this.deposit});
// // //   final DepositEntity deposit;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       margin: const EdgeInsets.only(bottom: 8),
// // //       padding: const EdgeInsets.all(12),
// // //       decoration: BoxDecoration(
// // //         color: AppColors.warningAmber.withOpacity(0.08),
// // //         borderRadius: BorderRadius.circular(12),
// // //         border: Border.all(color: AppColors.warningAmber.withOpacity(0.25)),
// // //       ),
// // //       child: Row(
// // //         children: [
// // //           const Icon(Icons.hourglass_top_rounded,
// // //               color: AppColors.warningAmber, size: 18),
// // //           const SizedBox(width: 10),
// // //           Expanded(
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 Text('Deposit ${deposit.formattedAmount}',
// // //                     style: const TextStyle(
// // //                         fontWeight: FontWeight.w600, fontSize: 13)),
// // //                 Text('${deposit.status.displayLabel} • ${deposit.paymentMethod}',
// // //                     style: context.textTheme.bodySmall?.copyWith(
// // //                         color: context.colorScheme.onSurfaceVariant)),
// // //               ],
// // //             ),
// // //           ),
// // //           Container(
// // //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // //             decoration: BoxDecoration(
// // //               color: AppColors.warningAmber.withOpacity(0.15),
// // //               borderRadius: BorderRadius.circular(6),
// // //             ),
// // //             child: Text(deposit.status.displayLabel,
// // //                 style: const TextStyle(
// // //                     fontSize: 11, fontWeight: FontWeight.w700,
// // //                     color: AppColors.warningAmber)),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _PendingWithdrawalTile extends StatelessWidget {
// // //   const _PendingWithdrawalTile({required this.withdrawal});
// // //   final WithdrawalEntity withdrawal;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       margin: const EdgeInsets.only(bottom: 8),
// // //       padding: const EdgeInsets.all(12),
// // //       decoration: BoxDecoration(
// // //         color: AppColors.infoBlue.withOpacity(0.07),
// // //         borderRadius: BorderRadius.circular(12),
// // //         border: Border.all(color: AppColors.infoBlue.withOpacity(0.2)),
// // //       ),
// // //       child: Row(
// // //         children: [
// // //           const Icon(Icons.schedule_rounded,
// // //               color: AppColors.infoBlue, size: 18),
// // //           const SizedBox(width: 10),
// // //           Expanded(
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 Text('Withdrawal ${withdrawal.formattedAmount}',
// // //                     style: const TextStyle(
// // //                         fontWeight: FontWeight.w600, fontSize: 13)),
// // //                 Text(withdrawal.status.displayLabel,
// // //                     style: context.textTheme.bodySmall?.copyWith(
// // //                         color: context.colorScheme.onSurfaceVariant)),
// // //               ],
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:provider/provider.dart';

// // import '../../../../core/extensions/context_ext.dart';
// // import '../../../../core/theme/app_colors.dart';
// // import '../../../../shared/widgets/cards/j_card.dart';
// // import '../../../../shared/widgets/feedback/error_view.dart';
// // import '../wallet_provider.dart';
// // import '../widgets/transaction_tile.dart';
// // import 'deposit_screen.dart';
// // import 'transaction_history_screen.dart';
// // import 'withdrawal_screen.dart';
// // import 'earnings_screen.dart';

// // /// Wallet home screen.
// // /// Shows: balance card, quick actions (deposit/withdraw), recent transactions.
// // class WalletHomeScreen extends StatefulWidget {
// //   const WalletHomeScreen({super.key});

// //   @override
// //   State<WalletHomeScreen> createState() => _WalletHomeScreenState();
// // }

// // class _WalletHomeScreenState extends State<WalletHomeScreen> {
// //   @override
// //   void initState() {
// //     super.initState();
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       final p = context.read<WalletProvider>();
// //       p.refreshWallet(); // always refresh balance on enter
// //       p.loadTransactions(reset: true);
// //       p.loadMyDeposits();
// //       p.loadMyWithdrawals();
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Wallet'),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.refresh_rounded),
// //             onPressed: () {
// //               context.read<WalletProvider>()
// //                 ..refreshWallet()
// //                 ..loadTransactions(reset: true);
// //             },
// //             tooltip: 'Refresh',
// //           ),
// //         ],
// //       ),
// //       body: Consumer<WalletProvider>(
// //         builder: (ctx, wallet, _) {
// //           if (wallet.isLoading && wallet.wallet == null) {
// //             return const Center(child: CircularProgressIndicator());
// //           }
// //           if (wallet.failure != null && wallet.wallet == null) {
// //             return ErrorView(
// //               message: wallet.failure!.message,
// //               onRetry: wallet.refreshWallet,
// //             );
// //           }

// //           return RefreshIndicator(
// //             onRefresh: () async {
// //               await wallet.refreshWallet();
// //               await wallet.loadTransactions(reset: true);
// //             },
// //             child: ListView(
// //               padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
// //               children: [
// //                 const SizedBox(height: 8),

// //                 // ── Balance card ─────────────────────────────────────────
// //                 _BalanceCard(
// //                   wallet: wallet,
// //                 ).animate().fadeIn().slideY(begin: -0.06, end: 0),

// //                 const SizedBox(height: 20),

// //                 // ── Quick actions ─────────────────────────────────────────
// //                 _QuickActions(wallet: wallet).animate(delay: 80.ms).fadeIn(),

// //                 const SizedBox(height: 24),

// //                 // ── Pending items ─────────────────────────────────────────
// //                 _PendingSection(wallet: wallet),

// //                 // ── Recent transactions ───────────────────────────────────
// //                 Row(
// //                   children: [
// //                     Text(
// //                       'Recent Transactions',
// //                       style: ctx.textTheme.titleMedium?.copyWith(
// //                         fontWeight: FontWeight.w700,
// //                       ),
// //                     ),
// //                     const Spacer(),
// //                     TextButton(
// //                       onPressed: () => Navigator.push(
// //                         ctx,
// //                         MaterialPageRoute(
// //                           builder: (_) => ChangeNotifierProvider.value(
// //                             value: wallet,
// //                             child: const TransactionHistoryScreen(),
// //                           ),
// //                         ),
// //                       ),
// //                       child: const Text('See all'),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 8),

// //                 if (wallet.transactions.isEmpty && !wallet.isLoading)
// //                   Padding(
// //                     padding: const EdgeInsets.symmetric(vertical: 24),
// //                     child: Center(
// //                       child: Text(
// //                         'No transactions yet',
// //                         style: ctx.textTheme.bodyMedium?.copyWith(
// //                           color: ctx.colorScheme.onSurfaceVariant,
// //                         ),
// //                       ),
// //                     ),
// //                   )
// //                 else
// //                   ...wallet.transactions
// //                       .take(5)
// //                       .map(
// //                         (tx) =>
// //                             TransactionTile(transaction: tx).animate().fadeIn(),
// //                       ),
// //               ],
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }

// // // ── Balance card ───────────────────────────────────────────────────────────────
// // class _BalanceCard extends StatelessWidget {
// //   const _BalanceCard({required this.wallet});
// //   final WalletProvider wallet;

// //   @override
// //   Widget build(BuildContext context) {
// //     final isFrozen = wallet.isWalletFrozen;

// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.all(24),
// //       decoration: BoxDecoration(
// //         gradient: isFrozen
// //             ? LinearGradient(
// //                 colors: [Colors.grey.shade600, Colors.grey.shade800],
// //               )
// //             : const LinearGradient(
// //                 colors: [AppColors.navyBlue, AppColors.navyBlueLight],
// //                 begin: Alignment.topLeft,
// //                 end: Alignment.bottomRight,
// //               ),
// //         borderRadius: BorderRadius.circular(20),
// //         boxShadow: [
// //           BoxShadow(
// //             color: (isFrozen ? Colors.grey : AppColors.navyBlue).withOpacity(
// //               0.25,
// //             ),
// //             blurRadius: 20,
// //             offset: const Offset(0, 8),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               const Icon(
// //                 Icons.account_balance_wallet_rounded,
// //                 color: Colors.white70,
// //                 size: 18,
// //               ),
// //               const SizedBox(width: 6),
// //               Text(
// //                 isFrozen ? 'Wallet (Frozen)' : 'Available Balance',
// //                 style: const TextStyle(
// //                   color: Colors.white70,
// //                   fontSize: 13,
// //                   fontWeight: FontWeight.w500,
// //                 ),
// //               ),
// //               if (isFrozen) ...[
// //                 const SizedBox(width: 6),
// //                 const Icon(
// //                   Icons.lock_outline_rounded,
// //                   color: Colors.white70,
// //                   size: 16,
// //                 ),
// //               ],
// //             ],
// //           ),
// //           const SizedBox(height: 12),
// //           Text(
// //             wallet.formattedBalance,
// //             style: const TextStyle(
// //               color: Colors.white,
// //               fontSize: 36,
// //               fontWeight: FontWeight.w800,
// //               letterSpacing: -1,
// //             ),
// //           ),
// //           const SizedBox(height: 4),
// //           Text(
// //             'Mauritanian Ouguiya',
// //             style: TextStyle(
// //               color: Colors.white.withOpacity(0.6),
// //               fontSize: 12,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // ── Quick actions ─────────────────────────────────────────────────────────────
// // class _QuickActions extends StatelessWidget {
// //   const _QuickActions({required this.wallet});
// //   final WalletProvider wallet;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Row(
// //       children: [
// //         Expanded(
// //           child: _ActionButton(
// //             icon: Icons.add_rounded,
// //             label: 'Deposit',
// //             color: AppColors.successGreen,
// //             onTap: wallet.isWalletFrozen
// //                 ? null
// //                 : () => Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder: (_) => ChangeNotifierProvider.value(
// //                         value: wallet,
// //                         child: const DepositScreen(),
// //                       ),
// //                     ),
// //                   ),
// //           ),
// //         ),
// //         const SizedBox(width: 12),
// //         Expanded(
// //           child: _ActionButton(
// //             icon: Icons.arrow_upward_rounded,
// //             label: 'Withdraw',
// //             color: AppColors.navyBlue,
// //             onTap: (wallet.isWalletFrozen || wallet.balanceMru < 500)
// //                 ? null
// //                 : () => Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder: (_) => ChangeNotifierProvider.value(
// //                         value: wallet,
// //                         child: const WithdrawalScreen(),
// //                       ),
// //                     ),
// //                   ),
// //           ),
// //         ),
// //         const SizedBox(width: 12),
// //         Expanded(
// //           child: _ActionButton(
// //             icon: Icons.bar_chart_rounded,
// //             label: 'Earnings',
// //             color: AppColors.amberOrangeLight,
// //             onTap: () => Navigator.push(
// //               context,
// //               MaterialPageRoute(
// //                 builder: (_) => ChangeNotifierProvider.value(
// //                   value: wallet,
// //                   child: const EarningsScreen(),
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }

// // class _ActionButton extends StatelessWidget {
// //   const _ActionButton({
// //     required this.icon,
// //     required this.label,
// //     required this.color,
// //     required this.onTap,
// //   });
// //   final IconData icon;
// //   final String label;
// //   final Color color;
// //   final VoidCallback? onTap;

// //   @override
// //   Widget build(BuildContext context) {
// //     final isDisabled = onTap == null;
// //     final effectiveColor = isDisabled
// //         ? context.colorScheme.onSurfaceVariant.withOpacity(0.4)
// //         : color;

// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         padding: const EdgeInsets.symmetric(vertical: 14),
// //         decoration: BoxDecoration(
// //           color: effectiveColor.withOpacity(0.1),
// //           borderRadius: BorderRadius.circular(14),
// //           border: Border.all(color: effectiveColor.withOpacity(0.2)),
// //         ),
// //         child: Column(
// //           children: [
// //             Icon(icon, color: effectiveColor, size: 24),
// //             const SizedBox(height: 4),
// //             Text(
// //               label,
// //               style: TextStyle(
// //                 color: effectiveColor,
// //                 fontSize: 12,
// //                 fontWeight: FontWeight.w600,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ── Pending section ───────────────────────────────────────────────────────────
// // class _PendingSection extends StatelessWidget {
// //   const _PendingSection({required this.wallet});
// //   final WalletProvider wallet;

// //   @override
// //   Widget build(BuildContext context) {
// //     final pendingDeposits = wallet.myDeposits
// //         .where((d) => d.isPending)
// //         .toList();
// //     final pendingWithdrawals = wallet.myWithdrawals
// //         .where((w) => w.isPending)
// //         .toList();

// //     if (pendingDeposits.isEmpty && pendingWithdrawals.isEmpty) {
// //       return const SizedBox.shrink();
// //     }

// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           'Pending',
// //           style: context.textTheme.titleMedium?.copyWith(
// //             fontWeight: FontWeight.w700,
// //           ),
// //         ),
// //         const SizedBox(height: 8),
// //         ...pendingDeposits.map((d) => _PendingDepositTile(deposit: d)),
// //         ...pendingWithdrawals.map((w) => _PendingWithdrawalTile(withdrawal: w)),
// //         const SizedBox(height: 16),
// //       ],
// //     );
// //   }
// // }

// // class _PendingDepositTile extends StatelessWidget {
// //   const _PendingDepositTile({required this.deposit});
// //   final DepositEntity deposit;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 8),
// //       padding: const EdgeInsets.all(12),
// //       decoration: BoxDecoration(
// //         color: AppColors.warningAmber.withOpacity(0.08),
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: AppColors.warningAmber.withOpacity(0.25)),
// //       ),
// //       child: Row(
// //         children: [
// //           const Icon(
// //             Icons.hourglass_top_rounded,
// //             color: AppColors.warningAmber,
// //             size: 18,
// //           ),
// //           const SizedBox(width: 10),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   'Deposit ${deposit.formattedAmount}',
// //                   style: const TextStyle(
// //                     fontWeight: FontWeight.w600,
// //                     fontSize: 13,
// //                   ),
// //                 ),
// //                 Text(
// //                   '${deposit.status.displayLabel} • ${deposit.paymentMethod}',
// //                   style: context.textTheme.bodySmall?.copyWith(
// //                     color: context.colorScheme.onSurfaceVariant,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           Container(
// //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// //             decoration: BoxDecoration(
// //               color: AppColors.warningAmber.withOpacity(0.15),
// //               borderRadius: BorderRadius.circular(6),
// //             ),
// //             child: Text(
// //               deposit.status.displayLabel,
// //               style: const TextStyle(
// //                 fontSize: 11,
// //                 fontWeight: FontWeight.w700,
// //                 color: AppColors.warningAmber,
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _PendingWithdrawalTile extends StatelessWidget {
// //   const _PendingWithdrawalTile({required this.withdrawal});
// //   final WithdrawalEntity withdrawal;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 8),
// //       padding: const EdgeInsets.all(12),
// //       decoration: BoxDecoration(
// //         color: AppColors.infoBlue.withOpacity(0.07),
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: AppColors.infoBlue.withOpacity(0.2)),
// //       ),
// //       child: Row(
// //         children: [
// //           const Icon(
// //             Icons.schedule_rounded,
// //             color: AppColors.infoBlue,
// //             size: 18,
// //           ),
// //           const SizedBox(width: 10),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   'Withdrawal ${withdrawal.formattedAmount}',
// //                   style: const TextStyle(
// //                     fontWeight: FontWeight.w600,
// //                     fontSize: 13,
// //                   ),
// //                 ),
// //                 Text(
// //                   withdrawal.status.displayLabel,
// //                   style: context.textTheme.bodySmall?.copyWith(
// //                     color: context.colorScheme.onSurfaceVariant,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:provider/provider.dart';

// // import '../../../../core/extensions/context_ext.dart';
// // import '../../../../core/theme/app_colors.dart';
// // import '../../../../shared/widgets/cards/j_card.dart';
// // import '../../../../shared/widgets/feedback/error_view.dart';
// // import '../wallet_provider.dart';
// // import '../widgets/transaction_tile.dart';
// // import 'deposit_screen.dart';
// // import 'transaction_history_screen.dart';
// // import 'withdrawal_screen.dart';
// // import 'earnings_screen.dart';

// // /// Wallet home screen.
// // /// Shows: balance card, quick actions (deposit/withdraw), recent transactions.
// // class WalletHomeScreen extends StatefulWidget {
// //   const WalletHomeScreen({super.key});

// //   @override
// //   State<WalletHomeScreen> createState() => _WalletHomeScreenState();
// // }

// // class _WalletHomeScreenState extends State<WalletHomeScreen> {
// //   @override
// //   void initState() {
// //     super.initState();
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       final p = context.read<WalletProvider>();
// //       p.loadTransactions(reset: true);
// //       p.loadMyDeposits();
// //       p.loadMyWithdrawals();
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Wallet'),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.refresh_rounded),
// //             onPressed: () {
// //               context.read<WalletProvider>()
// //                 ..refreshWallet()
// //                 ..loadTransactions(reset: true);
// //             },
// //             tooltip: 'Refresh',
// //           ),
// //         ],
// //       ),
// //       body: Consumer<WalletProvider>(
// //         builder: (ctx, wallet, _) {
// //           if (wallet.isLoading && wallet.wallet == null) {
// //             return const Center(child: CircularProgressIndicator());
// //           }
// //           if (wallet.failure != null && wallet.wallet == null) {
// //             return ErrorView(
// //               message: wallet.failure!.message,
// //               onRetry: wallet.refreshWallet,
// //             );
// //           }

// //           return RefreshIndicator(
// //             onRefresh: () async {
// //               await wallet.refreshWallet();
// //               await wallet.loadTransactions(reset: true);
// //             },
// //             child: ListView(
// //               padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
// //               children: [
// //                 const SizedBox(height: 8),

// //                 // ── Balance card ─────────────────────────────────────────
// //                 _BalanceCard(wallet: wallet)
// //                     .animate().fadeIn().slideY(begin: -0.06, end: 0),

// //                 const SizedBox(height: 20),

// //                 // ── Quick actions ─────────────────────────────────────────
// //                 _QuickActions(wallet: wallet)
// //                     .animate(delay: 80.ms).fadeIn(),

// //                 const SizedBox(height: 24),

// //                 // ── Pending items ─────────────────────────────────────────
// //                 _PendingSection(wallet: wallet),

// //                 // ── Recent transactions ───────────────────────────────────
// //                 Row(
// //                   children: [
// //                     Text('Recent Transactions',
// //                         style: ctx.textTheme.titleMedium?.copyWith(
// //                             fontWeight: FontWeight.w700)),
// //                     const Spacer(),
// //                     TextButton(
// //                       onPressed: () => Navigator.push(
// //                         ctx,
// //                         MaterialPageRoute(
// //                           builder: (_) =>
// //                               ChangeNotifierProvider.value(
// //                                 value: wallet,
// //                                 child: const TransactionHistoryScreen(),
// //                               ),
// //                         ),
// //                       ),
// //                       child: const Text('See all'),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 8),

// //                 if (wallet.transactions.isEmpty && !wallet.isLoading)
// //                   Padding(
// //                     padding: const EdgeInsets.symmetric(vertical: 24),
// //                     child: Center(
// //                       child: Text('No transactions yet',
// //                           style: ctx.textTheme.bodyMedium?.copyWith(
// //                               color: ctx.colorScheme.onSurfaceVariant)),
// //                     ),
// //                   )
// //                 else
// //                   ...wallet.transactions.take(5).map((tx) =>
// //                       TransactionTile(transaction: tx)
// //                           .animate().fadeIn()),
// //               ],
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }

// // // ── Balance card ───────────────────────────────────────────────────────────────
// // class _BalanceCard extends StatelessWidget {
// //   const _BalanceCard({required this.wallet});
// //   final WalletProvider wallet;

// //   @override
// //   Widget build(BuildContext context) {
// //     final isFrozen = wallet.isWalletFrozen;

// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.all(24),
// //       decoration: BoxDecoration(
// //         gradient: isFrozen
// //             ? LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade800])
// //             : const LinearGradient(
// //                 colors: [AppColors.navyBlue, AppColors.navyBlueLight],
// //                 begin: Alignment.topLeft,
// //                 end: Alignment.bottomRight,
// //               ),
// //         borderRadius: BorderRadius.circular(20),
// //         boxShadow: [
// //           BoxShadow(
// //             color:  (isFrozen ? Colors.grey : AppColors.navyBlue).withOpacity(0.25),
// //             blurRadius: 20,
// //             offset: const Offset(0, 8),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               const Icon(Icons.account_balance_wallet_rounded,
// //                   color: Colors.white70, size: 18),
// //               const SizedBox(width: 6),
// //               Text(
// //                 isFrozen ? 'Wallet (Frozen)' : 'Available Balance',
// //                 style: const TextStyle(
// //                     color: Colors.white70, fontSize: 13,
// //                     fontWeight: FontWeight.w500),
// //               ),
// //               if (isFrozen) ...[
// //                 const SizedBox(width: 6),
// //                 const Icon(Icons.lock_outline_rounded,
// //                     color: Colors.white70, size: 16),
// //               ],
// //             ],
// //           ),
// //           const SizedBox(height: 12),
// //           Text(
// //             wallet.formattedBalance,
// //             style: const TextStyle(
// //               color: Colors.white,
// //               fontSize: 36,
// //               fontWeight: FontWeight.w800,
// //               letterSpacing: -1,
// //             ),
// //           ),
// //           const SizedBox(height: 4),
// //           Text(
// //             'Mauritanian Ouguiya',
// //             style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // ── Quick actions ─────────────────────────────────────────────────────────────
// // class _QuickActions extends StatelessWidget {
// //   const _QuickActions({required this.wallet});
// //   final WalletProvider wallet;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Row(
// //       children: [
// //         Expanded(
// //           child: _ActionButton(
// //             icon:  Icons.add_rounded,
// //             label: 'Deposit',
// //             color: AppColors.successGreen,
// //             onTap: wallet.isWalletFrozen ? null : () =>
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (_) => ChangeNotifierProvider.value(
// //                       value: wallet,
// //                       child: const DepositScreen(),
// //                     ),
// //                   ),
// //                 ),
// //           ),
// //         ),
// //         const SizedBox(width: 12),
// //         Expanded(
// //           child: _ActionButton(
// //             icon:  Icons.arrow_upward_rounded,
// //             label: 'Withdraw',
// //             color: AppColors.navyBlue,
// //             onTap: (wallet.isWalletFrozen ||
// //                     wallet.balanceMru < 500) ? null : () =>
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (_) => ChangeNotifierProvider.value(
// //                       value: wallet,
// //                       child: const WithdrawalScreen(),
// //                     ),
// //                   ),
// //                 ),
// //           ),
// //         ),
// //         const SizedBox(width: 12),
// //         Expanded(
// //           child: _ActionButton(
// //             icon:  Icons.bar_chart_rounded,
// //             label: 'Earnings',
// //             color: AppColors.amberOrangeLight,
// //             onTap: () => Navigator.push(
// //               context,
// //               MaterialPageRoute(
// //                 builder: (_) => ChangeNotifierProvider.value(
// //                   value: wallet,
// //                   child: const EarningsScreen(),
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }

// // class _ActionButton extends StatelessWidget {
// //   const _ActionButton({
// //     required this.icon,
// //     required this.label,
// //     required this.color,
// //     required this.onTap,
// //   });
// //   final IconData icon;
// //   final String label;
// //   final Color color;
// //   final VoidCallback? onTap;

// //   @override
// //   Widget build(BuildContext context) {
// //     final isDisabled = onTap == null;
// //     final effectiveColor = isDisabled
// //         ? context.colorScheme.onSurfaceVariant.withOpacity(0.4)
// //         : color;

// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         padding: const EdgeInsets.symmetric(vertical: 14),
// //         decoration: BoxDecoration(
// //           color:        effectiveColor.withOpacity(0.1),
// //           borderRadius: BorderRadius.circular(14),
// //           border: Border.all(color: effectiveColor.withOpacity(0.2)),
// //         ),
// //         child: Column(
// //           children: [
// //             Icon(icon, color: effectiveColor, size: 24),
// //             const SizedBox(height: 4),
// //             Text(label,
// //                 style: TextStyle(
// //                     color:      effectiveColor,
// //                     fontSize:   12,
// //                     fontWeight: FontWeight.w600)),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ── Pending section ───────────────────────────────────────────────────────────
// // class _PendingSection extends StatelessWidget {
// //   const _PendingSection({required this.wallet});
// //   final WalletProvider wallet;

// //   @override
// //   Widget build(BuildContext context) {
// //     final pendingDeposits = wallet.myDeposits
// //         .where((d) => d.isPending).toList();
// //     final pendingWithdrawals = wallet.myWithdrawals
// //         .where((w) => w.isPending).toList();

// //     if (pendingDeposits.isEmpty && pendingWithdrawals.isEmpty) {
// //       return const SizedBox.shrink();
// //     }

// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text('Pending',
// //             style: context.textTheme.titleMedium?.copyWith(
// //                 fontWeight: FontWeight.w700)),
// //         const SizedBox(height: 8),
// //         ...pendingDeposits.map((d) => _PendingDepositTile(deposit: d)),
// //         ...pendingWithdrawals.map((w) => _PendingWithdrawalTile(withdrawal: w)),
// //         const SizedBox(height: 16),
// //       ],
// //     );
// //   }
// // }

// // class _PendingDepositTile extends StatelessWidget {
// //   const _PendingDepositTile({required this.deposit});
// //   final DepositEntity deposit;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 8),
// //       padding: const EdgeInsets.all(12),
// //       decoration: BoxDecoration(
// //         color: AppColors.warningAmber.withOpacity(0.08),
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: AppColors.warningAmber.withOpacity(0.25)),
// //       ),
// //       child: Row(
// //         children: [
// //           const Icon(Icons.hourglass_top_rounded,
// //               color: AppColors.warningAmber, size: 18),
// //           const SizedBox(width: 10),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text('Deposit ${deposit.formattedAmount}',
// //                     style: const TextStyle(
// //                         fontWeight: FontWeight.w600, fontSize: 13)),
// //                 Text('${deposit.status.displayLabel} • ${deposit.paymentMethod}',
// //                     style: context.textTheme.bodySmall?.copyWith(
// //                         color: context.colorScheme.onSurfaceVariant)),
// //               ],
// //             ),
// //           ),
// //           Container(
// //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// //             decoration: BoxDecoration(
// //               color: AppColors.warningAmber.withOpacity(0.15),
// //               borderRadius: BorderRadius.circular(6),
// //             ),
// //             child: Text(deposit.status.displayLabel,
// //                 style: const TextStyle(
// //                     fontSize: 11, fontWeight: FontWeight.w700,
// //                     color: AppColors.warningAmber)),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _PendingWithdrawalTile extends StatelessWidget {
// //   const _PendingWithdrawalTile({required this.withdrawal});
// //   final WithdrawalEntity withdrawal;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 8),
// //       padding: const EdgeInsets.all(12),
// //       decoration: BoxDecoration(
// //         color: AppColors.infoBlue.withOpacity(0.07),
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: AppColors.infoBlue.withOpacity(0.2)),
// //       ),
// //       child: Row(
// //         children: [
// //           const Icon(Icons.schedule_rounded,
// //               color: AppColors.infoBlue, size: 18),
// //           const SizedBox(width: 10),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text('Withdrawal ${withdrawal.formattedAmount}',
// //                     style: const TextStyle(
// //                         fontWeight: FontWeight.w600, fontSize: 13)),
// //                 Text(withdrawal.status.displayLabel,
// //                     style: context.textTheme.bodySmall?.copyWith(
// //                         color: context.colorScheme.onSurfaceVariant)),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/cards/j_card.dart';
// import '../../../../shared/widgets/feedback/error_view.dart';
// import '../wallet_provider.dart';
// import '../widgets/transaction_tile.dart';
// import 'deposit_screen.dart';
// import 'transaction_history_screen.dart';
// import 'withdrawal_screen.dart';
// import 'earnings_screen.dart';

// /// Wallet home screen.
// /// Shows: balance card, quick actions (deposit/withdraw), recent transactions.
// class WalletHomeScreen extends StatefulWidget {
//   const WalletHomeScreen({super.key});

//   @override
//   State<WalletHomeScreen> createState() => _WalletHomeScreenState();
// }

// class _WalletHomeScreenState extends State<WalletHomeScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final p = context.read<WalletProvider>();
//       p.refreshWallet(); // always refresh balance on enter
//       p.loadTransactions(reset: true);
//       p.loadMyDeposits();
//       p.loadMyWithdrawals();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Wallet'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh_rounded),
//             onPressed: () {
//               context.read<WalletProvider>()
//                 ..refreshWallet()
//                 ..loadTransactions(reset: true);
//             },
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: Consumer<WalletProvider>(
//         builder: (ctx, wallet, _) {
//           if (wallet.isLoading && wallet.wallet == null) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (wallet.failure != null && wallet.wallet == null) {
//             return ErrorView(
//               message: wallet.failure!.message,
//               onRetry: wallet.refreshWallet,
//             );
//           }

//           return RefreshIndicator(
//             onRefresh: () async {
//               await wallet.refreshWallet();
//               await wallet.loadTransactions(reset: true);
//             },
//             child: ListView(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
//               children: [
//                 const SizedBox(height: 8),

//                 // ── Balance card ─────────────────────────────────────────
//                 _BalanceCard(
//                   wallet: wallet,
//                 ).animate().fadeIn().slideY(begin: -0.06, end: 0),

//                 const SizedBox(height: 20),

//                 // ── Quick actions ─────────────────────────────────────────
//                 _QuickActions(wallet: wallet).animate(delay: 80.ms).fadeIn(),

//                 const SizedBox(height: 24),

//                 // ── Pending items ─────────────────────────────────────────
//                 _PendingSection(wallet: wallet),

//                 // ── Recent transactions ───────────────────────────────────
//                 Row(
//                   children: [
//                     Text(
//                       'Recent Transactions',
//                       style: ctx.textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const Spacer(),
//                     TextButton(
//                       onPressed: () => Navigator.push(
//                         ctx,
//                         MaterialPageRoute(
//                           builder: (_) => ChangeNotifierProvider.value(
//                             value: wallet,
//                             child: const TransactionHistoryScreen(),
//                           ),
//                         ),
//                       ),
//                       child: const Text('See all'),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),

//                 if (wallet.transactions.isEmpty && !wallet.isLoading)
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 24),
//                     child: Center(
//                       child: Text(
//                         'No transactions yet',
//                         style: ctx.textTheme.bodyMedium?.copyWith(
//                           color: ctx.colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                     ),
//                   )
//                 else
//                   ...wallet.transactions
//                       .take(5)
//                       .map(
//                         (tx) =>
//                             TransactionTile(transaction: tx).animate().fadeIn(),
//                       ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // ── Balance card ───────────────────────────────────────────────────────────────
// class _BalanceCard extends StatelessWidget {
//   const _BalanceCard({required this.wallet});
//   final WalletProvider wallet;

//   @override
//   Widget build(BuildContext context) {
//     final isFrozen = wallet.isWalletFrozen;

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         gradient: isFrozen
//             ? LinearGradient(
//                 colors: [Colors.grey.shade600, Colors.grey.shade800],
//               )
//             : const LinearGradient(
//                 colors: [AppColors.navyBlue, AppColors.navyBlueLight],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: (isFrozen ? Colors.grey : AppColors.navyBlue).withOpacity(
//               0.25,
//             ),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(
//                 Icons.account_balance_wallet_rounded,
//                 color: Colors.white70,
//                 size: 18,
//               ),
//               const SizedBox(width: 6),
//               Text(
//                 isFrozen ? 'Wallet (Frozen)' : 'Available Balance',
//                 style: const TextStyle(
//                   color: Colors.white70,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               if (isFrozen) ...[
//                 const SizedBox(width: 6),
//                 const Icon(
//                   Icons.lock_outline_rounded,
//                   color: Colors.white70,
//                   size: 16,
//                 ),
//               ],
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             wallet.formattedBalance,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 36,
//               fontWeight: FontWeight.w800,
//               letterSpacing: -1,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Mauritanian Ouguiya',
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.6),
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Quick actions ─────────────────────────────────────────────────────────────
// class _QuickActions extends StatelessWidget {
//   const _QuickActions({required this.wallet});
//   final WalletProvider wallet;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: _ActionButton(
//             icon: Icons.add_rounded,
//             label: 'Deposit',
//             color: AppColors.successGreen,
//             onTap: wallet.isWalletFrozen
//                 ? null
//                 : () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => ChangeNotifierProvider.value(
//                         value: wallet,
//                         child: const DepositScreen(),
//                       ),
//                     ),
//                   ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _ActionButton(
//             icon: Icons.arrow_upward_rounded,
//             label: 'Withdraw',
//             color: AppColors.navyBlue,
//             onTap: (wallet.isWalletFrozen || wallet.balanceMru < 500)
//                 ? null
//                 : () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => ChangeNotifierProvider.value(
//                         value: wallet,
//                         child: const WithdrawalScreen(),
//                       ),
//                     ),
//                   ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _ActionButton(
//             icon: Icons.bar_chart_rounded,
//             label: 'Earnings',
//             color: AppColors.amberOrangeLight,
//             onTap: () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => ChangeNotifierProvider.value(
//                   value: wallet,
//                   child: const EarningsScreen(),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _ActionButton extends StatelessWidget {
//   const _ActionButton({
//     required this.icon,
//     required this.label,
//     required this.color,
//     required this.onTap,
//   });
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     final isDisabled = onTap == null;
//     final effectiveColor = isDisabled
//         ? context.colorScheme.onSurfaceVariant.withOpacity(0.4)
//         : color;

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 14),
//         decoration: BoxDecoration(
//           color: effectiveColor.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: effectiveColor.withOpacity(0.2)),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, color: effectiveColor, size: 24),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 color: effectiveColor,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Pending section ───────────────────────────────────────────────────────────
// class _PendingSection extends StatelessWidget {
//   const _PendingSection({required this.wallet});
//   final WalletProvider wallet;

//   @override
//   Widget build(BuildContext context) {
//     final pendingDeposits = wallet.myDeposits
//         .where((d) => d.isPending)
//         .toList();
//     final pendingWithdrawals = wallet.myWithdrawals
//         .where((w) => w.isPending)
//         .toList();

//     if (pendingDeposits.isEmpty && pendingWithdrawals.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Pending',
//           style: context.textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         const SizedBox(height: 8),
//         ...pendingDeposits.map((d) => _PendingDepositTile(deposit: d)),
//         ...pendingWithdrawals.map((w) => _PendingWithdrawalTile(withdrawal: w)),
//         const SizedBox(height: 16),
//       ],
//     );
//   }
// }

// class _PendingDepositTile extends StatelessWidget {
//   const _PendingDepositTile({required this.deposit});
//   final DepositEntity deposit;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: AppColors.warningAmber.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.warningAmber.withOpacity(0.25)),
//       ),
//       child: Row(
//         children: [
//           const Icon(
//             Icons.hourglass_top_rounded,
//             color: AppColors.warningAmber,
//             size: 18,
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Deposit ${deposit.formattedAmount}',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 13,
//                   ),
//                 ),
//                 Text(
//                   '${deposit.status.displayLabel} • ${deposit.paymentMethod}',
//                   style: context.textTheme.bodySmall?.copyWith(
//                     color: context.colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//             decoration: BoxDecoration(
//               color: AppColors.warningAmber.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: Text(
//               deposit.status.displayLabel,
//               style: const TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w700,
//                 color: AppColors.warningAmber,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PendingWithdrawalTile extends StatelessWidget {
//   const _PendingWithdrawalTile({required this.withdrawal});
//   final WithdrawalEntity withdrawal;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: AppColors.infoBlue.withOpacity(0.07),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.infoBlue.withOpacity(0.2)),
//       ),
//       child: Row(
//         children: [
//           const Icon(
//             Icons.schedule_rounded,
//             color: AppColors.infoBlue,
//             size: 18,
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Withdrawal ${withdrawal.formattedAmount}',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 13,
//                   ),
//                 ),
//                 Text(
//                   withdrawal.status.displayLabel,
//                   style: context.textTheme.bodySmall?.copyWith(
//                     color: context.colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../wallet_provider.dart';
import '../widgets/transaction_tile.dart';
import 'deposit_screen.dart';
import 'transaction_history_screen.dart';
import 'withdrawal_screen.dart';
import 'earnings_screen.dart';

/// Wallet home screen.
/// Shows: balance card, quick actions (deposit/withdraw), recent transactions.
class WalletHomeScreen extends StatefulWidget {
  const WalletHomeScreen({super.key});

  @override
  State<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

class _WalletHomeScreenState extends State<WalletHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<WalletProvider>();
      await p.refreshWallet(); // always refresh balance on enter
      if (mounted) {
        p.loadTransactions(reset: true);
        p.loadMyDeposits();
        p.loadMyWithdrawals();
        p.loadEarnings(); // load earnings so wallet shows real data
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<WalletProvider>()
                ..refreshWallet()
                ..loadTransactions(reset: true);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (ctx, wallet, _) {
          if (wallet.isLoading && wallet.wallet == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (wallet.failure != null && wallet.wallet == null) {
            return ErrorView(
              message: wallet.failure!.message,
              onRetry: wallet.refreshWallet,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await wallet.refreshWallet();
              await wallet.loadTransactions(reset: true);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                const SizedBox(height: 8),

                // ── Balance card ─────────────────────────────────────────
                _BalanceCard(
                  wallet: wallet,
                ).animate().fadeIn().slideY(begin: -0.06, end: 0),

                const SizedBox(height: 20),

                // ── Quick actions ─────────────────────────────────────────
                _QuickActions(wallet: wallet).animate(delay: 80.ms).fadeIn(),

                const SizedBox(height: 24),

                // ── Pending items ─────────────────────────────────────────
                _PendingSection(wallet: wallet),

                // ── Recent transactions ───────────────────────────────────
                Row(
                  children: [
                    Text(
                      'Recent Transactions',
                      style: ctx.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: wallet,
                            child: const TransactionHistoryScreen(),
                          ),
                        ),
                      ),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (wallet.transactions.isEmpty && !wallet.isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No transactions yet',
                        style: ctx.textTheme.bodyMedium?.copyWith(
                          color: ctx.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ...wallet.transactions
                      .take(5)
                      .map(
                        (tx) =>
                            TransactionTile(transaction: tx).animate().fadeIn(),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Balance card ───────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.wallet});
  final WalletProvider wallet;

  @override
  Widget build(BuildContext context) {
    final isFrozen = wallet.isWalletFrozen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isFrozen
            ? LinearGradient(
                colors: [Colors.grey.shade600, Colors.grey.shade800],
              )
            : const LinearGradient(
                colors: [AppColors.navyBlue, AppColors.navyBlueLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isFrozen ? Colors.grey : AppColors.navyBlue).withOpacity(
              0.25,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isFrozen ? 'Wallet (Frozen)' : 'Available Balance',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isFrozen) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            wallet.formattedBalance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mauritanian Ouguiya',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.wallet});
  final WalletProvider wallet;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.add_rounded,
            label: 'Deposit',
            color: AppColors.successGreen,
            onTap: wallet.isWalletFrozen
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: wallet,
                        child: const DepositScreen(),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.arrow_upward_rounded,
            label: 'Withdraw',
            color: AppColors.navyBlue,
            onTap: (wallet.isWalletFrozen || wallet.balanceMru < 500)
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: wallet,
                        child: const WithdrawalScreen(),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.bar_chart_rounded,
            label: 'Earnings',
            color: AppColors.amberOrangeLight,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: wallet,
                  child: const EarningsScreen(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final effectiveColor = isDisabled
        ? context.colorScheme.onSurfaceVariant.withOpacity(0.4)
        : color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: effectiveColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: effectiveColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pending section ───────────────────────────────────────────────────────────
class _PendingSection extends StatelessWidget {
  const _PendingSection({required this.wallet});
  final WalletProvider wallet;

  @override
  Widget build(BuildContext context) {
    final pendingDeposits = wallet.myDeposits
        .where((d) => d.isPending)
        .toList();
    final pendingWithdrawals = wallet.myWithdrawals
        .where((w) => w.isPending)
        .toList();

    if (pendingDeposits.isEmpty && pendingWithdrawals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...pendingDeposits.map((d) => _PendingDepositTile(deposit: d)),
        ...pendingWithdrawals.map((w) => _PendingWithdrawalTile(withdrawal: w)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PendingDepositTile extends StatelessWidget {
  const _PendingDepositTile({required this.deposit});
  final DepositEntity deposit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningAmber.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            color: AppColors.warningAmber,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deposit ${deposit.formattedAmount}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${deposit.status.displayLabel} • ${deposit.paymentMethod}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.warningAmber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              deposit.status.displayLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.warningAmber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingWithdrawalTile extends StatelessWidget {
  const _PendingWithdrawalTile({required this.withdrawal});
  final WithdrawalEntity withdrawal;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoBlue.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.infoBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: AppColors.infoBlue,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdrawal ${withdrawal.formattedAmount}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  withdrawal.status.displayLabel,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
