// Tests for the game localization audit (real-device follow-up task):
// every user-facing game string must exist, non-empty, in EN/FR/AR. This
// doesn't re-derive what's "a game string" (that was a manual grep audit
// across the game screens/shared widgets — see final report for the
// list), it guards the STRUCTURAL property that makes missing/incomplete
// translations impossible to ship silently: the three ARB files must
// carry an identical key set, and none of the keys this session actually
// added (memeAddCaptionOptional, sharedHistoryTooltip,
// sharedReactionIconsTab, sharedReactionAvatarsTab,
// todForcePunishmentTooltip — replacing hardcoded English literals found
// in meme/nhie/tod game screens, Sticker.dart's reaction picker, and the
// ToD punishment override tooltip) may be missing or empty in any of the
// three languages.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadArb(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Only the actual translatable entries — ARB metadata keys (placeholders,
/// descriptions, plural/select config) are prefixed with '@' and aren't
/// translations themselves.
Set<String> _translationKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@') && k != '@@locale').toSet();

void main() {
  late Map<String, dynamic> en;
  late Map<String, dynamic> fr;
  late Map<String, dynamic> ar;

  setUpAll(() {
    en = _loadArb('lib/core/l10n/app_en.arb');
    fr = _loadArb('lib/core/l10n/app_fr.arb');
    ar = _loadArb('lib/core/l10n/app_ar.arb');
  });

  group('15/16/17 — EN/FR/AR key parity', () {
    test('every EN key has a FR translation', () {
      final missing = _translationKeys(en).difference(_translationKeys(fr));
      expect(missing, isEmpty, reason: 'Missing in FR: $missing');
    });

    test('every EN key has an AR translation', () {
      final missing = _translationKeys(en).difference(_translationKeys(ar));
      expect(missing, isEmpty, reason: 'Missing in AR: $missing');
    });

    test('FR/AR carry no orphaned keys absent from EN (the source of '
        'truth)', () {
      expect(_translationKeys(fr).difference(_translationKeys(en)), isEmpty);
      expect(_translationKeys(ar).difference(_translationKeys(en)), isEmpty);
    });

    test('no translation value is an empty string in any of the three '
        'languages', () {
      for (final MapEntry(:key, :value) in en.entries) {
        if (key.startsWith('@') || value is! String) continue;
        expect(value.isNotEmpty, isTrue, reason: 'app_en.arb["$key"] is empty');
        expect(
          (fr[key] as String).isNotEmpty,
          isTrue,
          reason: 'app_fr.arb["$key"] is empty',
        );
        expect(
          (ar[key] as String).isNotEmpty,
          isTrue,
          reason: 'app_ar.arb["$key"] is empty',
        );
      }
    });
  });

  group('18 — newly introduced game keys (this session\'s hardcoded-string '
      'fixes) are present and translated in all three languages', () {
    const newKeys = [
      'memeAddCaptionOptional',
      'sharedHistoryTooltip',
      'sharedReactionIconsTab',
      'sharedReactionAvatarsTab',
      'todForcePunishmentTooltip',
    ];

    for (final key in newKeys) {
      test(key, () {
        expect(en[key], isA<String>());
        expect(fr[key], isA<String>());
        expect(ar[key], isA<String>());
        expect((en[key] as String).isNotEmpty, isTrue);
        expect((fr[key] as String).isNotEmpty, isTrue);
        expect((ar[key] as String).isNotEmpty, isTrue);
      });
    }
  });

  group('19 — wallet localization audit: filter-chip labels and domain-enum '
      'display labels (TransactionType/TransactionStatus/DepositStatus) '
      'that were previously hardcoded English are present and translated '
      'in all three languages', () {
    const newKeys = [
      'walletFilterAll',
      'walletFilterDeposits',
      'walletFilterWithdrawals',
      'walletFilterPurchases',
      'walletFilterEarnings',
      'walletFilterRefunds',
      'walletFilterPayouts',
      'walletFilterBonuses',
      'walletFilterAdjustments',
      'walletFilterTransfers',
      'walletTypeDeposit',
      'walletTypeWithdrawal',
      'walletTypePurchase',
      'walletTypeRefund',
      'walletTypeCommission',
      'walletTypePayout',
      'walletTypeAdjustment',
      'walletTypeBonus',
      'walletTypeTransfer',
      'walletStatusPending',
      'walletStatusProcessing',
      'walletStatusCompleted',
      'walletStatusFailed',
      'walletStatusCancelled',
      'walletStatusReversed',
      'walletDepositStatusPending',
      'walletDepositStatusUnderReview',
      'walletDepositStatusApproved',
      'walletDepositStatusRejected',
    ];

    for (final key in newKeys) {
      test(key, () {
        expect(en[key], isA<String>());
        expect(fr[key], isA<String>());
        expect(ar[key], isA<String>());
        expect((en[key] as String).isNotEmpty, isTrue);
        expect((fr[key] as String).isNotEmpty, isTrue);
        expect((ar[key] as String).isNotEmpty, isTrue);
      });
    }

    test('roomsDailyLimitFreeBody/PremiumBody carry the daily-limit number '
        'as an ICU placeholder, not baked into the translated text, in all '
        'three languages', () {
      for (final arb in [en, fr, ar]) {
        expect(
          (arb['roomsDailyLimitFreeBody'] as String).contains('{basicLimit}'),
          isTrue,
        );
        expect(
          (arb['roomsDailyLimitFreeBody'] as String).contains(
            '{premiumLimit}',
          ),
          isTrue,
        );
        expect(
          (arb['roomsDailyLimitPremiumBody'] as String).contains(
            '{premiumLimit}',
          ),
          isTrue,
        );
      }
    });
  });
}
