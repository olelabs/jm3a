// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import '../../../core/data/base_repository.dart';
// // import '../../../core/errors/failures.dart';
// // import '../../../core/network/api_client.dart';
// // import '../domain/room_entity.dart';
// // import '../../games/engine/base_game_engine.dart';

// // class RoomRepository extends BaseRepository {
// //   final _api = ApiClient.instance;
// //   RoomRepository._();
// //   static final RoomRepository _instance = RoomRepository._();
// //   static RoomRepository get instance => _instance;

// //   final _supabase = Supabase.instance.client;

// //   Future<List<RoomEntity>> getPublicRooms({
// //     int limit = 20,
// //     int offset = 0,
// //     String? gameTypeFilter,
// //     String? userId,
// //   }) => guardedCall(
// //     operationName: 'getPublicRooms',
// //     operation: () async {
// //       var q = _supabase
// //           .from('rooms')
// //           .select('*, room_settings(*)')
// //           .eq('visibility', 'public')
// //           .inFilter('status', ['waiting', 'in_game'])
// //           .isFilter('deleted_at', null);
// //       if (gameTypeFilter != null) q = q.eq('game_type', gameTypeFilter);
// //       final publicRows = await q
// //           .order('last_active_at', ascending: false)
// //           .range(offset, offset + limit - 1);

// //       List<dynamic> privateRows = [];
// //       if (userId != null) {
// //         var ownedQ = _supabase
// //             .from('rooms')
// //             .select('*, room_settings(*)')
// //             .eq('owner_id', userId)
// //             .eq('visibility', 'private')
// //             .inFilter('status', ['waiting', 'in_game', 'paused'])
// //             .isFilter('deleted_at', null);
// //         if (gameTypeFilter != null)
// //           ownedQ = ownedQ.eq('game_type', gameTypeFilter);
// //         final ownedRows = await ownedQ.order(
// //           'last_active_at',
// //           ascending: false,
// //         );

// //         final membershipRows = await _supabase
// //             .from('room_members')
// //             .select('room_id')
// //             .eq('user_id', userId)
// //             .isFilter('left_at', null);
// //         final memberRoomIds = (membershipRows as List)
// //             .map((r) => r['room_id'] as String)
// //             .toList();

// //         if (memberRoomIds.isNotEmpty) {
// //           var memberQ = _supabase
// //               .from('rooms')
// //               .select('*, room_settings(*)')
// //               .eq('visibility', 'private')
// //               .inFilter('id', memberRoomIds)
// //               .inFilter('status', ['waiting', 'in_game', 'paused'])
// //               .isFilter('deleted_at', null);
// //           if (gameTypeFilter != null)
// //             memberQ = memberQ.eq('game_type', gameTypeFilter);
// //           final memberRoomRows = await memberQ.order(
// //             'last_active_at',
// //             ascending: false,
// //           );
// //           privateRows = [...ownedRows, ...memberRoomRows];
// //         } else {
// //           privateRows = ownedRows;
// //         }

// //         var pausedOwnedQ = _supabase
// //             .from('rooms')
// //             .select('*, room_settings(*)')
// //             .eq('owner_id', userId)
// //             .eq('status', 'paused')
// //             .isFilter('deleted_at', null);
// //         if (gameTypeFilter != null)
// //           pausedOwnedQ = pausedOwnedQ.eq('game_type', gameTypeFilter);
// //         final pausedOwnedRows = await pausedOwnedQ.order(
// //           'last_active_at',
// //           ascending: false,
// //         );

// //         List<dynamic> pausedMemberRows = [];
// //         if (memberRoomIds.isNotEmpty) {
// //           var pausedMemberQ = _supabase
// //               .from('rooms')
// //               .select('*, room_settings(*)')
// //               .inFilter('id', memberRoomIds)
// //               .eq('status', 'paused')
// //               .isFilter('deleted_at', null);
// //           if (gameTypeFilter != null)
// //             pausedMemberQ = pausedMemberQ.eq('game_type', gameTypeFilter);
// //           pausedMemberRows = await pausedMemberQ.order(
// //             'last_active_at',
// //             ascending: false,
// //           );
// //         }
// //         privateRows = [...privateRows, ...pausedOwnedRows, ...pausedMemberRows];
// //       }

// //       Set<String> bannedRoomIds = {};
// //       if (userId != null) {
// //         try {
// //           final bans = await _supabase
// //               .from('room_bans')
// //               .select('room_id')
// //               .eq('user_id', userId)
// //               .isFilter('lifted_at', null);
// //           bannedRoomIds = (bans as List)
// //               .map((b) => b['room_id'] as String)
// //               .toSet();
// //         } catch (_) {}
// //       }

// //       final allRows = [...publicRows, ...privateRows];
// //       final seen = <String>{};
// //       final unique = allRows.where((r) {
// //         final id = r['id'] as String;
// //         if (bannedRoomIds.contains(id)) return false;
// //         return seen.add(id);
// //       }).toList();
// //       unique.sort((a, b) {
// //         final aT = a['last_active_at'] as String? ?? '';
// //         final bT = b['last_active_at'] as String? ?? '';
// //         return bT.compareTo(aT);
// //       });
// //       return unique
// //           .map((row) => _rowToEntity(row as Map<String, dynamic>))
// //           .toList();
// //     },
// //   );

// //   Future<RoomEntity> createRoom({
// //     required String ownerId,
// //     required String name,
// //     required RoomVisibility visibility,
// //     int maxPlayers = 6,
// //     String language = 'en',
// //     String coverEmoji = '🎮',
// //   }) => guardedCall(
// //     operationName: 'createRoom',
// //     operation: () async {
// //       final existing = await _supabase
// //           .from('rooms')
// //           .select('id, name')
// //           .eq('owner_id', ownerId)
// //           .inFilter('status', ['waiting', 'in_game'])
// //           .isFilter('deleted_at', null)
// //           .maybeSingle();

// //       if (existing != null) {
// //         final roomName = existing['name'] as String? ?? 'your existing room';
// //         throw ConflictFailure(
// //           message:
// //               'You already have an open room "$roomName". '
// //               'Close it or transfer ownership before creating a new one.',
// //         );
// //       }

// //       final row = await _supabase
// //           .from('rooms')
// //           .insert({
// //             'owner_id': ownerId,
// //             'name': name,
// //             'visibility': visibility.name,
// //             'max_players': maxPlayers,
// //             'language': language,
// //             'cover_emoji': coverEmoji,
// //             'status': 'waiting',
// //           })
// //           .select()
// //           .single();

// //       String? inviteCode = row['invite_code'] as String?;
// //       if (inviteCode == null) {
// //         await Future.delayed(const Duration(milliseconds: 200));
// //         final refreshed = await _supabase
// //             .from('rooms')
// //             .select('invite_code')
// //             .eq('id', row['id'] as String)
// //             .single();
// //         inviteCode = refreshed['invite_code'] as String?;
// //       }

// //       await _supabase.from('room_members').upsert({
// //         'room_id': row['id'],
// //         'user_id': ownerId,
// //         'seat_order': 0,
// //         'role': 'player',
// //       }, onConflict: 'room_id,user_id');

// //       await _incrementRoomQuota(ownerId);

// //       return _rowToEntity(row);
// //     },
// //   );

// //   Future<RoomEntity> joinRoom({
// //     required String userId,
// //     required String roomId,
// //     String role = 'player',
// //     bool isHiddenSpectator = false,
// //   }) => guardedCall(
// //     operationName: 'joinRoom',
// //     operation: () async {
// //       final row = await _supabase
// //           .from('rooms')
// //           .select()
// //           .eq('id', roomId)
// //           .isFilter('deleted_at', null)
// //           .maybeSingle();

// //       if (row == null)
// //         throw const NotFoundFailure(
// //           message: 'Room not found or no longer available.',
// //         );

// //       final room = _rowToEntity(row);
// //       if (room.status == RoomStatus.closed)
// //         throw const NotFoundFailure(
// //           message: 'This room has been closed by the host.',
// //         );

// //       final ownerRow = await _supabase
// //           .from('room_members')
// //           .select('id')
// //           .eq('room_id', roomId)
// //           .eq('user_id', row['owner_id'] as String)
// //           .isFilter('left_at', null)
// //           .maybeSingle();
// //       if (ownerRow == null) {
// //         await _supabase
// //             .from('rooms')
// //             .update({'status': 'closed'})
// //             .eq('id', roomId);
// //         throw const NotFoundFailure(
// //           message: 'The host has left. This room is no longer available.',
// //         );
// //       }

// //       final playerCount = await _supabase
// //           .from('room_members')
// //           .select('id')
// //           .eq('room_id', roomId)
// //           .eq('role', 'player')
// //           .isFilter('left_at', null)
// //           .count(CountOption.exact);
// //       final activePlayers = playerCount.count ?? 0;
// //       if (activePlayers >= room.maxPlayers) {
// //         throw const ConflictFailure(message: 'Room is full.');
// //       }

// //       final ban = await _supabase
// //           .from('room_bans')
// //           .select('id, banned_until')
// //           .eq('room_id', roomId)
// //           .eq('user_id', userId)
// //           .isFilter('lifted_at', null)
// //           .maybeSingle();

// //       if (ban != null) {
// //         final until = ban['banned_until'];
// //         if (until == null ||
// //             DateTime.parse(until as String).isAfter(DateTime.now())) {
// //           throw const ForbiddenFailure(
// //             message: 'You are banned from this room.',
// //           );
// //         }
// //       }

// //       final seatRes = await _supabase
// //           .from('room_members')
// //           .select('id')
// //           .eq('room_id', roomId)
// //           .isFilter('left_at', null)
// //           .count(CountOption.exact);
// //       final seatOrder = seatRes.count ?? 0;

// //       await _supabase.from('room_members').upsert({
// //         'room_id': roomId,
// //         'user_id': userId,
// //         'seat_order': seatOrder,
// //         'role': role,
// //         'is_ready': false,
// //         'left_at': null,
// //         'joined_at': DateTime.now().toIso8601String(),
// //       }, onConflict: 'room_id,user_id');

// //       return room;
// //     },
// //   );

// //   Future<RoomEntity> joinByCode({
// //     required String userId,
// //     required String inviteCode,
// //     String? invitedBy,
// //   }) => guardedCall(
// //     operationName: 'joinByCode',
// //     operation: () async {
// //       final rows = await _supabase.rpc(
// //         'get_room_by_invite_code',
// //         params: {'p_code': inviteCode.toUpperCase()},
// //       );

// //       if (rows == null || (rows as List).isEmpty) {
// //         throw const NotFoundFailure(message: 'Invalid invite code.');
// //       }

// //       final row = (rows as List).first as Map<String, dynamic>;
// //       final roomId = row['id'] as String;

// //       final roomRow = await _supabase
// //           .from('rooms')
// //           .select('status, requires_approval')
// //           .eq('id', roomId)
// //           .maybeSingle();

// //       final status = roomRow?['status'] as String? ?? '';
// //       if (status == 'closed') {
// //         throw const NotFoundFailure(
// //           message: 'This room has been closed by the host.',
// //         );
// //       }

// //       final requiresApproval = roomRow?['requires_approval'] as bool? ?? false;
// //       if (requiresApproval && invitedBy == null) {
// //         await requestToJoin(userId: userId, roomId: roomId);
// //         throw const PendingApprovalFailure();
// //       }
// //       return joinRoom(userId: userId, roomId: roomId);
// //     },
// //   );

// //   Future<List<String>> getActiveSessionPlayerIds(String roomId) => guardedCall(
// //     operationName: 'getActiveSessionPlayerIds',
// //     operation: () async {
// //       final row = await _supabase
// //           .from('game_sessions')
// //           .select('player_ids')
// //           .eq('room_id', roomId)
// //           .eq('status', 'active')
// //           .order('started_at', ascending: false)
// //           .limit(1)
// //           .maybeSingle();
// //       return (row?['player_ids'] as List?)?.cast<String>() ?? [];
// //     },
// //   );

// //   Future<Set<String>> getInvitedUserIds(String roomId) => guardedCall(
// //     operationName: 'getInvitedUserIds',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('room_invites')
// //           .select('invited_user')
// //           .eq('room_id', roomId)
// //           .isFilter('declined_at', null)
// //           .gt('expires_at', DateTime.now().toIso8601String());
// //       return rows.map((r) => r['invited_user'] as String).toSet();
// //     },
// //   );

// //   Future<bool> isActiveMember({
// //     required String userId,
// //     required String roomId,
// //   }) => guardedCall(
// //     operationName: 'isActiveMember',
// //     operation: () async {
// //       final row = await _supabase
// //           .from('room_members')
// //           .select('id')
// //           .eq('room_id', roomId)
// //           .eq('user_id', userId)
// //           .isFilter('left_at', null)
// //           .maybeSingle();
// //       return row != null;
// //     },
// //   );

// //   Future<({String ownerId, bool requiresApproval})?> getRoomApprovalInfo(
// //     String roomId,
// //   ) => guardedCall(
// //     operationName: 'getRoomApprovalInfo',
// //     operation: () async {
// //       final row = await _supabase
// //           .from('rooms')
// //           .select('owner_id, requires_approval')
// //           .eq('id', roomId)
// //           .maybeSingle();
// //       if (row == null) return null;
// //       return (
// //         ownerId: row['owner_id'] as String,
// //         requiresApproval: row['requires_approval'] as bool? ?? false,
// //       );
// //     },
// //   );

// //   Future<void> sendInvite({
// //     required String roomId,
// //     required String invitedUserId,
// //   }) => guardedCall(
// //     operationName: 'sendInvite',
// //     operation: () async {
// //       await _api.post(
// //         '/v1/rooms/$roomId/invite',
// //         data: {'invited_user_id': invitedUserId},
// //       );
// //     },
// //   );

// //   Future<void> notifyFriendsRoomCreated(String roomId) => guardedCall(
// //     operationName: 'notifyFriendsRoomCreated',
// //     operation: () async {
// //       await _api.post('/v1/rooms/$roomId/notify-friends');
// //     },
// //   );

// //   Future<bool> hasValidInvite({
// //     required String userId,
// //     required String roomId,
// //   }) => guardedCall(
// //     operationName: 'hasValidInvite',
// //     operation: () async {
// //       final row = await _supabase
// //           .from('room_invites')
// //           .select('id')
// //           .eq('room_id', roomId)
// //           .eq('invited_user', userId)
// //           .isFilter('declined_at', null)
// //           .gt('expires_at', DateTime.now().toIso8601String())
// //           .maybeSingle();
// //       return row != null;
// //     },
// //   );

// //   Future<void> markInviteAccepted({
// //     required String userId,
// //     required String roomId,
// //   }) => guardedCall(
// //     operationName: 'markInviteAccepted',
// //     operation: () async {
// //       await _supabase
// //           .from('room_invites')
// //           .update({'accepted_at': DateTime.now().toIso8601String()})
// //           .eq('room_id', roomId)
// //           .eq('invited_user', userId)
// //           .isFilter('accepted_at', null);
// //     },
// //   );

// //   Future<List<Map<String, dynamic>>> getRoomModerators(String roomId) =>
// //       guardedCall(
// //         operationName: 'getRoomModerators',
// //         operation: () async {
// //           final rows = await _supabase
// //               .from('room_moderators')
// //               .select('user_id')
// //               .eq('room_id', roomId);
// //           return List<Map<String, dynamic>>.from(rows);
// //         },
// //       );

// //   static const _freeMinsToReturn = 5;
// //   static const _premiumMinsToReturn = 10;

// //   Future<void> setReturnTimer({
// //     required String roomId,
// //     required String userId,
// //     required bool isPremium,
// //   }) => guardedCall(
// //     operationName: 'setReturnTimer',
// //     operation: () async {
// //       final mins = isPremium ? _premiumMinsToReturn : _freeMinsToReturn;
// //       final returnBy = DateTime.now().add(Duration(minutes: mins));
// //       await _supabase.from('room_return_timers').upsert({
// //         'room_id': roomId,
// //         'user_id': userId,
// //         'return_by': returnBy.toIso8601String(),
// //         'is_premium': isPremium,
// //         'returned_at': null,
// //         'expired': false,
// //       }, onConflict: 'room_id,user_id');
// //     },
// //   );

// //   Future<void> clearReturnTimer({
// //     required String roomId,
// //     required String userId,
// //   }) => guardedCall(
// //     operationName: 'clearReturnTimer',
// //     operation: () async {
// //       await _supabase
// //           .from('room_return_timers')
// //           .update({'returned_at': DateTime.now().toIso8601String()})
// //           .eq('room_id', roomId)
// //           .eq('user_id', userId);
// //     },
// //   );

