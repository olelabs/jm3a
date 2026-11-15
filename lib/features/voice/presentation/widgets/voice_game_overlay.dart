import 'package:flutter/material.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/voice_repository.dart';
import '../voice_room_controller.dart';

/// In-game voice control: a small round button on the start edge that
/// expands into a pill with status, mic toggle (speakers only) and Leave.
/// Shown only while a voice session exists — joining happens in the lobby —
/// and never offers mic controls to spectators.
///
/// Positioning (start edge, slightly below center, inside the safe area)
/// keeps it clear of the game screens' app bars and bottom action rows.
/// Only the button/pill itself takes touches; the rest passes through.
class VoiceGameOverlay extends StatefulWidget {
  const VoiceGameOverlay({super.key, required this.controller});

  final VoiceRoomController controller;

  static const buttonKey = Key('voice_overlay_button');
  static const pillKey = Key('voice_overlay_pill');
  static const micKey = Key('voice_overlay_mic');
  static const leaveKey = Key('voice_overlay_leave');
  static const statusKey = Key('voice_overlay_status');

  @override
  State<VoiceGameOverlay> createState() => _VoiceGameOverlayState();
}

class _VoiceGameOverlayState extends State<VoiceGameOverlay> {
  bool _expanded = false;

  VoiceRoomController get _c => widget.controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        if (!_c.isActive || _c.isDisposed) return const SizedBox.shrink();
        return SafeArea(
          child: Align(
            alignment: const AlignmentDirectional(-1, 0.3),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 150),
                child: _expanded ? _pill(context) : _button(context),
              ),
            ),
          ),
        );
      },
    );
  }

  bool get _isSpeaker =>
      _c.role == VoiceRole.speaker && !(_c.membership?.isSpectator ?? false);

  bool get _busy =>
      _c.status == VoiceConnectionStatus.requestingToken ||
      _c.status == VoiceConnectionStatus.connecting ||
      _c.status == VoiceConnectionStatus.reconnecting;

  Widget _statusIcon(BuildContext context, {double size = 20}) {
    if (_busy) {
      return SizedBox(
        width: size - 2,
        height: size - 2,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (_isSpeaker) {
      final on = _c.isMicrophoneEnabled;
      return Icon(
        on ? Icons.mic_rounded : Icons.mic_off_rounded,
        size: size,
        color: on ? AppColors.successGreen : null,
      );
    }
    return Icon(
      Icons.headset_rounded,
      size: size,
      color: AppColors.successGreen,
    );
  }

  String _statusText(BuildContext context) {
    final l10n = context.l10n;
    return switch (_c.status) {
      VoiceConnectionStatus.reconnecting => l10n.voiceReconnecting,
      VoiceConnectionStatus.connected
          when _isSpeaker && _c.isVoiceMutedByAdmin =>
        l10n.voiceMemberMutedTooltip,
      VoiceConnectionStatus.connected =>
        _isSpeaker ? l10n.voiceSpeaking : l10n.voiceListening,
      _ => l10n.voiceConnecting,
    };
  }

  Widget _surface(BuildContext context, Widget child) {
    final theme = context.theme;
    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.92),
      elevation: 3,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _button(BuildContext context) {
    return Tooltip(
      message: _statusText(context),
      child: _surface(
        context,
        InkWell(
          key: VoiceGameOverlay.buttonKey,
          onTap: () => setState(() => _expanded = true),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: _statusIcon(context)),
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context) {
    final l10n = context.l10n;
    final on = _c.isMicrophoneEnabled;
    return _surface(
      context,
      Padding(
        key: VoiceGameOverlay.pillKey,
        padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusIcon(context, size: 18),
            const SizedBox(width: 8),
            // Flexible: on narrow phones the label ellipsizes instead of
            // pushing the buttons off-screen.
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  _statusText(context),
                  key: VoiceGameOverlay.statusKey,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.textTheme.labelMedium,
                ),
              ),
            ),
            if (_isSpeaker)
              IconButton(
                key: VoiceGameOverlay.micKey,
                tooltip: on ? l10n.voiceMicOn : l10n.voiceMicOff,
                onPressed: _c.canToggleMicrophone
                    ? () => _c.setMicrophoneEnabled(!on)
                    : null,
                icon: Icon(
                  on ? Icons.mic_rounded : Icons.mic_off_rounded,
                  color: on ? AppColors.successGreen : null,
                ),
              ),
            // Auto mode (room voice switch): no Leave — voice follows the room.
            if (!_c.isAutoMode)
              IconButton(
                key: VoiceGameOverlay.leaveKey,
                tooltip: l10n.voiceLeave,
                onPressed: () {
                  setState(() => _expanded = false);
                  _c.leave();
                },
                icon: const Icon(Icons.call_end_rounded),
                color: context.theme.colorScheme.error,
              ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => setState(() => _expanded = false),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
