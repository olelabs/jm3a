// // import 'dart:async';
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/scheduler.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import '../../../core/errors/failures.dart';
// // import '../../../core/services/realtime_service.dart';
// // import '../../../core/services/presence_service.dart';
// // import '../../../core/services/subscription_service.dart';
// // import '../../../core/utils/app_logger.dart';
// // import '../data/room_repository.dart';
// // import '../data/room_cache_service.dart';
// // import '../domain/room_entity.dart';
// // import '../../games/engine/base_game_engine.dart';
// // import 'package:uuid/uuid.dart';

// // const _uuid = Uuid();

// // enum RoomConnectionState {
// //   connecting,
// //   connected,
// //   reconnecting,
// //   recovering,
// //   pendingApproval,
// //   failed;

// //   bool get isStable => this == connected;
// //   bool get isBusy =>
// //       this == connecting || this == reconnecting || this == recovering;
// // }

// // enum RoomLifecycleEvent { kicked, banned, roomClosed, ownershipTransferred }

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

// //   RoomEntity? _room;
// //   List<RoomMemberEntity> _members = [];
// //   RoomSettingsEntity _settings = const RoomSettingsEntity();
// //   List<ChatMessageEntity> _chatMessages = [];
// //   RoomConnectionState _connectionState = RoomConnectionState.connecting;
// //   Failure? _failure;
// //   bool _isSendingChat = false;
// //   bool _isInitialized = false;
// //   bool _disposed = false;

// //   final _mutedUserIds = <String>{};

// //   final _disconnectedTimers = <String, Timer>{};

// //   int _reconnectAttempts = 0;
// //   Timer? _reconnectTimer;
// //   Timer? _readyPollTimer;
// //   static const _maxAttempts = 3;
// //   static const _delays = [1, 3, 7];

// //   final _lifecycleCtrl = StreamController<RoomLifecycleEvent>.broadcast();
// //   Stream<RoomLifecycleEvent> get lifecycleEvents => _lifecycleCtrl.stream;

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

// //   bool get canApproveSpectators {
// //     final me = currentMember;
// //     if (me == null) return false;
// //     return isOwner || me.isModerator;
// //   }

// //   Future<List<Map<String, dynamic>>> fetchPendingSpectatorRequests() async {
// //     if (_room == null) return [];
// //     return _repo.getPendingSpectatorRequests(_room!.id);
// //   }

// //   Future<void> decideSpectatorRequest({
// //     required String requestId,
// //     required String requestingUserId,
// //     required bool approve,
// //   }) async {
// //     if (_room == null) return;
// //     await _repo.decideSpectatorRequest(
// //       requestId: requestId,
// //       roomId: _room!.id,
// //       requestingUserId: requestingUserId,
// //       decidedBy: _currentUserId,
// //       approve: approve,
// //     );
// //     await _realtime.broadcastRoomEvent(_room!.id, {
// //       'type': approve ? 'spectator_approved' : 'spectator_denied',
// //       'user_id': requestingUserId,
// //     });
// //     _safeNotify();
// //   }

// //   Future<void> initialize(String roomId, {String role = 'player'}) async {
// //     _setConnection(RoomConnectionState.connecting);

// //     try {
// //       final cached = await _cache.getCachedChatMessages(roomId);
// //       if (cached.isNotEmpty) {
// //         _chatMessages = cached;
// //         _safeNotify();
// //       }

// //       final approvalInfo = await _repo.getRoomApprovalInfo(roomId);
// //       if (approvalInfo != null &&
// //           approvalInfo.requiresApproval &&
// //           approvalInfo.ownerId != _currentUserId) {
// //         final alreadyMember = await _repo.isActiveMember(
// //           userId: _currentUserId,
// //           roomId: roomId,
// //         );
// //         if (!alreadyMember) {
// //           final invited = await _repo.hasValidInvite(
// //             userId: _currentUserId,
// //             roomId: roomId,
// //           );
// //           if (invited) {
// //             await _repo.markInviteAccepted(
// //               userId: _currentUserId,
// //               roomId: roomId,
// //             );
// //             AppLogger.info('RoomProvider: approval bypassed via valid invite');
// //           } else {
// //             await _repo.requestToJoin(userId: _currentUserId, roomId: roomId);
// //             AppLogger.info(
// //               'RoomProvider: requires_approval — join request filed instead',
// //             );
// //             _setConnection(RoomConnectionState.pendingApproval);
// //             return;
// //           }
// //         }
// //       }

// //       if (role == 'spectator' || role == 'player') {
// //         final settingsRow = await _supabase
// //             .from('room_settings')
// //             .select('spectator_approval_required')
// //             .eq('room_id', roomId)
// //             .maybeSingle();
// //         final needsSpectatorApproval =
// //             settingsRow?['spectator_approval_required'] as bool? ?? false;
// //         if (needsSpectatorApproval && approvalInfo != null) {
// //           final roomRow = await _supabase
// //               .from('rooms')
// //               .select('status')
// //               .eq('id', roomId)
// //               .maybeSingle();
// //           final isInProgress = roomRow?['status'] == 'in_game';
// //           if (isInProgress) {
// //             final alreadyMember = await _repo.isActiveMember(
// //               userId: _currentUserId,
// //               roomId: roomId,
// //             );
// //             if (!alreadyMember) {
// //               await _repo.requestSpectatorAccess(
// //                 roomId: roomId,
// //                 userId: _currentUserId,
// //               );
// //               await _realtime.broadcastRoomEvent(roomId, {
// //                 'type': 'spectator_request',
// //                 'user_id': _currentUserId,
// //               });
// //               AppLogger.info(
// //                 'RoomProvider: game in progress + spectator gate — queued spectator request',
// //               );
// //               _setConnection(RoomConnectionState.pendingApproval);
// //               return;
// //             }
// //           }
// //         }
// //       }

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
// //       _safeNotify();

// //       final history = await _repo.getChatHistory(roomId);
// //       _chatMessages = history;
// //       await _cache.cacheChatMessages(roomId, history);
// //       _safeNotify();

// //       await _subscribeChannel(roomId);

// //       await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
// //       await _realtime.broadcastRoomEvent(roomId, {
// //         'type': 'join',
// //         'user_id': _currentUserId,
// //         'display_name': _currentDisplayName,
// //         'avatar_url': _currentAvatarUrl,
// //       });

// //       await _presence.setInGame(roomId);

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

// //   Future<void> _subscribeChannel(String roomId) async {
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
// //       onGameState: (_) {},
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

// //   void _handleChannelStatus(RealtimeSubscribeStatus status) {
// //     switch (status) {
// //       case RealtimeSubscribeStatus.subscribed:
// //         _reconnectAttempts = 0;
// //         _reconnectTimer?.cancel();
// //         if (_connectionState == RoomConnectionState.reconnecting ||
// //             _connectionState == RoomConnectionState.recovering) {
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
// //     Timer(const Duration(seconds: 5), () {
// //       if (_connectionState == RoomConnectionState.recovering) {
// //         _setConnection(RoomConnectionState.connected);
// //       }
// //     });
// //   }

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

// //   Future<void> _refreshMembers(String roomId) async {
// //     try {
// //       final (_, freshMembers, _, _) = await _repo.getRoomWithDetails(roomId);
// //       if (freshMembers.isEmpty) return;
// //       _members = freshMembers;
// //       _safeNotify();
// //       AppLogger.debug('RoomProvider: refreshed members=${_members.length}');
// //     } catch (e) {
// //       AppLogger.warning('RoomProvider: _refreshMembers failed: $e');
// //     }
// //   }

// //   void _handlePresenceSync(List<Map<String, dynamic>> presences) {
// //     bool changed = false;

// //     final onlineIds = presences
// //         .map((p) => p[PresenceKey.userId] as String?)
// //         .whereType<String>()
// //         .toSet();

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

// //     if (changed) _safeNotify();
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
// //     _safeNotify();
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
// //     _safeNotify();
// //   }

// //   void _cancelGracePeriod(String userId) {
// //     _disconnectedTimers[userId]?.cancel();
// //     _disconnectedTimers.remove(userId);
// //   }

// //   void _handleRoomEvent(Map<String, dynamic> p) {
// //     final type = p['type'] as String?;
// //     final userId = p['user_id'] as String?;

// //     switch (type) {
// //       case 'game_started':
// //         if (_room != null && !isOwner) {
// //           final gameTypeStr = p['game_type'] as String?;
// //           if (gameTypeStr != null) {
// //             final gt = GameType.values.firstWhere(
// //               (g) => g.toDbString() == gameTypeStr,
// //               orElse: () => GameType.truthOrDare,
// //             );
// //             _room = _room!.copyWith(status: RoomStatus.inGame, gameType: gt);
// //             _safeNotify();
// //           }
// //         }

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
// //           _safeNotify();
// //         }

// //       case 'owner_left':
// //         _room = _room?.copyWith(status: RoomStatus.closed);
// //         _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
// //         _safeNotify();

// //       case 'leave':
// //         if (userId != null) {
// //           _removeMember(userId);
// //           if (_room != null && !_members.any((m) => m.isOwner)) {
// //             _room = _room?.copyWith(status: RoomStatus.closed);
// //             _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
// //             _safeNotify();
// //           }
// //         }

// //       case 'pack_selected':
// //         final packId = p['pack_id'] as String?;
// //         if (packId != null && _room != null) {
// //           _room = _room!.copyWith(packId: packId);
// //           _safeNotify();
// //         }

// //       case 'language_changed':
// //         final lang = p['language'] as String?;
// //         if (lang != null && _room != null) {
// //           _room = _room!.copyWith(language: lang);
// //           _safeNotify();
// //         }

// //       case 'ready':
// //         if (userId != null) {
// //           _updateMember(userId, (m) => m.copyWith(isReady: true));
// //           _safeNotify();
// //           if (_room != null) _refreshMembers(_room!.id);
// //         }

// //       case 'not_ready':
// //         if (userId != null) {
// //           _updateMember(userId, (m) => m.copyWith(isReady: false));
// //           _safeNotify();
// //           if (_room != null) _refreshMembers(_room!.id);
// //         }

