import 'notification_entity.dart';

/// The four buckets the "Jma3a / Official Responses" screen groups official
/// moderation/review decisions into (item 3 of the audit). Distinct from
/// [NotificationType] — several notification types/categories can map to
/// the same bucket (e.g. both `room_ban` and `platform_ban` are
/// suspensions), and most [NotificationType] values (chat, wallet, room
/// invites, ...) aren't an "official response" at all and map to null.
enum OfficialResponseCategory { reviews, warnings, bansAndSuspensions, requestsAndDecisions }

/// True for exactly the notifications the "Official Responses" screen
/// should list — everything else (chat, wallet, room, follow, streak, ...)
/// is a normal notification, not an official decision concerning the user.
bool isOfficialResponseNotification(NotificationEntity n) =>
    officialResponseCategoryFor(n) != null;

/// Buckets a notification into one of the four required categories, or null
/// if it isn't an official response at all. Reads `notifications.data`'s
/// `category`/`action`/`status` fields (written by the DB triggers in
/// 20260901091200_official_responses_notifications.sql and, separately, by
/// the pack-review notification fix) rather than inferring from free text,
/// so this stays correct even as new moderation_actions.action values or
/// pack statuses are added.
OfficialResponseCategory? officialResponseCategoryFor(NotificationEntity n) {
  switch (n.type) {
    case NotificationType.packApproved:
    case NotificationType.packRejected:
    case NotificationType.packReview:
      return OfficialResponseCategory.reviews;
    case NotificationType.creatorPrivilegesRemoved:
    case NotificationType.creatorRecoveryRejected:
      return OfficialResponseCategory.warnings;
    case NotificationType.creatorRecoveryApproved:
      return OfficialResponseCategory.requestsAndDecisions;
    case NotificationType.moderation:
      return _moderationCategory(n.data);
    default:
      return null;
  }
}

OfficialResponseCategory? _moderationCategory(Map<String, dynamic> data) {
  final category = data['category'] as String?;
  switch (category) {
    case 'suspension':
      return OfficialResponseCategory.bansAndSuspensions;
    case 'warning':
      return OfficialResponseCategory.warnings;
    case 'creator_verification_review':
    case 'report_response':
      return OfficialResponseCategory.requestsAndDecisions;
    default:
      // A 'moderation' notification predating this categorization (no
      // `data.category`) is still a real official action — surface it
      // under Warnings, the least presumptive bucket, rather than
      // silently dropping it from the screen.
      return OfficialResponseCategory.warnings;
  }
}
