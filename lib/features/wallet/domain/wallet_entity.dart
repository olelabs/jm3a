import 'package:equatable/equatable.dart';

/// ============================================================
/// Wallet Domain Layer
/// All monetary values stored as integer MRU (Mauritanian Ouguiya).
/// This eliminates floating-point rounding errors entirely.
/// 1 MRU = smallest unit of account (no sub-units used here).
/// ============================================================

// ── Transaction type ──────────────────────────────────────────────────────────

enum TransactionType {
  deposit, withdrawal, purchase, refund,
  commission, payout, adjustment, bonus, transfer;

  static TransactionType fromString(String s) => switch (s) {
    'withdrawal'  => withdrawal,
    'purchase'    => purchase,
    'refund'      => refund,
    'commission'  => commission,
    'payout'      => payout,
    'adjustment'  => adjustment,
    'bonus'       => bonus,
    'transfer'    => transfer,
    _             => deposit,
  };

  String get displayLabel => switch (this) {
    deposit    => 'Deposit',
    withdrawal => 'Withdrawal',
    purchase   => 'Pack Purchase',
    refund     => 'Refund',
    commission => 'Creator Earnings',
    payout     => 'Payout',
    adjustment => 'Adjustment',
    bonus      => 'Bonus',
    transfer   => 'Balance Transfer',
  };

  bool get isCredit => this == deposit || this == refund ||
      this == commission || this == bonus || this == adjustment;
  bool get isDebit => !isCredit;

  String get emoji => switch (this) {
    deposit    => '💳',
    withdrawal => '💸',
    purchase   => '🛒',
    refund     => '↩️',
    commission => '💰',
    payout     => '🏦',
    adjustment => '⚙️',
    bonus      => '🎁',
    transfer   => '🔄',
  };
}

// ── Transaction status ────────────────────────────────────────────────────────

enum TransactionStatus {
  pending, processing, completed, failed, cancelled, reversed;

  static TransactionStatus fromString(String s) => switch (s) {
    'processing' => processing,
    'completed'  => completed,
    'failed'     => failed,
    'cancelled'  => cancelled,
    'reversed'   => reversed,
    _            => pending,
  };

  bool get isTerminal => this == completed || this == failed ||
      this == cancelled || this == reversed;
  bool get isPending  => this == pending || this == processing;

  String get displayLabel => switch (this) {
    pending    => 'Pending',
    processing => 'Processing',
    completed  => 'Completed',
    failed     => 'Failed',
    cancelled  => 'Cancelled',
    reversed   => 'Reversed',
  };
}

// ── Payment method type ───────────────────────────────────────────────────────

enum PaymentMethodType {
  bankily, masrivi, sedad, bimbank, cash, other;

  static PaymentMethodType fromString(String s) => switch (s) {
    'masrivi' => masrivi,
    'sedad'   => sedad,
    'bimbank' => bimbank,
    'cash'    => cash,
    'other'   => other,
    _         => bankily,
  };

  String get displayName => switch (this) {
    bankily  => 'Bankily',
    masrivi  => 'Masrivi',
    sedad    => 'Sedad',
    bimbank  => 'BimBank',
    cash     => 'Cash',
    other    => 'Other',
  };
}

// ── Deposit status ────────────────────────────────────────────────────────────

enum DepositStatus {
  pending, underReview, approved, rejected;

  static DepositStatus fromString(String s) => switch (s) {
    'under_review' => underReview,
    'approved'     => approved,
    'rejected'     => rejected,
    _              => pending,
  };

  String get displayLabel => switch (this) {
    pending     => 'Pending',
    underReview => 'Under Review',
    approved    => 'Approved',
    rejected    => 'Rejected',
  };

  bool get isTerminal => this == approved || this == rejected;
}

// ── Wallet entity ─────────────────────────────────────────────────────────────

class WalletEntity extends Equatable {
  const WalletEntity({
    required this.id,
    required this.userId,
    required this.balanceMru,
    this.earningsBalanceMru = 0,
    this.isFrozen = false,
    this.updatedAt,
  });

  final String    id;
  final String    userId;
  /// Spendable balance — deposits + manually transferred earnings. The
  /// ONLY balance used for buying packs, creating rooms, Premium, or any
  /// in-app payment.
  final int       balanceMru;
  /// Creator earnings, commissions, rewards. Withdrawals draw ONLY from
  /// here. Never auto-transferred to [balanceMru] — the user must
  /// explicitly transfer via [WalletRepository.transferEarningsToWallet].
  final int       earningsBalanceMru;
  final bool      isFrozen;
  final DateTime? updatedAt;

  String get formattedBalance => '${_formatMru(balanceMru)} MRU';
  String get formattedEarningsBalance => '${_formatMru(earningsBalanceMru)} MRU';

  bool canDebit(int amountMru) =>
      !isFrozen && balanceMru >= amountMru;

  WalletEntity copyWith({
    int? balanceMru,
    int? earningsBalanceMru,
    bool? isFrozen,
  }) => WalletEntity(
    id:                 id,
    userId:             userId,
    balanceMru:         balanceMru ?? this.balanceMru,
    earningsBalanceMru: earningsBalanceMru ?? this.earningsBalanceMru,
    isFrozen:           isFrozen ?? this.isFrozen,
    updatedAt:          updatedAt,
  );

