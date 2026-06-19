import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/errors/failures.dart';
import '../domain/room_entity.dart';
import '../../games/engine/base_game_engine.dart';

class RoomRepository extends BaseRepository {
  RoomRepository._();
  static final RoomRepository _instance = RoomRepository._();
  static RoomRepository get instance => _instance;

  final _supabase = Supabase.instance.client;

  // ── Browse ────────────────────────────────────────────────────────────────
  Future<List<RoomEntity>> getPublicRooms({
    int limit = 20,
    int offset = 0,
    String? gameTypeFilter,
    String? userId, // current user — shows their private rooms too
  }) => guardedCall(
    operationName: 'getPublicRooms',
    operation: () async {
      // Public rooms
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

      // Private rooms where current user is owner or member
      List<dynamic> privateRows = [];
      if (userId != null) {
        // Rooms owned by user
        var ownedQ = _supabase
            .from('rooms')
            .select('*, room_settings(*)')
            .eq('owner_id', userId)
            .eq('visibility', 'private')
            .inFilter('status', ['waiting', 'in_game'])
            .isFilter('deleted_at', null);
        if (gameTypeFilter != null)
          ownedQ = ownedQ.eq('game_type', gameTypeFilter);
        final ownedRows = await ownedQ.order(
          'last_active_at',
          ascending: false,
        );

        // Rooms where user is a member
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
              .inFilter('status', ['waiting', 'in_game'])
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
      }

      // Fetch rooms the current user is banned from — exclude them
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

      // Merge, deduplicate by id, exclude banned rooms, sort by last_active_at
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
      // return unique.map(_rowToEntity).cast<RoomEntity>().toList();
      return unique
          .map((row) => _rowToEntity(row as Map<String, dynamic>))
          .toList();
    },
  );

  // ── Create ────────────────────────────────────────────────────────────────
  Future<RoomEntity> createRoom({
    required String ownerId,
    required String name,
    required RoomVisibility visibility,
    int maxPlayers = 6,
    String language = 'en',
    String coverEmoji = '🎮',
  }) => guardedCall(
    operationName: 'createRoom',
    operation: () async {
      // ── Single-room-per-user check ──────────────────────────────────
      final existing = await _supabase
          .from('rooms')
          .select('id, name')
          .eq('owner_id', ownerId)
          .inFilter('status', ['waiting', 'in_game'])
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (existing != null) {
        final roomName = existing['name'] as String? ?? 'your existing room';
        throw ConflictFailure(
          message:
              'You already have an open room "$roomName". '
              'Close it or transfer ownership before creating a new one.',
        );
      }

      final row = await _supabase
          .from('rooms')
          .insert({
            'owner_id': ownerId,
            'name': name,
            'visibility': visibility.name,
            'max_players': maxPlayers,
            'language': language,
            'cover_emoji': coverEmoji,
            'status': 'waiting',
          })
          .select()
          .single();

      // If invite_code wasn't auto-generated (e.g. public room), fetch it back
      // after a brief moment to allow the DB trigger to run
      String? inviteCode = row['invite_code'] as String?;
      if (inviteCode == null) {
        await Future.delayed(const Duration(milliseconds: 200));
        final refreshed = await _supabase
            .from('rooms')
            .select('invite_code')
            .eq('id', row['id'] as String)
            .single();
        inviteCode = refreshed['invite_code'] as String?;
      }

      // Add owner as first member (seat 0)
      await _supabase.from('room_members').upsert({
        'room_id': row['id'],
        'user_id': ownerId,
        'seat_order': 0,
        'role': 'player',
      }, onConflict: 'room_id,user_id');

      return _rowToEntity(row);
    },
  );

  // ── Join ──────────────────────────────────────────────────────────────────
  Future<RoomEntity> joinRoom({
    required String userId,
    required String roomId,
    String role = 'player',
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
      if (room.isFull) throw const ConflictFailure(message: 'Room is full.');

      // Check ban
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

      // Count current members for seat order
      final countRes = await _supabase
          .from('room_members')
          .select('id')
          .eq('room_id', roomId)
          .isFilter('left_at', null)
          .count(CountOption.exact);
      final seatOrder = countRes.count ?? 0;

      await _supabase.from('room_members').upsert({
        'room_id': roomId,
        'user_id': userId,
        'seat_order': seatOrder,
        'role': role,
        'is_ready': false,
        'left_at': null,
        'joined_at': DateTime.now().toIso8601String(),
      }, onConflict: 'room_id,user_id');

      return room;
    },
  );

