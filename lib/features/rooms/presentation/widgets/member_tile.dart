import 'package:flutter/material.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/services/presence_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/honesty_score_line.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../domain/room_entity.dart';

class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    required this.isCurrentUser,
    required this.canModerate,
    this.isWaitingForGameApproval = false,
    this.onKick,
    this.onMute,
    this.onBan,
    this.onTransferOwnership,
    this.onManagePermissions,
  });

  final RoomMemberEntity member;
  final bool isCurrentUser;
  final bool canModerate;

  /// This member has a pending game_rejoin_requests row — physically in
  /// the room, but not yet admitted back into the running game. Distinct
  /// from isAway ("left the game") and isGameMuted ("watching, blocked
  /// from turns") — this member hasn't been decided on yet at all.
  final bool isWaitingForGameApproval;
  final VoidCallback? onKick;
  final VoidCallback? onMute;
  final VoidCallback? onBan;
  final VoidCallback? onTransferOwnership;

  /// Opens the granular permission picker — owner-only. Renamed from the
  /// old single-toggle "make/revoke moderator" action; the sheet it opens
  /// covers grant/adjust/revoke (an empty permission set is a revoke).
  final VoidCallback? onManagePermissions;

  // Premium Plus "away from app" badge — a separate, global presence
  // signal (PresenceService.instance.presenceStream) layered on top of
  // this room's own membership/disconnect state, not derived from it.
  // Gated to Premium Plus so the badge can never render for anyone else,
  // even if the enum value somehow appeared in a stale payload.
  bool get _isPremiumPlus =>
      member.isPremium && member.premiumTier == 'premium_plus';

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
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '${member.seatOrder + 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),

            StreamBuilder<Map<String, UserPresence>>(
              stream: _isPremiumPlus
                  ? PresenceService.instance.presenceStream
                  : const Stream.empty(),
              initialData: _isPremiumPlus
                  ? PresenceService.instance.currentPresence
                  : const {},
              builder: (context, snapshot) {
                final isAway =
                    _isPremiumPlus &&
                    snapshot.data?[member.userId]?.status ==
                        UserPresenceStatus.backgrounded;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UserAvatar(
                      avatarUrl: member.avatarUrl,
                      avatarConfig: member.avatarConfig,
                      isPremium: member.isPremium,
                      displayName: member.displayName,
                      size: 36,
                      showOnlineStatus: true,
                      isOnline: !member.isDisconnected && !member.isAway,
                      isBackgroundedAway: isAway,
                    ),
                    if (member.isMuted)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.mic_off_rounded,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.displayName + (isCurrentUser ? ' (You)' : ''),
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
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.amberOrangeLight.withOpacity(
                                0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              context.l10n.roomsModPermissionsCount(
                                member.moderatorPermissions.length,
                              ),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.amberOrangeLight,
                              ),
                            ),
                          ),
                        ),
                      if (member.isPremium)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            '✦',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFF5A623),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: HonestyScoreLine(
                      honestyPoints: member.honestyPoints,
                      generalScore: member.generalScore,
                      iconSize: 11,
                    ),
                  ),
                  // isAway (game-level kick) keeps the room_members row
                  // intact by design — still a room member, just removed
                  // from the current game — so it must be visually flagged
                  // here or a kicked player silently looks like a normal
                  // present member in this list.
                  if (isWaitingForGameApproval)
                    // Takes priority over every other label — a pending
                    // request means nothing else about their game state is
                    // decided yet (see RoomProvider.pendingRejoinUserIds).
                    Text(
                      context.l10n.roomsWaitingForGameApproval,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (member.isAway)
                    Text(
                      context.l10n.roomsLeftTheGame,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else if (member.isGameMuted)
                    // Distinct from isAway ("left the game") — this member
                    // is still physically present and watching, just
                    // excluded from turn participation by a moderator (see
                    // _durableAwayIds in each game provider, which now
                    // also folds isGameMuted in).
                    Text(
                      context.l10n.roomsMutedInGame,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else if (member.isDisconnected)
                    Text(
                      context.l10n.gameReconnecting,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),

            _ReadyBadge(isReady: member.isReady, isOwner: member.isOwner),

            if (canModerate)
              IconButton(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
            if (onMute != null)
              ListTile(
                leading: Icon(
                  member.isMuted ? Icons.mic_rounded : Icons.mic_off_outlined,
                ),
                title: Text(member.isMuted ? 'Unmute' : l10n.moderationMute),
                onTap: () {
                  Navigator.pop(ctx);
                  onMute?.call();
                },
              ),
            if (onKick != null)
              ListTile(
                leading: const Icon(Icons.person_remove_outlined),
                title: Text(l10n.moderationKick),
                textColor: AppColors.errorRed,
                iconColor: AppColors.errorRed,
                onTap: () {
                  Navigator.pop(ctx);
                  onKick?.call();
                },
              ),
            if (onBan != null)
              ListTile(
                leading: const Icon(Icons.block_rounded),
                title: Text(l10n.moderationBan),
                textColor: AppColors.errorRed,
                iconColor: AppColors.errorRed,
                onTap: () {
                  Navigator.pop(ctx);
                  onBan?.call();
                },
              ),
            if (onManagePermissions != null)
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(
                  member.isModerator
                      ? ctx.l10n.roomsManagePermissionsCount(
                          member.moderatorPermissions.length,
                        )
                      : ctx.l10n.roomsMakeModerator,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onManagePermissions?.call();
                },
              ),
            if (onTransferOwnership != null)
              ListTile(
                leading: const Text('👑', style: TextStyle(fontSize: 18)),
                title: Text(context.l10n.roomsTransferOwnership),
                onTap: () {
                  Navigator.pop(ctx);
                  onTransferOwnership?.call();
                },
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
