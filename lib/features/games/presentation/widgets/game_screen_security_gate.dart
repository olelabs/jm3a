import 'package:flutter/material.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../settings/presentation/screen_security_service.dart';

/// Route-level back-navigation registry for the active game.
///
/// Every game screen (Tod/Nhie/Meme) renders through the SINGLE
/// `/home/room/:roomId/game` route, wrapped by [GameScreenSecurityGate]. The
/// gate owns the one and only `PopScope(canPop: false)` for that route, so NO
/// back path — Android back, iOS swipe-back, AppBar back, go_router back, or a
/// system pop while an internal sub-view (round history, chat, results) is
/// open — can ever silently pop the game route out to Browse/Home/Lobby.
///
/// The gate itself is game-agnostic; each game screen registers a single
/// [handler] describing what "back" means for it right now: close an open
/// sub-view if one is showing, otherwise run that game's own existing
/// leave/quit flow (the "Quit game?" confirmation). The handler returns true
/// when it has consumed the gesture (which is always, while a game is active),
/// so the gate never falls through to a raw pop.
class GameBackController {
  Future<bool> Function()? _handler;

  /// The currently-registered game handler, if any.
  Future<bool> Function()? get handler => _handler;

  /// Registered by the active game screen; replaces any previous one (only one
  /// game route is ever mounted at a time).
  void register(Future<bool> Function() h) => _handler = h;

  /// Cleared on the game screen's dispose (only if it still owns the slot).
  void unregister(Future<bool> Function() h) {
    if (identical(_handler, h)) _handler = null;
  }
}

/// Exposes the route's [GameBackController] to the game screens below it.
class GameBackGuard extends InheritedWidget {
  const GameBackGuard({
    super.key,
    required this.controller,
    required super.child,
  });

  final GameBackController controller;

  static GameBackController? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<GameBackGuard>()
      ?.controller;

  @override
  bool updateShouldNotify(GameBackGuard oldWidget) =>
      controller != oldWidget.controller;
}

/// Wraps whichever game screen the `/home/room/:roomId/game` route renders
/// (see AppRouter — the switch on gameType picks Tod/Nhie/MemeGameScreen)
/// so screenshot/recording protection is enabled exactly once per game
/// session, for every game mode, without each of the 3 game screens
/// calling ScreenSecurityService individually. Applying it here, at the
/// single shared route builder, is what "works across every game mode
/// without each game implementing it separately" actually means in this
/// codebase — the 3 game screens have no common base class to hook into
/// instead, but they do all render through this one route.
///
/// enable()/disable() are tied to THIS widget's own initState/dispose, not
/// to anything game-state-related — the route being pushed/popped is what
/// defines "inside an active game" here, so protection turns on the
/// instant the game route mounts and off the instant it's gone, regardless
/// of *why* it's gone (back navigation, game-ended auto-pop, or the
/// kicked/banned teardown — all of them pop this route, so all of them
/// correctly clear protection through this same dispose() path).
///
/// Android is fully covered by FLAG_SECURE (ScreenSecurityService.enable())
/// — the OS itself blocks the capture, nothing else to do. iOS has no way
/// to block a capture, only react to one: this widget renders a full-screen
/// obscuring overlay for as long as ScreenProtector reports active screen
/// recording, satisfying "hide sensitive content while recording if full
/// prevention isn't possible" generically for every game mode, the same
/// way the block itself is generic — no per-game overlay code needed.
class GameScreenSecurityGate extends StatefulWidget {
  const GameScreenSecurityGate({super.key, required this.child});

  final Widget child;

  @override
  State<GameScreenSecurityGate> createState() =>
      _GameScreenSecurityGateState();
}

class _GameScreenSecurityGateState extends State<GameScreenSecurityGate> {
  bool _isRecording = false;
  final GameBackController _backController = GameBackController();

  @override
  void initState() {
    super.initState();
    ScreenSecurityService.instance.enable();
    ScreenSecurityService.instance.enableScreenshotDetection(
      _onScreenshotTaken,
      onRecordingChanged: (isRecording) {
        if (mounted) setState(() => _isRecording = isRecording);
      },
    );
  }

  void _onScreenshotTaken() {
    // A screenshot is instantaneous and already happened by the time this
    // fires — there's nothing left to obscure retroactively. Recording is
    // the ongoing case actually handled below via _isRecording.
  }

  @override
  void dispose() {
    ScreenSecurityService.instance.disable();
    super.dispose();
  }

  /// The single authoritative back handler for the whole game route. If a game
  /// screen has registered a handler (always, while active), delegate to it —
  /// it closes an open sub-view or runs that game's proper leave/quit flow.
  /// If none is registered (should not happen while a game is mounted), the
  /// gesture is swallowed rather than allowed to escape the route silently.
  Future<void> _onBack(bool didPop) async {
    if (didPop) return; // already popped (canPop was true) — nothing to guard
    final handler = _backController.handler;
    if (handler != null) {
      await handler();
      return;
    }
    AppLogger.warning(
      'GameScreenSecurityGate: back attempted with no game handler registered '
      '— swallowing to avoid escaping the active game route',
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = !_isRecording
        ? widget.child
        : Stack(
            children: [
              widget.child,
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Icon(
                      Icons.videocam_off_rounded,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ],
          );
    // The ONE PopScope for the entire game route. canPop:false means every
    // back path is intercepted here regardless of which internal sub-view a
    // game screen is currently showing — the fix for sub-views (round history,
    // chat, results) that used to early-return before their own PopScope and
    // let a system back escape to Browse.
    return GameBackGuard(
      controller: _backController,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) => _onBack(didPop),
        child: content,
      ),
    );
  }
}
