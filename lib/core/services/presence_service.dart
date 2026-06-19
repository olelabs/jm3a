import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';

enum UserPresenceStatus { online, inGame, offline }

class UserPresence {
  const UserPresence({required this.userId, required this.status, this.roomId});

  final String userId;
  final UserPresenceStatus status;
  final String? roomId;

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'status': status.name,
    if (roomId != null) 'room_id': roomId,
  };

  static UserPresence fromMap(Map<String, dynamic> map) {
    return UserPresence(
      userId: map['user_id'] as String,
      status: UserPresenceStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => UserPresenceStatus.offline,
      ),
      roomId: map['room_id'] as String?,
    );
  }
}

/// Manages global friend online/in-game/offline presence.
///
/// One shared "global:presence" channel for all authenticated users.
/// Each user tracks their own status; friends see each other's status.
/// FriendsProvider subscribes to presence changes for its friend list.
class PresenceService {
  PresenceService._();
  static final PresenceService _instance = PresenceService._();
  static PresenceService get instance => _instance;

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  String? _currentUserId;
  Timer? _heartbeatTimer;

  final _presenceController =
      StreamController<Map<String, UserPresence>>.broadcast();

  Stream<Map<String, UserPresence>> get presenceStream =>
      _presenceController.stream;

  // ── Start ────────────────────────────────────────────────────────────────
  Future<void> start(String userId) async {
    if (_channel != null) return;
    _currentUserId = userId;

    _channel = _supabase
        .channel('global:presence')
        .onPresenceSync((payload) => _emitCurrentState())
        .onPresenceJoin((payload) => _emitCurrentState())
        .onPresenceLeave((payload) => _emitCurrentState())
        .subscribe((status, _) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            _trackStatus(UserPresenceStatus.online);
            _startHeartbeat();
          }
        });

    AppLogger.info('PresenceService: started for $userId');
  }

  // ── Status updates ────────────────────────────────────────────────────────
  Future<void> setOnline() => _trackStatus(UserPresenceStatus.online);

  Future<void> setInGame(String roomId) =>
      _trackStatus(UserPresenceStatus.inGame, roomId: roomId);

  Future<void> setOffline() => _trackStatus(UserPresenceStatus.offline);

  // ── Get current presence map ──────────────────────────────────────────────
  // Map<String, UserPresence> get currentPresence {
  //   final state = _channel?.presenceState() ?? {};
  //   final result = <String, UserPresence>{};
  //   for (final entry in state.entries) {
  //     final presences = entry.value;
  //     if (presences.isNotEmpty) {
  //       final map = presences.first;
  //       if (map['user_id'] != null) {
  //         final p = UserPresence.fromMap(map as Map<String, dynamic>);
  //         result[p.userId] = p;
  //       }
  //     }
  //   }
  //   return result;
  // }
  Map<String, UserPresence> get currentPresence {
    final rawState = _channel?.presenceState();
    if (rawState == null) return {};
    final stateMap = rawState is Map
        ? Map<String, dynamic>.from(rawState as Map<dynamic, dynamic>)
        : <String, dynamic>{};
    final result = <String, UserPresence>{};
    for (final entry in stateMap.entries) {
      final presences = entry.value;
      final list = presences is List ? presences : [presences];
      if (list.isNotEmpty) {
        final map = list.first;
        if (map is Map && map['user_id'] != null) {
          final p = UserPresence.fromMap(Map<String, dynamic>.from(map));
          result[p.userId] = p;
        }
      }
    }
    return result;
  }

  UserPresenceStatus statusOf(String userId) {
    return currentPresence[userId]?.status ?? UserPresenceStatus.offline;
  }

  // ── Stop ──────────────────────────────────────────────────────────────────
  Future<void> stop() async {
    _heartbeatTimer?.cancel();
    await _channel?.untrack();
    await _channel?.unsubscribe();
    _channel = null;
    _currentUserId = null;
    AppLogger.info('PresenceService: stopped');
  }

  // ── Private ───────────────────────────────────────────────────────────────
  Future<void> _trackStatus(UserPresenceStatus status, {String? roomId}) async {
    if (_channel == null || _currentUserId == null) return;
    final presence = UserPresence(
      userId: _currentUserId!,
      status: status,
      roomId: roomId,
    );
    await _channel!.track(presence.toMap());
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // Supabase Presence heartbeat is ~10s but we re-track every 30s
    // to survive brief disconnects without losing presence
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _trackStatus(UserPresenceStatus.online),
    );
  }

  void _emitCurrentState() {
    _presenceController.add(currentPresence);
  }
}
