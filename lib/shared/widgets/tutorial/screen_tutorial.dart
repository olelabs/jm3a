import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';

/// Reusable first-time contextual tutorial wrapper.
///
/// Wrap a screen's body in a [ScreenTutorial], give it a stable [tutorialId]
/// and the ordered [steps] (the [GlobalKey]s of the [tutorialShowcase]-wrapped
/// controls to highlight). The first time the screen is shown — and only if
/// [enabled] is true, the tutorial isn't already completed, and at least one
/// step target is actually mounted — it auto-plays the guided highlights after
/// the frame is laid out. Completion is remembered via [AppTutorialService]; it
/// never runs again.
///
/// Deliberately inert with respect to app state: it owns only a showcase
/// overlay. It never reads/writes Provider, realtime, game, or room state and
/// never navigates, so it cannot interfere with the multiplayer lifecycle. If a
/// target isn't present for the current role/state, simply leave its key out of
/// [steps] (or pass `enabled: false`) and that step is skipped rather than
/// breaking the screen.
class ScreenTutorial extends StatefulWidget {
  const ScreenTutorial({
    super.key,
    required this.tutorialId,
    required this.steps,
    required this.child,
    this.enabled = true,
  });

  /// Stable id from [TutorialIds]; also the persistence key.
  final String tutorialId;

  /// Ordered highlight targets. Only include keys whose [tutorialShowcase]
  /// widgets are actually in the tree for the current role/state.
  final List<GlobalKey> steps;

  /// Extra gate — e.g. wait until room data + the user's role are known so the
  /// step list is final. When false the tour never starts (and any running one
  /// is left to natural teardown).
  final bool enabled;

  final Widget child;

  @override
  State<ScreenTutorial> createState() => _ScreenTutorialState();
}

class _ScreenTutorialState extends State<ScreenTutorial> {
  ShowCaseWidgetState? _showcase;
  bool _scheduled = false;
  bool _started = false;
  bool _finished = false;
  bool _livenessCheckScheduled = false;

  /// ROOT CAUSE of the "Cannot get renderObject of inactive element" crash
  /// reported from showcaseview's AnchoredOverlay/LayoutBuilder specifically
  /// during game-result -> Quit/Go Home navigation (verified by reading
  /// showcaseview 3.0.0's Showcase.build(): `AnchoredOverlay(showOverlay:
  /// true, ...)` is passed UNCONDITIONALLY whenever `_enableShowcase`
  /// (== ShowCaseWidget.enableShowcase, a package-wide flag, not "is this
  /// step the active one") is true — which is the package's default and
  /// what every call site here left it at. That means every
  /// [tutorialShowcase]-wrapped target (e.g. the game HUD) maintains a
  /// live AnchoredOverlay/OverlayEntry in the app's root Overlay for its
  /// ENTIRE mounted lifetime — the whole game, from start to the result
  /// screen — regardless of whether a tour is running, was ever started,
  /// or finished long ago. OverlayBuilder.build() (layout_overlays.dart)
  /// unconditionally re-marks that entry dirty via addPostFrameCallback on
  /// EVERY rebuild of the target, which is frequent during live gameplay.
  /// The result screen replaces the tutorial-wrapped game body with a
  /// separate widget (a real teardown, not an overlay toggle — same shape
  /// in ToD/NHIE/Meme), which should synchronously dispose that overlay
  /// machinery — but the WHOLE reason this entry exists continuously
  /// rather than only while a tour is actually visible is what creates the
  /// exposure window in the first place: an idle result screen may not
  /// pump another frame until Quit's own navigation does, by which point
  /// the target is gone.
  ///
  /// Fix, owned entirely here (not in showcaseview, not via a delay): only
  /// enable the package's overlay machinery for the narrow window a tour
  /// is actually in flight. [_overlayEnabled] drives [ShowCaseWidget.
  /// enableShowcase] below — false before a tour starts and once it
  /// finishes/aborts, so `Showcase.build()` returns the bare child (no
  /// AnchoredOverlay at all) for the entire rest of the game, including
  /// whenever a game genuinely reaches its result screen. This doesn't
  /// need to (and cannot, see _abort's own note) touch the still-mid-tour
  /// case any differently than before — dispose()'s existing abort
  /// remains the backstop there, unchanged.
  bool _overlayEnabled = false;

