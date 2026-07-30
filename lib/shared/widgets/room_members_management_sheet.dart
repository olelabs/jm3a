import 'package:flutter/material.dart';

import '../../features/rooms/domain/room_entity.dart';
import '../../features/rooms/presentation/room_provider.dart';

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
  const RoomMembersManagementSheet({
    super.key,
    required this.roomProvider,
    this.gameKickPlayer,
    this.gameBanPlayer,
  });

  final RoomProvider roomProvider;
  final Future<void> Function(String userId)? gameKickPlayer;
  final Future<void> Function(String userId)? gameBanPlayer;

  String _statusOf(RoomMemberEntity m) {
    if (m.isSpectator) return 'Spectator';
    if (m.isDisconnected || m.isAway) return 'Disconnected';
    if (m.isGameMuted) return 'Muted';
    return 'Playing';
  }

  Color _statusColor(BuildContext context, RoomMemberEntity m) {
    if (m.isDisconnected || m.isAway) return Colors.grey;
    if (m.isSpectator) return Colors.blueGrey;
    if (m.isGameMuted) return Colors.teal;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: roomProvider,
      builder: (context, _) {
        final theme = Theme.of(context);
        final members = roomProvider.members;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                '👥 Room Members (${members.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: members.length,
                  itemBuilder: (ctx, i) {
                    final m = members[i];
                    final isMe = m.userId == roomProvider.currentMember?.userId;
                    final canKick = roomProvider.canKickPlayers && !isMe;
                    final canBan = roomProvider.isOwner && !isMe;
                    final canMute =
                        roomProvider.canMutePlayers && !isMe && !m.isSpectator;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        child: Text(
                          m.displayName.isNotEmpty
                              ? m.displayName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              m.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (m.isOwner) ...[
                            const SizedBox(width: 4),
                            const Text('👑', style: TextStyle(fontSize: 12)),
                          ] else if (m.isModerator) ...[
                            const SizedBox(width: 4),
                            const Text('🛡', style: TextStyle(fontSize: 12)),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        _statusOf(m),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _statusColor(context, m),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: (canKick || canBan || canMute) && !isMe
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
                                    onPressed: () => roomProvider
                                        .mutePlayerInGame(
                                          m.userId,
                                          muted: !m.isGameMuted,
                                        ),
                                    child: Text(
                                      m.isGameMuted ? 'Unmute' : 'Mute',
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
                                      final confirmed = await showDialog<bool>(
                                        context: ctx,
                                        builder: (dCtx) => AlertDialog(
                                          title: const Text('Kick Player'),
                                          content: const Text(
                                            'Are you sure you want to remove this player from the current game?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                dCtx,
                                              ).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                              ),
                                              onPressed: () => Navigator.of(
                                                dCtx,
                                              ).pop(true),
                                              child: const Text('Kick'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed != true || !ctx.mounted) {
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
                                    child: const Text('Kick'),
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
                                      final confirmed = await showDialog<bool>(
                                        context: ctx,
                                        builder: (dCtx) => AlertDialog(
                                          title: const Text('Ban Player'),
                                          content: const Text(
                                            'Are you sure you want to ban this player from this room?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                dCtx,
                                              ).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              onPressed: () => Navigator.of(
                                                dCtx,
                                              ).pop(true),
                                              child: const Text('Ban'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed != true || !ctx.mounted) {
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
                                    child: const Text('Ban'),
                                  ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
                tooltip: 'Room members',
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
