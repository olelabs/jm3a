import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/service_locator.dart';
import '../../core/errors/failures.dart';
import '../../core/extensions/context_ext.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/app_tutorial_service.dart';
import '../../core/services/presence_service.dart';
import '../../core/theme/app_colors.dart';
import '../../features/rooms/domain/room_entity.dart';
import '../../features/rooms/presentation/room_provider.dart';
import 'tutorial/screen_tutorial.dart';

/// Admin/moderator member management, sourced entirely from
/// [RoomProvider.members] — the room membership source of truth. Never
/// derived from a game's current round/vote/response state, so it stays
/// correct and available across every phase (lobby, active round, voting,
/// submissions, results, ready phase) for all three games.
///
/// Kick/ban always uses the existing, single implementation of each action:
/// - Spectators: always [RoomProvider.kickPlayer]/[RoomProvider.banPlayer]
///   (room-level — there's no "game" concept for a spectator to be kicked
///   from).
/// - Players: [gameKickPlayer]/[gameBanPlayer] when provided (i.e. shown
///   from inside an active game screen) so the existing game-layer kick
///   lifecycle applies (removed from playerOrder/round-waiting/ready
///   calculations, game continues immediately). Falls back to the
///   room-level kick/ban when no game is active (e.g. shown from the
///   lobby before a game has started).
///
/// Mute always goes through [RoomProvider.mutePlayerInGame], gated on
/// [RoomProvider.canMutePlayers] — a single implementation shared by every
/// game, same as kick/ban. This is the in-game action-gating mute
/// ([RoomMemberEntity.isGameMuted]), distinct from the lobby's chat mute.
class RoomMembersManagementSheet extends StatelessWidget {
  RoomMembersManagementSheet({
    super.key,
    required this.roomProvider,
    this.gameKickPlayer,
    this.gameBanPlayer,
  });

  final RoomProvider roomProvider;
  final Future<void> Function(String userId)? gameKickPlayer;
  final Future<void> Function(String userId)? gameBanPlayer;

  // Stable for the sheet's lifetime (this widget is built once by the modal
  // builder; the inner AnimatedBuilder rebuilds don't reconstruct it), so the
  // showcase target survives member-list updates mid-tour.
  final GlobalKey _membersShowcaseKey = GlobalKey();

  /// Was previously a fire-and-forget `() => roomProvider.mutePlayerInGame
  /// (...)` — a failed RPC (permission revoked mid-session, network drop)
  /// gave the moderator no feedback at all, indistinguishable from mute
  /// silently "not working".
  Future<void> _toggleGameMute(BuildContext ctx, RoomMemberEntity m) async {
    try {
      await roomProvider.mutePlayerInGame(m.userId, muted: !m.isGameMuted);
    } on Failure catch (e) {
      if (ctx.mounted) ctx.showErrorSnackBar(e.message);
    }
  }

  // isWaitingForGameApproval takes priority over every other label — a
  // pending rejoin request means nothing else about this member's game
  // state is decided yet, and in particular they must never read as
  // "Playing" while genuinely stuck outside the game waiting on a
  // moderator. Mirrors the same priority order lobby_screen.dart's
  // MemberTile already uses via RoomProvider.pendingRejoinUserIds — this
  // was the one other surface that showed a member list without ever
  // consulting that state at all.
  /// [isAwayFromApp] is the Premium Plus "backgrounded" presence state
  /// (PresenceService.UserPresenceStatus.backgrounded) — unrelated to
  /// [RoomMemberEntity.isAway] (a different, room-scoped "left the current
  /// game round" concept handled by the isDisconnected||isAway branch
  /// below). Checked first since it's a more precise, live signal.
  String _statusOf(
    BuildContext context,
    RoomMemberEntity m, {
    required bool isWaitingForGameApproval,
    bool isAwayFromApp = false,
  }) {
    if (isWaitingForGameApproval) {
      return context.l10n.roomsWaitingForGameApproval;
    }
    if (isAwayFromApp) return context.l10n.presenceUserIsAwayFull;
    if (m.isSpectator) return context.l10n.sharedStatusSpectator;
    if (m.isDisconnected || m.isAway)
      return context.l10n.sharedStatusDisconnected;
    if (m.isGameMuted) return context.l10n.sharedStatusMuted;
    return context.l10n.sharedStatusPlaying;
  }

