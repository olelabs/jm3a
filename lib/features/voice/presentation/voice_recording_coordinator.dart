import 'package:flutter/widgets.dart';

import 'voice_room_controller.dart';

/// Exposes the current room's [VoiceRoomController] (if any) to widgets
/// below it — the game route provides it via GameScreenSecurityGate so
/// in-game features like voice-proof recording can coordinate with voice.
/// Lookups don't register a dependency (the controller is a ChangeNotifier;
/// listen to it directly if needed).
class VoiceSessionScope extends InheritedWidget {
  const VoiceSessionScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final VoiceRoomController controller;

  static VoiceRoomController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<VoiceSessionScope>()?.controller;

  @override
  bool updateShouldNotify(VoiceSessionScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Outcome of [VoiceRecordingCoordinator.prepareToRecord].
enum VoiceRecordingReadiness {
  /// Safe to start recording (no voice, or the voice mic is confirmed off).
  ready,

  /// The voice mic could not be confirmed muted — do NOT record.
  microphoneBusy,

  /// The recording UI already closed — do nothing.
  closed,
}

/// Keeps one recording UI (e.g. the ToD proof sheet) from competing with
/// LiveKit for the microphone:
///
/// - [prepareToRecord] mutes the voice mic and holds it muted for the
///   duration of the recording; recording must only start on `ready`.
/// - [recordingEnded] releases the hold (stop, completion, failure). The
///   voice mic stays muted — it is never restored automatically.
/// - [close] is the catch-all for every exit (dismissal, submit, widget
///   disposal, navigation): releases the hold and refuses further prepares.
///
/// With no voice controller every call is a no-op and prepare returns
/// `ready`, so recording behaves exactly as without voice.
class VoiceRecordingCoordinator {
  VoiceRecordingCoordinator(this._voice);

  final VoiceRoomController? _voice;
  VoiceMicrophoneHold? _hold;
  bool _closed = false;

  bool get isClosed => _closed;
  bool get isHoldingMicrophone => _hold != null;

  Future<VoiceRecordingReadiness> prepareToRecord() async {
    if (_closed) return VoiceRecordingReadiness.closed;
    final voice = _voice;
    if (voice == null) return VoiceRecordingReadiness.ready;

    final hold = await voice.holdMicrophoneOff();
    if (_closed) {
      hold?.release();
      return VoiceRecordingReadiness.closed;
    }
    if (hold == null) return VoiceRecordingReadiness.microphoneBusy;
    _hold?.release();
    _hold = hold;
    return VoiceRecordingReadiness.ready;
  }

  void recordingEnded() {
    _hold?.release();
    _hold = null;
  }

  void close() {
    _closed = true;
    recordingEnded();
  }
}

/// Calls [VoiceRecordingCoordinator.close] when this widget leaves the tree,
/// however that happens (pop, programmatic removal, parent route disposed).
class VoiceRecordingCleanup extends StatefulWidget {
  const VoiceRecordingCleanup({
    super.key,
    required this.coordinator,
    required this.child,
  });

  final VoiceRecordingCoordinator coordinator;
  final Widget child;

  @override
  State<VoiceRecordingCleanup> createState() => _VoiceRecordingCleanupState();
}

class _VoiceRecordingCleanupState extends State<VoiceRecordingCleanup> {
  @override
  void dispose() {
    widget.coordinator.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