// //   Future<List<String>> getExpiredAwayUsers(String roomId) => guardedCall(
// //     operationName: 'getExpiredAwayUsers',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('room_return_timers')
// //           .select('user_id')
// //           .eq('room_id', roomId)
// //           .eq('expired', false)
// //           .isFilter('returned_at', null)
// //           .lt('return_by', DateTime.now().toIso8601String());
// //       return rows.map((r) => r['user_id'] as String).toList();
// //     },
// //   );

// //   Future<void> markReturnTimerExpired({
// //     required String roomId,
// //     required String userId,
// //   }) => guardedCall(
// //     operationName: 'markReturnTimerExpired',
// //     operation: () async {
// //       await _supabase
// //           .from('room_return_timers')
// //           .update({'expired': true})
// //           .eq('room_id', roomId)
// //           .eq('user_id', userId);
// //     },
// //   );

// //   Future<int> getRoomsCreatedToday(String userId) => guardedCall(
// //     operationName: 'getRoomsCreatedToday',
// //     operation: () async {
// //       final today = DateTime.now().toIso8601String().substring(0, 10);
// //       final row = await _supabase
// //           .from('room_creation_quotas')
// //           .select('rooms_today, quota_date')
// //           .eq('user_id', userId)
// //           .maybeSingle();
// //       if (row == null || row['quota_date'] != today) return 0;
// //       return row['rooms_today'] as int? ?? 0;
// //     },
// //   );

// //   Future<bool> hasHitDailyRoomLimit({
// //     required String userId,
// //     required bool isPremium,
// //   }) async {
// //     final count = await getRoomsCreatedToday(userId);
// //     final limit = isPremium ? 15 : 5;
// //     return count >= limit;
// //   }

// //   Future<void> _incrementRoomQuota(String userId) async {
// //     try {
// //       final today = DateTime.now().toIso8601String().substring(0, 10);
// //       final existing = await _supabase
// //           .from('room_creation_quotas')
// //           .select('rooms_today, quota_date')
// //           .eq('user_id', userId)
// //           .maybeSingle();
// //       if (existing == null || existing['quota_date'] != today) {
// //         await _supabase.from('room_creation_quotas').upsert({
// //           'user_id': userId,
// //           'quota_date': today,
// //           'rooms_today': 1,
// //         }, onConflict: 'user_id');
// //       } else {
// //         final current = existing['rooms_today'] as int? ?? 0;
// //         await _supabase
// //             .from('room_creation_quotas')
// //             .update({'rooms_today': current + 1, 'quota_date': today})
// //             .eq('user_id', userId);
// //       }
// //     } catch (_) {}
// //   }

// //   Future<void> clearPack(String roomId) => guardedCall(
// //     operationName: 'clearPack',
// //     operation: () async {
// //       await _supabase.from('rooms').update({'pack_id': null}).eq('id', roomId);
// //     },
// //   );

// //   Future<Set<String>> getPlayedPackIds(String roomId) => guardedCall(
// //     operationName: 'getPlayedPackIds',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('room_played_packs')
// //           .select('pack_id')
// //           .eq('room_id', roomId);
// //       return rows.map((r) => r['pack_id'] as String).toSet();
// //     },
// //   );

// //   Future<String?> runGameSessionChecks({
// //     required String userId,
// //     required String roomId,
// //     required String packId,
// //     required bool isPremium,
// //   }) => guardedCall(
// //     operationName: 'runGameSessionChecks',
// //     operation: () async {
// //       final existing = await _supabase
// //           .from('room_played_packs')
// //           .select('id')
// //           .eq('room_id', roomId)
// //           .eq('pack_id', packId)
// //           .maybeSingle();
// //       if (existing != null) return 'pack_already_played';
// //       await _supabase.from('room_played_packs').insert({
// //         'room_id': roomId,
// //         'pack_id': packId,
// //       });
// //       return null;
// //     },
// //   );

// //   Future<void> requestSpectatorAccess({
// //     required String roomId,
// //     required String userId,
// //   }) => guardedCall(
// //     operationName: 'requestSpectatorAccess',
// //     operation: () async {
// //       await _supabase.from('spectator_requests').upsert({
// //         'room_id': roomId,
// //         'user_id': userId,
// //         'status': 'pending',
// //         'decided_by': null,
// //         'decided_at': null,
// //       }, onConflict: 'room_id,user_id');
// //     },
// //   );

// //   Future<List<Map<String, dynamic>>> getPendingSpectatorRequests(
// //     String roomId,
// //   ) => guardedCall(
// //     operationName: 'getPendingSpectatorRequests',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('spectator_requests')
// //           .select('id, user_id, created_at')
// //           .eq('room_id', roomId)
// //           .eq('status', 'pending')
// //           .order('created_at');
// //       return List<Map<String, dynamic>>.from(rows);
// //     },
// //   );

// //   Future<void> decideSpectatorRequest({
// //     required String requestId,
// //     required String roomId,
// //     required String requestingUserId,
// //     required String decidedBy,
// //     required bool approve,
// //   }) => guardedCall(
// //     operationName: 'decideSpectatorRequest',
// //     operation: () async {
// //       await _supabase
// //           .from('spectator_requests')
// //           .update({
// //             'status': approve ? 'approved' : 'denied',
// //             'decided_by': decidedBy,
// //             'decided_at': DateTime.now().toIso8601String(),
// //           })
// //           .eq('id', requestId);

// //       if (approve) {
// //         await joinRoom(
// //           userId: requestingUserId,
// //           roomId: roomId,
// //           role: 'spectator',
// //         );
// //       }
// //     },
// //   );

// //   Future<void> requestToJoin({
// //     required String userId,
// //     required String roomId,
// //     String? message,
// //   }) => guardedCall(
// //     operationName: 'requestToJoin',
// //     operation: () async {
// //       await _supabase.from('room_join_requests').upsert({
// //         'room_id': roomId,
// //         'user_id': userId,
// //         'status': 'pending',
// //         'message': message,
// //         'created_at': DateTime.now().toIso8601String(),
// //       }, onConflict: 'room_id,user_id');
// //     },
// //   );

// //   Future<void> resolveJoinRequest({
// //     required String requestId,
// //     required bool approve,
// //     required String roomId,
// //     required String targetUserId,
// //   }) => guardedCall(
// //     operationName: 'resolveJoinRequest',
// //     operation: () async {
// //       await _supabase
// //           .from('room_join_requests')
// //           .update({
// //             'status': approve ? 'approved' : 'rejected',
// //             'resolved_at': DateTime.now().toIso8601String(),
// //           })
// //           .eq('id', requestId);

// //       if (approve) {
// //         final roomInfo = await _supabase
// //             .from('rooms')
// //             .select('status')
// //             .eq('id', roomId)
// //             .maybeSingle();
// //         final settingsInfo = await _supabase
// //             .from('room_settings')
// //             .select('allow_spectators')
// //             .eq('room_id', roomId)
// //             .maybeSingle();
// //         final inGame = roomInfo?['status'] == 'in_game';
// //         final allowSpectators =
// //             settingsInfo?['allow_spectators'] as bool? ?? false;
// //         final role = (inGame && allowSpectators) ? 'spectator' : 'player';
// //         await joinRoom(userId: targetUserId, roomId: roomId, role: role);
// //       }
// //     },
// //   );

// //   Future<List<Map<String, dynamic>>> getPendingRequests(String roomId) =>
// //       guardedCall(
// //         operationName: 'getPendingRequests',
// //         operation: () async {
// //           final rows = await _supabase
// //               .from('room_join_requests')
// //               .select('id, user_id, message, created_at')
// //               .eq('room_id', roomId)
// //               .eq('status', 'pending')
// //               .order('created_at');
// //           final requests = (rows as List).cast<Map<String, dynamic>>();

// //           final enriched = <Map<String, dynamic>>[];
// //           for (final req in requests) {
// //             final uid = req['user_id'] as String;
// //             final profileRows = await _supabase
// //                 .from('profiles')
// //                 .select('display_name, username, avatar_url')
// //                 .eq('id', uid)
// //                 .limit(1);
// //             enriched.add({
// //               ...req,
// //               'profiles': profileRows.isNotEmpty ? profileRows.first : {},
// //             });
// //           }
// //           return enriched;
// //         },
// //       );

// //   Future<String?> getJoinRequestStatus({
// //     required String userId,
// //     required String roomId,
// //   }) => guardedCall(
// //     operationName: 'getJoinRequestStatus',
// //     operation: () async {
// //       final row = await _supabase
// //           .from('room_join_requests')
// //           .select('status')
// //           .eq('room_id', roomId)
// //           .eq('user_id', userId)
// //           .maybeSingle();
// //       return row?['status'] as String?;
// //     },
// //   );

// //   Future<void> leaveRoom({required String userId, required String roomId}) =>
// //       guardedCall(
// //         operationName: 'leaveRoom',
// //         operation: () async {
// //           await _supabase
// //               .from('room_members')
// //               .update({'left_at': DateTime.now().toIso8601String()})
// //               .eq('room_id', roomId)
// //               .eq('user_id', userId)
// //               .isFilter('left_at', null);
// //         },
// //       );

// //   Future<Map<String, dynamic>?> getActiveMembership(String userId) =>
// //       guardedCall(
// //         operationName: 'getActiveMembership',
// //         operation: () async {
// //           final rows = await _supabase
// //               .from('room_members')
// //               .select(
// //                 'room_id, rooms!inner(id, name, owner_id, status, deleted_at)',
// //               )
// //               .eq('user_id', userId)
// //               .isFilter('left_at', null)
// //               .inFilter('rooms.status', ['waiting', 'in_game', 'paused'])
// //               .isFilter('rooms.deleted_at', null)
// //               .limit(1);

// //           if (rows.isEmpty) return null;
// //           final room = rows.first['rooms'] as Map<String, dynamic>;
// //           return {
// //             'room_id': room['id'],
// //             'room_name': room['name'],
// //             'is_owner': room['owner_id'] == userId,
// //             'status': room['status'],
// //           };
// //         },
// //       );

// //   Future<void> forceLeaveRoom({
// //     required String userId,
// //     required String roomId,
// //   }) => guardedCall(
// //     operationName: 'forceLeaveRoom',
// //     operation: () async {
// //       final room = await _supabase
// //           .from('rooms')
// //           .select('owner_id')
// //           .eq('id', roomId)
// //           .maybeSingle();

// //       await _supabase
// //           .from('room_members')
// //           .update({'left_at': DateTime.now().toIso8601String()})
// //           .eq('room_id', roomId)
// //           .eq('user_id', userId)
// //           .isFilter('left_at', null);

// //       if (room != null && room['owner_id'] == userId) {
// //         await _supabase
// //             .from('rooms')
// //             .update({
// //               'status': 'closed',
// //               'deleted_at': DateTime.now().toIso8601String(),
// //               'updated_at': DateTime.now().toIso8601String(),
// //             })
// //             .eq('id', roomId);
// //       }
// //     },
// //   );

// //   Future<RoomEntity?> getActiveOwnedRoom(String userId) => guardedCall(
// //     operationName: 'getActiveOwnedRoom',
// //     operation: () async {
// //       final row = await _supabase
// //           .from('rooms')
// //           .select('*, room_settings(*)')
// //           .eq('owner_id', userId)
// //           .inFilter('status', ['waiting', 'in_game', 'paused'])
// //           .isFilter('deleted_at', null)
// //           .order('last_active_at', ascending: false)
// //           .limit(1)
// //           .maybeSingle();
// //       return row != null ? _rowToEntity(row) : null;
// //     },
// //   );

// //   Future<void> updateStatus(
// //     String roomId,
// //     RoomStatus status, {
// //     String? gameType,
// //   }) => guardedCall(
// //     operationName: 'updateStatus',
// //     operation: () async {
// //       final update = <String, dynamic>{
// //         'status': status.toDbString(),
// //         'last_active_at': DateTime.now().toIso8601String(),
// //       };
// //       if (gameType != null) update['game_type'] = gameType;
// //       if (status == RoomStatus.waiting) {
// //         update['pack_id'] = null;
// //       }
// //       await _supabase.from('rooms').update(update).eq('id', roomId);
// //     },
// //   );

// //   Future<void> updateSettings(String roomId, RoomSettingsEntity settings) =>
// //       guardedCall(
// //         operationName: 'updateSettings',
// //         operation: () async {
// //           await _supabase
// //               .from('room_settings')
// //               .update(settings.toMap())
// //               .eq('room_id', roomId);
// //         },
// //       );

// //   Future<(RoomEntity, List<RoomMemberEntity>, RoomSettingsEntity, List<String>)>
// //   getRoomWithDetails(String roomId) => guardedCall(
// //     operationName: 'getRoomWithDetails',
// //     operation: () async {
// //       final roomRow = await _supabase
// //           .from('rooms')
// //           .select('*, room_settings(*)')
// //           .eq('id', roomId)
// //           .single();

// //       final membersRows = await _supabase
// //           .from('room_members')
// //           .select(
// //             '*, profiles(id, username, display_name, avatar_url, avatar_config, is_premium, premium_tier)',
// //           )
// //           .eq('room_id', roomId)
// //           .isFilter('left_at', null)
// //           .order('seat_order');

// //       final modRows = await _supabase
// //           .from('room_moderators')
// //           .select('user_id')
// //           .eq('room_id', roomId);

// //       final modIds = modRows.map((r) => r['user_id'] as String).toSet();
// //       final ownerId = roomRow['owner_id'] as String;

// //       final members = membersRows.map((r) {
// //         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
// //         final uid = profile['id'] as String? ?? r['user_id'] as String;
// //         return RoomMemberEntity(
// //           userId: uid,
// //           displayName:
// //               profile['display_name'] as String? ??
// //               profile['username'] as String? ??
// //               'Player',
// //           avatarUrl: profile['avatar_url'] as String?,
// //           avatarConfig: profile['avatar_config'] != null
// //               ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
// //               : null,
// //           seatOrder: r['seat_order'] as int? ?? 0,
// //           isReady: r['is_ready'] as bool? ?? false,
// //           isOwner: uid == ownerId,
// //           isModerator: modIds.contains(uid),
// //           isSpectator: (r['role'] as String?) == 'spectator',
// //           isHiddenSpectator: r['is_hidden_spectator'] as bool? ?? false,
// //           isMuted: r['is_muted'] as bool? ?? false,
// //           isAway: r['is_away'] as bool? ?? false,
// //           leftDefinitively: r['left_definitively'] as bool? ?? false,
// //           isPremium: profile['is_premium'] as bool? ?? false,
// //           premiumTier: profile['premium_tier'] as String?,
// //           joinedAt: r['joined_at'] != null
// //               ? DateTime.tryParse(r['joined_at'] as String)
// //               : null,
// //         );
// //       }).toList();

// //       final settingsRow = roomRow['room_settings'] as Map<String, dynamic>?;
// //       final settings = settingsRow != null
// //           ? RoomSettingsEntity.fromMap(settingsRow)
// //           : const RoomSettingsEntity();

// //       final mutedRows = await _supabase
// //           .from('room_members')
// //           .select('user_id')
// //           .eq('room_id', roomId)
// //           .eq('is_muted', true)
// //           .isFilter('left_at', null);

// //       final mutedIds = mutedRows.map((r) => r['user_id'] as String).toList();

// //       return (_rowToEntity(roomRow), members, settings, mutedIds);
// //     },
// //   );

// //   Future<List<ChatMessageEntity>> getChatHistory(
// //     String roomId, {
// //     int limit = 50,
// //     String? before,
// //   }) => guardedCall(
// //     operationName: 'getChatHistory',
// //     operation: () async {
// //       var q = _supabase
// //           .from('room_chat_messages')
// //           .select('*, profiles!user_id(id, display_name, avatar_url)')
// //           .eq('room_id', roomId)
// //           .eq('is_deleted', false)
// //           .eq('is_system', false);

// //       if (before != null) {
// //         final cursor = await _supabase
// //             .from('room_chat_messages')
// //             .select('created_at')
// //             .eq('id', before)
// //             .single();
// //         q = q.lt('created_at', cursor['created_at']);
// //       }

// //       final rows = await q.order('created_at', ascending: false).limit(limit);

// //       return rows.reversed.map(_chatRowToEntity).toList();
// //     },
// //   );

// //   Future<void> persistChatMessage({
// //     required String roomId,
// //     required String userId,
// //     required String content,
// //     String? replyToId,
// //     String? replyToContent,
// //     String? replyToDisplayName,
// //     bool isAnonymous = false,
// //   }) => guardedCall(
// //     operationName: 'persistChatMessage',
// //     operation: () async {
// //       await _supabase.from('room_chat_messages').insert({
// //         'room_id': roomId,
// //         'user_id': userId,
// //         'content': content,
// //         if (replyToId != null) 'reply_to_id': replyToId,
// //         if (replyToContent != null) 'reply_to_content': replyToContent,
// //         if (replyToDisplayName != null)
// //           'reply_to_display_name': replyToDisplayName,
// //       });
// //     },
// //   );