  // ── Join by invite code ───────────────────────────────────────────────────
  Future<RoomEntity> joinByCode({
    required String userId,
    required String inviteCode,
    String? invitedBy, // set when joining via admin's direct invite link
  }) => guardedCall(
    operationName: 'joinByCode',
    operation: () async {
      // Use RPC to bypass RLS — invite code is the credential for private rooms
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
      // Bypass approval when the player was directly invited by the admin
      if (requiresApproval && invitedBy == null) {
        await requestToJoin(userId: userId, roomId: roomId);
        throw const PendingApprovalFailure();
      }
      return joinRoom(userId: userId, roomId: roomId);
    },
  );

  // ── Join requests ─────────────────────────────────────────────────────────

  /// Submit a join request for approval-required rooms.
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

  /// Approve or reject a join request (owner/moderator only).
  Future<void> resolveJoinRequest({
    required String requestId,
    required bool approve,
    required String roomId,
    required String targetUserId,
  }) => guardedCall(
    operationName: 'resolveJoinRequest',
    operation: () async {
      await _supabase
          .from('room_join_requests')
          .update({
            'status': approve ? 'approved' : 'rejected',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      if (approve) {
        // Check if game is in progress and spectators allowed (in room_settings)
        final roomInfo = await _supabase
            .from('rooms')
            .select('status')
            .eq('id', roomId)
            .maybeSingle();
        final settingsInfo = await _supabase
            .from('room_settings')
            .select('allow_spectators')
            .eq('room_id', roomId)
            .maybeSingle();
        final inGame = roomInfo?['status'] == 'in_game';
        final allowSpectators =
            settingsInfo?['allow_spectators'] as bool? ?? false;
        final role = (inGame && allowSpectators) ? 'spectator' : 'player';
        await joinRoom(userId: targetUserId, roomId: roomId, role: role);
      }
    },
  );

  /// Get pending join requests for a room (for admin/mod).
  Future<List<Map<String, dynamic>>> getPendingRequests(String roomId) =>
      guardedCall(
        operationName: 'getPendingRequests',
        operation: () async {
          // Fetch requests then profiles separately to avoid FK hint issues
          final rows = await _supabase
              .from('room_join_requests')
              .select('id, user_id, message, created_at')
              .eq('room_id', roomId)
              .eq('status', 'pending')
              .order('created_at');
          final requests = (rows as List).cast<Map<String, dynamic>>();

          // Enrich with profile data
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

  /// Check the status of a user's join request.
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

  // ── Leave ─────────────────────────────────────────────────────────────────
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

  // ── Status ────────────────────────────────────────────────────────────────
  Future<void> updateStatus(String roomId, RoomStatus status) => guardedCall(
    operationName: 'updateStatus',
    operation: () async {
      await _supabase
          .from('rooms')
          .update({
            'status': status.toDbString(),
            'last_active_at': DateTime.now().toIso8601String(),
          })
          .eq('id', roomId);
    },
  );

  // ── Settings ──────────────────────────────────────────────────────────────
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

  // ── Details ───────────────────────────────────────────────────────────────
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
          .select('*, profiles(id, username, display_name, avatar_url)')
          .eq('room_id', roomId)
          .isFilter('left_at', null)
          .order('seat_order');

      final modRows = await _supabase
          .from('room_moderators')
          .select('user_id')
          .eq('room_id', roomId);

      final modIds = modRows.map((r) => r['user_id'] as String).toSet();
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
          seatOrder: r['seat_order'] as int? ?? 0,
          isReady: r['is_ready'] as bool? ?? false,
          isOwner: uid == ownerId,
          isModerator: modIds.contains(uid),
          isSpectator: (r['role'] as String?) == 'spectator',
          isMuted: r['is_muted'] as bool? ?? false,
          joinedAt: r['joined_at'] != null
              ? DateTime.tryParse(r['joined_at'] as String)
              : null,
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

  // ── Chat ──────────────────────────────────────────────────────────────────
  Future<List<ChatMessageEntity>> getChatHistory(
    String roomId, {
    int limit = 50,
    String? before, // message id for cursor pagination
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
        // Get the created_at of the cursor message
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
  }) => guardedCall(
    operationName: 'persistChatMessage',
    operation: () async {
      await _supabase.from('room_chat_messages').insert({
        'room_id': roomId,
        'user_id': userId,
        'content': content,
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

  // ── Moderation ────────────────────────────────────────────────────────────
  Future<void> kickMember(String roomId, String targetUserId) => guardedCall(
    operationName: 'kickMember',
    operation: () async {
      // Set left_at so the trigger fires and decrements current_players
      await _supabase
          .from('room_members')
          .update({
            'left_at': DateTime.now().toIso8601String(),
            'kicked_at': DateTime.now().toIso8601String(),
          })
          .eq('room_id', roomId)
          .eq('user_id', targetUserId)
          .isFilter('left_at', null); // only active members
    },
  );

  Future<void> muteMember(
    String roomId,
    String targetUserId, {
    required bool muted,
  }) => guardedCall(
    operationName: 'muteMember',
    operation: () async {
      await _supabase
          .from('room_members')
          .update({'is_muted': muted})
          .eq('room_id', roomId)
          .eq('user_id', targetUserId);
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
      await _supabase.from('room_bans').upsert({
        'room_id': roomId,
        'user_id': targetUserId,
        'banned_by': bannedBy,
        'reason': reason,
        'banned_until': null, // permanent ban
      }, onConflict: 'room_id,user_id');
      await kickMember(roomId, targetUserId);
    },
  );

  Future<List<Map<String, dynamic>>> getBannedMembers(String roomId) =>
      guardedCall(
        operationName: 'getBannedMembers',
        operation: () async {
          // Fetch bans
          final bans = await _supabase
              .from('room_bans')
              .select('user_id, reason, banned_until')
              .eq('room_id', roomId)
              .isFilter('lifted_at', null);
          final banList = (bans as List).cast<Map<String, dynamic>>();
          if (banList.isEmpty) return banList;
          // Fetch display names separately
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

  /// Mark player as temporarily away — seat preserved, they can rejoin game.
  Future<void> setMemberAway(
    String roomId,
    String userId, {
    required bool away,
  }) => guardedCall(
    operationName: 'setMemberAway',
    operation: () async {
      await _supabase
          .from('room_members')
          .update({'is_away': away})
          .eq('room_id', roomId)
          .eq('user_id', userId);
    },
  );

  /// Player left definitively — downgrade to spectator-only for this room.
  Future<void> setMemberDefinitiveLeave(String roomId, String userId) =>
      guardedCall(
        operationName: 'setMemberDefinitiveLeave',
        operation: () async {
          await _supabase
              .from('room_members')
              .update({'role': 'spectator', 'left_definitively': true})
              .eq('room_id', roomId)
              .eq('user_id', userId);
        },
      );

  Future<void> transferOwnership(String roomId, String newOwnerId) =>
      guardedCall(
        operationName: 'transferOwnership',
        operation: () async {
          await _supabase
              .from('rooms')
              .update({'owner_id': newOwnerId})
              .eq('id', roomId);
        },
      );

  Future<void> grantModerator(String roomId, String userId, String grantedBy) =>
      guardedCall(
        operationName: 'grantModerator',
        operation: () async {
          await _supabase.from('room_moderators').upsert({
            'room_id': roomId,
            'user_id': userId,
            'granted_by': grantedBy,
          }, onConflict: 'room_id,user_id');
        },
      );

  Future<void> revokeModerator(String roomId, String userId) => guardedCall(
    operationName: 'revokeModerator',
    operation: () async {
      await _supabase
          .from('room_moderators')
          .delete()
          .eq('room_id', roomId)
          .eq('user_id', userId);
    },
  );

  Future<void> softDeleteRoom(String roomId) => guardedCall(
    operationName: 'softDeleteRoom',
    operation: () async {
      await _supabase
          .from('rooms')
          .update({
            'status': 'closed',
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', roomId);
    },
  );

  // ── Mappers ───────────────────────────────────────────────────────────────
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
    );
  }

  GameType? _parseGameType(String s) {
    return switch (s) {
      'truth_or_dare' => GameType.truthOrDare,
      'never_have_i_ever' => GameType.neverHaveIEver,
      'meme_game' => GameType.memeGame,
      _ => null,
    };
  }
}
