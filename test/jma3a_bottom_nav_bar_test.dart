// Regression coverage for the WhatsApp-inspired bottom nav redesign
// (Jma3aBottomNavBar). Deliberately tests the widget in isolation rather
// than through the full HomeShellScreen — HomeShellScreen requires the
// entire app provider tree to even build (see real_router_regression_test's
// own comment on this), which is unrelated to what actually changed here.
// This file exercises exactly the new/changed surface: destination count,
// order and labels are unchanged, selection/tap callbacks still fire
// immediately (the added "pop" animation must never delay navigation),
// and badges remain functional.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/shared/widgets/navigation/jma3a_bottom_nav_bar.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(bottomNavigationBar: child),
  );

  List<Jma3aNavDestination> destinations({
    int friendBadge = 0,
    int profileBadge = 0,
  }) => [
    const Jma3aNavDestination(
      icon: Icons.meeting_room_outlined,
      selectedIcon: Icons.meeting_room_rounded,
      cupertinoIcon: Icons.grid_view_outlined,
      cupertinoSelectedIcon: Icons.grid_view_rounded,
      label: 'Rooms',
    ),
    Jma3aNavDestination(
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      cupertinoIcon: Icons.people_outline_rounded,
      cupertinoSelectedIcon: Icons.people_rounded,
      label: 'Friends',
      badgeCount: friendBadge,
    ),
    const Jma3aNavDestination(
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront_rounded,
      cupertinoIcon: Icons.storefront_outlined,
      cupertinoSelectedIcon: Icons.storefront_rounded,
      label: 'Marketplace',
    ),
    Jma3aNavDestination(
      icon: Icons.account_circle_outlined,
      selectedIcon: Icons.account_circle_rounded,
      cupertinoIcon: Icons.account_circle_outlined,
      cupertinoSelectedIcon: Icons.account_circle_rounded,
      label: 'Profile',
      badgeCount: profileBadge,
    ),
  ];

  testWidgets(
    'renders the existing 4 destinations, in the existing order, with the '
    'existing labels — the redesign must not add, remove, or reorder tabs',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          Jma3aBottomNavBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinations: destinations(),
          ),
        ),
      );

      // Jma3aBottomNavBar no longer renders Material's NavigationDestination
      // (see the widget's own doc comment for why) — order/labels are
      // instead verified through each item's Semantics, which is also
      // what a screen reader actually sees.
      final semanticsLabels = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((s) => s.properties.label)
          .whereType<String>()
          .toList();
      expect(semanticsLabels, ['Rooms', 'Friends', 'Marketplace', 'Profile']);
      expect(find.text('Rooms'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Marketplace'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping a destination invokes the callback with the correct index '
    'immediately — the selection "pop" animation must never delay it',
    (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(
        wrap(
          Jma3aBottomNavBar(
            selectedIndex: 0,
            onDestinationSelected: taps.add,
            destinations: destinations(),
          ),
        ),
      );

      await tester.tap(find.text('Marketplace'));
      // No pump/settle before this assertion: the callback must have
      // already fired synchronously with the tap, not after an animation.
      expect(taps, [2]);
    },
  );

  testWidgets('badge counts remain visible when > 0', (tester) async {
    await tester.pumpWidget(
      wrap(
        Jma3aBottomNavBar(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          destinations: destinations(friendBadge: 3, profileBadge: 12),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('no badge text is shown when the count is 0', (tester) async {
    await tester.pumpWidget(
      wrap(
        Jma3aBottomNavBar(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          destinations: destinations(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Badge), findsNothing);
  });

  testWidgets(
    'selectedIconOverride replaces the default icon only for the selected '
    'tab, leaving other tabs on their normal icon',
    (tester) async {
      final overridden = destinations();
      overridden[3] = Jma3aNavDestination(
        icon: overridden[3].icon,
        selectedIcon: overridden[3].selectedIcon,
        cupertinoIcon: overridden[3].cupertinoIcon,
        cupertinoSelectedIcon: overridden[3].cupertinoSelectedIcon,
        label: overridden[3].label,
        selectedIconOverride: (_) => const Icon(Icons.star, key: Key('ov')),
      );

      await tester.pumpWidget(
        wrap(
          Jma3aBottomNavBar(
            selectedIndex: 3,
            onDestinationSelected: (_) {},
            destinations: overridden,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ov')), findsOneWidget);
    },
  );

  testWidgets('is genuinely translucent glass, not an opaque panel: blurs its '
      'backdrop and tints with a partly-transparent color, never a fully '
      'opaque fill', (tester) async {
    await tester.pumpWidget(
      wrap(
        Jma3aBottomNavBar(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          destinations: destinations(),
        ),
      ),
    );

    expect(
      find.byType(BackdropFilter),
      findsOneWidget,
      reason:
          'the glass effect must come from an actual backdrop blur, '
          'not a plain colored rectangle',
    );

    // The FIRST DecoratedBox in build order is the outer glass shell
    // (BackdropFilter's direct child) — later ones are the small per-item
    // selected-state pill highlights, which are deliberately more opaque
    // (a compact chip, not the panel behind the whole bar) and are out of
    // scope for this assertion.
    final glassShell = tester.widget<DecoratedBox>(
      find.byType(DecoratedBox).first,
    );
    final decoration = glassShell.decoration as BoxDecoration;
    expect(
      decoration.color!.a,
      lessThan(0.6),
      reason:
          'the outer glass fill must stay partly transparent — an opaque '
          '(alpha 1.0) fill is exactly the "bottom sheet" look this must '
          'not have',
    );
  });

  testWidgets(
    'unselected items render as bare icons — the glass/pill treatment '
    'belongs to the navbar container and the selected item only, never to '
    'an individual unselected item',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          Jma3aBottomNavBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinations: destinations(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly one AnimatedContainer pill exists — for the SELECTED item.
      // The other 3 unselected items have no Container/decoration of
      // their own at all.
      expect(find.byType(AnimatedContainer), findsOneWidget);
    },
  );

  testWidgets(
    'per-item taps never paint their own splash/highlight/hover background '
    '— that would look like each item having its own glass panel',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          Jma3aBottomNavBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinations: destinations(),
          ),
        ),
      );

      final inkWells = tester.widgetList<InkWell>(find.byType(InkWell));
      expect(inkWells, hasLength(4));
      for (final inkWell in inkWells) {
        expect(inkWell.splashColor, Colors.transparent);
        expect(inkWell.highlightColor, Colors.transparent);
        expect(inkWell.hoverColor, Colors.transparent);
        expect(inkWell.focusColor, Colors.transparent);
      }
    },
  );

  testWidgets(
    'swiping the navbar left/right changes tabs through the existing '
    'callback, matching the Rooms -> Friends -> Marketplace -> Profile order',
    (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(
        wrap(
          Jma3aBottomNavBar(
            selectedIndex: 1,
            onDestinationSelected: taps.add,
            destinations: destinations(),
          ),
        ),
      );

      await tester.drag(find.byType(Jma3aBottomNavBar), const Offset(-200, 0));
      expect(taps, [2], reason: 'swiping left advances to the next tab');

      taps.clear();
      await tester.drag(find.byType(Jma3aBottomNavBar), const Offset(200, 0));
      expect(taps, [0], reason: 'swiping right goes to the previous tab');
    },
  );

  testWidgets(
    'swiping clamps at the first/last tab instead of wrapping around',
    (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(
        wrap(
          Jma3aBottomNavBar(
            selectedIndex: 0,
            onDestinationSelected: taps.add,
            destinations: destinations(),
          ),
        ),
      );
      await tester.drag(find.byType(Jma3aBottomNavBar), const Offset(200, 0));
      expect(
        taps,
        isEmpty,
        reason:
            'already at the first tab (Rooms) — swiping right (toward '
            '"previous") must not wrap to the last tab (Profile)',
      );

      taps.clear();
      await tester.pumpWidget(
        wrap(
          Jma3aBottomNavBar(
            selectedIndex: 3,
            onDestinationSelected: taps.add,
            destinations: destinations(),
          ),
        ),
      );
      await tester.drag(find.byType(Jma3aBottomNavBar), const Offset(-200, 0));
      expect(
        taps,
        isEmpty,
        reason:
            'already at the last tab (Profile) — swiping left (toward '
            '"next") must not wrap to the first tab (Rooms)',
      );
    },
  );

  testWidgets(
    'a drag below the swipe distance threshold does not change tabs, even '
    'though it is clearly a drag and not a tap',
    (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(
        wrap(
          Jma3aBottomNavBar(
            selectedIndex: 0,
            onDestinationSelected: taps.add,
            destinations: destinations(),
          ),
        ),
      );
      // -25px clears the gesture arena's own touch-slop (so this is
      // unambiguously recognized as a drag, not a tap on whatever item
      // happens to sit under the bar's center) while staying below this
      // widget's own 40px swipe-distance threshold.
      await tester.drag(find.byType(Jma3aBottomNavBar), const Offset(-25, 0));
      expect(taps, isEmpty);
    },
  );

  testWidgets(
    'overlayInset combines the bar height, its bottom gap, and the current '
    'safe-area bottom inset — HomeShellScreen relies on this single number '
    'to keep FABs/scroll content clear of the floating bar',
    (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          // viewPadding, not padding: overlayInset deliberately reads the
          // fixed physical safe area (viewPadding), immune to
          // Scaffold(extendBody: true)'s own inflation of `padding` — see
          // overlayInset's own doc comment and
          // home_shell_overlay_layout_test.dart for the regression this
          // guards against.
          data: const MediaQueryData(viewPadding: EdgeInsets.only(bottom: 34)),
          child: Builder(
            builder: (context) {
              final inset = Jma3aBottomNavBar.overlayInset(context);
              expect(
                inset,
                Jma3aBottomNavBar.barHeight + Jma3aBottomNavBar.bottomGap + 34,
              );
              return const SizedBox();
            },
          ),
        ),
      );
    },
  );

  testWidgets(
    'respects Reduce Motion: still renders and switches selection with no '
    'animation-related exceptions',
    (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: wrap(
            Jma3aBottomNavBar(
              selectedIndex: 0,
              onDestinationSelected: taps.add,
              destinations: destinations(),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Profile'));
      expect(taps, [3]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