  Color _statusColor(
    BuildContext context,
    RoomMemberEntity m, {
    required bool isWaitingForGameApproval,
    bool isAwayFromApp = false,
  }) {
    if (isWaitingForGameApproval) return Theme.of(context).colorScheme.primary;
    if (isAwayFromApp) return AppColors.amberOrangeLight;
    if (m.isDisconnected || m.isAway) return Colors.grey;
    if (m.isSpectator) return Colors.blueGrey;
    if (m.isGameMuted) return Colors.teal;
    return Theme.of(context).colorScheme.primary;
  }

  Future<void> _resolveRejoin(
    BuildContext ctx,
    String requestId,
    bool approve,
  ) async {
    try {
      await sl.roomRepository.decideGameRejoinRequest(
        requestId: requestId,
        approve: approve,
      );
    } on Failure catch (e) {
      if (ctx.mounted) ctx.showErrorSnackBar(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenTutorial(
      tutorialId: TutorialIds.roomMembersIntro,
      steps: [_membersShowcaseKey],
      // Only moderators/host ever open this sheet (the FAB is gated on
      // canModerateRoom), so the tour only ever explains moderator controls.
      enabled: roomProvider.canModerateRoom,
      child: AnimatedBuilder(
        animation: roomProvider,
        builder: (context, _) {
          final theme = Theme.of(context);
          final members = roomProvider.members;
          // A hidden spectator's identity is unmasked here only for a Premium
          // Plus moderator; a non-Premium-Plus moderator sees a masked entry that
          // is still fully kickable/bannable (moderation is never gated by tier).
          final canRevealHidden = roomProvider.canRevealHiddenSpectator(
            viewerIsPremiumPlus:
                context.read<AuthProvider>().currentUser?.isPremiumPlusActive ??
                false,
          );
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7,
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  context.l10n.sharedRoomMembersCount(members.length),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: tutorialShowcase(
                    context: context,
                    showcaseKey: _membersShowcaseKey,
                    title: context.l10n.tutMembersTitle,
                    description: context.l10n.tutMembersBody,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: members.length,
                      itemBuilder: (ctx, i) {
                        final m = members[i];
                        final isMe =
                            m.userId == roomProvider.currentMember?.userId;
                        final rejoinRequestId = roomProvider
                            .pendingRejoinRequestId(m.userId);
                        final isWaitingForGameApproval =
                            rejoinRequestId != null;
                        final canAcceptRejoins =
                            roomProvider.canAcceptRejoins && !isMe;
                        final canKick =
                            roomProvider.canKickPlayers &&
                            !isMe &&
                            !isWaitingForGameApproval;
                        final canBan = roomProvider.isOwner && !isMe;
                        final canMute =
                            roomProvider.canMutePlayers &&
                            !isMe &&
                            !m.isSpectator &&
                            !isWaitingForGameApproval;
                        final masked = m.isHiddenSpectator && !canRevealHidden;
                        final shownName = masked
                            ? context.l10n.lobbyAnonymousSpectator
                            : m.displayName;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            child: masked
                                ? Icon(
                                    Icons.visibility_off_rounded,
                                    size: 18,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  )
                                : Text(
                                    shownName.isNotEmpty
                                        ? shownName[0].toUpperCase()
                                        : '?',
                                  ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  shownName,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (m.isOwner) ...[
                                const SizedBox(width: 4),
                                const Text(
                                  '👑',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ] else if (m.isModerator) ...[
                                const SizedBox(width: 4),
                                const Text(
                                  '🛡',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                          subtitle: StreamBuilder<Map<String, UserPresence>>(
                            stream:
                                m.isPremium && m.premiumTier == 'premium_plus'
                                ? PresenceService.instance.presenceStream
                                : const Stream.empty(),
                            initialData:
                                m.isPremium && m.premiumTier == 'premium_plus'
                                ? PresenceService.instance.currentPresence
                                : const {},
                            builder: (context, snapshot) {
                              final isAwayFromApp =
                                  m.isPremium &&
                                  m.premiumTier == 'premium_plus' &&
                                  snapshot.data?[m.userId]?.status ==
                                      UserPresenceStatus.backgrounded;
                              return Text(
                                _statusOf(
                                  context,
                                  m,
                                  isWaitingForGameApproval:
                                      isWaitingForGameApproval,
                                  isAwayFromApp: isAwayFromApp,
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _statusColor(
                                    context,
                                    m,
                                    isWaitingForGameApproval:
                                        isWaitingForGameApproval,
                                    isAwayFromApp: isAwayFromApp,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                          trailing: isWaitingForGameApproval && !isMe
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (canAcceptRejoins) ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.green,
                                        ),
                                        tooltip: context.l10n.lobbyApprove,
                                        onPressed: () => _resolveRejoin(
                                          ctx,
                                          rejoinRequestId,
                                          true,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.cancel_rounded,
                                          color: Colors.red,
                                        ),
                                        tooltip: context.l10n.lobbyReject,
                                        onPressed: () => _resolveRejoin(
                                          ctx,
                                          rejoinRequestId,
                                          false,
                                        ),
                                      ),
                                    ],
                                    if (canBan)
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () async {
                                          final confirmed =
                                              await showDialog<bool>(
                                                context: ctx,
                                                builder: (dCtx) => AlertDialog(
                                                  title: Text(
                                                    dCtx
                                                        .l10n
                                                        .sharedBanPlayerTitle,
                                                  ),
                                                  content: Text(
                                                    dCtx
                                                        .l10n
                                                        .sharedBanPlayerBody,
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            dCtx,
                                                          ).pop(false),
                                                      child: Text(
                                                        dCtx.l10n.cancel,
                                                      ),
                                                    ),
                                                    FilledButton(
                                                      style:
                                                          FilledButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            dCtx,
                                                          ).pop(true),
                                                      child: Text(
                                                        dCtx.l10n.sharedBan,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                          if (confirmed != true ||
                                              !ctx.mounted) {
                                            return;
                                          }
                                          Navigator.of(ctx).pop();
                                          await roomProvider.banPlayer(
                                            m.userId,
                                          );
                                        },
                                        child: Text(context.l10n.sharedBan),
                                      ),
                                  ],
                                )
                              : (canKick || canBan || canMute) && !isMe
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (canMute)
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: m.isGameMuted
                                              ? Colors.blueGrey
                                              : Colors.teal,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () =>
                                            _toggleGameMute(ctx, m),
                                        child: Text(
                                          m.isGameMuted
                                              ? context.l10n.sharedUnmute
                                              : context.l10n.sharedMute,
                                        ),
                                      ),
                                    if (canKick)
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.orange,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () async {
                                          final confirmed =
                                              await showDialog<bool>(
                                                context: ctx,
                                                builder: (dCtx) => AlertDialog(
                                                  title: Text(
                                                    dCtx
                                                        .l10n
                                                        .sharedKickPlayerTitle,
                                                  ),
                                                  content: Text(
                                                    dCtx
                                                        .l10n
                                                        .sharedKickPlayerBody,
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            dCtx,
                                                          ).pop(false),
                                                      child: Text(
                                                        dCtx.l10n.cancel,
                                                      ),
                                                    ),
                                                    FilledButton(
                                                      style:
                                                          FilledButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.orange,
                                                          ),
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            dCtx,
                                                          ).pop(true),
                                                      child: Text(
                                                        dCtx.l10n.sharedKick,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                          if (confirmed != true ||
                                              !ctx.mounted) {
                                            return;
                                          }
                                          Navigator.of(ctx).pop();
                                          if (!m.isSpectator &&
                                              gameKickPlayer != null) {
                                            await gameKickPlayer!(m.userId);
                                          } else {
                                            await roomProvider.kickPlayer(
                                              m.userId,
                                            );
                                          }
                                        },
                                        child: Text(context.l10n.sharedKick),
                                      ),
                                    if (canBan)
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () async {
                                          final confirmed =
                                              await showDialog<bool>(
                                                context: ctx,
                                                builder: (dCtx) => AlertDialog(
                                                  title: Text(
                                                    dCtx
                                                        .l10n
                                                        .sharedBanPlayerTitle,
                                                  ),
                                                  content: Text(
                                                    dCtx
                                                        .l10n
                                                        .sharedBanPlayerBody,
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            dCtx,
                                                          ).pop(false),
                                                      child: Text(
                                                        dCtx.l10n.cancel,
                                                      ),
                                                    ),
                                                    FilledButton(
                                                      style:
                                                          FilledButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            dCtx,
                                                          ).pop(true),
                                                      child: Text(
                                                        dCtx.l10n.sharedBan,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                          if (confirmed != true ||
                                              !ctx.mounted) {
                                            return;
                                          }
                                          Navigator.of(ctx).pop();
                                          if (!m.isSpectator &&
                                              gameBanPlayer != null) {
                                            await gameBanPlayer!(m.userId);
                                          } else {
                                            await roomProvider.banPlayer(
                                              m.userId,
                                            );
                                          }
                                        },
                                        child: Text(context.l10n.sharedBan),
                                      ),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ),
                // Batch D: owner-only Close Room, reachable from inside the
                // active game. Keeps the game and session running — it only
                // marks the room closed to new entrants. Distinct from any
                // leave/end action. Disabled when the owner is alone or the
                // room is already closed (canCloseRoom mirrors the RPC rule).
                if (roomProvider.isOwner) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        roomProvider.isRoomClosed
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline_rounded,
                      ),
                      label: Text(
                        roomProvider.isRoomClosed
                            ? context.l10n.lobbyReopenCta
                            : context.l10n.lobbyCloseKeepGameCta,
                      ),
                      onPressed: roomProvider.isRoomClosed
                          ? (roomProvider.canReopenRoom
                                ? () => _confirmReopenRoom(context)
                                : null)
                          : (roomProvider.canCloseRoom
                                ? () => _confirmCloseRoom(context)
                                : null),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmCloseRoom(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(dCtx.l10n.lobbyCloseKeepGameTitle),
        content: Text(dCtx.l10n.lobbyCloseKeepGameBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: Text(dCtx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: Text(dCtx.l10n.lobbyCloseKeepGameConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await roomProvider.closeRoomKeepGame();
      if (context.mounted) {
        // Dismiss the sheet and stay in the game — nothing about the live
        // session changes.
        Navigator.of(context).pop();
        context.showSnackBar(context.l10n.lobbyRoomClosedForNewPlayers);
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar(e is Failure ? e.message : e.toString());
      }
    }
  }

  Future<void> _confirmReopenRoom(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(dCtx.l10n.lobbyReopenTitle),
        content: Text(dCtx.l10n.lobbyReopenBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: Text(dCtx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: Text(dCtx.l10n.lobbyReopenConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await roomProvider.reopenRoom();
      if (context.mounted) {
        Navigator.of(context).pop();
        context.showSnackBar(context.l10n.lobbyRoomReopened);
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar(e is Failure ? e.message : e.toString());
      }
    }
  }
}

/// Floating entry point for [RoomMembersManagementSheet], shown as an
/// overlay so it's reachable during every phase of a game (not just one
/// specific screen/round state). Visibility is gated on
/// [RoomProvider.canModerateRoom] — non-admins never see the button.
class RoomMembersFab extends StatelessWidget {
  const RoomMembersFab({
    super.key,
    required this.roomProvider,
    this.gameKickPlayer,
    this.gameBanPlayer,
    required this.heroTag,
  });

  final RoomProvider? roomProvider;
  final Future<void> Function(String userId)? gameKickPlayer;
  final Future<void> Function(String userId)? gameBanPlayer;
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    final rp = roomProvider;
    if (rp == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: rp,
      builder: (context, _) {
        if (!rp.canModerateRoom) return const SizedBox.shrink();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton.small(
                heroTag: heroTag,
                tooltip: context.l10n.sharedRoomMembers,
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => RoomMembersManagementSheet(
                    roomProvider: rp,
                    gameKickPlayer: gameKickPlayer,
                    gameBanPlayer: gameBanPlayer,
                  ),
                ),
                child: const Icon(Icons.people_outline),
              ),
            ),
          ),
        );
      },
    );
  }
}
