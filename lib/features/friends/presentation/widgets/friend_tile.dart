import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/services/presence_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../data/friends_repository.dart';

// ── Online indicator ──────────────────────────────────────────────────────────

class OnlineIndicator extends StatelessWidget {
  const OnlineIndicator({
    super.key,
    required this.status,
    this.size = 10,
    this.showLabel = false,
  });

  final UserPresenceStatus status;
  final double size;
  final bool showLabel;

  Color get _color => switch (status) {
    UserPresenceStatus.online => AppColors.successGreen,
    UserPresenceStatus.inGame => AppColors.brandOrangeLight,
    UserPresenceStatus.offline => AppColors.textTertiaryLight,
  };

  String get _label => switch (status) {
    UserPresenceStatus.online => 'Online',
    UserPresenceStatus.inGame => 'In Game',
    UserPresenceStatus.offline => 'Offline',
  };

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: status != UserPresenceStatus.offline
            ? [BoxShadow(color: _color.withOpacity(0.5), blurRadius: 4)]
            : null,
      ),
    );

    if (!showLabel) return dot;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: 4),
        Text(
          _label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _color,
          ),
        ),
      ],
    );
  }
}

// ── Friend tile ───────────────────────────────────────────────────────────────

class FriendTile extends StatelessWidget {
  const FriendTile({
    super.key,
    required this.friend,
    required this.status,
    this.roomId,
    this.onTap,
    this.onJoinRoom,
    this.onRemove,
    this.onBlock,
  });

  final FriendEntity friend;
  final UserPresenceStatus status;
  final String? roomId;
  final VoidCallback? onTap;
  final VoidCallback? onJoinRoom;
  final VoidCallback? onRemove;
  final VoidCallback? onBlock;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: JCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Avatar with presence badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                  avatarUrl: friend.avatarUrl,
                  avatarConfig: friend.avatarConfig,
                  isPremium: friend.isPremium,
                  displayName: friend.displayName,
                  size: 44,
                  showOnlineStatus: false,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(1.5),
                    child: OnlineIndicator(status: status, size: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (friend.username != null)
                    Text(
                      '@${friend.username}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                  // In-game label
                  if (status == UserPresenceStatus.inGame)
                    Row(
                      children: [
                        const Text('🎮', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text(
                          'Playing now',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.brandOrangeLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Join room button
                if (onJoinRoom != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: FilledButton.tonal(
                      onPressed: onJoinRoom,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.brandOrangeLight.withOpacity(
                          0.12,
                        ),
                        foregroundColor: AppColors.warningAmber,
                      ),
                      child: const Text('Join'),
                    ),
                  ),

                // More menu
                if (onRemove != null || onBlock != null)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    itemBuilder: (_) => [
                      if (onRemove != null)
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.person_remove_outlined),
                              SizedBox(width: 8),
                              Text('Remove friend'),
                            ],
                          ),
                        ),
                      if (onBlock != null)
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(
                                Icons.block_rounded,
                                color: AppColors.errorRed,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Block',
                                style: TextStyle(color: AppColors.errorRed),
                              ),
                            ],
                          ),
                        ),
                    ],
                    onSelected: (v) {
                      if (v == 'remove') onRemove?.call();
                      if (v == 'block') onBlock?.call();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
