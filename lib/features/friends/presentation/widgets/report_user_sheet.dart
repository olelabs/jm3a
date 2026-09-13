import 'package:flutter/material.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';

/// Item 9 — reports a user's profile. Deliberately mirrors
/// ReportPackSheet's exact structure (reason radio list + optional
/// details + submit) so reporting a person reads as the same product
/// feature as reporting a pack, not a second, differently-designed report
/// flow. Reuses the SAME `reports` table/reason enum/duplicate-handling
/// (see FriendsRepository.reportUser) — this widget only collects input.
class ReportUserSheet extends StatefulWidget {
  const ReportUserSheet({
    super.key,
    required this.targetUserId,
    required this.onSubmit,
  });

  final String targetUserId;

  /// Returns whether the report was actually submitted — only a true
  /// result pops the sheet, matching ReportPackSheet's contract.
  final Future<bool> Function(String reason, String? details) onSubmit;

  @override
  State<ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends State<ReportUserSheet> {
  String? _reason;
  final _detailsCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _submitFailed = false;

  // report_type_enum values relevant to a PERSON (vs. ReportPackSheet's
  // pack-relevant subset, which includes 'cheating' instead of these) —
  // same enum, same 'reports' table, a different sensible slice of it.
  List<(String, String)> _reasons(BuildContext context) => [
    ('harassment', context.l10n.friendsReportReasonHarassment),
    ('spam', context.l10n.packReportReasonSpam),
    ('hate_speech', context.l10n.packReportReasonHateSpeech),
    ('impersonation', context.l10n.friendsReportReasonImpersonation),
    ('underage', context.l10n.friendsReportReasonUnderage),
    ('other', context.l10n.packReportReasonOther),
  ];

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            context.l10n.friendsReportUserTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.errorRed,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.friendsReportHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          ..._reasons(context).map(
            (r) => RadioListTile<String>(
              title: Text(r.$2),
              value: r.$1,
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _detailsCtrl,
            maxLength: 500,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: context.l10n.packAdditionalDetailsOptional,
              counterText: '',
            ),
          ),
          if (_submitFailed) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.packReportFailed,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.errorRed,
              ),
            ),
          ],
          const SizedBox(height: 16),

          JButton(
            label: context.l10n.packSubmitReport,
            isLoading: _isSubmitting,
            isDestructive: true,
            // Same double-tap-safe gating ReportPackSheet uses — checked
            // directly on _isSubmitting rather than only on _reason, so a
            // rapid second tap during an in-flight submission is a
            // guaranteed no-op regardless of frame timing.
            onPressed: (_reason == null || _isSubmitting)
                ? null
                : () async {
                    setState(() {
                      _isSubmitting = true;
                      _submitFailed = false;
                    });
                    final ok = await widget.onSubmit(
                      _reason!,
                      _detailsCtrl.text.trim().isEmpty
                          ? null
                          : _detailsCtrl.text.trim(),
                    );
                    if (!mounted) return;
                    if (ok) {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        _isSubmitting = false;
                        _submitFailed = true;
                      });
                    }
                  },
          ),
        ],
      ),
    );
  }
}
