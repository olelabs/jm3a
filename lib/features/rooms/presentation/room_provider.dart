// // // // import 'dart:async';
// // // // import 'package:flutter/foundation.dart';
// // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // import '../../../core/errors/failures.dart';
// // // // import '../../../core/services/realtime_service.dart';
// // // // import '../../../core/services/presence_service.dart';
// // // // import '../../../core/utils/app_logger.dart';
// // // // import '../data/room_repository.dart';
// // // // import '../data/room_cache_service.dart';
// // // // import '../domain/room_entity.dart';
// // // // import '../../games/engine/base_game_engine.dart';
// // // // import 'package:uuid/uuid.dart';

// // // // const _uuid = Uuid();

// // // // // ── Connection state ──────────────────────────────────────────────────────────
// // // // enum RoomConnectionState {
// // // //   connecting,
// // // //   connected,
// // // //   reconnecting,
// // // //   recovering,
// // // //   failed;

// // // //   bool get isStable => this == connected;
// // // //   bool get isBusy =>
// // // //       this == connecting || this == reconnecting || this == recovering;
// // // // }

// // // // // ── Events emitted to parent (e.g., for navigation) ──────────────────────────
// // // // enum RoomLifecycleEvent { kicked, banned, roomClosed, ownershipTransferred }

// // // // /// Complete room session state manager.
// // // // ///
// // // // /// Lifecycle: create → initialize() → [use] → leaveRoom() / dispose()
// // // // ///
// // // // /// Architecture:
// // // // ///   - Single source of truth for room + members + settings + chat
// // // // ///   - Hybrid chat: optimistic local + DB write + Broadcast delivery
// // // // ///   - Presence via Supabase Presence (not CDC — lower overhead)
// // // // ///   - Reconnect with exponential backoff: 1s, 3s, 7s then fail
// // // // ///   - 30-second grace period before treating disconnected player as gone
// // // // ///   - Scoped per room route — one instance per active room session
// // // // class RoomProvider extends ChangeNotifier {
// // // //   RoomProvider({
// // // //     required RoomRepository roomRepository,
// // // //     required RealtimeService realtimeService,
// // // //     required PresenceService presenceService,
// // // //     required RoomCacheService cacheService,
// // // //     required String currentUserId,
// // // //     required String currentDisplayName,
// // // //     String? currentAvatarUrl,
// // // //   }) : _repo = roomRepository,
// // // //        _realtime = realtimeService,
// // // //        _presence = presenceService,
// // // //        _cache = cacheService,
// // // //        _currentUserId = currentUserId,
// // // //        _currentDisplayName = currentDisplayName,
// // // //        _currentAvatarUrl = currentAvatarUrl;

// // // //   final RoomRepository _repo;
// // // //   final RealtimeService _realtime;
// // // //   final PresenceService _presence;
// // // //   final RoomCacheService _cache;
// // // //   final String _currentUserId;
// // // //   final _supabase = Supabase.instance.client;
// // // //   RealtimeChannel? _memberCdcChannel;
// // // //   final String _currentDisplayName;
// // // //   final String? _currentAvatarUrl;

// // // //   // ── State ──────────────────────────────────────────────────────────────────
// // // //   RoomEntity? _room;
// // // //   List<RoomMemberEntity> _members = [];
// // // //   RoomSettingsEntity _settings = const RoomSettingsEntity();
// // // //   List<ChatMessageEntity> _chatMessages = [];
// // // //   RoomConnectionState _connectionState = RoomConnectionState.connecting;
// // // //   Failure? _failure;
// // // //   bool _isSendingChat = false;
// // // //   bool _isInitialized = false;

// // // //   // Muted user IDs (local, synced from DB + Broadcast)
// // // //   final _mutedUserIds = <String>{};

// // // //   // Grace-period timers for disconnected players
// // // //   final _disconnectedTimers = <String, Timer>{};

// // // //   // ── Reconnect ─────────────────────────────────────────────────────────────
// // // //   int _reconnectAttempts = 0;
// // // //   Timer? _reconnectTimer;
// // // //   Timer? _readyPollTimer;
// // // //   static const _maxAttempts = 3;
// // // //   static const _delays = [1, 3, 7];

// // // //   // ── Lifecycle event stream (navigation triggers) ─────────────────────────
// // // //   final _lifecycleCtrl = StreamController<RoomLifecycleEvent>.broadcast();
// // // //   Stream<RoomLifecycleEvent> get lifecycleEvents => _lifecycleCtrl.stream;

// // // //   // ── Getters ───────────────────────────────────────────────────────────────
// // // //   RoomEntity? get room => _room;
// // // //   List<RoomMemberEntity> get members => _members;
// // // //   List<RoomMemberEntity> get activeMembers =>
// // // //       _members.where((m) => !m.isDisconnected).toList();
// // // //   RoomSettingsEntity get settings => _settings;
// // // //   List<ChatMessageEntity> get chatMessages => _chatMessages;
// // // //   RoomConnectionState get connectionState => _connectionState;
// // // //   Failure? get failure => _failure;
// // // //   bool get isSendingChat => _isSendingChat;
// // // //   bool get isInitialized => _isInitialized;

// // // //   bool get isOwner => _room?.ownerId == _currentUserId;
// // // //   bool get isConnected => _connectionState == RoomConnectionState.connected;
// // // //   bool get isCurrentUserMuted => _mutedUserIds.contains(_currentUserId);

// // // //   RoomMemberEntity? get currentMember => _members
// // // //       .cast<RoomMemberEntity?>()
// // // //       .firstWhere((m) => m?.userId == _currentUserId, orElse: () => null);

// // // //   bool canModerate(String targetUserId) {
// // // //     final me = currentMember;
// // // //     if (me == null) return false;
// // // //     return me.canModerate && targetUserId != _currentUserId;
// // // //   }

// // // //   // ── Initialize ─────────────────────────────────────────────────────────────
// // // //   Future<void> initialize(String roomId) async {
// // // //     _setConnection(RoomConnectionState.connecting);

// // // //     try {
// // // //       // 1. Load cached chat immediately (fast, no flicker)
// // // //       final cached = await _cache.getCachedChatMessages(roomId);
// // // //       if (cached.isNotEmpty) {
// // // //         _chatMessages = cached;
// // // //         notifyListeners();
// // // //       }

// // // //       // 2. Join the room, then retry until we can read our own member row.
// // // //       AppLogger.debug('RoomProvider: joining room $roomId as $_currentUserId');
// // // //       try {
// // // //         await _repo.joinRoom(userId: _currentUserId, roomId: roomId);
// // // //         AppLogger.debug('RoomProvider: joinRoom succeeded');
// // // //       } catch (joinErr) {
// // // //         AppLogger.warning('RoomProvider: joinRoom failed: $joinErr');
// // // //       }

// // // //       // 3. Fetch room data — retry up to 5x with 300ms gaps until members visible.
// // // //       AppLogger.debug('RoomProvider: fetching room details for $roomId');
// // // //       late RoomEntity room;
// // // //       List<RoomMemberEntity> members = [];
// // // //       late RoomSettingsEntity settings;
// // // //       late List<String> mutedIds;

// // // //       for (int attempt = 0; attempt < 5; attempt++) {
// // // //         if (attempt > 0)
// // // //           await Future.delayed(const Duration(milliseconds: 300));
// // // //         final result = await _repo.getRoomWithDetails(roomId);
// // // //         room = result.$1;
// // // //         members = result.$2;
// // // //         settings = result.$3;
// // // //         mutedIds = result.$4;
// // // //         AppLogger.debug(
// // // //           'RoomProvider: attempt $attempt — members=\${members.length}',
// // // //         );
// // // //         if (members.isNotEmpty) break;
// // // //       }

// // // //       _room = room;
// // // //       // Seed with current user if still empty after retries
// // // //       _members = members.isNotEmpty
// // // //           ? members
// // // //           : [
// // // //               RoomMemberEntity(
// // // //                 userId: _currentUserId,
// // // //                 displayName: _currentDisplayName,
// // // //                 avatarUrl: _currentAvatarUrl,
// // // //                 seatOrder: 0,
// // // //                 isReady: false,
// // // //                 isOwner: room.ownerId == _currentUserId,
// // // //                 isModerator: false,
// // // //                 isMuted: false,
// // // //               ),
// // // //             ];
// // // //       _settings = settings;
// // // //       _mutedUserIds.addAll(mutedIds);
// // // //       notifyListeners();

// // // //       // 4. Fetch fresh chat history
// // // //       final history = await _repo.getChatHistory(roomId);
// // // //       _chatMessages = history;
// // // //       await _cache.cacheChatMessages(roomId, history);
// // // //       notifyListeners();

// // // //       // 5. Subscribe to Realtime channel
// // // //       await _subscribeChannel(roomId);

// // // //       // 6. Track our own presence and announce join
// // // //       await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
// // // //       await _realtime.broadcastRoomEvent(roomId, {
// // // //         'type': 'join',
// // // //         'user_id': _currentUserId,
// // // //         'display_name': _currentDisplayName,
// // // //         'avatar_url': _currentAvatarUrl,
// // // //       });

// // // //       // 7. Update global presence to "in game"
// // // //       await _presence.setInGame(roomId);

// // // //       // 8. If room is in-game, request sync from owner
// // // //       if (room.isInGame) {
// // // //         await Future.delayed(const Duration(milliseconds: 300));
// // // //         await _realtime.broadcastSyncRequest(roomId, _currentUserId, 0);
// // // //       }

// // // //       _isInitialized = true;
// // // //       _setConnection(RoomConnectionState.connected);
// // // //     } catch (e, st) {
// // // //       AppLogger.error('RoomProvider: init failed', error: e, stackTrace: st);
// // // //       _failure = e is Failure ? e : ServerFailure(message: e.toString());
// // // //       _setConnection(RoomConnectionState.failed);
// // // //     }
// // // //   }

// // // //   // ── Channel subscription ──────────────────────────────────────────────────
// // // //   Future<void> _subscribeChannel(String roomId) async {
// // // //     // Subscribe to room_members changes via Postgres CDC
// // // //     // This is reliable even when presence fails
// // // //     _memberCdcChannel?.unsubscribe();
// // // //     _memberCdcChannel = _supabase
// // // //         .channel('room_members_cdc:$roomId')
// // // //         .onPostgresChanges(
// // // //           event: PostgresChangeEvent.all,
// // // //           schema: 'public',
// // // //           table: 'room_members',
// // // //           filter: PostgresChangeFilter(
// // // //             type: PostgresChangeFilterType.eq,
// // // //             column: 'room_id',
// // // //             value: roomId,
// // // //           ),
// // // //           callback: (_) => _refreshMembers(roomId),
// // // //         )
// // // //         .subscribe();

// // // //     // Poll ready state every 2s while in lobby — belt-and-suspenders
// // // //     _readyPollTimer?.cancel();
// // // //     _readyPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
// // // //       if (_room != null && _room!.status == RoomStatus.waiting) {
// // // //         _refreshMembers(_room!.id);
// // // //       } else {
// // // //         _readyPollTimer?.cancel();
// // // //       }
// // // //     });

// // // //     await _realtime.subscribe(
// // // //       roomId: roomId,
// // // //       onGameState: (_) {}, // forwarded to GameProvider
// // // //       onPlayerAction: (_) {},
// // // //       onSyncRequest: (_) {},
// // // //       onGameStarted: _handleGameStarted,
// // // //       onGameEnded: _handleGameEnded,
// // // //       onRoomEvent: _handleRoomEvent,
// // // //       onChatMessage: _handleChatBroadcast,
// // // //       onModeration: _handleModeration,
// // // //       onSettingsChange: _handleSettingsChange,
// // // //       onPresenceSync: _handlePresenceSync,
// // // //       onPresenceJoin: _handlePresenceJoin,
// // // //       onPresenceLeave: _handlePresenceLeave,
// // // //       onStatusChange: _handleChannelStatus,
// // // //     );
// // // //   }

// // // //   // ── Channel status ────────────────────────────────────────────────────────
// // // //   void _handleChannelStatus(RealtimeSubscribeStatus status) {
// // // //     switch (status) {
// // // //       case RealtimeSubscribeStatus.subscribed:
// // // //         _reconnectAttempts = 0;
// // // //         _reconnectTimer?.cancel();
// // // //         if (_connectionState == RoomConnectionState.reconnecting ||
// // // //             _connectionState == RoomConnectionState.recovering) {
// // // //           // Successfully reconnected — request fresh state snapshot
// // // //           _setConnection(RoomConnectionState.recovering);
// // // //           _requestSync();
// // // //         } else {
// // // //           _setConnection(RoomConnectionState.connected);
// // // //         }

// // // //       case RealtimeSubscribeStatus.closed:
// // // //         if (_connectionState == RoomConnectionState.connected) {
// // // //           _setConnection(RoomConnectionState.reconnecting);
// // // //           _scheduleReconnect();
// // // //         }

// // // //       case RealtimeSubscribeStatus.channelError:
// // // //         _setConnection(RoomConnectionState.reconnecting);
// // // //         _scheduleReconnect();

// // // //       default:
// // // //         break;
// // // //     }
// // // //   }

// // // //   // ── Reconnect ─────────────────────────────────────────────────────────────
// // // //   void _scheduleReconnect() {
// // // //     _reconnectTimer?.cancel();

// // // //     if (_reconnectAttempts >= _maxAttempts) {
// // // //       AppLogger.warning('RoomProvider: max reconnect attempts reached');
// // // //       _setConnection(RoomConnectionState.failed);
// // // //       return;
// // // //     }

// // // //     final delaySecs = _delays[_reconnectAttempts.clamp(0, _delays.length - 1)];
// // // //     AppLogger.info(
// // // //       'RoomProvider: reconnect in ${delaySecs}s (attempt ${_reconnectAttempts + 1})',
// // // //     );

// // // //     _reconnectTimer = Timer(Duration(seconds: delaySecs), () {
// // // //       _reconnectAttempts++;
// // // //       if (_room != null) {
// // // //         _realtime.unsubscribe(_room!.id).then((_) async {
// // // //           await _subscribeChannel(_room!.id);
// // // //           await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
// // // //         });
// // // //       }
// // // //     });
// // // //   }

// // // //   void retryConnection() {
// // // //     _reconnectAttempts = 0;
// // // //     _scheduleReconnect();
// // // //   }

// // // //   Future<void> _requestSync() async {
// // // //     if (_room == null) return;
// // // //     await _realtime.broadcastSyncRequest(_room!.id, _currentUserId, 0);
// // // //     // Fallback after 5s if no response
// // // //     Timer(const Duration(seconds: 5), () {
// // // //       if (_connectionState == RoomConnectionState.recovering) {
// // // //         _setConnection(RoomConnectionState.connected);
// // // //       }
// // // //     });
// // // //   }

// // // //   // ── Presence ──────────────────────────────────────────────────────────────
// // // //   Future<void> _trackOwnPresence({required int seatOrder}) async {
// // // //     if (_room == null) return;
// // // //     await _realtime.trackPresence(_room!.id, {
// // // //       PresenceKey.userId: _currentUserId,
// // // //       PresenceKey.displayName: _currentDisplayName,
// // // //       PresenceKey.avatarUrl: _currentAvatarUrl,
// // // //       PresenceKey.seatOrder: seatOrder,
// // // //       PresenceKey.isReady: currentMember?.isReady ?? false,
// // // //       PresenceKey.joinedAt: DateTime.now().toIso8601String(),
// // // //     });
// // // //   }

// // // //   /// Re-fetch member list from DB. Called on CDC events (member join/leave).
// // // //   Future<void> _refreshMembers(String roomId) async {
// // // //     try {
// // // //       final (_, freshMembers, _, _) = await _repo.getRoomWithDetails(roomId);
// // // //       if (freshMembers.isEmpty) return;
// // // //       _members = freshMembers;
// // // //       notifyListeners();
// // // //       AppLogger.debug('RoomProvider: refreshed members=${_members.length}');
// // // //     } catch (e) {
// // // //       AppLogger.warning('RoomProvider: _refreshMembers failed: $e');
// // // //     }
// // // //   }

// // // //   void _handlePresenceSync(List<Map<String, dynamic>> presences) {
// // // //     // Full presence state — source of truth for who is in the room.
// // // //     bool changed = false;

// // // //     final onlineIds = presences
// // // //         .map((p) => p[PresenceKey.userId] as String?)
// // // //         .whereType<String>()
// // // //         .toSet();

// // // //     // Update ready state for existing members from presence
// // // //     for (final p in presences) {
// // // //       final userId = p[PresenceKey.userId] as String?;
// // // //       final isReady = p[PresenceKey.isReady] as bool? ?? false;
// // // //       if (userId == null) continue;
// // // //       final existing = _members.firstWhere(
// // // //         (m) => m.userId == userId,
// // // //         orElse: () => RoomMemberEntity(
// // // //           userId: userId,
// // // //           displayName: '',
// // // //           seatOrder: 0,
// // // //           isReady: false,
// // // //           isOwner: false,
// // // //           isModerator: false,
// // // //           isMuted: false,
// // // //         ),
// // // //       );
// // // //       if (existing.userId.isNotEmpty && existing.isReady != isReady) {
// // // //         _updateMember(userId, (m) => m.copyWith(isReady: isReady));
// // // //         changed = true;
// // // //       }
// // // //     }

// // // //     // Add any presence member not yet in _members
// // // //     for (final p in presences) {
// // // //       final userId = p[PresenceKey.userId] as String?;
// // // //       if (userId == null) continue;
// // // //       if (!_members.any((m) => m.userId == userId)) {
// // // //         _members = [
// // // //           ..._members,
// // // //           RoomMemberEntity(
// // // //             userId: userId,
// // // //             displayName: p[PresenceKey.displayName] as String? ?? 'Player',
// // // //             avatarUrl: p[PresenceKey.avatarUrl] as String?,
// // // //             seatOrder: p[PresenceKey.seatOrder] as int? ?? _members.length,
// // // //             isReady: p[PresenceKey.isReady] as bool? ?? false,
// // // //             isOwner: _room?.ownerId == userId,
// // // //             isModerator: false,
// // // //             isMuted: false,
// // // //           ),
// // // //         ];
// // // //         changed = true;
// // // //       }
// // // //     }

// // // //     // Mark disconnected / reconnected members
// // // //     for (final member in _members) {
// // // //       final isOnline = onlineIds.contains(member.userId);
// // // //       if (!isOnline && !member.isDisconnected) {
// // // //         _startGracePeriod(member.userId);
// // // //         changed = true;
// // // //       } else if (isOnline && member.isDisconnected) {
// // // //         _cancelGracePeriod(member.userId);
// // // //         _updateMember(member.userId, (m) => m.copyWith(isDisconnected: false));
// // // //         changed = true;
// // // //       }
// // // //     }

// // // //     if (changed) notifyListeners();
// // // //   }

// // // //   void _handlePresenceJoin(List<Map<String, dynamic>> joins) {
// // // //     for (final p in joins) {
// // // //       final userId = p[PresenceKey.userId] as String?;
// // // //       final isReady = p[PresenceKey.isReady] as bool? ?? false;
// // // //       if (userId == null) continue;
// // // //       _cancelGracePeriod(userId);
// // // //       _updateMember(
// // // //         userId,
// // // //         (m) => m.copyWith(isDisconnected: false, isReady: isReady),
// // // //       );
// // // //     }
// // // //     notifyListeners();
// // // //   }

// // // //   void _handlePresenceLeave(List<Map<String, dynamic>> leaves) {
// // // //     for (final p in leaves) {
// // // //       final userId = p[PresenceKey.userId] as String?;
// // // //       if (userId == null || userId == _currentUserId) continue;
// // // //       _startGracePeriod(userId);
// // // //     }
// // // //   }

// // // //   void _startGracePeriod(String userId) {
// // // //     _updateMember(userId, (m) => m.copyWith(isDisconnected: true));
// // // //     _disconnectedTimers[userId]?.cancel();
// // // //     _disconnectedTimers[userId] = Timer(
// // // //       const Duration(seconds: 30),
// // // //       () => _removeMember(userId),
// // // //     );
// // // //     notifyListeners();
// // // //   }

// // // //   void _cancelGracePeriod(String userId) {
// // // //     _disconnectedTimers[userId]?.cancel();
// // // //     _disconnectedTimers.remove(userId);
// // // //   }

// // // //   // ── Room event handler ────────────────────────────────────────────────────
// // // //   void _handleRoomEvent(Map<String, dynamic> p) {
// // // //     final type = p['type'] as String?;
// // // //     final userId = p['user_id'] as String?;

// // // //     switch (type) {
// // // //       case 'join':
// // // //         if (userId != null &&
// // // //             userId != _currentUserId &&
// // // //             !_members.any((m) => m.userId == userId)) {
// // // //           _members = [
// // // //             ..._members,
// // // //             RoomMemberEntity(
// // // //               userId: userId,
// // // //               displayName: p['display_name'] as String? ?? 'Player',
// // // //               avatarUrl: p['avatar_url'] as String?,
// // // //               seatOrder: _members.length,
// // // //               isReady: false,
// // // //               isOwner: false,
// // // //               isModerator: false,
// // // //             ),
// // // //           ];
// // // //           notifyListeners();
// // // //         }

// // // //       case 'owner_left':
// // // //         // Owner closed the room — kick all followers home
// // // //         _room = _room?.copyWith(status: RoomStatus.closed);
// // // //         _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
// // // //         notifyListeners();

// // // //       case 'leave':
// // // //         if (userId != null) {
// // // //           _removeMember(userId);
// // // //           // If the owner left and no new owner assigned, close room
// // // //           if (_room != null && !_members.any((m) => m.isOwner)) {
// // // //             _room = _room?.copyWith(status: RoomStatus.closed);
// // // //             _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
// // // //             notifyListeners();
// // // //           }
// // // //         }

// // // //       case 'pack_selected':
// // // //         final packId = p['pack_id'] as String?;
// // // //         if (packId != null && _room != null) {
// // // //           _room = _room!.copyWith(packId: packId);
// // // //           notifyListeners();
// // // //         }

// // // //       case 'ready':
// // // //         if (userId != null) {
// // // //           _updateMember(userId, (m) => m.copyWith(isReady: true));
// // // //           notifyListeners();
// // // //           // Refresh DB to confirm — covers any presence lag
// // // //           if (_room != null) _refreshMembers(_room!.id);
// // // //         }

