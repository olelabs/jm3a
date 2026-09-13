import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:jma3a/Sticker.dart';
import 'package:jma3a/core/data/honesty_vote_repository.dart';
import 'package:jma3a/core/services/image_url_signer.dart';
import 'package:jma3a/core/router/app_router.dart';
import 'package:jma3a/shared/widgets/cards/honesty_score_line.dart';
import 'package:jma3a/shared/widgets/game/dishonest_reasons_panel.dart';
import 'package:jma3a/shared/widgets/game/honesty_vote_buttons.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/presentation/widgets/game_screen_security_gate.dart';
import 'package:jma3a/features/games/meme_game/meme_game_engine.dart';
import 'package:jma3a/features/games/meme_game/sticker_pool_loader.dart';
import 'package:jma3a/features/games/truth_or_dare/data/tod_repository.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
import 'package:jma3a/features/packs/data/pack_repository.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/features/avatar/presentation/avatar_creator_screen.dart'
    show AvatarConfig;
import 'package:jma3a/shared/widgets/cards/user_avatar.dart';
import 'package:jma3a/features/rooms/presentation/room_provider.dart';
import 'package:jma3a/features/settings/presentation/screen_security_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jma3a/shared/widgets/animated_reaction_overlay.dart';
import 'package:jma3a/shared/widgets/game_rules_sheet.dart';
import 'package:jma3a/shared/widgets/no_active_players_banner.dart';
import 'package:jma3a/shared/widgets/join_requests_panel.dart';
import 'package:jma3a/shared/widgets/room_members_management_sheet.dart';
import 'package:jma3a/shared/widgets/overlays/host_reconnect_overlay.dart';
import '../game_session_messages.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/services/app_tutorial_service.dart';
import '../../../../shared/widgets/tutorial/screen_tutorial.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/targeted_chat_listener.dart';
// import '../../../../core/services/screen_security_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/overlays/branded_status_view.dart';
import '../../../shared/widgets/game/away_presence_snackbar_listener.dart';
import '../../../shared/widgets/game/game_chat_sheet.dart';
import '../../../shared/widgets/game/game_flip_card.dart';
import '../../../shared/widgets/game/game_over_podium.dart';
import '../../../shared/widgets/game/player_result_tile.dart';
import '../../../shared/widgets/game/responsive_game_text.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/game_end_navigation.dart';

enum MemeLoadState { idle, loading, ready, error, gameOver }

/// Meme's own party-chrome identity (deep amber-brown → vivid amber),
/// structurally the same "deliberately theme-independent dark chrome" as
/// ToD's/NHIE's, distinct color so each game in the family reads as itself.
const _kMemeDeep = Color(0xFF92400E);
const _kMemeVivid = Color(0xFFF59E0B);
const _kMemeAccent = Color(0xFFFFE066);

/// Looks up [userId]'s CURRENT room-member row from [game.roomProvider] —
/// the SAME single source of truth the lobby (MemberTile), ToD, and NHIE
/// read for honesty_points/general_score. See ToD's todRoomMemberFor for
/// the identical rationale/limitation.
RoomMemberEntity? memeRoomMemberFor(MemeGameProvider game, String userId) {
  final members = game.roomProvider?.members;
  if (members == null) return null;
  for (final m in members) {
    if (m.userId == userId) return m;
  }
  return null;
}

class MemeGameProvider extends ChangeNotifier {
  MemeGameProvider({
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

  // ── Sticker pool preload (correction pass) ───────────────────────────
  // See StickerPoolLoader's own doc comment for the full rationale — the
  // fetch-and-sign chain (pack_reactions, falling back to pack_stickers
  // signed via ImageUrlSigner) is wired in here, once, at construction;
  // the loader itself owns the memoization/precache mechanics and has no
  // Supabase/PackRepository dependency of its own (unit-testable with a
  // fake fetcher).
  late final StickerPoolLoader _stickerPoolLoader = StickerPoolLoader(
    fetch: (packId) async {
      var urls = await PackRepository.instance.getPackReactions(packId);
      // pack_reactions is a verified creator's own custom-uploaded
      // images; an admin-authored official Meme pack never has any
      // (create_official_pack_screen.dart has no Reactions step), so it
      // fell all the way through to the hardcoded kAppStickers preset
      // even when the admin picked a real sticker pool. Fall back to
      // that pool (pack_stickers) before giving up to the generic
      // preset — signed via the same ImageUrlSigner every other remote
      // pack image already goes through (cached, batched, graceful
      // fallback to raw URL).
      if (urls.isEmpty) {
        final stickerUrls = await PackRepository.instance.getPackStickers(
          packId,
        );
        if (stickerUrls.isNotEmpty) {
          final signed = await ImageUrlSigner.instance.signAll(stickerUrls);
          urls = stickerUrls.map((u) => signed[u] ?? u).toList();
          AppLogger.info(
            'MemeGame: loaded ${urls.length} pack stickers (pack_stickers pool) for $packId',
          );
        }
      } else {
        AppLogger.info(
          'MemeGame: loaded ${urls.length} pack reactions for $packId',
        );
      }
      return urls;
    },
  );

  List<String> get stickerPool => _stickerPoolLoader.pool;
  Future<List<String>> loadStickerPool(String packId) =>
      _stickerPoolLoader.load(packId);
  Future<void> precacheStickerPool(BuildContext context) =>
      _stickerPoolLoader.precache(context);

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

  MemeGameEngine? _engine;
  MemeLoadState _loadState = MemeLoadState.idle;

  // Guards every notifyListeners() call against firing after this provider
  // has been disposed — see NhieGameProvider's identical _safeNotify (and
  // TodGameProvider's original) for the full rationale; applied here for
  // parity so all three games fail the same way (never).
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

  // Shared between _MemeGameScreenState (owns the realtime listeners) and
  // memeShowLeaveDialog (called from PopScope and various back buttons) via
  // this single provider instance, so a programmatic pop triggered by a
  // realtime event (e.g. onGameEnded) doesn't get misread by PopScope as
  // the user backing out, which would incorrectly open the Quit Game
  // confirmation dialog.
  bool isNavigatingAway = false;

  MemeLoadState get loadState => _loadState;
  MemeState? get state => _engine?.currentState as MemeState?;
  String get userId => _userId;
  bool get isOwner => _isOwner;
  bool get canModerate => _isOwner || isModerator;

  // Mirrors MemeGameEngine's own authoritative "everyoneResponded" check
  // (votes.containsKey(id) || passes.contains(id) for every player) exactly.
  // The previous votes.length >= playerOrder.length comparison never counted
  // a pass — once even one player chose Pass instead of voting, votes.length
  // could never reach playerOrder.length and this stayed false forever, even
  // after every player had genuinely finished responding, leaving the
  // admin's Next Round button permanently disabled (gated on
  // allPlayersVoted && allOthersReady).
  bool get allPlayersVoted {
    final s = state;
    if (s == null) return true;
    // Item 6 — a timeout can close the submission phase with ZERO
    // submissions (nobody responded in time). There is then nothing for
    // any player to vote ON, so requiring an explicit vote/pass from
    // every player — the normal rule, correct whenever there's a real
    // candidate list — would strand this round forever: with no
    // submissions there's no per-candidate Pass button anywhere to
    // press. Vacuously "done" in that specific case only; a round with
    // real submissions still requires the real per-player check below.
    if (s.submissions.isEmpty) return true;
    return s.playerOrder.every(
      (id) => s.votes.containsKey(id) || s.passes.contains(id),
    );
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
      '[READY-DEBUG][meme] allOthersReady: others=$others '
      'readyForNext=$_readyForNext away=$_effectiveAwayIds -> $result',
    );
    return result;
  }

  void markPlayerAway(String userId, {bool forGood = false}) {
    _awayPlayerIds.add(userId);
    if (_isOwner && _engine != null) {
      Future.microtask(_autoFillAwayPlayers);
    }
    _safeNotify();
  }

  /// playerOrder is fixed for the life of the session — a kicked/left
  /// player is never removed from it, only added to _awayPlayerIds.
  /// Submission/vote completion is a simple count against
  /// playerOrder.length, so an away player who never acts would otherwise
  /// block every round from here on (not just the one they left during).
  /// Auto-fills on their behalf, bounded so it can't loop forever, and
  /// re-reads state each step since one fill can cascade into the next
  /// phase needing a fill too (e.g. the away player's auto-submission is
  /// the last one needed, flipping the round straight to voting).
  bool _autoFilling = false;
  void _autoFillAwayPlayers() {
    if (_autoFilling ||
        !_isOwner ||
        _engine == null ||
        _effectiveAwayIds.isEmpty) {
      return;
    }
    _autoFilling = true;
    final away = _effectiveAwayIds;
    final maxSteps = away.length * 2 + 1;
    for (var i = 0; i < maxSteps; i++) {
      final s = _engine!.currentState as MemeState;
      if (s.phase == MemePhase.submitting) {
        final uid = away.firstWhere(
          (id) => !s.submissions.containsKey(id),
          orElse: () => '',
        );
        if (uid.isNotEmpty) {
          onPlayerAction({
            'action': 'meme_submit',
            'user_id': uid,
            'caption': '',
            'sticker_choice': '',
            'ts': DateTime.now().millisecondsSinceEpoch,
          });
          continue;
        }
      } else if (s.phase == MemePhase.voting) {
        final uid = away.firstWhere(
          (id) => !s.votes.containsKey(id) && !s.passes.contains(id),
          orElse: () => '',
        );
        if (uid.isNotEmpty) {
          // Away players auto-PASS (not a random auto-vote) — a disconnected
          // player must never influence the winner, and a pass still completes
          // the round. Matches the optional-voting rule.
          onPlayerAction({
            'action': 'meme_pass',
            'user_id': uid,
            'ts': DateTime.now().millisecondsSinceEpoch,
          });
          continue;
        }
      }
      break;
    }
    _autoFilling = false;
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
      AppLogger.warning('MemeProvider: kickPlayerFromGame RPC failed: $e');
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
    // session: timerEnabled/turnTimerSeconds, etc. The ENGINE's own
    // internal copy of config was always correct (constructed with the
    // real `config` param further down), which is why non-owner clients
    // — whose initAsFollower already set this — and the broadcast round
    // state itself were both fine; only the owner's local UI reads of
    // `game.config` were affected.
    _config = config;
    _loadState = MemeLoadState.loading;
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
      final prompts = todCards
          .map((c) => MemePrompt(id: c.id, caption: c.content))
          .toList();

      _engine = MemeGameEngine(config, prompts: prompts);

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
            .eq('game_type', 'meme_game')
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
            .eq('game_type', 'meme_game')
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
              'MemeProvider: owner reconnect room-status re-check failed: $e',
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
                .eq('game_type', 'meme_game')
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
            _loadState = MemeLoadState.error;
            _safeNotify();
            return;
          }
        }

