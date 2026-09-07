import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';

/// [backgrounded] is distinct from [RoomMemberEntity.isAway] (a
/// room/game-scoped "kicked from the current game round, still a room
/// member" state shown as "left the game" in member_tile.dart) — this is
/// purely "the app is in the background while Premium Plus" and is never
/// set for anyone else. Named `backgrounded` (not `away`) internally to
/// avoid confusion with that unrelated existing concept, even though the
/// user-facing copy says "away".
enum UserPresenceStatus { online, inGame, backgrounded, offline }

class UserPresence {
  const UserPresence({
    required this.userId,
    required this.status,
    this.roomId,
    this.roomStatus,
    this.gameType,
  });

  final String userId;
  final UserPresenceStatus status;
  final String? roomId;

  /// 'lobby' or 'in_game' — only meaningful when [status] is inGame.
  /// Coarse-grained UserPresenceStatus.inGame alone can't tell "waiting
  /// in a room" from "actively mid-game" apart; this is the detail
  /// premium viewers get (see FriendTile). Basic viewers only ever see
  /// [status], so this being present in the payload doesn't change
  /// anything for them.
  final String? roomStatus;

  /// GameType.toDbString() (e.g. 'truth_or_dare') — set only once the
  /// room has actually started a specific game, null while in the lobby.
  final String? gameType;

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'status': status.name,
    if (roomId != null) 'room_id': roomId,
    if (roomStatus != null) 'room_status': roomStatus,
    if (gameType != null) 'game_type': gameType,
  };

  static UserPresence fromMap(Map<String, dynamic> map) {
    return UserPresence(
      userId: map['user_id'] as String,
      status: UserPresenceStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => UserPresenceStatus.offline,
      ),
      roomId: map['room_id'] as String?,
      roomStatus: map['room_status'] as String?,
      gameType: map['game_type'] as String?,
    );
  }
}

/// Pure parsing of RealtimeChannel.presenceState()'s result into a userId
/// keyed map — extracted from PresenceService.currentPresence so it's
/// directly unit-testable without a live Supabase client/channel (mirrors
/// this codebase's existing pattern of pulling a service's pure decision
/// logic out for testability, e.g. RoomProvider.computeSessionParticipant).
///
/// realtime_client's presenceState() returns a list of SinglePresenceState
/// (each with a .key and a .presences list of Presence(.payload)) — this
/// was previously mishandled as if it were a Map, which silently made
/// PresenceService.currentPresence always return {} (see its doc comment).
Map<String, UserPresence> parsePresenceState(
  List<SinglePresenceState> rawState,
) {
  final result = <String, UserPresence>{};
  for (final single in rawState) {
    final payload = single.presences.firstOrNull?.payload;
    if (payload != null && payload['user_id'] != null) {
      final p = UserPresence.fromMap(Map<String, dynamic>.from(payload));
      result[p.userId] = p;
    }
  }
  return result;
}