// // // //       case 'not_ready':
// // // //         if (userId != null) {
// // // //           _updateMember(userId, (m) => m.copyWith(isReady: false));
// // // //           notifyListeners();
// // // //           if (_room != null) _refreshMembers(_room!.id);
// // // //         }

// // // //       case 'ownership_transfer':
// // // //         final newOwnerId = p['new_owner_id'] as String?;
// // // //         if (newOwnerId != null && _room != null) {
// // // //           _room = _room!.copyWith(ownerId: newOwnerId);
// // // //           _members = _members
// // // //               .map((m) => m.copyWith(isOwner: m.userId == newOwnerId))
// // // //               .toList();
// // // //           notifyListeners();
// // // //           if (_currentUserId == newOwnerId) {
// // // //             _lifecycleCtrl.add(RoomLifecycleEvent.ownershipTransferred);
// // // //           }
// // // //         }
// // // //     }
// // // //   }

// // // //   void _handleGameStarted(Map<String, dynamic> p) {
// // // //     _readyPollTimer?.cancel();
// // // //     if (_room != null) {
// // // //       final gameTypeName = p['game_type'] as String?;
// // // //       final gameType = gameTypeName != null
// // // //           ? GameType.values.firstWhere(
// // // //               (g) => g.toDbString() == gameTypeName || g.name == gameTypeName,
// // // //               orElse: () => GameType.truthOrDare,
// // // //             )
// // // //           : null;
// // // //       _room = _room!.copyWith(
// // // //         status: RoomStatus.inGame,
// // // //         gameType: gameType ?? _room!.gameType,
// // // //       );
// // // //       notifyListeners();
// // // //     }
// // // //   }

// // // //   void _handleGameEnded(Map<String, dynamic> p) {
// // // //     if (_room != null) {
// // // //       _room = _room!.copyWith(status: RoomStatus.waiting);
// // // //       // Reset ready state for all members
// // // //       _members = _members.map((m) => m.copyWith(isReady: false)).toList();
// // // //       notifyListeners();
// // // //     }
// // // //   }

// // // //   // ── Chat ──────────────────────────────────────────────────────────────────
// // // //   void _handleChatBroadcast(Map<String, dynamic> p) {
// // // //     final msgId = p['id'] as String?;
// // // //     if (msgId == null) return;

// // // //     // Deduplicate: skip if already in list (optimistic or from DB)
// // // //     if (_chatMessages.any((m) => m.id == msgId)) return;

// // // //     final msg = ChatMessageEntity(
// // // //       id: msgId,
// // // //       roomId: _room?.id ?? '',
// // // //       userId: p['user_id'] as String? ?? '',
// // // //       displayName: p['display_name'] as String? ?? 'Player',
// // // //       avatarUrl: p['avatar_url'] as String?,
// // // //       content: p['content'] as String? ?? '',
// // // //       createdAt: p['ts'] != null
// // // //           ? DateTime.fromMillisecondsSinceEpoch(p['ts'] as int)
// // // //           : DateTime.now(),
// // // //     );

// // // //     _chatMessages = [..._chatMessages, msg];
// // // //     _cache.appendChatMessage(msg).ignore();
// // // //     notifyListeners();
// // // //   }

// // // //   Future<void> sendChatMessage(String content) async {
// // // //     if (_room == null || content.trim().isEmpty) return;
// // // //     if (isCurrentUserMuted) return;
// // // //     if (!_settings.chatEnabled) return;

// // // //     final trimmed = content.trim();
// // // //     final msgId = _uuid.v4();

// // // //     _isSendingChat = true;

// // // //     // Optimistic: add immediately
// // // //     final optimistic = ChatMessageEntity(
// // // //       id: msgId,
// // // //       roomId: _room!.id,
// // // //       userId: _currentUserId,
// // // //       displayName: _currentDisplayName,
// // // //       avatarUrl: _currentAvatarUrl,
// // // //       content: trimmed,
// // // //       createdAt: DateTime.now(),
// // // //       isOptimistic: true,
// // // //     );
// // // //     _chatMessages = [..._chatMessages, optimistic];
// // // //     notifyListeners();

// // // //     try {
// // // //       // Write to DB (for history persistence)
// // // //       await _repo.persistChatMessage(
// // // //         roomId: _room!.id,
// // // //         userId: _currentUserId,
// // // //         content: trimmed,
// // // //       );

// // // //       // Broadcast for instant delivery (~50ms faster than CDC)
// // // //       await _realtime.broadcastChat(_room!.id, {
// // // //         'id': msgId,
// // // //         'user_id': _currentUserId,
// // // //         'display_name': _currentDisplayName,
// // // //         'avatar_url': _currentAvatarUrl,
// // // //         'content': trimmed,
// // // //       });

// // // //       // Replace optimistic with confirmed
// // // //       _chatMessages = _chatMessages
// // // //           .map((m) => m.id == msgId ? m.copyWithConfirmed() : m)
// // // //           .toList();
// // // //     } catch (e) {
// // // //       AppLogger.error('RoomProvider: sendChat failed', error: e);
// // // //       // Remove optimistic message on failure
// // // //       _chatMessages = _chatMessages.where((m) => m.id != msgId).toList();
// // // //     } finally {
// // // //       _isSendingChat = false;
// // // //       notifyListeners();
// // // //     }
// // // //   }

// // // //   // ── Moderation handler ────────────────────────────────────────────────────
// // // //   void _handleModeration(Map<String, dynamic> p) {
// // // //     final type = p['type'] as String?;
// // // //     final targetId = p['target_user_id'] as String?;

// // // //     switch (type) {
// // // //       case 'mute':
// // // //         if (targetId != null) {
// // // //           _mutedUserIds.add(targetId);
// // // //           _updateMember(targetId, (m) => m.copyWith(isMuted: true));
// // // //           notifyListeners();
// // // //         }

// // // //       case 'unmute':
// // // //         if (targetId != null) {
// // // //           _mutedUserIds.remove(targetId);
// // // //           _updateMember(targetId, (m) => m.copyWith(isMuted: false));
// // // //           notifyListeners();
// // // //         }

// // // //       case 'kick':
// // // //         if (targetId != null) {
// // // //           _removeMember(targetId);
// // // //           if (targetId == _currentUserId) {
// // // //             _lifecycleCtrl.add(RoomLifecycleEvent.kicked);
// // // //           }
// // // //         }

// // // //       case 'ban':
// // // //         if (targetId != null) {
// // // //           _removeMember(targetId);
// // // //           if (targetId == _currentUserId) {
// // // //             _lifecycleCtrl.add(RoomLifecycleEvent.banned);
// // // //           }
// // // //         }

// // // //       case 'pause':
// // // //         _room = _room?.copyWith(status: RoomStatus.paused);
// // // //         notifyListeners();

// // // //       case 'resume':
// // // //         _room = _room?.copyWith(status: RoomStatus.inGame);
// // // //         notifyListeners();

// // // //       case 'room_close':
// // // //         _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
// // // //     }
// // // //   }

// // // //   // ── Settings handler ──────────────────────────────────────────────────────
// // // //   void _handleSettingsChange(Map<String, dynamic> p) {
// // // //     final field = p['field'] as String?;
// // // //     final value = p['new_value'];

// // // //     _settings = switch (field) {
// // // //       'turn_timer_secs' => _settings.copyWith(
// // // //         turnTimerSeconds: (value as num).toInt(),
// // // //       ),
// // // //       'allow_skip' => _settings.copyWith(allowSkip: value as bool),
// // // //       'max_rounds' => _settings.copyWith(maxRounds: (value as num).toInt()),
// // // //       'chat_enabled' => _settings.copyWith(chatEnabled: value as bool),
// // // //       'allow_spectators' => _settings.copyWith(allowSpectators: value as bool),
// // // //       'allow_spicy' => _settings.copyWith(allowSpicy: value as bool),
// // // //       'requires_approval' => _settings.copyWith(
// // // //         requiresApproval: value as bool,
// // // //       ),
// // // //       _ => _settings,
// // // //     };
// // // //     notifyListeners();
// // // //   }

// // // //   // ── Owner / moderator actions ─────────────────────────────────────────────

// // // //   Future<void> kickPlayer(String targetUserId, {String? reason}) async {
// // // //     if (!canModerate(targetUserId) || _room == null) return;
// // // //     await _repo.kickMember(_room!.id, targetUserId);
// // // //     await _realtime.broadcastModeration(_room!.id, {
// // // //       'type': 'kick',
// // // //       'target_user_id': targetUserId,
// // // //       'reason': reason,
// // // //     });
// // // //     _removeMember(targetUserId);
// // // //   }

// // // //   Future<void> mutePlayer(
// // // //     String targetUserId, {
// // // //     bool muted = true,
// // // //     int durationSeconds = 300,
// // // //   }) async {
// // // //     if (!canModerate(targetUserId) || _room == null) return;
// // // //     await _repo.muteMember(_room!.id, targetUserId, muted: muted);
// // // //     await _realtime.broadcastModeration(_room!.id, {
// // // //       'type': muted ? 'mute' : 'unmute',
// // // //       'target_user_id': targetUserId,
// // // //       'duration_seconds': durationSeconds,
// // // //     });
// // // //     if (muted) {
// // // //       _mutedUserIds.add(targetUserId);
// // // //     } else {
// // // //       _mutedUserIds.remove(targetUserId);
// // // //     }
// // // //     _updateMember(targetUserId, (m) => m.copyWith(isMuted: muted));
// // // //     notifyListeners();
// // // //   }

// // // //   Future<void> banPlayer(
// // // //     String targetUserId, {
// // // //     String? reason,
// // // //     Duration? duration,
// // // //   }) async {
// // // //     if (!isOwner || _room == null) return;
// // // //     await _repo.banMember(
// // // //       roomId: _room!.id,
// // // //       targetUserId: targetUserId,
// // // //       bannedBy: _currentUserId,
// // // //       reason: reason,
// // // //       duration: duration,
// // // //     );
// // // //     await _realtime.broadcastModeration(_room!.id, {
// // // //       'type': 'ban',
// // // //       'target_user_id': targetUserId,
// // // //       'reason': reason,
// // // //     });
// // // //     _removeMember(targetUserId);
// // // //   }

// // // //   Future<void> transferOwnership(String newOwnerId) async {
// // // //     if (!isOwner || _room == null) return;
// // // //     await _repo.transferOwnership(_room!.id, newOwnerId);
// // // //     await _realtime.broadcastRoomEvent(_room!.id, {
// // // //       'type': 'ownership_transfer',
// // // //       'user_id': _currentUserId,
// // // //       'new_owner_id': newOwnerId,
// // // //     });
// // // //     _room = _room!.copyWith(ownerId: newOwnerId);
// // // //     _members = _members
// // // //         .map((m) => m.copyWith(isOwner: m.userId == newOwnerId))
// // // //         .toList();
// // // //     notifyListeners();
// // // //   }

// // // //   Future<void> grantModerator(String userId) async {
// // // //     if (!isOwner || _room == null) return;
// // // //     await _repo.grantModerator(_room!.id, userId, _currentUserId);
// // // //     _updateMember(userId, (m) => m.copyWith(isModerator: true));
// // // //     notifyListeners();
// // // //   }

// // // //   Future<void> revokeModerator(String userId) async {
// // // //     if (!isOwner || _room == null) return;
// // // //     await _repo.revokeModerator(_room!.id, userId);
// // // //     _updateMember(userId, (m) => m.copyWith(isModerator: false));
// // // //     notifyListeners();
// // // //   }

// // // //   Future<void> pauseGame() async {
// // // //     if (!canModerate(_currentUserId) || _room == null) return;
// // // //     await _realtime.broadcastModeration(_room!.id, {'type': 'pause'});
// // // //     await _repo.updateStatus(_room!.id, RoomStatus.paused);
// // // //   }

// // // //   Future<void> resumeGame() async {
// // // //     if (!canModerate(_currentUserId) || _room == null) return;
// // // //     await _realtime.broadcastModeration(_room!.id, {'type': 'resume'});
// // // //     await _repo.updateStatus(_room!.id, RoomStatus.inGame);
// // // //   }

// // // //   Future<void> updateSetting(String field, dynamic value) async {
// // // //     if (!isOwner || _room == null) return;
// // // //     // Optimistic update
// // // //     _handleSettingsChange({'field': field, 'new_value': value});
// // // //     // Broadcast to all members
// // // //     await _realtime.broadcastSettingsChange(_room!.id, field, value);
// // // //     // Persist to DB
// // // //     await _repo.updateSettings(_room!.id, _settings);
// // // //   }

// // // //   Future<void> setPackId(String packId) async {
// // // //     if (!isOwner || _room == null) return;
// // // //     _room = _room!.copyWith(packId: packId);
// // // //     notifyListeners();
// // // //     await _supabase
// // // //         .from('rooms')
// // // //         .update({'pack_id': packId})
// // // //         .eq('id', _room!.id);
// // // //     await _realtime.broadcastRoomEvent(_room!.id, {
// // // //       'type': 'pack_selected',
// // // //       'pack_id': packId,
// // // //     });
// // // //   }

// // // //   Future<void> setReady(bool ready) async {
// // // //     if (_room == null) return;
// // // //     // Update local state immediately for snappy UI
// // // //     _updateMember(_currentUserId, (m) => m.copyWith(isReady: ready));
// // // //     notifyListeners();
// // // //     // Persist to DB — CDC on other clients will pick this up
// // // //     await _supabase
// // // //         .from('room_members')
// // // //         .update({'is_ready': ready})
// // // //         .eq('room_id', _room!.id)
// // // //         .eq('user_id', _currentUserId);
// // // //     // Update presence so presenceSync on other clients reflects isReady
// // // //     await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
// // // //     // Explicit broadcast so _handleRoomEvent fires immediately on other clients
// // // //     await _realtime.broadcastRoomEvent(_room!.id, {
// // // //       'type': ready ? 'ready' : 'not_ready',
// // // //       'user_id': _currentUserId,
// // // //     });
// // // //     // Refresh from DB to confirm state is consistent
// // // //     Future.delayed(const Duration(milliseconds: 400), () {
// // // //       if (_room != null) _refreshMembers(_room!.id);
// // // //     });
// // // //   }

// // // //   // ── Leave ─────────────────────────────────────────────────────────────────
// // // //   Future<void> leaveRoom() async {
// // // //     if (_room == null) return;
// // // //     final roomId = _room!.id;
// // // //     final amOwner = isOwner;

// // // //     // If owner leaves without a replacement, close the room for everyone
// // // //     if (amOwner) {
// // // //       await _realtime.broadcastRoomEvent(roomId, {
// // // //         'type': 'owner_left',
// // // //         'user_id': _currentUserId,
// // // //       });
// // // //       // Mark room as closed in DB
// // // //       try {
// // // //         await _supabase
// // // //             .from('rooms')
// // // //             .update({
// // // //               'status': 'closed',
// // // //               'deleted_at': DateTime.now().toIso8601String(),
// // // //             })
// // // //             .eq('id', roomId);
// // // //       } catch (_) {}
// // // //     }

// // // //     await _realtime.broadcastRoomEvent(roomId, {
// // // //       'type': 'leave',
// // // //       'user_id': _currentUserId,
// // // //       'display_name': _currentDisplayName,
// // // //     });

// // // //     await _realtime.untrackPresence(roomId);
// // // //     await _repo.leaveRoom(userId: _currentUserId, roomId: roomId);
// // // //     await _realtime.unsubscribe(roomId);
// // // //     await _presence.setOnline();
// // // //   }

// // // //   // ── Helpers ───────────────────────────────────────────────────────────────
// // // //   void _setConnection(RoomConnectionState state) {
// // // //     if (_connectionState == state) return;
// // // //     _connectionState = state;
// // // //     notifyListeners();
// // // //   }

// // // //   void _updateMember(
// // // //     String? userId,
// // // //     RoomMemberEntity Function(RoomMemberEntity) fn,
// // // //   ) {
// // // //     if (userId == null) return;
// // // //     _members = _members.map((m) => m.userId == userId ? fn(m) : m).toList();
// // // //   }

// // // //   void _removeMember(String userId) {
// // // //     _cancelGracePeriod(userId);
// // // //     _members = _members.where((m) => m.userId != userId).toList();
// // // //     notifyListeners();
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _reconnectTimer?.cancel();
// // // //     _readyPollTimer?.cancel();
// // // //     for (final t in _disconnectedTimers.values) t.cancel();
// // // //     _lifecycleCtrl.close();
// // // //     _memberCdcChannel?.unsubscribe();
// // // //     if (_room != null) _realtime.unsubscribe(_room!.id).ignore();
// // // //     super.dispose();
// // // //   }
// // // // }

// // // // // ── Extension: confirm optimistic message ─────────────────────────────────────
// // // // extension _ChatEntityX on ChatMessageEntity {
// // // //   ChatMessageEntity copyWithConfirmed() => ChatMessageEntity(
// // // //     id: id,
// // // //     roomId: roomId,
// // // //     userId: userId,
// // // //     displayName: displayName,
// // // //     avatarUrl: avatarUrl,
// // // //     content: content,
// // // //     createdAt: createdAt,
// // // //     isOptimistic: false,
// // // //     type: type,
// // // //   );
// // // // }

// // // import 'dart:async';
// // // import 'package:flutter/foundation.dart';
// // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // import '../../../core/errors/failures.dart';
// // // import '../../../core/services/realtime_service.dart';
// // // import '../../../core/services/presence_service.dart';
// // // import '../../../core/utils/app_logger.dart';
// // // import '../data/room_repository.dart';
// // // import '../data/room_cache_service.dart';
// // // import '../domain/room_entity.dart';
// // // import '../../games/engine/base_game_engine.dart';
// // // import 'package:uuid/uuid.dart';

// // // const _uuid = Uuid();

// // // // ── Connection state ──────────────────────────────────────────────────────────
// // // enum RoomConnectionState {
// // //   connecting,
// // //   connected,
// // //   reconnecting,
// // //   recovering,
// // //   failed;

// // //   bool get isStable => this == connected;
// // //   bool get isBusy =>
// // //       this == connecting || this == reconnecting || this == recovering;
// // // }

// // // // ── Events emitted to parent (e.g., for navigation) ──────────────────────────
// // // enum RoomLifecycleEvent { kicked, banned, roomClosed, ownershipTransferred }

// // // /// Complete room session state manager.
// // // ///
// // // /// Lifecycle: create → initialize() → [use] → leaveRoom() / dispose()
// // // ///
// // // /// Architecture:
// // // ///   - Single source of truth for room + members + settings + chat
// // // ///   - Hybrid chat: optimistic local + DB write + Broadcast delivery
// // // ///   - Presence via Supabase Presence (not CDC — lower overhead)
// // // ///   - Reconnect with exponential backoff: 1s, 3s, 7s then fail
// // // ///   - 30-second grace period before treating disconnected player as gone
// // // ///   - Scoped per room route — one instance per active room session
// // // class RoomProvider extends ChangeNotifier {
// // //   RoomProvider({
// // //     required RoomRepository roomRepository,
// // //     required RealtimeService realtimeService,
// // //     required PresenceService presenceService,
// // //     required RoomCacheService cacheService,
// // //     required String currentUserId,
// // //     required String currentDisplayName,
// // //     String? currentAvatarUrl,
// // //   }) : _repo = roomRepository,
// // //        _realtime = realtimeService,
// // //        _presence = presenceService,
// // //        _cache = cacheService,
// // //        _currentUserId = currentUserId,
// // //        _currentDisplayName = currentDisplayName,
// // //        _currentAvatarUrl = currentAvatarUrl;

// // //   final RoomRepository _repo;
// // //   final RealtimeService _realtime;
// // //   final PresenceService _presence;
// // //   final RoomCacheService _cache;
// // //   final String _currentUserId;
// // //   final _supabase = Supabase.instance.client;
// // //   RealtimeChannel? _memberCdcChannel;
// // //   final String _currentDisplayName;
// // //   final String? _currentAvatarUrl;

// // //   // ── State ──────────────────────────────────────────────────────────────────
// // //   RoomEntity? _room;
// // //   List<RoomMemberEntity> _members = [];
// // //   RoomSettingsEntity _settings = const RoomSettingsEntity();
// // //   List<ChatMessageEntity> _chatMessages = [];
// // //   RoomConnectionState _connectionState = RoomConnectionState.connecting;
// // //   Failure? _failure;
// // //   bool _isSendingChat = false;
// // //   bool _isInitialized = false;

// // //   // Muted user IDs (local, synced from DB + Broadcast)
// // //   final _mutedUserIds = <String>{};

// // //   // Grace-period timers for disconnected players
// // //   final _disconnectedTimers = <String, Timer>{};

// // //   // ── Reconnect ─────────────────────────────────────────────────────────────
// // //   int _reconnectAttempts = 0;
// // //   Timer? _reconnectTimer;
// // //   Timer? _readyPollTimer;
// // //   static const _maxAttempts = 3;
// // //   static const _delays = [1, 3, 7];

// // //   // ── Lifecycle event stream (navigation triggers) ─────────────────────────
// // //   final _lifecycleCtrl = StreamController<RoomLifecycleEvent>.broadcast();
// // //   Stream<RoomLifecycleEvent> get lifecycleEvents => _lifecycleCtrl.stream;

// // //   // ── Getters ───────────────────────────────────────────────────────────────
// // //   RoomEntity? get room => _room;
// // //   List<RoomMemberEntity> get members => _members;
// // //   List<RoomMemberEntity> get activeMembers =>
// // //       _members.where((m) => !m.isDisconnected).toList();
// // //   RoomSettingsEntity get settings => _settings;
// // //   List<ChatMessageEntity> get chatMessages => _chatMessages;
// // //   RoomConnectionState get connectionState => _connectionState;
// // //   Failure? get failure => _failure;
// // //   bool get isSendingChat => _isSendingChat;
// // //   bool get isInitialized => _isInitialized;

// // //   bool get isOwner => _room?.ownerId == _currentUserId;
// // //   bool get isConnected => _connectionState == RoomConnectionState.connected;
// // //   bool get isCurrentUserMuted => _mutedUserIds.contains(_currentUserId);

// // //   RoomMemberEntity? get currentMember => _members
// // //       .cast<RoomMemberEntity?>()
// // //       .firstWhere((m) => m?.userId == _currentUserId, orElse: () => null);

// // //   bool canModerate(String targetUserId) {
// // //     final me = currentMember;
// // //     if (me == null) return false;
// // //     return me.canModerate && targetUserId != _currentUserId;
// // //   }

