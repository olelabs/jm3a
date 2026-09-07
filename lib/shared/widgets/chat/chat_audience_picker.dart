import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/rooms/domain/room_entity.dart';
import '../cards/user_avatar.dart';

/// Item 2 — Premium Plus targeted chat: the sender's current audience
/// choice. `everyone` is the default and is what every non-Premium-Plus
/// sender is permanently limited to; `selected` carries the exact
/// recipient ids/names the composer will send with the next message.
class ChatAudienceSelection {
  const ChatAudienceSelection.everyone()
    : recipientIds = const [],
      recipientNames = const [];
  const ChatAudienceSelection.selected(this.recipientIds, this.recipientNames);

  final List<String> recipientIds;
  final List<String> recipientNames;

  bool get isEveryone => recipientIds.isEmpty;
}

/// The small trigger shown above a Premium Plus sender's chat composer —
/// "[ Everyone ▾ ]" or "[ Only: Ahmed, Sara +1 ▾ ]" per the task's own
/// mockup. Tapping it opens [showChatAudiencePickerSheet]. Never rendered
/// at all for a non-Premium-Plus sender — see each call site's `isPremiumPlus`
/// gate, not a hidden/disabled state here (item 2: "the targeted-audience
/// option should not appear... do not expose hidden targeting controls").
class ChatAudienceTrigger extends StatelessWidget {
  const ChatAudienceTrigger({
    super.key,
    required this.selection,
    required this.onTap,
  });

  final ChatAudienceSelection selection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = selection.isEveryone
        ? l10n.chatAudienceEveryone
        : l10n.chatAudienceOnly(_namesSummary(selection.recipientNames));
    final isTargeted = !selection.isEveryone;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isTargeted
              ? AppColors.brandPurpleMid.withOpacity(0.12)
              : context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: isTargeted
              ? Border.all(color: AppColors.brandPurpleMid.withOpacity(0.4))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTargeted ? Icons.lock_person_rounded : Icons.public_rounded,
              size: 14,
              color: isTargeted
                  ? AppColors.brandPurpleMid
                  : context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isTargeted
                    ? AppColors.brandPurpleMid
                    : context.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more_rounded,
              size: 14,
              color: isTargeted
                  ? AppColors.brandPurpleMid
                  : context.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  String _namesSummary(List<String> names) {
    if (names.isEmpty) return '';
    if (names.length == 1) return names.first;
    final extra = names.length - 1;
    return '${names.first} +$extra';
  }
}

/// Opens the "Everyone / Select people" sheet. [candidates] is the current
/// room/game participant list to pick from — the caller is responsible
/// for it already excluding the sender and anyone who has left (item 2:
/// "prevent selecting users who already left the room/game"); this widget
/// only presents whatever list it's given. Returns the new selection, or
/// null if the sheet was dismissed without a change.
Future<ChatAudienceSelection?> showChatAudiencePickerSheet(
  BuildContext context, {
  required List<RoomMemberEntity> candidates,
  required ChatAudienceSelection current,
}) {
  return showModalBottomSheet<ChatAudienceSelection>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _AudiencePickerSheet(
      candidates: candidates,
      initialSelectedIds: current.recipientIds.toSet(),
    ),
  );
}

class _AudiencePickerSheet extends StatefulWidget {
  const _AudiencePickerSheet({
    required this.candidates,
    required this.initialSelectedIds,
  });

  final List<RoomMemberEntity> candidates;
  final Set<String> initialSelectedIds;

  @override
  State<_AudiencePickerSheet> createState() => _AudiencePickerSheetState();
}

class _AudiencePickerSheetState extends State<_AudiencePickerSheet> {
  late Set<String> _selected = {...widget.initialSelectedIds};
  // "Select people" starts active whenever a prior selection already
  // exists (re-opening the sheet on an already-targeted draft) — matches
  // "preserve the selection until the message is sent or cancelled".
  late bool _selectingPeople = widget.initialSelectedIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.chatAudiencePickerTitle,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            RadioListTile<bool>(
              value: false,
              // ignore: deprecated_member_use
              groupValue: _selectingPeople,
              // ignore: deprecated_member_use
              onChanged: (_) => setState(() => _selectingPeople = false),
              title: Text(l10n.chatAudienceEveryone),
              secondary: const Icon(Icons.public_rounded),
            ),
            RadioListTile<bool>(
              value: true,
              // ignore: deprecated_member_use
              groupValue: _selectingPeople,
              // ignore: deprecated_member_use
              onChanged: (_) => setState(() => _selectingPeople = true),
              title: Text(l10n.chatAudienceSelectPeople),
              secondary: const Icon(Icons.lock_person_rounded),
            ),
            if (_selectingPeople)
              if (widget.candidates.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Text(
                    l10n.chatAudienceNoOneAvailable,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.candidates.length,
                    itemBuilder: (_, i) {
                      final m = widget.candidates[i];
                      final isSelected = _selected.contains(m.userId);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (v) => setState(() {
                          if (v ?? false) {
                            _selected.add(m.userId);
                          } else {
                            _selected.remove(m.userId);
                          }
                        }),
                        secondary: UserAvatar(
                          avatarUrl: m.avatarUrl,
                          avatarConfig: m.avatarConfig,
                          isPremium: m.isPremium,
                          displayName: m.displayName,
                          size: 36,
                        ),
                        title: Text(m.displayName),
                      );
                    },
                  ),
                ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_selectingPeople && _selected.isEmpty)
                      ? null
                      : () {
                          if (!_selectingPeople || _selected.isEmpty) {
                            Navigator.pop(
                              context,
                              const ChatAudienceSelection.everyone(),
                            );
                            return;
                          }
                          final names = widget.candidates
                              .where((m) => _selected.contains(m.userId))
                              .map((m) => m.displayName)
                              .toList();
                          Navigator.pop(
                            context,
                            ChatAudienceSelection.selected(
                              _selected.toList(),
                              names,
                            ),
                          );
                        },
                  child: Text(l10n.chatAudienceApply),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
