import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:jma3a/Sticker.dart';
import 'package:jma3a/features/settings/presentation/screen_security_service.dart';
import '../../avatar/presentation/avatar_creator_screen.dart';
import '../../../shared/widgets/overlays/host_reconnect_overlay.dart';
import 'package:animated_emoji/animated_emoji.dart';
import '../../../shared/widgets/overlays/branded_status_view.dart';
import '../../../shared/widgets/game/away_presence_snackbar_listener.dart';
import '../../../shared/widgets/game/game_chat_sheet.dart';
import '../../../shared/widgets/game/game_over_podium.dart';
import '../../../shared/widgets/game/player_result_tile.dart';
import '../../../shared/widgets/game/responsive_game_text.dart';
import '../game_session_messages.dart';
import 'package:jma3a/core/router/app_router.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/engine/turn_queue.dart';
import 'package:jma3a/features/games/presentation/widgets/game_screen_security_gate.dart';
import 'package:jma3a/features/games/never_have_i_ever/never_have_i_ever_engine.dart';
import 'package:jma3a/features/games/truth_or_dare/data/tod_repository.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/features/rooms/presentation/room_provider.dart';
import 'package:jma3a/shared/widgets/animated_reaction_overlay.dart';
import 'package:jma3a/shared/widgets/game_rules_sheet.dart';
import 'package:jma3a/shared/widgets/no_active_players_banner.dart';
import 'package:jma3a/shared/widgets/join_requests_panel.dart';
import 'package:jma3a/shared/widgets/room_members_management_sheet.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/services/app_tutorial_service.dart';
import '../../../../shared/widgets/cards/honesty_score_line.dart';
import '../../../../shared/widgets/game/dishonest_reasons_panel.dart';
import '../../../../shared/widgets/game/game_flip_card.dart';
import '../../../../shared/widgets/game/honesty_vote_buttons.dart';
import '../../../../shared/widgets/tutorial/screen_tutorial.dart';
import '../../../../core/data/honesty_vote_repository.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/targeted_chat_listener.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/game_end_navigation.dart';

// import '../../../../core/services/screen_security_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/game_end_navigation.dart';

enum NhieLoadState { idle, loading, ready, error, gameOver }

/// NHIE's own party-chrome identity (deep emerald → vivid teal), matching
/// ToD's TodHud in structure (deliberately theme-independent dark chrome,
/// same continuous AppBar-into-HUD gradient) but distinct in color so each
/// game in the family reads as itself at a glance.
const _kNhieDeep = Color(0xFF065F46);
const _kNhieVivid = Color(0xFF0EA37A);
const _kNhieAccent = Color(0xFFB6F09C);

/// Looks up [userId]'s CURRENT room-member row from [game.roomProvider] —
/// the SAME single source of truth the lobby (MemberTile) and ToD read
/// for honesty_points/general_score. See ToD's own todRoomMemberFor for
/// the identical rationale/limitation (not independently reactive to a
/// RoomProvider-only change — this reveal list already rebuilds on every
/// honesty vote via NhieGameProvider.castHonestyVote's own
/// notifyListeners(), which in practice keeps this acceptably fresh
/// without a second Listenable wrapper).
RoomMemberEntity? nhieRoomMemberFor(NhieGameProvider game, String userId) {
  final members = game.roomProvider?.members;
  if (members == null) return null;
  for (final m in members) {
    if (m.userId == userId) return m;
  }
  return null;
}

class NhieGameProvider extends ChangeNotifier {
  NhieGameProvider({
    required RealtimeService realtimeService,
    required String userId,
    required String displayName,
    this.isModerator = false,
  }) : _realtime = realtimeService,
       _userId = userId,
       _displayName = displayName;

  final RealtimeService _realtime;
  final String _userId, _displayName;
  final bool isModerator;

  /// Set by the screen (which owns the RoomProvider reference) — lets the
  /// owner's client validate a moderator-delegated advance-turn action
  /// sent by someone else's client before executing it.
  bool Function(String userId, String permissionKey)? permissionChecker;

  bool _isAllowed(String? uid, String permissionKey) =>
      permissionChecker == null ||
      (uid != null && permissionChecker!(uid, permissionKey));

  /// Set by the screen right after construction, same as [permissionChecker]
  /// — gives this provider read access to the room's durable, backend-synced
  /// member list so ready/vote logic never has to trust its own ephemeral,
  /// broadcast-only away-tracking alone (see [_effectiveAwayIds]).
  RoomProvider? roomProvider;

  // Item 2 — Premium Plus targeted chat, in-game context. See
  // TodGameProvider's identical wiring/comments for the full rationale
  // (a separate, RLS-gated CDC path — never the plain broadcast channel).
  final _targetedChatListener = TargetedChatListener();

  void startTargetedChatListener(String roomId) {
    _targetedChatListener.start(
      roomId: roomId,
      onInsert: _handleTargetedChatInsert,
    );
  }

  void _handleTargetedChatInsert(Map<String, dynamic> row) {
    if (row['game_session_id'] != _sessionId) return;
    final msgId = row['id'] as String?;
    if (msgId == null) return;
    if (_chatMessages.any((m) => m.id == msgId)) return;

    final senderId = row['user_id'] as String? ?? '';
    final senderName =
        roomProvider?.memberById(senderId)?.displayName ?? 'Player';
    final msg = GameChatMsg(
      id: msgId,
      senderId: senderId,
      senderName: senderName,
      text: row['content'] as String? ?? '',
      ts: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      replyToId: row['reply_to_id'] as String?,
      replyToSenderName: row['reply_to_display_name'] as String?,
      replyToText: row['reply_to_content'] as String?,
      audienceType: row['audience_type'] as String? ?? 'everyone',
    );
    _chatMessages.add(msg);
    _safeNotify();
  }

  List<RoomMemberEntity> get gameParticipants =>
      roomProvider?.members
          .where(
            (m) => m.userId != _userId && !m.isSpectator && !m.leftDefinitively,
          )
          .toList() ??
      const [];

  Future<bool> sendTargetedChat(
    String text, {
    required List<String> recipientIds,
    required List<String> recipientNames,
    GameChatMsg? replyTo,
  }) async {
    if (_roomId == null || _sessionId == null || text.trim().isEmpty) {
      return false;
    }
    try {
      final replySnippet = replyTo != null && replyTo.text.length > 120
          ? '${replyTo.text.substring(0, 120)}…'
          : replyTo?.text;
      final row = await sl.roomRepository.sendTargetedChatMessage(
        roomId: _roomId!,
        content: text.trim(),
        recipientIds: recipientIds,
        gameSessionId: _sessionId,
        replyToId: replyTo?.id,
        replyToContent: replySnippet,
        replyToDisplayName: replyTo?.senderName,
      );
      final msg = GameChatMsg(
        id: row.id,
        senderId: _userId,
        senderName: _displayName,
        text: row.content,
        ts: row.createdAt,
        replyToId: row.replyToId,
        replyToSenderName: row.replyToDisplayName,
        replyToText: row.replyToContent,
        audienceType: row.audienceType,
        recipientNames: recipientNames,
      );
      _chatMessages.add(msg);
      _safeNotify();
      return true;
    } catch (_) {
      return false;
    }
  }

  bool get canAdvanceTurnHere =>
      _isOwner ||
      (permissionChecker?.call(_userId, 'advance_turn') ?? false) ||
      (permissionChecker?.call(_userId, 'skip_turn') ?? false);

  NeverHaveIEverEngine? _engine;
  NhieLoadState _loadState = NhieLoadState.idle;