// //   Future<void> deleteChatMessage(String messageId) => guardedCall(
// //     operationName: 'deleteChatMessage',
// //     operation: () async {
// //       await _supabase
// //           .from('room_chat_messages')
// //           .update({'is_deleted': true})
// //           .eq('id', messageId);
// //     },
// //   );

// //   Future<void> kickMember(String roomId, String targetUserId) => guardedCall(
// //     operationName: 'kickMember',
// //     operation: () async {
// //       await _supabase
// //           .from('room_members')
// //           .update({
// //             'left_at': DateTime.now().toIso8601String(),
// //             'kicked_at': DateTime.now().toIso8601String(),
// //           })
// //           .eq('room_id', roomId)
// //           .eq('user_id', targetUserId)
// //           .isFilter('left_at', null);
// //     },
// //   );

// //   Future<void> muteMember(
// //     String roomId,
// //     String targetUserId, {
// //     required bool muted,
// //   }) => guardedCall(
// //     operationName: 'muteMember',
// //     operation: () async {
// //       await _supabase
// //           .from('room_members')
// //           .update({'is_muted': muted})
// //           .eq('room_id', roomId)
// //           .eq('user_id', targetUserId);
// //     },
// //   );

// //   Future<void> banMember({
// //     required String roomId,
// //     required String targetUserId,
// //     required String bannedBy,
// //     String? reason,
// //     Duration? duration,
// //   }) => guardedCall(
// //     operationName: 'banMember',
// //     operation: () async {
// //       await _supabase.from('room_bans').upsert({
// //         'room_id': roomId,
// //         'user_id': targetUserId,
// //         'banned_by': bannedBy,
// //         'reason': reason,
// //         'banned_until': null,
// //       }, onConflict: 'room_id,user_id');
// //       await kickMember(roomId, targetUserId);
// //     },
// //   );

// //   Future<List<Map<String, dynamic>>> getBannedMembers(String roomId) =>
// //       guardedCall(
// //         operationName: 'getBannedMembers',
// //         operation: () async {
// //           final bans = await _supabase
// //               .from('room_bans')
// //               .select('user_id, reason, banned_until')
// //               .eq('room_id', roomId)
// //               .isFilter('lifted_at', null);
// //           final banList = (bans as List).cast<Map<String, dynamic>>();
// //           if (banList.isEmpty) return banList;
// //           final userIds = banList.map((b) => b['user_id'] as String).toList();
// //           final profiles = await _supabase
// //               .from('profiles')
// //               .select('id, display_name, username')
// //               .inFilter('id', userIds);
// //           final nameMap = {
// //             for (final p in (profiles as List))
// //               p['id'] as String:
// //                   p['display_name'] as String? ??
// //                   p['username'] as String? ??
// //                   '?',
// //           };
// //           return banList
// //               .map(
// //                 (b) => {
// //                   ...b,
// //                   'display_name':
// //                       nameMap[b['user_id'] as String] ??
// //                       (b['user_id'] as String).substring(0, 8),
// //                 },
// //               )
// //               .toList();
// //         },
// //       );

// //   Future<void> liftBan(String roomId, String targetUserId) => guardedCall(
// //     operationName: 'liftBan',
// //     operation: () async {
// //       await _supabase
// //           .from('room_bans')
// //           .update({'lifted_at': DateTime.now().toIso8601String()})
// //           .eq('room_id', roomId)
// //           .eq('user_id', targetUserId)
// //           .isFilter('lifted_at', null);
// //     },
// //   );

// //   Future<void> setMemberAway(
// //     String roomId,
// //     String userId, {
// //     required bool away,
// //   }) => guardedCall(
// //     operationName: 'setMemberAway',
// //     operation: () async {
// //       await _supabase
// //           .from('room_members')
// //           .update({
// //             'is_away': away,
// //             'left_at': away ? DateTime.now().toIso8601String() : null,
// //           })
// //           .eq('room_id', roomId)
// //           .eq('user_id', userId);
// //     },
// //   );

// //   Future<void> setMemberDefinitiveLeave(String roomId, String userId) =>
// //       guardedCall(
// //         operationName: 'setMemberDefinitiveLeave',
// //         operation: () async {
// //           await _supabase
// //               .from('room_members')
// //               .update({'role': 'spectator', 'left_definitively': true})
// //               .eq('room_id', roomId)
// //               .eq('user_id', userId);
// //         },
// //       );

// //   Future<void> transferOwnership(String roomId, String newOwnerId) =>
// //       guardedCall(
// //         operationName: 'transferOwnership',
// //         operation: () async {
// //           await _supabase
// //               .from('rooms')
// //               .update({'owner_id': newOwnerId})
// //               .eq('id', roomId);
// //         },
// //       );

// //   Future<void> grantModerator(String roomId, String userId, String grantedBy) =>
// //       guardedCall(
// //         operationName: 'grantModerator',
// //         operation: () async {
// //           await _supabase.from('room_moderators').upsert({
// //             'room_id': roomId,
// //             'user_id': userId,
// //             'granted_by': grantedBy,
// //           }, onConflict: 'room_id,user_id');
// //         },
// //       );

// //   Future<void> revokeModerator(String roomId, String userId) => guardedCall(
// //     operationName: 'revokeModerator',
// //     operation: () async {
// //       await _supabase
// //           .from('room_moderators')
// //           .delete()
// //           .eq('room_id', roomId)
// //           .eq('user_id', userId);
// //     },
// //   );

// //   Future<void> softDeleteRoom(String roomId) => guardedCall(
// //     operationName: 'softDeleteRoom',
// //     operation: () async {
// //       await _supabase
// //           .from('rooms')
// //           .update({
// //             'status': 'closed',
// //             'deleted_at': DateTime.now().toIso8601String(),
// //           })
// //           .eq('id', roomId);
// //     },
// //   );

// //   RoomEntity _rowToEntity(Map<String, dynamic> row) {
// //     return RoomEntity(
// //       id: row['id'] as String,
// //       ownerId: row['owner_id'] as String,
// //       name: row['name'] as String,
// //       status: RoomStatus.fromString(row['status'] as String? ?? 'waiting'),
// //       visibility: RoomVisibility.fromString(
// //         row['visibility'] as String? ?? 'public',
// //       ),
// //       maxPlayers: row['max_players'] as int? ?? 6,
// //       currentPlayers: row['current_players'] as int? ?? 0,
// //       inviteCode: row['invite_code'] as String?,
// //       gameType: row['game_type'] != null
// //           ? _parseGameType(row['game_type'] as String)
// //           : null,
// //       packId: row['pack_id'] as String?,
// //       language: row['language'] as String? ?? 'en',
// //       allowSpicy: row['allow_spicy'] as bool? ?? false,
// //       coverEmoji: row['cover_emoji'] as String? ?? '🎮',
// //       lastActiveAt: row['last_active_at'] != null
// //           ? DateTime.tryParse(row['last_active_at'] as String)
// //           : null,
// //       createdAt: row['created_at'] != null
// //           ? DateTime.tryParse(row['created_at'] as String)
// //           : null,
// //     );
// //   }

// //   ChatMessageEntity _chatRowToEntity(Map<String, dynamic> row) {
// //     final profile = row['profiles'] as Map<String, dynamic>? ?? {};
// //     return ChatMessageEntity(
// //       id: row['id'] as String,
// //       roomId: row['room_id'] as String,
// //       userId: row['user_id'] as String,
// //       displayName: profile['display_name'] as String? ?? 'Player',
// //       avatarUrl: profile['avatar_url'] as String?,
// //       content: row['content'] as String,
// //       createdAt: DateTime.parse(row['created_at'] as String),
// //       isDeleted: row['is_deleted'] as bool? ?? false,
// //       replyToId: row['reply_to_id'] as String?,
// //       replyToContent: row['reply_to_content'] as String?,
// //       replyToDisplayName: row['reply_to_display_name'] as String?,
// //     );
// //   }

// //   GameType? _parseGameType(String s) {
// //     return switch (s) {
// //       'truth_or_dare' => GameType.truthOrDare,
// //       'never_have_i_ever' => GameType.neverHaveIEver,
// //       'meme_game' => GameType.memeGame,
// //       _ => null,
// //     };
// //   }
// // }

// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../../core/data/base_repository.dart';
// import '../../../core/errors/failures.dart';
// import '../../../core/network/api_client.dart';
// import '../domain/room_entity.dart';
// import '../../games/engine/base_game_engine.dart';

// class RoomRepository extends BaseRepository {
//   final _api = ApiClient.instance;
//   RoomRepository._();
//   static final RoomRepository _instance = RoomRepository._();
//   static RoomRepository get instance => _instance;

//   final _supabase = Supabase.instance.client;

//   Future<List<RoomEntity>> getPublicRooms({
//     int limit = 20,
//     int offset = 0,
//     String? gameTypeFilter,
//     String? userId,
//   }) => guardedCall(
//     operationName: 'getPublicRooms',
//     operation: () async {
//       var q = _supabase
//           .from('rooms')
//           .select('*, room_settings(*)')
//           .eq('visibility', 'public')
//           .inFilter('status', ['waiting', 'in_game'])
//           .isFilter('deleted_at', null);
//       if (gameTypeFilter != null) q = q.eq('game_type', gameTypeFilter);
//       final publicRows = await q
//           .order('last_active_at', ascending: false)
//           .range(offset, offset + limit - 1);

//       List<dynamic> privateRows = [];
//       if (userId != null) {
//         var ownedQ = _supabase
//             .from('rooms')
//             .select('*, room_settings(*)')
//             .eq('owner_id', userId)
//             .eq('visibility', 'private')
//             .inFilter('status', ['waiting', 'in_game', 'paused'])
//             .isFilter('deleted_at', null);
//         if (gameTypeFilter != null)
//           ownedQ = ownedQ.eq('game_type', gameTypeFilter);
//         final ownedRows = await ownedQ.order(
//           'last_active_at',
//           ascending: false,
//         );

//         final membershipRows = await _supabase
//             .from('room_members')
//             .select('room_id')
//             .eq('user_id', userId)
//             .isFilter('left_at', null);
//         final memberRoomIds = (membershipRows as List)
//             .map((r) => r['room_id'] as String)
//             .toList();

//         if (memberRoomIds.isNotEmpty) {
//           var memberQ = _supabase
//               .from('rooms')
//               .select('*, room_settings(*)')
//               .eq('visibility', 'private')
//               .inFilter('id', memberRoomIds)
//               .inFilter('status', ['waiting', 'in_game', 'paused'])
//               .isFilter('deleted_at', null);
//           if (gameTypeFilter != null)
//             memberQ = memberQ.eq('game_type', gameTypeFilter);
//           final memberRoomRows = await memberQ.order(
//             'last_active_at',
//             ascending: false,
//           );
//           privateRows = [...ownedRows, ...memberRoomRows];
//         } else {
//           privateRows = ownedRows;
//         }

//         var pausedOwnedQ = _supabase
//             .from('rooms')
//             .select('*, room_settings(*)')
//             .eq('owner_id', userId)
//             .eq('status', 'paused')
//             .isFilter('deleted_at', null);
//         if (gameTypeFilter != null)
//           pausedOwnedQ = pausedOwnedQ.eq('game_type', gameTypeFilter);
//         final pausedOwnedRows = await pausedOwnedQ.order(
//           'last_active_at',
//           ascending: false,
//         );

//         List<dynamic> pausedMemberRows = [];
//         if (memberRoomIds.isNotEmpty) {
//           var pausedMemberQ = _supabase
//               .from('rooms')
//               .select('*, room_settings(*)')
//               .inFilter('id', memberRoomIds)
//               .eq('status', 'paused')
//               .isFilter('deleted_at', null);
//           if (gameTypeFilter != null)
//             pausedMemberQ = pausedMemberQ.eq('game_type', gameTypeFilter);
//           pausedMemberRows = await pausedMemberQ.order(
//             'last_active_at',
//             ascending: false,
//           );
//         }
//         privateRows = [...privateRows, ...pausedOwnedRows, ...pausedMemberRows];
//       }

//       Set<String> bannedRoomIds = {};
//       if (userId != null) {
//         try {
//           final bans = await _supabase
//               .from('room_bans')
//               .select('room_id')
//               .eq('user_id', userId)
//               .isFilter('lifted_at', null);
//           bannedRoomIds = (bans as List)
//               .map((b) => b['room_id'] as String)
//               .toSet();
//         } catch (_) {}
//       }

//       final allRows = [...publicRows, ...privateRows];
//       final seen = <String>{};
//       final unique = allRows.where((r) {
//         final id = r['id'] as String;
//         if (bannedRoomIds.contains(id)) return false;
//         return seen.add(id);
//       }).toList();
//       unique.sort((a, b) {
//         final aT = a['last_active_at'] as String? ?? '';
//         final bT = b['last_active_at'] as String? ?? '';
//         return bT.compareTo(aT);
//       });
//       return unique
//           .map((row) => _rowToEntity(row as Map<String, dynamic>))
//           .toList();
//     },
//   );

//   Future<RoomEntity> createRoom({
//     required String ownerId,
//     required String name,
//     required RoomVisibility visibility,
//     int maxPlayers = 6,
//     String language = 'en',
//     String coverEmoji = '🎮',
//   }) => guardedCall(
//     operationName: 'createRoom',
//     operation: () async {
//       final existing = await _supabase
//           .from('rooms')
//           .select('id, name')
//           .eq('owner_id', ownerId)
//           .inFilter('status', ['waiting', 'in_game'])
//           .isFilter('deleted_at', null)
//           .maybeSingle();

//       if (existing != null) {
//         final roomName = existing['name'] as String? ?? 'your existing room';
//         throw ConflictFailure(
//           message:
//               'You already have an open room "$roomName". '
//               'Close it or transfer ownership before creating a new one.',
//         );
//       }

//       final row = await _supabase
//           .from('rooms')
//           .insert({
//             'owner_id': ownerId,
//             'name': name,
//             'visibility': visibility.name,
//             'max_players': maxPlayers,
//             'language': language,
//             'cover_emoji': coverEmoji,
//             'status': 'waiting',
//           })
//           .select()
//           .single();

//       String? inviteCode = row['invite_code'] as String?;
//       if (inviteCode == null) {
//         await Future.delayed(const Duration(milliseconds: 200));
//         final refreshed = await _supabase
//             .from('rooms')
//             .select('invite_code')
//             .eq('id', row['id'] as String)
//             .single();
//         inviteCode = refreshed['invite_code'] as String?;
//       }

//       await _supabase.from('room_members').upsert({
//         'room_id': row['id'],
//         'user_id': ownerId,
//         'seat_order': 0,
//         'role': 'player',
//       }, onConflict: 'room_id,user_id');

//       await _incrementRoomQuota(ownerId);

//       return _rowToEntity(row);
//     },
//   );

//   Future<RoomEntity> joinRoom({
//     required String userId,
//     required String roomId,
//     String role = 'player',
//     bool isHiddenSpectator = false,
//   }) => guardedCall(
//     operationName: 'joinRoom',
//     operation: () async {
//       final row = await _supabase
//           .from('rooms')
//           .select()
//           .eq('id', roomId)
//           .isFilter('deleted_at', null)
//           .maybeSingle();

//       if (row == null)
//         throw const NotFoundFailure(
//           message: 'Room not found or no longer available.',
//         );

//       final room = _rowToEntity(row);
//       if (room.status == RoomStatus.closed)
//         throw const NotFoundFailure(
//           message: 'This room has been closed by the host.',
//         );

//       final ownerRow = await _supabase
//           .from('room_members')
//           .select('id')
//           .eq('room_id', roomId)
//           .eq('user_id', row['owner_id'] as String)
//           .isFilter('left_at', null)
//           .maybeSingle();
//       if (ownerRow == null) {
//         await _supabase
//             .from('rooms')
//             .update({'status': 'closed'})
//             .eq('id', roomId);
//         throw const NotFoundFailure(
//           message: 'The host has left. This room is no longer available.',
//         );
//       }

//       final playerCount = await _supabase
//           .from('room_members')
//           .select('id')
//           .eq('room_id', roomId)
//           .eq('role', 'player')
//           .isFilter('left_at', null)
//           .count(CountOption.exact);
//       final activePlayers = playerCount.count ?? 0;
//       if (activePlayers >= room.maxPlayers) {
//         throw const ConflictFailure(message: 'Room is full.');
//       }

