import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../domain/room_entity.dart';

class CreateRoomSheet extends StatefulWidget {
  const CreateRoomSheet({super.key});

  @override
  State<CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<CreateRoomSheet> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  RoomVisibility _visibility = RoomVisibility.public;
  int    _maxPlayers = 6;
  String _emoji     = '🎮';
  bool   _isCreating = false;

  static const _emojis = ['🎮', '🎯', '🎲', '🃏', '🎪', '🎉', '🌟', '🔥', '💥', '😂'];

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isCreating = true);
    try {
      final userId = context.read<AuthProvider>().currentUser!.id;
      final room = await sl.roomRepository.createRoom(
        ownerId:    userId,
        name:       _nameCtrl.text.trim(),
        visibility: _visibility,
        maxPlayers: _maxPlayers,
        coverEmoji: _emoji,
      );
      if (mounted) Navigator.pop(context, room);
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(context.l10n.errorUnexpected);
        setState(() => _isCreating = false);
      }
    }
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
      child: Form(
        key: _formKey,
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

            Text(l10n.roomsCreate,
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),

            // Emoji selector + name row
            Row(
              children: [
                // Emoji picker
                GestureDetector(
                  onTap: () => _pickEmoji(context),
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(_emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _create(),
                    decoration: const InputDecoration(
                      labelText: 'Room name',
                      hintText: 'e.g. Friday Night Fun',
                    ),
                    validator: (v) {
                      if ((v?.trim() ?? '').length < 3)
                        return 'At least 3 characters';
                      if ((v?.trim() ?? '').length > 60)
                        return 'Maximum 60 characters';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Visibility
            Text('Visibility', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<RoomVisibility>(
              segments: [
                ButtonSegment(
                  value: RoomVisibility.public,
                  label: Text(context.l10n.roomsPublic),
                  icon: const Icon(Icons.public_rounded),
                ),
                ButtonSegment(
                  value: RoomVisibility.private,
                  label: Text(context.l10n.roomsPrivate),
                  icon: const Icon(Icons.lock_outline_rounded),
                ),
              ],
              selected: {_visibility},
              onSelectionChanged: (v) =>
                  setState(() => _visibility = v.first),
              style: const ButtonStyle(
                  visualDensity: VisualDensity.compact),
            ),
            const SizedBox(height: 20),

            // Max players slider
            Row(
              children: [
                Text('Max players', style: theme.textTheme.labelLarge),
                const Spacer(),
                Text('$_maxPlayers',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            Slider(
              value: _maxPlayers.toDouble(),
              min: 2, max: 12, divisions: 10,
              label: '$_maxPlayers',
              onChanged: (v) =>
                  setState(() => _maxPlayers = v.round()),
            ),
            const SizedBox(height: 8),

            JButton(
              label: l10n.roomsCreate,
              onPressed: _create,
              isLoading: _isCreating,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickEmoji(BuildContext context) async {
    final theme = context.theme;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 16, runSpacing: 16,
          children: _emojis.map((e) => GestureDetector(
            onTap: () {
              setState(() => _emoji = e);
              Navigator.pop(ctx);
            },
            child: Text(e,
                style: TextStyle(
                    fontSize: 36,
                    decoration: e == _emoji
                        ? TextDecoration.underline
                        : null)),
          )).toList(),
        ),
      ),
    );
  }
}
