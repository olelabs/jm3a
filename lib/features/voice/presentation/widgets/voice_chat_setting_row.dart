import 'package:flutter/material.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../shared/widgets/settings_row_widgets.dart';
import '../../../rooms/presentation/room_provider.dart';
import '../../data/voice_repository.dart';

/// Room setting: voice chat on/off. Unlike the other settings rows this does
/// NOT write room_settings directly (the column is server-guarded): it asks
/// jma3a-api, which enforces permissions and the Basic-tier daily allowance,
/// then tells the room to re-read the value. The switch only reflects a
/// change once the server accepted it.
class VoiceChatSettingRow extends StatefulWidget {
  const VoiceChatSettingRow({super.key, required this.room, this.repository});

  final RoomProvider room;

  /// Injectable for tests; defaults to the real repository.
  final VoiceRepository? repository;

  @override
  State<VoiceChatSettingRow> createState() => _VoiceChatSettingRowState();
}

class _VoiceChatSettingRowState extends State<VoiceChatSettingRow> {
  bool _busy = false;

  Future<void> _set(bool enabled) async {
    final roomId = widget.room.room?.id;
    if (_busy || roomId == null) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    try {
      final now = await (widget.repository ?? VoiceRepository())
          .setRoomVoiceEnabled(roomId: roomId, enabled: enabled);
      await widget.room.announceVoiceEnabledChanged(now);
    } on Failure catch (f) {
      if (mounted) {
        context.showErrorSnackBar(
          f.code == 'voice_daily_limit_reached'
              ? l10n.voiceDailyLimitReached
              : l10n.voiceSettingFailed,
        );
      }
      await widget.room.refreshVoiceEnabled();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = widget.room.settings.voiceEnabled;
    final canManage = widget.room.canManageSettings;
    return Column(
      key: const Key('voice_chat_setting'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AbsorbPointer(
          absorbing: _busy || !canManage,
          child: Opacity(
            opacity: _busy || !canManage ? 0.6 : 1,
            child: SettingsSwitchRow(
              label: l10n.voiceChatSetting,
              icon: enabled
                  ? Icons.headset_mic_rounded
                  : Icons.headset_off_rounded,
              value: enabled,
              onChanged: _set,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 4),
          child: Text(
            enabled
                ? l10n.voiceChatSettingOnSubtitle
                : l10n.voiceChatSettingOffSubtitle,
            key: const Key('voice_chat_setting_status'),
            style: context.theme.textTheme.labelSmall?.copyWith(
              color: context.theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
