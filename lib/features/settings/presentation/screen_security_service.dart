import 'package:jma3a/core/utils/app_logger.dart';
import 'package:screen_protector/screen_protector.dart';

/// Blocks screenshots and screen recording while active — applied once per
/// game session via GameScreenSecurityGate (see
/// jma3a/lib/features/games/presentation/widgets/game_screen_security_gate.dart),
/// which wraps the single shared `/home/room/:roomId/game` route builder
/// (app_router.dart) instead of each of the 3 game screens calling this
/// individually — one integration point covers every game mode without
/// duplicating enable/disable logic per screen.
///
/// Platform reality (this is an Apple/Google limitation, not a package
/// limitation):
///  - Android: [preventScreenshotOn] sets FLAG_SECURE, which fully blocks
///    BOTH screenshots and screen recording at the OS level. The screen
///    just appears black/blank in any capture.
///  - iOS: Apple provides no API to block screenshots — only to detect
///    them after the fact. [protectDataLeakageOn] hides app content from
///    the OS task-switcher snapshot (a real leak vector on its own), and
///    [enableScreenshotDetection] lets the app react (e.g. warn the room)
///    when a screenshot is taken, since it can't be prevented outright.
class ScreenSecurityService {
  ScreenSecurityService._();
  static final ScreenSecurityService instance = ScreenSecurityService._();

  bool _enabled = false;
  bool get isEnabled => _enabled;

  /// Call once when entering a game session. Safe to call multiple times —
  /// nested game screens (e.g. punishment/end screens within the same
  /// session) can each call this without it re-triggering or conflicting.
  Future<void> enable() async {
    if (_enabled) return;
    _enabled = true;
    try {
      await ScreenProtector.preventScreenshotOn();
      // protectDataLeakageOn is Android-only (no-op on iOS, per the
      // package's own doc comment) — protectDataLeakageWithBlur is its
      // iOS-only counterpart (blurs content in the OS task-switcher
      // snapshot). Calling both covers task-switcher-snapshot leakage on
      // both platforms; each simply no-ops on the platform it doesn't
      // apply to.
      await ScreenProtector.protectDataLeakageOn();
      await ScreenProtector.protectDataLeakageWithBlur();
    } catch (e) {
      AppLogger.warning('ScreenSecurityService: enable failed: $e');
    }
  }

  /// Call once when leaving the game session (dispose of the security
  /// gate) — guarantees protection is never left on after the game route
  /// is popped, regardless of which screen/route triggered the exit (back
  /// button, kicked, game ended, app-level navigation reset).
  Future<void> disable() async {
    if (!_enabled) return;
    _enabled = false;
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
      await ScreenProtector.protectDataLeakageWithBlurOff();
      ScreenProtector.removeListener();
    } catch (e) {
      AppLogger.warning('ScreenSecurityService: disable failed: $e');
    }
  }

  /// iOS only — screenshots can't be blocked there, only detected. Pass a
  /// callback to react when one happens (e.g. broadcast a room event so
  /// other players know, Snapchat-style), and/or [onRecordingChanged] to
  /// react to ongoing screen recording starting/stopping (e.g.
  /// GameScreenSecurityGate uses this to show an obscuring overlay for as
  /// long as recording is active — a screenshot is instantaneous and
  /// already happened by the time [onScreenshotTaken] fires, but recording
  /// is ongoing and can still be reacted to while it's happening). Both
  /// no-op on Android (screenshots/recording are already fully blocked by
  /// FLAG_SECURE, nothing to detect or react to).
  void enableScreenshotDetection(
    void Function() onScreenshotTaken, {
    void Function(bool isRecording)? onRecordingChanged,
  }) {
    try {
      ScreenProtector.addListener(onScreenshotTaken, (isRecording) {
        AppLogger.debug('ScreenSecurityService: iOS recording=$isRecording');
        onRecordingChanged?.call(isRecording);
      });
    } catch (e) {
      AppLogger.warning('ScreenSecurityService: listener setup failed: $e');
    }
  }
}
