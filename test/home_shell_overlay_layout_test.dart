// Regression coverage for HomeShellScreen's floating-navbar layout
// mechanism, tested in isolation (HomeShellScreen itself needs the full
// app provider tree just to build — see real_router_regression_test's own
// comment on this, unrelated to what changed here).
//
// Pins two things directly:
//   1. A page behind the floating navbar still gets the FULL available
//      height (no Padding/MediaQuery-driven shrink reintroduced).
//   2. Jma3aBottomNavBar.overlayInset/fabLocation are immune to
//      Scaffold(extendBody: true)'s own MediaQuery.padding inflation —
//      the exact double-counting bug fixed here: extendBody sets
//      `padding.bottom = max(original, measured bottomNavigationBar
//      height)`, which (since the bar's measured height already equals
//      roughly what overlayInset computes) would double the bar's own
//      footprint back into itself if overlayInset read `padding` instead
//      of the untouched `viewPadding`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jma3a/shared/widgets/navigation/jma3a_bottom_nav_bar.dart';

void main() {
  const screenSize = Size(400, 800);
  const safeAreaBottom = 34.0;
  const rawOverlayInset =
      Jma3aBottomNavBar.barHeight +
      Jma3aBottomNavBar.bottomGap +
      safeAreaBottom;

  testWidgets('a page behind the floating navbar still gets the FULL available '
      'height — nothing shrinks its layout box, so its content can extend '
      'behind the bar', (tester) async {
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: ColoredBox(
            key: Key('page-body'),
            color: Colors.blue,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byKey(const Key('page-body')));
    expect(size.height, screenSize.height);
  });

  testWidgets('overlayInset ignores MediaQuery.padding inflation (what '
      "extendBody: true adds for the bar's own translucency) and reads "
      'the untouched viewPadding instead — this is the exact previous '
      'double-counting bug', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          // Simulates Scaffold(extendBody: true)'s own inflation of
          // `padding.bottom` to roughly the bar's measured height —
          // a value overlayInset must NOT also add its own
          // barHeight+bottomGap on top of.
          padding: EdgeInsets.only(bottom: rawOverlayInset),
          viewPadding: EdgeInsets.only(bottom: safeAreaBottom),
        ),
        child: Builder(
          builder: (context) {
            expect(
              Jma3aBottomNavBar.overlayInset(context),
              rawOverlayInset,
              reason:
                  'must equal barHeight + bottomGap + the RAW safe '
                  'area (viewPadding), not barHeight + bottomGap + '
                  'the already-inflated padding — that would double '
                  "the bar's own footprint",
            );
            return const SizedBox();
          },
        ),
      ),
    );
  });

  testWidgets(
    'fabLocation positions the FAB exactly fabGap above the navbar\'s '
    'own top edge — not Scaffold\'s default (looser) safe-area margin',
    (tester) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: screenSize,
            padding: EdgeInsets.only(bottom: safeAreaBottom),
            viewPadding: EdgeInsets.only(bottom: safeAreaBottom),
          ),
          child: Builder(
            builder: (context) => MaterialApp(
              home: Scaffold(
                backgroundColor: Colors.transparent,
                body: const SizedBox.expand(),
                floatingActionButtonLocation: Jma3aBottomNavBar.fabLocation(
                  context,
                ),
                floatingActionButton: FloatingActionButton(
                  key: const Key('fab'),
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fabBottom = tester.getRect(find.byKey(const Key('fab'))).bottom;
      final navBarTopY = screenSize.height - rawOverlayInset;
      expect(
        navBarTopY - fabBottom,
        closeTo(Jma3aBottomNavBar.fabGap, 0.5),
        reason:
            'the FAB\'s bottom edge must sit almost exactly fabGap '
            "above the navbar's top edge — a large gap here is exactly "
            'the regression this pins against',
      );
    },
  );
}
