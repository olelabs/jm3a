// Wallet translation audit (task item 2): TransactionType.displayLabel,
// TransactionStatus.displayLabel, DepositStatus.displayLabel, and the
// transaction-history filter-chip labels were previously plain Dart
// string-literal switches — hardcoded English with no localization
// mechanism at all, even though the ARB files already had full EN/FR/AR
// key parity everywhere else. These now take an AppLocalizations and read
// real per-locale strings; these tests are the regression guard for that.
//
// A full WalletProvider/WalletRepository integration test (filter state
// reaching a live `wallet_transactions` query) needs a live Supabase
// connection this offline suite doesn't have — see final report for what
// still needs real-device verification (same class of gap already noted
// in room_reconnect_approval_test.dart / game_chat_sheet_test.dart for
// their own Supabase-backed paths).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/features/wallet/domain/wallet_entity.dart';

const _locales = [Locale('en'), Locale('fr'), Locale('ar')];

Future<AppLocalizations> _l10nFor(WidgetTester tester, Locale locale) async {
  late AppLocalizations l10n;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return l10n;
}

void main() {
  for (final locale in _locales) {
    testWidgets(
      'every TransactionType has a non-empty ${locale.languageCode} label',
      (tester) async {
        final l10n = await _l10nFor(tester, locale);
        for (final type in TransactionType.values) {
          expect(type.displayLabel(l10n), isNotEmpty);
        }
      },
    );

    testWidgets(
      'every TransactionStatus has a non-empty ${locale.languageCode} label',
      (tester) async {
        final l10n = await _l10nFor(tester, locale);
        for (final status in TransactionStatus.values) {
          expect(status.displayLabel(l10n), isNotEmpty);
        }
      },
    );

    testWidgets(
      'every DepositStatus has a non-empty ${locale.languageCode} label',
      (tester) async {
        final l10n = await _l10nFor(tester, locale);
        for (final status in DepositStatus.values) {
          expect(status.displayLabel(l10n), isNotEmpty);
        }
      },
    );
  }

  testWidgets(
    'labels actually differ between English and Arabic — proves a real '
    'translation is wired up, not the English string reused everywhere',
    (tester) async {
      final en = await _l10nFor(tester, const Locale('en'));
      final ar = await _l10nFor(tester, const Locale('ar'));
      expect(
        TransactionType.deposit.displayLabel(en),
        isNot(equals(TransactionType.deposit.displayLabel(ar))),
      );
      expect(
        TransactionStatus.pending.displayLabel(en),
        isNot(equals(TransactionStatus.pending.displayLabel(ar))),
      );
      expect(
        DepositStatus.approved.displayLabel(en),
        isNot(equals(DepositStatus.approved.displayLabel(ar))),
      );
    },
  );

  testWidgets(
    'wallet transaction-history filter-chip labels are non-empty and '
    'locale-specific (previously a hardcoded const English tuple list)',
    (tester) async {
      final en = await _l10nFor(tester, const Locale('en'));
      final ar = await _l10nFor(tester, const Locale('ar'));
      expect(en.walletFilterAll, isNotEmpty);
      expect(ar.walletFilterAll, isNotEmpty);
      expect(en.walletFilterAll, isNot(equals(ar.walletFilterAll)));
      expect(en.walletFilterDeposits, isNot(equals(ar.walletFilterDeposits)));
    },
  );
}
