
import 'dart:async';
import 'package:jma3a/core/utils/app_logger.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/app_tutorial_service.dart';
import '../../../../shared/widgets/tutorial/screen_tutorial.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../../friends/presentation/friends_provider.dart';
import '../../../notifications/presentation/notification_provider.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../../../shared/widgets/overlays/confirm_dialog.dart';
import '../../../../shared/widgets/overlays/branded_status_view.dart';
import '../../../packs/data/pack_repository.dart';
import '../../../games/truth_or_dare/presentation/widgets/tod_pre_game_config_sheet.dart';
import '../../../packs/presentation/pack_provider.dart';
import '../room_provider.dart';
import '../../../../features/games/engine/base_game_engine.dart';
import '../widgets/chat_panel.dart';
import '../widgets/game_settings_sheet.dart';
import '../widgets/member_tile.dart';
import '../widgets/moderation_sheet.dart';
import '../../../../shared/widgets/join_requests_panel.dart';

String _permissionLabel(BuildContext context, String key) => switch (key) {
  ModeratorPermission.acceptJoins => context.l10n.roomsPermAcceptJoins,
  ModeratorPermission.acceptSpectators => context.l10n.roomsPermAcceptSpectators,
  ModeratorPermission.acceptRejoins => context.l10n.roomsPermAcceptRejoins,
  ModeratorPermission.advanceTurn => context.l10n.roomsPermAdvanceTurn,
  ModeratorPermission.skipTurn => context.l10n.roomsPermSkipTurn,
  ModeratorPermission.kickPlayers => context.l10n.roomsPermKickPlayers,
  ModeratorPermission.muteChat => context.l10n.roomsPermMuteChat,
  ModeratorPermission.mutePlayers => context.l10n.roomsPermMutePlayers,
  ModeratorPermission.manageSettings => context.l10n.roomsPermManageSettings,
  ModeratorPermission.endGame => context.l10n.roomsPermEndGame,
  ModeratorPermission.startGame => context.l10n.roomsPermStartGame,
  _ => key,
};

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.roomId});
  final String roomId;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