/// Manages global friend online/in-game/offline presence.
///
/// One shared "global:presence" channel for all authenticated users.
/// Each user tracks their own status; friends see each other's status.
/// FriendsProvider subscribes to presence changes for its friend list.
///
/// This is also the single owner of the Auto-mode app lifecycle: it mixes
/// in [WidgetsBindingObserver] itself (registered in [start], removed in
/// [stop]) rather than requiring some widget higher up to forward
/// foreground/background events to it — a singleton service, not a
/// widget's State, so nothing else in the tree is a natural place to own
/// this without every screen remembering to wire it up.
class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService _instance = PresenceService._();
  static PresenceService get instance => _instance;

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  String? _currentUserId;
  Timer? _heartbeatTimer;

  /// True only once `.subscribe()`'s callback has actually fired with
  /// `RealtimeSubscribeStatus.subscribed`. `_channel` itself is assigned
  /// synchronously the moment `.channel()` returns, well before the
  /// websocket join handshake completes — calling `.track()` against a
  /// channel that hasn't joined yet was the root cause of the online/
  /// offline picker hanging forever (see setManualMode below).
  bool _isSubscribed = false;

  /// Persisted premium preference (profiles.presence_mode): 'online' or
  /// 'offline' pins the tracked status and makes the automatic
  /// setOnline()/setOffline() calls elsewhere in the app (app lifecycle,
  /// etc.) no-ops until switched back to null/'auto'. setInGame() is
  /// deliberately NOT overridden — other features (e.g. "friend is in a
  /// room, tap to join") depend on it reflecting real room membership,
  /// not a vanity status.
  String? _manualMode;

  /// Gates the Premium Plus away/background-presence feature — computed
  /// once in [start] from the same premium fields already fetched there,
  /// reusing the app's one entitlement source (mirrors
  /// UserEntity.isPremiumPlusActive) rather than a second detection path.
  bool _isPremiumPlusActive = false;

  /// True whenever the app is foregrounded (or presence hasn't started
  /// yet, matching the app-launch requirement of "opens app -> online").
  /// Tracked independently of _manualMode so switching back to Auto can
  /// immediately reflect the *real* current lifecycle state instead of
  /// leaving stale tracked status in place.
  bool _isForeground = true;

  /// Grace period before Auto mode actually goes offline after the app is
  /// backgrounded — mirrors the 30s disconnect-grace convention already
  /// used elsewhere for presence-adjacent timing (RoomProvider's
  /// per-member disconnect grace timer, and this service's own heartbeat
  /// interval), so a brief app-switcher trip doesn't flicker a friend's
  /// status to offline and back.
  static const _backgroundGraceTimeout = Duration(seconds: 30);
  Timer? _backgroundGraceTimer;

  /// The status/room-context this service most recently *asserted* (via
  /// setOnline/setOffline/setInGame or an auto-lifecycle transition) —
  /// not necessarily what's live on the channel this instant. The
  /// heartbeat and reconnect-resubscribe re-track *this*, verbatim,
  /// rather than recomputing a fresh "what should auto status be right
  /// now" — recomputing was silently dropping room/game detail back to
  /// plain online every ~30s (a heartbeat has no idea a user is mid-game,
  /// only setInGame() does), and could also flip a backgrounded user
  /// offline up to 30s before the background-grace timer's own deadline.
  UserPresenceStatus _lastStatus = UserPresenceStatus.offline;
  String? _lastRoomId;
  String? _lastRoomStatus;
  String? _lastGameType;

  final _presenceController =
      StreamController<Map<String, UserPresence>>.broadcast();

  Stream<Map<String, UserPresence>> get presenceStream =>
      _presenceController.stream;

  // ── Start ────────────────────────────────────────────────────────────────
  Future<void> start(String userId) async {
    if (_channel != null) return;
    _currentUserId = userId;
    _isForeground = true;

    try {
      final row = await _supabase
          .from('profiles')
          .select('presence_mode, is_premium, premium_tier, premium_expires_at')
          .eq('id', userId)
          .maybeSingle();
      final mode = row?['presence_mode'] as String?;
      // A forced mode only survives while premium is genuinely active —
      // otherwise a lapsed-premium user (presence_mode left over as
      // 'online'/'offline' from before they lost premium) would stay
      // stuck out of Auto forever, violating "basic users always use
      // Auto". The preference itself is left alone in the DB in case
      // premium is renewed later.
      final isPremium = row?['is_premium'] as bool? ?? false;
      final expiresAtRaw = row?['premium_expires_at'] as String?;
      final expiresAt = expiresAtRaw != null
          ? DateTime.tryParse(expiresAtRaw)
          : null;
      final isPremiumActive =
          isPremium && (expiresAt == null || expiresAt.isAfter(DateTime.now()));
      _manualMode = (isPremiumActive && (mode == 'online' || mode == 'offline'))
          ? mode
          : null;
      _isPremiumPlusActive =
          isPremiumActive && row?['premium_tier'] == 'premium_plus';
    } catch (_) {
      _manualMode = null;
      _isPremiumPlusActive = false;
    }

    // Seeds what the very first track() on join should assert. Reconnects
    // later reuse _lastStatus as it stands then (see the subscribe
    // callback below), not this — only a genuine fresh start() computes
    // it from scratch.
    _lastStatus = _desiredAutoStatus();
    _lastRoomId = null;
    _lastRoomStatus = null;
    _lastGameType = null;

    WidgetsBinding.instance.addObserver(this);

    _channel = _supabase
        .channel('global:presence')
        .onPresenceSync((payload) => _emitCurrentState())
        .onPresenceJoin((payload) => _emitCurrentState())
        .onPresenceLeave((payload) => _emitCurrentState())
        .subscribe((status, _) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            _isSubscribed = true;
            // Also covers reconnect: the underlying realtime socket
            // rejoins this channel automatically after a connection
            // drop, which re-fires this callback with `subscribed` —
            // re-asserting (and re-persisting to the DB below) whatever
            // was last legitimately set, room/game detail included, with
            // no extra wiring needed.
            _reassertLastStatus();
            _startHeartbeat();
          }
        });

    AppLogger.info('PresenceService: started for $userId');
  }

  /// Applies (and persists via ProfileRepository.setPresenceMode, called
  /// by the caller) a manual online/offline override, or clears it back
  /// to automatic when [mode] is null/'auto'. Takes effect immediately on
  /// the live channel, not just on next start().
  Future<void> setManualMode(String? mode) async {
    _manualMode = (mode == 'online' || mode == 'offline') ? mode : null;
    if (_manualMode == 'online') {
      await _trackStatus(UserPresenceStatus.online);
    } else if (_manualMode == 'offline') {
      await _trackStatus(UserPresenceStatus.offline);
    } else {
      // Auto: immediately reflect the real current lifecycle state
      // rather than leaving whatever was last (manually) tracked.
      await _trackStatus(
        _isForeground ? UserPresenceStatus.online : UserPresenceStatus.offline,
      );
    }
  }

  // ── App lifecycle (Auto mode) ───────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isForeground = true;
        _backgroundGraceTimer?.cancel();
        _backgroundGraceTimer = null;
        // Restore inGame (with the room context preserved through the
        // backgrounded transition below) rather than unconditionally
        // dropping back to bare online — a Premium Plus user resuming
        // mid-room should immediately look "in the room" again, not
        // "online, no room" until the next unrelated room event happens
        // to resync it.
        if (_lastRoomId != null) {
          _trackStatus(
            UserPresenceStatus.inGame,
            roomId: _lastRoomId,
            roomStatus: _lastRoomStatus,
            gameType: _lastGameType,
          );
        } else {
          setOnline();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _isForeground = false;
        // Premium Plus + currently in a room/game: show "away" right away
        // instead of waiting out the full grace period — this is a real
        // app-lifecycle transition (not the network-fluctuation case the
        // grace period exists for), and the grace timer below still runs
        // to eventually go fully offline if they never return. Everyone
        // else keeps today's exact behavior unchanged.
        if (_isPremiumPlusActive && _lastStatus == UserPresenceStatus.inGame) {
          _trackStatus(
            UserPresenceStatus.backgrounded,
            roomId: _lastRoomId,
            roomStatus: _lastRoomStatus,
            gameType: _lastGameType,
          );
        }
        _backgroundGraceTimer?.cancel();
        _backgroundGraceTimer = Timer(_backgroundGraceTimeout, () {
          if (!_isForeground) setOffline();
        });
        break;
      case AppLifecycleState.detached:
        // App is being torn down — no point waiting out the grace period.
        _isForeground = false;
        _backgroundGraceTimer?.cancel();
        _backgroundGraceTimer = null;
        setOffline();
        break;
      case AppLifecycleState.inactive:
        // Transient (app-switcher preview, incoming call, permission
        // dialog) — not a real backgrounding, ignore.
        break;
    }
  }

  // ── Status updates ────────────────────────────────────────────────────────
  Future<void> setOnline() {
    if (_manualMode != null) return Future.value();
    return _trackStatus(UserPresenceStatus.online);
  }

  Future<void> setInGame(
    String roomId, {
    String? roomStatus,
    String? gameType,
  }) => _trackStatus(
    UserPresenceStatus.inGame,
    roomId: roomId,
    roomStatus: roomStatus,
    gameType: gameType,
  );

  Future<void> setOffline() {
    if (_manualMode != null) return Future.value();
    return _trackStatus(UserPresenceStatus.offline);
  }

  // ── Get current presence map ──────────────────────────────────────────────
  // realtime_client's RealtimeChannel.presenceState() returns
  // List<SinglePresenceState> (each with a .key and a .presences list of
  // Presence(.payload)) — NOT a Map, in every version of the pinned
  // supabase_flutter/realtime_client packages this project uses. Treating
  // it as a Map (the previous implementation) meant `rawState is Map` was
  // always false, so this getter — and therefore presenceStream and every
  // UI surface reading it — always returned {} regardless of who was
  // actually tracked on the channel. This was the sole root cause of
  // presence appearing completely non-functional app-wide.
  Map<String, UserPresence> get currentPresence {
    final rawState = _channel?.presenceState();
    if (rawState == null) return {};
    return parsePresenceState(rawState);
  }

  UserPresenceStatus statusOf(String userId) {
    return currentPresence[userId]?.status ?? UserPresenceStatus.offline;
  }

  // ── Stop ──────────────────────────────────────────────────────────────────
  Future<void> stop() async {
    _heartbeatTimer?.cancel();
    _backgroundGraceTimer?.cancel();
    _backgroundGraceTimer = null;
    WidgetsBinding.instance.removeObserver(this);

    // Logout must reach the database, not just drop off the ephemeral
    // presence channel — anyone reading profiles.online_status directly
    // (not currently joined to global:presence) would otherwise keep
    // seeing this user as online indefinitely.
    if (_currentUserId != null) {
      try {
        await _supabase
            .from('profiles')
            .update({'online_status': 'offline'})
            .eq('id', _currentUserId!);
      } catch (e) {
        AppLogger.warning('PresenceService: stop() offline persist failed: $e');
      }
    }

    await _channel?.untrack();
    await _channel?.unsubscribe();
    _channel = null;
    _currentUserId = null;
    _manualMode = null;
    _isPremiumPlusActive = false;
    _isSubscribed = false;
    _isForeground = true;
    _lastStatus = UserPresenceStatus.offline;
    _lastRoomId = null;
    _lastRoomStatus = null;
    _lastGameType = null;
    AppLogger.info('PresenceService: stopped');
  }

  // ── Private ───────────────────────────────────────────────────────────────
  Future<void> _trackStatus(
    UserPresenceStatus status, {
    String? roomId,
    String? roomStatus,
    String? gameType,
  }) async {
    // Not just "does _channel exist" — it's assigned synchronously the
    // moment .channel() returns, well before the websocket join actually
    // completes. Calling .track() before the join handshake finishes is
    // what made the online/offline picker hang forever: the underlying
    // Realtime client has nothing to send it to yet.
    if (_channel == null || _currentUserId == null || !_isSubscribed) return;
    _lastStatus = status;
    _lastRoomId = roomId;
    _lastRoomStatus = roomStatus;
    _lastGameType = gameType;
    final presence = UserPresence(
      userId: _currentUserId!,
      status: status,
      roomId: roomId,
      roomStatus: roomStatus,
      gameType: gameType,
    );
    await _channel!.track(presence.toMap());
    unawaited(_persistStatus(status));
  }

  /// Re-track whatever was last legitimately asserted, verbatim — used by
  /// the heartbeat and by reconnect (see the subscribe callback in
  /// [start]) so neither one ever has to (mis)guess the current status.
  Future<void> _reassertLastStatus() => _trackStatus(
    _lastStatus,
    roomId: _lastRoomId,
    roomStatus: _lastRoomStatus,
    gameType: _lastGameType,
  );

  /// Writes profiles.online_status + last_seen_at so the database is the
  /// authoritative record of presence, not just the ephemeral realtime
  /// channel — required for anyone reading a profile directly (not
  /// currently joined to global:presence: profile screens, other
  /// backend consumers, a fresh session before the channel has synced)
  /// to see the correct status, and for it to survive app restarts.
  /// `inGame` still counts as "online" here; the room-vs-idle distinction
  /// only exists in the ephemeral presence payload. `backgrounded` maps to
  /// the DB enum's pre-existing `'away'` value (online_status_enum already
  /// had online/offline/away before this feature — just never written by
  /// this service until now).
  Future<void> _persistStatus(UserPresenceStatus status) async {
    if (_currentUserId == null) return;
    final dbStatus = switch (status) {
      UserPresenceStatus.offline => 'offline',
      UserPresenceStatus.backgrounded => 'away',
      UserPresenceStatus.online || UserPresenceStatus.inGame => 'online',
    };
    try {
      await _supabase
          .from('profiles')
          .update({
            'online_status': dbStatus,
            'last_seen_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', _currentUserId!);
    } catch (e) {
      AppLogger.warning('PresenceService: _persistStatus failed: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // Supabase Presence heartbeat is ~10s but we re-track every 30s
    // to survive brief disconnects without losing presence
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _reassertLastStatus(),
    );
  }

  /// What status the (re)track calls that aren't a direct manual
  /// selection — initial join, reconnect, heartbeat — should assert.
  /// Forced modes win outright; otherwise it's real foreground state, so
  /// a heartbeat firing after the background-grace timer has already
  /// taken the user offline doesn't flip them back online.
  UserPresenceStatus _desiredAutoStatus() {
    if (_manualMode == 'offline') return UserPresenceStatus.offline;
    if (_manualMode == 'online') return UserPresenceStatus.online;
    return _isForeground
        ? UserPresenceStatus.online
        : UserPresenceStatus.offline;
  }

  void _emitCurrentState() {
    _presenceController.add(currentPresence);
  }
}