// // //   // ── Initialize ─────────────────────────────────────────────────────────────
// // //   Future<void> initialize(String roomId, {String role = 'player'}) async {
// // //     _setConnection(RoomConnectionState.connecting);

// // //     try {
// // //       // 1. Load cached chat immediately (fast, no flicker)
// // //       final cached = await _cache.getCachedChatMessages(roomId);
// // //       if (cached.isNotEmpty) {
// // //         _chatMessages = cached;
// // //         notifyListeners();
// // //       }

// // //       // 2. Join the room, then retry until we can read our own member row.
// // //       AppLogger.debug(
// // //         'RoomProvider: joining room $roomId as $_currentUserId (role=$role)',
// // //       );
// // //       try {
// // //         await _repo.joinRoom(
// // //           userId: _currentUserId,
// // //           roomId: roomId,
// // //           role: role,
// // //         );
// // //         AppLogger.debug('RoomProvider: joinRoom succeeded');
// // //       } catch (joinErr) {
// // //         AppLogger.warning('RoomProvider: joinRoom failed: $joinErr');
// // //       }

// // //       // 3. Fetch room data — retry up to 5x with 300ms gaps until members visible.
// // //       AppLogger.debug('RoomProvider: fetching room details for $roomId');
// // //       late RoomEntity room;
// // //       List<RoomMemberEntity> members = [];
// // //       late RoomSettingsEntity settings;
// // //       late List<String> mutedIds;

// // //       for (int attempt = 0; attempt < 5; attempt++) {
// // //         if (attempt > 0)
// // //           await Future.delayed(const Duration(milliseconds: 300));
// // //         final result = await _repo.getRoomWithDetails(roomId);
// // //         room = result.$1;
// // //         members = result.$2;
// // //         settings = result.$3;
// // //         mutedIds = result.$4;
// // //         AppLogger.debug(
// // //           'RoomProvider: attempt $attempt — members=\${members.length}',
// // //         );
// // //         if (members.isNotEmpty) break;
// // //       }

// // //       _room = room;
// // //       // Seed with current user if still empty after retries
// // //       _members = members.isNotEmpty
// // //           ? members
// // //           : [
// // //               RoomMemberEntity(
// // //                 userId: _currentUserId,
// // //                 displayName: _currentDisplayName,
// // //                 avatarUrl: _currentAvatarUrl,
// // //                 seatOrder: 0,
// // //                 isReady: false,
// // //                 isOwner: room.ownerId == _currentUserId,
// // //                 isModerator: false,
// // //                 isMuted: false,
// // //               ),
// // //             ];
// // //       _settings = settings;
// // //       _mutedUserIds.addAll(mutedIds);
// // //       notifyListeners();

// // //       // 4. Fetch fresh chat history
// // //       final history = await _repo.getChatHistory(roomId);
// // //       _chatMessages = history;
// // //       await _cache.cacheChatMessages(roomId, history);
// // //       notifyListeners();

// // //       // 5. Subscribe to Realtime channel
// // //       await _subscribeChannel(roomId);

// // //       // 6. Track our own presence and announce join
// // //       await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
// // //       await _realtime.broadcastRoomEvent(roomId, {
// // //         'type': 'join',
// // //         'user_id': _currentUserId,
// // //         'display_name': _currentDisplayName,
// // //         'avatar_url': _currentAvatarUrl,
// // //       });

// // //       // 7. Update global presence to "in game"
// // //       await _presence.setInGame(roomId);

// // //       // 8. If room is in-game, request sync from owner
// // //       if (room.isInGame) {
// // //         await Future.delayed(const Duration(milliseconds: 300));
// // //         await _realtime.broadcastSyncRequest(roomId, _currentUserId, 0);
// // //       }

// // //       _isInitialized = true;
// // //       _setConnection(RoomConnectionState.connected);
// // //     } catch (e, st) {
// // //       AppLogger.error('RoomProvider: init failed', error: e, stackTrace: st);
// // //       _failure = e is Failure ? e : ServerFailure(message: e.toString());
// // //       _setConnection(RoomConnectionState.failed);
// // //     }
// // //   }

// // //   // ── Channel subscription ──────────────────────────────────────────────────
// // //   Future<void> _subscribeChannel(String roomId) async {
// // //     // Subscribe to room_members changes via Postgres CDC
// // //     // This is reliable even when presence fails
// // //     _memberCdcChannel?.unsubscribe();
// // //     _memberCdcChannel = _supabase
// // //         .channel('room_members_cdc:$roomId')
// // //         .onPostgresChanges(
// // //           event: PostgresChangeEvent.all,
// // //           schema: 'public',
// // //           table: 'room_members',
// // //           filter: PostgresChangeFilter(
// // //             type: PostgresChangeFilterType.eq,
// // //             column: 'room_id',
// // //             value: roomId,
// // //           ),
// // //           callback: (_) => _refreshMembers(roomId),
// // //         )
// // //         .subscribe();

// // //     // Poll ready state every 2s while in lobby — belt-and-suspenders
// // //     _readyPollTimer?.cancel();
// // //     _readyPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
// // //       if (_room != null && _room!.status == RoomStatus.waiting) {
// // //         _refreshMembers(_room!.id);
// // //       } else {
// // //         _readyPollTimer?.cancel();
// // //       }
// // //     });

// // //     await _realtime.subscribe(
// // //       roomId: roomId,
// // //       onGameState: (_) {}, // forwarded to GameProvider
// // //       onPlayerAction: (_) {},
// // //       onSyncRequest: (_) {},
// // //       onGameStarted: _handleGameStarted,
// // //       onGameEnded: _handleGameEnded,
// // //       onRoomEvent: _handleRoomEvent,
// // //       onChatMessage: _handleChatBroadcast,
// // //       onModeration: _handleModeration,
// // //       onSettingsChange: _handleSettingsChange,
// // //       onPresenceSync: _handlePresenceSync,
// // //       onPresenceJoin: _handlePresenceJoin,
// // //       onPresenceLeave: _handlePresenceLeave,
// // //       onStatusChange: _handleChannelStatus,
// // //     );
// // //   }

// // //   // ── Channel status ────────────────────────────────────────────────────────
// // //   void _handleChannelStatus(RealtimeSubscribeStatus status) {
// // //     switch (status) {
// // //       case RealtimeSubscribeStatus.subscribed:
// // //         _reconnectAttempts = 0;
// // //         _reconnectTimer?.cancel();
// // //         if (_connectionState == RoomConnectionState.reconnecting ||
// // //             _connectionState == RoomConnectionState.recovering) {
// // //           // Successfully reconnected — request fresh state snapshot
// // //           _setConnection(RoomConnectionState.recovering);
// // //           _requestSync();
// // //         } else {
// // //           _setConnection(RoomConnectionState.connected);
// // //         }

// // //       case RealtimeSubscribeStatus.closed:
// // //         if (_connectionState == RoomConnectionState.connected) {
// // //           _setConnection(RoomConnectionState.reconnecting);
// // //           _scheduleReconnect();
// // //         }

// // //       case RealtimeSubscribeStatus.channelError:
// // //         _setConnection(RoomConnectionState.reconnecting);
// // //         _scheduleReconnect();

// // //       default:
// // //         break;
// // //     }
// // //   }

// // //   // ── Reconnect ─────────────────────────────────────────────────────────────
// // //   void _scheduleReconnect() {
// // //     _reconnectTimer?.cancel();

// // //     if (_reconnectAttempts >= _maxAttempts) {
// // //       AppLogger.warning('RoomProvider: max reconnect attempts reached');
// // //       _setConnection(RoomConnectionState.failed);
// // //       return;
// // //     }

// // //     final delaySecs = _delays[_reconnectAttempts.clamp(0, _delays.length - 1)];
// // //     AppLogger.info(
// // //       'RoomProvider: reconnect in ${delaySecs}s (attempt ${_reconnectAttempts + 1})',
// // //     );

// // //     _reconnectTimer = Timer(Duration(seconds: delaySecs), () {
// // //       _reconnectAttempts++;
// // //       if (_room != null) {
// // //         _realtime.unsubscribe(_room!.id).then((_) async {
// // //           await _subscribeChannel(_room!.id);
// // //           await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
// // //         });
// // //       }
// // //     });
// // //   }

// // //   void retryConnection() {
// // //     _reconnectAttempts = 0;
// // //     _scheduleReconnect();
// // //   }

// // //   Future<void> _requestSync() async {
// // //     if (_room == null) return;
// // //     await _realtime.broadcastSyncRequest(_room!.id, _currentUserId, 0);
// // //     // Fallback after 5s if no response
// // //     Timer(const Duration(seconds: 5), () {
// // //       if (_connectionState == RoomConnectionState.recovering) {
// // //         _setConnection(RoomConnectionState.connected);
// // //       }
// // //     });
// // //   }

// // //   // ── Presence ──────────────────────────────────────────────────────────────
// // //   Future<void> _trackOwnPresence({required int seatOrder}) async {
// // //     if (_room == null) return;
// // //     await _realtime.trackPresence(_room!.id, {
// // //       PresenceKey.userId: _currentUserId,
// // //       PresenceKey.displayName: _currentDisplayName,
// // //       PresenceKey.avatarUrl: _currentAvatarUrl,
// // //       PresenceKey.seatOrder: seatOrder,
// // //       PresenceKey.isReady: currentMember?.isReady ?? false,
// // //       PresenceKey.joinedAt: DateTime.now().toIso8601String(),
// // //     });
// // //   }

// // //   /// Re-fetch member list from DB. Called on CDC events (member join/leave).
// // //   Future<void> _refreshMembers(String roomId) async {
// // //     try {
// // //       final (_, freshMembers, _, _) = await _repo.getRoomWithDetails(roomId);
// // //       if (freshMembers.isEmpty) return;
// // //       _members = freshMembers;
// // //       notifyListeners();
// // //       AppLogger.debug('RoomProvider: refreshed members=${_members.length}');
// // //     } catch (e) {
// // //       AppLogger.warning('RoomProvider: _refreshMembers failed: $e');
// // //     }
// // //   }

// // //   void _handlePresenceSync(List<Map<String, dynamic>> presences) {
// // //     // Full presence state — source of truth for who is in the room.
// // //     bool changed = false;

// // //     final onlineIds = presences
// // //         .map((p) => p[PresenceKey.userId] as String?)
// // //         .whereType<String>()
// // //         .toSet();

// // //     // Update ready state for existing members from presence
// // //     for (final p in presences) {
// // //       final userId = p[PresenceKey.userId] as String?;
// // //       final isReady = p[PresenceKey.isReady] as bool? ?? false;
// // //       if (userId == null) continue;
// // //       final existing = _members.firstWhere(
// // //         (m) => m.userId == userId,
// // //         orElse: () => RoomMemberEntity(
// // //           userId: userId,
// // //           displayName: '',
// // //           seatOrder: 0,
// // //           isReady: false,
// // //           isOwner: false,
// // //           isModerator: false,
// // //           isMuted: false,
// // //         ),
// // //       );
// // //       if (existing.userId.isNotEmpty && existing.isReady != isReady) {
// // //         _updateMember(userId, (m) => m.copyWith(isReady: isReady));
// // //         changed = true;
// // //       }
// // //     }

// // //     // Add any presence member not yet in _members
// // //     for (final p in presences) {
// // //       final userId = p[PresenceKey.userId] as String?;
// // //       if (userId == null) continue;
// // //       if (!_members.any((m) => m.userId == userId)) {
// // //         _members = [
// // //           ..._members,
// // //           RoomMemberEntity(
// // //             userId: userId,
// // //             displayName: p[PresenceKey.displayName] as String? ?? 'Player',
// // //             avatarUrl: p[PresenceKey.avatarUrl] as String?,
// // //             seatOrder: p[PresenceKey.seatOrder] as int? ?? _members.length,
// // //             isReady: p[PresenceKey.isReady] as bool? ?? false,
// // //             isOwner: _room?.ownerId == userId,
// // //             isModerator: false,
// // //             isMuted: false,
// // //           ),
// // //         ];
// // //         changed = true;
// // //       }
// // //     }

// // //     // Mark disconnected / reconnected members
// // //     for (final member in _members) {
// // //       final isOnline = onlineIds.contains(member.userId);
// // //       if (!isOnline && !member.isDisconnected) {
// // //         _startGracePeriod(member.userId);
// // //         changed = true;
// // //       } else if (isOnline && member.isDisconnected) {
// // //         _cancelGracePeriod(member.userId);
// // //         _updateMember(member.userId, (m) => m.copyWith(isDisconnected: false));
// // //         changed = true;
// // //       }
// // //     }

// // //     if (changed) notifyListeners();
// // //   }

// // //   void _handlePresenceJoin(List<Map<String, dynamic>> joins) {
// // //     for (final p in joins) {
// // //       final userId = p[PresenceKey.userId] as String?;
// // //       final isReady = p[PresenceKey.isReady] as bool? ?? false;
// // //       if (userId == null) continue;
// // //       _cancelGracePeriod(userId);
// // //       _updateMember(
// // //         userId,
// // //         (m) => m.copyWith(isDisconnected: false, isReady: isReady),
// // //       );
// // //     }
// // //     notifyListeners();
// // //   }

// // //   void _handlePresenceLeave(List<Map<String, dynamic>> leaves) {
// // //     for (final p in leaves) {
// // //       final userId = p[PresenceKey.userId] as String?;
// // //       if (userId == null || userId == _currentUserId) continue;
// // //       _startGracePeriod(userId);
// // //     }
// // //   }

// // //   void _startGracePeriod(String userId) {
// // //     _updateMember(userId, (m) => m.copyWith(isDisconnected: true));
// // //     _disconnectedTimers[userId]?.cancel();
// // //     _disconnectedTimers[userId] = Timer(
// // //       const Duration(seconds: 30),
// // //       () => _removeMember(userId),
// // //     );
// // //     notifyListeners();
// // //   }

// // //   void _cancelGracePeriod(String userId) {
// // //     _disconnectedTimers[userId]?.cancel();
// // //     _disconnectedTimers.remove(userId);
// // //   }

// // //   // ── Room event handler ────────────────────────────────────────────────────
// // //   void _handleRoomEvent(Map<String, dynamic> p) {
// // //     final type = p['type'] as String?;
// // //     final userId = p['user_id'] as String?;

// // //     switch (type) {
// // //       case 'join':
// // //         if (userId != null &&
// // //             userId != _currentUserId &&
// // //             !_members.any((m) => m.userId == userId)) {
// // //           _members = [
// // //             ..._members,
// // //             RoomMemberEntity(
// // //               userId: userId,
// // //               displayName: p['display_name'] as String? ?? 'Player',
// // //               avatarUrl: p['avatar_url'] as String?,
// // //               seatOrder: _members.length,
// // //               isReady: false,
// // //               isOwner: false,
// // //               isModerator: false,
// // //             ),
// // //           ];
// // //           notifyListeners();
// // //         }

// // //       case 'owner_left':
// // //         // Owner closed the room — kick all followers home
// // //         _room = _room?.copyWith(status: RoomStatus.closed);
// // //         _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
// // //         notifyListeners();

// // //       case 'leave':
// // //         if (userId != null) {
// // //           _removeMember(userId);
// // //           // If the owner left and no new owner assigned, close room
// // //           if (_room != null && !_members.any((m) => m.isOwner)) {
// // //             _room = _room?.copyWith(status: RoomStatus.closed);
// // //             _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
// // //             notifyListeners();
// // //           }
// // //         }

// // //       case 'pack_selected':
// // //         final packId = p['pack_id'] as String?;
// // //         if (packId != null && _room != null) {
// // //           _room = _room!.copyWith(packId: packId);
// // //           notifyListeners();
// // //         }

// // //       case 'ready':
// // //         if (userId != null) {
// // //           _updateMember(userId, (m) => m.copyWith(isReady: true));
// // //           notifyListeners();
// // //           // Refresh DB to confirm — covers any presence lag
// // //           if (_room != null) _refreshMembers(_room!.id);
// // //         }

// // //       case 'not_ready':
// // //         if (userId != null) {
// // //           _updateMember(userId, (m) => m.copyWith(isReady: false));
// // //           notifyListeners();
// // //           if (_room != null) _refreshMembers(_room!.id);
// // //         }

// // //       case 'ownership_transfer':
// // //         final newOwnerId = p['new_owner_id'] as String?;
// // //         if (newOwnerId != null && _room != null) {
// // //           _room = _room!.copyWith(ownerId: newOwnerId);
// // //           _members = _members
// // //               .map((m) => m.copyWith(isOwner: m.userId == newOwnerId))
// // //               .toList();
// // //           notifyListeners();
// // //           if (_currentUserId == newOwnerId) {
// // //             _lifecycleCtrl.add(RoomLifecycleEvent.ownershipTransferred);
// // //           }
// // //         }
// // //     }
// // //   }

// // //   void _handleGameStarted(Map<String, dynamic> p) {
// // //     _readyPollTimer?.cancel();
// // //     if (_room != null) {
// // //       final gameTypeName = p['game_type'] as String?;
// // //       final gameType = gameTypeName != null
// // //           ? GameType.values.firstWhere(
// // //               (g) => g.toDbString() == gameTypeName || g.name == gameTypeName,
// // //               orElse: () => GameType.truthOrDare,
// // //             )
// // //           : null;
// // //       _room = _room!.copyWith(
// // //         status: RoomStatus.inGame,
// // //         gameType: gameType ?? _room!.gameType,
// // //       );
// // //       notifyListeners();
// // //     }
// // //   }

// // //   void _handleGameEnded(Map<String, dynamic> p) {
// // //     if (_room != null) {
// // //       _room = _room!.copyWith(status: RoomStatus.waiting);
// // //       // Reset ready state for all members
// // //       _members = _members.map((m) => m.copyWith(isReady: false)).toList();
// // //       notifyListeners();
// // //     }
// // //   }

// // //   // ── Chat ──────────────────────────────────────────────────────────────────
// // //   void _handleChatBroadcast(Map<String, dynamic> p) {
// // //     final msgId = p['id'] as String?;
// // //     if (msgId == null) return;

// // //     // Deduplicate: skip if already in list (optimistic or from DB)
// // //     if (_chatMessages.any((m) => m.id == msgId)) return;

// // //     final msg = ChatMessageEntity(
// // //       id: msgId,
// // //       roomId: _room?.id ?? '',
// // //       userId: p['user_id'] as String? ?? '',
// // //       displayName: p['display_name'] as String? ?? 'Player',
// // //       avatarUrl: p['avatar_url'] as String?,
// // //       content: p['content'] as String? ?? '',
// // //       createdAt: p['ts'] != null
// // //           ? DateTime.fromMillisecondsSinceEpoch(p['ts'] as int)
// // //           : DateTime.now(),
// // //     );

// // //     _chatMessages = [..._chatMessages, msg];
// // //     _cache.appendChatMessage(msg).ignore();
// // //     notifyListeners();
// // //   }

// // //   Future<void> sendChatMessage(String content) async {
// // //     if (_room == null || content.trim().isEmpty) return;
// // //     if (isCurrentUserMuted) return;
// // //     if (!_settings.chatEnabled) return;

// // //     final trimmed = content.trim();
// // //     final msgId = _uuid.v4();

// // //     _isSendingChat = true;

// // //     // Optimistic: add immediately
// // //     final optimistic = ChatMessageEntity(
// // //       id: msgId,
// // //       roomId: _room!.id,
// // //       userId: _currentUserId,
// // //       displayName: _currentDisplayName,
// // //       avatarUrl: _currentAvatarUrl,
// // //       content: trimmed,
// // //       createdAt: DateTime.now(),
// // //       isOptimistic: true,
// // //     );
// // //     _chatMessages = [..._chatMessages, optimistic];
// // //     notifyListeners();

// // //     try {
// // //       // Write to DB (for history persistence)
// // //       await _repo.persistChatMessage(
// // //         roomId: _room!.id,
// // //         userId: _currentUserId,
// // //         content: trimmed,
// // //       );

// // //       // Broadcast for instant delivery (~50ms faster than CDC)
// // //       await _realtime.broadcastChat(_room!.id, {
// // //         'id': msgId,
// // //         'user_id': _currentUserId,
// // //         'display_name': _currentDisplayName,
// // //         'avatar_url': _currentAvatarUrl,
// // //         'content': trimmed,
// // //       });

// // //       // Replace optimistic with confirmed
// // //       _chatMessages = _chatMessages
// // //           .map((m) => m.id == msgId ? m.copyWithConfirmed() : m)
// // //           .toList();
// // //     } catch (e) {
// // //       AppLogger.error('RoomProvider: sendChat failed', error: e);
// // //       // Remove optimistic message on failure
// // //       _chatMessages = _chatMessages.where((m) => m.id != msgId).toList();
// // //     } finally {
// // //       _isSendingChat = false;
// // //       notifyListeners();
// // //     }
// // //   }

// // //   // ── Moderation handler ────────────────────────────────────────────────────
// // //   void _handleModeration(Map<String, dynamic> p) {
// // //     final type = p['type'] as String?;
// // //     final targetId = p['target_user_id'] as String?;

// // //     switch (type) {
// // //       case 'mute':
// // //         if (targetId != null) {
// // //           _mutedUserIds.add(targetId);
// // //           _updateMember(targetId, (m) => m.copyWith(isMuted: true));
// // //           notifyListeners();
// // //         }

// // //       case 'unmute':
// // //         if (targetId != null) {
// // //           _mutedUserIds.remove(targetId);
// // //           _updateMember(targetId, (m) => m.copyWith(isMuted: false));
// // //           notifyListeners();
// // //         }

// // //       case 'kick':
// // //         if (targetId != null) {
// // //           _removeMember(targetId);
// // //           if (targetId == _currentUserId) {
// // //             _lifecycleCtrl.add(RoomLifecycleEvent.kicked);
// // //           }
// // //         }

// // //       case 'ban':
// // //         if (targetId != null) {
// // //           _removeMember(targetId);
// // //           if (targetId == _currentUserId) {
// // //             _lifecycleCtrl.add(RoomLifecycleEvent.banned);
// // //           }
// // //         }

// // //       case 'pause':
// // //         _room = _room?.copyWith(status: RoomStatus.paused);
// // //         notifyListeners();

// // //       case 'resume':
// // //         _room = _room?.copyWith(status: RoomStatus.inGame);
// // //         notifyListeners();