//       final ban = await _supabase
//           .from('room_bans')
//           .select('id, banned_until')
//           .eq('room_id', roomId)
//           .eq('user_id', userId)
//           .isFilter('lifted_at', null)
//           .maybeSingle();

//       if (ban != null) {
//         final until = ban['banned_until'];
//         if (until == null ||
//             DateTime.parse(until as String).isAfter(DateTime.now())) {
//           throw const ForbiddenFailure(
//             message: 'You are banned from this room.',
//           );
//         }
//       }

//       final seatRes = await _supabase
//           .from('room_members')
//           .select('id')
//           .eq('room_id', roomId)
//           .isFilter('left_at', null)
//           .count(CountOption.exact);
//       final seatOrder = seatRes.count ?? 0;

//       await _supabase.from('room_members').upsert({
//         'room_id': roomId,
//         'user_id': userId,
//         'seat_order': seatOrder,
//         'role': role == 'spectator_anon' ? 'spectator' : role,
//         'is_hidden_spectator': isHiddenSpectator || role == 'spectator_anon',
//         'is_ready': false,
//         'left_at': null,
//         'joined_at': DateTime.now().toIso8601String(),
//       }, onConflict: 'room_id,user_id');

//       return room;
//     },
//   );

//   Future<RoomEntity> joinByCode({
//     required String userId,
//     required String inviteCode,
//     String? invitedBy,
//   }) => guardedCall(
//     operationName: 'joinByCode',
//     operation: () async {
//       final rows = await _supabase.rpc(
//         'get_room_by_invite_code',
//         params: {'p_code': inviteCode.toUpperCase()},
//       );

//       if (rows == null || (rows as List).isEmpty) {
//         throw const NotFoundFailure(message: 'Invalid invite code.');
//       }

//       final row = (rows as List).first as Map<String, dynamic>;
//       final roomId = row['id'] as String;

//       final roomRow = await _supabase
//           .from('rooms')
//           .select('status, requires_approval')
//           .eq('id', roomId)
//           .maybeSingle();

//       final status = roomRow?['status'] as String? ?? '';
//       if (status == 'closed') {
//         throw const NotFoundFailure(
//           message: 'This room has been closed by the host.',
//         );
//       }

//       final requiresApproval = roomRow?['requires_approval'] as bool? ?? false;
//       if (requiresApproval && invitedBy == null) {
//         await requestToJoin(userId: userId, roomId: roomId);
//         throw const PendingApprovalFailure();
//       }
//       return joinRoom(userId: userId, roomId: roomId);
//     },
//   );

//   Future<List<String>> getActiveSessionPlayerIds(String roomId) => guardedCall(
//     operationName: 'getActiveSessionPlayerIds',
//     operation: () async {
//       final row = await _supabase
//           .from('game_sessions')
//           .select('player_ids')
//           .eq('room_id', roomId)
//           .eq('status', 'active')
//           .order('started_at', ascending: false)
//           .limit(1)
//           .maybeSingle();
//       return (row?['player_ids'] as List?)?.cast<String>() ?? [];
//     },
//   );

//   Future<Set<String>> getInvitedUserIds(String roomId) => guardedCall(
//     operationName: 'getInvitedUserIds',
//     operation: () async {
//       final rows = await _supabase
//           .from('room_invites')
//           .select('invited_user')
//           .eq('room_id', roomId)
//           .isFilter('declined_at', null)
//           .gt('expires_at', DateTime.now().toIso8601String());
//       return rows.map((r) => r['invited_user'] as String).toSet();
//     },
//   );

//   Future<bool> isActiveMember({
//     required String userId,
//     required String roomId,
//   }) => guardedCall(
//     operationName: 'isActiveMember',
//     operation: () async {
//       final row = await _supabase
//           .from('room_members')
//           .select('id')
//           .eq('room_id', roomId)
//           .eq('user_id', userId)
//           .isFilter('left_at', null)
//           .maybeSingle();
//       return row != null;
//     },
//   );

//   Future<({String ownerId, bool requiresApproval})?> getRoomApprovalInfo(
//     String roomId,
//   ) => guardedCall(
//     operationName: 'getRoomApprovalInfo',
//     operation: () async {
//       final row = await _supabase
//           .from('rooms')
//           .select('owner_id, requires_approval')
//           .eq('id', roomId)
//           .maybeSingle();
//       if (row == null) return null;
//       return (
//         ownerId: row['owner_id'] as String,
//         requiresApproval: row['requires_approval'] as bool? ?? false,
//       );
//     },
//   );

//   Future<void> sendInvite({
//     required String roomId,
//     required String invitedUserId,
//   }) => guardedCall(
//     operationName: 'sendInvite',
//     operation: () async {
//       await _api.post(
//         '/v1/rooms/$roomId/invite',
//         data: {'invited_user_id': invitedUserId},
//       );
//     },
//   );

//   Future<void> notifyFriendsRoomCreated(String roomId) => guardedCall(
//     operationName: 'notifyFriendsRoomCreated',
//     operation: () async {
//       await _api.post('/v1/rooms/$roomId/notify-friends');
//     },
//   );

//   Future<bool> hasValidInvite({
//     required String userId,
//     required String roomId,
//   }) => guardedCall(
//     operationName: 'hasValidInvite',
//     operation: () async {
//       final row = await _supabase
//           .from('room_invites')
//           .select('id')
//           .eq('room_id', roomId)
//           .eq('invited_user', userId)
//           .isFilter('declined_at', null)
//           .gt('expires_at', DateTime.now().toIso8601String())
//           .maybeSingle();
//       return row != null;
//     },
//   );

//   Future<void> markInviteAccepted({
//     required String userId,
//     required String roomId,
//   }) => guardedCall(
//     operationName: 'markInviteAccepted',
//     operation: () async {
//       await _supabase
//           .from('room_invites')
//           .update({'accepted_at': DateTime.now().toIso8601String()})
//           .eq('room_id', roomId)
//           .eq('invited_user', userId)
//           .isFilter('accepted_at', null);
//     },
//   );

//   Future<List<Map<String, dynamic>>> getRoomModerators(String roomId) =>
//       guardedCall(
//         operationName: 'getRoomModerators',
//         operation: () async {
//           final rows = await _supabase
//               .from('room_moderators')
//               .select('user_id')
//               .eq('room_id', roomId);
//           return List<Map<String, dynamic>>.from(rows);
//         },
//       );

//   static const _freeMinsToReturn = 5;
//   static const _premiumMinsToReturn = 10;

//   Future<void> setReturnTimer({
//     required String roomId,
//     required String userId,
//     required bool isPremium,
//   }) => guardedCall(
//     operationName: 'setReturnTimer',
//     operation: () async {
//       final mins = isPremium ? _premiumMinsToReturn : _freeMinsToReturn;
//       final returnBy = DateTime.now().add(Duration(minutes: mins));
//       await _supabase.from('room_return_timers').upsert({
//         'room_id': roomId,
//         'user_id': userId,
//         'return_by': returnBy.toIso8601String(),
//         'is_premium': isPremium,
//         'returned_at': null,
//         'expired': false,
//       }, onConflict: 'room_id,user_id');
//     },
//   );

//   Future<void> clearReturnTimer({
//     required String roomId,
//     required String userId,
//   }) => guardedCall(
//     operationName: 'clearReturnTimer',
//     operation: () async {
//       await _supabase
//           .from('room_return_timers')
//           .update({'returned_at': DateTime.now().toIso8601String()})
//           .eq('room_id', roomId)
//           .eq('user_id', userId);
//     },
//   );

//   Future<List<String>> getExpiredAwayUsers(String roomId) => guardedCall(
//     operationName: 'getExpiredAwayUsers',
//     operation: () async {
//       final rows = await _supabase
//           .from('room_return_timers')
//           .select('user_id')
//           .eq('room_id', roomId)
//           .eq('expired', false)
//           .isFilter('returned_at', null)
//           .lt('return_by', DateTime.now().toIso8601String());
//       return rows.map((r) => r['user_id'] as String).toList();
//     },
//   );

//   Future<void> markReturnTimerExpired({
//     required String roomId,
//     required String userId,
//   }) => guardedCall(
//     operationName: 'markReturnTimerExpired',
//     operation: () async {
//       await _supabase
//           .from('room_return_timers')
//           .update({'expired': true})
//           .eq('room_id', roomId)
//           .eq('user_id', userId);
//     },
//   );

//   Future<int> getRoomsCreatedToday(String userId) => guardedCall(
//     operationName: 'getRoomsCreatedToday',
//     operation: () async {
//       final today = DateTime.now().toIso8601String().substring(0, 10);
//       final row = await _supabase
//           .from('room_creation_quotas')
//           .select('rooms_today, quota_date')
//           .eq('user_id', userId)
//           .maybeSingle();
//       if (row == null || row['quota_date'] != today) return 0;
//       return row['rooms_today'] as int? ?? 0;
//     },
//   );

//   Future<bool> hasHitDailyRoomLimit({
//     required String userId,
//     required bool isPremium,
//   }) async {
//     final count = await getRoomsCreatedToday(userId);
//     final limit = isPremium ? 15 : 5;
//     return count >= limit;
//   }

//   Future<void> _incrementRoomQuota(String userId) async {
//     try {
//       final today = DateTime.now().toIso8601String().substring(0, 10);
//       final existing = await _supabase
//           .from('room_creation_quotas')
//           .select('rooms_today, quota_date')
//           .eq('user_id', userId)
//           .maybeSingle();
//       if (existing == null || existing['quota_date'] != today) {
//         await _supabase.from('room_creation_quotas').upsert({
//           'user_id': userId,
//           'quota_date': today,
//           'rooms_today': 1,
//         }, onConflict: 'user_id');
//       } else {
//         final current = existing['rooms_today'] as int? ?? 0;
//         await _supabase
//             .from('room_creation_quotas')
//             .update({'rooms_today': current + 1, 'quota_date': today})
//             .eq('user_id', userId);
//       }
//     } catch (_) {}
//   }

//   Future<void> clearPack(String roomId) => guardedCall(
//     operationName: 'clearPack',
//     operation: () async {
//       await _supabase.from('rooms').update({'pack_id': null}).eq('id', roomId);
//     },
//   );

//   Future<Set<String>> getPlayedPackIds(String roomId) => guardedCall(
//     operationName: 'getPlayedPackIds',
//     operation: () async {
//       final rows = await _supabase
//           .from('room_played_packs')
//           .select('pack_id')
//           .eq('room_id', roomId);
//       return rows.map((r) => r['pack_id'] as String).toSet();
//     },
//   );

//   Future<String?> runGameSessionChecks({
//     required String userId,
//     required String roomId,
//     required String packId,
//     required bool isPremium,
//   }) => guardedCall(
//     operationName: 'runGameSessionChecks',
//     operation: () async {
//       final existing = await _supabase
//           .from('room_played_packs')
//           .select('id')
//           .eq('room_id', roomId)
//           .eq('pack_id', packId)
//           .maybeSingle();
//       if (existing != null) return 'pack_already_played';
//       await _supabase.from('room_played_packs').insert({
//         'room_id': roomId,
//         'pack_id': packId,
//       });
//       return null;
//     },
//   );

//   Future<void> requestSpectatorAccess({
//     required String roomId,
//     required String userId,
//   }) => guardedCall(
//     operationName: 'requestSpectatorAccess',
//     operation: () async {
//       await _supabase.from('spectator_requests').upsert({
//         'room_id': roomId,
//         'user_id': userId,
//         'status': 'pending',
//         'decided_by': null,
//         'decided_at': null,
//       }, onConflict: 'room_id,user_id');
//     },
//   );

//   Future<List<Map<String, dynamic>>> getPendingSpectatorRequests(
//     String roomId,
//   ) => guardedCall(
//     operationName: 'getPendingSpectatorRequests',
//     operation: () async {
//       final rows = await _supabase
//           .from('spectator_requests')
//           .select('id, user_id, created_at')
//           .eq('room_id', roomId)
//           .eq('status', 'pending')
//           .order('created_at');
//       return List<Map<String, dynamic>>.from(rows);
//     },
//   );

//   Future<void> decideSpectatorRequest({
//     required String requestId,
//     required String roomId,
//     required String requestingUserId,
//     required String decidedBy,
//     required bool approve,
//   }) => guardedCall(
//     operationName: 'decideSpectatorRequest',
//     operation: () async {
//       await _supabase
//           .from('spectator_requests')
//           .update({
//             'status': approve ? 'approved' : 'denied',
//             'decided_by': decidedBy,
//             'decided_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', requestId);

//       if (approve) {
//         await joinRoom(
//           userId: requestingUserId,
//           roomId: roomId,
//           role: 'spectator',
//         );
//       }
//     },
//   );

//   Future<void> requestToJoin({
//     required String userId,
//     required String roomId,
//     String? message,
//   }) => guardedCall(
//     operationName: 'requestToJoin',
//     operation: () async {
//       await _supabase.from('room_join_requests').upsert({
//         'room_id': roomId,
//         'user_id': userId,
//         'status': 'pending',
//         'message': message,
//         'created_at': DateTime.now().toIso8601String(),
//       }, onConflict: 'room_id,user_id');
//     },
//   );

//   Future<void> resolveJoinRequest({
//     required String requestId,
//     required bool approve,
//     required String roomId,
//     required String targetUserId,
//   }) => guardedCall(
//     operationName: 'resolveJoinRequest',
//     operation: () async {
//       await _supabase
//           .from('room_join_requests')
//           .update({
//             'status': approve ? 'approved' : 'rejected',
//             'resolved_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', requestId);

//       if (approve) {
//         final roomInfo = await _supabase
//             .from('rooms')
//             .select('status')
//             .eq('id', roomId)
//             .maybeSingle();
//         final settingsInfo = await _supabase
//             .from('room_settings')
//             .select('allow_spectators')
//             .eq('room_id', roomId)
//             .maybeSingle();
//         final inGame = roomInfo?['status'] == 'in_game';
//         final allowSpectators =
//             settingsInfo?['allow_spectators'] as bool? ?? false;
//         final role = (inGame && allowSpectators) ? 'spectator' : 'player';
//         await joinRoom(userId: targetUserId, roomId: roomId, role: role);
//       }
//     },
//   );

//   Future<List<Map<String, dynamic>>> getPendingRequests(String roomId) =>
//       guardedCall(
//         operationName: 'getPendingRequests',
//         operation: () async {
//           final rows = await _supabase
//               .from('room_join_requests')
//               .select('id, user_id, message, created_at')
//               .eq('room_id', roomId)
//               .eq('status', 'pending')
//               .order('created_at');
//           final requests = (rows as List).cast<Map<String, dynamic>>();

//           final enriched = <Map<String, dynamic>>[];
//           for (final req in requests) {
//             final uid = req['user_id'] as String;
//             final profileRows = await _supabase
//                 .from('profiles')
//                 .select('display_name, username, avatar_url')
//                 .eq('id', uid)
//                 .limit(1);
//             enriched.add({
//               ...req,
//               'profiles': profileRows.isNotEmpty ? profileRows.first : {},
//             });
//           }
//           return enriched;
//         },
//       );

//   Future<String?> getJoinRequestStatus({
//     required String userId,
//     required String roomId,
//   }) => guardedCall(
//     operationName: 'getJoinRequestStatus',
//     operation: () async {
//       final row = await _supabase
//           .from('room_join_requests')
//           .select('status')
//           .eq('room_id', roomId)
//           .eq('user_id', userId)
//           .maybeSingle();
//       return row?['status'] as String?;
//     },
//   );

//   Future<void> leaveRoom({required String userId, required String roomId}) =>
//       guardedCall(
//         operationName: 'leaveRoom',
//         operation: () async {
//           await _supabase
//               .from('room_members')
//               .update({'left_at': DateTime.now().toIso8601String()})
//               .eq('room_id', roomId)
//               .eq('user_id', userId)
//               .isFilter('left_at', null);
//         },
//       );

//   Future<Map<String, dynamic>?> getActiveMembership(String userId) =>
//       guardedCall(
//         operationName: 'getActiveMembership',
//         operation: () async {
//           final rows = await _supabase
//               .from('room_members')
//               .select(
//                 'room_id, rooms!inner(id, name, owner_id, status, deleted_at)',
//               )
//               .eq('user_id', userId)
//               .isFilter('left_at', null)
//               .inFilter('rooms.status', ['waiting', 'in_game', 'paused'])
//               .isFilter('rooms.deleted_at', null)
//               .limit(1);

//           if (rows.isEmpty) return null;
//           final room = rows.first['rooms'] as Map<String, dynamic>;
//           return {
//             'room_id': room['id'],
//             'room_name': room['name'],
//             'is_owner': room['owner_id'] == userId,
//             'status': room['status'],
//           };
//         },
//       );

