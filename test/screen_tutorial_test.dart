// Regression coverage for the intermittent "Cannot get renderObject of
// inactive element" crash on the "Go to Lobby" flow.
//
// Root cause (verified by reading Flutter's own framework.dart and the
// showcaseview 3.0.0 package source — see ScreenTutorial.didUpdateWidget's
// doc comment): showcaseview's startShowCase() only flips a flag via
// setState(); the actual key.currentContext!.findRenderObject() call is
// deferred several addPostFrameCallback hops later, deep inside the
// package's own overlay machinery. On screens like the lobby, the tour's
// step list is recomputed from live, still-settling state (role/connection)
// right after navigation — if a step's target leaves the tree in that gap,
// the package's delayed callback can hit a transiently-inactive Element.
//
// This file cannot force Flutter's own multi-frame internal timing inside a
// third-party package deterministically (that's an engine/package-internal
// race, not something `pump()` calls can dial in on demand). What IS fully
// testable, and is exactly the mechanism the fix relies on, is that
// ScreenTutorial reacts the moment its `steps` change while a tour is
// in-flight: it must abort and release AppTutorialService's lock rather than
// silently keep chasing now-invalid targets or leaving the tutorial
// permanently unable to restart.
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/di/service_locator.dart';
import 'package:jma3a/core/storage/local_storage_service.dart';
import 'package:jma3a/shared/widgets/tutorial/screen_tutorial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

const _tutorialId = 'test_tutorial_screen_tutorial_race';

