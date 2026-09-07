// Tests for item 11 — the persistent admin/host-only top bar. Root cause
// (see join_requests_panel.dart's `floatingCard` doc comment): all three
// game screens (ToD/NHIE/Meme) used to wrap JoinRequestsPanel in an
// unconditional Material/SingleChildScrollView(padding: 8) chrome AT THE
// CALL SITE, so even when the panel itself collapsed to SizedBox.shrink()
// (the overwhelmingly common "nothing pending" case), that wrapper's own
// padding still gave the zero-size child a non-zero visible footprint — a
// persistent, contentless, elevated strip near the top of the screen, for
// every admin/moderator, for the whole session. The fix moved the SAME
// chrome inside JoinRequestsPanel itself (via `floatingCard: true`, now used
// identically by all three game screens' call sites), gated on the same
// null-content check that already produced SizedBox.shrink() — so the
// chrome only ever exists when there's real content to show.
//
// This exercises JoinRequestsPanel directly rather than the full game
// screens (which need a live room/session/provider stack this offline
// suite doesn't have) — since all three screens now call this widget with
// the exact identical `floatingCard: true` parameterization, one test
// against the shared root cause covers all three "no admin bar" cases.
//
// sl.roomRepository (Supabase-backed) isn't initialized in this offline
// test environment, so the panel's background fetch throws synchronously
// on first access and is caught by its own try/catch (see
// join_requests_panel.dart's `_load`), landing on the same
// zero-pending-requests code path a real, successful "no requests yet"
// response would — which is exactly the path this regression is about.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/shared/widgets/join_requests_panel.dart';

Future<void> _pumpPanel(
  WidgetTester tester, {
  required bool floatingCard,
  bool showAlways = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: JoinRequestsPanel(
            roomId: 'room-1',
            floatingCard: floatingCard,
            showAlways: showAlways,
          ),
        ),
      ),
    ),
  );
  // Let the fire-and-forget _load() future (and its catch branch) settle
  // without waiting on the 5s periodic refresh timer via pumpAndSettle,
  // which would hang on that still-pending Timer.periodic.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('11 — admin-only top bar: zero footprint when nothing is pending', () {
    testWidgets(
      '11. floatingCard:true (the 3 game screens\' usage) renders zero '
      'size — no Material/Card chrome — when there are no pending join '
      'requests, instead of a persistent empty elevated strip',
      (tester) async {
        await _pumpPanel(tester, floatingCard: true);

        // Asserting on find.byType(Material)/Card would be unreliable here
        // — Scaffold/MaterialApp already mount their own ambient Material
        // widgets regardless of this panel's content. The definitive
        // signal that no elevated chrome exists is that the panel's own
        // subtree renders with zero size — nothing at all, not even an
        // invisible reserved strip.
        expect(find.byType(JoinRequestsPanel), findsOneWidget);
        expect(tester.getSize(find.byType(JoinRequestsPanel)), Size.zero);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'floatingCard:false (the lobby\'s existing inline usage) is '
      'unaffected by this fix — still collapses to zero size when empty, '
      'exactly as before',
      (tester) async {
        await _pumpPanel(tester, floatingCard: false);

        expect(tester.getSize(find.byType(JoinRequestsPanel)), Size.zero);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'showAlways:true (the lobby\'s "requires approval" always-visible '
      'section) still renders its own "no pending requests" content '
      'instead of collapsing — this panel\'s always-visible mode is '
      'untouched by the game-screen-only floatingCard fix',
      (tester) async {
        await _pumpPanel(tester, floatingCard: false, showAlways: true);

        // showAlways:true skips the "return null when empty" branch this
        // fix relies on for the game screens, so its own always-visible
        // "no pending requests" row must still render — confirming the
        // floatingCard fix didn't touch showAlways's unrelated behavior.
        expect(tester.getSize(find.byType(JoinRequestsPanel)), isNot(Size.zero));
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
      },
    );
  });
}
