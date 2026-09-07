import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../shared/widgets/game/dishonest_reasons_panel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:jma3a/core/router/app_router.dart';
import 'package:jma3a/core/utils/app_logger.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/presentation/widgets/game_screen_security_gate.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/features/rooms/presentation/room_provider.dart';
import 'package:jma3a/features/settings/presentation/screen_security_service.dart';
import 'package:jma3a/shared/widgets/center_reaction_overlay.dart';
import 'package:jma3a/shared/widgets/game_rules_sheet.dart';
import 'package:jma3a/shared/widgets/no_active_players_banner.dart';
import 'package:jma3a/shared/widgets/join_requests_panel.dart';
import 'package:jma3a/shared/widgets/room_members_management_sheet.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/extensions/context_ext.dart';
import '../../../../../core/services/app_tutorial_service.dart';
import '../../../../../shared/widgets/tutorial/screen_tutorial.dart';
import '../../../../../core/providers/auth_provider.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/services/realtime_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/game_end_navigation.dart';
import '../../../../../shared/widgets/feedback/error_view.dart';
import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
import '../../../../../shared/widgets/overlays/host_reconnect_overlay.dart';
import '../../../../../shared/widgets/game/away_presence_snackbar_listener.dart';
import '../../../../../shared/widgets/game/game_chat_sheet.dart';
import '../../../game_session_messages.dart';
import '../../domain/tod_models.dart';
import '../../tod_game_provider.dart';
import '../../data/tod_repository.dart';
import 'tod_card_screen.dart';
import 'tod_end_screen.dart';
import 'tod_loading_screen.dart';
import 'tod_punishment_screen.dart';
import '../widgets/tod_hud.dart';

// import '../../../../../core/services/screen_security_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/game_end_navigation.dart';
import '../../../../../shared/widgets/feedback/error_view.dart';
import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
import '../../../../../shared/widgets/overlays/host_reconnect_overlay.dart';
import '../../../game_session_messages.dart';
import '../../domain/tod_models.dart';
import '../../tod_game_provider.dart';

import '../../data/tod_repository.dart';
import 'tod_card_screen.dart';
import 'tod_end_screen.dart';
import 'tod_loading_screen.dart';
import 'tod_punishment_screen.dart';
import '../widgets/tod_hud.dart';

class TodGameScreen extends StatefulWidget {
  const TodGameScreen({
    super.key,
    required this.roomId,
    required this.config,
    required this.playerIds,
    required this.playerDisplayNames,
    required this.packId,
    required this.isOwner,
    this.sessionId,
    this.isModerator = false,
    this.isSpectator = false,
    this.packCoverUrl,
    this.isNewGameStart = false,
    this.roomProvider,
  });

  final String roomId;
  final GameConfig config;
  final List<String> playerIds;
  final Map<String, String> playerDisplayNames;
  final String packId;
  final bool isOwner;
  final String? sessionId;
  final bool isModerator;
  final bool isSpectator;
  final String? packCoverUrl;

  /// True only for a genuine, fresh "Start Game" press (see
  /// lobby_screen.dart's _onStartGame) — never set for a reconnect,
  /// "Continue Game", or the automatic status-change listener, all of
  /// which are entering an already-running game and must resume it.
  final bool isNewGameStart;
  final RoomProvider? roomProvider;

  @override
  State<TodGameScreen> createState() => _TodGameScreenState();
}

class _TodGameScreenState extends State<TodGameScreen> {
  late final TodGameProvider _provider;

  StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

  // Tracks whether we've reached `subscribed` before. hasSyncedState alone
  // isn't enough to gate the resync request — it stays true forever after
  // the first sync, so a later reconnect (network drop, backgrounding)
  // would otherwise never trigger a fresh sync even though state broadcasts
  // sent while disconnected were permanently missed (Realtime Broadcast has
  // no delivery guarantee or replay).
  bool _hasEverSubscribed = false;

  // Room ownership can be transferred mid-game (see RoomProvider.
  // transferOwnership); this provider's own `_isOwner` is otherwise cached
  // once at game start and never re-derived, so this listener is what
  // actually moves game-authority (state broadcasting) to the new owner.
  bool? _lastKnownRoomOwner;

  void _onRoomOwnershipChanged() {
    final rp = widget.roomProvider;
    if (rp == null) return;
    final amOwner = rp.isOwner;
    if (_lastKnownRoomOwner == amOwner) return;
    _lastKnownRoomOwner = amOwner;
    _provider.applyOwnershipChange(amOwner);
  }

  // The build() Consumer only listens to _provider (the game engine
  // provider) — RoomProvider pausing/resuming for a disconnected host
  // otherwise wouldn't trigger a rebuild at all, so the host-reconnect
  // overlay (gated on widget.roomProvider?.isPausedForHostReconnect inside
  // _build) would never actually appear or disappear on its own.
  bool _lastKnownPaused = false;

  // Guards the session-ended auto-navigate in _build's error branch against
  // firing more than once (the error branch re-runs on every rebuild while
  // loadState stays 'error').
  bool _autoLeftOnSessionEnd = false;

  void _onRoomPauseChanged() {
    final rp = widget.roomProvider;
    if (rp == null) return;
    final paused = rp.isPausedForHostReconnect;
    if (_lastKnownPaused != paused) {
      _lastKnownPaused = paused;
      if (mounted) setState(() {});
    }
    // Authoritative reconciliation fallback for a missed game_ended
    // broadcast (Realtime Broadcast has no delivery guarantee) —
    // RoomProvider already re-derives rooms.status from the database
    // independently on its own 5s reconcile poll (_gameReconcileTimer ->
    // _refreshMembers), so this eventually notices "the room is no longer
    // in_game/paused" even when the broadcast that was supposed to
    // announce it never arrived, without a second timer/poll of its own.
    _leaveIfRoomNoLongerActive(rp);
  }