Widget _harness({required List<GlobalKey> steps, required bool showSecond}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return ScreenTutorial(
            tutorialId: _tutorialId,
            steps: steps,
            child: Column(
              children: [
                tutorialShowcase(
                  context: context,
                  showcaseKey: steps.isNotEmpty ? steps[0] : GlobalKey(),
                  description: 'first target',
                  child: const SizedBox(width: 40, height: 40),
                ),
                if (showSecond)
                  tutorialShowcase(
                    context: context,
                    showcaseKey: steps.length > 1 ? steps[1] : GlobalKey(),
                    description: 'second target',
                    child: const SizedBox(width: 40, height: 40),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // AppLogger (used by LocalStorageService.initialize) reads
  // AppConfig.isDevelopment -> dotenv, never loaded in a bare unit test.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.instance.initialize();
    sl.tutorialService.endShowing(_tutorialId);
  });

  testWidgets(
    'a mid-flight tour is aborted (and its lock released) the moment its '
    'step list changes under it — the exact ScreenTutorial.didUpdateWidget '
    'path the "Go to Lobby" race depends on',
    (tester) async {
      final key1 = GlobalKey(debugLabel: 'step1');
      final key2 = GlobalKey(debugLabel: 'step2');

      await tester.pumpWidget(_harness(steps: [key1, key2], showSecond: true));
      // Let ScreenTutorial's postFrameCallback fire: both targets are
      // mounted and laid out, so this reserves the lock and calls
      // showcaseview's startShowCase (started == true from this point).
      await tester.pump();

      expect(
        sl.tutorialService.shouldShow(_tutorialId),
        isFalse,
        reason: 'beginShowing must have reserved the tour as active',
      );

      // Simulate exactly the lobby scenario this guards against: room state
      // settles differently than it first appeared right after "Go to
      // Lobby" (e.g. the role/connection resync lands on "spectator", which
      // _lobbyTutorialSteps maps to an empty step list) and the SAME
      // ScreenTutorial instance is rebuilt with a DIFFERENT — here, empty —
      // step list. Using an empty list (rather than a shorter non-empty one)
      // isolates the release-the-lock guarantee from ScreenTutorial's
      // correct, separate self-healing behavior of immediately re-arming
      // when the new steps are already valid (an empty list can't restart:
      // ScreenTutorial._shouldRun requires steps.isNotEmpty).
      await tester.pumpWidget(_harness(steps: const [], showSecond: false));
      await tester.pump();

      // No exception should have propagated out of the rebuild/frame.
      expect(tester.takeException(), isNull);

      // The critical regression check: the lock must be released so the
      // tutorial can safely re-arm later, instead of being stuck "active"
      // forever (which — before this fix — is what happened, since only
      // dispose() ever called endShowing, and ScreenTutorial never disposes
      // here; the lobby's ScreenTutorial persists across this exact kind of
      // rebuild).
      expect(
        sl.tutorialService.shouldShow(_tutorialId),
        isTrue,
        reason:
            'didUpdateWidget must abort the stale tour and call endShowing, '
            'not leave AppTutorialService permanently locked',
      );
    },
  );

  testWidgets(
    'an unchanged step list across rebuilds does NOT abort a running tour '
    '(the fix must not make ordinary re-renders cancel a valid tour)',
    (tester) async {
      final key1 = GlobalKey(debugLabel: 'stableStep1');
      final key2 = GlobalKey(debugLabel: 'stableStep2');

      await tester.pumpWidget(_harness(steps: [key1, key2], showSecond: true));
      await tester.pump();

      expect(sl.tutorialService.shouldShow(_tutorialId), isFalse);

      // An unrelated rebuild with the SAME steps content (new list instance,
      // same GlobalKeys — exactly how _lobbyTutorialSteps behaves when the
      // underlying room state hasn't actually changed the visible controls).
      await tester.pumpWidget(_harness(steps: [key1, key2], showSecond: true));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        sl.tutorialService.shouldShow(_tutorialId),
        isFalse,
        reason: 'an unchanged step list must not release the in-flight lock',
      );
    },
  );

  testWidgets(
    // Item 2 (real-device report: iOS "History" red-screen crash) — a
    // THIRD case neither of the two tests above cover: the `steps` LIST
    // ITSELF never changes (same GlobalKeys, same length — so
    // didUpdateWidget's listEquals guard never fires), but the actual
    // WIDGET under one of those keys gets unmounted by a sibling/
    // descendant rebuild — exactly what ToD/Meme/NHIE's "History" toggle
    // used to do (and, for NHIE, still structurally does: ScreenTutorial
    // stays mounted, only the target underneath swaps out). Before this
    // pass's fix, nothing in ScreenTutorial ever re-checked target
    // liveness on an ordinary rebuild, so the tour stayed "started"
    // forever with a dead GlobalKey, leaving showcaseview's own deferred
    // overlay callback to eventually crash on it uncaught.
    'a step target that disappears from the tree — WITHOUT the steps '
    'list itself changing — is detected on the next rebuild and the tour '
    'is safely aborted',
    (tester) async {
      final key1 = GlobalKey(debugLabel: 'survivingStep');
      final key2 = GlobalKey(debugLabel: 'vanishingStep');

      await tester.pumpWidget(_harness(steps: [key1, key2], showSecond: true));
      await tester.pump();

      expect(
        sl.tutorialService.shouldShow(_tutorialId),
        isFalse,
        reason: 'beginShowing must have reserved the tour as active',
      );

      // The steps LIST is identical (same keys, same length) — only the
      // second target's own widget is removed from the tree, simulating
      // a sibling "History" toggle unmounting the showcased control
      // while ScreenTutorial (and its `steps` param) stay exactly the
      // same.
      await tester.pumpWidget(_harness(steps: [key1, key2], showSecond: false));
      // The liveness check is scheduled via addPostFrameCallback, so it
      // needs one more pump to actually run.
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        sl.tutorialService.shouldShow(_tutorialId),
        isTrue,
        reason:
            'the liveness check must abort the tour and release the lock '
            'once a target is confirmed gone, even though widget.steps '
            'never changed',
      );
    },
  );

  testWidgets(
    'looking ready for exactly one frame is NOT enough to commit — the tour '
    'must confirm readiness on a second consecutive frame before calling '
    "showcaseview's startShowCase at all",
    (tester) async {
      final key1 = GlobalKey(debugLabel: 'flappingStep');

      // Frame 1: target is ready. Internally this only reaches the
      // unconfirmed first pass and schedules a second-frame recheck — it
      // must NOT reserve AppTutorialService's lock yet.
      await tester.pumpWidget(_harness(steps: [key1], showSecond: false));

      // Before the second confirmation frame ever runs, the step list
      // changes (steps -> empty) — exactly the kind of same-frame-window
      // invalidation the two-frame confirmation exists to catch BEFORE
      // startShowCase is ever called, not just clean up after.
      await tester.pumpWidget(_harness(steps: const [], showSecond: false));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        sl.tutorialService.shouldShow(_tutorialId),
        isTrue,
        reason:
            'a target that was only ready for a single frame must never '
            'reach startShowCase — beginShowing should never have been '
            'called, so the tutorial must still be eligible to show',
      );
    },
  );

  _resultScreenQuitTests();
  _structuralInvariantTests();
}