//   Future<void> forceLeaveRoom({
//     required String userId,
//     required String roomId,
//   }) => guardedCall(
//     operationName: 'forceLeaveRoom',
//     operation: () async {
//       final room = await _supabase
//           .from('rooms')
//           .select('owner_id')
//           .eq('id', roomId)
//           .maybeSingle();

//       await _supabase
//           .from('room_members')
//           .update({'left_at': DateTime.now().toIso8601String()})
//           .eq('room_id', roomId)
//           .eq('user_id', userId)
//           .isFilter('left_at', null);

//       if (room != null && room['owner_id'] == userId) {
//         await _supabase
//             .from('rooms')
//             .update({
//               'status': 'closed',
//               'deleted_at': DateTime.now().toIso8601String(),
//               'updated_at': DateTime.now().toIso8601String(),
//             })
//             .eq('id', roomId);
//       }
//     },
//   );

//   Future<RoomEntity?> getActiveOwnedRoom(String userId) => guardedCall(
//     operationName: 'getActiveOwnedRoom',
//     operation: () async {
//       final row = await _supabase
//           .from('rooms')
//           .select('*, room_settings(*)')
//           .eq('owner_id', userId)
//           .inFilter('status', ['waiting', 'in_game', 'paused'])
//           .isFilter('deleted_at', null)
//           .order('last_active_at', ascending: false)
//           .limit(1)
//           .maybeSingle();
//       return row != null ? _rowToEntity(row) : null;
//     },
//   );

//   Future<void> updateStatus(
//     String roomId,
//     RoomStatus status, {
//     String? gameType,
//   }) => guardedCall(
//     operationName: 'updateStatus',
//     operation: () async {
//       final update = <String, dynamic>{
//         'status': status.toDbString(),
//         'last_active_at': DateTime.now().toIso8601String(),
//       };
//       if (gameType != null) update['game_type'] = gameType;
//       if (status == RoomStatus.waiting) {
//         update['pack_id'] = null;
//       }
//       await _supabase.from('rooms').update(update).eq('id', roomId);
//     },
//   );

//   Future<void> updateSettings(String roomId, RoomSettingsEntity settings) =>
//       guardedCall(
//         operationName: 'updateSettings',
//         operation: () async {
//           await _supabase
//               .from('room_settings')
//               .update(settings.toMap())
//               .eq('room_id', roomId);
//         },
//       );

//   Future<(RoomEntity, List<RoomMemberEntity>, RoomSettingsEntity, List<String>)>
//   getRoomWithDetails(String roomId) => guardedCall(
//     operationName: 'getRoomWithDetails',
//     operation: () async {
//       final roomRow = await _supabase
//           .from('rooms')
//           .select('*, room_settings(*)')
//           .eq('id', roomId)
//           .single();

//       final membersRows = await _supabase
//           .from('room_members')
//           .select(
//             '*, profiles(id, username, display_name, avatar_url, avatar_config, is_premium, premium_tier)',
//           )
//           .eq('room_id', roomId)
//           .isFilter('left_at', null)
//           .order('seat_order');

//       final modRows = await _supabase
//           .from('room_moderators')
//           .select('user_id')
//           .eq('room_id', roomId);

//       final modIds = modRows.map((r) => r['user_id'] as String).toSet();
//       final ownerId = roomRow['owner_id'] as String;

//       final members = membersRows.map((r) {
//         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
//         final uid = profile['id'] as String? ?? r['user_id'] as String;
//         return RoomMemberEntity(
//           userId: uid,
//           displayName:
//               profile['display_name'] as String? ??
//               profile['username'] as String? ??
//               'Player',
//           avatarUrl: profile['avatar_url'] as String?,
//           avatarConfig: profile['avatar_config'] != null
//               ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
//               : null,
//           seatOrder: r['seat_order'] as int? ?? 0,
//           isReady: r['is_ready'] as bool? ?? false,
//           isOwner: uid == ownerId,
//           isModerator: modIds.contains(uid),
//           isSpectator: (r['role'] as String?) == 'spectator',
//           isHiddenSpectator: r['is_hidden_spectator'] as bool? ?? false,
//           isMuted: r['is_muted'] as bool? ?? false,
//           isAway: r['is_away'] as bool? ?? false,
//           leftDefinitively: r['left_definitively'] as bool? ?? false,
//           isPremium: profile['is_premium'] as bool? ?? false,
//           premiumTier: profile['premium_tier'] as String?,
//           joinedAt: r['joined_at'] != null
//               ? DateTime.tryParse(r['joined_at'] as String)
//               : null,
//         );
//       }).toList();

//       final settingsRow = roomRow['room_settings'] as Map<String, dynamic>?;
//       final settings = settingsRow != null
//           ? RoomSettingsEntity.fromMap(settingsRow)
//           : const RoomSettingsEntity();

//       final mutedRows = await _supabase
//           .from('room_members')
//           .select('user_id')
//           .eq('room_id', roomId)
//           .eq('is_muted', true)
//           .isFilter('left_at', null);

//       final mutedIds = mutedRows.map((r) => r['user_id'] as String).toList();

//       return (_rowToEntity(roomRow), members, settings, mutedIds);
//     },
//   );

//   Future<List<ChatMessageEntity>> getChatHistory(
//     String roomId, {
//     int limit = 50,
//     String? before,
//   }) => guardedCall(
//     operationName: 'getChatHistory',
//     operation: () async {
//       var q = _supabase
//           .from('room_chat_messages')
//           .select('*, profiles!user_id(id, display_name, avatar_url)')
//           .eq('room_id', roomId)
//           .eq('is_deleted', false)
//           .eq('is_system', false);

//       if (before != null) {
//         final cursor = await _supabase
//             .from('room_chat_messages')
//             .select('created_at')
//             .eq('id', before)
//             .single();
//         q = q.lt('created_at', cursor['created_at']);
//       }

//       final rows = await q.order('created_at', ascending: false).limit(limit);

//       return rows.reversed.map(_chatRowToEntity).toList();
//     },
//   );

//   Future<void> persistChatMessage({
//     required String roomId,
//     required String userId,
//     required String content,
//     String? replyToId,
//     String? replyToContent,
//     String? replyToDisplayName,
//     bool isAnonymous = false,
//   }) => guardedCall(
//     operationName: 'persistChatMessage',
//     operation: () async {
//       await _supabase.from('room_chat_messages').insert({
//         'room_id': roomId,
//         'user_id': userId,
//         'content': content,
//         if (replyToId != null) 'reply_to_id': replyToId,
//         if (replyToContent != null) 'reply_to_content': replyToContent,
//         if (replyToDisplayName != null)
//           'reply_to_display_name': replyToDisplayName,
//       });
//     },
//   );

//   Future<void> deleteChatMessage(String messageId) => guardedCall(
//     operationName: 'deleteChatMessage',
//     operation: () async {
//       await _supabase
//           .from('room_chat_messages')
//           .update({'is_deleted': true})
//           .eq('id', messageId);
//     },
//   );

//   Future<void> kickMember(String roomId, String targetUserId) => guardedCall(
//     operationName: 'kickMember',
//     operation: () async {
//       await _supabase
//           .from('room_members')
//           .update({
//             'left_at': DateTime.now().toIso8601String(),
//             'kicked_at': DateTime.now().toIso8601String(),
//           })
//           .eq('room_id', roomId)
//           .eq('user_id', targetUserId)
//           .isFilter('left_at', null);
//     },
//   );

//   Future<void> muteMember(
//     String roomId,
//     String targetUserId, {
//     required bool muted,
//   }) => guardedCall(
//     operationName: 'muteMember',
//     operation: () async {
//       await _supabase
//           .from('room_members')
//           .update({'is_muted': muted})
//           .eq('room_id', roomId)
//           .eq('user_id', targetUserId);
//     },
//   );

//   Future<void> banMember({
//     required String roomId,
//     required String targetUserId,
//     required String bannedBy,
//     String? reason,
//     Duration? duration,
//   }) => guardedCall(
//     operationName: 'banMember',
//     operation: () async {
//       await _supabase.from('room_bans').upsert({
//         'room_id': roomId,
//         'user_id': targetUserId,
//         'banned_by': bannedBy,
//         'reason': reason,
//         'banned_until': null,
//       }, onConflict: 'room_id,user_id');
//       await kickMember(roomId, targetUserId);
//     },
//   );

//   Future<List<Map<String, dynamic>>> getBannedMembers(String roomId) =>
//       guardedCall(
//         operationName: 'getBannedMembers',
//         operation: () async {
//           final bans = await _supabase
//               .from('room_bans')
//               .select('user_id, reason, banned_until')
//               .eq('room_id', roomId)
//               .isFilter('lifted_at', null);
//           final banList = (bans as List).cast<Map<String, dynamic>>();
//           if (banList.isEmpty) return banList;
//           final userIds = banList.map((b) => b['user_id'] as String).toList();
//           final profiles = await _supabase
//               .from('profiles')
//               .select('id, display_name, username')
//               .inFilter('id', userIds);
//           final nameMap = {
//             for (final p in (profiles as List))
//               p['id'] as String:
//                   p['display_name'] as String? ??
//                   p['username'] as String? ??
//                   '?',
//           };
//           return banList
//               .map(
//                 (b) => {
//                   ...b,
//                   'display_name':
//                       nameMap[b['user_id'] as String] ??
//                       (b['user_id'] as String).substring(0, 8),
//                 },
//               )
//               .toList();
//         },
//       );

//   Future<void> liftBan(String roomId, String targetUserId) => guardedCall(
//     operationName: 'liftBan',
//     operation: () async {
//       await _supabase
//           .from('room_bans')
//           .update({'lifted_at': DateTime.now().toIso8601String()})
//           .eq('room_id', roomId)
//           .eq('user_id', targetUserId)
//           .isFilter('lifted_at', null);
//     },
//   );

//   Future<void> setMemberAway(
//     String roomId,
//     String userId, {
//     required bool away,
//   }) => guardedCall(
//     operationName: 'setMemberAway',
//     operation: () async {
//       await _supabase
//           .from('room_members')
//           .update({
//             'is_away': away,
//             'left_at': away ? DateTime.now().toIso8601String() : null,
//           })
//           .eq('room_id', roomId)
//           .eq('user_id', userId);
//     },
//   );

//   Future<void> setMemberDefinitiveLeave(String roomId, String userId) =>
//       guardedCall(
//         operationName: 'setMemberDefinitiveLeave',
//         operation: () async {
//           await _supabase
//               .from('room_members')
//               .update({'role': 'spectator', 'left_definitively': true})
//               .eq('room_id', roomId)
//               .eq('user_id', userId);
//         },
//       );

//   Future<void> transferOwnership(String roomId, String newOwnerId) =>
//       guardedCall(
//         operationName: 'transferOwnership',
//         operation: () async {
//           await _supabase
//               .from('rooms')
//               .update({'owner_id': newOwnerId})
//               .eq('id', roomId);
//         },
//       );

//   Future<void> grantModerator(String roomId, String userId, String grantedBy) =>
//       guardedCall(
//         operationName: 'grantModerator',
//         operation: () async {
//           await _supabase.from('room_moderators').upsert({
//             'room_id': roomId,
//             'user_id': userId,
//             'granted_by': grantedBy,
//           }, onConflict: 'room_id,user_id');
//         },
//       );

//   Future<void> revokeModerator(String roomId, String userId) => guardedCall(
//     operationName: 'revokeModerator',
//     operation: () async {
//       await _supabase
//           .from('room_moderators')
//           .delete()
//           .eq('room_id', roomId)
//           .eq('user_id', userId);
//     },
//   );

//   Future<void> softDeleteRoom(String roomId) => guardedCall(
//     operationName: 'softDeleteRoom',
//     operation: () async {
//       await _supabase
//           .from('rooms')
//           .update({
//             'status': 'closed',
//             'deleted_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', roomId);
//     },
//   );

//   RoomEntity _rowToEntity(Map<String, dynamic> row) {
//     return RoomEntity(
//       id: row['id'] as String,
//       ownerId: row['owner_id'] as String,
//       name: row['name'] as String,
//       status: RoomStatus.fromString(row['status'] as String? ?? 'waiting'),
//       visibility: RoomVisibility.fromString(
//         row['visibility'] as String? ?? 'public',
//       ),
//       maxPlayers: row['max_players'] as int? ?? 6,
//       currentPlayers: row['current_players'] as int? ?? 0,
//       inviteCode: row['invite_code'] as String?,
//       gameType: row['game_type'] != null
//           ? _parseGameType(row['game_type'] as String)
//           : null,
//       packId: row['pack_id'] as String?,
//       language: row['language'] as String? ?? 'en',
//       allowSpicy: row['allow_spicy'] as bool? ?? false,
//       coverEmoji: row['cover_emoji'] as String? ?? '🎮',
//       lastActiveAt: row['last_active_at'] != null
//           ? DateTime.tryParse(row['last_active_at'] as String)
//           : null,
//       createdAt: row['created_at'] != null
//           ? DateTime.tryParse(row['created_at'] as String)
//           : null,
//     );
//   }

//   ChatMessageEntity _chatRowToEntity(Map<String, dynamic> row) {
//     final profile = row['profiles'] as Map<String, dynamic>? ?? {};
//     return ChatMessageEntity(
//       id: row['id'] as String,
//       roomId: row['room_id'] as String,
//       userId: row['user_id'] as String,
//       displayName: profile['display_name'] as String? ?? 'Player',
//       avatarUrl: profile['avatar_url'] as String?,
//       content: row['content'] as String,
//       createdAt: DateTime.parse(row['created_at'] as String),
//       isDeleted: row['is_deleted'] as bool? ?? false,
//       replyToId: row['reply_to_id'] as String?,
//       replyToContent: row['reply_to_content'] as String?,
//       replyToDisplayName: row['reply_to_display_name'] as String?,
//     );
//   }

//   GameType? _parseGameType(String s) {
//     return switch (s) {
//       'truth_or_dare' => GameType.truthOrDare,
//       'never_have_i_ever' => GameType.neverHaveIEver,
//       'meme_game' => GameType.memeGame,
//       _ => null,
//     };
//   }
// }

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/room_entity.dart';
import '../../games/engine/base_game_engine.dart';

class RoomRepository extends BaseRepository {
  final _api = ApiClient.instance;
  RoomRepository._();
  static final RoomRepository _instance = RoomRepository._();
  static RoomRepository get instance => _instance;

  final _supabase = Supabase.instance.client;

  Future<List<RoomEntity>> getPublicRooms({
    int limit = 20,
    int offset = 0,
    String? gameTypeFilter,
    String? userId,
  }) => guardedCall(
    operationName: 'getPublicRooms',
    operation: () async {
      var q = _supabase
          .from('rooms')
          .select('*, room_settings(*)')
          .eq('visibility', 'public')
          .inFilter('status', ['waiting', 'in_game'])
          .isFilter('deleted_at', null);
      if (gameTypeFilter != null) q = q.eq('game_type', gameTypeFilter);
      final publicRows = await q
          .order('last_active_at', ascending: false)
          .range(offset, offset + limit - 1);

      List<dynamic> privateRows = [];
      if (userId != null) {
        var ownedQ = _supabase
            .from('rooms')
            .select('*, room_settings(*)')
            .eq('owner_id', userId)
            .eq('visibility', 'private')
            .inFilter('status', ['waiting', 'in_game', 'paused'])
            .isFilter('deleted_at', null);
        if (gameTypeFilter != null)
          ownedQ = ownedQ.eq('game_type', gameTypeFilter);
        final ownedRows = await ownedQ.order(
          'last_active_at',
          ascending: false,
        );

        final membershipRows = await _supabase
            .from('room_members')
            .select('room_id')
            .eq('user_id', userId)
            .isFilter('left_at', null);
        final memberRoomIds = (membershipRows as List)
            .map((r) => r['room_id'] as String)
            .toList();

        if (memberRoomIds.isNotEmpty) {
          var memberQ = _supabase
              .from('rooms')
              .select('*, room_settings(*)')
              .eq('visibility', 'private')
              .inFilter('id', memberRoomIds)
              .inFilter('status', ['waiting', 'in_game', 'paused'])
              .isFilter('deleted_at', null);
          if (gameTypeFilter != null)
            memberQ = memberQ.eq('game_type', gameTypeFilter);
          final memberRoomRows = await memberQ.order(
            'last_active_at',
            ascending: false,
          );
          privateRows = [...ownedRows, ...memberRoomRows];
        } else {
          privateRows = ownedRows;
        }

        var pausedOwnedQ = _supabase
            .from('rooms')
            .select('*, room_settings(*)')
            .eq('owner_id', userId)
            .eq('status', 'paused')
            .isFilter('deleted_at', null);
        if (gameTypeFilter != null)
          pausedOwnedQ = pausedOwnedQ.eq('game_type', gameTypeFilter);
        final pausedOwnedRows = await pausedOwnedQ.order(
          'last_active_at',
          ascending: false,
        );

        List<dynamic> pausedMemberRows = [];
        if (memberRoomIds.isNotEmpty) {
          var pausedMemberQ = _supabase
              .from('rooms')
              .select('*, room_settings(*)')
              .inFilter('id', memberRoomIds)
              .eq('status', 'paused')
              .isFilter('deleted_at', null);
          if (gameTypeFilter != null)
            pausedMemberQ = pausedMemberQ.eq('game_type', gameTypeFilter);
          pausedMemberRows = await pausedMemberQ.order(
            'last_active_at',
            ascending: false,
          );
        }
        privateRows = [...privateRows, ...pausedOwnedRows, ...pausedMemberRows];
      }

      Set<String> bannedRoomIds = {};
      if (userId != null) {
        try {
          final bans = await _supabase
              .from('room_bans')
              .select('room_id')
              .eq('user_id', userId)
              .isFilter('lifted_at', null);
          bannedRoomIds = (bans as List)
              .map((b) => b['room_id'] as String)
              .toSet();
        } catch (_) {}
      }

      final allRows = [...publicRows, ...privateRows];
      final seen = <String>{};
      final unique = allRows.where((r) {
        final id = r['id'] as String;
        if (bannedRoomIds.contains(id)) return false;
        return seen.add(id);
      }).toList();
      unique.sort((a, b) {
        final aT = a['last_active_at'] as String? ?? '';
        final bT = b['last_active_at'] as String? ?? '';
        return bT.compareTo(aT);
      });
      return unique
          .map((row) => _rowToEntity(row as Map<String, dynamic>))
          .toList();
    },
  );

