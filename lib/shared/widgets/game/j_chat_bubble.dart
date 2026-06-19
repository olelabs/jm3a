import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/j_theme_extension.dart';

/// ═══════════════════════════════════════════════════════════════
/// JChatBubble — Room chat message bubble
/// ═══════════════════════════════════════════════════════════════
class JChatBubble extends StatelessWidget {
  const JChatBubble({
    super.key,
    required this.message,
    required this.senderName,
    required this.timestamp,
    this.avatarUrl,
    this.isMe          = false,
    this.isOptimistic  = false,
    this.showSender    = true,
    this.isSystem      = false,
  });

  final String  message;
  final String  senderName;
  final String  timestamp;
  final String? avatarUrl;
  final bool    isMe;
  final bool    isOptimistic;   // not yet confirmed by server
  final bool    showSender;     // false when same sender as previous bubble
  final bool    isSystem;       // system messages (joined, left, game started)

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // System message — centered, subtle
    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color:        theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.badge),
            ),
            child: Text(
              message,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    // My message — right-aligned, primary colour bubble
    if (isMe) {
      return Padding(
        padding: const EdgeInsets.only(
            left: 64, right: AppSpacing.md, bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft:     Radius.circular(16),
                        topRight:    Radius.circular(16),
                        bottomLeft:  Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOptimistic)
                        Icon(Icons.schedule_rounded, size: 10,
                            color: theme.colorScheme.onSurfaceVariant),
                      Text(
                        ' $timestamp',
                        style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: AppDuration.fast)
          .slideX(begin: 0.04, end: 0, curve: AppCurves.enter);
    }

    // Other player's message — left-aligned
    return Padding(
      padding: const EdgeInsets.only(
          left: AppSpacing.md, right: 64, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          if (showSender)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 2),
              child: CircleAvatar(
                radius: 14,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl!) : null,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: avatarUrl == null
                    ? Text(
                        senderName.isNotEmpty
                            ? senderName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            )
          else
            const SizedBox(width: 36),

          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showSender)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 2),
                    child: Text(
                      senderName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:      theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkElevated
                        : AppColors.neutral100,
                    borderRadius: const BorderRadius.only(
                      topLeft:     Radius.circular(4),
                      topRight:    Radius.circular(16),
                      bottomLeft:  Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 2),
                  child: Text(
                    timestamp,
                    style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppDuration.fast)
        .slideX(begin: -0.04, end: 0, curve: AppCurves.enter);
  }
}


/// ═══════════════════════════════════════════════════════════════
/// JNotificationTile — Notification list item
/// ═══════════════════════════════════════════════════════════════
class JNotificationTile extends StatelessWidget {
  const JNotificationTile({
    super.key,
    required this.emoji,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.isRead    = false,
    this.onTap,
    this.onDismiss,
  });

  final String    emoji;
  final String    title;
  final String    body;
  final String    timeAgo;
  final bool      isRead;
  final VoidCallback?  onTap;
  final VoidCallback?  onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key:        ValueKey(title + timeAgo),
      direction:  DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding:   const EdgeInsets.only(right: 20),
        color:     theme.colorScheme.error.withOpacity(0.12),
        child:     Icon(Icons.delete_outline_rounded,
            color: theme.colorScheme.error),
      ),
      onDismissed: (_) => onDismiss?.call(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isRead
              ? null
              : theme.colorScheme.primaryContainer.withOpacity(0.06),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md - 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji container
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            )),
                      ),
                      Text(timeAgo,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      if (!isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            color:  theme.colorScheme.primary,
                            shape:  BoxShape.circle,
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(body,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// ═══════════════════════════════════════════════════════════════
/// JReconnectBanner — Shown when connection is lost
/// ═══════════════════════════════════════════════════════════════
class JReconnectBanner extends StatelessWidget {
  const JReconnectBanner({
    super.key,
    required this.isReconnecting,
    this.message,
    this.onRetry,
  });

  final bool         isReconnecting;
  final String?      message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isReconnecting
        ? AppColors.warningAmber
        : AppColors.errorRed;

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color:   color.withOpacity(0.1),
      child: Row(
        children: [
          if (isReconnecting)
            const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2,
                  color: AppColors.warningAmber),
            )
          else
            Icon(Icons.wifi_off_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message ?? (isReconnecting
                  ? 'Reconnecting…'
                  : 'Connection lost.'),
              style: TextStyle(
                color:      color,
                fontSize:   12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null && !isReconnecting)
            TextButton(
              onPressed:   onRetry,
              style:       TextButton.styleFrom(
                foregroundColor: color,
                visualDensity:   VisualDensity.compact,
                padding:         const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    ).animate().slideY(begin: -1, end: 0, duration: AppDuration.normal,
        curve: AppCurves.enter);
  }
}