/// Regression coverage for the "Cannot get renderObject of inactive
/// element" crash reported from showcaseview's AnchoredOverlay/LayoutBuilder
/// (package:showcaseview/src/layout_overlays.dart:68) specifically during
/// game RESULT screen -> Quit/Go Home navigation.
///
/// ROOT CAUSE (verified by reading showcaseview 3.0.0's Showcase.build()):
/// `AnchoredOverlay(showOverlay: true, ...)` is passed UNCONDITIONALLY
/// whenever `ShowCaseWidget.enableShowcase` is true — which every call site
/// in this app left at the package's own default (always true), regardless
/// of whether a tour was actually running. That means every
/// tutorialShowcase-wrapped target (the ToD/NHIE/Meme game HUD) maintained
/// a live AnchoredOverlay/OverlayEntry in the app's root Overlay for its
/// ENTIRE mounted lifetime — the whole game, from start to the result
/// screen — not just while a tour was visible. Combined with
/// OverlayBuilder.build() unconditionally re-marking that entry dirty via
/// addPostFrameCallback on every rebuild (very frequent during live
/// gameplay), and every one of ToD/NHIE/Meme's result screens replacing
/// the tutorial-wrapped game body with a separate widget at the same
/// conditional slot (confirmed identical across all three games), an idle
/// result screen may not pump another frame to process an
/// already-orphaned dirty entry until Quit's own navigation (a GoRouter
/// `context.go()`, forcing a full rebuild of everything under the root
/// Overlay) finally does — by which point the target is long gone.
///
/// THE FIX: ScreenTutorial now only enables showcaseview's overlay
/// machinery (`ShowCaseWidget.enableShowcase`) for the narrow window a
/// tour is actually in flight — see `_overlayEnabled` in
/// screen_tutorial.dart. Before a tour starts, and once it finishes or is
/// aborted, `enableShowcase` is false, so `Showcase.build()` returns the
/// bare child with no AnchoredOverlay at all — for the entire rest of a
/// game, including whenever it genuinely reaches its result screen.
///
/// What's directly, deterministically testable (same documented boundary
/// as every test above in this file — the underlying package race is
/// genuine multi-frame Overlay-portal timing that a synchronous test
/// harness can't force on demand) is the actual mechanism the fix relies
/// on: `enableShowcase` reflects "is a tour actually running" rather than
/// being permanently true, AND the full result->quit widget-teardown
/// sequence completes without throwing.
void _resultScreenQuitTests() {
  const resultQuitTutorialId = 'test_tutorial_result_quit';

  Widget harnessWithResultSwap({
    required List<GlobalKey> steps,
    required bool showResult,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            if (showResult) {
              // The exact shape confirmed identical in ToD (TodEndScreen),
              // NHIE (_GameOverScreen), and Meme (_GameOverScreen): a
              // plain conditional returning a completely different widget
              // at the same tree position the moment the game ends —
              // tearing ScreenTutorial (and its tutorialShowcase-wrapped
              // HUD target) down, not covering it in place.
              return const Center(child: Text('RESULT SCREEN'));
            }
            return ScreenTutorial(
              tutorialId: resultQuitTutorialId,
              steps: steps,
              child: tutorialShowcase(
                context: context,
                showcaseKey: steps.isNotEmpty ? steps[0] : GlobalKey(),
                description: 'hud target',
                child: const SizedBox(width: 40, height: 40),
              ),
            );
          },
        ),
      ),
    );
  }

  setUp(() => sl.tutorialService.endShowing(resultQuitTutorialId));

  testWidgets(
    "ShowCaseWidget.enableShowcase — the fix's actual mechanism — is false "
    'before a tour starts, becomes true only once one is genuinely in '
    'flight, and returns to false once it is aborted',
    (tester) async {
      final key1 = GlobalKey(debugLabel: 'overlayGateStep');
      await tester.pumpWidget(
        harnessWithResultSwap(steps: [key1], showResult: false),
      );

      // Before the two-frame confirmation even begins: no overlay
      // machinery should be live yet.
      expect(
        tester
            .widget<ShowCaseWidget>(find.byType(ShowCaseWidget))
            .enableShowcase,
        isFalse,
      );

      // Frame 1: readiness confirmed once — this is where the fix enables
      // the overlay, one full frame before showcaseview's startShowCase()
      // (frame 2) reads it synchronously (and throws if it's still false).
      await tester.pump();
      expect(
        tester
            .widget<ShowCaseWidget>(find.byType(ShowCaseWidget))
            .enableShowcase,
        isTrue,
      );

      // Frame 2: startShowCase() actually runs — must not throw.
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(sl.tutorialService.shouldShow(resultQuitTutorialId), isFalse);

      // Abort the in-flight tour (steps -> empty, the same didUpdateWidget
      // path already covered above) — the overlay must be disabled again,
      // not left permanently on for the rest of the game.
      await tester.pumpWidget(
        harnessWithResultSwap(steps: const [], showResult: false),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<ShowCaseWidget>(find.byType(ShowCaseWidget))
            .enableShowcase,
        isFalse,
        reason:
            'once aborted/finished, the overlay machinery must not stay '
            'live for the remainder of the game',
      );
    },
  );

  testWidgets(
    'game/tutorial active or initialized -> result screen -> quit/go home '
    '-> tutorial target subtree removed: no attempt to interact with an '
    'inactive target',
    (tester) async {
      final key1 = GlobalKey(debugLabel: 'resultQuitStep');

      // Game screen, tutorial initialized and actively running — mirrors
      // ToD's _TodGameScaffold / NHIE's _GameBody / Meme's _SubmitScreen.
      await tester.pumpWidget(
        harnessWithResultSwap(steps: [key1], showResult: false),
      );
      await tester.pump(); // enable overlay
      await tester.pump(); // startShowCase
      expect(sl.tutorialService.shouldShow(resultQuitTutorialId), isFalse);

      // Reach the result screen: the confirmed-identical widget-type swap
      // from all three games tears the tutorial-wrapped game body (and
      // its target) down entirely.
      await tester.pumpWidget(
        harnessWithResultSwap(steps: [key1], showResult: true),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('RESULT SCREEN'), findsOneWidget);

      // Quit/Go Home: a further full-app rebuild, mirroring GoRouter's
      // context.go() forcing a comprehensive rebuild of everything under
      // the root Overlay — exactly the trigger that surfaces a stale
      // AnchoredOverlay callback in the real bug.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('HOME'))),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('HOME'), findsOneWidget);
      // The tour was interrupted mid-flight, not completed — must remain
      // eligible to run again on a future game (same "aborted, not
      // completed" contract as dispose()'s existing behavior).
      expect(sl.tutorialService.shouldShow(resultQuitTutorialId), isTrue);
    },
  );
}