  @override
  List<Object?> get props => [id, userId, balanceMru, earningsBalanceMru, isFrozen];
}

// ── Transaction entity ────────────────────────────────────────────────────────

class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.status,
    required this.amountMru,
    required this.balanceBefore,
    required this.balanceAfter,
    this.description,
    this.referenceId,
    this.idempotencyKey,
    required this.createdAt,
    this.balanceType = 'wallet',
  });

  final String            id;
  final String            walletId;
  final TransactionType   type;
  final TransactionStatus status;
  final int               amountMru;     // positive = credit, negative = debit
  final int               balanceBefore;
  final int               balanceAfter;
  final String?           description;
  final String?           referenceId;
  final String?           idempotencyKey;
  final DateTime          createdAt;
  final String            balanceType; // 'wallet' | 'earnings'

  bool get isCredit    => amountMru > 0;
  bool get isDebit     => amountMru < 0;
  int  get absAmount   => amountMru.abs();
  String get formattedAmount =>
      '${isCredit ? '+' : '-'}${_formatMru(absAmount)} MRU';
  String get formattedBalance => '${_formatMru(balanceAfter)} MRU';

  @override
  List<Object?> get props => [id, walletId, amountMru, createdAt];
}

// ── Deposit entity ────────────────────────────────────────────────────────────

class DepositEntity extends Equatable {
  const DepositEntity({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.amountMru,
    required this.paymentMethod,
    this.paymentReference,
    required this.status,
    this.rejectedReason,
    required this.submittedAt,
    this.approvedAt,
    this.rejectedAt,
  });

  final String        id;
  final String        walletId;
  final String        userId;
  final int           amountMru;
  final String        paymentMethod;
  final String?       paymentReference;
  final DepositStatus status;
  final String?       rejectedReason;
  final DateTime      submittedAt;
  final DateTime?     approvedAt;
  final DateTime?     rejectedAt;

  String get formattedAmount => '${_formatMru(amountMru)} MRU';
  bool   get isPending  => !status.isTerminal;

  @override
  List<Object?> get props => [id, amountMru, status];
}

// ── Withdrawal entity ─────────────────────────────────────────────────────────

class WithdrawalEntity extends Equatable {
  const WithdrawalEntity({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.amountMru,
    required this.payoutMethod,
    required this.payoutDetails,
    required this.status,
    this.rejectedReason,
    required this.submittedAt,
    this.processedAt,
  });

  final String                id;
  final String                walletId;
  final String                userId;
  final int                   amountMru;
  final String                payoutMethod;
  final Map<String, dynamic>  payoutDetails;
  final TransactionStatus     status;
  final String?               rejectedReason;
  final DateTime              submittedAt;
  final DateTime?             processedAt;

  String get formattedAmount => '${_formatMru(amountMru)} MRU';
  bool   get isPending  => status.isPending;

  @override
  List<Object?> get props => [id, amountMru, status];
}

// ── Payment method entity (dynamic, admin-managed) ────────────────────────────

class PaymentMethodEntity extends Equatable {
  const PaymentMethodEntity({
    required this.id,
    required this.type,
    required this.name,
    this.logoUrl,
    this.accountNumber,
    this.accountName,
    this.instructions,
    this.isActive = true,
    this.supportsDeposit = true,
    this.supportsWithdrawal = true,
    this.minAmountMru,
    this.maxAmountMru,
    this.sortOrder = 0,
  });

  final String  id;
  final String  type;    // maps to PaymentMethodType
  final String  name;
  final String? logoUrl;
  final String? accountNumber;
  final String? accountName;
  final String? instructions;
  final bool    isActive;
  final bool    supportsDeposit;
  final bool    supportsWithdrawal;
  final int?    minAmountMru;
  final int?    maxAmountMru;
  final int     sortOrder;

  @override
  List<Object?> get props => [id, type, name, isActive];
}

// ── Earnings summary (creator dashboard) ─────────────────────────────────────

class EarningsSummary extends Equatable {
  const EarningsSummary({
    required this.totalEarnedMru,
    required this.pendingEarningsMru,
    required this.availableForWithdrawalMru,
    required this.totalSales,
    required this.thisMonthMru,
    required this.commissionRate,
  });

  final int    totalEarnedMru;
  final int    pendingEarningsMru;
  final int    availableForWithdrawalMru;
  final int    totalSales;
  final int    thisMonthMru;
  final double commissionRate;

  String get formatted       => '${_formatMru(totalEarnedMru)} MRU';
  String get pendingFormatted => '${_formatMru(pendingEarningsMru)} MRU';
  String get availableFormatted => '${_formatMru(availableForWithdrawalMru)} MRU';
  String get thisMonthFormatted => '${_formatMru(thisMonthMru)} MRU';

  @override
  List<Object?> get props => [totalEarnedMru, pendingEarningsMru, totalSales];
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Format integer MRU with thousands separator.
String _formatMru(int mru) {
  final s = mru.toString();
  final result = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
    result.write(s[i]);
  }
  return result.toString();
}