// //       case 'ownership_transfer':
// //         final newOwnerId = p['new_owner_id'] as String?;
// //         if (newOwnerId != null && _room != null) {
// //           _room = _room!.copyWith(ownerId: newOwnerId);
// //           _members = _members
// //               .map((m) => m.copyWith(isOwner: m.userId == newOwnerId))
// //               .toList();
// //           _safeNotify();
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
// //       _safeNotify();
// //     }
// //   }

// //   void _handleGameEnded(Map<String, dynamic> p) {
// //     if (_room != null) {
// //       _room = _room!.copyWith(status: RoomStatus.waiting);
// //       _members = _members.map((m) => m.copyWith(isReady: false)).toList();
// //       _safeNotify();
// //     }
// //   }

// //   void _handleChatBroadcast(Map<String, dynamic> p) {
// //     final msgId = p['id'] as String?;
// //     if (msgId == null) return;

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
// //       replyToId: p['reply_to_id'] as String?,
// //       replyToContent: p['reply_to_content'] as String?,
// //       replyToDisplayName: p['reply_to_display_name'] as String?,
// //     );

// //     _chatMessages = [..._chatMessages, msg];
// //     _cache.appendChatMessage(msg).ignore();
// //     _safeNotify();
// //   }

// //   Future<void> sendChatMessage(
// //     String content, {
// //     ChatMessageEntity? replyTo,
// //     bool anonymous = false,
// //   }) async {
// //     if (_room == null || content.trim().isEmpty) return;
// //     if (isCurrentUserMuted) return;
// //     if (!_settings.chatEnabled) return;

// //     final isPremium = anonymous
// //         ? await SubscriptionService.instance.isPremiumActive(_currentUserId)
// //         : false;
// //     final sendAnon = anonymous && isPremium;

// //     final trimmed = content.trim();
// //     final msgId = _uuid.v4();
// //     final replySnippet = replyTo != null
// //         ? (replyTo.content.length > 120
// //               ? '${replyTo.content.substring(0, 120)}…'
// //               : replyTo.content)
// //         : null;

// //     _isSendingChat = true;

// //     final optimistic = ChatMessageEntity(
// //       id: msgId,
// //       roomId: _room!.id,
// //       userId: sendAnon ? 'anonymous' : _currentUserId,
// //       displayName: sendAnon ? 'Anonymous' : _currentDisplayName,
// //       avatarUrl: sendAnon ? null : _currentAvatarUrl,
// //       content: trimmed,
// //       createdAt: DateTime.now(),
// //       isOptimistic: true,
// //       isAnonymous: sendAnon,
// //       replyToId: replyTo?.id,
// //       replyToContent: replySnippet,
// //       replyToDisplayName: replyTo?.displayName,
// //     );
// //     _chatMessages = [..._chatMessages, optimistic];
// //     _safeNotify();

// //     try {
// //       await _repo.persistChatMessage(
// //         roomId: _room!.id,
// //         userId: _currentUserId,
// //         content: trimmed,
// //         replyToId: replyTo?.id,
// //         replyToContent: replySnippet,
// //         replyToDisplayName: replyTo?.displayName,
// //         isAnonymous: sendAnon,
// //       );

// //       await _realtime.broadcastChat(_room!.id, {
// //         'id': msgId,
// //         'user_id': sendAnon ? 'anonymous' : _currentUserId,
// //         'display_name': sendAnon ? 'Anonymous' : _currentDisplayName,
// //         'avatar_url': sendAnon ? null : _currentAvatarUrl,
// //         'content': trimmed,
// //         'is_anonymous': sendAnon,
// //         if (replyTo != null) 'reply_to_id': replyTo.id,
// //         if (replySnippet != null) 'reply_to_content': replySnippet,
// //         if (replyTo != null) 'reply_to_display_name': replyTo.displayName,
// //       });

// //       _chatMessages = _chatMessages
// //           .map((m) => m.id == msgId ? m.copyWithConfirmed() : m)
// //           .toList();
// //     } catch (e) {
// //       AppLogger.error('RoomProvider: sendChat failed', error: e);
// //       _chatMessages = _chatMessages.where((m) => m.id != msgId).toList();
// //     } finally {
// //       _isSendingChat = false;
// //       _safeNotify();
// //     }
// //   }

// //   void _handleModeration(Map<String, dynamic> p) {
// //     final type = p['type'] as String?;
// //     final targetId = p['target_user_id'] as String?;

// //     switch (type) {
// //       case 'mute':
// //         if (targetId != null) {
// //           _mutedUserIds.add(targetId);
// //           _updateMember(targetId, (m) => m.copyWith(isMuted: true));
// //           _safeNotify();
// //         }

// //       case 'unmute':
// //         if (targetId != null) {
// //           _mutedUserIds.remove(targetId);
// //           _updateMember(targetId, (m) => m.copyWith(isMuted: false));
// //           _safeNotify();
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
// //         _safeNotify();

// //       case 'resume':
// //         _room = _room?.copyWith(status: RoomStatus.inGame);
// //         _safeNotify();

// //       case 'room_close':
// //         _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
// //     }
// //   }

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
// //       'spectator_approval_required' => _settings.copyWith(
// //         spectatorApprovalRequired: value as bool,
// //       ),
// //       'allow_spicy' => _settings.copyWith(allowSpicy: value as bool),
// //       'requires_approval' => _settings.copyWith(
// //         requiresApproval: value as bool,
// //       ),
// //       _ => _settings,
// //     };
// //     _safeNotify();
// //   }

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
// //     _safeNotify();
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
// //     _safeNotify();
// //   }

// //   Future<void> grantModerator(String userId) async {
// //     if (!isOwner || _room == null) return;
// //     await _repo.grantModerator(_room!.id, userId, _currentUserId);
// //     _updateMember(userId, (m) => m.copyWith(isModerator: true));
// //     _safeNotify();
// //   }

// //   Future<void> revokeModerator(String userId) async {
// //     if (!isOwner || _room == null) return;
// //     await _repo.revokeModerator(_room!.id, userId);
// //     _updateMember(userId, (m) => m.copyWith(isModerator: false));
// //     _safeNotify();
// //   }

// //   Future<void> updateSetting(String field, dynamic value) async {
// //     if (!isOwner || _room == null) return;
// //     _handleSettingsChange({'field': field, 'new_value': value});
// //     await _realtime.broadcastSettingsChange(_room!.id, field, value);
// //     await _repo.updateSettings(_room!.id, _settings);
// //   }

// //   Future<void> setPackId(String packId) async {
// //     if (!isOwner || _room == null) return;
// //     _room = _room!.copyWith(packId: packId);
// //     _safeNotify();
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
// //     _safeNotify();
// //     await _supabase
// //         .from('rooms')
// //         .update({'language': language})
// //         .eq('id', _room!.id);
// //     await _realtime.broadcastRoomEvent(_room!.id, {
// //       'type': 'language_changed',
// //       'language': language,
// //     });
// //   }

// //   Future<void> setReady(bool ready) async {
// //     if (_room == null) return;
// //     _updateMember(_currentUserId, (m) => m.copyWith(isReady: ready));
// //     _safeNotify();
// //     await _supabase
// //         .from('room_members')
// //         .update({'is_ready': ready})
// //         .eq('room_id', _room!.id)
// //         .eq('user_id', _currentUserId);
// //     await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
// //     await _realtime.broadcastRoomEvent(_room!.id, {
// //       'type': ready ? 'ready' : 'not_ready',
// //       'user_id': _currentUserId,
// //     });
// //     Future.delayed(const Duration(milliseconds: 400), () {
// //       if (_room != null) _refreshMembers(_room!.id);
// //     });
// //   }

// //   Future<void> leaveRoom({bool permanent = false}) async {
// //     if (_room == null) return;
// //     final roomId = _room!.id;
// //     final amOwner = isOwner;

// //     bool isPaused = _room!.status == RoomStatus.paused;
// //     if (!isPaused && amOwner) {
// //       try {
// //         final row = await _supabase
// //             .from('rooms')
// //             .select('status')
// //             .eq('id', roomId)
// //             .maybeSingle();
// //         isPaused = (row?['status'] as String?) == 'paused';
// //         if (isPaused) _room = _room!.copyWith(status: RoomStatus.paused);
// //       } catch (_) {}
// //     }

// //     if (amOwner && (permanent || !isPaused)) {
// //       await _realtime.broadcastRoomEvent(roomId, {
// //         'type': 'owner_left',
// //         'user_id': _currentUserId,
// //       });
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

// //   void _setConnection(RoomConnectionState state) {
// //     if (_connectionState == state) return;
// //     _connectionState = state;
// //     _safeNotify();
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
// //     _safeNotify();
// //   }

// //   /// Schedules notifyListeners on the next frame when called mid-build,
// //   /// preventing "dirty widget in the wrong build scope" from async callbacks
// //   /// (e.g. _refreshMembers) completing while the navigator is updating routes.
// //   void _safeNotify() {
// //     if (_disposed) return;
// //     final phase = SchedulerBinding.instance.schedulerPhase;
// //     if (phase == SchedulerPhase.persistentCallbacks ||
// //         phase == SchedulerPhase.transientCallbacks ||
// //         phase == SchedulerPhase.midFrameMicrotasks) {
// //       SchedulerBinding.instance.addPostFrameCallback((_) {
// //         if (!_disposed) notifyListeners();
// //       });
// //     } else {
// //       notifyListeners();
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     _disposed = true;
// //     _reconnectTimer?.cancel();
// //     _readyPollTimer?.cancel();
// //     for (final t in _disconnectedTimers.values) t.cancel();
// //     _lifecycleCtrl.close();
// //     _memberCdcChannel?.unsubscribe();
// //     if (_room != null) _realtime.unsubscribe(_room!.id).ignore();
// //     super.dispose();
// //   }
// // }

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
// //     replyToId: replyToId,
// //     replyToContent: replyToContent,
// //     replyToDisplayName: replyToDisplayName,
// //   );
// // }

// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../../core/errors/failures.dart';
// import '../../../core/services/realtime_service.dart';
// import '../../../core/services/presence_service.dart';
// import '../../../core/services/subscription_service.dart';
// import '../../../core/utils/app_logger.dart';
// import '../data/room_repository.dart';
// import '../data/room_cache_service.dart';
// import '../domain/room_entity.dart';
// import '../../games/engine/base_game_engine.dart';
// import 'package:uuid/uuid.dart';

// const _uuid = Uuid();

