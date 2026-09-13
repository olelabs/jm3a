// Item 3 (real-device report) — the ToD pre-game config sheet's "Allow
// Skip" toggle used to be nested INSIDE the Punishments section's
// `_enablePunishments ? ... : null` conditional child (default off), so
// in the common case the admin could never see or disable it, and
// _allowSkip stayed hardcoded at its initial `true` regardless of what
// the room's persisted setting actually was.
//
// This regression test proves, at the widget level:
// 1. The Allow Skip row is ALWAYS visible, independent of the
//    Punishments switch.
// 2. It is correctly initialized from the room's actual persisted
//    allow_skip setting (initialAllowSkip), not a hardcoded default.
// 3. Toggling it and confirming produces a TodPreGameConfig carrying the
//    new value.
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

void main() {
  testWidgets(
    'Allow Skip is visible and ON by default (Punishments left off) when '
    'the room setting is true',
    (tester) async {
      TodPreGameConfig? result;
      await tester.pumpWidget(
        _wrap(
          (context) => ElevatedButton(
            onPressed: () async {
              result = await showTodPreGameConfigSheet(
                context,
                pack: null,
                initialAllowSkip: true,
              );
            },
            child: const Text('open'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Visible without ever touching the Punishments switch — the
      // actual root-cause fix.
      final allowSkipLabel = find.text('Allow skip');
      expect(allowSkipLabel, findsOneWidget);
      final skipRow = find
          .ancestor(of: allowSkipLabel, matching: find.byType(Row))
          .first;
      final skipSwitch = tester.widget<Switch>(
        find.descendant(of: skipRow, matching: find.byType(Switch)),
      );
      expect(skipSwitch.value, isTrue);

      await tester.ensureVisible(find.text('Confirm & Start'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm & Start'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.allowSkip, isTrue);
    },
  );

  testWidgets(
    'Allow Skip is visible and OFF when the room setting is false — the '
    'exact bug report: the admin disabled it, so it must not silently '
    'come back on',
    (tester) async {
      TodPreGameConfig? result;
      await tester.pumpWidget(
        _wrap(
          (context) => ElevatedButton(
            onPressed: () async {
              result = await showTodPreGameConfigSheet(
                context,
                pack: null,
                initialAllowSkip: false,
              );
            },
            child: const Text('open'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final allowSkipLabel = find.text('Allow skip');
      expect(allowSkipLabel, findsOneWidget);
      final skipRow = find
          .ancestor(of: allowSkipLabel, matching: find.byType(Row))
          .first;
      final skipSwitch = tester.widget<Switch>(
        find.descendant(of: skipRow, matching: find.byType(Switch)),
      );
      expect(skipSwitch.value, isFalse);

      await tester.ensureVisible(find.text('Confirm & Start'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm & Start'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.allowSkip, isFalse);
    },
  );

  testWidgets(
    'the admin can flip Allow Skip off without ever touching Punishments',
    (tester) async {
      TodPreGameConfig? result;
      await tester.pumpWidget(
        _wrap(
          (context) => ElevatedButton(
            onPressed: () async {
              result = await showTodPreGameConfigSheet(
                context,
                pack: null,
                initialAllowSkip: true,
              );
            },
            child: const Text('open'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final allowSkipLabel = find.text('Allow skip');
      final skipRow = find
          .ancestor(of: allowSkipLabel, matching: find.byType(Row))
          .first;
      final skipSwitchFinder = find.descendant(
        of: skipRow,
        matching: find.byType(Switch),
      );
      await tester.tap(skipSwitchFinder);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Confirm & Start'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm & Start'));
      await tester.pumpAndSettle();
      expect(result!.allowSkip, isFalse);
    },
  );
}
