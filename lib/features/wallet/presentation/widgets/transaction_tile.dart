import 'package:flutter/material.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../wallet_provider.dart';

// ── Transaction tile ──────────────────────────────────────────────────────────

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});
  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final tx     = transaction;
    final theme  = context.theme;
    final credit = tx.isCredit;
    final color  = credit ? AppColors.successGreen : AppColors.errorRed;
    final isTerminal = tx.status.isTerminal;
    final isPending  = tx.status.isPending;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Type icon
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:  color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(tx.type.emoji,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.type.displayLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Text(
                      _formatDate(tx.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    if (isPending) ...[
                      const SizedBox(width: 6),
                      _StatusBadge(
                          label: tx.status.displayLabel,
                          color: AppColors.warningAmber),
                    ] else if (tx.status == TransactionStatus.failed ||
                        tx.status == TransactionStatus.cancelled) ...[
                      const SizedBox(width: 6),
                      _StatusBadge(
                          label: tx.status.displayLabel,
                          color: AppColors.errorRed),
                    ],
                  ],
                ),
                if (tx.description != null)
                  Text(tx.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tx.formattedAmount,
                style: TextStyle(
                  color:      isTerminal && tx.status != TransactionStatus.completed
                      ? theme.colorScheme.onSurfaceVariant
                      : color,
                  fontWeight: FontWeight.w700,
                  fontSize:   15,
                  decoration: tx.status == TransactionStatus.reversed
                      ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(tx.formattedBalance,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Today $h:$m';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7)  return '${diff.inDays}d ago';

    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Payment method card ───────────────────────────────────────────────────────

class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({
    super.key,
    required this.method,
    this.onTap,
    this.showArrow = false,
    this.compact   = false,
    this.isSelected = false,
  });

  final PaymentMethodEntity method;
  final VoidCallback?       onTap;
  final bool                showArrow;
  final bool                compact;
  final bool                isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:        theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MethodIcon(method: method, size: 28),
            const SizedBox(width: 8),
            Text(method.name,
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:  isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            _MethodIcon(method: method, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700)),
                  if (method.accountNumber != null)
                    Text(method.accountNumber!,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (showArrow)
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.successGreen),
          ],
        ),
      ),
    );
  }
}

class _MethodIcon extends StatelessWidget {
  const _MethodIcon({required this.method, required this.size});
  final PaymentMethodEntity method;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (method.logoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          method.logoUrl!,
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackIcon(size: size),
        ),
      );
    }
    return _FallbackIcon(size: size);
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color:        AppColors.navyBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.account_balance_outlined,
          size: size * 0.55, color: AppColors.navyBlue),
    );
  }
}
