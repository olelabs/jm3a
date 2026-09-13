// Regression coverage for item 7 — Wallet localization. Root cause: every
// wallet amount-formatting getter (WalletEntity.formattedBalance,
// WalletTransaction.formattedAmount/formattedBalance,
// DepositEntity/WithdrawalEntity.formattedAmount,
// EarningsSummary.formatted/pendingFormatted/availableFormatted/
// thisMonthFormatted) hardcoded the raw "MRU" currency code directly into
// the returned string, with no way for a caller to supply a localized
// display name — so Arabic always showed the Latin-script "MRU" instead of
// "أوقية". Fixed by turning each getter into a method taking an optional
// currency label (default 'MRU', preserving any unmigrated call site's
// exact prior output), with every real UI call site now passing
// `context.l10n.walletCurrencyShort`.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/wallet/domain/wallet_entity.dart';

void main() {
  group('WalletEntity — currency label is a parameter, not hardcoded', () {
    const wallet = WalletEntity(
      id: 'w1',
      userId: 'u1',
      balanceMru: 1500,
      earningsBalanceMru: 2000,
    );

    test('defaults to the raw "MRU" code when no currency is supplied '
        '(backward compatible with any unmigrated call site)', () {
      expect(wallet.formattedBalance(), '1,500 MRU');
      expect(wallet.formattedEarningsBalance(), '2,000 MRU');
    });

    test('uses the supplied localized currency label instead', () {
      expect(wallet.formattedBalance('أوقية'), '1,500 أوقية');
      expect(wallet.formattedEarningsBalance('أوقية'), '2,000 أوقية');
    });
  });

  group('WalletTransaction — amount and balance-after both localize', () {
    final credit = WalletTransaction(
      id: 't1',
      walletId: 'w1',
      type: TransactionType.deposit,
      status: TransactionStatus.completed,
      amountMru: 500,
      balanceBefore: 1000,
      balanceAfter: 1500,
      createdAt: DateTime(2026),
    );
    final debit = WalletTransaction(
      id: 't2',
      walletId: 'w1',
      type: TransactionType.purchase,
      status: TransactionStatus.completed,
      amountMru: -500,
      balanceBefore: 1000,
      balanceAfter: 500,
      createdAt: DateTime(2026),
    );

    test('credit is prefixed with + and uses the supplied currency', () {
      expect(credit.formattedAmount('أوقية'), '+500 أوقية');
      expect(credit.formattedBalance('أوقية'), '1,500 أوقية');
    });

    test('debit is prefixed with - and uses the supplied currency', () {
      expect(debit.formattedAmount('أوقية'), '-500 أوقية');
    });

    test('defaults to MRU when nothing is supplied', () {
      expect(credit.formattedAmount(), '+500 MRU');
    });
  });

  group('DepositEntity / WithdrawalEntity', () {
    final deposit = DepositEntity(
      id: 'd1',
      walletId: 'w1',
      userId: 'u1',
      amountMru: 2500,
      paymentMethod: 'bankily',
      status: DepositStatus.pending,
      submittedAt: DateTime(2026),
    );
    final withdrawal = WithdrawalEntity(
      id: 'wd1',
      walletId: 'w1',
      userId: 'u1',
      amountMru: 800,
      payoutMethod: 'bankily',
      payoutDetails: const {},
      status: TransactionStatus.pending,
      submittedAt: DateTime(2026),
    );

    test('both localize their formatted amount', () {
      expect(deposit.formattedAmount('أوقية'), '2,500 أوقية');
      expect(withdrawal.formattedAmount('أوقية'), '800 أوقية');
    });

    test('both default to MRU', () {
      expect(deposit.formattedAmount(), '2,500 MRU');
      expect(withdrawal.formattedAmount(), '800 MRU');
    });
  });

  group('EarningsSummary — every formatted stat localizes independently', () {
    const earnings = EarningsSummary(
      totalEarnedMru: 10000,
      pendingEarningsMru: 1200,
      availableForWithdrawalMru: 8800,
      totalSales: 42,
      thisMonthMru: 3000,
      commissionRate: 0.85,
    );

    test('localized currency applies to all four stats', () {
      expect(earnings.formatted('أوقية'), '10,000 أوقية');
      expect(earnings.pendingFormatted('أوقية'), '1,200 أوقية');
      expect(earnings.availableFormatted('أوقية'), '8,800 أوقية');
      expect(earnings.thisMonthFormatted('أوقية'), '3,000 أوقية');
    });

    test('defaults to MRU for all four stats', () {
      expect(earnings.formatted(), '10,000 MRU');
      expect(earnings.pendingFormatted(), '1,200 MRU');
      expect(earnings.availableFormatted(), '8,800 MRU');
      expect(earnings.thisMonthFormatted(), '3,000 MRU');
    });
  });
}