  void _leaveIfRoomNoLongerActive(RoomProvider rp) {
    if (_autoLeftOnSessionEnd || _provider.isNavigatingAway) return;
    final status = rp.room?.status;
    // 'starting' is included here too — not just 'inGame'/'paused' — since
    // the OWNER is already inside this game screen during STARTING_GAME
    // (see LobbyScreen._syncGameRoute's isGameInProgress gate, which is
    // owner-only for 'starting'). Bouncing them back to the lobby off a
    // reconciliation poll that still reads 'starting' (the normal, brief
    // window before this same owner's own initAsOwner flips the room to
    // 'in_game' once session creation succeeds) would be exactly the
    // premature loading->lobby bounce this whole state was introduced to
    // eliminate. A non-owner never reaches this screen while status is
    // still 'starting' at all, so this is a no-op safety net for them.
    if (status == null ||
        status == RoomStatus.inGame ||
        status == RoomStatus.paused ||
        status == RoomStatus.starting) {
      return;
    }
    _autoLeftOnSessionEnd = true;
    _provider.isNavigatingAway = true;
    AppLogger.info(
      'GAME_NAV leaveIfRoomNoLongerActive room=${widget.roomId} '
      'isOwner=${widget.isOwner} status=$status canPop=${context.canPop()} '
      'dest=lobby',
    );
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        // The game ended/was superseded, but the ROOM still exists (e.g.
        // auto-end after a player was kicked, a host-timeout end). Return
        // to this room's LOBBY, never RouteNames.home — sending the owner
        // to the app home here is exactly the "admin kicked out when they
        // kicked a player" bug. Genuine room deletion/kick/ban goes home
        // via the RoomLifecycleEvent path in LobbyScreen instead.
        context.go('/home/room/${widget.roomId}');
      }
    }
  }

  // Previously nothing in this screen listened to RoomProvider's lifecycle
  // stream at all — a player sitting inside an active game when the owner
  // vanished (and no other member was eligible for auto-promotion) got no
  // notification and no fallback; the screen just hung indefinitely.
  StreamSubscription<RoomLifecycleEvent>? _lifecycleSub;

  void _onRoomLifecycleEvent(RoomLifecycleEvent event) {
    if (!mounted) return;
    switch (event) {
      case RoomLifecycleEvent.roomClosed:
      case RoomLifecycleEvent.kicked:
      case RoomLifecycleEvent.banned:
      case RoomLifecycleEvent.removed:
      case RoomLifecycleEvent.ownershipTransferred:
        // handled by _onRoomOwnershipChanged / the target's own nav — and,
        // for roomClosed specifically, by LobbyScreen's own listener, which
        // stays mounted underneath this pushed route (see app_router.dart's
        // parentNavigatorKey:rootKey). This screen previously ALSO reacted
        // to roomClosed with its own snackbar + AppRouter.router.go(), which
        // raced against LobbyScreen's showDialog for the same event — both
        // are registered on the same broadcast RoomLifecycleEvent stream,
        // and go() replacing the entire route stack while the lobby's
        // AlertDialog was still mid-transition left a semantics-blocking
        // barrier that never got to cleanly rejoin the tree, producing a
        // permanently corrupted semantics node (RenderObject.
        // debugCheckForParentData's `!semantics.parentDataDirty` assertion,
        // repeating every frame thereafter). roomClosed now has exactly one
        // owner — LobbyScreen — same as the other three events here.
        break;
      case RoomLifecycleEvent.memberLeft:
        final name = widget.roomProvider?.lastDepartedMemberName;
        if (name != null && name.isNotEmpty) {
          context.showSnackBar(context.l10n.todPlayerLeftGame(name));
        }
    }
  }

  // Single presence pipeline: RoomProvider already tracks connected/
  // disconnected members reliably (presence sync + a debounced grace
  // period); rather than a second, separate presence system here, the
  // owner's client derives/updates away status straight from that one
  // source of truth. This also fixes _awayPlayerIds never surviving a
  // full app restart (it's normally only set by runtime moderation
  // events) — this runs once immediately on init too, deriving the
  // correct set from the DB-backed member list right away.
  void _syncAwayFromPresence() {
    final rp = widget.roomProvider;
    final state = _provider.state;
    if (rp == null || !_provider.isOwner || state == null) return;
    for (final id in state.playerOrder) {
      final member = rp.members.where((m) => m.userId == id).firstOrNull;
      // A game-muted player must NOT lose their turn: muting parks the turn
      // on them (blocked — they can't submit), it does not skip them. So a
      // mute must never route through markPlayerAway/force-advance here.
      // Only a genuinely-absent player (disconnected) is marked away; the
      // provider's own _turnSkipIds keeps muted players in the rotation.
      final isPresent = member != null && !member.isDisconnected;
      final isAway = _provider.awayPlayerIds.contains(id);
      if (isPresent && isAway) {
        _provider.markPlayerReturned(id);
      } else if (!isPresent && !isAway) {
        _provider.markPlayerAway(id);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // ScreenSecurityService.instance.enable();
    // ScreenSecurityService.instance.enableScreenshotDetection(() {
    //   sl.realtimeService.broadcastRoomEvent(widget.roomId, {
    //     'type': 'screenshot_taken',
    //     'user_id': context.read<AuthProvider>().currentUser?.id,
    //   }).ignore();
    // });

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;

    _provider = TodGameProvider(
      realtimeService: sl.realtimeService,
      repository: TodRepository.instance,
      currentUserId: user.id,
      currentDisplayName:
          user.displayName ?? user.username ?? context.l10n.packPlayer,
      isModerator: widget.isModerator,
    );

    _wireRealtimeCallbacks();

    if (widget.isOwner) {
      final isPremium =
          context.read<AuthProvider>().currentUser?.isPremium ?? false;
      _provider.initAsOwner(
        roomId: widget.roomId,
        config: widget.config,
        playerIds: widget.playerIds,
        playerDisplayNames: widget.playerDisplayNames,
        packId: widget.packId,
        isPremium: isPremium,
        packCoverUrl: widget.packCoverUrl,
        isNewGame: widget.isNewGameStart,
      );
    } else {
      _provider.initAsFollower(
        roomId: widget.roomId,
        config: widget.config,
        sessionId: widget.sessionId,
        packCoverUrl: widget.packCoverUrl,
      );
    }

    _lastKnownRoomOwner = widget.isOwner;
    _lastKnownPaused = widget.roomProvider?.isPausedForHostReconnect ?? false;
    widget.roomProvider?.addListener(_onRoomOwnershipChanged);
    widget.roomProvider?.addListener(_onRoomPauseChanged);
    widget.roomProvider?.addListener(_syncAwayFromPresence);
    // initAsOwner/initAsFollower are async — _provider.state isn't
    // populated yet at this point, so also re-run once the game provider
    // itself notifies (e.g. once its initial state loads), not just when
    // RoomProvider changes.
    _provider.addListener(_syncAwayFromPresence);
    _provider.permissionChecker = widget.roomProvider?.memberHasPermission;
    _provider.roomProvider = widget.roomProvider;
    final roomId = widget.roomProvider?.room?.id;
    if (roomId != null) _provider.startTargetedChatListener(roomId);
    _lifecycleSub = widget.roomProvider?.lifecycleEvents.listen(
      _onRoomLifecycleEvent,
    );
  }

  @override
  void dispose() {
    widget.roomProvider?.removeListener(_onRoomOwnershipChanged);
    widget.roomProvider?.removeListener(_onRoomPauseChanged);
    widget.roomProvider?.removeListener(_syncAwayFromPresence);
    _provider.removeListener(_syncAwayFromPresence);
    _lifecycleSub?.cancel();
    // ScreenSecurityService.instance.disable();
    _statusSub?.cancel();
    // Only removes this screen's own 'game' listener — the room channel,
    // RoomProvider's 'room' listener, and presence tracking are untouched.
    sl.realtimeService.unsubscribeListener(
      widget.roomId,
      RoomChannelSubscriber.game,
    );
    _provider.dispose();
    super.dispose();
  }

  void _wireRealtimeCallbacks() {
    _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
      status,
    ) {
      if (status == RealtimeSubscribeStatus.subscribed &&
          !_provider.hasSyncedState) {
        sl.realtimeService.broadcastSyncRequest(
          widget.roomId,
          context.read<AuthProvider>().currentUser!.id,
          0,
        );
      }
    });

    _resubscribeWithGameHandlers();
  }

  void _resubscribeWithGameHandlers() {
    final userId = context.read<AuthProvider>().currentUser!.id;

    // Registers this screen's own 'game' listener alongside RoomProvider's
    // 'room' listener on the shared channel — no full unsubscribe/rebuild,
    // so RoomProvider's own subscription (and presence tracking) is never
    // disturbed.
    sl.realtimeService.subscribe(
      roomId: widget.roomId,
      subscriberId: RoomChannelSubscriber.game,
      onGameState: (p) => _provider.onStateBroadcast(p),
      onPlayerAction: (p) {
        // Receiving a live action from a member is proof they're
        // connected — clear any presence grace-period in progress for
        // them immediately rather than waiting on the next heartbeat.
        final uid = p['user_id'] as String?;
        if (uid != null) widget.roomProvider?.markMemberActive(uid);
        _provider.onPlayerAction(p);
      },
      onSyncRequest: (p) => _provider.onSyncRequest(p),
      onGameStarted: (_) {},
      onGameEnded: (p) {
        // A game_ended broadcast for a session that isn't this client's
        // current one — a previous game's event delayed in flight (no
        // delivery guarantee/ordering on Realtime Broadcast) arriving
        // after a fresh game already started — must never end the game
        // actually running now. Tolerant of either side being null (a
        // session_id-less legacy caller, or this client not having
        // resolved its own session_id yet) — only a CONFIRMED mismatch
        // (both known, and different) is rejected, same rule already used
        // for session_ready above.
        final eventSessionId = p['session_id'] as String?;
        if (eventSessionId != null &&
            _provider.sessionId != null &&
            eventSessionId != _provider.sessionId) {
          AppLogger.warning(
            'TodGameScreen: ignoring game_ended for stale session '
            '$eventSessionId (current: ${_provider.sessionId})',
          );
          return;
        }
        // Idempotent navigation-away: another exit path
        // (_leaveIfRoomNoLongerActive, the error/session-ended auto-leave,
        // the quit flow, or a duplicate game_ended) may have already
        // started leaving this screen. Same combined guard
        // _leaveIfRoomNoLongerActive uses — once EITHER latch is set, every
        // other exit becomes a no-op, so we can never double-pop / navigate
        // after this route is already gone.
        if (_autoLeftOnSessionEnd || _provider.isNavigatingAway) return;
        if (mounted) {
          // Mark this as a programmatic exit before popping, so the
          // _TodGameScaffold's PopScope (which shares this same
          // TodGameProvider instance) doesn't mistake it for the user
          // backing out and open the Quit Game dialog on top of it.
          _autoLeftOnSessionEnd = true;
          _provider.isNavigatingAway = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.todHostEndedGame)),
          );
          // game_ended means the SESSION ended, not the room — return to
          // the room lobby, never app home (see _leaveIfRoomNoLongerActive).
          if (context.canPop())
            context.pop();
          else
            context.go('/home/room/${widget.roomId}');
        }
      },
      onRoomEvent: (p) {
        final type = p['type'] as String?;
        if (type == 'session_ready') {
          // The owner's own live tracking of who's confirmed loading this
          // session — a follower's DB confirmation (durable, for
          // reconnect) also fires this as a broadcast so the owner learns
          // it immediately instead of only on its next poll.
          final sessionId = p['session_id'] as String?;
          final userId = p['user_id'] as String?;
          if (sessionId != null &&
              userId != null &&
              sessionId == _provider.sessionId) {
            _provider.handleSessionReadyEvent(userId);
          }
          return;
        }
        if (type == 'screenshot_taken') {
          final shooterId = p['user_id'] as String?;
          final myId = context.read<AuthProvider>().currentUser?.id;
          if (shooterId != null && shooterId != myId && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.todScreenshotTaken(
                    widget.playerDisplayNames[shooterId] ??
                        context.l10n.someone,
                  ),
                ),
                backgroundColor: Colors.black87,
              ),
            );
          }
          return;
        }
        if (type == 'player_left' && mounted) {
          final name =
              p['display_name'] as String? ?? context.l10n.defaultPlayerName;
          final leavingId = p['user_id'] as String?;
          if (leavingId != null) {
            _provider.markPlayerAway(leavingId, forGood: true);
          }
          // The "fewer than 2 active players left -> end the game" check
          // previously lived here, computed from this screen's own
          // in-memory playerOrder/awayPlayerIds — ToD-only, and blind to
          // every departure path that doesn't broadcast 'player_left'
          // specifically (disconnect timeout, a kick/ban whose broadcast
          // was missed, a purely server-side sweep). It's now centralized
          // in RoomProvider._maybeAutoEndGame, computed from real DB
          // membership truth via the same reconciliation path kicked/
          // banned-removal already relies on (see _refreshMembers), and
          // shared by all 3 games uniformly instead of re-implemented per
          // screen. That path broadcasts the same 'game_ended' room event
          // (reason: 'not_enough_players'), handled below same as a
          // host-initiated end.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.todPlayerLeftGame(name)),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.fixed,
            ),
          );
          return;
        }
        // RoomProvider's own manual-transfer and automatic-failover paths
        // both broadcast 'ownership_transfer' (see room_provider.dart) —
        // this screen previously only matched 'ownership_transferred',
        // so this snackbar never fired for either of those, only for a
        // (currently ToD-absent) in-game handoff feature that would send
        // the other spelling.
        if ((type == 'ownership_transferred' || type == 'ownership_transfer') &&
            mounted) {
          final myId = context.read<AuthProvider>().currentUser?.id;
          final newOwnerId = p['new_owner_id'] as String?;
          if (newOwnerId == myId) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.todYouAreNowHost),
                backgroundColor: Colors.purple,
              ),
            );
          }
          return;
        }
        if (type == 'game_ended' && mounted) {
          final reason = p['reason'] as String? ?? '';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final isAllLeft =
                reason == 'all_players_left' || reason == 'not_enough_players';
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx2) => AlertDialog(
                title: Text(
                  isAllLeft
                      ? context.l10n.todGameOver
                      : context.l10n.todGameEnded,
                ),
                content: Text(
                  isAllLeft
                      ? context.l10n.todAllPlayersLeftGameBody
                      : context.l10n.todHostEndedGameBody,
                ),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx2).pop();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home/room/${widget.roomId}');
                      }
                    },
                    child: Text(context.l10n.todGoToLobby),
                  ),
                ],
              ),
            );
          });
          return;
        }
        if (type == 'tod_ready_count') {
          final ids = (p['ready_user_ids'] as List?)?.cast<String>() ?? [];
          _provider.onReadyCountUpdate(
            ids,
            ts: p['ts'] as int?,
            turnStartedAt: p['turn_started_at'] as int?,
          );
          return;
        }
        if (type == 'tod_player_activity') {
          _provider.onPlayerActivityUpdate(p);
          return;
        }
        if (type == 'dishonest_reason_added') {
          _provider.onDishonestReasonAdded(p);
          return;
        }
        if ((type == 'room_closed' || type == 'owner_left') && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              AppRouter.router.go(RouteNames.home);
              return;
            }
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx2) => AlertDialog(
                title: Text(context.l10n.lobbyRoomClosedTitle),
                content: Text(context.l10n.lobbyRoomClosedBody),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx2).pop();
                      AppRouter.router.go(RouteNames.home);
                    },
                    child: Text(context.l10n.ok),
                  ),
                ],
              ),
            );
          });
          return;
        }
      },
      onChatMessage: (p) {
        final msg = TodChatMsg(
          id: p['id'] as String?,
          senderId: p['user_id'] as String? ?? '',
          senderName:
              p['display_name'] as String? ?? context.l10n.defaultPlayerName,
          text: p['content'] as String? ?? '',
          ts: DateTime.fromMillisecondsSinceEpoch(
            (p['ts'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
          ),
          replyToId: p['reply_to_id'] as String?,
          replyToSenderName: p['reply_to_sender_name'] as String?,
          replyToText: p['reply_to_text'] as String?,
        );
        _provider.addChatMessage(msg);
      },
      onModeration: (p) => _handleModerationEvent(p),
      onSettingsChange: (_) {},
      onPresenceSync: (_) {},
      onStatusChange: (status) {
        if (!mounted) return;
        if (status == RealtimeSubscribeStatus.subscribed) {
          if (!_provider.hasSyncedState || _hasEverSubscribed) {
            sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
          }
          _hasEverSubscribed = true;
        }
      },
    );
  }

  void _handleModerationEvent(Map<String, dynamic> p) {
    final type = p['type'] as String?;
    final targetId = p['target_user_id'] as String?;
    final currentId = context.read<AuthProvider>().currentUser?.id;

    if (type == 'game_kick' && targetId != null) {
      _provider.markPlayerAway(targetId, forGood: true);
      if (targetId == currentId && mounted) {
        _provider.isNavigatingAway = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.todRemovedFromGame)),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home/room/${widget.roomId}');
        }
      }
      return;
    }

    if ((type == 'kick' || type == 'ban') && targetId != null) {
      // Room-level kick/ban (e.g. from the lobby's member panel, or a ban
      // triggered from inside a game) previously only told the TARGET's
      // own client to leave — every other client's game provider never
      // learned the target was gone, so it kept waiting on their
      // turn/vote/submission indefinitely even though they'd already been
      // removed from the room. Mark them away for everyone, same as
      // game_kick, regardless of whose client this is.
      _provider.markPlayerAway(targetId, forGood: true);
      if (targetId == currentId && mounted) {
        // Name the actual actor (admin/moderator display name from the
        // broadcast's by_name), never a generic "admin". Falls back to the
        // unattributed string only when the payload omits the name.
        final byName = (p['by_name'] as String?)?.trim();
        final msg = (byName != null && byName.isNotEmpty)
            ? (type == 'ban'
                  ? context.l10n.moderationYouWereBannedBy(byName)
                  : context.l10n.moderationYouWereKickedBy(byName))
            : (type == 'ban'
                  ? context.l10n.moderationYouWereBanned
                  : context.l10n.moderationYouWereKicked);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        context.go(RouteNames.home);
      }
    }
  }

  @override
  // Premium Plus away-from-app snackbar (item 1) — wraps whatever this
  // build() returns; no-op (returns [child] unchanged) when this screen
  // has no roomProvider.
  Widget _wrapAwayListener(Widget child) {
    final rp = widget.roomProvider;
    return rp == null
        ? child
        : AwayPresenceSnackbarListener(roomProvider: rp, child: child);
  }

  Widget build(BuildContext context) {
    // Stacked so the members management entry point stays reachable across
    // every phase this screen can render (choosing/reading/awaiting/
    // punishment-voting/game-over) without needing to be threaded into each
    // phase's own Scaffold individually.
    return _wrapAwayListener(
      Stack(
        children: [
          ChangeNotifierProvider.value(
            value: _provider,
            child: Consumer<TodGameProvider>(
              builder: (ctx, game, _) => _build(ctx, game),
            ),
          ),
          RoomMembersFab(
            roomProvider: widget.roomProvider,
            gameKickPlayer: _provider.kickPlayerFromGame,
            gameBanPlayer: _provider.banPlayerFromGame,
            heroTag: 'tod_members_${widget.roomId}',
          ),
          // Positioned below kToolbarHeight, not just SafeArea's status-bar
          // inset — these are later Stack children than the game phase's own
          // Scaffold/AppBar below, so Stack paints them ON TOP of it; without
          // accounting for the AppBar's own height too, they land inside the
          // AppBar's vertical span and visually overlap/block it.
          Positioned(
            top: kToolbarHeight,
            left: 0,
            right: 0,
            child: NoActivePlayersBanner(
              roomProvider: widget.roomProvider,
              isOwner: widget.isOwner,
              onEndGame: () => _provider.endGame(),
            ),
          ),
          // LobbyScreen stays mounted underneath this pushed game route, but
          // isn't visible while a moderator is actively here — mirror its
          // join-requests panel so requests filed mid-game (see
          // RoomProvider.initialize's new brand-new-player gate) are seen.
          if (widget.roomProvider?.canAcceptJoins ?? false)
            Positioned(
              top: kToolbarHeight + 8,
              left: 12,
              right: 12,
              child: SafeArea(
                bottom: false,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  // Item 11 — the elevated-card chrome now lives INSIDE
                  // JoinRequestsPanel (floatingCard: true) so it only exists
                  // together with real content — see its own doc comment.
                  // No wrapper here means no leftover footprint when there's
                  // nothing pending.
                  child: JoinRequestsPanel(
                    roomId: widget.roomId,
                    inGame: true,
                    floatingCard: true,
                  ),
                ),
              ),
            ),
          // Positioned.fill is required here: AnimatedReactionOverlay is
          // itself a Stack, and an un-positioned Stack nested inside this
          // outer Stack gets sized to fit its content and pinned to the
          // outer Stack's default alignment (AlignmentDirectional.topStart —
          // top-RIGHT under RTL/Arabic) instead of filling the screen. Its
          // internal Positioned children are computed from the full device
          // size (MediaQuery.sizeOf), so without this they all collapsed
          // into that corner instead of spanning the game screen.
          Positioned.fill(
            child: ChangeNotifierProvider.value(
              value: _provider,
              child: Consumer<TodGameProvider>(
                builder: (ctx, game, _) => CenterReactionOverlay(
                  reactions: (game.state?.currentReactions ?? const [])
                      .map((r) => (emoji: r.emoji, ts: r.ts, userId: r.userId))
                      .toList(),
                  avatarResolver: widget.roomProvider?.memberById,
                ),
              ),
            ),
          ),
          // Persistent indicator so everyone understands the rules before
          // playing, not just when someone happens to skip — per the room
          // owner's punishment-mode setting.
          if (_provider.config?.enablePunishments ?? false)
            const Positioned(
              top: kToolbarHeight + 8,
              left: 0,
              right: 0,
              child: Center(child: _PunishmentModeBadge()),
            ),
        ],
      ),
    );
  }

  Widget _build(BuildContext ctx, TodGameProvider game) {
    // Host disconnected mid-game — replaces everything else until the room
    // un-pauses (host back) or the game ends (timeout). Takes priority over
    // every other state; there is nothing meaningful to show underneath it.
    //
    // NEVER shown to the OWNER themselves: the overlay literally says
    // "waiting for the admin to return", which is nonsensical for the admin
    // — they ARE the host. On the admin's own reconnect the reconcile sets
    // local status=paused for a frame (before _maybeOwnerSelfResumeFromPause
    // finishes the DB-first flip back to in_game), which briefly rendered
    // this overlay to the admin. Suppressing it for the owner keeps the
    // admin visually on the game/loading state throughout the resume — no
    // flash. Only the getter/gameplay gate (isSessionActive) and the
    // countdown are untouched; every OTHER (non-owner) client still sees
    // the normal waiting screen while the admin is genuinely away.
    if (widget.roomProvider?.isPausedForHostReconnect == true &&
        widget.roomProvider?.isOwner != true) {
      return HostReconnectOverlay(roomProvider: widget.roomProvider!);
    }

    if (game.loadState == TodLoadState.loading) {
      return const TodLoadingScreen();
    }

    // A definitive failure must take priority over "still starting" —
    // game.isSessionStarting (_lifecycleState == 'starting') stays true
    // forever once session creation fails (nothing ever advances it past
    // 'starting'), so checking isSessionStarting before this error branch
    // would make a real, already-surfaced error permanently unreachable
    // in the UI: the "waiting for players" loading screen below would win
    // every single build, masking the error completely and presenting as
    // an infinite loading screen with no indication anything had gone
    // wrong. This check must come BEFORE isSessionStarting for exactly
    // that reason (latent here — ToD's own create_game_session call
    // doesn't currently fail in practice — but identical to the
    // already-observed bug in NHIE/Meme, fixed the same way for
    // consistency).
    if (game.loadState == TodLoadState.error) {
      Future<void> leaveToLobby() async {
        if (widget.isOwner) {
          try {
            await sl.realtimeService.broadcastGameEnded(widget.roomId, {
              'reason': 'host_left',
              'session_id': game.sessionId,
            });
            await sl.roomRepository.updateStatus(
              widget.roomId,
              RoomStatus.waiting,
            );
          } catch (_) {}
        }
        // Prefer popping back to the LobbyScreen instance already alive
        // underneath this pushed game route over go(), which may not
        // resolve the Future _pushGameRoute is awaiting to clear its
        // _navigatedToGame guard — leaving a second game in this same room
        // permanently unable to navigate. Same pattern as
        // goToLobbyOrHome/onGameEnded.
        if (ctx.mounted) {
          if (ctx.canPop()) {
            ctx.pop();
          } else {
            // Room still exists (session ended/failed to start, e.g. a
            // player was kicked during loading) — return to its LOBBY, not
            // the app home. See _leaveIfRoomNoLongerActive's rationale.
            ctx.go('/home/room/${widget.roomId}');
          }
        }
      }

      // The session-ended case (aborted elsewhere — auto-end, a
      // disconnect timeout, the owner quitting) is not a real error the
      // user needs to read and dismiss — it's this client finding out
      // late that the game is already over, exactly what onGameEnded
      // handles for everyone whose broadcast *did* arrive in time (no
      // delivery guarantee on Realtime Broadcast — this is the fallback
      // for whoever's didn't). Leave automatically instead of parking on
      // a screen that looks like a crash and waiting for a manual tap.
      if (game.error == kSessionEndedErrorMessage) {
        // Never render the red ErrorView for this specific case — even a
        // single visible frame of it before the postFrameCallback below
        // fires reads as "an error appeared" to the user, even though it's
        // just this client finding out late that the game already ended
        // cleanly elsewhere. A plain loading screen while leaving happens
        // in the background looks identical to every other brief
        // navigation transition in this app.
        if (!_autoLeftOnSessionEnd) {
          _autoLeftOnSessionEnd = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => leaveToLobby());
        }
        return const TodLoadingScreen();
      }

      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: leaveToLobby)),
        body: ErrorView(
          message: game.error ?? 'Failed to load game',
          onRetry: () => ctx.go(RouteNames.home),
        ),
      );
    }

    // Session ready barrier: state is already loaded and rendering fine
    // (that's specifically what made the old bug invisible — the screen
    // LOOKED ready) but this client's own session hasn't reached ACTIVE
    // yet, so no gameplay UI is shown at all — nothing to press, nothing
    // to silently ignore. Checked AFTER the error branch above — see its
    // comment for why the order matters.
    if (game.isSessionStarting) {
      // The ready-count is only tracked on the owner's client (it's the
      // one collecting confirmations) — a follower just sees the plain
      // waiting copy instead of a "0/0" that would mean nothing to them.
      return TodLoadingScreen(
        subtitle: game.expectedReadyCount > 0
            ? ctx.l10n.todWaitingForPlayers(
                game.readyConfirmedCount,
                game.expectedReadyCount,
              )
            : null,
      );
    }

    if (game.loadState == TodLoadState.gameOver ||
        (game.state?.isOver ?? false)) {
      return TodEndScreen(
        state: game.state!,
        displayNames: widget.playerDisplayNames,
        onLeave: () => goToLobbyOrHome(
          ctx,
          widget.roomId,
          roomProvider: widget.roomProvider,
        ),
      );
    }

    final state = game.state;
    if (state == null) return const TodLoadingScreen();

    return _TodGameScaffold(
      state: state,
      game: game,
      displayNames: widget.playerDisplayNames,
      roomId: widget.roomId,
      isOwner: widget.isOwner,
    );
  }
}

