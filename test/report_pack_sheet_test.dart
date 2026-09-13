// Regression coverage for item 11 — duplicate report prevention. This file
// covers the UI-level half of the fix: ReportPackSheet itself, which takes
// a plain callback (not a live PackProvider/Supabase-backed repository),
// so it's directly testable in isolation.
//
// The application-level half — PackProvider.reportPack's synchronous,
// persisted (survives app restart) duplicate guard — cannot be unit
// tested here: PackRepository's singleton eagerly touches
// Supabase.instance.client at construction, and its constructor is
// private, so no fake substitute can be built without a live Supabase
// client. That guard was verified by direct code reading instead (see
// PackProvider.reportPack's own doc comment for exactly how the race is
// closed: the id is claimed synchronously BEFORE the network call, not
// after success).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/features/packs/presentation/widgets/review_sheet.dart';
import 'package:jma3a/shared/widgets/buttons/j_button.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'the submit button is a guaranteed no-op for a rapid second tap while '
    'a submission is already in flight — not just "eventually" (the old '
    "_reason == null-only guard didn't check _isSubmitting at all)",
    (tester) async {
      var callCount = 0;
      final submitCompleter = Completer<bool>();
      await tester.pumpWidget(
        _wrap(
          ReportPackSheet(
            packId: 'p1',
            onSubmit: (reason, details) {
              callCount++;
              return submitCompleter.future;
            },
          ),
        ),
      );

      // Pick a reason so the button becomes enabled at all.
      await tester.tap(find.byType(RadioListTile<String>).first);
      await tester.pumpAndSettle();

      // First tap starts the (never-yet-resolved) submission.
      await tester.tap(find.byType(JButton));
      await tester.pump();
      // A second tap on the same button while still in flight — the
      // JButton itself is now showing isLoading, so this tap lands on the
      // same widget instance regardless of what it's currently painting.
      await tester.tap(find.byType(JButton), warnIfMissed: false);
      await tester.pump();

      expect(
        callCount,
        1,
        reason:
            'onSubmit must be invoked exactly once for two rapid taps '
            'on the same in-flight submission',
      );

      submitCompleter.complete(true);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'a failed/duplicate submission (onSubmit returns false) keeps the '
    'sheet open with visible feedback, instead of silently closing',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ReportPackSheet(
            packId: 'p1',
            onSubmit: (reason, details) async => false,
          ),
        ),
      );

      await tester.tap(find.byType(RadioListTile<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(JButton));
      await tester.pumpAndSettle();

      // The sheet is still on screen (didn't pop) and the submit button
      // is enabled again (not stuck showing a permanent spinner) — a
      // second real attempt remains possible.
      expect(find.byType(ReportPackSheet), findsOneWidget);
      final button = tester.widget<JButton>(find.byType(JButton));
      expect(button.isLoading, isFalse);
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets('a successful submission closes the sheet (pops)', (
    tester,
  ) async {
    var popped = false;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              await showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => ReportPackSheet(
                  packId: 'p1',
                  onSubmit: (reason, details) async => true,
                ),
              );
              popped = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(RadioListTile<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(JButton));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(find.byType(ReportPackSheet), findsNothing);
  });
}
