import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../domain/room_entity.dart';
import '../room_provider.dart';

/// Bottom sheet for the ban flow — allows owner to select ban duration.
class BanConfirmSheet extends StatefulWidget {
  const BanConfirmSheet({super.key, required this.targetMember});
  final RoomMemberEntity targetMember;

  @override
  State<BanConfirmSheet> createState() => _BanConfirmSheetState();
}

class _BanConfirmSheetState extends State<BanConfirmSheet> {
  Duration? _duration = const Duration(hours: 24); // null = permanent
  final _reasonCtrl = TextEditingController();
  bool _isBanning = false;

  List<(Duration?, String)> _durations(BuildContext context) => [
    (const Duration(minutes: 30), context.l10n.moderationDuration30Min),
    (const Duration(hours: 1),    context.l10n.moderationDuration1Hour),
    (const Duration(hours: 24),   context.l10n.moderationDuration24Hours),
    (const Duration(days: 7),     context.l10n.moderationDuration7Days),
    (null,                        context.l10n.moderationDurationPermanent),
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _ban() async {
    setState(() => _isBanning = true);
    await context.read<RoomProvider>().banPlayer(
      widget.targetMember.userId,
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
      duration: _duration,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n  = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              const Icon(Icons.block_rounded, color: AppColors.errorRed),
              const SizedBox(width: 8),
              Text(l10n.moderationBan,
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.errorRed)),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            context.l10n.roomsBanConfirm(widget.targetMember.displayName),
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          Text(context.l10n.roomsDuration, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8, runSpacing: 8,
            children: _durations(context).map((d) {
              final isSelected = d.$1 == _duration;
              return ChoiceChip(
                label: Text(d.$2),
                selected: isSelected,
                onSelected: (_) => setState(() => _duration = d.$1),
                selectedColor: AppColors.errorRed.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.errorRed : null,
                  fontWeight: isSelected ? FontWeight.w700 : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Reason input
          TextField(
            controller: _reasonCtrl,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: l10n.moderationReasonOptional,
              prefixIcon: const Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: 20),

          JButton(
            label: l10n.moderationBanPlayer,
            onPressed: _ban,
            isLoading: _isBanning,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}