  bool get _shouldRun =>
      widget.enabled &&
      widget.steps.isNotEmpty &&
      sl.tutorialService.shouldShow(widget.tutorialId);

  void _scheduleStart(BuildContext showcaseContext) {
    // Capture the ShowCaseWidget state now (valid during build); the post-frame
    // callback then starts the tour once the targets have been laid out.
    _showcase = ShowCaseWidget.of(showcaseContext);
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _confirmAndStart(false),
    );
  }

  /// Turns the showcase overlay machinery on/off ([_overlayEnabled]),
  /// rebuilding so a fresh [ShowCaseWidget] actually carries the new
  /// `enableShowcase` value down to every [tutorialShowcase]-wrapped
  /// target. Never called from [dispose] — calling setState during
  /// dispose is illegal, and nothing needs to rebuild on the way out
  /// anyway; [_abort] plain-assigns instead for that path.
  void _setOverlayEnabled(bool value) {
    if (_overlayEnabled == value) return;
    if (mounted) {
      setState(() => _overlayEnabled = value);
    } else {
      _overlayEnabled = value;
    }
  }

  /// [confirmed] is false on the first pass, true on the second.
  ///
  /// Two-frame confirmation, not a delay: showcaseview's own
  /// findRenderObject() access is several REAL frames further out than
  /// either of these checks (see didUpdateWidget's doc comment for the exact
  /// chain) — a single readiness snapshot right after "Go to Lobby" can look
  /// fine and still be invalidated a frame or two later while room/role
  /// state keeps resyncing (this is what "the previous fix did not
  /// completely resolve" turned out to mean: didUpdateWidget only reacts
  /// AFTER a tour has already committed via startShowCase; it did nothing to
  /// stop a tour from committing on a target that was ready for exactly one
  /// frame and then wasn't). Requiring readiness to hold across two
  /// consecutive real frames — driven by actual rebuilds, not a timer —
  /// meaningfully narrows that window for free; didUpdateWidget remains the
  /// backstop for whatever's left once a tour has actually started.
  void _confirmAndStart(bool confirmed) {
    if (!mounted || _started || !_shouldRun) {
      _scheduled = false;
      return;
    }
    // CRITICAL: do NOT start the tour unless EVERY step target is actually
    // mounted. showcaseview's AnchoredOverlay calls findRenderObject() on
    // each target, which throws "Cannot get renderObject of inactive
    // element" for any target whose Element is inactive/defunct — exactly
    // what happens when this screen is being (re)built mid-navigation (e.g.
    // returning to the lobby right after a game via Go to Lobby): the frame
    // fires before the targets have re-attached. Reset _scheduled so a later
    // build (the lobby rebuilds on every provider notify) retries once the
    // targets are genuinely laid out, instead of crashing or silently never
    // running.
    final targetsReady = widget.steps.every(
      (k) => k.currentContext?.mounted ?? false,
    );
    if (!targetsReady) {
      _scheduled = false;
      _setOverlayEnabled(false);
      return;
    }
    if (!confirmed) {
      // Enable the overlay machinery NOW, one full frame before
      // startShowCase() is actually called below — showcaseview's
      // startShowCase() reads ShowCaseWidgetState.widget.enableShowcase
      // SYNCHRONOUSLY (throwing if false), so it must already be true by
      // the time that call happens. setState() here schedules a
      // ScreenTutorial rebuild that lands (build → layout → paint, all
      // BEFORE any postFrameCallback fires) before the confirmed=true
      // pass's own postFrameCallback runs, so ShowCaseWidget's
      // `enableShowcase` param has already propagated down to every
      // tutorialShowcase-wrapped target's Showcase widget by then.
      _setOverlayEnabled(true);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _confirmAndStart(true),
      );
      return;
    }
    // Reserve the id so a rebuild / fast re-entry can't stack a second tour.
    if (!sl.tutorialService.beginShowing(widget.tutorialId)) {
      _scheduled = false;
      _setOverlayEnabled(false);
      return;
    }
    _started = true;
    _showcase?.startShowCase(widget.steps);
  }

  void _onFinish() {
    _finished = true;
    sl.tutorialService.markCompleted(widget.tutorialId);
    // Tour genuinely complete — every tutorialShowcase-wrapped target goes
    // back to a bare child (no AnchoredOverlay) for the rest of this
    // screen's life, closing the exposure window this whole mechanism
    // exists to close (see _overlayEnabled's own doc comment).
    _setOverlayEnabled(false);
  }

  /// Skip (barrier tap): stop immediately and never show this tutorial again.
  void _skip() {
    if (_finished) return;
    _finished = true;
    sl.tutorialService.markCompleted(widget.tutorialId);
    try {
      _showcase?.dismiss();
    } catch (_) {}
    _setOverlayEnabled(false);
  }

  /// Tear a mid-flight tour down safely and release the showing-lock, WITHOUT
  /// marking it completed (an aborted tour is allowed to replay later).
  /// Shared by [dispose] (screen torn down) and [didUpdateWidget] (screen
  /// stays up but the step list changed under us — see its doc comment).
  void _abort() {
    try {
      _showcase?.dismiss();
    } catch (_) {}
    sl.tutorialService.endShowing(widget.tutorialId);
    _started = false;
    // Plain assignment, not _setOverlayEnabled: this runs from dispose()
    // too, where calling setState is illegal. didUpdateWidget's own
    // caller already rebuilds right after this returns, so build() below
    // still picks up the new value there; dispose() doesn't need a
    // rebuild at all — the subtree is going away regardless.
    _overlayEnabled = false;
  }

  @override
  void didUpdateWidget(covariant ScreenTutorial oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ROOT CAUSE of the intermittent "Cannot get renderObject of inactive
    // element" crash this guards against: showcaseview's startShowCase()
    // does NOT touch any RenderObject synchronously — it only flips a flag
    // via setState(). The actual key.currentContext!.findRenderObject() call
    // happens several addPostFrameCallback hops later, deep inside the
    // package's own OverlayBuilder/AnchoredOverlay machinery (verified by
    // reading showcaseview 3.0.0's source: OverlayBuilder.didUpdateWidget
    // schedules a postFrameCallback to sync the overlay, which itself
    // schedules ANOTHER postFrameCallback to rebuild the OverlayEntry, whose
    // builder is what finally calls findRenderObject() — a 2-3 frame gap
    // after we called startShowCase). widget.steps here (e.g. the lobby's
    // role-dependent _lobbyTutorialSteps) is recomputed from live room state
    // that is often still settling in exactly that window — right after
    // "Go to Lobby" navigation, while connection/role/membership resync. If a
    // step's target is no longer part of the tree by the time the package's
    // deferred callback finally reaches it, its Element can be transiently
    // `inactive` (deactivated, not yet unmounted — `mounted` stays true for
    // that whole window, so the old one-shot mounted-only check here could
    // not catch this), and findRenderObject() throws.
    //
    // Fix: don't try to out-guess the package's internal timing. Instead,
    // react the moment the step list actually changes (this build already
    // proves the underlying state changed, since _lobbyTutorialSteps — and
    // any sibling screen's equivalent — is a pure function of that state):
    // abort the in-flight tour immediately and let it safely re-arm once
    // steps stabilize, rather than let a stale snapshot of GlobalKeys race
    // the package's deferred render-object access.
    if (_started && !_finished && !listEquals(oldWidget.steps, widget.steps)) {
      _abort();
      _scheduled = false;
    }
  }

  @override
  void dispose() {
    // Leaving the screen mid-tour: tear the overlay down safely and release the
    // lock. NOT marked completed — an interrupted tour may replay next time.
    if (_started && !_finished) {
      _abort();
    }
    super.dispose();
  }

  // Item 2 (real-device report: iOS "History" red-screen crash) — a
  // THIRD case neither dispose() nor didUpdateWidget() above covers:
  // ScreenTutorial itself stays mounted AND widget.steps stays the same
  // list, but the ACTUAL WIDGET underneath a step's GlobalKey gets
  // unmounted by a sibling/descendant rebuild — exactly what ToD/Meme/
  // NHIE's "History" toggle does (swapping Scaffold.body to a history
  // panel while ScreenTutorial keeps wrapping the same Scaffold above
  // it). showcaseview's own overlay rebuild is several
  // addPostFrameCallback hops deferred (see didUpdateWidget's own doc
  // comment for the full chain) — if a step's GlobalKey.currentContext
  // is null by the time that deferred callback finally runs,
  // showcaseview's internal GetPosition leaves its own `late final
  // _box`/`_boxOffset` fields unassigned, and the very next access
  // throws a raw, uncaught LateInitializationError from inside a
  // framework overlay-build callback — a full red/grey error screen,
  // not something a widget-level try/catch here could ever intercept.
  //
  // Fix: whenever this widget rebuilds while a tour is active (a
  // sibling's setState — like the History toggle — already triggers
  // this rebuild, since ScreenTutorial sits above the swapped content),
  // schedule a post-frame liveness check. By the time a post-frame
  // callback runs, this frame's own element disposals (if the target
  // was removed THIS build) have already completed, so
  // `currentContext?.mounted` reads the true, settled state — not a
  // mid-reconciliation snapshot. If any step's target is gone, abort
  // the tour safely before showcaseview's own deferred callback chain
  // ever gets to touch the dead key.
  void _scheduleLivenessCheck() {
    if (_livenessCheckScheduled) return;
    _livenessCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _livenessCheckScheduled = false;
      if (!mounted || !_started || _finished) return;
      final anyTargetGone = widget.steps.any(
        (k) => !(k.currentContext?.mounted ?? false),
      );
      if (anyTargetGone) {
        // setState (not a bare _abort() call): unlike didUpdateWidget,
        // nothing else rebuilds this widget right after a postFrame
        // callback returns — without this, _abort's plain-assigned
        // _overlayEnabled=false would never actually reach a fresh
        // ShowCaseWidget(enableShowcase: false).
        setState(_abort);
        _scheduled = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_started && !_finished) _scheduleLivenessCheck();
    return ShowCaseWidget(
      onFinish: _onFinish,
      // See _overlayEnabled's own doc comment: false here means every
      // tutorialShowcase-wrapped target's Showcase.build() returns its
      // bare child, with no AnchoredOverlay/OverlayEntry at all — the fix
      // for showcaseview keeping a live overlay for a target's entire
      // mounted lifetime regardless of tour state.
      enableShowcase: _overlayEnabled,
      // Barrier stays tappable so a tap outside the highlight = skip.
      disableBarrierInteraction: false,
      builder: (showcaseContext) {
        if (_shouldRun) _scheduleStart(showcaseContext);
        return _TutorialScope(onSkip: _skip, child: widget.child);
      },
    );
  }
}