/// Item 2 (real-device report, follow-up) — a NEW crash was found after
/// the first History fix: `Failed assertion: '_dependents.isEmpty': is
/// not true` inside `InheritedElement.debugDeactivated`
/// (framework.dart), reproducing when a non-admin (or, on iOS, seemingly
/// anyone) opened History from inside an active ToD/NHIE game.
///
/// Root cause: the first fix made ScreenTutorial's `steps` list stay
/// identical while History opened, but ToD (via a ternary) and NHIE
/// (via a `body:` ternary) still SWAPPED THE TARGET'S OWN WIDGET for a
/// completely different widget type at the same tree position —
/// tearing the tutorialShowcase(_hudShowcaseKey)-wrapped target down
/// and rebuilding a fresh one, while ScreenTutorial (an ancestor
/// InheritedWidget host, via ShowCaseWidget's own _InheritedShowCaseView)
/// stayed mounted across that same transition. showcaseview's Showcase
/// widget has an ALWAYS-ACTIVE side effect independent of whether a
/// tour is running — AnchoredOverlay/OverlayBuilder
/// (showcaseview/src/layout_overlays.dart) inserts a real OverlayEntry
/// into the app's root Overlay for as long as the target is mounted,
/// whose builder closure captures the target's own local BuildContext.
/// A partial subtree removal (the target's widget-type swap) happening
/// underneath a surviving ancestor, with that portal straddling the
/// boundary, is exactly the shape Flutter's `_dependents.isEmpty`
/// assertion guards against.
///
/// This suite cannot force the exact multi-frame Overlay-portal timing
/// that makes the assertion fire (same documented boundary as every
/// other test above — that's genuine engine/package-internal timing,
/// not something `pump()` calls dial in on demand). What IS directly,
/// deterministically testable — and is exactly the structural property
/// the fix (a Stack overlay that never removes the target, used by
/// both tod_game_screen.dart and nhie_game_screen.dart) relies on — is
/// whether toggling "History" tears the target's Element/State down
/// and rebuilds it from scratch, or leaves it alone.
class _CountingTarget extends StatefulWidget {
  const _CountingTarget({required this.onInitState});
  final VoidCallback onInitState;
  @override
  State<_CountingTarget> createState() => _CountingTargetState();
}