  Future<RoomEntity> createRoom({
    required String ownerId,
    required String name,
    required RoomVisibility visibility,
    int? maxPlayers,
    String language = 'en',
    String coverEmoji = '🎮',
  }) => guardedCall(
    operationName: 'createRoom',
    operation: () async {
      // Server-verified: subscription-tier player cap (Basic=3/Premium=8/
      // Premium Plus=12) and the "one open room per owner" rule (status
      // waiting/in_game/paused, serialized via an advisory lock) both live
      // in this one atomic RPC now — replacing the previous raw insert's
      // non-atomic select-then-insert check (which also missed 'paused').
      Map<String, dynamic> row;
      try {
        final result = await _supabase.rpc(
          'create_room',
          params: {
            'p_name': name,
            'p_visibility': visibility.name,
            'p_max_players': maxPlayers,
            'p_language': language,
            'p_cover_emoji': coverEmoji,
          },
        );
        row = Map<String, dynamic>.from(result as Map);
      } on PostgrestException catch (e) {
        if (e.message.contains('already_has_open_room')) {
          throw const ConflictFailure(
            message:
                'You already have an open room. Close it or transfer '
                'ownership before creating a new one.',
          );
        }
        if (e.message.contains('max_players_exceeds_tier_cap')) {
          throw const ValidationFailure(
            message: 'That many players requires a higher subscription tier.',
          );
        }
        rethrow;
      }

      await _incrementRoomQuota(ownerId);

      return _rowToEntity(row);
    },
  );

