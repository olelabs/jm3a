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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _started || !_shouldRun) return;
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
      final targetsReady =
          widget.steps.every((k) => k.currentContext?.mounted ?? false);
      if (!targetsReady) {
        _scheduled = false;
        return;
      }
      // Reserve the id so a rebuild / fast re-entry can't stack a second tour.
      if (!sl.tutorialService.beginShowing(widget.tutorialId)) return;
      _started = true;
      _showcase?.startShowCase(widget.steps);
    });
  }

  void _onFinish() {
    _finished = true;
    sl.tutorialService.markCompleted(widget.tutorialId);
  }

  /// Skip (barrier tap): stop immediately and never show this tutorial again.
  void _skip() {
    if (_finished) return;
    _finished = true;
    sl.tutorialService.markCompleted(widget.tutorialId);
    try {
      _showcase?.dismiss();
    } catch (_) {}
  }

  @override
  void dispose() {
    // Leaving the screen mid-tour: tear the overlay down safely and release the
    // lock. NOT marked completed — an interrupted tour may replay next time.
    if (_started && !_finished) {
      try {
        _showcase?.dismiss();
      } catch (_) {}
      sl.tutorialService.endShowing(widget.tutorialId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: _onFinish,
      // Barrier stays tappable so a tap outside the highlight = skip.
      disableBarrierInteraction: false,
      builder: (showcaseContext) {
        if (_shouldRun) _scheduleStart(showcaseContext);
        return _TutorialScope(
          onSkip: _skip,
          child: widget.child,
        );
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