// // //       case 'room_close':
// // //         _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
// // //     }
// // //   }

// // //   // ── Settings handler ──────────────────────────────────────────────────────
// // //   void _handleSettingsChange(Map<String, dynamic> p) {
// // //     final field = p['field'] as String?;
// // //     final value = p['new_value'];

// // //     _settings = switch (field) {
// // //       'turn_timer_secs' => _settings.copyWith(
// // //         turnTimerSeconds: (value as num).toInt(),
// // //       ),
// // //       'allow_skip' => _settings.copyWith(allowSkip: value as bool),
// // //       'max_rounds' => _settings.copyWith(maxRounds: (value as num).toInt()),
// // //       'chat_enabled' => _settings.copyWith(chatEnabled: value as bool),
// // //       'allow_spectators' => _settings.copyWith(allowSpectators: value as bool),
// // //       'allow_spicy' => _settings.copyWith(allowSpicy: value as bool),
// // //       'requires_approval' => _settings.copyWith(
// // //         requiresApproval: value as bool,
// // //       ),
// // //       _ => _settings,
// // //     };
// // //     notifyListeners();
// // //   }

// // //   // ── Owner / moderator actions ─────────────────────────────────────────────

// // //   Future<void> kickPlayer(String targetUserId, {String? reason}) async {
// // //     if (!canModerate(targetUserId) || _room == null) return;
// // //     await _repo.kickMember(_room!.id, targetUserId);
// // //     await _realtime.broadcastModeration(_room!.id, {
// // //       'type': 'kick',
// // //       'target_user_id': targetUserId,
// // //       'reason': reason,
// // //     });
// // //     _removeMember(targetUserId);
// // //   }

// // //   Future<void> mutePlayer(
// // //     String targetUserId, {
// // //     bool muted = true,
// // //     int durationSeconds = 300,
// // //   }) async {
// // //     if (!canModerate(targetUserId) || _room == null) return;
// // //     await _repo.muteMember(_room!.id, targetUserId, muted: muted);
// // //     await _realtime.broadcastModeration(_room!.id, {
// // //       'type': muted ? 'mute' : 'unmute',
// // //       'target_user_id': targetUserId,
// // //       'duration_seconds': durationSeconds,
// // //     });
// // //     if (muted) {
// // //       _mutedUserIds.add(targetUserId);
// // //     } else {
// // //       _mutedUserIds.remove(targetUserId);
// // //     }
// // //     _updateMember(targetUserId, (m) => m.copyWith(isMuted: muted));
// // //     notifyListeners();
// // //   }

// // //   Future<void> banPlayer(
// // //     String targetUserId, {
// // //     String? reason,
// // //     Duration? duration,
// // //   }) async {
// // //     if (!isOwner || _room == null) return;
// // //     await _repo.banMember(
// // //       roomId: _room!.id,
// // //       targetUserId: targetUserId,
// // //       bannedBy: _currentUserId,
// // //       reason: reason,
// // //       duration: duration,
// // //     );
// // //     await _realtime.broadcastModeration(_room!.id, {
// // //       'type': 'ban',
// // //       'target_user_id': targetUserId,
// // //       'reason': reason,
// // //     });
// // //     _removeMember(targetUserId);
// // //   }

// // //   Future<void> transferOwnership(String newOwnerId) async {
// // //     if (!isOwner || _room == null) return;
// // //     await _repo.transferOwnership(_room!.id, newOwnerId);
// // //     await _realtime.broadcastRoomEvent(_room!.id, {
// // //       'type': 'ownership_transfer',
// // //       'user_id': _currentUserId,
// // //       'new_owner_id': newOwnerId,
// // //     });
// // //     _room = _room!.copyWith(ownerId: newOwnerId);
// // //     _members = _members
// // //         .map((m) => m.copyWith(isOwner: m.userId == newOwnerId))
// // //         .toList();
// // //     notifyListeners();
// // //   }

// // //   Future<void> grantModerator(String userId) async {
// // //     if (!isOwner || _room == null) return;
// // //     await _repo.grantModerator(_room!.id, userId, _currentUserId);
// // //     _updateMember(userId, (m) => m.copyWith(isModerator: true));
// // //     notifyListeners();
// // //   }

// // //   Future<void> revokeModerator(String userId) async {
// // //     if (!isOwner || _room == null) return;
// // //     await _repo.revokeModerator(_room!.id, userId);
// // //     _updateMember(userId, (m) => m.copyWith(isModerator: false));
// // //     notifyListeners();
// // //   }

// // //   Future<void> pauseGame() async {
// // //     if (!canModerate(_currentUserId) || _room == null) return;
// // //     await _realtime.broadcastModeration(_room!.id, {'type': 'pause'});
// // //     await _repo.updateStatus(_room!.id, RoomStatus.paused);
// // //   }

// // //   Future<void> resumeGame() async {
// // //     if (!canModerate(_currentUserId) || _room == null) return;
// // //     await _realtime.broadcastModeration(_room!.id, {'type': 'resume'});
// // //     await _repo.updateStatus(_room!.id, RoomStatus.inGame);
// // //   }

// // //   Future<void> updateSetting(String field, dynamic value) async {
// // //     if (!isOwner || _room == null) return;
// // //     // Optimistic update
// // //     _handleSettingsChange({'field': field, 'new_value': value});
// // //     // Broadcast to all members
// // //     await _realtime.broadcastSettingsChange(_room!.id, field, value);
// // //     // Persist to DB
// // //     await _repo.updateSettings(_room!.id, _settings);
// // //   }

// // //   Future<void> setPackId(String packId) async {
// // //     if (!isOwner || _room == null) return;
// // //     _room = _room!.copyWith(packId: packId);
// // //     notifyListeners();
// // //     await _supabase
// // //         .from('rooms')
// // //         .update({'pack_id': packId})
// // //         .eq('id', _room!.id);
// // //     await _realtime.broadcastRoomEvent(_room!.id, {
// // //       'type': 'pack_selected',
// // //       'pack_id': packId,
// // //     });
// // //   }

// // //   Future<void> setReady(bool ready) async {
// // //     if (_room == null) return;
// // //     // Update local state immediately for snappy UI
// // //     _updateMember(_currentUserId, (m) => m.copyWith(isReady: ready));
// // //     notifyListeners();
// // //     // Persist to DB — CDC on other clients will pick this up
// // //     await _supabase
// // //         .from('room_members')
// // //         .update({'is_ready': ready})
// // //         .eq('room_id', _room!.id)
// // //         .eq('user_id', _currentUserId);
// // //     // Update presence so presenceSync on other clients reflects isReady
// // //     await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
// // //     // Explicit broadcast so _handleRoomEvent fires immediately on other clients
// // //     await _realtime.broadcastRoomEvent(_room!.id, {
// // //       'type': ready ? 'ready' : 'not_ready',
// // //       'user_id': _currentUserId,
// // //     });
// // //     // Refresh from DB to confirm state is consistent
// // //     Future.delayed(const Duration(milliseconds: 400), () {
// // //       if (_room != null) _refreshMembers(_room!.id);
// // //     });
// // //   }

// // //   // ── Leave ─────────────────────────────────────────────────────────────────
// // //   Future<void> leaveRoom() async {
// // //     if (_room == null) return;
// // //     final roomId = _room!.id;
// // //     final amOwner = isOwner;

// // //     // If owner leaves without a replacement, close the room for everyone
// // //     if (amOwner) {
// // //       await _realtime.broadcastRoomEvent(roomId, {
// // //         'type': 'owner_left',
// // //         'user_id': _currentUserId,
// // //       });
// // //       // Mark room as closed in DB
// // //       try {
// // //         await _supabase
// // //             .from('rooms')
// // //             .update({
// // //               'status': 'closed',
// // //               'deleted_at': DateTime.now().toIso8601String(),
// // //             })
// // //             .eq('id', roomId);
// // //       } catch (_) {}
// // //     }

// // //     await _realtime.broadcastRoomEvent(roomId, {
// // //       'type': 'leave',
// // //       'user_id': _currentUserId,
// // //       'display_name': _currentDisplayName,
// // //     });

// // //     await _realtime.untrackPresence(roomId);
// // //     await _repo.leaveRoom(userId: _currentUserId, roomId: roomId);
// // //     await _realtime.unsubscribe(roomId);
// // //     await _presence.setOnline();
// // //   }

// // //   // ── Helpers ───────────────────────────────────────────────────────────────
// // //   void _setConnection(RoomConnectionState state) {
// // //     if (_connectionState == state) return;
// // //     _connectionState = state;
// // //     notifyListeners();
// // //   }

// // //   void _updateMember(
// // //     String? userId,
// // //     RoomMemberEntity Function(RoomMemberEntity) fn,
// // //   ) {
// // //     if (userId == null) return;
// // //     _members = _members.map((m) => m.userId == userId ? fn(m) : m).toList();
// // //   }

// // //   void _removeMember(String userId) {
// // //     _cancelGracePeriod(userId);
// // //     _members = _members.where((m) => m.userId != userId).toList();
// // //     notifyListeners();
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _reconnectTimer?.cancel();
// // //     _readyPollTimer?.cancel();
// // //     for (final t in _disconnectedTimers.values) t.cancel();
// // //     _lifecycleCtrl.close();
// // //     _memberCdcChannel?.unsubscribe();
// // //     if (_room != null) _realtime.unsubscribe(_room!.id).ignore();
// // //     super.dispose();
// // //   }
// // // }

// // // // ── Extension: confirm optimistic message ─────────────────────────────────────
// // // extension _ChatEntityX on ChatMessageEntity {
// // //   ChatMessageEntity copyWithConfirmed() => ChatMessageEntity(
// // //     id: id,
// // //     roomId: roomId,
// // //     userId: userId,
// // //     displayName: displayName,
// // //     avatarUrl: avatarUrl,
// // //     content: content,
// // //     createdAt: createdAt,
// // //     isOptimistic: false,
// // //     type: type,
// // //   );
// // // }

// // import 'dart:async';
// // import 'package:flutter/foundation.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import '../../../core/errors/failures.dart';
// // import '../../../core/services/realtime_service.dart';
// // import '../../../core/services/presence_service.dart';
// // import '../../../core/utils/app_logger.dart';
// // import '../data/room_repository.dart';
// // import '../data/room_cache_service.dart';
// // import '../domain/room_entity.dart';
// // import '../../games/engine/base_game_engine.dart';
// // import 'package:uuid/uuid.dart';

// // const _uuid = Uuid();

// // // ── Connection state ──────────────────────────────────────────────────────────
// // enum RoomConnectionState {
// //   connecting,
// //   connected,
// //   reconnecting,
// //   recovering,
// //   failed;

// //   bool get isStable => this == connected;
// //   bool get isBusy =>
// //       this == connecting || this == reconnecting || this == recovering;
// // }

// // // ── Events emitted to parent (e.g., for navigation) ──────────────────────────
// // enum RoomLifecycleEvent { kicked, banned, roomClosed, ownershipTransferred }

// // /// Complete room session state manager.
// // ///
// // /// Lifecycle: create → initialize() → [use] → leaveRoom() / dispose()
// // ///
// // /// Architecture:
// // ///   - Single source of truth for room + members + settings + chat
// // ///   - Hybrid chat: optimistic local + DB write + Broadcast delivery
// // ///   - Presence via Supabase Presence (not CDC — lower overhead)
// // ///   - Reconnect with exponential backoff: 1s, 3s, 7s then fail
// // ///   - 30-second grace period before treating disconnected player as gone
// // ///   - Scoped per room route — one instance per active room session
// // class RoomProvider extends ChangeNotifier {
// //   RoomProvider({
// //     required RoomRepository roomRepository,
// //     required RealtimeService realtimeService,
// //     required PresenceService presenceService,
// //     required RoomCacheService cacheService,
// //     required String currentUserId,
// //     required String currentDisplayName,
// //     String? currentAvatarUrl,
// //   }) : _repo = roomRepository,
// //        _realtime = realtimeService,
// //        _presence = presenceService,
// //        _cache = cacheService,
// //        _currentUserId = currentUserId,
// //        _currentDisplayName = currentDisplayName,
// //        _currentAvatarUrl = currentAvatarUrl;

// //   final RoomRepository _repo;
// //   final RealtimeService _realtime;
// //   final PresenceService _presence;
// //   final RoomCacheService _cache;
// //   final String _currentUserId;
// //   final _supabase = Supabase.instance.client;
// //   RealtimeChannel? _memberCdcChannel;
// //   final String _currentDisplayName;
// //   final String? _currentAvatarUrl;

// //   // ── State ──────────────────────────────────────────────────────────────────
// //   RoomEntity? _room;
// //   List<RoomMemberEntity> _members = [];
// //   RoomSettingsEntity _settings = const RoomSettingsEntity();
// //   List<ChatMessageEntity> _chatMessages = [];
// //   RoomConnectionState _connectionState = RoomConnectionState.connecting;
// //   Failure? _failure;
// //   bool _isSendingChat = false;
// //   bool _isInitialized = false;

// //   // Muted user IDs (local, synced from DB + Broadcast)
// //   final _mutedUserIds = <String>{};

// //   // Grace-period timers for disconnected players
// //   final _disconnectedTimers = <String, Timer>{};

// //   // ── Reconnect ─────────────────────────────────────────────────────────────
// //   int _reconnectAttempts = 0;
// //   Timer? _reconnectTimer;
// //   Timer? _readyPollTimer;
// //   static const _maxAttempts = 3;
// //   static const _delays = [1, 3, 7];

// //   // ── Lifecycle event stream (navigation triggers) ─────────────────────────
// //   final _lifecycleCtrl = StreamController<RoomLifecycleEvent>.broadcast();
// //   Stream<RoomLifecycleEvent> get lifecycleEvents => _lifecycleCtrl.stream;

// //   // ── Getters ───────────────────────────────────────────────────────────────
// //   RoomEntity? get room => _room;
// //   List<RoomMemberEntity> get members => _members;
// //   List<RoomMemberEntity> get activeMembers =>
// //       _members.where((m) => !m.isDisconnected).toList();
// //   RoomSettingsEntity get settings => _settings;
// //   List<ChatMessageEntity> get chatMessages => _chatMessages;
// //   RoomConnectionState get connectionState => _connectionState;
// //   Failure? get failure => _failure;
// //   bool get isSendingChat => _isSendingChat;
// //   bool get isInitialized => _isInitialized;

// //   bool get isOwner => _room?.ownerId == _currentUserId;
// //   bool get isConnected => _connectionState == RoomConnectionState.connected;
// //   bool get isCurrentUserMuted => _mutedUserIds.contains(_currentUserId);

// //   RoomMemberEntity? get currentMember => _members
// //       .cast<RoomMemberEntity?>()
// //       .firstWhere((m) => m?.userId == _currentUserId, orElse: () => null);

// //   bool canModerate(String targetUserId) {
// //     final me = currentMember;
// //     if (me == null) return false;
// //     return me.canModerate && targetUserId != _currentUserId;
// //   }

// //   // ── Initialize ─────────────────────────────────────────────────────────────
// //   Future<void> initialize(String roomId, {String role = 'player'}) async {
// //     _setConnection(RoomConnectionState.connecting);

// //     try {
// //       // 1. Load cached chat immediately (fast, no flicker)
// //       final cached = await _cache.getCachedChatMessages(roomId);
// //       if (cached.isNotEmpty) {
// //         _chatMessages = cached;
// //         notifyListeners();
// //       }

// //       // 2. Join the room, then retry until we can read our own member row.
// //       AppLogger.debug(
// //         'RoomProvider: joining room $roomId as $_currentUserId (role=$role)',
// //       );
// //       try {
// //         await _repo.joinRoom(
// //           userId: _currentUserId,
// //           roomId: roomId,
// //           role: role,
// //         );
// //         AppLogger.debug('RoomProvider: joinRoom succeeded');
// //       } catch (joinErr) {
// //         AppLogger.warning('RoomProvider: joinRoom failed: $joinErr');
// //       }

// //       // 3. Fetch room data — retry up to 5x with 300ms gaps until members visible.
// //       AppLogger.debug('RoomProvider: fetching room details for $roomId');
// //       late RoomEntity room;
// //       List<RoomMemberEntity> members = [];
// //       late RoomSettingsEntity settings;
// //       late List<String> mutedIds;

// //       for (int attempt = 0; attempt < 5; attempt++) {
// //         if (attempt > 0)
// //           await Future.delayed(const Duration(milliseconds: 300));
// //         final result = await _repo.getRoomWithDetails(roomId);
// //         room = result.$1;
// //         members = result.$2;
// //         settings = result.$3;
// //         mutedIds = result.$4;
// //         AppLogger.debug(
// //           'RoomProvider: attempt $attempt — members=\${members.length}',
// //         );
// //         if (members.isNotEmpty) break;
// //       }

// //       _room = room;
// //       // Seed with current user if still empty after retries
// //       _members = members.isNotEmpty
// //           ? members
// //           : [
// //               RoomMemberEntity(
// //                 userId: _currentUserId,
// //                 displayName: _currentDisplayName,
// //                 avatarUrl: _currentAvatarUrl,
// //                 seatOrder: 0,
// //                 isReady: false,
// //                 isOwner: room.ownerId == _currentUserId,
// //                 isModerator: false,
// //                 isMuted: false,
// //               ),
// //             ];
// //       _settings = settings;
// //       _mutedUserIds.addAll(mutedIds);
// //       notifyListeners();

// //       // 4. Fetch fresh chat history
// //       final history = await _repo.getChatHistory(roomId);
// //       _chatMessages = history;
// //       await _cache.cacheChatMessages(roomId, history);
// //       notifyListeners();

// //       // 5. Subscribe to Realtime channel
// //       await _subscribeChannel(roomId);

// //       // 6. Track our own presence and announce join
// //       await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
// //       await _realtime.broadcastRoomEvent(roomId, {
// //         'type': 'join',
// //         'user_id': _currentUserId,
// //         'display_name': _currentDisplayName,
// //         'avatar_url': _currentAvatarUrl,
// //       });

// //       // 7. Update global presence to "in game"
// //       await _presence.setInGame(roomId);

// //       // 8. If room is in-game, request sync from owner
// //       if (room.isInGame) {
// //         await Future.delayed(const Duration(milliseconds: 300));
// //         await _realtime.broadcastSyncRequest(roomId, _currentUserId, 0);
// //       }

// //       _isInitialized = true;
// //       _setConnection(RoomConnectionState.connected);
// //     } catch (e, st) {
// //       AppLogger.error('RoomProvider: init failed', error: e, stackTrace: st);
// //       _failure = e is Failure ? e : ServerFailure(message: e.toString());
// //       _setConnection(RoomConnectionState.failed);
// //     }
// //   }

// //   // ── Channel subscription ──────────────────────────────────────────────────
// //   Future<void> _subscribeChannel(String roomId) async {
// //     // Subscribe to room_members changes via Postgres CDC
// //     // This is reliable even when presence fails
// //     _memberCdcChannel?.unsubscribe();
// //     _memberCdcChannel = _supabase
// //         .channel('room_members_cdc:$roomId')
// //         .onPostgresChanges(
// //           event: PostgresChangeEvent.all,
// //           schema: 'public',
// //           table: 'room_members',
// //           filter: PostgresChangeFilter(
// //             type: PostgresChangeFilterType.eq,
// //             column: 'room_id',
// //             value: roomId,
// //           ),
// //           callback: (_) => _refreshMembers(roomId),
// //         )
// //         .subscribe();

// //     // Poll ready state every 2s while in lobby — belt-and-suspenders
// //     _readyPollTimer?.cancel();
// //     _readyPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
// //       if (_room != null && _room!.status == RoomStatus.waiting) {
// //         _refreshMembers(_room!.id);
// //       } else {
// //         _readyPollTimer?.cancel();
// //       }
// //     });

// //     await _realtime.subscribe(
// //       roomId: roomId,
// //       onGameState: (_) {}, // forwarded to GameProvider
// //       onPlayerAction: (_) {},
// //       onSyncRequest: (_) {},
// //       onGameStarted: _handleGameStarted,
// //       onGameEnded: _handleGameEnded,
// //       onRoomEvent: _handleRoomEvent,
// //       onChatMessage: _handleChatBroadcast,
// //       onModeration: _handleModeration,
// //       onSettingsChange: _handleSettingsChange,
// //       onPresenceSync: _handlePresenceSync,
// //       onPresenceJoin: _handlePresenceJoin,
// //       onPresenceLeave: _handlePresenceLeave,
// //       onStatusChange: _handleChannelStatus,
// //     );
// //   }

// //   // ── Channel status ────────────────────────────────────────────────────────
// //   void _handleChannelStatus(RealtimeSubscribeStatus status) {
// //     switch (status) {
// //       case RealtimeSubscribeStatus.subscribed:
// //         _reconnectAttempts = 0;
// //         _reconnectTimer?.cancel();
// //         if (_connectionState == RoomConnectionState.reconnecting ||
// //             _connectionState == RoomConnectionState.recovering) {
// //           // Successfully reconnected — request fresh state snapshot
// //           _setConnection(RoomConnectionState.recovering);
// //           _requestSync();
// //         } else {
// //           _setConnection(RoomConnectionState.connected);
// //         }

// //       case RealtimeSubscribeStatus.closed:
// //         if (_connectionState == RoomConnectionState.connected) {
// //           _setConnection(RoomConnectionState.reconnecting);
// //           _scheduleReconnect();
// //         }

// //       case RealtimeSubscribeStatus.channelError:
// //         _setConnection(RoomConnectionState.reconnecting);
// //         _scheduleReconnect();

// //       default:
// //         break;
// //     }
// //   }

// //   // ── Reconnect ─────────────────────────────────────────────────────────────
// //   void _scheduleReconnect() {
// //     _reconnectTimer?.cancel();

// //     if (_reconnectAttempts >= _maxAttempts) {
// //       AppLogger.warning('RoomProvider: max reconnect attempts reached');
// //       _setConnection(RoomConnectionState.failed);
// //       return;
// //     }

// //     final delaySecs = _delays[_reconnectAttempts.clamp(0, _delays.length - 1)];
// //     AppLogger.info(
// //       'RoomProvider: reconnect in ${delaySecs}s (attempt ${_reconnectAttempts + 1})',
// //     );

