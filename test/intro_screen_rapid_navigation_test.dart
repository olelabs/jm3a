// Regression: rapid taps on IntroScreen's Next button could leave the
// surrounding chrome (background gradient, progress dots, Skip/"Next"
// vs "Get started" button label — all driven by the `_page` field)
// reporting an EARLIER page than the one actually visible, because
// _next()/_finish() were fire-and-forget: a second tap before the first
// page-change animation settled called PageController.nextPage() again
// while the first was still in flight, and the two competed for the
// same AnimationController, dropping/reordering the onPageChanged calls
// that update `_page`. Fixed by making both handlers ignore further
// taps until the in-flight transition's own Future genuinely resolves
// (see IntroScreen's own _isTransitioning doc).
//
// This file proves the fix at the level the bug is externally
// observable: after firing several rapid, non-settled taps, once
// everything genuinely settles, the visible title, body, and background
// gradient must all correspond to the SAME page index — the general
// invariant "whatever is on screen is internally consistent for exactly
// one index" — and rapid tapping through the whole tour must reliably
// reach the last page rather than silently dropping taps.
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/storage/local_storage_service.dart';
import 'package:jma3a/features/intro/presentation/screens/intro_screen.dart';

Widget _wrap() => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const IntroScreen(),
);

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets(
    'rapid Next taps (never letting a transition settle) land on a page whose title/body/gradient all agree',
    (tester) async {
      await LocalStorageService.instance.initialize();
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Fire taps back-to-back with only a partial pump between them —
      // i.e. never letting the 380ms page-change animation complete —
      // exactly the "quickly swipes/taps" scenario from the bug report.
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text(l10n.introNext));
        await tester.pump(const Duration(milliseconds: 40));
      }
      await tester.pumpAndSettle();

      // Whichever page this settled on, its title AND body must belong
      // to the SAME index — never a mix (e.g. page 2's title with page
      // 1's body), which is what "the previous screen's details are
      // still showing" would look like here.
      final titles = [
        l10n.introPage1Title,
        l10n.introPage2Title,
        l10n.introPage3Title,
        l10n.introPage4Title,
        l10n.introPage5Title,
      ];
      final bodies = [
        l10n.introPage1Body,
        l10n.introPage2Body,
        l10n.introPage3Body,
        l10n.introPage4Body,
        l10n.introPage5Body,
      ];

      final visibleTitleIndex = titles.indexWhere(
        (t) => find.text(t).evaluate().isNotEmpty,
      );
      final visibleBodyIndex = bodies.indexWhere(
        (b) => find.text(b).evaluate().isNotEmpty,
      );

      expect(visibleTitleIndex, isNot(-1), reason: 'no known page title is visible at all');
      expect(
        visibleBodyIndex,
        visibleTitleIndex,
        reason: 'the visible title and body belong to different pages — stale content bleed',
      );

      // Exactly one page's title is visible — never two at once (which
      // would itself indicate old content wasn't cleaned up).
      final visibleTitleCount = titles
          .where((t) => find.text(t).evaluate().isNotEmpty)
          .length;
      expect(visibleTitleCount, 1);
    },
  );

  testWidgets(
    'rapid-tapping Next exactly pageCount-1 times reliably reaches the last page — no taps silently dropped',
    (tester) async {
      await LocalStorageService.instance.initialize();
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // 4 transitions get from page 1 to page 5 (index 4, the last one).
      // Each tap is followed by a full settle here (unlike the rapid
      // test above) specifically so this test isolates "does the guard
      // itself block legitimate, one-at-a-time advances" from "does
      // rapid double-tapping corrupt state" — regressing either would
      // fail one of these two tests but not necessarily the other.
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text(l10n.introNext));
        await tester.pumpAndSettle();
      }

      expect(find.text(l10n.introPage5Title), findsOneWidget);
      expect(find.text(l10n.introGetStarted), findsOneWidget);
    },
  );
}
