import 'package:flutter/material.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/services/presence_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/games/engine/base_game_engine.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../data/friends_repository.dart';

/// GameType.toDbString() -> display name, or null if unresolvable/absent.
/// Shared by OnlineIndicator's label and FriendTile's in-game row so the
/// two premium-detail surfaces never disagree.
String? resolveGameDisplayName(String? gameType) {
  if (gameType == null) return null;
  final resolved = GameType.values.cast<GameType?>().firstWhere(
    (g) => g?.toDbString() == gameType,
    orElse: () => null,
  );
  return resolved?.displayName;
}

// ── Online indicator ──────────────────────────────────────────────────────────

class OnlineIndicator extends StatelessWidget {
  const OnlineIndicator({
    super.key,
    required this.status,
    this.size = 10,
    this.showLabel = false,
    this.roomStatus,
    this.gameType,
    this.showDetail = false,
  });

  final UserPresenceStatus status;
  final double size;
  final bool showLabel;

  /// 'lobby' or 'in_game' — see PresenceService.setInGame. Only rendered
  /// when [showDetail] is true.
  final String? roomStatus;

  /// GameType.toDbString(), only meaningful when roomStatus == 'in_game'.
  final String? gameType;

  /// Premium-only detail gate — "Premium users should be able to see
  /// detailed friend status ... Basic users should only see the normal
  /// allowed status". The caller decides this from the *viewer's* own
  /// premium status, not the friend being displayed.
  final bool showDetail;

  Color get _color => switch (status) {
    UserPresenceStatus.online => AppColors.successGreen,
    UserPresenceStatus.inGame => AppColors.brandOrangeLight,
    UserPresenceStatus.backgrounded => AppColors.amberOrangeLight,
    UserPresenceStatus.offline => AppColors.textTertiaryLight,
  };

  String _label(BuildContext context) {
    if (showDetail && status == UserPresenceStatus.inGame) {
      if (roomStatus == 'in_game') {
        final display = resolveGameDisplayName(gameType);
        if (display != null) {
          return context.l10n.friendsStatusPlayingGame(display);
        }
      }
      if (roomStatus == 'lobby') return context.l10n.friendsStatusInRoomLobby;
    }
    return switch (status) {
      UserPresenceStatus.online => context.l10n.friendsStatusOnline,
      UserPresenceStatus.inGame => context.l10n.friendsStatusInGame,
      UserPresenceStatus.backgrounded => context.l10n.presenceUserIsAway,
      UserPresenceStatus.offline => context.l10n.friendsStatusOffline,
    };
  }

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
          _label(context),
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
    this.roomStatus,
    this.gameType,
    this.showDetail = false,
    this.onTap,
    this.onJoinRoom,
    this.onRemove,
    this.onBlock,
  });

  final FriendEntity friend;
  final UserPresenceStatus status;
  final String? roomId;

  /// See OnlineIndicator — 'lobby'/'in_game' and the game type, plus
  /// [showDetail] gating whether they're actually shown (premium viewers
  /// only; passed in by the caller from the *viewer's* premium status).
  final String? roomStatus;
  final String? gameType;
  final bool showDetail;
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
                    child: OnlineIndicator(
                      status: status,
                      size: 10,
                      roomStatus: roomStatus,
                      gameType: gameType,
                      showDetail: showDetail,
                    ),
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

                  // In-game label — premium viewers get the specific
                  // lobby/game-type detail; basic viewers keep the
                  // existing generic "Playing Now" text unchanged.
                  if (status == UserPresenceStatus.inGame)
                    Row(
                      children: [
                        const Text('🎮', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text(
                          showDetail
                              ? _detailedInGameLabel(context)
                              : context.l10n.friendsPlayingNow,
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
                    // Explicit minimumSize:Size.zero — Row gives an
                    // unbounded max width to a non-Expanded child
                    // regardless of mainAxisSize, and the app-wide
                    // FilledButton theme defaults minimumSize to
                    // Size(double.infinity, 52); without this override
                    // this throws "BoxConstraints forces an infinite
                    // width" (see the identical fix in friends_screen.dart
                    // for the full explanation).
                    child: SizedBox(
                      height: 34,
                      child: FilledButton.tonal(
                        onPressed: onJoinRoom,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppColors.brandOrangeLight
                              .withOpacity(0.12),
                          foregroundColor: AppColors.warningAmber,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(context.l10n.roomsJoin),
                      ),
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
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              const Icon(Icons.person_remove_outlined),
                              const SizedBox(width: 8),
                              Text(context.l10n.friendsRemoveFriend),
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
                                context.l10n.friendsBlock,
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

  String _detailedInGameLabel(BuildContext context) {
    if (roomStatus == 'in_game') {
      final display = resolveGameDisplayName(gameType);
      if (display != null)
        return context.l10n.friendsStatusPlayingGame(display);
    }
    if (roomStatus == 'lobby') return context.l10n.friendsStatusInRoomLobby;
    return context.l10n.friendsPlayingNow;
  }
}