// //     _reconnectTimer = Timer(Duration(seconds: delaySecs), () {
// //       _reconnectAttempts++;
// //       if (_room != null) {
// //         _realtime.unsubscribe(_room!.id).then((_) async {
// //           await _subscribeChannel(_room!.id);
// //           await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
// //         });
// //       }
// //     });
// //   }

// //   void retryConnection() {
// //     _reconnectAttempts = 0;
// //     _scheduleReconnect();
// //   }

// //   Future<void> _requestSync() async {
// //     if (_room == null) return;
// //     await _realtime.broadcastSyncRequest(_room!.id, _currentUserId, 0);
// //     // Fallback after 5s if no response
// //     Timer(const Duration(seconds: 5), () {
// //       if (_connectionState == RoomConnectionState.recovering) {
// //         _setConnection(RoomConnectionState.connected);
// //       }
// //     });
// //   }

// //   // ── Presence ──────────────────────────────────────────────────────────────
// //   Future<void> _trackOwnPresence({required int seatOrder}) async {
// //     if (_room == null) return;
// //     await _realtime.trackPresence(_room!.id, {
// //       PresenceKey.userId: _currentUserId,
// //       PresenceKey.displayName: _currentDisplayName,
// //       PresenceKey.avatarUrl: _currentAvatarUrl,
// //       PresenceKey.seatOrder: seatOrder,
// //       PresenceKey.isReady: currentMember?.isReady ?? false,
// //       PresenceKey.joinedAt: DateTime.now().toIso8601String(),
// //     });
// //   }

// //   /// Re-fetch member list from DB. Called on CDC events (member join/leave).
// //   Future<void> _refreshMembers(String roomId) async {
// //     try {
// //       final (_, freshMembers, _, _) = await _repo.getRoomWithDetails(roomId);
// //       if (freshMembers.isEmpty) return;
// //       _members = freshMembers;
// //       notifyListeners();
// //       AppLogger.debug('RoomProvider: refreshed members=${_members.length}');
// //     } catch (e) {
// //       AppLogger.warning('RoomProvider: _refreshMembers failed: $e');
// //     }
// //   }

// //   void _handlePresenceSync(List<Map<String, dynamic>> presences) {
// //     // Full presence state — source of truth for who is in the room.
// //     bool changed = false;

// //     final onlineIds = presences
// //         .map((p) => p[PresenceKey.userId] as String?)
// //         .whereType<String>()
// //         .toSet();

// //     // Update ready state for existing members from presence
// //     for (final p in presences) {
// //       final userId = p[PresenceKey.userId] as String?;
// //       final isReady = p[PresenceKey.isReady] as bool? ?? false;
// //       if (userId == null) continue;
// //       final existing = _members.firstWhere(
// //         (m) => m.userId == userId,
// //         orElse: () => RoomMemberEntity(
// //           userId: userId,
// //           displayName: '',
// //           seatOrder: 0,
// //           isReady: false,
// //           isOwner: false,
// //           isModerator: false,
// //           isMuted: false,
// //         ),
// //       );
// //       if (existing.userId.isNotEmpty && existing.isReady != isReady) {
// //         _updateMember(userId, (m) => m.copyWith(isReady: isReady));
// //         changed = true;
// //       }
// //     }

// //     // Add any presence member not yet in _members
// //     for (final p in presences) {
// //       final userId = p[PresenceKey.userId] as String?;
// //       if (userId == null) continue;
// //       if (!_members.any((m) => m.userId == userId)) {
// //         _members = [
// //           ..._members,
// //           RoomMemberEntity(
// //             userId: userId,
// //             displayName: p[PresenceKey.displayName] as String? ?? 'Player',
// //             avatarUrl: p[PresenceKey.avatarUrl] as String?,
// //             seatOrder: p[PresenceKey.seatOrder] as int? ?? _members.length,
// //             isReady: p[PresenceKey.isReady] as bool? ?? false,
// //             isOwner: _room?.ownerId == userId,
// //             isModerator: false,
// //             isMuted: false,
// //           ),
// //         ];
// //         changed = true;
// //       }
// //     }

// //     // Mark disconnected / reconnected members
// //     for (final member in _members) {
// //       final isOnline = onlineIds.contains(member.userId);
// //       if (!isOnline && !member.isDisconnected) {
// //         _startGracePeriod(member.userId);
// //         changed = true;
// //       } else if (isOnline && member.isDisconnected) {
// //         _cancelGracePeriod(member.userId);
// //         _updateMember(member.userId, (m) => m.copyWith(isDisconnected: false));
// //         changed = true;
// //       }
// //     }

// //     if (changed) notifyListeners();
// //   }

// //   void _handlePresenceJoin(List<Map<String, dynamic>> joins) {
// //     for (final p in joins) {
// //       final userId = p[PresenceKey.userId] as String?;
// //       final isReady = p[PresenceKey.isReady] as bool? ?? false;
// //       if (userId == null) continue;
// //       _cancelGracePeriod(userId);
// //       _updateMember(
// //         userId,
// //         (m) => m.copyWith(isDisconnected: false, isReady: isReady),
// //       );
// //     }
// //     notifyListeners();
// //   }

// //   void _handlePresenceLeave(List<Map<String, dynamic>> leaves) {
// //     for (final p in leaves) {
// //       final userId = p[PresenceKey.userId] as String?;
// //       if (userId == null || userId == _currentUserId) continue;
// //       _startGracePeriod(userId);
// //     }
// //   }

// //   void _startGracePeriod(String userId) {
// //     _updateMember(userId, (m) => m.copyWith(isDisconnected: true));
// //     _disconnectedTimers[userId]?.cancel();
// //     _disconnectedTimers[userId] = Timer(
// //       const Duration(seconds: 30),
// //       () => _removeMember(userId),
// //     );
// //     notifyListeners();
// //   }

// //   void _cancelGracePeriod(String userId) {
// //     _disconnectedTimers[userId]?.cancel();
// //     _disconnectedTimers.remove(userId);
// //   }

// //   // ── Room event handler ────────────────────────────────────────────────────
// //   void _handleRoomEvent(Map<String, dynamic> p) {
// //     final type = p['type'] as String?;
// //     final userId = p['user_id'] as String?;

// //     switch (type) {
// //       case 'join':
// //         if (userId != null &&
// //             userId != _currentUserId &&
// //             !_members.any((m) => m.userId == userId)) {
// //           _members = [
// //             ..._members,
// //             RoomMemberEntity(
// //               userId: userId,
// //               displayName: p['display_name'] as String? ?? 'Player',
// //               avatarUrl: p['avatar_url'] as String?,
// //               seatOrder: _members.length,
// //               isReady: false,
// //               isOwner: false,
// //               isModerator: false,
// //             ),
// //           ];
// //           notifyListeners();
// //         }

// //       case 'owner_left':
// //         // Owner closed the room — kick all followers home
// //         _room = _room?.copyWith(status: RoomStatus.closed);
// //         _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
// //         notifyListeners();

// //       case 'leave':
// //         if (userId != null) {
// //           _removeMember(userId);
// //           // If the owner left and no new owner assigned, close room
// //           if (_room != null && !_members.any((m) => m.isOwner)) {
// //             _room = _room?.copyWith(status: RoomStatus.closed);
// //             _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
// //             notifyListeners();
// //           }
// //         }

// //       case 'pack_selected':
// //         final packId = p['pack_id'] as String?;
// //         if (packId != null && _room != null) {
// //           _room = _room!.copyWith(packId: packId);
// //           notifyListeners();
// //         }

// //       case 'language_changed':
// //         final lang = p['language'] as String?;
// //         if (lang != null && _room != null) {
// //           _room = _room!.copyWith(language: lang);
// //           notifyListeners();
// //         }

// //       case 'ready':
// //         if (userId != null) {
// //           _updateMember(userId, (m) => m.copyWith(isReady: true));
// //           notifyListeners();
// //           // Refresh DB to confirm — covers any presence lag
// //           if (_room != null) _refreshMembers(_room!.id);
// //         }

// //       case 'not_ready':
// //         if (userId != null) {
// //           _updateMember(userId, (m) => m.copyWith(isReady: false));
// //           notifyListeners();
// //           if (_room != null) _refreshMembers(_room!.id);
// //         }

// //       case 'ownership_transfer':
// //         final newOwnerId = p['new_owner_id'] as String?;
// //         if (newOwnerId != null && _room != null) {
// //           _room = _room!.copyWith(ownerId: newOwnerId);
// //           _members = _members
// //               .map((m) => m.copyWith(isOwner: m.userId == newOwnerId))
// //               .toList();
// //           notifyListeners();
// //           if (_currentUserId == newOwnerId) {
// //             _lifecycleCtrl.add(RoomLifecycleEvent.ownershipTransferred);
// //           }
// //         }
// //     }
// //   }

// //   void _handleGameStarted(Map<String, dynamic> p) {
// //     _readyPollTimer?.cancel();
// //     if (_room != null) {
// //       final gameTypeName = p['game_type'] as String?;
// //       final gameType = gameTypeName != null
// //           ? GameType.values.firstWhere(
// //               (g) => g.toDbString() == gameTypeName || g.name == gameTypeName,
// //               orElse: () => GameType.truthOrDare,
// //             )
// //           : null;
// //       _room = _room!.copyWith(
// //         status: RoomStatus.inGame,
// //         gameType: gameType ?? _room!.gameType,
// //       );
// //       notifyListeners();
// //     }
// //   }

// //   void _handleGameEnded(Map<String, dynamic> p) {
// //     if (_room != null) {
// //       _room = _room!.copyWith(status: RoomStatus.waiting);
// //       // Reset ready state for all members
// //       _members = _members.map((m) => m.copyWith(isReady: false)).toList();
// //       notifyListeners();
// //     }
// //   }

// //   // ── Chat ──────────────────────────────────────────────────────────────────
// //   void _handleChatBroadcast(Map<String, dynamic> p) {
// //     final msgId = p['id'] as String?;
// //     if (msgId == null) return;

// //     // Deduplicate: skip if already in list (optimistic or from DB)
// //     if (_chatMessages.any((m) => m.id == msgId)) return;

// //     final msg = ChatMessageEntity(
// //       id: msgId,
// //       roomId: _room?.id ?? '',
// //       userId: p['user_id'] as String? ?? '',
// //       displayName: p['display_name'] as String? ?? 'Player',
// //       avatarUrl: p['avatar_url'] as String?,
// //       content: p['content'] as String? ?? '',
// //       createdAt: p['ts'] != null
// //           ? DateTime.fromMillisecondsSinceEpoch(p['ts'] as int)
// //           : DateTime.now(),
// //     );

// //     _chatMessages = [..._chatMessages, msg];
// //     _cache.appendChatMessage(msg).ignore();
// //     notifyListeners();
// //   }

// //   Future<void> sendChatMessage(String content) async {
// //     if (_room == null || content.trim().isEmpty) return;
// //     if (isCurrentUserMuted) return;
// //     if (!_settings.chatEnabled) return;

// //     final trimmed = content.trim();
// //     final msgId = _uuid.v4();

// //     _isSendingChat = true;

// //     // Optimistic: add immediately
// //     final optimistic = ChatMessageEntity(
// //       id: msgId,
// //       roomId: _room!.id,
// //       userId: _currentUserId,
// //       displayName: _currentDisplayName,
// //       avatarUrl: _currentAvatarUrl,
// //       content: trimmed,
// //       createdAt: DateTime.now(),
// //       isOptimistic: true,
// //     );
// //     _chatMessages = [..._chatMessages, optimistic];
// //     notifyListeners();

// //     try {
// //       // Write to DB (for history persistence)
// //       await _repo.persistChatMessage(
// //         roomId: _room!.id,
// //         userId: _currentUserId,
// //         content: trimmed,
// //       );

// //       // Broadcast for instant delivery (~50ms faster than CDC)
// //       await _realtime.broadcastChat(_room!.id, {
// //         'id': msgId,
// //         'user_id': _currentUserId,
// //         'display_name': _currentDisplayName,
// //         'avatar_url': _currentAvatarUrl,
// //         'content': trimmed,
// //       });

// //       // Replace optimistic with confirmed
// //       _chatMessages = _chatMessages
// //           .map((m) => m.id == msgId ? m.copyWithConfirmed() : m)
// //           .toList();
// //     } catch (e) {
// //       AppLogger.error('RoomProvider: sendChat failed', error: e);
// //       // Remove optimistic message on failure
// //       _chatMessages = _chatMessages.where((m) => m.id != msgId).toList();
// //     } finally {
// //       _isSendingChat = false;
// //       notifyListeners();
// //     }
// //   }

// //   // ── Moderation handler ────────────────────────────────────────────────────
// //   void _handleModeration(Map<String, dynamic> p) {
// //     final type = p['type'] as String?;
// //     final targetId = p['target_user_id'] as String?;

// //     switch (type) {
// //       case 'mute':
// //         if (targetId != null) {
// //           _mutedUserIds.add(targetId);
// //           _updateMember(targetId, (m) => m.copyWith(isMuted: true));
// //           notifyListeners();
// //         }

// //       case 'unmute':
// //         if (targetId != null) {
// //           _mutedUserIds.remove(targetId);
// //           _updateMember(targetId, (m) => m.copyWith(isMuted: false));
// //           notifyListeners();
// //         }

// //       case 'kick':
// //         if (targetId != null) {
// //           _removeMember(targetId);
// //           if (targetId == _currentUserId) {
// //             _lifecycleCtrl.add(RoomLifecycleEvent.kicked);
// //           }
// //         }

// //       case 'ban':
// //         if (targetId != null) {
// //           _removeMember(targetId);
// //           if (targetId == _currentUserId) {
// //             _lifecycleCtrl.add(RoomLifecycleEvent.banned);
// //           }
// //         }

// //       case 'pause':
// //         _room = _room?.copyWith(status: RoomStatus.paused);
// //         notifyListeners();

// //       case 'resume':
// //         _room = _room?.copyWith(status: RoomStatus.inGame);
// //         notifyListeners();

// //       case 'room_close':
// //         _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
// //     }
// //   }

// //   // ── Settings handler ──────────────────────────────────────────────────────
// //   void _handleSettingsChange(Map<String, dynamic> p) {
// //     final field = p['field'] as String?;
// //     final value = p['new_value'];

// //     _settings = switch (field) {
// //       'turn_timer_secs' => _settings.copyWith(
// //         turnTimerSeconds: (value as num).toInt(),
// //       ),
// //       'allow_skip' => _settings.copyWith(allowSkip: value as bool),
// //       'max_rounds' => _settings.copyWith(maxRounds: (value as num).toInt()),
// //       'chat_enabled' => _settings.copyWith(chatEnabled: value as bool),
// //       'allow_spectators' => _settings.copyWith(allowSpectators: value as bool),
// //       'allow_spicy' => _settings.copyWith(allowSpicy: value as bool),
// //       'requires_approval' => _settings.copyWith(
// //         requiresApproval: value as bool,
// //       ),
// //       _ => _settings,
// //     };
// //     notifyListeners();
// //   }

// //   // ── Owner / moderator actions ─────────────────────────────────────────────

// //   Future<void> kickPlayer(String targetUserId, {String? reason}) async {
// //     if (!canModerate(targetUserId) || _room == null) return;
// //     await _repo.kickMember(_room!.id, targetUserId);
// //     await _realtime.broadcastModeration(_room!.id, {
// //       'type': 'kick',
// //       'target_user_id': targetUserId,
// //       'reason': reason,
// //     });
// //     _removeMember(targetUserId);
// //   }

// //   Future<void> mutePlayer(
// //     String targetUserId, {
// //     bool muted = true,
// //     int durationSeconds = 300,
// //   }) async {
// //     if (!canModerate(targetUserId) || _room == null) return;
// //     await _repo.muteMember(_room!.id, targetUserId, muted: muted);
// //     await _realtime.broadcastModeration(_room!.id, {
// //       'type': muted ? 'mute' : 'unmute',
// //       'target_user_id': targetUserId,
// //       'duration_seconds': durationSeconds,
// //     });
// //     if (muted) {
// //       _mutedUserIds.add(targetUserId);
// //     } else {
// //       _mutedUserIds.remove(targetUserId);
// //     }
// //     _updateMember(targetUserId, (m) => m.copyWith(isMuted: muted));
// //     notifyListeners();
// //   }

// //   Future<void> banPlayer(
// //     String targetUserId, {
// //     String? reason,
// //     Duration? duration,
// //   }) async {
// //     if (!isOwner || _room == null) return;
// //     await _repo.banMember(
// //       roomId: _room!.id,
// //       targetUserId: targetUserId,
// //       bannedBy: _currentUserId,
// //       reason: reason,
// //       duration: duration,
// //     );
// //     await _realtime.broadcastModeration(_room!.id, {
// //       'type': 'ban',
// //       'target_user_id': targetUserId,
// //       'reason': reason,
// //     });
// //     _removeMember(targetUserId);
// //   }

// //   Future<void> unbanPlayer(String targetUserId) async {
// //     if (!isOwner || _room == null) return;
// //     await _repo.liftBan(_room!.id, targetUserId);
// //   }

// //   Future<void> transferOwnership(String newOwnerId) async {
// //     if (!isOwner || _room == null) return;
// //     await _repo.transferOwnership(_room!.id, newOwnerId);
// //     await _realtime.broadcastRoomEvent(_room!.id, {
// //       'type': 'ownership_transfer',
// //       'user_id': _currentUserId,
// //       'new_owner_id': newOwnerId,
// //     });
// //     _room = _room!.copyWith(ownerId: newOwnerId);
// //     _members = _members
// //         .map((m) => m.copyWith(isOwner: m.userId == newOwnerId))
// //         .toList();
// //     notifyListeners();
// //   }

// //   Future<void> grantModerator(String userId) async {
// //     if (!isOwner || _room == null) return;
// //     await _repo.grantModerator(_room!.id, userId, _currentUserId);
// //     _updateMember(userId, (m) => m.copyWith(isModerator: true));
// //     notifyListeners();
// //   }

// //   Future<void> revokeModerator(String userId) async {
// //     if (!isOwner || _room == null) return;
// //     await _repo.revokeModerator(_room!.id, userId);
// //     _updateMember(userId, (m) => m.copyWith(isModerator: false));
// //     notifyListeners();
// //   }

// //   Future<void> pauseGame() async {
// //     if (!canModerate(_currentUserId) || _room == null) return;
// //     await _realtime.broadcastModeration(_room!.id, {'type': 'pause'});
// //     await _repo.updateStatus(_room!.id, RoomStatus.paused);
// //   }

// //   Future<void> resumeGame() async {
// //     if (!canModerate(_currentUserId) || _room == null) return;
// //     await _realtime.broadcastModeration(_room!.id, {'type': 'resume'});
// //     await _repo.updateStatus(_room!.id, RoomStatus.inGame);
// //   }

// //   Future<void> updateSetting(String field, dynamic value) async {
// //     if (!isOwner || _room == null) return;
// //     // Optimistic update
// //     _handleSettingsChange({'field': field, 'new_value': value});
// //     // Broadcast to all members
// //     await _realtime.broadcastSettingsChange(_room!.id, field, value);
// //     // Persist to DB
// //     await _repo.updateSettings(_room!.id, _settings);
// //   }

// //   Future<void> setPackId(String packId) async {
// //     if (!isOwner || _room == null) return;
// //     _room = _room!.copyWith(packId: packId);
// //     notifyListeners();
// //     await _supabase
// //         .from('rooms')
// //         .update({'pack_id': packId})
// //         .eq('id', _room!.id);
// //     await _realtime.broadcastRoomEvent(_room!.id, {
// //       'type': 'pack_selected',
// //       'pack_id': packId,
// //     });
// //   }

// //   Future<void> setLanguage(String language) async {
// //     if (!isOwner || _room == null) return;
// //     _room = _room!.copyWith(language: language);
// //     notifyListeners();
// //     // Persist language to rooms table
// //     await _supabase
// //         .from('rooms')
// //         .update({'language': language})
// //         .eq('id', _room!.id);
// //     // Broadcast so followers update their UI
// //     await _realtime.broadcastRoomEvent(_room!.id, {
// //       'type': 'language_changed',
// //       'language': language,
// //     });
// //   }

// //   Future<void> setReady(bool ready) async {
// //     if (_room == null) return;
// //     // Update local state immediately for snappy UI
// //     _updateMember(_currentUserId, (m) => m.copyWith(isReady: ready));
// //     notifyListeners();
// //     // Persist to DB — CDC on other clients will pick this up
// //     await _supabase
// //         .from('room_members')
// //         .update({'is_ready': ready})
// //         .eq('room_id', _room!.id)
// //         .eq('user_id', _currentUserId);
// //     // Update presence so presenceSync on other clients reflects isReady
// //     await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
// //     // Explicit broadcast so _handleRoomEvent fires immediately on other clients
// //     await _realtime.broadcastRoomEvent(_room!.id, {
// //       'type': ready ? 'ready' : 'not_ready',
// //       'user_id': _currentUserId,
// //     });
// //     // Refresh from DB to confirm state is consistent
// //     Future.delayed(const Duration(milliseconds: 400), () {
// //       if (_room != null) _refreshMembers(_room!.id);
// //     });
// //   }

// //   // ── Leave ─────────────────────────────────────────────────────────────────
// //   Future<void> leaveRoom() async {
// //     if (_room == null) return;
// //     final roomId = _room!.id;
// //     final amOwner = isOwner;

// //     // If owner leaves without a replacement, close the room for everyone
// //     if (amOwner) {
// //       await _realtime.broadcastRoomEvent(roomId, {
// //         'type': 'owner_left',
// //         'user_id': _currentUserId,
// //       });
// //       // Mark room as closed in DB
// //       try {
// //         await _supabase
// //             .from('rooms')
// //             .update({
// //               'status': 'closed',
// //               'deleted_at': DateTime.now().toIso8601String(),
// //             })
// //             .eq('id', roomId);
// //       } catch (_) {}
// //     }

// //     await _realtime.broadcastRoomEvent(roomId, {
// //       'type': 'leave',
// //       'user_id': _currentUserId,
// //       'display_name': _currentDisplayName,
// //     });

// //     await _realtime.untrackPresence(roomId);
// //     await _repo.leaveRoom(userId: _currentUserId, roomId: roomId);
// //     await _realtime.unsubscribe(roomId);
// //     await _presence.setOnline();
// //   }

// //   // ── Helpers ───────────────────────────────────────────────────────────────
// //   void _setConnection(RoomConnectionState state) {
// //     if (_connectionState == state) return;
// //     _connectionState = state;
// //     notifyListeners();
// //   }

