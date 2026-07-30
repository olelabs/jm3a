import 'package:flutter/material.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/wallet_repository.dart';

/// Opens a modern detail sheet for a single transaction — matches the
/// DraggableScrollableSheet convention already used across the app (e.g.
/// showGameRulesSheet) for style/spacing consistency.
Future<void> showTransactionDetailSheet(
  BuildContext context,
  WalletTransaction transaction,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => TransactionDetailSheet(
        transaction: transaction,
        scrollController: scrollController,
      ),
    ),
  );
}

class TransactionDetailSheet extends StatefulWidget {
  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    this.scrollController,
  });

  final WalletTransaction transaction;
  final ScrollController? scrollController;

  @override
  State<TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  String? _paymentMethod;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethod();
  }

  Future<void> _loadPaymentMethod() async {
    try {
      final method = await WalletRepository.instance
          .getPaymentMethodForTransaction(
            widget.transaction.id,
            widget.transaction.type,
          );
      if (mounted && method != null) setState(() => _paymentMethod = method);
    } catch (_) {
      // Best-effort only — the sheet already works without this row.
    }
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} at $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final tx = widget.transaction;
    final credit = tx.isCredit;
    final color = credit ? AppColors.successGreen : AppColors.errorRed;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: ListView(
        controller: widget.scrollController,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(tx.type.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.type.displayLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      tx.status.displayLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                tx.formattedAmount,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 8),

          _DetailRow(label: 'Date & time', value: _formatDateTime(tx.createdAt)),
          _DetailRow(
            label: 'Wallet affected',
            value: tx.balanceType == 'earnings' ? 'Earnings' : 'Wallet Balance',
          ),
          _DetailRow(label: 'Balance after', value: tx.formattedBalance),
          if (_paymentMethod != null)
            _DetailRow(
              label: 'Payment method',
              value: _paymentMethod!.toUpperCase(),
            ),
          if (tx.description != null && tx.description!.isNotEmpty)
            _DetailRow(label: 'Description', value: tx.description!),
          if (tx.referenceId != null)
            _DetailRow(label: 'Reference', value: tx.referenceId!, mono: true),
          _DetailRow(label: 'Transaction ID', value: tx.id, mono: true),
        ],
      ),
    );
  }
}

/// One optional detail line — skipped entirely when [value] is null/empty
/// so this sheet gracefully grows as more fields become available later.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.mono = false});
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