class _CountingTargetState extends State<_CountingTarget> {
  @override
  void initState() {
    super.initState();
    widget.onInitState();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 40, height: 40);
}

void _structuralInvariantTests() {
  group(
    'ScreenTutorial target lifecycle across a History-style toggle — item 2 '
    "follow-up (the '_dependents.isEmpty' regression)",
    () {
      testWidgets(
        'the FIXED pattern (Stack overlay — target always present, only '
        'covered) never tears the target down: initState runs exactly '
        'once across repeated toggles',
        (tester) async {
          var initCount = 0;
          var showOverlay = false;
          final targetKey = GlobalKey(debugLabel: 'fixedTarget');

          Widget build() => MaterialApp(
            home: Scaffold(
              body: ScreenTutorial(
                tutorialId: 'fixed_pattern_tutorial',
                steps: [targetKey],
                child: Builder(
                  builder: (context) => Stack(
                    children: [
                      tutorialShowcase(
                        context: context,
                        showcaseKey: targetKey,
                        description: 'target',
                        child: _CountingTarget(onInitState: () => initCount++),
                      ),
                      if (showOverlay)
                        const Positioned.fill(
                          child: ColoredBox(color: Colors.black),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );

          await tester.pumpWidget(build());
          await tester.pump();
          // Let the tour's two-frame start confirmation fully settle
          // BEFORE toggling. showcaseview itself does ONE internal,
          // one-time Element churn during startup, unrelated to
          // anything under test here: ShowCaseWidgetState.
          // anchoredOverlayKey starts null and is only assigned a real
          // UniqueKey() via its own addPostFrameCallback
          // (showcase_widget.dart initRootWidget) — Showcase's build()
          // passes that key straight to AnchoredOverlay, so the very
          // first key null->UniqueKey() transition forces exactly one
          // package-internal subtree rebuild (and thus one extra
          // _CountingTarget init) purely from normal startup, with zero
          // toggling. That is a pre-existing showcaseview quirk, not
          // the regression under test — the baseline captured below,
          // AFTER settling, is what must never move again once History
          // starts toggling.
          await tester.pump();
          await tester.pump();
          final baseline = initCount;
          expect(baseline, greaterThanOrEqualTo(1));

          showOverlay = true;
          await tester.pumpWidget(build());
          await tester.pump();
          expect(
            initCount,
            baseline,
            reason: 'after first toggle (overlay ON)',
          );

          showOverlay = false;
          await tester.pumpWidget(build());
          await tester.pump();
          expect(
            initCount,
            baseline,
            reason: 'after second toggle (overlay OFF)',
          );

          showOverlay = true;
          await tester.pumpWidget(build());
          await tester.pump();
          showOverlay = false;
          await tester.pumpWidget(build());
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(
            initCount,
            baseline,
            reason:
                'the target must never be torn down/recreated by toggling '
                'the overlay — this is the exact property that prevents '
                "showcaseview's Overlay/portal from ever racing a partial "
                'subtree removal',
          );
        },
      );

      testWidgets(
        'the OLD, buggy pattern (ternary swap — a different widget type '
        'at the same position) DOES tear the target down and rebuild it '
        '— this is the structural hazard the fix removes',
        (tester) async {
          var initCount = 0;
          var showOther = false;
          final targetKey = GlobalKey(debugLabel: 'oldPatternTarget');

          Widget build() => MaterialApp(
            home: Scaffold(
              body: ScreenTutorial(
                tutorialId: 'old_pattern_tutorial',
                steps: [targetKey],
                child: Builder(
                  builder: (context) => showOther
                      ? const Center(child: Text('other view'))
                      : tutorialShowcase(
                          context: context,
                          showcaseKey: targetKey,
                          description: 'target',
                          child: _CountingTarget(
                            onInitState: () => initCount++,
                          ),
                        ),
                ),
              ),
            ),
          );

          await tester.pumpWidget(build());
          await tester.pump();
          expect(initCount, 1);

          showOther = true;
          await tester.pumpWidget(build());
          await tester.pump();

          showOther = false;
          await tester.pumpWidget(build());
          await tester.pump();

          expect(
            initCount,
            greaterThan(1),
            reason:
                'demonstrates the OLD pattern really did tear the target '
                'down and rebuild a fresh Element/State on every toggle — '
                'the exact condition that let a partial subtree removal '
                "race showcaseview's Overlay-portal side effect",
          );
        },
      );
    },
  );
}