// enum RoomConnectionState {
//   connecting,
//   connected,
//   reconnecting,
//   recovering,
//   pendingApproval,
//   failed;

//   bool get isStable => this == connected;
//   bool get isBusy =>
//       this == connecting || this == reconnecting || this == recovering;
// }

// enum RoomLifecycleEvent { kicked, banned, roomClosed, ownershipTransferred }

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

//   RoomEntity? _room;
//   List<RoomMemberEntity> _members = [];
//   RoomSettingsEntity _settings = const RoomSettingsEntity();
//   List<ChatMessageEntity> _chatMessages = [];
//   RoomConnectionState _connectionState = RoomConnectionState.connecting;
//   Failure? _failure;
//   bool _isSendingChat = false;
//   bool _isInitialized = false;
//   bool _disposed = false;

//   final _mutedUserIds = <String>{};

//   final _disconnectedTimers = <String, Timer>{};

//   int _reconnectAttempts = 0;
//   Timer? _reconnectTimer;
//   Timer? _readyPollTimer;
//   static const _maxAttempts = 3;
//   static const _delays = [1, 3, 7];

//   final _lifecycleCtrl = StreamController<RoomLifecycleEvent>.broadcast();
//   Stream<RoomLifecycleEvent> get lifecycleEvents => _lifecycleCtrl.stream;

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

//   bool get canApproveSpectators {
//     final me = currentMember;
//     if (me == null) return false;
//     return isOwner || me.isModerator;
//   }

//   Future<List<Map<String, dynamic>>> fetchPendingSpectatorRequests() async {
//     if (_room == null) return [];
//     return _repo.getPendingSpectatorRequests(_room!.id);
//   }

//   Future<void> decideSpectatorRequest({
//     required String requestId,
//     required String requestingUserId,
//     required bool approve,
//   }) async {
//     if (_room == null) return;
//     await _repo.decideSpectatorRequest(
//       requestId: requestId,
//       roomId: _room!.id,
//       requestingUserId: requestingUserId,
//       decidedBy: _currentUserId,
//       approve: approve,
//     );
//     await _realtime.broadcastRoomEvent(_room!.id, {
//       'type': approve ? 'spectator_approved' : 'spectator_denied',
//       'user_id': requestingUserId,
//     });
//     _safeNotify();
//   }

//   Future<void> initialize(String roomId, {String role = 'player'}) async {
//     _setConnection(RoomConnectionState.connecting);

//     try {
//       final cached = await _cache.getCachedChatMessages(roomId);
//       if (cached.isNotEmpty) {
//         _chatMessages = cached;
//         _safeNotify();
//       }

//       final approvalInfo = await _repo.getRoomApprovalInfo(roomId);
//       if (approvalInfo != null &&
//           approvalInfo.requiresApproval &&
//           approvalInfo.ownerId != _currentUserId) {
//         final alreadyMember = await _repo.isActiveMember(
//           userId: _currentUserId,
//           roomId: roomId,
//         );
//         if (!alreadyMember) {
//           final invited = await _repo.hasValidInvite(
//             userId: _currentUserId,
//             roomId: roomId,
//           );
//           if (invited) {
//             await _repo.markInviteAccepted(
//               userId: _currentUserId,
//               roomId: roomId,
//             );
//             AppLogger.info('RoomProvider: approval bypassed via valid invite');
//           } else {
//             await _repo.requestToJoin(userId: _currentUserId, roomId: roomId);
//             AppLogger.info(
//               'RoomProvider: requires_approval — join request filed instead',
//             );
//             _setConnection(RoomConnectionState.pendingApproval);
//             return;
//           }
//         }
//       }

//       if (role == 'spectator' || role == 'player') {
//         final settingsRow = await _supabase
//             .from('room_settings')
//             .select('spectator_approval_required')
//             .eq('room_id', roomId)
//             .maybeSingle();
//         final needsSpectatorApproval =
//             settingsRow?['spectator_approval_required'] as bool? ?? false;
//         if (needsSpectatorApproval && approvalInfo != null) {
//           final roomRow = await _supabase
//               .from('rooms')
//               .select('status')
//               .eq('id', roomId)
//               .maybeSingle();
//           final isInProgress = roomRow?['status'] == 'in_game';
//           if (isInProgress) {
//             final alreadyMember = await _repo.isActiveMember(
//               userId: _currentUserId,
//               roomId: roomId,
//             );
//             if (!alreadyMember) {
//               await _repo.requestSpectatorAccess(
//                 roomId: roomId,
//                 userId: _currentUserId,
//               );
//               await _realtime.broadcastRoomEvent(roomId, {
//                 'type': 'spectator_request',
//                 'user_id': _currentUserId,
//               });
//               AppLogger.info(
//                 'RoomProvider: game in progress + spectator gate — queued spectator request',
//               );
//               _setConnection(RoomConnectionState.pendingApproval);
//               return;
//             }
//           }
//         }
//       }

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
//       _safeNotify();

//       final history = await _repo.getChatHistory(roomId);
//       _chatMessages = history;
//       await _cache.cacheChatMessages(roomId, history);
//       _safeNotify();

//       await _subscribeChannel(roomId);

//       await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
//       await _realtime.broadcastRoomEvent(roomId, {
//         'type': 'join',
//         'user_id': _currentUserId,
//         'display_name': _currentDisplayName,
//         'avatar_url': _currentAvatarUrl,
//       });

//       await _presence.setInGame(roomId);

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

//   Future<void> _subscribeChannel(String roomId) async {
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
//       onGameState: (_) {},
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

//   void _handleChannelStatus(RealtimeSubscribeStatus status) {
//     switch (status) {
//       case RealtimeSubscribeStatus.subscribed:
//         _reconnectAttempts = 0;
//         _reconnectTimer?.cancel();
//         if (_connectionState == RoomConnectionState.reconnecting ||
//             _connectionState == RoomConnectionState.recovering) {
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
//     Timer(const Duration(seconds: 5), () {
//       if (_connectionState == RoomConnectionState.recovering) {
//         _setConnection(RoomConnectionState.connected);
//       }
//     });
//   }

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

//   Future<void> _refreshMembers(String roomId) async {
//     try {
//       final (_, freshMembers, _, _) = await _repo.getRoomWithDetails(roomId);
//       if (freshMembers.isEmpty) return;
//       _members = freshMembers;
//       _safeNotify();
//       AppLogger.debug('RoomProvider: refreshed members=${_members.length}');
//     } catch (e) {
//       AppLogger.warning('RoomProvider: _refreshMembers failed: $e');
//     }
//   }

//   void _handlePresenceSync(List<Map<String, dynamic>> presences) {
//     bool changed = false;

//     final onlineIds = presences
//         .map((p) => p[PresenceKey.userId] as String?)
//         .whereType<String>()
//         .toSet();

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

//     if (changed) _safeNotify();
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
//     _safeNotify();
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
//     _safeNotify();
//   }

//   void _cancelGracePeriod(String userId) {
//     _disconnectedTimers[userId]?.cancel();
//     _disconnectedTimers.remove(userId);
//   }

//   void _handleRoomEvent(Map<String, dynamic> p) {
//     final type = p['type'] as String?;
//     final userId = p['user_id'] as String?;

//     switch (type) {
//       case 'game_started':
//         if (_room != null && !isOwner) {
//           final gameTypeStr = p['game_type'] as String?;
//           if (gameTypeStr != null) {
//             final gt = GameType.values.firstWhere(
//               (g) => g.toDbString() == gameTypeStr,
//               orElse: () => GameType.truthOrDare,
//             );
//             _room = _room!.copyWith(status: RoomStatus.inGame, gameType: gt);
//             _safeNotify();
//           }
//         }

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
//           _safeNotify();
//         }

//       case 'owner_left':
//         _room = _room?.copyWith(status: RoomStatus.closed);
//         _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
//         _safeNotify();

//       case 'leave':
//         if (userId != null) {
//           _removeMember(userId);
//           if (_room != null && !_members.any((m) => m.isOwner)) {
//             _room = _room?.copyWith(status: RoomStatus.closed);
//             _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
//             _safeNotify();
//           }
//         }

//       case 'pack_selected':
//         final packId = p['pack_id'] as String?;
//         if (packId != null && _room != null) {
//           _room = _room!.copyWith(packId: packId);
//           _safeNotify();
//         }

//       case 'language_changed':
//         final lang = p['language'] as String?;
//         if (lang != null && _room != null) {
//           _room = _room!.copyWith(language: lang);
//           _safeNotify();
//         }

//       case 'ready':
//         if (userId != null) {
//           _updateMember(userId, (m) => m.copyWith(isReady: true));
//           _safeNotify();
//           if (_room != null) _refreshMembers(_room!.id);
//         }

//       case 'not_ready':
//         if (userId != null) {
//           _updateMember(userId, (m) => m.copyWith(isReady: false));
//           _safeNotify();
//           if (_room != null) _refreshMembers(_room!.id);
//         }

//       case 'ownership_transfer':
//         final newOwnerId = p['new_owner_id'] as String?;
//         if (newOwnerId != null && _room != null) {
//           _room = _room!.copyWith(ownerId: newOwnerId);
//           _members = _members
//               .map((m) => m.copyWith(isOwner: m.userId == newOwnerId))
//               .toList();
//           _safeNotify();
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
//       _safeNotify();
//     }
//   }

//   void _handleGameEnded(Map<String, dynamic> p) {
//     if (_room != null) {
//       _room = _room!.copyWith(status: RoomStatus.waiting);
//       _members = _members.map((m) => m.copyWith(isReady: false)).toList();
//       _safeNotify();
//     }
//   }

//   void _handleChatBroadcast(Map<String, dynamic> p) {
//     final msgId = p['id'] as String?;
//     if (msgId == null) return;

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
//       replyToId: p['reply_to_id'] as String?,
//       replyToContent: p['reply_to_content'] as String?,
//       replyToDisplayName: p['reply_to_display_name'] as String?,
//     );

//     _chatMessages = [..._chatMessages, msg];
//     _cache.appendChatMessage(msg).ignore();
//     _safeNotify();
//   }

//   Future<void> sendChatMessage(
//     String content, {
//     ChatMessageEntity? replyTo,
//     bool anonymous = false,
//   }) async {
//     if (_room == null || content.trim().isEmpty) return;
//     if (isCurrentUserMuted) return;
//     if (!_settings.chatEnabled) return;

