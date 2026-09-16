import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/notifications/domain/user_request_entity.dart';
import 'j_card.dart';

/// The localized name of a request type.
String userRequestTypeLabel(AppLocalizations l10n, UserRequestType type) =>
    switch (type) {
      UserRequestType.accountDeletion => l10n.requestTypeAccountDeletion,
      UserRequestType.packReport => l10n.requestTypePackReport,
      UserRequestType.userReport => l10n.requestTypeUserReport,
      UserRequestType.creatorVerification =>
        l10n.requestTypeCreatorVerification,
      UserRequestType.creatorRecoveryAppeal =>
        l10n.requestTypeCreatorRecoveryAppeal,
    };

/// The localized name of a RAW backend status.
///
/// Covers every value the source tables can actually hold — `pending`/
/// `approved`/`rejected` from the review tables, and report_status_enum's
/// `open`/`under_review`/`resolved`/`dismissed`. Anything else falls
/// through to the raw string rather than being relabelled or hidden, so a
/// status added server-side later still displays truthfully instead of
/// silently reading as something it is not.
String userRequestStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'pending' => l10n.requestStatusPending,
      'open' => l10n.requestStatusOpen,
      'under_review' => l10n.requestStatusUnderReview,
      'approved' => l10n.requestStatusApproved,
      'rejected' => l10n.requestStatusRejected,
      'resolved' => l10n.requestStatusResolved,
      'dismissed' => l10n.requestStatusDismissed,
      _ => status,
    };

/// The localized name of a `reports.target_type`.
String reportTargetTypeLabel(AppLocalizations l10n, String targetType) =>
    switch (targetType) {
      'profile' => l10n.reportTargetProfile,
      'pack' => l10n.reportTargetPack,
      'room' => l10n.reportTargetRoom,
      'chat_message' => l10n.reportTargetChatMessage,
      _ => targetType,
    };

/// One row in the "My Requests" tab: what the user asked for, when, and
/// where it currently stands.
///
/// Provider-free by design (same convention as [OfficialResponseTile]) —
/// it takes a plain [UserRequestEntity] plus an optional cancel callback,
/// so it can be pumped directly in a widget test.
class UserRequestTile extends StatelessWidget {
  const UserRequestTile({
    super.key,
    required this.request,
    required this.languageCode,
    this.onCancel,
  });

  final UserRequestEntity request;
  final String languageCode;

  /// Supplied only for a request the backend can genuinely cancel — see
  /// [UserRequestEntity.canCancel]. Null hides the action entirely rather
  /// than showing a disabled one.
  final VoidCallback? onCancel;

  /// Outstanding requests are the ones the user is waiting on, so they get
  /// the accent; a settled one is deliberately quieter.
  static const _openStatuses = {'pending', 'open', 'under_review'};

  Color _statusColor(String status) => switch (status) {
    'approved' || 'resolved' => AppColors.successGreen,
    'rejected' || 'dismissed' => AppColors.errorRed,
    _ => AppColors.amberOrangeLight,
  };

  IconData _icon(UserRequestType type) => switch (type) {
    UserRequestType.accountDeletion => Icons.person_remove_outlined,
    UserRequestType.packReport => Icons.flag_outlined,
    UserRequestType.userReport => Icons.report_gmailerrorred_outlined,
    UserRequestType.creatorVerification => Icons.verified_outlined,
    UserRequestType.creatorRecoveryAppeal => Icons.restore_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final dateFmt = DateFormat.yMMMd(languageCode);
    final statusColor = _statusColor(request.status);
    final isOpen = _openStatuses.contains(request.status);

    final packTitle = request.targetTitleFor(languageCode);
    final targetType = request.reportTargetType;

    return JCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderColor: isOpen ? statusColor.withValues(alpha: 0.35) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon(request.type), color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userRequestTypeLabel(l10n, request.type),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // What the request was about, when the backend actually
                // records it. A generic report shows only the KIND of
                // target — never who, and never the moderation outcome.
                if (packTitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    packTitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else if (targetType != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    reportTargetTypeLabel(l10n, targetType),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userRequestStatusLabel(l10n, request.status),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      l10n.requestSubmittedOn(
                        dateFmt.format(request.submittedAt),
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (request.decidedAt != null)
                      Text(
                        l10n.requestAnsweredOn(
                          dateFmt.format(request.decidedAt!),
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),

                if (onCancel != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      label: Text(l10n.settingsCancelAccountDeletion),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
