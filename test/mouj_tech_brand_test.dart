// MoujTechBrand — the shared "developed/owned by MOUJ TECH" mark used by
// every auth/settings/splash screen. Text-only: the MOUJ logo image that
// used to render beside the text was removed from this component, so this
// file confirms the "Developed by MOUJ TECH" text renders without
// overflow/exception at both sizes, and that no Image widget is rendered.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/shared/widgets/mouj_tech_brand.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'renders the "Developed by MOUJ TECH" text, no logo image (normal size)',
    (tester) async {
      await tester.pumpWidget(_wrap(const MoujTechBrand()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Developed by MOUJ TECH'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    },
  );

  testWidgets('renders without overflow at compact size, no logo image', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const MoujTechBrand(size: MoujTechBrandSize.compact)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('renders nothing when showLabel is false', (tester) async {
    await tester.pumpWidget(_wrap(const MoujTechBrand(showLabel: false)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Developed by MOUJ TECH'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('renders without overflow on a very narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(const MoujTechBrand()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