        // 'aborted' means this session was deliberately closed (auto-end,
        // host-disconnect timeout, quit) — not the engine's own natural
        // completion. This IS confirmed, authoritative evidence of
        // termination (unlike a null lookup above) — self-heal the room
        // status and send the owner back to the lobby. Only
        // 'active'/'completed' are valid.
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
          _loadState = MemeLoadState.error;
          _safeNotify();
          return;
        }
      }
      final snapshotGameType = existing?['game_type'] as String?;
      Map<String, dynamic>? existingSnapshot;
      if (snapshotGameType == 'meme_game') {
        existingSnapshot = existing?['state_snapshot'] as Map<String, dynamic>?;
      }

      if (existing != null &&
          existingSnapshot != null &&
          existingSnapshot.isNotEmpty) {
        _sessionId = existing['id'] as String;
        _engine!.restoreFromSnapshot(existingSnapshot);
        _syncTimer();
        _lifecycleState = existing['lifecycle_state'] as String? ?? 'active';
        AppLogger.info(
          'MemeProvider: resumed existing session $_sessionId '
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
            'MemeProvider: fresh member fetch failed, falling back to '
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
        // MemeLoadState.error.
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
            'p_game_type': 'meme_game',
            'p_player_ids': freshPlayerIds,
            'p_max_rounds': config.maxRounds,
            'p_turn_timer_secs': config.turnTimerSeconds,
            'p_allow_skip': config.allowSkip,
            'p_allow_spicy': config.allowSpicy,
            'p_state_snapshot': _engine!.serializeState(),
            // Items 2/3/8 — Meme's engine has no repeat mode at all (every
            // prompt is always unique within a game — see
            // meme_game_engine.dart's _usedPromptIds); always true, so the
            // server enforces Max Rounds <= actual prompt supply.
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
            'MemeProvider: failed to flip room to in_game after '
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
            _engine!.injectCard(MemePrompt(id: c.id, caption: c.content));
          }
          if (customCards.isNotEmpty) {
            AppLogger.info(
              'MemeProvider: merged ${customCards.length} custom cards into deck',
            );
          }
        } catch (e) {
          AppLogger.warning('MemeProvider: custom card load failed: $e');
        }
      }

      _loadState = _engine!.isGameOver
          ? MemeLoadState.gameOver
          : MemeLoadState.ready;
      _safeNotify();
      _broadcastState();

      if (_lifecycleState == 'starting' && _sessionId != null) {
        _startReadyBarrier(playerIds);
      }
    } catch (e) {
      _error = e.toString();
      _loadState = MemeLoadState.error;
      AppLogger.error('MemeProvider: init failed', error: e);
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
          'MemeProvider: ready barrier TIMEOUT room=$_roomId '
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
      AppLogger.warning('MemeProvider: confirmSessionReady failed: $e');
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
          'MemeProvider: session_active poll gave up room=$_roomId '
          'session=$_sessionId',
        );
        _error = 'Could not confirm the game started. Please rejoin.';
        _loadState = MemeLoadState.error;
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
        AppLogger.warning('MemeProvider: session_active poll failed: $e');
      }
    });
  }

  Timer? _syncTimeoutTimer;
  String? _packId;
  GameConfig? _config;
  GameConfig? get config => _config;

  // ── Round timer (item 1) ─────────────────────────────────────────────
  // Same architecture as TodGameProvider._syncTimer/NhieGameProvider's
  // identical copy — the DEADLINE lives in state.timerStartedAt (set/
  // cleared by the engine), never in this local countdown value, so a
  // rebuild/resubscribe/reconnect never "restarts" anything: it just
  // re-derives remaining time from `now - timerStartedAt`. Only the
  // OWNER's local ticker ever dispatches the timeout event; everyone
  // else's ticker is purely cosmetic.
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
            MemeTimerExpiredEvent(
              userId: _userId,
              ts: DateTime.now().millisecondsSinceEpoch,
            ),
          );
          if (_engine!.isGameOver) _loadState = MemeLoadState.gameOver;
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
        'MemeProvider: no state broadcast for ${sinceLastState.inSeconds}s — requesting resync',
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
            'MemeProvider: resync request unanswered — reading state from DB',
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
    _loadState = MemeLoadState.loading;
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
        _loadState = MemeLoadState.error;
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
        'MemeProvider: _checkSessionLifecycleOnJoin failed: $e',
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
      final prompts = await _loadPrompts(_packId!, _config!);
      _engine = MemeGameEngine(_config!, prompts: prompts);
      _engine!.restoreFromSnapshot(state!.toMap());
    } catch (e) {
      AppLogger.error(
        'MemeProvider: ownership handoff engine build failed: $e',
      );
      return;
    }
    _isOwner = true;
    // Item 1 — host migration must preserve the timer, not restart it: the
    // new owner's ticker picks up from the SAME timerStartedAt the
    // restored state carries.
    _syncTimer();
    _safeNotify();
  }

  /// Loads this pack's deck as [MemePrompt]s — the same conversion
  /// [initAsOwner] performs, reused here for the ownership mid-game handoff.
  Future<List<MemePrompt>> _loadPrompts(
    String packId,
    GameConfig config,
  ) async {
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
    return todCards
        .map((c) => MemePrompt(id: c.id, caption: c.content))
        .toList();
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
          _loadState = MemeLoadState.error;
          _safeNotify();
          return;
        }
      } else {
        // _sessionId genuinely unknown yet — the only safe query here is
        // "the current ACTIVE session for this room", never "whatever
        // the latest session happens to be" (previously ordered by
        // started_at with no status filter at all — a returning player
        // could get silently dropped into an old, already-completed
        // game just because it was the most recent row).
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
      final Map<String, dynamic>? snapshot = snapshotGameType == 'meme_game'
          ? (row?['state_snapshot'] as Map<String, dynamic>?)
          : null;
      if (snapshot == null || snapshot.isEmpty) {
        _error = 'Could not recover session state. Please rejoin the room.';
        _loadState = MemeLoadState.error;
        _safeNotify();
        return;
      }

      _sessionId ??= row!['id'] as String?;
      // Weak-connection fallback must respect the ready barrier exactly
      // like every other path does.
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
      _engine ??= MemeGameEngine(
        const GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 60,
          allowSkip: false,
          allowSpicy: false,
        ),
        prompts: [],
      );
      _engine!.restoreFromSnapshot(snapshot);
      _loadState = _engine!.isGameOver
          ? MemeLoadState.gameOver
          : MemeLoadState.ready;
      _syncTimer();
      _lastStateReceivedAt = DateTime.now();
      _safeNotify();
    } catch (e) {
      _error = 'Reconnection failed: ${e.toString()}';
      _loadState = MemeLoadState.error;
      AppLogger.warning('MemeProvider: DB fallback load failed: $e');
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
      _engine?.injectCard(MemePrompt(id: card.id, caption: card.content));
      _safeNotify();
      _broadcastState();
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  Future<void> submit({String caption = '', String stickerChoice = ''}) =>
      _handleAction({
        'action': 'meme_submit',
        'caption': caption,
        'sticker_choice': stickerChoice,
      });

  Future<void> voteFor(String targetUserId) =>
      _handleAction({'action': 'meme_vote', 'target_user_id': targetUserId});

  /// Optional-voting opt-out: the player chooses not to vote this round. The
  /// authoritative engine records a pass (0 points) and still counts them
  /// toward round completion, so a passing player never blocks the round.
  Future<void> pass() => _handleAction({'action': 'meme_pass'});

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

  Future<void> reactTo(String targetUserId, String emoji) => _handleAction({
    'action': 'meme_react',
    'target_user_id': targetUserId,
    'emoji': emoji,
  });

  bool _advancing = false;

  Future<void> ownerAdvanceTurn({bool force = false}) async {
    if (!_isOwner || _engine == null) return;
    if (!force && !allOthersReady) return;
    // Explicit re-entrancy guard against a rapid double-tap triggering two
    // engine advances back to back.
    if (_advancing) return;
    _advancing = true;
    // Diagnostic snapshot for the "admin next-round red screen" report —
    // this is a real, not-yet-reproduced-in-this-sandbox crash (see final
    // report). Logged unconditionally (not just on error) so the state
    // immediately BEFORE the transition is on record even if the crash
    // happens during the subsequent widget rebuild, not inside this
    // method itself — a plain try/catch here couldn't see that, since
    // Flutter's build-phase exceptions never propagate back through the
    // call that triggered the rebuild.
    final preState = _engine!.currentState;
    AppLogger.info(
      'MEME_ADVANCE_TURN_START user=$_userId room=$_roomId session=$_sessionId '
      'role=${_isOwner ? 'owner' : 'follower'} round=${preState.roundNumber} '
      'phase=${preState.phase} playerOrder=${preState.playerOrder} '
      'submissions=${preState.submissions.length} votes=${preState.votes.length} '
      'passes=${preState.passes.length} readyCount=${_readyForNext.length} '
      'timerStartedAt=${preState.timerStartedAt} isOver=${preState.isOver}',
    );
    try {
      _readyForNext.clear();
      _myReadyIntent = false;
      _engine!.advanceTurn();
      _autoFillAwayPlayers();
      if (_engine!.isGameOver) _loadState = MemeLoadState.gameOver;
      _syncTimer();
      final postState = _engine!.currentState;
      AppLogger.info(
        'MEME_ADVANCE_TURN_OK user=$_userId room=$_roomId session=$_sessionId '
        'round=${postState.roundNumber} phase=${postState.phase} '
        'playerOrder=${postState.playerOrder} isOver=${postState.isOver} '
        'loadState=$_loadState timerStartedAt=${postState.timerStartedAt}',
      );
      _safeNotify();
      _broadcastState();
    } catch (e, st) {
      AppLogger.error(
        'MEME_ADVANCE_TURN_FAILED user=$_userId room=$_roomId '
        'session=$_sessionId preRound=${preState.roundNumber} '
        'prePhase=${preState.phase}',
        error: e,
        stackTrace: st,
      );
      rethrow;
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
      'action': 'meme_mod_advance_turn',
      'force': force,
      'user_id': _userId,
      'display_name': _displayName,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Durable "I intend to be ready for the current round" flag — unlike
  // _readyForNext (wholesale overwritten by each authoritative
  // meme_ready_count broadcast), this survives a broadcast that never
  // reached the owner, so onReadyCountUpdate can detect the mismatch and
  // resend instead of leaving the presser stuck forever.
  bool _myReadyIntent = false;

  Future<void> markReadyForNext() {
    final isPlayer = state?.playerOrder.contains(_userId) ?? false;
    AppLogger.debug(
      '[READY-DEBUG][meme] markReadyForNext called by $_userId '
      'isPlayer=$isPlayer hasMarkedReady=$hasMarkedReady',
    );
    if (_userId.isEmpty || hasMarkedReady || !isPlayer) return Future.value();
    _myReadyIntent = true;
    _readyForNext.add(_userId);
    _safeNotify();
    return _handleAction({'action': 'meme_ready_next'});
  }

  int _lastReadyCountTs = 0;

  void onReadyCountUpdate(
    List<String> readyUserIds, {
    int? ts,
    int? roundNumber,
  }) {
    AppLogger.debug('[READY-DEBUG][meme] onReadyCountUpdate: $readyUserIds');
    // A ready_count broadcast is only meaningful for the round it was
    // computed for. State-broadcast and ready-count travel as two separate
    // messages with no ordering guarantee between them — the very last
    // ready_count of a round (the one that made everyone ready and caused
    // the advance) can arrive AFTER the new round's state broadcast already
    // reset _readyForNext, and since its ts is not necessarily older than
    // _lastReadyCountTs it would otherwise slip past the ts guard below and
    // re-populate the stale, already-complete list for the round that just
    // ended. Tagging every ready_count with the round it belongs to and
    // rejecting a mismatch closes that gap regardless of ts ordering.
    if (roundNumber != null &&
        state?.roundNumber != null &&
        roundNumber != state!.roundNumber) {
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
    // Self-heal a lost meme_ready_next broadcast: if I intended to be
    // ready for this round but the owner's authoritative list doesn't
    // have me, resend rather than leaving myself and the host stuck.
    if (_myReadyIntent && !_readyForNext.contains(_userId)) {
      _readyForNext.add(_userId);
      _handleAction({'action': 'meme_ready_next'}).ignore();
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
          'MemeProvider: discarded state from stale session '
          '$payloadSessionId (current: $_sessionId)',
        );
        return;
      }
      // A follower previously only ever learned its own _sessionId via
      // the 8s DB-fallback timeout — the state broadcast already carries
      // it, just read it.
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
          // appearing) — mirrors NhieGameProvider's identical fix. The
          // ready-barrier's activation broadcast (see _activateSession)
          // carries the SAME state snapshot the round already started
          // with — nothing mutated it, so its snapshot_at is UNCHANGED —
          // only the lifecycle_state envelope field is new. The
          // staleness check just below (incomingTs <= currentTs)
          // therefore always discards this exact broadcast as a
          // duplicate and returns BEFORE ever reaching _syncTimer() at
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
          'MemeProvider: stale broadcast ts=$incomingTs discarded',
        );
        return;
      }
      final previousRound = state?.roundNumber;
      _syncTimeoutTimer?.cancel();
      _lastStateReceivedAt = DateTime.now();
      _engine ??= MemeGameEngine(
        const GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 60,
          allowSkip: false,
          allowSpicy: false,
        ),
        prompts: [],
      );
      _engine!.restoreFromSnapshot(snap);
      _loadState = _engine!.isGameOver
          ? MemeLoadState.gameOver
          : MemeLoadState.ready;
      if (previousRound != null && state?.roundNumber != previousRound) {
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
      AppLogger.warning('MemeProvider: restore failed: $e');
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
    // sender before applying any action. This game previously had NO
    // membership gate at all here (unlike ToD/NHIE's onPlayerAction,
    // which had one but keyed it — incorrectly — solely off
    // roomProvider.members; see those files' matching comments for the
    // full root-cause explanation of the "real players randomly treated
    // as spectators" bug that caused). Session membership
    // (state.playerOrder, fixed the instant the game starts, no async
    // dependency) is checked first and is what actually matters for "is
    // this a real player in this game"; roomProvider.members is only a
    // secondary gate for a removal that happened after the game started.
    final isSessionPlayer = state?.playerOrder.contains(uid) ?? false;
    if (!isSessionPlayer) {
      AppLogger.warning(
        'MemeProvider: rejected action "$action" from non-session-player $uid',
      );
      return;
    }
    final members = roomProvider?.members;
    if (members != null && !members.any((m) => m.userId == uid)) {
      AppLogger.warning(
        'MemeProvider: rejected action "$action" from removed member $uid',
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
        'MemeProvider: rejected action "$action" from stale session '
        '$payloadSessionId (current: $_sessionId)',
      );
      return;
    }
    if (action == 'meme_mod_advance_turn') {
      if (_isAllowed(uid, 'advance_turn')) {
        ownerAdvanceTurn(force: payload['force'] as bool? ?? false);
      }
      return;
    }
    if (action == 'meme_ready_next') {
      final isPlayer = state?.playerOrder.contains(uid) ?? false;
      AppLogger.debug(
        '[READY-DEBUG][meme] onPlayerAction ready_next from $uid '
        'isPlayer=$isPlayer current=$_readyForNext',
      );
      if (isPlayer && _readyForNext.add(uid)) {
        AppLogger.debug(
          '[READY-DEBUG][meme] rebroadcasting ready_count: $_readyForNext',
        );
        _safeNotify();
        final broadcastTs = DateTime.now().millisecondsSinceEpoch;
        _lastReadyCountTs = broadcastTs;
        _realtime.broadcastRoomEvent(_roomId ?? '', {
          'type': 'meme_ready_count',
          'ready_user_ids': _readyForNext.toList(),
          'ts': broadcastTs,
          'round_number': state?.roundNumber,
        }).ignore();
      }
      return;
    }
    switch (action) {
      case 'meme_submit':
        _engine!.handleEvent(
          MemeSubmitEvent(
            userId: uid,
            ts: ts,
            caption: payload['caption'] as String? ?? '',
            stickerChoice: payload['sticker_choice'] as String? ?? '',
          ),
        );
      case 'meme_vote':
        _engine!.handleEvent(
          MemeVoteEvent(
            userId: uid,
            ts: ts,
            targetUserId: payload['target_user_id'] as String? ?? '',
          ),
        );
      case 'meme_pass':
        _engine!.handleEvent(MemePassEvent(userId: uid, ts: ts));
      case 'meme_react':
        // Reaction-before-response real-device bug: the engine's own
        // guard (submissions.containsKey) already rejects this —
        // returning the EXACT SAME state object — but a rejected reaction
        // must be a complete no-op end to end, not just "no visible state
        // change". Without this early return, a rejected reaction still
        // fell through to _syncTimer()/_broadcastState() below like any
        // other action — harmless by itself, but an unnecessary
        // timer-recompute + state rebroadcast triggered by an action that
        // was supposed to do nothing. A stale/duplicate/double-tapped
        // reaction hits this same guard every time (identical() stays
        // true), so it can never touch the timer no matter how many times
        // it's retried.
        final before = _engine!.currentState;
        _engine!.handleEvent(
          MemeReactEvent(
            userId: uid,
            ts: ts,
            targetUserId: payload['target_user_id'] as String? ?? '',
            emoji: payload['emoji'] as String? ?? '👍',
          ),
        );
        if (identical(_engine!.currentState, before)) return;
    }
    // A real action here can flip the phase (e.g. the last real submission
    // opens voting) — re-check for any away player who now needs an
    // auto-fill in the new phase.
    _autoFillAwayPlayers();
    if (_engine!.isGameOver) _loadState = MemeLoadState.gameOver;
    // Item 1 — a submission may have just closed the submitting phase
    // early (allIn), which clears state.timerStartedAt; re-derive so the
    // owner's own ticker stops immediately instead of firing a
    // now-meaningless timeout.
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
      'type': 'meme_ready_count',
      'ready_user_ids': _readyForNext.toList(),
      'ts': broadcastTs,
      'round_number': state?.roundNumber,
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
    // sync timing. This game previously had no membership gate at all
    // here (unlike ToD/NHIE's _handleAction, which had one — but keyed
    // it, incorrectly, off roomProvider.currentMember alone; see those
    // files' matching comments). Checking session membership FIRST is
    // what actually matters for "is this a real player in this game".
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
              AppLogger.warning('MemeProvider: snapshot save failed: $e');
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

void _showAddCustomCardSheet(BuildContext ctx, MemeGameProvider game) {
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
                sheetCtx.l10n.memeCustomPromptSessionOnly,
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
                  hintText: sheetCtx.l10n.memeWritePromptHint,
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

Future<void> memeShowLeaveDialog(
  BuildContext ctx, {
  required String roomId,
  required bool isOwner,
  String displayName = 'A player',
  MemeGameProvider? game,
}) async {
  if (!ctx.mounted) return;
  final myUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
  final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

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

  if (isOwner) {
    // Quit Game only ends the current game session — it must NOT close
    // or delete the room. Closing the room is a separate action, only
    // available from LobbyScreen's room management. Use the dedicated
    // game-ended broadcast (not 'owner_left') so every player's existing
    // onGameEnded handler fires immediately and pops back to this same
    // room's lobby — no dialog required on the receiving end.
    try {
      await sl.realtimeService.broadcastGameEnded(roomId, {
        'reason': 'host_quit_to_lobby',
        'session_id': game?.sessionId,
      });
      await sl.roomRepository.updateStatus(roomId, RoomStatus.waiting);
    } catch (_) {}
    if (ctx.mounted) {
      // Mark this as a programmatic exit before popping, so PopScope
      // (which shares this same MemeGameProvider instance) doesn't
      // mistake it for the user backing out and open Quit Game again.
      game?.isNavigatingAway = true;
      if (ctx.canPop()) {
        ctx.pop();
      } else {
        AppRouter.router.go('/home/room/$roomId');
      }
    }
    return;
  }
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

class MemeGameScreen extends StatefulWidget {
  const MemeGameScreen({
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
  State<MemeGameScreen> createState() => _MemeGameScreenState();
}

class _MemeGameScreenState extends State<MemeGameScreen> {
  late final MemeGameProvider _provider;

  // Tracks whether we've reached `subscribed` before, so a later reconnect
  // (network drop, backgrounding) also triggers a fresh sync request —
  // Realtime Broadcast has no delivery guarantee or replay, so state
  // broadcasts sent while disconnected are permanently missed otherwise.
  bool _hasEverSubscribed = false;

  // Route-level back guard (GameScreenSecurityGate) — see the TOD screen's
  // matching comment. Back closes the in-game history sub-view first (if open),
  // then routes through the existing quit flow, the same single guarded path
  // every other game uses.
  GameBackController? _backGuard;

  // In-game round history — same current-game history capability the other
  // games have, now available WHILE the meme game is running. Toggled here (not
  // per-phase) so the single back guard below always sees it; the game route
  // itself never pops while it's open (GameScreenSecurityGate.canPop:false).
  bool _showHistory = false;

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

  Future<bool> _handleGameBack() async {
    if (!mounted) return true;
    // Back dismisses the history sub-view first — it never escapes the game.
    if (_showHistory) {
      setState(() => _showHistory = false);
      return true;
    }
    if (_provider.isNavigatingAway) return true;
    await memeShowLeaveDialog(
      context,
      roomId: widget.roomId,
      isOwner: widget.isOwner,
      game: _provider,
      displayName:
          widget.playerDisplayNames[Supabase
                  .instance
                  .client
                  .auth
                  .currentUser
                  ?.id ??
              ''] ??
          context.l10n.defaultPlayerName,
    );
    return true;
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
    final user = context.read<AuthProvider>().currentUser!;
    _provider = MemeGameProvider(
      realtimeService: sl.realtimeService,
      userId: user.id,
      displayName: user.displayName ?? user.username ?? context.l10n.packPlayer,
      isModerator: widget.isModerator,
    );
    // Sticker preload correction pass — kicked off immediately, once, for
    // the whole game (not per-round) so by the time any player actually
    // reaches a submit phase the pool is very likely already fetched and
    // its images already precached — see MemeGameProvider.loadStickerPool/
    // precacheStickerPool's own comments. Fire-and-forget: _SubmitScreen
    // itself awaits the same memoized future and shows its own existing
    // loading state for the (rare) case a round is reached before this
    // finishes, rather than blocking this whole screen on it.
    _provider.loadStickerPool(widget.packId).then((_) {
      if (mounted) _provider.precacheStickerPool(context);
    });
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
            'MemeGameScreen: ignoring game_ended for stale session '
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
          // Mark this as a programmatic exit before popping, so PopScope
          // (which shares this same MemeGameProvider instance) doesn't
          // mistake it for the user backing out and open Quit Game.
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
            AppRouter.router.go('/home/room/${widget.roomId}');
        }
      },
      onRoomEvent: (p) {
        final type = p['type'] as String?;
        if (type == 'session_ready') {
          final sessionId = p['session_id'] as String?;
          final userId = p['user_id'] as String?;
          if (sessionId != null &&
              userId != null &&
              sessionId == _provider.sessionId) {
            _provider.handleSessionReadyEvent(userId);
          }
          return;
        }
        if (type == 'meme_ready_count') {
          final ids = (p['ready_user_ids'] as List?)?.cast<String>() ?? [];
          _provider.onReadyCountUpdate(
            ids,
            ts: p['ts'] as int?,
            roundNumber: p['round_number'] as int?,
          );
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
        if (type == 'game_ended' && mounted) {
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
        if (type == 'player_left' && mounted) {
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
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
        // RoomProvider's manual-transfer and automatic-failover paths both
        // broadcast 'ownership_transfer' (see room_provider.dart) — this
        // previously only matched 'ownership_transferred', so it never
        // fired for either of those.
        if ((type == 'ownership_transferred' || type == 'ownership_transfer') &&
            mounted) {
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

        if ((type == 'room_closed' || type == 'owner_left') && mounted) {
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
          // vote/submission indefinitely even though they'd already been
          // removed from the room. Mark them away for everyone.
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
    for (final id in state.playerOrder) {
      final member = rp.members.where((m) => m.userId == id).firstOrNull;
      // A muted player is exactly as ineligible for a turn as a
      // disconnected one — see TodGameScreen's identical fix.
      final isPresent =
          member != null && !member.isDisconnected && !member.isGameMuted;
      final isAway = _provider.awayPlayerIds.contains(id);
      if (isPresent && isAway) {
        _provider.markPlayerReturned(id);
      } else if (!isPresent && !isAway) {
        _provider.markPlayerAway(id);
      }
    }
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
      if (mounted && _provider.loadState == MemeLoadState.loading) {
        sl.realtimeService
            .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
            .ignore();
      }
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _provider.loadState == MemeLoadState.loading) {
        sl.realtimeService
            .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
            .ignore();
      }
    });
  }

  @override
  void dispose() {
    _backGuard?.unregister(_handleGameBack);
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
    // every phase this screen can render (submitting/voting/results) without
    // needing to be threaded into each phase's own Scaffold individually.
    return _wrapAwayListener(
      Stack(
        children: [
          _buildContent(context),
          // Same current-game history affordance the other games expose, plus
          // (item 4) the same shared in-game chat ToD/NHIE already have —
          // placed once here so every phase gets both.
          //
          // The round timer (item 1) previously floated here as a bare
          // TodTimerRing Positioned at a hardcoded `right: 4` — RTL-unsafe,
          // and visually disconnected from the actual prompt card. The
          // engine only ever runs the timer during MemePhase.submitting (see
          // MemeGameEngine._onTimerExpired's own phase guard), so it now
          // lives inside _SubmitScreen's own _MemeHud, directly above the
          // prompt card it actually times — same timerIsRunning/
          // timerRemaining/config.turnTimerSeconds data, no engine change.
          RoomMembersFab(
            roomProvider: widget.roomProvider,
            gameKickPlayer: _provider.kickPlayerFromGame,
            gameBanPlayer: _provider.banPlayerFromGame,
            heroTag: 'meme_members_${widget.roomId}',
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
              child: Consumer<MemeGameProvider>(
                builder: (ctx, game, _) => AnimatedReactionOverlay(
                  reactions: (game.state?.reactions ?? const [])
                      .map(
                        (r) => (emoji: r.emoji, ts: r.ts, userId: r.reactorId),
                      )
                      .toList(),
                  avatarResolver: widget.roomProvider?.memberById,
                ),
              ),
            ),
          ),
          // In-game history overlay (item 2, real-device report: iOS
          // red-screen crash root-cause fix) — rendered ABOVE _buildContent
          // as a Stack layer, not as an early `return` that replaced it
          // entirely: the old version fully UNMOUNTED _buildContent (and
          // therefore _SubmitScreen's own ScreenTutorial(tutorialId:
          // TutorialIds.memeIntro, ...)) the instant History opened, which
          // could race a still-in-flight first-time tour into
          // showcaseview's uncaught LateInitializationError crash — see
          // ScreenTutorial's own doc comments for the full mechanism. Now
          // _buildContent stays mounted underneath (matching this stack's
          // own pre-existing "rendered ABOVE all phases so it's reachable
          // while the game is running" comment, which the early-return
          // version never actually honored), gated by GameScreenSecurityGate
          // exactly as before (a system back closes it via
          // _handleGameBack; the game route never pops under it).
          if (_showHistory)
            Positioned.fill(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(context.l10n.nhieGameHistoryTitle),
                  leading: BackButton(
                    onPressed: () => setState(() => _showHistory = false),
                  ),
                ),
                body: _HistoryPanel(
                  history: _provider.state?.history ?? const [],
                  displayNames: widget.playerDisplayNames,
                  onClose: () => setState(() => _showHistory = false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return PopScope(
      // Redundant route-pop blocker only; the back ACTION is handled once by
      // GameScreenSecurityGate via _handleGameBack (registered above). See the
      // TOD screen's matching note.
      canPop: false,
      onPopInvoked: (_) {},
      child: ChangeNotifierProvider.value(
        value: _provider,
        child: Consumer<MemeGameProvider>(
          builder: (ctx, game, _) {
            // Host disconnected mid-game — takes priority over everything
            // else. NEVER shown to the OWNER themselves (they ARE the host);
            // this is what removes the brief "waiting for admin" flash on
            // the admin's own reconnect. See tod_game_screen.dart's gate.
            if (widget.roomProvider?.isPausedForHostReconnect == true &&
                widget.roomProvider?.isOwner != true) {
              return HostReconnectOverlay(roomProvider: widget.roomProvider!);
            }
            if (game.loadState == MemeLoadState.loading)
              return BrandedStatusView(
                emoji: '😹',
                title: context.l10n.gameNameMeme,
                subtitle: context.l10n.todLoadingGame,
                accent: AppColors.brandOrangeMid,
              );
            // A definitive failure must take priority over "still
            // starting" — game.isSessionStarting (_lifecycleState ==
            // 'starting') stays true forever once session creation fails
            // (nothing ever advances it past 'starting'), so checking
            // isSessionStarting before this error branch made a real,
            // already-surfaced error permanently unreachable in the UI:
            // the "waiting for players" spinner below would win every
            // single build, masking the error completely and presenting
            // as an infinite loading screen with no indication anything
            // had gone wrong. This check must come BEFORE isSessionStarting
            // for exactly that reason.
            if (game.loadState == MemeLoadState.error) {
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
                // alive underneath this pushed game route over go(), which
                // may not resolve the Future _pushGameRoute is awaiting to
                // clear its _navigatedToGame guard — leaving a second game
                // in this same room permanently unable to navigate. Same
                // pattern as goToLobbyOrHome/onGameEnded.
                if (context.mounted) {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    // Room still exists (session ended/failed to start,
                    // e.g. a player kicked during loading) — return to its
                    // LOBBY, not app home. See _leaveIfRoomNoLongerActive.
                    context.go('/home/room/${widget.roomId}');
                  }
                }
              }

              // Session-ended is not a real error to read/dismiss — it's
              // this client learning late the game already ended (its own
              // game_ended broadcast — no delivery guarantee — was
              // missed). Leave automatically, and never render the red
              // error UI for this case at all (even one visible frame of
              // it before the postFrameCallback fires reads as "an error
              // appeared"). See tod_game_screen.dart's identical handling.
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
            // client's own session hasn't reached ACTIVE yet — no
            // gameplay UI shown at all, nothing to press, nothing to
            // silently ignore. Checked AFTER the error branch above —
            // see its comment for why the order matters.
            if (game.isSessionStarting) {
              return BrandedStatusView(
                emoji: '😹',
                title: context.l10n.gameNameMeme,
                subtitle: game.expectedReadyCount > 0
                    ? context.l10n.todWaitingForPlayers(
                        game.readyConfirmedCount,
                        game.expectedReadyCount,
                      )
                    : context.l10n.todLoadingGame,
                accent: AppColors.brandOrangeMid,
              );
            }
            // Items 8/9/10 — the ONE history mechanism every phase's own
            // AppBar now opens into (see memeChatAndHistoryActions),
            // replacing the previous floating Positioned button.
            final hasHistory = (game.state?.history ?? const []).isNotEmpty;
            void onOpenHistory() => setState(() => _showHistory = true);
            if (game.loadState == MemeLoadState.gameOver)
              return _GameOverScreen(
                game: game,
                displayNames: widget.playerDisplayNames,
                roomId: widget.roomId,
                hasHistory: hasHistory,
                onOpenHistory: onOpenHistory,
              );
            final state = game.state;
            if (state == null)
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            // Item 6 root-cause fix: MemeTimerExpiredEvent (see
            // MemeGameEngine._onTimerExpired) closes the submission phase
            // straight to MemePhase.voting even when NOBODY submitted
            // anything — there was never a separate "nothing to vote on"
            // phase, and was never meant to need one (see the engine's own
            // comment on that handler: it force-closes submissions "the
            // same way _handleSubmit does"). _VotingScreen's body is a
            // ListView.builder keyed to state.submissions — with zero
            // entries that's a genuinely empty scrollable, i.e. a blank
            // game body, which is exactly the reported bug. There's
            // nothing to vote ON in that case, so — without inventing a
            // new phase — the existing MemePhase.results screen (which
            // already renders correctly with zero submissions and no
            // winner: see its own `if (winnerId != null)` guard) is the
            // right EXISTING UI for "this round produced nothing,  show
            // the leaderboard and let everyone move on."
            return switch (state.phase) {
              MemePhase.submitting => _SubmitScreen(
                game: game,
                state: state,
                displayNames: widget.playerDisplayNames,
                packId: widget.packId,
                packCoverUrl: widget.packCoverUrl,
                roomId: widget.roomId,
                isOwner: widget.isOwner,
                isSpectator: widget.isSpectator,
                hasHistory: hasHistory,
                onOpenHistory: onOpenHistory,
              ),
              MemePhase.voting when state.submissions.isEmpty => _ResultsScreen(
                game: game,
                state: state,
                displayNames: widget.playerDisplayNames,
                roomId: widget.roomId,
                isOwner: widget.isOwner,
                isSpectator: widget.isSpectator,
                hasHistory: hasHistory,
                onOpenHistory: onOpenHistory,
              ),
              MemePhase.voting => _VotingScreen(
                game: game,
                state: state,
                displayNames: widget.playerDisplayNames,
                roomId: widget.roomId,
                isOwner: widget.isOwner,
                isSpectator: widget.isSpectator,
                hasHistory: hasHistory,
                onOpenHistory: onOpenHistory,
              ),
              MemePhase.results => _ResultsScreen(
                game: game,
                state: state,
                displayNames: widget.playerDisplayNames,
                roomId: widget.roomId,
                isOwner: widget.isOwner,
                isSpectator: widget.isSpectator,
                hasHistory: hasHistory,
                onOpenHistory: onOpenHistory,
              ),
            };
          },
        ),
      ),
    );
  }
}

String _nameOf(Map<String, String> names, String id) =>
    names[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

/// Items 8/9/10 — chat + history AppBar actions shared by every Meme phase
/// screen's own AppBar (Submit/Voting/Results/GameOver), so there's ONE
/// definition instead of duplicating the icon+badge/history-button code
/// four times. Chat reuses the exact same GameChatSheet ToD/NHIE already
/// use; history reuses whatever [onOpenHistory] the caller wires to (the
/// single top-level _showHistory override in _MemeGameScreenState — no
/// second history mechanism). Mirrors NHIE's own AppBar ordering exactly:
/// chat, then history, then (added by each call site) RulesButton.
List<Widget> memeChatAndHistoryActions({
  required BuildContext context,
  required MemeGameProvider game,
  required bool hasHistory,
  required VoidCallback onOpenHistory,
}) => [
  ListenableBuilder(
    listenable: game,
    builder: (_, __) => Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          tooltip: context.l10n.todChatTitle,
          onPressed: () {
            game.clearUnreadChat();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => GameChatSheet(
                listenable: game,
                messagesOf: () => game.chatMessages,
                myId: game.userId,
                title: context.l10n.todChatTitle,
                onSend: (text, {replyTo}) =>
                    game.sendChat(text, replyTo: replyTo),
                memberOf: game.roomProvider?.memberById,
                isPremiumPlus:
                    context
                        .read<AuthProvider>()
                        .currentUser
                        ?.isPremiumPlusActive ??
                    false,
                participants: game.gameParticipants,
                onSendTargeted:
                    (
                      text, {
                      required recipientIds,
                      required recipientNames,
                      replyTo,
                    }) => game.sendTargetedChat(
                      text,
                      recipientIds: recipientIds,
                      recipientNames: recipientNames,
                      replyTo: replyTo,
                    ),
              ),
            );
          },
        ),
        if (game.unreadChat > 0)
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
  if (hasHistory)
    IconButton(
      icon: const Icon(Icons.history_rounded),
      tooltip: context.l10n.nhieGameHistoryTitle,
      onPressed: onOpenHistory,
    ),
];

class _ReactionBar extends StatelessWidget {
  const _ReactionBar({
    required this.targetUserId,
    required this.game,
    required this.reactions,
    required this.myId,
    required this.viewerHasSubmitted,
    this.isSpectator = false,
  });
  final String targetUserId;
  final MemeGameProvider game;
  final List<EmojiReaction> reactions;
  final String myId;
  final bool isSpectator;

  /// Real-device bug: a player who never submitted their own
  /// caption/sticker this round (e.g. a slow/timed-out player reaching a
  /// voting/results screen others' submissions already opened) could
  /// still react to other players' submissions. False disables the
  /// picker the same way isSpectator/alreadyReacted already do — the
  /// engine's own submissions.containsKey guard (see
  /// MemeGameEngine._handleReact) remains the authoritative enforcement,
  /// this is only the matching UI-side prevention.
  final bool viewerHasSubmitted;

  @override
  Widget build(BuildContext context) {
    final rp = game.roomProvider;
    final targetReactions = reactions
        .where((r) => r.targetUserId == targetUserId)
        .toList();
    final alreadyReacted = reactions.any(
      (r) => r.reactorId == myId && r.targetUserId == targetUserId,
    );
    final isOwnSubmission = targetUserId == myId;
    // Spectators never react; a player reacts at most once per response.
    final canReact =
        !(isSpectator || alreadyReacted || isOwnSubmission) &&
        viewerHasSubmitted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // WHO reacted — the actual reacting users' avatars + names and their
        // reaction, instead of anonymous reaction icons. An avatar reaction
        // renders as that user's avatar; an internal token is never shown.
        if (targetReactions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in targetReactions)
                _ReactorReactionChip(
                  member: rp?.memberById(r.reactorId),
                  value: r.emoji,
                ),
            ],
          ),
        if (targetReactions.isNotEmpty && canReact) const SizedBox(height: 8),
        // Reacting is OPTIONAL — only the tap-to-react picker, shown when this
        // player may still react.
        if (canReact)
          EmojiReactionRow(
            reactionsByEmoji: const {},
            alreadyReacted: false,
            onReact: (emoji) => game.reactTo(targetUserId, emoji),
            // Previously omitted entirely — Meme never offered avatar
            // reactions at all, unlike ToD/NHIE which already gate this the
            // same way. The reaction domain model already fully supports
            // avatar-token reactions (see AvatarConfig.isAvatarReaction use
            // in _ReactorReactionChip below); only the picker was missing it.
            useAvatarMode:
                context.read<AuthProvider>().currentUser?.isPremiumActive ??
                false,
            ownAvatarConfig: context
                .read<AuthProvider>()
                .currentUser
                ?.avatarConfig,
          ),
      ],
    );
  }
}

/// One reacting user shown on a response: their real avatar + name and the
/// reaction they gave (an avatar reaction renders as their avatar with the
/// chosen expression; a plain emoji renders as the emoji). Never shows an
/// internal `avatar:<key>` token.
class _ReactorReactionChip extends StatelessWidget {
  const _ReactorReactionChip({required this.member, required this.value});
  final RoomMemberEntity? member;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = member?.displayName ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(
            avatarUrl: member?.avatarUrl,
            avatarConfig: member?.avatarConfig,
            isPremium: member?.isPremium ?? false,
            displayName: name,
            size: 22,
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(name, style: theme.textTheme.labelSmall),
          ],
          const SizedBox(width: 6),
          ReactionDisplay(
            value: value,
            size: 14,
            avatarConfig: AvatarConfig.isAvatarReaction(value)
                ? member?.avatarConfig
                : null,
          ),
        ],
      ),
    );
  }
}

/// Tinder-style horizontal reaction picker: one card per reaction (the
/// reaction image is the card cover), swipe left/right to move between them.
/// The centered card is auto-selected via [onSelect] so the submit button
/// reflects the current pick. A player submits exactly one reaction per round;
/// once submitted this picker is gone and the engine rejects any resubmission.
class _ReactionCardSwiper extends StatefulWidget {
  const _ReactionCardSwiper({
    required this.items,
    required this.selected,
    required this.onSelect,
  });
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  State<_ReactionCardSwiper> createState() => _ReactionCardSwiperState();
}

class _ReactionCardSwiperState extends State<_ReactionCardSwiper>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  // Live drag offset of the FRONT card (Tinder-style). Positive dx = right.
  Offset _drag = Offset.zero;
  late final AnimationController _controller;
  Offset _animFrom = Offset.zero;
  Offset _animTo = Offset.zero;
  // When a fly-off animation finishes, advance to the next card underneath.
  bool _advanceAfterAnim = false;

  static const double _cardW = 200;
  static const double _cardH = 220;

  @override
  void initState() {
    super.initState();
    final start = widget.selected.isNotEmpty
        ? widget.items.indexOf(widget.selected)
        : 0;
    _index = start < 0 ? 0 : start;
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 220),
          )
          ..addListener(() {
            setState(() {
              _drag = Offset.lerp(
                _animFrom,
                _animTo,
                Curves.easeOut.transform(_controller.value),
              )!;
            });
          })
          ..addStatusListener((s) {
            if (s != AnimationStatus.completed) return;
            if (_advanceAfterAnim) {
              _advanceAfterAnim = false;
              setState(() {
                _index = (_index + 1) % widget.items.length;
                _drag = Offset.zero;
              });
              widget.onSelect(widget.items[_index]);
            }
          });
    // The FRONT card is always the current pick — select it up front so the
    // submit button reflects it without an extra tap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.items.isNotEmpty) {
        widget.onSelect(widget.items[_index]);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_controller.isAnimating) return;
    setState(() => _drag += d.delta);
  }

  void _onPanEnd(DragEndDetails d) {
    if (widget.items.length < 2) {
      // Nothing behind to swipe to — snap back.
      _animateTo(Offset.zero, advance: false);
      return;
    }
    final width = MediaQuery.sizeOf(context).width;
    final threshold = width * 0.22;
    if (_drag.dx.abs() > threshold) {
      // Fling the front card off-screen in the drag direction, then the card
      // behind becomes the new front (and the new selection).
      _animateTo(Offset(_drag.dx.sign * width * 1.4, _drag.dy), advance: true);
    } else {
      _animateTo(Offset.zero, advance: false); // snap back
    }
  }

  void _animateTo(Offset to, {required bool advance}) {
    _animFrom = _drag;
    _animTo = to;
    _advanceAfterAnim = advance;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    // Cards peeking out BEHIND the front one, furthest first (drawn at the
    // bottom of the stack). Skipped when there aren't enough distinct cards.
    final behind = <({int index, double scale, double dy})>[
      if (items.length > 2)
        (index: (_index + 2) % items.length, scale: 0.86, dy: -26),
      if (items.length > 1)
        (index: (_index + 1) % items.length, scale: 0.93, dy: -13),
    ];

    final width = MediaQuery.sizeOf(context).width;
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final b in behind)
                Transform.translate(
                  offset: Offset(0, b.dy),
                  child: Transform.scale(
                    scale: b.scale,
                    child: _card(items[b.index], theme, front: false),
                  ),
                ),
              // Front card — draggable.
              GestureDetector(
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Transform.translate(
                  offset: _drag,
                  child: Transform.rotate(
                    angle: (_drag.dx / width) * 0.35,
                    child: _card(items[_index], theme, front: true),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swipe_rounded, size: 16),
            const SizedBox(width: 6),
            Text(
              '${_index + 1} / ${items.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _card(String path, ThemeData theme, {required bool front}) {
    final card = Container(
      width: _cardW,
      height: _cardH,
      decoration: BoxDecoration(
        gradient: front
            ? LinearGradient(
                colors: [
                  _kMemeVivid.withValues(alpha: 0.16),
                  theme.colorScheme.surfaceContainerHighest,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: front ? null : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: front ? _kMemeVivid : theme.colorScheme.outlineVariant,
          width: front ? 2.5 : 1,
        ),
        boxShadow: front
            ? [
                BoxShadow(
                  color: _kMemeVivid.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Center(child: _stickerImg(path, height: 180)),
          // Selected badge — the front card IS the current pick (see
          // initState's onSelect(items[_index])), so this is purely a
          // "this is what you'll submit" affordance, not a separate
          // selection mechanism.
          if (front)
            PositionedDirectional(
              top: 8,
              end: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _kMemeVivid,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kMemeVivid.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
    return card;
  }
}

Widget _stickerImg(String path, {double? height, BoxFit fit = BoxFit.contain}) {
  if (path.startsWith('http')) {
    return Image.network(
      path,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          const Text('🎭', style: TextStyle(fontSize: 80)),
    );
  }
  return Image.asset(
    path,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) =>
        const Text('🎭', style: TextStyle(fontSize: 80)),
  );
}

class _HiddenReactionCard extends StatefulWidget {
  const _HiddenReactionCard({
    required this.stickerChoice,
    required this.caption,
    required this.isOwn,
  });
  final String stickerChoice;
  final String caption;
  final bool isOwn;

  @override
  State<_HiddenReactionCard> createState() => _HiddenReactionCardState();
}

class _HiddenReactionCardState extends State<_HiddenReactionCard> {
  late bool _revealed = widget.isOwn;

  Future<void> _reveal() async {
    await showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.stickerChoice.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _stickerImg(
                        widget.stickerChoice,
                        fit: BoxFit.contain,
                      ),
                    ),
                  if (widget.caption.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ResponsiveGameText(
                        widget.caption,
                        textAlign: TextAlign.center,
                        maxLines: 5,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.memeTapAnywhereToClose,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() => _revealed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_revealed) {
      if (widget.stickerChoice.isEmpty) {
        return widget.caption.isEmpty
            ? const SizedBox.shrink()
            // Item 18.3 — a caption-only response IS the whole result for
            // this player's turn, so it gets the same large/expressive,
            // auto-scaling treatment as every other "response" text.
            : ResponsiveGameText(
                widget.caption,
                maxLines: 4,
                style:
                    Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ) ??
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              );
      }
      return _TappableStickerCard(
        assetPath: widget.stickerChoice,
        caption: widget.caption,
      );
    }

    return GestureDetector(
      onTap: _reveal,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎭', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              context.l10n.memeTapToSeeReaction,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TappableStickerCard extends StatefulWidget {
  const _TappableStickerCard({required this.assetPath, this.caption = ''});
  final String assetPath;
  final String caption;
  @override
  State<_TappableStickerCard> createState() => _TappableStickerCardState();
}

class _TappableStickerCardState extends State<_TappableStickerCard> {
  bool _expanded = false;

  void _showFullscreen() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _stickerImg(widget.assetPath, fit: BoxFit.contain),
                  ),
                  if (widget.caption.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ResponsiveGameText(
                        widget.caption,
                        textAlign: TextAlign.center,
                        maxLines: 5,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.memeTapAnywhereToClose,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showFullscreen,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _stickerImg(widget.assetPath, height: 140),
            ),
            if (widget.caption.isNotEmpty) ...[
              const SizedBox(height: 8),
              // Item 18.3 — the caption is the actual "response" text next
              // to the sticker; large/expressive by default, scales down
              // only if it's genuinely long, still never overflows the
              // card.
              ResponsiveGameText(
                widget.caption,
                textAlign: TextAlign.center,
                maxLines: 3,
                style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ) ??
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              context.l10n.memeTapToExpand,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round/timer/count HUD strip — same structure as ToD's TodHud/NHIE's
/// _NhieHud, Meme's own amber identity. [countFraction]/[countLabel] are
/// whatever the caller already had (submitted count in _SubmitScreen);
/// this widget doesn't compute them. Timer badge only renders while
/// [game] actually has a round timer running — Meme's engine only ever
/// runs the timer during MemePhase.submitting, so callers outside
/// _SubmitScreen simply never see it appear.
class _MemeHud extends StatelessWidget {
  const _MemeHud({
    required this.roundNumber,
    required this.maxRounds,
    required this.game,
    required this.countLabel,
    required this.countFraction,
  });
  final int roundNumber;
  final int maxRounds;
  final MemeGameProvider game;
  final String countLabel;
  final double countFraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kMemeDeep, _kMemeVivid],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kMemeDeep.withValues(alpha: 0.35),
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
              tween: Tween(begin: 0, end: countFraction.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                color: _kMemeAccent,
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
                    const Text('😂', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text(
                      context.l10n.todRoundBadge(roundNumber, maxRounds),
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
                  child: _MemeTimerBadge(
                    deadlineMs: game.state?.timerStartedAt,
                    totalSeconds: game.config?.turnTimerSeconds ?? 0,
                  ).animate().fadeIn(),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    countLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _kMemeDeep,
                    ),
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

/// Item 2/3 (real-device follow-up) root-cause fix — mirrors NHIE's
/// identical `_NhieTimerBadge` fix (see its doc comment for the full
/// rationale): this used to be a StatelessWidget fed a precomputed
/// `seconds` value that only changed when MemeGameProvider's own
/// Timer.periodic tick called notifyListeners(), which on-device left the
/// visible number frozen until an unrelated interaction caused a
/// rebuild. Now purely presentational — its own Timer.periodic only ever
/// calls setState() to redraw, recomputing `remaining` fresh from the
/// authoritative `deadlineMs` (state.timerStartedAt) every second. Never
/// dispatches any event; MemeGameProvider._syncTimer's own ticker remains
/// the only thing that can fire MemeTimerExpiredEvent.
class _MemeTimerBadge extends StatefulWidget {
  const _MemeTimerBadge({required this.deadlineMs, required this.totalSeconds});
  final int? deadlineMs;
  final int totalSeconds;

  @override
  State<_MemeTimerBadge> createState() => _MemeTimerBadgeState();
}

class _MemeTimerBadgeState extends State<_MemeTimerBadge> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _restartTicker();
  }

  @override
  void didUpdateWidget(covariant _MemeTimerBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
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

class _SubmitScreen extends StatefulWidget {
  const _SubmitScreen({
    required this.game,
    required this.state,
    required this.displayNames,
    required this.packId,
    this.packCoverUrl,
    required this.roomId,
    required this.isOwner,
    this.isSpectator = false,
    required this.hasHistory,
    required this.onOpenHistory,
  });
  final MemeGameProvider game;
  final MemeState state;
  final Map<String, String> displayNames;
  final String packId;
  final String? packCoverUrl;
  final String roomId;
  final bool isOwner;
  final bool isSpectator;
  final bool hasHistory;
  final VoidCallback onOpenHistory;
  @override
  State<_SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<_SubmitScreen> {
  final _captionCtrl = TextEditingController();
  String _pickedSticker = '';
  List<String> _packReactions = [];
  bool _loadingReactions = true;

  // First-time Meme game overview highlight (the meme card).
  final GlobalKey _memeShowcaseKey = GlobalKey();

  // Card reveal → controls-panel-appears sequence (see GameFlipCard).
  // Item 4 (Meme full-width pass) — this used to ALSO physically shrink
  // the card itself (width and height) once true, which was the actual
  // cause of the reported "front/caption side becomes narrow" bug (see
  // this file's own note at the GameFlipCard call site in build()) — the
  // card is now a constant size for its whole lifetime. `_minimized`
  // still exists and still gates when the sticker/caption/submit
  // controls (and the spectator/already-submitted waiting states) below
  // it appear, so they still animate in as a continuation of the reveal
  // sequence rather than popping in immediately.
  bool _minimized = false;
  String? _lastPromptId;

  // Meme card width fix: the shared GameFlipCard defaults to a portrait
  // ratio (0.68) sized for ToD/NHIE's short prompts. Meme's captions vary
  // a lot in length and need real horizontal room, so this card opts into
  // GameFlipCard.aspectRatioOverride for a wide/landscape shape instead —
  // ToD/NHIE never set this, so they're completely unaffected.
  //
  // The "big" width used to be a fixed 600 constant, wider than any real
  // phone, on the theory that the outer FittedBox(contain) scaling it
  // down to the real available width was purely a geometric no-op. That
  // reasoning holds for POSITIONS and BOX SIZES, but not for the caption
  // auto-fit's font-size bounds (_MemeCaptionText's _minFontSize/
  // _maxFontSize) — those are absolute pixel values chosen INSIDE the
  // 600-wide subtree, before the outer FittedBox uniformly shrinks
  // everything (including that already-chosen font) down to the real
  // ~350-400px screen width. A "26px" font picked in 600-space renders at
  // roughly 26 * (350/600) ≈ 15px on an actual phone — the real cause of
  // "the caption is still too small", not the nominal max-width value
  // itself. Fixed by sizing the "big" state from the REAL available width
  // (via the LayoutBuilder in build() below) instead of a proxy value, so
  // the font-size search operates in true on-screen pixel space. Kept as
  // instance fields (not `static const`) because the real width is only
  // known once `build()` runs.
  double _bigCardWidth = 340;
  static const double _wideAspectRatio = 1.5;

  @override
  void initState() {
    super.initState();
    _lastPromptId = widget.state.currentPrompt?.id;
    _loadPackReactions();
  }

  @override
  void didUpdateWidget(covariant _SubmitScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Defense in depth: _SubmitScreen is normally recreated fresh every
    // round (MemePhase cycles through voting/results in between, so this
    // State never survives across rounds in practice — see this file's
    // switch in _MemeGameBodyState), but if a prompt ever changed while
    // this exact instance somehow persisted, the card (keyed on prompt
    // id) would already flip back to its back face on its own; this just
    // makes sure the LAYOUT also goes back to "large" for that reveal
    // instead of staying minimized.
    final newId = widget.state.currentPrompt?.id;
    if (newId != _lastPromptId) {
      _lastPromptId = newId;
      _minimized = false;
    }
  }

  void _onCardRevealed() {
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      setState(() => _minimized = true);
    });
  }

  // Correction pass — sticker preloading. This no longer fetches
  // anything itself: the whole game's sticker pool is loaded (and its
  // images precached) exactly once by MemeGameProvider, triggered as
  // soon as the game screen mounts (see _MemeGameScreenState.initState).
  // Every round's _SubmitScreen just awaits that SAME memoized future —
  // by the time a player actually reaches this screen, the fetch (and
  // usually the precache) has very likely already finished, so this
  // resolves near-instantly instead of re-downloading the pool again.
  // The loading state is preserved for the rare case a round is reached
  // before the very first load completes (e.g. an unusually fast game
  // start on a slow connection).
  Future<void> _loadPackReactions() async {
    final urls = await widget.game.loadStickerPool(widget.packId);
    // Precache is normally already in flight/done from the screen-level
    // trigger; awaiting it here too just means this screen's own loading
    // spinner covers the (rare) case it hasn't finished yet, rather than
    // showing sticker tiles that then pop in one by one.
    if (mounted) await widget.game.precacheStickerPool(context);
    if (mounted) {
      setState(() {
        _packReactions = urls;
        _loadingReactions = false;
      });
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => _pickedSticker.isNotEmpty && !widget.isSpectator;

  /// Item 5: this player's sticker deck with already-used-this-game
  /// stickers filtered out (UX layer only — see engine's _handleSubmit for
  /// the authoritative enforcement). Never affects any other player's deck.
  List<String> get _availableStickers {
    final full = _packReactions.isNotEmpty ? _packReactions : kStickerAssets;
    final used = widget.state.usedStickersByPlayer[widget.game.userId];
    if (used == null || used.isEmpty) return full;
    final available = full.where((s) => !used.contains(s)).toList();
    return available.isNotEmpty ? available : full;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final hasSubmitted = widget.state.submissions.containsKey(
      widget.game.userId,
    );
    final submitted = widget.state.submissions.length;
    final total = widget.game.activePlayerCount;

    return ScreenTutorial(
      tutorialId: TutorialIds.memeIntro,
      steps: [_memeShowcaseKey],
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          // Solid brand-amber chrome flowing into _MemeHud's own gradient
          // below it — same continuous-chrome pattern as ToD/NHIE, Meme's
          // own color identity.
          backgroundColor: _kMemeDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(
            onPressed: () => memeShowLeaveDialog(
              context,
              roomId: widget.roomId,
              isOwner: widget.isOwner,
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
              widget.state.roundNumber,
              widget.state.maxRounds,
            ),
          ),
          actions: [
            ...memeChatAndHistoryActions(
              context: context,
              game: widget.game,
              hasHistory: widget.hasHistory,
              onOpenHistory: widget.onOpenHistory,
            ),
            RulesButton(
              gameType: GameType.memeGame,
              config: widget.game.config,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Round/timer/submitted-count HUD — same data the old
              // progress bar + text used (state.roundNumber/maxRounds,
              // submitted/total, game.timerRemaining/timerIsRunning), one
              // continuous party-chrome strip instead of a separate plain
              // progress bar. Timer badge only renders while running.
              _MemeHud(
                roundNumber: widget.state.roundNumber,
                maxRounds: widget.state.maxRounds,
                game: widget.game,
                countLabel: context.l10n.memeSubmittedCount(submitted, total),
                countFraction: total == 0 ? 0 : submitted / total,
              ),
              const SizedBox(height: 14),

              tutorialShowcase(
                context: context,
                showcaseKey: _memeShowcaseKey,
                title: context.l10n.tutMemeTitle,
                description: context.l10n.tutMemeBody,
                // Item 4 (Meme full-width pass) — the card used to
                // physically shrink (width AND height, via FittedBox)
                // once _minimized became true, to make room for the
                // sticker/caption controls below it. That shrink was the
                // actual cause of "the front/caption side becomes
                // narrow": BoxFit.contain scales a FIXED-aspect-ratio
                // box uniformly, so making the outer box shorter
                // necessarily also made it narrower — there is no way to
                // keep full width while uniformly scaling down height
                // for a fixed aspect ratio. Since body is already a
                // SingleChildScrollView (see build() above), the screen
                // does not actually need the card to shrink to make
                // room for the controls panel below — it can simply
                // scroll instead. The card now renders at ONE constant
                // size (_bigCardWidth × its aspect-derived height) for
                // its entire lifetime; `_minimized` still exists and
                // still gates onRevealed/the controls panel's reveal
                // timing (unchanged sequencing), it just no longer
                // drives any sizing.
                child: LayoutBuilder(
                  builder: (context, outerConstraints) {
                    // The genuinely available width at this exact point in
                    // the tree — replaces the old fixed-600 proxy (see
                    // _bigCardWidth's own doc comment for why that made the
                    // caption font render far smaller than its nominal
                    // size). Stored on the State (not recomputed inline
                    // below) purely so _MemeCaptionText's own reasoning
                    // stays simple; it does not change between builds
                    // unless the screen itself is resized/rotated.
                    _bigCardWidth = outerConstraints.maxWidth;
                    return SizedBox(
                      width: _bigCardWidth,
                      height: _bigCardWidth / _wideAspectRatio,
                      child: GameFlipCard(
                        title: context.l10n.gameNameMeme,
                        contentId: widget.state.currentPrompt?.id,
                        autoRevealDelay: const Duration(seconds: 1),
                        onRevealed: _minimized ? null : _onCardRevealed,
                        maxWidth: _bigCardWidth,
                        aspectRatioOverride: _wideAspectRatio,
                        frontChild: Text(
                          widget.state.currentPrompt?.caption ?? '…',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.gameCardContent(
                            color: Colors.white,
                          ),
                        ),
                        // Caption layout fix: a long caption used to be
                        // wrapped at a fixed narrow width and then
                        // block-scaled DOWN (width and font together) by
                        // GameFlipCard's default FittedBox(scaleDown)
                        // handling whenever the wrapped text was taller
                        // than the safe zone — reading as the caption
                        // being squeezed into a narrow vertical column
                        // with small text and wasted side margins. This
                        // builder gets the real bounded safe-zone size
                        // and picks the largest font that fits WITHOUT
                        // narrowing the width, so the caption always
                        // uses the full available horizontal space.
                        frontContentBuilder: (context, constraints) =>
                            _MemeCaptionText(
                              widget.state.currentPrompt?.caption ?? '…',
                              maxWidth: constraints.maxWidth,
                              maxHeight: constraints.maxHeight,
                            ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              if (_minimized)
                _MemeControlsPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!hasSubmitted && !widget.isSpectator) ...[
                            _buildStickerPickerSection(theme, context),
                          ] else if (widget.isSpectator) ...[
                            _buildWaitingBox(
                              theme,
                              context.l10n.memeSpectatingWaitingSubmit,
                            ),
                          ] else ...[
                            _buildWaitingBox(
                              theme,
                              context.l10n.memeResponseSubmittedWaiting,
                            ),
                          ],
                        ],
                      ),
                    )
                    // Continuation of the same minimize sequence rather
                    // than an abrupt pop-in underneath a still-shrinking
                    // card — a short fade+rise, lightly staggered after
                    // the shrink starts.
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 300.ms)
                    .slideY(delay: 150.ms, begin: 0.06, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingBox(ThemeData theme, String message) => Container(
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    ),
  );

  Widget _buildStickerPickerSection(ThemeData theme, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.memePickSticker,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        // Tinder-style reaction cards: each reaction is a card with the
        // reaction image as its cover; swipe left/right to browse and the
        // centered card is your pick. One reaction is submitted per round
        // (the picker is replaced by a "submitted" state once you submit,
        // and the engine rejects any second submission).
        _loadingReactions
            ? const Center(child: CircularProgressIndicator())
            : _ReactionCardSwiper(
                // Item 5 (client UX layer only — the engine's
                // _handleSubmit is the actual enforcement): hide
                // stickers this player already used earlier in the
                // current game so they're not offered again. Falls
                // back to the full deck if every sticker has been used
                // (exhausted pool), matching the engine's own
                // fallback-safe behavior rather than showing an empty
                // picker.
                items: _availableStickers,
                selected: _pickedSticker,
                onSelect: (path) => setState(() => _pickedSticker = path),
              ),
        const SizedBox(height: 12),

        TextField(
          controller: _captionCtrl,
          maxLines: 2,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: context.l10n.memeAddCaptionOptional,
            border: const OutlineInputBorder(),
            counterText: '',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _canSubmit
                ? () => widget.game.submit(
                    caption: _captionCtrl.text.trim(),
                    stickerChoice: _pickedSticker,
                  )
                : null,
            child: Text(
              _pickedSticker.isEmpty
                  ? context.l10n.memePickStickerFirst
                  : context.l10n.memeSubmitResponseButton,
            ),
          ),
        ),
      ],
    );
  }
}

/// Auto-fits [text] into the given bounded box by picking the LARGEST
/// font size that fits, always wrapping at the FULL [maxWidth] first —
/// never narrowing the rendered block the way GameFlipCard's default
/// FittedBox(scaleDown) front-content handling does. Short/medium
/// captions render at [_maxFontSize] (never scaled up further); only a
/// caption whose full-width wrap is still taller than [maxHeight] steps
/// the font size down, one point at a time, until it fits — so a long
/// caption gains more lines at a large, readable size instead of
/// shrinking into a small, narrow column with wasted side margins. Pure
/// synchronous measurement (TextPainter), computed once per build — no
/// per-frame recomputation, so it can't fight the card's own animation.
class _MemeCaptionText extends StatelessWidget {
  const _MemeCaptionText(
    this.text, {
    required this.maxWidth,
    required this.maxHeight,
  });

  final String text;
  final double maxWidth;
  final double maxHeight;

  // Now that the card's "big" width is the REAL available screen width
  // (see _bigCardWidth's doc comment), these render at their true on-
  // screen pixel size — no longer silently shrunk ~40% by an outer
  // FittedBox — so the ceiling can genuinely mean "large, easy to read"
  // rather than compensating in advance for that shrink.
  static const double _maxFontSize = 34;
  static const double _minFontSize = 16;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTextStyles.gameCardContent(color: Colors.white);
    var fontSize = _maxFontSize;
    while (fontSize > _minFontSize) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: baseStyle.copyWith(fontSize: fontSize),
        ),
        textAlign: TextAlign.center,
        textDirection: Directionality.of(context),
      )..layout(maxWidth: maxWidth <= 0 ? 1 : maxWidth);
      if (painter.height <= maxHeight) break;
      fontSize -= 1;
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: baseStyle.copyWith(fontSize: fontSize),
    );
  }
}

/// Fades + slides the sticker/caption/submit controls (or the spectator/
/// already-submitted waiting box) up into view — built fresh only once
/// the card has minimized (see _SubmitScreenState), so this widget's
/// first build IS the moment it should animate in; flutter_animate's
/// `.animate()` plays once per new element the same way every other
/// entrance animation in this file already does.
class _MemeControlsPanel extends StatelessWidget {
  const _MemeControlsPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      child.animate().fadeIn(duration: 380.ms).slideY(begin: 0.12, end: 0);
}

class _VotingScreen extends StatelessWidget {
  const _VotingScreen({
    required this.game,
    required this.state,
    required this.displayNames,
    required this.roomId,
    required this.isOwner,
    this.isSpectator = false,
    required this.hasHistory,
    required this.onOpenHistory,
  });
  final MemeGameProvider game;
  final MemeState state;
  final Map<String, String> displayNames;
  final String roomId;
  final bool isOwner;
  final bool isSpectator;
  final bool hasHistory;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // Spectators can watch voting but never cast one themselves.
    final hasVoted = isSpectator || state.votes.containsKey(game.userId);
    final hasPassed = state.passes.contains(game.userId);
    // Voting is OPTIONAL: a player who voted OR passed is "done" for this round
    // and shouldn't be prompted (or blocked) any further.
    final hasResponded = hasVoted || hasPassed;
    // Round completion is by responses (votes + passes), so the progress bar
    // reaches full even when some players choose to pass.
    final respondedCount = state.votes.length + state.passes.length;
    final entries = state.submissions.entries.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kMemeDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          onPressed: () => memeShowLeaveDialog(
            context,
            roomId: roomId,
            isOwner: isOwner,
            game: game,
          ),
        ),
        title: Text(context.l10n.memeVoteForBest),
        actions: [
          ...memeChatAndHistoryActions(
            context: context,
            game: game,
            hasHistory: hasHistory,
            onOpenHistory: onOpenHistory,
          ),
          RulesButton(gameType: GameType.memeGame, config: game.config),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: game.activePlayerCount == 0
                          ? 0
                          : respondedCount / game.activePlayerCount,
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      color: _kMemeAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.memeVotesCount(
                    state.votes.length,
                    game.activePlayerCount,
                  ),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasResponded && !isSpectator)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.l10n.memeVotedWaiting,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (_, i) {
                  final e = entries[i];
                  final sub = e.value;
                  final isOwn = e.key == game.userId;
                  final isVoted = state.votes[game.userId] == e.key;

                  return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isVoted
                                ? AppColors.successGreen
                                : Colors.transparent,
                            width: 1.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _kMemeVivid.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  context.l10n.memeResponseNumber(i + 1),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: _kMemeVivid,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _HiddenReactionCard(
                                stickerChoice: sub.stickerChoice,
                                caption: sub.caption,
                                isOwn: isOwn,
                              ),
                              const SizedBox(height: 12),
                              _ReactionBar(
                                targetUserId: e.key,
                                game: game,
                                reactions: state.reactions,
                                myId: game.userId,
                                isSpectator: isSpectator,
                                viewerHasSubmitted: state.submissions
                                    .containsKey(game.userId),
                              ),
                              const SizedBox(height: 10),
                              if (!hasResponded && !isOwn)
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: FilledButton.icon(
                                    onPressed: () => game.voteFor(e.key),
                                    icon: const Text(
                                      '😂',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    label: Text(context.l10n.memeVoteForThis),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _kMemeVivid,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              if (!hasResponded && isOwn)
                                Text(
                                  context.l10n.memeYourResponse,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              if (hasVoted && isVoted)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.successGreen.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    context.l10n.memeYourVote,
                                    style: const TextStyle(
                                      color: AppColors.successGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                      .animate(delay: (i * 70).ms)
                      .fadeIn()
                      .slideY(begin: 0.04, end: 0);
                },
              ),
            ),
            // Optional voting: a player may skip voting entirely. Passing gives
            // 0 points and does not block the round — the engine records a pass
            // and completes the round once everyone has voted OR passed.
            if (!hasResponded && !isSpectator)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () => game.pass(),
                    icon: const Icon(Icons.skip_next_rounded),
                    label: Text(context.l10n.memePassVote),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultsScreen extends StatefulWidget {
  const _ResultsScreen({
    required this.game,
    required this.state,
    required this.displayNames,
    required this.roomId,
    required this.isOwner,
    this.isSpectator = false,
    required this.hasHistory,
    required this.onOpenHistory,
  });
  final MemeGameProvider game;
  final MemeState state;
  final Map<String, String> displayNames;
  final String roomId;
  final bool isOwner;
  final bool isSpectator;
  final bool hasHistory;
  final VoidCallback onOpenHistory;
  @override
  State<_ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<_ResultsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final state = widget.state;
    final game = widget.game;
    final winnerId = state.roundWinnerId;
    final tally = <String, int>{};
    for (final t in state.votes.values) tally[t] = (tally[t] ?? 0) + 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kMemeDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          onPressed: () => memeShowLeaveDialog(
            context,
            roomId: widget.roomId,
            isOwner: widget.isOwner,
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
        title: Text(context.l10n.memeRoundResultsTitle(state.roundNumber)),
        actions: memeChatAndHistoryActions(
          context: context,
          game: game,
          hasHistory: widget.hasHistory,
          onOpenHistory: widget.onOpenHistory,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Item 5 (result-screen pass) — a compact, visually prominent
            // completion indicator, matching the "Results" header goal
            // (item 5's own list) without adding a second big banner
            // above the existing winner card.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ResultCompletionChip(
                  responded: state.submissions.length,
                  total: state.playerOrder
                      .where((id) => !game.awayPlayerIds.contains(id))
                      .length,
                ),
              ),
            ),
            if (winnerId != null)
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.amberOrangeLight.withOpacity(0.22),
                      AppColors.amberOrangeLight.withOpacity(0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.amberOrangeLight,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amberOrangeLight.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '🏆',
                      style: TextStyle(fontSize: 48),
                    ).animate().scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 450.ms,
                      curve: Curves.elasticOut,
                    ),
                    Text(
                      _nameOf(widget.displayNames, winnerId),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      context.l10n.memeWinsThisRound,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (state.submissions[winnerId]?.stickerChoice.isNotEmpty ==
                        true)
                      StickerDisplay(
                            assetPath:
                                state.submissions[winnerId]!.stickerChoice,
                            size: 80,
                          )
                          .animate(delay: 150.ms)
                          .fadeIn()
                          .scale(
                            begin: const Offset(0.7, 0.7),
                            end: const Offset(1, 1),
                          ),
                    if (state.submissions[winnerId]?.caption.isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.todQuotedResponse(
                          state.submissions[winnerId]!.caption,
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.08, end: 0),

            DishonestReasonsPanel(
              fetch: game.getMyDishonestReasons,
              key: ValueKey('meme_dishonest_${state.roundNumber}'),
            ),

            Expanded(
              child: ListView(
                children: [
                  ...state.submissions.entries.toList().asMap().entries.map((
                    indexed,
                  ) {
                    final i = indexed.key;
                    final e = indexed.value;
                    final sub = e.value;
                    final votes = tally[e.key] ?? 0;
                    final isWinner = e.key == winnerId;
                    return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: isWinner
                              ? AppColors.amberOrangeLight.withOpacity(0.08)
                              : null,
                          shape: isWinner
                              ? RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: AppColors.amberOrangeLight
                                        .withOpacity(0.5),
                                  ),
                                )
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Item 5 (result-screen pass) — every
                                    // other result row in the app now
                                    // shows an avatar (see
                                    // PlayerResultTile); this card was
                                    // previously text-only.
                                    UserAvatar(
                                      avatarUrl: memeRoomMemberFor(
                                        game,
                                        e.key,
                                      )?.avatarUrl,
                                      avatarConfig: memeRoomMemberFor(
                                        game,
                                        e.key,
                                      )?.avatarConfig,
                                      isPremium:
                                          memeRoomMemberFor(
                                            game,
                                            e.key,
                                          )?.isPremium ??
                                          false,
                                      displayName: _nameOf(
                                        widget.displayNames,
                                        e.key,
                                      ),
                                      size: 30,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _nameOf(widget.displayNames, e.key),
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: isWinner
                                                  ? AppColors.amberOrangeLight
                                                  : null,
                                            ),
                                      ),
                                    ),
                                    if (isWinner) ...[
                                      const SizedBox(width: 4),
                                      const Text('🏆'),
                                    ],
                                    const Spacer(),
                                    Text(
                                      context.l10n.memeVotesAbbrev(votes),
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: HonestyScoreLine(
                                    honestyPoints:
                                        memeRoomMemberFor(
                                          game,
                                          e.key,
                                        )?.honestyPoints ??
                                        0,
                                    generalScore:
                                        memeRoomMemberFor(
                                          game,
                                          e.key,
                                        )?.generalScore ??
                                        0,
                                    iconSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (sub.stickerChoice.isNotEmpty)
                                  _TappableStickerCard(
                                    assetPath: sub.stickerChoice,
                                    caption: sub.caption,
                                  ),
                                const SizedBox(height: 8),
                                _ReactionBar(
                                  targetUserId: e.key,
                                  game: game,
                                  reactions: state.reactions,
                                  myId: game.userId,
                                  isSpectator: widget.isSpectator,
                                  viewerHasSubmitted: state.submissions
                                      .containsKey(game.userId),
                                ),
                                if (!widget.isSpectator &&
                                    (game.config?.honestyVoteEnabled ?? true))
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: CompactHonestyVoteButtons(
                                      voterId: game.userId,
                                      targetUserId: e.key,
                                      participantIds: state.playerOrder,
                                      responseKey: 'round:${state.roundNumber}',
                                      hasVoted: game.hasVotedHonesty(
                                        'round:${state.roundNumber}',
                                        e.key,
                                      ),
                                      onVote: game.castHonestyVote,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                        .animate(delay: (i * 60).ms)
                        .fadeIn()
                        .slideX(begin: 0.05, end: 0);
                  }),
                  // Item 4/5 (result-screen pass) — a player who never
                  // submitted before the round closed previously had NO
                  // row at all here (state.submissions is keyed only by
                  // actual submitters). Meme has no separate Skip action
                  // (only a timer), so every player in the active roster
                  // absent from state.submissions is genuinely a timeout,
                  // determined from real state, never inferred from any
                  // response text.
                  ...state.playerOrder
                      .where(
                        (id) =>
                            !state.submissions.containsKey(id) &&
                            !game.awayPlayerIds.contains(id),
                      )
                      .map(
                        (id) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PlayerResultTile(
                            key: ValueKey('meme_nr_$id'),
                            avatarUrl: memeRoomMemberFor(game, id)?.avatarUrl,
                            avatarConfig: memeRoomMemberFor(
                              game,
                              id,
                            )?.avatarConfig,
                            isPremium:
                                memeRoomMemberFor(game, id)?.isPremium ?? false,
                            displayName: _nameOf(widget.displayNames, id),
                            status: PlayerResultStatus.timedOut,
                            isViewer: id == game.userId,
                            accentColor: AppColors.amberOrangeLight,
                          ).animate().fadeIn(),
                        ),
                      ),
                ],
              ),
            ),

            const Divider(),
            Text(
              context.l10n.todLeaderboard,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _Leaderboard(
              scores: state.scores,
              displayNames: widget.displayNames,
              myId: game.userId,
            ),
            const SizedBox(height: 12),

            if (game.canAdvanceTurnHere) ...[
              if (!game.allPlayersVoted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    context.l10n.memePlayersVoted(
                      game.votedCount,
                      game.activePlayerCount,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (!game.allOthersReady)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    context.l10n.nhieWaitingForPlayersReady,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: (game.allPlayersVoted && game.allOthersReady)
                      ? () => game.requestAdvanceTurn()
                      : null,
                  child: Text(context.l10n.memeNextRound),
                ),
              ),
              if (game.isOwner)
                Builder(
                  builder: (ctx) {
                    final isPremium =
                        ctx.read<AuthProvider>().currentUser?.isPremium ??
                        false;
                    if (!isPremium) return const SizedBox.shrink();
                    return TextButton.icon(
                      onPressed: () => _showAddCustomCardSheet(ctx, game),
                      icon: const Icon(Icons.add_card_outlined, size: 16),
                      label: Text(ctx.l10n.todAddCustomCardButton),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
            ] else if (widget.isSpectator)
              Text(
                context.l10n.todSpectatingWaitingHost,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else if (game.hasMarkedReady)
              Text(
                context.l10n.todReadyWaitingHost,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.successGreen,
                ),
              )
            else
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: game.markReadyForNext,
                  child: Text(context.l10n.nhieReadyForNextRound),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Ranked score list with medal badges and a proportional bar per player,
/// replacing a flat "name — number" text list — the point is to make
/// standing at a glance obvious, reinforcing the competitive framing the
/// redesign asked for.
class _Leaderboard extends StatelessWidget {
  const _Leaderboard({
    required this.scores,
    required this.displayNames,
    required this.myId,
  });
  final Map<String, int> scores;
  final Map<String, String> displayNames;
  final String myId;

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxScore = ranked.isEmpty ? 1 : ranked.first.value.clamp(1, 1 << 30);

    return Column(
      children: ranked.asMap().entries.map((indexed) {
        final rank = indexed.key;
        final e = indexed.value;
        final isMe = e.key == myId;
        final fraction = e.value / maxScore;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  rank < _medals.length ? _medals[rank] : '${rank + 1}',
                  style: theme.textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _nameOf(displayNames, e.key) +
                                (isMe ? ' (You)' : ''),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isMe
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${e.value}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: fraction.toDouble()),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: rank == 0
                              ? AppColors.amberOrangeLight
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate(delay: (rank * 80).ms).fadeIn().slideX(begin: -0.03, end: 0);
      }).toList(),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.history,
    required this.displayNames,
    required this.onClose,
  });
  final List<MemeRoundRecord> history;
  final Map<String, String> displayNames;
  final VoidCallback onClose;

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
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      '${round.roundNumber}',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  title: Text(
                    round.prompt.caption,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    context.l10n.memeWinnerLabel(
                      round.winnerId != null
                          ? _nameOf(displayNames, round.winnerId!)
                          : context.l10n.memeTie,
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: round.submissions.entries.map((e) {
                          final sub = e.value;
                          final reacts = round.reactions
                              .where((r) => r.targetUserId == e.key)
                              .toList();
                          final reactTally = <String, int>{};
                          for (final r in reacts)
                            reactTally[r.emoji] =
                                (reactTally[r.emoji] ?? 0) + 1;
                          final isWinner = e.key == round.winnerId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _nameOf(displayNames, e.key),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: isWinner
                                                ? AppColors.amberOrangeLight
                                                : null,
                                          ),
                                    ),
                                    if (isWinner) const Text(' 🏆'),
                                  ],
                                ),
                                if (sub.stickerChoice.isNotEmpty)
                                  StickerDisplay(
                                    assetPath: sub.stickerChoice,
                                    size: 48,
                                  ),
                                if (sub.caption.isNotEmpty)
                                  Text(
                                    context.l10n.todQuotedResponse(sub.caption),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                if (reactTally.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Wrap(
                                      spacing: 4,
                                      children: reactTally.entries
                                          .map(
                                            (r) => Text(
                                              '${r.key}${r.value}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
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
    required this.hasHistory,
    required this.onOpenHistory,
  });
  final MemeGameProvider game;
  final Map<String, String> displayNames;
  final String roomId;
  final bool hasHistory;
  final VoidCallback onOpenHistory;
  @override
  State<_GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<_GameOverScreen> {
  @override
  Widget build(BuildContext context) {
    final scores = widget.game.state?.scores ?? {};
    final history = widget.game.state?.history ?? [];
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      // Items 8/9/10 — this screen previously had no AppBar at all, so
      // chat/history were unreachable from here; every other Meme phase
      // already has an AppBar with these same shared actions.
      appBar: AppBar(
        backgroundColor: _kMemeDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(context.l10n.todGameOverBang),
        actions: memeChatAndHistoryActions(
          context: context,
          game: widget.game,
          hasHistory: widget.hasHistory,
          onOpenHistory: widget.onOpenHistory,
        ),
      ),
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
                    colors: [_kMemeDeep, _kMemeVivid],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _kMemeDeep.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '😂🏆',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 56),
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
                      context.l10n.memeFunniestPlayerWins,
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
                  nameOf: (id) => _nameOf(widget.displayNames, id),
                  scoreLabelOf: (s) => context.l10n.memeTrophyScore(s),
                  accentColor: _kMemeVivid,
                ),
              ),
              if (history.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: widget.onOpenHistory,
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
