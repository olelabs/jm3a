import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../buttons/j_button.dart';

/// Shows a standard confirmation dialog.
///
/// Usage:
/// ```dart
/// final confirmed = await showConfirmDialog(
///   context: context,
///   title: 'Leave room?',
///   message: 'You will lose your progress.',
///   confirmLabel: 'Leave',
///   isDestructive: true,
/// );
/// if (confirmed == true) { ... }
/// ```
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel ?? context.l10n.confirm,
      cancelLabel: cancelLabel ?? context.l10n.cancel,
      isDestructive: isDestructive,
    ),
  );
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Column(
          children: [
            JButton(
              label: confirmLabel,
              onPressed: () => Navigator.of(context).pop(true),
              isDestructive: isDestructive,
              minimumSize: const Size(double.infinity, 48),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
          ],
        ),
      ],
    );
  }
}