// //   void _updateMember(
// //     String? userId,
// //     RoomMemberEntity Function(RoomMemberEntity) fn,
// //   ) {
// //     if (userId == null) return;
// //     _members = _members.map((m) => m.userId == userId ? fn(m) : m).toList();
// //   }

// //   void _removeMember(String userId) {
// //     _cancelGracePeriod(userId);
// //     _members = _members.where((m) => m.userId != userId).toList();
// //     notifyListeners();
// //   }

// //   @override
// //   void dispose() {
// //     _reconnectTimer?.cancel();
// //     _readyPollTimer?.cancel();
// //     for (final t in _disconnectedTimers.values) t.cancel();
// //     _lifecycleCtrl.close();
// //     _memberCdcChannel?.unsubscribe();
// //     if (_room != null) _realtime.unsubscribe(_room!.id).ignore();
// //     super.dispose();
// //   }
// // }

// // // ── Extension: confirm optimistic message ─────────────────────────────────────
// // extension _ChatEntityX on ChatMessageEntity {
// //   ChatMessageEntity copyWithConfirmed() => ChatMessageEntity(
// //     id: id,
// //     roomId: roomId,
// //     userId: userId,
// //     displayName: displayName,
// //     avatarUrl: avatarUrl,
// //     content: content,
// //     createdAt: createdAt,
// //     isOptimistic: false,
// //     type: type,
// //   );
// // }

// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../../core/errors/failures.dart';
// import '../../../core/services/realtime_service.dart';
// import '../../../core/services/presence_service.dart';
// import '../../../core/utils/app_logger.dart';
// import '../data/room_repository.dart';
// import '../data/room_cache_service.dart';
// import '../domain/room_entity.dart';
// import '../../games/engine/base_game_engine.dart';
// import 'package:uuid/uuid.dart';

// const _uuid = Uuid();

// // ── Connection state ──────────────────────────────────────────────────────────
// enum RoomConnectionState {
//   connecting,
//   connected,
//   reconnecting,
//   recovering,
//   failed;

//   bool get isStable => this == connected;
//   bool get isBusy =>
//       this == connecting || this == reconnecting || this == recovering;
// }

// // ── Events emitted to parent (e.g., for navigation) ──────────────────────────
// enum RoomLifecycleEvent { kicked, banned, roomClosed, ownershipTransferred }

// /// Complete room session state manager.
// ///
// /// Lifecycle: create → initialize() → [use] → leaveRoom() / dispose()
// ///
// /// Architecture:
// ///   - Single source of truth for room + members + settings + chat
// ///   - Hybrid chat: optimistic local + DB write + Broadcast delivery
// ///   - Presence via Supabase Presence (not CDC — lower overhead)
// ///   - Reconnect with exponential backoff: 1s, 3s, 7s then fail
// ///   - 30-second grace period before treating disconnected player as gone
// ///   - Scoped per room route — one instance per active room session
// class RoomProvider extends ChangeNotifier {
//   RoomProvider({
//     required RoomRepository roomRepository,
//     required RealtimeService realtimeService,
//     required PresenceService presenceService,
//     required RoomCacheService cacheService,
//     required String currentUserId,
//     required String currentDisplayName,
//     String? currentAvatarUrl,
//   }) : _repo = roomRepository,
//        _realtime = realtimeService,
//        _presence = presenceService,
//        _cache = cacheService,
//        _currentUserId = currentUserId,
//        _currentDisplayName = currentDisplayName,
//        _currentAvatarUrl = currentAvatarUrl;

//   final RoomRepository _repo;
//   final RealtimeService _realtime;
//   final PresenceService _presence;
//   final RoomCacheService _cache;
//   final String _currentUserId;
//   final _supabase = Supabase.instance.client;
//   RealtimeChannel? _memberCdcChannel;
//   final String _currentDisplayName;
//   final String? _currentAvatarUrl;

//   // ── State ──────────────────────────────────────────────────────────────────
//   RoomEntity? _room;
//   List<RoomMemberEntity> _members = [];
//   RoomSettingsEntity _settings = const RoomSettingsEntity();
//   List<ChatMessageEntity> _chatMessages = [];
//   RoomConnectionState _connectionState = RoomConnectionState.connecting;
//   Failure? _failure;
//   bool _isSendingChat = false;
//   bool _isInitialized = false;

//   // Muted user IDs (local, synced from DB + Broadcast)
//   final _mutedUserIds = <String>{};

//   // Grace-period timers for disconnected players
//   final _disconnectedTimers = <String, Timer>{};

//   // ── Reconnect ─────────────────────────────────────────────────────────────
//   int _reconnectAttempts = 0;
//   Timer? _reconnectTimer;
//   Timer? _readyPollTimer;
//   static const _maxAttempts = 3;
//   static const _delays = [1, 3, 7];

//   // ── Lifecycle event stream (navigation triggers) ─────────────────────────
//   final _lifecycleCtrl = StreamController<RoomLifecycleEvent>.broadcast();
//   Stream<RoomLifecycleEvent> get lifecycleEvents => _lifecycleCtrl.stream;

//   // ── Getters ───────────────────────────────────────────────────────────────
//   RoomEntity? get room => _room;
//   List<RoomMemberEntity> get members => _members;
//   List<RoomMemberEntity> get activeMembers =>
//       _members.where((m) => !m.isDisconnected).toList();
//   RoomSettingsEntity get settings => _settings;
//   List<ChatMessageEntity> get chatMessages => _chatMessages;
//   RoomConnectionState get connectionState => _connectionState;
//   Failure? get failure => _failure;
//   bool get isSendingChat => _isSendingChat;
//   bool get isInitialized => _isInitialized;

//   bool get isOwner => _room?.ownerId == _currentUserId;
//   bool get isConnected => _connectionState == RoomConnectionState.connected;
//   bool get isCurrentUserMuted => _mutedUserIds.contains(_currentUserId);

//   RoomMemberEntity? get currentMember => _members
//       .cast<RoomMemberEntity?>()
//       .firstWhere((m) => m?.userId == _currentUserId, orElse: () => null);

//   bool canModerate(String targetUserId) {
//     final me = currentMember;
//     if (me == null) return false;
//     return me.canModerate && targetUserId != _currentUserId;
//   }

//   // ── Initialize ─────────────────────────────────────────────────────────────
//   Future<void> initialize(String roomId, {String role = 'player'}) async {
//     _setConnection(RoomConnectionState.connecting);

//     try {
//       // 1. Load cached chat immediately (fast, no flicker)
//       final cached = await _cache.getCachedChatMessages(roomId);
//       if (cached.isNotEmpty) {
//         _chatMessages = cached;
//         notifyListeners();
//       }

//       // 2. Join the room, then retry until we can read our own member row.
//       AppLogger.debug(
//         'RoomProvider: joining room $roomId as $_currentUserId (role=$role)',
//       );
//       try {
//         await _repo.joinRoom(
//           userId: _currentUserId,
//           roomId: roomId,
//           role: role,
//         );
//         AppLogger.debug('RoomProvider: joinRoom succeeded');
//       } catch (joinErr) {
//         AppLogger.warning('RoomProvider: joinRoom failed: $joinErr');
//       }

//       // 3. Fetch room data — retry up to 5x with 300ms gaps until members visible.
//       AppLogger.debug('RoomProvider: fetching room details for $roomId');
//       late RoomEntity room;
//       List<RoomMemberEntity> members = [];
//       late RoomSettingsEntity settings;
//       late List<String> mutedIds;

//       for (int attempt = 0; attempt < 5; attempt++) {
//         if (attempt > 0)
//           await Future.delayed(const Duration(milliseconds: 300));
//         final result = await _repo.getRoomWithDetails(roomId);
//         room = result.$1;
//         members = result.$2;
//         settings = result.$3;
//         mutedIds = result.$4;
//         AppLogger.debug(
//           'RoomProvider: attempt $attempt — members=\${members.length}',
//         );
//         if (members.isNotEmpty) break;
//       }

//       _room = room;
//       // Seed with current user if still empty after retries
//       _members = members.isNotEmpty
//           ? members
//           : [
//               RoomMemberEntity(
//                 userId: _currentUserId,
//                 displayName: _currentDisplayName,
//                 avatarUrl: _currentAvatarUrl,
//                 seatOrder: 0,
//                 isReady: false,
//                 isOwner: room.ownerId == _currentUserId,
//                 isModerator: false,
//                 isMuted: false,
//               ),
//             ];
//       _settings = settings;
//       _mutedUserIds.addAll(mutedIds);
//       notifyListeners();

//       // 4. Fetch fresh chat history
//       final history = await _repo.getChatHistory(roomId);
//       _chatMessages = history;
//       await _cache.cacheChatMessages(roomId, history);
//       notifyListeners();

//       // 5. Subscribe to Realtime channel
//       await _subscribeChannel(roomId);

//       // 6. Track our own presence and announce join
//       await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
//       await _realtime.broadcastRoomEvent(roomId, {
//         'type': 'join',
//         'user_id': _currentUserId,
//         'display_name': _currentDisplayName,
//         'avatar_url': _currentAvatarUrl,
//       });

//       // 7. Update global presence to "in game"
//       await _presence.setInGame(roomId);

//       // 8. If room is in-game, request sync from owner
//       if (room.isInGame) {
//         await Future.delayed(const Duration(milliseconds: 300));
//         await _realtime.broadcastSyncRequest(roomId, _currentUserId, 0);
//       }

//       _isInitialized = true;
//       _setConnection(RoomConnectionState.connected);
//     } catch (e, st) {
//       AppLogger.error('RoomProvider: init failed', error: e, stackTrace: st);
//       _failure = e is Failure ? e : ServerFailure(message: e.toString());
//       _setConnection(RoomConnectionState.failed);
//     }
//   }

//   // ── Channel subscription ──────────────────────────────────────────────────
//   Future<void> _subscribeChannel(String roomId) async {
//     // Subscribe to room_members changes via Postgres CDC
//     // This is reliable even when presence fails
//     _memberCdcChannel?.unsubscribe();
//     _memberCdcChannel = _supabase
//         .channel('room_members_cdc:$roomId')
//         .onPostgresChanges(
//           event: PostgresChangeEvent.all,
//           schema: 'public',
//           table: 'room_members',
//           filter: PostgresChangeFilter(
//             type: PostgresChangeFilterType.eq,
//             column: 'room_id',
//             value: roomId,
//           ),
//           callback: (_) => _refreshMembers(roomId),
//         )
//         .subscribe();

//     // Poll ready state every 2s while in lobby — belt-and-suspenders
//     _readyPollTimer?.cancel();
//     _readyPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
//       if (_room != null && _room!.status == RoomStatus.waiting) {
//         _refreshMembers(_room!.id);
//       } else {
//         _readyPollTimer?.cancel();
//       }
//     });

//     await _realtime.subscribe(
//       roomId: roomId,
//       onGameState: (_) {}, // forwarded to GameProvider
//       onPlayerAction: (_) {},
//       onSyncRequest: (_) {},
//       onGameStarted: _handleGameStarted,
//       onGameEnded: _handleGameEnded,
//       onRoomEvent: _handleRoomEvent,
//       onChatMessage: _handleChatBroadcast,
//       onModeration: _handleModeration,
//       onSettingsChange: _handleSettingsChange,
//       onPresenceSync: _handlePresenceSync,
//       onPresenceJoin: _handlePresenceJoin,
//       onPresenceLeave: _handlePresenceLeave,
//       onStatusChange: _handleChannelStatus,
//     );
//   }

//   // ── Channel status ────────────────────────────────────────────────────────
//   void _handleChannelStatus(RealtimeSubscribeStatus status) {
//     switch (status) {
//       case RealtimeSubscribeStatus.subscribed:
//         _reconnectAttempts = 0;
//         _reconnectTimer?.cancel();
//         if (_connectionState == RoomConnectionState.reconnecting ||
//             _connectionState == RoomConnectionState.recovering) {
//           // Successfully reconnected — request fresh state snapshot
//           _setConnection(RoomConnectionState.recovering);
//           _requestSync();
//         } else {
//           _setConnection(RoomConnectionState.connected);
//         }

//       case RealtimeSubscribeStatus.closed:
//         if (_connectionState == RoomConnectionState.connected) {
//           _setConnection(RoomConnectionState.reconnecting);
//           _scheduleReconnect();
//         }

//       case RealtimeSubscribeStatus.channelError:
//         _setConnection(RoomConnectionState.reconnecting);
//         _scheduleReconnect();

//       default:
//         break;
//     }
//   }

//   // ── Reconnect ─────────────────────────────────────────────────────────────
//   void _scheduleReconnect() {
//     _reconnectTimer?.cancel();

//     if (_reconnectAttempts >= _maxAttempts) {
//       AppLogger.warning('RoomProvider: max reconnect attempts reached');
//       _setConnection(RoomConnectionState.failed);
//       return;
//     }

//     final delaySecs = _delays[_reconnectAttempts.clamp(0, _delays.length - 1)];
//     AppLogger.info(
//       'RoomProvider: reconnect in ${delaySecs}s (attempt ${_reconnectAttempts + 1})',
//     );

//     _reconnectTimer = Timer(Duration(seconds: delaySecs), () {
//       _reconnectAttempts++;
//       if (_room != null) {
//         _realtime.unsubscribe(_room!.id).then((_) async {
//           await _subscribeChannel(_room!.id);
//           await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
//         });
//       }
//     });
//   }

//   void retryConnection() {
//     _reconnectAttempts = 0;
//     _scheduleReconnect();
//   }

//   Future<void> _requestSync() async {
//     if (_room == null) return;
//     await _realtime.broadcastSyncRequest(_room!.id, _currentUserId, 0);
//     // Fallback after 5s if no response
//     Timer(const Duration(seconds: 5), () {
//       if (_connectionState == RoomConnectionState.recovering) {
//         _setConnection(RoomConnectionState.connected);
//       }
//     });
//   }

//   // ── Presence ──────────────────────────────────────────────────────────────
//   Future<void> _trackOwnPresence({required int seatOrder}) async {
//     if (_room == null) return;
//     await _realtime.trackPresence(_room!.id, {
//       PresenceKey.userId: _currentUserId,
//       PresenceKey.displayName: _currentDisplayName,
//       PresenceKey.avatarUrl: _currentAvatarUrl,
//       PresenceKey.seatOrder: seatOrder,
//       PresenceKey.isReady: currentMember?.isReady ?? false,
//       PresenceKey.joinedAt: DateTime.now().toIso8601String(),
//     });
//   }

//   /// Re-fetch member list from DB. Called on CDC events (member join/leave).
//   Future<void> _refreshMembers(String roomId) async {
//     try {
//       final (_, freshMembers, _, _) = await _repo.getRoomWithDetails(roomId);
//       if (freshMembers.isEmpty) return;
//       _members = freshMembers;
//       notifyListeners();
//       AppLogger.debug('RoomProvider: refreshed members=${_members.length}');
//     } catch (e) {
//       AppLogger.warning('RoomProvider: _refreshMembers failed: $e');
//     }
//   }

//   void _handlePresenceSync(List<Map<String, dynamic>> presences) {
//     // Full presence state — source of truth for who is in the room.
//     bool changed = false;

//     final onlineIds = presences
//         .map((p) => p[PresenceKey.userId] as String?)
//         .whereType<String>()
//         .toSet();

//     // Update ready state for existing members from presence
//     for (final p in presences) {
//       final userId = p[PresenceKey.userId] as String?;
//       final isReady = p[PresenceKey.isReady] as bool? ?? false;
//       if (userId == null) continue;
//       final existing = _members.firstWhere(
//         (m) => m.userId == userId,
//         orElse: () => RoomMemberEntity(
//           userId: userId,
//           displayName: '',
//           seatOrder: 0,
//           isReady: false,
//           isOwner: false,
//           isModerator: false,
//           isMuted: false,
//         ),
//       );
//       if (existing.userId.isNotEmpty && existing.isReady != isReady) {
//         _updateMember(userId, (m) => m.copyWith(isReady: isReady));
//         changed = true;
//       }
//     }

//     // Add any presence member not yet in _members
//     for (final p in presences) {
//       final userId = p[PresenceKey.userId] as String?;
//       if (userId == null) continue;
//       if (!_members.any((m) => m.userId == userId)) {
//         _members = [
//           ..._members,
//           RoomMemberEntity(
//             userId: userId,
//             displayName: p[PresenceKey.displayName] as String? ?? 'Player',
//             avatarUrl: p[PresenceKey.avatarUrl] as String?,
//             seatOrder: p[PresenceKey.seatOrder] as int? ?? _members.length,
//             isReady: p[PresenceKey.isReady] as bool? ?? false,
//             isOwner: _room?.ownerId == userId,
//             isModerator: false,
//             isMuted: false,
//           ),
//         ];
//         changed = true;
//       }
//     }

//     // Mark disconnected / reconnected members
//     for (final member in _members) {
//       final isOnline = onlineIds.contains(member.userId);
//       if (!isOnline && !member.isDisconnected) {
//         _startGracePeriod(member.userId);
//         changed = true;
//       } else if (isOnline && member.isDisconnected) {
//         _cancelGracePeriod(member.userId);
//         _updateMember(member.userId, (m) => m.copyWith(isDisconnected: false));
//         changed = true;
//       }
//     }

//     if (changed) notifyListeners();
//   }

//   void _handlePresenceJoin(List<Map<String, dynamic>> joins) {
//     for (final p in joins) {
//       final userId = p[PresenceKey.userId] as String?;
//       final isReady = p[PresenceKey.isReady] as bool? ?? false;
//       if (userId == null) continue;
//       _cancelGracePeriod(userId);
//       _updateMember(
//         userId,
//         (m) => m.copyWith(isDisconnected: false, isReady: isReady),
//       );
//     }
//     notifyListeners();
//   }

//   void _handlePresenceLeave(List<Map<String, dynamic>> leaves) {
//     for (final p in leaves) {
//       final userId = p[PresenceKey.userId] as String?;
//       if (userId == null || userId == _currentUserId) continue;
//       _startGracePeriod(userId);
//     }
//   }

//   void _startGracePeriod(String userId) {
//     _updateMember(userId, (m) => m.copyWith(isDisconnected: true));
//     _disconnectedTimers[userId]?.cancel();
//     _disconnectedTimers[userId] = Timer(
//       const Duration(seconds: 30),
//       () => _removeMember(userId),
//     );
//     notifyListeners();
//   }

//   void _cancelGracePeriod(String userId) {
//     _disconnectedTimers[userId]?.cancel();
//     _disconnectedTimers.remove(userId);
//   }

//   // ── Room event handler ────────────────────────────────────────────────────
//   void _handleRoomEvent(Map<String, dynamic> p) {
//     final type = p['type'] as String?;
//     final userId = p['user_id'] as String?;

//     switch (type) {
//       case 'join':
//         if (userId != null &&
//             userId != _currentUserId &&
//             !_members.any((m) => m.userId == userId)) {
//           _members = [
//             ..._members,
//             RoomMemberEntity(
//               userId: userId,
//               displayName: p['display_name'] as String? ?? 'Player',
//               avatarUrl: p['avatar_url'] as String?,
//               seatOrder: _members.length,
//               isReady: false,
//               isOwner: false,
//               isModerator: false,
//             ),
//           ];
//           notifyListeners();
//         }

//       case 'owner_left':
//         // Owner closed the room — kick all followers home
//         _room = _room?.copyWith(status: RoomStatus.closed);
//         _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
//         notifyListeners();

//       case 'leave':
//         if (userId != null) {
//           _removeMember(userId);
//           // If the owner left and no new owner assigned, close room
//           if (_room != null && !_members.any((m) => m.isOwner)) {
//             _room = _room?.copyWith(status: RoomStatus.closed);
//             _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
//             notifyListeners();
//           }
//         }

//       case 'pack_selected':
//         final packId = p['pack_id'] as String?;
//         if (packId != null && _room != null) {
//           _room = _room!.copyWith(packId: packId);
//           notifyListeners();
//         }

//       case 'language_changed':
//         final lang = p['language'] as String?;
//         if (lang != null && _room != null) {
//           _room = _room!.copyWith(language: lang);
//           notifyListeners();
//         }

//       case 'ready':
//         if (userId != null) {
//           _updateMember(userId, (m) => m.copyWith(isReady: true));
//           notifyListeners();
//           // Refresh DB to confirm — covers any presence lag
//           if (_room != null) _refreshMembers(_room!.id);
//         }

//       case 'not_ready':
//         if (userId != null) {
//           _updateMember(userId, (m) => m.copyWith(isReady: false));
//           notifyListeners();
//           if (_room != null) _refreshMembers(_room!.id);
//         }

//       case 'ownership_transfer':
//         final newOwnerId = p['new_owner_id'] as String?;
//         if (newOwnerId != null && _room != null) {
//           _room = _room!.copyWith(ownerId: newOwnerId);
//           _members = _members
//               .map((m) => m.copyWith(isOwner: m.userId == newOwnerId))
//               .toList();
//           notifyListeners();
//           if (_currentUserId == newOwnerId) {
//             _lifecycleCtrl.add(RoomLifecycleEvent.ownershipTransferred);
//           }
//         }
//     }
//   }

//   void _handleGameStarted(Map<String, dynamic> p) {
//     _readyPollTimer?.cancel();
//     if (_room != null) {
//       final gameTypeName = p['game_type'] as String?;
//       final gameType = gameTypeName != null
//           ? GameType.values.firstWhere(
//               (g) => g.toDbString() == gameTypeName || g.name == gameTypeName,
//               orElse: () => GameType.truthOrDare,
//             )
//           : null;
//       _room = _room!.copyWith(
//         status: RoomStatus.inGame,
//         gameType: gameType ?? _room!.gameType,
//       );
//       notifyListeners();
//     }
//   }

//   void _handleGameEnded(Map<String, dynamic> p) {
//     if (_room != null) {
//       _room = _room!.copyWith(status: RoomStatus.waiting);
//       // Reset ready state for all members
//       _members = _members.map((m) => m.copyWith(isReady: false)).toList();
//       notifyListeners();
//     }
//   }

//   // ── Chat ──────────────────────────────────────────────────────────────────
//   void _handleChatBroadcast(Map<String, dynamic> p) {
//     final msgId = p['id'] as String?;
//     if (msgId == null) return;