//     final isPremium = anonymous
//         ? await SubscriptionService.instance.isPremiumActive(_currentUserId)
//         : false;
//     final sendAnon = anonymous && isPremium;

//     final trimmed = content.trim();
//     final msgId = _uuid.v4();
//     final replySnippet = replyTo != null
//         ? (replyTo.content.length > 120
//               ? '${replyTo.content.substring(0, 120)}…'
//               : replyTo.content)
//         : null;

//     _isSendingChat = true;

//     final optimistic = ChatMessageEntity(
//       id: msgId,
//       roomId: _room!.id,
//       userId: sendAnon ? 'anonymous' : _currentUserId,
//       displayName: sendAnon ? 'Anonymous' : _currentDisplayName,
//       avatarUrl: sendAnon ? null : _currentAvatarUrl,
//       content: trimmed,
//       createdAt: DateTime.now(),
//       isOptimistic: true,
//       isAnonymous: sendAnon,
//       replyToId: replyTo?.id,
//       replyToContent: replySnippet,
//       replyToDisplayName: replyTo?.displayName,
//     );
//     _chatMessages = [..._chatMessages, optimistic];
//     _safeNotify();

//     try {
//       await _repo.persistChatMessage(
//         roomId: _room!.id,
//         userId: _currentUserId,
//         content: trimmed,
//         replyToId: replyTo?.id,
//         replyToContent: replySnippet,
//         replyToDisplayName: replyTo?.displayName,
//         isAnonymous: sendAnon,
//       );

//       await _realtime.broadcastChat(_room!.id, {
//         'id': msgId,
//         'user_id': sendAnon ? 'anonymous' : _currentUserId,
//         'display_name': sendAnon ? 'Anonymous' : _currentDisplayName,
//         'avatar_url': sendAnon ? null : _currentAvatarUrl,
//         'content': trimmed,
//         'is_anonymous': sendAnon,
//         if (replyTo != null) 'reply_to_id': replyTo.id,
//         if (replySnippet != null) 'reply_to_content': replySnippet,
//         if (replyTo != null) 'reply_to_display_name': replyTo.displayName,
//       });

//       _chatMessages = _chatMessages
//           .map((m) => m.id == msgId ? m.copyWithConfirmed() : m)
//           .toList();
//     } catch (e) {
//       AppLogger.error('RoomProvider: sendChat failed', error: e);
//       _chatMessages = _chatMessages.where((m) => m.id != msgId).toList();
//     } finally {
//       _isSendingChat = false;
//       _safeNotify();
//     }
//   }

//   void _handleModeration(Map<String, dynamic> p) {
//     final type = p['type'] as String?;
//     final targetId = p['target_user_id'] as String?;

//     switch (type) {
//       case 'mute':
//         if (targetId != null) {
//           _mutedUserIds.add(targetId);
//           _updateMember(targetId, (m) => m.copyWith(isMuted: true));
//           _safeNotify();
//         }

//       case 'unmute':
//         if (targetId != null) {
//           _mutedUserIds.remove(targetId);
//           _updateMember(targetId, (m) => m.copyWith(isMuted: false));
//           _safeNotify();
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
//         _safeNotify();

//       case 'resume':
//         _room = _room?.copyWith(status: RoomStatus.inGame);
//         _safeNotify();

//       case 'room_close':
//         _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
//     }
//   }

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
//       'spectator_approval_required' => _settings.copyWith(
//         spectatorApprovalRequired: value as bool,
//       ),
//       'allow_spicy' => _settings.copyWith(allowSpicy: value as bool),
//       'requires_approval' => _settings.copyWith(
//         requiresApproval: value as bool,
//       ),
//       _ => _settings,
//     };
//     _safeNotify();
//   }

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
//     _safeNotify();
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
//     _safeNotify();
//   }

//   Future<void> grantModerator(String userId) async {
//     if (!isOwner || _room == null) return;
//     await _repo.grantModerator(_room!.id, userId, _currentUserId);
//     _updateMember(userId, (m) => m.copyWith(isModerator: true));
//     _safeNotify();
//   }

//   Future<void> revokeModerator(String userId) async {
//     if (!isOwner || _room == null) return;
//     await _repo.revokeModerator(_room!.id, userId);
//     _updateMember(userId, (m) => m.copyWith(isModerator: false));
//     _safeNotify();
//   }

//   Future<void> updateSetting(String field, dynamic value) async {
//     if (!isOwner || _room == null) return;
//     _handleSettingsChange({'field': field, 'new_value': value});
//     await _realtime.broadcastSettingsChange(_room!.id, field, value);
//     await _repo.updateSettings(_room!.id, _settings);
//   }

//   Future<void> setPackId(String packId) async {
//     if (!isOwner || _room == null) return;
//     _room = _room!.copyWith(packId: packId);
//     _safeNotify();
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
//     _safeNotify();
//     await _supabase
//         .from('rooms')
//         .update({'language': language})
//         .eq('id', _room!.id);
//     await _realtime.broadcastRoomEvent(_room!.id, {
//       'type': 'language_changed',
//       'language': language,
//     });
//   }

//   Future<void> setReady(bool ready) async {
//     if (_room == null) return;
//     _updateMember(_currentUserId, (m) => m.copyWith(isReady: ready));
//     _safeNotify();
//     await _supabase
//         .from('room_members')
//         .update({'is_ready': ready})
//         .eq('room_id', _room!.id)
//         .eq('user_id', _currentUserId);
//     await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
//     await _realtime.broadcastRoomEvent(_room!.id, {
//       'type': ready ? 'ready' : 'not_ready',
//       'user_id': _currentUserId,
//     });
//     Future.delayed(const Duration(milliseconds: 400), () {
//       if (_room != null) _refreshMembers(_room!.id);
//     });
//   }

//   Future<void> toggleReady() => setReady(!(currentMember?.isReady ?? false));

//   Future<void> leaveRoom({bool permanent = false}) async {
//     if (_room == null) return;
//     final roomId = _room!.id;
//     final amOwner = isOwner;

//     bool isPaused = _room!.status == RoomStatus.paused;
//     if (!isPaused && amOwner) {
//       try {
//         final row = await _supabase
//             .from('rooms')
//             .select('status')
//             .eq('id', roomId)
//             .maybeSingle();
//         isPaused = (row?['status'] as String?) == 'paused';
//         if (isPaused) _room = _room!.copyWith(status: RoomStatus.paused);
//       } catch (_) {}
//     }

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

//   void _setConnection(RoomConnectionState state) {
//     if (_connectionState == state) return;
//     _connectionState = state;
//     _safeNotify();
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
//     _safeNotify();
//   }

//   /// Schedules notifyListeners on the next frame when called mid-build,
//   /// preventing "dirty widget in the wrong build scope" from async callbacks
//   /// (e.g. _refreshMembers) completing while the navigator is updating routes.
//   void _safeNotify() {
//     if (_disposed) return;
//     final phase = SchedulerBinding.instance.schedulerPhase;
//     if (phase == SchedulerPhase.persistentCallbacks ||
//         phase == SchedulerPhase.transientCallbacks ||
//         phase == SchedulerPhase.midFrameMicrotasks) {
//       SchedulerBinding.instance.addPostFrameCallback((_) {
//         if (!_disposed) notifyListeners();
//       });
//     } else {
//       notifyListeners();
//     }
//   }

//   @override
//   void dispose() {
//     _disposed = true;
//     _reconnectTimer?.cancel();
//     _readyPollTimer?.cancel();
//     for (final t in _disconnectedTimers.values) t.cancel();
//     _lifecycleCtrl.close();
//     _memberCdcChannel?.unsubscribe();
//     if (_room != null) _realtime.unsubscribe(_room!.id).ignore();
//     super.dispose();
//   }
// }

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
//     replyToId: replyToId,
//     replyToContent: replyToContent,
//     replyToDisplayName: replyToDisplayName,
//   );
// }

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/utils/app_logger.dart';
import '../data/room_repository.dart';
import '../data/room_cache_service.dart';
import '../domain/room_entity.dart';
import '../../games/engine/base_game_engine.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum RoomConnectionState {
  connecting,
  connected,
  reconnecting,
  recovering,
  pendingApproval,
  failed;

  bool get isStable => this == connected;
  bool get isBusy =>
      this == connecting || this == reconnecting || this == recovering;
}