/// The three states this screen renders during a game start:
///   lobby        — the ordinary, fully interactive lobby.
///   preparing    — start accepted (and, for Truth or Dare, settings
///                  confirmed) but room.status hasn't caught up locally
///                  yet. Overlaid on the (input-absorbed) lobby, not a
///                  replacement — see build()'s Stack.
///   enteringGame — room.status itself now confirms starting/in_game/
///                  paused; a full-screen lock replaces the lobby outright
///                  until the actual game route is pushed. This is also
///                  the resume/rejoin path — a client that was never in
///                  `preparing` at all (a follower, or an app relaunch
///                  landing straight on an already-starting room) reaches
///                  this phase directly from room.status alone.
/// See _LobbyScreenState._gameStartPhase for the derivation.
enum _GameStartPhase { lobby, preparing, enteringGame }

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  late final RoomProvider _provider;
  StreamSubscription<RoomLifecycleEvent>? _lifecycleSub;
  List<String>? _sessionPlayerIds;
  // True once we've observed THIS room OPEN (status != closed) while connected.
  // Distinguishes "the host just closed the room while I'm sitting in it"
  // (must be removed + shown the room-closed message) from "I reconnected into
  // a room I belong to that was ALREADY closed" (the session-participant
  // exemption — I'm allowed to land in the closed lobby). Without this split,
  // the reconnect exemption wrongly kept a present player in a room the host
  // had just closed, because the owner_left handler won't re-fire the
  // roomClosed dialog once status is already 'closed'.
  bool _wasRoomOpenWhileConnected = false;
  bool _fetchingSessionPlayerIds = false;

  // Role-aware lobby tutorial targets (only the controls a given role can
  // actually use are ever added to the step list — see _lobbyTutorialSteps).
  final GlobalKey _lobbyManageKey = GlobalKey();
  final GlobalKey _lobbyStartKey = GlobalKey();
  final GlobalKey _lobbyReadyKey = GlobalKey();

  /// The ordered highlight steps for the CURRENT role, matching exactly what is
  /// rendered so no step ever points at a missing target. Host: manage room +
  /// start game. A non-owner who can start (mod): start game. A normal player:
  /// the ready toggle. A spectator: nothing (they only watch) — an empty list
  /// makes [ScreenTutorial] a no-op.
  List<GlobalKey> _lobbyTutorialSteps(RoomProvider room) {
    if (room.isOwner) return [_lobbyManageKey, _lobbyStartKey];
    if (room.canStartGame) return [_lobbyStartKey];
    final isSpectator = room.currentMember?.isSpectator ?? false;
    if (!isSpectator && room.isConnected) return [_lobbyReadyKey];
    return const [];
  }

  // Single idempotency latch for terminal, leave-the-room navigation. A
  // kick produces TWO legitimate signals for the same event — the
  // moderation broadcast (-> RoomLifecycleEvent.kicked) and the
  // room_members CDC/reconcile (-> RoomLifecycleEvent.removed) — and a
  // close/ban can add more. Without this, two near-simultaneous
  // context.go(home) calls could run while the route is already tearing
  // down (the second on a defunct context -> red ErrorWidget). The first
  // terminal event navigates; every later one no-ops.
  bool _isLeavingRoom = false;

  // Drives ONLY the full-screen "Preparing Game" overlay's visibility —
  // deliberately separate from RoomProvider.isStartingGame (which still
  // instantly disables the Start button/all lobby taps the moment Start is
  // tapped, for every game type, via the AbsorbPointer in _build). For
  // Truth or Dare, the pre-game settings sheet must be shown and confirmed
  // BEFORE this ever becomes true — see _BottomActionBar._doStartGame's
  // single setPreparingLock(true) call site for exactly where. For every
  // other game (no settings step) that point is reached essentially
  // immediately.
  //
  // ROOT CAUSE this flag exists to close: RoomProvider.isStartingGame (and
  // this flag, in the previous version of this fix) were both cleared the
  // instant _doStartGame's own network calls (the pack check, the
  // game_started broadcast, the rooms.status='starting' write) RETURNED —
  // but returning from those calls does NOT mean the LOCAL RoomProvider
  // has actually adopted the new status yet. This client only learns its
  // own write succeeded via a separate, later signal — the realtime
  // 'game_started' self-echo (RoomProvider._handleGameStarted) or, failing
  // that, the periodic reconcile poll — which can lag the write by
  // anywhere from tens of milliseconds to several seconds on a slow
  // connection. Clearing the lock on _doStartGame's return (instead of on
  // that later signal) opened exactly that window: the lock dropped, but
  // room.status was still locally 'waiting', so _build's final branch fell
  // through to the ordinary interactive lobby — the "lobby flashes during
  // the delay" bug.
  //
  // Fix: this flag is now cleared ONLY on a genuine failure/cancel (see
  // _onStartGame's catch) or once the game route has actually been pushed
  // and popped back to this lobby (_pushGameRoute's finally — covers a
  // finished/aborted game cleanly). It is deliberately NEVER cleared just
  // because _doStartGame returned successfully, and never re-derived from
  // room.status — so a stale/out-of-order status read while this is true
  // can only ever *confirm* the transition (via _isEnteringOrInGame taking
  // over — see _gameStartPhase) or leave the lock exactly as it was; it
  // can never regress this client back to the interactive lobby mid-start.
  bool _showPreparingLock = false;
  void _setPreparingLock(bool value) {
    if (mounted) setState(() => _showPreparingLock = value);
  }

  // Item 5 — reported to NotificationProvider so it can suppress a
  // redundant in-app notification for a chat message in the room the
  // user is already looking at (tab index 1 == ChatPanel). Cleared
  // whenever the tab isn't chat, and on dispose (leaving the lobby
  // entirely is exactly as "not viewing this room's chat" as switching
  // tabs).
  void _onTabChanged() {
    if (!mounted) return;
    context.read<NotificationProvider>().setActiveChatRoom(
      _tabs.index == 1 ? widget.roomId : null,
    );
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);

    final auth = context.read<AuthProvider>();
    _provider = RoomProvider(
      roomRepository: sl.roomRepository,
      realtimeService: sl.realtimeService,
      presenceService: sl.presenceService,
      cacheService: sl.roomCacheService,
      currentUserId: auth.currentUser!.id,
      currentDisplayName: auth.currentUser!.displayName ?? context.l10n.packPlayer,
      currentAvatarUrl: auth.currentUser!.avatarUrl,
    );

    _initializeWithRoleCheck();

    _lifecycleSub = _provider.lifecycleEvents.listen(_onLifecycleEvent);

    _provider.addListener(_onRoomStateChanged);
  }

  Future<void> _initializeWithRoleCheck() async {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    bool isRoomOwner = false;
    try {
      final roomInfo = await Supabase.instance.client
          .from('rooms')
          .select('status, owner_id')
          .eq('id', widget.roomId)
          .maybeSingle();
      final settingsInfo = await Supabase.instance.client
          .from('room_settings')
          .select('allow_spectators, allow_anonymous_spectators')
          .eq('room_id', widget.roomId)
          .maybeSingle();

      final isInGame = roomInfo?['status'] == 'in_game';
      final allowSpectators =
          settingsInfo?['allow_spectators'] as bool? ?? false;
      final allowAnonymousSpectators =
          settingsInfo?['allow_anonymous_spectators'] as bool? ?? true;
      isRoomOwner = roomInfo?['owner_id'] == myId;

      // Must not clear the pack while the room is mid-game — a returning
      // owner reconnecting to an in-progress/paused session needs their
      // selected pack preserved (recover_owner_room, triggered inside
      // _provider.initialize() below, resets an in-progress game back to a
      // waiting lobby without touching pack_id). Only applies to an
      // ordinary "owner opens their own still-waiting room" entry.
      if (isRoomOwner && !isInGame && roomInfo?['status'] != 'paused') {
        await sl.roomRepository.clearPack(widget.roomId).catchError((_) {});
      }

      final isPremium = mounted
          ? (context.read<AuthProvider>().currentUser?.isPremiumActive ?? false)
          : false;

      String role = 'player';
      if (allowSpectators && !isRoomOwner && mounted) {
        final picked = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _JoinRoleDialog(
            isInGame: isInGame,
            isPremium: isPremium,
            allowAnonymous: allowAnonymousSpectators,
          ),
        );
        role = picked ?? 'player';
      }

      if (mounted) {
        _provider.initialize(widget.roomId, role: role);
      }
    } catch (_) {
      // Room/settings fetch failed above, so room status is unknown here —
      // skip clearPack entirely rather than risk clobbering pack_id for a
      // room that turns out to be mid-game (see the guarded call above).
      if (mounted) {
        _provider.initialize(widget.roomId);
      }
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onRoomStateChanged);
    _ownerLeftTimer?.cancel();
    _lifecycleSub?.cancel();
    _tabs.removeListener(_onTabChanged);
    // Leaving the lobby entirely is exactly as "not viewing this room's
    // chat" as switching away from the chat tab (item 5/8) — never leave
    // a stale room id suppressing that room's notifications after this
    // screen is gone.
    context.read<NotificationProvider>().setActiveChatRoom(null);
    _tabs.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _onLifecycleEvent(RoomLifecycleEvent event) {
    if (!mounted) return;
    AppLogger.info(
      'LOBBY_LIFECYCLE event=$event isOwner=${_provider.isOwner} '
      'status=${_provider.room?.status} isLeavingRoom=$_isLeavingRoom',
    );
    switch (event) {
      case RoomLifecycleEvent.kicked:
      case RoomLifecycleEvent.banned:
      case RoomLifecycleEvent.removed:
        // OWNER INVARIANT: the room's owner can never be legitimately
        // kicked/banned/removed from their OWN room (they own it; the
        // moderation RPCs reject targeting the owner, and no one else can
        // moderate them). If any of these fire for the owner it's a
        // transient reconciliation glitch — e.g. a member-list refresh that
        // momentarily didn't include the owner right after they kicked the
        // only other player in a 2-player room. Do NOT send the owner to
        // the app home. A genuine room deletion is a separate `roomClosed`
        // event, handled below. This is the root-cause guard for "admin
        // kicked out when kicking the only other player during loading".
        if (_provider.isOwner) {
          AppLogger.warning(
            'LOBBY_LIFECYCLE ignored $event for OWNER (spurious) '
            'room=${_provider.room?.id}',
          );
          return;
        }
        if (_isLeavingRoom) return;
        _isLeavingRoom = true;
        final banner = event == RoomLifecycleEvent.banned
            ? context.l10n.moderationYouWereBanned
            : context.l10n.moderationYouWereKicked;
        _showEventBanner(_moderationMessage(banner), isError: true);
        AppLogger.info('LOBBY_LIFECYCLE nav home reason=$event');
        context.go(RouteNames.home);
      case RoomLifecycleEvent.roomClosed:
        if (_isLeavingRoom) return;
        _isLeavingRoom = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            AppRouter.router.go(RouteNames.home);
            return;
          }
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => AlertDialog(
              title: Text(context.l10n.lobbyRoomClosedTitle),
              content: Text(context.l10n.lobbyRoomClosedBody),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    AppRouter.router.go(RouteNames.home);
                  },
                  child: Text(context.l10n.ok),
                ),
              ],
            ),
          );
        });
      case RoomLifecycleEvent.ownershipTransferred:
        _showEventBanner(context.l10n.lobbyYouAreNowOwner);
      case RoomLifecycleEvent.memberLeft:
        final name = _provider.lastDepartedMemberName;
        if (name != null && name.isNotEmpty) {
          _showEventBanner(context.l10n.lobbyPlayerLeft(name));
        }
    }
  }

  void _showEventBanner(String message, {bool isError = false}) {
    if (!mounted) return;
    context.showSnackBar(message, isError: isError);
  }

  /// Builds a real "removed by X: reason" message from the actor name +
  /// reason kickPlayer/banPlayer already broadcast — falling back to
  /// [base] alone when either is missing (e.g. an older client that
  /// hasn't sent them yet).
  String _moderationMessage(String base) {
    final actor = _provider.lastModerationActorName;
    final reason = _provider.lastModerationReason;
    var message = (actor != null && actor.isNotEmpty)
        ? '$base by $actor'
        : base;
    if (reason != null && reason.trim().isNotEmpty) {
      message = '$message: ${reason.trim()}';
    }
    return message;
  }

  bool _navigatedToGame = false;

  Timer? _ownerLeftTimer;
  int _maxMembersSeen = 0;

  void _onRoomStateChanged() {
    if (!mounted) return;
    final room = _provider;

    // Record that we've seen this room live/open — see _wasRoomOpenWhileConnected.
    if (room.isInitialized &&
        room.isConnected &&
        room.room != null &&
        room.room!.status != RoomStatus.closed) {
      _wasRoomOpenWhileConnected = true;
    }

    if (room.room?.status == RoomStatus.closed && !room.isOwner) {
      // A verified participant RECONNECTING into a room that was ALREADY closed
      // before they arrived legitimately belongs to it — let them land in the
      // closed lobby (view the ended game, then leave normally). But if the
      // room JUST closed while they were sitting in it (_wasRoomOpenWhileConnected),
      // the host closed the room ON them: they MUST be removed and shown the
      // room-closed message, exactly like everyone else. Only a genuine
      // reconnect (never saw the room open on this client) gets the exemption.
      final liveClose = _wasRoomOpenWhileConnected;
      final remove = RoomProvider.shouldRemoveOnRoomClosed(
        isOwner: room.isOwner,
        isSessionParticipant: room.isSessionParticipant,
        wasRoomOpenWhileConnected: liveClose,
      );
      AppLogger.info(
        'ROOM_STATE_CHANGED->CLOSED room=${room.room?.id} '
        'userId=${_provider.currentMember?.userId} '
        'sessionParticipant=${room.isSessionParticipant} '
        'liveClose=$liveClose remove=$remove isLeaving=$_isLeavingRoom',
      );
      if (!remove) {
        _showEventBanner(context.l10n.lobbyRoomClosedBody);
      } else {
        // Removed by the host's close. This is the reconcile-path fallback that
        // has ALWAYS handled removal when the owner_left broadcast is missed;
        // it deliberately does NOT set _isLeavingRoom so the roomClosed
        // lifecycle dialog (the primary owner_left path) still shows when that
        // broadcast DID arrive. The shared latch inside each navigation call
        // keeps the two from fighting.
        AppLogger.info(
          'ROOM_MEMBER_REMOVED room=${room.room?.id} '
          'userId=${_provider.currentMember?.userId} reason=host_closed_room',
        );
        _showEventBanner(context.l10n.lobbyRoomClosedBody);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (context.canPop())
            context.pop();
          else
            context.go(RouteNames.home);
        });
      }
      return;
    }

    // Batch D keep-game close (closed_at set, status stays in_game). Only a
    // non-owner LOBBY-ONLY player is turned out, and ONLY while a game is
    // actively running: an active-session participant (game_sessions.
    // player_ids) keeps playing and must NEVER be ejected — the lobby stays
    // mounted under the game route, so this listener fires for them too.
    // Deliberately NOT applied once the game has ended (status waiting/ended):
    // players who just finished follow the normal game-end -> lobby flow
    // (Batch A) and stay; the room merely remains closed to NEW entrants.
    // While the participant list hasn't loaded yet, defer rather than risk
    // ejecting a participant.
    final r = room.room;
    final gameLive =
        r?.status == RoomStatus.inGame || r?.status == RoomStatus.paused;
    final amSpectator = room.currentMember?.isSpectator ?? false;
    if (r != null && r.isClosed && !room.isOwner && gameLive && !amSpectator) {
      final myId = context.read<AuthProvider>().currentUser?.id;
      final sessionKnown = _sessionPlayerIds != null;
      final iAmParticipant =
          sessionKnown && myId != null && _sessionPlayerIds!.contains(myId);
      if (sessionKnown && !iAmParticipant) {
        _showEventBanner(context.l10n.lobbyRoomClosedForNewPlayers);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RouteNames.home);
          }
        });
        return;
      }
    }

    if (room.members.length > _maxMembersSeen) {
      _maxMembersSeen = room.members.length;
    }

    final ownerGone =
        room.isInitialized &&
        !room.isOwner &&
        _maxMembersSeen >= 2 &&
        room.members.isNotEmpty &&
        room.room?.status != RoomStatus.inGame &&
        !room.members.any((m) => m.isOwner);

    if (ownerGone) {
      _ownerLeftTimer ??= Timer(const Duration(seconds: 2), () {
        _ownerLeftTimer = null;
        if (!mounted || _isLeavingRoom) return;
        final r2 = _provider;
        if (r2.isInitialized &&
            !r2.isOwner &&
            r2.members.isNotEmpty &&
            r2.room?.status != RoomStatus.inGame &&
            !r2.members.any((m) => m.isOwner)) {
          // Shares the terminal-navigation latch — a concurrent
          // roomClosed/removed/kicked event must not also navigate.
          _isLeavingRoom = true;
          _showEventBanner('The host left the room.');
          if (context.canPop())
            context.pop();
          else
            context.go(RouteNames.home);
        }
      });
    } else {
      _ownerLeftTimer?.cancel();
      _ownerLeftTimer = null;
    }

    if (ownerGone) return;

    // The single decision point picks this up on its own — see
    // _syncGameRoute's doc comment for why nothing else in this file is
    // allowed to independently decide to push the game route.
    _syncGameRoute();
  }

  // True for exactly one _syncGameRoute call: the one immediately
  // following a genuine, fresh "Start Game" press (set by _doStartGame,
  // consumed and cleared the moment it's read). Every other route into
  // this method — reconnect, Continue Game, the Rejoin banner, a
  // follower's very first entry — is a resume of an already-running game,
  // never a fresh one. This is state the game providers genuinely need
  // (skip the resume lookup vs. restore from it — see
  // TodGameScreen.isNewGameStart), not a lifecycle guard; there is
  // nothing else it could be inferred from once the decision of *whether*
  // to navigate is centralized here instead of at each call site.
  bool _pendingFreshStart = false;

  /// True whenever this client should be looking at SOME full-screen
  /// "entering the game" state — either the STARTING_GAME lock (see
  /// build()) or the actual pushed game route — rather than the ordinary,
  /// interactive lobby body. This is the single shared signal both
  /// build() and _syncGameRoute() consult, so the two can never disagree
  /// about whether the raw lobby is allowed to render for a given frame.
  /// Deliberately broader than _syncGameRoute's own additional push gates
  /// below (owner-only during 'starting', packId populated, confirmed
  /// membership, ...) — those decide whether a push is safe to actually
  /// perform right now, not whether the lobby is allowed to flash
  /// underneath while we wait for them to resolve.
  bool _isEnteringOrInGame(RoomProvider room) {
    final status = room.room?.status;
    if (status == RoomStatus.starting) return true;
    if (status == RoomStatus.inGame || status == RoomStatus.paused) {
      // A non-owner who arrived mid-game and hasn't been approved yet is
      // deliberately NOT "entering the game" — they need to see the
      // ordinary lobby (with its rejoin-approval banner), not a locked
      // loading screen with no way to request access.
      if (!room.isOwner && room.arrivedMidGame) return false;
      return true;
    }
    return false;
  }

  /// Explicit, EXPLICITLY-DERIVED (never a stored field of its own) game-
  /// start phase — names the three states this screen can render for the
  /// start sequence, computed fresh from the two signals that must never
  /// disagree:
  ///   - [_showPreparingLock]: this client's own "start accepted" intent —
  ///     true from the moment Start is genuinely committed (after ToD
  ///     settings confirm, if applicable) until a genuine failure/cancel or
  ///     the game route has been pushed and popped back here.
  ///   - room.status, via [_isEnteringOrInGame]: the AUTHORITATIVE signal,
  ///     once this client's local RoomProvider has adopted it (broadcast
  ///     self-echo or the reconcile poll).
  /// [enteringGame] always wins over [preparing] when both are true — once
  /// status itself confirms the transition there is nothing left to wait
  /// on locally. See build() for exactly how each phase renders; the ToD
  /// settings sheet itself is a modal shown OVER [lobby], not a separate
  /// render phase here.
  _GameStartPhase _gameStartPhase(RoomProvider room) {
    if (room.isInitialized && _isEnteringOrInGame(room)) {
      return _GameStartPhase.enteringGame;
    }
    if (_showPreparingLock) return _GameStartPhase.preparing;
    return _GameStartPhase.lobby;
  }

  /// The single, sole decision point for "should this client be inside the
  /// game route right now" — and, if so, the only place that ever calls
  /// _pushGameRoute. Every trigger that could plausibly mean "the game
  /// route should now be active" — RoomProvider's own listener (a fresh
  /// start, a reconnect, another client's poll correcting a stale read),
  /// "Continue Game", the Rejoin banner — calls this SAME method instead
  /// of independently deciding to navigate and building its own extras.
  /// No other code in this file constructs the game route's extras or
  /// calls AppRouter.router.push for it.
  void _syncGameRoute() {
    if (!mounted || _navigatedToGame) return;
    final room = _provider;
    final r = room.room;
    // Every skip/push decision this method makes is logged with the exact
    // reason — this is the ONE place any of this app's game-route
    // navigation happens, so this log is sufficient to reconstruct why a
    // given client did or didn't enter a game, without guessing.
    void logDecision(String decision, {String? reason}) {
      AppLogger.info(
        'NAV_DECISION room=${r?.id} status=${r?.status} '
        'gameType=${r?.gameType} isOwner=${room.isOwner} '
        'currentMemberPresent=${room.currentMember != null} '
        'arrivedMidGame=${room.arrivedMidGame} '
        'isInitialized=${room.isInitialized} decision=$decision'
        '${reason != null ? ' reason=$reason' : ''}',
      );
    }

    if (r == null || !room.isInitialized || !_isEnteringOrInGame(room)) {
      logDecision('skip', reason: 'no_game_in_progress_or_not_initialized');
      return;
    }

    // 'starting' only ever authorizes a push for the OWNER — they're the
    // one who has to actually reach the game screen to run
    // create_game_session in the first place. A non-owner must never
    // navigate off 'starting' alone; they stay on the locked
    // "Preparing the game..." screen (see build(), driven by the same
    // _isEnteringOrInGame check above) until this room's status reaches
    // 'in_game', which only happens once the owner's own
    // create_game_session call has genuinely succeeded (see
    // RoomProvider._handleGameSessionReady) — by which point the session
    // row is guaranteed to exist, closing the race that previously let a
    // player's game screen mount, find no session yet, and bounce back to
    // the lobby. 'paused' needs no such restriction — it's still a game
    // in progress for everyone already dealt into it (the game screen
    // itself renders the "waiting for host" overlay, gated on
    // RoomProvider.isPausedForHostReconnect), so a player whose own
    // reconnect happens to land mid-pause is still carried straight in.
    if (r.status == RoomStatus.starting && !room.isOwner) {
      logDecision('skip', reason: 'non_owner_awaiting_session_ready');
      return;
    }
    final gameTypeEnum = r.gameType;
    if (gameTypeEnum == null) {
      logDecision('skip', reason: 'gameType_not_yet_known');
      return;
    }

    // room.isInitialized alone does NOT prove the current user actually
    // holds a confirmed room_members row — RoomProvider.initialize()'s
    // joinRoom() upsert can fail (RLS correctly rejecting a brand-new,
    // non-approved join into an in_game/paused room) while initialize()
    // still runs to completion and sets isInitialized=true regardless
    // (the failure is only logged, never surfaced). Without this check, a
    // never-approved stranger — or a spectator when spectator approval is
    // off — could get auto-navigated straight into the live game,
    // bypassing the entire approval flow client-side even though they
    // were never actually admitted server-side.
    if (!room.isOwner && room.currentMember == null) {
      logDecision('skip', reason: 'not_a_confirmed_room_member');
      return;
    }

    // Hard requirement: a non-owner who connected while the game was
    // already running must never be auto-navigated in, regardless of
    // whether their room_members row happens to still be intact (a weak
    // disconnect presence never caught, a brief background) — only an
    // explicit admin/mod approval (which clears this flag — see
    // RoomProvider.clearArrivedMidGame, called by _RejoinBanner) may let
    // them through. A player who was already in the lobby when Start Game
    // fired never has this flag set at all, so this never blocks the
    // normal "everyone starts together" path.
    if (!room.isOwner && room.arrivedMidGame) {
      logDecision('skip', reason: 'arrived_mid_game_awaiting_approval');
      return;
    }

    if (room.isOwner && (r.packId == null || r.packId!.isEmpty)) {
      // Room flipped to in-game before its pack_id was populated locally
      // (reconnect/race) — retry on the next notify instead of pushing the
      // game screen with an empty packId, which crashes deep in
      // initAsOwner with a cryptic Postgres "invalid input syntax for
      // type uuid" error.
      logDecision('skip', reason: 'owner_packId_not_yet_populated');
      return;
    }

    logDecision('push');
    _navigatedToGame = true;
    final gameType = gameTypeEnum.toDbString();
    final isNewGameStart = _pendingFreshStart;
    _pendingFreshStart = false;

    // Navigator operations must not run mid-notify (this can be called
    // from directly inside RoomProvider.notifyListeners()) — deferred to
    // the next frame, same as every other post-build navigation in this
    // screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _navigatedToGame = false;
        return;
      }
      final displayNames = {
        for (final m in room.members) m.userId: m.displayName,
      };
      PackEntity? pack;
      try {
        pack = context
            .read<PackProvider>()
            .allPacks
            .where((p) => p.id == (r.packId ?? ''))
            .firstOrNull;
      } catch (_) {}

      _pushGameRoute(
        '${RouteNames.home}/room/${r.id}/game',
        {
          'config': GameConfig(
            maxRounds: room.settings.maxRounds,
            turnTimerSeconds: room.settings.turnTimerSeconds,
            allowSkip: room.settings.allowSkip,
            allowSpicy: r.allowSpicy,
            enablePunishments: room.settings.enablePunishments,
            punishmentSource: room.settings.punishmentSource,
            suggestedPunishments: pack?.suggestedPunishments,
            proofVisibilityPolicy: room.settings.proofVisibilityPolicy,
            proofViewSeconds: room.settings.proofViewSeconds,
            proofReplayMode: room.settings.proofReplayMode,
            // Item 18.2 root-cause fix: this reactive navigation path is
            // what actually pushes EVERY client (owner's own first
            // navigation included) into the game screen — it previously
            // omitted these two entirely, so TruthOrDareEngine was always
            // constructed with GameConfig's forceDareMode='unlimited'
            // default no matter what the host chose in the pre-game
            // sheet. Now durable in room.settings (see
            // migration_2026_tod_force_dare_persistence.sql) instead of
            // only living in the one-shot game_started broadcast payload
            // RoomProvider._handleGameStarted already discarded.
            forceDareMode: room.settings.forceDareMode,
            maxTruths: room.settings.maxTruths,
            packId: r.packId,
            language: r.language,
          ),
          'playerIds': room.members
              .where((m) => !m.isSpectator)
              .map((m) => m.userId)
              .toList(),
          'displayNames': displayNames,
          'packId': r.packId ?? '',
          'packCoverUrl': pack?.coverImageUrl ?? '',
          'isOwner': room.isOwner,
          'isModerator': room.isOwner
              ? false
              : (room.currentMember?.isModerator ?? false),
          'isSpectator': room.isOwner
              ? false
              : (room.currentMember?.isSpectator ?? false),
          'gameType': gameType,
          'isNewGameStart': isNewGameStart,
          'roomProvider': room,
        },
      );
    });
  }

  /// The only place that ever actually pushes the game route — called
  /// exclusively from _syncGameRoute above. Clears the guard automatically
  /// the moment the pushed route is popped (quit, kick, ban, game end,
  /// back button — go_router's push() resolves its Future exactly then),
  /// rather than inferring "no game route is active" from room status
  /// elsewhere. That inference (previously: reset the flag whenever
  /// status read 'waiting') was the actual root cause of "two game
  /// instances" — an out-of-order/stale poll response could momentarily
  /// regress _room.status to 'waiting' while a game route was still
  /// genuinely on the stack, resetting the guard and letting the very
  /// next correct status read push a second game route on top of the
  /// first, still-live one.
  Future<void> _pushGameRoute(String path, Map<String, dynamic> extra) async {
    try {
      await AppRouter.router.push(path, extra: extra);
    } finally {
      if (mounted) {
        _navigatedToGame = false;
        // The game route just popped back to THIS lobby — the one place
        // _showPreparingLock is reset now that it's no longer cleared just
        // because _doStartGame returned (see that flag's doc comment).
        // Without this, a lock left up from THIS start (or, defensively,
        // any prior one) would incorrectly keep shadowing a genuinely
        // fresh, interactive lobby visit after the game ends.
        setState(() => _showPreparingLock = false);
        // CENTRALIZED game-end lifecycle: the game route just popped back to
        // THIS lobby, which (given the game route is pushed over the lobby and
        // only ever pops to it on a genuine game end — every other exit goes
        // Home) means the game this client was in has ended for them. Route
        // ALL exit reasons — natural completion, host force-end, auto-end, the
        // game_ended broadcast/dialog, results "Leave", session-ended
        // auto-leave — through this one hook so RoomProvider transitions to the
        // lobby immediately (no _GameStartingLock "Preparing…" flash) and the
        // reconcile poll won't re-adopt the stale, owner-gated in_game status.
        // Idempotent; the per-game screens no longer need to do this.
        _provider.onReturnedFromGameRoute();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<RoomProvider>(
        builder: (ctx, room, _) => _build(ctx, room),
      ),
    );
  }

  Widget _build(BuildContext ctx, RoomProvider room) {
    if (room.connectionState == RoomConnectionState.failed &&
        !room.isInitialized) {
      final errorMsg = room.failure?.message ?? context.l10n.errorConnectionFailed;
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: errorMsg,
          onRetry: () => _provider.initialize(widget.roomId),
        ),
      );
    }

    if (room.connectionState == RoomConnectionState.pendingApproval) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.lobbyJoinRequestSentTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top_rounded, size: 56),
                const SizedBox(height: 16),
                Text(
                  context.l10n.lobbyWaitingForHostApproval,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.lobbyAutoLetInOnceApproved,
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => ctx.go(RouteNames.home),
                  child: Text(context.l10n.backToHome),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // OWNERSHIP-LOADING STATE: until initialize() completes, _room (and so
    // isOwner) is not yet resolved — isOwner defaults to false. Rendering
    // the normal lobby here would show the player "Leave" button and let a
    // back press run _leaveRoom AS A NORMAL PLAYER, which for the actual
    // owner is the "admin accidentally leaves their own room via back
    // during load" race. Show a neutral loading state whose back simply
    // returns Home WITHOUT any leave-room mutation (the room stays intact
    // in the DB, owner still owns it). Once isInitialized is true, isOwner
    // is authoritative and the real PopScope below — which branches on
    // isOwner into Close Room vs Leave — takes over. Reconnects keep
    // isInitialized=true, so this never displaces an already-open lobby.
    if (!room.isInitialized) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (mounted) ctx.go(RouteNames.home);
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => ctx.go(RouteNames.home),
            ),
            title: Text(context.l10n.lobbyTitle),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // MID-GAME RETURN → WAITING FOR ACCEPTANCE: a non-owner who reconnected
    // into an already-running game has NOT been let back in yet (their
    // rejoin request was auto-filed in RoomProvider.initialize). Show a
    // dedicated full-screen "waiting for admin acceptance" state instead of
    // dropping them into the interactive lobby — the admin accepts/rejects
    // via the existing _RejoinRequestsPanel + decide_game_rejoin_request.
    // _RejoinWaitingView owns the approval poll: on approval it clears
    // arrivedMidGame and re-runs _syncGameRoute (which then enters the game,
    // now that _isEnteringOrInGame stops returning false for this client).
    // Placed before the _GameStartingLock check below — an unapproved
    // returning player must never see the game-loading lock.
    if (!room.isOwner && room.arrivedMidGame) {
      return _RejoinWaitingView(room: room, onApproved: _syncGameRoute);
    }

    // STARTING_GAME lock / entering-game placeholder: shown to EVERY
    // client — owner included — for the entire window between "the room
    // is starting or transitioning into a game" and "the real game route
    // has actually been pushed on top of this screen". See
    // _isEnteringOrInGame's doc comment for exactly why this must be a
    // superset of _syncGameRoute's own push condition: this is what
    // closes the "lobby flashes underneath the loading screen" bug — the
    // OLD condition here (starting-only, non-owner-only) stopped matching
    // one frame before _syncGameRoute's deferred push actually ran
    // whenever status flipped straight to 'in_game' (the owner's own
    // client never even passed through this branch at all), so the full
    // interactive lobby was what the push-transition animation captured
    // as the outgoing screen. Now this stays true continuously from
    // 'starting' through the push, for both roles, so there is nothing
    // but this placeholder to ever flash.
    // Driven by room STATUS only — NOT by isStartingGame. Returning this
    // full-screen lock REPLACES the interactive lobby, which UNMOUNTS the
    // _BottomActionBar whose BuildContext the in-flight _doStartGame is still
    // using (pack checks, the ToD pre-game sheet, snackbars). Gating this on
    // isStartingGame therefore killed that context the instant Start was
    // tapped, so _doStartGame hit `if (!ctx.mounted) return;` right after the
    // pack-check round-trip and aborted BEFORE broadcasting game_started /
    // flipping the room status — the "Preparing… ~1s → back to lobby, no game
    // starts" regression, for every game. The immediate Start-tapped feedback
    // is instead the button's own disabled state (see _BottomActionBar, gated
    // on isStartingGame with the bar kept mounted); this placeholder still
    // appears the moment the room reaches 'starting'/'in_game', by which point
    // _doStartGame is past every context-dependent step.
    if (_gameStartPhase(room) == _GameStartPhase.enteringGame) {
      return const _GameStartingLock();
    }

    final gameIsActive =
        room.room?.gameType != null && (room.room?.status == RoomStatus.inGame);
    if (gameIsActive &&
        !room.isOwner &&
        _sessionPlayerIds == null &&
        !_fetchingSessionPlayerIds) {
      _fetchingSessionPlayerIds = true;
      sl.roomRepository
          .getActiveSessionPlayerIds(widget.roomId)
          .then((ids) {
            if (!mounted) return;
            setState(() {
              _sessionPlayerIds = ids;
              _fetchingSessionPlayerIds = false;
            });
          })
          .catchError((_) {
            if (!mounted) return;
            setState(() => _fetchingSessionPlayerIds = false);
          });
    }
    if (!gameIsActive && _sessionPlayerIds != null) {
      _sessionPlayerIds = null;
    }

    final lobby = PopScope(
      // canPop:false so EVERY back path — Android back, iOS edge-swipe (this
      // also disables the swipe-to-pop gesture itself), Navigator/go_router
      // pop, and the AppBar back (which routes through onLeave: _leaveRoom) —
      // funnels into the SAME confirmation flow (_leaveRoom shows the
      // owner-close / player-leave dialog). Using onPopInvokedWithResult (the
      // non-deprecated predictive-back API) keeps this correct on Android 14+.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _leaveRoom();
        });
      },
      child: ScreenTutorial(
        tutorialId: TutorialIds.roomLobbyIntro,
        steps: _lobbyTutorialSteps(room),
        enabled: room.isInitialized && room.isConnected,
        child: Scaffold(
        appBar: _LobbyAppBar(
          room: room,
          tabs: _tabs,
          onLeave: _leaveRoom,
          onCloseRoom: _closeRoom,
          onReopenRoom: _reopenRoom,
          manageShowcaseKey: _lobbyManageKey,
        ),
        body: Column(
          children: [
            if (room.connectionState != RoomConnectionState.connected &&
                room.connectionState != RoomConnectionState.connecting)
              _ConnectionBanner(
                state: room.connectionState,
                onRetry: room.retryConnection,
              ),
            if ((room.room?.status == RoomStatus.inGame ||
                    room.room?.status == RoomStatus.paused) &&
                room.room?.gameType != null)
              // "Rejoin" is a manual nudge for the exact same check
              // _syncGameRoute already runs reactively — not a second,
              // independent decision to navigate, and not a second builder
              // of the game route's extras. See _syncGameRoute's doc
              // comment for why nothing else is allowed to be either.
              _RejoinBanner(room: room, onRejoin: _syncGameRoute),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _LobbyTab(room: room),
                  ChatPanel(room: room),
                ],
              ),
            ),
            _BottomActionBar(
              room: room,
              startShowcaseKey: _lobbyStartKey,
              readyShowcaseKey: _lobbyReadyKey,
              wasInActiveSession:
                  _sessionPlayerIds == null ||
                  _sessionPlayerIds!.contains(
                    context.read<AuthProvider>().currentUser?.id,
                  ),
              onLeave: _leaveRoom,
              markFreshStart: () => _pendingFreshStart = true,
              syncGameRoute: _syncGameRoute,
              setPreparingLock: _setPreparingLock,
              // "Continue Game" is just a manual nudge for the exact same
              // check _syncGameRoute already runs reactively — not a
              // second, independent decision to navigate. Its own guard
              // (_navigatedToGame) makes this a no-op if a route is
              // already active/in-flight.
              onContinueGame: _syncGameRoute,
            ),
          ],
        ),
        ),
      ),
    );

    // Immediate, whole-lobby INPUT lock the instant Start Game is tapped —
    // overlaid ON TOP of (not replacing) the interactive lobby via
    // AbsorbPointer, so the still-mounted _BottomActionBar's BuildContext
    // (which the in-flight _doStartGame keeps using for pack checks, the
    // ToD pre-game sheet, snackbars) is never unmounted.
    //
    // The Stack is returned UNCONDITIONALLY — never `return lobby;` in one
    // branch and `return Stack(...)` in another — because that was a past
    // regression: switching the ROOT widget type _build returns (PopScope
    // vs Stack) on the very rebuild `setStartingGame(true)` triggers makes
    // Flutter's element diffing treat it as a completely different tree at
    // that position, unmounting and remounting everything below it —
    // including _BottomActionBar — one frame after Start was tapped. Only
    // `absorbing` and whether `_GameStartingLock` is present ever change;
    // the tree shape itself never does, so `lobby` (and everything inside
    // it) stays mounted continuously through the whole start sequence,
    // including the ToD sheet — which, as a showModalBottomSheet, is
    // pushed onto the route's own Overlay and therefore already renders
    // above this Stack regardless of the lock's own visibility.
    //
    // absorbing uses room.isStartingGame (input-blocking must be instant
    // for every game, so double-tap/other-lobby-actions are impossible the
    // moment Start is tapped) while the VISIBLE lock uses _gameStartPhase
    // == preparing (Truth or Dare must show its settings sheet BEFORE that
    // ever becomes true — see _BottomActionBar._doStartGame's single
    // setPreparingLock(true) call site). For every other game those two
    // become true at effectively the same moment, so nothing changes there.
    // (enteringGame is handled by the earlier, full-replacement branch
    // above and never reaches here.)
    return Stack(
      children: [
        AbsorbPointer(absorbing: room.isStartingGame, child: lobby),
        if (_gameStartPhase(room) == _GameStartPhase.preparing)
          const _GameStartingLock(),
      ],
    );
  }

  Future<void> _leaveRoom() async {
    if (!mounted) return;
    final isOwner = _provider.isOwner;

    // Batch D: the owner of an ALREADY keep-game-closed room leaving the lobby
    // must NOT tear the room down — its game is still live for active
    // participants, and the owner must be able to come back to re-enter/reopen
    // it (that's the whole point of a keep-game close). Just exit to Home,
    // keeping the room closed-but-alive and ownership intact. The destructive
    // owner-close path below is only for an OPEN room. (Non-owners are handled
    // by the normal leave path regardless of closed state.)
    if (isOwner && _provider.isRoomClosed) {
      _isLeavingRoom = true;
      context.go(RouteNames.home);
      return;
    }

    if (isOwner) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dCtx) => AlertDialog(
          title: Text(context.l10n.lobbyCloseRoomTitle),
          content: Text(context.l10n.lobbyCloseRoomBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dCtx).pop(true),
              child: Text(context.l10n.lobbyCloseRoomConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      // RoomProvider.leaveRoom() is the single authoritative owner-leave
      // action — it broadcasts 'owner_left' itself (now reliably fanned out
      // to every subscriber, including any active game screen, by
      // RealtimeService). No need to pre-broadcast here too.
      await _provider.leaveRoom(permanent: true);
      if (mounted) {
        // Share the terminal-navigation latch so a kicked/removed/closed
        // lifecycle event racing this manual leave can't also navigate.
        _isLeavingRoom = true;
        context.go(RouteNames.home);
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dCtx) => AlertDialog(
          title: Text(context.l10n.lobbyLeaveRoomTitle),
          content: Text(context.l10n.lobbyLeaveConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dCtx).pop(true),
              child: Text(context.l10n.leave),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      final myId = context.read<AuthProvider>().currentUser?.id ?? '';
      final displayName =
          context.read<AuthProvider>().currentUser?.displayName ?? context.l10n.defaultPlayerName;
      try {
        await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
          'type': 'player_left',
          'user_id': myId,
          'display_name': displayName,
          'for_good': true,
        });
        await sl.roomRepository.setMemberDefinitiveLeave(widget.roomId, myId);
      } catch (_) {}
      if (mounted) {
        // Share the terminal-navigation latch so a kicked/removed/closed
        // lifecycle event racing this manual leave can't also navigate.
        _isLeavingRoom = true;
        context.go(RouteNames.home);
      }
    }
  }

  /// Batch D keep-game close (owner-only). Completely distinct from
  /// [_leaveRoom]'s destructive owner-leave teardown: this keeps the live
  /// game running and the owner in the room, only marking it closed to new
  /// entrants. Guarded by canCloseRoom (owner + >1 relevant member); the RPC
  /// re-checks server-side and its typed failure is surfaced on error.
  Future<void> _closeRoom() async {
    if (!mounted || !_provider.canCloseRoom) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(context.l10n.lobbyCloseKeepGameTitle),
        content: Text(context.l10n.lobbyCloseKeepGameBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: Text(context.l10n.lobbyCloseKeepGameConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _provider.closeRoomKeepGame();
      if (mounted) {
        _showEventBanner(context.l10n.lobbyRoomClosedForNewPlayers);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          e is Failure ? e.message : e.toString(),
        );
      }
    }
  }

  /// Batch D reopen (owner-only): reverses a keep-game close. Server-checked.
  Future<void> _reopenRoom() async {
    if (!mounted || !_provider.canReopenRoom) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(context.l10n.lobbyReopenTitle),
        content: Text(context.l10n.lobbyReopenBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: Text(context.l10n.lobbyReopenConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _provider.reopenRoom();
      if (mounted) {
        _showEventBanner(context.l10n.lobbyRoomReopened);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e is Failure ? e.message : e.toString());
      }
    }
  }
}

