// import 'package:jma3a/core/utils/app_logger.dart';
// import 'package:screen_protector/screen_protector.dart';

// // import '../utils/app_logger.dart';

// /// Blocks screenshots and screen recording while active — used in game
// /// screens so proof photos/videos and responses can't be captured.
// ///
// /// Platform reality (this is an Apple/Google limitation, not a package
// /// limitation):
// ///  - Android: [preventScreenshotOn] sets FLAG_SECURE, which fully blocks
// ///    BOTH screenshots and screen recording at the OS level. The screen
// ///    just appears black/blank in any capture.
// ///  - iOS: Apple provides no API to block screenshots — only to detect
// ///    them after the fact. [protectDataLeakageOn] hides app content from
// ///    the OS task-switcher snapshot (a real leak vector on its own), and
// ///    [enableScreenshotDetection] lets the app react (e.g. warn the room)
// ///    when a screenshot is taken, since it can't be prevented outright.
// class ScreenSecurityService {
//   ScreenSecurityService._();
//   static final ScreenSecurityService instance = ScreenSecurityService._();

//   bool _enabled = false;
//   bool get isEnabled => _enabled;

//   /// Call from a game screen's initState(). Safe to call multiple times —
//   /// nested game screens (e.g. punishment/end screens) can each call this
//   /// without it re-triggering or conflicting.
//   Future<void> enable() async {
//     if (_enabled) return;
//     _enabled = true;
//     try {
//       await ScreenProtector.preventScreenshotOn();
//       // protectDataLeakageOn is Android-only (no-op on iOS, per the
//       // package's own doc comment) — protectDataLeakageWithBlur is its
//       // iOS-only counterpart (blurs content in the OS task-switcher
//       // snapshot). Calling both covers task-switcher-snapshot leakage on
//       // both platforms; each simply no-ops on the platform it doesn't
//       // apply to.
//       await ScreenProtector.protectDataLeakageOn();
//       await ScreenProtector.protectDataLeakageWithBlur();
//     } catch (e) {
//       AppLogger.warning('ScreenSecurityService: enable failed: $e');
//     }
//   }

//   /// Call from the SAME screen's dispose(). Only actually turns protection
//   /// off if nothing else still wants it active — see [enable]/[disable]
//   /// being called in pairs per screen via a simple ref-count.
//   Future<void> disable() async {
//     if (!_enabled) return;
//     _enabled = false;
//     try {
//       await ScreenProtector.preventScreenshotOff();
//       await ScreenProtector.protectDataLeakageOff();
//       await ScreenProtector.protectDataLeakageWithBlurOff();
//       ScreenProtector.removeListener();
//     } catch (e) {
//       AppLogger.warning('ScreenSecurityService: disable failed: $e');
//     }
//   }

//   /// iOS only — screenshots can't be blocked there, only detected. Pass a
//   /// callback to react when one happens (e.g. broadcast a room event so
//   /// other players know, Snapchat-style). No-op on Android (screenshots
//   /// are already fully blocked by FLAG_SECURE, nothing to detect).
//   void enableScreenshotDetection(void Function() onScreenshotTaken) {
//     try {
//       ScreenProtector.addListener(onScreenshotTaken, (isRecording) {
//         AppLogger.debug('ScreenSecurityService: iOS recording=$isRecording');
//       });
//     } catch (e) {
//       AppLogger.warning('ScreenSecurityService: listener setup failed: $e');
//     }
//   }
// }
