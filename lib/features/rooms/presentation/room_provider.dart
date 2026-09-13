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

  /// Fallback signal: the periodic membership reconciliation (see
  /// _refreshMembers) noticed the current user's own row is simply no
  /// longer in the room, without a moderation broadcast ever arriving to
  /// say why (missed/undelivered broadcast — Realtime Broadcast has no
  /// delivery guarantee or replay — or a purely server-side removal path
  /// like cleanupJob.js's stale-room/expired-ban sweep, which never
  /// broadcasts to begin with). kicked/banned are still the primary,
  /// immediate signal when the broadcast *does* arrive; this is what
  /// guarantees the same teardown eventually happens even when it doesn't.
  removed,
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
  // Item 2 — targeted chat delivery. Deliberately a SEPARATE CDC
  // subscription from _memberCdcChannel (same 'xxx_cdc:$roomId' naming
  // convention) rather than piggybacking on RealtimeService's broadcast
  // channel: broadcast has no RLS/authorization, so a targeted message
  // must never be sent over it (see the migration's header comment for
  // the full audit). CDC events are evaluated against RLS, so a
  // 'selected'-audience row only ever reaches a client that's the
  // sender or a listed recipient.
  RealtimeChannel? _targetedChatCdcChannel;
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

  final _disconnectedTimers = <String, Timer>{};

  // Latches _autoEndGame so a still-connected owner's client doesn't
  // re-broadcast game_ended on every subsequent _refreshMembers tick while
  // waiting for its own updateStatus(waiting) write to come back around
  // through CDC. Reset the moment the room is next seen with a viable
  // player count or has left the in-game/paused phase — see
  // _maybeAutoEndGame.
  bool _autoEndTriggered = false;

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

  /// RAW membership — includes hidden spectators. Use ONLY for moderation,
  /// room-lifecycle, and count-of-real-members logic. For anything a NORMAL
  /// player can SEE (member list, spectator list, tiles, profiles), use
  /// [visibleMembers]/[visibleSpectators] so hidden spectators stay invisible.
  List<RoomMemberEntity> get members => _members;

  /// Pure, testable membership-visibility rule: hidden spectators are visible
  /// only to a moderator; everyone else never sees them. The instance getters
  /// below delegate here so the exact production rule is unit-testable without
  /// standing up a full provider.
  static List<RoomMemberEntity> filterVisibleMembers(
    List<RoomMemberEntity> members, {
    required bool viewerCanModerate,
  }) => viewerCanModerate
      ? List<RoomMemberEntity>.from(members)
      : members.where((m) => !m.isHiddenSpectator).toList();

  /// Pure, testable identity-reveal rule: a hidden spectator's real identity is
  /// unmaskable only by a moderator who is Premium Plus. Moderation (kick/ban)
  /// is deliberately independent of this.
  static bool computeCanRevealHiddenSpectator({
    required bool viewerCanModerate,
    required bool viewerIsPremiumPlus,
  }) => viewerCanModerate && viewerIsPremiumPlus;

  /// Authoritative "may this user RETURN to (and not be bounced from) this
  /// room" rule, keyed off the room's most-recent game session — used both by
  /// the closed-room entry gate and by joinRoom's closed-status bypass. A user
  /// is a returning participant iff they are in the session's frozen
  /// player_ids, still have a member row, and are neither kicked nor a
  /// permanent leaver. A grace-evicted player (left_at set, but kicked_at NULL
  /// and left_definitively false) is STILL a participant — they're resuming,
  /// not re-joining. Kicked, permanently-left, and never-participated users are
  /// not, and stay blocked. (Bans are enforced separately by joinRoom's own ban
  /// check — a banned user must not walk back in even if still in player_ids.)
  static bool computeSessionParticipant({
    required List<String> sessionPlayerIds,
    required String userId,
    required bool hasMemberRow,
    required bool isKicked,
    required bool leftDefinitively,
  }) =>
      sessionPlayerIds.contains(userId) &&
      hasMemberRow &&
      !isKicked &&
      !leftDefinitively;

  /// Pure, testable rule for "the room's status is now `closed` — should this
  /// non-owner be removed from the lobby?" A session participant who
  /// RECONNECTED into an already-closed room they belong to is allowed to stay
  /// (they were told to return to it). But if the room CLOSED WHILE THEY WERE
  /// PRESENT ([wasRoomOpenWhileConnected] — the host closed it on them), they
  /// must be removed like everyone else — the reconnect exemption must never
  /// keep a present player in a room the host just closed. The owner is never
  /// removed from their own room.
  static bool shouldRemoveOnRoomClosed({
    required bool isOwner,
    required bool isSessionParticipant,
    required bool wasRoomOpenWhileConnected,
  }) {
    if (isOwner) return false;
    // Genuine reconnect into an already-closed room → keep (view/leave).
    if (isSessionParticipant && !wasRoomOpenWhileConnected) return false;
    return true;
  }

  /// Canonical-identity collapse: `(room_id, user_id)` identifies exactly ONE
  /// logical room member, so a member list may never contain the same user_id
  /// twice — regardless of which entry path (invitation, join request,
  /// reconnect, multiple devices) produced it. This is the client-side
  /// last-line-of-defense for that invariant; the authoritative guarantee is
  /// the room_members (room_id, user_id) UNIQUE constraint plus the atomic
  /// accept_room_invite / joinRoom upserts. Later entries win (a fresh DB row
  /// supersedes a stale one), preserving list order by first appearance. If a
  /// duplicate is ever seen it is logged as DUPLICATE_ROOM_MEMBER — that log
  /// firing means something upstream violated the identity invariant.
  static List<RoomMemberEntity> dedupeMembersByUserId(
    List<RoomMemberEntity> members, {
    String? roomId,
  }) {
    final byUser = <String, RoomMemberEntity>{};
    final order = <String>[];
    for (final m in members) {
      if (!byUser.containsKey(m.userId)) {
        order.add(m.userId);
      } else {
        AppLogger.warning(
          'DUPLICATE_ROOM_MEMBER room=$roomId userId=${m.userId} '
          'source=member_list_merge',
        );
      }
      byUser[m.userId] = m; // later entry wins
    }
    return [for (final id in order) byUser[id]!];
  }

  /// The single canonical "what a viewer is allowed to see" member set.
  /// Moderators/host see everyone (they must, to moderate hidden spectators);
  /// every other viewer never sees hidden spectators at all. Player-facing
  /// screens filter through this rather than re-deriving the rule ad-hoc.
  List<RoomMemberEntity> get visibleMembers =>
      filterVisibleMembers(_members, viewerCanModerate: canModerateRoom);

  /// Spectators a viewer is allowed to see AS ENTRIES. Normal players see only
  /// visible spectators; moderators additionally see hidden ones (so they can
  /// moderate/kick them). Whether a hidden entry's identity is UNMASKED is a
  /// separate axis — see [canRevealHiddenSpectator].
  List<RoomMemberEntity> get visibleSpectators =>
      visibleMembers.where((m) => m.isSpectator).toList();

  /// Whether the CURRENT viewer may unmask a hidden (anonymous) spectator's
  /// real identity (name/avatar/profile). Requires being a moderator AND
  /// Premium Plus. A non-Premium-Plus moderator still sees the (masked) entry
  /// and can kick it; a normal player never sees hidden spectators at all.
  /// [viewerIsPremiumPlus] is supplied by the UI from AuthProvider so this
  /// provider stays auth-free. Moderation (kick/ban) is deliberately NOT gated
  /// by this — only identity visibility is.
  bool canRevealHiddenSpectator({required bool viewerIsPremiumPlus}) =>
      computeCanRevealHiddenSpectator(
        viewerCanModerate: canModerateRoom,
        viewerIsPremiumPlus: viewerIsPremiumPlus,
      );

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

  /// Non-spectator room MEMBERS, regardless of [RoomMemberEntity.
  /// isDisconnected] — deliberately distinct from [eligiblePlayers]. A
  /// player who is merely, momentarily disconnected (a presence blip, the
  /// ordinary few seconds of an app reopening) is still a full room
  /// member — see the room-membership architecture used everywhere else
  /// in this class (`left_at IS NULL`). Only a genuine departure (kicked,
  /// banned, quit, or evicted after the disconnect grace period actually
  /// expires — every one of which removes the row from [_members]
  /// entirely) should ever count against "not enough players to
  /// continue". Root cause of a 2-player room's game ending the instant
  /// the non-owner's presence flipped `isDisconnected: true` on an
  /// ordinary reconnect, with no grace period at all: [_maybeAutoEndGame]
  /// used to count [eligiblePlayers] (which DOES filter out
  /// isDisconnected), so a single transient blip in a 2-player room
  /// dropped the count straight to 1 and ended the game immediately.
  List<RoomMemberEntity> get _presentNonSpectatorMembers =>
      _members.where((m) => !m.isSpectator).toList();

  /// A game can't meaningfully continue with fewer than 2 non-spectator
  /// room members present — unlike [hasNoActivePlayers] (which excludes
  /// the owner from the count, deliberately, since it only exists to
  /// power the "End Game" advisory banner an owner sees about *other*
  /// players), this counts everyone uniformly, because the failure mode
  /// here is symmetric: it must fire whether it's the owner alone with
  /// everyone else gone, only spectators left, or the owner themselves
  /// has disconnected leaving a lone survivor. Called from every path
  /// that mutates [_members] — the reliable DB-reconciliation poll
  /// (_refreshMembers) and the immediate local removal on a kick/ban
  /// broadcast (_removeMember) — so this fires uniformly for every
  /// genuine departure cause (quit, disconnect-timeout-eviction, kick,
  /// ban, room-leave) without each game screen re-deriving player counts
  /// from its own in-memory engine state. Deliberately counts
  /// [_presentNonSpectatorMembers], NOT [eligiblePlayers] — a merely
  /// disconnected-but-still-present member must never trigger this.
  void _maybeAutoEndGame() {
    final status = _room?.status;
    if (status != RoomStatus.inGame && status != RoomStatus.paused) {
      _autoEndTriggered = false;
      return;
    }
    if (_presentNonSpectatorMembers.length >= 2) {
      _autoEndTriggered = false;
      return;
    }
    // Only the owner performs this write — every other still-connected
    // client independently reaches this same branch on its own next poll
    // tick, but must not also broadcast/write, or every one of them would
    // race to do the same close. When the owner themselves is the one
    // who's gone, this is deliberately NOT also a second path to ending
    // the game: that's the pause state machine's job alone (pause -> 60s
    // countdown -> resume or end via _onHostReconnectTimeout, the only
    // other writer of "game over while the owner is absent"). Having two
    // independent triggers race to decide the same outcome is exactly
    // what caused the pause to "disappear by itself" before — whichever
    // one lost the race left its own broadcast/state half-applied against
    // the other's.
    if (_autoEndTriggered || !isOwner) return;
    _autoEndTriggered = true;
    _autoEndGame();
  }

  // RoomProvider is deliberately room-scoped, not session-aware (session
  // identity is the game providers' concern) — but a room-triggered
  // game_ended (auto-end for <2 players, the host-reconnect timeout) still
  // needs to stamp the session it actually applies to, so a stale copy of
  // this event arriving after a fresh game has already started can be
  // told apart from one that actually applies to it. Best-effort: a
  // failed lookup just omits session_id, which every receiving handler
  // already tolerates (never rejects on an unresolved null, only on a
  // confirmed mismatch).
  Future<String?> _currentActiveSessionId(String roomId) async {
    try {
      final row = await _supabase
          .from('game_sessions')
          .select('id')
          .eq('room_id', roomId)
          .eq('status', 'active')
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row?['id'] as String?;
    } catch (e) {
      AppLogger.warning('RoomProvider: _currentActiveSessionId failed: $e');
      return null;
    }
  }

  Future<void> _autoEndGame() async {
    final room = _room;
    if (room == null) return;
    AppLogger.warning(
      'RoomProvider: auto-ending game in room ${room.id} — only '
      '${_presentNonSpectatorMembers.length} non-spectator member(s) remain',
    );
    try {
      // Same convention ToD's original (now-generalized, see
      // tod_game_screen.dart/nhie_game_screen.dart/meme_game_screen.dart's
      // game_ended handlers) all-players-left handling already used:
      // broadcast tells every connected screen to show the "game over"
      // dialog and pop back to the lobby; updateStatus is the actual
      // server-side game-end (mirrors the manual "End Game" button path),
      // returning the room to 'waiting' — the room itself stays open,
      // only the game session ends. session_id lets each game screen
      // reject this if a fresh game has already started and superseded
      // it by the time this arrives (no delivery-order guarantee on
      // Realtime Broadcast) — see each screen's onGameEnded handler.
      final sessionId = await _currentActiveSessionId(room.id);
      await _realtime.broadcastRoomEvent(room.id, {
        'type': 'game_ended',
        'reason': 'not_enough_players',
        'session_id': sessionId,
      });
      if (isOwner) {
        // updateStatus(waiting) now also closes any still-active
        // game_sessions row for this room — see RoomRepository.updateStatus.
        await _repo.updateStatus(room.id, RoomStatus.waiting);
      } else {
        // The designated-closer path (owner themselves is the one who's
        // absent) — rooms/game_sessions both restrict direct UPDATE to
        // the owner via RLS, so this must go through the one RPC allowed
        // to write on a verified-absent owner's behalf instead.
        await _repo.forceEndGameIfOwnerAbsent(room.id);
      }
      _repo.notifyGameEnded(room.id).ignore();
    } catch (e) {
      AppLogger.warning('RoomProvider: _autoEndGame failed: $e');
      // Let the next reconciliation tick retry — this attempt may not have
      // taken effect.
      _autoEndTriggered = false;
    }
  }

  RoomSettingsEntity get settings => _settings;
  List<ChatMessageEntity> get chatMessages => _chatMessages;
  RoomConnectionState get connectionState => _connectionState;
  Failure? get failure => _failure;
  bool get isSendingChat => _isSendingChat;
  bool get isInitialized => _isInitialized;

  bool get isOwner => _room?.ownerId == _currentUserId;
  bool get isConnected => _connectionState == RoomConnectionState.connected;

  /// Batch D keep-game closed marker (rooms.closed_at). Distinct from
  /// `_room.status == RoomStatus.closed` (terminal teardown).
  bool get isRoomClosed => _room?.isClosed ?? false;

  /// Count of "relevant" members — mirrors close_room_keep_game's server-side
  /// rule (room_members with left_at IS NULL AND kicked_at IS NULL). `_members`
  /// already comes from getRoomWithDetails filtered to left_at IS NULL, and a
  /// kicked player's row carries left_at, so it is excluded there too.
  int get relevantMemberCount => _members.length;

  /// Whether the owner may keep-game-close the room right now: owner-only,
  /// not already closed, and strictly more than one relevant member present
  /// (the admin-alone rule). Enforced again server-side by the RPC.
  bool get canCloseRoom => isOwner && !isRoomClosed && relevantMemberCount > 1;

  /// Whether the owner may reopen a keep-game-closed room right now.
  bool get canReopenRoom => isOwner && isRoomClosed;

  bool _isClosingRoom = false;

  /// Keep-game close: hides the room from Browse and blocks new entrants
  /// while the live game and its participants continue untouched. Does NOT
  /// change status, does NOT abort the session, does NOT call the destructive
  /// close_room. Rethrows the repository's typed failure so the UI can show
  /// the reason (e.g. not-enough-members).
  Future<void> closeRoomKeepGame() async {
    if (_room == null || !isOwner || _isClosingRoom) return;
    _isClosingRoom = true;
    AppLogger.info(
      'ROOM_CLOSE keep-game room=${_room!.id} userId=$_currentUserId '
      'sessionId=$_endedSessionId oldStatus=${_room!.status} '
      'newStatus=${_room!.status}(closed_at set)',
    );
    try {
      await _repo.closeRoomKeepGame(_room!.id);
      // Adopt closed locally WITHOUT touching status — the game keeps running.
      _room = _room!.copyWith(closedAt: DateTime.now());
      _safeNotify();
    } finally {
      _isClosingRoom = false;
    }
  }

  /// Reverse of [closeRoomKeepGame]. Clears closed_at server-side so the room
  /// is joinable and browsable again per its normal rules — nothing else
  /// changes (no delete, no new session, no settings/game-data reset).
  Future<void> reopenRoom() async {
    if (_room == null || !isOwner || _isClosingRoom || !isRoomClosed) return;
    _isClosingRoom = true;
    try {
      await _repo.reopenRoom(_room!.id);
      // copyWith can't null a field, so rebuild the entity without closedAt.
      final r = _room!;
      _room = RoomEntity(
        id: r.id,
        ownerId: r.ownerId,
        name: r.name,
        status: r.status,
        visibility: r.visibility,
        maxPlayers: r.maxPlayers,
        currentPlayers: r.currentPlayers,
        inviteCode: r.inviteCode,
        gameType: r.gameType,
        packId: r.packId,
        language: r.language,
        allowSpicy: r.allowSpicy,
        coverEmoji: r.coverEmoji,
        lastActiveAt: r.lastActiveAt,
        createdAt: r.createdAt,
        ownerTransferredAt: r.ownerTransferredAt,
        closedAt: null,
      );
      _safeNotify();
    } finally {
      _isClosingRoom = false;
    }
  }

  // Was a separately-tracked Set<String> that duplicated
  // RoomMemberEntity.isMuted (already correctly kept in sync via CDC/the
  // reconciliation poll — see _refreshMembers/_rowToEntity) and only ever
  // got updated in lockstep with it anyway (see _handleModeration,
  // mutePlayer). The duplicate copy was populated once at initial join and
  // then never resynced on any later member refresh — a missed/undelivered
  // 'mute' broadcast (Realtime Broadcast has no delivery guarantee or
  // replay) left it stale forever for that session, even after the DB row
  // and every other client's view were correctly muted. Reading the
  // already-synced field directly removes the duplicate state entirely.
  bool get isCurrentUserMuted => currentMember?.isMuted ?? false;

  RoomMemberEntity? get currentMember => _members
      .cast<RoomMemberEntity?>()
      .firstWhere((m) => m?.userId == _currentUserId, orElse: () => null);

  /// Looks up any member (not just the current user) by id — e.g. to
  /// resolve the avatar/premium data behind a realtime reaction event,
  /// which only carries the sender's userId to keep the payload small.
  /// Returns null (never throws) for a departed/not-yet-synced member —
  /// callers must render a graceful fallback, not assume a hit.
  RoomMemberEntity? memberById(String userId) => _members
      .cast<RoomMemberEntity?>()
      .firstWhere((m) => m?.userId == userId, orElse: () => null);

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
  bool hasPermission(String key) =>
      currentMember?.hasPermission(key) ?? isOwner;

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

  bool get canApproveSpectators =>
      hasPermission(ModeratorPermission.acceptSpectators);
  bool get canAcceptJoins => hasPermission(ModeratorPermission.acceptJoins);
  bool get canAcceptRejoins => hasPermission(ModeratorPermission.acceptRejoins);
  bool get canKickPlayers => hasPermission(ModeratorPermission.kickPlayers);
  bool get canMuteChat => hasPermission(ModeratorPermission.muteChat);
  bool get canMutePlayers => hasPermission(ModeratorPermission.mutePlayers);
  bool get canAdvanceTurn => hasPermission(ModeratorPermission.advanceTurn);
  bool get canSkipTurn => hasPermission(ModeratorPermission.skipTurn);
  bool get canManageSettings =>
      hasPermission(ModeratorPermission.manageSettings);
  bool get canEndGame => hasPermission(ModeratorPermission.endGame);
  bool get canStartGame => hasPermission(ModeratorPermission.startGame);
  bool get canSetSpectator => hasPermission(ModeratorPermission.setSpectator);

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
          _realtime.broadcastGameEnded(roomId, {
            'reason': 'host_reconnected',
          }).ignore();
        } else if (recovery?['resumed'] == true) {
          // Host reconnected within the 60s window — recover_owner_room
          // already flipped rooms.status back to in_game itself; tell
          // every other client immediately instead of waiting for their
          // own next reconciliation poll to notice.
          AppLogger.info(
            'RoomProvider: resumed a paused game for returning host in '
            'room $roomId',
          );
          _realtime.broadcastRoomEvent(roomId, {'type': 'resume'}).ignore();
        }
      } catch (e) {
        AppLogger.warning('RoomProvider: recoverOwnerRoom failed: $e');
      }

      final approvalInfo = await _repo.getRoomApprovalInfo(roomId);

      // Batch D closed-room entry gate: a keep-game-closed room admits no new
      // entrants. The owner may always re-enter to manage it; everyone else
      // is admitted ONLY if they are a genuine active-session participant
      // (in game_sessions.player_ids, authoritative) AND still an active
      // member (left_at IS NULL) — i.e. an active player reconnecting. That
      // deliberately turns away lobby-only players, new joiners, kicked
      // players (left_at set), and long-gone players, with no join, no
      // rejoin request, and no "waiting for acceptance" screen. Runs before
      // every join/rejoin branch below so none of them fire for a closed
      // room. (The server enforces the same via RLS + the reactivation
      // trigger + request_game_rejoin's own closed check — this is the clean
      // client-side UX, not the security boundary.)
      // Batch C/D reconnect classification. The AUTHORITATIVE "am I currently
      // playing this game" signal is game_sessions.player_ids — NOT room
      // membership. An ACTIVE participant reconnecting is RESUMING, not
      // arriving: they must bypass BOTH the closed-room gate AND the
      // arrivedMidGame rejoin-approval routing below, and must never be
      // marked is_away. "Active participant" = in the current session's
      // player_ids AND not kicked AND not a permanent leaver (a grace-evicted
      // player whose row carries left_at but neither kicked_at nor
      // left_definitively is still resuming). Owners are handled by their own
      // reconnect path and are excluded here.
      var isActiveParticipant = false;
      // Broader than isActiveParticipant: a participant of the room's MOST
      // RECENT session whatever its status (active/paused/completed/aborted).
      // player_ids is frozen for the session's life, so a game that just ended
      // still lists everyone who played it. This is the authoritative "was I a
      // real participant of this room's game" signal — used to let such a
      // player RETURN to the room lobby after the game ends without being
      // treated as a brand-new entrant (see the closed-room gate below). Still
      // excludes the kicked and permanent leavers.
      var isSessionParticipant = false;
      if (approvalInfo != null && approvalInfo.ownerId != _currentUserId) {
        try {
          // The room's latest session, any status. (Was filtered to
          // active/paused, which is correct for a LIVE resume but wrongly
          // reports "not a participant" the instant the game finishes — the
          // moment this gate matters most for a player pressing "Back to
          // Room" on the results screen.) The active/paused distinction is
          // re-derived from the returned status below.
          final sessionRow = await _supabase
              .from('game_sessions')
              .select('player_ids, status')
              .eq('room_id', roomId)
              .order('started_at', ascending: false)
              .limit(1)
              .maybeSingle();
          final playerIds =
              (sessionRow?['player_ids'] as List?)?.cast<String>() ??
              const <String>[];
          final sessionStatus = sessionRow?['status'] as String?;
          if (playerIds.contains(_currentUserId)) {
            // Exclude the kicked and permanent leavers; a merely disconnected/
            // grace-evicted player (kicked_at NULL, left_definitively false) is
            // still a legitimate participant.
            final myRow = await _supabase
                .from('room_members')
                .select('kicked_at, left_definitively')
                .eq('room_id', roomId)
                .eq('user_id', _currentUserId)
                .maybeSingle();
            final eligible = computeSessionParticipant(
              sessionPlayerIds: playerIds,
              userId: _currentUserId,
              hasMemberRow: myRow != null,
              isKicked: myRow?['kicked_at'] != null,
              leftDefinitively: myRow?['left_definitively'] == true,
            );
            isSessionParticipant = eligible;
            // Only a still-LIVE session is a RESUME that must also bypass the
            // arrivedMidGame rejoin routing and clear is_away below.
            isActiveParticipant =
                eligible &&
                (sessionStatus == 'active' || sessionStatus == 'paused');
          }
        } catch (e) {
          AppLogger.warning(
            'RoomProvider: active-participant check failed: $e',
          );
        }
        if (isActiveParticipant) {
          // Resuming — clear any stale is_away (left over from a disconnect or
          // a prior arrivedMidGame self-mark) so the owner's game engine
          // re-includes this player as an active turn-taker immediately,
          // instead of leaving the admin seeing them stuck as away/gone. Only
          // toggles is_away; never touches left_at, so the reactivation
          // trigger stays out of the way even in a closed room.
          _repo.setMemberAway(roomId, _currentUserId, away: false).catchError((
            e,
          ) {
            AppLogger.warning('RoomProvider: resume is_away clear failed: $e');
          });
        }
      }

      // Publish the authoritative participant verdict so UI (the lobby's own
      // closed-room bounce) can grant the same exemption this gate does.
      _isSessionParticipant = isSessionParticipant;

      // Batch D closed-room entry gate: turn away non-owner NON-participants
      // (lobby-only, new joiners, kicked/left, long-gone). A genuine
      // participant is NEVER blocked — closed_at must not stop them resuming an
      // in-progress game NOR returning to the lobby right after it ends (the
      // post-game "Back to Room" flow). Keyed off isSessionParticipant (the
      // room's most-recent session's frozen player_ids), NOT isActiveParticipant
      // — the latter goes false the instant the session completes, which is
      // exactly when a valid player is pressing "Back to Room" and would
      // otherwise be wrongly bounced out of their own closed room. Server still
      // enforces the real boundary via RLS + the reactivation trigger +
      // request_game_rejoin's own closed check; this is only the client UX.
      if (approvalInfo != null &&
          approvalInfo.ownerId != _currentUserId &&
          !isSessionParticipant) {
        try {
          final closedRow = await _supabase
              .from('rooms')
              .select('closed_at')
              .eq('id', roomId)
              .maybeSingle();
          if (closedRow?['closed_at'] != null) {
            AppLogger.info(
              'RoomProvider: room $roomId is closed — turning away '
              'non-participant $_currentUserId',
            );
            _failure = const ServerFailure(
              message: 'This room has been closed by the host.',
            );
            _setConnection(RoomConnectionState.failed);
            return;
          }
        } catch (e) {
          AppLogger.warning('RoomProvider: closed-room gate check failed: $e');
        }
      }
      // The exact, one-time signal for "did I just now arrive at an
      // already-running game, or was I already here (in the lobby) when
      // it started" — computed ONCE, from the room's actual status at the
      // moment this RoomProvider first initializes, before any join/
      // rejoin decision below runs. This is what lobby_screen.dart's
      // _syncGameRoute and _RejoinBanner key off to enforce "never
      // automatically re-enter a normal player" — even one whose
      // room_members row happens to still be intact (a weak disconnect
      // presence never caught, a brief background) must go through
      // explicit admin/mod approval now, with no exception for row
      // intactness. Owners are exempt — their own separate host-
      // reconnect-pause mechanism governs their reconnect instead, and
      // never consults this flag. An ACTIVE participant (isActiveParticipant,
      // computed above from the authoritative game_sessions.player_ids) is
      // RESUMING their own in-progress game, not "arriving" — they must never
      // set arrivedMidGame (which would route them into rejoin-approval and
      // block _syncGameRoute) and must never be self-marked is_away (which
      // would make the owner's game engine treat them as gone). Only a
      // non-participant returning mid-game goes through this Batch C path.
      if (approvalInfo != null &&
          approvalInfo.ownerId != _currentUserId &&
          !isActiveParticipant) {
        try {
          final statusRow = await _supabase
              .from('rooms')
              .select('status')
              .eq('id', roomId)
              .maybeSingle();
          _arrivedMidGame = const {
            'in_game',
            'paused',
          }.contains(statusRow?['status']);
          if (_arrivedMidGame) {
            // This is the piece that actually makes arrivedMidGame mean
            // something to the OWNER's game engine, not just to this
            // client's own navigation gate: is_away is the pre-existing,
            // already-correct signal every game's turn-eligibility
            // exclusion (_durableAwayIds, identical across all 3 games)
            // already keys off. Without this, a returning player with an
            // intact room_members row was invisible to that exclusion —
            // the instant their presence reconnected they became fully
            // turn-eligible again, regardless of whether they'd ever been
            // approved back in. decide_game_rejoin_request's approval path
            // already clears is_away, which is what makes them eligible
            // again once actually accepted — never before.
            _repo.setMemberAway(roomId, _currentUserId, away: true).catchError((
              e,
            ) {
              AppLogger.warning(
                'RoomProvider: arrivedMidGame self is_away mark failed: $e',
              );
            });
          }
        } catch (e) {
          AppLogger.warning('RoomProvider: arrivedMidGame check failed: $e');
        }
      }
      // Set when this client entered through the atomic invite-acceptance RPC,
      // which already created/reused the single membership AND reconciled any
      // pending join request. It suppresses the redundant shared joinRoom()
      // upsert further below so entry stays exactly one authoritative write.
      var enteredViaInvite = false;
      if (approvalInfo != null &&
          approvalInfo.requiresApproval &&
          approvalInfo.ownerId != _currentUserId) {
        // ROOT CAUSE of "accepted NHIE/Meme player reconnects into an
        // ongoing game and sees pending-approval instead": this gate used
        // isActiveMember alone, which requires left_at IS NULL — but a
        // player who closed the app mid-game has their room_members row
        // soft-evicted (left_at set) by the disconnect grace period even
        // though they're still a live, accepted participant of the
        // room's ongoing session. isActiveMember then read false, so this
        // gate filed a BRAND-NEW join request and routed them into
        // pendingApproval — even though the admin's member list still
        // showed them with normal Mute/Kick/Ban controls (their row was
        // never actually removed). isActiveParticipant (computed above
        // from game_sessions.player_ids via computeSessionParticipant,
        // already excluding kicked/left_definitively) is the correct,
        // pre-existing signal for exactly this — the same one the
        // arrivedMidGame gate already trusts. Mirrors the two sibling
        // approval gates just below, which already use the equivalent
        // hasPriorMembership for their own version of this same gap.
        final alreadyMember =
            isActiveParticipant ||
            await _repo.isActiveMember(userId: _currentUserId, roomId: roomId);
        if (!alreadyMember) {
          final invited = await _repo.hasValidInvite(
            userId: _currentUserId,
            roomId: roomId,
          );
          if (invited) {
            // Authoritative atomic reconciliation: one RPC validates the
            // invite (invited_user == auth.uid()), reuses-or-creates the
            // single membership, and marks any pending join request for the
            // SAME user_id as approved — so a user who both requested access
            // and was invited ends up as exactly ONE member with NO lingering
            // pending request, never two room identities. Previously this only
            // marked the invite accepted and left the request pending.
            final membershipId = await _repo.acceptRoomInvite(roomId: roomId);
            enteredViaInvite = true;
            AppLogger.info(
              'INVITE_RECONCILE room=$roomId user=$_currentUserId '
              'membershipId=$membershipId requestResolved=server '
              'source=invite_accept_rpc',
            );
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
          // 'paused' must gate identically to 'in_game' — it's still a
          // real, ongoing game session (just temporarily halted, e.g. for
          // a disconnect grace period), not a fresh 'waiting' lobby a
          // stranger can walk into. Matches the isMidGame gate further
          // below, which already covers both.
          final isInProgress = const {
            'in_game',
            'paused',
          }.contains(roomRow?['status']);
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
        // Same 'paused' gap as the spectator gate above.
        final isMidGameForPlayerGate = const {
          'in_game',
          'paused',
        }.contains(roomRow?['status']);
        if (isMidGameForPlayerGate) {
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
      // isActiveParticipant (authoritative game_sessions.player_ids, computed
      // above) short-circuits the entire returning-player detour: a resuming
      // active player must ALWAYS take the joinRoom path below so their
      // membership is restored (left_at cleared) and they re-enter the same
      // session — never deferred to rejoin-approval, even if a grace timeout
      // had set their left_at. Only a genuine non-participant returning
      // mid-game is routed through the Batch C rejoin flow.
      var skipAutoJoin = false;
      if (normalizedRole != 'spectator' && !isActiveParticipant) {
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
        // Auto-file the rejoin request so the admin's pending-requests panel
        // lights up immediately and this client can go straight to the
        // "waiting for acceptance" screen — instead of the returning player
        // having to first find and tap a "Request to rejoin" banner. The
        // _RejoinBanner/_RejoinWaitingView poll still owns the approval
        // transition; this only pre-files. Swallow "already pending / already
        // in room" — a re-init while a request is outstanding is expected.
        try {
          await _repo.requestGameRejoin(roomId);
        } on ConflictFailure {
          // already_pending / already_in_room — nothing to do.
        } catch (e) {
          AppLogger.warning('RoomProvider: auto rejoin-request failed: $e');
        }
      } else if (enteredViaInvite) {
        // Membership was already created/reused atomically by
        // accept_room_invite (which also reconciled any pending request) — the
        // shared joinRoom() upsert here would be a redundant second write that
        // could reset seat/role, so skip it. Entry stays exactly one
        // authoritative membership for this user_id.
        AppLogger.debug(
          'RoomProvider: entry via invite RPC — skipping redundant joinRoom',
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
            // A verified participant of this room's current/most-recent session
            // (authoritative game_sessions.player_ids, not kicked/left — see
            // isSessionParticipant above) is RETURNING to a host-closed room,
            // not joining fresh: joinRoom must reactivate their membership
            // instead of throwing "This room has been closed by the host."
            // Kicked/banned/permanent-leavers/non-participants have
            // isSessionParticipant=false and are still blocked (both by the
            // closed-room gate above and by joinRoom's own ban check).
            isReturningParticipant: isSessionParticipant,
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

      for (int attempt = 0; attempt < 5; attempt++) {
        if (attempt > 0)
          await Future.delayed(const Duration(milliseconds: 300));
        try {
          final result = await _repo.getRoomWithDetails(roomId);
          room = result.$1;
          members = result.$2;
          settings = result.$3;
          AppLogger.debug(
            'RoomProvider: attempt $attempt — members=\${members.length}',
          );
          if (members.isNotEmpty) break;
        } on NotFoundFailure {
          // A single 0-row PGRST116 here does not prove the room is gone
          // (see _refreshMembers' identical reasoning) — this is exactly
          // where it's most likely to strike: the very first fetch right
          // after a reconnect, before this client's own RLS visibility
          // (is_room_member / current-session-participant) has settled.
          // Previously this propagated straight to initialize()'s outer
          // catch on the very first attempt, permanently failing the
          // connection instead of giving it the same retry budget every
          // other transient failure here already gets.
          AppLogger.warning(
            'RoomProvider: getRoomWithDetails 0-rows on attempt $attempt '
            'for room $roomId — retrying',
          );
          if (attempt == 4) rethrow;
        }
      }

      _room = room;
      _members = members.isNotEmpty
          ? dedupeMembersByUserId(members, roomId: roomId)
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
        // Live honesty_points/general_score in the lobby (and, via
        // members, in every game screen that reads roomProvider.members —
        // ToD already does). Realtime postgres_changes filters only
        // support a single-column equality (confirmed elsewhere in this
        // codebase), so this can't be scoped to "id IN (current member
        // ids)" — left unfiltered and simply re-runs the same
        // _refreshMembers(roomId) full re-fetch already wired above for
        // room_members changes. Rooms are small, so re-fetching on any
        // profile update (even one for a user not currently in this room)
        // is cheap; this is the SAME single mechanism both event sources
        // feed, not a second/competing refresh path.
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          callback: (_) => _refreshMembers(roomId),
        )
        .subscribe();

    _targetedChatCdcChannel?.unsubscribe();
    _targetedChatCdcChannel = _supabase
        .channel('room_chat_cdc:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'room_chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) =>
              _handleTargetedChatCdcInsert(payload.newRecord),
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
    // correct it. Keep a lighter periodic re-fetch running for as long as
    // the room stays in_game/paused — this is also the single tick that
    // drives owner-heartbeat-staleness detection (see
    // _checkOwnerHeartbeatStaleness), replacing presence-diffing as the
    // owner-pause trigger: Realtime Presence's own disconnect detection on
    // the SERVER has no bound (a force-quit or dropped connection is only
    // noticed once the server's own keepalive times out, which can take
    // well over a minute) — a bounded poll against the heartbeat this
    // client writes every _heartbeatInterval is the only way to guarantee
    // a fixed worst-case pause-detection latency.
    _gameReconcileTimer?.cancel();
    _gameReconcileTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final status = _room?.status;
      if (status == RoomStatus.inGame) {
        _checkOwnerHeartbeatStaleness();
      }
      if (status == RoomStatus.inGame ||
          status == RoomStatus.paused ||
          status == RoomStatus.starting) {
        _refreshMembers(_room!.id);
        _refreshPendingRejoinUserIds(_room!.id);
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
          // If we (the owner) were offline when the room got paused for our
          // "disconnect" and are now back and healthy, resume rather than
          // stay stuck on our own host-away overlay. No-op for non-owners.
          _maybeOwnerSelfResumeFromPause().ignore();
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
    // VISIBILITY vs LIVENESS — these are two different things and must not be
    // conflated. A hidden spectator must stay INVISIBLE, so it is never tracked
    // in the Realtime Presence channel (every client can read that channel — a
    // presence entry would leak its identity). But Presence is NOT the liveness
    // authority; the server-side heartbeat (`room_members.last_seen_at`, written
    // by _touchPresence/_startHeartbeat) is. A hidden spectator MUST still write
    // that heartbeat like any other member — otherwise it looks permanently
    // "absent from presence" to every other client, which then evicts it after
    // the disconnect grace period. Skipping the heartbeat here (the old
    // `isHiddenSpectator == true → return`) was the root cause of the ~1–2 min
    // auto-removal. Only the presence track is conditional now.
    if (currentMember?.isHiddenSpectator != true) {
      await _realtime.trackPresence(_room!.id, {
        PresenceKey.userId: _currentUserId,
        PresenceKey.displayName: _currentDisplayName,
        PresenceKey.avatarUrl: _currentAvatarUrl,
        PresenceKey.seatOrder: seatOrder,
        PresenceKey.isReady: currentMember?.isReady ?? false,
        PresenceKey.joinedAt: DateTime.now().toIso8601String(),
      });
    }
    _touchPresence();
    _startHeartbeat();
  }

  Timer? _heartbeatTimer;

  // Single source of truth for "is the owner still connected", consumed by
  // ownerHeartbeatStaleThreshold below (and by every SQL-side staleness
  // check that mirrors this same interval: claim_room_ownership,
  // force_end_game_if_owner_absent). Must stay a small multiple of this —
  // never equal to it — so a perfectly healthy connection between two
  // writes is never seen as stale.
  static const _heartbeatInterval = Duration(seconds: 10);

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      _heartbeatInterval,
      (_) => _touchPresence(),
    );
  }

  void _touchPresence() {
    if (_room == null) return;
    _repo.touchPresence(_room!.id).ignore();
  }

  // _refreshMembers is called from many independent, unsynchronized
  // triggers (the 20s periodic timer, presence/CDC events, channel
  // reconnect) — nothing previously stopped two overlapping calls from
  // resolving OUT OF ORDER. A slow request issued right before a game
  // started (still reading status='waiting') could resolve AFTER a
  // faster, later request that already correctly saw 'in_game', silently
  // regressing _room.status back to 'waiting'. That regression is exactly
  // what caused two symptoms that looked unrelated but shared one root
  // cause: (1) LobbyScreen._onRoomStateChanged resets _navigatedToGame the
  // instant it sees 'waiting', so the very next correct poll re-triggers
  // _navigateOwnerToGame and pushes a SECOND game route on top of the
  // first, still-live one ("two game instances"); (2) a stale, out-of-
  // order response can just as easily carry a transiently-empty member
  // list, firing _handleSelfNoLongerMember for a user who was never
  // actually removed ("players unexpectedly removed from the room"). A
  // monotonic sequence number discards any response superseded by a
  // newer request before it resolves, the standard fix for out-of-order
  // async responses.
  int _refreshMembersSeq = 0;

  Future<void> _refreshMembers(String roomId) async {
    final mySeq = ++_refreshMembersSeq;
    try {
      final (freshRoom, freshMembers, _) = await _repo.getRoomWithDetails(
        roomId,
      );
      if (mySeq != _refreshMembersSeq) return;
      // A successful fetch is proof the room IS currently visible to us —
      // clears any streak of prior PGRST116s so a single transient blip
      // (see the NotFoundFailure branch below) never accumulates across
      // otherwise-healthy polls.
      _consecutiveRoomNotFoundCount = 0;
      // getRoomWithDetails already filters left_at IS NULL server-side (see
      // RoomRepository), so a kicked/banned/left row simply isn't in
      // freshMembers at all — checked BEFORE the isEmpty early-return below
      // so the fallback still fires even in the edge case where the
      // current user was the only member and the room is now empty.
      final wasMember = _members.any((m) => m.userId == _currentUserId);
      if (freshMembers.isEmpty) {
        if (wasMember) _handleSelfNoLongerMember();
        return;
      }
      _members = dedupeMembersByUserId(freshMembers, roomId: roomId);
      // Previously discarded the freshly-fetched room row and only applied
      // members — so a client whose ownership had been silently reassigned
      // (automatic failover, 0d) while it was disconnected never picked up
      // the new owner_id on reconnect, even though this same call already
      // re-fetched it. isOwner (_room.ownerId == me) stayed stale-true,
      // so pressing "Close Room" issued an RLS-gated update that silently
      // matched 0 rows — no error, room just never closed.
      if (_room != null && _room!.id == freshRoom.id) {
        final prevStatus = _room!.status;
        // POST-GAME-END stale-status suppression (durable, session-authoritative).
        // The game this client just finished has ended, but rooms.status is
        // owner-gated and may still lag at in_game/starting/paused — a non-owner
        // can't and must not write it (that's the owner/server's job). Never
        // re-adopt that stale status: it would re-raise _GameStartingLock
        // ("Preparing the game…"), which is exactly the bug this guards. Hold
        // the lobby until the backend authoritatively converges (rooms.status
        // becomes waiting/ended) OR a genuinely NEW game (a DIFFERENT live
        // game_sessions row) begins. "New vs stale tail" is decided against the
        // authoritative game_sessions row this client just left
        // (_endedSessionId), never against the owner-gated rooms.status — so
        // this converges correctly no matter how slowly the owner writes
        // waiting, and can never get permanently stuck out of a real new game.
        if (_endedReturnPending) {
          if (freshRoom.status == RoomStatus.waiting ||
              freshRoom.status == RoomStatus.ended) {
            // Backend converged — release and adopt normally below.
            _endedReturnPending = false;
            _endedSessionId = null;
          } else if (freshRoom.status == RoomStatus.starting) {
            // 'starting' is UNAMBIGUOUS: it is only ever written by a fresh
            // Start Game press (updateStatus('starting') in _doStartGame) — a
            // finished game's stale tail is 'in_game', never 'starting'. So a
            // DB status of 'starting' always means a genuinely NEW game, even
            // before create_game_session has produced a queryable session row.
            // Releasing here (instead of consulting _latestLiveSessionId, which
            // returns null during that pre-session 'starting' window and would
            // wrongly force this client's status back to 'waiting') is what
            // stops a player who MISSED the game_started broadcast from being
            // pinned in the lobby while everyone else enters the game.
            _endedReturnPending = false;
            _endedSessionId = null;
          } else {
            // in_game / paused in the DB. Stale tail of the game we already
            // left, or a brand-new game?
            final liveId = await _latestLiveSessionId(freshRoom.id);
            if (mySeq != _refreshMembersSeq) return;
            final isNewGame = liveId != null && liveId != _endedSessionId;
            if (!isNewGame) {
              // Stale tail (our finished session lingering, or nothing live) —
              // keep showing the normal lobby. Members were already adopted
              // above; hold status at waiting. Late-capture the session id if
              // onReturnedFromGameRoute couldn't, so subsequent cycles stay
              // race-free.
              _endedSessionId ??= liveId;
              _room = freshRoom.copyWith(status: RoomStatus.waiting);
              _safeNotify();
              return;
            }
            // A different, genuinely-live session — a NEW game. Release and let
            // it be adopted below so _syncGameRoute can enter it.
            _endedReturnPending = false;
            _endedSessionId = null;
          }
        }
        // Adopt fresh DB truth FIRST so the host-reconnect countdown below
        // is derived from the NEW room state (its real pause timestamp /
        // status), not the stale pre-transition one. Reading
        // hostReconnectRemaining while _room was still the old (not-yet-
        // paused) room returned zero and armed a full fresh window,
        // desyncing the real timeout timer from the displayed countdown.
        _room = freshRoom;
        // Safety net for a missed 'pause'/'resume' broadcast (Realtime
        // Broadcast has no delivery guarantee or replay) — this
        // reconciliation poll independently re-derives DB truth every
        // cycle, same convention as every other moderation fallback here.
        if (prevStatus == RoomStatus.paused &&
            freshRoom.status != RoomStatus.paused) {
          _cancelHostReconnectCountdown();
        } else if (prevStatus != RoomStatus.paused &&
            freshRoom.status == RoomStatus.paused) {
          _startHostReconnectCountdown();
        }
        // Startup grace, reconcile-observed (covers a client that flipped
        // starting -> in_game via this poll rather than the
        // game_session_ready broadcast). Mirror of _handleGameSessionReady:
        // arm on the transition into in_game, clear on any transition out
        // of the in_game/starting handoff so a stale value can't linger.
        if (prevStatus == RoomStatus.starting &&
            freshRoom.status == RoomStatus.inGame) {
          _inGameSince = DateTime.now();
        } else if (freshRoom.status != RoomStatus.inGame &&
            freshRoom.status != RoomStatus.starting) {
          _inGameSince = null;
        }
        // Owner self-resume, driven off EVERY reconcile observation of a
        // paused room (not just the transition into paused). This is what
        // makes owner reconnect deterministic: the 5s reconcile is already
        // running, so as long as the room stays paused the owner keeps
        // attempting the (idempotent, heartbeat-gated) resume until it
        // succeeds — instead of the single transition-only attempt, which
        // could fire at the exact instant the owner's connectivity wasn't
        // ready yet and then never retry (leaving admin + players stuck on
        // Admin Away after the admin genuinely came back). No-op for
        // non-owners and for an already-resumed room — see
        // _maybeOwnerSelfResumeFromPause. Not a new timer; reuses the
        // existing reconcile tick.
        if (freshRoom.status == RoomStatus.paused && isOwner) {
          AppLogger.info(
            'OWNER_RESUME trigger=refreshMembers room=${freshRoom.id} '
            'prevStatus=$prevStatus dbStatus=${freshRoom.status}',
          );
          _maybeOwnerSelfResumeFromPause().ignore();
        }
      }
      // Fallback path for a kick/ban (or any other removal, e.g.
      // cleanupJob.js's server-only stale-room/expired-ban sweep) whose
      // moderation broadcast was missed or never sent — Realtime Broadcast
      // has no delivery guarantee or replay, but this reconciliation poll
      // (see _gameReconcileTimer) independently re-derives DB truth every
      // cycle, so it's what guarantees the same teardown eventually
      // happens even when the primary, near-instant broadcast signal
      // doesn't arrive. The primary kicked/banned events (_handleModeration)
      // still fire immediately when the broadcast does arrive — this only
      // ever fires in addition, as a safety net, never instead.
      final isStillMember = freshMembers.any((m) => m.userId == _currentUserId);
      if (wasMember && !isStillMember) _handleSelfNoLongerMember();
      // Every departure path (kick, ban, disconnect timeout, explicit
      // leave, or a purely server-side sweep like cleanupJob.js that never
      // broadcasts at all) eventually surfaces here, since this re-derives
      // DB truth directly rather than reacting to any one specific
      // broadcast — see _maybeAutoEndGame.
      _maybeAutoEndGame();
      _safeNotify();
      AppLogger.debug('RoomProvider: refreshed members=${_members.length}');
    } on NotFoundFailure {
      if (mySeq != _refreshMembersSeq) return;
      // getRoomWithDetails' room fetch uses .single() — PGRST116/0-rows
      // means only that THIS particular query returned no visible row, not
      // that the room is definitively gone. It can legitimately happen for
      // a room that still exists: "rooms: read" RLS requires
      // is_room_member() (or a current-session-participant carve-out, or a
      // public/invite branch) — a room-membership state that can be
      // mid-transition (e.g. a just-evicted, not-yet-rejoin-approved
      // member briefly has no matching branch) without the room itself
      // having been deleted. Treating a single 0-row result as conclusive
      // was the actual root cause of "stuck loading then bounced to lobby
      // in a loop": one transient/edge-case PGRST116 fired a permanent
      // fallback 'roomClosed' event, indistinguishable from a real
      // deletion. Require the SAME persistent absence across consecutive,
      // independent 5s-apart reconciliation ticks before concluding the
      // room is actually gone — a real deletion stays 0-rows on every
      // subsequent poll; a transient/edge-case visibility gap does not.
      _consecutiveRoomNotFoundCount++;
      if (_consecutiveRoomNotFoundCount >= 2) {
        _handleRoomNoLongerExists();
      } else {
        AppLogger.warning(
          'RoomProvider: getRoomWithDetails returned 0 rows for room '
          '$roomId (streak=$_consecutiveRoomNotFoundCount) — not yet '
          'treating as a genuine deletion.',
        );
      }
    } catch (e) {
      AppLogger.warning('RoomProvider: _refreshMembers failed: $e');
    }
  }

  int _consecutiveRoomNotFoundCount = 0;

  bool _roomGoneHandled = false;

  void _handleRoomNoLongerExists() {
    if (_roomGoneHandled) return;
    _roomGoneHandled = true;
    AppLogger.warning(
      'RoomProvider: reconciliation found room ${_room?.id} no longer '
      'exists — firing fallback roomClosed event.',
    );
    if (_room != null) {
      _room = _room!.copyWith(status: RoomStatus.closed);
    }
    _lifecycleCtrl.add(RoomLifecycleEvent.roomClosed);
  }

  bool _selfRemovalHandled = false;

  void _handleSelfNoLongerMember() {
    // Latched, not reset — once detected, every subsequent poll tick would
    // otherwise keep re-firing the same event for as long as this
    // RoomProvider instance stays alive (e.g. while the lifecycle-event
    // listener's own navigation is still in flight).
    if (_selfRemovalHandled) return;
    _selfRemovalHandled = true;
    AppLogger.warning(
      'RoomProvider: reconciliation detected self is no longer a room '
      'member (roomId=${_room?.id}) — moderation broadcast was likely '
      'missed. Firing fallback removal event.',
    );
    _lifecycleCtrl.add(RoomLifecycleEvent.removed);
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

    // Decide who (if anyone) has now been absent from presence across two
    // consecutive syncs and should have their removal grace period armed. The
    // decision — including the hidden-spectator exemption and the two-sync
    // debounce — lives in the pure static `membersToGraceArm` so it is unit
    // testable in isolation and can never silently drift from a parallel copy.
    // `membersToGraceArm` also mutates `_pendingAbsence` to the new pending set.
    final toArm = membersToGraceArm(
      members: _members,
      onlineIds: onlineIds,
      pendingAbsence: _pendingAbsence,
    );
    for (final userId in toArm) {
      _startGracePeriod(userId);
      changed = true;
    }

    // Reconnect handling stays here because it mutates member state: a member
    // seen online again clears any disconnected flag / running grace timer.
    // Hidden spectators are skipped for the same reason as in the arm decision
    // (they are never tracked, so their online/offline state is meaningless).
    for (final member in _members) {
      if (member.isHiddenSpectator) continue;
      if (onlineIds.contains(member.userId) && member.isDisconnected) {
        _cancelGracePeriod(member.userId);
        _updateMember(member.userId, (m) => m.copyWith(isDisconnected: false));
        changed = true;
      }
    }

    if (changed) _safeNotify();
  }

  final Set<String> _pendingAbsence = {};

  /// Pure model of one presence-sync pass's automatic-eviction decision,
  /// extracted so the hidden-spectator invariant is directly testable without a
  /// live realtime channel. Returns the set of member IDs whose removal grace
  /// period should be armed on THIS sync, and mutates [pendingAbsence] to the
  /// new pending-absent set for the next sync.
  ///
  /// Rules (all load-bearing):
  ///  - A hidden spectator is DELIBERATELY never tracked in the presence
  ///    channel (to stay invisible), so its absence from [onlineIds] carries no
  ///    liveness information and must NEVER arm eviction. Visibility must never
  ///    participate in membership validity. Its liveness is governed solely by
  ///    the server heartbeat (last_seen_at). This is the root-cause fix.
  ///  - A member already flagged disconnected (grace already running) is left
  ///    untouched here — its fate is decided by the grace timer / heartbeat
  ///    re-check, not by re-running this decision.
  ///  - A newly-absent member is armed only after being absent across TWO
  ///    consecutive syncs (debounce), because a channel resubscribe transiently
  ///    shows still-connected members as absent for a single sync. One missed
  ///    sync must never cause a real `left_at` DB write.
  static Set<String> membersToGraceArm({
    required List<RoomMemberEntity> members,
    required Set<String> onlineIds,
    required Set<String> pendingAbsence,
  }) {
    final toArm = <String>{};
    for (final member in members) {
      if (member.isHiddenSpectator) continue;
      final isOnline = onlineIds.contains(member.userId);
      if (!isOnline && !member.isDisconnected) {
        if (pendingAbsence.add(member.userId)) continue; // first miss: debounce
        pendingAbsence.remove(member.userId);
        toArm.add(member.userId);
      } else if (isOnline) {
        pendingAbsence.remove(member.userId);
      }
    }
    return toArm;
  }

  void _startGracePeriod(String userId) {
    // Diagnostic: every automatic eviction begins here. Logs exactly WHO is
    // being put on the removal path and WHY, so a spurious removal can be
    // traced to its source (a hidden spectator must never appear here — the
    // isHiddenSpectator skip in _handlePresenceSync guarantees it).
    final m = _members.where((x) => x.userId == userId).firstOrNull;
    AppLogger.info(
      'MEMBER_EVICTION grace-armed room=${_room?.id} user=$userId '
      'isSpectator=${m?.isSpectator} isHidden=${m?.isHiddenSpectator} '
      'isOwner=${m?.isOwner} reason=absent_from_presence',
    );
    _updateMember(userId, (m) => m.copyWith(isDisconnected: true));
    _disconnectedTimers[userId]?.cancel();
    _disconnectedTimers[userId] = Timer(
      const Duration(seconds: 30),
      () => _confirmAndRemoveMember(userId),
    );
    // Deliberately does NOT trigger owner-pause here — presence's own
    // server-side disconnect detection has no bound (see
    // _checkOwnerHeartbeatStaleness's doc comment), so it must not be a
    // second path into pausing alongside the bounded heartbeat watchdog.
    // One detection signal, one trigger: the 5s reconcile tick.
    // eligiblePlayers excludes isDisconnected members, so it already
    // reflects this departure immediately — but _maybeAutoEndGame was
    // previously only re-checked once the FULL 30s grace period elapsed
    // and _confirmAndRemoveMember ran (or the next up-to-20s poll tick),
    // "freezing" a 1-real-player game for up to 30+ seconds before it
    // actually ended. Re-check right away instead of waiting for the
    // eventual permanent removal to trigger it.
    _maybeAutoEndGame();
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
      lastSeen = await _repo.getMemberLastSeen(roomId: room.id, userId: userId);
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
      final midGame =
          room.status == RoomStatus.inGame ||
          room.status == RoomStatus.paused ||
          room.status == RoomStatus.starting;
      if (midGame) {
        // Never transfer ownership mid-game — handing an active session to
        // a different client silently reassigned who was authoritative for
        // the engine, which is exactly the class of bug the whole
        // session-lifecycle rework has been fixing. Nothing to do here:
        // pausing is entirely owned by _checkOwnerHeartbeatStaleness (the
        // 5s reconcile tick's bounded heartbeat check) — this presence-
        // driven confirmation path must not ALSO trigger it, or the two
        // independent triggers race to decide the same outcome, which is
        // exactly what caused the pause to behave nondeterministically
        // before (one path's broadcast/write landing over the other's).
      } else {
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
            AppLogger.warning('RoomProvider: claimRoomOwnership failed: $e');
          }
        }
      }
      _cancelGracePeriod(userId);
      _updateMember(userId, (m) => m.copyWith(isDisconnected: true));
      _safeNotify();
      return;
    }

    // While paused, nothing productive happens for anyone — every player
    // is just staring at the "waiting for host" overlay, which is exactly
    // when they're most likely to background the app or have a brief
    // connectivity gap of their own. Evicting them for that during a
    // pause is actively destructive and serves no purpose (the pause
    // state machine already owns the room's fate — resume or end, see
    // hostReconnectWindow). This is the fix for "when the host
    // reconnects, every player gets removed from the room": their own
    // ordinary 30s grace timers, armed by the same connectivity dip that
    // likely also affected the host, were completing right around when
    // the host came back, not because of anything the reconnect itself
    // did. Leave them marked disconnected for the UI; a real reconciliation
    // resumes the moment the room leaves 'paused' (resume or end).
    if (_room?.status == RoomStatus.paused) {
      _cancelGracePeriod(userId);
      _updateMember(userId, (m) => m.copyWith(isDisconnected: true));
      _safeNotify();
      return;
    }

    _removeMember(userId);
  }

  // ── Host reconnect (replaces mid-game ownership transfer) ──────────────
  // See migration_2026_host_reconnect_pause.sql for the matching
  // recover_owner_room change (a fast reconnect resumes in place instead
  // of always terminating the session on the owner's return).

  static const hostReconnectWindow = Duration(seconds: 60);

  Timer? _hostReconnectTimer;

  // Set once, near the top of initialize() — see the doc comment there.
  // Cleared explicitly the moment an approval is observed (see
  // clearArrivedMidGame's callers: _RejoinBanner, on seeing this user's
  // own game_rejoin_requests row become 'approved').
  bool _arrivedMidGame = false;
  bool get arrivedMidGame => _arrivedMidGame;
  void clearArrivedMidGame() {
    if (!_arrivedMidGame) return;
    _arrivedMidGame = false;
    _safeNotify();
  }

  /// True while every client should show the "waiting for host to
  /// reconnect" overlay and refuse gameplay actions.
  bool get isPausedForHostReconnect => _room?.status == RoomStatus.paused;

  // User ids with a pending game_rejoin_requests row — every client polls
  // this (any room member may read it, see game_rejoin_requests' own RLS),
  // not just the admin's _RejoinRequestsPanel, so the member list itself
  // can show "Waiting for game approval" on that member's own row instead
  // of leaving it looking like a normal, currently-playing member (section
  // 5/UI-gap requirement — the requests panel alone isn't sufficient).
  // user_id -> game_rejoin_requests.id, so any moderation surface (lobby
  // member list, in-game RoomMembersManagementSheet) can both show the
  // "Waiting for game approval" badge AND act on the request (Accept/
  // Reject) directly, without a second round trip to look up the id.
  Map<String, String> _pendingRejoinUserIds = const {};
  Set<String> get pendingRejoinUserIds => _pendingRejoinUserIds.keys.toSet();
  String? pendingRejoinRequestId(String userId) =>
      _pendingRejoinUserIds[userId];

  Future<void> _refreshPendingRejoinUserIds(String roomId) async {
    try {
      final ids = await _repo.getPendingRejoinUserIds(roomId);
      if (!mapEquals(_pendingRejoinUserIds, ids)) {
        _pendingRejoinUserIds = ids;
        _safeNotify();
      }
    } catch (e) {
      AppLogger.warning('RoomProvider: pending rejoin ids refresh failed: $e');
    }
  }

  /// Remaining countdown, recomputed live from rooms.last_active_at (which
  /// updateStatus() stamps the moment the pause was persisted) rather than
  /// from a local timer — every client (not just whichever one happened to
  /// detect the disconnect) renders the same deadline this way.
  Duration get hostReconnectRemaining {
    final since = _room?.lastActiveAt;
    if (!isPausedForHostReconnect || since == null) return Duration.zero;
    final elapsed = DateTime.now().difference(since);
    final remaining = hostReconnectWindow - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // Whether the current user is a participant of this room's most-recent game
  // session (authoritative game_sessions.player_ids, and NOT kicked / permanent
  // leaver) — computed once during initialize(). This is the SAME signal the
  // closed-room entry gate uses; exposed so the lobby's own closed-room bounce
  // can grant a returning participant the identical exemption instead of
  // ejecting them from a room they legitimately belong to.
  bool _isSessionParticipant = false;
  bool get isSessionParticipant => _isSessionParticipant;

  // Guards against overlapping calls to _checkOwnerHeartbeatStaleness (the
  // 5s reconcile tick) piling up if a single check is still awaiting its
  // network round-trip.
  bool _checkingOwnerStaleness = false;

  /// Wall-clock time THIS client last observed the room transition
  /// starting -> in_game. Host-away staleness detection is suppressed for
  /// [_startupHostAwayGraceWindow] afterward: the owner may still be
  /// finishing game initialization (initAsOwner / the ready barrier /
  /// card+config work) on their single isolate right after they flip the
  /// room to in_game, briefly lagging their own heartbeat past the 20s
  /// threshold — pausing then would evict a present, actively-starting
  /// owner (the confirmed host-away/startup race). Null except during that
  /// specific window; set only on the starting -> in_game transition and
  /// cleared on every game end / the next game's 'starting', so a previous
  /// game's value can never suppress detection in the next one.
  DateTime? _inGameSince;

  /// Covers the owner's post-in_game startup settling PLUS at least one
  /// full heartbeat landing afterward (heartbeat is [_heartbeatInterval] =
  /// 10s; staleness threshold is [_ownerStaleThreshold] = 20s), so a
  /// genuinely-present owner's last_seen_at is always fresh again before
  /// detection resumes. Strictly tied to the starting -> in_game
  /// transition, NOT a blanket "first N seconds after app open". Well
  /// within the 60s host-reconnect countdown, so a genuine disconnect at
  /// startup is still caught the moment this window elapses.
  static const _startupHostAwayGraceWindow = Duration(seconds: 20);

  /// Idempotency guard for [_maybeOwnerSelfResumeFromPause].
  bool _ownerSelfResuming = false;

  /// The single detection path for "the owner is gone" — called from the
  /// 5s reconcile tick (see startRoomReconcile's Timer.periodic above),
  /// never from presence-diffing. Presence's own server-side disconnect
  /// detection has no bound (a force-quit or dropped connection is only
  /// noticed once the server's own keepalive times out, which can take
  /// well over a minute — the exact "sometimes appears after more than a
  /// minute" symptom) — a bounded poll against the heartbeat every client
  /// writes every _heartbeatInterval is the only way to guarantee a fixed
  /// worst-case latency here. This intentionally does NOT also run off
  /// presence sync events; one detection path, one trigger.
  Future<void> _checkOwnerHeartbeatStaleness() async {
    final room = _room;
    if (room == null || isOwner || _checkingOwnerStaleness) return;
    // Startup handoff grace: the room just went starting -> in_game (this
    // client flipped via game_session_ready or the reconcile below), but
    // the owner may still be mid-initialization. Suppress host-away pausing
    // for the grace window so a present, still-starting owner is never
    // evicted — see [_inGameSince]. A genuine disconnect is still detected
    // the instant this window elapses, long before the 60s countdown.
    final since = _inGameSince;
    if (since != null &&
        DateTime.now().difference(since) < _startupHostAwayGraceWindow) {
      return;
    }
    _checkingOwnerStaleness = true;
    try {
      final lastSeen = await _repo.getMemberLastSeen(
        roomId: room.id,
        userId: room.ownerId,
      );
      if (lastSeen != null &&
          DateTime.now().difference(lastSeen) >= _ownerStaleThreshold) {
        await _pauseGameForHostDisconnect(room);
      }
    } catch (e) {
      AppLogger.warning(
        'RoomProvider: owner heartbeat staleness check failed: $e',
      );
    } finally {
      _checkingOwnerStaleness = false;
    }
  }

  // 2x _heartbeatInterval — the same "more than one missed heartbeat"
  // tolerance already used everywhere else staleness is checked in this
  // project (claim_room_ownership, force_end_game_if_owner_absent,
  // pause_game_if_owner_absent), so a single slow write is never mistaken
  // for a real disconnect.
  static const _ownerStaleThreshold = Duration(seconds: 20);

  Future<void> _pauseGameForHostDisconnect(RoomEntity room) async {
    if (room.status == RoomStatus.paused) {
      _startHostReconnectCountdown();
      return;
    }
    try {
      // rooms.status is RLS-restricted to owner-only writes — this is
      // always called by a bystander (the owner can't detect their own
      // absence), so it must go through the one RPC allowed to write on a
      // verified-absent owner's behalf. See
      // migration_2026_pause_if_owner_absent.sql — a plain updateStatus()
      // call here previously silently affected 0 rows, which is why the
      // pause only ever "stuck" for as long as the one-shot broadcast's
      // local effect lasted, then reverted on the next full refetch.
      await _repo.pauseGameIfOwnerAbsent(room.id);
      await _realtime.broadcastRoomEvent(room.id, {
        'type': 'pause',
        'reason': 'host_disconnected',
      });
      _room = _room?.copyWith(
        status: RoomStatus.paused,
        lastActiveAt: DateTime.now(),
      );
      AppLogger.info(
        'RoomProvider: paused room ${room.id} — host disconnected',
      );
      _startHostReconnectCountdown();
    } catch (e) {
      AppLogger.warning('RoomProvider: pause-for-host-disconnect failed: $e');
    }
  }

  /// Host-away safety net (PART 2/3): a genuinely-present owner must never
  /// be stranded on the "waiting for host to reconnect" overlay about
  /// THEMSELVES. If this client is the owner, is online/healthy, and the
  /// room is currently paused for a host disconnect, resume the game via
  /// the SAME owner-authorized path the ordinary resume flow uses
  /// (updateStatus(in_game) + a 'resume' broadcast) — because "host
  /// reconnect" is meaningless when the host never actually left.
  ///
  /// Deliberately does NOT call recover_owner_room: after
  /// pause_game_if_owner_absent (which only writes rooms.status, never
  /// game_sessions.paused_at) that RPC's paused_at-is-null branch would
  /// TERMINATE the session rather than resume it — the exact opposite of
  /// what a present owner wants. updateStatus(in_game) only flips room
  /// status and never touches a game_sessions row, so it can neither
  /// resurrect an already-ended game (guarded below on an actually-active
  /// session) nor abort a live one.
  ///
  /// Idempotent and race-safe: a single in-flight guard, an owner check, a
  /// connection-health check (a genuinely disconnected owner's client is
  /// offline and must NOT override the pause — the countdown/timeout must
  /// run its course), an active-session existence check, and a final
  /// re-read of status right before the write so a legitimate end/close
  /// that landed meanwhile is never overridden.
  Future<void> _maybeOwnerSelfResumeFromPause() async {
    if (!isOwner || _ownerSelfResuming) {
      AppLogger.info(
        'OWNER_RESUME skip room=${_room?.id} user=$_currentUserId '
        'isOwner=$isOwner ownerSelfResuming=$_ownerSelfResuming '
        'reason=guard',
      );
      return;
    }
    final room = _room;
    if (room == null || room.status != RoomStatus.paused) {
      AppLogger.info(
        'OWNER_RESUME skip room=${room?.id} user=$_currentUserId '
        'roomStatus=${room?.status} reason=not_paused',
      );
      return;
    }
    _ownerSelfResuming = true;
    AppLogger.info(
      'OWNER_RESUME begin room=${room.id} user=$_currentUserId isOwner=true '
      'connectionState=$_connectionState roomStatus=${room.status}',
    );
    try {
      // GENUINE-PRESENCE GATE (not _connectionState): fire the owner's own
      // real heartbeat first and let its success/failure decide whether we
      // are actually online. touch_room_presence goes through guardedCall,
      // which throws OfflineFailure when offline and rethrows any RPC
      // error — so if this throws we are genuinely NOT reachable and fall
      // to the catch WITHOUT resuming (the pause/countdown runs its
      // course). If it succeeds, HTTP to the server provably works right
      // now, which is the real proof of presence — more reliable than the
      // realtime websocket's _connectionState, which can lag actual
      // connectivity (reconnecting/recovering) and previously stranded the
      // owner on their own away overlay after a genuine reconnect. It also
      // refreshes last_seen_at (legitimate, the owner IS present), closing
      // the resume -> bystander-still-sees-stale-last_seen -> re-pause flap.
      //
      // Every network await here is bounded by _resumeOpTimeout: a stale/
      // half-open socket after a real reconnect can leave an RPC hanging
      // forever with no default HTTP timeout, which would pin
      // _ownerSelfResuming=true and permanently block every future retry
      // (the reconnect-stays-paused bug). A TimeoutException instead falls
      // to the catch, releases the guard in the finally, and the reconcile
      // simply retries on its next tick. This is a failure bound, not a
      // delay.
      await _repo.touchPresence(room.id).timeout(_resumeOpTimeout);
      AppLogger.info('OWNER_RESUME heartbeat_ok room=${room.id}');
      // Never resurrect an ended game: only resume if a live (status=
      // 'active') session still exists. A genuine end (force-end timeout,
      // quit) sets game_sessions.status='aborted'/'completed' AND
      // rooms.status away from 'paused', so both this and the re-read
      // below independently rule it out.
      final sessionId = await _currentActiveSessionId(
        room.id,
      ).timeout(_resumeOpTimeout);
      AppLogger.info(
        'OWNER_RESUME session_lookup room=${room.id} '
        'activeSessionId=$sessionId',
      );
      if (sessionId == null) return;
      // Re-read immediately before the write: another client may have
      // resumed or terminated the room while the awaits above were in
      // flight. Only act if it's still paused.
      if (_room?.status != RoomStatus.paused) {
        AppLogger.info(
          'OWNER_RESUME abort room=${room.id} '
          'reason=status_changed_to=${_room?.status}',
        );
        return;
      }
      // Authoritative DB write FIRST (owner-RLS-allowed), then flip local
      // state and cancel the countdown, then a best-effort 'resume'
      // broadcast. Ordering matters: if the broadcast were awaited before
      // the local update and the realtime socket were still down, a throw
      // would skip the local flip and leave the owner stuck on the overlay
      // until the next reconcile — whereas the DB write is authoritative,
      // so every other client reconciles to in_game regardless of whether
      // the broadcast lands.
      await _repo
          .updateStatus(room.id, RoomStatus.inGame)
          .timeout(_resumeOpTimeout);
      _room = _room?.copyWith(status: RoomStatus.inGame);
      _cancelHostReconnectCountdown();
      _safeNotify();
      _realtime.broadcastRoomEvent(room.id, {'type': 'resume'}).ignore();
      AppLogger.info(
        'OWNER_RESUME success room=${room.id} session=$sessionId '
        '-> rooms.status=in_game + resume broadcast',
      );
    } catch (e) {
      // Heartbeat failed (offline), a write failed, or a call timed out —
      // do NOT resume; the owner is not demonstrably present/reachable. The
      // finally releases the guard and the reconcile loop retries on a
      // later tick once connectivity is genuinely back.
      AppLogger.warning('OWNER_RESUME failed room=${room.id} error=$e');
    } finally {
      _ownerSelfResuming = false;
    }
  }

  // Failure bound for each network op inside _maybeOwnerSelfResumeFromPause.
  // Without it a stale/half-open socket after a real reconnect could hang an
  // RPC forever (no default HTTP timeout), pinning _ownerSelfResuming=true
  // and permanently blocking every future resume retry. Long enough not to
  // trip on a healthy-but-slow request, short enough that a hang releases
  // the guard well within a couple of reconcile ticks.
  static const _resumeOpTimeout = Duration(seconds: 8);

  void _startHostReconnectCountdown() {
    if (_hostReconnectTimer != null) return;
    final remaining = hostReconnectRemaining;
    _hostReconnectTimer = Timer(
      remaining > Duration.zero ? remaining : hostReconnectWindow,
      _onHostReconnectTimeout,
    );
  }

  void _cancelHostReconnectCountdown() {
    _hostReconnectTimer?.cancel();
    _hostReconnectTimer = null;
  }

  Future<void> _onHostReconnectTimeout() async {
    _hostReconnectTimer = null;
    final room = _room;
    if (room == null || room.status != RoomStatus.paused) return;
    // EVERY present non-owner client attempts the authoritative
    // termination — no longer just a single designated closer. That was a
    // single point of failure: if that one client's Dart Timer was
    // suspended (backgrounded/locked phone), disposed, or the client was
    // gone, nobody called the RPC and the room stayed stuck at 0s while
    // every other client's visual countdown had already reached zero.
    //
    // This is safe because force_end_game_if_owner_absent is idempotent
    // and race-safe: it takes a FOR UPDATE lock, re-verifies server-side
    // that the owner is genuinely stale (>25s), and no-ops the moment the
    // room has already left in_game/paused — so the first caller to win
    // the lock terminates and every later caller safely does nothing. The
    // server RPC remains the SOLE authority on whether termination is
    // valid; this never writes rooms.status locally. The owner themselves
    // never runs this (a present owner self-resumes instead; an absent
    // owner's client isn't executing).
    if (isOwner) return;
    AppLogger.warning(
      'RoomProvider: host did not reconnect within '
      '${hostReconnectWindow.inSeconds}s — attempting authoritative '
      'termination of room ${room.id}',
    );
    try {
      final sessionId = await _currentActiveSessionId(room.id);
      // Fan out game_ended to everyone else (self:false, so this sender
      // relies on its own reconcile/_leaveIfRoomNoLongerActive once the
      // RPC flips the room to waiting). Duplicate broadcasts from other
      // callers are harmless — receivers dedupe via the game screens'
      // isNavigatingAway/_autoLeftOnSessionEnd guard.
      await _realtime.broadcastRoomEvent(room.id, {
        'type': 'game_ended',
        'reason': 'host_disconnect_timeout',
        'session_id': sessionId,
      });
      // rooms/game_sessions restrict direct UPDATE to the owner via RLS —
      // a plain updateStatus() call here would silently affect 0 rows.
      // This RPC is the one path allowed to write on a verified-absent
      // owner's behalf, and it re-checks that absence itself.
      await _repo.forceEndGameIfOwnerAbsent(room.id);
    } catch (e) {
      AppLogger.warning('RoomProvider: host-reconnect timeout end failed: $e');
    }
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
      // Note: the real 'game started' broadcast is a dedicated
      // RoomEvent.gameStarted channel handled by _handleGameStarted below,
      // NOT a generic room event routed through this switch — nothing
      // ever sends a generic {'type': 'game_started', ...} event (verified
      // by grepping the whole app), so there is deliberately no case for
      // it here.
      case 'game_session_ready':
        // Sent by the owner's client the instant create_game_session has
        // genuinely succeeded (the session row provably exists) — see each
        // game screen's initAsOwner. THIS is what's allowed to flip a
        // non-owner's local status to 'in_game' and let _syncGameRoute
        // navigate them — by construction, the session cannot be missing
        // by the time any client reacts to it, closing the exact race that
        // previously bounced players between the lobby and the loading
        // screen (a player's game screen could mount, look for the
        // session, find nothing yet, and bail back to the lobby).
        if (!isOwner) _handleGameSessionReady();

      case 'join':
        // Never fabricate authoritative member state from a broadcast
        // payload — it only ever carries userId/displayName/avatarUrl, so
        // constructing a RoomMemberEntity straight from it silently
        // defaulted every other field (isAway, isDisconnected,
        // isGameMuted, isSpectator, role, ...) to false/normal regardless
        // of the real room_members row. That's exactly how a returning
        // player — genuinely is_away=true and/or sitting on a pending
        // rejoin request — briefly-to-persistently rendered as an
        // ordinary "Playing" member with full kick/mute/ban: the admin's
        // local list was updated from this fabricated object, not from
        // the database. A join is just a "membership changed, go re-check"
        // notification — re-fetch through the same sequenced,
        // authoritative path (_refreshMembers) every other reconciliation
        // already uses, so a stale/out-of-order response can never
        // overwrite newer state (_refreshMembersSeq) and every field
        // (is_away, is_disconnected, is_game_muted, is_spectator,
        // is_ready, role, ...) comes from the real row.
        if (userId != null && userId != _currentUserId && _room != null) {
          // _refreshMembers notifies once the real data lands — nothing
          // to show before that (the old member state, if any, is still
          // correct until this resolves).
          _refreshMembers(_room!.id);
        }

      case 'owner_left':
        // Idempotency guard: leaveRoom() also sends a 'leave' broadcast
        // right after this one, which independently closes the room via
        // _removeMember's owner-check — without this guard a client that
        // already processed one of the two would fire roomClosed (and
        // LobbyScreen's dialog) a second time.
        AppLogger.info(
          'ROOM_CLOSED_EVENT owner_left room=${_room?.id} '
          'userId=$_currentUserId oldStatus=${_room?.status} '
          'newStatus=closed alreadyClosed=${_room?.status == RoomStatus.closed}',
        );
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

  /// Sets 'starting', NOT 'in_game' — the room enters the explicit,
  /// DB-backed STARTING_GAME lock the instant the owner presses Start
  /// Game, before create_game_session has even been called (let alone
  /// succeeded). Runs identically for every client, owner included.
  /// A non-owner must never navigate into the actual game screen off this
  /// signal alone — see LobbyScreen.build()'s locked "Game Starting"
  /// overlay (shown for exactly this status) and _syncGameRoute (which
  /// only pushes the real game route for a non-owner once status reaches
  /// 'in_game' — see _handleGameSessionReady below). Root-cause fix for
  /// players bouncing lobby -> loading -> lobby: previously this set
  /// 'in_game' directly, so a player's game screen could mount and look
  /// for a game_sessions row the owner's own create_game_session call
  /// hadn't necessarily created yet.
  void _handleGameStarted(Map<String, dynamic> p) {
    _readyPollTimer?.cancel();
    // A new game is starting — clear any startup-grace timestamp left over
    // from a PREVIOUS game so it can never suppress host-away detection in
    // this one. The grace is (re)armed only when this game reaches
    // starting -> in_game (see _handleGameSessionReady / _refreshMembers).
    _inGameSince = null;
    if (_room != null) {
      final gameTypeName = p['game_type'] as String?;
      final gameType = gameTypeName != null
          ? GameType.values.firstWhere(
              (g) => g.toDbString() == gameTypeName || g.name == gameTypeName,
              orElse: () => GameType.truthOrDare,
            )
          : null;
      // A genuinely new game is starting — release any post-game-end stale-
      // status suppression so the new starting/in_game status is adopted.
      _endedReturnPending = false;
      _endedSessionId = null;
      _room = _room!.copyWith(
        status: RoomStatus.starting,
        gameType: gameType ?? _room!.gameType,
      );
      _safeNotify();
    }
  }

  /// Companion to _handleGameStarted — see 'game_session_ready' in
  /// _handleRoomEvent, which is what actually calls this.
  void _handleGameSessionReady() {
    if (_room != null) {
      // This IS the starting -> in_game transition on a non-owner client
      // (the only clients that run host-away detection). Arm the startup
      // grace so a bystander doesn't pause a still-initializing owner in
      // the handoff window — see [_inGameSince].
      if (_room!.status == RoomStatus.starting) {
        _inGameSince = DateTime.now();
      }
      // A genuinely new game is starting — release the post-game-end stale-
      // status suppression so this in_game IS adopted normally.
      _endedReturnPending = false;
      _endedSessionId = null;
      _room = _room!.copyWith(status: RoomStatus.inGame);
      _safeNotify();
    }
  }

  // DURABLE latch: set when the game ends locally (markReturnedToLobby /
  // onReturnedFromGameRoute / _handleGameEnded). Bridges the window where
  // this client's local status is already 'waiting' but the authoritative
  // rooms.status=waiting write (owner-only) hasn't propagated — a non-owner
  // client cannot and MUST NOT write rooms.status, so it can't rely on that
  // write ever happening promptly. While set, the reconcile poll refuses to
  // re-adopt a stale 'in_game'/'starting'/'paused' rooms.status (which would
  // re-raise _GameStartingLock / "Preparing the game…"). Unlike the old
  // one-shot version this stays latched across EVERY reconcile cycle until the
  // backend authoritatively converges (rooms.status -> waiting/ended) OR a
  // genuinely NEW game begins — the latter proven against the authoritative
  // game_sessions row, never rooms.status (see _refreshMembers). Cleared on
  // convergence, on a new game_started/game_session_ready, and on leave.
  bool _endedReturnPending = false;

  // The game_sessions id this client was playing when it last returned to the
  // lobby (captured by onReturnedFromGameRoute). Lets the reconcile poll tell
  // a stale 'in_game' tail of the game we already finished (same session id,
  // now completed/aborted) apart from a genuinely NEW game (a DIFFERENT live
  // session id) — race-free even if the owner is slow to close the old
  // session. game_sessions.player_ids/identity stays the single authority.
  String? _endedSessionId;

  /// Id of the most recent game_sessions row for [roomId], regardless of its
  /// status (active/paused/completed/aborted). Used to capture which session
  /// this client just finished. RLS scopes game_sessions to player_ids, so a
  /// participant (owner or player) can always read their own just-ended row.
  Future<String?> _latestSessionId(String roomId) async {
    if (roomId.isEmpty) return null;
    final row = await _supabase
        .from('game_sessions')
        .select('id')
        .eq('room_id', roomId)
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row?['id'] as String?;
  }

  /// Id of the current genuinely-live (active OR paused) session for [roomId],
  /// or null if none is live. A live id that DIFFERS from [_endedSessionId]
  /// proves a brand-new game has started; the same id (or none) means the
  /// game this client left is merely still lingering in a stale rooms.status.
  Future<String?> _latestLiveSessionId(String roomId) async {
    if (roomId.isEmpty) return null;
    final row = await _supabase
        .from('game_sessions')
        .select('id')
        .eq('room_id', roomId)
        .inFilter('status', ['active', 'paused'])
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row?['id'] as String?;
  }

  /// Centralized game-route-exit hook. LobbyScreen calls this the instant the
  /// pushed game route is popped for ANY reason — natural completion, host
  /// force-end, automatic end, a `game_ended` realtime event, the game-ended
  /// dialog, the results-screen "Leave", the session-ended auto-leave — so
  /// none of the per-game screens have to (and can't forget to) do it
  /// themselves. [_pushGameRoute] is the ONE place the game route is ever
  /// pushed, so its completion is the ONE reliable signal that this client is
  /// back on the lobby after a game. Idempotent: calling it twice (e.g. a path
  /// that already ran markReturnedToLobby, then this backstop) is harmless.
  ///
  /// Marks this client returned-to-lobby immediately (so the lobby renders the
  /// normal lobby, never _GameStartingLock) WITHOUT this non-owner client ever
  /// writing the owner-gated rooms.status, and records the finished session so
  /// the reconcile poll can converge naturally on the backend's authoritative
  /// state.
  Future<void> onReturnedFromGameRoute() async {
    // Immediate, synchronous local transition — no flash while the async
    // capture below runs. Force the latch even if status was already 'waiting'
    // (some paths flip it without latching), so reconcile still suppresses a
    // stale in_game re-adopt.
    markReturnedToLobby();
    _endedReturnPending = true;
    // Best-effort: record which session just ended for race-free stale-vs-new
    // discrimination in _refreshMembers. Non-fatal — reconcile falls back to
    // live-session existence if this is null.
    try {
      final id = await _latestSessionId(_room?.id ?? '');
      if (id != null) _endedSessionId = id;
    } catch (_) {}
  }

  void _handleGameEnded(Map<String, dynamic> p) {
    if (_room != null) {
      // Game over — clear the startup grace so it can't carry into a
      // later game in this same room.
      _inGameSince = null;
      if (_room!.status == RoomStatus.inGame ||
          _room!.status == RoomStatus.paused ||
          _room!.status == RoomStatus.starting) {
        _endedReturnPending = true;
        // Stamp the just-ended session (auto-end/host-end broadcasts carry it)
        // so reconcile can tell this stale in_game tail from a genuine new
        // game race-free — same authoritative game_sessions identity used
        // everywhere else.
        final endedSid = p['session_id'] as String?;
        if (endedSid != null) _endedSessionId = endedSid;
      }
      _room = _room!.copyWith(status: RoomStatus.waiting);
      _members = _members.map((m) => m.copyWith(isReady: false)).toList();
      _safeNotify();
    }
  }

  /// Called by a game screen the instant it navigates back to THIS room's
  /// lobby after the game/session has ended (the natural game-over "Go to
  /// Lobby" path — see goToLobbyOrHome). Reflects the ended state in local
  /// room status IMMEDIATELY so the lobby's first rebuild after the game
  /// route is popped shows the normal lobby — not the STARTING/"Preparing"
  /// placeholder (_GameStartingLock, via LobbyScreen._isEnteringOrInGame),
  /// which would otherwise flash until the 5s reconcile caught up: the
  /// natural-end path writes rooms.status=waiting to the DB but nothing
  /// updated local state, so the lobby kept reading the stale in_game
  /// status for a frame (or until reconcile). Local-only and idempotent —
  /// only downgrades an in-game/paused/starting local status to waiting,
  /// never touches an already waiting/ended/closed room, and never writes
  /// the DB (the authoritative waiting write is the caller's own
  /// updateStatus / the host-ended _handleGameEnded above).
  void markReturnedToLobby() {
    final s = _room?.status;
    if (s == RoomStatus.inGame ||
        s == RoomStatus.paused ||
        s == RoomStatus.starting) {
      _inGameSince = null;
      // Bridge the DB-lag window so the reconcile poll can't re-adopt the
      // stale in_game status and flash _GameStartingLock (see
      // _endedReturnPending / _refreshMembers).
      _endedReturnPending = true;
      _room = _room?.copyWith(status: RoomStatus.waiting);
      _cancelHostReconnectCountdown();
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
      // Real-device root-cause fix (missing premium identity in chat):
      // sendChatMessage's own broadcast payload below now carries these —
      // this read side was the other half of the gap. Every OTHER
      // recipient of a LIVE message (the normal case for anything
      // currently visible in an active chat) was reconstructing it from
      // this broadcast, which never carried the sender's premium status
      // at all, so PremiumBadge could only ever render for a message the
      // viewer re-fetched from the database — never for one received
      // live. isAnonymous was the same gap: sent by the broadcast, never
      // read here, so another viewer's own client never actually knew a
      // live message was anonymous (only the sender's own optimistic
      // bubble did).
      isAnonymous: p['is_anonymous'] as bool? ?? false,
      senderIsPremium: p['is_premium'] as bool? ?? false,
      senderPremiumTier: p['premium_tier'] as String?,
      replyToId: p['reply_to_id'] as String?,
      replyToContent: p['reply_to_content'] as String?,
      replyToDisplayName: p['reply_to_display_name'] as String?,
    );

    _chatMessages = [..._chatMessages, msg];
    _cache.appendChatMessage(msg).ignore();
    _safeNotify();
  }

  /// Item 2 — a targeted message, delivered via the RLS-gated CDC channel
  /// above rather than the broadcast fan-out. Only ever fires for a row
  /// this user's RLS already allowed them to see (sender, a listed
  /// recipient, or — for a lobby 'everyone' row inserted by some other
  /// path — any room member); lobby-scoped, so a game-context row
  /// (game_session_id set) is skipped here — it belongs to whichever
  /// game provider's own targeted-chat listener is live for that session.
  /// No joined profile data arrives over CDC (only the raw table row), so
  /// the sender's display identity is resolved from the room's own
  /// already-synced member list, same as every other in-room identity
  /// lookup.
  void _handleTargetedChatCdcInsert(Map<String, dynamic> row) {
    if (row['game_session_id'] != null) return;
    final msgId = row['id'] as String?;
    if (msgId == null) return;
    if (_chatMessages.any((m) => m.id == msgId)) return;

    final senderId = row['user_id'] as String? ?? '';
    final sender = memberById(senderId);
    final msg = ChatMessageEntity(
      id: msgId,
      roomId: row['room_id'] as String? ?? _room?.id ?? '',
      userId: senderId,
      displayName: sender?.displayName ?? 'Player',
      avatarUrl: sender?.avatarUrl,
      content: row['content'] as String? ?? '',
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      isAnonymous: row['is_anonymous'] as bool? ?? false,
      senderIsPremium: sender?.isPremium ?? false,
      senderPremiumTier: sender?.premiumTier,
      replyToId: row['reply_to_id'] as String?,
      replyToContent: row['reply_to_content'] as String?,
      replyToDisplayName: row['reply_to_display_name'] as String?,
      audienceType: row['audience_type'] as String? ?? 'everyone',
    );

    _chatMessages = [..._chatMessages, msg];
    _cache.appendChatMessage(msg).ignore();
    _safeNotify();
  }

  /// Item 2 — Premium Plus targeted lobby chat. Entitlement/room-
  /// membership/recipient-context checks all happen server-side inside
  /// send_targeted_chat_message(); this just calls it and shows the
  /// result immediately as the sender's own confirmed message (their own
  /// CDC echo of the same row is deduped by id in
  /// _handleTargetedChatCdcInsert above). [recipientNames] is display-only
  /// (the audience-selector UI already has this locally) — never sent to
  /// the server, which only ever receives ids.
  Future<bool> sendTargetedMessage({
    required String content,
    required List<String> recipientIds,
    required List<String> recipientNames,
    ChatMessageEntity? replyTo,
  }) async {
    if (_room == null || content.trim().isEmpty || recipientIds.isEmpty) {
      return false;
    }
    _isSendingChat = true;
    _safeNotify();
    try {
      final replySnippet = replyTo != null
          ? (replyTo.content.length > 120
                ? '${replyTo.content.substring(0, 120)}…'
                : replyTo.content)
          : null;
      final msg = await _repo.sendTargetedChatMessage(
        roomId: _room!.id,
        content: content.trim(),
        recipientIds: recipientIds,
        replyToId: replyTo?.id,
        replyToContent: replySnippet,
        replyToDisplayName: replyTo?.displayName,
      );
      final withNames = ChatMessageEntity(
        id: msg.id,
        roomId: msg.roomId,
        userId: msg.userId,
        displayName: _currentDisplayName,
        avatarUrl: _currentAvatarUrl,
        content: msg.content,
        createdAt: msg.createdAt,
        senderIsPremium: currentMember?.isPremium ?? false,
        senderPremiumTier: currentMember?.premiumTier,
        replyToId: msg.replyToId,
        replyToContent: msg.replyToContent,
        replyToDisplayName: msg.replyToDisplayName,
        audienceType: msg.audienceType,
        gameSessionId: msg.gameSessionId,
        recipientNames: recipientNames,
      );
      _chatMessages = [..._chatMessages, withNames];
      _isSendingChat = false;
      _safeNotify();
      return true;
    } catch (e) {
      _isSendingChat = false;
      _failure = e is Failure ? e : null;
      _safeNotify();
      return false;
    }
  }

  /// Returns true once the message has been both persisted and
  /// successfully broadcast, false if it failed (item 7) — the composer
  /// uses this to decide whether it's safe to clear the draft/close the
  /// keyboard, or whether the draft must be kept so the user can retry.
  Future<bool> sendChatMessage(
    String content, {
    ChatMessageEntity? replyTo,
    bool anonymous = false,
  }) async {
    if (_room == null || content.trim().isEmpty) return false;
    if (isCurrentUserMuted) return false;
    if (!_settings.chatEnabled) return false;

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

    // Real-device root-cause fix (missing premium identity in chat): the
    // room's own already-synced membership record — not a second
    // profile/premium source — mirroring exactly what currentMember
    // already exposes everywhere else premium status is shown. Never
    // attached to an anonymous message, same as avatarUrl/displayName
    // above — anonymity must hide premium status too, not just the name.
    final senderIsPremium = !sendAnon && (currentMember?.isPremium ?? false);
    final senderPremiumTier = sendAnon ? null : currentMember?.premiumTier;

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
      senderIsPremium: senderIsPremium,
      senderPremiumTier: senderPremiumTier,
      replyToId: replyTo?.id,
      replyToContent: replySnippet,
      replyToDisplayName: replyTo?.displayName,
    );
    _chatMessages = [..._chatMessages, optimistic];
    _safeNotify();

    try {
      await _repo.persistChatMessage(
        id: msgId,
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
        'is_premium': senderIsPremium,
        if (senderPremiumTier != null) 'premium_tier': senderPremiumTier,
        if (replyTo != null) 'reply_to_id': replyTo.id,
        if (replySnippet != null) 'reply_to_content': replySnippet,
        if (replyTo != null) 'reply_to_display_name': replyTo.displayName,
      });

      _chatMessages = _chatMessages
          .map((m) => m.id == msgId ? m.copyWithConfirmed() : m)
          .toList();
      return true;
    } catch (e) {
      AppLogger.error('RoomProvider: sendChat failed', error: e);
      _chatMessages = _chatMessages.where((m) => m.id != msgId).toList();
      return false;
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
          _updateMember(targetId, (m) => m.copyWith(isMuted: true));
          _safeNotify();
        }

      case 'unmute':
        if (targetId != null) {
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

      case 'set_spectator':
        // Item 5 — reflects the admin's spectator toggle on every OTHER
        // connected client (the admin's own client already applied this
        // locally in setMemberSpectator, same as game_mute/unmute above).
        if (targetId != null) {
          _updateMember(targetId, (m) => m.copyWith(isSpectator: true));
          _safeNotify();
        }

      case 'unset_spectator':
        if (targetId != null) {
          _updateMember(targetId, (m) => m.copyWith(isSpectator: false));
          _safeNotify();
        }

      case 'pause':
        _room = _room?.copyWith(
          status: RoomStatus.paused,
          lastActiveAt: DateTime.now(),
        );
        _startHostReconnectCountdown();
        _safeNotify();
        // If THIS client is the (present, healthy) owner, a host-disconnect
        // pause is spurious — resume instead of sitting on our own
        // "waiting for host" overlay. No-op for everyone else. See
        // _maybeOwnerSelfResumeFromPause.
        _maybeOwnerSelfResumeFromPause().ignore();

      case 'resume':
        _room = _room?.copyWith(status: RoomStatus.inGame);
        _cancelHostReconnectCountdown();
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
      'force_dare_mode' => _settings.copyWith(forceDareMode: value as String),
      'max_truths' => _settings.copyWith(maxTruths: (value as num).toInt()),
      'honesty_vote_enabled' => _settings.copyWith(
        honestyVoteEnabled: value as bool,
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
  /// [mutePlayer], which only silences text chat. Previously
  /// broadcast-only/session-scoped despite mute_player_in_game and
  /// room_members.is_game_muted already existing to persist it — a
  /// reconnect/CDC refresh silently reverted this to unmuted because
  /// nothing ever wrote the DB row, and _rowToEntity never even read the
  /// column back (see room_repository.dart). Now persisted the same way
  /// [mutePlayer] persists chat mute. durationSeconds null = permanent.
  Future<void> mutePlayerInGame(
    String targetUserId, {
    bool muted = true,
    int? durationSeconds,
  }) async {
    if (!canMutePlayers || targetUserId == _currentUserId || _room == null) {
      return;
    }
    await _repo.muteMemberInGame(
      _room!.id,
      targetUserId,
      muted: muted,
      durationSeconds: durationSeconds,
    );
    await _realtime.broadcastModeration(_room!.id, {
      'type': muted ? 'game_mute' : 'game_unmute',
      'target_user_id': targetUserId,
      'duration_seconds': durationSeconds,
    });
    _updateMember(targetUserId, (m) => m.copyWith(isGameMuted: muted));
    _safeNotify();
  }

  /// Item 5 — admin/moderator spectator toggle. Reuses the EXISTING
  /// spectator concept end-to-end: the target's role flips server-side
  /// (set_room_member_spectator RPC) to/from 'spectator', which is the
  /// SAME flag [eligiblePlayers], pack min/max enforcement, and turn
  /// order already read via [RoomMemberEntity.isSpectator] — no second,
  /// parallel spectator state. Never called automatically; the admin
  /// picks the target explicitly and can reverse it the same way.
  Future<void> setMemberSpectator(
    String targetUserId, {
    required bool isSpectator,
  }) async {
    if (!canSetSpectator || targetUserId == _currentUserId || _room == null) {
      return;
    }
    await _repo.setMemberSpectator(
      _room!.id,
      targetUserId,
      isSpectator: isSpectator,
    );
    await _realtime.broadcastModeration(_room!.id, {
      'type': isSpectator ? 'set_spectator' : 'unset_spectator',
      'target_user_id': targetUserId,
    });
    _updateMember(targetUserId, (m) => m.copyWith(isSpectator: isSpectator));
    _safeNotify();
  }

  Future<void> mutePlayer(
    String targetUserId, {
    bool muted = true,
    // Was a hardcoded, invisible 5-minute auto-expiry with no UI to
    // surface or override it — a moderator muting someone had no way to
    // know it would silently lift itself, which reads exactly like "mute
    // doesn't work" from their side. Permanent-by-default (null) until a
    // UI actually offers a duration choice; mute_room_member/muteMember
    // still fully support a real duration when one is passed.
    int? durationSeconds,
  }) async {
    if (!canMuteChat || targetUserId == _currentUserId || _room == null) {
      return;
    }
    await _repo.muteMember(
      _room!.id,
      targetUserId,
      muted: muted,
      durationSeconds: durationSeconds,
    );
    await _realtime.broadcastModeration(_room!.id, {
      'type': muted ? 'mute' : 'unmute',
      'target_user_id': targetUserId,
      'duration_seconds': durationSeconds,
    });
    _updateMember(targetUserId, (m) => m.copyWith(isMuted: muted));
    _safeNotify();
    // Mirrors kickPlayer/banPlayer's push-notification backstop — a target
    // who isn't connected to the room's realtime channel at the moment of
    // muting (backgrounded app, brief disconnect) would otherwise never
    // find out until they reopen the room and the DB row (correctly)
    // reflects it. Unmute doesn't need this: it's not time-sensitive the
    // way "you've just lost the ability to speak" is.
    if (muted) {
      _repo
          .notifyModeration(
            roomId: _room!.id,
            targetUserId: targetUserId,
            action: 'mute',
          )
          .ignore();
    }
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
    final target = _members.where((m) => m.userId == newOwnerId).firstOrNull;
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

  // Debounce guard for lobby_screen.dart's _onStartGame — that closure is
  // rebuilt fresh on every _BottomActionBar build (a StatelessWidget), so
  // it can't reliably hold its own "already starting" flag across a rapid
  // double-tap; RoomProvider is the one stable, long-lived instance for
  // the whole room visit. Without this, a double-tap (or a tap that felt
  // unresponsive under lag, prompting a second tap) could call
  // create_game_session twice for the same room, and push the game route
  // twice. Mirrors the existing _isLeaving guard on leaveRoom() below.
  bool _startGameInFlight = false;
  bool get isStartingGame => _startGameInFlight;
  void setStartingGame(bool value) {
    if (_startGameInFlight == value) return;
    _startGameInFlight = value;
    // Notify so the lobby immediately swaps to the loading lock (disabling
    // Start Game AND every other lobby action) the instant starting begins,
    // and restores the interactive lobby if starting fails/cancels — instead
    // of leaving the lobby live during the pre-status-flip window where a
    // second tap or another action could still fire. See LobbyScreen._build's
    // lock condition and _onStartGame's finally.
    _safeNotify();
  }

  bool _isLeaving = false;

  // A room owner's leaveRoom() is a chain of up to 8 sequential network
  // calls (status check, two broadcasts, the close_room RPC, presence
  // untrack, the leave DB write, channel unsubscribe, presence set-online)
  // — every one of them a plain `await` with no bound on how long it can
  // take. Whoever calls leaveRoom() (lobby_screen.dart's "Close Room")
  // awaits the whole thing before navigating away, so a single stuck call
  // anywhere in that chain — a flaky connection, a Realtime channel stuck
  // reconnecting — freezes the screen indefinitely with no error, no
  // feedback, and no way to proceed short of force-quitting the app. A
  // non-owner's leave is only 2 calls, so the exact same class of bug is
  // far less likely to ever actually manifest for them within a normal
  // testing session — not because they're immune to it, just because
  // there are far fewer chances to hit it. Bounding every step here, so a
  // stuck call degrades to "this step didn't finish in time" and the
  // sequence still completes, is what makes the owner's leave actually
  // finish deterministically instead of only finishing when every single
  // network call happens to succeed.
  Future<void> _leaveRoomStep(Future<void> step, String label) async {
    try {
      await step.timeout(const Duration(seconds: 6));
    } catch (e) {
      AppLogger.warning('RoomProvider: leaveRoom step "$label" failed: $e');
    }
  }

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
              .maybeSingle()
              .timeout(const Duration(seconds: 6));
          isPaused = (row?['status'] as String?) == 'paused';
          if (isPaused) _room = _room!.copyWith(status: RoomStatus.paused);
        } catch (_) {}
      }

      if (amOwner && (permanent || !isPaused)) {
        AppLogger.info(
          'ROOM_CLOSE destructive room=$roomId userId=$_currentUserId '
          'oldStatus=${_room?.status} newStatus=closed '
          '(broadcasting owner_left + close_room RPC)',
        );
        await _leaveRoomStep(
          _realtime.broadcastRoomEvent(roomId, {
            'type': 'owner_left',
            'user_id': _currentUserId,
          }),
          'broadcast owner_left',
        );
        await _leaveRoomStep(_closeRoomInBackend(roomId), 'close_room');
      }

      await _leaveRoomStep(
        _realtime.broadcastRoomEvent(roomId, {
          'type': 'leave',
          'user_id': _currentUserId,
          'display_name': _currentDisplayName,
        }),
        'broadcast leave',
      );

      await _leaveRoomStep(
        _realtime.untrackPresence(roomId),
        'untrackPresence',
      );
      await _leaveRoomStep(
        _repo.leaveRoom(userId: _currentUserId, roomId: roomId),
        'repo.leaveRoom',
      );
      await _leaveRoomStep(_realtime.unsubscribe(roomId), 'unsubscribe');
      await _leaveRoomStep(_presence.setOnline(), 'presence.setOnline');
    } finally {
      _isLeaving = false;
    }
  }

  void _setConnection(RoomConnectionState state) {
    if (_connectionState == state) return;
    final previous = _connectionState;
    _connectionState = state;
    _safeNotify();
    // Reconnect fully settled (recovering -> connected). Retry the owner's
    // self-resume so a paused room the owner reconnected into is recovered
    // even if the earlier attempt — fired while still 'recovering' in
    // _handleChannelStatus — raced a transient failure. Idempotent no-op
    // for non-owners, non-paused rooms, or an already-resumed room.
    if (previous == RoomConnectionState.recovering &&
        state == RoomConnectionState.connected) {
      _maybeOwnerSelfResumeFromPause().ignore();
    }
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

    // Diagnostic: capture WHO is being removed and WHAT their membership
    // looked like at removal time. A hidden spectator must never reach here
    // via a presence-diff eviction — if it does, this line pins down the
    // exact victim/room/state for the post-mortem.
    AppLogger.info(
      'MEMBER_REMOVED room=${_room?.id} user=$userId '
      'isSpectator=${leaving?.isSpectator} isHidden=${leaving?.isHiddenSpectator} '
      'isOwner=$wasOwner status=${_room?.status}',
    );

    // Mirrors _confirmAndRemoveMember's deliberate mid-game/paused
    // exemption for the owner (see that method's comment) — pausing and
    // ending are entirely owned by _checkOwnerHeartbeatStaleness /
    // _onHostReconnectTimeout, which poll room_members.last_seen_at on
    // their own bounded schedule, independently of any broadcast. This
    // method is the ONE caller of close_room that ISN'T already gated the
    // same way (a stray 'leave'/'player_left' broadcast reaching a
    // bystander's client while the game is running or paused must not be
    // able to race ahead of that state machine and permanently close the
    // room / abort a still-resumable session on its behalf).
    if (wasOwner &&
        _room != null &&
        (_room!.status == RoomStatus.inGame ||
            _room!.status == RoomStatus.paused ||
            _room!.status == RoomStatus.starting)) {
      _updateMember(userId, (m) => m.copyWith(isDisconnected: true));
      _safeNotify();
      return;
    }

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
    // Immediate local-removal path (kick/ban broadcast just applied) —
    // don't wait for the next _refreshMembers poll tick to notice the
    // game can no longer continue.
    _maybeAutoEndGame();
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

  // Last (roomStatus, gameType) actually pushed to PresenceService — a
  // plain equality guard so _syncPresenceWithRoomState (called from every
  // _safeNotify, which fires *very* often: chat, ready-toggles, etc.)
  // only actually writes presence when the room's lobby/in-game/game-type
  // state genuinely changed, not on every unrelated notify.
  RoomStatus? _lastSyncedPresenceStatus;
  GameType? _lastSyncedPresenceGameType;

  /// Keeps PresenceService's detailed room/game presence (see
  /// PresenceService.setInGame's roomStatus/gameType params) correct
  /// without threading an explicit call through every one of the many
  /// places _room gets reassigned throughout this file (local mutation,
  /// broadcast events, postgres CDC) — this is the one place already
  /// guaranteed to run after every single one of them.
  void _syncPresenceWithRoomState() {
    final room = _room;
    if (room == null || _disposed) return;
    if (room.status == _lastSyncedPresenceStatus &&
        room.gameType == _lastSyncedPresenceGameType) {
      return;
    }
    _lastSyncedPresenceStatus = room.status;
    _lastSyncedPresenceGameType = room.gameType;
    _presence.setInGame(
      room.id,
      roomStatus: room.status == RoomStatus.inGame ? 'in_game' : 'lobby',
      gameType: room.status == RoomStatus.inGame
          ? room.gameType?.toDbString()
          : null,
    );
  }

  void _safeNotify() {
    if (_disposed) return;
    _syncPresenceWithRoomState();
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
    _hostReconnectTimer?.cancel();
    for (final t in _disconnectedTimers.values) t.cancel();
    _lifecycleCtrl.close();
    _memberCdcChannel?.unsubscribe();
    _targetedChatCdcChannel?.unsubscribe();
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