class _LobbyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _LobbyAppBar({
    required this.room,
    required this.tabs,
    required this.onLeave,
    required this.onCloseRoom,
    required this.onReopenRoom,
    this.manageShowcaseKey,
  });

  final RoomProvider room;
  final TabController tabs;
  final VoidCallback onLeave;
  final VoidCallback onCloseRoom;
  final VoidCallback onReopenRoom;
  /// Tutorial highlight target for the owner-only Close/Reopen control.
  final GlobalKey? manageShowcaseKey;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final r = room.room;
    final l10n = context.l10n;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: onLeave,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r?.name ?? l10n.lobbyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          _ConnectionIndicator(state: room.connectionState),
        ],
      ),
      actions: [
        if (r?.inviteCode != null && room.isOwner)
          _InviteCodeChip(code: r!.inviteCode!),

        // Batch D: owner-only Close/Reopen. Distinct lock icon (never the
        // back/Leave control). When open it closes (disabled if the owner is
        // the only relevant member); when already closed it reopens. The
        // server re-checks both rules.
        if (room.isOwner)
          Builder(
            builder: (context) {
              final button = IconButton(
                tooltip: (r?.isClosed ?? false)
                    ? l10n.lobbyReopenCta
                    : l10n.lobbyCloseKeepGameCta,
                icon: Icon(
                  (r?.isClosed ?? false)
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                  size: 20,
                  color: Colors.white70,
                ),
                onPressed: (r?.isClosed ?? false)
                    ? (room.canReopenRoom ? onReopenRoom : null)
                    : (room.canCloseRoom ? onCloseRoom : null),
              );
              final k = manageShowcaseKey;
              if (k == null) return button;
              return tutorialShowcase(
                context: context,
                showcaseKey: k,
                title: context.l10n.tutLobbyManageTitle,
                description: context.l10n.tutLobbyManageBody,
                child: button,
              );
            },
          ),

        Consumer<RoomProvider>(
          builder: (ctx, rp, __) {
            // Viewer-scoped: a normal player gets ONLY visible spectators; a
            // moderator additionally gets hidden ones as real (kickable)
            // entries. Identity of hidden entries is unmasked only for a
            // Premium Plus moderator (canRevealHidden).
            final specs = rp.visibleSpectators;
            if (specs.isEmpty) return const SizedBox.shrink();
            final canRevealHidden = rp.canRevealHiddenSpectator(
              viewerIsPremiumPlus:
                  ctx.read<AuthProvider>().currentUser?.isPremiumPlusActive ??
                  false,
            );
            return TextButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => _SpectatorsSheet(
                  spectators: specs,
                  room: rp,
                  canRevealHidden: canRevealHidden,
                ),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: Text('${specs.length}'),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            );
          },
        ),

        if (room.canApproveSpectators &&
            (room.room?.status == RoomStatus.inGame || false))
          FutureBuilder<List<Map<String, dynamic>>>(
            future: room.fetchPendingSpectatorRequests(),
            builder: (ctx, snap) {
              final requests = snap.data ?? [];
              if (requests.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: context.l10n.lobbySpectatorRequestCount(requests.length),
                icon: Badge(
                  label: Text('\${requests.length}'),
                  child: const Icon(
                    Icons.person_add_outlined,
                    size: 20,
                    color: Colors.white70,
                  ),
                ),
                onPressed: () => showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  builder: (_) =>
                      _SpectatorRequestsSheet(requests: requests, room: room),
                ),
              );
            },
          ),
        const SizedBox(width: 4),
      ],
      bottom: TabBar(
        controller: tabs,
        tabs: [
          Tab(text: l10n.lobbyTitle),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.chatTabLabel),
                if (!context.watch<RoomProvider>().settings.chatEnabled)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.voice_over_off_rounded, size: 14),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.state});
  final RoomConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      RoomConnectionState.connected => (context.l10n.roomsConnLive, AppColors.successGreen),
      RoomConnectionState.reconnecting => (
        context.l10n.roomsConnReconnecting,
        AppColors.warningAmber,
      ),
      RoomConnectionState.recovering => (context.l10n.roomsConnSyncing, AppColors.infoBlue),
      RoomConnectionState.failed => (context.l10n.roomsConnDisconnected, AppColors.errorRed),
      _ => (context.l10n.roomsConnConnecting, AppColors.textTertiaryLight),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InviteCodeChip extends StatelessWidget {
  const _InviteCodeChip({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        context.showSnackBar(context.l10n.lobbyCopied);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: context.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.copy_rounded,
              size: 12,
              color: context.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              code,
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen lock shown to non-owners while `rooms.status == starting`.
/// Deliberately offers ZERO interactive controls and a no-op [PopScope] —
/// see the call site in `_LobbyScreenState.build()` for why: a player must
/// not be able to leave, go back, or touch any lobby action from the moment
/// the owner presses Start Game until the room reaches `in_game`.
class _GameStartingLock extends StatelessWidget {
  const _GameStartingLock();

  @override
  Widget build(BuildContext context) {
    // UI redesign only — the no-op PopScope (full-screen lock, no leave / no
    // back) semantics are unchanged.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: BrandedStatusView(
        emoji: '🎮',
        title: context.l10n.lobbyGameStarting,
        subtitle: context.l10n.lobbyGameStartingBody,
        accent: AppColors.brandPurpleMid,
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.state, required this.onRetry});
  final RoomConnectionState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isFailed = state == RoomConnectionState.failed;
    final color = isFailed ? AppColors.errorRed : AppColors.warningAmber;
    final message = isFailed
        ? context.l10n.gameConnectionLost
        : context.l10n.gameReconnecting;

    return Container(
      width: double.infinity,
      color: color.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (!isFailed)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
            )
          else
            Icon(Icons.wifi_off_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
          if (isFailed)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: color,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(context.l10n.gameTryAgain),
            ),
        ],
      ),
    );
  }
}

