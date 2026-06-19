import 'package:flutter/material.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../domain/room_entity.dart';

class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    required this.isCurrentUser,
    required this.canModerate,
    this.onKick,
    this.onMute,
    this.onBan,
    this.onTransferOwnership,
    this.onToggleModerator,
  });

  final RoomMemberEntity member;
  final bool isCurrentUser;
  final bool canModerate;
  final VoidCallback? onKick;
  final VoidCallback? onMute;
  final VoidCallback? onBan;
  final VoidCallback? onTransferOwnership;
  final VoidCallback? onToggleModerator;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? theme.colorScheme.primaryContainer.withOpacity(0.2)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: isCurrentUser
              ? Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Seat number
            SizedBox(
              width: 20,
              child: Text('${member.seatOrder + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),

            // Avatar with disconnect indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                  avatarUrl: member.avatarUrl,
                  displayName: member.displayName,
                  size: 36,
                  showOnlineStatus: true,
                  isOnline: !member.isDisconnected,
                ),
                if (member.isMuted)
                  Positioned(
                    right: -2, bottom: -2,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: theme.colorScheme.surface, width: 1),
                      ),
                      child: const Icon(Icons.mic_off_rounded,
                          size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),

            // Name + badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.displayName +
                              (isCurrentUser ? ' (You)' : ''),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCurrentUser
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (member.isOwner)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text('👑', style: TextStyle(fontSize: 14)),
                        )
                      else if (member.isModerator)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.amberOrangeLight.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('MOD',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.amberOrangeLight)),
                          ),
                        ),
                    ],
                  ),
                  if (member.isDisconnected)
                    Text('Reconnecting…',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error)),
                ],
              ),
            ),

            // Ready badge
            _ReadyBadge(isReady: member.isReady, isOwner: member.isOwner),

            // Moderation menu
            if (canModerate)
              IconButton(
                icon: Icon(Icons.more_vert_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: () => _showMenu(context),
              ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                member.isMuted ? Icons.mic_rounded : Icons.mic_off_outlined,
              ),
              title: Text(member.isMuted ? 'Unmute' : l10n.moderationMute),
              onTap: () { Navigator.pop(ctx); onMute?.call(); },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined),
              title: Text(l10n.moderationKick),
              textColor: AppColors.errorRed,
              iconColor: AppColors.errorRed,
              onTap: () { Navigator.pop(ctx); onKick?.call(); },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded),
              title: Text(l10n.moderationBan),
              textColor: AppColors.errorRed,
              iconColor: AppColors.errorRed,
              onTap: () { Navigator.pop(ctx); onBan?.call(); },
            ),
            if (onToggleModerator != null)
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(member.isModerator
                    ? 'Revoke moderator'
                    : 'Make moderator'),
                onTap: () { Navigator.pop(ctx); onToggleModerator?.call(); },
              ),
            if (onTransferOwnership != null)
              ListTile(
                leading: const Text('👑', style: TextStyle(fontSize: 18)),
                title: const Text('Transfer ownership'),
                onTap: () { Navigator.pop(ctx); onTransferOwnership?.call(); },
              ),
          ],
        ),
      ),
    );
  }
}

class _ReadyBadge extends StatelessWidget {
  const _ReadyBadge({required this.isReady, required this.isOwner});
  final bool isReady;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    if (isOwner) return const SizedBox(width: 24);
    return Icon(
      isReady
          ? Icons.check_circle_rounded
          : Icons.radio_button_unchecked_rounded,
      size: 20,
      color: isReady
          ? AppColors.successGreen
          : context.colorScheme.onSurfaceVariant.withOpacity(0.35),
    );
  }
}
