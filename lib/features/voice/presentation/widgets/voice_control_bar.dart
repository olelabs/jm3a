import 'package:flutter/material.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/voice_repository.dart';
import '../voice_room_controller.dart';

/// Compact voice strip for the lobby. Manual mode: Join, Leave, mic toggle,
/// state and the last issue. Auto mode (room voice switch): no Join/Leave —
/// connection is automatic — just state, mic toggle, admin-mute notice and a
/// Retry after a failure; hidden entirely while the room's voice is off. Renders nothing for hidden spectators or while the
/// user has no membership yet. Mic controls exist only for a connected
/// speaker who is not a spectator; speakers always start muted.
class VoiceControlBar extends StatelessWidget {
  const VoiceControlBar({super.key, required this.controller});

  final VoiceRoomController controller;

  static const joinKey = Key('voice_join');
  static const leaveKey = Key('voice_leave');
  static const micKey = Key('voice_mic');
  static const statusKey = Key('voice_status');
  static const issueKey = Key('voice_issue');
  static const retryKey = Key('voice_retry');
  static const adminMutedKey = Key('voice_admin_muted');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final status = controller.status;
    final active = controller.isActive;
    final blocker = controller.joinBlocker;
    final auto = controller.isAutoMode;

    if (auto && !controller.isRoomVoiceEnabled) {
      return const SizedBox.shrink();
    }
    if (!active &&
        (blocker == VoiceIssue.hiddenSpectator ||
            blocker == VoiceIssue.notActiveMember)) {
      return const SizedBox.shrink();
    }

    final isSpectator = controller.membership?.isSpectator ?? false;
    final showMic =
        active && controller.role == VoiceRole.speaker && !isSpectator;
    // "Waiting for approval" is a live condition, not history: drop it once
    // the host has let the member back in.
    final issue =
        controller.issue == VoiceIssue.awaitingApproval &&
            blocker != VoiceIssue.awaitingApproval
        ? null
        : controller.issue ?? blocker;
    final issueText = _issueText(l10n, issue);

    final String statusText;
    final IconData statusIcon;
    switch (status) {
      case VoiceConnectionStatus.idle:
        statusText = '';
        statusIcon = Icons.headset_off_rounded;
      case VoiceConnectionStatus.requestingToken:
      case VoiceConnectionStatus.connecting:
        statusText = l10n.voiceConnecting;
        statusIcon = Icons.headset_rounded;
      case VoiceConnectionStatus.reconnecting:
        statusText = l10n.voiceReconnecting;
        statusIcon = Icons.headset_rounded;
      case VoiceConnectionStatus.connected:
        statusText = controller.role == VoiceRole.speaker
            ? l10n.voiceSpeaking
            : l10n.voiceListening;
        statusIcon = Icons.headset_mic_rounded;
    }
    final busy =
        status == VoiceConnectionStatus.requestingToken ||
        status == VoiceConnectionStatus.connecting ||
        status == VoiceConnectionStatus.reconnecting;
    final listenOnly =
        status == VoiceConnectionStatus.connected &&
        controller.role == VoiceRole.listener &&
        isSpectator;
    final adminMuted =
        showMic && controller.isVoiceMutedByAdmin && !isSpectator;
    // Auto mode retry: after a failure or a pause, never for live conditions
    // (waiting for approval, voice off) that resolve on their own.
    final showRetry =
        auto &&
        !active &&
        blocker == null &&
        (controller.isAutoConnectSuppressed || issue != null) &&
        issue != VoiceIssue.voiceDisabled;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (busy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      statusIcon,
                      size: 20,
                      color: status == VoiceConnectionStatus.connected
                          ? AppColors.successGreen
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusText,
                      key: statusKey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  if (showMic) _micButton(context),
                  if (auto)
                    if (showRetry)
                      FilledButton.tonalIcon(
                        key: retryKey,
                        style: _compact,
                        onPressed: controller.retry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(l10n.voiceRetry),
                      )
                    else
                      const SizedBox.shrink()
                  else if (active)
                    TextButton(
                      key: leaveKey,
                      style: _compact,
                      onPressed: controller.leave,
                      child: Text(l10n.voiceLeave),
                    )
                  else
                    FilledButton.tonalIcon(
                      key: joinKey,
                      style: _compact,
                      onPressed: blocker == null ? controller.join : null,
                      icon: const Icon(Icons.headset_rounded, size: 18),
                      label: Text(
                        _isRejoin(controller.issue)
                            ? l10n.voiceRejoin
                            : l10n.voiceJoin,
                      ),
                    ),
                ],
              ),
              if (adminMuted)
                Text(
                  l10n.voiceMutedByAdmin,
                  key: adminMutedKey,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              if (listenOnly)
                Text(
                  l10n.voiceListenOnlyNotice,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (issueText != null)
                Text(
                  issueText,
                  key: issueKey,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: issue == VoiceIssue.awaitingApproval
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _micButton(BuildContext context) {
    final l10n = context.l10n;
    final on = controller.isMicrophoneEnabled;
    return IconButton(
      key: micKey,
      tooltip: on ? l10n.voiceMicOn : l10n.voiceMicOff,
      onPressed: controller.canToggleMicrophone
          ? () => controller.setMicrophoneEnabled(!on)
          : null,
      icon: Icon(
        on ? Icons.mic_rounded : Icons.mic_off_rounded,
        color: on ? AppColors.successGreen : null,
      ),
    );
  }

  // The app theme gives buttons an infinite minimum width (full-width CTAs);
  // inside this Row they must size to their label instead.
  static final _compact = ButtonStyle(
    minimumSize: WidgetStateProperty.all(const Size(0, 36)),
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 12),
    ),
  );

  static bool _isRejoin(VoiceIssue? issue) => switch (issue) {
    VoiceIssue.connectionLost ||
    VoiceIssue.backgroundTimeout ||
    VoiceIssue.joinedElsewhere ||
    VoiceIssue.roleChanged ||
    VoiceIssue.failed => true,
    _ => false,
  };

  static String? _issueText(AppLocalizations l10n, VoiceIssue? issue) =>
      switch (issue) {
        null || VoiceIssue.hiddenSpectator => null,
        VoiceIssue.unavailable => l10n.voiceUnavailable,
        VoiceIssue.awaitingApproval => l10n.voiceAwayPendingApproval,
        VoiceIssue.rateLimited => l10n.voiceErrorRateLimited,
        VoiceIssue.offline => l10n.noInternetConnection,
        VoiceIssue.failed => l10n.voiceErrorFailed,
        VoiceIssue.roleChanged => l10n.voiceRoleChangedListenOnly,
        VoiceIssue.joinedElsewhere => l10n.voiceDisconnectedElsewhere,
        VoiceIssue.connectionLost ||
        VoiceIssue.backgroundTimeout => l10n.voiceDisconnected,
        VoiceIssue.microphoneUnavailable => l10n.voiceMicPermissionDenied,
        VoiceIssue.voiceDisabled => l10n.voiceDisabledForRoom,
        VoiceIssue.notActiveMember ||
        VoiceIssue.membershipLost ||
        VoiceIssue.speakerNotAllowed ||
        VoiceIssue.bannedFromRoom ||
        VoiceIssue.roomClosed ||
        VoiceIssue.roomNotFound ||
        VoiceIssue.notAllowed ||
        VoiceIssue.removed => l10n.voiceErrorNotAllowed,
      };
}
