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

  // Item 19's own wallet-localization-audit group (filter-chip labels and
  // TransactionType/TransactionStatus display labels) was removed here —
  // Stage 8 deleted the mobile wallet UI entirely (creator earnings,
  // transaction history, and withdrawals now live exclusively in the
  // Store Creator Portal), along with WalletEntity/TransactionType/
  // TransactionStatus and every walletFilter*/walletType*/walletStatus*
  // key those screens used. (This mirrors the same group's own earlier
  // history: the deposit-specific keys it once also covered —
  // walletFilterDeposits, walletTypeDeposit, the four
  // walletDepositStatus* keys — were removed the same way when the
  // customer-facing deposit system was deleted.) walletCurrencyShort
  // remains in use (pack creation's price field) and is covered by the
  // key-parity checks above like any other live key.
  group('19b — room daily-limit messages carry the limit as a live '
      'placeholder', () {
    test('roomsDailyLimitFreeBody/PremiumBody carry the daily-limit number '
        'as an ICU placeholder, not baked into the translated text, in all '
        'three languages', () {
      for (final arb in [en, fr, ar]) {
        expect(
          (arb['roomsDailyLimitFreeBody'] as String).contains('{basicLimit}'),
          isTrue,
        );
        // No {premiumLimit} in the free body — the free-tier message no
        // longer mentions upgrading to Premium (no in-app purchase path
        // exists), so there's nothing to interpolate there.
        expect(
          (arb['roomsDailyLimitFreeBody'] as String).contains(
            '{premiumLimit}',
          ),
          isFalse,
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
