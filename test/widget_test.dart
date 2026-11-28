// App-level smoke test.
//
// Replaces the untouched `flutter create` template ("Counter increments
// smoke test"), which pumped the full Jma3aApp — Supabase, dotenv and the
// service locator, none of which exist in a unit-test environment — and
// then looked for a counter and a "+" button this app has never had, so it
// could never pass. This version checks real, backend-free app
// configuration instead.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:jma3a/core/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('every supported locale loads; Arabic is right-to-left', (
    tester,
  ) async {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
      containsAll(<String>{'en', 'ar', 'fr'}),
    );

    for (final (code, rtl, elite) in [
      ('en', false, 'Jma3a Elite'),
      ('fr', false, 'Jma3a Elite'),
      ('ar', true, 'جماعة إيليت'),
    ]) {
      late AppLocalizations l10n;
      late TextDirection direction;
      late String formattedDate;
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(code),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              direction = Directionality.of(context);
              // Same call the access-level screen makes for "Active until".
              formattedDate = DateFormat.yMd(
                l10n.localeName,
              ).format(DateTime(2026, 12, 31));
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(l10n.localeName, code);
      expect(direction, rtl ? TextDirection.rtl : TextDirection.ltr);
      expect(formattedDate, isNotEmpty);
      expect(l10n.premiumPlusLabel, elite);
      expect(l10n.accessLevelActiveUntil(formattedDate), contains(formattedDate));
    }
  });
}