/// Carries the current tour's skip action down to [tutorialShowcase] so every
/// highlighted step can be dismissed by tapping outside it.
class _TutorialScope extends InheritedWidget {
  const _TutorialScope({required this.onSkip, required super.child});
  final VoidCallback onSkip;

  static _TutorialScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TutorialScope>();

  @override
  bool updateShouldNotify(_TutorialScope oldWidget) => false;
}

/// Wrap a control you want the tutorial to highlight. Applies the Jma3a look
/// (brand-purple tooltip, rounded corners, themed text) so the tour never looks
/// like stock package UI, and wires "tap outside = skip". [description] is
/// required and [title] optional — keep both concise, they render inside a small
/// overlay. Direction/RTL follows the ambient [Directionality] (Arabic works
/// without extra config).
Widget tutorialShowcase({
  required BuildContext context,
  required GlobalKey showcaseKey,
  required String description,
  required Widget child,
  String? title,
  ShapeBorder? targetShape,
}) {
  final scope = _TutorialScope.maybeOf(context);
  final onSurface = context.colorScheme.onSurface;
  return Showcase(
    key: showcaseKey,
    title: title,
    description: description,
    tooltipBackgroundColor: AppColors.brandPurpleMid,
    textColor: Colors.white,
    overlayColor: Colors.black,
    overlayOpacity: 0.72,
    tooltipBorderRadius: BorderRadius.circular(14),
    targetBorderRadius: BorderRadius.circular(12),
    targetPadding: const EdgeInsets.all(6),
    titleTextStyle: context.textTheme.titleSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
    ),
    descTextStyle: context.textTheme.bodySmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.95),
      height: 1.35,
    ),
    // Tap anywhere outside the highlighted control ends the whole tour.
    onBarrierClick: scope?.onSkip,
    child: DefaultTextStyle.merge(
      style: TextStyle(color: onSurface),
      child: child,
    ),
  );
}