/// Persistent "punishment mode is active" indicator — shown throughout the
/// game (not just when someone skips) so every participant understands the
/// rules before playing, per the room owner's setting.
class _PunishmentModeBadge extends StatelessWidget {
  const _PunishmentModeBadge();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.deepOrange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gavel_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              context.l10n.todPunishmentModeOn,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodGameScaffold extends StatefulWidget {
  const _TodGameScaffold({
    required this.state,
    required this.game,
    required this.displayNames,
    required this.roomId,
    required this.isOwner,
  });
  final TodState state;
  final TodGameProvider game;
  final Map<String, String> displayNames;
  final String roomId;
  final bool isOwner;
  @override
  State<_TodGameScaffold> createState() => _TodGameScaffoldState();
}

class _TodGameScaffoldState extends State<_TodGameScaffold> {
  bool _showHistory = false;
  bool _showChat = false;
  int _unreadChat = 0;

  // First-time Truth or Dare overview highlight (the always-present HUD).
  final GlobalKey _hudShowcaseKey = GlobalKey();

  // The route-level back guard owned by GameScreenSecurityGate. Registering
  // here routes EVERY back gesture — including one made while an internal
  // sub-view (round history / chat) is open, which the old per-screen PopScope
  // couldn't see — through _handleGameBack, so back can never escape the game.
  GameBackController? _backGuard;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final guard = GameBackGuard.of(context);
    if (!identical(guard, _backGuard)) {
      _backGuard?.unregister(_handleGameBack);
      _backGuard = guard;
      _backGuard?.register(_handleGameBack);
    }
  }