  Future<RoomEntity> joinRoom({
    required String userId,
    required String roomId,
    String role = 'player',
    bool isHiddenSpectator = false,
  }) => guardedCall(
    operationName: 'joinRoom',
    operation: () async {
      final row = await _supabase
          .from('rooms')
          .select()
          .eq('id', roomId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (row == null)
        throw const NotFoundFailure(
          message: 'Room not found or no longer available.',
        );

      final room = _rowToEntity(row);
      if (room.status == RoomStatus.closed)
        throw const NotFoundFailure(
          message: 'This room has been closed by the host.',
        );

      final isOwnerJoining = userId == (row['owner_id'] as String);
      if (!isOwnerJoining) {
        final ownerRow = await _supabase
            .from('room_members')
            .select('id')
            .eq('room_id', roomId)
            .eq('user_id', row['owner_id'] as String)
            .isFilter('left_at', null)
            .maybeSingle();
        if (ownerRow == null) {
          // RPC atomically sets deleted_at alongside status (a plain
          // status-only update here previously left the room in an
          // inconsistent partial-close state — closed but not deleted_at)
          // and aborts any active/paused game_sessions row too.
          await _supabase.rpc(
            'close_abandoned_room',
            params: {'p_room_id': roomId},
          );
          throw const NotFoundFailure(
            message: 'The host has left. This room is no longer available.',
          );
        }
      }

      final playerCount = await _supabase
          .from('room_members')
          .select('id')
          .eq('room_id', roomId)
          .eq('role', 'player')
          .isFilter('left_at', null)
          .neq('user_id', userId)
          .count(CountOption.exact);
      final activePlayers = playerCount.count ?? 0;
      if (activePlayers >= room.maxPlayers) {
        throw const ConflictFailure(message: 'Room is full.');
      }

      final ban = await _supabase
          .from('room_bans')
          .select('id, banned_until')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .isFilter('lifted_at', null)
          .maybeSingle();

      if (ban != null) {
        final until = ban['banned_until'];
        if (until == null ||
            DateTime.parse(until as String).isAfter(DateTime.now())) {
          throw const ForbiddenFailure(
            message: 'You are banned from this room.',
          );
        }
      }

      final seatRes = await _supabase
          .from('room_members')
          .select('id')
          .eq('room_id', roomId)
          .isFilter('left_at', null)
          .count(CountOption.exact);
      final seatOrder = seatRes.count ?? 0;

      await _supabase.from('room_members').upsert({
        'room_id': roomId,
        'user_id': userId,
        'seat_order': seatOrder,
        'role': role == 'spectator_anon' ? 'spectator' : role,
        'is_hidden_spectator': isHiddenSpectator || role == 'spectator_anon',
        'is_ready': false,
        'left_at': null,
        'joined_at': DateTime.now().toIso8601String(),
      }, onConflict: 'room_id,user_id');

      return room;
    },
  );

  Future<RoomEntity> joinByCode({
    required String userId,
    required String inviteCode,
    String? invitedBy,
  }) => guardedCall(
    operationName: 'joinByCode',
    operation: () async {
      final rows = await _supabase.rpc(
        'get_room_by_invite_code',
        params: {'p_code': inviteCode.toUpperCase()},
      );

      if (rows == null || (rows as List).isEmpty) {
        throw const NotFoundFailure(message: 'Invalid invite code.');
      }

      final row = (rows as List).first as Map<String, dynamic>;
      final roomId = row['id'] as String;

      final roomRow = await _supabase
          .from('rooms')
          .select('status, requires_approval')
          .eq('id', roomId)
          .maybeSingle();

      final status = roomRow?['status'] as String? ?? '';
      if (status == 'closed') {
        throw const NotFoundFailure(
          message: 'This room has been closed by the host.',
        );
      }

      final requiresApproval = roomRow?['requires_approval'] as bool? ?? false;
      if (requiresApproval && invitedBy == null) {
        await requestToJoin(userId: userId, roomId: roomId);
        throw const PendingApprovalFailure();
      }
      return joinRoom(userId: userId, roomId: roomId);
    },
  );

  Future<List<String>> getActiveSessionPlayerIds(String roomId) => guardedCall(
    operationName: 'getActiveSessionPlayerIds',
    operation: () async {
      final row = await _supabase
          .from('game_sessions')
          .select('player_ids')
          .eq('room_id', roomId)
          .eq('status', 'active')
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return (row?['player_ids'] as List?)?.cast<String>() ?? [];
    },
  );

  Future<Set<String>> getInvitedUserIds(String roomId) => guardedCall(
    operationName: 'getInvitedUserIds',
    operation: () async {
      final rows = await _supabase
          .from('room_invites')
          .select('invited_user')
          .eq('room_id', roomId)
          .isFilter('declined_at', null)
          .gt('expires_at', DateTime.now().toIso8601String());
      return rows.map((r) => r['invited_user'] as String).toSet();
    },
  );

  Future<bool> isActiveMember({
    required String userId,
    required String roomId,
  }) => guardedCall(
    operationName: 'isActiveMember',
    operation: () async {
      final row = await _supabase
          .from('room_members')
          .select('id')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .isFilter('left_at', null)
          .maybeSingle();
      return row != null;
    },
  );

  /// Unlike [isActiveMember] (only true while `left_at IS NULL`), this is
  /// true for ANY prior room_members row regardless of left_at — used to
  /// tell a genuinely new joiner apart from a returning member whose row
  /// was soft-removed by the 30s disconnect grace period. joinRoom's own
  /// upsert already correctly reactivates a returning member (clears
  /// left_at), so callers should use this, not isActiveMember, to decide
  /// whether someone needs fresh spectator/join approval.
  Future<bool> hasPriorMembership({
    required String userId,
    required String roomId,
  }) => guardedCall(
    operationName: 'hasPriorMembership',
    operation: () async {
      final row = await _supabase
          .from('room_members')
          .select('id')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();
      return row != null;
    },
  );

  Future<({String ownerId, bool requiresApproval})?> getRoomApprovalInfo(
    String roomId,
  ) => guardedCall(
    operationName: 'getRoomApprovalInfo',
    operation: () async {
      final row = await _supabase
          .from('rooms')
          .select('owner_id, requires_approval')
          .eq('id', roomId)
          .maybeSingle();
      if (row == null) return null;
      return (
        ownerId: row['owner_id'] as String,
        requiresApproval: row['requires_approval'] as bool? ?? false,
      );
    },
  );

  Future<void> sendInvite({
    required String roomId,
    required String invitedUserId,
  }) => guardedCall(
    operationName: 'sendInvite',
    operation: () async {
      await _api.post(
        '/v1/rooms/$roomId/invite',
        data: {'invited_user_id': invitedUserId},
      );
    },
  );

  Future<void> notifyFriendsRoomCreated(String roomId) => guardedCall(
    operationName: 'notifyFriendsRoomCreated',
    operation: () async {
      await _api.post('/v1/rooms/$roomId/notify-friends');
    },
  );

  /// Backs the ephemeral kick/ban realtime broadcast with a real
  /// notification, so a target who isn't currently connected to the room's
  /// channel still finds out. Best-effort — failures are swallowed by
  /// callers, moderation itself has already taken effect regardless.
  Future<void> notifyModeration({
    required String roomId,
    required String targetUserId,
    required String action, // 'kick' | 'ban'
  }) => guardedCall(
    operationName: 'notifyModeration',
    operation: () async {
      await _api.post(
        '/v1/rooms/$roomId/moderation-notify',
        data: {'target_user_id': targetUserId, 'action': action},
      );
    },
  );

  Future<void> notifyJoinRequest(String roomId) => guardedCall(
    operationName: 'notifyJoinRequest',
    operation: () async {
      await _api.post('/v1/rooms/$roomId/join-request-notify');
    },
  );

  Future<void> notifyJoinDecision({
    required String roomId,
    required String targetUserId,
    required bool approved,
  }) => guardedCall(
    operationName: 'notifyJoinDecision',
    operation: () async {
      await _api.post(
        '/v1/rooms/$roomId/join-decision-notify',
        data: {'target_user_id': targetUserId, 'approved': approved},
      );
    },
  );

  Future<void> notifyGameStarted(String roomId) => guardedCall(
    operationName: 'notifyGameStarted',
    operation: () async {
      await _api.post('/v1/rooms/$roomId/game-started-notify');
    },
  );

  Future<void> notifyGameEnded(String roomId) => guardedCall(
    operationName: 'notifyGameEnded',
    operation: () async {
      await _api.post('/v1/rooms/$roomId/game-ended-notify');
    },
  );

  Future<bool> hasValidInvite({
    required String userId,
    required String roomId,
  }) => guardedCall(
    operationName: 'hasValidInvite',
    operation: () async {
      final row = await _supabase
          .from('room_invites')
          .select('id')
          .eq('room_id', roomId)
          .eq('invited_user', userId)
          .isFilter('declined_at', null)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();
      return row != null;
    },
  );

  Future<void> markInviteAccepted({
    required String userId,
    required String roomId,
  }) => guardedCall(
    operationName: 'markInviteAccepted',
    operation: () async {
      await _supabase
          .from('room_invites')
          .update({'accepted_at': DateTime.now().toIso8601String()})
          .eq('room_id', roomId)
          .eq('invited_user', userId)
          .isFilter('accepted_at', null);
    },
  );

  /// Explicitly rejects an invite — previously nothing in the client ever
  /// wrote `declined_at` even though the schema/RLS already supported it,
  /// so a declined invite just sat there until it expired on its own.
  Future<void> declineInvite({
    required String userId,
    required String roomId,
  }) => guardedCall(
    operationName: 'declineInvite',
    operation: () async {
      await _supabase
          .from('room_invites')
          .update({'declined_at': DateTime.now().toIso8601String()})
          .eq('room_id', roomId)
          .eq('invited_user', userId)
          .isFilter('declined_at', null);
    },
  );

  /// Validates a room invitation before entering the room directly — the
  /// single source of truth called by NotificationService.
  /// _handleRoomInviteTap (every notification trigger: OneSignal click,
  /// foreground local notification, in-app toast, Notification Center row
  /// tap, and PendingInvitesSection's "View" button all funnel through
  /// it). There is no intermediate confirmation screen — a null result
  /// means "show a friendly message and go Home," a non-null result means
  /// "enter the room now."
  /// Covers THREE cases that share the same push payload shape
  /// (`type: 'room_invite'`):
  ///   1. A real per-friend invite the user explicitly DECLINED
  ///      (`declined_at` set) — a hard stop, always "no longer available"
  ///      regardless of room status. A stale notification for an invite
  ///      the user already dismissed should never let them back in.
  ///   2. A real per-friend invite that's still valid (not declined, not
  ///      expired) — the normal case, returns inviter/room info.
  ///   3. No formal invite row at all, or one that merely expired without
  ///      being declined — this also covers the public "I created a room"
  ///      broadcast (the /notify-friends endpoint, which never creates a
  ///      `room_invites` row). Falls back to a plain room-open check, so
  ///      a friend tapping a broadcast notification for a still-open room
  ///      isn't dead-ended just because no formal invite exists.
  /// Only returns null for case 1, or when the room itself is genuinely
  /// gone/closed.
  Future<Map<String, dynamic>?> getInviteInfo({
    required String userId,
    required String roomId,
  }) => guardedCall(
    operationName: 'getInviteInfo',
    operation: () async {
      final row = await _supabase
          .from('room_invites')
          .select('invited_by, expires_at, declined_at, rooms!inner(name)')
          .eq('room_id', roomId)
          .eq('invited_user', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row != null && row['declined_at'] != null) {
        AppLogger.info(
          'getInviteInfo: invite for room $roomId was declined by $userId '
          '— hard stop',
        );
        return null;
      }

      if (row != null) {
        final expiresAt = DateTime.tryParse(row['expires_at'] as String);
        if (expiresAt == null || expiresAt.isAfter(DateTime.now())) {
          final inviterId = row['invited_by'] as String;
          final profileRow = await _supabase
              .from('profiles')
              .select('display_name, username')
              .eq('id', inviterId)
              .maybeSingle();
          final room = row['rooms'] as Map<String, dynamic>;
          return {
            'room_name': room['name'],
            'inviter_name':
                profileRow?['display_name'] ??
                profileRow?['username'] ??
                'A friend',
            'expires_at': row['expires_at'],
          };
        }
        // Formal invite exists but merely expired (not declined) — fall
        // through to the room-still-open check below rather than treating
        // it as valid OR as a hard stop.
      }

      final roomRow = await _supabase
          .from('rooms')
          .select('name, status, deleted_at')
          .eq('id', roomId)
          .maybeSingle();
      if (roomRow == null ||
          roomRow['deleted_at'] != null ||
          roomRow['status'] == 'closed') {
        AppLogger.info(
          'getInviteInfo: room $roomId is gone/closed — no valid invite '
          'or fallback',
        );
        return null;
      }
      return {
        'room_name': roomRow['name'],
        'inviter_name': null,
        'expires_at': null,
      };
    },
  );

  /// All of the current user's still-outstanding (unexpired, undecided)
  /// invites — surfaced as a list so a user isn't limited to reacting to a
  /// single push/toast per invite.
  Future<List<Map<String, dynamic>>> getPendingInvites(String userId) =>
      guardedCall(
        operationName: 'getPendingInvites',
        operation: () async {
          final rows = await _supabase
              .from('room_invites')
              .select('room_id, invited_by, created_at, rooms!inner(name)')
              .eq('invited_user', userId)
              .isFilter('declined_at', null)
              .isFilter('accepted_at', null)
              .gt('expires_at', DateTime.now().toIso8601String())
              .order('created_at', ascending: false);
          return List<Map<String, dynamic>>.from(rows);
        },
      );

  Future<List<Map<String, dynamic>>> getRoomModerators(String roomId) =>
      guardedCall(
        operationName: 'getRoomModerators',
        operation: () async {
          final rows = await _supabase
              .from('room_moderators')
              .select('user_id')
              .eq('room_id', roomId);
          return List<Map<String, dynamic>>.from(rows);
        },
      );

  static const _freeMinsToReturn = 5;
  static const _premiumMinsToReturn = 10;

  Future<void> setReturnTimer({
    required String roomId,
    required String userId,
    required bool isPremium,
  }) => guardedCall(
    operationName: 'setReturnTimer',
    operation: () async {
      final mins = isPremium ? _premiumMinsToReturn : _freeMinsToReturn;
      final returnBy = DateTime.now().add(Duration(minutes: mins));
      await _supabase.from('room_return_timers').upsert({
        'room_id': roomId,
        'user_id': userId,
        'return_by': returnBy.toIso8601String(),
        'is_premium': isPremium,
        'returned_at': null,
        'expired': false,
      }, onConflict: 'room_id,user_id');
    },
  );

  Future<void> clearReturnTimer({
    required String roomId,
    required String userId,
  }) => guardedCall(
    operationName: 'clearReturnTimer',
    operation: () async {
      await _supabase
          .from('room_return_timers')
          .update({'returned_at': DateTime.now().toIso8601String()})
          .eq('room_id', roomId)
          .eq('user_id', userId);
    },
  );

  Future<List<String>> getExpiredAwayUsers(String roomId) => guardedCall(
    operationName: 'getExpiredAwayUsers',
    operation: () async {
      final rows = await _supabase
          .from('room_return_timers')
          .select('user_id')
          .eq('room_id', roomId)
          .eq('expired', false)
          .isFilter('returned_at', null)
          .lt('return_by', DateTime.now().toIso8601String());
      return rows.map((r) => r['user_id'] as String).toList();
    },
  );

  Future<void> markReturnTimerExpired({
    required String roomId,
    required String userId,
  }) => guardedCall(
    operationName: 'markReturnTimerExpired',
    operation: () async {
      await _supabase
          .from('room_return_timers')
          .update({'expired': true})
          .eq('room_id', roomId)
          .eq('user_id', userId);
    },
  );

  Future<int> getRoomsCreatedToday(String userId) => guardedCall(
    operationName: 'getRoomsCreatedToday',
    operation: () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final row = await _supabase
          .from('room_creation_quotas')
          .select('rooms_today, quota_date')
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null || row['quota_date'] != today) return 0;
      return row['rooms_today'] as int? ?? 0;
    },
  );

  Future<bool> hasHitDailyRoomLimit({
    required String userId,
    required bool isPremium,
  }) async {
    final count = await getRoomsCreatedToday(userId);
    final limit = isPremium ? 15 : 5;
    return count >= limit;
  }

  Future<void> _incrementRoomQuota(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final existing = await _supabase
          .from('room_creation_quotas')
          .select('rooms_today, quota_date')
          .eq('user_id', userId)
          .maybeSingle();
      if (existing == null || existing['quota_date'] != today) {
        await _supabase.from('room_creation_quotas').upsert({
          'user_id': userId,
          'quota_date': today,
          'rooms_today': 1,
        }, onConflict: 'user_id');
      } else {
        final current = existing['rooms_today'] as int? ?? 0;
        await _supabase
            .from('room_creation_quotas')
            .update({'rooms_today': current + 1, 'quota_date': today})
            .eq('user_id', userId);
      }
    } catch (_) {}
  }

  Future<void> clearPack(String roomId) => guardedCall(
    operationName: 'clearPack',
    operation: () async {
      await _supabase.from('rooms').update({'pack_id': null}).eq('id', roomId);
    },
  );

  Future<Set<String>> getPlayedPackIds(String roomId) => guardedCall(
    operationName: 'getPlayedPackIds',
    operation: () async {
      final rows = await _supabase
          .from('room_played_packs')
          .select('pack_id')
          .eq('room_id', roomId);
      return rows.map((r) => r['pack_id'] as String).toSet();
    },
  );

  Future<String?> runGameSessionChecks({
    required String userId,
    required String roomId,
    required String packId,
    required bool isPremium,
  }) => guardedCall(
    operationName: 'runGameSessionChecks',
    operation: () async {
      // Atomic check-then-insert via a SECURITY DEFINER RPC — a plain
      // Dart-side SELECT-then-INSERT has a race window where two players
      // starting a game simultaneously could both pass the check.
      final result = await _supabase.rpc(
        'start_game_session_checks',
        params: {
          'p_user_id': userId,
          'p_room_id': roomId,
          'p_pack_id': packId,
          'p_is_premium': isPremium,
        },
      );
      return result as String?;
    },
  );

  Future<void> requestSpectatorAccess({
    required String roomId,
    required String userId,
  }) => guardedCall(
    operationName: 'requestSpectatorAccess',
    operation: () async {
      await _supabase.from('spectator_requests').upsert({
        'room_id': roomId,
        'user_id': userId,
        'status': 'pending',
        'decided_by': null,
        'decided_at': null,
      }, onConflict: 'room_id,user_id');
    },
  );

  Future<List<Map<String, dynamic>>> getPendingSpectatorRequests(
    String roomId,
  ) => guardedCall(
    operationName: 'getPendingSpectatorRequests',
    operation: () async {
      final rows = await _supabase
          .from('spectator_requests')
          .select('id, user_id, created_at')
          .eq('room_id', roomId)
          .eq('status', 'pending')
          .order('created_at');
      return List<Map<String, dynamic>>.from(rows);
    },
  );

  Future<void> decideSpectatorRequest({
    required String requestId,
    required String roomId,
    required String requestingUserId,
    required String decidedBy,
    required bool approve,
  }) => guardedCall(
    operationName: 'decideSpectatorRequest',
    operation: () async {
      // Permission-gated server-side (accept_spectators) — a SECURITY
      // DEFINER RPC. On approval it also performs the room_members
      // admission itself (mirroring decide_game_rejoin_request), since a
      // follow-up client-side joinRoom() call here would run under the
      // MODERATOR's own session and get rejected by RLS for a brand-new
      // target user.
      await _supabase.rpc(
        'decide_spectator_request',
        params: {'p_request_id': requestId, 'p_approve': approve},
      );
    },
  );

  Future<void> requestToJoin({
    required String userId,
    required String roomId,
    String? message,
  }) => guardedCall(
    operationName: 'requestToJoin',
    operation: () async {
      await _supabase.from('room_join_requests').upsert({
        'room_id': roomId,
        'user_id': userId,
        'status': 'pending',
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'room_id,user_id');
    },
  );

  Future<void> resolveJoinRequest({
    required String requestId,
    required bool approve,
    required String roomId,
    required String targetUserId,
  }) => guardedCall(
    operationName: 'resolveJoinRequest',
    operation: () async {
      // Permission-gated server-side (accept_joins) — a SECURITY DEFINER
      // RPC. On approval it also performs the room_members admission
      // itself (mirroring decide_game_rejoin_request), since a follow-up
      // client-side joinRoom() call here would run under the MODERATOR's
      // own session and get rejected by RLS for a brand-new target user.
      await _supabase.rpc(
        'decide_join_request',
        params: {'p_request_id': requestId, 'p_approve': approve},
      );
    },
  );

  Future<List<Map<String, dynamic>>> getPendingRequests(String roomId) =>
      guardedCall(
        operationName: 'getPendingRequests',
        operation: () async {
          final rows = await _supabase
              .from('room_join_requests')
              .select('id, user_id, message, created_at')
              .eq('room_id', roomId)
              .eq('status', 'pending')
              .order('created_at');
          final requests = (rows as List).cast<Map<String, dynamic>>();

          final enriched = <Map<String, dynamic>>[];
          for (final req in requests) {
            final uid = req['user_id'] as String;
            final profileRows = await _supabase
                .from('profiles')
                .select('display_name, username, avatar_url')
                .eq('id', uid)
                .limit(1);
            enriched.add({
              ...req,
              'profiles': profileRows.isNotEmpty ? profileRows.first : {},
            });
          }
          return enriched;
        },
      );

  Future<String?> getJoinRequestStatus({
    required String userId,
    required String roomId,
  }) => guardedCall(
    operationName: 'getJoinRequestStatus',
    operation: () async {
      final row = await _supabase
          .from('room_join_requests')
          .select('status')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();
      return row?['status'] as String?;
    },
  );

  /// Requests to rejoin an in-progress game after a real disconnect/leave
  /// (an intact `room_members` row reconnects instantly with no request —
  /// see `RoomProvider.currentMember`). Eligibility is fully enforced
  /// server-side by the `request_game_rejoin` RPC, not just this client.
  Future<String> requestGameRejoin(String roomId) => guardedCall(
    operationName: 'requestGameRejoin',
    operation: () async {
      try {
        final result = await _supabase.rpc(
          'request_game_rejoin',
          params: {'p_room_id': roomId},
        );
        return result as String;
      } on PostgrestException catch (e) {
        if (e.message.contains('game_finished')) {
          throw const ValidationFailure(
            message: 'This game has already ended.',
          );
        }
        if (e.message.contains('room_full')) {
          throw const ValidationFailure(message: 'The room is full.');
        }
        if (e.message.contains('already_pending')) {
          throw const ConflictFailure(
            message: 'A rejoin request is already pending.',
          );
        }
        if (e.message.contains('already_in_room')) {
          throw const ConflictFailure(message: "You're already in this room.");
        }
        if (e.message.contains('not_eligible')) {
          throw const ForbiddenFailure(
            message: "You're not eligible to rejoin this game.",
          );
        }
        if (e.message.contains('room_not_found')) {
          throw const NotFoundFailure(message: 'Room not found.');
        }
        rethrow;
      }
    },
  );

  Future<String?> getRejoinRequestStatus({
    required String userId,
    required String roomId,
  }) => guardedCall(
    operationName: 'getRejoinRequestStatus',
    operation: () async {
      final row = await _supabase
          .from('game_rejoin_requests')
          .select('status')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();
      return row?['status'] as String?;
    },
  );

  Future<List<Map<String, dynamic>>> getPendingRejoinRequests(
    String roomId,
  ) => guardedCall(
    operationName: 'getPendingRejoinRequests',
    operation: () async {
      final rows = await _supabase
          .from('game_rejoin_requests')
          .select('id, user_id, created_at')
          .eq('room_id', roomId)
          .eq('status', 'pending')
          .order('created_at');
      final requests = (rows as List).cast<Map<String, dynamic>>();

      final enriched = <Map<String, dynamic>>[];
      for (final req in requests) {
        final uid = req['user_id'] as String;
        final profileRows = await _supabase
            .from('profiles')
            .select('display_name, username, avatar_url')
            .eq('id', uid)
            .limit(1);
        enriched.add({
          ...req,
          'profiles': profileRows.isNotEmpty ? profileRows.first : {},
        });
      }
      return enriched;
    },
  );

  Future<void> decideGameRejoinRequest({
    required String requestId,
    required bool approve,
  }) => guardedCall(
    operationName: 'decideGameRejoinRequest',
    operation: () async {
      // Permission-gated server-side (accept_rejoins) — a SECURITY DEFINER
      // RPC that also revives the existing room_members row on approval,
      // not just a status flag the client has to act on separately.
      try {
        await _supabase.rpc(
          'decide_game_rejoin_request',
          params: {'p_request_id': requestId, 'p_approve': approve},
        );
      } on PostgrestException catch (e) {
        if (e.message.contains('permission_denied')) {
          throw const ForbiddenFailure(
            message: "You don't have permission to decide rejoin requests.",
          );
        }
        if (e.message.contains('request_not_found')) {
          throw const NotFoundFailure(message: 'Request not found.');
        }
        rethrow;
      }
    },
  );

  Future<void> leaveRoom({required String userId, required String roomId}) =>
      guardedCall(
        operationName: 'leaveRoom',
        operation: () async {
          await _supabase
              .from('room_members')
              .update({'left_at': DateTime.now().toIso8601String()})
              .eq('room_id', roomId)
              .eq('user_id', userId)
              .isFilter('left_at', null);
        },
      );

  /// Server-verified heartbeat — Presence (client-side diffing, no server
  /// record) was previously the sole signal driving member eviction, and
  /// any two unrelated presence events could race-arm a false eviction for
  /// someone with only a momentary blip. Called periodically while
  /// connected; the grace-period timer re-checks [getMemberLastSeen]
  /// before actually evicting so a heartbeat landing after the timer armed
  /// cancels a false-positive eviction.
  Future<void> touchPresence(String roomId) => guardedCall(
    operationName: 'touchPresence',
    operation: () async {
      await _supabase.rpc('touch_room_presence', params: {'p_room_id': roomId});
    },
  );

  Future<DateTime?> getMemberLastSeen({
    required String roomId,
    required String userId,
  }) => guardedCall(
    operationName: 'getMemberLastSeen',
    operation: () async {
      final row = await _supabase
          .from('room_members')
          .select('last_seen_at')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();
      final raw = row?['last_seen_at'] as String?;
      return raw != null ? DateTime.tryParse(raw) : null;
    },
  );

  /// Emergency failover — deliberately separate from the manual, Premium-
  /// gated [transferOwnership]. Server re-verifies the current owner's own
  /// heartbeat is actually stale before allowing this to succeed, so a
  /// client can't steal ownership of a room whose owner is genuinely still
  /// active. Returns the new owner's user id, or null if the RPC rejected
  /// the claim (owner still active, no eligible member, etc.) — callers
  /// should treat any failure as "nothing changed" rather than surfacing
  /// an error to the user, since this runs automatically in the background.
  Future<String?> claimRoomOwnership(String roomId) => guardedCall(
    operationName: 'claimRoomOwnership',
    operation: () async {
      final result = await _supabase.rpc(
        'claim_room_ownership',
        params: {'p_room_id': roomId},
      );
      return result as String?;
    },
  );

  /// The ownership branch queries `rooms` directly by `owner_id`, mirroring
  /// create_room's own `already_has_open_room` guard exactly — previously
  /// this went through `room_members.left_at IS NULL`, which a bystander's
  /// presence-timeout cleanup could set on the OWNER's own row (see
  /// _removeMember) while `rooms.status`/`deleted_at` never actually
  /// changed, producing a false negative here and letting the create-room
  /// sheet open even though the server would reject the submit.
  Future<Map<String, dynamic>?> getActiveMembership(String userId) =>
      guardedCall(
        operationName: 'getActiveMembership',
        operation: () async {
          final ownedRows = await _supabase
              .from('rooms')
              .select('id, name, status')
              .eq('owner_id', userId)
              .inFilter('status', ['waiting', 'in_game', 'paused'])
              .isFilter('deleted_at', null)
              .limit(1);
          if (ownedRows.isNotEmpty) {
            final room = ownedRows.first;
            return {
              'room_id': room['id'],
              'room_name': room['name'],
              'is_owner': true,
              'status': room['status'],
            };
          }

          final rows = await _supabase
              .from('room_members')
              .select(
                'room_id, rooms!inner(id, name, owner_id, status, deleted_at)',
              )
              .eq('user_id', userId)
              .isFilter('left_at', null)
              .inFilter('rooms.status', ['waiting', 'in_game', 'paused'])
              .isFilter('rooms.deleted_at', null)
              .limit(1);

          if (rows.isEmpty) return null;
          final room = rows.first['rooms'] as Map<String, dynamic>;
          return {
            'room_id': room['id'],
            'room_name': room['name'],
            'is_owner': false,
            'status': room['status'],
          };
        },
      );

  /// Single authoritative recovery step — reclaims ownership for the
  /// room's original creator if it was reassigned while they were gone,
  /// and gracefully terminates a stale mid-game session so a returning
  /// owner lands on a normal lobby instead of silently resuming a
  /// partially-running game. No-ops safely for anyone who isn't the
  /// room's creator or current owner, so it's safe to call unconditionally
  /// on every room entry. See recover_owner_room in schema.sql.
  Future<Map<String, dynamic>?> recoverOwnerRoom(String roomId) =>
      guardedCall(
        operationName: 'recoverOwnerRoom',
        operation: () async {
          final result = await _supabase.rpc(
            'recover_owner_room',
            params: {'p_room_id': roomId},
          );
          return (result as Map?)?.cast<String, dynamic>();
        },
      );

  Future<void> forceLeaveRoom({
    required String userId,
    required String roomId,
  }) => guardedCall(
    operationName: 'forceLeaveRoom',
    operation: () async {
      final room = await _supabase
          .from('rooms')
          .select('owner_id')
          .eq('id', roomId)
          .maybeSingle();

      await _supabase
          .from('room_members')
          .update({'left_at': DateTime.now().toIso8601String()})
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .isFilter('left_at', null);

      if (room != null && room['owner_id'] == userId) {
        await _supabase
            .from('rooms')
            .update({
              'status': 'closed',
              'deleted_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', roomId);
      }
    },
  );

  Future<void> updateStatus(
    String roomId,
    RoomStatus status, {
    String? gameType,
  }) => guardedCall(
    operationName: 'updateStatus',
    operation: () async {
      final update = <String, dynamic>{
        'status': status.toDbString(),
        'last_active_at': DateTime.now().toIso8601String(),
      };
      if (gameType != null) update['game_type'] = gameType;
      if (status == RoomStatus.waiting) {
        update['pack_id'] = null;
      }
      if (status == RoomStatus.closed) {
        update['deleted_at'] = DateTime.now().toIso8601String();
      }
      await _supabase.from('rooms').update(update).eq('id', roomId);
    },
  );

  Future<void> updateSettings(String roomId, RoomSettingsEntity settings) =>
      guardedCall(
        operationName: 'updateSettings',
        operation: () async {
          await _supabase
              .from('room_settings')
              .update(settings.toMap())
              .eq('room_id', roomId);
        },
      );

  Future<(RoomEntity, List<RoomMemberEntity>, RoomSettingsEntity, List<String>)>
  getRoomWithDetails(String roomId) => guardedCall(
    operationName: 'getRoomWithDetails',
    operation: () async {
      final roomRow = await _supabase
          .from('rooms')
          .select('*, room_settings(*)')
          .eq('id', roomId)
          .single();

      final membersRows = await _supabase
          .from('room_members')
          .select(
            '*, profiles(id, username, display_name, avatar_url, avatar_config, is_premium, premium_tier)',
          )
          .eq('room_id', roomId)
          .isFilter('left_at', null)
          .order('seat_order');

      final modRows = await _supabase
          .from('room_moderators')
          .select('user_id, permissions')
          .eq('room_id', roomId);

      final modPermissions = <String, Set<String>>{
        for (final r in modRows)
          r['user_id'] as String: Set<String>.from(
            (r['permissions'] as List?) ?? const [],
          ),
      };
      final modIds = modPermissions.keys.toSet();
      final ownerId = roomRow['owner_id'] as String;

      final members = membersRows.map((r) {
        final profile = r['profiles'] as Map<String, dynamic>? ?? {};
        final uid = profile['id'] as String? ?? r['user_id'] as String;
        return RoomMemberEntity(
          userId: uid,
          displayName:
              profile['display_name'] as String? ??
              profile['username'] as String? ??
              'Player',
          avatarUrl: profile['avatar_url'] as String?,
          avatarConfig: profile['avatar_config'] != null
              ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
              : null,
          seatOrder: r['seat_order'] as int? ?? 0,
          isReady: r['is_ready'] as bool? ?? false,
          isOwner: uid == ownerId,
          isModerator: modIds.contains(uid),
          isSpectator: (r['role'] as String?) == 'spectator',
          isHiddenSpectator: r['is_hidden_spectator'] as bool? ?? false,
          isMuted: r['is_muted'] as bool? ?? false,
          isAway: r['is_away'] as bool? ?? false,
          leftDefinitively: r['left_definitively'] as bool? ?? false,
          isPremium: profile['is_premium'] as bool? ?? false,
          premiumTier: profile['premium_tier'] as String?,
          joinedAt: r['joined_at'] != null
              ? DateTime.tryParse(r['joined_at'] as String)
              : null,
          moderatorPermissions: modPermissions[uid] ?? const {},
        );
      }).toList();

      final settingsRow = roomRow['room_settings'] as Map<String, dynamic>?;
      final settings = settingsRow != null
          ? RoomSettingsEntity.fromMap(settingsRow)
          : const RoomSettingsEntity();

      final mutedRows = await _supabase
          .from('room_members')
          .select('user_id')
          .eq('room_id', roomId)
          .eq('is_muted', true)
          .isFilter('left_at', null);

      final mutedIds = mutedRows.map((r) => r['user_id'] as String).toList();

      return (_rowToEntity(roomRow), members, settings, mutedIds);
    },
  );

  Future<List<ChatMessageEntity>> getChatHistory(
    String roomId, {
    int limit = 50,
    String? before,
  }) => guardedCall(
    operationName: 'getChatHistory',
    operation: () async {
      var q = _supabase
          .from('room_chat_messages')
          .select('*, profiles!user_id(id, display_name, avatar_url)')
          .eq('room_id', roomId)
          .eq('is_deleted', false)
          .eq('is_system', false);

      if (before != null) {
        final cursor = await _supabase
            .from('room_chat_messages')
            .select('created_at')
            .eq('id', before)
            .single();
        q = q.lt('created_at', cursor['created_at']);
      }

      final rows = await q.order('created_at', ascending: false).limit(limit);

      return rows.reversed.map(_chatRowToEntity).toList();
    },
  );

  Future<void> persistChatMessage({
    required String roomId,
    required String userId,
    required String content,
    String? replyToId,
    String? replyToContent,
    String? replyToDisplayName,
    bool isAnonymous = false,
  }) => guardedCall(
    operationName: 'persistChatMessage',
    operation: () async {
      await _supabase.from('room_chat_messages').insert({
        'room_id': roomId,
        'user_id': userId,
        'content': content,
        if (replyToId != null) 'reply_to_id': replyToId,
        if (replyToContent != null) 'reply_to_content': replyToContent,
        if (replyToDisplayName != null)
          'reply_to_display_name': replyToDisplayName,
      });
    },
  );

  Future<void> deleteChatMessage(String messageId) => guardedCall(
    operationName: 'deleteChatMessage',
    operation: () async {
      await _supabase
          .from('room_chat_messages')
          .update({'is_deleted': true})
          .eq('id', messageId);
    },
  );

  Future<void> kickMember(String roomId, String targetUserId) => guardedCall(
    operationName: 'kickMember',
    operation: () async {
      // Permission-gated server-side (kick_players) — a SECURITY DEFINER
      // RPC, not a plain .update() relying on RLS alone.
      await _supabase.rpc(
        'kick_room_member',
        params: {'p_room_id': roomId, 'p_target_user_id': targetUserId},
      );
    },
  );

  Future<void> muteMember(
    String roomId,
    String targetUserId, {
    required bool muted,
  }) => guardedCall(
    operationName: 'muteMember',
    operation: () async {
      // Permission-gated server-side (mute_chat).
      await _supabase.rpc(
        'mute_room_member',
        params: {
          'p_room_id': roomId,
          'p_target_user_id': targetUserId,
          'p_muted': muted,
        },
      );
    },
  );

  Future<void> markMemberAwayInGame(
    String roomId,
    String targetUserId, {
    required bool away,
  }) => guardedCall(
    operationName: 'markMemberAwayInGame',
    operation: () async {
      // Permission-gated server-side (kick_players) — a SECURITY DEFINER
      // RPC persisting to room_members.is_away, so a client that
      // reconnects, briefly drops, or joins after the moderation broadcast
      // fired still sees the correct away status via a fresh fetch, not
      // just whoever happened to be connected when the broadcast fired.
      await _supabase.rpc(
        'mark_room_member_away',
        params: {
          'p_room_id': roomId,
          'p_target_user_id': targetUserId,
          'p_away': away,
        },
      );
    },
  );

  Future<void> banMember({
    required String roomId,
    required String targetUserId,
    required String bannedBy,
    String? reason,
    Duration? duration,
  }) => guardedCall(
    operationName: 'banMember',
    operation: () async {
      // Atomic RPC replacing the previous ban-row-upsert-then-kickMember
      // flow — that left a window where the ban row (targeting the room's
      // owner) could be inserted before kick_room_member's own owner-
      // protection ever ran. banned_by is now derived server-side from
      // auth.uid(), not trusted from whatever the client passes.
      await _supabase.rpc(
        'ban_room_member',
        params: {
          'p_room_id': roomId,
          'p_target_user_id': targetUserId,
          'p_reason': reason,
          'p_duration_secs': duration?.inSeconds,
        },
      );
    },
  );

  Future<List<Map<String, dynamic>>> getBannedMembers(String roomId) =>
      guardedCall(
        operationName: 'getBannedMembers',
        operation: () async {
          final bans = await _supabase
              .from('room_bans')
              .select('user_id, reason, banned_until')
              .eq('room_id', roomId)
              .isFilter('lifted_at', null);
          final banList = (bans as List).cast<Map<String, dynamic>>();
          if (banList.isEmpty) return banList;
          final userIds = banList.map((b) => b['user_id'] as String).toList();
          final profiles = await _supabase
              .from('profiles')
              .select('id, display_name, username')
              .inFilter('id', userIds);
          final nameMap = {
            for (final p in (profiles as List))
              p['id'] as String:
                  p['display_name'] as String? ??
                  p['username'] as String? ??
                  '?',
          };
          return banList
              .map(
                (b) => {
                  ...b,
                  'display_name':
                      nameMap[b['user_id'] as String] ??
                      (b['user_id'] as String).substring(0, 8),
                },
              )
              .toList();
        },
      );

  Future<void> liftBan(String roomId, String targetUserId) => guardedCall(
    operationName: 'liftBan',
    operation: () async {
      await _supabase
          .from('room_bans')
          .update({'lifted_at': DateTime.now().toIso8601String()})
          .eq('room_id', roomId)
          .eq('user_id', targetUserId)
          .isFilter('lifted_at', null);
    },
  );

  Future<void> setMemberAway(
    String roomId,
    String userId, {
    required bool away,
  }) => guardedCall(
    operationName: 'setMemberAway',
    operation: () async {
      await _supabase
          .from('room_members')
          .update({
            'is_away': away,
            'left_at': away ? DateTime.now().toIso8601String() : null,
          })
          .eq('room_id', roomId)
          .eq('user_id', userId);
    },
  );

  Future<void> setMemberDefinitiveLeave(String roomId, String userId) =>
      guardedCall(
        operationName: 'setMemberDefinitiveLeave',
        operation: () async {
          await _supabase
              .from('room_members')
              .update({
                'role': 'spectator',
                'left_definitively': true,
                'left_at': DateTime.now().toIso8601String(),
              })
              .eq('room_id', roomId)
              .eq('user_id', userId);
        },
      );

  Future<void> transferOwnership(String roomId, String newOwnerId) =>
      guardedCall(
        operationName: 'transferOwnership',
        operation: () async {
          // Server-enforced (once-per-calendar-day, owner-only, non-
          // spectator target) via a SECURITY DEFINER RPC — a plain
          // .update() cannot be trusted to enforce the limit since a
          // modified client/direct API call could bypass a client-side
          // check entirely.
          try {
            await _supabase.rpc(
              'transfer_room_ownership',
              params: {'p_room_id': roomId, 'p_new_owner_id': newOwnerId},
            );
          } on PostgrestException catch (e) {
            if (e.message.contains('premium_required')) {
              throw const ForbiddenFailure(
                message: 'Transferring room ownership requires Premium.',
              );
            }
            if (e.message.contains('transfer_limit_reached')) {
              throw const RateLimitFailure(
                message:
                    "You've already transferred ownership today — try again tomorrow.",
              );
            }
            if (e.message.contains('target_is_spectator')) {
              throw const ValidationFailure(
                message: 'A spectator cannot become the room owner.',
              );
            }
            if (e.message.contains('target_not_member')) {
              throw const ValidationFailure(
                message: 'That player is no longer in the room.',
              );
            }
            rethrow;
          }
        },
      );


  /// Grants moderator status (if not already granted) and sets their exact
  /// permission set in one call — an empty set is equivalent to
  /// [revokeModerator]. Owner-only at the RLS layer (insert/update
  /// policies on room_moderators both check `rooms.owner_id = auth.uid()`).
  Future<void> updateModeratorPermissions({
    required String roomId,
    required String userId,
    required String grantedBy,
    required Set<String> permissions,
  }) => guardedCall(
    operationName: 'updateModeratorPermissions',
    operation: () async {
      if (permissions.isEmpty) {
        await _supabase
            .from('room_moderators')
            .delete()
            .eq('room_id', roomId)
            .eq('user_id', userId);
        return;
      }
      await _supabase.from('room_moderators').upsert({
        'room_id': roomId,
        'user_id': userId,
        'granted_by': grantedBy,
        'permissions': permissions.toList(),
      }, onConflict: 'room_id,user_id');
    },
  );

  Future<void> softDeleteRoom(String roomId) => guardedCall(
    operationName: 'softDeleteRoom',
    operation: () async {
      // Atomic close via RPC — also aborts any active/paused game_sessions
      // row for this room server-side (a plain rooms.update() never did).
      await _supabase.rpc('close_room', params: {'p_room_id': roomId});
    },
  );

  RoomEntity _rowToEntity(Map<String, dynamic> row) {
    return RoomEntity(
      id: row['id'] as String,
      ownerId: row['owner_id'] as String,
      name: row['name'] as String,
      status: RoomStatus.fromString(row['status'] as String? ?? 'waiting'),
      visibility: RoomVisibility.fromString(
        row['visibility'] as String? ?? 'public',
      ),
      maxPlayers: row['max_players'] as int? ?? 6,
      currentPlayers: row['current_players'] as int? ?? 0,
      inviteCode: row['invite_code'] as String?,
      gameType: row['game_type'] != null
          ? _parseGameType(row['game_type'] as String)
          : null,
      packId: row['pack_id'] as String?,
      language: row['language'] as String? ?? 'en',
      allowSpicy: row['allow_spicy'] as bool? ?? false,
      coverEmoji: row['cover_emoji'] as String? ?? '🎮',
      lastActiveAt: row['last_active_at'] != null
          ? DateTime.tryParse(row['last_active_at'] as String)
          : null,
      ownerTransferredAt: row['owner_transferred_at'] != null
          ? DateTime.tryParse(row['owner_transferred_at'] as String)
          : null,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String)
          : null,
    );
  }

  ChatMessageEntity _chatRowToEntity(Map<String, dynamic> row) {
    final profile = row['profiles'] as Map<String, dynamic>? ?? {};
    return ChatMessageEntity(
      id: row['id'] as String,
      roomId: row['room_id'] as String,
      userId: row['user_id'] as String,
      displayName: profile['display_name'] as String? ?? 'Player',
      avatarUrl: profile['avatar_url'] as String?,
      content: row['content'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      isDeleted: row['is_deleted'] as bool? ?? false,
      replyToId: row['reply_to_id'] as String?,
      replyToContent: row['reply_to_content'] as String?,
      replyToDisplayName: row['reply_to_display_name'] as String?,
    );
  }

  /// Premium-only, strictly read-only archive of rooms the caller owned
  /// that closed within the last 5 days — server-enforced via
  /// `get_my_closed_rooms`, not just a client-side filter.
  Future<List<Map<String, dynamic>>> getMyClosedRooms() => guardedCall(
    operationName: 'getMyClosedRooms',
    operation: () async {
      try {
        final rows = await _supabase.rpc('get_my_closed_rooms');
        return List<Map<String, dynamic>>.from(rows as List);
      } on PostgrestException catch (e) {
        if (e.message.contains('premium_required')) {
          throw const ForbiddenFailure(
            message: 'Closed room history requires Premium.',
          );
        }
        rethrow;
      }
    },
  );

  /// Full read-only archive payload for one closed room — room info, every
  /// game session's state snapshot, played packs, and participants.
  Future<Map<String, dynamic>> getClosedRoomDetails(String roomId) =>
      guardedCall(
        operationName: 'getClosedRoomDetails',
        operation: () async {
          try {
            final result = await _supabase.rpc(
              'get_closed_room_details',
              params: {'p_room_id': roomId},
            );
            return Map<String, dynamic>.from(result as Map);
          } on PostgrestException catch (e) {
            if (e.message.contains('premium_required')) {
              throw const ForbiddenFailure(
                message: 'Closed room history requires Premium.',
              );
            }
            if (e.message.contains('room_not_found')) {
              throw const NotFoundFailure(
                message: 'This room is no longer available.',
              );
            }
            rethrow;
          }
        },
      );

  GameType? _parseGameType(String s) {
    return switch (s) {
      'truth_or_dare' => GameType.truthOrDare,
      'never_have_i_ever' => GameType.neverHaveIEver,
      'meme_game' => GameType.memeGame,
      _ => null,
    };
  }
}