//     // Deduplicate: skip if already in list (optimistic or from DB)
//     if (_chatMessages.any((m) => m.id == msgId)) return;

//     final msg = ChatMessageEntity(
//       id: msgId,
//       roomId: _room?.id ?? '',
//       userId: p['user_id'] as String? ?? '',
//       displayName: p['display_name'] as String? ?? 'Player',
//       avatarUrl: p['avatar_url'] as String?,
//       content: p['content'] as String? ?? '',
//       createdAt: p['ts'] != null
//           ? DateTime.fromMillisecondsSinceEpoch(p['ts'] as int)
//           : DateTime.now(),
//     );

//     _chatMessages = [..._chatMessages, msg];
//     _cache.appendChatMessage(msg).ignore();
//     notifyListeners();
//   }

//   Future<void> sendChatMessage(String content) async {
//     if (_room == null || content.trim().isEmpty) return;
//     if (isCurrentUserMuted) return;
//     if (!_settings.chatEnabled) return;

//     final trimmed = content.trim();
//     final msgId = _uuid.v4();

//     _isSendingChat = true;

//     // Optimistic: add immediately
//     final optimistic = ChatMessageEntity(
//       id: msgId,
//       roomId: _room!.id,
//       userId: _currentUserId,
//       displayName: _currentDisplayName,
//       avatarUrl: _currentAvatarUrl,
//       content: trimmed,
//       createdAt: DateTime.now(),
//       isOptimistic: true,
//     );
//     _chatMessages = [..._chatMessages, optimistic];
//     notifyListeners();

//     try {
//       // Write to DB (for history persistence)
//       await _repo.persistChatMessage(
//         roomId: _room!.id,
//         userId: _currentUserId,
//         content: trimmed,
//       );

//       // Broadcast for instant delivery (~50ms faster than CDC)
//       await _realtime.broadcastChat(_room!.id, {
//         'id': msgId,
//         'user_id': _currentUserId,
//         'display_name': _currentDisplayName,
//         'avatar_url': _currentAvatarUrl,
//         'content': trimmed,
//       });

//       // Replace optimistic with confirmed
//       _chatMessages = _chatMessages
//           .map((m) => m.id == msgId ? m.copyWithConfirmed() : m)
//           .toList();
//     } catch (e) {
//       AppLogger.error('RoomProvider: sendChat failed', error: e);
//       // Remove optimistic message on failure
//       _chatMessages = _chatMessages.where((m) => m.id != msgId).toList();
//     } finally {
//       _isSendingChat = false;
//       notifyListeners();
//     }
//   }

//   // ── Moderation handler ────────────────────────────────────────────────────
//   void _handleModeration(Map<String, dynamic> p) {
//     final type = p['type'] as String?;
//     final targetId = p['target_user_id'] as String?;

//     switch (type) {
//       case 'mute':
//         if (targetId != null) {
//           _mutedUserIds.add(targetId);
//           _updateMember(targetId, (m) => m.copyWith(isMuted: true));
//           notifyListeners();
//         }

//       case 'unmute':
//         if (targetId != null) {
//           _mutedUserIds.remove(targetId);
//           _updateMember(targetId, (m) => m.copyWith(isMuted: false));
//           notifyListeners();
//         }

//       case 'kick':
//         if (targetId != null) {
//           _removeMember(targetId);
//           if (targetId == _currentUserId) {
//             _lifecycleCtrl.add(RoomLifecycleEvent.kicked);
//           }
//         }

//       case 'ban':
//         if (targetId != null) {
//           _removeMember(targetId);
//           if (targetId == _currentUserId) {
//             _lifecycleCtrl.add(RoomLifecycleEvent.banned);
//           }
//         }

//       case 'pause':
//         _room = _room?.copyWith(status: RoomStatus.paused);
//         notifyListeners();

//       case 'resume':
//         _room = _room?.copyWith(status: RoomStatus.inGame);
//         notifyListeners();

//       case 'room_close':
//         _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
//     }
//   }

//   // ── Settings handler ──────────────────────────────────────────────────────
//   void _handleSettingsChange(Map<String, dynamic> p) {
//     final field = p['field'] as String?;
//     final value = p['new_value'];

//     _settings = switch (field) {
//       'turn_timer_secs' => _settings.copyWith(
//         turnTimerSeconds: (value as num).toInt(),
//       ),
//       'allow_skip' => _settings.copyWith(allowSkip: value as bool),
//       'max_rounds' => _settings.copyWith(maxRounds: (value as num).toInt()),
//       'chat_enabled' => _settings.copyWith(chatEnabled: value as bool),
//       'allow_spectators' => _settings.copyWith(allowSpectators: value as bool),
//       'allow_spicy' => _settings.copyWith(allowSpicy: value as bool),
//       'requires_approval' => _settings.copyWith(
//         requiresApproval: value as bool,
//       ),
//       _ => _settings,
//     };
//     notifyListeners();
//   }

//   // ── Owner / moderator actions ─────────────────────────────────────────────

//   Future<void> kickPlayer(String targetUserId, {String? reason}) async {
//     if (!canModerate(targetUserId) || _room == null) return;
//     await _repo.kickMember(_room!.id, targetUserId);
//     await _realtime.broadcastModeration(_room!.id, {
//       'type': 'kick',
//       'target_user_id': targetUserId,
//       'reason': reason,
//     });
//     _removeMember(targetUserId);
//   }

//   Future<void> mutePlayer(
//     String targetUserId, {
//     bool muted = true,
//     int durationSeconds = 300,
//   }) async {
//     if (!canModerate(targetUserId) || _room == null) return;
//     await _repo.muteMember(_room!.id, targetUserId, muted: muted);
//     await _realtime.broadcastModeration(_room!.id, {
//       'type': muted ? 'mute' : 'unmute',
//       'target_user_id': targetUserId,
//       'duration_seconds': durationSeconds,
//     });
//     if (muted) {
//       _mutedUserIds.add(targetUserId);
//     } else {
//       _mutedUserIds.remove(targetUserId);
//     }
//     _updateMember(targetUserId, (m) => m.copyWith(isMuted: muted));
//     notifyListeners();
//   }

//   Future<void> banPlayer(
//     String targetUserId, {
//     String? reason,
//     Duration? duration,
//   }) async {
//     if (!isOwner || _room == null) return;
//     await _repo.banMember(
//       roomId: _room!.id,
//       targetUserId: targetUserId,
//       bannedBy: _currentUserId,
//       reason: reason,
//       duration: duration,
//     );
//     await _realtime.broadcastModeration(_room!.id, {
//       'type': 'ban',
//       'target_user_id': targetUserId,
//       'reason': reason,
//     });
//     _removeMember(targetUserId);
//   }

//   Future<void> unbanPlayer(String targetUserId) async {
//     if (!isOwner || _room == null) return;
//     await _repo.liftBan(_room!.id, targetUserId);
//   }

//   Future<void> transferOwnership(String newOwnerId) async {
//     if (!isOwner || _room == null) return;
//     await _repo.transferOwnership(_room!.id, newOwnerId);
//     await _realtime.broadcastRoomEvent(_room!.id, {
//       'type': 'ownership_transfer',
//       'user_id': _currentUserId,
//       'new_owner_id': newOwnerId,
//     });
//     _room = _room!.copyWith(ownerId: newOwnerId);
//     _members = _members
//         .map((m) => m.copyWith(isOwner: m.userId == newOwnerId))
//         .toList();
//     notifyListeners();
//   }

//   Future<void> grantModerator(String userId) async {
//     if (!isOwner || _room == null) return;
//     await _repo.grantModerator(_room!.id, userId, _currentUserId);
//     _updateMember(userId, (m) => m.copyWith(isModerator: true));
//     notifyListeners();
//   }

//   Future<void> revokeModerator(String userId) async {
//     if (!isOwner || _room == null) return;
//     await _repo.revokeModerator(_room!.id, userId);
//     _updateMember(userId, (m) => m.copyWith(isModerator: false));
//     notifyListeners();
//   }

//   Future<void> pauseGame() async {
//     if (!canModerate(_currentUserId) || _room == null) return;
//     await _realtime.broadcastModeration(_room!.id, {'type': 'pause'});
//     await _repo.updateStatus(_room!.id, RoomStatus.paused);
//   }

//   Future<void> resumeGame() async {
//     if (!canModerate(_currentUserId) || _room == null) return;
//     await _realtime.broadcastModeration(_room!.id, {'type': 'resume'});
//     await _repo.updateStatus(_room!.id, RoomStatus.inGame);
//   }

//   Future<void> updateSetting(String field, dynamic value) async {
//     if (!isOwner || _room == null) return;
//     // Optimistic update
//     _handleSettingsChange({'field': field, 'new_value': value});
//     // Broadcast to all members
//     await _realtime.broadcastSettingsChange(_room!.id, field, value);
//     // Persist to DB
//     await _repo.updateSettings(_room!.id, _settings);
//   }

//   Future<void> setPackId(String packId) async {
//     if (!isOwner || _room == null) return;
//     _room = _room!.copyWith(packId: packId);
//     notifyListeners();
//     await _supabase
//         .from('rooms')
//         .update({'pack_id': packId})
//         .eq('id', _room!.id);
//     await _realtime.broadcastRoomEvent(_room!.id, {
//       'type': 'pack_selected',
//       'pack_id': packId,
//     });
//   }

//   Future<void> setLanguage(String language) async {
//     if (!isOwner || _room == null) return;
//     _room = _room!.copyWith(language: language);
//     notifyListeners();
//     // Persist language to rooms table
//     await _supabase
//         .from('rooms')
//         .update({'language': language})
//         .eq('id', _room!.id);
//     // Broadcast so followers update their UI
//     await _realtime.broadcastRoomEvent(_room!.id, {
//       'type': 'language_changed',
//       'language': language,
//     });
//   }

//   Future<void> setReady(bool ready) async {
//     if (_room == null) return;
//     // Update local state immediately for snappy UI
//     _updateMember(_currentUserId, (m) => m.copyWith(isReady: ready));
//     notifyListeners();
//     // Persist to DB — CDC on other clients will pick this up
//     await _supabase
//         .from('room_members')
//         .update({'is_ready': ready})
//         .eq('room_id', _room!.id)
//         .eq('user_id', _currentUserId);
//     // Update presence so presenceSync on other clients reflects isReady
//     await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
//     // Explicit broadcast so _handleRoomEvent fires immediately on other clients
//     await _realtime.broadcastRoomEvent(_room!.id, {
//       'type': ready ? 'ready' : 'not_ready',
//       'user_id': _currentUserId,
//     });
//     // Refresh from DB to confirm state is consistent
//     Future.delayed(const Duration(milliseconds: 400), () {
//       if (_room != null) _refreshMembers(_room!.id);
//     });
//   }

//   // ── Leave ─────────────────────────────────────────────────────────────────
//   Future<void> leaveRoom({bool permanent = false}) async {
//     if (_room == null) return;
//     final roomId = _room!.id;
//     final amOwner = isOwner;
//     final isPaused = _room!.status == RoomStatus.paused;

//     // If owner leaves and the room is NOT paused (i.e. it was not a pause-and-return),
//     // close the room for everyone. If paused, keep the room alive so players stay.
//     if (amOwner && (permanent || !isPaused)) {
//       await _realtime.broadcastRoomEvent(roomId, {
//         'type': 'owner_left',
//         'user_id': _currentUserId,
//       });
//       try {
//         await _supabase
//             .from('rooms')
//             .update({
//               'status': 'closed',
//               'deleted_at': DateTime.now().toIso8601String(),
//             })
//             .eq('id', roomId);
//       } catch (_) {}
//     }

//     await _realtime.broadcastRoomEvent(roomId, {
//       'type': 'leave',
//       'user_id': _currentUserId,
//       'display_name': _currentDisplayName,
//     });

//     await _realtime.untrackPresence(roomId);
//     await _repo.leaveRoom(userId: _currentUserId, roomId: roomId);
//     await _realtime.unsubscribe(roomId);
//     await _presence.setOnline();
//   }

//   // ── Helpers ───────────────────────────────────────────────────────────────
//   void _setConnection(RoomConnectionState state) {
//     if (_connectionState == state) return;
//     _connectionState = state;
//     notifyListeners();
//   }

//   void _updateMember(
//     String? userId,
//     RoomMemberEntity Function(RoomMemberEntity) fn,
//   ) {
//     if (userId == null) return;
//     _members = _members.map((m) => m.userId == userId ? fn(m) : m).toList();
//   }

//   void _removeMember(String userId) {
//     _cancelGracePeriod(userId);
//     _members = _members.where((m) => m.userId != userId).toList();
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     _reconnectTimer?.cancel();
//     _readyPollTimer?.cancel();
//     for (final t in _disconnectedTimers.values) t.cancel();
//     _lifecycleCtrl.close();
//     _memberCdcChannel?.unsubscribe();
//     if (_room != null) _realtime.unsubscribe(_room!.id).ignore();
//     super.dispose();
//   }
// }

// // ── Extension: confirm optimistic message ─────────────────────────────────────
// extension _ChatEntityX on ChatMessageEntity {
//   ChatMessageEntity copyWithConfirmed() => ChatMessageEntity(
//     id: id,
//     roomId: roomId,
//     userId: userId,
//     displayName: displayName,
//     avatarUrl: avatarUrl,
//     content: content,
//     createdAt: createdAt,
//     isOptimistic: false,
//     type: type,
//   );
// }

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/utils/app_logger.dart';
import '../data/room_repository.dart';
import '../data/room_cache_service.dart';
import '../domain/room_entity.dart';
import '../../games/engine/base_game_engine.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ── Connection state ──────────────────────────────────────────────────────────
enum RoomConnectionState {
  connecting,
  connected,
  reconnecting,
  recovering,
  failed;

  bool get isStable => this == connected;
  bool get isBusy =>
      this == connecting || this == reconnecting || this == recovering;
}

// ── Events emitted to parent (e.g., for navigation) ──────────────────────────
enum RoomLifecycleEvent { kicked, banned, roomClosed, ownershipTransferred }

/// Complete room session state manager.
///
/// Lifecycle: create → initialize() → [use] → leaveRoom() / dispose()
///
/// Architecture:
///   - Single source of truth for room + members + settings + chat
///   - Hybrid chat: optimistic local + DB write + Broadcast delivery
///   - Presence via Supabase Presence (not CDC — lower overhead)
///   - Reconnect with exponential backoff: 1s, 3s, 7s then fail
///   - 30-second grace period before treating disconnected player as gone
///   - Scoped per room route — one instance per active room session
class RoomProvider extends ChangeNotifier {
  RoomProvider({
    required RoomRepository roomRepository,
    required RealtimeService realtimeService,
    required PresenceService presenceService,
    required RoomCacheService cacheService,
    required String currentUserId,
    required String currentDisplayName,
    String? currentAvatarUrl,
  }) : _repo = roomRepository,
       _realtime = realtimeService,
       _presence = presenceService,
       _cache = cacheService,
       _currentUserId = currentUserId,
       _currentDisplayName = currentDisplayName,
       _currentAvatarUrl = currentAvatarUrl;

  final RoomRepository _repo;
  final RealtimeService _realtime;
  final PresenceService _presence;
  final RoomCacheService _cache;
  final String _currentUserId;
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _memberCdcChannel;
  final String _currentDisplayName;
  final String? _currentAvatarUrl;

  // ── State ──────────────────────────────────────────────────────────────────
  RoomEntity? _room;
  List<RoomMemberEntity> _members = [];
  RoomSettingsEntity _settings = const RoomSettingsEntity();
  List<ChatMessageEntity> _chatMessages = [];
  RoomConnectionState _connectionState = RoomConnectionState.connecting;
  Failure? _failure;
  bool _isSendingChat = false;
  bool _isInitialized = false;

  // Muted user IDs (local, synced from DB + Broadcast)
  final _mutedUserIds = <String>{};

  // Grace-period timers for disconnected players
  final _disconnectedTimers = <String, Timer>{};

  // ── Reconnect ─────────────────────────────────────────────────────────────
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _readyPollTimer;
  static const _maxAttempts = 3;
  static const _delays = [1, 3, 7];

  // ── Lifecycle event stream (navigation triggers) ─────────────────────────
  final _lifecycleCtrl = StreamController<RoomLifecycleEvent>.broadcast();
  Stream<RoomLifecycleEvent> get lifecycleEvents => _lifecycleCtrl.stream;

  // ── Getters ───────────────────────────────────────────────────────────────
  RoomEntity? get room => _room;
  List<RoomMemberEntity> get members => _members;
  List<RoomMemberEntity> get activeMembers =>
      _members.where((m) => !m.isDisconnected).toList();
  RoomSettingsEntity get settings => _settings;
  List<ChatMessageEntity> get chatMessages => _chatMessages;
  RoomConnectionState get connectionState => _connectionState;
  Failure? get failure => _failure;
  bool get isSendingChat => _isSendingChat;
  bool get isInitialized => _isInitialized;

  bool get isOwner => _room?.ownerId == _currentUserId;
  bool get isConnected => _connectionState == RoomConnectionState.connected;
  bool get isCurrentUserMuted => _mutedUserIds.contains(_currentUserId);

  RoomMemberEntity? get currentMember => _members
      .cast<RoomMemberEntity?>()
      .firstWhere((m) => m?.userId == _currentUserId, orElse: () => null);

  bool canModerate(String targetUserId) {
    final me = currentMember;
    if (me == null) return false;
    return me.canModerate && targetUserId != _currentUserId;
  }

  // ── Initialize ─────────────────────────────────────────────────────────────
  Future<void> initialize(String roomId, {String role = 'player'}) async {
    _setConnection(RoomConnectionState.connecting);

    try {
      // 1. Load cached chat immediately (fast, no flicker)
      final cached = await _cache.getCachedChatMessages(roomId);
      if (cached.isNotEmpty) {
        _chatMessages = cached;
        notifyListeners();
      }

      // 2. Join the room, then retry until we can read our own member row.
      AppLogger.debug(
        'RoomProvider: joining room $roomId as $_currentUserId (role=$role)',
      );
      try {
        await _repo.joinRoom(
          userId: _currentUserId,
          roomId: roomId,
          role: role,
        );
        AppLogger.debug('RoomProvider: joinRoom succeeded');
      } catch (joinErr) {
        AppLogger.warning('RoomProvider: joinRoom failed: $joinErr');
      }

      // 3. Fetch room data — retry up to 5x with 300ms gaps until members visible.
      AppLogger.debug('RoomProvider: fetching room details for $roomId');
      late RoomEntity room;
      List<RoomMemberEntity> members = [];
      late RoomSettingsEntity settings;
      late List<String> mutedIds;

      for (int attempt = 0; attempt < 5; attempt++) {
        if (attempt > 0)
          await Future.delayed(const Duration(milliseconds: 300));
        final result = await _repo.getRoomWithDetails(roomId);
        room = result.$1;
        members = result.$2;
        settings = result.$3;
        mutedIds = result.$4;
        AppLogger.debug(
          'RoomProvider: attempt $attempt — members=\${members.length}',
        );
        if (members.isNotEmpty) break;
      }

      _room = room;
      // Seed with current user if still empty after retries
      _members = members.isNotEmpty
          ? members
          : [
              RoomMemberEntity(
                userId: _currentUserId,
                displayName: _currentDisplayName,
                avatarUrl: _currentAvatarUrl,
                seatOrder: 0,
                isReady: false,
                isOwner: room.ownerId == _currentUserId,
                isModerator: false,
                isMuted: false,
              ),
            ];
      _settings = settings;
      _mutedUserIds.addAll(mutedIds);
      notifyListeners();

      // 4. Fetch fresh chat history
      final history = await _repo.getChatHistory(roomId);
      _chatMessages = history;
      await _cache.cacheChatMessages(roomId, history);
      notifyListeners();

      // 5. Subscribe to Realtime channel
      await _subscribeChannel(roomId);

      // 6. Track our own presence and announce join
      await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
      await _realtime.broadcastRoomEvent(roomId, {
        'type': 'join',
        'user_id': _currentUserId,
        'display_name': _currentDisplayName,
        'avatar_url': _currentAvatarUrl,
      });

      // 7. Update global presence to "in game"
      await _presence.setInGame(roomId);

      // 8. If room is in-game, request sync from owner
      if (room.isInGame) {
        await Future.delayed(const Duration(milliseconds: 300));
        await _realtime.broadcastSyncRequest(roomId, _currentUserId, 0);
      }

      _isInitialized = true;
      _setConnection(RoomConnectionState.connected);
    } catch (e, st) {
      AppLogger.error('RoomProvider: init failed', error: e, stackTrace: st);
      _failure = e is Failure ? e : ServerFailure(message: e.toString());
      _setConnection(RoomConnectionState.failed);
    }
  }