enum RoomLifecycleEvent {
  kicked,
  banned,
  roomClosed,
  ownershipTransferred,
  memberLeft,
}

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

  RoomEntity? _room;
  List<RoomMemberEntity> _members = [];
  RoomSettingsEntity _settings = const RoomSettingsEntity();
  List<ChatMessageEntity> _chatMessages = [];
  RoomConnectionState _connectionState = RoomConnectionState.connecting;
  Failure? _failure;
  bool _isSendingChat = false;
  bool _isInitialized = false;
  bool _disposed = false;

  final _mutedUserIds = <String>{};

  final _disconnectedTimers = <String, Timer>{};

  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _readyPollTimer;
  Timer? _gameReconcileTimer;
  static const _maxAttempts = 3;
  static const _delays = [1, 3, 7];

  final _lifecycleCtrl = StreamController<RoomLifecycleEvent>.broadcast();
  Stream<RoomLifecycleEvent> get lifecycleEvents => _lifecycleCtrl.stream;

  // Read by a memberLeft consumer to build its snackbar text — enum values
  // carry no payload, so the departed member's display name is exposed
  // alongside it rather than turning the whole enum into a payload-bearing
  // class (which would break every existing switch on it).
  String? _lastDepartedMemberName;
  String? get lastDepartedMemberName => _lastDepartedMemberName;

  // Same pattern as _lastDepartedMemberName above — read by the kicked/
  // banned lifecycle-event consumer to build a real "removed by X: reason"
  // snackbar instead of a generic hardcoded one. kickPlayer/banPlayer
  // already broadcast both fields; this just carries them from the
  // received broadcast to whatever handles the resulting lifecycle event.
  String? _lastModerationActorName;
  String? get lastModerationActorName => _lastModerationActorName;
  String? _lastModerationReason;
  String? get lastModerationReason => _lastModerationReason;

  RoomEntity? get room => _room;
  List<RoomMemberEntity> get members => _members;
  List<RoomMemberEntity> get activeMembers =>
      _members.where((m) => !m.isDisconnected).toList();

  /// Non-spectator AND non-disconnected members — the canonical "eligible
  /// active players" set for game-start gating (min-player and
  /// no-reconnecting checks). Combines both axes that [activeMembers]
  /// (disconnected-only) and ad-hoc per-screen filters (spectator-only)
  /// each cover separately.
  List<RoomMemberEntity> get eligiblePlayers =>
      _members.where((m) => !m.isSpectator && !m.isDisconnected).toList();

  /// True when the room is in a game and the owner is the only actively
  /// connected, non-spectator participant left — the game cannot
  /// meaningfully continue like this. Used to prompt the owner to end it,
  /// never to force-end automatically.
  bool get hasNoActivePlayers {
    if (_room?.status != RoomStatus.inGame) return false;
    final others = activeMembers.where(
      (m) => m.userId != _room?.ownerId && !m.isSpectator,
    );
    return others.isEmpty;
  }
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

  bool get canModerateRoom {
    final me = currentMember;
    if (me == null) return false;
    return isOwner || me.isModerator;
  }

  /// Granular permission check for the current user — the owner always
  /// passes; a moderator only passes for a permission explicitly listed in
  /// [ModeratorPermission.all] and granted via [updateModeratorPermissions].
  bool hasPermission(String key) => currentMember?.hasPermission(key) ?? isOwner;

  /// Same check for an arbitrary member — used by the room owner's game
  /// provider to validate a moderator-delegated action (e.g. "advance
  /// turn") sent by someone else's client before executing it, since the
  /// owner's client is the sole authority actually running the game
  /// engine and must not just trust whatever a broadcast claims.
  bool memberHasPermission(String userId, String key) {
    final m = _members.cast<RoomMemberEntity?>().firstWhere(
      (m) => m?.userId == userId,
      orElse: () => null,
    );
    return m?.hasPermission(key) ?? (userId == _room?.ownerId);
  }

  bool get canApproveSpectators => hasPermission(ModeratorPermission.acceptSpectators);
  bool get canAcceptJoins => hasPermission(ModeratorPermission.acceptJoins);
  bool get canAcceptRejoins => hasPermission(ModeratorPermission.acceptRejoins);
  bool get canKickPlayers => hasPermission(ModeratorPermission.kickPlayers);
  bool get canMuteChat => hasPermission(ModeratorPermission.muteChat);
  bool get canMutePlayers => hasPermission(ModeratorPermission.mutePlayers);
  bool get canAdvanceTurn => hasPermission(ModeratorPermission.advanceTurn);
  bool get canSkipTurn => hasPermission(ModeratorPermission.skipTurn);
  bool get canManageSettings => hasPermission(ModeratorPermission.manageSettings);
  bool get canEndGame => hasPermission(ModeratorPermission.endGame);
  bool get canStartGame => hasPermission(ModeratorPermission.startGame);

  /// Owner-only: grants moderator status (if needed) and sets [userId]'s
  /// exact permission set; an empty set revokes moderator status entirely.
  Future<void> updateModeratorPermissions(
    String userId,
    Set<String> permissions,
  ) async {
    if (!isOwner || _room == null) return;
    await _repo.updateModeratorPermissions(
      roomId: _room!.id,
      userId: userId,
      grantedBy: _currentUserId,
      permissions: permissions,
    );
    _updateMember(
      userId,
      (m) => m.copyWith(
        isModerator: permissions.isNotEmpty,
        moderatorPermissions: permissions,
      ),
    );
    _safeNotify();
  }

  Future<List<Map<String, dynamic>>> fetchPendingSpectatorRequests() async {
    if (_room == null) return [];
    return _repo.getPendingSpectatorRequests(_room!.id);
  }

  Future<void> decideSpectatorRequest({
    required String requestId,
    required String requestingUserId,
    required bool approve,
  }) async {
    if (_room == null || !canApproveSpectators) return;
    await _repo.decideSpectatorRequest(
      requestId: requestId,
      roomId: _room!.id,
      requestingUserId: requestingUserId,
      decidedBy: _currentUserId,
      approve: approve,
    );
    await _realtime.broadcastRoomEvent(_room!.id, {
      'type': approve ? 'spectator_approved' : 'spectator_denied',
      'user_id': requestingUserId,
    });
    _safeNotify();
  }

  Future<void> initialize(String roomId, {String role = 'player'}) async {
    final isAnonSpectator = role == 'spectator_anon';
    final normalizedRole = isAnonSpectator ? 'spectator' : role;
    _setConnection(RoomConnectionState.connecting);

    try {
      final cached = await _cache.getCachedChatMessages(roomId);
      if (cached.isNotEmpty) {
        _chatMessages = cached;
        _safeNotify();
      }

      // Single authoritative recovery step, run before any gate below reads
      // room/approval state — no-ops for anyone who isn't this room's
      // creator or current owner. Must run first so: (a) a returning
      // original creator is recognized as the owner by every gate that
      // follows (they'd otherwise be misrouted into a join/spectator
      // request), and (b) a stale mid-game session is already terminated
      // before the mid-game "returning member" gate re-checks room status,
      // so it naturally proceeds as an ordinary join into a waiting room
      // with no further changes needed downstream.
      try {
        final recovery = await _repo.recoverOwnerRoom(roomId);
        if (recovery?['game_terminated'] == true) {
          AppLogger.info(
            'RoomProvider: terminated a stale mid-game session for '
            'returning owner in room $roomId',
          );
          _realtime
              .broadcastGameEnded(roomId, {'reason': 'host_reconnected'})
              .ignore();
        }
      } catch (e) {
        AppLogger.warning('RoomProvider: recoverOwnerRoom failed: $e');
      }

      final approvalInfo = await _repo.getRoomApprovalInfo(roomId);
      if (approvalInfo != null &&
          approvalInfo.requiresApproval &&
          approvalInfo.ownerId != _currentUserId) {
        final alreadyMember = await _repo.isActiveMember(
          userId: _currentUserId,
          roomId: roomId,
        );
        if (!alreadyMember) {
          final invited = await _repo.hasValidInvite(
            userId: _currentUserId,
            roomId: roomId,
          );
          if (invited) {
            await _repo.markInviteAccepted(
              userId: _currentUserId,
              roomId: roomId,
            );
            AppLogger.info('RoomProvider: approval bypassed via valid invite');
          } else {
            await _repo.requestToJoin(userId: _currentUserId, roomId: roomId);
            AppLogger.info(
              'RoomProvider: requires_approval — join request filed instead',
            );
            _repo.notifyJoinRequest(roomId).ignore();
            _setConnection(RoomConnectionState.pendingApproval);
            return;
          }
        }
      }

      if (normalizedRole == 'spectator' || normalizedRole == 'player') {
        final settingsRow = await _supabase
            .from('room_settings')
            .select('spectator_approval_required')
            .eq('room_id', roomId)
            .maybeSingle();
        final needsSpectatorApproval =
            settingsRow?['spectator_approval_required'] as bool? ?? false;
        if (needsSpectatorApproval &&
            approvalInfo != null &&
            approvalInfo.ownerId != _currentUserId) {
          final roomRow = await _supabase
              .from('rooms')
              .select('status')
              .eq('id', roomId)
              .maybeSingle();
          final isInProgress = roomRow?['status'] == 'in_game';
          if (isInProgress) {
            // hasPriorMembership (not isActiveMember) — a returning member
            // whose row was soft-removed by the disconnect grace period
            // must reactivate normally via joinRoom's own upsert below, not
            // get funneled into spectator-approval limbo as if they were a
            // stranger. Only someone with NO prior room_members row at all
            // is a genuinely new joiner that needs the approval gate.
            final alreadyMember = await _repo.hasPriorMembership(
              userId: _currentUserId,
              roomId: roomId,
            );
            if (!alreadyMember) {
              await _repo.requestSpectatorAccess(
                roomId: roomId,
                userId: _currentUserId,
              );
              await _realtime.broadcastRoomEvent(roomId, {
                'type': 'spectator_request',
                'user_id': _currentUserId,
              });
              AppLogger.info(
                'RoomProvider: game in progress + spectator gate — queued spectator request',
              );
              _setConnection(RoomConnectionState.pendingApproval);
              return;
            }
          }
        }
      }

      // A brand-new player (never a member of this room before) attempting
      // to join while a game is already in_game must not be dropped
      // straight into it — force them through the same
      // room_join_requests/decide_join_request approval flow used for
      // ordinary requires_approval joins, regardless of the room's own
      // requires_approval toggle (mirrors gate 2's spectator-approval
      // convention above, which is likewise independent of that toggle).
      // Spectators are covered by the spectator-approval gate above;
      // returning members (hasPriorMembership) are covered by the
      // rejoin-approval gate below — this only catches the remaining gap:
      // a genuine stranger joining as a player mid-game.
      if (normalizedRole == 'player' &&
          approvalInfo != null &&
          approvalInfo.ownerId != _currentUserId) {
        final roomRow = await _supabase
            .from('rooms')
            .select('status')
            .eq('id', roomId)
            .maybeSingle();
        if (roomRow?['status'] == 'in_game') {
          final everMember = await _repo.hasPriorMembership(
            userId: _currentUserId,
            roomId: roomId,
          );
          if (!everMember) {
            await _repo.requestToJoin(userId: _currentUserId, roomId: roomId);
            AppLogger.info(
              'RoomProvider: game already in progress — brand-new player '
              'join request filed instead of auto-joining',
            );
            _repo.notifyJoinRequest(roomId).ignore();
            _setConnection(RoomConnectionState.pendingApproval);
            return;
          }
        }
      }

      // A player genuinely returning to an ONGOING game (disconnected/app
      // closed, room now in_game/paused, and their room_members row was
      // actually left — not just a normal join/rejoin into a waiting
      // lobby) must go through the existing request_game_rejoin approval
      // flow instead of silently reviving via joinRoom's upsert. The
      // approval system (request_game_rejoin/decide_game_rejoin_request +
      // _RejoinBanner/_RejoinRequestsPanel) already exists and is fully
      // wired — it was just never reached in practice because joinRoom ran
      // unconditionally here and almost always succeeded first. Spectators
      // are excluded: they aren't in game_sessions.player_ids, so routing
      // them through request_game_rejoin would incorrectly reject them —
      // they keep using the normal joinRoom path below.
      var skipAutoJoin = false;
      if (normalizedRole != 'spectator') {
        final roomStatusRow = await _supabase
            .from('rooms')
            .select('status')
            .eq('id', roomId)
            .maybeSingle();
        final isMidGame = const {
          'in_game',
          'paused',
        }.contains(roomStatusRow?['status']);
        if (isMidGame) {
          final stillActive = await _repo.isActiveMember(
            userId: _currentUserId,
            roomId: roomId,
          );
          if (!stillActive) {
            skipAutoJoin = await _repo.hasPriorMembership(
              userId: _currentUserId,
              roomId: roomId,
            );
          }
        }
      }

      if (skipAutoJoin) {
        AppLogger.info(
          'RoomProvider: mid-game returning member — deferring to the '
          'rejoin-approval flow instead of auto-reviving membership',
        );
      } else {
        AppLogger.debug(
          'RoomProvider: joining room $roomId as $_currentUserId (role=$normalizedRole, anon=$isAnonSpectator)',
        );
        try {
          await _repo.joinRoom(
            userId: _currentUserId,
            roomId: roomId,
            role: normalizedRole,
            isHiddenSpectator: isAnonSpectator,
          );
          AppLogger.debug('RoomProvider: joinRoom succeeded');
        } catch (joinErr) {
          AppLogger.warning('RoomProvider: joinRoom failed: $joinErr');
        }
      }

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
      _safeNotify();

      final history = await _repo.getChatHistory(roomId);
      _chatMessages = history;
      await _cache.cacheChatMessages(roomId, history);
      _safeNotify();

      await _subscribeChannel(roomId);

      await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
      await _realtime.broadcastRoomEvent(roomId, {
        'type': 'join',
        'user_id': _currentUserId,
        'display_name': _currentDisplayName,
        'avatar_url': _currentAvatarUrl,
      });

      await _presence.setInGame(roomId);

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

  Future<void> _subscribeChannel(String roomId) async {
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

    _readyPollTimer?.cancel();
    _readyPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_room != null && _room!.status == RoomStatus.waiting) {
        _refreshMembers(_room!.id);
      } else {
        _readyPollTimer?.cancel();
      }
    });

    // Once a game starts, the fast lobby poll above stops — but membership
    // is otherwise purely event-driven (presence sync + the room_members
    // CDC subscription), so a single missed/incomplete event could desync
    // a client's member list for the rest of the game with nothing to
    // correct it. Keep a much lighter periodic re-fetch running for as
    // long as the room stays in_game/paused.
    _gameReconcileTimer?.cancel();
    _gameReconcileTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      final status = _room?.status;
      if (status == RoomStatus.inGame || status == RoomStatus.paused) {
        _refreshMembers(_room!.id);
      }
      // Deliberately does NOT self-cancel on any other status — unlike
      // the fast lobby-only poll above, this needs to still be running
      // whenever the room later transitions into in_game/paused, not just
      // if it happened to already be in that state when this timer was
      // created. Only actually cancelled on disconnect/dispose.
    });

    // subscriberId: 'room' — this listener persists for the whole room
    // visit and is never displaced by a game screen's own 'game' listener
    // registered on the same channel (see RealtimeService/RoomChannelSubscriber).
    await _realtime.subscribe(
      roomId: roomId,
      subscriberId: RoomChannelSubscriber.room,
      onGameState: (_) {},
      onPlayerAction: (_) {},
      onSyncRequest: (_) {},
      onGameStarted: _handleGameStarted,
      onGameEnded: _handleGameEnded,
      onRoomEvent: _handleRoomEvent,
      onChatMessage: _handleChatBroadcast,
      onModeration: _handleModeration,
      onSettingsChange: _handleSettingsChange,
      onPresenceSync: _handlePresenceSync,
      onStatusChange: _handleChannelStatus,
    );
  }

  void _handleChannelStatus(RealtimeSubscribeStatus status) {
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
        if (_connectionState == RoomConnectionState.reconnecting ||
            _connectionState == RoomConnectionState.recovering) {
          _setConnection(RoomConnectionState.recovering);
          _requestSync();
          // Reconnect previously only resumed the channel and trusted
          // whatever incremental postgres-changes events happen to arrive
          // afterward — any member-list drift accumulated during the
          // disconnect window (a grace-period eviction that fired while
          // this client was offline, someone joining/leaving, etc.) would
          // otherwise linger until the next incidental event. A full
          // refetch here corrects it immediately.
          if (_room != null) _refreshMembers(_room!.id);
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
    Timer(const Duration(seconds: 5), () {
      if (_connectionState == RoomConnectionState.recovering) {
        _setConnection(RoomConnectionState.connected);
      }
    });
  }

  Future<void> _trackOwnPresence({required int seatOrder}) async {
    if (_room == null) return;
    if (currentMember?.isHiddenSpectator == true) return;
    await _realtime.trackPresence(_room!.id, {
      PresenceKey.userId: _currentUserId,
      PresenceKey.displayName: _currentDisplayName,
      PresenceKey.avatarUrl: _currentAvatarUrl,
      PresenceKey.seatOrder: seatOrder,
      PresenceKey.isReady: currentMember?.isReady ?? false,
      PresenceKey.joinedAt: DateTime.now().toIso8601String(),
    });
    _touchPresence();
    _startHeartbeat();
  }

  Timer? _heartbeatTimer;

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _touchPresence(),
    );
  }

  void _touchPresence() {
    if (_room == null) return;
    _repo.touchPresence(_room!.id).ignore();
  }

  Future<void> _refreshMembers(String roomId) async {
    try {
      final (freshRoom, freshMembers, _, _) = await _repo.getRoomWithDetails(
        roomId,
      );
      if (freshMembers.isEmpty) return;
      _members = freshMembers;
      // Previously discarded the freshly-fetched room row and only applied
      // members — so a client whose ownership had been silently reassigned
      // (automatic failover, 0d) while it was disconnected never picked up
      // the new owner_id on reconnect, even though this same call already
      // re-fetched it. isOwner (_room.ownerId == me) stayed stale-true,
      // so pressing "Close Room" issued an RLS-gated update that silently
      // matched 0 rows — no error, room just never closed.
      if (_room != null && _room!.id == freshRoom.id) {
        _room = freshRoom;
      }
      _safeNotify();
      AppLogger.debug('RoomProvider: refreshed members=${_members.length}');
    } catch (e) {
      AppLogger.warning('RoomProvider: _refreshMembers failed: $e');
    }
  }

  void _handlePresenceSync(List<Map<String, dynamic>> presences) {
    bool changed = false;

    final onlineIds = presences
        .map((p) => p[PresenceKey.userId] as String?)
        .whereType<String>()
        .toSet();

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

    for (final member in _members) {
      final isOnline = onlineIds.contains(member.userId);
      if (!isOnline && !member.isDisconnected) {
        // Require absence across two consecutive syncs before starting the
        // removal grace period — a channel resubscribe (reconnect) clears
        // the local presence cache, and the very next sync can transiently
        // show other genuinely-still-connected members as absent simply
        // because their own clients haven't re-tracked yet server-side.
        // One missed/incomplete sync shouldn't be enough to start a timer
        // that ends in a real `left_at` DB write for someone who never
        // actually disconnected.
        if (_pendingAbsence.add(member.userId)) continue;
        _pendingAbsence.remove(member.userId);
        _startGracePeriod(member.userId);
        changed = true;
      } else if (isOnline) {
        _pendingAbsence.remove(member.userId);
        if (member.isDisconnected) {
          _cancelGracePeriod(member.userId);
          _updateMember(
            member.userId,
            (m) => m.copyWith(isDisconnected: false),
          );
          changed = true;
        }
      }
    }

    if (changed) _safeNotify();
  }

  final Set<String> _pendingAbsence = {};

  void _startGracePeriod(String userId) {
    _updateMember(userId, (m) => m.copyWith(isDisconnected: true));
    _disconnectedTimers[userId]?.cancel();
    _disconnectedTimers[userId] = Timer(
      const Duration(seconds: 30),
      () => _confirmAndRemoveMember(userId),
    );
    _safeNotify();
  }

  void _cancelGracePeriod(String userId) {
    _disconnectedTimers[userId]?.cancel();
    _disconnectedTimers.remove(userId);
  }

  /// Presence (client-side diffing, no server record) is what *arms* the
  /// grace-period timer, but the actual permanent eviction re-checks a
  /// server-verified heartbeat first — closes the race where two unrelated
  /// presence events (e.g. someone else's ready-toggle re-tracking) could
  /// arm the timer for a member who only had a momentary blip and has
  /// since reconnected, whose own client just hasn't had a fresh presence
  /// sync reach this one yet.
  Future<void> _confirmAndRemoveMember(String userId) async {
    final room = _room;
    if (room == null) return;
    DateTime? lastSeen;
    try {
      lastSeen = await _repo.getMemberLastSeen(
        roomId: room.id,
        userId: userId,
      );
      if (lastSeen != null &&
          DateTime.now().difference(lastSeen) < const Duration(seconds: 25)) {
        AppLogger.debug(
          'RoomProvider: cancelling eviction for $userId — heartbeat at $lastSeen',
        );
        _cancelGracePeriod(userId);
        _updateMember(userId, (m) => m.copyWith(isDisconnected: false));
        _safeNotify();
        return;
      }
    } catch (e) {
      AppLogger.warning(
        'RoomProvider: last_seen_at check failed, proceeding with eviction: $e',
      );
    }

    // A stale OWNER is never evicted (no leaveRoom/left_at write, and no
    // "close the room" side effect even if they're alone) by a bystander's
    // presence-timeout detection — that write was what previously made a
    // briefly force-quit owner look like they'd left the room, and desynced
    // the create-room pre-flight check (getActiveMembership). Ownership
    // only moves to another active member after a MUCH longer absence
    // (3 minutes, not the ordinary 25s eviction threshold used above), and
    // even then the original owner's own room_members row is left intact —
    // recover_owner_room hands the room straight back to them automatically
    // the moment they do reconnect, regardless of how long they were gone.
    final wasOwner = _members.any((m) => m.userId == userId && m.isOwner);
    if (wasOwner) {
      final hasOtherActiveMember = _members.any(
        (m) => m.userId != userId && !m.isSpectator,
      );
      final longStale =
          lastSeen != null &&
          DateTime.now().difference(lastSeen) > const Duration(minutes: 3);
      if (hasOtherActiveMember && longStale) {
        try {
          final newOwnerId = await _repo.claimRoomOwnership(room.id);
          if (newOwnerId != null) {
            AppLogger.info(
              'RoomProvider: auto-promoted $newOwnerId after owner $userId went stale',
            );
            await _realtime.broadcastRoomEvent(room.id, {
              'type': 'ownership_transfer',
              'user_id': userId,
              'new_owner_id': newOwnerId,
            });
            _room = _room?.copyWith(
              ownerId: newOwnerId,
              ownerTransferredAt: DateTime.now(),
            );
            _members = _members
                .map((m) => m.copyWith(isOwner: m.userId == newOwnerId))
                .toList();
          }
        } catch (e) {
          AppLogger.warning(
            'RoomProvider: claimRoomOwnership failed: $e',
          );
        }
      }
      _cancelGracePeriod(userId);
      _updateMember(userId, (m) => m.copyWith(isDisconnected: true));
      _safeNotify();
      return;
    }

    _removeMember(userId);
  }

  /// Called by a game screen whenever it receives ANY realtime player
  /// action (ready, submit, vote, react, ...) from a member — receiving a
  /// live action is proof of connectivity, so this cancels a presence
  /// grace-period in progress and clears a stale "disconnected" flag
  /// immediately, instead of waiting up to 30s for the next presence
  /// heartbeat. Prevents an active, still-playing member from being
  /// removed from the room due to a transient presence hiccup coinciding
  /// with real game activity (e.g. pressing Ready).
  void markMemberActive(String userId) {
    if (_disconnectedTimers.containsKey(userId)) {
      _cancelGracePeriod(userId);
      _updateMember(userId, (m) => m.copyWith(isDisconnected: false));
      _safeNotify();
    }
  }

  void _handleRoomEvent(Map<String, dynamic> p) {
    final type = p['type'] as String?;
    final userId = p['user_id'] as String?;

    switch (type) {
      case 'game_started':
        if (_room != null && !isOwner) {
          final gameTypeStr = p['game_type'] as String?;
          if (gameTypeStr != null) {
            final gt = GameType.values.firstWhere(
              (g) => g.toDbString() == gameTypeStr,
              orElse: () => GameType.truthOrDare,
            );
            _room = _room!.copyWith(status: RoomStatus.inGame, gameType: gt);
            _safeNotify();
          }
        }

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
          _safeNotify();
        }

      case 'owner_left':
        // Idempotency guard: leaveRoom() also sends a 'leave' broadcast
        // right after this one, which independently closes the room via
        // _removeMember's owner-check — without this guard a client that
        // already processed one of the two would fire roomClosed (and
        // LobbyScreen's dialog) a second time.
        if (_room != null && _room!.status != RoomStatus.closed) {
          _room = _room!.copyWith(status: RoomStatus.closed);
          _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
          _safeNotify();
        }

      case 'leave':
        // Owner-loss closing the room is now handled centrally in
        // _removeMember, which also covers the presence-timeout
        // (ungraceful disconnect) path — see that method.
        if (userId != null) {
          _removeMember(userId);
        }

      case 'player_left':
        // 'player_left' is sent for two different situations, told apart
        // by for_good:
        //  - for_good: true  -> the user actually left the room (normal
        //    player/spectator quitting a game also leaves the room — see
        //    the game screens). Update membership immediately rather than
        //    waiting on the room_members CDC round-trip. No toast needed
        //    here — the member disappearing from the list is enough.
        //  - for_good: false -> the user only left the current game
        //    session (owner ending a game does NOT send this at all — it
        //    goes through 'game_ended'/_handleGameEnded instead). Room
        //    membership is untouched; only the game screens' own listener
        //    reacts, showing "left the game" — not handled here, so it
        //    isn't duplicated.
        final forGood = p['for_good'] as bool? ?? true;
        if (userId != null && forGood) {
          _removeMember(userId);
        }

      case 'pack_selected':
        final packId = p['pack_id'] as String?;
        if (packId != null && _room != null) {
          _room = _room!.copyWith(packId: packId);
          _safeNotify();
        }

      case 'language_changed':
        final lang = p['language'] as String?;
        if (lang != null && _room != null) {
          _room = _room!.copyWith(language: lang);
          _safeNotify();
        }

      case 'ready':
        if (userId != null) {
          _updateMember(userId, (m) => m.copyWith(isReady: true));
          _safeNotify();
          if (_room != null) _refreshMembers(_room!.id);
        }

      case 'not_ready':
        if (userId != null) {
          _updateMember(userId, (m) => m.copyWith(isReady: false));
          _safeNotify();
          if (_room != null) _refreshMembers(_room!.id);
        }

      case 'ownership_transfer':
        final newOwnerId = p['new_owner_id'] as String?;
        if (newOwnerId != null && _room != null) {
          _room = _room!.copyWith(ownerId: newOwnerId);
          _members = _members
              .map((m) => m.copyWith(isOwner: m.userId == newOwnerId))
              .toList();
          _safeNotify();
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
      _safeNotify();
    }
  }

  void _handleGameEnded(Map<String, dynamic> p) {
    if (_room != null) {
      _room = _room!.copyWith(status: RoomStatus.waiting);
      _members = _members.map((m) => m.copyWith(isReady: false)).toList();
      _safeNotify();
    }
  }

  void _handleChatBroadcast(Map<String, dynamic> p) {
    final msgId = p['id'] as String?;
    if (msgId == null) return;

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
      replyToId: p['reply_to_id'] as String?,
      replyToContent: p['reply_to_content'] as String?,
      replyToDisplayName: p['reply_to_display_name'] as String?,
    );

    _chatMessages = [..._chatMessages, msg];
    _cache.appendChatMessage(msg).ignore();
    _safeNotify();
  }

  Future<void> sendChatMessage(
    String content, {
    ChatMessageEntity? replyTo,
    bool anonymous = false,
  }) async {
    if (_room == null || content.trim().isEmpty) return;
    if (isCurrentUserMuted) return;
    if (!_settings.chatEnabled) return;

    final isPremium = anonymous
        ? await SubscriptionService.instance.isPremiumActive(_currentUserId)
        : false;
    final sendAnon = anonymous && isPremium;

    final trimmed = content.trim();
    final msgId = _uuid.v4();
    final replySnippet = replyTo != null
        ? (replyTo.content.length > 120
              ? '${replyTo.content.substring(0, 120)}…'
              : replyTo.content)
        : null;

    _isSendingChat = true;

    final optimistic = ChatMessageEntity(
      id: msgId,
      roomId: _room!.id,
      userId: sendAnon ? 'anonymous' : _currentUserId,
      displayName: sendAnon ? 'Anonymous' : _currentDisplayName,
      avatarUrl: sendAnon ? null : _currentAvatarUrl,
      content: trimmed,
      createdAt: DateTime.now(),
      isOptimistic: true,
      isAnonymous: sendAnon,
      replyToId: replyTo?.id,
      replyToContent: replySnippet,
      replyToDisplayName: replyTo?.displayName,
    );
    _chatMessages = [..._chatMessages, optimistic];
    _safeNotify();

    try {
      await _repo.persistChatMessage(
        roomId: _room!.id,
        userId: _currentUserId,
        content: trimmed,
        replyToId: replyTo?.id,
        replyToContent: replySnippet,
        replyToDisplayName: replyTo?.displayName,
        isAnonymous: sendAnon,
      );

      await _realtime.broadcastChat(_room!.id, {
        'id': msgId,
        'user_id': sendAnon ? 'anonymous' : _currentUserId,
        'display_name': sendAnon ? 'Anonymous' : _currentDisplayName,
        'avatar_url': sendAnon ? null : _currentAvatarUrl,
        'content': trimmed,
        'is_anonymous': sendAnon,
        if (replyTo != null) 'reply_to_id': replyTo.id,
        if (replySnippet != null) 'reply_to_content': replySnippet,
        if (replyTo != null) 'reply_to_display_name': replyTo.displayName,
      });

      _chatMessages = _chatMessages
          .map((m) => m.id == msgId ? m.copyWithConfirmed() : m)
          .toList();
    } catch (e) {
      AppLogger.error('RoomProvider: sendChat failed', error: e);
      _chatMessages = _chatMessages.where((m) => m.id != msgId).toList();
    } finally {
      _isSendingChat = false;
      _safeNotify();
    }
  }

  void _handleModeration(Map<String, dynamic> p) {
    final type = p['type'] as String?;
    final targetId = p['target_user_id'] as String?;

    switch (type) {
      case 'mute':
        if (targetId != null) {
          _mutedUserIds.add(targetId);
          _updateMember(targetId, (m) => m.copyWith(isMuted: true));
          _safeNotify();
        }

      case 'unmute':
        if (targetId != null) {
          _mutedUserIds.remove(targetId);
          _updateMember(targetId, (m) => m.copyWith(isMuted: false));
          _safeNotify();
        }

      case 'kick':
        if (targetId != null) {
          _removeMember(targetId);
          if (targetId == _currentUserId) {
            _lastModerationActorName = p['by_name'] as String?;
            _lastModerationReason = p['reason'] as String?;
            _lifecycleCtrl.add(RoomLifecycleEvent.kicked);
          }
        }

      case 'ban':
        if (targetId != null) {
          _removeMember(targetId);
          if (targetId == _currentUserId) {
            _lastModerationActorName = p['by_name'] as String?;
            _lastModerationReason = p['reason'] as String?;
            _lifecycleCtrl.add(RoomLifecycleEvent.banned);
          }
        }

      case 'game_kick':
        // Game-level kick keeps room membership (unlike room-level kick/ban
        // above) — the target is still a member, just no longer playing, so
        // reflect that in the member list instead of removing the row.
        if (targetId != null) {
          _updateMember(targetId, (m) => m.copyWith(isAway: true));
          _safeNotify();
        }

      case 'game_mute':
        // Distinct from 'mute' above: this gates game actions (see
        // RoomMemberEntity.isGameMuted), not chat.
        if (targetId != null) {
          _updateMember(targetId, (m) => m.copyWith(isGameMuted: true));
          _safeNotify();
        }

      case 'game_unmute':
        if (targetId != null) {
          _updateMember(targetId, (m) => m.copyWith(isGameMuted: false));
          _safeNotify();
        }

      case 'pause':
        _room = _room?.copyWith(status: RoomStatus.paused);
        _safeNotify();

      case 'resume':
        _room = _room?.copyWith(status: RoomStatus.inGame);
        _safeNotify();

      case 'room_close':
        _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
    }
  }

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
      'spectator_approval_required' => _settings.copyWith(
        spectatorApprovalRequired: value as bool,
      ),
      'allow_spicy' => _settings.copyWith(allowSpicy: value as bool),
      'requires_approval' => _settings.copyWith(
        requiresApproval: value as bool,
      ),
      'enable_punishments' => _settings.copyWith(
        enablePunishments: value as bool,
      ),
      'punishment_source' => _settings.copyWith(
        punishmentSource: value as String,
      ),
      'proof_visibility_policy' => _settings.copyWith(
        proofVisibilityPolicy: value as String,
      ),
      'proof_view_seconds' => _settings.copyWith(
        proofViewSeconds: (value as num).toInt(),
      ),
      'proof_replay_mode' => _settings.copyWith(
        proofReplayMode: value as String,
      ),
      'proof_visibility_selected_user_ids' => _settings.copyWith(
        proofVisibilitySelectedUserIds: (value as List).cast<String>(),
      ),
      _ => _settings,
    };
    _safeNotify();
  }

  Future<void> kickPlayer(String targetUserId, {String? reason}) async {
    if (!canKickPlayers || targetUserId == _currentUserId || _room == null) {
      return;
    }
    // Server-side (kick_room_member RPC) is the real gate — this is a
    // client-side pre-check so the UI doesn't attempt a round-trip it
    // knows will be rejected.
    await _repo.kickMember(_room!.id, targetUserId);
    await _realtime.broadcastModeration(_room!.id, {
      'type': 'kick',
      'target_user_id': targetUserId,
      'reason': reason,
      'by_name': currentMember?.displayName,
    });
    _removeMember(targetUserId);
    _repo
        .notifyModeration(
          roomId: _room!.id,
          targetUserId: targetUserId,
          action: 'kick',
        )
        .ignore();
  }

  /// In-game moderation mute (see [RoomMemberEntity.isGameMuted]) — the
  /// target can still watch but every game engine's action chokepoint
  /// (_handleAction) drops their submit/vote/turn actions. Distinct from
  /// [mutePlayer], which only silences text chat and persists to the
  /// room's chat-mute column; this is broadcast-only/session-scoped, same
  /// as game_kick's away-marking above.
  Future<void> mutePlayerInGame(String targetUserId, {bool muted = true}) async {
    if (!canMutePlayers || targetUserId == _currentUserId || _room == null) {
      return;
    }
    await _realtime.broadcastModeration(_room!.id, {
      'type': muted ? 'game_mute' : 'game_unmute',
      'target_user_id': targetUserId,
    });
    _updateMember(targetUserId, (m) => m.copyWith(isGameMuted: muted));
    _safeNotify();
  }

  Future<void> mutePlayer(
    String targetUserId, {
    bool muted = true,
    int durationSeconds = 300,
  }) async {
    if (!canMuteChat || targetUserId == _currentUserId || _room == null) {
      return;
    }
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
    _safeNotify();
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
      'by_name': currentMember?.displayName,
    });
    _removeMember(targetUserId);
    _repo
        .notifyModeration(
          roomId: _room!.id,
          targetUserId: targetUserId,
          action: 'ban',
        )
        .ignore();
  }

  Future<void> unbanPlayer(String targetUserId) async {
    if (!isOwner || _room == null) return;
    await _repo.liftBan(_room!.id, targetUserId);
  }

  /// UI-visibility hint only — the real, unbypassable gate (Premium
  /// required, once per UTC calendar day PER USER across all rooms they
  /// own) lives entirely in the `transfer_room_ownership` server RPC.
  /// Callers should additionally check the current user's Premium status
  /// (via AuthProvider) before showing the option, and surface whatever
  /// message the RPC's rejection carries rather than trying to predict
  /// the daily limit client-side (a per-room timestamp can't reflect a
  /// transfer done from a different room).
  bool get canTransferOwnership => isOwner;

  Future<void> transferOwnership(String newOwnerId) async {
    if (!canTransferOwnership || _room == null) return;
    final target = _members
        .where((m) => m.userId == newOwnerId)
        .firstOrNull;
    // Only a current, non-spectator player may receive game-authority —
    // a spectator becoming owner mid-game would have no way to run the
    // active game's engine. (The server RPC also enforces this, but
    // checking here avoids an unnecessary round-trip for the common case.)
    if (target == null || target.isSpectator) return;
    // Throws a Failure (e.g. RateLimitFailure with a friendly message) if
    // the server-side check rejects it — left to the caller to surface.
    await _repo.transferOwnership(_room!.id, newOwnerId);
    await _realtime.broadcastRoomEvent(_room!.id, {
      'type': 'ownership_transfer',
      'user_id': _currentUserId,
      'new_owner_id': newOwnerId,
    });
    _room = _room!.copyWith(
      ownerId: newOwnerId,
      ownerTransferredAt: DateTime.now(),
    );
    _members = _members
        .map((m) => m.copyWith(isOwner: m.userId == newOwnerId))
        .toList();
    _safeNotify();
  }


  Future<void> updateSetting(String field, dynamic value) async {
    if (!canManageSettings || _room == null) return;
    _handleSettingsChange({'field': field, 'new_value': value});
    await _realtime.broadcastSettingsChange(_room!.id, field, value);
    await _repo.updateSettings(_room!.id, _settings);
  }

  Future<void> setPackId(String packId) async {
    if (!canManageSettings || _room == null) return;
    _room = _room!.copyWith(packId: packId);
    _safeNotify();
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
    _safeNotify();
    await _supabase
        .from('rooms')
        .update({'language': language})
        .eq('id', _room!.id);
    await _realtime.broadcastRoomEvent(_room!.id, {
      'type': 'language_changed',
      'language': language,
    });
  }

  Future<void> setReady(bool ready) async {
    if (_room == null) return;
    _updateMember(_currentUserId, (m) => m.copyWith(isReady: ready));
    _safeNotify();
    await _supabase
        .from('room_members')
        .update({'is_ready': ready})
        .eq('room_id', _room!.id)
        .eq('user_id', _currentUserId);
    await _trackOwnPresence(seatOrder: currentMember?.seatOrder ?? 0);
    await _realtime.broadcastRoomEvent(_room!.id, {
      'type': ready ? 'ready' : 'not_ready',
      'user_id': _currentUserId,
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_room != null) _refreshMembers(_room!.id);
    });
  }

  Future<void> toggleReady() => setReady(!(currentMember?.isReady ?? false));

  bool _isLeaving = false;

  Future<void> leaveRoom({bool permanent = false}) async {
    // Defensive: a double-tap on "Leave" (or a duplicate call racing the
    // screen's own navigation) must not re-broadcast owner_left/leave or
    // re-run the DB close twice.
    if (_room == null || _isLeaving) return;
    _isLeaving = true;
    try {
      final roomId = _room!.id;
      final amOwner = isOwner;

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

      if (amOwner && (permanent || !isPaused)) {
        await _realtime.broadcastRoomEvent(roomId, {
          'type': 'owner_left',
          'user_id': _currentUserId,
        });
        await _closeRoomInBackend(roomId);
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
    } finally {
      _isLeaving = false;
    }
  }

  void _setConnection(RoomConnectionState state) {
    if (_connectionState == state) return;
    _connectionState = state;
    _safeNotify();
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
    final leaving = _members.where((m) => m.userId == userId).firstOrNull;
    final wasOwner = leaving?.isOwner ?? false;
    _members = _members.where((m) => m.userId != userId).toList();
    // Never a silent removal — every real departure (kick, ban, confirmed
    // disconnect timeout, explicit leave) gets a visible "X left the game"
    // for everyone else, not just the target's own kicked/banned event
    // below (which only fires for the target's own client).
    if (leaving != null) {
      _lastDepartedMemberName = leaving.displayName;
      _lifecycleCtrl.add(RoomLifecycleEvent.memberLeft);
    }
    // Persist the departure so a stale room_members row doesn't linger
    // forever after an ungraceful disconnect (app killed/crash/network
    // drop) times out via the presence grace period instead of going
    // through an explicit leave/kick/ban call that already writes this.
    // isFilter('left_at', null) in leaveRoom makes this a no-op when
    // another path already recorded the departure.
    if (_room != null) {
      _repo.leaveRoom(userId: userId, roomId: _room!.id).ignore();
    }
    // Covers the ungraceful-exit case (app killed, crash, network drop)
    // where the owner's presence just times out via the grace-period timer
    // instead of an explicit 'leave'/'owner_left' broadcast ever being sent.
    if (wasOwner &&
        _room != null &&
        _room!.status != RoomStatus.closed &&
        !_members.any((m) => m.isOwner)) {
      _room = _room!.copyWith(status: RoomStatus.closed);
      _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
      _closeRoomInBackend(_room!.id);
    }
    _safeNotify();
  }

  Future<void> _closeRoomInBackend(String roomId) async {
    try {
      // Atomic close: also aborts any active/paused game_sessions row for
      // this room server-side — a plain rooms.update() left game_sessions
      // untouched, so a closed room's session could stay 'active' forever.
      await _supabase.rpc('close_room', params: {'p_room_id': roomId});
    } catch (e) {
      AppLogger.warning('RoomProvider: _closeRoomInBackend failed: $e');
    }
  }

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

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _readyPollTimer?.cancel();
    _gameReconcileTimer?.cancel();
    _heartbeatTimer?.cancel();
    for (final t in _disconnectedTimers.values) t.cancel();
    _lifecycleCtrl.close();
    _memberCdcChannel?.unsubscribe();
    if (_room != null) _realtime.unsubscribe(_room!.id).ignore();
    super.dispose();
  }
}

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
    replyToId: replyToId,
    replyToContent: replyToContent,
    replyToDisplayName: replyToDisplayName,
  );
}