  // Guards every notifyListeners() call against firing after this provider
  // has been disposed — without it, any async work still in flight when
  // the game screen is popped (a pending Supabase query, a realtime
  // broadcast handler invoked just before unsubscribe completes, a Timer
  // callback) throws "A NhieGameProvider was used after being disposed"
  // the moment it resolves. See TodGameProvider's identical _safeNotify
  // for the original fix — applied here too for parity.
  bool _disposed = false;
  void _safeNotify() {
    if (_disposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  String? _roomId;
  String? _sessionId;
  String? get sessionId => _sessionId;
  bool _isOwner = false;
  String _error = '';
  final Set<String> _awayPlayerIds = {};
  final Set<String> _readyForNext = {};

  /// Turn-selection policy — see turn_queue.dart (shared with
  /// TodGameProvider/MemeGameProvider). Lazily (re)built whenever the
  /// current playerOrder's id set differs from what it already reflects
  /// — NHIE re-establishes/restores its engine from several call sites
  /// (fresh start, resume, host-migration reconnect, DB resync), so a
  /// lazy getter is more robust here than trying to seed it at every one
  /// of those individually; playerOrder itself is still fixed for the
  /// life of the session, so in practice this only ever builds once.
  TurnQueue? _turnQueueCache;
  TurnQueue get _turnQueue {
    final order = state?.playerOrder ?? const <String>[];
    final cached = _turnQueueCache;
    final sameIds =
        cached != null &&
        cached.order.length == order.length &&
        cached.order.toSet().containsAll(order);
    if (!sameIds) _turnQueueCache = TurnQueue(order);
    return _turnQueueCache!;
  }

  /// Ids this provider currently believes are game-muted — the "last
  /// known" side of [syncMutedPlayers]'s edge detection.
  final Set<String> _knownMutedIds = {};

  /// Reconciles the CURRENT set of game-muted player ids against what
  /// this provider last knew — see TodGameProvider.syncMutedPlayers's
  /// identical rationale. NHIE has no concept of the current
  /// (revealer) player being mid-action the way ToD does (every player,
  /// revealer included, votes independently — see never_have_i_ever_
  /// engine.dart's _handleVote, gated only on playerOrder membership,
  /// never currentPlayerId), so unlike ToD this never needs to force an
  /// immediate turn-advance: a muted id's own vote is already auto-
  /// filled (see _autoFillAwayPlayers, which already treats isGameMuted
  /// exactly like away), and the NEXT round's revealer selection simply
  /// excludes them (via _turnQueue.nextEligible in ownerAdvanceTurn). A
  /// newly-unmuted id rejoins the active rotation at the END via
  /// [TurnQueue.markReturned] — never their original fixed-order slot.
  void syncMutedPlayers(Set<String> mutedIds) {
    final newlyMuted = mutedIds.difference(_knownMutedIds);
    final newlyUnmuted = _knownMutedIds.difference(mutedIds);
    if (newlyMuted.isEmpty && newlyUnmuted.isEmpty) return;
    _knownMutedIds
      ..clear()
      ..addAll(mutedIds);
    for (final id in newlyUnmuted) {
      _turnQueue.markReturned(id);
    }
    _safeNotify();
  }

  // ── Game session ready barrier ──────────────────────────────────────
  // See TodGameProvider's identical block for the full root-cause
  // rationale — same fix, same architecture, applied here too.
  String _lifecycleState = 'active';
  String get lifecycleState => _lifecycleState;
  // A room-level host-disconnect pause (RoomProvider.isPausedForHostReconnect)
  // is not itself a game_sessions.lifecycle_state transition broadcast by
  // anyone — the owner is the one who's absent, so nothing is running to
  // broadcast it — but every action gate in this provider keys off this
  // single getter, so folding the room's pause signal in here is what
  // actually makes "paused" reject actions at the engine level instead of
  // only visually overlaying the screen. roomProvider already updates
  // near-instantly off the 'pause' broadcast and its own poll fallback —
  // no extra round trip needed.
  bool get isSessionActive =>
      _lifecycleState == 'active' &&
      roomProvider?.isPausedForHostReconnect != true;
  bool get isSessionStarting => _lifecycleState == 'starting';
  List<String> _expectedReadyPlayerIds = const [];
  final _readyConfirmedUserIds = <String>{};
  int get readyConfirmedCount => _readyConfirmedUserIds.length;
  int get expectedReadyCount => _expectedReadyPlayerIds.length;
  Timer? _readyBarrierTimeout;
  Timer? _sessionActivePollTimer;

  // Shared between _NhieGameScreenState (owns the realtime listeners) and
  // _GameBodyState (owns the PopScope) via this single provider instance,
  // so a programmatic pop triggered by a realtime event (e.g. onGameEnded)
  // doesn't get misread by PopScope as the user backing out, which would
  // incorrectly open the Quit Game confirmation dialog.
  bool isNavigatingAway = false;

  NhieLoadState get loadState => _loadState;
  NhieState? get state => _engine?.currentState as NhieState?;
  String get userId => _userId;
  bool get isOwner => _isOwner;
  bool get canModerate => _isOwner || isModerator;

  bool get allPlayersVoted {
    final s = state;
    if (s == null) return true;
    // Item 1/4/5 root-cause fix: "ready to show results and advance"
    // really means "the round is closed" — which the engine already
    // signals via isVotingOpen, flipped false in exactly the two cases
    // that mean the round is over: every player voted (_handleVote) or
    // the timer expired with some players never responding
    // (_onTimerExpired). The old `votes.length >= playerOrder.length`
    // check could never become true again once even one player timed
    // out (a skipped player never gets a votes/voteEntries entry by
    // design), permanently disabling the "Next Card"/"Continue" action
    // for the whole table.
    return !s.isVotingOpen;
  }

  int get votedCount => state?.votes.length ?? 0;
  int get playerCount => state?.playerOrder.length ?? 1;

  /// Live count of players still actually in the game (excludes
  /// kicked/banned/left players) — unlike [playerCount], which is frozen at
  /// game start since `playerOrder` never shrinks for the life of a session.
  int get activePlayerCount => (state?.playerOrder ?? const <String>[])
      .where((id) => !_effectiveAwayIds.contains(id))
      .length;
  String get error => _error;
  Set<String> get awayPlayerIds => _effectiveAwayIds;

  /// Away/gone ids derived from the room's durable, backend-synced member
  /// list — see the identical getter in TodGameProvider for the full
  /// rationale. Unlike [_awayPlayerIds] (fed only by a one-shot moderation
  /// broadcast this specific client happened to be connected for), this
  /// reflects a fresh fetch + realtime `room_members` subscription.
  Set<String> get _durableAwayIds {
    final rp = roomProvider;
    final order = state?.playerOrder;
    if (rp == null || order == null) return const {};
    final members = {for (final m in rp.members) m.userId: m};
    return order.where((id) {
      final m = members[id];
      // isGameMuted: a moderator-muted player already can't submit an
      // action, but without excluding them here too the engine could
      // still select their turn and nothing could ever complete it — see
      // TodGameProvider's identical fix for the full rationale.
      return m == null || m.isAway || m.isDisconnected || m.isGameMuted;
    }).toSet();
  }

  Set<String> get _effectiveAwayIds => _awayPlayerIds.union(_durableAwayIds);

  Set<String> get readyForNext => Set.unmodifiable(_readyForNext);
  bool get hasMarkedReady => _readyForNext.contains(_userId);

  // See the identical getter in TodGameProvider for the full rationale —
  // exempts a permissioned moderator from being counted among "others who
  // must ready up", symmetric with the owner's own existing exemption.
  // Must explicitly exclude the owner since memberHasPermission already
  // ORs in isOwner.
  bool _isExemptModerator(String id) {
    final rp = roomProvider;
    if (rp == null || id == rp.room?.ownerId) return false;
    return rp.memberHasPermission(id, 'advance_turn') ||
        rp.memberHasPermission(id, 'skip_turn');
  }

  bool get allOthersReady {
    final others = (state?.playerOrder ?? const <String>[])
        .where(
          (id) =>
              id != _userId &&
              !_effectiveAwayIds.contains(id) &&
              !_isExemptModerator(id),
        )
        .toSet();
    final result = others.isEmpty || _readyForNext.containsAll(others);
    AppLogger.debug(
      '[READY-DEBUG][nhie] allOthersReady: others=$others '
      'readyForNext=$_readyForNext away=$_effectiveAwayIds -> $result',
    );
    return result;
  }

  void markPlayerAway(String userId, {bool forGood = false}) {
    _awayPlayerIds.add(userId);
    if (_isOwner && _engine != null) {
      _autoFillAwayPlayers();
      _safeNotify();
      _broadcastState();
    }
    _safeNotify();
  }

  /// playerOrder is fixed for the life of the session — a kicked/left
  /// player is never removed from it, only added to _awayPlayerIds. Vote
  /// completion is a simple count against playerOrder.length, so an away
  /// player who never votes would otherwise block every round from here on
  /// (not just the one they left during). Auto-casts on their behalf each
  /// round; _handleVote itself is idempotent per user, so calling this
  /// repeatedly across rounds is safe.
  void _autoFillAwayPlayers() {
    if (!_isOwner || _engine == null || _effectiveAwayIds.isEmpty) return;
    final s = _engine!.currentState as NhieState;
    if (!s.isVotingOpen) return;
    for (final uid in _effectiveAwayIds) {
      if (!s.voteEntries.containsKey(uid)) {
        _engine!.handleEvent(
          NhieVoteEvent(
            userId: uid,
            ts: DateTime.now().millisecondsSinceEpoch,
            haveI: false,
          ),
        );
      }
    }
  }

  void markPlayerReturned(String userId) {
    _awayPlayerIds.remove(userId);
    _safeNotify();
  }

  /// Owner-only early termination (e.g. every other player has left the
  /// game) — forces the engine to game-over and lets the existing
  /// `_broadcastState` isGameOver branch persist/notify as usual.
  Future<void> endGame() async {
    if (!_isOwner || _engine == null) return;
    _engine!.forceEnd();
    _broadcastState();
    _safeNotify();
  }

  /// ROOT CAUSE of "ban removes users correctly, but kick does not":
  /// this used to only mark the target away (broadcasting 'game_kick',
  /// which RoomProvider._handleModeration only ever treats as "flip
  /// isAway=true" — never removing them from room_members, never firing
  /// RoomLifecycleEvent for the target). banPlayerFromGame (below) never
  /// had this gap — it always called the real room-level ban RPC and
  /// broadcast a genuine 'ban' event. Kick now does the same.
  Future<void> kickPlayerFromGame(String targetUserId) async {
    if (!canModerate || _roomId == null) return;
    markPlayerAway(targetUserId, forGood: true);
    try {
      await sl.roomRepository.kickMember(_roomId!, targetUserId);
    } catch (e) {
      AppLogger.warning('NhieProvider: kickPlayerFromGame RPC failed: $e');
    }
    await _realtime.broadcastModeration(_roomId!, {
      'type': 'kick',
      'target_user_id': targetUserId,
      'by_name': _displayName,
    });
  }

  Future<void> banPlayerFromGame(String targetUserId, {String? reason}) async {
    if (!canModerate || _roomId == null) return;
    markPlayerAway(targetUserId, forGood: true);
    await sl.roomRepository.banMember(
      roomId: _roomId!,
      targetUserId: targetUserId,
      bannedBy: _userId,
      reason: reason,
    );
    await _realtime.broadcastModeration(_roomId!, {
      'type': 'ban',
      'target_user_id': targetUserId,
      'reason': reason,
    });
  }

  Future<void> initAsOwner({
    required String roomId,
    required String packId,
    required List<String> playerIds,
    required Map<String, String> displayNames,
    required GameConfig config,
    // True only for a genuine, fresh "Start Game" press — see
    // TodGameScreen.isNewGameStart's doc comment. Skips the resume lookup
    // below entirely so a brand-new game never resurrects a previous,
    // already-finished session for this room.
    bool isNewGame = false,
  }) async {
    _roomId = roomId;
    _isOwner = true;
    // Item 18.1 root cause: this was never set on the owner path — only
    // initAsFollower assigned it — so every `config`/`config?.` read on
    // the OWNER'S OWN client (this._config, via the public `config`
    // getter below) was silently null for the room owner's entire
    // session: timerEnabled/turnTimerSeconds, allowSkip, etc. The
    // ENGINE's own internal copy of config was always correct (it's
    // constructed with the real `config` param further down), which is
    // why non-owner clients — whose initAsFollower already set this —
    // and the broadcast round state itself were both fine; only the
    // owner's local UI reads of `game.config` were affected.
    _config = config;
    _loadState = NhieLoadState.loading;
    _safeNotify();
    try {
      var todCards = await TodRepository.instance.loadCardsFromCache(
        packId: packId,
        language: config.language,
      );
      if (todCards.isEmpty) {
        final rows = await Supabase.instance.client
            .from('pack_cards')
            .select('id, content, card_type, difficulty, sort_order')
            .eq('pack_id', packId)
            .order('sort_order');
        todCards = (rows as List).map((r) {
          String text = '';
          final raw = r['content'];
          if (raw is Map) {
            final m = Map<String, dynamic>.from(raw as Map);
            text =
                (m[config.language] ??
                        m['en'] ??
                        m.values.whereType<String>().firstOrNull ??
                        '')
                    as String;
          } else if (raw is String) {
            try {
              final d = jsonDecode(raw);
              if (d is Map)
                text = (d[config.language] ?? d['en'] ?? '') as String;
              else
                text = raw;
            } catch (_) {
              text = raw;
            }
          }
          final rawDiff = r['difficulty'];
          final diffStr = rawDiff is Map
              ? (rawDiff['en'] ?? rawDiff.values.first ?? 'mild').toString()
              : rawDiff?.toString() ?? 'mild';
          return TodCard(
            id: r['id'] as String,
            content: text,
            type: TodCardType.truth,
            difficulty: TodDifficulty.values.firstWhere(
              (d) => d.name == diffStr,
              orElse: () => TodDifficulty.mild,
            ),
          );
        }).toList();
      }
      final cards = todCards.map((c) {
        var t = c.content;
        for (final p in ['Never have I ever ', 'never have I ever ']) {
          if (t.startsWith(p)) {
            t = t.substring(p.length);
            break;
          }
        }
        if (t.isNotEmpty) t = t[0].toUpperCase() + t.substring(1);
        return NhieCard(id: c.id, content: t, difficulty: c.difficulty.name);
      }).toList();
      _engine = NeverHaveIEverEngine(config, cards: cards);

      Map<String, dynamic>? existing;
      if (!isNewGame) {
        // Scoped to THIS game type — never treat a stale session from a
        // different, previously-played game type in the same room as
        // "the" existing session to resume/inspect. Confirmed root cause
        // of "starting NHIE/Meme after ToD gets stuck loading then bounces
        // to lobby": an unscoped lookup here (or the equivalent unscoped
        // create_game_session fallback, fixed separately server-side)
        // could latch onto a still-active/paused session belonging to an
        // entirely different game.
        existing = await Supabase.instance.client
            .from('game_sessions')
            .select('id, state_snapshot, game_type, lifecycle_state, status')
            .eq('room_id', roomId)
            .eq('game_type', 'never_have_i_ever')
            .eq('status', 'active')
            .order('started_at', ascending: false)
            .limit(1)
            .maybeSingle();
        // Nothing active — a reconnecting owner whose game already ended
        // should still land on the results screen for that session, not
        // silently start a brand-new game. Still scoped to this game
        // type — a completed/aborted session from a DIFFERENT game must
        // fall through to "create new" below, not be inspected here at
        // all.
        existing ??= await Supabase.instance.client
            .from('game_sessions')
            .select('id, state_snapshot, game_type, lifecycle_state, status')
            .eq('room_id', roomId)
            .eq('game_type', 'never_have_i_ever')
            .order('started_at', ascending: false)
            .limit(1)
            .maybeSingle();

        // NO session row found on this FIRST lookup: this is AMBIGUOUS,
        // not proof the game ended — RLS/timing/reconnect-state can all
        // produce a transient miss on this client's own read even though
        // the session row genuinely still exists elsewhere. initAsFollower
        // (_checkSessionLifecycleOnJoin) already tolerates this exact
        // ambiguity for a non-owner (see its own comment: a null lookup
        // "doesn't prove there's no session") — this mirrors that same
        // principle for the owner instead of treating a single miss as
        // definitive. CONFIRMED ROOT CAUSE of a real regression: a
        // reconnecting owner's transient lookup miss used to be enough,
        // on its own, to write rooms.status = waiting for the WHOLE
        // ROOM — evicting every other still-actively-playing client the
        // instant they discovered it (via the 5s reconcile poll, or
        // near-instantly via ANY unrelated 'join' broadcast triggering
        // _refreshMembers).
        if (existing == null) {
          String? liveRoomStatus;
          try {
            final row = await Supabase.instance.client
                .from('rooms')
                .select('status')
                .eq('id', roomId)
                .maybeSingle();
            liveRoomStatus = row?['status'] as String?;
          } catch (e) {
            AppLogger.warning(
              'NhieProvider: owner reconnect room-status re-check failed: $e',
            );
          }
          // The room itself still claiming in_game/paused is authoritative
          // evidence a session MUST exist — retry the exact same lookup
          // once more instead of assuming termination from a single miss.
          if (liveRoomStatus == 'in_game' || liveRoomStatus == 'paused') {
            existing = await Supabase.instance.client
                .from('game_sessions')
                .select(
                  'id, state_snapshot, game_type, lifecycle_state, status',
                )
                .eq('room_id', roomId)
                .eq('game_type', 'never_have_i_ever')
                .order('started_at', ascending: false)
                .limit(1)
                .maybeSingle();
          }
          AppLogger.info(
            'Owner reconnect session check: room=$roomId user=$_userId '
            'isNewGame=$isNewGame session=${existing?['id']} '
            'status=${existing?['status']} roomStatus=$liveRoomStatus '
            'decision=${existing != null ? 'resume' : 'preserve_room_state_no_action'}',
          );
          if (existing == null) {
            // Still nothing to resume even after the re-check — but this
            // is NOT confirmed termination (only a genuinely 'aborted'
            // session row below is), so the room and every other player
            // are left completely untouched: no status write, no
            // broadcast, nobody else is affected. Only this owner's own
            // screen shows a recoverable error.
            _error = kSessionEndedErrorMessage;
            _loadState = NhieLoadState.error;
            _safeNotify();
            return;
          }
        }

        // 'aborted' means this session was deliberately closed (auto-end,
        // host-disconnect timeout, quit) — not the engine's own natural
        // completion. This IS confirmed, authoritative evidence of
        // termination (unlike a null lookup above) — self-heal the room
        // status and send the owner back to the lobby. Only 'active'
        // (still live) or 'completed' (natural end — renders the results
        // screen below) are valid.
        final existingStatus = existing['status'] as String?;
        if (existingStatus == 'aborted') {
          AppLogger.warning(
            'Owner reconnect session check: room=$roomId user=$_userId '
            'session=${existing['id']} status=$existingStatus '
            'decision=confirmed_game_ended',
          );
          try {
            await sl.roomRepository.updateStatus(roomId, RoomStatus.waiting);
          } catch (_) {}
          _error = kSessionEndedErrorMessage;
          _loadState = NhieLoadState.error;
          _safeNotify();
          return;
        }
      }
      final snapshotGameType = existing?['game_type'] as String?;
      Map<String, dynamic>? existingSnapshot;
      if (snapshotGameType == 'never_have_i_ever') {
        existingSnapshot = existing?['state_snapshot'] as Map<String, dynamic>?;
      }

      if (existing != null &&
          existingSnapshot != null &&
          existingSnapshot.isNotEmpty) {
        final raw = existingSnapshot;
        if (raw['scores'] is Map) {
          raw['scores'] = (raw['scores'] as Map).map(
            (k, v) => MapEntry(k as String, v is num ? v.toInt() : 0),
          );
        }
        _sessionId = existing['id'] as String;
        _engine!.restoreFromSnapshot(raw);
        // Item 3 root-cause fix: this resume branch (hit whenever
        // initAsOwner finds an already-active session — reconnect, host
        // migration, or any remount of the owner's own screen after the
        // very first navigation) restored round state but never
        // re-derived the local timer ticker from it. _timerRemaining/
        // _timerIsRunning stayed at their initial zero/false values —
        // frozen — until some UNRELATED event (a vote, an advance, a
        // broadcast) happened to call _syncTimer() elsewhere, which is
        // exactly the "doesn't count down until you interact, then jumps
        // forward" symptom: that later call correctly re-derives
        // _timerRemaining from `now - timerStartedAt`, jumping straight
        // to the real current value. Meme's own initAsOwner already did
        // this correctly in its own resume branch; NHIE's simply never
        // had it.
        _syncTimer();
        _lifecycleState = existing['lifecycle_state'] as String? ?? 'active';
        AppLogger.info(
          'NhieProvider: resumed existing session $_sessionId '
          'lifecycle=$_lifecycleState',
        );
      } else {
        // Never trust the playerIds this call was made with for a
        // genuinely new session — RoomProvider.members it was built from
        // could already be stale by the time execution reaches here (the
        // Start Game flow has several awaits before this point). A player
        // who left during that window would otherwise be baked into the
        // new session's player_ids/turn order/ready barrier, which would
        // then wait on a confirmation or a turn from someone no longer in
        // the room — "admin enters loading forever". Re-derive who's
        // actually here right now, immediately before creating the
        // session. See TodRepository.fetchActiveMemberIds's identical
        // rationale.
        var freshPlayerIds = playerIds;
        try {
          final rows = await Supabase.instance.client
              .from('room_members')
              .select('user_id')
              .eq('room_id', roomId)
              .isFilter('left_at', null)
              .neq('role', 'spectator');
          final fetched = (rows as List)
              .map((r) => r['user_id'] as String)
              .toList();
          if (fetched.isNotEmpty) freshPlayerIds = fetched;
        } catch (e) {
          AppLogger.warning(
            'NhieProvider: fresh member fetch failed, falling back to '
            'passed-in playerIds: $e',
          );
        }

        _engine!.init(freshPlayerIds);
        _syncTimer();
        _lifecycleState = 'starting';
        // Deliberately NOT wrapped in its own try/catch — a swallowed
        // failure here previously left _sessionId null while execution
        // fell through to _loadState = ready and, below,
        // `if (_lifecycleState == 'starting' && _sessionId != null)`
        // silently skipped _startReadyBarrier entirely: no ready barrier
        // ever starts, _lifecycleState is permanently stuck at 'starting'
        // (never reaches activate_game_session), and the screen's own
        // `isSessionStarting` gate shows the "waiting for players" spinner
        // forever with no error and no recovery path — exactly the
        // reported "NHIE/Meme remain on loading screen forever", and
        // exactly what ToD's equivalent (TodRepository.createSession, no
        // swallowing catch of its own) does NOT do — it propagates to the
        // outer catch below, which already correctly sets _error/
        // NhieLoadState.error.
        //
        // game_sessions has no permissive INSERT policy — creation only
        // ever happens through this SECURITY DEFINER RPC, which also
        // enforces that the caller is the room owner or an
        // explicitly-permitted moderator.
        final id = await Supabase.instance.client.rpc(
          'create_game_session',
          params: {
            'p_room_id': roomId,
            'p_pack_id': packId,
            'p_game_type': 'never_have_i_ever',
            'p_player_ids': freshPlayerIds,
            'p_max_rounds': config.maxRounds,
            'p_turn_timer_secs': config.turnTimerSeconds,
            'p_allow_skip': config.allowSkip,
            'p_allow_spicy': config.allowSpicy,
            'p_state_snapshot': _engine!.serializeState(),
            // Items 2/3/8 — NHIE's engine has no repeat mode at all (every
            // card is always unique within a game — see
            // never_have_i_ever_engine.dart's _usedCardIds); always true,
            // so the server enforces Max Rounds <= actual card supply.
            'p_unique_cards': true,
          },
        );
        _sessionId = id as String;
        AppLogger.info(
          'SESSION_CREATED room=$roomId session=$_sessionId '
          'players=$freshPlayerIds',
        );

        // GAME SESSION CREATED/AVAILABLE: the game_sessions row provably
        // exists now — safe to release every other client from the
        // STARTING_GAME lock (LobbyScreen's _GameStartingLock,
        // RoomProvider._handleGameSessionReady) and let _syncGameRoute
        // carry them into this game screen. The broadcast covers
        // currently-connected clients immediately; the DB write covers
        // anyone who reconnects, or was slow to subscribe, before it
        // arrives — either alone is sufficient, this is belt-and-suspenders.
        _realtime.broadcastRoomEvent(roomId, {
          'type': 'game_session_ready',
        }).ignore();
        try {
          await sl.roomRepository.updateStatus(roomId, RoomStatus.inGame);
        } catch (e) {
          AppLogger.warning(
            'NhieProvider: failed to flip room to in_game after '
            'session creation: $e',
          );
        }
      }

      if (_sessionId != null) {
        try {
          final customCards = await TodRepository.instance.loadCustomCards(
            _sessionId!,
          );
          for (final c in customCards) {
            _engine!.injectCard(
              NhieCard(id: c.id, content: c.content, difficulty: 'mild'),
            );
          }
          if (customCards.isNotEmpty) {
            AppLogger.info(
              'NhieProvider: merged ${customCards.length} custom cards into deck',
            );
          }
        } catch (e) {
          AppLogger.warning('NhieProvider: custom card load failed: $e');
        }
      }

      _loadState = _engine!.isGameOver
          ? NhieLoadState.gameOver
          : NhieLoadState.ready;
      _safeNotify();
      _broadcastState();

      if (_lifecycleState == 'starting' && _sessionId != null) {
        _startReadyBarrier(playerIds);
      }
    } catch (e) {
      _error = e.toString();
      _loadState = NhieLoadState.error;
      AppLogger.error('NhieProvider: init failed', error: e);
      _safeNotify();
      // Only reaches here with _sessionId still null when session creation
      // itself never completed (a reconnect that already had _sessionId
      // set from an existing row fails BEFORE any of this, since that
      // assignment is the very first thing the resume branch does) — see
      // _revertRoomFromStartingOnFailure's doc comment for why this is
      // gated on the room's live status rather than assumed.
      if (_sessionId == null) {
        await _revertRoomFromStartingOnFailure(roomId);
      }
    }
  }

  /// STARTUP FAILURE (see initAsOwner's catch block, its only caller): a
  /// genuine, definitive failure to create a new game session must not
  /// leave the room permanently locked in STARTING_GAME. Re-reads the
  /// room's live status rather than assuming it — this same failure path
  /// can also be reached mid-reconnect (an already in_game room), where
  /// forcing it back to `waiting` would wrongly evict every other player
  /// from an otherwise-fine ongoing game just because of e.g. a transient
  /// card-load error on the reconnecting owner's client. Only a room still
  /// sitting in `starting` — i.e. one that never got the chance to be
  /// unlocked — is safe to release here.
  Future<void> _revertRoomFromStartingOnFailure(String roomId) async {
    try {
      final row = await Supabase.instance.client
          .from('rooms')
          .select('status')
          .eq('id', roomId)
          .maybeSingle();
      if (row != null && row['status'] == 'starting') {
        await sl.roomRepository.updateStatus(roomId, RoomStatus.waiting);
      }
    } catch (_) {}
  }

  // ── Ready barrier implementation (see TodGameProvider for full
  // rationale — identical design, applied here too) ──────────────────
  void _startReadyBarrier(List<String> playerIds) {
    _expectedReadyPlayerIds = playerIds;
    _readyConfirmedUserIds.clear();
    _confirmReady();
    _readyBarrierTimeout?.cancel();
    _readyBarrierTimeout = Timer(const Duration(seconds: 10), () {
      if (_lifecycleState == 'starting') {
        AppLogger.warning(
          'NhieProvider: ready barrier TIMEOUT room=$_roomId '
          'session=$_sessionId confirmed=$_readyConfirmedUserIds '
          'expected=$_expectedReadyPlayerIds — activating anyway',
        );
        _activateSession();
      }
    });
  }

  Future<void> _confirmReady() async {
    if (_sessionId == null || _roomId == null) return;
    try {
      await Supabase.instance.client.rpc(
        'confirm_game_session_ready',
        params: {'p_session_id': _sessionId},
      );
    } catch (e) {
      AppLogger.warning('NhieProvider: confirmSessionReady failed: $e');
    }
    AppLogger.info(
      'PLAYER_JOINED_SESSION room=$_roomId session=$_sessionId user=$_userId',
    );
    if (_isOwner) {
      handleSessionReadyEvent(_userId);
    } else {
      _realtime.broadcastRoomEvent(_roomId!, {
        'type': 'session_ready',
        'session_id': _sessionId,
        'user_id': _userId,
      }).ignore();
    }
  }

  void handleSessionReadyEvent(String userId) {
    if (!_isOwner || _lifecycleState != 'starting') return;
    if (!_expectedReadyPlayerIds.contains(userId)) return;
    _readyConfirmedUserIds.add(userId);
    AppLogger.info(
      'PLAYER_READY room=$_roomId session=$_sessionId user=$userId '
      'confirmed=${_readyConfirmedUserIds.length}/${_expectedReadyPlayerIds.length}',
    );
    _safeNotify();
    if (_expectedReadyPlayerIds.every(_readyConfirmedUserIds.contains)) {
      _activateSession();
    }
  }

  Future<void> _activateSession() async {
    if (_lifecycleState != 'starting') return;
    _readyBarrierTimeout?.cancel();
    _lifecycleState = 'active';
    AppLogger.info('SESSION_ACTIVE room=$_roomId session=$_sessionId');
    if (_isOwner && _sessionId != null) {
      Supabase.instance.client
          .rpc('activate_game_session', params: {'p_session_id': _sessionId})
          .then((_) {}, onError: (e) {});
    }
    _broadcastState();
    _safeNotify();
  }

  void _pollForSessionActive() {
    _sessionActivePollTimer?.cancel();
    var attempts = 0;
    _sessionActivePollTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      attempts++;
      if (_isOwner || _lifecycleState != 'starting' || _sessionId == null) {
        timer.cancel();
        return;
      }
      if (attempts > 10) {
        timer.cancel();
        AppLogger.warning(
          'NhieProvider: session_active poll gave up room=$_roomId '
          'session=$_sessionId',
        );
        _error = 'Could not confirm the game started. Please rejoin.';
        _loadState = NhieLoadState.error;
        _safeNotify();
        return;
      }
      try {
        final row = await Supabase.instance.client
            .from('game_sessions')
            .select('lifecycle_state')
            .eq('id', _sessionId!)
            .maybeSingle();
        if (row?['lifecycle_state'] == 'active') {
          timer.cancel();
          _lifecycleState = 'active';
          AppLogger.info(
            'SESSION_ACTIVE (via poll) room=$_roomId session=$_sessionId '
            'user=$_userId',
          );
          _safeNotify();
        }
      } catch (e) {
        AppLogger.warning('NhieProvider: session_active poll failed: $e');
      }
    });
  }