  // ── Channel subscription ──────────────────────────────────────────────────
  Future<void> _subscribeChannel(String roomId) async {
    // Subscribe to room_members changes via Postgres CDC
    // This is reliable even when presence fails
    _memberCdcChannel?.unsubscribe();
    _memberCdcChannel = _supabase
        .channel('room_members_cdc:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (_) => _refreshMembers(roomId),
        )
        .subscribe();

    // Poll ready state every 2s while in lobby — belt-and-suspenders
    _readyPollTimer?.cancel();
    _readyPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_room != null && _room!.status == RoomStatus.waiting) {
        _refreshMembers(_room!.id);
      } else {
        _readyPollTimer?.cancel();
      }
    });

    await _realtime.subscribe(
      roomId: roomId,
      onGameState: (_) {}, // forwarded to GameProvider
      onPlayerAction: (_) {},
      onSyncRequest: (_) {},
      onGameStarted: _handleGameStarted,
      onGameEnded: _handleGameEnded,
      onRoomEvent: _handleRoomEvent,
      onChatMessage: _handleChatBroadcast,
      onModeration: _handleModeration,
      onSettingsChange: _handleSettingsChange,
      onPresenceSync: _handlePresenceSync,
      onPresenceJoin: _handlePresenceJoin,
      onPresenceLeave: _handlePresenceLeave,
      onStatusChange: _handleChannelStatus,
    );
  }

  // ── Channel status ────────────────────────────────────────────────────────
  void _handleChannelStatus(RealtimeSubscribeStatus status) {
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
        if (_connectionState == RoomConnectionState.reconnecting ||
            _connectionState == RoomConnectionState.recovering) {
          // Successfully reconnected — request fresh state snapshot
          _setConnection(RoomConnectionState.recovering);
          _requestSync();
        } else {
          _setConnection(RoomConnectionState.connected);
        }

      case RealtimeSubscribeStatus.closed:
        if (_connectionState == RoomConnectionState.connected) {
          _setConnection(RoomConnectionState.reconnecting);
          _scheduleReconnect();
        }

      case RealtimeSubscribeStatus.channelError:
        _setConnection(RoomConnectionState.reconnecting);
        _scheduleReconnect();

      default:
        break;
    }
  }

  // ── Reconnect ─────────────────────────────────────────────────────────────
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    if (_reconnectAttempts >= _maxAttempts) {
      AppLogger.warning('RoomProvider: max reconnect attempts reached');
      _setConnection(RoomConnectionState.failed);
      return;
    }

    final delaySecs = _delays[_reconnectAttempts.clamp(0, _delays.length - 1)];
    AppLogger.info(
      'RoomProvider: reconnect in ${delaySecs}s (attempt ${_reconnectAttempts + 1})',
    );

    _reconnectTimer = Timer(Duration(seconds: delaySecs), () {
      _reconnectAttempts++;
      if (_room != null) {
        _realtime.unsubscribe(_room!.id).then((_) async {
          await _subscribeChannel(_room!.id);
          await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
        });
      }
    });
  }

  void retryConnection() {
    _reconnectAttempts = 0;
    _scheduleReconnect();
  }

  Future<void> _requestSync() async {
    if (_room == null) return;
    await _realtime.broadcastSyncRequest(_room!.id, _currentUserId, 0);
    // Fallback after 5s if no response
    Timer(const Duration(seconds: 5), () {
      if (_connectionState == RoomConnectionState.recovering) {
        _setConnection(RoomConnectionState.connected);
      }
    });
  }

  // ── Presence ──────────────────────────────────────────────────────────────
  Future<void> _trackOwnPresence({required int seatOrder}) async {
    if (_room == null) return;
    await _realtime.trackPresence(_room!.id, {
      PresenceKey.userId: _currentUserId,
      PresenceKey.displayName: _currentDisplayName,
      PresenceKey.avatarUrl: _currentAvatarUrl,
      PresenceKey.seatOrder: seatOrder,
      PresenceKey.isReady: currentMember?.isReady ?? false,
      PresenceKey.joinedAt: DateTime.now().toIso8601String(),
    });
  }

  /// Re-fetch member list from DB. Called on CDC events (member join/leave).
  Future<void> _refreshMembers(String roomId) async {
    try {
      final (_, freshMembers, _, _) = await _repo.getRoomWithDetails(roomId);
      if (freshMembers.isEmpty) return;
      _members = freshMembers;
      notifyListeners();
      AppLogger.debug('RoomProvider: refreshed members=${_members.length}');
    } catch (e) {
      AppLogger.warning('RoomProvider: _refreshMembers failed: $e');
    }
  }

  void _handlePresenceSync(List<Map<String, dynamic>> presences) {
    // Full presence state — source of truth for who is in the room.
    bool changed = false;

    final onlineIds = presences
        .map((p) => p[PresenceKey.userId] as String?)
        .whereType<String>()
        .toSet();

    // Update ready state for existing members from presence
    for (final p in presences) {
      final userId = p[PresenceKey.userId] as String?;
      final isReady = p[PresenceKey.isReady] as bool? ?? false;
      if (userId == null) continue;
      final existing = _members.firstWhere(
        (m) => m.userId == userId,
        orElse: () => RoomMemberEntity(
          userId: userId,
          displayName: '',
          seatOrder: 0,
          isReady: false,
          isOwner: false,
          isModerator: false,
          isMuted: false,
        ),
      );
      if (existing.userId.isNotEmpty && existing.isReady != isReady) {
        _updateMember(userId, (m) => m.copyWith(isReady: isReady));
        changed = true;
      }
    }

    // Add any presence member not yet in _members
    for (final p in presences) {
      final userId = p[PresenceKey.userId] as String?;
      if (userId == null) continue;
      if (!_members.any((m) => m.userId == userId)) {
        _members = [
          ..._members,
          RoomMemberEntity(
            userId: userId,
            displayName: p[PresenceKey.displayName] as String? ?? 'Player',
            avatarUrl: p[PresenceKey.avatarUrl] as String?,
            seatOrder: p[PresenceKey.seatOrder] as int? ?? _members.length,
            isReady: p[PresenceKey.isReady] as bool? ?? false,
            isOwner: _room?.ownerId == userId,
            isModerator: false,
            isMuted: false,
          ),
        ];
        changed = true;
      }
    }

    // Mark disconnected / reconnected members
    for (final member in _members) {
      final isOnline = onlineIds.contains(member.userId);
      if (!isOnline && !member.isDisconnected) {
        _startGracePeriod(member.userId);
        changed = true;
      } else if (isOnline && member.isDisconnected) {
        _cancelGracePeriod(member.userId);
        _updateMember(member.userId, (m) => m.copyWith(isDisconnected: false));
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  void _handlePresenceJoin(List<Map<String, dynamic>> joins) {
    for (final p in joins) {
      final userId = p[PresenceKey.userId] as String?;
      final isReady = p[PresenceKey.isReady] as bool? ?? false;
      if (userId == null) continue;
      _cancelGracePeriod(userId);
      _updateMember(
        userId,
        (m) => m.copyWith(isDisconnected: false, isReady: isReady),
      );
    }
    notifyListeners();
  }

  void _handlePresenceLeave(List<Map<String, dynamic>> leaves) {
    for (final p in leaves) {
      final userId = p[PresenceKey.userId] as String?;
      if (userId == null || userId == _currentUserId) continue;
      _startGracePeriod(userId);
    }
  }

  void _startGracePeriod(String userId) {
    _updateMember(userId, (m) => m.copyWith(isDisconnected: true));
    _disconnectedTimers[userId]?.cancel();
    _disconnectedTimers[userId] = Timer(
      const Duration(seconds: 30),
      () => _removeMember(userId),
    );
    notifyListeners();
  }

  void _cancelGracePeriod(String userId) {
    _disconnectedTimers[userId]?.cancel();
    _disconnectedTimers.remove(userId);
  }

  // ── Room event handler ────────────────────────────────────────────────────
  void _handleRoomEvent(Map<String, dynamic> p) {
    final type = p['type'] as String?;
    final userId = p['user_id'] as String?;

    switch (type) {
      case 'join':
        if (userId != null &&
            userId != _currentUserId &&
            !_members.any((m) => m.userId == userId)) {
          _members = [
            ..._members,
            RoomMemberEntity(
              userId: userId,
              displayName: p['display_name'] as String? ?? 'Player',
              avatarUrl: p['avatar_url'] as String?,
              seatOrder: _members.length,
              isReady: false,
              isOwner: false,
              isModerator: false,
            ),
          ];
          notifyListeners();
        }

      case 'owner_left':
        // Owner closed the room — kick all followers home
        _room = _room?.copyWith(status: RoomStatus.closed);
        _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
        notifyListeners();

      case 'leave':
        if (userId != null) {
          _removeMember(userId);
          // If the owner left and no new owner assigned, close room
          if (_room != null && !_members.any((m) => m.isOwner)) {
            _room = _room?.copyWith(status: RoomStatus.closed);
            _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
            notifyListeners();
          }
        }

      case 'pack_selected':
        final packId = p['pack_id'] as String?;
        if (packId != null && _room != null) {
          _room = _room!.copyWith(packId: packId);
          notifyListeners();
        }

      case 'language_changed':
        final lang = p['language'] as String?;
        if (lang != null && _room != null) {
          _room = _room!.copyWith(language: lang);
          notifyListeners();
        }

      case 'ready':
        if (userId != null) {
          _updateMember(userId, (m) => m.copyWith(isReady: true));
          notifyListeners();
          // Refresh DB to confirm — covers any presence lag
          if (_room != null) _refreshMembers(_room!.id);
        }

      case 'not_ready':
        if (userId != null) {
          _updateMember(userId, (m) => m.copyWith(isReady: false));
          notifyListeners();
          if (_room != null) _refreshMembers(_room!.id);
        }

      case 'ownership_transfer':
        final newOwnerId = p['new_owner_id'] as String?;
        if (newOwnerId != null && _room != null) {
          _room = _room!.copyWith(ownerId: newOwnerId);
          _members = _members
              .map((m) => m.copyWith(isOwner: m.userId == newOwnerId))
              .toList();
          notifyListeners();
          if (_currentUserId == newOwnerId) {
            _lifecycleCtrl.add(RoomLifecycleEvent.ownershipTransferred);
          }
        }
    }
  }

  void _handleGameStarted(Map<String, dynamic> p) {
    _readyPollTimer?.cancel();
    if (_room != null) {
      final gameTypeName = p['game_type'] as String?;
      final gameType = gameTypeName != null
          ? GameType.values.firstWhere(
              (g) => g.toDbString() == gameTypeName || g.name == gameTypeName,
              orElse: () => GameType.truthOrDare,
            )
          : null;
      _room = _room!.copyWith(
        status: RoomStatus.inGame,
        gameType: gameType ?? _room!.gameType,
      );
      notifyListeners();
    }
  }

  void _handleGameEnded(Map<String, dynamic> p) {
    if (_room != null) {
      _room = _room!.copyWith(status: RoomStatus.waiting);
      // Reset ready state for all members
      _members = _members.map((m) => m.copyWith(isReady: false)).toList();
      notifyListeners();
    }
  }

  // ── Chat ──────────────────────────────────────────────────────────────────
  void _handleChatBroadcast(Map<String, dynamic> p) {
    final msgId = p['id'] as String?;
    if (msgId == null) return;

    // Deduplicate: skip if already in list (optimistic or from DB)
    if (_chatMessages.any((m) => m.id == msgId)) return;

    final msg = ChatMessageEntity(
      id: msgId,
      roomId: _room?.id ?? '',
      userId: p['user_id'] as String? ?? '',
      displayName: p['display_name'] as String? ?? 'Player',
      avatarUrl: p['avatar_url'] as String?,
      content: p['content'] as String? ?? '',
      createdAt: p['ts'] != null
          ? DateTime.fromMillisecondsSinceEpoch(p['ts'] as int)
          : DateTime.now(),
    );

    _chatMessages = [..._chatMessages, msg];
    _cache.appendChatMessage(msg).ignore();
    notifyListeners();
  }

  Future<void> sendChatMessage(String content) async {
    if (_room == null || content.trim().isEmpty) return;
    if (isCurrentUserMuted) return;
    if (!_settings.chatEnabled) return;

    final trimmed = content.trim();
    final msgId = _uuid.v4();

    _isSendingChat = true;

    // Optimistic: add immediately
    final optimistic = ChatMessageEntity(
      id: msgId,
      roomId: _room!.id,
      userId: _currentUserId,
      displayName: _currentDisplayName,
      avatarUrl: _currentAvatarUrl,
      content: trimmed,
      createdAt: DateTime.now(),
      isOptimistic: true,
    );
    _chatMessages = [..._chatMessages, optimistic];
    notifyListeners();

    try {
      // Write to DB (for history persistence)
      await _repo.persistChatMessage(
        roomId: _room!.id,
        userId: _currentUserId,
        content: trimmed,
      );

      // Broadcast for instant delivery (~50ms faster than CDC)
      await _realtime.broadcastChat(_room!.id, {
        'id': msgId,
        'user_id': _currentUserId,
        'display_name': _currentDisplayName,
        'avatar_url': _currentAvatarUrl,
        'content': trimmed,
      });

      // Replace optimistic with confirmed
      _chatMessages = _chatMessages
          .map((m) => m.id == msgId ? m.copyWithConfirmed() : m)
          .toList();
    } catch (e) {
      AppLogger.error('RoomProvider: sendChat failed', error: e);
      // Remove optimistic message on failure
      _chatMessages = _chatMessages.where((m) => m.id != msgId).toList();
    } finally {
      _isSendingChat = false;
      notifyListeners();
    }
  }

  // ── Moderation handler ────────────────────────────────────────────────────
  void _handleModeration(Map<String, dynamic> p) {
    final type = p['type'] as String?;
    final targetId = p['target_user_id'] as String?;

    switch (type) {
      case 'mute':
        if (targetId != null) {
          _mutedUserIds.add(targetId);
          _updateMember(targetId, (m) => m.copyWith(isMuted: true));
          notifyListeners();
        }

      case 'unmute':
        if (targetId != null) {
          _mutedUserIds.remove(targetId);
          _updateMember(targetId, (m) => m.copyWith(isMuted: false));
          notifyListeners();
        }

      case 'kick':
        if (targetId != null) {
          _removeMember(targetId);
          if (targetId == _currentUserId) {
            _lifecycleCtrl.add(RoomLifecycleEvent.kicked);
          }
        }

      case 'ban':
        if (targetId != null) {
          _removeMember(targetId);
          if (targetId == _currentUserId) {
            _lifecycleCtrl.add(RoomLifecycleEvent.banned);
          }
        }

      case 'pause':
        _room = _room?.copyWith(status: RoomStatus.paused);
        notifyListeners();

      case 'resume':
        _room = _room?.copyWith(status: RoomStatus.inGame);
        notifyListeners();

      case 'room_close':
        _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
    }
  }

  // ── Settings handler ──────────────────────────────────────────────────────
  void _handleSettingsChange(Map<String, dynamic> p) {
    final field = p['field'] as String?;
    final value = p['new_value'];

    _settings = switch (field) {
      'turn_timer_secs' => _settings.copyWith(
        turnTimerSeconds: (value as num).toInt(),
      ),
      'allow_skip' => _settings.copyWith(allowSkip: value as bool),
      'max_rounds' => _settings.copyWith(maxRounds: (value as num).toInt()),
      'chat_enabled' => _settings.copyWith(chatEnabled: value as bool),
      'allow_spectators' => _settings.copyWith(allowSpectators: value as bool),
      'allow_spicy' => _settings.copyWith(allowSpicy: value as bool),
      'requires_approval' => _settings.copyWith(
        requiresApproval: value as bool,
      ),
      _ => _settings,
    };
    notifyListeners();
  }

  // ── Owner / moderator actions ─────────────────────────────────────────────

  Future<void> kickPlayer(String targetUserId, {String? reason}) async {
    if (!canModerate(targetUserId) || _room == null) return;
    await _repo.kickMember(_room!.id, targetUserId);
    await _realtime.broadcastModeration(_room!.id, {
      'type': 'kick',
      'target_user_id': targetUserId,
      'reason': reason,
    });
    _removeMember(targetUserId);
  }

  Future<void> mutePlayer(
    String targetUserId, {
    bool muted = true,
    int durationSeconds = 300,
  }) async {
    if (!canModerate(targetUserId) || _room == null) return;
    await _repo.muteMember(_room!.id, targetUserId, muted: muted);
    await _realtime.broadcastModeration(_room!.id, {
      'type': muted ? 'mute' : 'unmute',
      'target_user_id': targetUserId,
      'duration_seconds': durationSeconds,
    });
    if (muted) {
      _mutedUserIds.add(targetUserId);
    } else {
      _mutedUserIds.remove(targetUserId);
    }
    _updateMember(targetUserId, (m) => m.copyWith(isMuted: muted));
    notifyListeners();
  }

  Future<void> banPlayer(
    String targetUserId, {
    String? reason,
    Duration? duration,
  }) async {
    if (!isOwner || _room == null) return;
    await _repo.banMember(
      roomId: _room!.id,
      targetUserId: targetUserId,
      bannedBy: _currentUserId,
      reason: reason,
      duration: duration,
    );
    await _realtime.broadcastModeration(_room!.id, {
      'type': 'ban',
      'target_user_id': targetUserId,
      'reason': reason,
    });
    _removeMember(targetUserId);
  }

  Future<void> unbanPlayer(String targetUserId) async {
    if (!isOwner || _room == null) return;
    await _repo.liftBan(_room!.id, targetUserId);
  }

  Future<void> transferOwnership(String newOwnerId) async {
    if (!isOwner || _room == null) return;
    await _repo.transferOwnership(_room!.id, newOwnerId);
    await _realtime.broadcastRoomEvent(_room!.id, {
      'type': 'ownership_transfer',
      'user_id': _currentUserId,
      'new_owner_id': newOwnerId,
    });
    _room = _room!.copyWith(ownerId: newOwnerId);
    _members = _members
        .map((m) => m.copyWith(isOwner: m.userId == newOwnerId))
        .toList();
    notifyListeners();
  }

  Future<void> grantModerator(String userId) async {
    if (!isOwner || _room == null) return;
    await _repo.grantModerator(_room!.id, userId, _currentUserId);
    _updateMember(userId, (m) => m.copyWith(isModerator: true));
    notifyListeners();
  }

  Future<void> revokeModerator(String userId) async {
    if (!isOwner || _room == null) return;
    await _repo.revokeModerator(_room!.id, userId);
    _updateMember(userId, (m) => m.copyWith(isModerator: false));
    notifyListeners();
  }

  Future<void> pauseGame() async {
    if (!canModerate(_currentUserId) || _room == null) return;
    await _repo.updateStatus(_room!.id, RoomStatus.paused);
    _room = _room!.copyWith(
      status: RoomStatus.paused,
    ); // update in memory FIRST
    notifyListeners();
    await _realtime.broadcastModeration(_room!.id, {'type': 'pause'});
  }

  Future<void> resumeGame() async {
    if (!canModerate(_currentUserId) || _room == null) return;
    await _realtime.broadcastModeration(_room!.id, {'type': 'resume'});
    await _repo.updateStatus(_room!.id, RoomStatus.inGame);
  }

  Future<void> updateSetting(String field, dynamic value) async {
    if (!isOwner || _room == null) return;
    // Optimistic update
    _handleSettingsChange({'field': field, 'new_value': value});
    // Broadcast to all members
    await _realtime.broadcastSettingsChange(_room!.id, field, value);
    // Persist to DB
    await _repo.updateSettings(_room!.id, _settings);
  }

  Future<void> setPackId(String packId) async {
    if (!isOwner || _room == null) return;
    _room = _room!.copyWith(packId: packId);
    notifyListeners();
    await _supabase
        .from('rooms')
        .update({'pack_id': packId})
        .eq('id', _room!.id);
    await _realtime.broadcastRoomEvent(_room!.id, {
      'type': 'pack_selected',
      'pack_id': packId,
    });
  }

  Future<void> setLanguage(String language) async {
    if (!isOwner || _room == null) return;
    _room = _room!.copyWith(language: language);
    notifyListeners();
    // Persist language to rooms table
    await _supabase
        .from('rooms')
        .update({'language': language})
        .eq('id', _room!.id);
    // Broadcast so followers update their UI
    await _realtime.broadcastRoomEvent(_room!.id, {
      'type': 'language_changed',
      'language': language,
    });
  }

  Future<void> setReady(bool ready) async {
    if (_room == null) return;
    // Update local state immediately for snappy UI
    _updateMember(_currentUserId, (m) => m.copyWith(isReady: ready));
    notifyListeners();
    // Persist to DB — CDC on other clients will pick this up
    await _supabase
        .from('room_members')
        .update({'is_ready': ready})
        .eq('room_id', _room!.id)
        .eq('user_id', _currentUserId);
    // Update presence so presenceSync on other clients reflects isReady
    await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
    // Explicit broadcast so _handleRoomEvent fires immediately on other clients
    await _realtime.broadcastRoomEvent(_room!.id, {
      'type': ready ? 'ready' : 'not_ready',
      'user_id': _currentUserId,
    });
    // Refresh from DB to confirm state is consistent
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_room != null) _refreshMembers(_room!.id);
    });
  }

  // ── Leave ─────────────────────────────────────────────────────────────────
  Future<void> leaveRoom({bool permanent = false}) async {
    if (_room == null) return;
    final roomId = _room!.id;
    final amOwner = isOwner;

    // Re-read status from DB to avoid stale in-memory state
    // (e.g. game screen set DB to paused but didn't update _room)
    bool isPaused = _room!.status == RoomStatus.paused;
    if (!isPaused && amOwner) {
      try {
        final row = await _supabase
            .from('rooms')
            .select('status')
            .eq('id', roomId)
            .maybeSingle();
        isPaused = (row?['status'] as String?) == 'paused';
        if (isPaused) _room = _room!.copyWith(status: RoomStatus.paused);
      } catch (_) {}
    }

    // If owner leaves and the room is NOT paused, close and delete it.
    // If paused, keep the room alive so players can wait for the owner.
    if (amOwner && (permanent || !isPaused)) {
      await _realtime.broadcastRoomEvent(roomId, {
        'type': 'owner_left',
        'user_id': _currentUserId,
      });
      try {
        await _supabase
            .from('rooms')
            .update({
              'status': 'closed',
              'deleted_at': DateTime.now().toIso8601String(),
            })
            .eq('id', roomId);
      } catch (_) {}
    }

    await _realtime.broadcastRoomEvent(roomId, {
      'type': 'leave',
      'user_id': _currentUserId,
      'display_name': _currentDisplayName,
    });

    await _realtime.untrackPresence(roomId);
    await _repo.leaveRoom(userId: _currentUserId, roomId: roomId);
    await _realtime.unsubscribe(roomId);
    await _presence.setOnline();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _setConnection(RoomConnectionState state) {
    if (_connectionState == state) return;
    _connectionState = state;
    notifyListeners();
  }

  void _updateMember(
    String? userId,
    RoomMemberEntity Function(RoomMemberEntity) fn,
  ) {
    if (userId == null) return;
    _members = _members.map((m) => m.userId == userId ? fn(m) : m).toList();
  }

  void _removeMember(String userId) {
    _cancelGracePeriod(userId);
    _members = _members.where((m) => m.userId != userId).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _readyPollTimer?.cancel();
    for (final t in _disconnectedTimers.values) t.cancel();
    _lifecycleCtrl.close();
    _memberCdcChannel?.unsubscribe();
    if (_room != null) _realtime.unsubscribe(_room!.id).ignore();
    super.dispose();
  }
}

// ── Extension: confirm optimistic message ─────────────────────────────────────
extension _ChatEntityX on ChatMessageEntity {
  ChatMessageEntity copyWithConfirmed() => ChatMessageEntity(
    id: id,
    roomId: roomId,
    userId: userId,
    displayName: displayName,
    avatarUrl: avatarUrl,
    content: content,
    createdAt: createdAt,
    isOptimistic: false,
    type: type,
  );
}
