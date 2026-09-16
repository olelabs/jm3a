// Item 2 (TOD settings: enable/disable dares) — mirrors
// tod_pre_game_allow_skip_test.dart's own pattern exactly: the pre-game
// sheet must (1) always show the Dares toggle, (2) initialize it from
// the room's actual persisted setting (initialDaresEnabled), (3) produce
// a TodPreGameConfig carrying whatever the admin chose, and (4) hide the
// (now-meaningless) Force Dare Rules section whenever dares are off.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/games/truth_or_dare/presentation/widgets/tod_pre_game_config_sheet.dart';

Widget _wrap(WidgetBuilder builder) {
  return MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Builder(builder: builder)),
  );
}

Future<TodPreGameConfig?> _open(
  WidgetTester tester, {
  required bool initialDaresEnabled,
}) async {
  TodPreGameConfig? result;
  await tester.pumpWidget(
    _wrap(
      (context) => ElevatedButton(
        onPressed: () async {
          result = await showTodPreGameConfigSheet(
            context,
            pack: null,
            initialDaresEnabled: initialDaresEnabled,
          );
        },
        child: const Text('open'),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

Switch _switchFor(WidgetTester tester, String label) {
  final labelFinder = find.text(label);
  final row = find.ancestor(of: labelFinder, matching: find.byType(Row)).first;
  return tester.widget<Switch>(
    find.descendant(of: row, matching: find.byType(Switch)),
  );
}

void main() {
  testWidgets('Dares is visible and ON by default when the room setting is true', (
    tester,
  ) async {
    await _open(tester, initialDaresEnabled: true);
    expect(find.text('Dares'), findsOneWidget);
    expect(_switchFor(tester, 'Dares').value, isTrue);
    // Force Dare Rules is still meaningful with dares on.
    expect(find.text('Force Dare Rules'), findsOneWidget);
  });

  testWidgets(
    'Dares is visible and OFF when the room setting is false, and Force '
    'Dare Rules is hidden (meaningless with no dares to force)',
    (tester) async {
      await _open(tester, initialDaresEnabled: false);
      expect(find.text('Dares'), findsOneWidget);
      expect(_switchFor(tester, 'Dares').value, isFalse);
      expect(find.text('Force Dare Rules'), findsNothing);
    },
  );

  testWidgets('toggling Dares off produces daresEnabled: false in the result', (
    tester,
  ) async {
    TodPreGameConfig? result;
    await tester.pumpWidget(
      _wrap(
        (context) => ElevatedButton(
          onPressed: () async {
            result = await showTodPreGameConfigSheet(
              context,
              pack: null,
              initialDaresEnabled: true,
            );
          },
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final daresLabel = find.text('Dares');
    final daresRow = find
        .ancestor(of: daresLabel, matching: find.byType(Row))
        .first;
    await tester.tap(
      find.descendant(of: daresRow, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Confirm & Start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm & Start'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.daresEnabled, isFalse);
  });

  testWidgets('leaving Dares on (default) produces daresEnabled: true in the result', (
    tester,
  ) async {
    TodPreGameConfig? result;
    await tester.pumpWidget(
      _wrap(
        (context) => ElevatedButton(
          onPressed: () async {
            result = await showTodPreGameConfigSheet(
              context,
              pack: null,
              initialDaresEnabled: true,
            );
          },
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Confirm & Start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm & Start'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.daresEnabled, isTrue);
  });
}