  @override
  void dispose() {
    _backGuard?.unregister(_handleGameBack);
    super.dispose();
  }

  /// Single back handler for the active Truth-or-Dare screen: close an open
  /// sub-view first (so back dismisses history/chat instead of leaving the
  /// game), otherwise run the existing quit-confirmation flow. Always consumes
  /// the gesture so the game route never pops out from under an active game.
  Future<bool> _handleGameBack() async {
    if (!mounted) return true;
    if (_showChat) {
      setState(() => _showChat = false);
      return true;
    }
    if (_showHistory) {
      setState(() => _showHistory = false);
      return true;
    }
    await _showLeaveDialog(context, widget.game, widget.state);
    return true;
  }

  void _navigateAway(BuildContext ctx, String location) {
    // widget.game (TodGameProvider) is shared with _TodGameScreenState,
    // which owns the realtime listeners — this is the single flag both
    // sides check, so a programmatic pop triggered by a realtime event
    // isn't misread by PopScope below as the user backing out.
    widget.game.isNavigatingAway = true;
    if (ctx.canPop()) {
      ctx.pop();
    } else {
      ctx.go(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final game = widget.game;

    if (_showHistory) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => setState(() => _showHistory = false),
          ),
          title: Text(context.l10n.todHistoryRoundsCount(state.history.length)),
        ),
        body: _HistoryPanel(
          history: state.history,
          displayNames: widget.displayNames,
          game: game,
        ),
      );
    }

    return ScreenTutorial(
      tutorialId: TutorialIds.todIntro,
      steps: [_hudShowcaseKey],
      child: PopScope(
        // Kept as a redundant route-pop blocker only; the actual back ACTION is
        // handled once, centrally, by GameScreenSecurityGate via _handleGameBack
        // (registered above) — so a system back fires the quit dialog exactly
        // once, and sub-views the old handler couldn't see are covered too.
        canPop: false,
        onPopInvoked: (_) {},
        child: Scaffold(
          appBar: AppBar(
            // Solid brand-purple so it flows straight into TodHud's own
            // purple-to-blue gradient below it — one continuous "party" chrome
            // instead of the system-themed AppBar it used to be.
            backgroundColor: AppColors.brandPurpleDark,
            foregroundColor: Colors.white,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            automaticallyImplyLeading: false,
            title: const Text(''),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _showLeaveDialog(context, game, state),
            ),
            actions: [
              Consumer<TodGameProvider>(
                builder: (_, g, __) => Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      onPressed: () {
                        g.clearUnreadChat();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => GameChatSheet(
                            listenable: g,
                            messagesOf: () => g.chatMessages,
                            myId: g.currentUserId,
                            title: context.l10n.todChatTitle,
                            onSend: (text, {replyTo}) =>
                                g.sendChat(text, replyTo: replyTo),
                            memberOf: g.roomProvider?.memberById,
                            isPremiumPlus:
                                context
                                    .read<AuthProvider>()
                                    .currentUser
                                    ?.isPremiumPlusActive ??
                                false,
                            participants: g.gameParticipants,
                            onSendTargeted:
                                (
                                  text, {
                                  required recipientIds,
                                  required recipientNames,
                                  replyTo,
                                }) => g.sendTargetedChat(
                                  text,
                                  recipientIds: recipientIds,
                                  recipientNames: recipientNames,
                                  replyTo: replyTo,
                                ),
                          ),
                        );
                      },
                    ),
                    if (g.unreadChat > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (state.history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  tooltip: context.l10n.sharedHistoryTooltip,
                  onPressed: () => setState(() => _showHistory = true),
                ),
              RulesButton(gameType: GameType.truthOrDare, config: game.config),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                tutorialShowcase(
                  context: context,
                  showcaseKey: _hudShowcaseKey,
                  title: context.l10n.tutTodTitle,
                  description: context.l10n.tutTodBody,
                  child: TodHud(
                    state: state,
                    game: game,
                    displayNames: widget.displayNames,
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey('${state.phase}-${state.currentPlayerId}'),
                      child: _phaseWidget(
                        context,
                        game,
                        widget.displayNames,
                        state,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLeaveDialog(
    BuildContext ctx,
    TodGameProvider game,
    TodState state,
  ) async {
    if (!ctx.mounted) return;
    final isOwner = widget.isOwner;
    final myUserId = game.currentUserId;
    final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(ctx.l10n.todQuitGameTitle),
        content: Text(ctx.l10n.todQuitGameBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: Text(ctx.l10n.todQuitGame),
          ),
        ],
      ),
    );
    if (confirmed != true || !ctx.mounted) return;

    if (isOwner) {
      // Quit Game only ends the current game session — it must NOT close
      // or delete the room. Closing the room is a separate action, only
      // available from LobbyScreen's room management. Use the dedicated
      // game-ended broadcast (not 'owner_left') so every player's existing
      // onGameEnded handler fires immediately and pops back to this same
      // room's lobby — no dialog required on the receiving end.
      try {
        await sl.realtimeService.broadcastGameEnded(widget.roomId, {
          'reason': 'host_quit_to_lobby',
          'session_id': game.sessionId,
        });
        await sl.roomRepository.updateStatus(widget.roomId, RoomStatus.waiting);
      } catch (_) {}
      if (ctx.mounted) _navigateAway(ctx, '/home/room/${widget.roomId}');
    } else {
      // A normal player/spectator quitting the game also leaves the room
      // entirely (frees their slot, updates counts) — for_good:true tells
      // every client's RoomProvider to remove them from the member list.
      final displayName =
          widget.displayNames[myUserId] ?? ctx.l10n.defaultPlayerName;
      try {
        await sl.roomRepository.setMemberDefinitiveLeave(
          widget.roomId,
          myUserId,
        );
        await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
          'type': 'player_left',
          'user_id': myUserId,
          'display_name': displayName,
          'for_good': true,
        });
      } catch (_) {}
      if (ctx.mounted) {
        widget.game.isNavigatingAway = true;
        ctx.go(RouteNames.home);
      }
    }
  }

  Widget _phaseWidget(
    BuildContext ctx,
    TodGameProvider game,
    Map<String, String> displayNames,
    TodState state,
  ) {
    return switch (state.phase) {
      TodTurnPhase.punishmentVoting => TodPunishmentScreen(
        state: state,
        game: game,
        displayNames: widget.displayNames,
      ),
      _ => TodCardScreen(
        state: state,
        game: game,
        displayNames: widget.displayNames,
      ),
    };
  }
}

class _HistoryPanel extends StatefulWidget {
  const _HistoryPanel({
    required this.history,
    required this.displayNames,
    required this.game,
  });
  final List<TodRoundRecord> history;
  final Map<String, String> displayNames;
  final TodGameProvider game;

  @override
  State<_HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<_HistoryPanel> {
  // turnStartedAt -> (distinctViewers, totalViews). Fetched exactly once
  // when the panel opens (never from build()/a stream callback) so it
  // can't re-fire on every rebuild; {} until the fetch resolves, which
  // simply means no round shows a replay count yet.
  Map<int, ({int distinctViewers, int totalViews})> _viewStats = const {};

  @override
  void initState() {
    super.initState();
    final turnStartedAts = widget.history
        .where((r) => r.hadProof && r.turnStartedAt != null)
        .map((r) => r.turnStartedAt!)
        .toSet()
        .toList();
    if (turnStartedAts.isNotEmpty) {
      widget.game.fetchProofViewStats(turnStartedAts).then((stats) {
        if (mounted) setState(() => _viewStats = stats);
      });
    }
  }

  String _name(String id) =>
      widget.displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

  @override
  Widget build(BuildContext context) {
    final history = widget.history;
    final theme = context.theme;
    if (history.isEmpty) {
      return Center(child: Text(context.l10n.todNoRoundsYet));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: history.length,
      itemBuilder: (_, i) {
        final round = history[history.length - 1 - i];
        final reactTally = <String, int>{};
        for (final r in round.reactions) {
          reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
        }
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '${round.roundNumber}',
                style: theme.textTheme.labelLarge,
              ),
            ),
            title: Text(
              _name(round.playerId),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              round.card != null
                  ? context.l10n.todRoundTypeContent(
                      round.card!.type == TodCardType.truth
                          ? context.l10n.todTruth
                          : context.l10n.todDare,
                      round.card!.content,
                    )
                  : context.l10n.todSkipped,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (round.card != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: round.card!.type == TodCardType.truth
                              ? Colors.blue.withOpacity(0.08)
                              : Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          round.card!.content,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    if (round.response.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💬 ', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              context.l10n.todQuotedResponse(round.response),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (round.voteCount > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.todVoteCount(round.voteCount),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (round.hadProof) ...[
                      const SizedBox(height: 8),
                      _ProofWatchedBadge(watchedBy: round.proofWatchedBy),
                      const SizedBox(height: 4),
                      _ReplayCountBadge(
                        replays: switch (
                            round.turnStartedAt != null
                                ? _viewStats[round.turnStartedAt!]
                                : null) {
                          final stats? =>
                            (stats.totalViews - stats.distinctViewers)
                                .clamp(0, 1 << 30),
                          null => 0,
                        },
                      ),
                    ],
                    if (reactTally.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: reactTally.entries
                            .map(
                              (e) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${e.key} ${e.value}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    // Item: Game History → my own past turn → dishonest
                    // reasons. Only ever shown/fetched for a round the
                    // VIEWER themselves played — a spectator or another
                    // player's round never reaches this branch, and even
                    // if it did, honesty_votes' own RLS ("participant
                    // read": voter OR target only) independently blocks
                    // the read. Voter identity is never returned — see
                    // HonestyVoteRepository.getDishonestReasons.
                    if (round.playerId == widget.game.currentUserId)
                      DishonestReasonsPanel(
                        key: ValueKey('history_dishonest_${round.roundNumber}'),
                        fetch: () => widget.game
                            .getDishonestReasonsForRound(round.roundNumber),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProofWatchedBadge extends StatelessWidget {
  const _ProofWatchedBadge({required this.watchedBy});
  final List<String> watchedBy;

  @override
  Widget build(BuildContext context) {
    final watched = watchedBy.isNotEmpty;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            watched ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            context.l10n.todProofWatchedByCount(watchedBy.length),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ReplayCountBadge extends StatelessWidget {
  const _ReplayCountBadge({required this.replays});
  final int replays;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.replay_rounded, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            context.l10n.todReplayCount(replays),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PausedOverlay extends StatefulWidget {
  const _PausedOverlay({required this.onLeave});
  final VoidCallback onLeave;

  @override
  State<_PausedOverlay> createState() => _PausedOverlayState();
}

class _PausedOverlayState extends State<_PausedOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) =>
                      Opacity(opacity: 0.6 + _pulse.value * 0.4, child: child),
                  child: const Text('⏸', style: TextStyle(fontSize: 72)),
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.todGamePausedTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.todHostSteppedAway,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  onPressed: widget.onLeave,
                  child: Text(context.l10n.todLeaveForNow),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
