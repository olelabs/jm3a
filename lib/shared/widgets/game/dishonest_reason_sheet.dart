import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';

/// Reason-required bottom sheet for a "Not honest" honesty vote — shared
/// by every game's vote UI (ToD's full-size _HonestyVoteRow, NHIE/Meme's
/// CompactHonestyVoteButtons) so there's exactly one reason-collection UI,
/// not three. Pops with the trimmed reason string, or null if cancelled.
/// Submit stays disabled until the trimmed text reaches the minimum
/// length, mirroring the server's own `length(trim(p_reason)) < 3` gate
/// exactly (see 20260901090000_honesty_vote_reason.sql) — this is purely
/// responsive UX; the server independently re-validates regardless of
/// what this sheet allows through.
Future<String?> showDishonestReasonSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const DishonestReasonSheet(),
  );
}

class DishonestReasonSheet extends StatefulWidget {
  const DishonestReasonSheet({super.key});

  @override
  State<DishonestReasonSheet> createState() => _DishonestReasonSheetState();
}

class _DishonestReasonSheetState extends State<DishonestReasonSheet> {
  final _ctrl = TextEditingController();
  static const _minLength = 3;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.honestyReasonSheetTitle,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLength: 200,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: context.l10n.honestyReasonHint),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _ctrl.text.trim().length >= _minLength
                      ? () => Navigator.of(context).pop(_ctrl.text.trim())
                      : null,
                  child: Text(context.l10n.submit),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