class _LobbyTab extends StatelessWidget {
  const _LobbyTab({required this.room});
  final RoomProvider room;

  @override
  Widget build(BuildContext context) {
    // Canonical viewer-scoped list: moderators see everyone, normal players
    // never see hidden spectators (see RoomProvider.visibleMembers). The
    // hidden-spectator visibility rules are preserved — we only split this
    // already-filtered list into its two sections below.
    final members = room.visibleMembers;
    // Split into Players and Spectators — never one merged list. Both derive
    // from the same viewer-scoped `members`, so hidden spectators a viewer
    // isn't allowed to see are already absent from `spectators` too.
    final players = members.where((m) => !m.isSpectator).toList();
    final spectators = members.where((m) => m.isSpectator).toList();
    // Players count must exclude spectators (visible or hidden).
    final playerCount = room.members.where((m) => !m.isSpectator).length;
    final theme = context.theme;

    if (members.isEmpty &&
        room.connectionState == RoomConnectionState.connecting) {
      return const Center(child: CircularProgressIndicator());
    }

    final myId = context.read<AuthProvider>().currentUser?.id ?? '';
    // Transferring ownership requires Premium — the server RPC is the real
    // enforcement, this just avoids showing an option that would always be
    // rejected.
    final iAmPremiumForTransfer =
        context.read<AuthProvider>().currentUser?.isPremiumActive ?? false;

    // One tile builder shared by both sections so Players and Spectators
    // render identically (same moderation actions, animation, etc.).
    Widget memberTile(RoomMemberEntity member, int index) {
      return Column(
        children: [
          GestureDetector(
            onTap: member.userId != myId
                ? () => _showMemberPopup(context, member, myId)
                : null,
            child: MemberTile(
              member: member,
              isCurrentUser: member.userId == myId,
              canModerate: room.canModerate(member.userId),
              isWaitingForGameApproval: room.pendingRejoinUserIds.contains(
                member.userId,
              ),
              onKick:
                  room.canKickPlayers &&
                      member.userId != myId &&
                      !member.isOwner
                  ? () => _kickConfirm(context, room, member)
                  : null,
              onMute: room.canMuteChat && member.userId != myId
                  ? () => _toggleMute(
                      context,
                      room,
                      member.userId,
                      muted: !member.isMuted,
                    )
                  : null,
              onBan: room.isOwner && member.userId != myId && !member.isOwner
                  ? () => _banConfirm(context, room, member)
                  : null,
              onTransferOwnership:
                  room.canTransferOwnership &&
                      iAmPremiumForTransfer &&
                      !member.isSpectator
                  ? () => _transferConfirm(context, room, member)
                  : null,
              onManagePermissions: room.isOwner
                  ? () => _showPermissionsSheet(context, room, member)
                  : null,
            ).animate(delay: (index * 40).ms).fadeIn(),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(
              context.l10n.roomsPlayers(playerCount, room.room?.maxPlayers ?? 6),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (room.isOwner)
              Text(
                context.l10n.lobbyYouAreHost,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.ownerBadge,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (room.canAcceptJoins)
          JoinRequestsPanel(
            roomId: room.room!.id,
            showAlways: room.settings.requiresApproval,
            inGame: room.room?.status == RoomStatus.inGame,
          ),

        if (room.canAcceptJoins) const SizedBox(height: 4),

        if (room.canAcceptRejoins &&
            (room.room?.status == RoomStatus.inGame ||
                room.room?.status == RoomStatus.paused))
          _RejoinRequestsPanel(roomId: room.room!.id),

        // ── Players section ──────────────────────────────────────────────
        ...players.asMap().entries.map((e) => memberTile(e.value, e.key)),

        // ── Spectators section (only when there are any visible to this
        // viewer — hidden ones a normal player can't see are already gone) ──
        if (spectators.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            context.l10n.lobbySpectatorsSection,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...spectators
              .asMap()
              .entries
              .map((e) => memberTile(e.value, players.length + e.key)),
        ],
      ],
    );
  }

  void _showMemberPopup(
    BuildContext ctx,
    RoomMemberEntity member,
    String myId,
  ) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                child: Text(member.displayName[0].toUpperCase()),
              ),
              title: Text(
                member.displayName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(member.isSpectator ? '👁 Spectator' : '🎮 Player'),
            ),
            const Divider(),
            _FriendRequestButton(
              targetUserId: member.userId,
              displayName: member.displayName,
              myId: myId,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _kickConfirm(
    BuildContext ctx,
    RoomProvider room,
    RoomMemberEntity m,
  ) async {
    final confirmed = await showConfirmDialog(
      context: ctx,
      title: ctx.l10n.moderationKick,
      message: ctx.l10n.moderationKickConfirm(m.displayName),
      confirmLabel: ctx.l10n.moderationKick,
      isDestructive: true,
    );
    if (confirmed == true) await room.kickPlayer(m.userId);
  }

  /// Was previously a fire-and-forget `() => room.mutePlayer(...)` inside a
  /// synchronous onTap — if the RPC threw (permission revoked mid-session,
  /// network drop, etc.) the moderator got no feedback at all; the button
  /// just appeared to silently do nothing, indistinguishable from mute
  /// "not working". Mirrors _transferConfirm's error handling.
  Future<void> _toggleMute(
    BuildContext ctx,
    RoomProvider room,
    String targetUserId, {
    required bool muted,
  }) async {
    try {
      await room.mutePlayer(targetUserId, muted: muted);
    } on Failure catch (e) {
      if (ctx.mounted) ctx.showErrorSnackBar(e.message);
    }
  }

  Future<void> _banConfirm(
    BuildContext ctx,
    RoomProvider room,
    RoomMemberEntity m,
  ) async {
    await showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: room,
        child: BanConfirmSheet(targetMember: m),
      ),
    );
  }

  Future<void> _transferConfirm(
    BuildContext ctx,
    RoomProvider room,
    RoomMemberEntity m,
  ) async {
    final confirmed = await showConfirmDialog(
      context: ctx,
      title: ctx.l10n.roomsTransferOwnership,
      message: ctx.l10n.roomsTransferOwnershipConfirm(m.displayName),
    );
    if (confirmed != true) return;
    try {
      await room.transferOwnership(m.userId);
    } on Failure catch (e) {
      if (ctx.mounted) ctx.showErrorSnackBar(e.message);
    }
  }

  Future<void> _showPermissionsSheet(
    BuildContext ctx,
    RoomProvider room,
    RoomMemberEntity m,
  ) async {
    var selected = Set<String>.from(m.moderatorPermissions);
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheetCtx.l10n.lobbyPermissionsFor(m.displayName),
                style: Theme.of(
                  sheetCtx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                sheetCtx.l10n.lobbyPermissionsHint,
                style: Theme.of(sheetCtx).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final key in ModeratorPermission.all)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_permissionLabel(sheetCtx, key)),
                  value: selected.contains(key),
                  onChanged: (v) => setSheetState(() {
                    if (v ?? false) {
                      selected.add(key);
                    } else {
                      selected.remove(key);
                    }
                  }),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.pop(sheetCtx);
                    await room.updateModeratorPermissions(m.userId, selected);
                  },
                  child: Text(sheetCtx.l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps [child] in a themed tutorial highlight when [key] is provided,
/// otherwise returns it unchanged — so a role that shouldn't be taught a given
/// control simply passes a null key and no highlight is attached.
Widget _maybeShowcase(
  BuildContext context,
  GlobalKey? key,
  String title,
  String description,
  Widget child,
) {
  if (key == null) return child;
  return tutorialShowcase(
    context: context,
    showcaseKey: key,
    title: title,
    description: description,
    child: child,
  );
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.room,
    required this.onLeave,
    required this.onContinueGame,
    required this.markFreshStart,
    required this.syncGameRoute,
    required this.setPreparingLock,
    required this.wasInActiveSession,
    this.startShowcaseKey,
    this.readyShowcaseKey,
  });
  final RoomProvider room;
  /// Tutorial targets: the host's Start Game button and the player's Ready
  /// toggle. Only the one actually rendered for the current role is ever
  /// highlighted (see _LobbyScreenState._lobbyTutorialSteps).
  final GlobalKey? startShowcaseKey;
  final GlobalKey? readyShowcaseKey;
  final VoidCallback onLeave;
  final VoidCallback onContinueGame;
  // _LobbyScreenState._pendingFreshStart's setter and _syncGameRoute — the
  // single authoritative decision point for "should the game route be
  // active right now". _BottomActionBar is a separate (Stateless) widget,
  // so it can't reach those private members directly; threaded down like
  // onLeave/onContinueGame already are. Start Game itself never pushes —
  // it marks the fresh-start intent and lets the same reactive path every
  // other entry into the game goes through pick it up.
  final VoidCallback markFreshStart;
  final VoidCallback syncGameRoute;
  // Reveals/hides ONLY the full-screen "Preparing Game" overlay — see
  // _LobbyScreenState._showPreparingLock's doc comment. Distinct from
  // room.isStartingGame, which still gates this button's own disabled
  // state below immediately, for every game type.
  final ValueChanged<bool> setPreparingLock;
  final bool wasInActiveSession;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isReady = room.currentMember?.isReady ?? false;
    final hasPack = room.room?.packId?.isNotEmpty == true;
    final r = room.room;
    final nonOwners = room.members.where((m) => !m.isOwner).toList();
    final activePlayers = room.members.where((m) => !m.isSpectator).toList();
    final hasEnough = activePlayers.length >= 1;
    final allReady =
        nonOwners.where((m) => !m.isSpectator).isEmpty ||
        nonOwners.where((m) => !m.isSpectator).every((m) => m.isReady);

    // Same in-memory pack cache lookup _onStartGame uses — the pack must
    // already be cached since the owner selected it moments earlier via
    // the pack list in game_settings_sheet.dart.
    final selectedPack = hasPack
        ? context.watch<PackProvider>().allPacks
              .where((p) => p.id == r?.packId)
              .firstOrNull
        : null;
    final eligibleCount = room.eligiblePlayers.length;
    final notEnoughPlayers =
        selectedPack != null && eligibleCount < selectedPack.minPlayers;
    final hasReconnecting = room.members.any(
      (m) => m.isDisconnected && !m.leftDefinitively,
    );

    String? blockedReason;
    if (notEnoughPlayers) {
      blockedReason = l10n.roomsPackRequiresMinPlayers(selectedPack.minPlayers);
    } else if (hasReconnecting) {
      blockedReason = l10n.roomsWaitingForReconnecting;
    }

    final canStart =
        hasPack && allReady && hasEnough && !notEnoughPlayers && !hasReconnecting;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (room.isOwner || room.canStartGame) ...[
              if (!hasPack)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    context.l10n.lobbySelectPackToStart,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )
              else if (blockedReason != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    blockedReason,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              _maybeShowcase(
                context,
                startShowcaseKey,
                context.l10n.tutLobbyStartTitle,
                context.l10n.tutLobbyStartBody,
                JButton(
                  label: l10n.lobbyStartGame,
                  // Disabled the instant Start is tapped (isStartingGame) —
                  // this keeps the _BottomActionBar MOUNTED (a rebuild, not a
                  // replacement) so the in-flight _doStartGame's context stays
                  // valid, while still preventing a double-tap / duplicate
                  // session. The debounce guard in _onStartGame is the second
                  // line of defense.
                  onPressed: canStart && !room.isStartingGame
                      ? _onStartGame(context, room, markFreshStart,
                          syncGameRoute, setPreparingLock)
                      : null,
                  icon: Icons.play_arrow_rounded,
                ),
              ),
            ] else if (room.isConnected) ...[
              if (!(room.currentMember?.isSpectator ?? false))
                _maybeShowcase(
                  context,
                  readyShowcaseKey,
                  context.l10n.tutLobbyReadyTitle,
                  context.l10n.tutLobbyReadyBody,
                  _ReadyButton(
                    isReady: isReady,
                    onToggle: () => room.toggleReady(),
                  ),
                ),
            ] else ...[
              const SizedBox(
                height: 48,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            Row(
              children: [
                if (room.isOwner || room.canManageSettings) ...[
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.tune_rounded,
                      label: l10n.settingsTitle,
                      onTap: () => _showLobbySettings(context, room),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.gavel_rounded,
                      label: l10n.roomsModeration,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ChangeNotifierProvider.value(
                          value: room,
                          child: _ModerationSheet(roomId: r?.id ?? ''),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.person_add_rounded,
                      label: l10n.roomsInvite,
                      onTap: r?.inviteCode != null
                          ? () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => _InviteFriendsSheet(
                                roomId: r!.id,
                                inviteCode: r.inviteCode!,
                              ),
                            )
                          : null,
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.exit_to_app_rounded,
                      label: l10n.leave,
                      color: Theme.of(context).colorScheme.error,
                      onTap: onLeave,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _onStartGame(
    BuildContext ctx,
    RoomProvider room,
    VoidCallback markFreshStart,
    VoidCallback syncGameRoute,
    ValueChanged<bool> setPreparingLock,
  ) {
    return () async {
      // Debounce guard: a rapid double-tap (or a second tap prompted by
      // lag making the first feel unresponsive) must not call
      // create_game_session twice for this room — see
      // RoomProvider.isStartingGame's doc comment.
      if (room.isStartingGame) return;
      final myId = ctx.read<AuthProvider>().currentUser?.id;
      AppLogger.info(
        'START_GAME begin room=${room.room?.id} '
        'gameType=${room.room?.gameType} userId=$myId '
        'status=${room.room?.status} ctxMounted=${ctx.mounted}',
      );
      room.setStartingGame(true);
      try {
        await _doStartGame(
          ctx, room, markFreshStart, syncGameRoute, setPreparingLock);
      } catch (e, st) {
        AppLogger.error(
          'START_GAME failed room=${room.room?.id} '
          'gameType=${room.room?.gameType} status=${room.room?.status}',
          error: e,
          stackTrace: st,
        );
        // Genuine failure: the ONLY path (besides a ToD-settings cancel,
        // which returns from _doStartGame before ever arming the lock —
        // see its single setPreparingLock(true) call site) that clears the
        // Preparing lock. A normal return does NOT clear it here — see
        // _showPreparingLock's doc comment for exactly why: clearing it on
        // _doStartGame merely RETURNING (rather than on room.status
        // actually catching up) was the root cause of the lobby flashing
        // during a slow start. Never a silent failure either — show it.
        setPreparingLock(false);
        if (ctx.mounted) {
          ctx.showErrorSnackBar(
            e is Failure ? e.message : ctx.l10n.lobbyStartGameFailed,
          );
        }
        rethrow;
      } finally {
        AppLogger.info(
          'START_GAME end room=${room.room?.id} '
          'status=${room.room?.status} ctxMounted=${ctx.mounted}',
        );
        room.setStartingGame(false);
      }
    };
  }

  Future<void> _doStartGame(
    BuildContext ctx,
    RoomProvider room,
    VoidCallback markFreshStart,
    VoidCallback syncGameRoute,
    ValueChanged<bool> setPreparingLock,
  ) async {
    final r = room.room;
    if (r == null) return;

    if (r.packId == null || r.packId!.isEmpty) {
        ctx.showErrorSnackBar(ctx.l10n.lobbySelectPackBeforeStart);
        return;
      }

      String gameType = r.gameType?.toDbString() ?? 'truth_or_dare';
      PackEntity? startPack;
      try {
        final packs = ctx.read<PackProvider>();
        final cached = packs.allPacks
            .where((p) => p.id == r.packId)
            .firstOrNull;
        if (cached != null) {
          gameType = cached.gameType;
          startPack = cached;
        } else {
          final fetched = await PackRepository.instance.getPackDetail(
            r.packId!,
          );
          gameType = fetched.gameType;
          startPack = fetched;
        }
      } catch (_) {}

      // Backend-enforced pack-per-room rule (requirement: once a pack has
      // been played in a room, it's unavailable in that room forever,
      // regardless of which game type plays it) — checked here, once, for
      // every game mode, BEFORE broadcasting/pushing anything. Previously
      // this only ever ran deep inside TodGameProvider.initAsOwner, so (a)
      // NHIE/Meme never enforced it server-side at all — only the picker's
      // client-side filtering stood in the way, and (b) even for ToD, the
      // game_started broadcast + room status flip + route push had already
      // happened by the time the rejection came back, stranding every
      // other player mid-navigation into a game that was about to error
      // out for the owner alone.
      if (ctx.mounted) {
        final myId = ctx.read<AuthProvider>().currentUser?.id;
        final isPremium =
            ctx.read<AuthProvider>().currentUser?.isPremiumActive ?? false;
        if (myId != null) {
          final checkError = await sl.roomRepository.runGameSessionChecks(
            userId: myId,
            roomId: r.id,
            packId: r.packId!,
            isPremium: isPremium,
          );
          if (checkError == 'pack_already_played') {
            if (ctx.mounted) {
              ctx.showErrorSnackBar(ctx.l10n.gameSettingsPackAlreadyPlayed);
            }
            return;
          }
        }
      }

      // Truth or Dare gets a dedicated pre-start setup step — every other
      // game continues starting exactly as before, untouched by this.
      TodPreGameConfig? todConfig;
      if (gameType == 'truth_or_dare') {
        if (!ctx.mounted) {
          AppLogger.warning(
            'START_GAME abort room=${r.id} gameType=$gameType '
            'reason=ctx_unmounted_before_tod_sheet',
          );
          return;
        }
        todConfig = await showTodPreGameConfigSheet(
          ctx,
          pack: startPack,
        );
        // Host backed out of the sheet without confirming — don't start.
        if (todConfig == null) return;
        // Item 18.2 root-cause fix: persist the chosen Force Dare settings
        // into room.settings (durable, already read by every navigation
        // into the game screen — see _syncGameRoute's GameConfig
        // construction below) instead of letting them live only in the
        // one-shot game_started broadcast, which RoomProvider never
        // stored anywhere retrievable. Awaited so room.settings already
        // reflects the new values by the time syncGameRoute() runs below
        // (updateSetting updates local state synchronously before its own
        // network round-trip — see RoomProvider.updateSetting).
        //
        // Real-device follow-up root-cause fix (player Skip regression /
        // punishment indicator): this same 18.2 fix only ever persisted
        // force_dare_mode/max_truths — allowSkip/enablePunishments/
        // punishmentSource are ALSO chosen right here in this same sheet
        // (see TodPreGameConfig) and used for this client's own immediate
        // GameConfig below, but were never added to this persistence
        // step. Every OTHER navigation into the game screen (every
        // follower, and this same owner client if it re-navigates via
        // the reactive path instead of this direct one) rebuilds
        // GameConfig from room.settings alone — so allowSkip in
        // particular silently fell back to whatever room.settings.allow
        // _skip already was (stale/default), never what was just chosen
        // in this sheet. The engine was never the problem; the setting
        // simply never reached it for anyone but this one client.
        await room.updateSetting('force_dare_mode', todConfig.forceDareMode);
        await room.updateSetting('max_truths', todConfig.maxTruths);
        await room.updateSetting('allow_skip', todConfig.allowSkip);
        await room.updateSetting(
          'enable_punishments',
          todConfig.enablePunishments,
        );
        await room.updateSetting(
          'punishment_source',
          todConfig.punishmentSource,
        );
      }
      if (!ctx.mounted) {
        AppLogger.warning(
          'START_GAME abort room=${r.id} gameType=$gameType '
          'reason=ctx_unmounted_before_broadcast (this was the regression)',
        );
        return;
      }

      // Single point where the full-screen "Preparing Game" lock actually
      // becomes visible — reached only once we're genuinely committed to
      // starting: past the pack-already-played check, and, for Truth or
      // Dare, only after its settings sheet was CONFIRMED (todConfig != null
      // — a cancel returned above and never reaches here). Every other game
      // has no settings step, so this is effectively immediate for them,
      // same as before.
      setPreparingLock(true);

      final displayNames = {
        for (final m in room.members) m.userId: m.displayName,
      };

      final config = GameConfig(
        maxRounds: room.settings.maxRounds,
        turnTimerSeconds: room.settings.turnTimerSeconds,
        allowSkip: todConfig?.allowSkip ?? true,
        allowSpicy: r.allowSpicy,
        enablePunishments: todConfig?.enablePunishments ?? false,
        punishmentSource: todConfig?.punishmentSource ?? 'players',
        suggestedPunishments: startPack?.suggestedPunishments,
        // Proof visibility/timer are no longer a game-wide default chosen
        // here — the submitting player picks them per-Dare instead (see
        // TodCardScreen._showCompleteSheet). These GameConfig fields are
        // kept (other call sites / the shared Rules sheet still read them)
        // and sourced from the room's own persisted settings, exactly like
        // the resume/rejoin GameConfig construction above already does —
        // no longer overridable by the (now-removed) pre-game sheet fields.
        proofVisibilityPolicy: room.settings.proofVisibilityPolicy,
        proofViewSeconds: room.settings.proofViewSeconds,
        proofReplayMode: room.settings.proofReplayMode,
        forceDareMode: todConfig?.forceDareMode ?? 'unlimited',
        maxTruths: todConfig?.maxTruths ?? 2,
        cardRepetitionMode: todConfig?.cardRepetitionMode ?? 'shuffle',
        packId: r.packId,
        language: r.language,
      );

      // Declare intent BEFORE either write below — RoomProvider's own
      // listener (_handleGameStarted reacts to the broadcast itself, not
      // just the DB status change, so it can flip _room.status to inGame
      // and notify locally before either await here even resolves) is
      // what actually performs the navigation, via _syncGameRoute. This
      // method never pushes the game route itself — see _syncGameRoute's
      // doc comment for why nothing else is allowed to.
      markFreshStart();

      await sl.realtimeService.broadcastGameStarted(r.id, {
        'game_type': gameType,
        'pack_id': r.packId,
        'config': config.toMap(),
        'player_ids': room.members
            .where((m) => !m.isSpectator)
            .map((m) => m.userId)
            .toList(),
        'display_names': displayNames,
      });

      // 'starting', NOT 'in_game' — the room enters the explicit,
      // DB-backed STARTING_GAME lock. Every non-owner client stays locked
      // on the "Game Starting" overlay (see build()) until the OWNER's own
      // game screen confirms create_game_session has genuinely succeeded
      // and flips this to 'in_game' itself (see each game's initAsOwner /
      // RoomProvider._handleGameSessionReady) — closing the race where a
      // player's game screen could previously mount and look for a
      // session the owner hadn't necessarily created yet.
      await sl.roomRepository.updateStatus(
        r.id,
        RoomStatus.starting,
        gameType: gameType,
      );
      AppLogger.info(
        'START_GAME session-triggers-sent room=${r.id} gameType=$gameType '
        'status=${room.room?.status} — broadcast + status=starting done, '
        'awaiting owner initAsOwner/create_game_session',
      );

      // Direct nudge for promptness — not required for correctness (the
      // notify from either write above already reaches _onRoomStateChanged
      // -> _syncGameRoute on its own), same as "Continue Game"/Rejoin
      // calling the same shared function rather than pushing independently.
      syncGameRoute();
  }

  void _showLobbySettings(BuildContext ctx, RoomProvider room) {
    if (!room.isOwner && !room.canManageSettings) return;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // DraggableScrollableSheet instead of letting the sheet grow to its
      // full unconstrained content height (which reached almost to the top
      // of the screen) — bounded, swipe-to-dismiss, and comfortable on
      // both phones and tablets since the sizes are fractions of the
      // available height rather than fixed pixel values.
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => ChangeNotifierProvider.value(
          value: room,
          child: GameSettingsSheet(scrollController: scrollController),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Material(
      color: c.withOpacity(0.10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: onTap != null ? c : theme.disabledColor,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: onTap != null ? c : theme.disabledColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyButton extends StatelessWidget {
  const _ReadyButton({required this.isReady, required this.onToggle});
  final bool isReady;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: OutlinedButton(
        onPressed: onToggle,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: isReady
              ? AppColors.successGreen.withOpacity(0.08)
              : null,
          side: BorderSide(
            color: isReady
                ? AppColors.successGreen
                : context.colorScheme.outline,
            width: isReady ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isReady
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isReady
                  ? AppColors.successGreen
                  : context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              isReady ? context.l10n.lobbyReady : context.l10n.lobbyNotReady,
              style: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isReady
                    ? AppColors.successGreen
                    : context.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RejoinBanner extends StatefulWidget {
  const _RejoinBanner({required this.room, required this.onRejoin});

  /// An intact `room_members` row (the common "briefly backgrounded" case)
  /// rejoins instantly via [onRejoin]. A row that was actually terminated
  /// (real disconnect/leave) instead has to go through a host-approved
  /// request — see `request_game_rejoin`/`decide_game_rejoin_request`.
  final RoomProvider room;
  final VoidCallback onRejoin;

  @override
  State<_RejoinBanner> createState() => _RejoinBannerState();
}

class _RejoinBannerState extends State<_RejoinBanner> {
  String? _requestStatus;
  bool _requesting = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Also poll when arrivedMidGame is set even with an intact row — that
    // combination is exactly "reconnected mid-game, row never got
    // evicted, still needs explicit approval" (see RoomProvider.
    // arrivedMidGame's doc comment), and this is the only place that
    // notices the approval (clearing the flag) once it happens.
    if (widget.room.currentMember == null || widget.room.arrivedMidGame) {
      _loadStatus();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _loadStatus(),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    final roomId = widget.room.room?.id;
    if (userId == null || roomId == null) return;
    try {
      final status = await sl.roomRepository.getRejoinRequestStatus(
        userId: userId,
        roomId: roomId,
      );
      // The explicit signal that clears arrivedMidGame — an admin/mod
      // decided this, not any inference from room_members row state
      // (which, for the intact-row case, never actually changed).
      if (status == 'approved') widget.room.clearArrivedMidGame();
      if (mounted) setState(() => _requestStatus = status);
    } catch (_) {
      // Keep last known status on a transient fetch failure.
    }
  }

  Future<void> _requestRejoin() async {
    final roomId = widget.room.room?.id;
    if (roomId == null) return;
    setState(() => _requesting = true);
    try {
      await sl.roomRepository.requestGameRejoin(roomId);
      if (mounted) setState(() => _requestStatus = 'pending');
    } catch (e) {
      if (mounted) context.showErrorSnackBar(context.l10n.roomsFailedToSendRequest(e.toString()));
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The row reappeared (approved, or it was never actually gone) — fold
    // back into the normal one-tap instant rejoin. arrivedMidGame
    // overrides this: an intact row from a reconnect that landed while
    // the game was already running still requires explicit approval (see
    // RoomProvider.arrivedMidGame) — it's only cleared once that approval
    // is actually observed, in _loadStatus above.
    final hasIntactRow =
        widget.room.currentMember != null && !widget.room.arrivedMidGame;

    final String label;
    final String buttonLabel;
    final VoidCallback? onPressed;
    if (hasIntactRow) {
      label = context.l10n.roomsGameInProgress;
      buttonLabel = context.l10n.roomsRejoin;
      onPressed = widget.onRejoin;
    } else if (_requestStatus == 'pending') {
      label = context.l10n.roomsRequestSentWaiting;
      buttonLabel = context.l10n.roomsPendingEllipsis;
      onPressed = null;
    } else if (_requestStatus == 'rejected') {
      label = context.l10n.roomsRejoinRequestDeclined;
      buttonLabel = context.l10n.roomsRequestAgain;
      onPressed = _requesting ? null : _requestRejoin;
    } else {
      label = context.l10n.roomsGameInProgress;
      buttonLabel = context.l10n.roomsRequestToRejoin;
      onPressed = _requesting ? null : _requestRejoin;
    }

    return Container(
      width: double.infinity,
      color: AppColors.tealGreen.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.sports_esports_rounded, color: AppColors.tealGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Explicit minimumSize:Size.zero + shrinkWrap tap target — the
          // app-wide FilledButton/ElevatedButton/OutlinedButton theme sets
          // minimumSize: Size(double.infinity, 52) (for full-width
          // primary CTAs). This button is a non-Expanded Row child (after
          // an Expanded Text), which receives an UNBOUNDED max width from
          // the Row — without this override it throws "BoxConstraints
          // forces an infinite width" the instant this banner renders,
          // i.e. whenever a room member views the lobby while the game
          // (room.status == inGame/paused) is in progress — exactly the
          // "other player watching/rejoining while a game is live"
          // scenario. See friends_screen.dart's identical fix/comment for
          // the same root cause.
          SizedBox(
            height: 34,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tealGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen "waiting for admin acceptance" state for a non-owner who
/// reconnected into an already-running game (RoomProvider.arrivedMidGame).
/// Their rejoin request is auto-filed in RoomProvider.initialize; this view
/// only polls its status and drives the transition — on approval it clears
/// arrivedMidGame (so the lobby rebuilds and [onApproved]/_syncGameRoute
/// enters the game), on rejection it offers to request again or leave. It
/// deliberately reuses the same getRejoinRequestStatus/requestGameRejoin
/// path as _RejoinBanner so there is exactly one approval mechanism.
class _RejoinWaitingView extends StatefulWidget {
  const _RejoinWaitingView({required this.room, required this.onApproved});

  final RoomProvider room;
  final VoidCallback onApproved;

  @override
  State<_RejoinWaitingView> createState() => _RejoinWaitingViewState();
}

class _RejoinWaitingViewState extends State<_RejoinWaitingView> {
  String? _status;
  bool _requesting = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadStatus(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    final roomId = widget.room.room?.id;
    if (userId == null || roomId == null) return;
    try {
      final status = await sl.roomRepository.getRejoinRequestStatus(
        userId: userId,
        roomId: roomId,
      );
      if (!mounted) return;
      if (status == 'approved') {
        // The explicit admin decision — clearing arrivedMidGame rebuilds the
        // lobby out of this waiting state, and _syncGameRoute then enters the
        // game (its own guard now lets this client through).
        widget.room.clearArrivedMidGame();
        widget.onApproved();
        return;
      }
      setState(() => _status = status);
    } catch (_) {
      // Keep last known status on a transient fetch failure.
    }
  }

  Future<void> _requestAgain() async {
    final roomId = widget.room.room?.id;
    if (roomId == null) return;
    setState(() => _requesting = true);
    try {
      await sl.roomRepository.requestGameRejoin(roomId);
      if (mounted) setState(() => _status = 'pending');
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          context.l10n.roomsFailedToSendRequest(e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rejected = _status == 'rejected';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (mounted) context.go(RouteNames.home);
      },
      child: BrandedStatusView(
        emoji: rejected ? '🚫' : '⏳',
        title: rejected
            ? context.l10n.roomsRejoinRequestDeclined
            : context.l10n.roomsRequestSentWaiting,
        subtitle: rejected ? null : context.l10n.lobbyAutoLetInOnceApproved,
        accent: rejected ? AppColors.brandOrangeMid : AppColors.brandPurpleMid,
        showLoader: !rejected,
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rejected)
              FilledButton(
                onPressed: _requesting ? null : _requestAgain,
                child: Text(context.l10n.roomsRequestAgain),
              ),
            if (rejected) const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(RouteNames.home),
              child: Text(
                context.l10n.backToHome,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RejoinRequestsPanel extends StatefulWidget {
  const _RejoinRequestsPanel({required this.roomId});
  final String roomId;
  @override
  State<_RejoinRequestsPanel> createState() => _RejoinRequestsPanelState();
}

class _RejoinRequestsPanelState extends State<_RejoinRequestsPanel> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await sl.roomRepository.getPendingRejoinRequests(
        widget.roomId,
      );
      if (mounted)
        setState(() {
          _requests = rows;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolve(String requestId, bool approve) async {
    try {
      await sl.roomRepository.decideGameRejoinRequest(
        requestId: requestId,
        approve: approve,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(context.l10n.lobbyRejoinDecisionFailed('$e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    if (_loading && _requests.isEmpty) return const SizedBox.shrink();
    if (_requests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.lobbyRejoinRequestsCount(_requests.length),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        ..._requests.map((req) {
          final profile = req['profiles'] as Map<String, dynamic>? ?? {};
          final name = profile['display_name'] as String? ?? context.l10n.defaultPlayerName;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text(name[0].toUpperCase())),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(context.l10n.lobbyWantsToRejoin),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                    onPressed: () => _resolve(req['id'] as String, true),
                    tooltip: context.l10n.lobbyApprove,
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                    onPressed: () => _resolve(req['id'] as String, false),
                    tooltip: context.l10n.lobbyReject,
                  ),
                ],
              ),
            ),
          );
        }),
        const Divider(),
      ],
    );
  }
}

class _JoinRoleDialog extends StatelessWidget {
  const _JoinRoleDialog({
    this.isInGame = false,
    this.isPremium = false,
    this.allowAnonymous = true,
  });
  final bool isInGame;
  final bool isPremium;
  final bool allowAnonymous;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        context.l10n.lobbyHowToJoin,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isInGame
                ? context.l10n.roomsGameAlreadyInProgress
                : context.l10n.roomsChooseYourRole,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _RoleOption(
            icon: Icons.sports_esports_rounded,
            title: context.l10n.roomsJoinAsPlayer,
            subtitle: context.l10n.roomsTakePartInGame,
            color: AppColors.successGreen,
            onTap: () => Navigator.pop(context, 'player'),
          ),
          const SizedBox(height: 10),
          _RoleOption(
            icon: Icons.visibility_rounded,
            title: context.l10n.roomsWatchAsSpectator,
            subtitle: context.l10n.roomsObserveWithoutPlaying,
            color: AppColors.infoBlue,
            onTap: () => Navigator.pop(context, 'spectator'),
          ),
          if (isPremium && allowAnonymous) ...[
            const SizedBox(height: 10),
            _RoleOption(
              icon: Icons.visibility_off_rounded,
              title: context.l10n.roomsWatchAnonymously,
              subtitle: context.l10n.roomsHiddenFromPlayersList,
              color: const Color(0xFF7B68EE),
              onTap: () => Navigator.pop(context, 'spectator_anon'),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w700, color: color),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SpectatorRequestsSheet extends StatefulWidget {
  const _SpectatorRequestsSheet({required this.requests, required this.room});
  final List<Map<String, dynamic>> requests;
  final RoomProvider room;

  @override
  State<_SpectatorRequestsSheet> createState() =>
      _SpectatorRequestsSheetState();
}

class _SpectatorRequestsSheetState extends State<_SpectatorRequestsSheet> {
  final Set<String> _decided = {};

  Future<void> _decide(Map<String, dynamic> req, bool approve) async {
    final id = req['id'] as String;
    final userId = req['user_id'] as String;
    setState(() => _decided.add(id));
    await widget.room.decideSpectatorRequest(
      requestId: id,
      requestingUserId: userId,
      approve: approve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final pending = widget.requests
        .where((r) => !_decided.contains(r['id'] as String))
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  context.l10n.lobbySpectatorRequestsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (pending.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Badge(label: Text('${pending.length}')),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.lobbySpectateWatchHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (pending.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    context.l10n.lobbyAllRequestsDecided,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...pending.map((req) {
                final userId = req['user_id'] as String;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(userId.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(
                    userId.substring(0, 8),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(context.l10n.lobbyWantsToSpectate),
                  trailing: SizedBox(
                    width: 130,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: context.l10n.deny,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.red,
                          ),
                          onPressed: () => _decide(req, false),
                        ),
                        IconButton(
                          tooltip: context.l10n.lobbyApprove,
                          icon: const Icon(
                            Icons.check_rounded,
                            color: Colors.green,
                          ),
                          onPressed: () => _decide(req, true),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ModerationSheet extends StatefulWidget {
  const _ModerationSheet({required this.roomId});
  final String roomId;
  @override
  State<_ModerationSheet> createState() => _ModerationSheetState();
}

class _ModerationSheetState extends State<_ModerationSheet> {
  List<Map<String, dynamic>> _banned = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Was previously a fire-and-forget `() => room.mutePlayer(...)` — see
  /// _LobbyTab._toggleMute for why that's a real problem, not just style.
  Future<void> _unmute(
    BuildContext ctx,
    RoomProvider room,
    String targetUserId,
  ) async {
    try {
      await room.mutePlayer(targetUserId, muted: false);
    } on Failure catch (e) {
      if (ctx.mounted) ctx.showErrorSnackBar(e.message);
    }
  }

  Future<void> _load() async {
    try {
      final banned = await sl.roomRepository.getBannedMembers(widget.roomId);
      if (mounted)
        setState(() {
          _banned = banned;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final room = context.watch<RoomProvider>();
    final muted = room.members.where((m) => m.isMuted).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              context.l10n.lobbyModerationTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (muted.isEmpty && _banned.isEmpty)
                ? Center(
                    child: Text(
                      context.l10n.lobbyNoMutedOrBanned,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (muted.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            context.l10n.lobbyMutedSectionTitle,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ...muted.map(
                          (m) => ListTile(
                            leading: CircleAvatar(
                              child: Text(m.displayName[0].toUpperCase()),
                            ),
                            title: Text(m.displayName),
                            subtitle: Text(context.l10n.muted),
                            trailing: TextButton(
                              onPressed: () => _unmute(context, room, m.userId),
                              child: Text(context.l10n.unmute),
                            ),
                            dense: true,
                          ),
                        ),
                        const Divider(),
                      ],
                      if (_banned.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            context.l10n.lobbyBannedSectionTitle,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ..._banned.map((b) {
                          final name =
                              b['display_name'] as String? ??
                              b['user_id'] as String? ??
                              '?';
                          final reason = b['reason'] as String?;
                          final userId = b['user_id'] as String;
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(name[0].toUpperCase()),
                            ),
                            title: Text(name),
                            subtitle: reason != null
                                ? Text(context.l10n.lobbyBanReason(reason))
                                : null,
                            trailing: TextButton(
                              onPressed: () async {
                                await room.unbanPlayer(userId);
                                _load();
                              },
                              child: Text(context.l10n.unban),
                            ),
                            dense: true,
                          );
                        }),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SpectatorsSheet extends StatelessWidget {
  const _SpectatorsSheet({
    required this.spectators,
    this.canRevealHidden = false,
    this.room,
  });
  final List<RoomMemberEntity> spectators;
  /// True only for a Premium Plus moderator — controls whether a hidden
  /// (anonymous) spectator's real name/avatar is shown. When false, a hidden
  /// spectator still appears (and is kickable) but as a masked "Anonymous"
  /// entry.
  final bool canRevealHidden;
  final RoomProvider? room;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final canModerate = room?.canModerateRoom ?? false;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.lobbySpectatorsCount(spectators.length),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (canModerate) ...[
            const SizedBox(height: 4),
            Builder(
              builder: (_) {
                final hidden =
                    spectators.where((s) => s.isHiddenSpectator).length;
                if (hidden == 0) return const SizedBox.shrink();
                return Text(
                  context.l10n.lobbyHiddenAnonymousCount(hidden),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          if (spectators.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                context.l10n.lobbyNoVisibleSpectators,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ...spectators.map((s) {
            // A hidden spectator's identity is unmasked only for a Premium Plus
            // moderator. Otherwise the entry is anonymized (generic avatar +
            // "Anonymous spectator") — but still present and kickable, so a
            // non-Premium-Plus admin can moderate without seeing who it is.
            final masked = s.isHiddenSpectator && !canRevealHidden;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: masked
                  ? CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.visibility_off_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : UserAvatar(
                      avatarUrl: s.avatarUrl,
                      avatarConfig: s.avatarConfig,
                      isPremium: s.isPremium,
                      displayName: s.displayName,
                      size: 36,
                    ),
              title: Text(
                masked ? context.l10n.lobbyAnonymousSpectator : s.displayName,
              ),
              trailing: canModerate
                  ? IconButton(
                      icon: Icon(
                        Icons.person_remove_rounded,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: context.l10n.kick,
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            title: Text(context.l10n.lobbyKickSpectatorTitle),
                            content: Text(
                              context.l10n.lobbyKickSpectatorBody(
                                masked
                                    ? context.l10n.lobbyAnonymousSpectator
                                    : s.displayName,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx, false),
                                child: Text(context.l10n.cancel),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(dCtx, true),
                                child: Text(context.l10n.kick),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await room?.kickPlayer(
                            s.userId,
                            reason: 'spectator_removed',
                          );
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                    )
                  : Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              dense: true,
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FriendRequestButton extends StatefulWidget {
  const _FriendRequestButton({
    required this.targetUserId,
    required this.displayName,
    required this.myId,
  });
  final String targetUserId, displayName, myId;
  @override
  State<_FriendRequestButton> createState() => _FriendRequestButtonState();
}

class _FriendRequestButtonState extends State<_FriendRequestButton> {
  bool _sent = false, _loading = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      // Jma3a Official can never be friended — checked first so this
      // button never renders "Add Friend" for it, matching every other
      // entry point (server-side RLS is still the real backstop; see
      // FriendsRepository.isOfficialAccount).
      if (await sl.friendsRepository.isOfficialAccount(widget.targetUserId)) {
        if (mounted) setState(() => _status = 'official');
        return;
      }
      final friendship = await sl.friendsRepository.getFriendshipStatus(
        userId: widget.myId,
        otherId: widget.targetUserId,
      );
      if (mounted)
        setState(() {
          if (friendship == null)
            _status = 'none';
          else if (friendship.isAccepted)
            _status = 'friend';
          else
            _status = 'pending';
        });
    } catch (_) {
      if (mounted) setState(() => _status = 'none');
    }
  }

  Future<void> _send() async {
    setState(() => _loading = true);
    try {
      await sl.friendsRepository.sendFriendRequest(
        requesterId: widget.myId,
        addresseeId: widget.targetUserId,
      );
      if (mounted)
        setState(() {
          _sent = true;
          _loading = false;
          _status = 'pending';
        });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.lobbyFriendRequestSent(widget.displayName)),
          ),
        );
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      final msg = e.toString().contains('Cannot interact')
          ? context.l10n.lobbyCannotSendRequest(widget.displayName)
          : context.l10n.lobbyCouldNotSendRequest;
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == '') {
      return ListTile(
        leading: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text(context.l10n.checking),
        dense: true,
      );
    }
    if (_status == 'official') {
      // Jma3a Official — no friend-request affordance at all here (this
      // is a same-room-member quick action, not the full profile sheet,
      // so there's no Follow action to offer in its place either).
      return const SizedBox.shrink();
    }
    if (_status == 'friend') {
      return ListTile(
        leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
        title: Text(
          context.l10n.lobbyAreFriends(widget.displayName),
          style: const TextStyle(fontSize: 13),
        ),
        dense: true,
      );
    }
    if (_status == 'pending' || _sent) {
      return ListTile(
        leading: const Icon(Icons.hourglass_top_rounded, color: Colors.orange),
        title: Text(context.l10n.lobbyFriendRequestPending),
        dense: true,
      );
    }
    return ListTile(
      leading: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.person_add_outlined),
      title: Text(context.l10n.lobbyAddAsFriend(widget.displayName)),
      dense: true,
      onTap: _loading ? null : _send,
    );
  }
}

class _InviteFriendsSheet extends StatefulWidget {
  const _InviteFriendsSheet({required this.roomId, required this.inviteCode});
  final String roomId, inviteCode;
  @override
  State<_InviteFriendsSheet> createState() => _InviteFriendsSheetState();
}

class _InviteFriendsSheetState extends State<_InviteFriendsSheet> {
  Set<String> _invited = {};
  bool _loadingInvited = true;
  // userId -> reason code, only for friends the server says can't be
  // invited right now (already in the room, banned, blocked, room full,
  // already in another active game, platform-banned) — see
  // RoomRepository.getInvitableFriends. Absence means eligible.
  // Excluded from the list entirely below, not just shown-but-disabled —
  // "filter users and exclude" per the invite-eligibility requirement.
  Map<String, String> _ineligible = {};
  final _searchCtrl = TextEditingController();
  String _query = '';
  final Set<String> _selected = {};
  final Set<String> _sending = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
    sl.roomRepository
        .getInvitedUserIds(widget.roomId)
        .then((ids) {
          if (!mounted) return;
          setState(() {
            _invited = ids;
            _loadingInvited = false;
          });
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() => _loadingInvited = false);
        });
    sl.roomRepository
        .getInvitableFriends(widget.roomId)
        .then((eligibility) {
          if (!mounted) return;
          setState(() {
            _ineligible = {
              for (final e in eligibility.entries)
                if (e.value != null) e.key: e.value!,
            };
          });
        })
        // Best-effort: if this fails, everyone just shows as
        // invitable client-side — POST /invite still enforces the real
        // eligibility check, so nothing unsafe slips through, this only
        // affects whether the picker pre-filters them.
        .catchError((_) {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _invite(FriendEntity friend) async {
    if (_invited.contains(friend.userId) || _sending.contains(friend.userId)) {
      return;
    }
    setState(() => _sending.add(friend.userId));
    try {
      await sl.roomRepository.sendInvite(
        roomId: widget.roomId,
        invitedUserId: friend.userId,
      );
      if (!mounted) return;
      setState(() {
        _invited.add(friend.userId);
        _sending.remove(friend.userId);
        _selected.remove(friend.userId);
      });
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() {
        _sending.remove(friend.userId);
        // The eligibility pre-filter is best-effort (see initState) and
        // there's an inherent race between it and the actual invite
        // (the friend's state can change in between) — either way, the
        // server's specific rejection reason (already in the room,
        // banned, blocked, room full, already in another game...) is
        // more useful here than a generic failure message, and this
        // friend clearly isn't invitable right now regardless of what
        // the pre-filter said, so drop them from the list too.
        _ineligible[friend.userId] = f.code ?? 'ineligible';
      });
      context.showErrorSnackBar(f.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending.remove(friend.userId));
      context.showErrorSnackBar(
        'Could not send invite to ${friend.displayName}',
      );
    }
  }

  Future<void> _inviteSelected(List<FriendEntity> friends) async {
    final targets = friends.where((f) => _selected.contains(f.userId)).toList();
    for (final f in targets) {
      await _invite(f);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final fp = context.watch<FriendsProvider>();
    // A friend busy in a DIFFERENT room/game stays VISIBLE but non-invitable
    // ("In Game"), driven by live presence (re-evaluated on every build, so it
    // stays current while the sheet is open). This is distinct from a friend
    // already in THIS room, who is excluded entirely (handled by the server's
    // 'already in room' ineligibility reason below).
    bool inAnotherGame(String uid) =>
        fp.isInGame(uid) && fp.roomIdOf(uid) != widget.roomId;
    final allFriends = fp.friends.where((f) {
      if (!f.isAccepted) return false;
      // Keep in-another-game friends regardless of the server reason so they
      // can be shown disabled; every other ineligibility (already in room,
      // banned, blocked, room full, platform-banned) still excludes them.
      if (inAnotherGame(f.userId)) return true;
      return !_ineligible.containsKey(f.userId);
    }).toList();
    final friends = _query.isEmpty
        ? allFriends
        : allFriends
              .where((f) => f.displayName.toLowerCase().contains(_query))
              .toList();
    // In-another-game friends are visible but not selectable/invitable.
    final selectableCount = friends
        .where((f) => !_invited.contains(f.userId) && !inAnotherGame(f.userId))
        .length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  context.l10n.lobbyInviteFriendsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (_selected.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () => _inviteSelected(friends),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: Text(context.l10n.lobbyInviteCount(_selected.length)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          if (allFriends.length > 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: context.l10n.lobbySearchFriendsHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (_loadingInvited)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (allFriends.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n.lobbyNoFriendsToInvite,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else if (friends.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n.lobbyNoFriendsMatchQuery(_query),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: friends.length,
                itemBuilder: (_, i) {
                  final f = friends[i];
                  final sent = _invited.contains(f.userId);
                  final sending = _sending.contains(f.userId);
                  final selected = _selected.contains(f.userId);
                  final busyInGame = inAnotherGame(f.userId);
                  return CheckboxListTile(
                    value: busyInGame ? false : (sent ? true : selected),
                    // In-another-game friends stay visible but can't be
                    // selected or invited.
                    onChanged: sent || sending || busyInGame
                        ? null
                        : (v) => setState(() {
                            if (v ?? false) {
                              _selected.add(f.userId);
                            } else {
                              _selected.remove(f.userId);
                            }
                          }),
                    controlAffinity: ListTileControlAffinity.leading,
                    secondary: CircleAvatar(
                      child: Text(f.displayName[0].toUpperCase()),
                    ),
                    title: Text(
                      f.displayName,
                      style: busyInGame
                          ? TextStyle(color: theme.colorScheme.onSurfaceVariant)
                          : null,
                    ),
                    subtitle: busyInGame
                        ? Text(
                            context.l10n.friendsStatusInGame,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : sent
                        ? Text(
                            context.l10n.invited,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : sending
                        ? Text(context.l10n.sending)
                        : null,
                  );
                },
              ),
            ),
          if (selectableCount > 1 && !_loadingInvited)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() {
                    bool selectable(FriendEntity f) =>
                        !_invited.contains(f.userId) &&
                        !inAnotherGame(f.userId);
                    final allSelected = friends
                        .where(selectable)
                        .every((f) => _selected.contains(f.userId));
                    _selected.clear();
                    if (!allSelected) {
                      _selected.addAll(
                        friends.where(selectable).map((f) => f.userId),
                      );
                    }
                  }),
                  child: Text(
                    _selected.length >= selectableCount
                        ? context.l10n.lobbyDeselectAll
                        : context.l10n.lobbySelectAll,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final myId2 =
                          context.read<AuthProvider>().currentUser?.id ?? '';
                      final code2 = widget.inviteCode;
                      // HTTPS, not jma3a:// — a custom scheme renders as
                      // plain, non-tappable text in WhatsApp/SMS/etc. The
                      // https://jma3a.com/join link opens the app directly
                      // via Android App Links / iOS Universal Links when
                      // installed, and falls back to the website (with
                      // download prompts) when it isn't — jma3a:// can't
                      // do either of those from inside a chat app.
                      Share.share(
                        context.l10n.lobbyShareInviteMessage(
                          code2,
                          AppConstants.roomInviteUrl(
                            code: code2,
                            invitedBy: myId2,
                          ),
                        ),
                        subject: context.l10n.lobbyShareInviteSubject(code2),
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: Text(context.l10n.lobbyShareInviteLink),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
