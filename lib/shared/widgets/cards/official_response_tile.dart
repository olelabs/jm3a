import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/notifications/domain/notification_entity.dart';
import '../../../features/notifications/domain/official_response_category.dart';
import 'j_card.dart';

/// One row on the "Jma3a / Official Responses" screen (item 3 of the
/// audit). Extracted as a public, provider-free widget (mirrors
/// ExplorePersonCard/HonestyVoteRow's established pattern this session) —
/// takes a plain [NotificationEntity] + callbacks instead of a live
/// NotificationProvider, so it can be pumped directly in a widget test
/// against the real AppTheme at narrow widths/RTL/large text.
class OfficialResponseTile extends StatelessWidget {
  const OfficialResponseTile({
    super.key,
    required this.notification,
    required this.languageCode,
    this.onTap,
  });

  final NotificationEntity notification;
  final String languageCode;

  /// Opens the related object (e.g. the reviewed pack) and/or marks the
  /// notification read — optional so a test that doesn't care about
  /// navigation doesn't need to supply one.
  final VoidCallback? onTap;

  Color _accentColor(OfficialResponseCategory? category) => switch (category) {
    OfficialResponseCategory.bansAndSuspensions => AppColors.errorRed,
    OfficialResponseCategory.warnings => AppColors.amberOrangeLight,
    OfficialResponseCategory.reviews => AppColors.brandPurpleMid,
    OfficialResponseCategory.requestsAndDecisions => AppColors.brandPurpleMid,
    null => AppColors.brandPurpleMid,
  };

  IconData _icon(OfficialResponseCategory? category) => switch (category) {
    OfficialResponseCategory.bansAndSuspensions => Icons.block_rounded,
    OfficialResponseCategory.warnings => Icons.warning_amber_rounded,
    OfficialResponseCategory.reviews => Icons.rate_review_outlined,
    OfficialResponseCategory.requestsAndDecisions => Icons.fact_check_outlined,
    null => Icons.campaign_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final category = officialResponseCategoryFor(notification);
    final color = _accentColor(category);
    final title = notification.titleFor(languageCode);
    final body = notification.bodyFor(languageCode);
    final expiresAt = notification.expiresAt;
    final dateFmt = DateFormat.yMMMd(languageCode);

    return JCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      borderColor: notification.isRead
          ? null
          : color.withValues(alpha: 0.35),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon(category), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: notification.isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsetsDirectional.only(start: 6),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      dateFmt.format(notification.createdAt),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (expiresAt != null)
                      Text(
                        context.l10n.officialResponseExpiresOn(
                          dateFmt.format(expiresAt),
                        ),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