  Timer? _syncTimeoutTimer;
  String? _packId;
  GameConfig? _config;
  GameConfig? get config => _config;

  // ── Round timer (item 1) ─────────────────────────────────────────────
  // Same architecture as TodGameProvider._syncTimer — the DEADLINE lives
  // in state.timerStartedAt (set/cleared by the engine), never in this
  // local countdown value, so a rebuild/resubscribe/reconnect never
  // "restarts" anything: it just re-derives remaining time from
  // `now - timerStartedAt`. Only the OWNER's local ticker ever dispatches
  // the timeout event; everyone else's ticker is purely cosmetic.
  Timer? _timerTicker;
  int _timerRemaining = 0;
  bool _timerIsRunning = false;
  int get timerRemaining => _timerRemaining;
  bool get timerIsRunning => _timerIsRunning;

  void _syncTimer() {
    _timerTicker?.cancel();
    if (!isSessionActive) {
      _timerIsRunning = false;
      return;
    }
    final s = state;
    if (s == null) return;

    final timerEnabled =
        s.timerStartedAt != null && (_config?.timerEnabled ?? false);
    if (!timerEnabled) {
      _timerRemaining = 0;
      _timerIsRunning = false;
      return;
    }

    final elapsed =
        (DateTime.now().millisecondsSinceEpoch - s.timerStartedAt!) ~/ 1000;
    _timerRemaining = (_config!.turnTimerSeconds - elapsed).clamp(
      0,
      _config!.turnTimerSeconds,
    );
    _timerIsRunning = _timerRemaining > 0;
    if (!_timerIsRunning) return;

    _timerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isSessionActive) {
        _timerTicker?.cancel();
        return;
      }
      if (_timerRemaining > 0) {
        _timerRemaining--;
        _safeNotify();
      }
      if (_timerRemaining <= 0) {
        _timerTicker?.cancel();
        _timerIsRunning = false;
        if (_isOwner && _engine != null) {
          _engine!.handleEvent(
            NhieTimerExpiredEvent(
              userId: _userId,
              ts: DateTime.now().millisecondsSinceEpoch,
            ),
          );
          if (_engine!.isGameOver) _loadState = NhieLoadState.gameOver;
          _safeNotify();
          _broadcastState();
        }
      }
    });
  }

  // See the identical watchdog in TodGameProvider for the full rationale:
  // realtime broadcast has no delivery guarantee, and nothing previously
  // detected a *missing* update on an otherwise-healthy socket — a
  // follower just stayed stuck. This self-heals via resync request, then a
  // direct DB read if that doesn't land either.
  DateTime _lastStateReceivedAt = DateTime.now();
  Timer? _staleWatchdog;
  Timer? _staleRecoveryTimer;
  DateTime? _lastStaleRecoveryAttempt;
  static const _staleThreshold = Duration(seconds: 15);
  static const _staleRecoveryCooldown = Duration(seconds: 10);

  void _startStaleWatchdog() {
    _staleWatchdog?.cancel();
    _staleWatchdog = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_isOwner || state == null || _roomId == null) return;
      if (_engine != null && _engine!.isGameOver) return;
      final sinceLastState = DateTime.now().difference(_lastStateReceivedAt);
      if (sinceLastState <= _staleThreshold) return;

      final lastAttempt = _lastStaleRecoveryAttempt;
      if (lastAttempt != null &&
          DateTime.now().difference(lastAttempt) < _staleRecoveryCooldown) {
        return;
      }
      _lastStaleRecoveryAttempt = DateTime.now();
      AppLogger.warning(
        'NhieProvider: no state broadcast for ${sinceLastState.inSeconds}s — requesting resync',
      );
      _realtime.broadcastSyncRequest(_roomId!, _userId, 0).ignore();

      // Tracked (not a bare nested Timer(...)) so dispose() can actually
      // cancel an already-scheduled instance — previously this could fire
      // after dispose using a stale captured _roomId and issue a DB query
      // on behalf of an already-disposed provider.
      _staleRecoveryTimer?.cancel();
      _staleRecoveryTimer = Timer(const Duration(seconds: 4), () {
        if (DateTime.now().difference(_lastStateReceivedAt) > _staleThreshold) {
          AppLogger.warning(
            'NhieProvider: resync request unanswered — reading state from DB',
          );
          _tryLoadSnapshotFromDb(_roomId!);
        }
      });
    });
  }

  void initAsFollower(String roomId, {String? packId, GameConfig? config}) {
    _roomId = roomId;
    _packId = packId;
    _config = config;
    _isOwner = false;
    _loadState = NhieLoadState.loading;
    _syncTimeoutTimer?.cancel();
    _syncTimeoutTimer = Timer(const Duration(seconds: 8), () async {
      if (state == null) await _tryLoadSnapshotFromDb(roomId);
    });
    _lastStateReceivedAt = DateTime.now();
    _startStaleWatchdog();
    _safeNotify();
    // Fire-and-forget: this screen's normal path (receiving the owner's
    // state broadcasts) already learns _sessionId/lifecycle_state from
    // the payload (see onStateBroadcast) — this is only for a
    // reconnecting client that might otherwise sit through the whole
    // 'starting' phase with no broadcast to read it from yet.
    _checkSessionLifecycleOnJoin(roomId);
  }

  Future<void> _checkSessionLifecycleOnJoin(String roomId) async {
    try {
      final row = await Supabase.instance.client
          .from('game_sessions')
          .select('id, lifecycle_state, status')
          .eq('room_id', roomId)
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
      // 'aborted' is unambiguous (that row only exists after a close
      // already fully committed) — bail to the lobby exactly like
      // initAsOwner does. A null row is deliberately left alone: on a
      // genuinely fresh game start the owner's createSession() may not
      // have committed yet when this lookup runs, so null here doesn't
      // prove there's no session — the live state broadcast remains the
      // real source of truth for that case.
      if (row != null && row['status'] == 'aborted') {
        AppLogger.warning(
          'SESSION_ENDED room=$roomId session=${row['id']} '
          'reason=follower_found_aborted_session',
        );
        _error = kSessionEndedErrorMessage;
        _loadState = NhieLoadState.error;
        _safeNotify();
        return;
      }
      _sessionId ??= row?['id'] as String?;
      final lifecycle = row?['lifecycle_state'] as String?;
      if (lifecycle != null) _lifecycleState = lifecycle;
      AppLogger.info(
        'PLAYER_JOINED_SESSION room=$roomId session=$_sessionId '
        'user=$_userId lifecycle=$_lifecycleState',
      );
      if (_lifecycleState == 'starting') {
        _confirmReady();
        _pollForSessionActive();
      }
      _safeNotify();
    } catch (e) {
      AppLogger.warning(
        'NhieProvider: _checkSessionLifecycleOnJoin failed: $e',
      );
    }
  }

  /// Called when [RoomProvider.isOwner] changes mid-game (room ownership
  /// transferred). A follower never runs a local [_engine] — it only tracks
  /// [state] from broadcasts — so becoming the new authoritative owner
  /// means constructing one from the last-synced state before this provider
  /// can start applying/broadcasting actions.
  Future<void> applyOwnershipChange(bool amOwner) async {
    if (amOwner == _isOwner) return;
    if (!amOwner) {
      _isOwner = false;
      _lastStateReceivedAt = DateTime.now();
      _startStaleWatchdog();
      _safeNotify();
      return;
    }
    if (_engine == null ||
        state == null ||
        _packId == null ||
        _config == null) {
      return;
    }
    try {
      final cards = await _loadCards(_packId!, _config!);
      _engine = NeverHaveIEverEngine(_config!, cards: cards);
      _engine!.restoreFromSnapshot(state!.toMap());
    } catch (e) {
      AppLogger.error(
        'NhieProvider: ownership handoff engine build failed: $e',
      );
      return;
    }
    _isOwner = true;
    _safeNotify();
  }

  /// Loads this pack's deck as [NhieCard]s — the same conversion
  /// [initAsOwner] performs, reused here for the ownership mid-game handoff.
  Future<List<NhieCard>> _loadCards(String packId, GameConfig config) async {
    var todCards = await TodRepository.instance.loadCardsFromCache(
      packId: packId,
      language: config.language,
    );
    if (todCards.isEmpty) {
      final rows = await Supabase.instance.client
          .from('pack_cards')
          .select('id, content, card_type, difficulty, sort_order')
          .eq('pack_id', packId)
          .order('sort_order');
      todCards = (rows as List).map((r) {
        String text = '';
        final raw = r['content'];
        if (raw is Map) {
          final m = Map<String, dynamic>.from(raw as Map);
          text =
              (m[config.language] ??
                      m['en'] ??
                      m.values.whereType<String>().firstOrNull ??
                      '')
                  as String;
        } else if (raw is String) {
          try {
            final d = jsonDecode(raw);
            if (d is Map)
              text = (d[config.language] ?? d['en'] ?? '') as String;
            else
              text = raw;
          } catch (_) {
            text = raw;
          }
        }
        final rawDiff = r['difficulty'];
        final diffStr = rawDiff is Map
            ? (rawDiff['en'] ?? rawDiff.values.first ?? 'mild').toString()
            : rawDiff?.toString() ?? 'mild';
        return TodCard(
          id: r['id'] as String,
          content: text,
          type: TodCardType.truth,
          difficulty: TodDifficulty.values.firstWhere(
            (d) => d.name == diffStr,
            orElse: () => TodDifficulty.mild,
          ),
        );
      }).toList();
    }
    return todCards.map((c) {
      var t = c.content;
      for (final p in ['Never have I ever ', 'never have I ever ']) {
        if (t.startsWith(p)) {
          t = t.substring(p.length);
          break;
        }
      }
      if (t.isNotEmpty) t = t[0].toUpperCase() + t.substring(1);
      return NhieCard(id: c.id, content: t, difficulty: c.difficulty.name);
    }).toList();
  }

  /// DB-fallback for a follower that never received a state broadcast
  /// (e.g. the owner was also offline) — without this, a reconnecting
  /// follower could be stuck on the loading screen indefinitely.
  Future<void> _tryLoadSnapshotFromDb(String roomId) async {
    try {
      Map<String, dynamic>? row;
      if (_sessionId != null) {
        // Scoped to the EXACT session this client is actually in — never
        // resurrect a different session just because it exists.
        row = await Supabase.instance.client
            .from('game_sessions')
            .select('id, state_snapshot, game_type, lifecycle_state, status')
            .eq('id', _sessionId!)
            .maybeSingle();
        // 'aborted' is unambiguous here (we know exactly which session
        // this is) — never render its snapshot as if still live.
        if (row != null && row['status'] == 'aborted') {
          AppLogger.warning(
            'SESSION_ENDED room=$roomId session=$_sessionId '
            'reason=snapshot_fallback_found_aborted_session',
          );
          _error = kSessionEndedErrorMessage;
          _loadState = NhieLoadState.error;
          _safeNotify();
          return;
        }
      } else {
        // _sessionId genuinely unknown yet (this fallback fired before
        // any broadcast or the initial lookup resolved) — the only safe
        // query here is "the current ACTIVE session for this room",
        // never "whatever the latest session happens to be" (previously
        // ordered by started_at with no status filter at all — a
        // returning player could get silently dropped into an old,
        // already-completed game just because it was the most recent
        // row, which is exactly the "old game resurrection" bug).
        row = await Supabase.instance.client
            .from('game_sessions')
            .select('id, state_snapshot, game_type, lifecycle_state')
            .eq('room_id', roomId)
            .eq('status', 'active')
            .order('started_at', ascending: false)
            .limit(1)
            .maybeSingle();
      }
      final snapshotGameType = row?['game_type'] as String?;
      final Map<String, dynamic>? snapshot =
          snapshotGameType == 'never_have_i_ever'
          ? (row?['state_snapshot'] as Map<String, dynamic>?)
          : null;
      if (snapshot == null || snapshot.isEmpty) {
        _error = 'Could not recover session state. Please rejoin the room.';
        _loadState = NhieLoadState.error;
        _safeNotify();
        return;
      }

      _sessionId ??= row!['id'] as String?;
      // Weak-connection fallback must respect the ready barrier exactly
      // like every other path does — this predates the barrier and
      // previously unlocked the full interactive UI purely off snapshot
      // content, regardless of whether the session had actually reached
      // 'active'.
      final lifecycle = row?['lifecycle_state'] as String?;
      if (lifecycle != null && lifecycle != _lifecycleState) {
        final wasStarting = _lifecycleState == 'starting';
        _lifecycleState = lifecycle;
        if (wasStarting && lifecycle == 'active') {
          _sessionActivePollTimer?.cancel();
        }
      }
      if (_lifecycleState == 'starting') {
        if (_sessionActivePollTimer == null) {
          _confirmReady();
          _pollForSessionActive();
        }
        _lastStateReceivedAt = DateTime.now();
        _safeNotify();
        return;
      }

      // Only apply if actually newer — this is also called by the
      // staleness watchdog, where a race against a broadcast landing at
      // the same moment shouldn't regress state.
      final incomingTs = snapshot['snapshot_at'] as int? ?? 0;
      if (state != null && incomingTs <= (state!.snapshotAt)) {
        _lastStateReceivedAt = DateTime.now();
        return;
      }
      if (snapshot['scores'] is Map) {
        snapshot['scores'] = (snapshot['scores'] as Map).map(
          (k, v) => MapEntry(k as String, v is num ? v.toInt() : 0),
        );
      }
      _engine ??= NeverHaveIEverEngine(
        const GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 60,
          allowSkip: false,
          allowSpicy: false,
        ),
        cards: const [],
      );
      _engine!.restoreFromSnapshot(snapshot);
      _loadState = _engine!.isGameOver
          ? NhieLoadState.gameOver
          : NhieLoadState.ready;
      _lastStateReceivedAt = DateTime.now();
      _safeNotify();
    } catch (e) {
      _error = 'Reconnection failed: ${e.toString()}';
      _loadState = NhieLoadState.error;
      AppLogger.warning('NhieProvider: DB fallback load failed: $e');
      _safeNotify();
    }
  }

  Future<({bool success, String? error})> addCustomCard({
    required String content,
  }) async {
    if (_sessionId == null || _roomId == null) {
      return (success: false, error: 'game_not_started_yet');
    }
    if (_engine == null) {
      return (success: false, error: 'game_not_ready');
    }
    try {
      final card = await TodRepository.instance.addCustomCard(
        sessionId: _sessionId!,
        roomId: _roomId!,
        addedBy: _userId,
        type: TodCardType.truth,
        content: content.trim(),
        difficulty: TodDifficulty.mild,
      );
      _engine?.injectCard(
        NhieCard(id: card.id, content: card.content, difficulty: 'mild'),
      );
      _safeNotify();
      _broadcastState();
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  Future<void> vote(bool haveI, {String message = ''}) => _handleAction({
    'action': 'nhie_vote',
    'have_i': haveI,
    'message': message,
  });
  Future<void> sendReaction(String emoji) =>
      _handleAction({'action': 'nhie_reaction', 'sticker': emoji});

  // ── Honesty voting (shared across ToD/NHIE/Meme, see
  // core/data/honesty_vote_repository.dart) ─────────────────────────────
  final _honestyRepo = HonestyVoteRepository.instance;
  final Set<String> _honestyVotedKeys = {};

  bool hasVotedHonesty(String responseKey, String targetUserId) =>
      _honestyVotedKeys.contains('$responseKey|$targetUserId');

  Future<void> castHonestyVote({
    required String targetUserId,
    required bool isHonest,
    String? reason,
  }) async {
    final s = state;
    if (_sessionId == null || s == null) return;
    final responseKey = 'round:${s.roundNumber}';
    await _honestyRepo.castVote(
      gameSessionId: _sessionId!,
      responseKey: responseKey,
      targetUserId: targetUserId,
      isHonest: isHonest,
      reason: reason,
    );
    _honestyVotedKeys.add('$responseKey|$targetUserId');
    notifyListeners();
  }

  /// Every "Not honest" reason left for MY OWN current-round response.
  /// See HonestyVoteRepository.getDishonestReasons for the RLS/anonymity
  /// contract (voter identity is never returned).
  Future<List<HonestyVoteReason>> getMyDishonestReasons() {
    final s = state;
    if (_sessionId == null || s == null) return Future.value(const []);
    return _honestyRepo.getDishonestReasons(
      gameSessionId: _sessionId!,
      responseKey: 'round:${s.roundNumber}',
    );
  }

  bool _advancing = false;

  Future<void> ownerAdvanceTurn({bool force = false}) async {
    if (!_isOwner || _engine == null) return;
    if (!force && !allOthersReady) return;
    // Explicit re-entrancy guard against a rapid double-tap triggering two
    // engine advances back to back.
    if (_advancing) return;
    _advancing = true;
    try {
      _readyForNext.clear();
      _myReadyIntent = false;
      // Next revealer, per the shared TurnQueue policy (see
      // turn_queue.dart / syncMutedPlayers's own doc comment): skips
      // every currently-ineligible id (away, disconnected, or
      // game-muted) and places a just-unmuted id at the END of the
      // active rotation rather than their original fixed-order slot.
      // Falls back to the engine's own natural next-index if there's no
      // current player yet (shouldn't happen post-init) or nobody is
      // eligible at all — NHIE's round always advances regardless (see
      // NeverHaveIEverEngine.advanceTurn's own doc comment on the
      // unconditional per-call round increment), so unlike ToD this
      // never blocks the advance itself, only which id becomes revealer.
      final currentId = state?.currentPlayerId;
      final nextId = currentId != null
          ? _turnQueue.nextEligible(currentId, _effectiveAwayIds)
          : null;
      _engine!.advanceTurn(forcePlayerId: nextId);
      _autoFillAwayPlayers();
      if (_engine!.isGameOver) _loadState = NhieLoadState.gameOver;
      _syncTimer();
      _safeNotify();
      _broadcastState();
    } finally {
      _advancing = false;
    }
  }

  /// Advance the round, delegating to the owner's client if the caller
  /// isn't the owner — used by a moderator granted 'advance_turn'.
  Future<void> requestAdvanceTurn({bool force = false}) async {
    if (_isOwner) {
      await ownerAdvanceTurn(force: force);
      return;
    }
    if (_roomId == null) return;
    await _realtime.broadcastPlayerAction(_roomId!, {
      'action': 'nhie_mod_advance_turn',
      'force': force,
      'user_id': _userId,
      'display_name': _displayName,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Durable "I intend to be ready for the current round" flag — unlike
  // _readyForNext (wholesale overwritten by each authoritative
  // nhie_ready_count broadcast), this survives a broadcast that never
  // reached the owner, so onReadyCountUpdate can detect the mismatch and
  // resend instead of leaving the presser stuck forever.
  bool _myReadyIntent = false;

  Future<void> markReadyForNext() {
    final isPlayer = state?.playerOrder.contains(_userId) ?? false;
    AppLogger.debug(
      '[READY-DEBUG][nhie] markReadyForNext called by $_userId '
      'isPlayer=$isPlayer hasMarkedReady=$hasMarkedReady',
    );
    if (_userId.isEmpty || hasMarkedReady || !isPlayer) return Future.value();
    _myReadyIntent = true;
    _readyForNext.add(_userId);
    _safeNotify();
    return _handleAction({'action': 'nhie_ready_next'});
  }

  int _lastReadyCountTs = 0;

  void onReadyCountUpdate(
    List<String> readyUserIds, {
    int? ts,
    int? playerIndex,
  }) {
    AppLogger.debug('[READY-DEBUG][nhie] onReadyCountUpdate: $readyUserIds');
    // A ready_count broadcast is only meaningful for the turn it was
    // computed for. State-broadcast and ready-count travel as two separate
    // messages with no ordering guarantee between them — the very last
    // ready_count of a turn (the one that made everyone ready and caused
    // the advance) can arrive AFTER the new turn's state broadcast already
    // reset _readyForNext, and since its ts is not necessarily older than
    // _lastReadyCountTs it would otherwise slip past the ts guard below and
    // re-populate the stale, already-complete list for the turn that just
    // ended — this is what made the Ready button get stuck forever. Tagging
    // every ready_count with the turn it belongs to (currentPlayerIndex) and
    // rejecting a mismatch closes that gap regardless of ts ordering.
    if (playerIndex != null &&
        state?.currentPlayerIndex != null &&
        playerIndex != state!.currentPlayerIndex) {
      return;
    }
    // Multiple players marking ready in quick succession fires multiple
    // ready_count broadcasts back to back — with no delivery-order
    // guarantee, an older one arriving after a newer one would otherwise
    // silently un-ready someone who already marked ready.
    if (ts != null && ts < _lastReadyCountTs) return;
    if (ts != null) _lastReadyCountTs = ts;
    _readyForNext
      ..clear()
      ..addAll(readyUserIds);
    // Self-heal a lost nhie_ready_next broadcast: if I intended to be
    // ready for this round but the owner's authoritative list doesn't
    // have me, resend rather than leaving myself and the host stuck.
    if (_myReadyIntent && !_readyForNext.contains(_userId)) {
      _readyForNext.add(_userId);
      _handleAction({'action': 'nhie_ready_next'}).ignore();
    }
    _safeNotify();
  }

  void onStateBroadcast(Map<String, dynamic> payload) {
    if (_isOwner) return;
    try {
      final snap =
          (payload['snapshot'] as Map<String, dynamic>?)?['state']
              as Map<String, dynamic>? ??
          payload['state'] as Map<String, dynamic>?;
      if (snap == null) return;
      // Reject a snapshot belonging to a PREVIOUS game session outright
      // — the timestamp-based staleness check below only protects
      // against out-of-order broadcasts WITHIN the session already being
      // tracked; it does nothing right at the start of a brand-new
      // session, before any state has synced, when a delayed broadcast
      // from the OLD session could otherwise be adopted as current.
      final payloadSessionId = payload['session_id'] as String?;
      if (payloadSessionId != null &&
          _sessionId != null &&
          payloadSessionId != _sessionId) {
        AppLogger.debug(
          'NhieProvider: discarded state from stale session '
          '$payloadSessionId (current: $_sessionId)',
        );
        return;
      }
      // A follower previously only ever learned its own _sessionId via
      // the 8s DB-fallback timeout — meaning for the common case (state
      // broadcasts arriving normally), it silently stayed null for the
      // whole game, and every check keyed off it (stale-session
      // rejection, ready-barrier confirmation) was inert. The state
      // broadcast already carries it — just read it.
      _sessionId ??= payloadSessionId;

      final incomingLifecycle = payload['lifecycle_state'] as String?;
      if (incomingLifecycle != null && _lifecycleState != incomingLifecycle) {
        final wasStarting = _lifecycleState == 'starting';
        _lifecycleState = incomingLifecycle;
        if (wasStarting && incomingLifecycle == 'active') {
          _sessionActivePollTimer?.cancel();
          AppLogger.info(
            'SESSION_ACTIVE (via broadcast) room=$_roomId '
            'session=$_sessionId user=$_userId',
          );
          // Real-device root-cause fix (first-round follower timer never
          // appearing): the ready-barrier's activation broadcast (see
          // _activateSession) carries the SAME state snapshot the round
          // already started with — nothing mutated it, so its
          // snapshot_at is UNCHANGED — only the lifecycle_state envelope
          // field is new. The staleness check just below (incomingTs <=
          // currentTs) therefore always discards this exact broadcast as
          // a duplicate and returns BEFORE ever reaching _syncTimer() at
          // the bottom of this method. Every prior _syncTimer() call for
          // this follower (the one from the FIRST 'starting'-lifecycle
          // broadcast) ran while isSessionActive was still false, so it
          // correctly left the timer off — but nothing ever re-evaluated
          // it once isSessionActive flipped true, until the NEXT round's
          // genuinely-newer snapshot arrived. Re-deriving right here,
          // the instant the lifecycle itself transitions, closes that
          // gap — safe to call unconditionally: _syncTimer() always
          // cancels any existing ticker before recomputing, so this can
          // never create a duplicate.
          _syncTimer();
        }
        _safeNotify();
      }

      // Realtime broadcast has no ordering/delivery guarantee — an older
      // snapshot arriving after a newer one (e.g. a retried/delayed packet
      // during a brief reconnect) would otherwise silently revert the
      // round/phase with nothing to warn about it.
      final incomingTs = snap['snapshot_at'] as int? ?? 0;
      final currentTs = state?.snapshotAt ?? 0;
      if (state != null && incomingTs <= currentTs) {
        AppLogger.debug(
          'NhieProvider: stale broadcast ts=$incomingTs discarded',
        );
        return;
      }
      // Ready state must reset every TURN, not every ROUND — roundNumber
      // only increments when the turn index wraps back to 0 across the
      // full player order, but the owner's `_readyForNext` is cleared on
      // every single turn advance. Using roundNumber here left a
      // follower's stale "already marked ready" flag in place for every
      // non-wrapping turn, permanently blocking their next ready press.
      // currentPlayerIndex changes on every advanceTurn() call, unlike
      // roundNumber (NHIE's engine has no dedicated turnStartedAt field).
      final previousPlayerIndex = state?.currentPlayerIndex;
      _syncTimeoutTimer?.cancel();
      _lastStateReceivedAt = DateTime.now();
      _engine ??= NeverHaveIEverEngine(
        const GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 60,
          allowSkip: false,
          allowSpicy: false,
        ),
        cards: [],
      );
      _engine!.restoreFromSnapshot(snap);
      _loadState = _engine!.isGameOver
          ? NhieLoadState.gameOver
          : NhieLoadState.ready;
      if (previousPlayerIndex != null &&
          state?.currentPlayerIndex != previousPlayerIndex) {
        _readyForNext.clear();
        _myReadyIntent = false;
      }
      // Item 1 — re-derives remaining time from the (possibly unchanged)
      // timerStartedAt this snapshot carries; never "restarts" a timer
      // that was already running, including on reconnect.
      _syncTimer();
      _safeNotify();
    } catch (e) {
      // A restore failure here must never permanently strand a follower
      // on stale/no state with nothing visibly wrong (see the identical
      // fix and rationale in TodGameProvider.onStateBroadcast) — request
      // a fresh broadcast immediately rather than waiting for the
      // stale-broadcast watchdog to notice.
      AppLogger.warning('NhieProvider: restore failed: $e');
      if (!_isOwner && _roomId != null) {
        _realtime.broadcastSyncRequest(_roomId!, _userId, 0).ignore();
      }
    }
  }

  void onPlayerAction(Map<String, dynamic> payload) {
    if (!_isOwner || _engine == null) return;
    final action = payload['action'] as String?;
    final uid = payload['user_id'] as String?;
    final ts = payload['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    if (uid == null) return;
    // Defense-in-depth mirror of _handleAction's own gate — the owner
    // must never apply an action while the session hasn't reached
    // ACTIVE, regardless of what the sender's own client believed.
    if (!isSessionActive) {
      AppLogger.warning(
        'ACTION_REJECTED_BEFORE_READY room=$_roomId session=$_sessionId '
        'user=$uid lifecycle=$_lifecycleState action=$action',
      );
      return;
    }
    // The owner's client is the closest thing to "the server" in this
    // broadcast-relay architecture — it must independently verify the
    // sender before applying any action, rather than trusting the
    // sender's own client stopped itself.
    //
    // ROOT CAUSE of "real players randomly treated as spectators": this
    // used to check ONLY roomProvider.members — a live, async-populated
    // list that RoomProvider itself is still syncing (initial fetch, CDC,
    // the periodic reconcile poll) right after a game starts. A genuine
    // player whose very first action arrived before that sync caught up
    // got silently and PERMANENTLY rejected here — nothing ever
    // re-checked them, so every subsequent action failed too, forever,
    // even after roomProvider.members caught up seconds later. This is
    // exactly why it looked random and could affect "only some players"
    // or "everyone but the host": whichever clients' actions happened to
    // race the owner's own member-list sync lost, silently, with no
    // retry.
    //
    // Fixed by checking session membership FIRST: state.playerOrder is
    // fixed the instant the game starts (from the same playerIds this
    // engine was initialized with) and needs no async round-trip at all
    // — it's immediately, always correct for anyone who was actually
    // dealt into this game. roomProvider.members is now only consulted
    // as a SECOND gate, to catch a real removal (kick/ban/leave) that
    // happened AFTER the game started — never as the sole source of
    // truth for "is this a real player".
    final isSessionPlayer = state?.playerOrder.contains(uid) ?? false;
    if (!isSessionPlayer) {
      AppLogger.warning(
        'NhieProvider: rejected action "$action" from non-session-player $uid',
      );
      return;
    }
    final members = roomProvider?.members;
    if (members != null && !members.any((m) => m.userId == uid)) {
      AppLogger.warning(
        'NhieProvider: rejected action "$action" from removed member $uid',
      );
      return;
    }
    // A late/delayed broadcast from a PREVIOUS game in this same room
    // must never be applied to whatever game is running now —
    // playerOrder alone can't tell these apart, since consecutive games
    // usually share the same players. Only rejects on a CONFIRMED
    // mismatch (both sides resolved, genuinely different).
    final payloadSessionId = payload['session_id'] as String?;
    if (payloadSessionId != null &&
        _sessionId != null &&
        payloadSessionId != _sessionId) {
      AppLogger.warning(
        'NhieProvider: rejected action "$action" from stale session '
        '$payloadSessionId (current: $_sessionId)',
      );
      return;
    }
    if (action == 'nhie_mod_advance_turn') {
      if (_isAllowed(uid, 'advance_turn')) {
        ownerAdvanceTurn(force: payload['force'] as bool? ?? false);
      }
      return;
    }
    if (action == 'nhie_ready_next') {
      final isPlayer = state?.playerOrder.contains(uid) ?? false;
      AppLogger.debug(
        '[READY-DEBUG][nhie] onPlayerAction ready_next from $uid '
        'isPlayer=$isPlayer current=$_readyForNext',
      );
      if (isPlayer && _readyForNext.add(uid)) {
        AppLogger.debug(
          '[READY-DEBUG][nhie] rebroadcasting ready_count: $_readyForNext',
        );
        _safeNotify();
        final broadcastTs = DateTime.now().millisecondsSinceEpoch;
        _lastReadyCountTs = broadcastTs;
        _realtime.broadcastRoomEvent(_roomId ?? '', {
          'type': 'nhie_ready_count',
          'ready_user_ids': _readyForNext.toList(),
          'ts': broadcastTs,
          'player_index': state?.currentPlayerIndex,
        }).ignore();
      }
      return;
    }
    if (action == 'nhie_vote') {
      _engine!.handleEvent(
        NhieVoteEvent(
          userId: uid,
          ts: ts,
          haveI: payload['have_i'] as bool? ?? false,
          message: payload['message'] as String? ?? '',
        ),
      );
    } else if (action == 'nhie_reaction') {
      // Reaction-before-response real-device bug: the engine's own guard
      // (voteEntries.containsKey) already rejects this — returning the
      // EXACT SAME state object — but a rejected reaction must be a
      // complete no-op end to end, not just "no visible state change".
      // Without this early return, a rejected reaction still fell through
      // to _syncTimer()/_broadcastState() below like any other action —
      // harmless by itself, but an unnecessary timer-recompute + state
      // rebroadcast triggered by an action that was supposed to do
      // nothing. A stale/duplicate/double-tapped reaction hits this same
      // guard every time (identical() stays true), so it can never touch
      // the timer no matter how many times it's retried.
      final before = _engine!.currentState;
      _engine!.handleEvent(
        NhieReactionEvent(
          userId: uid,
          ts: ts,
          sticker: payload['sticker'] as String? ?? '😂',
        ),
      );
      if (identical(_engine!.currentState, before)) return;
    }
    if (_engine!.isGameOver) _loadState = NhieLoadState.gameOver;
    // Item 1 — a vote may have just closed voting early (allVoted), which
    // clears state.timerStartedAt; re-derive so the owner's own ticker
    // stops immediately instead of firing a now-meaningless timeout.
    _syncTimer();
    _safeNotify();
    _broadcastState();
  }

  void onSyncRequest(Map<String, dynamic> _) {
    if (!_isOwner) return;
    _broadcastState();
    // The ready list is broadcast separately from game state (as a room
    // event, not part of the snapshot) — resend it here too so a client
    // that reconnected mid-round doesn't miss it and get stuck waiting.
    final broadcastTs = DateTime.now().millisecondsSinceEpoch;
    _lastReadyCountTs = broadcastTs;
    _realtime.broadcastRoomEvent(_roomId ?? '', {
      'type': 'nhie_ready_count',
      'ready_user_ids': _readyForNext.toList(),
      'ts': broadcastTs,
      'player_index': state?.currentPlayerIndex,
    }).ignore();
  }

  Future<void> _handleAction(Map<String, dynamic> action) async {
    // No gameplay action is valid before this client's OWN session has
    // reached ACTIVE — the actual chokepoint fix for "sees the game but
    // can't interact": a client whose screen mounted and is rendering
    // broadcasts fine, but whose own readiness hasn't been
    // confirmed/activated yet, must not be able to act.
    if (!isSessionActive) {
      AppLogger.warning(
        'ACTION_REJECTED_BEFORE_READY room=$_roomId session=$_sessionId '
        'user=$_userId lifecycle=$_lifecycleState action=${action['action']}',
      );
      return;
    }
    // A kicked/banned/left player must not be able to act again even in the
    // brief window before their client has processed the moderation
    // broadcast and navigated away.
    if (_effectiveAwayIds.contains(_userId)) return;
    // Game session membership decides if I belong to the game — fixed at
    // game-init time (playerOrder, from the same playerIds this engine
    // was initialized with), no async dependency on RoomProvider's own
    // sync timing. Mirrors the fix already applied to onPlayerAction's
    // owner-side validation: checking roomProvider.currentMember FIRST
    // (a live, async-populated read) risked treating "RoomProvider hasn't
    // finished syncing yet" the same as "I'm not really in this game",
    // which could turn a real player into a de-facto spectator for
    // reasons that had nothing to do with being removed.
    if (!(state?.playerOrder.contains(_userId) ?? false)) return;
    // Room membership only decides if I was later removed (kick/ban/
    // leave) — but only once RoomProvider has actually completed its
    // first load (isInitialized); before that, its member list is
    // legitimately empty/incomplete and must never be read as "removed".
    final rp = roomProvider;
    if (rp != null && rp.isInitialized) {
      final stillInRoom = rp.members.any((m) => m.userId == _userId);
      if (!stillInRoom) return;
    }
    // Moderator-imposed game mute (RoomMemberEntity.isGameMuted, distinct
    // from chat mute) — muted players can still watch but not act.
    if (rp?.currentMember?.isGameMuted ?? false) return;
    final full = {
      ...action,
      'user_id': _userId,
      'display_name': _displayName,
      'ts': DateTime.now().millisecondsSinceEpoch,
      // Lets a late-arriving action from a PREVIOUS game in this same
      // room be told apart from the game currently running — see
      // onPlayerAction's check. May be null very briefly during session
      // creation; that's fine, onPlayerAction only rejects on a
      // confirmed mismatch.
      'session_id': _sessionId,
    };
    if (_isOwner && _engine != null)
      onPlayerAction(full);
    else if (_roomId != null)
      await _realtime.broadcastPlayerAction(_roomId!, full);
  }

  bool _gameEndedNotified = false;

  void _broadcastState() {
    if (_roomId == null || _engine == null) return;
    final snapshot = _engine!.serializeState();
    _realtime
        .broadcastGameState(
          _roomId!,
          {'state': snapshot},
          _userId,
          sessionId: _sessionId,
          lifecycleState: _lifecycleState,
        )
        .ignore();

    if (_isOwner && _sessionId != null) {
      if (_engine!.isGameOver) {
        AppLogger.info('SESSION_ENDED room=$_roomId session=$_sessionId');
      }
      Supabase.instance.client
          .from('game_sessions')
          .update({
            'state_snapshot': snapshot,
            'updated_at': DateTime.now().toIso8601String(),
            if (_engine!.isGameOver) 'status': 'completed',
            if (_engine!.isGameOver)
              'ended_at': DateTime.now().toIso8601String(),
            if (_engine!.isGameOver) 'lifecycle_state': 'ended',
          })
          .eq('id', _sessionId!)
          .then(
            (_) {},
            onError: (e) {
              AppLogger.warning('NhieProvider: snapshot save failed: $e');
            },
          );
    }
    if (_isOwner && _engine!.isGameOver && !_gameEndedNotified) {
      _gameEndedNotified = true;
      sl.roomRepository.notifyGameEnded(_roomId!).ignore();
    }
  }

  // ── Chat (item 4) — same mechanism as TodGameProvider's chat: an
  // in-memory per-session message list, sent/received over the room's
  // existing 'chat_message' realtime broadcast (RealtimeService.
  // broadcastChat/onChatMessage), deduped by (sender, text, ts) so a
  // locally-optimistic add is never double-counted against the same
  // message echoed back by realtime. See TodGameProvider.sendChat/
  // addChatMessage for the identical pattern this mirrors.
  final List<GameChatMsg> _chatMessages = [];
  List<GameChatMsg> get chatMessages => _chatMessages;
  int _unreadChat = 0;
  int get unreadChat => _unreadChat;
  void clearUnreadChat() {
    _unreadChat = 0;
    _safeNotify();
  }

  Future<bool> sendChat(String text, {GameChatMsg? replyTo}) async {
    if (_roomId == null || text.trim().isEmpty) return false;
    final id = '${_userId}_${DateTime.now().microsecondsSinceEpoch}';
    final msg = GameChatMsg(
      id: id,
      senderId: _userId,
      senderName: _displayName,
      text: text.trim(),
      ts: DateTime.now(),
      replyToId: replyTo?.id,
      replyToSenderName: replyTo?.senderName,
      replyToText: replyTo?.text,
    );
    _chatMessages.add(msg);
    _safeNotify();
    try {
      await _realtime.broadcastChat(_roomId!, {
        'id': id,
        'user_id': _userId,
        'display_name': _displayName,
        'content': text.trim(),
        'ts': DateTime.now().millisecondsSinceEpoch,
        if (replyTo != null) 'reply_to_id': replyTo.id,
        if (replyTo != null) 'reply_to_sender_name': replyTo.senderName,
        if (replyTo != null) 'reply_to_text': replyTo.text,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  void addChatMessage(GameChatMsg msg) {
    if (_chatMessages.any(
      (m) =>
          m.senderName == msg.senderName &&
          m.text == msg.text &&
          msg.ts.difference(m.ts).abs().inSeconds < 2,
    )) {
      return;
    }
    _chatMessages.add(msg);
    _unreadChat++;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _syncTimeoutTimer?.cancel();
    _staleWatchdog?.cancel();
    _staleRecoveryTimer?.cancel();
    _readyBarrierTimeout?.cancel();
    _sessionActivePollTimer?.cancel();
    _timerTicker?.cancel();
    _targetedChatListener.stop();
    super.dispose();
  }
}

Future<void> nhieShowLeaveDialog(
  BuildContext ctx, {
  required String roomId,
  required bool isOwners,
  String displayName = 'A player',
  NhieGameProvider? game,
}) async {
  if (!ctx.mounted) return;
  final isOwner = isOwners;
  final myUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
  final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

  if (isOwner) {
    final mods = await sl.roomRepository
        .getRoomModerators(roomId)
        .catchError((_) => <Map<String, dynamic>>[]);
    final hasMod = mods.isNotEmpty;

    // Quit Game only ends the current game session — it must NOT close or
    // delete the room. Closing the room is a separate action, only
    // available from LobbyScreen's room management. Handing ownership off
    // to someone else first remains a separate, unrelated option.
    final choice = await showDialog<String>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(ctx.l10n.todQuitGameTitle),
        content: Text(ctx.l10n.todQuitGameBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, 'cancel'),
            child: Text(ctx.l10n.cancel),
          ),
          if (hasMod)
            FilledButton.tonal(
              onPressed: () => Navigator.pop(d, 'handoff'),
              child: Text(ctx.l10n.nhiePlayAnotherHandOff),
            ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(d, 'end'),
            child: Text(ctx.l10n.todQuitGame),
          ),
        ],
      ),
    );
    if (choice == null || choice == 'cancel' || !ctx.mounted) return;

    if (choice == 'handoff' && mods.isNotEmpty) {
      final newOwner = mods.length == 1
          ? mods.first['user_id'] as String
          : await showDialog<String>(
              context: ctx,
              builder: (d) => SimpleDialog(
                title: Text(ctx.l10n.nhieWhoTakesOver),
                children: mods.map((m) {
                  final uid = m['user_id'] as String;
                  return SimpleDialogOption(
                    onPressed: () => Navigator.pop(d, uid),
                    child: Text(uid.substring(0, 8).toUpperCase()),
                  );
                }).toList(),
              ),
            );
      if (newOwner == null || !ctx.mounted) return;
      try {
        await Supabase.instance.client
            .from('rooms')
            .update({'owner_id': newOwner})
            .eq('id', roomId);
        await sl.realtimeService.broadcastRoomEvent(roomId, {
          'type': 'ownership_transferred',
          'new_owner_id': newOwner,
          'by': myUserId,
        });
        await sl.realtimeService.broadcastRoomEvent(roomId, {
          'type': 'player_left',
          'user_id': myUserId,
          'for_good': true,
        });
      } catch (_) {}
      if (ctx.mounted) AppRouter.router.go(RouteNames.home);
      return;
    }

    // Use the dedicated game-ended broadcast (not 'owner_left') so every
    // player's existing onGameEnded handler fires immediately and pops
    // back to this same room's lobby — no dialog required on the
    // receiving end.
    try {
      await sl.realtimeService.broadcastGameEnded(roomId, {
        'reason': 'host_quit_to_lobby',
        'session_id': game?.sessionId,
      });
      await sl.roomRepository.updateStatus(roomId, RoomStatus.waiting);
    } catch (_) {}
    if (ctx.mounted) {
      // Mark this as a programmatic exit before popping, so PopScope
      // (which shares this same NhieGameProvider instance) doesn't
      // mistake it for the user backing out and open Quit Game again.
      game?.isNavigatingAway = true;
      if (ctx.canPop()) {
        ctx.pop();
      } else {
        AppRouter.router.go('/home/room/$roomId');
      }
    }
  } else {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(ctx.l10n.todQuitGameTitle),
        content: Text(ctx.l10n.todQuitGameBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(d, true),
            child: Text(ctx.l10n.todQuitGame),
          ),
        ],
      ),
    );
    if (confirmed != true || !ctx.mounted) return;
    // A normal player/spectator quitting the game also leaves the room
    // entirely (frees their slot, updates counts) — for_good:true tells
    // every client's RoomProvider to remove them from the member list.
    try {
      await sl.roomRepository.setMemberDefinitiveLeave(roomId, myUserId);
      await sl.realtimeService.broadcastRoomEvent(roomId, {
        'type': 'player_left',
        'user_id': myUserId,
        'display_name': displayName,
        'for_good': true,
      });
    } catch (_) {}
    if (ctx.mounted) AppRouter.router.go(RouteNames.home);
  }
}

class NhieGameScreen extends StatefulWidget {
  const NhieGameScreen({
    super.key,
    required this.roomId,
    required this.config,
    required this.playerIds,
    required this.playerDisplayNames,
    required this.packId,
    this.packCoverUrl,
    required this.isOwner,
    this.isModerator = false,
    this.isSpectator = false,
    this.isNewGameStart = false,
    this.roomProvider,
  });
  final String roomId;
  final GameConfig config;
  final List<String> playerIds;
  final Map<String, String> playerDisplayNames;
  final String packId;
  final bool isOwner;
  final bool isModerator;
  final bool isSpectator;
  final String? packCoverUrl;
  // True only for a genuine, fresh "Start Game" press — see
  // TodGameScreen.isNewGameStart's doc comment for the full rationale.
  final bool isNewGameStart;
  final RoomProvider? roomProvider;
  @override
  State<NhieGameScreen> createState() => _NhieGameScreenState();
}

class _NhieGameScreenState extends State<NhieGameScreen> {
  late final NhieGameProvider _provider;

  // Tracks whether we've reached `subscribed` before, so a later reconnect
  // (network drop, backgrounding) also triggers a fresh sync request —
  // Realtime Broadcast has no delivery guarantee or replay, so state
  // broadcasts sent while disconnected are permanently missed otherwise.
  bool _hasEverSubscribed = false;

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
    final user = context.read<AuthProvider>().currentUser!;
    _provider = NhieGameProvider(
      realtimeService: sl.realtimeService,
      userId: user.id,
      displayName: user.displayName ?? user.username ?? context.l10n.packPlayer,
      isModerator: widget.isModerator,
    );
    // subscriberId: 'game' — registers alongside RoomProvider's own 'room'
    // listener on the shared channel; does not displace it.
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
      onChatMessage: (p) {
        // Same shared mechanism as ToD's game chat (item 4) — see
        // TodGameScreen's identical onChatMessage for the reference
        // implementation this mirrors field-for-field.
        final msg = GameChatMsg(
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
      onGameStarted: (_) {},
      onGameEnded: (p) {
        // A game_ended broadcast for a session that isn't this client's
        // current one — a previous game's event delayed in flight (no
        // delivery guarantee/ordering on Realtime Broadcast) arriving
        // after a fresh game already started — must never end the game
        // actually running now. Tolerant of either side being null (a
        // session_id-less legacy caller, or this client not having
        // resolved its own session_id yet) — only a CONFIRMED mismatch
        // (both known, and different) is rejected.
        final eventSessionId = p['session_id'] as String?;
        if (eventSessionId != null &&
            _provider.sessionId != null &&
            eventSessionId != _provider.sessionId) {
          AppLogger.warning(
            'NhieGameScreen: ignoring game_ended for stale session '
            '$eventSessionId (current: ${_provider.sessionId})',
          );
          return;
        }
        // Idempotent navigation-away: another exit path
        // (_leaveIfRoomNoLongerActive, the error/session-ended auto-leave,
        // the quit flow, or a duplicate game_ended) may have already
        // started leaving. Same combined guard _leaveIfRoomNoLongerActive
        // uses — once EITHER latch is set, every other exit no-ops, so we
        // can never double-pop / navigate after this route is already gone.
        if (_autoLeftOnSessionEnd || _provider.isNavigatingAway) return;
        if (mounted) {
          // Mark this as a programmatic exit before popping, so
          // _GameBody's PopScope (which shares this same NhieGameProvider
          // instance) doesn't mistake it for the user backing out and
          // open the Quit Game dialog on top of it.
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
        final evType = p['type'] as String?;
        if (evType == 'session_ready') {
          final sessionId = p['session_id'] as String?;
          final userId = p['user_id'] as String?;
          if (sessionId != null &&
              userId != null &&
              sessionId == _provider.sessionId) {
            _provider.handleSessionReadyEvent(userId);
          }
          return;
        }
        if (evType == 'nhie_ready_count') {
          final ids = (p['ready_user_ids'] as List?)?.cast<String>() ?? [];
          _provider.onReadyCountUpdate(
            ids,
            ts: p['ts'] as int?,
            playerIndex: p['player_index'] as int?,
          );
          return;
        }
        if (evType == 'screenshot_taken') {
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
        if (evType == 'game_ended' && mounted) {
          final reason = p['reason'] as String? ?? '';
          // Reused from ToD's original all_players_left handling (see
          // tod_game_screen.dart) — RoomProvider now raises the same
          // game_ended/not_enough_players event uniformly across every
          // game mode (see RoomProvider._maybeAutoEndGame), so every
          // screen shares the exact same dialog copy for it instead of
          // each drifting on its own wording.
          final isAutoEnded =
              reason == 'all_players_left' || reason == 'not_enough_players';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx2) => AlertDialog(
                title: Text(
                  isAutoEnded
                      ? context.l10n.todGameOver
                      : context.l10n.todGameEnded,
                ),
                content: Text(
                  isAutoEnded
                      ? context.l10n.todAllPlayersLeftGameBody
                      : context.l10n.todHostEndedGameBody,
                ),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx2).pop();
                      if (context.canPop())
                        context.pop();
                      else
                        AppRouter.router.go('/home/room/${widget.roomId}');
                    },
                    child: Text(context.l10n.todGoToLobby),
                  ),
                ],
              ),
            );
          });
          return;
        }
        if (evType == 'player_left' && mounted) {
          final name =
              p['display_name'] as String? ?? context.l10n.defaultPlayerName;
          final leavingId = p['user_id'] as String?;
          if (leavingId != null && _provider.isOwner) {
            _provider.markPlayerAway(leavingId, forGood: true);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.todPlayerLeftGame(name)),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.fixed,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
        if (evType == 'ownership_transferred' && mounted) {
          final myId = context.read<AuthProvider>().currentUser?.id;
          if (p['new_owner_id'] == myId) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.todYouAreNowHost),
                backgroundColor: Colors.purple,
              ),
            );
          }
          return;
        }

        if (((p['type'] as String?) == 'room_closed' ||
            (p['type'] as String?) == 'owner_left')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted)
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
            else
              AppRouter.router.go(RouteNames.home);
          });
        }
      },
      onModeration: (p) {
        final type = p['type'] as String?;
        final targetId = p['target_user_id'] as String?;
        final myId = context.read<AuthProvider>().currentUser?.id;
        if (type == 'game_kick' && targetId != null) {
          _provider.markPlayerAway(targetId, forGood: true);
          if (targetId == myId && mounted) {
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
          // Room-level kick/ban previously only told the TARGET's own
          // client to leave — every other client's game provider never
          // learned the target was gone, so it kept waiting on their
          // vote indefinitely even though they'd already been removed
          // from the room. Mark them away for everyone.
          _provider.markPlayerAway(targetId, forGood: true);
          if (targetId == myId && mounted) {
            // Name the actual actor (by_name), never a generic "admin".
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
      },
      onSettingsChange: (_) {},
      onPresenceSync: (_) {},
      onStatusChange: (status) {
        if (!mounted) return;
        if (status == RealtimeSubscribeStatus.subscribed) {
          if (_hasEverSubscribed) _requestSync();
          _hasEverSubscribed = true;
        }
      },
    );
    if (!widget.isOwner) {
      Future.delayed(const Duration(milliseconds: 300), _requestSync);
    }
    if (widget.isOwner) {
      _provider.initAsOwner(
        roomId: widget.roomId,
        packId: widget.packId,
        playerIds: widget.playerIds,
        displayNames: widget.playerDisplayNames,
        config: widget.config,
        isNewGame: widget.isNewGameStart,
      );
    } else {
      _provider.initAsFollower(
        widget.roomId,
        packId: widget.packId,
        config: widget.config,
      );
    }

    _lastKnownRoomOwner = widget.isOwner;
    _lastKnownPaused = widget.roomProvider?.isPausedForHostReconnect ?? false;
    widget.roomProvider?.addListener(_onRoomOwnershipChanged);
    widget.roomProvider?.addListener(_onRoomPauseChanged);
    _provider.permissionChecker = widget.roomProvider?.memberHasPermission;
    _provider.roomProvider = widget.roomProvider;
    final roomId = widget.roomProvider?.room?.id;
    if (roomId != null) _provider.startTargetedChatListener(roomId);

    widget.roomProvider?.addListener(_syncAwayFromPresence);
    _provider.addListener(_syncAwayFromPresence);
    _lifecycleSub = widget.roomProvider?.lifecycleEvents.listen(
      _onRoomLifecycleEvent,
    );
  }

  bool? _lastKnownRoomOwner;

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
        // stays mounted underneath this pushed route. This screen
        // previously ALSO reacted to roomClosed with its own snackbar +
        // AppRouter.router.go(), racing against LobbyScreen's showDialog
        // for the same broadcast event — go() replacing the entire route
        // stack while the lobby's AlertDialog was still mid-transition left
        // a semantics-blocking barrier that never cleanly rejoined the
        // tree, producing a permanently corrupted semantics node (repeating
        // '!semantics.parentDataDirty' assertion every frame thereafter).
        // roomClosed now has exactly one owner, same as the other three.
        break;
      case RoomLifecycleEvent.memberLeft:
        final name = widget.roomProvider?.lastDepartedMemberName;
        if (name != null && name.isNotEmpty) {
          context.showSnackBar(context.l10n.todPlayerLeftGame(name));
        }
    }
  }

  // Single presence pipeline: RoomProvider already tracks connected/
  // disconnected members reliably via its own debounced presence sync.
  // Reacting to that (instead of the dead RealtimeService presence
  // callbacks) is the one source of truth for away/return in-game.
  void _syncAwayFromPresence() {
    final rp = widget.roomProvider;
    final state = _provider.state;
    if (rp == null || !_provider.isOwner || state == null) return;
    final mutedIds = <String>{};
    for (final id in state.playerOrder) {
      final member = rp.members.where((m) => m.userId == id).firstOrNull;
      // Disconnection and game-mute are two separate eligibility
      // signals: "away" here means genuinely absent (disconnected) only
      // — mute has its own dedicated transition handling
      // (_provider.syncMutedPlayers) below, which reorders the active
      // turn rotation on unmute (rejoin at the end, never the original
      // fixed-order slot) rather than a plain resume-in-place the way a
      // reconnecting disconnected player gets. _durableAwayIds still
      // separately folds isGameMuted in for ready-checks/action-blocking
      // purposes — unaffected by this split.
      final isPresent = member != null && !member.isDisconnected;
      final isAway = _provider.awayPlayerIds.contains(id);
      if (isPresent && isAway) {
        _provider.markPlayerReturned(id);
      } else if (!isPresent && !isAway) {
        _provider.markPlayerAway(id);
      }
      if (member?.isGameMuted ?? false) mutedIds.add(id);
    }
    _provider.syncMutedPlayers(mutedIds);
  }

  void _onRoomOwnershipChanged() {
    final rp = widget.roomProvider;
    if (rp == null) return;
    final amOwner = rp.isOwner;
    if (_lastKnownRoomOwner == amOwner) return;
    _lastKnownRoomOwner = amOwner;
    _provider.applyOwnershipChange(amOwner);
  }

  // build()'s Consumer only listens to _provider — RoomProvider
  // pausing/resuming for a disconnected host otherwise wouldn't trigger a
  // rebuild, so the host-reconnect overlay would never appear/disappear.
  bool _lastKnownPaused = false;

  // Guards the session-ended auto-navigate in build's error branch against
  // firing more than once.
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

  void _requestSync() {
    if (!mounted) return;
    sl.realtimeService
        .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
        .ignore();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _provider.loadState == NhieLoadState.loading) {
        sl.realtimeService
            .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
            .ignore();
      }
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _provider.loadState == NhieLoadState.loading) {
        sl.realtimeService
            .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
            .ignore();
      }
    });
  }

  @override
  void dispose() {
    widget.roomProvider?.removeListener(_onRoomOwnershipChanged);
    widget.roomProvider?.removeListener(_onRoomPauseChanged);
    widget.roomProvider?.removeListener(_syncAwayFromPresence);
    _provider.removeListener(_syncAwayFromPresence);
    _lifecycleSub?.cancel();
    // ScreenSecurityService.instance.disable();
    // Only removes this screen's own 'game' listener — the room channel,
    // RoomProvider's 'room' listener, and presence tracking are untouched.
    sl.realtimeService.unsubscribeListener(
      widget.roomId,
      RoomChannelSubscriber.game,
    );
    _provider.dispose();
    super.dispose();
  }

  // Premium Plus away-from-app snackbar (item 1) — wraps whatever this
  // build() returns; no-op (returns [child] unchanged) when this screen
  // has no roomProvider.
  Widget _wrapAwayListener(Widget child) {
    final rp = widget.roomProvider;
    return rp == null
        ? child
        : AwayPresenceSnackbarListener(roomProvider: rp, child: child);
  }

  @override
  Widget build(BuildContext context) {
    // Stacked so the members management entry point stays reachable across
    // every phase this screen can render (loading/error/gameOver/active
    // round) without needing to be threaded into each one individually.
    return _wrapAwayListener(
      Stack(
        children: [
          _buildContent(context),
          RoomMembersFab(
            roomProvider: widget.roomProvider,
            gameKickPlayer: _provider.kickPlayerFromGame,
            gameBanPlayer: _provider.banPlayerFromGame,
            heroTag: 'nhie_members_${widget.roomId}',
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
          // Positioned.fill: see tod_game_screen.dart's identical wrapper —
          // without it this nested Stack collapses into the outer Stack's
          // default corner instead of filling the screen.
          Positioned.fill(
            child: ChangeNotifierProvider.value(
              value: _provider,
              child: Consumer<NhieGameProvider>(
                builder: (ctx, game, _) => AnimatedReactionOverlay(
                  reactions: (game.state?.reactions ?? const [])
                      .map(
                        (r) => (emoji: r.sticker, ts: r.ts, userId: r.userId),
                      )
                      .toList(),
                  avatarResolver: widget.roomProvider?.memberById,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<NhieGameProvider>(
        builder: (ctx, game, _) {
          // Host disconnected mid-game — takes priority over everything
          // else. NEVER shown to the OWNER themselves (they ARE the host);
          // this is what removes the brief "waiting for admin" flash on the
          // admin's own reconnect. See tod_game_screen.dart's identical gate.
          if (widget.roomProvider?.isPausedForHostReconnect == true &&
              widget.roomProvider?.isOwner != true) {
            return HostReconnectOverlay(roomProvider: widget.roomProvider!);
          }
          if (game.loadState == NhieLoadState.loading)
            return BrandedStatusView(
              emoji: '🙊',
              title: context.l10n.gameNameNeverHaveIEverFull,
              subtitle: context.l10n.todLoadingGame,
              accent: AppColors.brandBlueMid,
            );
          // A definitive failure must take priority over "still starting"
          // — game.isSessionStarting (_lifecycleState == 'starting') stays
          // true forever once session creation fails (nothing ever
          // advances it past 'starting'), so checking isSessionStarting
          // before this error branch made a real, already-surfaced error
          // permanently unreachable in the UI: the "waiting for players"
          // spinner below would win every single build, masking the error
          // completely and presenting as an infinite loading screen with
          // no indication anything had gone wrong. This check must come
          // BEFORE isSessionStarting for exactly that reason.
          if (game.loadState == NhieLoadState.error) {
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
              // Prefer popping back to the LobbyScreen instance already
              // alive underneath this pushed game route (pushed with
              // parentNavigatorKey: rootKey specifically so it survives)
              // over go(), which re-resolves the whole location from
              // scratch and may not resolve the Future _pushGameRoute is
              // awaiting to clear its _navigatedToGame guard — leaving a
              // second game in this same room permanently unable to
              // navigate. Same pattern as goToLobbyOrHome/onGameEnded.
              if (context.mounted) {
                if (context.canPop()) {
                  context.pop();
                } else {
                  // Room still exists (session ended/failed to start, e.g.
                  // a player was kicked during loading) — return to its
                  // LOBBY, not the app home. See _leaveIfRoomNoLongerActive.
                  context.go('/home/room/${widget.roomId}');
                }
              }
            }

            // Session-ended is not a real error to read/dismiss — it's this
            // client learning late the game already ended (its own
            // game_ended broadcast — no delivery guarantee — was missed).
            // Leave automatically, and never render the red error UI for
            // this case at all (even one visible frame of it before the
            // postFrameCallback fires reads as "an error appeared"). See
            // tod_game_screen.dart's identical handling.
            if (game.error == kSessionEndedErrorMessage) {
              if (!_autoLeftOnSessionEnd) {
                _autoLeftOnSessionEnd = true;
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => leaveToLobby(),
                );
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return Scaffold(
              appBar: AppBar(leading: BackButton(onPressed: leaveToLobby)),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    context.l10n.errorPrefix(game.error ?? ''),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          // Session ready barrier: state already loaded fine (that's
          // specifically what made the old bug invisible) but this
          // client's own session hasn't reached ACTIVE yet — no gameplay
          // UI shown at all, nothing to press, nothing to silently
          // ignore. Checked AFTER the error branch above — see its
          // comment for why the order matters.
          if (game.isSessionStarting) {
            return BrandedStatusView(
              emoji: '🙊',
              title: context.l10n.gameNameNeverHaveIEverFull,
              subtitle: game.expectedReadyCount > 0
                  ? context.l10n.todWaitingForPlayers(
                      game.readyConfirmedCount,
                      game.expectedReadyCount,
                    )
                  : context.l10n.todLoadingGame,
              accent: AppColors.brandBlueMid,
            );
          }
          if (game.loadState == NhieLoadState.gameOver)
            return _GameOverScreen(
              game: game,
              displayNames: widget.playerDisplayNames,
              roomId: widget.roomId,
            );
          final state = game.state;
          if (state == null)
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          return _GameBody(
            game: game,
            state: state,
            displayNames: widget.playerDisplayNames,
            packCoverUrl: widget.packCoverUrl,
            roomId: widget.roomId,
            isOwner: widget.isOwner,
            isSpectator: widget.isSpectator,
          );
        },
      ),
    );
  }
}

class _GameBody extends StatefulWidget {
  const _GameBody({
    required this.game,
    required this.state,
    required this.displayNames,
    this.packCoverUrl,
    required this.roomId,
    required this.isOwner,
    this.isSpectator = false,
  });
  final NhieGameProvider game;
  final NhieState state;
  final Map<String, String> displayNames;
  final String? packCoverUrl;
  final String roomId;
  final bool isOwner;
  final bool isSpectator;
  @override
  State<_GameBody> createState() => _GameBodyState();
}

class _GameBodyState extends State<_GameBody> {
  final _msgCtrl = TextEditingController();
  bool _showHistory = false;

  // First-time NHIE / Who's Most Likely overview highlight (the play area).
  final GlobalKey _nhieShowcaseKey = GlobalKey();

  // Route-level back guard (GameScreenSecurityGate) — see the TOD screen's
  // matching comment. Registering here means back is guarded even while the
  // round-history sub-view is open, uniformly across every game.
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

  /// Close the history sub-view first, otherwise run the existing NHIE quit
  /// flow. Always consumes the gesture so the game route can't escape.
  Future<bool> _handleGameBack() async {
    if (!mounted) return true;
    if (_showHistory) {
      setState(() => _showHistory = false);
      return true;
    }
    if (widget.game.isNavigatingAway) return true;
    await nhieShowLeaveDialog(
      context,
      roomId: widget.roomId,
      isOwners: widget.isOwner,
      game: widget.game,
      displayName:
          widget.displayNames[Supabase.instance.client.auth.currentUser?.id ??
              ''] ??
          context.l10n.defaultPlayerName,
    );
    return true;
  }

  @override
  void dispose() {
    _backGuard?.unregister(_handleGameBack);
    _msgCtrl.dispose();
    super.dispose();
  }

  String _name(String id) =>
      widget.displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final state = widget.state;
    final game = widget.game;
    // Spectators can watch voting but never cast one themselves.
    final hasVoted =
        widget.isSpectator || state.voteEntries.containsKey(game.userId);
    // Item 1/4/5 root-cause fix: this used to require EVERY player to
    // literally have a voteEntries entry, which a non-responder never
    // gets (see NeverHaveIEverEngine._onTimerExpired — a skipped player
    // stays absent from voteEntries by design, that's the existing
    // "no response" representation). After a timeout with even one
    // non-responder, that condition could never become true again,
    // permanently stranding the results/"Ready for next round" branch
    // below unreachable — the observed "stuck at Time's Up forever" bug.
    // What actually determines "the round is over and results should
    // show" is state.isVotingOpen itself: the engine already flips it to
    // false in EXACTLY the two cases that mean the round is closed —
    // every player voted (_handleVote) or the timer expired
    // (_onTimerExpired) — so this is the correct, already-authoritative
    // signal to key off, not a re-derived vote count.
    final allVoted = !state.isVotingOpen;
    final hasReacted =
        widget.isSpectator ||
        state.reactions.any((r) => r.userId == game.userId);
    // Emoji reactions aggregate to a count. AVATAR reactions cannot be
    // aggregated by their sticker key — the same "avatar:<key>" from two
    // players must render each player's OWN avatar — so they're kept per
    // reactor and resolved by reactor userId (never the current viewer). This
    // is the same resolution the history panel uses.
    final reactionTally = <String, int>{};
    final avatarReactions = <NhieReaction>[];
    for (final r in state.reactions) {
      if (AvatarConfig.isAvatarReaction(r.sticker)) {
        avatarReactions.add(r);
      } else {
        reactionTally[r.sticker] = (reactionTally[r.sticker] ?? 0) + 1;
      }
    }

    return ScreenTutorial(
      tutorialId: TutorialIds.nhieIntro,
      steps: [_nhieShowcaseKey],
      child: Stack(
        children: [
          PopScope(
            // Redundant route-pop blocker only; the back ACTION is handled once by
            // GameScreenSecurityGate via _handleGameBack (registered above), which
            // also covers the history sub-view. See the TOD screen's matching note.
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {},
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                // Solid brand-green chrome flowing into _NhieHud's own gradient
                // below it, mirroring ToD's purple/blue party chrome — same
                // continuous-chrome pattern, NHIE's own color identity. Actions
                // (chat/history/rules) and back navigation are unchanged.
                backgroundColor: _kNhieDeep,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => nhieShowLeaveDialog(
                    context,
                    roomId: widget.roomId,
                    isOwners: widget.isOwner,
                    game: widget.game,
                    displayName:
                        widget.displayNames[Supabase
                                .instance
                                .client
                                .auth
                                .currentUser
                                ?.id ??
                            ''] ??
                        context.l10n.defaultPlayerName,
                  ),
                ),
                title: Text(
                  context.l10n.todRoundBadge(
                    state.roundNumber,
                    state.maxRounds,
                  ),
                ),
                actions: [
                  // Item 4 — same shared in-game chat ToD already had, now
                  // available in NHIE too. showModalBottomSheet is its own
                  // Navigator route, so it already gets a working system-back
                  // dismissal for free (no extra back-guard branch needed, same
                  // as ToD's own chat button).
                  Consumer<NhieGameProvider>(
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
                                myId: g.userId,
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
                      onPressed: () =>
                          setState(() => _showHistory = !_showHistory),
                    ),
                  RulesButton(
                    gameType: GameType.neverHaveIEver,
                    config: widget.game.config,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: Text(
                        context.l10n.nhieDrinksTotal(
                          state.scores.values.fold(0, (a, b) => a + b),
                        ),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Item 2 (real-device report: iOS "History" red-screen crash)
              // — this body used to conditionally SWAP between
              // _HistoryPanel and this tutorialShowcase(_nhieShowcaseKey)-
              // wrapped content, tearing the showcase target down whenever
              // History opened while ScreenTutorial (an ancestor,
              // unconditionally wrapping this whole Scaffold) stayed
              // mounted — the exact partial-subtree-teardown-under-a-
              // surviving-ancestor hazard explained in full at this
              // screen's own build() (see the matching fix/comment in
              // tod_game_screen.dart, applied identically here). Now always
              // built (never removed); the History overlay is a separate
              // Stack layer above this Scaffold instead — see below.
              body: tutorialShowcase(
                context: context,
                showcaseKey: _nhieShowcaseKey,
                title: context.l10n.tutNhieTitle,
                description: widget.isSpectator
                    ? context.l10n.tutNhieSpectatorBody
                    : context.l10n.tutNhieBody,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Round/timer/answered-count HUD — same data as
                        // before (roundNumber/maxRounds, votes.length/
                        // activePlayerCount, timerRemaining/timerIsRunning),
                        // just presented as one continuous party-chrome
                        // strip instead of a plain centered Text + a
                        // separately-floating ring. Timer badge only
                        // renders while g.timerIsRunning — no reserved
                        // space when the timer is off, same guarantee the
                        // old Consumer had.
                        _NhieHud(state: state, game: game),
                        const SizedBox(height: 12),

                        Expanded(
                          child: GameFlipCard(
                            title: context.l10n.gameNameNeverHaveIEverFull,
                            contentId: state.currentCard?.id,
                            autoRevealDelay: const Duration(seconds: 1),
                            frontChild: Text(
                              state.currentCard?.content ?? '…',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.gameCardContent(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (!hasVoted && state.isVotingOpen) ...[
                          TextField(
                            controller: _msgCtrl,
                            maxLength: 120,
                            maxLines: 1,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) =>
                                FocusScope.of(context).unfocus(),
                            decoration: InputDecoration(
                              hintText: context.l10n.nhieAddCommentOptional,
                              border: OutlineInputBorder(),
                              isDense: true,
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Item 4 — large, playful, clearly-distinct
                          // response choices (replacing the previous
                          // 50px text buttons). The engine is still what
                          // actually accepts/rejects the vote (see
                          // NeverHaveIEverEngine._handleVote) — this is
                          // presentation only.
                          Row(
                            children: [
                              Expanded(
                                child: _NhieResponseButton(
                                  label: context.l10n.nhieIHave,
                                  emoji: '✋',
                                  color: AppColors.errorRed,
                                  onTap: () => game.vote(
                                    true,
                                    message: _msgCtrl.text.trim(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _NhieResponseButton(
                                  label: context.l10n.nhieNever,
                                  emoji: '❌',
                                  color: _kNhieVivid,
                                  onTap: () => game.vote(
                                    false,
                                    message: _msgCtrl.text.trim(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (!allVoted && hasVoted) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _kNhieVivid.withValues(alpha: 0.14),
                                  _kNhieVivid.withValues(alpha: 0.04),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _kNhieVivid.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Item 4 — the player's own choice, shown
                                // as a large animated icon the moment
                                // it's recorded, while still waiting on
                                // the rest of the table.
                                _NhieChoiceRevealIcon(
                                  haveI:
                                      state.voteEntries[game.userId]?.haveI ??
                                      false,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      context.l10n.nhieWaitingCount(
                                        state.voteEntries.length,
                                        game.activePlayerCount,
                                      ),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: 0.04, end: 0),
                        ] else if (allVoted) ...[
                          // Item 5 (result-screen pass) — visually
                          // prominent completion state, matching the
                          // same chip Meme's results screen uses.
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ResultCompletionChip(
                                responded: state.voteEntries.length,
                                total: state.playerOrder
                                    .where(
                                      (id) => !game.awayPlayerIds.contains(id),
                                    )
                                    .length,
                              ),
                            ),
                          ),
                          // Item 1/4/5 — a player who never responded
                          // before the timer closed the round (no entry
                          // in voteEntries) still reaches this same
                          // results/ready-for-next-round state as
                          // everyone else — this banner is purely
                          // informational, not a dead end the way the
                          // old standalone "Time's Up" screen was.
                          if (!hasVoted)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.warningAmber.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.warningAmber.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '⏱️',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.l10n.nhieTimedOut,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(),
                          DishonestReasonsPanel(
                            fetch: game.getMyDishonestReasons,
                            key: ValueKey(
                              'nhie_dishonest_${state.roundNumber}',
                            ),
                          ),
                          // Flexible (not Expanded) so this list only
                          // takes the room left after the card above —
                          // scrolls internally instead of overflowing
                          // when many players have responded (item 12).
                          //
                          // Item 4/5 (result-screen pass) — this now
                          // iterates the round's full active roster
                          // (state.playerOrder, minus away/disconnected
                          // players), not just state.voteEntries.keys.
                          // A player who never voted before the timer
                          // closed the round previously had NO row at
                          // all here (see PlayerResultTile's own doc
                          // comment) — indistinguishable from "this
                          // screen is still loading". They now get an
                          // explicit PlayerResultStatus.timedOut row.
                          // NHIE has no separate Skip action (only a
                          // timer), so every non-voter here is
                          // genuinely a timeout, determined from real
                          // state (absence from voteEntries), never
                          // from response text.
                          Flexible(
                            child: Builder(
                              builder: (context) {
                                final respondedIds = state.voteEntries.keys
                                    .toSet();
                                final nonResponderIds = state.playerOrder
                                    .where(
                                      (id) =>
                                          !respondedIds.contains(id) &&
                                          !game.awayPlayerIds.contains(id),
                                    )
                                    .toList();
                                final respondedTiles = state.voteEntries.entries
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((indexed) {
                                      final i = indexed.key;
                                      final e = indexed.value;
                                      final isMe = e.key == game.userId;
                                      final color = e.value.haveI
                                          ? AppColors.errorRed
                                          : _kNhieVivid;
                                      final member = nhieRoomMemberFor(
                                        game,
                                        e.key,
                                      );
                                      return PlayerResultTile(
                                            key: ValueKey('nhie_r_${e.key}'),
                                            avatarUrl: member?.avatarUrl,
                                            avatarConfig: member?.avatarConfig,
                                            isPremium:
                                                member?.isPremium ?? false,
                                            displayName: _name(e.key),
                                            status:
                                                PlayerResultStatus.responded,
                                            isViewer: isMe,
                                            accentColor: _kNhieVivid,
                                            responseContent: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                HonestyScoreLine(
                                                  honestyPoints:
                                                      member?.honestyPoints ??
                                                      0,
                                                  generalScore:
                                                      member?.generalScore ?? 0,
                                                  iconSize: 10,
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: color.withValues(
                                                      alpha: 0.14,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    e.value.haveI
                                                        ? '✋ ${context.l10n.nhieIHave}'
                                                        : '❌ ${context.l10n.nhieNever}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 12,
                                                      color: color,
                                                    ),
                                                  ),
                                                ),
                                                if (e.value.message.isNotEmpty)
                                                  // Item 18.3 — this IS the
                                                  // player's response, not
                                                  // metadata; larger and
                                                  // stronger than the old
                                                  // muted bodySmall italic,
                                                  // scaling down only if
                                                  // genuinely long.
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                    child: ResponsiveGameText(
                                                      context.l10n
                                                          .todQuotedResponse(
                                                            e.value.message,
                                                          ),
                                                      maxLines: 3,
                                                      style:
                                                          theme
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: theme
                                                                    .colorScheme
                                                                    .onSurface,
                                                              ) ??
                                                          const TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            trailing:
                                                (game
                                                        .config
                                                        ?.honestyVoteEnabled ??
                                                    true)
                                                ? CompactHonestyVoteButtons(
                                                    voterId: game.userId,
                                                    targetUserId: e.key,
                                                    participantIds:
                                                        state.playerOrder,
                                                    responseKey:
                                                        'round:${state.roundNumber}',
                                                    hasVoted: game.hasVotedHonesty(
                                                      'round:${state.roundNumber}',
                                                      e.key,
                                                    ),
                                                    onVote:
                                                        game.castHonestyVote,
                                                  )
                                                : null,
                                          )
                                          .animate(delay: (i * 50).ms)
                                          .fadeIn()
                                          .slideX(begin: 0.03, end: 0);
                                    });
                                final nonResponderTiles = nonResponderIds.map((
                                  id,
                                ) {
                                  final member = nhieRoomMemberFor(game, id);
                                  return PlayerResultTile(
                                    key: ValueKey('nhie_nr_$id'),
                                    avatarUrl: member?.avatarUrl,
                                    avatarConfig: member?.avatarConfig,
                                    isPremium: member?.isPremium ?? false,
                                    displayName: _name(id),
                                    status: PlayerResultStatus.timedOut,
                                    isViewer: id == game.userId,
                                    accentColor: _kNhieVivid,
                                  ).animate().fadeIn();
                                });
                                return ListView(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  children:
                                      [...respondedTiles, ...nonResponderTiles]
                                          .map(
                                            (w) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              child: w,
                                            ),
                                          )
                                          .toList(),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (game.canAdvanceTurnHere) ...[
                            if (!game.allPlayersVoted)
                              Text(
                                context.l10n.nhieAnsweredCount(
                                  game.votedCount,
                                  game.activePlayerCount,
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              )
                            else if (!game.allOthersReady)
                              Text(
                                context.l10n.nhieWaitingForPlayersReady,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 46,
                              child: FilledButton(
                                onPressed:
                                    (game.allPlayersVoted &&
                                        game.allOthersReady)
                                    ? () => game.requestAdvanceTurn()
                                    : null,
                                child: Text(context.l10n.nhieNextCard),
                              ),
                            ),
                            if (game.isOwner)
                              Builder(
                                builder: (ctx) {
                                  final isPremium =
                                      ctx
                                          .read<AuthProvider>()
                                          .currentUser
                                          ?.isPremium ??
                                      false;
                                  if (!isPremium)
                                    return const SizedBox.shrink();
                                  return TextButton.icon(
                                    onPressed: () =>
                                        _showAddCustomCardSheet(ctx, game),
                                    icon: const Icon(
                                      Icons.add_card_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      ctx.l10n.todAddCustomCardButton,
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          theme.colorScheme.primary,
                                    ),
                                  );
                                },
                              ),
                          ] else if (widget.isSpectator)
                            Text(
                              context.l10n.todSpectatingWaitingHost,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          else if (game.hasMarkedReady)
                            Text(
                              context.l10n.todReadyWaitingHost,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.tealGreen,
                              ),
                            )
                          else
                            SizedBox(
                              height: 46,
                              child: FilledButton(
                                onPressed: game.markReadyForNext,
                                child: Text(context.l10n.nhieReadyForNextRound),
                              ),
                            ),
                        ],

                        const SizedBox(height: 8),
                        if (reactionTally.isNotEmpty ||
                            avatarReactions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                // Emoji reactions: aggregated with a count.
                                for (final e in reactionTally.entries)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ReactionDisplay(value: e.key, size: 13),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${e.value}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Avatar reactions: one per reactor, each using
                                // the REACTOR's own avatar config.
                                for (final r in avatarReactions)
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: ReactionDisplay(
                                      value: r.sticker,
                                      size: 13,
                                      avatarConfig: game.roomProvider
                                          ?.memberById(r.userId)
                                          ?.avatarConfig,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        EmojiReactionRow(
                          reactionsByEmoji: const {},
                          // Real-device bug: reacting before this player
                          // has actually voted was interactive and
                          // reachable. EmojiReactionRow already hides its
                          // picker entry points whenever alreadyReacted is
                          // true (see Sticker.dart) — reusing that exact
                          // mechanism means "hasn't voted yet" simply
                          // looks like "nothing to react with yet", and
                          // reverts to the normal alreadyReacted-only
                          // behavior the instant hasVoted flips true. The
                          // engine's own voteEntries guard (see
                          // NeverHaveIEverEngine._handleReaction) remains
                          // the authoritative enforcement — this is only
                          // the matching UI-side prevention.
                          alreadyReacted: hasReacted || !hasVoted,
                          onReact: game.sendReaction,
                          useAvatarMode:
                              context
                                  .read<AuthProvider>()
                                  .currentUser
                                  ?.isPremiumActive ??
                              false,
                          ownAvatarConfig: context
                              .read<AuthProvider>()
                              .currentUser
                              ?.avatarConfig,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // History overlay (item 2 fix) — a COVER, not a replacement:
          // the main-game PopScope/Scaffold above is never removed
          // from the tree, so _nhieShowcaseKey's tutorialShowcase
          // target (and its always-active showcaseview Overlay/portal
          // side effect) is never torn down by toggling History. See
          // this screen's own build()-start comment and
          // tod_game_screen.dart's matching fix for the full
          // explanation.
          if (_showHistory)
            Positioned.fill(
              child: Scaffold(
                appBar: AppBar(
                  leading: BackButton(
                    onPressed: () => setState(() => _showHistory = false),
                  ),
                  title: Text(context.l10n.nhieGameHistoryTitle),
                ),
                body: _HistoryPanel(
                  history: state.history,
                  displayNames: widget.displayNames,
                  onClose: () => setState(() => _showHistory = false),
                  avatarConfigResolver: (uid) =>
                      widget.game.roomProvider?.memberById(uid)?.avatarConfig,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _showAddCustomCardSheet(BuildContext ctx, NhieGameProvider game) {
  final ctrl = TextEditingController();
  bool submitting = false;

  showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (_, setS) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(sheetCtx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_card_outlined),
                  const SizedBox(width: 8),
                  Text(
                    sheetCtx.l10n.todAddCustomCardTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    sheetCtx.l10n.premiumBadge,
                    style: const TextStyle(color: Colors.amber, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                sheetCtx.l10n.todCustomCardSessionOnly,
                style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(sheetCtx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLength: 300,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: sheetCtx.l10n.nhieCardPromptHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: submitting
                    ? null
                    : () async {
                        if (ctrl.text.trim().length < 5) return;
                        setS(() => submitting = true);
                        final result = await game.addCustomCard(
                          content: ctrl.text.trim(),
                        );
                        if (sheetCtx.mounted) {
                          Navigator.of(sheetCtx).pop();
                          if (!result.success && ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(switch (result.error) {
                                  'game_not_started_yet' =>
                                    ctx.l10n.gameNotStartedYet,
                                  'game_not_ready' => ctx.l10n.gameNotReady,
                                  _ => result.error ?? ctx.l10n.failed,
                                }),
                              ),
                            );
                          } else if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(ctx.l10n.todCustomCardAdded),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                child: submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(sheetCtx.l10n.todAddCardToDeck),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Persistent round/timer HUD strip — a rounded, gradient party-chrome pill
/// mirroring TodHud's structure (round badge, timer badge, player count)
/// with NHIE's own green identity. Purely presentational: reads
/// state.roundNumber/maxRounds, state.votes.length/game.activePlayerCount,
/// and game.timerIsRunning/timerRemaining — never derives or mutates any
/// of them. The timer badge only appears while a round is actually
/// counting down, so nothing is reserved when the timer is off.
class _NhieHud extends StatelessWidget {
  const _NhieHud({required this.state, required this.game});
  final NhieState state;
  final NhieGameProvider game;

  @override
  Widget build(BuildContext context) {
    final progress = state.maxRounds > 0
        ? state.roundNumber / state.maxRounds
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kNhieDeep, _kNhieVivid],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kNhieDeep.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                color: _kNhieAccent,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🙊', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text(
                      context.l10n.todRoundBadge(
                        state.roundNumber,
                        state.maxRounds,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (game.timerIsRunning)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: _NhieTimerBadge(
                    deadlineMs: state.timerStartedAt,
                    totalSeconds: game.config?.turnTimerSeconds ?? 0,
                  ).animate().fadeIn(),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.l10n.nhieAnsweredCount(
                    state.votes.length,
                    game.activePlayerCount,
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _kNhieDeep,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Item 2/3 (real-device follow-up) root-cause fix: this used to be a
/// StatelessWidget fed a precomputed `seconds` value from
/// NhieGameProvider.timerRemaining, which only changes on the PROVIDER's
/// own Timer.periodic tick calling notifyListeners() — on-device that
/// left the visible number frozen at its initial value until some
/// unrelated interaction caused a rebuild, even though the provider's own
/// ticker (and the authoritative timeout it eventually dispatches) was
/// running correctly the whole time. Rather than chase exactly why that
/// notifyListeners() cadence wasn't reliably reaching this Consumer chain
/// on-device, this widget now owns a second, PURELY PRESENTATIONAL
/// Timer.periodic — it never dispatches any event and never touches
/// provider/engine state, it only calls setState() to redraw itself once
/// a second, recomputing `remaining` fresh from the same authoritative
/// `deadlineMs` (state.timerStartedAt) the provider itself derives from.
/// The provider's own ticker (NhieGameProvider._syncTimer) remains the
/// ONLY thing that can fire NhieTimerExpiredEvent — this widget is
/// display-only and is guaranteed to redraw every second regardless of
/// how/when the provider's own notifications land.
class _NhieTimerBadge extends StatefulWidget {
  const _NhieTimerBadge({required this.deadlineMs, required this.totalSeconds});
  final int? deadlineMs;
  final int totalSeconds;

  @override
  State<_NhieTimerBadge> createState() => _NhieTimerBadgeState();
}

class _NhieTimerBadgeState extends State<_NhieTimerBadge> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _restartTicker();
  }

  @override
  void didUpdateWidget(covariant _NhieTimerBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new round/reconnect carries a new deadline — restart so the very
    // next tick lands exactly a second from now instead of drifting from
    // whenever the previous round's ticker happened to last fire.
    if (oldWidget.deadlineMs != widget.deadlineMs) _restartTicker();
  }

  void _restartTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int get _seconds {
    final deadline = widget.deadlineMs;
    if (deadline == null || widget.totalSeconds <= 0) return 0;
    final elapsed = (DateTime.now().millisecondsSinceEpoch - deadline) ~/ 1000;
    return (widget.totalSeconds - elapsed).clamp(0, widget.totalSeconds);
  }

  Color _colorFor(int seconds) {
    if (seconds > 15) return Colors.white;
    if (seconds > 5) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _seconds;
    final color = _colorFor(seconds);
    final urgent = seconds <= 5;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.85)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            context.l10n.gameSettingsSeconds(seconds),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
    if (!urgent) return badge;
    return badge
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1.0,
          end: 1.08,
          duration: 500.ms,
          curve: Curves.easeInOut,
        );
  }
}

/// Item 4 — large, playful, highly-tappable response choice. Presentation
/// only: `onTap` is whatever the caller wired to `game.vote(...)`, the
/// authoritative accept/reject decision is entirely NeverHaveIEverEngine's
/// (see _handleVote's isVotingOpen/duplicate-vote guards) — this widget
/// has no game-state logic of its own.
class _NhieResponseButton extends StatefulWidget {
  const _NhieResponseButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_NhieResponseButton> createState() => _NhieResponseButtonState();
}

class _NhieResponseButtonState extends State<_NhieResponseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
            height: 124,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color, widget.color.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Frosted circular badge — same tactile "premium party
                // token" treatment ToD's Truth/Dare choice buttons use.
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Item 4 — the large animated icon shown once this player's own choice
/// has been recorded (reveal state, while waiting on the rest of the
/// table, and again on the final results). Reuses the app's existing
/// AnimatedEmoji/kAnimatedEmojiMap mechanism — no new animation framework.
class _NhieChoiceRevealIcon extends StatelessWidget {
  const _NhieChoiceRevealIcon({required this.haveI});
  final bool haveI;

  @override
  Widget build(BuildContext context) {
    final emoji = haveI ? '✋' : '❌';
    final asset = kAnimatedEmojiMap[emoji];
    if (asset == null) {
      return Text(emoji, style: const TextStyle(fontSize: 56));
    }
    return AnimatedEmoji(
      asset,
      size: 64,
      source: AnimatedEmojiSource.asset,
      errorWidget: Text(emoji, style: const TextStyle(fontSize: 56)),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.history,
    required this.displayNames,
    required this.onClose,
    this.avatarConfigResolver,
  });
  final List<NhieRoundRecord> history;
  final Map<String, String> displayNames;
  final VoidCallback onClose;

  /// Resolves a reacting user's avatar config by user_id, so an avatar-style
  /// reaction (value "avatar:<key>") renders as THAT user's real profile
  /// avatar instead of the raw token text. Null → emoji fallback.
  final Map<String, dynamic>? Function(String userId)? avatarConfigResolver;

  String _name(String id) =>
      displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.history_rounded),
          title: Text(
            context.l10n.todHistoryRoundsCount(history.length),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ),
        const Divider(height: 0),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: history.length,
            itemBuilder: (_, i) {
              final round = history[history.length - 1 - i];
              final haves = round.votes.values.where((v) => v.haveI).length;
              final nevers = round.votes.values.where((v) => !v.haveI).length;
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
                    round.card.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Vote counts as text, then each reaction rendered via the
                  // shared ReactionDisplay keyed to the REACTING user's avatar
                  // config — so an avatar-style reaction shows that user's real
                  // profile avatar instead of the raw "avatar:<key>" token.
                  subtitle: Row(
                    children: [
                      Text(
                        '✋ $haves  •  🙅 $nevers',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (round.reactions.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: round.reactions
                                .map(
                                  (r) => ReactionDisplay(
                                    value: r.sticker,
                                    size: 13,
                                    avatarConfig: avatarConfigResolver?.call(
                                      r.userId,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: round.votes.entries
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _name(e.key),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(e.value.haveI ? '✋' : '🙅'),
                                    if (e.value.message.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          context.l10n.todQuotedResponse(
                                            e.value.message,
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontStyle: FontStyle.italic,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GameOverScreen extends StatefulWidget {
  const _GameOverScreen({
    required this.game,
    required this.displayNames,
    required this.roomId,
  });
  final NhieGameProvider game;
  final Map<String, String> displayNames;
  final String roomId;
  @override
  State<_GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<_GameOverScreen> {
  bool _showHistory = false;
  String _name(String id) =>
      widget.displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

  @override
  Widget build(BuildContext context) {
    final scores = widget.game.state?.scores ?? {};
    final history = widget.game.state?.history ?? [];
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (_showHistory)
      return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.nhieGameHistoryTitle),
          leading: BackButton(
            onPressed: () => setState(() => _showHistory = false),
          ),
        ),
        body: _HistoryPanel(
          history: history,
          displayNames: widget.displayNames,
          onClose: () => setState(() => _showHistory = false),
          avatarConfigResolver: (uid) =>
              widget.game.roomProvider?.memberById(uid)?.avatarConfig,
        ),
      );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kNhieDeep, _kNhieVivid],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _kNhieDeep.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '🏆',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 64),
                    ).animate().scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 450.ms,
                      curve: Curves.elasticOut,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.todGameOverBang,
                      textAlign: TextAlign.center,
                      style: context.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      context.l10n.nhieMostDrinksWins,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.06, end: 0),
              const SizedBox(height: 20),
              Expanded(
                child: GameOverPodium(
                  entries: sorted,
                  nameOf: _name,
                  scoreLabelOf: (s) => context.l10n.nhieDrinksScore(s),
                  accentColor: _kNhieVivid,
                ),
              ),
              if (history.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showHistory = true),
                  icon: const Icon(Icons.history_rounded),
                  label: Text(
                    context.l10n.nhieViewHistoryCount(history.length),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => goToLobbyOrHome(
                    context,
                    widget.roomId,
                    roomProvider: widget.game.roomProvider,
                    isOwner: widget.game.isOwner,
                  ),
                  child: Text(context.l10n.gameBackToRoom),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemeNhiePausedOverlay extends StatefulWidget {
  const _MemeNhiePausedOverlay({required this.onLeave});
  final VoidCallback onLeave;
  @override
  State<_MemeNhiePausedOverlay> createState() => _MemeNhiePausedOverlayState();
}

class _MemeNhiePausedOverlayState extends State<_MemeNhiePausedOverlay>
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
  Widget build(BuildContext context) => Dialog.fullscreen(
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
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.todHostSteppedAway,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
