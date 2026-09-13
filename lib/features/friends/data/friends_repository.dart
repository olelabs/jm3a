// // // // // // // // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // // // // // // // // import '../../../core/data/base_repository.dart';
// // // // // // // // // // // // // // import '../../../core/errors/failures.dart';
// // // // // // // // // // // // // // import '../../../features/auth/domain/entities/user_entity.dart';

// // // // // // // // // // // // // // // ── Domain types ──────────────────────────────────────────────────────────────

// // // // // // // // // // // // // // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // // // // // // // // // // // // // class FriendEntity {
// // // // // // // // // // // // // //   const FriendEntity({
// // // // // // // // // // // // // //     required this.userId,
// // // // // // // // // // // // // //     required this.displayName,
// // // // // // // // // // // // // //     this.username,
// // // // // // // // // // // // // //     this.avatarUrl,
// // // // // // // // // // // // // //     required this.status,
// // // // // // // // // // // // // //     required this.isRequester,
// // // // // // // // // // // // // //     this.mutualFriendsCount = 0,
// // // // // // // // // // // // // //     this.friendshipId,
// // // // // // // // // // // // // //   });

// // // // // // // // // // // // // //   final String userId;
// // // // // // // // // // // // // //   final String displayName;
// // // // // // // // // // // // // //   final String? username;
// // // // // // // // // // // // // //   final String? avatarUrl;
// // // // // // // // // // // // // //   final FriendshipStatus status;
// // // // // // // // // // // // // //   final bool isRequester;
// // // // // // // // // // // // // //   final int mutualFriendsCount;
// // // // // // // // // // // // // //   final String? friendshipId;

// // // // // // // // // // // // // //   bool get isAccepted => status == FriendshipStatus.accepted;
// // // // // // // // // // // // // //   bool get isPending => status == FriendshipStatus.pending;
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // // class FollowEntity {
// // // // // // // // // // // // // //   const FollowEntity({
// // // // // // // // // // // // // //     required this.userId,
// // // // // // // // // // // // // //     required this.displayName,
// // // // // // // // // // // // // //     this.username,
// // // // // // // // // // // // // //     this.avatarUrl,
// // // // // // // // // // // // // //     required this.followedAt,
// // // // // // // // // // // // // //     this.isVerified = false,
// // // // // // // // // // // // // //   });

// // // // // // // // // // // // // //   final String userId;
// // // // // // // // // // // // // //   final String displayName;
// // // // // // // // // // // // // //   final String? username;
// // // // // // // // // // // // // //   final String? avatarUrl;
// // // // // // // // // // // // // //   final DateTime followedAt;
// // // // // // // // // // // // // //   final bool isVerified;
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // // class SocialProfile {
// // // // // // // // // // // // // //   const SocialProfile({
// // // // // // // // // // // // // //     required this.userId,
// // // // // // // // // // // // // //     required this.displayName,
// // // // // // // // // // // // // //     this.username,
// // // // // // // // // // // // // //     this.avatarUrl,
// // // // // // // // // // // // // //     this.bio,
// // // // // // // // // // // // // //     required this.followersCount,
// // // // // // // // // // // // // //     required this.followingCount,
// // // // // // // // // // // // // //     required this.friendsCount,
// // // // // // // // // // // // // //     this.friendshipStatus,
// // // // // // // // // // // // // //     this.isFollowing = false,
// // // // // // // // // // // // // //     this.isFollowedBy = false,
// // // // // // // // // // // // // //     this.isBlocked = false,
// // // // // // // // // // // // // //     this.isBlockedBy = false,
// // // // // // // // // // // // // //     this.isVerified = false,
// // // // // // // // // // // // // //   });

// // // // // // // // // // // // // //   final String userId;
// // // // // // // // // // // // // //   final String displayName;
// // // // // // // // // // // // // //   final String? username;
// // // // // // // // // // // // // //   final String? avatarUrl;
// // // // // // // // // // // // // //   final String? bio;
// // // // // // // // // // // // // //   final int followersCount;
// // // // // // // // // // // // // //   final int followingCount;
// // // // // // // // // // // // // //   final int friendsCount;
// // // // // // // // // // // // // //   final FriendshipStatus? friendshipStatus;
// // // // // // // // // // // // // //   final bool isFollowing;
// // // // // // // // // // // // // //   final bool isFollowedBy;
// // // // // // // // // // // // // //   final bool isBlocked;
// // // // // // // // // // // // // //   final bool isBlockedBy;
// // // // // // // // // // // // // //   final bool isVerified;

// // // // // // // // // // // // // //   bool get canInteract => !isBlocked && !isBlockedBy;
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // // // ── Repository ────────────────────────────────────────────────────────────────

// // // // // // // // // // // // // // class FriendsRepository extends BaseRepository {
// // // // // // // // // // // // // //   FriendsRepository._();
// // // // // // // // // // // // // //   static final FriendsRepository _instance = FriendsRepository._();
// // // // // // // // // // // // // //   static FriendsRepository get instance => _instance;

// // // // // // // // // // // // // //   final _supabase = Supabase.instance.client;

// // // // // // // // // // // // // //   // ── Friends ───────────────────────────────────────────────────────────────

// // // // // // // // // // // // // //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// // // // // // // // // // // // // //     operationName: 'getFriends',
// // // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // // // //           .select(
// // // // // // // // // // // // // //             'id,status,requester_id,addressee_id,'
// // // // // // // // // // // // // //             'requester:profiles!requester_id(id,display_name,username,avatar_url),'
// // // // // // // // // // // // // //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url)',
// // // // // // // // // // // // // //           )
// // // // // // // // // // // // // //           .or('requester_id.eq.$userId,addressee_id.eq.$userId')
// // // // // // // // // // // // // //           .eq('status', 'accepted');
// // // // // // // // // // // // // //       return rows.map((r) => _toFriendEntity(r, userId)).toList();
// // // // // // // // // // // // // //     },
// // // // // // // // // // // // // //   );

// // // // // // // // // // // // // //   Future<List<FriendEntity>> getPendingRequests(String userId) => guardedCall(
// // // // // // // // // // // // // //     operationName: 'getPendingRequests',
// // // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // // // // // // // // //           .eq('addressee_id', userId)
// // // // // // // // // // // // // //           .eq('status', 'pending');
// // // // // // // // // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // // // // // // // // //       // Fetch requester profiles separately to avoid join ambiguity
// // // // // // // // // // // // // //       final requesterIds = rows
// // // // // // // // // // // // // //           .map((r) => r['requester_id'] as String)
// // // // // // // // // // // // // //           .toList();
// // // // // // // // // // // // // //       final profiles = await _supabase
// // // // // // // // // // // // // //           .from('profiles')
// // // // // // // // // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // // // // // // // // //           .inFilter('id', requesterIds);
// // // // // // // // // // // // // //       final profileMap = {
// // // // // // // // // // // // // //         for (final p in profiles as List)
// // // // // // // // // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // // // // // // // // //       };
// // // // // // // // // // // // // //       return rows.map((r) {
// // // // // // // // // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // // // // // // // // //         row['requester'] = profileMap[row['requester_id']] ?? {};
// // // // // // // // // // // // // //         return _toFriendEntity(row, userId);
// // // // // // // // // // // // // //       }).toList();
// // // // // // // // // // // // // //     },
// // // // // // // // // // // // // //   );

// // // // // // // // // // // // // //   Future<List<FriendEntity>> getSentRequests(String userId) => guardedCall(
// // // // // // // // // // // // // //     operationName: 'getSentRequests',
// // // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // // // // // // // // //           .eq('requester_id', userId)
// // // // // // // // // // // // // //           .eq('status', 'pending');
// // // // // // // // // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // // // // // // // // //       // Fetch addressee profiles separately
// // // // // // // // // // // // // //       final addresseeIds = rows
// // // // // // // // // // // // // //           .map((r) => r['addressee_id'] as String)
// // // // // // // // // // // // // //           .toList();
// // // // // // // // // // // // // //       final profiles = await _supabase
// // // // // // // // // // // // // //           .from('profiles')
// // // // // // // // // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // // // // // // // // //           .inFilter('id', addresseeIds);
// // // // // // // // // // // // // //       final profileMap = {
// // // // // // // // // // // // // //         for (final p in profiles as List)
// // // // // // // // // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // // // // // // // // //       };
// // // // // // // // // // // // // //       return rows.map((r) {
// // // // // // // // // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // // // // // // // // //         row['addressee'] = profileMap[row['addressee_id']] ?? {};
// // // // // // // // // // // // // //         return _toFriendEntity(row, userId);
// // // // // // // // // // // // // //       }).toList();
// // // // // // // // // // // // // //     },
// // // // // // // // // // // // // //   );

// // // // // // // // // // // // // //   Future<void> sendFriendRequest({
// // // // // // // // // // // // // //     required String requesterId,
// // // // // // // // // // // // // //     required String addresseeId,
// // // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // // //     operationName: 'sendFriendRequest',
// // // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // // //       // Check not blocked
// // // // // // // // // // // // // //       await _checkNotBlocked(requesterId, addresseeId);
// // // // // // // // // // // // // //       await _supabase.from('friendships').insert({
// // // // // // // // // // // // // //         'requester_id': requesterId,
// // // // // // // // // // // // // //         'addressee_id': addresseeId,
// // // // // // // // // // // // // //         'status': 'pending',
// // // // // // // // // // // // // //       });
// // // // // // // // // // // // // //     },
// // // // // // // // // // // // // //   );

// // // // // // // // // // // // // //   Future<void> respondToRequest({
// // // // // // // // // // // // // //     required String requesterId,
// // // // // // // // // // // // // //     required String addresseeId,
// // // // // // // // // // // // // //     required bool accept,
// // // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // // //     operationName: 'respondToRequest',
// // // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // // //       await _supabase
// // // // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // // // //           .update({'status': accept ? 'accepted' : 'rejected'})
// // // // // // // // // // // // // //           .eq('requester_id', requesterId)
// // // // // // // // // // // // // //           .eq('addressee_id', addresseeId);
// // // // // // // // // // // // // //     },
// // // // // // // // // // // // // //   );

// // // // // // // // // // // // // //   Future<void> removeFriend({
// // // // // // // // // // // // // //     required String userId,
// // // // // // // // // // // // // //     required String friendId,
// // // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // // //     operationName: 'removeFriend',
// // // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // // //       await _supabase
// // // // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // // // //           .delete()
// // // // // // // // // // // // // //           .or(
// // // // // // // // // // // // // //             'and(requester_id.eq.$userId,addressee_id.eq.$friendId),'
// // // // // // // // // // // // // //             'and(requester_id.eq.$friendId,addressee_id.eq.$userId)',
// // // // // // // // // // // // // //           );
// // // // // // // // // // // // // //     },
// // // // // // // // // // // // // //   );

// // // // // // // // // // // // // //   Future<void> cancelRequest({
// // // // // // // // // // // // // //     required String requesterId,
// // // // // // // // // // // // // //     required String addresseeId,
// // // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // // //     operationName: 'cancelRequest',
// // // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // // //       await _supabase
// // // // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // // // //           .delete()
// // // // // // // // // // // // // //           .eq('requester_id', requesterId)
// // // // // // // // // // // // // //           .eq('addressee_id', addresseeId)
// // // // // // // // // // // // // //           .eq('status', 'pending');
// // // // // // // // // // // // // //     },
// // // // // // // // // // // // // //   );

// // // // // // // // // // // // // //   // ── Follow system ─────────────────────────────────────────────────────────

// // // // // // // // // // // // // //   Future<void> followUser(String followerId, String followingId) => guardedCall(
// // // // // // // // // // // // // //     operationName: 'followUser',
// // // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // // //       await _checkNotBlocked(followerId, followingId);
// // // // // // // // // // // // // //       await _supabase.from('follows').upsert({
// // // // // // // // // // // // // //         'follower_id': followerId,
// // // // // // // // // // // // // //         'following_id': followingId,
// // // // // // // // // // // // // //       }, onConflict: 'follower_id,following_id');
// // // // // // // // // // // // // //     },
// // // // // // // // // // // // // //   );

// // // // // // // // // // // // // //   Future<void> unfollowUser(String followerId, String followingId) =>
// // // // // // // // // // // // // //       guardedCall(
// // // // // // // // // // // // // //         operationName: 'unfollowUser',
// // // // // // // // // // // // // //         operation: () async {
// // // // // // // // // // // // // //           await _supabase
// // // // // // // // // // // // // //               .from('follows')
// // // // // // // // // // // // // //               .delete()
// // // // // // // // // // // // // //               .eq('follower_id', followerId)
// // // // // // // // // // // // // //               .eq('following_id', followingId);
// // // // // // // // // // // // // //         },
// // // // // // // // // // // // // //       );

// // // // // // // // // // // // // //   Future<List<FollowEntity>> getFollowers(
// // // // // // // // // // // // // //     String userId, {
// // // // // // // // // // // // // //     int limit = 50,
// // // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // // //     operationName: 'getFollowers',
// // // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // // // //           .from('follows')
// // // // // // // // // // // // // //           .select(
// // // // // // // // // // // // // //             'follower_id,created_at,'
// // // // // // // // // // // // // //             'profiles!follower_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // // // // // // // // //           )
// // // // // // // // // // // // // //           .eq('following_id', userId)
// // // // // // // // // // // // // //           .order('created_at', ascending: false)
// // // // // // // // // // // // // //           .limit(limit);
// // // // // // // // // // // // // //       return rows.map(_toFollowEntity).toList();
// // // // // // // // // // // // // //     },
// // // // // // // // // // // // // //   );

// // // // // // // // // // // // // //   Future<List<FollowEntity>> getFollowing(
// // // // // // // // // // // // // //     String userId, {
// // // // // // // // // // // // // //     int limit = 50,
// // // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // // //     operationName: 'getFollowing',
// // // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // // // //           .from('follows')
// // // // // // // // // // // // // //           .select(
// // // // // // // // // // // // // //             'following_id,created_at,'
// // // // // // // // // // // // // //             'profiles!following_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // // // // // // // // //           )
// // // // // // // // // // // // // //           .eq('follower_id', userId)
// // // // // // // // // // // // // //           .order('created_at', ascending: false)
// // // // // // // // // // // // // //           .limit(limit);
// // // // // // // // // // // // // //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// // // // // // // // // // // // // //     },
// // // // // // // // // // // // // //   );

// // // // // // // // // // // // // //   // ── Block system ──────────────────────────────────────────────────────────

// // // // // // // // // // // // // //   Future<void> blockUser({
// // // // // // // // // // // // // //     required String blockerId,
// // // // // // // // // // // // // //     required String blockedId,
// // // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // // //     operationName: 'blockUser',
// // // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // // //       await _supabase.from('blocked_users').upsert({
// // // // // // // // // // // // // //         'blocker_id': blockerId,
// // // // // // // // // // // // // //         'blocked_id': blockedId,
// // // // // // // // // // // // // //       }, onConflict: 'blocker_id,blocked_id');
// // // // // // // // // // // // // //       // Also remove any existing friendship
// // // // // // // // // // // // // //       await removeFriend(
// // // // // // // // // // // // // //         userId: blockerId,
// // // // // // // // // // // // // //         friendId: blockedId,
// // // // // // // // // // // // // //       ).catchError((_) {});
// // // // // // // // // // // // // //       // Remove follow in both directions
// // // // // // // // // // // // // //       await unfollowUser(blockerId, blockedId).catchError((_) {});
// // // // // // // // // // // // // //       await unfollowUser(blockedId, blockerId).catchError((_) {});
// // // // // // // // // // // // // //     },
// // // // // // // // // // // // // //   );

// // // // // // // // // // // // // //   Future<void> unblockUser({
// // // // // // // // // // // // // //     required String blockerId,
// // // // // // // // // // // // // //     required String blockedId,
// // // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // // //     operationName: 'unblockUser',
// // // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // // //       await _supabase
// // // // // // // // // // // // // //           .from('blocked_users')
// // // // // // // // // // // // // //           .delete()
// // // // // // // // // // // // // //           .eq('blocker_id', blockerId)
// // // // // // // // // // // // // //           .eq('blocked_id', blockedId);
// // // // // // // // // // // // // //     },
// // // // // // // // // // // // // //   );

// // // // // // // // // // // // // //   Future<List<FriendEntity>> getBlockedUsers(String userId) => guardedCall(
// // // // // // // // // // // // // //     operationName: 'getBlockedUsers',
// // // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // // // //           .from('blocked_users')
// // // // // // // // // // // // // //           .select(
// // // // // // // // // // // // // //             'blocked_id,created_at,'
// // // // // // // // // // // // // //             'profiles!blocked_id(id,display_name,username,avatar_url)',
// // // // // // // // // // // // // //           )
// // // // // // // // // // // // // //           .eq('blocker_id', userId)
// // // // // // // // // // // // // //           .order('created_at', ascending: false);
// // // // // // // // // // // // // //       return rows.map((r) {
// // // // // // // // // // // // // //         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
// // // // // // // // // // // // // //         return FriendEntity(
// // // // // // // // // // // // // //           userId: profile['id'] as String? ?? '',
// // // // // // // // // // // // // //           displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // // // // // // //           username: profile['username'] as String?,
// // // // // // // // // // // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // // // // // //           status: FriendshipStatus.blocked,
// // // // // // // // // // // // // //           isRequester: true,
// // // // // // // // // // // // // //         );
// // // // // // // // // // // // // //       }).toList();
// // // // // // // // // // // // // //     },
// // // // // // // // // // // // // //   );

// // // // // // // // // // // // // //   // ── Social profile ────────────────────────────────────────────────────────

// // // // // // // // // // // // // //   Future<SocialProfile> getSocialProfile({
// // // // // // // // // // // // // //     required String targetUserId,
// // // // // // // // // // // // // //     required String viewerUserId,
// // // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // // //     operationName: 'getSocialProfile',
// // // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // // //       final profile = await _supabase
// // // // // // // // // // // // // //           .from('profiles_public')
// // // // // // // // // // // // // //           .select()
// // // // // // // // // // // // // //           .eq('id', targetUserId)
// // // // // // // // // // // // // //           .single();

// // // // // // // // // // // // // //       final [
// // // // // // // // // // // // // //         blockedByMe,
// // // // // // // // // // // // // //         blockedByThem,
// // // // // // // // // // // // // //         friendshipRow,
// // // // // // // // // // // // // //         followingRow,
// // // // // // // // // // // // // //         followedByRow,
// // // // // // // // // // // // // //       ] = await Future.wait([
// // // // // // // // // // // // // //         _supabase
// // // // // // // // // // // // // //             .from('blocked_users')
// // // // // // // // // // // // // //             .select('blocker_id')
// // // // // // // // // // // // // //             .eq('blocker_id', viewerUserId)
// // // // // // // // // // // // // //             .eq('blocked_id', targetUserId)
// // // // // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // // // // //         _supabase
// // // // // // // // // // // // // //             .from('blocked_users')
// // // // // // // // // // // // // //             .select('blocker_id')
// // // // // // // // // // // // // //             .eq('blocker_id', targetUserId)
// // // // // // // // // // // // // //             .eq('blocked_id', viewerUserId)
// // // // // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // // // // //         _supabase
// // // // // // // // // // // // // //             .from('friendships')
// // // // // // // // // // // // // //             .select('status')
// // // // // // // // // // // // // //             .or(
// // // // // // // // // // // // // //               'and(requester_id.eq.$viewerUserId,addressee_id.eq.$targetUserId),'
// // // // // // // // // // // // // //               'and(requester_id.eq.$targetUserId,addressee_id.eq.$viewerUserId)',
// // // // // // // // // // // // // //             )
// // // // // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // // // // //         _supabase
// // // // // // // // // // // // // //             .from('follows')
// // // // // // // // // // // // // //             .select('id')
// // // // // // // // // // // // // //             .eq('follower_id', viewerUserId)
// // // // // // // // // // // // // //             .eq('following_id', targetUserId)
// // // // // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // // // // //         _supabase
// // // // // // // // // // // // // //             .from('follows')
// // // // // // // // // // // // // //             .select('id')
// // // // // // // // // // // // // //             .eq('follower_id', targetUserId)
// // // // // // // // // // // // // //             .eq('following_id', viewerUserId)
// // // // // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // // // // //       ]);

// // // // // // // // // // // // // //       FriendshipStatus? friendStatus;
// // // // // // // // // // // // // //       if (friendshipRow != null) {
// // // // // // // // // // // // // //         friendStatus = FriendshipStatus.values.firstWhere(
// // // // // // // // // // // // // //           (s) => s.name == (friendshipRow as Map)['status'],
// // // // // // // // // // // // // //           orElse: () => FriendshipStatus.pending,
// // // // // // // // // // // // // //         );
// // // // // // // // // // // // // //       }

// // // // // // // // // // // // // //       return SocialProfile(
// // // // // // // // // // // // // //         userId: profile['id'] as String,
// // // // // // // // // // // // // //         displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // // // // // // //         username: profile['username'] as String?,
// // // // // // // // // // // // // //         avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // // // // // //         bio: profile['bio'] as String?,
// // // // // // // // // // // // // //         followersCount: profile['followers_count'] as int? ?? 0,
// // // // // // // // // // // // // //         followingCount: profile['following_count'] as int? ?? 0,
// // // // // // // // // // // // // //         friendsCount: profile['friends_count'] as int? ?? 0,
// // // // // // // // // // // // // //         friendshipStatus: friendStatus,
// // // // // // // // // // // // // //         isFollowing: followingRow != null,
// // // // // // // // // // // // // //         isFollowedBy: followedByRow != null,
// // // // // // // // // // // // // //         isBlocked: blockedByMe != null,
// // // // // // // // // // // // // //         isBlockedBy: blockedByThem != null,
// // // // // // // // // // // // // //         isVerified: profile['verification_status'] == 'verified',
// // // // // // // // // // // // // //       );
// // // // // // // // // // // // // //     },
// // // // // // // // // // // // // //   );

// // // // // // // // // // // // // //   // ── Search ────────────────────────────────────────────────────────────────

// // // // // // // // // // // // // //   Future<List<UserEntity>> searchUsers(
// // // // // // // // // // // // // //     String query, {
// // // // // // // // // // // // // //     required String excludeUserId,
// // // // // // // // // // // // // //     int limit = 20,
// // // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // // //     operationName: 'searchUsers',
// // // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // // // //           .from('profiles_public')
// // // // // // // // // // // // // //           .select('id,username,display_name,avatar_url')
// // // // // // // // // // // // // //           .or('username.ilike.%$query%,display_name.ilike.%$query%')
// // // // // // // // // // // // // //           .neq('id', excludeUserId)
// // // // // // // // // // // // // //           .limit(limit);
// // // // // // // // // // // // // //       return rows
// // // // // // // // // // // // // //           .map(
// // // // // // // // // // // // // //             (r) => UserEntity(
// // // // // // // // // // // // // //               id: r['id'] as String,
// // // // // // // // // // // // // //               email: '',
// // // // // // // // // // // // // //               username: r['username'] as String?,
// // // // // // // // // // // // // //               displayName: r['display_name'] as String?,
// // // // // // // // // // // // // //               avatarUrl: r['avatar_url'] as String?,
// // // // // // // // // // // // // //             ),
// // // // // // // // // // // // // //           )
// // // // // // // // // // // // // //           .toList();
// // // // // // // // // // // // // //     },
// // // // // // // // // // // // // //   );

// // // // // // // // // // // // // //   // ── Private helpers ───────────────────────────────────────────────────────

// // // // // // // // // // // // // //   Future<void> _checkNotBlocked(String a, String b) async {
// // // // // // // // // // // // // //     final block = await _supabase
// // // // // // // // // // // // // //         .from('blocked_users')
// // // // // // // // // // // // // //         .select('blocker_id')
// // // // // // // // // // // // // //         .or(
// // // // // // // // // // // // // //           'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // // // // // // // // // // // // //           'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // // // // // // // // // // // // //         )
// // // // // // // // // // // // // //         .maybeSingle();
// // // // // // // // // // // // // //     if (block != null) {
// // // // // // // // // // // // // //       throw const ForbiddenFailure(message: 'Cannot interact with this user.');
// // // // // // // // // // // // // //     }
// // // // // // // // // // // // // //   }

// // // // // // // // // // // // // //   FriendEntity _toFriendEntity(Map<String, dynamic> row, String currentUserId) {
// // // // // // // // // // // // // //     final requesterId = row['requester_id'] as String? ?? '';
// // // // // // // // // // // // // //     final isRequester = requesterId == currentUserId;
// // // // // // // // // // // // // //     final rawOther = isRequester ? row['addressee'] : row['requester'];
// // // // // // // // // // // // // //     final other = (rawOther is Map)
// // // // // // // // // // // // // //         ? Map<String, dynamic>.from(rawOther)
// // // // // // // // // // // // // //         : <String, dynamic>{};
// // // // // // // // // // // // // //     return FriendEntity(
// // // // // // // // // // // // // //       friendshipId: row['id'] as String?,
// // // // // // // // // // // // // //       userId: other['id'] as String? ?? '',
// // // // // // // // // // // // // //       displayName: other['display_name'] as String? ?? 'Player',
// // // // // // // // // // // // // //       username: other['username'] as String?,
// // // // // // // // // // // // // //       avatarUrl: other['avatar_url'] as String?,
// // // // // // // // // // // // // //       status: FriendshipStatus.values.firstWhere(
// // // // // // // // // // // // // //         (s) => s.name == (row['status'] as String? ?? ''),
// // // // // // // // // // // // // //         orElse: () => FriendshipStatus.pending,
// // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // //       isRequester: isRequester,
// // // // // // // // // // // // // //     );
// // // // // // // // // // // // // //   }

// // // // // // // // // // // // // //   FollowEntity _toFollowEntity(
// // // // // // // // // // // // // //     Map<String, dynamic> row, {
// // // // // // // // // // // // // //     bool followingMode = false,
// // // // // // // // // // // // // //   }) {
// // // // // // // // // // // // // //     final profile =
// // // // // // // // // // // // // //         row[followingMode ? 'profiles!following_id' : 'profiles!follower_id']
// // // // // // // // // // // // // //             as Map<String, dynamic>? ??
// // // // // // // // // // // // // //         {};
// // // // // // // // // // // // // //     return FollowEntity(
// // // // // // // // // // // // // //       userId: profile['id'] as String? ?? '',
// // // // // // // // // // // // // //       displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // // // // // // //       username: profile['username'] as String?,
// // // // // // // // // // // // // //       avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // // // // // //       followedAt: DateTime.parse(row['created_at'] as String),
// // // // // // // // // // // // // //       isVerified: profile['verification_status'] == 'verified',
// // // // // // // // // // // // // //     );
// // // // // // // // // // // // // //   }
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // // // // // // // import '../../../core/data/base_repository.dart';
// // // // // // // // // // // // // import '../../../core/errors/failures.dart';
// // // // // // // // // // // // // import '../../../features/auth/domain/entities/user_entity.dart';

// // // // // // // // // // // // // // ── Domain types ──────────────────────────────────────────────────────────────

// // // // // // // // // // // // // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // // // // // // // // // // // // class FriendEntity {
// // // // // // // // // // // // //   const FriendEntity({
// // // // // // // // // // // // //     required this.userId,
// // // // // // // // // // // // //     required this.displayName,
// // // // // // // // // // // // //     this.username,
// // // // // // // // // // // // //     this.avatarUrl,
// // // // // // // // // // // // //     required this.status,
// // // // // // // // // // // // //     required this.isRequester,
// // // // // // // // // // // // //     this.mutualFriendsCount = 0,
// // // // // // // // // // // // //     this.friendshipId,
// // // // // // // // // // // // //   });

// // // // // // // // // // // // //   final String userId;
// // // // // // // // // // // // //   final String displayName;
// // // // // // // // // // // // //   final String? username;
// // // // // // // // // // // // //   final String? avatarUrl;
// // // // // // // // // // // // //   final FriendshipStatus status;
// // // // // // // // // // // // //   final bool isRequester;
// // // // // // // // // // // // //   final int mutualFriendsCount;
// // // // // // // // // // // // //   final String? friendshipId;

// // // // // // // // // // // // //   bool get isAccepted => status == FriendshipStatus.accepted;
// // // // // // // // // // // // //   bool get isPending => status == FriendshipStatus.pending;
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class FollowEntity {
// // // // // // // // // // // // //   const FollowEntity({
// // // // // // // // // // // // //     required this.userId,
// // // // // // // // // // // // //     required this.displayName,
// // // // // // // // // // // // //     this.username,
// // // // // // // // // // // // //     this.avatarUrl,
// // // // // // // // // // // // //     required this.followedAt,
// // // // // // // // // // // // //     this.isVerified = false,
// // // // // // // // // // // // //   });

// // // // // // // // // // // // //   final String userId;
// // // // // // // // // // // // //   final String displayName;
// // // // // // // // // // // // //   final String? username;
// // // // // // // // // // // // //   final String? avatarUrl;
// // // // // // // // // // // // //   final DateTime followedAt;
// // // // // // // // // // // // //   final bool isVerified;
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class SocialProfile {
// // // // // // // // // // // // //   const SocialProfile({
// // // // // // // // // // // // //     required this.userId,
// // // // // // // // // // // // //     required this.displayName,
// // // // // // // // // // // // //     this.username,
// // // // // // // // // // // // //     this.avatarUrl,
// // // // // // // // // // // // //     this.bio,
// // // // // // // // // // // // //     required this.followersCount,
// // // // // // // // // // // // //     required this.followingCount,
// // // // // // // // // // // // //     required this.friendsCount,
// // // // // // // // // // // // //     this.friendshipStatus,
// // // // // // // // // // // // //     this.isFollowing = false,
// // // // // // // // // // // // //     this.isFollowedBy = false,
// // // // // // // // // // // // //     this.isBlocked = false,
// // // // // // // // // // // // //     this.isBlockedBy = false,
// // // // // // // // // // // // //     this.isVerified = false,
// // // // // // // // // // // // //   });

// // // // // // // // // // // // //   final String userId;
// // // // // // // // // // // // //   final String displayName;
// // // // // // // // // // // // //   final String? username;
// // // // // // // // // // // // //   final String? avatarUrl;
// // // // // // // // // // // // //   final String? bio;
// // // // // // // // // // // // //   final int followersCount;
// // // // // // // // // // // // //   final int followingCount;
// // // // // // // // // // // // //   final int friendsCount;
// // // // // // // // // // // // //   final FriendshipStatus? friendshipStatus;
// // // // // // // // // // // // //   final bool isFollowing;
// // // // // // // // // // // // //   final bool isFollowedBy;
// // // // // // // // // // // // //   final bool isBlocked;
// // // // // // // // // // // // //   final bool isBlockedBy;
// // // // // // // // // // // // //   final bool isVerified;

// // // // // // // // // // // // //   bool get canInteract => !isBlocked && !isBlockedBy;
// // // // // // // // // // // // // }

// // // // // // // // // // // // // // ── Repository ────────────────────────────────────────────────────────────────

// // // // // // // // // // // // // class FriendsRepository extends BaseRepository {
// // // // // // // // // // // // //   FriendsRepository._();
// // // // // // // // // // // // //   static final FriendsRepository _instance = FriendsRepository._();
// // // // // // // // // // // // //   static FriendsRepository get instance => _instance;

// // // // // // // // // // // // //   final _supabase = Supabase.instance.client;

// // // // // // // // // // // // //   // ── Friends ───────────────────────────────────────────────────────────────

// // // // // // // // // // // // //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// // // // // // // // // // // // //     operationName: 'getFriends',
// // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // // //           .select(
// // // // // // // // // // // // //             'id,status,requester_id,addressee_id,'
// // // // // // // // // // // // //             'requester:profiles!requester_id(id,display_name,username,avatar_url),'
// // // // // // // // // // // // //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url)',
// // // // // // // // // // // // //           )
// // // // // // // // // // // // //           .or('requester_id.eq.$userId,addressee_id.eq.$userId')
// // // // // // // // // // // // //           .eq('status', 'accepted');
// // // // // // // // // // // // //       return rows.map((r) => _toFriendEntity(r, userId)).toList();
// // // // // // // // // // // // //     },
// // // // // // // // // // // // //   );

// // // // // // // // // // // // //   Future<List<FriendEntity>> getPendingRequests(String userId) => guardedCall(
// // // // // // // // // // // // //     operationName: 'getPendingRequests',
// // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // // // // // // // //           .eq('addressee_id', userId)
// // // // // // // // // // // // //           .eq('status', 'pending');
// // // // // // // // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // // // // // // // //       // Fetch requester profiles separately to avoid join ambiguity
// // // // // // // // // // // // //       final requesterIds = rows
// // // // // // // // // // // // //           .map((r) => r['requester_id'] as String)
// // // // // // // // // // // // //           .toList();
// // // // // // // // // // // // //       final profiles = await _supabase
// // // // // // // // // // // // //           .from('profiles')
// // // // // // // // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // // // // // // // //           .inFilter('id', requesterIds);
// // // // // // // // // // // // //       final profileMap = {
// // // // // // // // // // // // //         for (final p in profiles as List)
// // // // // // // // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // // // // // // // //       };
// // // // // // // // // // // // //       return rows.map((r) {
// // // // // // // // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // // // // // // // //         row['requester'] = profileMap[row['requester_id']] ?? {};
// // // // // // // // // // // // //         return _toFriendEntity(row, userId);
// // // // // // // // // // // // //       }).toList();
// // // // // // // // // // // // //     },
// // // // // // // // // // // // //   );

// // // // // // // // // // // // //   Future<List<FriendEntity>> getSentRequests(String userId) => guardedCall(
// // // // // // // // // // // // //     operationName: 'getSentRequests',
// // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // // // // // // // //           .eq('requester_id', userId)
// // // // // // // // // // // // //           .eq('status', 'pending');
// // // // // // // // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // // // // // // // //       // Fetch addressee profiles separately
// // // // // // // // // // // // //       final addresseeIds = rows
// // // // // // // // // // // // //           .map((r) => r['addressee_id'] as String)
// // // // // // // // // // // // //           .toList();
// // // // // // // // // // // // //       final profiles = await _supabase
// // // // // // // // // // // // //           .from('profiles')
// // // // // // // // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // // // // // // // //           .inFilter('id', addresseeIds);
// // // // // // // // // // // // //       final profileMap = {
// // // // // // // // // // // // //         for (final p in profiles as List)
// // // // // // // // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // // // // // // // //       };
// // // // // // // // // // // // //       return rows.map((r) {
// // // // // // // // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // // // // // // // //         row['addressee'] = profileMap[row['addressee_id']] ?? {};
// // // // // // // // // // // // //         return _toFriendEntity(row, userId);
// // // // // // // // // // // // //       }).toList();
// // // // // // // // // // // // //     },
// // // // // // // // // // // // //   );

// // // // // // // // // // // // //   Future<void> sendFriendRequest({
// // // // // // // // // // // // //     required String requesterId,
// // // // // // // // // // // // //     required String addresseeId,
// // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // //     operationName: 'sendFriendRequest',
// // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // //       // Check not blocked
// // // // // // // // // // // // //       await _checkNotBlocked(requesterId, addresseeId);
// // // // // // // // // // // // //       await _supabase.from('friendships').insert({
// // // // // // // // // // // // //         'requester_id': requesterId,
// // // // // // // // // // // // //         'addressee_id': addresseeId,
// // // // // // // // // // // // //         'status': 'pending',
// // // // // // // // // // // // //       });
// // // // // // // // // // // // //     },
// // // // // // // // // // // // //   );

// // // // // // // // // // // // //   Future<void> respondToRequest({
// // // // // // // // // // // // //     required String requesterId,
// // // // // // // // // // // // //     required String addresseeId,
// // // // // // // // // // // // //     required bool accept,
// // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // //     operationName: 'respondToRequest',
// // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // //       await _supabase
// // // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // // //           .update({'status': accept ? 'accepted' : 'rejected'})
// // // // // // // // // // // // //           .eq('requester_id', requesterId)
// // // // // // // // // // // // //           .eq('addressee_id', addresseeId);
// // // // // // // // // // // // //     },
// // // // // // // // // // // // //   );

// // // // // // // // // // // // //   Future<void> removeFriend({
// // // // // // // // // // // // //     required String userId,
// // // // // // // // // // // // //     required String friendId,
// // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // //     operationName: 'removeFriend',
// // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // //       await _supabase
// // // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // // //           .delete()
// // // // // // // // // // // // //           .or(
// // // // // // // // // // // // //             'and(requester_id.eq.$userId,addressee_id.eq.$friendId),'
// // // // // // // // // // // // //             'and(requester_id.eq.$friendId,addressee_id.eq.$userId)',
// // // // // // // // // // // // //           );
// // // // // // // // // // // // //     },
// // // // // // // // // // // // //   );

// // // // // // // // // // // // //   Future<void> cancelRequest({
// // // // // // // // // // // // //     required String requesterId,
// // // // // // // // // // // // //     required String addresseeId,
// // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // //     operationName: 'cancelRequest',
// // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // //       await _supabase
// // // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // // //           .delete()
// // // // // // // // // // // // //           .eq('requester_id', requesterId)
// // // // // // // // // // // // //           .eq('addressee_id', addresseeId)
// // // // // // // // // // // // //           .eq('status', 'pending');
// // // // // // // // // // // // //     },
// // // // // // // // // // // // //   );

// // // // // // // // // // // // //   // ── Follow system ─────────────────────────────────────────────────────────

// // // // // // // // // // // // //   Future<void> followUser(String followerId, String followingId) => guardedCall(
// // // // // // // // // // // // //     operationName: 'followUser',
// // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // //       await _checkNotBlocked(followerId, followingId);
// // // // // // // // // // // // //       await _supabase.from('follows').upsert({
// // // // // // // // // // // // //         'follower_id': followerId,
// // // // // // // // // // // // //         'following_id': followingId,
// // // // // // // // // // // // //       }, onConflict: 'follower_id,following_id');
// // // // // // // // // // // // //     },
// // // // // // // // // // // // //   );

// // // // // // // // // // // // //   Future<void> unfollowUser(String followerId, String followingId) =>
// // // // // // // // // // // // //       guardedCall(
// // // // // // // // // // // // //         operationName: 'unfollowUser',
// // // // // // // // // // // // //         operation: () async {
// // // // // // // // // // // // //           await _supabase
// // // // // // // // // // // // //               .from('follows')
// // // // // // // // // // // // //               .delete()
// // // // // // // // // // // // //               .eq('follower_id', followerId)
// // // // // // // // // // // // //               .eq('following_id', followingId);
// // // // // // // // // // // // //         },
// // // // // // // // // // // // //       );

// // // // // // // // // // // // //   Future<List<FollowEntity>> getFollowers(
// // // // // // // // // // // // //     String userId, {
// // // // // // // // // // // // //     int limit = 50,
// // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // //     operationName: 'getFollowers',
// // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // // //           .from('follows')
// // // // // // // // // // // // //           .select(
// // // // // // // // // // // // //             'follower_id,created_at,'
// // // // // // // // // // // // //             'profiles!follower_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // // // // // // // //           )
// // // // // // // // // // // // //           .eq('following_id', userId)
// // // // // // // // // // // // //           .order('created_at', ascending: false)
// // // // // // // // // // // // //           .limit(limit);
// // // // // // // // // // // // //       return rows.map(_toFollowEntity).toList();
// // // // // // // // // // // // //     },
// // // // // // // // // // // // //   );

// // // // // // // // // // // // //   Future<List<FollowEntity>> getFollowing(
// // // // // // // // // // // // //     String userId, {
// // // // // // // // // // // // //     int limit = 50,
// // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // //     operationName: 'getFollowing',
// // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // // //           .from('follows')
// // // // // // // // // // // // //           .select(
// // // // // // // // // // // // //             'following_id,created_at,'
// // // // // // // // // // // // //             'profiles!following_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // // // // // // // //           )
// // // // // // // // // // // // //           .eq('follower_id', userId)
// // // // // // // // // // // // //           .order('created_at', ascending: false)
// // // // // // // // // // // // //           .limit(limit);
// // // // // // // // // // // // //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// // // // // // // // // // // // //     },
// // // // // // // // // // // // //   );

// // // // // // // // // // // // //   // ── Block system ──────────────────────────────────────────────────────────

// // // // // // // // // // // // //   Future<void> blockUser({
// // // // // // // // // // // // //     required String blockerId,
// // // // // // // // // // // // //     required String blockedId,
// // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // //     operationName: 'blockUser',
// // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // //       await _supabase.from('blocked_users').upsert({
// // // // // // // // // // // // //         'blocker_id': blockerId,
// // // // // // // // // // // // //         'blocked_id': blockedId,
// // // // // // // // // // // // //       }, onConflict: 'blocker_id,blocked_id');
// // // // // // // // // // // // //       // Also remove any existing friendship
// // // // // // // // // // // // //       await removeFriend(
// // // // // // // // // // // // //         userId: blockerId,
// // // // // // // // // // // // //         friendId: blockedId,
// // // // // // // // // // // // //       ).catchError((_) {});
// // // // // // // // // // // // //       // Remove follow in both directions
// // // // // // // // // // // // //       await unfollowUser(blockerId, blockedId).catchError((_) {});
// // // // // // // // // // // // //       await unfollowUser(blockedId, blockerId).catchError((_) {});
// // // // // // // // // // // // //     },
// // // // // // // // // // // // //   );

// // // // // // // // // // // // //   Future<void> unblockUser({
// // // // // // // // // // // // //     required String blockerId,
// // // // // // // // // // // // //     required String blockedId,
// // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // //     operationName: 'unblockUser',
// // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // //       await _supabase
// // // // // // // // // // // // //           .from('blocked_users')
// // // // // // // // // // // // //           .delete()
// // // // // // // // // // // // //           .eq('blocker_id', blockerId)
// // // // // // // // // // // // //           .eq('blocked_id', blockedId);
// // // // // // // // // // // // //     },
// // // // // // // // // // // // //   );

// // // // // // // // // // // // //   Future<List<FriendEntity>> getBlockedUsers(String userId) => guardedCall(
// // // // // // // // // // // // //     operationName: 'getBlockedUsers',
// // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // // //           .from('blocked_users')
// // // // // // // // // // // // //           .select(
// // // // // // // // // // // // //             'blocked_id,created_at,'
// // // // // // // // // // // // //             'profiles!blocked_id(id,display_name,username,avatar_url)',
// // // // // // // // // // // // //           )
// // // // // // // // // // // // //           .eq('blocker_id', userId)
// // // // // // // // // // // // //           .order('created_at', ascending: false);
// // // // // // // // // // // // //       return rows.map((r) {
// // // // // // // // // // // // //         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
// // // // // // // // // // // // //         return FriendEntity(
// // // // // // // // // // // // //           userId: profile['id'] as String? ?? '',
// // // // // // // // // // // // //           displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // // // // // //           username: profile['username'] as String?,
// // // // // // // // // // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // // // // //           status: FriendshipStatus.blocked,
// // // // // // // // // // // // //           isRequester: true,
// // // // // // // // // // // // //         );
// // // // // // // // // // // // //       }).toList();
// // // // // // // // // // // // //     },
// // // // // // // // // // // // //   );

// // // // // // // // // // // // //   // ── Social profile ────────────────────────────────────────────────────────

// // // // // // // // // // // // //   Future<SocialProfile> getSocialProfile({
// // // // // // // // // // // // //     required String targetUserId,
// // // // // // // // // // // // //     required String viewerUserId,
// // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // //     operationName: 'getSocialProfile',
// // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // //       final profile = await _supabase
// // // // // // // // // // // // //           .from('profiles_public')
// // // // // // // // // // // // //           .select()
// // // // // // // // // // // // //           .eq('id', targetUserId)
// // // // // // // // // // // // //           .maybeSingle();

// // // // // // // // // // // // //       if (profile == null) {
// // // // // // // // // // // // //         // Fallback: try profiles table directly
// // // // // // // // // // // // //         final fallback = await _supabase
// // // // // // // // // // // // //             .from('profiles')
// // // // // // // // // // // // //             .select('id, display_name, username, avatar_url, bio')
// // // // // // // // // // // // //             .eq('id', targetUserId)
// // // // // // // // // // // // //             .maybeSingle();
// // // // // // // // // // // // //         if (fallback == null) throw Exception('Profile not found');
// // // // // // // // // // // // //         // Build minimal profile from profiles table
// // // // // // // // // // // // //         return SocialProfile(
// // // // // // // // // // // // //           userId: fallback['id'] as String,
// // // // // // // // // // // // //           displayName: fallback['display_name'] as String? ?? 'Player',
// // // // // // // // // // // // //           username: fallback['username'] as String?,
// // // // // // // // // // // // //           avatarUrl: fallback['avatar_url'] as String?,
// // // // // // // // // // // // //           bio: fallback['bio'] as String?,
// // // // // // // // // // // // //           followersCount: 0,
// // // // // // // // // // // // //           followingCount: 0,
// // // // // // // // // // // // //           friendsCount: 0,
// // // // // // // // // // // // //         );
// // // // // // // // // // // // //       }

// // // // // // // // // // // // //       final [
// // // // // // // // // // // // //         blockedByMe,
// // // // // // // // // // // // //         blockedByThem,
// // // // // // // // // // // // //         friendshipRow,
// // // // // // // // // // // // //         followingRow,
// // // // // // // // // // // // //         followedByRow,
// // // // // // // // // // // // //       ] = await Future.wait([
// // // // // // // // // // // // //         _supabase
// // // // // // // // // // // // //             .from('blocked_users')
// // // // // // // // // // // // //             .select('blocker_id')
// // // // // // // // // // // // //             .eq('blocker_id', viewerUserId)
// // // // // // // // // // // // //             .eq('blocked_id', targetUserId)
// // // // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // // // //         _supabase
// // // // // // // // // // // // //             .from('blocked_users')
// // // // // // // // // // // // //             .select('blocker_id')
// // // // // // // // // // // // //             .eq('blocker_id', targetUserId)
// // // // // // // // // // // // //             .eq('blocked_id', viewerUserId)
// // // // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // // // //         _supabase
// // // // // // // // // // // // //             .from('friendships')
// // // // // // // // // // // // //             .select('status')
// // // // // // // // // // // // //             .or(
// // // // // // // // // // // // //               'and(requester_id.eq.$viewerUserId,addressee_id.eq.$targetUserId),'
// // // // // // // // // // // // //               'and(requester_id.eq.$targetUserId,addressee_id.eq.$viewerUserId)',
// // // // // // // // // // // // //             )
// // // // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // // // //         _supabase
// // // // // // // // // // // // //             .from('follows')
// // // // // // // // // // // // //             .select('id')
// // // // // // // // // // // // //             .eq('follower_id', viewerUserId)
// // // // // // // // // // // // //             .eq('following_id', targetUserId)
// // // // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // // // //         _supabase
// // // // // // // // // // // // //             .from('follows')
// // // // // // // // // // // // //             .select('id')
// // // // // // // // // // // // //             .eq('follower_id', targetUserId)
// // // // // // // // // // // // //             .eq('following_id', viewerUserId)
// // // // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // // // //       ]);

// // // // // // // // // // // // //       FriendshipStatus? friendStatus;
// // // // // // // // // // // // //       if (friendshipRow != null) {
// // // // // // // // // // // // //         friendStatus = FriendshipStatus.values.firstWhere(
// // // // // // // // // // // // //           (s) => s.name == (friendshipRow as Map)['status'],
// // // // // // // // // // // // //           orElse: () => FriendshipStatus.pending,
// // // // // // // // // // // // //         );
// // // // // // // // // // // // //       }

// // // // // // // // // // // // //       return SocialProfile(
// // // // // // // // // // // // //         userId: profile['id'] as String,
// // // // // // // // // // // // //         displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // // // // // //         username: profile['username'] as String?,
// // // // // // // // // // // // //         avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // // // // //         bio: profile['bio'] as String?,
// // // // // // // // // // // // //         followersCount: profile['followers_count'] as int? ?? 0,
// // // // // // // // // // // // //         followingCount: profile['following_count'] as int? ?? 0,
// // // // // // // // // // // // //         friendsCount: profile['friends_count'] as int? ?? 0,
// // // // // // // // // // // // //         friendshipStatus: friendStatus,
// // // // // // // // // // // // //         isFollowing: followingRow != null,
// // // // // // // // // // // // //         isFollowedBy: followedByRow != null,
// // // // // // // // // // // // //         isBlocked: blockedByMe != null,
// // // // // // // // // // // // //         isBlockedBy: blockedByThem != null,
// // // // // // // // // // // // //         isVerified: profile['verification_status'] == 'verified',
// // // // // // // // // // // // //       );
// // // // // // // // // // // // //     },
// // // // // // // // // // // // //   );

// // // // // // // // // // // // //   // ── Search ────────────────────────────────────────────────────────────────

// // // // // // // // // // // // //   Future<List<UserEntity>> searchUsers(
// // // // // // // // // // // // //     String query, {
// // // // // // // // // // // // //     required String excludeUserId,
// // // // // // // // // // // // //     int limit = 20,
// // // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // // //     operationName: 'searchUsers',
// // // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // // //           .from('profiles_public')
// // // // // // // // // // // // //           .select('id,username,display_name,avatar_url')
// // // // // // // // // // // // //           .or('username.ilike.%$query%,display_name.ilike.%$query%')
// // // // // // // // // // // // //           .neq('id', excludeUserId)
// // // // // // // // // // // // //           .limit(limit);
// // // // // // // // // // // // //       return rows
// // // // // // // // // // // // //           .map(
// // // // // // // // // // // // //             (r) => UserEntity(
// // // // // // // // // // // // //               id: r['id'] as String,
// // // // // // // // // // // // //               email: '',
// // // // // // // // // // // // //               username: r['username'] as String?,
// // // // // // // // // // // // //               displayName: r['display_name'] as String?,
// // // // // // // // // // // // //               avatarUrl: r['avatar_url'] as String?,
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //           )
// // // // // // // // // // // // //           .toList();
// // // // // // // // // // // // //     },
// // // // // // // // // // // // //   );

// // // // // // // // // // // // //   // ── Private helpers ───────────────────────────────────────────────────────

// // // // // // // // // // // // //   Future<void> _checkNotBlocked(String a, String b) async {
// // // // // // // // // // // // //     final block = await _supabase
// // // // // // // // // // // // //         .from('blocked_users')
// // // // // // // // // // // // //         .select('blocker_id')
// // // // // // // // // // // // //         .or(
// // // // // // // // // // // // //           'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // // // // // // // // // // // //           'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // // // // // // // // // // // //         )
// // // // // // // // // // // // //         .maybeSingle();
// // // // // // // // // // // // //     if (block != null) {
// // // // // // // // // // // // //       throw const ForbiddenFailure(message: 'Cannot interact with this user.');
// // // // // // // // // // // // //     }
// // // // // // // // // // // // //   }

// // // // // // // // // // // // //   FriendEntity _toFriendEntity(Map<String, dynamic> row, String currentUserId) {
// // // // // // // // // // // // //     final requesterId = row['requester_id'] as String? ?? '';
// // // // // // // // // // // // //     final isRequester = requesterId == currentUserId;
// // // // // // // // // // // // //     final rawOther = isRequester ? row['addressee'] : row['requester'];
// // // // // // // // // // // // //     final other = (rawOther is Map)
// // // // // // // // // // // // //         ? Map<String, dynamic>.from(rawOther)
// // // // // // // // // // // // //         : <String, dynamic>{};
// // // // // // // // // // // // //     return FriendEntity(
// // // // // // // // // // // // //       friendshipId: row['id'] as String?,
// // // // // // // // // // // // //       userId: other['id'] as String? ?? '',
// // // // // // // // // // // // //       displayName: other['display_name'] as String? ?? 'Player',
// // // // // // // // // // // // //       username: other['username'] as String?,
// // // // // // // // // // // // //       avatarUrl: other['avatar_url'] as String?,
// // // // // // // // // // // // //       status: FriendshipStatus.values.firstWhere(
// // // // // // // // // // // // //         (s) => s.name == (row['status'] as String? ?? ''),
// // // // // // // // // // // // //         orElse: () => FriendshipStatus.pending,
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //       isRequester: isRequester,
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }

// // // // // // // // // // // // //   FollowEntity _toFollowEntity(
// // // // // // // // // // // // //     Map<String, dynamic> row, {
// // // // // // // // // // // // //     bool followingMode = false,
// // // // // // // // // // // // //   }) {
// // // // // // // // // // // // //     final profile =
// // // // // // // // // // // // //         row[followingMode ? 'profiles!following_id' : 'profiles!follower_id']
// // // // // // // // // // // // //             as Map<String, dynamic>? ??
// // // // // // // // // // // // //         {};
// // // // // // // // // // // // //     return FollowEntity(
// // // // // // // // // // // // //       userId: profile['id'] as String? ?? '',
// // // // // // // // // // // // //       displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // // // // // //       username: profile['username'] as String?,
// // // // // // // // // // // // //       avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // // // // //       followedAt: DateTime.parse(row['created_at'] as String),
// // // // // // // // // // // // //       isVerified: profile['verification_status'] == 'verified',
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // // // // // // import '../../../core/data/base_repository.dart';
// // // // // // // // // // // // import '../../../core/errors/failures.dart';
// // // // // // // // // // // // import '../../../features/auth/domain/entities/user_entity.dart';

// // // // // // // // // // // // // ── Domain types ──────────────────────────────────────────────────────────────

// // // // // // // // // // // // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // // // // // // // // // // // class FriendEntity {
// // // // // // // // // // // //   const FriendEntity({
// // // // // // // // // // // //     required this.userId,
// // // // // // // // // // // //     required this.displayName,
// // // // // // // // // // // //     this.username,
// // // // // // // // // // // //     this.avatarUrl,
// // // // // // // // // // // //     required this.status,
// // // // // // // // // // // //     required this.isRequester,
// // // // // // // // // // // //     this.mutualFriendsCount = 0,
// // // // // // // // // // // //     this.friendshipId,
// // // // // // // // // // // //   });

// // // // // // // // // // // //   final String userId;
// // // // // // // // // // // //   final String displayName;
// // // // // // // // // // // //   final String? username;
// // // // // // // // // // // //   final String? avatarUrl;
// // // // // // // // // // // //   final FriendshipStatus status;
// // // // // // // // // // // //   final bool isRequester;
// // // // // // // // // // // //   final int mutualFriendsCount;
// // // // // // // // // // // //   final String? friendshipId;

// // // // // // // // // // // //   bool get isAccepted => status == FriendshipStatus.accepted;
// // // // // // // // // // // //   bool get isPending => status == FriendshipStatus.pending;
// // // // // // // // // // // // }

// // // // // // // // // // // // class FollowEntity {
// // // // // // // // // // // //   const FollowEntity({
// // // // // // // // // // // //     required this.userId,
// // // // // // // // // // // //     required this.displayName,
// // // // // // // // // // // //     this.username,
// // // // // // // // // // // //     this.avatarUrl,
// // // // // // // // // // // //     required this.followedAt,
// // // // // // // // // // // //     this.isVerified = false,
// // // // // // // // // // // //   });

// // // // // // // // // // // //   final String userId;
// // // // // // // // // // // //   final String displayName;
// // // // // // // // // // // //   final String? username;
// // // // // // // // // // // //   final String? avatarUrl;
// // // // // // // // // // // //   final DateTime followedAt;
// // // // // // // // // // // //   final bool isVerified;
// // // // // // // // // // // // }

// // // // // // // // // // // // class SocialProfile {
// // // // // // // // // // // //   const SocialProfile({
// // // // // // // // // // // //     required this.userId,
// // // // // // // // // // // //     required this.displayName,
// // // // // // // // // // // //     this.username,
// // // // // // // // // // // //     this.avatarUrl,
// // // // // // // // // // // //     this.bio,
// // // // // // // // // // // //     required this.followersCount,
// // // // // // // // // // // //     required this.followingCount,
// // // // // // // // // // // //     required this.friendsCount,
// // // // // // // // // // // //     this.friendshipStatus,
// // // // // // // // // // // //     this.isFollowing = false,
// // // // // // // // // // // //     this.isFollowedBy = false,
// // // // // // // // // // // //     this.isBlocked = false,
// // // // // // // // // // // //     this.isBlockedBy = false,
// // // // // // // // // // // //     this.isVerified = false,
// // // // // // // // // // // //   });

// // // // // // // // // // // //   final String userId;
// // // // // // // // // // // //   final String displayName;
// // // // // // // // // // // //   final String? username;
// // // // // // // // // // // //   final String? avatarUrl;
// // // // // // // // // // // //   final String? bio;
// // // // // // // // // // // //   final int followersCount;
// // // // // // // // // // // //   final int followingCount;
// // // // // // // // // // // //   final int friendsCount;
// // // // // // // // // // // //   final FriendshipStatus? friendshipStatus;
// // // // // // // // // // // //   final bool isFollowing;
// // // // // // // // // // // //   final bool isFollowedBy;
// // // // // // // // // // // //   final bool isBlocked;
// // // // // // // // // // // //   final bool isBlockedBy;
// // // // // // // // // // // //   final bool isVerified;

// // // // // // // // // // // //   bool get canInteract => !isBlocked && !isBlockedBy;
// // // // // // // // // // // // }

// // // // // // // // // // // // // ── Repository ────────────────────────────────────────────────────────────────

// // // // // // // // // // // // class FriendsRepository extends BaseRepository {
// // // // // // // // // // // //   FriendsRepository._();
// // // // // // // // // // // //   static final FriendsRepository _instance = FriendsRepository._();
// // // // // // // // // // // //   static FriendsRepository get instance => _instance;

// // // // // // // // // // // //   final _supabase = Supabase.instance.client;

// // // // // // // // // // // //   // ── Friends ───────────────────────────────────────────────────────────────

// // // // // // // // // // // //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// // // // // // // // // // // //     operationName: 'getFriends',
// // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // //           .select(
// // // // // // // // // // // //             'id,status,requester_id,addressee_id,'
// // // // // // // // // // // //             'requester:profiles!requester_id(id,display_name,username,avatar_url),'
// // // // // // // // // // // //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url)',
// // // // // // // // // // // //           )
// // // // // // // // // // // //           .or('requester_id.eq.$userId,addressee_id.eq.$userId')
// // // // // // // // // // // //           .eq('status', 'accepted');
// // // // // // // // // // // //       return rows.map((r) => _toFriendEntity(r, userId)).toList();
// // // // // // // // // // // //     },
// // // // // // // // // // // //   );

// // // // // // // // // // // //   Future<List<FriendEntity>> getPendingRequests(String userId) => guardedCall(
// // // // // // // // // // // //     operationName: 'getPendingRequests',
// // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // // // // // // //           .eq('addressee_id', userId)
// // // // // // // // // // // //           .eq('status', 'pending');
// // // // // // // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // // // // // // //       // Fetch requester profiles separately to avoid join ambiguity
// // // // // // // // // // // //       final requesterIds = rows
// // // // // // // // // // // //           .map((r) => r['requester_id'] as String)
// // // // // // // // // // // //           .toList();
// // // // // // // // // // // //       final profiles = await _supabase
// // // // // // // // // // // //           .from('profiles')
// // // // // // // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // // // // // // //           .inFilter('id', requesterIds);
// // // // // // // // // // // //       final profileMap = {
// // // // // // // // // // // //         for (final p in profiles as List)
// // // // // // // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // // // // // // //       };
// // // // // // // // // // // //       return rows.map((r) {
// // // // // // // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // // // // // // //         row['requester'] = profileMap[row['requester_id']] ?? {};
// // // // // // // // // // // //         return _toFriendEntity(row, userId);
// // // // // // // // // // // //       }).toList();
// // // // // // // // // // // //     },
// // // // // // // // // // // //   );

// // // // // // // // // // // //   Future<List<FriendEntity>> getSentRequests(String userId) => guardedCall(
// // // // // // // // // // // //     operationName: 'getSentRequests',
// // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // // // // // // //           .eq('requester_id', userId)
// // // // // // // // // // // //           .eq('status', 'pending');
// // // // // // // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // // // // // // //       // Fetch addressee profiles separately
// // // // // // // // // // // //       final addresseeIds = rows
// // // // // // // // // // // //           .map((r) => r['addressee_id'] as String)
// // // // // // // // // // // //           .toList();
// // // // // // // // // // // //       final profiles = await _supabase
// // // // // // // // // // // //           .from('profiles')
// // // // // // // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // // // // // // //           .inFilter('id', addresseeIds);
// // // // // // // // // // // //       final profileMap = {
// // // // // // // // // // // //         for (final p in profiles as List)
// // // // // // // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // // // // // // //       };
// // // // // // // // // // // //       return rows.map((r) {
// // // // // // // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // // // // // // //         row['addressee'] = profileMap[row['addressee_id']] ?? {};
// // // // // // // // // // // //         return _toFriendEntity(row, userId);
// // // // // // // // // // // //       }).toList();
// // // // // // // // // // // //     },
// // // // // // // // // // // //   );

// // // // // // // // // // // //   Future<void> sendFriendRequest({
// // // // // // // // // // // //     required String requesterId,
// // // // // // // // // // // //     required String addresseeId,
// // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // //     operationName: 'sendFriendRequest',
// // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // //       // Check not blocked
// // // // // // // // // // // //       await _checkNotBlocked(requesterId, addresseeId);
// // // // // // // // // // // //       await _supabase.from('friendships').insert({
// // // // // // // // // // // //         'requester_id': requesterId,
// // // // // // // // // // // //         'addressee_id': addresseeId,
// // // // // // // // // // // //         'status': 'pending',
// // // // // // // // // // // //       });
// // // // // // // // // // // //     },
// // // // // // // // // // // //   );

// // // // // // // // // // // //   Future<void> respondToRequest({
// // // // // // // // // // // //     required String requesterId,
// // // // // // // // // // // //     required String addresseeId,
// // // // // // // // // // // //     required bool accept,
// // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // //     operationName: 'respondToRequest',
// // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // //       await _supabase
// // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // //           .update({'status': accept ? 'accepted' : 'rejected'})
// // // // // // // // // // // //           .eq('requester_id', requesterId)
// // // // // // // // // // // //           .eq('addressee_id', addresseeId);
// // // // // // // // // // // //     },
// // // // // // // // // // // //   );

// // // // // // // // // // // //   Future<void> removeFriend({
// // // // // // // // // // // //     required String userId,
// // // // // // // // // // // //     required String friendId,
// // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // //     operationName: 'removeFriend',
// // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // //       await _supabase
// // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // //           .delete()
// // // // // // // // // // // //           .or(
// // // // // // // // // // // //             'and(requester_id.eq.$userId,addressee_id.eq.$friendId),'
// // // // // // // // // // // //             'and(requester_id.eq.$friendId,addressee_id.eq.$userId)',
// // // // // // // // // // // //           );
// // // // // // // // // // // //     },
// // // // // // // // // // // //   );

// // // // // // // // // // // //   Future<void> cancelRequest({
// // // // // // // // // // // //     required String requesterId,
// // // // // // // // // // // //     required String addresseeId,
// // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // //     operationName: 'cancelRequest',
// // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // //       await _supabase
// // // // // // // // // // // //           .from('friendships')
// // // // // // // // // // // //           .delete()
// // // // // // // // // // // //           .eq('requester_id', requesterId)
// // // // // // // // // // // //           .eq('addressee_id', addresseeId)
// // // // // // // // // // // //           .eq('status', 'pending');
// // // // // // // // // // // //     },
// // // // // // // // // // // //   );

// // // // // // // // // // // //   // ── Follow system ─────────────────────────────────────────────────────────

// // // // // // // // // // // //   Future<void> followUser(String followerId, String followingId) => guardedCall(
// // // // // // // // // // // //     operationName: 'followUser',
// // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // //       await _checkNotBlocked(followerId, followingId);
// // // // // // // // // // // //       await _supabase.from('follows').upsert({
// // // // // // // // // // // //         'follower_id': followerId,
// // // // // // // // // // // //         'following_id': followingId,
// // // // // // // // // // // //       }, onConflict: 'follower_id,following_id');
// // // // // // // // // // // //     },
// // // // // // // // // // // //   );

// // // // // // // // // // // //   Future<void> unfollowUser(String followerId, String followingId) =>
// // // // // // // // // // // //       guardedCall(
// // // // // // // // // // // //         operationName: 'unfollowUser',
// // // // // // // // // // // //         operation: () async {
// // // // // // // // // // // //           await _supabase
// // // // // // // // // // // //               .from('follows')
// // // // // // // // // // // //               .delete()
// // // // // // // // // // // //               .eq('follower_id', followerId)
// // // // // // // // // // // //               .eq('following_id', followingId);
// // // // // // // // // // // //         },
// // // // // // // // // // // //       );

// // // // // // // // // // // //   Future<List<FollowEntity>> getFollowers(
// // // // // // // // // // // //     String userId, {
// // // // // // // // // // // //     int limit = 50,
// // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // //     operationName: 'getFollowers',
// // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // //           .from('follows')
// // // // // // // // // // // //           .select(
// // // // // // // // // // // //             'follower_id,created_at,'
// // // // // // // // // // // //             'profiles!follower_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // // // // // // //           )
// // // // // // // // // // // //           .eq('following_id', userId)
// // // // // // // // // // // //           .order('created_at', ascending: false)
// // // // // // // // // // // //           .limit(limit);
// // // // // // // // // // // //       return rows.map(_toFollowEntity).toList();
// // // // // // // // // // // //     },
// // // // // // // // // // // //   );

// // // // // // // // // // // //   Future<List<FollowEntity>> getFollowing(
// // // // // // // // // // // //     String userId, {
// // // // // // // // // // // //     int limit = 50,
// // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // //     operationName: 'getFollowing',
// // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // //           .from('follows')
// // // // // // // // // // // //           .select(
// // // // // // // // // // // //             'following_id,created_at,'
// // // // // // // // // // // //             'profiles!following_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // // // // // // //           )
// // // // // // // // // // // //           .eq('follower_id', userId)
// // // // // // // // // // // //           .order('created_at', ascending: false)
// // // // // // // // // // // //           .limit(limit);
// // // // // // // // // // // //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// // // // // // // // // // // //     },
// // // // // // // // // // // //   );

// // // // // // // // // // // //   // ── Block system ──────────────────────────────────────────────────────────

// // // // // // // // // // // //   Future<void> blockUser({
// // // // // // // // // // // //     required String blockerId,
// // // // // // // // // // // //     required String blockedId,
// // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // //     operationName: 'blockUser',
// // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // //       await _supabase.from('blocked_users').upsert({
// // // // // // // // // // // //         'blocker_id': blockerId,
// // // // // // // // // // // //         'blocked_id': blockedId,
// // // // // // // // // // // //       }, onConflict: 'blocker_id,blocked_id');
// // // // // // // // // // // //       // Also remove any existing friendship
// // // // // // // // // // // //       await removeFriend(
// // // // // // // // // // // //         userId: blockerId,
// // // // // // // // // // // //         friendId: blockedId,
// // // // // // // // // // // //       ).catchError((_) {});
// // // // // // // // // // // //       // Remove follow in both directions
// // // // // // // // // // // //       await unfollowUser(blockerId, blockedId).catchError((_) {});
// // // // // // // // // // // //       await unfollowUser(blockedId, blockerId).catchError((_) {});
// // // // // // // // // // // //     },
// // // // // // // // // // // //   );

// // // // // // // // // // // //   Future<void> unblockUser({
// // // // // // // // // // // //     required String blockerId,
// // // // // // // // // // // //     required String blockedId,
// // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // //     operationName: 'unblockUser',
// // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // //       await _supabase
// // // // // // // // // // // //           .from('blocked_users')
// // // // // // // // // // // //           .delete()
// // // // // // // // // // // //           .eq('blocker_id', blockerId)
// // // // // // // // // // // //           .eq('blocked_id', blockedId);
// // // // // // // // // // // //     },
// // // // // // // // // // // //   );

// // // // // // // // // // // //   Future<List<FriendEntity>> getBlockedUsers(String userId) => guardedCall(
// // // // // // // // // // // //     operationName: 'getBlockedUsers',
// // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // //           .from('blocked_users')
// // // // // // // // // // // //           .select(
// // // // // // // // // // // //             'blocked_id,created_at,'
// // // // // // // // // // // //             'profiles!blocked_id(id,display_name,username,avatar_url)',
// // // // // // // // // // // //           )
// // // // // // // // // // // //           .eq('blocker_id', userId)
// // // // // // // // // // // //           .order('created_at', ascending: false);
// // // // // // // // // // // //       return rows.map((r) {
// // // // // // // // // // // //         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
// // // // // // // // // // // //         return FriendEntity(
// // // // // // // // // // // //           userId: profile['id'] as String? ?? '',
// // // // // // // // // // // //           displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // // // // //           username: profile['username'] as String?,
// // // // // // // // // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // // // //           status: FriendshipStatus.blocked,
// // // // // // // // // // // //           isRequester: true,
// // // // // // // // // // // //         );
// // // // // // // // // // // //       }).toList();
// // // // // // // // // // // //     },
// // // // // // // // // // // //   );

// // // // // // // // // // // //   // ── Social profile ────────────────────────────────────────────────────────

// // // // // // // // // // // //   Future<SocialProfile> getSocialProfile({
// // // // // // // // // // // //     required String targetUserId,
// // // // // // // // // // // //     required String viewerUserId,
// // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // //     operationName: 'getSocialProfile',
// // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // //       final profile = await _supabase
// // // // // // // // // // // //           .from('profiles_public')
// // // // // // // // // // // //           .select()
// // // // // // // // // // // //           .eq('id', targetUserId)
// // // // // // // // // // // //           .maybeSingle();

// // // // // // // // // // // //       if (profile == null) {
// // // // // // // // // // // //         // Fallback: try profiles table directly
// // // // // // // // // // // //         final fallback = await _supabase
// // // // // // // // // // // //             .from('profiles')
// // // // // // // // // // // //             .select('id, display_name, username, avatar_url, bio')
// // // // // // // // // // // //             .eq('id', targetUserId)
// // // // // // // // // // // //             .maybeSingle();
// // // // // // // // // // // //         if (fallback == null) throw Exception('Profile not found');
// // // // // // // // // // // //         // Build minimal profile from profiles table
// // // // // // // // // // // //         return SocialProfile(
// // // // // // // // // // // //           userId: fallback['id'] as String,
// // // // // // // // // // // //           displayName: fallback['display_name'] as String? ?? 'Player',
// // // // // // // // // // // //           username: fallback['username'] as String?,
// // // // // // // // // // // //           avatarUrl: fallback['avatar_url'] as String?,
// // // // // // // // // // // //           bio: fallback['bio'] as String?,
// // // // // // // // // // // //           followersCount: 0,
// // // // // // // // // // // //           followingCount: 0,
// // // // // // // // // // // //           friendsCount: 0,
// // // // // // // // // // // //         );
// // // // // // // // // // // //       }

// // // // // // // // // // // //       final [
// // // // // // // // // // // //         blockedByMe,
// // // // // // // // // // // //         blockedByThem,
// // // // // // // // // // // //         friendshipRow,
// // // // // // // // // // // //         followingRow,
// // // // // // // // // // // //         followedByRow,
// // // // // // // // // // // //       ] = await Future.wait([
// // // // // // // // // // // //         _supabase
// // // // // // // // // // // //             .from('blocked_users')
// // // // // // // // // // // //             .select('blocker_id')
// // // // // // // // // // // //             .eq('blocker_id', viewerUserId)
// // // // // // // // // // // //             .eq('blocked_id', targetUserId)
// // // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // // //         _supabase
// // // // // // // // // // // //             .from('blocked_users')
// // // // // // // // // // // //             .select('blocker_id')
// // // // // // // // // // // //             .eq('blocker_id', targetUserId)
// // // // // // // // // // // //             .eq('blocked_id', viewerUserId)
// // // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // // //         _supabase
// // // // // // // // // // // //             .from('friendships')
// // // // // // // // // // // //             .select('status')
// // // // // // // // // // // //             .or(
// // // // // // // // // // // //               'and(requester_id.eq.$viewerUserId,addressee_id.eq.$targetUserId),'
// // // // // // // // // // // //               'and(requester_id.eq.$targetUserId,addressee_id.eq.$viewerUserId)',
// // // // // // // // // // // //             )
// // // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // // //         _supabase
// // // // // // // // // // // //             .from('follows')
// // // // // // // // // // // //             .select('id')
// // // // // // // // // // // //             .eq('follower_id', viewerUserId)
// // // // // // // // // // // //             .eq('following_id', targetUserId)
// // // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // // //         _supabase
// // // // // // // // // // // //             .from('follows')
// // // // // // // // // // // //             .select('id')
// // // // // // // // // // // //             .eq('follower_id', targetUserId)
// // // // // // // // // // // //             .eq('following_id', viewerUserId)
// // // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // // //       ]);

// // // // // // // // // // // //       FriendshipStatus? friendStatus;
// // // // // // // // // // // //       if (friendshipRow != null) {
// // // // // // // // // // // //         friendStatus = FriendshipStatus.values.firstWhere(
// // // // // // // // // // // //           (s) => s.name == (friendshipRow as Map)['status'],
// // // // // // // // // // // //           orElse: () => FriendshipStatus.pending,
// // // // // // // // // // // //         );
// // // // // // // // // // // //       }

// // // // // // // // // // // //       return SocialProfile(
// // // // // // // // // // // //         userId: profile['id'] as String,
// // // // // // // // // // // //         displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // // // // //         username: profile['username'] as String?,
// // // // // // // // // // // //         avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // // // //         bio: profile['bio'] as String?,
// // // // // // // // // // // //         followersCount: profile['followers_count'] as int? ?? 0,
// // // // // // // // // // // //         followingCount: profile['following_count'] as int? ?? 0,
// // // // // // // // // // // //         friendsCount: profile['friends_count'] as int? ?? 0,
// // // // // // // // // // // //         friendshipStatus: friendStatus,
// // // // // // // // // // // //         isFollowing: followingRow != null,
// // // // // // // // // // // //         isFollowedBy: followedByRow != null,
// // // // // // // // // // // //         isBlocked: blockedByMe != null,
// // // // // // // // // // // //         isBlockedBy: blockedByThem != null,
// // // // // // // // // // // //         isVerified: profile['verification_status'] == 'verified',
// // // // // // // // // // // //       );
// // // // // // // // // // // //     },
// // // // // // // // // // // //   );

// // // // // // // // // // // //   // ── Search ────────────────────────────────────────────────────────────────

// // // // // // // // // // // //   Future<List<UserEntity>> searchUsers(
// // // // // // // // // // // //     String query, {
// // // // // // // // // // // //     required String excludeUserId,
// // // // // // // // // // // //     int limit = 20,
// // // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // // //     operationName: 'searchUsers',
// // // // // // // // // // // //     operation: () async {
// // // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // // //           .from('profiles_public')
// // // // // // // // // // // //           .select('id,username,display_name,avatar_url')
// // // // // // // // // // // //           .or('username.ilike.%$query%,display_name.ilike.%$query%')
// // // // // // // // // // // //           .neq('id', excludeUserId)
// // // // // // // // // // // //           .limit(limit);
// // // // // // // // // // // //       return rows
// // // // // // // // // // // //           .map(
// // // // // // // // // // // //             (r) => UserEntity(
// // // // // // // // // // // //               id: r['id'] as String,
// // // // // // // // // // // //               email: '',
// // // // // // // // // // // //               username: r['username'] as String?,
// // // // // // // // // // // //               displayName: r['display_name'] as String?,
// // // // // // // // // // // //               avatarUrl: r['avatar_url'] as String?,
// // // // // // // // // // // //             ),
// // // // // // // // // // // //           )
// // // // // // // // // // // //           .toList();
// // // // // // // // // // // //     },
// // // // // // // // // // // //   );

// // // // // // // // // // // //   // ── Private helpers ───────────────────────────────────────────────────────

// // // // // // // // // // // //   Future<void> _checkNotBlocked(String a, String b) async {
// // // // // // // // // // // //     final block = await _supabase
// // // // // // // // // // // //         .from('blocked_users')
// // // // // // // // // // // //         .select('blocker_id')
// // // // // // // // // // // //         .or(
// // // // // // // // // // // //           'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // // // // // // // // // // //           'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // // // // // // // // // // //         )
// // // // // // // // // // // //         .maybeSingle();
// // // // // // // // // // // //     if (block != null) {
// // // // // // // // // // // //       throw const ForbiddenFailure(message: 'Cannot interact with this user.');
// // // // // // // // // // // //     }
// // // // // // // // // // // //   }

// // // // // // // // // // // //   FriendEntity _toFriendEntity(Map<String, dynamic> row, String currentUserId) {
// // // // // // // // // // // //     final requesterId = row['requester_id'] as String? ?? '';
// // // // // // // // // // // //     final isRequester = requesterId == currentUserId;
// // // // // // // // // // // //     final rawOther = isRequester ? row['addressee'] : row['requester'];
// // // // // // // // // // // //     final other = (rawOther is Map)
// // // // // // // // // // // //         ? Map<String, dynamic>.from(rawOther)
// // // // // // // // // // // //         : <String, dynamic>{};
// // // // // // // // // // // //     return FriendEntity(
// // // // // // // // // // // //       friendshipId: row['id'] as String?,
// // // // // // // // // // // //       userId: other['id'] as String? ?? '',
// // // // // // // // // // // //       displayName: other['display_name'] as String? ?? 'Player',
// // // // // // // // // // // //       username: other['username'] as String?,
// // // // // // // // // // // //       avatarUrl: other['avatar_url'] as String?,
// // // // // // // // // // // //       status: FriendshipStatus.values.firstWhere(
// // // // // // // // // // // //         (s) => s.name == (row['status'] as String? ?? ''),
// // // // // // // // // // // //         orElse: () => FriendshipStatus.pending,
// // // // // // // // // // // //       ),
// // // // // // // // // // // //       isRequester: isRequester,
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }

// // // // // // // // // // // //   FollowEntity _toFollowEntity(
// // // // // // // // // // // //     Map<String, dynamic> row, {
// // // // // // // // // // // //     bool followingMode = false,
// // // // // // // // // // // //   }) {
// // // // // // // // // // // //     final profile =
// // // // // // // // // // // //         row[followingMode ? 'profiles!following_id' : 'profiles!follower_id']
// // // // // // // // // // // //             as Map<String, dynamic>? ??
// // // // // // // // // // // //         {};
// // // // // // // // // // // //     return FollowEntity(
// // // // // // // // // // // //       userId: profile['id'] as String? ?? '',
// // // // // // // // // // // //       displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // // // // //       username: profile['username'] as String?,
// // // // // // // // // // // //       avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // // // //       followedAt: DateTime.parse(row['created_at'] as String),
// // // // // // // // // // // //       isVerified: profile['verification_status'] == 'verified',
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }
// // // // // // // // // // // // }

// // // // // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // // // // // import '../../../core/data/base_repository.dart';
// // // // // // // // // // // import '../../../core/errors/failures.dart';
// // // // // // // // // // // import '../../../features/auth/domain/entities/user_entity.dart';

// // // // // // // // // // // // ── Domain types ──────────────────────────────────────────────────────────────

// // // // // // // // // // // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // // // // // // // // // // class FriendEntity {
// // // // // // // // // // //   const FriendEntity({
// // // // // // // // // // //     required this.userId,
// // // // // // // // // // //     required this.displayName,
// // // // // // // // // // //     this.username,
// // // // // // // // // // //     this.avatarUrl,
// // // // // // // // // // //     required this.status,
// // // // // // // // // // //     required this.isRequester,
// // // // // // // // // // //     this.mutualFriendsCount = 0,
// // // // // // // // // // //     this.friendshipId,
// // // // // // // // // // //   });

// // // // // // // // // // //   final String userId;
// // // // // // // // // // //   final String displayName;
// // // // // // // // // // //   final String? username;
// // // // // // // // // // //   final String? avatarUrl;
// // // // // // // // // // //   final FriendshipStatus status;
// // // // // // // // // // //   final bool isRequester;
// // // // // // // // // // //   final int mutualFriendsCount;
// // // // // // // // // // //   final String? friendshipId;

// // // // // // // // // // //   bool get isAccepted => status == FriendshipStatus.accepted;
// // // // // // // // // // //   bool get isPending => status == FriendshipStatus.pending;
// // // // // // // // // // // }

// // // // // // // // // // // class FollowEntity {
// // // // // // // // // // //   const FollowEntity({
// // // // // // // // // // //     required this.userId,
// // // // // // // // // // //     required this.displayName,
// // // // // // // // // // //     this.username,
// // // // // // // // // // //     this.avatarUrl,
// // // // // // // // // // //     required this.followedAt,
// // // // // // // // // // //     this.isVerified = false,
// // // // // // // // // // //   });

// // // // // // // // // // //   final String userId;
// // // // // // // // // // //   final String displayName;
// // // // // // // // // // //   final String? username;
// // // // // // // // // // //   final String? avatarUrl;
// // // // // // // // // // //   final DateTime followedAt;
// // // // // // // // // // //   final bool isVerified;
// // // // // // // // // // // }

// // // // // // // // // // // class SocialProfile {
// // // // // // // // // // //   const SocialProfile({
// // // // // // // // // // //     required this.userId,
// // // // // // // // // // //     required this.displayName,
// // // // // // // // // // //     this.username,
// // // // // // // // // // //     this.avatarUrl,
// // // // // // // // // // //     this.bio,
// // // // // // // // // // //     required this.followersCount,
// // // // // // // // // // //     required this.followingCount,
// // // // // // // // // // //     required this.friendsCount,
// // // // // // // // // // //     this.friendshipStatus,
// // // // // // // // // // //     this.isFollowing = false,
// // // // // // // // // // //     this.isFollowedBy = false,
// // // // // // // // // // //     this.isBlocked = false,
// // // // // // // // // // //     this.isBlockedBy = false,
// // // // // // // // // // //     this.isVerified = false,
// // // // // // // // // // //   });

// // // // // // // // // // //   final String userId;
// // // // // // // // // // //   final String displayName;
// // // // // // // // // // //   final String? username;
// // // // // // // // // // //   final String? avatarUrl;
// // // // // // // // // // //   final String? bio;
// // // // // // // // // // //   final int followersCount;
// // // // // // // // // // //   final int followingCount;
// // // // // // // // // // //   final int friendsCount;
// // // // // // // // // // //   final FriendshipStatus? friendshipStatus;
// // // // // // // // // // //   final bool isFollowing;
// // // // // // // // // // //   final bool isFollowedBy;
// // // // // // // // // // //   final bool isBlocked;
// // // // // // // // // // //   final bool isBlockedBy;
// // // // // // // // // // //   final bool isVerified;

// // // // // // // // // // //   bool get canInteract => !isBlocked && !isBlockedBy;
// // // // // // // // // // // }

// // // // // // // // // // // // ── Repository ────────────────────────────────────────────────────────────────

// // // // // // // // // // // class FriendsRepository extends BaseRepository {
// // // // // // // // // // //   FriendsRepository._();
// // // // // // // // // // //   static final FriendsRepository _instance = FriendsRepository._();
// // // // // // // // // // //   static FriendsRepository get instance => _instance;

// // // // // // // // // // //   final _supabase = Supabase.instance.client;

// // // // // // // // // // //   // ── Friends ───────────────────────────────────────────────────────────────

// // // // // // // // // // //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// // // // // // // // // // //     operationName: 'getFriends',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // //           .from('friendships')
// // // // // // // // // // //           .select(
// // // // // // // // // // //             'id,status,requester_id,addressee_id,'
// // // // // // // // // // //             'requester:profiles!requester_id(id,display_name,username,avatar_url),'
// // // // // // // // // // //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url)',
// // // // // // // // // // //           )
// // // // // // // // // // //           .or('requester_id.eq.$userId,addressee_id.eq.$userId')
// // // // // // // // // // //           .eq('status', 'accepted');
// // // // // // // // // // //       return rows.map((r) => _toFriendEntity(r, userId)).toList();
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   Future<List<FriendEntity>> getPendingRequests(String userId) => guardedCall(
// // // // // // // // // // //     operationName: 'getPendingRequests',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // //           .from('friendships')
// // // // // // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // // // // // //           .eq('addressee_id', userId)
// // // // // // // // // // //           .eq('status', 'pending');
// // // // // // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // // // // // //       // Fetch requester profiles separately to avoid join ambiguity
// // // // // // // // // // //       final requesterIds = rows
// // // // // // // // // // //           .map((r) => r['requester_id'] as String)
// // // // // // // // // // //           .toList();
// // // // // // // // // // //       final profiles = await _supabase
// // // // // // // // // // //           .from('profiles')
// // // // // // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // // // // // //           .inFilter('id', requesterIds);
// // // // // // // // // // //       final profileMap = {
// // // // // // // // // // //         for (final p in profiles as List)
// // // // // // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // // // // // //       };
// // // // // // // // // // //       return rows.map((r) {
// // // // // // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // // // // // //         row['requester'] = profileMap[row['requester_id']] ?? {};
// // // // // // // // // // //         return _toFriendEntity(row, userId);
// // // // // // // // // // //       }).toList();
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   Future<List<FriendEntity>> getSentRequests(String userId) => guardedCall(
// // // // // // // // // // //     operationName: 'getSentRequests',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // //           .from('friendships')
// // // // // // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // // // // // //           .eq('requester_id', userId)
// // // // // // // // // // //           .eq('status', 'pending');
// // // // // // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // // // // // //       // Fetch addressee profiles separately
// // // // // // // // // // //       final addresseeIds = rows
// // // // // // // // // // //           .map((r) => r['addressee_id'] as String)
// // // // // // // // // // //           .toList();
// // // // // // // // // // //       final profiles = await _supabase
// // // // // // // // // // //           .from('profiles')
// // // // // // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // // // // // //           .inFilter('id', addresseeIds);
// // // // // // // // // // //       final profileMap = {
// // // // // // // // // // //         for (final p in profiles as List)
// // // // // // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // // // // // //       };
// // // // // // // // // // //       return rows.map((r) {
// // // // // // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // // // // // //         row['addressee'] = profileMap[row['addressee_id']] ?? {};
// // // // // // // // // // //         return _toFriendEntity(row, userId);
// // // // // // // // // // //       }).toList();
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   Future<void> sendFriendRequest({
// // // // // // // // // // //     required String requesterId,
// // // // // // // // // // //     required String addresseeId,
// // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // //     operationName: 'sendFriendRequest',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       // Check not blocked
// // // // // // // // // // //       await _checkNotBlocked(requesterId, addresseeId);
// // // // // // // // // // //       await _supabase.from('friendships').insert({
// // // // // // // // // // //         'requester_id': requesterId,
// // // // // // // // // // //         'addressee_id': addresseeId,
// // // // // // // // // // //         'status': 'pending',
// // // // // // // // // // //       });
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   Future<void> respondToRequest({
// // // // // // // // // // //     required String requesterId,
// // // // // // // // // // //     required String addresseeId,
// // // // // // // // // // //     required bool accept,
// // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // //     operationName: 'respondToRequest',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       await _supabase
// // // // // // // // // // //           .from('friendships')
// // // // // // // // // // //           .update({'status': accept ? 'accepted' : 'rejected'})
// // // // // // // // // // //           .eq('requester_id', requesterId)
// // // // // // // // // // //           .eq('addressee_id', addresseeId);
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   Future<void> removeFriend({
// // // // // // // // // // //     required String userId,
// // // // // // // // // // //     required String friendId,
// // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // //     operationName: 'removeFriend',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       await _supabase
// // // // // // // // // // //           .from('friendships')
// // // // // // // // // // //           .delete()
// // // // // // // // // // //           .or(
// // // // // // // // // // //             'and(requester_id.eq.$userId,addressee_id.eq.$friendId),'
// // // // // // // // // // //             'and(requester_id.eq.$friendId,addressee_id.eq.$userId)',
// // // // // // // // // // //           );
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   Future<void> cancelRequest({
// // // // // // // // // // //     required String requesterId,
// // // // // // // // // // //     required String addresseeId,
// // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // //     operationName: 'cancelRequest',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       await _supabase
// // // // // // // // // // //           .from('friendships')
// // // // // // // // // // //           .delete()
// // // // // // // // // // //           .eq('requester_id', requesterId)
// // // // // // // // // // //           .eq('addressee_id', addresseeId)
// // // // // // // // // // //           .eq('status', 'pending');
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   // ── Follow system ─────────────────────────────────────────────────────────

// // // // // // // // // // //   Future<void> followUser(String followerId, String followingId) => guardedCall(
// // // // // // // // // // //     operationName: 'followUser',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       await _checkNotBlocked(followerId, followingId);
// // // // // // // // // // //       await _supabase.from('follows').upsert({
// // // // // // // // // // //         'follower_id': followerId,
// // // // // // // // // // //         'following_id': followingId,
// // // // // // // // // // //       }, onConflict: 'follower_id,following_id');
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   Future<void> unfollowUser(String followerId, String followingId) =>
// // // // // // // // // // //       guardedCall(
// // // // // // // // // // //         operationName: 'unfollowUser',
// // // // // // // // // // //         operation: () async {
// // // // // // // // // // //           await _supabase
// // // // // // // // // // //               .from('follows')
// // // // // // // // // // //               .delete()
// // // // // // // // // // //               .eq('follower_id', followerId)
// // // // // // // // // // //               .eq('following_id', followingId);
// // // // // // // // // // //         },
// // // // // // // // // // //       );

// // // // // // // // // // //   Future<List<FollowEntity>> getFollowers(
// // // // // // // // // // //     String userId, {
// // // // // // // // // // //     int limit = 50,
// // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // //     operationName: 'getFollowers',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // //           .from('follows')
// // // // // // // // // // //           .select(
// // // // // // // // // // //             'follower_id,created_at,'
// // // // // // // // // // //             'profiles!follower_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // // // // // //           )
// // // // // // // // // // //           .eq('following_id', userId)
// // // // // // // // // // //           .order('created_at', ascending: false)
// // // // // // // // // // //           .limit(limit);
// // // // // // // // // // //       return rows.map(_toFollowEntity).toList();
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   Future<List<FollowEntity>> getFollowing(
// // // // // // // // // // //     String userId, {
// // // // // // // // // // //     int limit = 50,
// // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // //     operationName: 'getFollowing',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // //           .from('follows')
// // // // // // // // // // //           .select(
// // // // // // // // // // //             'following_id,created_at,'
// // // // // // // // // // //             'profiles!following_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // // // // // //           )
// // // // // // // // // // //           .eq('follower_id', userId)
// // // // // // // // // // //           .order('created_at', ascending: false)
// // // // // // // // // // //           .limit(limit);
// // // // // // // // // // //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   // ── Block system ──────────────────────────────────────────────────────────

// // // // // // // // // // //   Future<void> blockUser({
// // // // // // // // // // //     required String blockerId,
// // // // // // // // // // //     required String blockedId,
// // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // //     operationName: 'blockUser',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       await _supabase.from('blocked_users').upsert({
// // // // // // // // // // //         'blocker_id': blockerId,
// // // // // // // // // // //         'blocked_id': blockedId,
// // // // // // // // // // //       }, onConflict: 'blocker_id,blocked_id');
// // // // // // // // // // //       // Also remove any existing friendship
// // // // // // // // // // //       await removeFriend(
// // // // // // // // // // //         userId: blockerId,
// // // // // // // // // // //         friendId: blockedId,
// // // // // // // // // // //       ).catchError((_) {});
// // // // // // // // // // //       // Remove follow in both directions
// // // // // // // // // // //       await unfollowUser(blockerId, blockedId).catchError((_) {});
// // // // // // // // // // //       await unfollowUser(blockedId, blockerId).catchError((_) {});
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   Future<void> unblockUser({
// // // // // // // // // // //     required String blockerId,
// // // // // // // // // // //     required String blockedId,
// // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // //     operationName: 'unblockUser',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       await _supabase
// // // // // // // // // // //           .from('blocked_users')
// // // // // // // // // // //           .delete()
// // // // // // // // // // //           .eq('blocker_id', blockerId)
// // // // // // // // // // //           .eq('blocked_id', blockedId);
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   Future<List<FriendEntity>> getBlockedUsers(String userId) => guardedCall(
// // // // // // // // // // //     operationName: 'getBlockedUsers',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // //           .from('blocked_users')
// // // // // // // // // // //           .select(
// // // // // // // // // // //             'blocked_id,created_at,'
// // // // // // // // // // //             'profiles!blocked_id(id,display_name,username,avatar_url)',
// // // // // // // // // // //           )
// // // // // // // // // // //           .eq('blocker_id', userId)
// // // // // // // // // // //           .order('created_at', ascending: false);
// // // // // // // // // // //       return rows.map((r) {
// // // // // // // // // // //         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
// // // // // // // // // // //         return FriendEntity(
// // // // // // // // // // //           userId: profile['id'] as String? ?? '',
// // // // // // // // // // //           displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // // // //           username: profile['username'] as String?,
// // // // // // // // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // // //           status: FriendshipStatus.blocked,
// // // // // // // // // // //           isRequester: true,
// // // // // // // // // // //         );
// // // // // // // // // // //       }).toList();
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   // ── Social profile ────────────────────────────────────────────────────────

// // // // // // // // // // //   Future<SocialProfile> getSocialProfile({
// // // // // // // // // // //     required String targetUserId,
// // // // // // // // // // //     required String viewerUserId,
// // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // //     operationName: 'getSocialProfile',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       // Try profiles_public first (has bio + counts after migration)
// // // // // // // // // // //       Map<String, dynamic>? profile = await _supabase
// // // // // // // // // // //           .from('profiles_public')
// // // // // // // // // // //           .select()
// // // // // // // // // // //           .eq('id', targetUserId)
// // // // // // // // // // //           .maybeSingle();

// // // // // // // // // // //       // Fallback: profiles table directly (handles RLS edge cases)
// // // // // // // // // // //       if (profile == null) {
// // // // // // // // // // //         profile = await _supabase
// // // // // // // // // // //             .from('profiles')
// // // // // // // // // // //             .select('id, display_name, username, avatar_url, bio')
// // // // // // // // // // //             .eq('id', targetUserId)
// // // // // // // // // // //             .maybeSingle();
// // // // // // // // // // //       }
// // // // // // // // // // //       if (profile == null) throw Exception('Profile not found');

// // // // // // // // // // //       // If we only got minimal data (no counts), return basic profile
// // // // // // // // // // //       final hasFullData = profile.containsKey('followers_count');
// // // // // // // // // // //       if (!hasFullData) {
// // // // // // // // // // //         return SocialProfile(
// // // // // // // // // // //           userId: profile['id'] as String,
// // // // // // // // // // //           displayName: profile['display_name'] as String? ?? 'Player',
// // // // // // // // // // //           username: profile['username'] as String?,
// // // // // // // // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // // //           bio: profile['bio'] as String?,
// // // // // // // // // // //           followersCount: 0,
// // // // // // // // // // //           followingCount: 0,
// // // // // // // // // // //           friendsCount: 0,
// // // // // // // // // // //         );
// // // // // // // // // // //       }

// // // // // // // // // // //       final [
// // // // // // // // // // //         blockedByMe,
// // // // // // // // // // //         blockedByThem,
// // // // // // // // // // //         friendshipRow,
// // // // // // // // // // //         followingRow,
// // // // // // // // // // //         followedByRow,
// // // // // // // // // // //       ] = await Future.wait([
// // // // // // // // // // //         _supabase
// // // // // // // // // // //             .from('blocked_users')
// // // // // // // // // // //             .select('blocker_id')
// // // // // // // // // // //             .eq('blocker_id', viewerUserId)
// // // // // // // // // // //             .eq('blocked_id', targetUserId)
// // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // //         _supabase
// // // // // // // // // // //             .from('blocked_users')
// // // // // // // // // // //             .select('blocker_id')
// // // // // // // // // // //             .eq('blocker_id', targetUserId)
// // // // // // // // // // //             .eq('blocked_id', viewerUserId)
// // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // //         _supabase
// // // // // // // // // // //             .from('friendships')
// // // // // // // // // // //             .select('status')
// // // // // // // // // // //             .or(
// // // // // // // // // // //               'and(requester_id.eq.$viewerUserId,addressee_id.eq.$targetUserId),'
// // // // // // // // // // //               'and(requester_id.eq.$targetUserId,addressee_id.eq.$viewerUserId)',
// // // // // // // // // // //             )
// // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // //         _supabase
// // // // // // // // // // //             .from('follows')
// // // // // // // // // // //             .select('id')
// // // // // // // // // // //             .eq('follower_id', viewerUserId)
// // // // // // // // // // //             .eq('following_id', targetUserId)
// // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // //         _supabase
// // // // // // // // // // //             .from('follows')
// // // // // // // // // // //             .select('id')
// // // // // // // // // // //             .eq('follower_id', targetUserId)
// // // // // // // // // // //             .eq('following_id', viewerUserId)
// // // // // // // // // // //             .maybeSingle(),
// // // // // // // // // // //       ]);

// // // // // // // // // // //       FriendshipStatus? friendStatus;
// // // // // // // // // // //       if (friendshipRow != null) {
// // // // // // // // // // //         friendStatus = FriendshipStatus.values.firstWhere(
// // // // // // // // // // //           (s) => s.name == (friendshipRow as Map)['status'],
// // // // // // // // // // //           orElse: () => FriendshipStatus.pending,
// // // // // // // // // // //         );
// // // // // // // // // // //       }

// // // // // // // // // // //       return SocialProfile(
// // // // // // // // // // //         userId: profile['id'] as String,
// // // // // // // // // // //         displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // // // //         username: profile['username'] as String?,
// // // // // // // // // // //         avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // // //         bio: profile['bio'] as String?,
// // // // // // // // // // //         followersCount: profile['followers_count'] as int? ?? 0,
// // // // // // // // // // //         followingCount: profile['following_count'] as int? ?? 0,
// // // // // // // // // // //         friendsCount: profile['friends_count'] as int? ?? 0,
// // // // // // // // // // //         friendshipStatus: friendStatus,
// // // // // // // // // // //         isFollowing: followingRow != null,
// // // // // // // // // // //         isFollowedBy: followedByRow != null,
// // // // // // // // // // //         isBlocked: blockedByMe != null,
// // // // // // // // // // //         isBlockedBy: blockedByThem != null,
// // // // // // // // // // //         isVerified: profile['verification_status'] == 'verified',
// // // // // // // // // // //       );
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   // ── Search ────────────────────────────────────────────────────────────────

// // // // // // // // // // //   Future<List<UserEntity>> searchUsers(
// // // // // // // // // // //     String query, {
// // // // // // // // // // //     required String excludeUserId,
// // // // // // // // // // //     int limit = 20,
// // // // // // // // // // //   }) => guardedCall(
// // // // // // // // // // //     operationName: 'searchUsers',
// // // // // // // // // // //     operation: () async {
// // // // // // // // // // //       final rows = await _supabase
// // // // // // // // // // //           .from('profiles_public')
// // // // // // // // // // //           .select('id,username,display_name,avatar_url')
// // // // // // // // // // //           .or('username.ilike.%$query%,display_name.ilike.%$query%')
// // // // // // // // // // //           .neq('id', excludeUserId)
// // // // // // // // // // //           .limit(limit);
// // // // // // // // // // //       return rows
// // // // // // // // // // //           .map(
// // // // // // // // // // //             (r) => UserEntity(
// // // // // // // // // // //               id: r['id'] as String,
// // // // // // // // // // //               email: '',
// // // // // // // // // // //               username: r['username'] as String?,
// // // // // // // // // // //               displayName: r['display_name'] as String?,
// // // // // // // // // // //               avatarUrl: r['avatar_url'] as String?,
// // // // // // // // // // //             ),
// // // // // // // // // // //           )
// // // // // // // // // // //           .toList();
// // // // // // // // // // //     },
// // // // // // // // // // //   );

// // // // // // // // // // //   // ── Private helpers ───────────────────────────────────────────────────────

// // // // // // // // // // //   Future<void> _checkNotBlocked(String a, String b) async {
// // // // // // // // // // //     final block = await _supabase
// // // // // // // // // // //         .from('blocked_users')
// // // // // // // // // // //         .select('blocker_id')
// // // // // // // // // // //         .or(
// // // // // // // // // // //           'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // // // // // // // // // //           'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // // // // // // // // // //         )
// // // // // // // // // // //         .maybeSingle();
// // // // // // // // // // //     if (block != null) {
// // // // // // // // // // //       throw const ForbiddenFailure(message: 'Cannot interact with this user.');
// // // // // // // // // // //     }
// // // // // // // // // // //   }

// // // // // // // // // // //   FriendEntity _toFriendEntity(Map<String, dynamic> row, String currentUserId) {
// // // // // // // // // // //     final requesterId = row['requester_id'] as String? ?? '';
// // // // // // // // // // //     final isRequester = requesterId == currentUserId;
// // // // // // // // // // //     final rawOther = isRequester ? row['addressee'] : row['requester'];
// // // // // // // // // // //     final other = (rawOther is Map)
// // // // // // // // // // //         ? Map<String, dynamic>.from(rawOther)
// // // // // // // // // // //         : <String, dynamic>{};
// // // // // // // // // // //     return FriendEntity(
// // // // // // // // // // //       friendshipId: row['id'] as String?,
// // // // // // // // // // //       userId: other['id'] as String? ?? '',
// // // // // // // // // // //       displayName: other['display_name'] as String? ?? 'Player',
// // // // // // // // // // //       username: other['username'] as String?,
// // // // // // // // // // //       avatarUrl: other['avatar_url'] as String?,
// // // // // // // // // // //       status: FriendshipStatus.values.firstWhere(
// // // // // // // // // // //         (s) => s.name == (row['status'] as String? ?? ''),
// // // // // // // // // // //         orElse: () => FriendshipStatus.pending,
// // // // // // // // // // //       ),
// // // // // // // // // // //       isRequester: isRequester,
// // // // // // // // // // //     );
// // // // // // // // // // //   }

// // // // // // // // // // //   FollowEntity _toFollowEntity(
// // // // // // // // // // //     Map<String, dynamic> row, {
// // // // // // // // // // //     bool followingMode = false,
// // // // // // // // // // //   }) {
// // // // // // // // // // //     final profile =
// // // // // // // // // // //         row[followingMode ? 'profiles!following_id' : 'profiles!follower_id']
// // // // // // // // // // //             as Map<String, dynamic>? ??
// // // // // // // // // // //         {};
// // // // // // // // // // //     return FollowEntity(
// // // // // // // // // // //       userId: profile['id'] as String? ?? '',
// // // // // // // // // // //       displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // // // //       username: profile['username'] as String?,
// // // // // // // // // // //       avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // // //       followedAt: DateTime.parse(row['created_at'] as String),
// // // // // // // // // // //       isVerified: profile['verification_status'] == 'verified',
// // // // // // // // // // //     );
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // // // // import '../../../core/data/base_repository.dart';
// // // // // // // // // // import '../../../core/errors/failures.dart';
// // // // // // // // // // import '../../../features/auth/domain/entities/user_entity.dart';

// // // // // // // // // // // ── Domain types ──────────────────────────────────────────────────────────────

// // // // // // // // // // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // // // // // // // // // class FriendEntity {
// // // // // // // // // //   const FriendEntity({
// // // // // // // // // //     required this.userId,
// // // // // // // // // //     required this.displayName,
// // // // // // // // // //     this.username,
// // // // // // // // // //     this.avatarUrl,
// // // // // // // // // //     required this.status,
// // // // // // // // // //     required this.isRequester,
// // // // // // // // // //     this.mutualFriendsCount = 0,
// // // // // // // // // //     this.friendshipId,
// // // // // // // // // //   });

// // // // // // // // // //   final String userId;
// // // // // // // // // //   final String displayName;
// // // // // // // // // //   final String? username;
// // // // // // // // // //   final String? avatarUrl;
// // // // // // // // // //   final FriendshipStatus status;
// // // // // // // // // //   final bool isRequester;
// // // // // // // // // //   final int mutualFriendsCount;
// // // // // // // // // //   final String? friendshipId;

// // // // // // // // // //   bool get isAccepted => status == FriendshipStatus.accepted;
// // // // // // // // // //   bool get isPending => status == FriendshipStatus.pending;
// // // // // // // // // // }

// // // // // // // // // // class FollowEntity {
// // // // // // // // // //   const FollowEntity({
// // // // // // // // // //     required this.userId,
// // // // // // // // // //     required this.displayName,
// // // // // // // // // //     this.username,
// // // // // // // // // //     this.avatarUrl,
// // // // // // // // // //     required this.followedAt,
// // // // // // // // // //     this.isVerified = false,
// // // // // // // // // //   });

// // // // // // // // // //   final String userId;
// // // // // // // // // //   final String displayName;
// // // // // // // // // //   final String? username;
// // // // // // // // // //   final String? avatarUrl;
// // // // // // // // // //   final DateTime followedAt;
// // // // // // // // // //   final bool isVerified;
// // // // // // // // // // }

// // // // // // // // // // class SocialProfile {
// // // // // // // // // //   const SocialProfile({
// // // // // // // // // //     required this.userId,
// // // // // // // // // //     required this.displayName,
// // // // // // // // // //     this.username,
// // // // // // // // // //     this.avatarUrl,
// // // // // // // // // //     this.bio,
// // // // // // // // // //     required this.followersCount,
// // // // // // // // // //     required this.followingCount,
// // // // // // // // // //     required this.friendsCount,
// // // // // // // // // //     this.friendshipStatus,
// // // // // // // // // //     this.isFollowing = false,
// // // // // // // // // //     this.isFollowedBy = false,
// // // // // // // // // //     this.isBlocked = false,
// // // // // // // // // //     this.isBlockedBy = false,
// // // // // // // // // //     this.isVerified = false,
// // // // // // // // // //   });

// // // // // // // // // //   final String userId;
// // // // // // // // // //   final String displayName;
// // // // // // // // // //   final String? username;
// // // // // // // // // //   final String? avatarUrl;
// // // // // // // // // //   final String? bio;
// // // // // // // // // //   final int followersCount;
// // // // // // // // // //   final int followingCount;
// // // // // // // // // //   final int friendsCount;
// // // // // // // // // //   final FriendshipStatus? friendshipStatus;
// // // // // // // // // //   final bool isFollowing;
// // // // // // // // // //   final bool isFollowedBy;
// // // // // // // // // //   final bool isBlocked;
// // // // // // // // // //   final bool isBlockedBy;
// // // // // // // // // //   final bool isVerified;

// // // // // // // // // //   bool get canInteract => !isBlocked && !isBlockedBy;
// // // // // // // // // // }

// // // // // // // // // // // ── Repository ────────────────────────────────────────────────────────────────

// // // // // // // // // // class FriendsRepository extends BaseRepository {
// // // // // // // // // //   FriendsRepository._();
// // // // // // // // // //   static final FriendsRepository _instance = FriendsRepository._();
// // // // // // // // // //   static FriendsRepository get instance => _instance;

// // // // // // // // // //   final _supabase = Supabase.instance.client;

// // // // // // // // // //   // ── Friends ───────────────────────────────────────────────────────────────

// // // // // // // // // //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// // // // // // // // // //     operationName: 'getFriends',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       final rows = await _supabase
// // // // // // // // // //           .from('friendships')
// // // // // // // // // //           .select(
// // // // // // // // // //             'id,status,requester_id,addressee_id,'
// // // // // // // // // //             'requester:profiles!requester_id(id,display_name,username,avatar_url),'
// // // // // // // // // //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url)',
// // // // // // // // // //           )
// // // // // // // // // //           .or('requester_id.eq.$userId,addressee_id.eq.$userId')
// // // // // // // // // //           .eq('status', 'accepted');
// // // // // // // // // //       return rows.map((r) => _toFriendEntity(r, userId)).toList();
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   Future<List<FriendEntity>> getPendingRequests(String userId) => guardedCall(
// // // // // // // // // //     operationName: 'getPendingRequests',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       final rows = await _supabase
// // // // // // // // // //           .from('friendships')
// // // // // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // // // // //           .eq('addressee_id', userId)
// // // // // // // // // //           .eq('status', 'pending');
// // // // // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // // // // //       // Fetch requester profiles separately to avoid join ambiguity
// // // // // // // // // //       final requesterIds = rows
// // // // // // // // // //           .map((r) => r['requester_id'] as String)
// // // // // // // // // //           .toList();
// // // // // // // // // //       final profiles = await _supabase
// // // // // // // // // //           .from('profiles')
// // // // // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // // // // //           .inFilter('id', requesterIds);
// // // // // // // // // //       final profileMap = {
// // // // // // // // // //         for (final p in profiles as List)
// // // // // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // // // // //       };
// // // // // // // // // //       return rows.map((r) {
// // // // // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // // // // //         row['requester'] = profileMap[row['requester_id']] ?? {};
// // // // // // // // // //         return _toFriendEntity(row, userId);
// // // // // // // // // //       }).toList();
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   Future<List<FriendEntity>> getSentRequests(String userId) => guardedCall(
// // // // // // // // // //     operationName: 'getSentRequests',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       final rows = await _supabase
// // // // // // // // // //           .from('friendships')
// // // // // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // // // // //           .eq('requester_id', userId)
// // // // // // // // // //           .eq('status', 'pending');
// // // // // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // // // // //       // Fetch addressee profiles separately
// // // // // // // // // //       final addresseeIds = rows
// // // // // // // // // //           .map((r) => r['addressee_id'] as String)
// // // // // // // // // //           .toList();
// // // // // // // // // //       final profiles = await _supabase
// // // // // // // // // //           .from('profiles')
// // // // // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // // // // //           .inFilter('id', addresseeIds);
// // // // // // // // // //       final profileMap = {
// // // // // // // // // //         for (final p in profiles as List)
// // // // // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // // // // //       };
// // // // // // // // // //       return rows.map((r) {
// // // // // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // // // // //         row['addressee'] = profileMap[row['addressee_id']] ?? {};
// // // // // // // // // //         return _toFriendEntity(row, userId);
// // // // // // // // // //       }).toList();
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   Future<void> sendFriendRequest({
// // // // // // // // // //     required String requesterId,
// // // // // // // // // //     required String addresseeId,
// // // // // // // // // //   }) => guardedCall(
// // // // // // // // // //     operationName: 'sendFriendRequest',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       // Check not blocked
// // // // // // // // // //       await _checkNotBlocked(requesterId, addresseeId);
// // // // // // // // // //       await _supabase.from('friendships').insert({
// // // // // // // // // //         'requester_id': requesterId,
// // // // // // // // // //         'addressee_id': addresseeId,
// // // // // // // // // //         'status': 'pending',
// // // // // // // // // //       });
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   Future<void> respondToRequest({
// // // // // // // // // //     required String requesterId,
// // // // // // // // // //     required String addresseeId,
// // // // // // // // // //     required bool accept,
// // // // // // // // // //   }) => guardedCall(
// // // // // // // // // //     operationName: 'respondToRequest',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       await _supabase
// // // // // // // // // //           .from('friendships')
// // // // // // // // // //           .update({'status': accept ? 'accepted' : 'rejected'})
// // // // // // // // // //           .eq('requester_id', requesterId)
// // // // // // // // // //           .eq('addressee_id', addresseeId);
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   Future<void> removeFriend({
// // // // // // // // // //     required String userId,
// // // // // // // // // //     required String friendId,
// // // // // // // // // //   }) => guardedCall(
// // // // // // // // // //     operationName: 'removeFriend',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       await _supabase
// // // // // // // // // //           .from('friendships')
// // // // // // // // // //           .delete()
// // // // // // // // // //           .or(
// // // // // // // // // //             'and(requester_id.eq.$userId,addressee_id.eq.$friendId),'
// // // // // // // // // //             'and(requester_id.eq.$friendId,addressee_id.eq.$userId)',
// // // // // // // // // //           );
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   Future<void> cancelRequest({
// // // // // // // // // //     required String requesterId,
// // // // // // // // // //     required String addresseeId,
// // // // // // // // // //   }) => guardedCall(
// // // // // // // // // //     operationName: 'cancelRequest',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       await _supabase
// // // // // // // // // //           .from('friendships')
// // // // // // // // // //           .delete()
// // // // // // // // // //           .eq('requester_id', requesterId)
// // // // // // // // // //           .eq('addressee_id', addresseeId)
// // // // // // // // // //           .eq('status', 'pending');
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   // ── Follow system ─────────────────────────────────────────────────────────

// // // // // // // // // //   Future<void> followUser(String followerId, String followingId) => guardedCall(
// // // // // // // // // //     operationName: 'followUser',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       await _checkNotBlocked(followerId, followingId);
// // // // // // // // // //       await _supabase.from('follows').upsert({
// // // // // // // // // //         'follower_id': followerId,
// // // // // // // // // //         'followee_id': followingId,
// // // // // // // // // //       }, onConflict: 'follower_id,followee_id');
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   Future<void> unfollowUser(String followerId, String followingId) =>
// // // // // // // // // //       guardedCall(
// // // // // // // // // //         operationName: 'unfollowUser',
// // // // // // // // // //         operation: () async {
// // // // // // // // // //           await _supabase
// // // // // // // // // //               .from('follows')
// // // // // // // // // //               .delete()
// // // // // // // // // //               .eq('follower_id', followerId)
// // // // // // // // // //               .eq('followee_id', followingId);
// // // // // // // // // //         },
// // // // // // // // // //       );

// // // // // // // // // //   Future<List<FollowEntity>> getFollowers(
// // // // // // // // // //     String userId, {
// // // // // // // // // //     int limit = 50,
// // // // // // // // // //   }) => guardedCall(
// // // // // // // // // //     operationName: 'getFollowers',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       final rows = await _supabase
// // // // // // // // // //           .from('follows')
// // // // // // // // // //           .select(
// // // // // // // // // //             'follower_id,created_at,'
// // // // // // // // // //             'profiles!follower_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // // // // //           )
// // // // // // // // // //           .eq('followee_id', userId)
// // // // // // // // // //           .order('created_at', ascending: false)
// // // // // // // // // //           .limit(limit);
// // // // // // // // // //       return rows.map(_toFollowEntity).toList();
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   Future<List<FollowEntity>> getFollowing(
// // // // // // // // // //     String userId, {
// // // // // // // // // //     int limit = 50,
// // // // // // // // // //   }) => guardedCall(
// // // // // // // // // //     operationName: 'getFollowing',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       final rows = await _supabase
// // // // // // // // // //           .from('follows')
// // // // // // // // // //           .select(
// // // // // // // // // //             'followee_id,created_at,'
// // // // // // // // // //             'profiles!followee_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // // // // //           )
// // // // // // // // // //           .eq('follower_id', userId)
// // // // // // // // // //           .order('created_at', ascending: false)
// // // // // // // // // //           .limit(limit);
// // // // // // // // // //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   // ── Block system ──────────────────────────────────────────────────────────

// // // // // // // // // //   Future<void> blockUser({
// // // // // // // // // //     required String blockerId,
// // // // // // // // // //     required String blockedId,
// // // // // // // // // //   }) => guardedCall(
// // // // // // // // // //     operationName: 'blockUser',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       await _supabase.from('blocked_users').upsert({
// // // // // // // // // //         'blocker_id': blockerId,
// // // // // // // // // //         'blocked_id': blockedId,
// // // // // // // // // //       }, onConflict: 'blocker_id,blocked_id');
// // // // // // // // // //       // Also remove any existing friendship
// // // // // // // // // //       await removeFriend(
// // // // // // // // // //         userId: blockerId,
// // // // // // // // // //         friendId: blockedId,
// // // // // // // // // //       ).catchError((_) {});
// // // // // // // // // //       // Remove follow in both directions
// // // // // // // // // //       await unfollowUser(blockerId, blockedId).catchError((_) {});
// // // // // // // // // //       await unfollowUser(blockedId, blockerId).catchError((_) {});
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   Future<void> unblockUser({
// // // // // // // // // //     required String blockerId,
// // // // // // // // // //     required String blockedId,
// // // // // // // // // //   }) => guardedCall(
// // // // // // // // // //     operationName: 'unblockUser',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       await _supabase
// // // // // // // // // //           .from('blocked_users')
// // // // // // // // // //           .delete()
// // // // // // // // // //           .eq('blocker_id', blockerId)
// // // // // // // // // //           .eq('blocked_id', blockedId);
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   Future<List<FriendEntity>> getBlockedUsers(String userId) => guardedCall(
// // // // // // // // // //     operationName: 'getBlockedUsers',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       final rows = await _supabase
// // // // // // // // // //           .from('blocked_users')
// // // // // // // // // //           .select(
// // // // // // // // // //             'blocked_id,created_at,'
// // // // // // // // // //             'profiles!blocked_id(id,display_name,username,avatar_url)',
// // // // // // // // // //           )
// // // // // // // // // //           .eq('blocker_id', userId)
// // // // // // // // // //           .order('created_at', ascending: false);
// // // // // // // // // //       return rows.map((r) {
// // // // // // // // // //         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
// // // // // // // // // //         return FriendEntity(
// // // // // // // // // //           userId: profile['id'] as String? ?? '',
// // // // // // // // // //           displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // // //           username: profile['username'] as String?,
// // // // // // // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // //           status: FriendshipStatus.blocked,
// // // // // // // // // //           isRequester: true,
// // // // // // // // // //         );
// // // // // // // // // //       }).toList();
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   // ── Social profile ────────────────────────────────────────────────────────

// // // // // // // // // //   Future<SocialProfile> getSocialProfile({
// // // // // // // // // //     required String targetUserId,
// // // // // // // // // //     required String viewerUserId,
// // // // // // // // // //   }) => guardedCall(
// // // // // // // // // //     operationName: 'getSocialProfile',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       // Try profiles_public first (has bio + counts after migration)
// // // // // // // // // //       Map<String, dynamic>? profile = await _supabase
// // // // // // // // // //           .from('profiles_public')
// // // // // // // // // //           .select()
// // // // // // // // // //           .eq('id', targetUserId)
// // // // // // // // // //           .maybeSingle();

// // // // // // // // // //       // Fallback: profiles table directly (handles RLS edge cases)
// // // // // // // // // //       if (profile == null) {
// // // // // // // // // //         profile = await _supabase
// // // // // // // // // //             .from('profiles')
// // // // // // // // // //             .select('id, display_name, username, avatar_url, bio')
// // // // // // // // // //             .eq('id', targetUserId)
// // // // // // // // // //             .maybeSingle();
// // // // // // // // // //       }
// // // // // // // // // //       if (profile == null) throw Exception('Profile not found');

// // // // // // // // // //       // If we only got minimal data (no counts), return basic profile
// // // // // // // // // //       final hasFullData = profile.containsKey('followers_count');
// // // // // // // // // //       if (!hasFullData) {
// // // // // // // // // //         return SocialProfile(
// // // // // // // // // //           userId: profile['id'] as String,
// // // // // // // // // //           displayName: profile['display_name'] as String? ?? 'Player',
// // // // // // // // // //           username: profile['username'] as String?,
// // // // // // // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // //           bio: profile['bio'] as String?,
// // // // // // // // // //           followersCount: 0,
// // // // // // // // // //           followingCount: 0,
// // // // // // // // // //           friendsCount: 0,
// // // // // // // // // //         );
// // // // // // // // // //       }

// // // // // // // // // //       final [
// // // // // // // // // //         blockedByMe,
// // // // // // // // // //         blockedByThem,
// // // // // // // // // //         friendshipRow,
// // // // // // // // // //         followingRow,
// // // // // // // // // //         followedByRow,
// // // // // // // // // //       ] = await Future.wait([
// // // // // // // // // //         _supabase
// // // // // // // // // //             .from('blocked_users')
// // // // // // // // // //             .select('blocker_id')
// // // // // // // // // //             .eq('blocker_id', viewerUserId)
// // // // // // // // // //             .eq('blocked_id', targetUserId)
// // // // // // // // // //             .maybeSingle(),
// // // // // // // // // //         _supabase
// // // // // // // // // //             .from('blocked_users')
// // // // // // // // // //             .select('blocker_id')
// // // // // // // // // //             .eq('blocker_id', targetUserId)
// // // // // // // // // //             .eq('blocked_id', viewerUserId)
// // // // // // // // // //             .maybeSingle(),
// // // // // // // // // //         _supabase
// // // // // // // // // //             .from('friendships')
// // // // // // // // // //             .select('status')
// // // // // // // // // //             .or(
// // // // // // // // // //               'and(requester_id.eq.$viewerUserId,addressee_id.eq.$targetUserId),'
// // // // // // // // // //               'and(requester_id.eq.$targetUserId,addressee_id.eq.$viewerUserId)',
// // // // // // // // // //             )
// // // // // // // // // //             .maybeSingle(),
// // // // // // // // // //         _supabase
// // // // // // // // // //             .from('follows')
// // // // // // // // // //             .select('id')
// // // // // // // // // //             .eq('follower_id', viewerUserId)
// // // // // // // // // //             .eq('followee_id', targetUserId)
// // // // // // // // // //             .maybeSingle(),
// // // // // // // // // //         _supabase
// // // // // // // // // //             .from('follows')
// // // // // // // // // //             .select('id')
// // // // // // // // // //             .eq('follower_id', targetUserId)
// // // // // // // // // //             .eq('followee_id', viewerUserId)
// // // // // // // // // //             .maybeSingle(),
// // // // // // // // // //       ]);

// // // // // // // // // //       FriendshipStatus? friendStatus;
// // // // // // // // // //       if (friendshipRow != null) {
// // // // // // // // // //         friendStatus = FriendshipStatus.values.firstWhere(
// // // // // // // // // //           (s) => s.name == (friendshipRow as Map)['status'],
// // // // // // // // // //           orElse: () => FriendshipStatus.pending,
// // // // // // // // // //         );
// // // // // // // // // //       }

// // // // // // // // // //       return SocialProfile(
// // // // // // // // // //         userId: profile['id'] as String,
// // // // // // // // // //         displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // // //         username: profile['username'] as String?,
// // // // // // // // // //         avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // //         bio: profile['bio'] as String?,
// // // // // // // // // //         followersCount: profile['followers_count'] as int? ?? 0,
// // // // // // // // // //         followingCount: profile['following_count'] as int? ?? 0,
// // // // // // // // // //         friendsCount: profile['friends_count'] as int? ?? 0,
// // // // // // // // // //         friendshipStatus: friendStatus,
// // // // // // // // // //         isFollowing: followingRow != null,
// // // // // // // // // //         isFollowedBy: followedByRow != null,
// // // // // // // // // //         isBlocked: blockedByMe != null,
// // // // // // // // // //         isBlockedBy: blockedByThem != null,
// // // // // // // // // //         isVerified: profile['verification_status'] == 'verified',
// // // // // // // // // //       );
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   // ── Search ────────────────────────────────────────────────────────────────

// // // // // // // // // //   Future<List<UserEntity>> searchUsers(
// // // // // // // // // //     String query, {
// // // // // // // // // //     required String excludeUserId,
// // // // // // // // // //     int limit = 20,
// // // // // // // // // //   }) => guardedCall(
// // // // // // // // // //     operationName: 'searchUsers',
// // // // // // // // // //     operation: () async {
// // // // // // // // // //       final rows = await _supabase
// // // // // // // // // //           .from('profiles_public')
// // // // // // // // // //           .select('id,username,display_name,avatar_url')
// // // // // // // // // //           .or('username.ilike.%$query%,display_name.ilike.%$query%')
// // // // // // // // // //           .neq('id', excludeUserId)
// // // // // // // // // //           .limit(limit);
// // // // // // // // // //       return rows
// // // // // // // // // //           .map(
// // // // // // // // // //             (r) => UserEntity(
// // // // // // // // // //               id: r['id'] as String,
// // // // // // // // // //               email: '',
// // // // // // // // // //               username: r['username'] as String?,
// // // // // // // // // //               displayName: r['display_name'] as String?,
// // // // // // // // // //               avatarUrl: r['avatar_url'] as String?,
// // // // // // // // // //             ),
// // // // // // // // // //           )
// // // // // // // // // //           .toList();
// // // // // // // // // //     },
// // // // // // // // // //   );

// // // // // // // // // //   // ── Private helpers ───────────────────────────────────────────────────────

// // // // // // // // // //   Future<void> _checkNotBlocked(String a, String b) async {
// // // // // // // // // //     final block = await _supabase
// // // // // // // // // //         .from('blocked_users')
// // // // // // // // // //         .select('blocker_id')
// // // // // // // // // //         .or(
// // // // // // // // // //           'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // // // // // // // // //           'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // // // // // // // // //         )
// // // // // // // // // //         .maybeSingle();
// // // // // // // // // //     if (block != null) {
// // // // // // // // // //       throw const ForbiddenFailure(message: 'Cannot interact with this user.');
// // // // // // // // // //     }
// // // // // // // // // //   }

// // // // // // // // // //   FriendEntity _toFriendEntity(Map<String, dynamic> row, String currentUserId) {
// // // // // // // // // //     final requesterId = row['requester_id'] as String? ?? '';
// // // // // // // // // //     final isRequester = requesterId == currentUserId;
// // // // // // // // // //     final rawOther = isRequester ? row['addressee'] : row['requester'];
// // // // // // // // // //     final other = (rawOther is Map)
// // // // // // // // // //         ? Map<String, dynamic>.from(rawOther)
// // // // // // // // // //         : <String, dynamic>{};
// // // // // // // // // //     return FriendEntity(
// // // // // // // // // //       friendshipId: row['id'] as String?,
// // // // // // // // // //       userId: other['id'] as String? ?? '',
// // // // // // // // // //       displayName: other['display_name'] as String? ?? 'Player',
// // // // // // // // // //       username: other['username'] as String?,
// // // // // // // // // //       avatarUrl: other['avatar_url'] as String?,
// // // // // // // // // //       status: FriendshipStatus.values.firstWhere(
// // // // // // // // // //         (s) => s.name == (row['status'] as String? ?? ''),
// // // // // // // // // //         orElse: () => FriendshipStatus.pending,
// // // // // // // // // //       ),
// // // // // // // // // //       isRequester: isRequester,
// // // // // // // // // //     );
// // // // // // // // // //   }

// // // // // // // // // //   FollowEntity _toFollowEntity(
// // // // // // // // // //     Map<String, dynamic> row, {
// // // // // // // // // //     bool followingMode = false,
// // // // // // // // // //   }) {
// // // // // // // // // //     final profile =
// // // // // // // // // //         row[followingMode ? 'profiles!followee_id' : 'profiles!follower_id']
// // // // // // // // // //             as Map<String, dynamic>? ??
// // // // // // // // // //         {};
// // // // // // // // // //     return FollowEntity(
// // // // // // // // // //       userId: profile['id'] as String? ?? '',
// // // // // // // // // //       displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // // //       username: profile['username'] as String?,
// // // // // // // // // //       avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // // //       followedAt: DateTime.parse(row['created_at'] as String),
// // // // // // // // // //       isVerified: profile['verification_status'] == 'verified',
// // // // // // // // // //     );
// // // // // // // // // //   }
// // // // // // // // // // }

// // // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // // // import '../../../core/data/base_repository.dart';
// // // // // // // // // import '../../../core/errors/failures.dart';
// // // // // // // // // import '../../../features/auth/domain/entities/user_entity.dart';

// // // // // // // // // // ── Domain types ──────────────────────────────────────────────────────────────

// // // // // // // // // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // // // // // // // // class FriendEntity {
// // // // // // // // //   const FriendEntity({
// // // // // // // // //     required this.userId,
// // // // // // // // //     required this.displayName,
// // // // // // // // //     this.username,
// // // // // // // // //     this.avatarUrl,
// // // // // // // // //     required this.status,
// // // // // // // // //     required this.isRequester,
// // // // // // // // //     this.mutualFriendsCount = 0,
// // // // // // // // //     this.friendshipId,
// // // // // // // // //   });

// // // // // // // // //   final String userId;
// // // // // // // // //   final String displayName;
// // // // // // // // //   final String? username;
// // // // // // // // //   final String? avatarUrl;
// // // // // // // // //   final FriendshipStatus status;
// // // // // // // // //   final bool isRequester;
// // // // // // // // //   final int mutualFriendsCount;
// // // // // // // // //   final String? friendshipId;

// // // // // // // // //   bool get isAccepted => status == FriendshipStatus.accepted;
// // // // // // // // //   bool get isPending => status == FriendshipStatus.pending;
// // // // // // // // // }

// // // // // // // // // class FollowEntity {
// // // // // // // // //   const FollowEntity({
// // // // // // // // //     required this.userId,
// // // // // // // // //     required this.displayName,
// // // // // // // // //     this.username,
// // // // // // // // //     this.avatarUrl,
// // // // // // // // //     required this.followedAt,
// // // // // // // // //     this.isVerified = false,
// // // // // // // // //   });

// // // // // // // // //   final String userId;
// // // // // // // // //   final String displayName;
// // // // // // // // //   final String? username;
// // // // // // // // //   final String? avatarUrl;
// // // // // // // // //   final DateTime followedAt;
// // // // // // // // //   final bool isVerified;
// // // // // // // // // }

// // // // // // // // // class SocialProfile {
// // // // // // // // //   const SocialProfile({
// // // // // // // // //     required this.userId,
// // // // // // // // //     required this.displayName,
// // // // // // // // //     this.username,
// // // // // // // // //     this.avatarUrl,
// // // // // // // // //     this.bio,
// // // // // // // // //     required this.followersCount,
// // // // // // // // //     required this.followingCount,
// // // // // // // // //     required this.friendsCount,
// // // // // // // // //     this.friendshipStatus,
// // // // // // // // //     this.isFollowing = false,
// // // // // // // // //     this.isFollowedBy = false,
// // // // // // // // //     this.isBlocked = false,
// // // // // // // // //     this.isBlockedBy = false,
// // // // // // // // //     this.isVerified = false,
// // // // // // // // //   });

// // // // // // // // //   final String userId;
// // // // // // // // //   final String displayName;
// // // // // // // // //   final String? username;
// // // // // // // // //   final String? avatarUrl;
// // // // // // // // //   final String? bio;
// // // // // // // // //   final int followersCount;
// // // // // // // // //   final int followingCount;
// // // // // // // // //   final int friendsCount;
// // // // // // // // //   final FriendshipStatus? friendshipStatus;
// // // // // // // // //   final bool isFollowing;
// // // // // // // // //   final bool isFollowedBy;
// // // // // // // // //   final bool isBlocked;
// // // // // // // // //   final bool isBlockedBy;
// // // // // // // // //   final bool isVerified;

// // // // // // // // //   bool get canInteract => !isBlocked && !isBlockedBy;
// // // // // // // // // }

// // // // // // // // // // ── Repository ────────────────────────────────────────────────────────────────

// // // // // // // // // class FriendsRepository extends BaseRepository {
// // // // // // // // //   FriendsRepository._();
// // // // // // // // //   static final FriendsRepository _instance = FriendsRepository._();
// // // // // // // // //   static FriendsRepository get instance => _instance;

// // // // // // // // //   final _supabase = Supabase.instance.client;

// // // // // // // // //   // ── Friends ───────────────────────────────────────────────────────────────

// // // // // // // // //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// // // // // // // // //     operationName: 'getFriends',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final rows = await _supabase
// // // // // // // // //           .from('friendships')
// // // // // // // // //           .select(
// // // // // // // // //             'id,status,requester_id,addressee_id,'
// // // // // // // // //             'requester:profiles!requester_id(id,display_name,username,avatar_url),'
// // // // // // // // //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url)',
// // // // // // // // //           )
// // // // // // // // //           .or('requester_id.eq.$userId,addressee_id.eq.$userId')
// // // // // // // // //           .eq('status', 'accepted');
// // // // // // // // //       return rows.map((r) => _toFriendEntity(r, userId)).toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<List<FriendEntity>> getPendingRequests(String userId) => guardedCall(
// // // // // // // // //     operationName: 'getPendingRequests',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final rows = await _supabase
// // // // // // // // //           .from('friendships')
// // // // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // // // //           .eq('addressee_id', userId)
// // // // // // // // //           .eq('status', 'pending');
// // // // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // // // //       // Fetch requester profiles separately to avoid join ambiguity
// // // // // // // // //       final requesterIds = rows
// // // // // // // // //           .map((r) => r['requester_id'] as String)
// // // // // // // // //           .toList();
// // // // // // // // //       final profiles = await _supabase
// // // // // // // // //           .from('profiles')
// // // // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // // // //           .inFilter('id', requesterIds);
// // // // // // // // //       final profileMap = {
// // // // // // // // //         for (final p in profiles as List)
// // // // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // // // //       };
// // // // // // // // //       return rows.map((r) {
// // // // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // // // //         row['requester'] = profileMap[row['requester_id']] ?? {};
// // // // // // // // //         return _toFriendEntity(row, userId);
// // // // // // // // //       }).toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<List<FriendEntity>> getSentRequests(String userId) => guardedCall(
// // // // // // // // //     operationName: 'getSentRequests',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final rows = await _supabase
// // // // // // // // //           .from('friendships')
// // // // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // // // //           .eq('requester_id', userId)
// // // // // // // // //           .eq('status', 'pending');
// // // // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // // // //       // Fetch addressee profiles separately
// // // // // // // // //       final addresseeIds = rows
// // // // // // // // //           .map((r) => r['addressee_id'] as String)
// // // // // // // // //           .toList();
// // // // // // // // //       final profiles = await _supabase
// // // // // // // // //           .from('profiles')
// // // // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // // // //           .inFilter('id', addresseeIds);
// // // // // // // // //       final profileMap = {
// // // // // // // // //         for (final p in profiles as List)
// // // // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // // // //       };
// // // // // // // // //       return rows.map((r) {
// // // // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // // // //         row['addressee'] = profileMap[row['addressee_id']] ?? {};
// // // // // // // // //         return _toFriendEntity(row, userId);
// // // // // // // // //       }).toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<void> sendFriendRequest({
// // // // // // // // //     required String requesterId,
// // // // // // // // //     required String addresseeId,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'sendFriendRequest',
// // // // // // // // //     operation: () async {
// // // // // // // // //       // Check not blocked
// // // // // // // // //       await _checkNotBlocked(requesterId, addresseeId);
// // // // // // // // //       await _supabase.from('friendships').insert({
// // // // // // // // //         'requester_id': requesterId,
// // // // // // // // //         'addressee_id': addresseeId,
// // // // // // // // //         'status': 'pending',
// // // // // // // // //       });
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<void> respondToRequest({
// // // // // // // // //     required String requesterId,
// // // // // // // // //     required String addresseeId,
// // // // // // // // //     required bool accept,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'respondToRequest',
// // // // // // // // //     operation: () async {
// // // // // // // // //       await _supabase
// // // // // // // // //           .from('friendships')
// // // // // // // // //           .update({'status': accept ? 'accepted' : 'rejected'})
// // // // // // // // //           .eq('requester_id', requesterId)
// // // // // // // // //           .eq('addressee_id', addresseeId);
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<void> removeFriend({
// // // // // // // // //     required String userId,
// // // // // // // // //     required String friendId,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'removeFriend',
// // // // // // // // //     operation: () async {
// // // // // // // // //       await _supabase
// // // // // // // // //           .from('friendships')
// // // // // // // // //           .delete()
// // // // // // // // //           .or(
// // // // // // // // //             'and(requester_id.eq.$userId,addressee_id.eq.$friendId),'
// // // // // // // // //             'and(requester_id.eq.$friendId,addressee_id.eq.$userId)',
// // // // // // // // //           );
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<void> cancelRequest({
// // // // // // // // //     required String requesterId,
// // // // // // // // //     required String addresseeId,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'cancelRequest',
// // // // // // // // //     operation: () async {
// // // // // // // // //       await _supabase
// // // // // // // // //           .from('friendships')
// // // // // // // // //           .delete()
// // // // // // // // //           .eq('requester_id', requesterId)
// // // // // // // // //           .eq('addressee_id', addresseeId)
// // // // // // // // //           .eq('status', 'pending');
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   // ── Follow system ─────────────────────────────────────────────────────────

// // // // // // // // //   Future<void> followUser(String followerId, String followingId) => guardedCall(
// // // // // // // // //     operationName: 'followUser',
// // // // // // // // //     operation: () async {
// // // // // // // // //       await _checkNotBlocked(followerId, followingId);
// // // // // // // // //       await _supabase.from('follows').upsert({
// // // // // // // // //         'follower_id': followerId,
// // // // // // // // //         'followee_id': followingId,
// // // // // // // // //       }, onConflict: 'follower_id,followee_id');
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<void> unfollowUser(String followerId, String followingId) =>
// // // // // // // // //       guardedCall(
// // // // // // // // //         operationName: 'unfollowUser',
// // // // // // // // //         operation: () async {
// // // // // // // // //           await _supabase
// // // // // // // // //               .from('follows')
// // // // // // // // //               .delete()
// // // // // // // // //               .eq('follower_id', followerId)
// // // // // // // // //               .eq('followee_id', followingId);
// // // // // // // // //         },
// // // // // // // // //       );

// // // // // // // // //   Future<List<FollowEntity>> getFollowers(
// // // // // // // // //     String userId, {
// // // // // // // // //     int limit = 50,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'getFollowers',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final rows = await _supabase
// // // // // // // // //           .from('follows')
// // // // // // // // //           .select(
// // // // // // // // //             'follower_id,created_at,'
// // // // // // // // //             'profiles!follower_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // // // //           )
// // // // // // // // //           .eq('followee_id', userId)
// // // // // // // // //           .order('created_at', ascending: false)
// // // // // // // // //           .limit(limit);
// // // // // // // // //       return rows.map(_toFollowEntity).toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<List<FollowEntity>> getFollowing(
// // // // // // // // //     String userId, {
// // // // // // // // //     int limit = 50,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'getFollowing',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final rows = await _supabase
// // // // // // // // //           .from('follows')
// // // // // // // // //           .select(
// // // // // // // // //             'followee_id,created_at,'
// // // // // // // // //             'profiles!followee_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // // // //           )
// // // // // // // // //           .eq('follower_id', userId)
// // // // // // // // //           .order('created_at', ascending: false)
// // // // // // // // //           .limit(limit);
// // // // // // // // //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   // ── Block system ──────────────────────────────────────────────────────────

// // // // // // // // //   Future<void> blockUser({
// // // // // // // // //     required String blockerId,
// // // // // // // // //     required String blockedId,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'blockUser',
// // // // // // // // //     operation: () async {
// // // // // // // // //       await _supabase.from('blocked_users').upsert({
// // // // // // // // //         'blocker_id': blockerId,
// // // // // // // // //         'blocked_id': blockedId,
// // // // // // // // //       }, onConflict: 'blocker_id,blocked_id');
// // // // // // // // //       // Also remove any existing friendship
// // // // // // // // //       await removeFriend(
// // // // // // // // //         userId: blockerId,
// // // // // // // // //         friendId: blockedId,
// // // // // // // // //       ).catchError((_) {});
// // // // // // // // //       // Remove follow in both directions
// // // // // // // // //       await unfollowUser(blockerId, blockedId).catchError((_) {});
// // // // // // // // //       await unfollowUser(blockedId, blockerId).catchError((_) {});
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<void> unblockUser({
// // // // // // // // //     required String blockerId,
// // // // // // // // //     required String blockedId,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'unblockUser',
// // // // // // // // //     operation: () async {
// // // // // // // // //       await _supabase
// // // // // // // // //           .from('blocked_users')
// // // // // // // // //           .delete()
// // // // // // // // //           .eq('blocker_id', blockerId)
// // // // // // // // //           .eq('blocked_id', blockedId);
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<List<FriendEntity>> getBlockedUsers(String userId) => guardedCall(
// // // // // // // // //     operationName: 'getBlockedUsers',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final rows = await _supabase
// // // // // // // // //           .from('blocked_users')
// // // // // // // // //           .select(
// // // // // // // // //             'blocked_id,created_at,'
// // // // // // // // //             'profiles!blocked_id(id,display_name,username,avatar_url)',
// // // // // // // // //           )
// // // // // // // // //           .eq('blocker_id', userId)
// // // // // // // // //           .order('created_at', ascending: false);
// // // // // // // // //       return rows.map((r) {
// // // // // // // // //         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
// // // // // // // // //         return FriendEntity(
// // // // // // // // //           userId: profile['id'] as String? ?? '',
// // // // // // // // //           displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // //           username: profile['username'] as String?,
// // // // // // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // //           status: FriendshipStatus.blocked,
// // // // // // // // //           isRequester: true,
// // // // // // // // //         );
// // // // // // // // //       }).toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   // ── Social profile ────────────────────────────────────────────────────────

// // // // // // // // //   Future<SocialProfile> getSocialProfile({
// // // // // // // // //     required String targetUserId,
// // // // // // // // //     required String viewerUserId,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'getSocialProfile',
// // // // // // // // //     operation: () async {
// // // // // // // // //       // Try profiles_public first (has bio + counts after migration)
// // // // // // // // //       // Use limit(1) to guard against duplicate rows in view/table
// // // // // // // // //       final profileRows = await _supabase
// // // // // // // // //           .from('profiles_public')
// // // // // // // // //           .select()
// // // // // // // // //           .eq('id', targetUserId)
// // // // // // // // //           .limit(1);
// // // // // // // // //       Map<String, dynamic>? profile = profileRows.isNotEmpty
// // // // // // // // //           ? profileRows.first as Map<String, dynamic>
// // // // // // // // //           : null;

// // // // // // // // //       // Fallback: profiles table directly
// // // // // // // // //       if (profile == null) {
// // // // // // // // //         final fallbackRows = await _supabase
// // // // // // // // //             .from('profiles')
// // // // // // // // //             .select('id, display_name, username, avatar_url, bio')
// // // // // // // // //             .eq('id', targetUserId)
// // // // // // // // //             .limit(1);
// // // // // // // // //         profile = fallbackRows.isNotEmpty
// // // // // // // // //             ? fallbackRows.first as Map<String, dynamic>
// // // // // // // // //             : null;
// // // // // // // // //       }
// // // // // // // // //       if (profile == null) throw Exception('Profile not found');

// // // // // // // // //       // If we only got minimal data (no counts), return basic profile
// // // // // // // // //       final hasFullData = profile.containsKey('followers_count');
// // // // // // // // //       if (!hasFullData) {
// // // // // // // // //         return SocialProfile(
// // // // // // // // //           userId: profile['id'] as String,
// // // // // // // // //           displayName: profile['display_name'] as String? ?? 'Player',
// // // // // // // // //           username: profile['username'] as String?,
// // // // // // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // //           bio: profile['bio'] as String?,
// // // // // // // // //           followersCount: 0,
// // // // // // // // //           followingCount: 0,
// // // // // // // // //           friendsCount: 0,
// // // // // // // // //         );
// // // // // // // // //       }

// // // // // // // // //       final [
// // // // // // // // //         blockedByMe,
// // // // // // // // //         blockedByThem,
// // // // // // // // //         friendshipRow,
// // // // // // // // //         followingRow,
// // // // // // // // //         followedByRow,
// // // // // // // // //       ] = await Future.wait([
// // // // // // // // //         _supabase
// // // // // // // // //             .from('blocked_users')
// // // // // // // // //             .select('blocker_id')
// // // // // // // // //             .eq('blocker_id', viewerUserId)
// // // // // // // // //             .eq('blocked_id', targetUserId)
// // // // // // // // //             .maybeSingle(),
// // // // // // // // //         _supabase
// // // // // // // // //             .from('blocked_users')
// // // // // // // // //             .select('blocker_id')
// // // // // // // // //             .eq('blocker_id', targetUserId)
// // // // // // // // //             .eq('blocked_id', viewerUserId)
// // // // // // // // //             .maybeSingle(),
// // // // // // // // //         _supabase
// // // // // // // // //             .from('friendships')
// // // // // // // // //             .select('status')
// // // // // // // // //             .or(
// // // // // // // // //               'and(requester_id.eq.$viewerUserId,addressee_id.eq.$targetUserId),'
// // // // // // // // //               'and(requester_id.eq.$targetUserId,addressee_id.eq.$viewerUserId)',
// // // // // // // // //             )
// // // // // // // // //             .maybeSingle(),
// // // // // // // // //         _supabase
// // // // // // // // //             .from('follows')
// // // // // // // // //             .select('id')
// // // // // // // // //             .eq('follower_id', viewerUserId)
// // // // // // // // //             .eq('followee_id', targetUserId)
// // // // // // // // //             .maybeSingle(),
// // // // // // // // //         _supabase
// // // // // // // // //             .from('follows')
// // // // // // // // //             .select('id')
// // // // // // // // //             .eq('follower_id', targetUserId)
// // // // // // // // //             .eq('followee_id', viewerUserId)
// // // // // // // // //             .maybeSingle(),
// // // // // // // // //       ]);

// // // // // // // // //       FriendshipStatus? friendStatus;
// // // // // // // // //       if (friendshipRow != null) {
// // // // // // // // //         friendStatus = FriendshipStatus.values.firstWhere(
// // // // // // // // //           (s) => s.name == (friendshipRow as Map)['status'],
// // // // // // // // //           orElse: () => FriendshipStatus.pending,
// // // // // // // // //         );
// // // // // // // // //       }

// // // // // // // // //       return SocialProfile(
// // // // // // // // //         userId: profile['id'] as String,
// // // // // // // // //         displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // //         username: profile['username'] as String?,
// // // // // // // // //         avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // //         bio: profile['bio'] as String?,
// // // // // // // // //         followersCount: profile['followers_count'] as int? ?? 0,
// // // // // // // // //         followingCount: profile['following_count'] as int? ?? 0,
// // // // // // // // //         friendsCount: profile['friends_count'] as int? ?? 0,
// // // // // // // // //         friendshipStatus: friendStatus,
// // // // // // // // //         isFollowing: followingRow != null,
// // // // // // // // //         isFollowedBy: followedByRow != null,
// // // // // // // // //         isBlocked: blockedByMe != null,
// // // // // // // // //         isBlockedBy: blockedByThem != null,
// // // // // // // // //         isVerified: profile['verification_status'] == 'verified',
// // // // // // // // //       );
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   // ── Search ────────────────────────────────────────────────────────────────

// // // // // // // // //   Future<List<UserEntity>> searchUsers(
// // // // // // // // //     String query, {
// // // // // // // // //     required String excludeUserId,
// // // // // // // // //     int limit = 20,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'searchUsers',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final rows = await _supabase
// // // // // // // // //           .from('profiles_public')
// // // // // // // // //           .select('id,username,display_name,avatar_url')
// // // // // // // // //           .or('username.ilike.%$query%,display_name.ilike.%$query%')
// // // // // // // // //           .neq('id', excludeUserId)
// // // // // // // // //           .limit(limit);
// // // // // // // // //       return rows
// // // // // // // // //           .map(
// // // // // // // // //             (r) => UserEntity(
// // // // // // // // //               id: r['id'] as String,
// // // // // // // // //               email: '',
// // // // // // // // //               username: r['username'] as String?,
// // // // // // // // //               displayName: r['display_name'] as String?,
// // // // // // // // //               avatarUrl: r['avatar_url'] as String?,
// // // // // // // // //             ),
// // // // // // // // //           )
// // // // // // // // //           .toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   // ── Private helpers ───────────────────────────────────────────────────────

// // // // // // // // //   Future<void> _checkNotBlocked(String a, String b) async {
// // // // // // // // //     final block = await _supabase
// // // // // // // // //         .from('blocked_users')
// // // // // // // // //         .select('blocker_id')
// // // // // // // // //         .or(
// // // // // // // // //           'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // // // // // // // //           'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // // // // // // // //         )
// // // // // // // // //         .maybeSingle();
// // // // // // // // //     if (block != null) {
// // // // // // // // //       throw const ForbiddenFailure(message: 'Cannot interact with this user.');
// // // // // // // // //     }
// // // // // // // // //   }

// // // // // // // // //   FriendEntity _toFriendEntity(Map<String, dynamic> row, String currentUserId) {
// // // // // // // // //     final requesterId = row['requester_id'] as String? ?? '';
// // // // // // // // //     final isRequester = requesterId == currentUserId;
// // // // // // // // //     final rawOther = isRequester ? row['addressee'] : row['requester'];
// // // // // // // // //     final other = (rawOther is Map)
// // // // // // // // //         ? Map<String, dynamic>.from(rawOther)
// // // // // // // // //         : <String, dynamic>{};
// // // // // // // // //     return FriendEntity(
// // // // // // // // //       friendshipId: row['id'] as String?,
// // // // // // // // //       userId: other['id'] as String? ?? '',
// // // // // // // // //       displayName: other['display_name'] as String? ?? 'Player',
// // // // // // // // //       username: other['username'] as String?,
// // // // // // // // //       avatarUrl: other['avatar_url'] as String?,
// // // // // // // // //       status: FriendshipStatus.values.firstWhere(
// // // // // // // // //         (s) => s.name == (row['status'] as String? ?? ''),
// // // // // // // // //         orElse: () => FriendshipStatus.pending,
// // // // // // // // //       ),
// // // // // // // // //       isRequester: isRequester,
// // // // // // // // //     );
// // // // // // // // //   }

// // // // // // // // //   FollowEntity _toFollowEntity(
// // // // // // // // //     Map<String, dynamic> row, {
// // // // // // // // //     bool followingMode = false,
// // // // // // // // //   }) {
// // // // // // // // //     final profile =
// // // // // // // // //         row[followingMode ? 'profiles!followee_id' : 'profiles!follower_id']
// // // // // // // // //             as Map<String, dynamic>? ??
// // // // // // // // //         {};
// // // // // // // // //     return FollowEntity(
// // // // // // // // //       userId: profile['id'] as String? ?? '',
// // // // // // // // //       displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // // //       username: profile['username'] as String?,
// // // // // // // // //       avatarUrl: profile['avatar_url'] as String?,
// // // // // // // // //       followedAt: DateTime.parse(row['created_at'] as String),
// // // // // // // // //       isVerified: profile['verification_status'] == 'verified',
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // // import '../../../core/data/base_repository.dart';
// // // // // // // // import '../../../core/errors/failures.dart';
// // // // // // // // import '../../../features/auth/domain/entities/user_entity.dart';

// // // // // // // // // ── Domain types ──────────────────────────────────────────────────────────────

// // // // // // // // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // // // // // // // class FriendEntity {
// // // // // // // //   const FriendEntity({
// // // // // // // //     required this.userId,
// // // // // // // //     required this.displayName,
// // // // // // // //     this.username,
// // // // // // // //     this.avatarUrl,
// // // // // // // //     required this.status,
// // // // // // // //     required this.isRequester,
// // // // // // // //     this.mutualFriendsCount = 0,
// // // // // // // //     this.friendshipId,
// // // // // // // //   });

// // // // // // // //   final String userId;
// // // // // // // //   final String displayName;
// // // // // // // //   final String? username;
// // // // // // // //   final String? avatarUrl;
// // // // // // // //   final FriendshipStatus status;
// // // // // // // //   final bool isRequester;
// // // // // // // //   final int mutualFriendsCount;
// // // // // // // //   final String? friendshipId;

// // // // // // // //   bool get isAccepted => status == FriendshipStatus.accepted;
// // // // // // // //   bool get isPending => status == FriendshipStatus.pending;
// // // // // // // // }

// // // // // // // // class FollowEntity {
// // // // // // // //   const FollowEntity({
// // // // // // // //     required this.userId,
// // // // // // // //     required this.displayName,
// // // // // // // //     this.username,
// // // // // // // //     this.avatarUrl,
// // // // // // // //     required this.followedAt,
// // // // // // // //     this.isVerified = false,
// // // // // // // //   });

// // // // // // // //   final String userId;
// // // // // // // //   final String displayName;
// // // // // // // //   final String? username;
// // // // // // // //   final String? avatarUrl;
// // // // // // // //   final DateTime followedAt;
// // // // // // // //   final bool isVerified;
// // // // // // // // }

// // // // // // // // class SocialProfile {
// // // // // // // //   const SocialProfile({
// // // // // // // //     required this.userId,
// // // // // // // //     required this.displayName,
// // // // // // // //     this.username,
// // // // // // // //     this.avatarUrl,
// // // // // // // //     this.bio,
// // // // // // // //     required this.followersCount,
// // // // // // // //     required this.followingCount,
// // // // // // // //     required this.friendsCount,
// // // // // // // //     this.gamesPlayed = 0,
// // // // // // // //     this.packsCount = 0,
// // // // // // // //     this.friendshipStatus,
// // // // // // // //     this.isFollowing = false,
// // // // // // // //     this.isFollowedBy = false,
// // // // // // // //     this.isBlocked = false,
// // // // // // // //     this.isBlockedBy = false,
// // // // // // // //     this.isVerified = false,
// // // // // // // //   });

// // // // // // // //   final String userId;
// // // // // // // //   final String displayName;
// // // // // // // //   final String? username;
// // // // // // // //   final String? avatarUrl;
// // // // // // // //   final String? bio;
// // // // // // // //   final int followersCount;
// // // // // // // //   final int followingCount;
// // // // // // // //   final int friendsCount;
// // // // // // // //   final int gamesPlayed;
// // // // // // // //   final int packsCount;
// // // // // // // //   final FriendshipStatus? friendshipStatus;
// // // // // // // //   final bool isFollowing;
// // // // // // // //   final bool isFollowedBy;
// // // // // // // //   final bool isBlocked;
// // // // // // // //   final bool isBlockedBy;
// // // // // // // //   final bool isVerified;

// // // // // // // //   bool get canInteract => !isBlocked && !isBlockedBy;
// // // // // // // // }

// // // // // // // // // ── Repository ────────────────────────────────────────────────────────────────

// // // // // // // // class FriendsRepository extends BaseRepository {
// // // // // // // //   FriendsRepository._();
// // // // // // // //   static final FriendsRepository _instance = FriendsRepository._();
// // // // // // // //   static FriendsRepository get instance => _instance;

// // // // // // // //   final _supabase = Supabase.instance.client;

// // // // // // // //   // ── Friends ───────────────────────────────────────────────────────────────

// // // // // // // //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// // // // // // // //     operationName: 'getFriends',
// // // // // // // //     operation: () async {
// // // // // // // //       final rows = await _supabase
// // // // // // // //           .from('friendships')
// // // // // // // //           .select(
// // // // // // // //             'id,status,requester_id,addressee_id,'
// // // // // // // //             'requester:profiles!requester_id(id,display_name,username,avatar_url),'
// // // // // // // //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url)',
// // // // // // // //           )
// // // // // // // //           .or('requester_id.eq.$userId,addressee_id.eq.$userId')
// // // // // // // //           .eq('status', 'accepted');
// // // // // // // //       return rows.map((r) => _toFriendEntity(r, userId)).toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<List<FriendEntity>> getPendingRequests(String userId) => guardedCall(
// // // // // // // //     operationName: 'getPendingRequests',
// // // // // // // //     operation: () async {
// // // // // // // //       final rows = await _supabase
// // // // // // // //           .from('friendships')
// // // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // // //           .eq('addressee_id', userId)
// // // // // // // //           .eq('status', 'pending');
// // // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // // //       // Fetch requester profiles separately to avoid join ambiguity
// // // // // // // //       final requesterIds = rows
// // // // // // // //           .map((r) => r['requester_id'] as String)
// // // // // // // //           .toList();
// // // // // // // //       final profiles = await _supabase
// // // // // // // //           .from('profiles')
// // // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // // //           .inFilter('id', requesterIds);
// // // // // // // //       final profileMap = {
// // // // // // // //         for (final p in profiles as List)
// // // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // // //       };
// // // // // // // //       return rows.map((r) {
// // // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // // //         row['requester'] = profileMap[row['requester_id']] ?? {};
// // // // // // // //         return _toFriendEntity(row, userId);
// // // // // // // //       }).toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<List<FriendEntity>> getSentRequests(String userId) => guardedCall(
// // // // // // // //     operationName: 'getSentRequests',
// // // // // // // //     operation: () async {
// // // // // // // //       final rows = await _supabase
// // // // // // // //           .from('friendships')
// // // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // // //           .eq('requester_id', userId)
// // // // // // // //           .eq('status', 'pending');
// // // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // // //       // Fetch addressee profiles separately
// // // // // // // //       final addresseeIds = rows
// // // // // // // //           .map((r) => r['addressee_id'] as String)
// // // // // // // //           .toList();
// // // // // // // //       final profiles = await _supabase
// // // // // // // //           .from('profiles')
// // // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // // //           .inFilter('id', addresseeIds);
// // // // // // // //       final profileMap = {
// // // // // // // //         for (final p in profiles as List)
// // // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // // //       };
// // // // // // // //       return rows.map((r) {
// // // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // // //         row['addressee'] = profileMap[row['addressee_id']] ?? {};
// // // // // // // //         return _toFriendEntity(row, userId);
// // // // // // // //       }).toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<void> sendFriendRequest({
// // // // // // // //     required String requesterId,
// // // // // // // //     required String addresseeId,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'sendFriendRequest',
// // // // // // // //     operation: () async {
// // // // // // // //       // Check not blocked
// // // // // // // //       await _checkNotBlocked(requesterId, addresseeId);
// // // // // // // //       await _supabase.from('friendships').insert({
// // // // // // // //         'requester_id': requesterId,
// // // // // // // //         'addressee_id': addresseeId,
// // // // // // // //         'status': 'pending',
// // // // // // // //       });
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<void> respondToRequest({
// // // // // // // //     required String requesterId,
// // // // // // // //     required String addresseeId,
// // // // // // // //     required bool accept,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'respondToRequest',
// // // // // // // //     operation: () async {
// // // // // // // //       await _supabase
// // // // // // // //           .from('friendships')
// // // // // // // //           .update({'status': accept ? 'accepted' : 'rejected'})
// // // // // // // //           .eq('requester_id', requesterId)
// // // // // // // //           .eq('addressee_id', addresseeId);
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<void> removeFriend({
// // // // // // // //     required String userId,
// // // // // // // //     required String friendId,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'removeFriend',
// // // // // // // //     operation: () async {
// // // // // // // //       await _supabase
// // // // // // // //           .from('friendships')
// // // // // // // //           .delete()
// // // // // // // //           .or(
// // // // // // // //             'and(requester_id.eq.$userId,addressee_id.eq.$friendId),'
// // // // // // // //             'and(requester_id.eq.$friendId,addressee_id.eq.$userId)',
// // // // // // // //           );
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<void> cancelRequest({
// // // // // // // //     required String requesterId,
// // // // // // // //     required String addresseeId,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'cancelRequest',
// // // // // // // //     operation: () async {
// // // // // // // //       await _supabase
// // // // // // // //           .from('friendships')
// // // // // // // //           .delete()
// // // // // // // //           .eq('requester_id', requesterId)
// // // // // // // //           .eq('addressee_id', addresseeId)
// // // // // // // //           .eq('status', 'pending');
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   // ── Follow system ─────────────────────────────────────────────────────────

// // // // // // // //   Future<void> followUser(String followerId, String followingId) => guardedCall(
// // // // // // // //     operationName: 'followUser',
// // // // // // // //     operation: () async {
// // // // // // // //       await _checkNotBlocked(followerId, followingId);
// // // // // // // //       await _supabase.from('follows').upsert({
// // // // // // // //         'follower_id': followerId,
// // // // // // // //         'followee_id': followingId,
// // // // // // // //       }, onConflict: 'follower_id,followee_id');
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<void> unfollowUser(String followerId, String followingId) =>
// // // // // // // //       guardedCall(
// // // // // // // //         operationName: 'unfollowUser',
// // // // // // // //         operation: () async {
// // // // // // // //           await _supabase
// // // // // // // //               .from('follows')
// // // // // // // //               .delete()
// // // // // // // //               .eq('follower_id', followerId)
// // // // // // // //               .eq('followee_id', followingId);
// // // // // // // //         },
// // // // // // // //       );

// // // // // // // //   Future<List<FollowEntity>> getFollowers(
// // // // // // // //     String userId, {
// // // // // // // //     int limit = 50,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'getFollowers',
// // // // // // // //     operation: () async {
// // // // // // // //       final rows = await _supabase
// // // // // // // //           .from('follows')
// // // // // // // //           .select(
// // // // // // // //             'follower_id,created_at,'
// // // // // // // //             'profiles!follower_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // // //           )
// // // // // // // //           .eq('followee_id', userId)
// // // // // // // //           .order('created_at', ascending: false)
// // // // // // // //           .limit(limit);
// // // // // // // //       return rows.map(_toFollowEntity).toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<List<FollowEntity>> getFollowing(
// // // // // // // //     String userId, {
// // // // // // // //     int limit = 50,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'getFollowing',
// // // // // // // //     operation: () async {
// // // // // // // //       final rows = await _supabase
// // // // // // // //           .from('follows')
// // // // // // // //           .select(
// // // // // // // //             'followee_id,created_at,'
// // // // // // // //             'profiles!followee_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // // //           )
// // // // // // // //           .eq('follower_id', userId)
// // // // // // // //           .order('created_at', ascending: false)
// // // // // // // //           .limit(limit);
// // // // // // // //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   // ── Block system ──────────────────────────────────────────────────────────

// // // // // // // //   Future<void> blockUser({
// // // // // // // //     required String blockerId,
// // // // // // // //     required String blockedId,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'blockUser',
// // // // // // // //     operation: () async {
// // // // // // // //       await _supabase.from('blocked_users').upsert({
// // // // // // // //         'blocker_id': blockerId,
// // // // // // // //         'blocked_id': blockedId,
// // // // // // // //       }, onConflict: 'blocker_id,blocked_id');
// // // // // // // //       // Also remove any existing friendship
// // // // // // // //       await removeFriend(
// // // // // // // //         userId: blockerId,
// // // // // // // //         friendId: blockedId,
// // // // // // // //       ).catchError((_) {});
// // // // // // // //       // Remove follow in both directions
// // // // // // // //       await unfollowUser(blockerId, blockedId).catchError((_) {});
// // // // // // // //       await unfollowUser(blockedId, blockerId).catchError((_) {});
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<void> unblockUser({
// // // // // // // //     required String blockerId,
// // // // // // // //     required String blockedId,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'unblockUser',
// // // // // // // //     operation: () async {
// // // // // // // //       await _supabase
// // // // // // // //           .from('blocked_users')
// // // // // // // //           .delete()
// // // // // // // //           .eq('blocker_id', blockerId)
// // // // // // // //           .eq('blocked_id', blockedId);
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<List<FriendEntity>> getBlockedUsers(String userId) => guardedCall(
// // // // // // // //     operationName: 'getBlockedUsers',
// // // // // // // //     operation: () async {
// // // // // // // //       final rows = await _supabase
// // // // // // // //           .from('blocked_users')
// // // // // // // //           .select(
// // // // // // // //             'blocked_id,created_at,'
// // // // // // // //             'profiles!blocked_id(id,display_name,username,avatar_url)',
// // // // // // // //           )
// // // // // // // //           .eq('blocker_id', userId)
// // // // // // // //           .order('created_at', ascending: false);
// // // // // // // //       return rows.map((r) {
// // // // // // // //         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
// // // // // // // //         return FriendEntity(
// // // // // // // //           userId: profile['id'] as String? ?? '',
// // // // // // // //           displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // //           username: profile['username'] as String?,
// // // // // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // // // // //           status: FriendshipStatus.blocked,
// // // // // // // //           isRequester: true,
// // // // // // // //         );
// // // // // // // //       }).toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   // ── Social profile ────────────────────────────────────────────────────────

// // // // // // // //   Future<SocialProfile> getSocialProfile({
// // // // // // // //     required String targetUserId,
// // // // // // // //     required String viewerUserId,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'getSocialProfile',
// // // // // // // //     operation: () async {
// // // // // // // //       // Try profiles_public first (has bio + counts after migration)
// // // // // // // //       // Use limit(1) to guard against duplicate rows in view/table
// // // // // // // //       final profileRows = await _supabase
// // // // // // // //           .from('profiles_public')
// // // // // // // //           .select()
// // // // // // // //           .eq('id', targetUserId)
// // // // // // // //           .limit(1);
// // // // // // // //       Map<String, dynamic>? profile = profileRows.isNotEmpty
// // // // // // // //           ? profileRows.first as Map<String, dynamic>
// // // // // // // //           : null;

// // // // // // // //       // Fallback: profiles table directly
// // // // // // // //       if (profile == null) {
// // // // // // // //         final fallbackRows = await _supabase
// // // // // // // //             .from('profiles')
// // // // // // // //             .select('id, display_name, username, avatar_url, bio')
// // // // // // // //             .eq('id', targetUserId)
// // // // // // // //             .limit(1);
// // // // // // // //         profile = fallbackRows.isNotEmpty
// // // // // // // //             ? fallbackRows.first as Map<String, dynamic>
// // // // // // // //             : null;
// // // // // // // //       }
// // // // // // // //       if (profile == null) throw Exception('Profile not found');

// // // // // // // //       // If we only got minimal data (no counts), return basic profile
// // // // // // // //       final hasFullData = profile.containsKey('followers_count');
// // // // // // // //       if (!hasFullData) {
// // // // // // // //         return SocialProfile(
// // // // // // // //           userId: profile['id'] as String,
// // // // // // // //           displayName: profile['display_name'] as String? ?? 'Player',
// // // // // // // //           username: profile['username'] as String?,
// // // // // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // // // // //           bio: profile['bio'] as String?,
// // // // // // // //           followersCount: 0,
// // // // // // // //           followingCount: 0,
// // // // // // // //           friendsCount: 0,
// // // // // // // //           gamesPlayed: 0,
// // // // // // // //           packsCount: 0,
// // // // // // // //         );
// // // // // // // //       }

// // // // // // // //       final [
// // // // // // // //         blockedByMe,
// // // // // // // //         blockedByThem,
// // // // // // // //         friendshipRow,
// // // // // // // //         followingRow,
// // // // // // // //         followedByRow,
// // // // // // // //       ] = await Future.wait([
// // // // // // // //         _supabase
// // // // // // // //             .from('blocked_users')
// // // // // // // //             .select('blocker_id')
// // // // // // // //             .eq('blocker_id', viewerUserId)
// // // // // // // //             .eq('blocked_id', targetUserId)
// // // // // // // //             .maybeSingle(),
// // // // // // // //         _supabase
// // // // // // // //             .from('blocked_users')
// // // // // // // //             .select('blocker_id')
// // // // // // // //             .eq('blocker_id', targetUserId)
// // // // // // // //             .eq('blocked_id', viewerUserId)
// // // // // // // //             .maybeSingle(),
// // // // // // // //         _supabase
// // // // // // // //             .from('friendships')
// // // // // // // //             .select('status')
// // // // // // // //             .or(
// // // // // // // //               'and(requester_id.eq.$viewerUserId,addressee_id.eq.$targetUserId),'
// // // // // // // //               'and(requester_id.eq.$targetUserId,addressee_id.eq.$viewerUserId)',
// // // // // // // //             )
// // // // // // // //             .maybeSingle(),
// // // // // // // //         _supabase
// // // // // // // //             .from('follows')
// // // // // // // //             .select('id')
// // // // // // // //             .eq('follower_id', viewerUserId)
// // // // // // // //             .eq('followee_id', targetUserId)
// // // // // // // //             .maybeSingle(),
// // // // // // // //         _supabase
// // // // // // // //             .from('follows')
// // // // // // // //             .select('id')
// // // // // // // //             .eq('follower_id', targetUserId)
// // // // // // // //             .eq('followee_id', viewerUserId)
// // // // // // // //             .maybeSingle(),
// // // // // // // //       ]);

// // // // // // // //       FriendshipStatus? friendStatus;
// // // // // // // //       if (friendshipRow != null) {
// // // // // // // //         friendStatus = FriendshipStatus.values.firstWhere(
// // // // // // // //           (s) => s.name == (friendshipRow as Map)['status'],
// // // // // // // //           orElse: () => FriendshipStatus.pending,
// // // // // // // //         );
// // // // // // // //       }

// // // // // // // //       return SocialProfile(
// // // // // // // //         userId: profile['id'] as String,
// // // // // // // //         displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // //         username: profile['username'] as String?,
// // // // // // // //         avatarUrl: profile['avatar_url'] as String?,
// // // // // // // //         bio: profile['bio'] as String?,
// // // // // // // //         followersCount: (profile['followers_count'] as num?)?.toInt() ?? 0,
// // // // // // // //         followingCount: (profile['following_count'] as num?)?.toInt() ?? 0,
// // // // // // // //         friendsCount: (profile['friends_count'] as num?)?.toInt() ?? 0,
// // // // // // // //         gamesPlayed: (profile['games_played'] as num?)?.toInt() ?? 0,
// // // // // // // //         packsCount: (profile['packs_count'] as num?)?.toInt() ?? 0,
// // // // // // // //         friendshipStatus: friendStatus,
// // // // // // // //         isFollowing: followingRow != null,
// // // // // // // //         isFollowedBy: followedByRow != null,
// // // // // // // //         isBlocked: blockedByMe != null,
// // // // // // // //         isBlockedBy: blockedByThem != null,
// // // // // // // //         isVerified: profile['verification_status'] == 'verified',
// // // // // // // //       );
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   // ── Search ────────────────────────────────────────────────────────────────

// // // // // // // //   Future<List<UserEntity>> searchUsers(
// // // // // // // //     String query, {
// // // // // // // //     required String excludeUserId,
// // // // // // // //     int limit = 20,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'searchUsers',
// // // // // // // //     operation: () async {
// // // // // // // //       final rows = await _supabase
// // // // // // // //           .from('profiles_public')
// // // // // // // //           .select('id,username,display_name,avatar_url')
// // // // // // // //           .or('username.ilike.%$query%,display_name.ilike.%$query%')
// // // // // // // //           .neq('id', excludeUserId)
// // // // // // // //           .limit(limit);
// // // // // // // //       return rows
// // // // // // // //           .map(
// // // // // // // //             (r) => UserEntity(
// // // // // // // //               id: r['id'] as String,
// // // // // // // //               email: '',
// // // // // // // //               username: r['username'] as String?,
// // // // // // // //               displayName: r['display_name'] as String?,
// // // // // // // //               avatarUrl: r['avatar_url'] as String?,
// // // // // // // //             ),
// // // // // // // //           )
// // // // // // // //           .toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   // ── Private helpers ───────────────────────────────────────────────────────

// // // // // // // //   Future<void> _checkNotBlocked(String a, String b) async {
// // // // // // // //     final block = await _supabase
// // // // // // // //         .from('blocked_users')
// // // // // // // //         .select('blocker_id')
// // // // // // // //         .or(
// // // // // // // //           'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // // // // // // //           'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // // // // // // //         )
// // // // // // // //         .maybeSingle();
// // // // // // // //     if (block != null) {
// // // // // // // //       throw const ForbiddenFailure(message: 'Cannot interact with this user.');
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   FriendEntity _toFriendEntity(Map<String, dynamic> row, String currentUserId) {
// // // // // // // //     final requesterId = row['requester_id'] as String? ?? '';
// // // // // // // //     final isRequester = requesterId == currentUserId;
// // // // // // // //     final rawOther = isRequester ? row['addressee'] : row['requester'];
// // // // // // // //     final other = (rawOther is Map)
// // // // // // // //         ? Map<String, dynamic>.from(rawOther)
// // // // // // // //         : <String, dynamic>{};
// // // // // // // //     return FriendEntity(
// // // // // // // //       friendshipId: row['id'] as String?,
// // // // // // // //       userId: other['id'] as String? ?? '',
// // // // // // // //       displayName: other['display_name'] as String? ?? 'Player',
// // // // // // // //       username: other['username'] as String?,
// // // // // // // //       avatarUrl: other['avatar_url'] as String?,
// // // // // // // //       status: FriendshipStatus.values.firstWhere(
// // // // // // // //         (s) => s.name == (row['status'] as String? ?? ''),
// // // // // // // //         orElse: () => FriendshipStatus.pending,
// // // // // // // //       ),
// // // // // // // //       isRequester: isRequester,
// // // // // // // //     );
// // // // // // // //   }

// // // // // // // //   FollowEntity _toFollowEntity(
// // // // // // // //     Map<String, dynamic> row, {
// // // // // // // //     bool followingMode = false,
// // // // // // // //   }) {
// // // // // // // //     final profile =
// // // // // // // //         row[followingMode ? 'profiles!followee_id' : 'profiles!follower_id']
// // // // // // // //             as Map<String, dynamic>? ??
// // // // // // // //         {};
// // // // // // // //     return FollowEntity(
// // // // // // // //       userId: profile['id'] as String? ?? '',
// // // // // // // //       displayName: profile['display_name'] as String? ?? 'User',
// // // // // // // //       username: profile['username'] as String?,
// // // // // // // //       avatarUrl: profile['avatar_url'] as String?,
// // // // // // // //       followedAt: DateTime.parse(row['created_at'] as String),
// // // // // // // //       isVerified: profile['verification_status'] == 'verified',
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // import '../../../core/data/base_repository.dart';
// // // // // // // import '../../../core/errors/failures.dart';
// // // // // // // import '../../../features/auth/domain/entities/user_entity.dart';

// // // // // // // // ── Domain types ──────────────────────────────────────────────────────────────

// // // // // // // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // // // // // // class FriendEntity {
// // // // // // //   const FriendEntity({
// // // // // // //     required this.userId,
// // // // // // //     required this.displayName,
// // // // // // //     this.username,
// // // // // // //     this.avatarUrl,
// // // // // // //     required this.status,
// // // // // // //     required this.isRequester,
// // // // // // //     this.mutualFriendsCount = 0,
// // // // // // //     this.friendshipId,
// // // // // // //   });

// // // // // // //   final String userId;
// // // // // // //   final String displayName;
// // // // // // //   final String? username;
// // // // // // //   final String? avatarUrl;
// // // // // // //   final FriendshipStatus status;
// // // // // // //   final bool isRequester;
// // // // // // //   final int mutualFriendsCount;
// // // // // // //   final String? friendshipId;

// // // // // // //   bool get isAccepted => status == FriendshipStatus.accepted;
// // // // // // //   bool get isPending => status == FriendshipStatus.pending;
// // // // // // // }

// // // // // // // class FollowEntity {
// // // // // // //   const FollowEntity({
// // // // // // //     required this.userId,
// // // // // // //     required this.displayName,
// // // // // // //     this.username,
// // // // // // //     this.avatarUrl,
// // // // // // //     required this.followedAt,
// // // // // // //     this.isVerified = false,
// // // // // // //   });

// // // // // // //   final String userId;
// // // // // // //   final String displayName;
// // // // // // //   final String? username;
// // // // // // //   final String? avatarUrl;
// // // // // // //   final DateTime followedAt;
// // // // // // //   final bool isVerified;
// // // // // // // }

// // // // // // // class SocialProfile {
// // // // // // //   const SocialProfile({
// // // // // // //     required this.userId,
// // // // // // //     required this.displayName,
// // // // // // //     this.username,
// // // // // // //     this.avatarUrl,
// // // // // // //     this.bio,
// // // // // // //     required this.followersCount,
// // // // // // //     required this.followingCount,
// // // // // // //     required this.friendsCount,
// // // // // // //     this.gamesPlayed = 0,
// // // // // // //     this.packsCount = 0,
// // // // // // //     this.friendshipStatus,
// // // // // // //     this.isFollowing = false,
// // // // // // //     this.isFollowedBy = false,
// // // // // // //     this.isBlocked = false,
// // // // // // //     this.isBlockedBy = false,
// // // // // // //     this.isVerified = false,
// // // // // // //   });

// // // // // // //   final String userId;
// // // // // // //   final String displayName;
// // // // // // //   final String? username;
// // // // // // //   final String? avatarUrl;
// // // // // // //   final String? bio;
// // // // // // //   final int followersCount;
// // // // // // //   final int followingCount;
// // // // // // //   final int friendsCount;
// // // // // // //   final int gamesPlayed;
// // // // // // //   final int packsCount;
// // // // // // //   final FriendshipStatus? friendshipStatus;
// // // // // // //   final bool isFollowing;
// // // // // // //   final bool isFollowedBy;
// // // // // // //   final bool isBlocked;
// // // // // // //   final bool isBlockedBy;
// // // // // // //   final bool isVerified;

// // // // // // //   bool get canInteract => !isBlocked && !isBlockedBy;
// // // // // // // }

// // // // // // // // ── Repository ────────────────────────────────────────────────────────────────

// // // // // // // class FriendsRepository extends BaseRepository {
// // // // // // //   FriendsRepository._();
// // // // // // //   static final FriendsRepository _instance = FriendsRepository._();
// // // // // // //   static FriendsRepository get instance => _instance;

// // // // // // //   final _supabase = Supabase.instance.client;

// // // // // // //   // ── Friends ───────────────────────────────────────────────────────────────

// // // // // // //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// // // // // // //     operationName: 'getFriends',
// // // // // // //     operation: () async {
// // // // // // //       final rows = await _supabase
// // // // // // //           .from('friendships')
// // // // // // //           .select(
// // // // // // //             'id,status,requester_id,addressee_id,'
// // // // // // //             'requester:profiles!requester_id(id,display_name,username,avatar_url),'
// // // // // // //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url)',
// // // // // // //           )
// // // // // // //           .or('requester_id.eq.$userId,addressee_id.eq.$userId')
// // // // // // //           .eq('status', 'accepted');
// // // // // // //       return rows.map((r) => _toFriendEntity(r, userId)).toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<List<FriendEntity>> getPendingRequests(String userId) => guardedCall(
// // // // // // //     operationName: 'getPendingRequests',
// // // // // // //     operation: () async {
// // // // // // //       final rows = await _supabase
// // // // // // //           .from('friendships')
// // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // //           .eq('addressee_id', userId)
// // // // // // //           .eq('status', 'pending');
// // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // //       // Fetch requester profiles separately to avoid join ambiguity
// // // // // // //       final requesterIds = rows
// // // // // // //           .map((r) => r['requester_id'] as String)
// // // // // // //           .toList();
// // // // // // //       final profiles = await _supabase
// // // // // // //           .from('profiles')
// // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // //           .inFilter('id', requesterIds);
// // // // // // //       final profileMap = {
// // // // // // //         for (final p in profiles as List)
// // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // //       };
// // // // // // //       return rows.map((r) {
// // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // //         row['requester'] = profileMap[row['requester_id']] ?? {};
// // // // // // //         return _toFriendEntity(row, userId);
// // // // // // //       }).toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<List<FriendEntity>> getSentRequests(String userId) => guardedCall(
// // // // // // //     operationName: 'getSentRequests',
// // // // // // //     operation: () async {
// // // // // // //       final rows = await _supabase
// // // // // // //           .from('friendships')
// // // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // // //           .eq('requester_id', userId)
// // // // // // //           .eq('status', 'pending');
// // // // // // //       if ((rows as List).isEmpty) return [];
// // // // // // //       // Fetch addressee profiles separately
// // // // // // //       final addresseeIds = rows
// // // // // // //           .map((r) => r['addressee_id'] as String)
// // // // // // //           .toList();
// // // // // // //       final profiles = await _supabase
// // // // // // //           .from('profiles')
// // // // // // //           .select('id,display_name,username,avatar_url')
// // // // // // //           .inFilter('id', addresseeIds);
// // // // // // //       final profileMap = {
// // // // // // //         for (final p in profiles as List)
// // // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // // //       };
// // // // // // //       return rows.map((r) {
// // // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // // //         row['addressee'] = profileMap[row['addressee_id']] ?? {};
// // // // // // //         return _toFriendEntity(row, userId);
// // // // // // //       }).toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<void> sendFriendRequest({
// // // // // // //     required String requesterId,
// // // // // // //     required String addresseeId,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'sendFriendRequest',
// // // // // // //     operation: () async {
// // // // // // //       // Check not blocked
// // // // // // //       await _checkNotBlocked(requesterId, addresseeId);
// // // // // // //       await _supabase.from('friendships').insert({
// // // // // // //         'requester_id': requesterId,
// // // // // // //         'addressee_id': addresseeId,
// // // // // // //         'status': 'pending',
// // // // // // //       });
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<void> respondToRequest({
// // // // // // //     required String requesterId,
// // // // // // //     required String addresseeId,
// // // // // // //     required bool accept,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'respondToRequest',
// // // // // // //     operation: () async {
// // // // // // //       await _supabase
// // // // // // //           .from('friendships')
// // // // // // //           .update({'status': accept ? 'accepted' : 'rejected'})
// // // // // // //           .eq('requester_id', requesterId)
// // // // // // //           .eq('addressee_id', addresseeId);
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<void> removeFriend({
// // // // // // //     required String userId,
// // // // // // //     required String friendId,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'removeFriend',
// // // // // // //     operation: () async {
// // // // // // //       await _supabase
// // // // // // //           .from('friendships')
// // // // // // //           .delete()
// // // // // // //           .or(
// // // // // // //             'and(requester_id.eq.$userId,addressee_id.eq.$friendId),'
// // // // // // //             'and(requester_id.eq.$friendId,addressee_id.eq.$userId)',
// // // // // // //           );
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<void> cancelRequest({
// // // // // // //     required String requesterId,
// // // // // // //     required String addresseeId,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'cancelRequest',
// // // // // // //     operation: () async {
// // // // // // //       await _supabase
// // // // // // //           .from('friendships')
// // // // // // //           .delete()
// // // // // // //           .eq('requester_id', requesterId)
// // // // // // //           .eq('addressee_id', addresseeId)
// // // // // // //           .eq('status', 'pending');
// // // // // // //     },
// // // // // // //   );

// // // // // // //   // ── Follow system ─────────────────────────────────────────────────────────

// // // // // // //   Future<void> followUser(String followerId, String followingId) => guardedCall(
// // // // // // //     operationName: 'followUser',
// // // // // // //     operation: () async {
// // // // // // //       await _checkNotBlocked(followerId, followingId);
// // // // // // //       await _supabase.from('follows').upsert({
// // // // // // //         'follower_id': followerId,
// // // // // // //         'followee_id': followingId,
// // // // // // //       }, onConflict: 'follower_id,followee_id');
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<void> unfollowUser(String followerId, String followingId) =>
// // // // // // //       guardedCall(
// // // // // // //         operationName: 'unfollowUser',
// // // // // // //         operation: () async {
// // // // // // //           await _supabase
// // // // // // //               .from('follows')
// // // // // // //               .delete()
// // // // // // //               .eq('follower_id', followerId)
// // // // // // //               .eq('followee_id', followingId);
// // // // // // //         },
// // // // // // //       );

// // // // // // //   Future<List<FollowEntity>> getFollowers(
// // // // // // //     String userId, {
// // // // // // //     int limit = 50,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'getFollowers',
// // // // // // //     operation: () async {
// // // // // // //       final rows = await _supabase
// // // // // // //           .from('follows')
// // // // // // //           .select(
// // // // // // //             'follower_id,created_at,'
// // // // // // //             'profiles!follower_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // //           )
// // // // // // //           .eq('followee_id', userId)
// // // // // // //           .order('created_at', ascending: false)
// // // // // // //           .limit(limit);
// // // // // // //       return rows.map(_toFollowEntity).toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<List<FollowEntity>> getFollowing(
// // // // // // //     String userId, {
// // // // // // //     int limit = 50,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'getFollowing',
// // // // // // //     operation: () async {
// // // // // // //       final rows = await _supabase
// // // // // // //           .from('follows')
// // // // // // //           .select(
// // // // // // //             'followee_id,created_at,'
// // // // // // //             'profiles!followee_id(id,display_name,username,avatar_url,verification_status)',
// // // // // // //           )
// // // // // // //           .eq('follower_id', userId)
// // // // // // //           .order('created_at', ascending: false)
// // // // // // //           .limit(limit);
// // // // // // //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   // ── Block system ──────────────────────────────────────────────────────────

// // // // // // //   Future<void> blockUser({
// // // // // // //     required String blockerId,
// // // // // // //     required String blockedId,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'blockUser',
// // // // // // //     operation: () async {
// // // // // // //       await _supabase.from('blocked_users').upsert({
// // // // // // //         'blocker_id': blockerId,
// // // // // // //         'blocked_id': blockedId,
// // // // // // //       }, onConflict: 'blocker_id,blocked_id');
// // // // // // //       // Also remove any existing friendship
// // // // // // //       await removeFriend(
// // // // // // //         userId: blockerId,
// // // // // // //         friendId: blockedId,
// // // // // // //       ).catchError((_) {});
// // // // // // //       // Remove follow in both directions
// // // // // // //       await unfollowUser(blockerId, blockedId).catchError((_) {});
// // // // // // //       await unfollowUser(blockedId, blockerId).catchError((_) {});
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<void> unblockUser({
// // // // // // //     required String blockerId,
// // // // // // //     required String blockedId,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'unblockUser',
// // // // // // //     operation: () async {
// // // // // // //       await _supabase
// // // // // // //           .from('blocked_users')
// // // // // // //           .delete()
// // // // // // //           .eq('blocker_id', blockerId)
// // // // // // //           .eq('blocked_id', blockedId);
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<List<FriendEntity>> getBlockedUsers(String userId) => guardedCall(
// // // // // // //     operationName: 'getBlockedUsers',
// // // // // // //     operation: () async {
// // // // // // //       final rows = await _supabase
// // // // // // //           .from('blocked_users')
// // // // // // //           .select(
// // // // // // //             'blocked_id,created_at,'
// // // // // // //             'profiles!blocked_id(id,display_name,username,avatar_url)',
// // // // // // //           )
// // // // // // //           .eq('blocker_id', userId)
// // // // // // //           .order('created_at', ascending: false);
// // // // // // //       return rows.map((r) {
// // // // // // //         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
// // // // // // //         return FriendEntity(
// // // // // // //           userId: profile['id'] as String? ?? '',
// // // // // // //           displayName: profile['display_name'] as String? ?? 'User',
// // // // // // //           username: profile['username'] as String?,
// // // // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // // // //           status: FriendshipStatus.blocked,
// // // // // // //           isRequester: true,
// // // // // // //         );
// // // // // // //       }).toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   // ── Social profile ────────────────────────────────────────────────────────

// // // // // // //   Future<SocialProfile> getSocialProfile({
// // // // // // //     required String targetUserId,
// // // // // // //     required String viewerUserId,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'getSocialProfile',
// // // // // // //     operation: () async {
// // // // // // //       // Try profiles_public first (has bio + counts after migration)
// // // // // // //       // Use limit(1) to guard against duplicate rows in view/table
// // // // // // //       final profileRows = await _supabase
// // // // // // //           .from('profiles_public')
// // // // // // //           .select()
// // // // // // //           .eq('id', targetUserId)
// // // // // // //           .limit(1);
// // // // // // //       Map<String, dynamic>? profile = profileRows.isNotEmpty
// // // // // // //           ? profileRows.first as Map<String, dynamic>
// // // // // // //           : null;

// // // // // // //       // Fallback: profiles table directly
// // // // // // //       if (profile == null) {
// // // // // // //         final fallbackRows = await _supabase
// // // // // // //             .from('profiles')
// // // // // // //             .select('id, display_name, username, avatar_url, bio')
// // // // // // //             .eq('id', targetUserId)
// // // // // // //             .limit(1);
// // // // // // //         profile = fallbackRows.isNotEmpty
// // // // // // //             ? fallbackRows.first as Map<String, dynamic>
// // // // // // //             : null;
// // // // // // //       }
// // // // // // //       if (profile == null) throw Exception('Profile not found');

// // // // // // //       // If we only got minimal data (no counts), return basic profile
// // // // // // //       final hasFullData = profile.containsKey('followers_count');
// // // // // // //       if (!hasFullData) {
// // // // // // //         return SocialProfile(
// // // // // // //           userId: profile['id'] as String,
// // // // // // //           displayName: profile['display_name'] as String? ?? 'Player',
// // // // // // //           username: profile['username'] as String?,
// // // // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // // // //           bio: profile['bio'] as String?,
// // // // // // //           followersCount: 0,
// // // // // // //           followingCount: 0,
// // // // // // //           friendsCount: 0,
// // // // // // //           gamesPlayed: 0,
// // // // // // //           packsCount: 0,
// // // // // // //         );
// // // // // // //       }

// // // // // // //       final [
// // // // // // //         blockedByMe,
// // // // // // //         blockedByThem,
// // // // // // //         friendshipRow,
// // // // // // //         followingRow,
// // // // // // //         followedByRow,
// // // // // // //       ] = await Future.wait([
// // // // // // //         _supabase
// // // // // // //             .from('blocked_users')
// // // // // // //             .select('blocker_id')
// // // // // // //             .eq('blocker_id', viewerUserId)
// // // // // // //             .eq('blocked_id', targetUserId)
// // // // // // //             .maybeSingle(),
// // // // // // //         _supabase
// // // // // // //             .from('blocked_users')
// // // // // // //             .select('blocker_id')
// // // // // // //             .eq('blocker_id', targetUserId)
// // // // // // //             .eq('blocked_id', viewerUserId)
// // // // // // //             .maybeSingle(),
// // // // // // //         _supabase
// // // // // // //             .from('friendships')
// // // // // // //             .select('status')
// // // // // // //             .or(
// // // // // // //               'and(requester_id.eq.$viewerUserId,addressee_id.eq.$targetUserId),'
// // // // // // //               'and(requester_id.eq.$targetUserId,addressee_id.eq.$viewerUserId)',
// // // // // // //             )
// // // // // // //             .maybeSingle(),
// // // // // // //         _supabase
// // // // // // //             .from('follows')
// // // // // // //             .select('follower_id')
// // // // // // //             .eq('follower_id', viewerUserId)
// // // // // // //             .eq('followee_id', targetUserId)
// // // // // // //             .maybeSingle(),
// // // // // // //         _supabase
// // // // // // //             .from('follows')
// // // // // // //             .select('follower_id')
// // // // // // //             .eq('follower_id', targetUserId)
// // // // // // //             .eq('followee_id', viewerUserId)
// // // // // // //             .maybeSingle(),
// // // // // // //       ]);

// // // // // // //       FriendshipStatus? friendStatus;
// // // // // // //       if (friendshipRow != null) {
// // // // // // //         friendStatus = FriendshipStatus.values.firstWhere(
// // // // // // //           (s) => s.name == (friendshipRow as Map)['status'],
// // // // // // //           orElse: () => FriendshipStatus.pending,
// // // // // // //         );
// // // // // // //       }

// // // // // // //       return SocialProfile(
// // // // // // //         userId: profile['id'] as String,
// // // // // // //         displayName: profile['display_name'] as String? ?? 'User',
// // // // // // //         username: profile['username'] as String?,
// // // // // // //         avatarUrl: profile['avatar_url'] as String?,
// // // // // // //         bio: profile['bio'] as String?,
// // // // // // //         followersCount: (profile['followers_count'] as num?)?.toInt() ?? 0,
// // // // // // //         followingCount: (profile['following_count'] as num?)?.toInt() ?? 0,
// // // // // // //         friendsCount: (profile['friends_count'] as num?)?.toInt() ?? 0,
// // // // // // //         gamesPlayed: (profile['games_played'] as num?)?.toInt() ?? 0,
// // // // // // //         packsCount: (profile['packs_count'] as num?)?.toInt() ?? 0,
// // // // // // //         friendshipStatus: friendStatus,
// // // // // // //         isFollowing: followingRow != null,
// // // // // // //         isFollowedBy: followedByRow != null,
// // // // // // //         isBlocked: blockedByMe != null,
// // // // // // //         isBlockedBy: blockedByThem != null,
// // // // // // //         isVerified: profile['verification_status'] == 'verified',
// // // // // // //       );
// // // // // // //     },
// // // // // // //   );

// // // // // // //   // ── Search ────────────────────────────────────────────────────────────────

// // // // // // //   Future<List<UserEntity>> searchUsers(
// // // // // // //     String query, {
// // // // // // //     required String excludeUserId,
// // // // // // //     int limit = 20,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'searchUsers',
// // // // // // //     operation: () async {
// // // // // // //       final rows = await _supabase
// // // // // // //           .from('profiles_public')
// // // // // // //           .select('id,username,display_name,avatar_url')
// // // // // // //           .or('username.ilike.%$query%,display_name.ilike.%$query%')
// // // // // // //           .neq('id', excludeUserId)
// // // // // // //           .limit(limit);
// // // // // // //       return rows
// // // // // // //           .map(
// // // // // // //             (r) => UserEntity(
// // // // // // //               id: r['id'] as String,
// // // // // // //               email: '',
// // // // // // //               username: r['username'] as String?,
// // // // // // //               displayName: r['display_name'] as String?,
// // // // // // //               avatarUrl: r['avatar_url'] as String?,
// // // // // // //             ),
// // // // // // //           )
// // // // // // //           .toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   // ── Private helpers ───────────────────────────────────────────────────────

// // // // // // //   Future<void> _checkNotBlocked(String a, String b) async {
// // // // // // //     final block = await _supabase
// // // // // // //         .from('blocked_users')
// // // // // // //         .select('blocker_id')
// // // // // // //         .or(
// // // // // // //           'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // // // // // //           'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // // // // // //         )
// // // // // // //         .maybeSingle();
// // // // // // //     if (block != null) {
// // // // // // //       throw const ForbiddenFailure(message: 'Cannot interact with this user.');
// // // // // // //     }
// // // // // // //   }

// // // // // // //   FriendEntity _toFriendEntity(Map<String, dynamic> row, String currentUserId) {
// // // // // // //     final requesterId = row['requester_id'] as String? ?? '';
// // // // // // //     final isRequester = requesterId == currentUserId;
// // // // // // //     final rawOther = isRequester ? row['addressee'] : row['requester'];
// // // // // // //     final other = (rawOther is Map)
// // // // // // //         ? Map<String, dynamic>.from(rawOther)
// // // // // // //         : <String, dynamic>{};
// // // // // // //     return FriendEntity(
// // // // // // //       friendshipId: row['id'] as String?,
// // // // // // //       userId: other['id'] as String? ?? '',
// // // // // // //       displayName: other['display_name'] as String? ?? 'Player',
// // // // // // //       username: other['username'] as String?,
// // // // // // //       avatarUrl: other['avatar_url'] as String?,
// // // // // // //       status: FriendshipStatus.values.firstWhere(
// // // // // // //         (s) => s.name == (row['status'] as String? ?? ''),
// // // // // // //         orElse: () => FriendshipStatus.pending,
// // // // // // //       ),
// // // // // // //       isRequester: isRequester,
// // // // // // //     );
// // // // // // //   }

// // // // // // //   FollowEntity _toFollowEntity(
// // // // // // //     Map<String, dynamic> row, {
// // // // // // //     bool followingMode = false,
// // // // // // //   }) {
// // // // // // //     final profile =
// // // // // // //         row[followingMode ? 'profiles!followee_id' : 'profiles!follower_id']
// // // // // // //             as Map<String, dynamic>? ??
// // // // // // //         {};
// // // // // // //     return FollowEntity(
// // // // // // //       userId: profile['id'] as String? ?? '',
// // // // // // //       displayName: profile['display_name'] as String? ?? 'User',
// // // // // // //       username: profile['username'] as String?,
// // // // // // //       avatarUrl: profile['avatar_url'] as String?,
// // // // // // //       followedAt: DateTime.parse(row['created_at'] as String),
// // // // // // //       isVerified: profile['verification_status'] == 'verified',
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // import '../../../core/data/base_repository.dart';
// // // // // // import '../../../core/errors/failures.dart';
// // // // // // import '../../../features/auth/domain/entities/user_entity.dart';

// // // // // // // ── Domain types ──────────────────────────────────────────────────────────────

// // // // // // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // // // // // class FriendEntity {
// // // // // //   const FriendEntity({
// // // // // //     required this.userId,
// // // // // //     required this.displayName,
// // // // // //     this.username,
// // // // // //     this.avatarUrl,
// // // // // //     required this.status,
// // // // // //     required this.isRequester,
// // // // // //     this.mutualFriendsCount = 0,
// // // // // //     this.friendshipId,
// // // // // //   });

// // // // // //   final String userId;
// // // // // //   final String displayName;
// // // // // //   final String? username;
// // // // // //   final String? avatarUrl;
// // // // // //   final FriendshipStatus status;
// // // // // //   final bool isRequester;
// // // // // //   final int mutualFriendsCount;
// // // // // //   final String? friendshipId;

// // // // // //   bool get isAccepted => status == FriendshipStatus.accepted;
// // // // // //   bool get isPending => status == FriendshipStatus.pending;
// // // // // // }

// // // // // // class FollowEntity {
// // // // // //   const FollowEntity({
// // // // // //     required this.userId,
// // // // // //     required this.displayName,
// // // // // //     this.username,
// // // // // //     this.avatarUrl,
// // // // // //     required this.followedAt,
// // // // // //     this.isVerified = false,
// // // // // //   });

// // // // // //   final String userId;
// // // // // //   final String displayName;
// // // // // //   final String? username;
// // // // // //   final String? avatarUrl;
// // // // // //   final DateTime followedAt;
// // // // // //   final bool isVerified;
// // // // // // }

// // // // // // class SocialProfile {
// // // // // //   const SocialProfile({
// // // // // //     required this.userId,
// // // // // //     required this.displayName,
// // // // // //     this.username,
// // // // // //     this.avatarUrl,
// // // // // //     this.bio,
// // // // // //     required this.followersCount,
// // // // // //     required this.followingCount,
// // // // // //     required this.friendsCount,
// // // // // //     this.gamesPlayed = 0,
// // // // // //     this.packsCount = 0,
// // // // // //     this.friendshipStatus,
// // // // // //     this.isFollowing = false,
// // // // // //     this.isFollowedBy = false,
// // // // // //     this.isBlocked = false,
// // // // // //     this.isBlockedBy = false,
// // // // // //     this.isVerified = false,
// // // // // //   });

// // // // // //   final String userId;
// // // // // //   final String displayName;
// // // // // //   final String? username;
// // // // // //   final String? avatarUrl;
// // // // // //   final String? bio;
// // // // // //   final int followersCount;
// // // // // //   final int followingCount;
// // // // // //   final int friendsCount;
// // // // // //   final int gamesPlayed;
// // // // // //   final int packsCount;
// // // // // //   final FriendshipStatus? friendshipStatus;
// // // // // //   final bool isFollowing;
// // // // // //   final bool isFollowedBy;
// // // // // //   final bool isBlocked;
// // // // // //   final bool isBlockedBy;
// // // // // //   final bool isVerified;

// // // // // //   bool get canInteract => !isBlocked && !isBlockedBy;
// // // // // // }

// // // // // // // ── Repository ────────────────────────────────────────────────────────────────

// // // // // // class FriendsRepository extends BaseRepository {
// // // // // //   FriendsRepository._();
// // // // // //   static final FriendsRepository _instance = FriendsRepository._();
// // // // // //   static FriendsRepository get instance => _instance;

// // // // // //   final _supabase = Supabase.instance.client;

// // // // // //   // ── Friends ───────────────────────────────────────────────────────────────

// // // // // //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// // // // // //     operationName: 'getFriends',
// // // // // //     operation: () async {
// // // // // //       final rows = await _supabase
// // // // // //           .from('friendships')
// // // // // //           .select(
// // // // // //             'id,status,requester_id,addressee_id,'
// // // // // //             'requester:profiles!requester_id(id,display_name,username,avatar_url),'
// // // // // //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url)',
// // // // // //           )
// // // // // //           .or('requester_id.eq.$userId,addressee_id.eq.$userId')
// // // // // //           .eq('status', 'accepted');
// // // // // //       return rows.map((r) => _toFriendEntity(r, userId)).toList();
// // // // // //     },
// // // // // //   );

// // // // // //   Future<List<FriendEntity>> getPendingRequests(String userId) => guardedCall(
// // // // // //     operationName: 'getPendingRequests',
// // // // // //     operation: () async {
// // // // // //       final rows = await _supabase
// // // // // //           .from('friendships')
// // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // //           .eq('addressee_id', userId)
// // // // // //           .eq('status', 'pending');
// // // // // //       if ((rows as List).isEmpty) return [];
// // // // // //       // Fetch requester profiles separately to avoid join ambiguity
// // // // // //       final requesterIds = rows
// // // // // //           .map((r) => r['requester_id'] as String)
// // // // // //           .toList();
// // // // // //       final profiles = await _supabase
// // // // // //           .from('profiles')
// // // // // //           .select('id,display_name,username,avatar_url')
// // // // // //           .inFilter('id', requesterIds);
// // // // // //       final profileMap = {
// // // // // //         for (final p in profiles as List)
// // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // //       };
// // // // // //       return rows.map((r) {
// // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // //         row['requester'] = profileMap[row['requester_id']] ?? {};
// // // // // //         return _toFriendEntity(row, userId);
// // // // // //       }).toList();
// // // // // //     },
// // // // // //   );

// // // // // //   Future<List<FriendEntity>> getSentRequests(String userId) => guardedCall(
// // // // // //     operationName: 'getSentRequests',
// // // // // //     operation: () async {
// // // // // //       final rows = await _supabase
// // // // // //           .from('friendships')
// // // // // //           .select('id,status,requester_id,addressee_id')
// // // // // //           .eq('requester_id', userId)
// // // // // //           .eq('status', 'pending');
// // // // // //       if ((rows as List).isEmpty) return [];
// // // // // //       // Fetch addressee profiles separately
// // // // // //       final addresseeIds = rows
// // // // // //           .map((r) => r['addressee_id'] as String)
// // // // // //           .toList();
// // // // // //       final profiles = await _supabase
// // // // // //           .from('profiles')
// // // // // //           .select('id,display_name,username,avatar_url')
// // // // // //           .inFilter('id', addresseeIds);
// // // // // //       final profileMap = {
// // // // // //         for (final p in profiles as List)
// // // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // // //       };
// // // // // //       return rows.map((r) {
// // // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // // //         row['addressee'] = profileMap[row['addressee_id']] ?? {};
// // // // // //         return _toFriendEntity(row, userId);
// // // // // //       }).toList();
// // // // // //     },
// // // // // //   );

// // // // // //   Future<void> sendFriendRequest({
// // // // // //     required String requesterId,
// // // // // //     required String addresseeId,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'sendFriendRequest',
// // // // // //     operation: () async {
// // // // // //       // Check not blocked
// // // // // //       await _checkNotBlocked(requesterId, addresseeId);
// // // // // //       await _supabase.from('friendships').insert({
// // // // // //         'requester_id': requesterId,
// // // // // //         'addressee_id': addresseeId,
// // // // // //         'status': 'pending',
// // // // // //       });
// // // // // //     },
// // // // // //   );

// // // // // //   Future<void> respondToRequest({
// // // // // //     required String requesterId,
// // // // // //     required String addresseeId,
// // // // // //     required bool accept,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'respondToRequest',
// // // // // //     operation: () async {
// // // // // //       await _supabase
// // // // // //           .from('friendships')
// // // // // //           .update({'status': accept ? 'accepted' : 'rejected'})
// // // // // //           .eq('requester_id', requesterId)
// // // // // //           .eq('addressee_id', addresseeId);
// // // // // //     },
// // // // // //   );

// // // // // //   Future<void> removeFriend({
// // // // // //     required String userId,
// // // // // //     required String friendId,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'removeFriend',
// // // // // //     operation: () async {
// // // // // //       await _supabase
// // // // // //           .from('friendships')
// // // // // //           .delete()
// // // // // //           .or(
// // // // // //             'and(requester_id.eq.$userId,addressee_id.eq.$friendId),'
// // // // // //             'and(requester_id.eq.$friendId,addressee_id.eq.$userId)',
// // // // // //           );
// // // // // //     },
// // // // // //   );

// // // // // //   Future<void> cancelRequest({
// // // // // //     required String requesterId,
// // // // // //     required String addresseeId,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'cancelRequest',
// // // // // //     operation: () async {
// // // // // //       await _supabase
// // // // // //           .from('friendships')
// // // // // //           .delete()
// // // // // //           .eq('requester_id', requesterId)
// // // // // //           .eq('addressee_id', addresseeId)
// // // // // //           .eq('status', 'pending');
// // // // // //     },
// // // // // //   );

// // // // // //   // ── Follow system ─────────────────────────────────────────────────────────

// // // // // //   Future<void> followUser(String followerId, String followingId) => guardedCall(
// // // // // //     operationName: 'followUser',
// // // // // //     operation: () async {
// // // // // //       await _checkNotBlocked(followerId, followingId);
// // // // // //       await _supabase.from('follows').upsert({
// // // // // //         'follower_id': followerId,
// // // // // //         'followee_id': followingId,
// // // // // //       }, onConflict: 'follower_id,followee_id');
// // // // // //     },
// // // // // //   );

// // // // // //   Future<void> unfollowUser(String followerId, String followingId) =>
// // // // // //       guardedCall(
// // // // // //         operationName: 'unfollowUser',
// // // // // //         operation: () async {
// // // // // //           await _supabase
// // // // // //               .from('follows')
// // // // // //               .delete()
// // // // // //               .eq('follower_id', followerId)
// // // // // //               .eq('followee_id', followingId);
// // // // // //         },
// // // // // //       );

// // // // // //   Future<List<FollowEntity>> getFollowers(
// // // // // //     String userId, {
// // // // // //     int limit = 50,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'getFollowers',
// // // // // //     operation: () async {
// // // // // //       final rows = await _supabase
// // // // // //           .from('follows')
// // // // // //           .select(
// // // // // //             'follower_id,created_at,'
// // // // // //             'profiles!follower_id(id,display_name,username,avatar_url,verification_status)',
// // // // // //           )
// // // // // //           .eq('followee_id', userId)
// // // // // //           .order('created_at', ascending: false)
// // // // // //           .limit(limit);
// // // // // //       return rows.map(_toFollowEntity).toList();
// // // // // //     },
// // // // // //   );

// // // // // //   Future<List<FollowEntity>> getFollowing(
// // // // // //     String userId, {
// // // // // //     int limit = 50,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'getFollowing',
// // // // // //     operation: () async {
// // // // // //       final rows = await _supabase
// // // // // //           .from('follows')
// // // // // //           .select(
// // // // // //             'followee_id,created_at,'
// // // // // //             'profiles!followee_id(id,display_name,username,avatar_url,verification_status)',
// // // // // //           )
// // // // // //           .eq('follower_id', userId)
// // // // // //           .order('created_at', ascending: false)
// // // // // //           .limit(limit);
// // // // // //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// // // // // //     },
// // // // // //   );

// // // // // //   // ── Block system ──────────────────────────────────────────────────────────

// // // // // //   Future<void> blockUser({
// // // // // //     required String blockerId,
// // // // // //     required String blockedId,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'blockUser',
// // // // // //     operation: () async {
// // // // // //       await _supabase.from('blocked_users').upsert({
// // // // // //         'blocker_id': blockerId,
// // // // // //         'blocked_id': blockedId,
// // // // // //       }, onConflict: 'blocker_id,blocked_id');
// // // // // //       // Also remove any existing friendship
// // // // // //       await removeFriend(
// // // // // //         userId: blockerId,
// // // // // //         friendId: blockedId,
// // // // // //       ).catchError((_) {});
// // // // // //       // Remove follow in both directions
// // // // // //       await unfollowUser(blockerId, blockedId).catchError((_) {});
// // // // // //       await unfollowUser(blockedId, blockerId).catchError((_) {});
// // // // // //     },
// // // // // //   );

// // // // // //   Future<void> unblockUser({
// // // // // //     required String blockerId,
// // // // // //     required String blockedId,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'unblockUser',
// // // // // //     operation: () async {
// // // // // //       await _supabase
// // // // // //           .from('blocked_users')
// // // // // //           .delete()
// // // // // //           .eq('blocker_id', blockerId)
// // // // // //           .eq('blocked_id', blockedId);
// // // // // //     },
// // // // // //   );

// // // // // //   Future<List<FriendEntity>> getBlockedUsers(String userId) => guardedCall(
// // // // // //     operationName: 'getBlockedUsers',
// // // // // //     operation: () async {
// // // // // //       final rows = await _supabase
// // // // // //           .from('blocked_users')
// // // // // //           .select(
// // // // // //             'blocked_id,created_at,'
// // // // // //             'profiles!blocked_id(id,display_name,username,avatar_url)',
// // // // // //           )
// // // // // //           .eq('blocker_id', userId)
// // // // // //           .order('created_at', ascending: false);
// // // // // //       return rows.map((r) {
// // // // // //         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
// // // // // //         return FriendEntity(
// // // // // //           userId: profile['id'] as String? ?? '',
// // // // // //           displayName: profile['display_name'] as String? ?? 'User',
// // // // // //           username: profile['username'] as String?,
// // // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // // //           status: FriendshipStatus.blocked,
// // // // // //           isRequester: true,
// // // // // //         );
// // // // // //       }).toList();
// // // // // //     },
// // // // // //   );

// // // // // //   // ── Social profile ────────────────────────────────────────────────────────

// // // // // //   Future<SocialProfile> getSocialProfile({
// // // // // //     required String targetUserId,
// // // // // //     required String viewerUserId,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'getSocialProfile',
// // // // // //     operation: () async {
// // // // // //       // Try profiles_public first (has bio + counts after migration)
// // // // // //       // Use limit(1) to guard against duplicate rows in view/table
// // // // // //       final profileRows = await _supabase
// // // // // //           .from('profiles_public')
// // // // // //           .select()
// // // // // //           .eq('id', targetUserId)
// // // // // //           .limit(1);
// // // // // //       Map<String, dynamic>? profile = profileRows.isNotEmpty
// // // // // //           ? profileRows.first as Map<String, dynamic>
// // // // // //           : null;

// // // // // //       // Fallback: profiles table directly
// // // // // //       if (profile == null) {
// // // // // //         final fallbackRows = await _supabase
// // // // // //             .from('profiles')
// // // // // //             .select('id, display_name, username, avatar_url, bio')
// // // // // //             .eq('id', targetUserId)
// // // // // //             .limit(1);
// // // // // //         profile = fallbackRows.isNotEmpty
// // // // // //             ? fallbackRows.first as Map<String, dynamic>
// // // // // //             : null;
// // // // // //       }
// // // // // //       if (profile == null) throw Exception('Profile not found');

// // // // // //       // If we only got minimal data (no counts), return basic profile
// // // // // //       final hasFullData = profile.containsKey('followers_count');
// // // // // //       if (!hasFullData) {
// // // // // //         return SocialProfile(
// // // // // //           userId: profile['id'] as String,
// // // // // //           displayName: profile['display_name'] as String? ?? 'Player',
// // // // // //           username: profile['username'] as String?,
// // // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // // //           bio: profile['bio'] as String?,
// // // // // //           followersCount: 0,
// // // // // //           followingCount: 0,
// // // // // //           friendsCount: 0,
// // // // // //           gamesPlayed: 0,
// // // // // //           packsCount: 0,
// // // // // //         );
// // // // // //       }

// // // // // //       final [
// // // // // //         blockedByMe,
// // // // // //         blockedByThem,
// // // // // //         friendshipRow,
// // // // // //         followingRow,
// // // // // //         followedByRow,
// // // // // //       ] = await Future.wait([
// // // // // //         _supabase
// // // // // //             .from('blocked_users')
// // // // // //             .select('blocker_id')
// // // // // //             .eq('blocker_id', viewerUserId)
// // // // // //             .eq('blocked_id', targetUserId)
// // // // // //             .maybeSingle(),
// // // // // //         _supabase
// // // // // //             .from('blocked_users')
// // // // // //             .select('blocker_id')
// // // // // //             .eq('blocker_id', targetUserId)
// // // // // //             .eq('blocked_id', viewerUserId)
// // // // // //             .maybeSingle(),
// // // // // //         _supabase
// // // // // //             .from('friendships')
// // // // // //             .select('status')
// // // // // //             .or(
// // // // // //               'and(requester_id.eq.$viewerUserId,addressee_id.eq.$targetUserId),'
// // // // // //               'and(requester_id.eq.$targetUserId,addressee_id.eq.$viewerUserId)',
// // // // // //             )
// // // // // //             .maybeSingle(),
// // // // // //         _supabase
// // // // // //             .from('follows')
// // // // // //             .select('follower_id')
// // // // // //             .eq('follower_id', viewerUserId)
// // // // // //             .eq('followee_id', targetUserId)
// // // // // //             .maybeSingle(),
// // // // // //         _supabase
// // // // // //             .from('follows')
// // // // // //             .select('follower_id')
// // // // // //             .eq('follower_id', targetUserId)
// // // // // //             .eq('followee_id', viewerUserId)
// // // // // //             .maybeSingle(),
// // // // // //       ]);

// // // // // //       FriendshipStatus? friendStatus;
// // // // // //       if (friendshipRow != null) {
// // // // // //         friendStatus = FriendshipStatus.values.firstWhere(
// // // // // //           (s) => s.name == (friendshipRow as Map)['status'],
// // // // // //           orElse: () => FriendshipStatus.pending,
// // // // // //         );
// // // // // //       }

// // // // // //       return SocialProfile(
// // // // // //         userId: profile['id'] as String,
// // // // // //         displayName: profile['display_name'] as String? ?? 'User',
// // // // // //         username: profile['username'] as String?,
// // // // // //         avatarUrl: profile['avatar_url'] as String?,
// // // // // //         bio: profile['bio'] as String?,
// // // // // //         followersCount: (profile['followers_count'] as num?)?.toInt() ?? 0,
// // // // // //         followingCount: (profile['following_count'] as num?)?.toInt() ?? 0,
// // // // // //         friendsCount: (profile['friends_count'] as num?)?.toInt() ?? 0,
// // // // // //         gamesPlayed: (profile['games_played'] as num?)?.toInt() ?? 0,
// // // // // //         packsCount: (profile['packs_count'] as num?)?.toInt() ?? 0,
// // // // // //         friendshipStatus: friendStatus,
// // // // // //         isFollowing: followingRow != null,
// // // // // //         isFollowedBy: followedByRow != null,
// // // // // //         isBlocked: blockedByMe != null,
// // // // // //         isBlockedBy: blockedByThem != null,
// // // // // //         isVerified: profile['verification_status'] == 'verified',
// // // // // //       );
// // // // // //     },
// // // // // //   );

// // // // // //   // ── Search ────────────────────────────────────────────────────────────────

// // // // // //   Future<List<UserEntity>> searchUsers(
// // // // // //     String query, {
// // // // // //     required String excludeUserId,
// // // // // //     int limit = 20,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'searchUsers',
// // // // // //     operation: () async {
// // // // // //       final rows = await _supabase
// // // // // //           .from('profiles_public')
// // // // // //           .select('id,username,display_name,avatar_url')
// // // // // //           .or('username.ilike.%$query%,display_name.ilike.%$query%')
// // // // // //           .neq('id', excludeUserId)
// // // // // //           .limit(limit);
// // // // // //       return rows
// // // // // //           .map(
// // // // // //             (r) => UserEntity(
// // // // // //               id: r['id'] as String,
// // // // // //               email: '',
// // // // // //               username: r['username'] as String?,
// // // // // //               displayName: r['display_name'] as String?,
// // // // // //               avatarUrl: r['avatar_url'] as String?,
// // // // // //             ),
// // // // // //           )
// // // // // //           .toList();
// // // // // //     },
// // // // // //   );

// // // // // //   // ── Private helpers ───────────────────────────────────────────────────────

// // // // // //   Future<void> _checkNotBlocked(String a, String b) async {
// // // // // //     try {
// // // // // //       final block = await _supabase
// // // // // //           .from('blocked_users')
// // // // // //           .select('blocker_id')
// // // // // //           .or(
// // // // // //             'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // // // // //             'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // // // // //           )
// // // // // //           .maybeSingle();
// // // // // //       if (block != null) {
// // // // // //         throw const ForbiddenFailure(
// // // // // //           message: 'Cannot interact with this user.',
// // // // // //         );
// // // // // //       }
// // // // // //     } on ForbiddenFailure {
// // // // // //       rethrow; // actual block — rethrow
// // // // // //     } catch (_) {
// // // // // //       // RLS error reading blocked_users — treat as not blocked
// // // // // //     }
// // // // // //   }

// // // // // //   FriendEntity _toFriendEntity(Map<String, dynamic> row, String currentUserId) {
// // // // // //     final requesterId = row['requester_id'] as String? ?? '';
// // // // // //     final isRequester = requesterId == currentUserId;
// // // // // //     final rawOther = isRequester ? row['addressee'] : row['requester'];
// // // // // //     final other = (rawOther is Map)
// // // // // //         ? Map<String, dynamic>.from(rawOther)
// // // // // //         : <String, dynamic>{};
// // // // // //     return FriendEntity(
// // // // // //       friendshipId: row['id'] as String?,
// // // // // //       userId: other['id'] as String? ?? '',
// // // // // //       displayName: other['display_name'] as String? ?? 'Player',
// // // // // //       username: other['username'] as String?,
// // // // // //       avatarUrl: other['avatar_url'] as String?,
// // // // // //       status: FriendshipStatus.values.firstWhere(
// // // // // //         (s) => s.name == (row['status'] as String? ?? ''),
// // // // // //         orElse: () => FriendshipStatus.pending,
// // // // // //       ),
// // // // // //       isRequester: isRequester,
// // // // // //     );
// // // // // //   }

// // // // // //   FollowEntity _toFollowEntity(
// // // // // //     Map<String, dynamic> row, {
// // // // // //     bool followingMode = false,
// // // // // //   }) {
// // // // // //     final profile =
// // // // // //         row[followingMode ? 'profiles!followee_id' : 'profiles!follower_id']
// // // // // //             as Map<String, dynamic>? ??
// // // // // //         {};
// // // // // //     return FollowEntity(
// // // // // //       userId: profile['id'] as String? ?? '',
// // // // // //       displayName: profile['display_name'] as String? ?? 'User',
// // // // // //       username: profile['username'] as String?,
// // // // // //       avatarUrl: profile['avatar_url'] as String?,
// // // // // //       followedAt: DateTime.parse(row['created_at'] as String),
// // // // // //       isVerified: profile['verification_status'] == 'verified',
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // import '../../../core/data/base_repository.dart';
// // // import '../../../core/errors/failures.dart';
// // // import '../../../features/auth/domain/entities/user_entity.dart';

// // // // // // ── Domain types ──────────────────────────────────────────────────────────────

// // // // // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // // // // class FriendEntity {
// // // // //   const FriendEntity({
// // // // //     required this.userId,
// // // // //     required this.displayName,
// // // // //     this.username,
// // // // //     this.avatarUrl,
// // // // //     required this.status,
// // // // //     required this.isRequester,
// // // // //     this.mutualFriendsCount = 0,
// // // // //     this.friendshipId,
// // // // //   });

// // // // //   final String userId;
// // // // //   final String displayName;
// // // // //   final String? username;
// // // // //   final String? avatarUrl;
// // // // //   final FriendshipStatus status;
// // // // //   final bool isRequester;
// // // // //   final int mutualFriendsCount;
// // // // //   final String? friendshipId;

// // // // //   bool get isAccepted => status == FriendshipStatus.accepted;
// // // // //   bool get isPending => status == FriendshipStatus.pending;
// // // // // }

// // // // // class FollowEntity {
// // // // //   const FollowEntity({
// // // // //     required this.userId,
// // // // //     required this.displayName,
// // // // //     this.username,
// // // // //     this.avatarUrl,
// // // // //     required this.followedAt,
// // // // //     this.isVerified = false,
// // // // //   });

// // // // //   final String userId;
// // // // //   final String displayName;
// // // // //   final String? username;
// // // // //   final String? avatarUrl;
// // // // //   final DateTime followedAt;
// // // // //   final bool isVerified;
// // // // // }

// // // // // class SocialProfile {
// // // // //   const SocialProfile({
// // // // //     required this.userId,
// // // // //     required this.displayName,
// // // // //     this.username,
// // // // //     this.avatarUrl,
// // // // //     this.bio,
// // // // //     required this.followersCount,
// // // // //     required this.followingCount,
// // // // //     required this.friendsCount,
// // // // //     this.gamesPlayed = 0,
// // // // //     this.packsCount = 0,
// // // // //     this.friendshipStatus,
// // // // //     this.isFollowing = false,
// // // // //     this.isFollowedBy = false,
// // // // //     this.isBlocked = false,
// // // // //     this.isBlockedBy = false,
// // // // //     this.isVerified = false,
// // // // //   });

// // // // //   final String userId;
// // // // //   final String displayName;
// // // // //   final String? username;
// // // // //   final String? avatarUrl;
// // // // //   final String? bio;
// // // // //   final int followersCount;
// // // // //   final int followingCount;
// // // // //   final int friendsCount;
// // // // //   final int gamesPlayed;
// // // // //   final int packsCount;
// // // // //   final FriendshipStatus? friendshipStatus;
// // // // //   final bool isFollowing;
// // // // //   final bool isFollowedBy;
// // // // //   final bool isBlocked;
// // // // //   final bool isBlockedBy;
// // // // //   final bool isVerified;

// // // // //   bool get canInteract => !isBlocked && !isBlockedBy;
// // // // // }

// // // // // // ── Repository ────────────────────────────────────────────────────────────────

// // // // // class FriendsRepository extends BaseRepository {
// // // // //   FriendsRepository._();
// // // // //   static final FriendsRepository _instance = FriendsRepository._();
// // // // //   static FriendsRepository get instance => _instance;

// // // // //   final _supabase = Supabase.instance.client;

// // // // //   // ── Friends ───────────────────────────────────────────────────────────────

// // // // //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// // // // //     operationName: 'getFriends',
// // // // //     operation: () async {
// // // // //       final rows = await _supabase
// // // // //           .from('friendships')
// // // // //           .select(
// // // // //             'id,status,requester_id,addressee_id,'
// // // // //             'requester:profiles!requester_id(id,display_name,username,avatar_url),'
// // // // //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url)',
// // // // //           )
// // // // //           .or('requester_id.eq.$userId,addressee_id.eq.$userId')
// // // // //           .eq('status', 'accepted');
// // // // //       return rows.map((r) => _toFriendEntity(r, userId)).toList();
// // // // //     },
// // // // //   );

// // // // //   Future<List<FriendEntity>> getPendingRequests(String userId) => guardedCall(
// // // // //     operationName: 'getPendingRequests',
// // // // //     operation: () async {
// // // // //       final rows = await _supabase
// // // // //           .from('friendships')
// // // // //           .select('id,status,requester_id,addressee_id')
// // // // //           .eq('addressee_id', userId)
// // // // //           .eq('status', 'pending');
// // // // //       if ((rows as List).isEmpty) return [];
// // // // //       // Fetch requester profiles separately to avoid join ambiguity
// // // // //       final requesterIds = rows
// // // // //           .map((r) => r['requester_id'] as String)
// // // // //           .toList();
// // // // //       final profiles = await _supabase
// // // // //           .from('profiles')
// // // // //           .select('id,display_name,username,avatar_url')
// // // // //           .inFilter('id', requesterIds);
// // // // //       final profileMap = {
// // // // //         for (final p in profiles as List)
// // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // //       };
// // // // //       return rows.map((r) {
// // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // //         row['requester'] = profileMap[row['requester_id']] ?? {};
// // // // //         return _toFriendEntity(row, userId);
// // // // //       }).toList();
// // // // //     },
// // // // //   );

// // // // //   Future<List<FriendEntity>> getSentRequests(String userId) => guardedCall(
// // // // //     operationName: 'getSentRequests',
// // // // //     operation: () async {
// // // // //       final rows = await _supabase
// // // // //           .from('friendships')
// // // // //           .select('id,status,requester_id,addressee_id')
// // // // //           .eq('requester_id', userId)
// // // // //           .eq('status', 'pending');
// // // // //       if ((rows as List).isEmpty) return [];
// // // // //       // Fetch addressee profiles separately
// // // // //       final addresseeIds = rows
// // // // //           .map((r) => r['addressee_id'] as String)
// // // // //           .toList();
// // // // //       final profiles = await _supabase
// // // // //           .from('profiles')
// // // // //           .select('id,display_name,username,avatar_url')
// // // // //           .inFilter('id', addresseeIds);
// // // // //       final profileMap = {
// // // // //         for (final p in profiles as List)
// // // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // // //       };
// // // // //       return rows.map((r) {
// // // // //         final row = Map<String, dynamic>.from(r as Map);
// // // // //         row['addressee'] = profileMap[row['addressee_id']] ?? {};
// // // // //         return _toFriendEntity(row, userId);
// // // // //       }).toList();
// // // // //     },
// // // // //   );

// // // // //   Future<void> sendFriendRequest({
// // // // //     required String requesterId,
// // // // //     required String addresseeId,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'sendFriendRequest',
// // // // //     operation: () async {
// // // // //       // Check not blocked
// // // // //       await _checkNotBlocked(requesterId, addresseeId);
// // // // //       await _supabase.from('friendships').insert({
// // // // //         'requester_id': requesterId,
// // // // //         'addressee_id': addresseeId,
// // // // //         'status': 'pending',
// // // // //       });
// // // // //     },
// // // // //   );

// // // // //   Future<void> respondToRequest({
// // // // //     required String requesterId,
// // // // //     required String addresseeId,
// // // // //     required bool accept,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'respondToRequest',
// // // // //     operation: () async {
// // // // //       await _supabase
// // // // //           .from('friendships')
// // // // //           .update({'status': accept ? 'accepted' : 'rejected'})
// // // // //           .eq('requester_id', requesterId)
// // // // //           .eq('addressee_id', addresseeId);
// // // // //     },
// // // // //   );

// // // // //   Future<void> removeFriend({
// // // // //     required String userId,
// // // // //     required String friendId,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'removeFriend',
// // // // //     operation: () async {
// // // // //       await _supabase
// // // // //           .from('friendships')
// // // // //           .delete()
// // // // //           .or(
// // // // //             'and(requester_id.eq.$userId,addressee_id.eq.$friendId),'
// // // // //             'and(requester_id.eq.$friendId,addressee_id.eq.$userId)',
// // // // //           );
// // // // //     },
// // // // //   );

// // // // //   Future<void> cancelRequest({
// // // // //     required String requesterId,
// // // // //     required String addresseeId,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'cancelRequest',
// // // // //     operation: () async {
// // // // //       await _supabase
// // // // //           .from('friendships')
// // // // //           .delete()
// // // // //           .eq('requester_id', requesterId)
// // // // //           .eq('addressee_id', addresseeId)
// // // // //           .eq('status', 'pending');
// // // // //     },
// // // // //   );

// // // // //   // ── Follow system ─────────────────────────────────────────────────────────

// // // // //   Future<void> followUser(String followerId, String followingId) => guardedCall(
// // // // //     operationName: 'followUser',
// // // // //     operation: () async {
// // // // //       await _checkNotBlocked(followerId, followingId);
// // // // //       await _supabase.from('follows').upsert({
// // // // //         'follower_id': followerId,
// // // // //         'followee_id': followingId,
// // // // //       }, onConflict: 'follower_id,followee_id');
// // // // //     },
// // // // //   );

// // // // //   Future<void> unfollowUser(String followerId, String followingId) =>
// // // // //       guardedCall(
// // // // //         operationName: 'unfollowUser',
// // // // //         operation: () async {
// // // // //           await _supabase
// // // // //               .from('follows')
// // // // //               .delete()
// // // // //               .eq('follower_id', followerId)
// // // // //               .eq('followee_id', followingId);
// // // // //         },
// // // // //       );

// // // // //   Future<List<FollowEntity>> getFollowers(
// // // // //     String userId, {
// // // // //     int limit = 50,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'getFollowers',
// // // // //     operation: () async {
// // // // //       final rows = await _supabase
// // // // //           .from('follows')
// // // // //           .select(
// // // // //             'follower_id,created_at,'
// // // // //             'profiles!follower_id(id,display_name,username,avatar_url,verification_status)',
// // // // //           )
// // // // //           .eq('followee_id', userId)
// // // // //           .order('created_at', ascending: false)
// // // // //           .limit(limit);
// // // // //       return rows.map(_toFollowEntity).toList();
// // // // //     },
// // // // //   );

// // // // //   Future<List<FollowEntity>> getFollowing(
// // // // //     String userId, {
// // // // //     int limit = 50,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'getFollowing',
// // // // //     operation: () async {
// // // // //       final rows = await _supabase
// // // // //           .from('follows')
// // // // //           .select(
// // // // //             'followee_id,created_at,'
// // // // //             'profiles!followee_id(id,display_name,username,avatar_url,verification_status)',
// // // // //           )
// // // // //           .eq('follower_id', userId)
// // // // //           .order('created_at', ascending: false)
// // // // //           .limit(limit);
// // // // //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// // // // //     },
// // // // //   );

// // // // //   // ── Block system ──────────────────────────────────────────────────────────

// // // // //   Future<void> blockUser({
// // // // //     required String blockerId,
// // // // //     required String blockedId,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'blockUser',
// // // // //     operation: () async {
// // // // //       await _supabase.from('blocked_users').upsert({
// // // // //         'blocker_id': blockerId,
// // // // //         'blocked_id': blockedId,
// // // // //       }, onConflict: 'blocker_id,blocked_id');
// // // // //       // Also remove any existing friendship
// // // // //       await removeFriend(
// // // // //         userId: blockerId,
// // // // //         friendId: blockedId,
// // // // //       ).catchError((_) {});
// // // // //       // Remove follow in both directions
// // // // //       await unfollowUser(blockerId, blockedId).catchError((_) {});
// // // // //       await unfollowUser(blockedId, blockerId).catchError((_) {});
// // // // //     },
// // // // //   );

// // // // //   Future<void> unblockUser({
// // // // //     required String blockerId,
// // // // //     required String blockedId,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'unblockUser',
// // // // //     operation: () async {
// // // // //       await _supabase
// // // // //           .from('blocked_users')
// // // // //           .delete()
// // // // //           .eq('blocker_id', blockerId)
// // // // //           .eq('blocked_id', blockedId);
// // // // //     },
// // // // //   );

// // // // //   Future<List<FriendEntity>> getBlockedUsers(String userId) => guardedCall(
// // // // //     operationName: 'getBlockedUsers',
// // // // //     operation: () async {
// // // // //       final rows = await _supabase
// // // // //           .from('blocked_users')
// // // // //           .select(
// // // // //             'blocked_id,created_at,'
// // // // //             'profiles!blocked_id(id,display_name,username,avatar_url)',
// // // // //           )
// // // // //           .eq('blocker_id', userId)
// // // // //           .order('created_at', ascending: false);
// // // // //       return rows.map((r) {
// // // // //         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
// // // // //         return FriendEntity(
// // // // //           userId: profile['id'] as String? ?? '',
// // // // //           displayName: profile['display_name'] as String? ?? 'User',
// // // // //           username: profile['username'] as String?,
// // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // //           status: FriendshipStatus.blocked,
// // // // //           isRequester: true,
// // // // //         );
// // // // //       }).toList();
// // // // //     },
// // // // //   );

// // // // //   // ── Social profile ────────────────────────────────────────────────────────

// // // // //   Future<SocialProfile> getSocialProfile({
// // // // //     required String targetUserId,
// // // // //     required String viewerUserId,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'getSocialProfile',
// // // // //     operation: () async {
// // // // //       // Try profiles_public first (has bio + counts after migration)
// // // // //       // Use limit(1) to guard against duplicate rows in view/table
// // // // //       final profileRows = await _supabase
// // // // //           .from('profiles_public')
// // // // //           .select()
// // // // //           .eq('id', targetUserId)
// // // // //           .limit(1);
// // // // //       Map<String, dynamic>? profile = profileRows.isNotEmpty
// // // // //           ? profileRows.first as Map<String, dynamic>
// // // // //           : null;

// // // // //       // Fallback: profiles table directly
// // // // //       if (profile == null) {
// // // // //         final fallbackRows = await _supabase
// // // // //             .from('profiles')
// // // // //             .select('id, display_name, username, avatar_url, bio')
// // // // //             .eq('id', targetUserId)
// // // // //             .limit(1);
// // // // //         profile = fallbackRows.isNotEmpty
// // // // //             ? fallbackRows.first as Map<String, dynamic>
// // // // //             : null;
// // // // //       }
// // // // //       if (profile == null) throw Exception('Profile not found');

// // // // //       // If we only got minimal data (no counts), return basic profile
// // // // //       final hasFullData = profile.containsKey('followers_count');
// // // // //       if (!hasFullData) {
// // // // //         return SocialProfile(
// // // // //           userId: profile['id'] as String,
// // // // //           displayName: profile['display_name'] as String? ?? 'Player',
// // // // //           username: profile['username'] as String?,
// // // // //           avatarUrl: profile['avatar_url'] as String?,
// // // // //           bio: profile['bio'] as String?,
// // // // //           followersCount: 0,
// // // // //           followingCount: 0,
// // // // //           friendsCount: 0,
// // // // //           gamesPlayed: 0,
// // // // //           packsCount: 0,
// // // // //         );
// // // // //       }

// // // // //       final [
// // // // //         blockedByMe,
// // // // //         blockedByThem,
// // // // //         friendshipRow,
// // // // //         followingRow,
// // // // //         followedByRow,
// // // // //       ] = await Future.wait([
// // // // //         _supabase
// // // // //             .from('blocked_users')
// // // // //             .select('blocker_id')
// // // // //             .eq('blocker_id', viewerUserId)
// // // // //             .eq('blocked_id', targetUserId)
// // // // //             .maybeSingle(),
// // // // //         _supabase
// // // // //             .from('blocked_users')
// // // // //             .select('blocker_id')
// // // // //             .eq('blocker_id', targetUserId)
// // // // //             .eq('blocked_id', viewerUserId)
// // // // //             .maybeSingle(),
// // // // //         _supabase
// // // // //             .from('friendships')
// // // // //             .select('status')
// // // // //             .or(
// // // // //               'and(requester_id.eq.$viewerUserId,addressee_id.eq.$targetUserId),'
// // // // //               'and(requester_id.eq.$targetUserId,addressee_id.eq.$viewerUserId)',
// // // // //             )
// // // // //             .maybeSingle(),
// // // // //         _supabase
// // // // //             .from('follows')
// // // // //             .select('follower_id')
// // // // //             .eq('follower_id', viewerUserId)
// // // // //             .eq('followee_id', targetUserId)
// // // // //             .maybeSingle(),
// // // // //         _supabase
// // // // //             .from('follows')
// // // // //             .select('follower_id')
// // // // //             .eq('follower_id', targetUserId)
// // // // //             .eq('followee_id', viewerUserId)
// // // // //             .maybeSingle(),
// // // // //       ]);

// // // // //       FriendshipStatus? friendStatus;
// // // // //       if (friendshipRow != null) {
// // // // //         friendStatus = FriendshipStatus.values.firstWhere(
// // // // //           (s) => s.name == (friendshipRow as Map)['status'],
// // // // //           orElse: () => FriendshipStatus.pending,
// // // // //         );
// // // // //       }

// // // // //       return SocialProfile(
// // // // //         userId: profile['id'] as String,
// // // // //         displayName: profile['display_name'] as String? ?? 'User',
// // // // //         username: profile['username'] as String?,
// // // // //         avatarUrl: profile['avatar_url'] as String?,
// // // // //         bio: profile['bio'] as String?,
// // // // //         followersCount: (profile['followers_count'] as num?)?.toInt() ?? 0,
// // // // //         followingCount: (profile['following_count'] as num?)?.toInt() ?? 0,
// // // // //         friendsCount: (profile['friends_count'] as num?)?.toInt() ?? 0,
// // // // //         gamesPlayed: (profile['games_played'] as num?)?.toInt() ?? 0,
// // // // //         packsCount: (profile['packs_count'] as num?)?.toInt() ?? 0,
// // // // //         friendshipStatus: friendStatus,
// // // // //         isFollowing: followingRow != null,
// // // // //         isFollowedBy: followedByRow != null,
// // // // //         isBlocked: blockedByMe != null,
// // // // //         isBlockedBy: blockedByThem != null,
// // // // //         isVerified: profile['verification_status'] == 'verified',
// // // // //       );
// // // // //     },
// // // // //   );

// // // // //   // ── Search ────────────────────────────────────────────────────────────────

// // // // //   Future<List<UserEntity>> searchUsers(
// // // // //     String query, {
// // // // //     required String excludeUserId,
// // // // //     int limit = 20,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'searchUsers',
// // // // //     operation: () async {
// // // // //       final rows = await _supabase
// // // // //           .from('profiles_public')
// // // // //           .select('id,username,display_name,avatar_url')
// // // // //           .or('username.ilike.%$query%,display_name.ilike.%$query%')
// // // // //           .neq('id', excludeUserId)
// // // // //           .limit(limit);
// // // // //       return rows
// // // // //           .map(
// // // // //             (r) => UserEntity(
// // // // //               id: r['id'] as String,
// // // // //               email: '',
// // // // //               username: r['username'] as String?,
// // // // //               displayName: r['display_name'] as String?,
// // // // //               avatarUrl: r['avatar_url'] as String?,
// // // // //             ),
// // // // //           )
// // // // //           .toList();
// // // // //     },
// // // // //   );

// // // // //   // ── Private helpers ───────────────────────────────────────────────────────

// // // // //   /// Returns the friendship status between two users, or null if none exists.
// // // // //   Future<FriendEntity?> getFriendshipStatus({
// // // // //     required String userId,
// // // // //     required String otherId,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'getFriendshipStatus',
// // // // //     operation: () async {
// // // // //       final row = await _supabase
// // // // //           .from('friendships')
// // // // //           .select()
// // // // //           .or(
// // // // //             'and(requester_id.eq.$userId,addressee_id.eq.$otherId),'
// // // // //             'and(requester_id.eq.$otherId,addressee_id.eq.$userId)',
// // // // //           )
// // // // //           .maybeSingle();
// // // // //       if (row == null) return null;
// // // // //       return FriendEntity(
// // // // //         userId: otherId,
// // // // //         displayName: '',
// // // // //         status: FriendshipStatus.values.firstWhere(
// // // // //           (s) => s.name == (row['status'] as String? ?? 'pending'),
// // // // //           orElse: () => FriendshipStatus.pending,
// // // // //         ),
// // // // //         isRequester: (row['requester_id'] as String?) == userId,
// // // // //         friendshipId: row['id'] as String?,
// // // // //       );
// // // // //     },
// // // // //   );

// // // // //   Future<void> _checkNotBlocked(String a, String b) async {
// // // // //     try {
// // // // //       final block = await _supabase
// // // // //           .from('blocked_users')
// // // // //           .select('blocker_id')
// // // // //           .or(
// // // // //             'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // // // //             'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // // // //           )
// // // // //           .maybeSingle();
// // // // //       if (block != null) {
// // // // //         throw const ForbiddenFailure(
// // // // //           message: 'Cannot interact with this user.',
// // // // //         );
// // // // //       }
// // // // //     } on ForbiddenFailure {
// // // // //       rethrow; // actual block — rethrow
// // // // //     } catch (_) {
// // // // //       // RLS error reading blocked_users — treat as not blocked
// // // // //     }
// // // // //   }

// // // // //   FriendEntity _toFriendEntity(Map<String, dynamic> row, String currentUserId) {
// // // // //     final requesterId = row['requester_id'] as String? ?? '';
// // // // //     final isRequester = requesterId == currentUserId;
// // // // //     final rawOther = isRequester ? row['addressee'] : row['requester'];
// // // // //     final other = (rawOther is Map)
// // // // //         ? Map<String, dynamic>.from(rawOther)
// // // // //         : <String, dynamic>{};
// // // // //     return FriendEntity(
// // // // //       friendshipId: row['id'] as String?,
// // // // //       userId: other['id'] as String? ?? '',
// // // // //       displayName: other['display_name'] as String? ?? 'Player',
// // // // //       username: other['username'] as String?,
// // // // //       avatarUrl: other['avatar_url'] as String?,
// // // // //       status: FriendshipStatus.values.firstWhere(
// // // // //         (s) => s.name == (row['status'] as String? ?? ''),
// // // // //         orElse: () => FriendshipStatus.pending,
// // // // //       ),
// // // // //       isRequester: isRequester,
// // // // //     );
// // // // //   }

// // // // //   FollowEntity _toFollowEntity(
// // // // //     Map<String, dynamic> row, {
// // // // //     bool followingMode = false,
// // // // //   }) {
// // // // //     final profile =
// // // // //         row[followingMode ? 'profiles!followee_id' : 'profiles!follower_id']
// // // // //             as Map<String, dynamic>? ??
// // // // //         {};
// // // // //     return FollowEntity(
// // // // //       userId: profile['id'] as String? ?? '',
// // // // //       displayName: profile['display_name'] as String? ?? 'User',
// // // // //       username: profile['username'] as String?,
// // // // //       avatarUrl: profile['avatar_url'] as String?,
// // // // //       followedAt: DateTime.parse(row['created_at'] as String),
// // // // //       isVerified: profile['verification_status'] == 'verified',
// // // // //     );
// // // // //   }
// // // // // }

// // // // // import 'package:jma3a/core/errors/failures.dart';

// // // // // import '../../../features/auth/domain/entities/user_entity.dart';

// // // // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // // // class FriendEntity {
// // // //   const FriendEntity({
// // // //     required this.userId,
// // // //     required this.displayName,
// // // //     this.username,
// // // //     this.avatarUrl,
// // // //     this.avatarConfig,
// // // //     this.isPremium = false,
// // // //     required this.status,
// // // //     required this.isRequester,
// // // //     this.mutualFriendsCount = 0,
// // // //     this.friendshipId,
// // // //   });

// // // //   final String userId;
// // // //   final String displayName;
// // // //   final String? username;
// // // //   final String? avatarUrl;
// // // //   final Map<String, dynamic>? avatarConfig;
// // // //   final bool isPremium;
// // // //   final FriendshipStatus status;
// // // //   final bool isRequester;
// // // //   final int mutualFriendsCount;
// // // //   final String? friendshipId;

// // // //   bool get isAccepted => status == FriendshipStatus.accepted;
// // // //   bool get isPending => status == FriendshipStatus.pending;
// // // // }

// // // // class FollowEntity {
// // // //   const FollowEntity({
// // // //     required this.userId,
// // // //     required this.displayName,
// // // //     this.username,
// // // //     this.avatarUrl,
// // // //     this.avatarConfig,
// // // //     this.isPremium = false,
// // // //     required this.followedAt,
// // // //     this.isVerified = false,
// // // //   });

// // // //   final String userId;
// // // //   final String displayName;
// // // //   final String? username;
// // // //   final String? avatarUrl;
// // // //   final Map<String, dynamic>? avatarConfig;
// // // //   final bool isPremium;
// // // //   final DateTime followedAt;
// // // //   final bool isVerified;
// // // // }

// // // // class SocialProfile {
// // // //   const SocialProfile({
// // // //     required this.userId,
// // // //     required this.displayName,
// // // //     this.username,
// // // //     this.avatarUrl,
// // // //     this.avatarConfig,
// // // //     this.isPremium = false,
// // // //     this.bio,
// // // //     required this.followersCount,
// // // //     required this.followingCount,
// // // //     required this.friendsCount,
// // // //     this.gamesPlayed = 0,
// // // //     this.packsCount = 0,
// // // //     this.friendshipStatus,
// // // //     this.isFollowing = false,
// // // //     this.isFollowedBy = false,
// // // //     this.isBlocked = false,
// // // //     this.isBlockedBy = false,
// // // //     this.isVerified = false,
// // // //   });

// // // //   final String userId;
// // // //   final String displayName;
// // // //   final String? username;
// // // //   final String? avatarUrl;
// // // //   final Map<String, dynamic>? avatarConfig;
// // // //   final bool isPremium;
// // // //   final String? bio;
// // // //   final int followersCount;
// // // //   final int followingCount;
// // // //   final int friendsCount;
// // // //   final int gamesPlayed;
// // // //   final int packsCount;
// // // //   final FriendshipStatus? friendshipStatus;
// // // //   final bool isFollowing;
// // // //   final bool isFollowedBy;
// // // //   final bool isBlocked;
// // // //   final bool isBlockedBy;
// // // //   final bool isVerified;

// // // //   bool get canInteract => !isBlocked && !isBlockedBy;
// // // // }

// // // // class FriendsRepository extends BaseRepository {
// // // //   FriendsRepository._();
// // // //   static final FriendsRepository _instance = FriendsRepository._();
// // // //   static FriendsRepository get instance => _instance;

// // // //   final _supabase = Supabase.instance.client;

// // // //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// // // //     operationName: 'getFriends',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('friendships')
// // // //           .select(
// // // //             'id,status,requester_id,addressee_id,'
// // // //             'requester:profiles!requester_id(id,display_name,username,avatar_url,avatar_config,is_premium),'
// // // //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url,avatar_config,is_premium)',
// // // //           )
// // // //           .or('requester_id.eq.$userId,addressee_id.eq.$userId')
// // // //           .eq('status', 'accepted');
// // // //       return rows.map((r) => _toFriendEntity(r, userId)).toList();
// // // //     },
// // // //   );

// // // //   Future<List<FriendEntity>> getPendingRequests(String userId) => guardedCall(
// // // //     operationName: 'getPendingRequests',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('friendships')
// // // //           .select('id,status,requester_id,addressee_id')
// // // //           .eq('addressee_id', userId)
// // // //           .eq('status', 'pending');
// // // //       if ((rows as List).isEmpty) return [];
// // // //       final requesterIds = rows
// // // //           .map((r) => r['requester_id'] as String)
// // // //           .toList();
// // // //       final profiles = await _supabase
// // // //           .from('profiles')
// // // //           .select(
// // // //             'id,display_name,username,avatar_url,avatar_config,is_premium',
// // // //           )
// // // //           .inFilter('id', requesterIds);
// // // //       final profileMap = {
// // // //         for (final p in profiles as List)
// // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // //       };
// // // //       return rows.map((r) {
// // // //         final row = Map<String, dynamic>.from(r as Map);
// // // //         row['requester'] = profileMap[row['requester_id']] ?? {};
// // // //         return _toFriendEntity(row, userId);
// // // //       }).toList();
// // // //     },
// // // //   );

// // // //   Future<List<FriendEntity>> getSentRequests(String userId) => guardedCall(
// // // //     operationName: 'getSentRequests',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('friendships')
// // // //           .select('id,status,requester_id,addressee_id')
// // // //           .eq('requester_id', userId)
// // // //           .eq('status', 'pending');
// // // //       if ((rows as List).isEmpty) return [];
// // // //       final addresseeIds = rows
// // // //           .map((r) => r['addressee_id'] as String)
// // // //           .toList();
// // // //       final profiles = await _supabase
// // // //           .from('profiles')
// // // //           .select(
// // // //             'id,display_name,username,avatar_url,avatar_config,is_premium',
// // // //           )
// // // //           .inFilter('id', addresseeIds);
// // // //       final profileMap = {
// // // //         for (final p in profiles as List)
// // // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // // //       };
// // // //       return rows.map((r) {
// // // //         final row = Map<String, dynamic>.from(r as Map);
// // // //         row['addressee'] = profileMap[row['addressee_id']] ?? {};
// // // //         return _toFriendEntity(row, userId);
// // // //       }).toList();
// // // //     },
// // // //   );

// // // //   Future<void> sendFriendRequest({
// // // //     required String requesterId,
// // // //     required String addresseeId,
// // // //   }) => guardedCall(
// // // //     operationName: 'sendFriendRequest',
// // // //     operation: () async {
// // // //       await _checkNotBlocked(requesterId, addresseeId);
// // // //       await _supabase.from('friendships').insert({
// // // //         'requester_id': requesterId,
// // // //         'addressee_id': addresseeId,
// // // //         'status': 'pending',
// // // //       });
// // // //     },
// // // //   );

// // // //   Future<void> respondToRequest({
// // // //     required String requesterId,
// // // //     required String addresseeId,
// // // //     required bool accept,
// // // //   }) => guardedCall(
// // // //     operationName: 'respondToRequest',
// // // //     operation: () async {
// // // //       await _supabase
// // // //           .from('friendships')
// // // //           .update({'status': accept ? 'accepted' : 'rejected'})
// // // //           .eq('requester_id', requesterId)
// // // //           .eq('addressee_id', addresseeId);
// // // //     },
// // // //   );

// // // //   Future<void> removeFriend({
// // // //     required String userId,
// // // //     required String friendId,
// // // //   }) => guardedCall(
// // // //     operationName: 'removeFriend',
// // // //     operation: () async {
// // // //       await _supabase
// // // //           .from('friendships')
// // // //           .delete()
// // // //           .or(
// // // //             'and(requester_id.eq.$userId,addressee_id.eq.$friendId),'
// // // //             'and(requester_id.eq.$friendId,addressee_id.eq.$userId)',
// // // //           );
// // // //     },
// // // //   );

// // // //   Future<void> cancelRequest({
// // // //     required String requesterId,
// // // //     required String addresseeId,
// // // //   }) => guardedCall(
// // // //     operationName: 'cancelRequest',
// // // //     operation: () async {
// // // //       await _supabase
// // // //           .from('friendships')
// // // //           .delete()
// // // //           .eq('requester_id', requesterId)
// // // //           .eq('addressee_id', addresseeId)
// // // //           .eq('status', 'pending');
// // // //     },
// // // //   );

// // // //   Future<void> followUser(String followerId, String followingId) => guardedCall(
// // // //     operationName: 'followUser',
// // // //     operation: () async {
// // // //       await _checkNotBlocked(followerId, followingId);
// // // //       await _supabase.from('follows').upsert({
// // // //         'follower_id': followerId,
// // // //         'followee_id': followingId,
// // // //       }, onConflict: 'follower_id,followee_id');
// // // //     },
// // // //   );

// // // //   Future<void> unfollowUser(String followerId, String followingId) =>
// // // //       guardedCall(
// // // //         operationName: 'unfollowUser',
// // // //         operation: () async {
// // // //           await _supabase
// // // //               .from('follows')
// // // //               .delete()
// // // //               .eq('follower_id', followerId)
// // // //               .eq('followee_id', followingId);
// // // //         },
// // // //       );

// // // //   Future<List<FollowEntity>> getFollowers(
// // // //     String userId, {
// // // //     int limit = 50,
// // // //   }) => guardedCall(
// // // //     operationName: 'getFollowers',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('follows')
// // // //           .select(
// // // //             'follower_id,created_at,'
// // // //             'profiles!follower_id(id,display_name,username,avatar_url,avatar_config,is_premium,verification_status)',
// // // //           )
// // // //           .eq('followee_id', userId)
// // // //           .order('created_at', ascending: false)
// // // //           .limit(limit);
// // // //       return rows.map(_toFollowEntity).toList();
// // // //     },
// // // //   );

// // // //   Future<List<FollowEntity>> getFollowing(
// // // //     String userId, {
// // // //     int limit = 50,
// // // //   }) => guardedCall(
// // // //     operationName: 'getFollowing',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('follows')
// // // //           .select(
// // // //             'followee_id,created_at,'
// // // //             'profiles!followee_id(id,display_name,username,avatar_url,avatar_config,is_premium,verification_status)',
// // // //           )
// // // //           .eq('follower_id', userId)
// // // //           .order('created_at', ascending: false)
// // // //           .limit(limit);
// // // //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// // // //     },
// // // //   );

// // // //   Future<void> blockUser({
// // // //     required String blockerId,
// // // //     required String blockedId,
// // // //   }) => guardedCall(
// // // //     operationName: 'blockUser',
// // // //     operation: () async {
// // // //       await _supabase.from('blocked_users').upsert({
// // // //         'blocker_id': blockerId,
// // // //         'blocked_id': blockedId,
// // // //       }, onConflict: 'blocker_id,blocked_id');
// // // //       await removeFriend(
// // // //         userId: blockerId,
// // // //         friendId: blockedId,
// // // //       ).catchError((_) {});
// // // //       await unfollowUser(blockerId, blockedId).catchError((_) {});
// // // //       await unfollowUser(blockedId, blockerId).catchError((_) {});
// // // //     },
// // // //   );

// // // //   Future<void> unblockUser({
// // // //     required String blockerId,
// // // //     required String blockedId,
// // // //   }) => guardedCall(
// // // //     operationName: 'unblockUser',
// // // //     operation: () async {
// // // //       await _supabase
// // // //           .from('blocked_users')
// // // //           .delete()
// // // //           .eq('blocker_id', blockerId)
// // // //           .eq('blocked_id', blockedId);
// // // //     },
// // // //   );

// // // //   Future<List<FriendEntity>> getBlockedUsers(String userId) => guardedCall(
// // // //     operationName: 'getBlockedUsers',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('blocked_users')
// // // //           .select(
// // // //             'blocked_id,created_at,'
// // // //             'profiles!blocked_id(id,display_name,username,avatar_url,avatar_config,is_premium)',
// // // //           )
// // // //           .eq('blocker_id', userId)
// // // //           .order('created_at', ascending: false);
// // // //       return rows.map((r) {
// // // //         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
// // // //         return FriendEntity(
// // // //           userId: profile['id'] as String? ?? '',
// // // //           displayName: profile['display_name'] as String? ?? 'User',
// // // //           username: profile['username'] as String?,
// // // //           avatarUrl: profile['avatar_url'] as String?,
// // // //           avatarConfig: profile['avatar_config'] != null
// // // //               ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
// // // //               : null,
// // // //           isPremium: profile['is_premium'] as bool? ?? false,
// // // //           status: FriendshipStatus.blocked,
// // // //           isRequester: true,
// // // //         );
// // // //       }).toList();
// // // //     },
// // // //   );

// // // //   Future<SocialProfile> getSocialProfile({
// // // //     required String targetUserId,
// // // //     required String viewerUserId,
// // // //   }) => guardedCall(
// // // //     operationName: 'getSocialProfile',
// // // //     operation: () async {
// // // //       final profileRows = await _supabase
// // // //           .from('profiles_public')
// // // //           .select()
// // // //           .eq('id', targetUserId)
// // // //           .limit(1);
// // // //       Map<String, dynamic>? profile = profileRows.isNotEmpty
// // // //           ? profileRows.first as Map<String, dynamic>
// // // //           : null;

// // // //       if (profile == null) {
// // // //         final fallbackRows = await _supabase
// // // //             .from('profiles')
// // // //             .select(
// // // //               'id, display_name, username, avatar_url, avatar_config, is_premium, bio',
// // // //             )
// // // //             .eq('id', targetUserId)
// // // //             .limit(1);
// // // //         profile = fallbackRows.isNotEmpty
// // // //             ? fallbackRows.first as Map<String, dynamic>
// // // //             : null;
// // // //       }
// // // //       if (profile == null) throw Exception('Profile not found');

// // // //       final hasFullData = profile.containsKey('followers_count');
// // // //       if (!hasFullData) {
// // // //         return SocialProfile(
// // // //           userId: profile['id'] as String,
// // // //           displayName: profile['display_name'] as String? ?? 'Player',
// // // //           username: profile['username'] as String?,
// // // //           avatarUrl: profile['avatar_url'] as String?,
// // // //           avatarConfig: profile['avatar_config'] != null
// // // //               ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
// // // //               : null,
// // // //           isPremium: profile['is_premium'] as bool? ?? false,
// // // //           bio: profile['bio'] as String?,
// // // //           followersCount: 0,
// // // //           followingCount: 0,
// // // //           friendsCount: 0,
// // // //           gamesPlayed: 0,
// // // //           packsCount: 0,
// // // //         );
// // // //       }

// // // //       final [
// // // //         blockedByMe,
// // // //         blockedByThem,
// // // //         friendshipRow,
// // // //         followingRow,
// // // //         followedByRow,
// // // //       ] = await Future.wait([
// // // //         _supabase
// // // //             .from('blocked_users')
// // // //             .select('blocker_id')
// // // //             .eq('blocker_id', viewerUserId)
// // // //             .eq('blocked_id', targetUserId)
// // // //             .maybeSingle(),
// // // //         _supabase
// // // //             .from('blocked_users')
// // // //             .select('blocker_id')
// // // //             .eq('blocker_id', targetUserId)
// // // //             .eq('blocked_id', viewerUserId)
// // // //             .maybeSingle(),
// // // //         _supabase
// // // //             .from('friendships')
// // // //             .select('status')
// // // //             .or(
// // // //               'and(requester_id.eq.$viewerUserId,addressee_id.eq.$targetUserId),'
// // // //               'and(requester_id.eq.$targetUserId,addressee_id.eq.$viewerUserId)',
// // // //             )
// // // //             .maybeSingle(),
// // // //         _supabase
// // // //             .from('follows')
// // // //             .select('follower_id')
// // // //             .eq('follower_id', viewerUserId)
// // // //             .eq('followee_id', targetUserId)
// // // //             .maybeSingle(),
// // // //         _supabase
// // // //             .from('follows')
// // // //             .select('follower_id')
// // // //             .eq('follower_id', targetUserId)
// // // //             .eq('followee_id', viewerUserId)
// // // //             .maybeSingle(),
// // // //       ]);

// // // //       FriendshipStatus? friendStatus;
// // // //       if (friendshipRow != null) {
// // // //         friendStatus = FriendshipStatus.values.firstWhere(
// // // //           (s) => s.name == (friendshipRow as Map)['status'],
// // // //           orElse: () => FriendshipStatus.pending,
// // // //         );
// // // //       }

// // // //       return SocialProfile(
// // // //         userId: profile['id'] as String,
// // // //         displayName: profile['display_name'] as String? ?? 'User',
// // // //         username: profile['username'] as String?,
// // // //         avatarUrl: profile['avatar_url'] as String?,
// // // //         bio: profile['bio'] as String?,
// // // //         followersCount: (profile['followers_count'] as num?)?.toInt() ?? 0,
// // // //         followingCount: (profile['following_count'] as num?)?.toInt() ?? 0,
// // // //         friendsCount: (profile['friends_count'] as num?)?.toInt() ?? 0,
// // // //         gamesPlayed: (profile['games_played'] as num?)?.toInt() ?? 0,
// // // //         packsCount: (profile['packs_count'] as num?)?.toInt() ?? 0,
// // // //         friendshipStatus: friendStatus,
// // // //         isFollowing: followingRow != null,
// // // //         isFollowedBy: followedByRow != null,
// // // //         isBlocked: blockedByMe != null,
// // // //         isBlockedBy: blockedByThem != null,
// // // //         isVerified: profile['verification_status'] == 'verified',
// // // //       );
// // // //     },
// // // //   );

// // // //   Future<List<UserEntity>> searchUsers(
// // // //     String query, {
// // // //     required String excludeUserId,
// // // //     int limit = 20,
// // // //   }) => guardedCall(
// // // //     operationName: 'searchUsers',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('profiles_public')
// // // //           .select('id,username,display_name,avatar_url')
// // // //           .or('username.ilike.%$query%,display_name.ilike.%$query%')
// // // //           .neq('id', excludeUserId)
// // // //           .limit(limit);
// // // //       return rows
// // // //           .map(
// // // //             (r) => UserEntity(
// // // //               id: r['id'] as String,
// // // //               email: '',
// // // //               username: r['username'] as String?,
// // // //               displayName: r['display_name'] as String?,
// // // //               avatarUrl: r['avatar_url'] as String?,
// // // //               avatarConfig: r['avatar_config'] != null
// // // //                   ? Map<String, dynamic>.from(r['avatar_config'] as Map)
// // // //                   : null,
// // // //               isPremium: r['is_premium'] as bool? ?? false,
// // // //             ),
// // // //           )
// // // //           .toList();
// // // //     },
// // // //   );

// // // //   Future<FriendEntity?> getFriendshipStatus({
// // // //     required String userId,
// // // //     required String otherId,
// // // //   }) => guardedCall(
// // // //     operationName: 'getFriendshipStatus',
// // // //     operation: () async {
// // // //       final row = await _supabase
// // // //           .from('friendships')
// // // //           .select()
// // // //           .or(
// // // //             'and(requester_id.eq.$userId,addressee_id.eq.$otherId),'
// // // //             'and(requester_id.eq.$otherId,addressee_id.eq.$userId)',
// // // //           )
// // // //           .maybeSingle();
// // // //       if (row == null) return null;
// // // //       return FriendEntity(
// // // //         userId: otherId,
// // // //         displayName: '',
// // // //         status: FriendshipStatus.values.firstWhere(
// // // //           (s) => s.name == (row['status'] as String? ?? 'pending'),
// // // //           orElse: () => FriendshipStatus.pending,
// // // //         ),
// // // //         isRequester: (row['requester_id'] as String?) == userId,
// // // //         friendshipId: row['id'] as String?,
// // // //       );
// // // //     },
// // // //   );

// // // //   Future<void> _checkNotBlocked(String a, String b) async {
// // // //     try {
// // // //       final block = await _supabase
// // // //           .from('blocked_users')
// // // //           .select('blocker_id')
// // // //           .or(
// // // //             'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // // //             'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // // //           )
// // // //           .maybeSingle();
// // // //       if (block != null) {
// // // //         throw const ForbiddenFailure(
// // // //           message: 'Cannot interact with this user.',
// // // //         );
// // // //       }
// // // //     } on ForbiddenFailure {
// // // //       rethrow;
// // // //     } catch (_) {}
// // // //   }

// // // //   FriendEntity _toFriendEntity(Map<String, dynamic> row, String currentUserId) {
// // // //     final requesterId = row['requester_id'] as String? ?? '';
// // // //     final isRequester = requesterId == currentUserId;
// // // //     final rawOther = isRequester ? row['addressee'] : row['requester'];
// // // //     final other = (rawOther is Map)
// // // //         ? Map<String, dynamic>.from(rawOther)
// // // //         : <String, dynamic>{};
// // // //     return FriendEntity(
// // // //       friendshipId: row['id'] as String?,
// // // //       userId: other['id'] as String? ?? '',
// // // //       displayName: other['display_name'] as String? ?? 'Player',
// // // //       username: other['username'] as String?,
// // // //       avatarUrl: other['avatar_url'] as String?,
// // // //       avatarConfig: other['avatar_config'] != null
// // // //           ? Map<String, dynamic>.from(other['avatar_config'] as Map)
// // // //           : null,
// // // //       isPremium: other['is_premium'] as bool? ?? false,
// // // //       status: FriendshipStatus.values.firstWhere(
// // // //         (s) => s.name == (row['status'] as String? ?? ''),
// // // //         orElse: () => FriendshipStatus.pending,
// // // //       ),
// // // //       isRequester: isRequester,
// // // //     );
// // // //   }

// // // //   FollowEntity _toFollowEntity(
// // // //     Map<String, dynamic> row, {
// // // //     bool followingMode = false,
// // // //   }) {
// // // //     final profile =
// // // //         row[followingMode ? 'profiles!followee_id' : 'profiles!follower_id']
// // // //             as Map<String, dynamic>? ??
// // // //         {};
// // // //     return FollowEntity(
// // // //       userId: profile['id'] as String? ?? '',
// // // //       displayName: profile['display_name'] as String? ?? 'User',
// // // //       username: profile['username'] as String?,
// // // //       avatarUrl: profile['avatar_url'] as String?,
// // // //       avatarConfig: profile['avatar_config'] != null
// // // //           ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
// // // //           : null,
// // // //       isPremium: profile['is_premium'] as bool? ?? false,
// // // //       followedAt: DateTime.parse(row['created_at'] as String),
// // // //       isVerified: profile['verification_status'] == 'verified',
// // // //     );
// // // //   }
// // // // }

// // // import '../../../features/auth/domain/entities/user_entity.dart';

// // // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // // class FriendEntity {
// // //   const FriendEntity({
// // //     required this.userId,
// // //     required this.displayName,
// // //     this.username,
// // //     this.avatarUrl,
// // //     this.avatarConfig,
// // //     this.isPremium = false,
// // //     required this.status,
// // //     required this.isRequester,
// // //     this.mutualFriendsCount = 0,
// // //     this.friendshipId,
// // //   });

// // //   final String userId;
// // //   final String displayName;
// // //   final String? username;
// // //   final String? avatarUrl;
// // //   final Map<String, dynamic>? avatarConfig;
// // //   final bool isPremium;
// // //   final FriendshipStatus status;
// // //   final bool isRequester;
// // //   final int mutualFriendsCount;
// // //   final String? friendshipId;

// // //   bool get isAccepted => status == FriendshipStatus.accepted;
// // //   bool get isPending => status == FriendshipStatus.pending;
// // // }

// // // class FollowEntity {
// // //   const FollowEntity({
// // //     required this.userId,
// // //     required this.displayName,
// // //     this.username,
// // //     this.avatarUrl,
// // //     this.avatarConfig,
// // //     this.isPremium = false,
// // //     required this.followedAt,
// // //     this.isVerified = false,
// // //   });

// // //   final String userId;
// // //   final String displayName;
// // //   final String? username;
// // //   final String? avatarUrl;
// // //   final Map<String, dynamic>? avatarConfig;
// // //   final bool isPremium;
// // //   final DateTime followedAt;
// // //   final bool isVerified;
// // // }

// // // class SocialProfile {
// // //   const SocialProfile({
// // //     required this.userId,
// // //     required this.displayName,
// // //     this.username,
// // //     this.avatarUrl,
// // //     this.avatarConfig,
// // //     this.isPremium = false,
// // //     this.bio,
// // //     required this.followersCount,
// // //     required this.followingCount,
// // //     required this.friendsCount,
// // //     this.gamesPlayed = 0,
// // //     this.packsCount = 0,
// // //     this.friendshipStatus,
// // //     this.isFollowing = false,
// // //     this.isFollowedBy = false,
// // //     this.isBlocked = false,
// // //     this.isBlockedBy = false,
// // //     this.isVerified = false,
// // //   });

// // //   final String userId;
// // //   final String displayName;
// // //   final String? username;
// // //   final String? avatarUrl;
// // //   final Map<String, dynamic>? avatarConfig;
// // //   final bool isPremium;
// // //   final String? bio;
// // //   final int followersCount;
// // //   final int followingCount;
// // //   final int friendsCount;
// // //   final int gamesPlayed;
// // //   final int packsCount;
// // //   final FriendshipStatus? friendshipStatus;
// // //   final bool isFollowing;
// // //   final bool isFollowedBy;
// // //   final bool isBlocked;
// // //   final bool isBlockedBy;
// // //   final bool isVerified;

// // //   bool get canInteract => !isBlocked && !isBlockedBy;
// // // }

// // // class FriendsRepository extends BaseRepository {
// // //   FriendsRepository._();
// // //   static final FriendsRepository _instance = FriendsRepository._();
// // //   static FriendsRepository get instance => _instance;

// // //   final _supabase = Supabase.instance.client;

// // //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// // //     operationName: 'getFriends',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('friendships')
// // //           .select(
// // //             'id,status,requester_id,addressee_id,'
// // //             'requester:profiles!requester_id(id,display_name,username,avatar_url,avatar_config,is_premium),'
// // //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url,avatar_config,is_premium)',
// // //           )
// // //           .or('requester_id.eq.$userId,addressee_id.eq.$userId')
// // //           .eq('status', 'accepted');
// // //       return rows.map((r) => _toFriendEntity(r, userId)).toList();
// // //     },
// // //   );

// // //   Future<List<FriendEntity>> getPendingRequests(String userId) => guardedCall(
// // //     operationName: 'getPendingRequests',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('friendships')
// // //           .select('id,status,requester_id,addressee_id')
// // //           .eq('addressee_id', userId)
// // //           .eq('status', 'pending');
// // //       if ((rows as List).isEmpty) return [];
// // //       final requesterIds = rows
// // //           .map((r) => r['requester_id'] as String)
// // //           .toList();
// // //       final profiles = await _supabase
// // //           .from('profiles')
// // //           .select(
// // //             'id,display_name,username,avatar_url,avatar_config,is_premium',
// // //           )
// // //           .inFilter('id', requesterIds);
// // //       final profileMap = {
// // //         for (final p in profiles as List)
// // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // //       };
// // //       return rows.map((r) {
// // //         final row = Map<String, dynamic>.from(r as Map);
// // //         row['requester'] = profileMap[row['requester_id']] ?? {};
// // //         return _toFriendEntity(row, userId);
// // //       }).toList();
// // //     },
// // //   );

// // //   Future<List<FriendEntity>> getSentRequests(String userId) => guardedCall(
// // //     operationName: 'getSentRequests',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('friendships')
// // //           .select('id,status,requester_id,addressee_id')
// // //           .eq('requester_id', userId)
// // //           .eq('status', 'pending');
// // //       if ((rows as List).isEmpty) return [];
// // //       final addresseeIds = rows
// // //           .map((r) => r['addressee_id'] as String)
// // //           .toList();
// // //       final profiles = await _supabase
// // //           .from('profiles')
// // //           .select(
// // //             'id,display_name,username,avatar_url,avatar_config,is_premium',
// // //           )
// // //           .inFilter('id', addresseeIds);
// // //       final profileMap = {
// // //         for (final p in profiles as List)
// // //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// // //       };
// // //       return rows.map((r) {
// // //         final row = Map<String, dynamic>.from(r as Map);
// // //         row['addressee'] = profileMap[row['addressee_id']] ?? {};
// // //         return _toFriendEntity(row, userId);
// // //       }).toList();
// // //     },
// // //   );

// // //   Future<void> sendFriendRequest({
// // //     required String requesterId,
// // //     required String addresseeId,
// // //   }) => guardedCall(
// // //     operationName: 'sendFriendRequest',
// // //     operation: () async {
// // //       await _checkNotBlocked(requesterId, addresseeId);
// // //       await _supabase.from('friendships').insert({
// // //         'requester_id': requesterId,
// // //         'addressee_id': addresseeId,
// // //         'status': 'pending',
// // //       });
// // //     },
// // //   );

// // //   Future<void> respondToRequest({
// // //     required String requesterId,
// // //     required String addresseeId,
// // //     required bool accept,
// // //   }) => guardedCall(
// // //     operationName: 'respondToRequest',
// // //     operation: () async {
// // //       await _supabase
// // //           .from('friendships')
// // //           .update({'status': accept ? 'accepted' : 'rejected'})
// // //           .eq('requester_id', requesterId)
// // //           .eq('addressee_id', addresseeId);
// // //     },
// // //   );

// // //   Future<void> removeFriend({
// // //     required String userId,
// // //     required String friendId,
// // //   }) => guardedCall(
// // //     operationName: 'removeFriend',
// // //     operation: () async {
// // //       await _supabase
// // //           .from('friendships')
// // //           .delete()
// // //           .or(
// // //             'and(requester_id.eq.$userId,addressee_id.eq.$friendId),'
// // //             'and(requester_id.eq.$friendId,addressee_id.eq.$userId)',
// // //           );
// // //     },
// // //   );

// // //   Future<void> cancelRequest({
// // //     required String requesterId,
// // //     required String addresseeId,
// // //   }) => guardedCall(
// // //     operationName: 'cancelRequest',
// // //     operation: () async {
// // //       await _supabase
// // //           .from('friendships')
// // //           .delete()
// // //           .eq('requester_id', requesterId)
// // //           .eq('addressee_id', addresseeId)
// // //           .eq('status', 'pending');
// // //     },
// // //   );

// // //   Future<void> followUser(String followerId, String followingId) => guardedCall(
// // //     operationName: 'followUser',
// // //     operation: () async {
// // //       await _checkNotBlocked(followerId, followingId);
// // //       await _supabase.from('follows').upsert({
// // //         'follower_id': followerId,
// // //         'followee_id': followingId,
// // //       }, onConflict: 'follower_id,followee_id');
// // //     },
// // //   );

// // //   Future<void> unfollowUser(String followerId, String followingId) =>
// // //       guardedCall(
// // //         operationName: 'unfollowUser',
// // //         operation: () async {
// // //           await _supabase
// // //               .from('follows')
// // //               .delete()
// // //               .eq('follower_id', followerId)
// // //               .eq('followee_id', followingId);
// // //         },
// // //       );

// // //   Future<List<FollowEntity>> getFollowers(
// // //     String userId, {
// // //     int limit = 50,
// // //   }) => guardedCall(
// // //     operationName: 'getFollowers',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('follows')
// // //           .select(
// // //             'follower_id,created_at,'
// // //             'profiles!follower_id(id,display_name,username,avatar_url,avatar_config,is_premium,verification_status)',
// // //           )
// // //           .eq('followee_id', userId)
// // //           .order('created_at', ascending: false)
// // //           .limit(limit);
// // //       return rows.map(_toFollowEntity).toList();
// // //     },
// // //   );

// // //   Future<List<FollowEntity>> getFollowing(
// // //     String userId, {
// // //     int limit = 50,
// // //   }) => guardedCall(
// // //     operationName: 'getFollowing',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('follows')
// // //           .select(
// // //             'followee_id,created_at,'
// // //             'profiles!followee_id(id,display_name,username,avatar_url,avatar_config,is_premium,verification_status)',
// // //           )
// // //           .eq('follower_id', userId)
// // //           .order('created_at', ascending: false)
// // //           .limit(limit);
// // //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// // //     },
// // //   );

// // //   Future<void> blockUser({
// // //     required String blockerId,
// // //     required String blockedId,
// // //   }) => guardedCall(
// // //     operationName: 'blockUser',
// // //     operation: () async {
// // //       await _supabase.from('blocked_users').upsert({
// // //         'blocker_id': blockerId,
// // //         'blocked_id': blockedId,
// // //       }, onConflict: 'blocker_id,blocked_id');
// // //       await removeFriend(
// // //         userId: blockerId,
// // //         friendId: blockedId,
// // //       ).catchError((_) {});
// // //       await unfollowUser(blockerId, blockedId).catchError((_) {});
// // //       await unfollowUser(blockedId, blockerId).catchError((_) {});
// // //     },
// // //   );

// // //   Future<void> unblockUser({
// // //     required String blockerId,
// // //     required String blockedId,
// // //   }) => guardedCall(
// // //     operationName: 'unblockUser',
// // //     operation: () async {
// // //       await _supabase
// // //           .from('blocked_users')
// // //           .delete()
// // //           .eq('blocker_id', blockerId)
// // //           .eq('blocked_id', blockedId);
// // //     },
// // //   );

// // //   Future<List<FriendEntity>> getBlockedUsers(String userId) => guardedCall(
// // //     operationName: 'getBlockedUsers',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('blocked_users')
// // //           .select(
// // //             'blocked_id,created_at,'
// // //             'profiles!blocked_id(id,display_name,username,avatar_url,avatar_config,is_premium)',
// // //           )
// // //           .eq('blocker_id', userId)
// // //           .order('created_at', ascending: false);
// // //       return rows.map((r) {
// // //         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
// // //         return FriendEntity(
// // //           userId: profile['id'] as String? ?? '',
// // //           displayName: profile['display_name'] as String? ?? 'User',
// // //           username: profile['username'] as String?,
// // //           avatarUrl: profile['avatar_url'] as String?,
// // //           avatarConfig: profile['avatar_config'] != null
// // //               ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
// // //               : null,
// // //           isPremium: profile['is_premium'] as bool? ?? false,
// // //           status: FriendshipStatus.blocked,
// // //           isRequester: true,
// // //         );
// // //       }).toList();
// // //     },
// // //   );

// // //   Future<SocialProfile> getSocialProfile({
// // //     required String targetUserId,
// // //     required String viewerUserId,
// // //   }) => guardedCall(
// // //     operationName: 'getSocialProfile',
// // //     operation: () async {
// // //       final profileRows = await _supabase
// // //           .from('profiles_public')
// // //           .select()
// // //           .eq('id', targetUserId)
// // //           .limit(1);
// // //       Map<String, dynamic>? profile = profileRows.isNotEmpty
// // //           ? profileRows.first as Map<String, dynamic>
// // //           : null;

// // //       if (profile == null) {
// // //         final fallbackRows = await _supabase
// // //             .from('profiles')
// // //             .select(
// // //               'id, display_name, username, avatar_url, avatar_config, is_premium, bio',
// // //             )
// // //             .eq('id', targetUserId)
// // //             .limit(1);
// // //         profile = fallbackRows.isNotEmpty
// // //             ? fallbackRows.first as Map<String, dynamic>
// // //             : null;
// // //       }
// // //       if (profile == null) throw Exception('Profile not found');

// // //       final hasFullData = profile.containsKey('followers_count');
// // //       if (!hasFullData) {
// // //         return SocialProfile(
// // //           userId: profile['id'] as String,
// // //           displayName: profile['display_name'] as String? ?? 'Player',
// // //           username: profile['username'] as String?,
// // //           avatarUrl: profile['avatar_url'] as String?,
// // //           avatarConfig: profile['avatar_config'] != null
// // //               ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
// // //               : null,
// // //           isPremium: profile['is_premium'] as bool? ?? false,
// // //           bio: profile['bio'] as String?,
// // //           followersCount: 0,
// // //           followingCount: 0,
// // //           friendsCount: 0,
// // //           gamesPlayed: 0,
// // //           packsCount: 0,
// // //         );
// // //       }

// // //       final [
// // //         blockedByMe,
// // //         blockedByThem,
// // //         friendshipRow,
// // //         followingRow,
// // //         followedByRow,
// // //       ] = await Future.wait([
// // //         _supabase
// // //             .from('blocked_users')
// // //             .select('blocker_id')
// // //             .eq('blocker_id', viewerUserId)
// // //             .eq('blocked_id', targetUserId)
// // //             .maybeSingle(),
// // //         _supabase
// // //             .from('blocked_users')
// // //             .select('blocker_id')
// // //             .eq('blocker_id', targetUserId)
// // //             .eq('blocked_id', viewerUserId)
// // //             .maybeSingle(),
// // //         _supabase
// // //             .from('friendships')
// // //             .select('status')
// // //             .or(
// // //               'and(requester_id.eq.$viewerUserId,addressee_id.eq.$targetUserId),'
// // //               'and(requester_id.eq.$targetUserId,addressee_id.eq.$viewerUserId)',
// // //             )
// // //             .maybeSingle(),
// // //         _supabase
// // //             .from('follows')
// // //             .select('follower_id')
// // //             .eq('follower_id', viewerUserId)
// // //             .eq('followee_id', targetUserId)
// // //             .maybeSingle(),
// // //         _supabase
// // //             .from('follows')
// // //             .select('follower_id')
// // //             .eq('follower_id', targetUserId)
// // //             .eq('followee_id', viewerUserId)
// // //             .maybeSingle(),
// // //       ]);

// // //       FriendshipStatus? friendStatus;
// // //       if (friendshipRow != null) {
// // //         friendStatus = FriendshipStatus.values.firstWhere(
// // //           (s) => s.name == (friendshipRow as Map)['status'],
// // //           orElse: () => FriendshipStatus.pending,
// // //         );
// // //       }

// // //       return SocialProfile(
// // //         userId: profile['id'] as String,
// // //         displayName: profile['display_name'] as String? ?? 'User',
// // //         username: profile['username'] as String?,
// // //         avatarUrl: profile['avatar_url'] as String?,
// // //         bio: profile['bio'] as String?,
// // //         followersCount: (profile['followers_count'] as num?)?.toInt() ?? 0,
// // //         followingCount: (profile['following_count'] as num?)?.toInt() ?? 0,
// // //         friendsCount: (profile['friends_count'] as num?)?.toInt() ?? 0,
// // //         gamesPlayed: (profile['games_played'] as num?)?.toInt() ?? 0,
// // //         packsCount: (profile['packs_count'] as num?)?.toInt() ?? 0,
// // //         friendshipStatus: friendStatus,
// // //         isFollowing: followingRow != null,
// // //         isFollowedBy: followedByRow != null,
// // //         isBlocked: blockedByMe != null,
// // //         isBlockedBy: blockedByThem != null,
// // //         isVerified: profile['verification_status'] == 'verified',
// // //       );
// // //     },
// // //   );

// // //   Future<List<UserEntity>> searchUsers(
// // //     String query, {
// // //     required String excludeUserId,
// // //     int limit = 20,
// // //   }) => guardedCall(
// // //     operationName: 'searchUsers',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('profiles_public')
// // //           .select(
// // //             'id,username,display_name,avatar_url,avatar_config,is_premium',
// // //           )
// // //           .or('username.ilike.%$query%,display_name.ilike.%$query%')
// // //           .neq('id', excludeUserId)
// // //           .limit(limit);
// // //       return rows
// // //           .map(
// // //             (r) => UserEntity(
// // //               id: r['id'] as String,
// // //               email: '',
// // //               username: r['username'] as String?,
// // //               displayName: r['display_name'] as String?,
// // //               avatarUrl: r['avatar_url'] as String?,
// // //               avatarConfig: r['avatar_config'] != null
// // //                   ? Map<String, dynamic>.from(r['avatar_config'] as Map)
// // //                   : null,
// // //               isPremium: r['is_premium'] as bool? ?? false,
// // //               // avatarConfig: r['avatar_config'] != null ? Map<String, dynamic>.from(r['avatar_config'] as Map) : null,
// // //               // isPremium: r['is_premium'] as bool? ?? false,
// // //             ),
// // //           )
// // //           .toList();
// // //     },
// // //   );

// // //   Future<FriendEntity?> getFriendshipStatus({
// // //     required String userId,
// // //     required String otherId,
// // //   }) => guardedCall(
// // //     operationName: 'getFriendshipStatus',
// // //     operation: () async {
// // //       final row = await _supabase
// // //           .from('friendships')
// // //           .select()
// // //           .or(
// // //             'and(requester_id.eq.$userId,addressee_id.eq.$otherId),'
// // //             'and(requester_id.eq.$otherId,addressee_id.eq.$userId)',
// // //           )
// // //           .maybeSingle();
// // //       if (row == null) return null;
// // //       return FriendEntity(
// // //         userId: otherId,
// // //         displayName: '',
// // //         status: FriendshipStatus.values.firstWhere(
// // //           (s) => s.name == (row['status'] as String? ?? 'pending'),
// // //           orElse: () => FriendshipStatus.pending,
// // //         ),
// // //         isRequester: (row['requester_id'] as String?) == userId,
// // //         friendshipId: row['id'] as String?,
// // //       );
// // //     },
// // //   );

// // //   Future<void> _checkNotBlocked(String a, String b) async {
// // //     try {
// // //       final block = await _supabase
// // //           .from('blocked_users')
// // //           .select('blocker_id')
// // //           .or(
// // //             'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // //             'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // //           )
// // //           .maybeSingle();
// // //       if (block != null) {
// // //         throw const ForbiddenFailure(
// // //           message: 'Cannot interact with this user.',
// // //         );
// // //       }
// // //     } on ForbiddenFailure {
// // //       rethrow;
// // //     } catch (_) {}
// // //   }

// // //   FriendEntity _toFriendEntity(Map<String, dynamic> row, String currentUserId) {
// // //     final requesterId = row['requester_id'] as String? ?? '';
// // //     final isRequester = requesterId == currentUserId;
// // //     final rawOther = isRequester ? row['addressee'] : row['requester'];
// // //     final other = (rawOther is Map)
// // //         ? Map<String, dynamic>.from(rawOther)
// // //         : <String, dynamic>{};
// // //     return FriendEntity(
// // //       friendshipId: row['id'] as String?,
// // //       userId: other['id'] as String? ?? '',
// // //       displayName: other['display_name'] as String? ?? 'Player',
// // //       username: other['username'] as String?,
// // //       avatarUrl: other['avatar_url'] as String?,
// // //       avatarConfig: other['avatar_config'] != null
// // //           ? Map<String, dynamic>.from(other['avatar_config'] as Map)
// // //           : null,
// // //       isPremium: other['is_premium'] as bool? ?? false,
// // //       status: FriendshipStatus.values.firstWhere(
// // //         (s) => s.name == (row['status'] as String? ?? ''),
// // //         orElse: () => FriendshipStatus.pending,
// // //       ),
// // //       isRequester: isRequester,
// // //     );
// // //   }

// // //   FollowEntity _toFollowEntity(
// // //     Map<String, dynamic> row, {
// // //     bool followingMode = false,
// // //   }) {
// // //     final profile =
// // //         row[followingMode ? 'profiles!followee_id' : 'profiles!follower_id']
// // //             as Map<String, dynamic>? ??
// // //         {};
// // //     return FollowEntity(
// // //       userId: profile['id'] as String? ?? '',
// // //       displayName: profile['display_name'] as String? ?? 'User',
// // //       username: profile['username'] as String?,
// // //       avatarUrl: profile['avatar_url'] as String?,
// // //       avatarConfig: profile['avatar_config'] != null
// // //           ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
// // //           : null,
// // //       isPremium: profile['is_premium'] as bool? ?? false,
// // //       followedAt: DateTime.parse(row['created_at'] as String),
// // //       isVerified: profile['verification_status'] == 'verified',
// // //     );
// // //   }
// // // }

// // // import '../../../features/auth/domain/entities/user_entity.dart';

// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import '../../../core/data/base_repository.dart';
// // import '../../../core/errors/failures.dart';
// // import '../../../features/auth/domain/entities/user_entity.dart';

// // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // class FriendEntity {
// //   const FriendEntity({
// //     required this.userId,
// //     required this.displayName,
// //     this.username,
// //     this.avatarUrl,
// //     this.avatarConfig,
// //     this.isPremium = false,
// //     required this.status,
// //     required this.isRequester,
// //     this.mutualFriendsCount = 0,
// //     this.friendshipId,
// //   });

// //   final String userId;
// //   final String displayName;
// //   final String? username;
// //   final String? avatarUrl;
// //   final Map<String, dynamic>? avatarConfig;
// //   final bool isPremium;
// //   final FriendshipStatus status;
// //   final bool isRequester;
// //   final int mutualFriendsCount;
// //   final String? friendshipId;

// //   bool get isAccepted => status == FriendshipStatus.accepted;
// //   bool get isPending => status == FriendshipStatus.pending;
// // }

// // class FollowEntity {
// //   const FollowEntity({
// //     required this.userId,
// //     required this.displayName,
// //     this.username,
// //     this.avatarUrl,
// //     this.avatarConfig,
// //     this.isPremium = false,
// //     required this.followedAt,
// //     this.isVerified = false,
// //   });

// //   final String userId;
// //   final String displayName;
// //   final String? username;
// //   final String? avatarUrl;
// //   final Map<String, dynamic>? avatarConfig;
// //   final bool isPremium;
// //   final DateTime followedAt;
// //   final bool isVerified;
// // }

// // class SocialProfile {
// //   const SocialProfile({
// //     required this.userId,
// //     required this.displayName,
// //     this.username,
// //     this.avatarUrl,
// //     this.avatarConfig,
// //     this.isPremium = false,
// //     this.bio,
// //     required this.followersCount,
// //     required this.followingCount,
// //     required this.friendsCount,
// //     this.gamesPlayed = 0,
// //     this.packsCount = 0,
// //     this.friendshipStatus,
// //     this.isFollowing = false,
// //     this.isFollowedBy = false,
// //     this.isBlocked = false,
// //     this.isBlockedBy = false,
// //     this.isVerified = false,
// //   });

// //   final String userId;
// //   final String displayName;
// //   final String? username;
// //   final String? avatarUrl;
// //   final Map<String, dynamic>? avatarConfig;
// //   final bool isPremium;
// //   final String? bio;
// //   final int followersCount;
// //   final int followingCount;
// //   final int friendsCount;
// //   final int gamesPlayed;
// //   final int packsCount;
// //   final FriendshipStatus? friendshipStatus;
// //   final bool isFollowing;
// //   final bool isFollowedBy;
// //   final bool isBlocked;
// //   final bool isBlockedBy;
// //   final bool isVerified;

// //   bool get canInteract => !isBlocked && !isBlockedBy;
// // }

// // class FriendsRepository extends BaseRepository {
// //   FriendsRepository._();
// //   static final FriendsRepository _instance = FriendsRepository._();
// //   static FriendsRepository get instance => _instance;

// //   final _supabase = Supabase.instance.client;

// //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// //     operationName: 'getFriends',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('friendships')
// //           .select(
// //             'id,status,requester_id,addressee_id,'
// //             'requester:profiles!requester_id(id,display_name,username,avatar_url,avatar_config,is_premium),'
// //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url,avatar_config,is_premium)',
// //           )
// //           .or('requester_id.eq.$userId,addressee_id.eq.$userId')
// //           .eq('status', 'accepted');
// //       return rows.map((r) => _toFriendEntity(r, userId)).toList();
// //     },
// //   );

// //   Future<List<FriendEntity>> getPendingRequests(String userId) => guardedCall(
// //     operationName: 'getPendingRequests',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('friendships')
// //           .select('id,status,requester_id,addressee_id')
// //           .eq('addressee_id', userId)
// //           .eq('status', 'pending');
// //       if ((rows as List).isEmpty) return [];
// //       final requesterIds = rows
// //           .map((r) => r['requester_id'] as String)
// //           .toList();
// //       final profiles = await _supabase
// //           .from('profiles')
// //           .select(
// //             'id,display_name,username,avatar_url,avatar_config,is_premium',
// //           )
// //           .inFilter('id', requesterIds);
// //       final profileMap = {
// //         for (final p in profiles as List)
// //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// //       };
// //       return rows.map((r) {
// //         final row = Map<String, dynamic>.from(r as Map);
// //         row['requester'] = profileMap[row['requester_id']] ?? {};
// //         return _toFriendEntity(row, userId);
// //       }).toList();
// //     },
// //   );

// //   Future<List<FriendEntity>> getSentRequests(String userId) => guardedCall(
// //     operationName: 'getSentRequests',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('friendships')
// //           .select('id,status,requester_id,addressee_id')
// //           .eq('requester_id', userId)
// //           .eq('status', 'pending');
// //       if ((rows as List).isEmpty) return [];
// //       final addresseeIds = rows
// //           .map((r) => r['addressee_id'] as String)
// //           .toList();
// //       final profiles = await _supabase
// //           .from('profiles')
// //           .select(
// //             'id,display_name,username,avatar_url,avatar_config,is_premium',
// //           )
// //           .inFilter('id', addresseeIds);
// //       final profileMap = {
// //         for (final p in profiles as List)
// //           p['id'] as String: Map<String, dynamic>.from(p as Map),
// //       };
// //       return rows.map((r) {
// //         final row = Map<String, dynamic>.from(r as Map);
// //         row['addressee'] = profileMap[row['addressee_id']] ?? {};
// //         return _toFriendEntity(row, userId);
// //       }).toList();
// //     },
// //   );

// //   Future<void> sendFriendRequest({
// //     required String requesterId,
// //     required String addresseeId,
// //   }) => guardedCall(
// //     operationName: 'sendFriendRequest',
// //     operation: () async {
// //       await _checkNotBlocked(requesterId, addresseeId);
// //       await _supabase.from('friendships').insert({
// //         'requester_id': requesterId,
// //         'addressee_id': addresseeId,
// //         'status': 'pending',
// //       });
// //     },
// //   );

// //   Future<void> respondToRequest({
// //     required String requesterId,
// //     required String addresseeId,
// //     required bool accept,
// //   }) => guardedCall(
// //     operationName: 'respondToRequest',
// //     operation: () async {
// //       await _supabase
// //           .from('friendships')
// //           .update({'status': accept ? 'accepted' : 'rejected'})
// //           .eq('requester_id', requesterId)
// //           .eq('addressee_id', addresseeId);
// //     },
// //   );

// //   Future<void> removeFriend({
// //     required String userId,
// //     required String friendId,
// //   }) => guardedCall(
// //     operationName: 'removeFriend',
// //     operation: () async {
// //       await _supabase
// //           .from('friendships')
// //           .delete()
// //           .or(
// //             'and(requester_id.eq.$userId,addressee_id.eq.$friendId),'
// //             'and(requester_id.eq.$friendId,addressee_id.eq.$userId)',
// //           );
// //     },
// //   );

// //   Future<void> cancelRequest({
// //     required String requesterId,
// //     required String addresseeId,
// //   }) => guardedCall(
// //     operationName: 'cancelRequest',
// //     operation: () async {
// //       await _supabase
// //           .from('friendships')
// //           .delete()
// //           .eq('requester_id', requesterId)
// //           .eq('addressee_id', addresseeId)
// //           .eq('status', 'pending');
// //     },
// //   );

// //   Future<void> followUser(String followerId, String followingId) => guardedCall(
// //     operationName: 'followUser',
// //     operation: () async {
// //       await _checkNotBlocked(followerId, followingId);
// //       await _supabase.from('follows').upsert({
// //         'follower_id': followerId,
// //         'followee_id': followingId,
// //       }, onConflict: 'follower_id,followee_id');
// //     },
// //   );

// //   Future<void> unfollowUser(String followerId, String followingId) =>
// //       guardedCall(
// //         operationName: 'unfollowUser',
// //         operation: () async {
// //           await _supabase
// //               .from('follows')
// //               .delete()
// //               .eq('follower_id', followerId)
// //               .eq('followee_id', followingId);
// //         },
// //       );

// //   Future<List<FollowEntity>> getFollowers(
// //     String userId, {
// //     int limit = 50,
// //   }) => guardedCall(
// //     operationName: 'getFollowers',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('follows')
// //           .select(
// //             'follower_id,created_at,'
// //             'profiles!follower_id(id,display_name,username,avatar_url,avatar_config,is_premium,verification_status)',
// //           )
// //           .eq('followee_id', userId)
// //           .order('created_at', ascending: false)
// //           .limit(limit);
// //       return rows.map(_toFollowEntity).toList();
// //     },
// //   );

// //   Future<List<FollowEntity>> getFollowing(
// //     String userId, {
// //     int limit = 50,
// //   }) => guardedCall(
// //     operationName: 'getFollowing',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('follows')
// //           .select(
// //             'followee_id,created_at,'
// //             'profiles!followee_id(id,display_name,username,avatar_url,avatar_config,is_premium,verification_status)',
// //           )
// //           .eq('follower_id', userId)
// //           .order('created_at', ascending: false)
// //           .limit(limit);
// //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// //     },
// //   );

// //   Future<void> blockUser({
// //     required String blockerId,
// //     required String blockedId,
// //   }) => guardedCall(
// //     operationName: 'blockUser',
// //     operation: () async {
// //       await _supabase.from('blocked_users').upsert({
// //         'blocker_id': blockerId,
// //         'blocked_id': blockedId,
// //       }, onConflict: 'blocker_id,blocked_id');
// //       await removeFriend(
// //         userId: blockerId,
// //         friendId: blockedId,
// //       ).catchError((_) {});
// //       await unfollowUser(blockerId, blockedId).catchError((_) {});
// //       await unfollowUser(blockedId, blockerId).catchError((_) {});
// //     },
// //   );

// //   Future<void> unblockUser({
// //     required String blockerId,
// //     required String blockedId,
// //   }) => guardedCall(
// //     operationName: 'unblockUser',
// //     operation: () async {
// //       await _supabase
// //           .from('blocked_users')
// //           .delete()
// //           .eq('blocker_id', blockerId)
// //           .eq('blocked_id', blockedId);
// //     },
// //   );

// //   Future<List<FriendEntity>> getBlockedUsers(String userId) => guardedCall(
// //     operationName: 'getBlockedUsers',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('blocked_users')
// //           .select(
// //             'blocked_id,created_at,'
// //             'profiles!blocked_id(id,display_name,username,avatar_url,avatar_config,is_premium)',
// //           )
// //           .eq('blocker_id', userId)
// //           .order('created_at', ascending: false);
// //       return rows.map((r) {
// //         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
// //         return FriendEntity(
// //           userId: profile['id'] as String? ?? '',
// //           displayName: profile['display_name'] as String? ?? 'User',
// //           username: profile['username'] as String?,
// //           avatarUrl: profile['avatar_url'] as String?,
// //           avatarConfig: profile['avatar_config'] != null
// //               ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
// //               : null,
// //           isPremium: profile['is_premium'] as bool? ?? false,
// //           status: FriendshipStatus.blocked,
// //           isRequester: true,
// //         );
// //       }).toList();
// //     },
// //   );

// //   Future<SocialProfile> getSocialProfile({
// //     required String targetUserId,
// //     required String viewerUserId,
// //   }) => guardedCall(
// //     operationName: 'getSocialProfile',
// //     operation: () async {
// //       final profileRows = await _supabase
// //           .from('profiles_public')
// //           .select()
// //           .eq('id', targetUserId)
// //           .limit(1);
// //       Map<String, dynamic>? profile = profileRows.isNotEmpty
// //           ? profileRows.first as Map<String, dynamic>
// //           : null;

// //       if (profile == null) {
// //         final fallbackRows = await _supabase
// //             .from('profiles')
// //             .select(
// //               'id, display_name, username, avatar_url, avatar_config, is_premium, bio',
// //             )
// //             .eq('id', targetUserId)
// //             .limit(1);
// //         profile = fallbackRows.isNotEmpty
// //             ? fallbackRows.first as Map<String, dynamic>
// //             : null;
// //       }
// //       if (profile == null) throw Exception('Profile not found');

// //       final hasFullData = profile.containsKey('followers_count');
// //       if (!hasFullData) {
// //         return SocialProfile(
// //           userId: profile['id'] as String,
// //           displayName: profile['display_name'] as String? ?? 'Player',
// //           username: profile['username'] as String?,
// //           avatarUrl: profile['avatar_url'] as String?,
// //           avatarConfig: profile['avatar_config'] != null
// //               ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
// //               : null,
// //           isPremium: profile['is_premium'] as bool? ?? false,
// //           bio: profile['bio'] as String?,
// //           followersCount: 0,
// //           followingCount: 0,
// //           friendsCount: 0,
// //           gamesPlayed: 0,
// //           packsCount: 0,
// //         );
// //       }

// //       final [
// //         blockedByMe,
// //         blockedByThem,
// //         friendshipRow,
// //         followingRow,
// //         followedByRow,
// //       ] = await Future.wait([
// //         _supabase
// //             .from('blocked_users')
// //             .select('blocker_id')
// //             .eq('blocker_id', viewerUserId)
// //             .eq('blocked_id', targetUserId)
// //             .maybeSingle(),
// //         _supabase
// //             .from('blocked_users')
// //             .select('blocker_id')
// //             .eq('blocker_id', targetUserId)
// //             .eq('blocked_id', viewerUserId)
// //             .maybeSingle(),
// //         _supabase
// //             .from('friendships')
// //             .select('status')
// //             .or(
// //               'and(requester_id.eq.$viewerUserId,addressee_id.eq.$targetUserId),'
// //               'and(requester_id.eq.$targetUserId,addressee_id.eq.$viewerUserId)',
// //             )
// //             .maybeSingle(),
// //         _supabase
// //             .from('follows')
// //             .select('follower_id')
// //             .eq('follower_id', viewerUserId)
// //             .eq('followee_id', targetUserId)
// //             .maybeSingle(),
// //         _supabase
// //             .from('follows')
// //             .select('follower_id')
// //             .eq('follower_id', targetUserId)
// //             .eq('followee_id', viewerUserId)
// //             .maybeSingle(),
// //       ]);

// //       FriendshipStatus? friendStatus;
// //       if (friendshipRow != null) {
// //         friendStatus = FriendshipStatus.values.firstWhere(
// //           (s) => s.name == (friendshipRow as Map)['status'],
// //           orElse: () => FriendshipStatus.pending,
// //         );
// //       }

// //       return SocialProfile(
// //         userId: profile['id'] as String,
// //         displayName: profile['display_name'] as String? ?? 'User',
// //         username: profile['username'] as String?,
// //         avatarUrl: profile['avatar_url'] as String?,
// //         avatarConfig: profile['avatar_config'] != null
// //             ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
// //             : null,
// //         isPremium: profile['is_premium'] as bool? ?? false,
// //         bio: profile['bio'] as String?,
// //         followersCount: (profile['followers_count'] as num?)?.toInt() ?? 0,
// //         followingCount: (profile['following_count'] as num?)?.toInt() ?? 0,
// //         friendsCount: (profile['friends_count'] as num?)?.toInt() ?? 0,
// //         gamesPlayed: (profile['games_played'] as num?)?.toInt() ?? 0,
// //         packsCount: (profile['packs_count'] as num?)?.toInt() ?? 0,
// //         friendshipStatus: friendStatus,
// //         isFollowing: followingRow != null,
// //         isFollowedBy: followedByRow != null,
// //         isBlocked: blockedByMe != null,
// //         isBlockedBy: blockedByThem != null,
// //         isVerified: profile['verification_status'] == 'verified',
// //       );
// //     },
// //   );

// //   Future<List<UserEntity>> searchUsers(
// //     String query, {
// //     required String excludeUserId,
// //     int limit = 20,
// //   }) => guardedCall(
// //     operationName: 'searchUsers',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('profiles_public')
// //           .select(
// //             'id,username,display_name,avatar_url,avatar_config,is_premium',
// //           )
// //           .or('username.ilike.%$query%,display_name.ilike.%$query%')
// //           .neq('id', excludeUserId)
// //           .limit(limit);
// //       return rows
// //           .map(
// //             (r) => UserEntity(
// //               id: r['id'] as String,
// //               email: '',
// //               username: r['username'] as String?,
// //               displayName: r['display_name'] as String?,
// //               avatarUrl: r['avatar_url'] as String?,
// //               avatarConfig: r['avatar_config'] != null
// //                   ? Map<String, dynamic>.from(r['avatar_config'] as Map)
// //                   : null,
// //               isPremium: r['is_premium'] as bool? ?? false,
// //               // avatarConfig: r['avatar_config'] != null ? Map<String, dynamic>.from(r['avatar_config'] as Map) : null,
// //               // isPremium: r['is_premium'] as bool? ?? false,
// //             ),
// //           )
// //           .toList();
// //     },
// //   );

// //   Future<FriendEntity?> getFriendshipStatus({
// //     required String userId,
// //     required String otherId,
// //   }) => guardedCall(
// //     operationName: 'getFriendshipStatus',
// //     operation: () async {
// //       final row = await _supabase
// //           .from('friendships')
// //           .select()
// //           .or(
// //             'and(requester_id.eq.$userId,addressee_id.eq.$otherId),'
// //             'and(requester_id.eq.$otherId,addressee_id.eq.$userId)',
// //           )
// //           .maybeSingle();
// //       if (row == null) return null;
// //       return FriendEntity(
// //         userId: otherId,
// //         displayName: '',
// //         status: FriendshipStatus.values.firstWhere(
// //           (s) => s.name == (row['status'] as String? ?? 'pending'),
// //           orElse: () => FriendshipStatus.pending,
// //         ),
// //         isRequester: (row['requester_id'] as String?) == userId,
// //         friendshipId: row['id'] as String?,
// //       );
// //     },
// //   );

// //   Future<void> _checkNotBlocked(String a, String b) async {
// //     try {
// //       final block = await _supabase
// //           .from('blocked_users')
// //           .select('blocker_id')
// //           .or(
// //             'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// //             'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// //           )
// //           .maybeSingle();
// //       if (block != null) {
// //         throw const ForbiddenFailure(
// //           message: 'Cannot interact with this user.',
// //         );
// //       }
// //     } on ForbiddenFailure {
// //       rethrow;
// //     } catch (_) {}
// //   }

// //   FriendEntity _toFriendEntity(Map<String, dynamic> row, String currentUserId) {
// //     final requesterId = row['requester_id'] as String? ?? '';
// //     final isRequester = requesterId == currentUserId;
// //     final rawOther = isRequester ? row['addressee'] : row['requester'];
// //     final other = (rawOther is Map)
// //         ? Map<String, dynamic>.from(rawOther)
// //         : <String, dynamic>{};
// //     return FriendEntity(
// //       friendshipId: row['id'] as String?,
// //       userId: other['id'] as String? ?? '',
// //       displayName: other['display_name'] as String? ?? 'Player',
// //       username: other['username'] as String?,
// //       avatarUrl: other['avatar_url'] as String?,
// //       avatarConfig: other['avatar_config'] != null
// //           ? Map<String, dynamic>.from(other['avatar_config'] as Map)
// //           : null,
// //       isPremium: other['is_premium'] as bool? ?? false,
// //       status: FriendshipStatus.values.firstWhere(
// //         (s) => s.name == (row['status'] as String? ?? ''),
// //         orElse: () => FriendshipStatus.pending,
// //       ),
// //       isRequester: isRequester,
// //     );
// //   }

// //   FollowEntity _toFollowEntity(
// //     Map<String, dynamic> row, {
// //     bool followingMode = false,
// //   }) {
// //     final profile =
// //         row[followingMode ? 'profiles!followee_id' : 'profiles!follower_id']
// //             as Map<String, dynamic>? ??
// //         {};
// //     return FollowEntity(
// //       userId: profile['id'] as String? ?? '',
// //       displayName: profile['display_name'] as String? ?? 'User',
// //       username: profile['username'] as String?,
// //       avatarUrl: profile['avatar_url'] as String?,
// //       avatarConfig: profile['avatar_config'] != null
// //           ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
// //           : null,
// //       isPremium: profile['is_premium'] as bool? ?? false,
// //       followedAt: DateTime.parse(row['created_at'] as String),
// //       isVerified: profile['verification_status'] == 'verified',
// //     );
// //   }
// // }

// // import '../../../features/auth/domain/entities/user_entity.dart';

// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../../core/data/base_repository.dart';
// import '../../../core/errors/failures.dart';
// import '../../../features/auth/domain/entities/user_entity.dart';

// enum FriendshipStatus { pending, accepted, rejected, blocked }

// class FriendEntity {
//   const FriendEntity({
//     required this.userId,
//     required this.displayName,
//     this.username,
//     this.avatarUrl,
//     this.avatarConfig,
//     this.isPremium = false,
//     required this.status,
//     required this.isRequester,
//     this.mutualFriendsCount = 0,
//     this.friendshipId,
//   });

//   final String userId;
//   final String displayName;
//   final String? username;
//   final String? avatarUrl;
//   final Map<String, dynamic>? avatarConfig;
//   final bool isPremium;
//   final FriendshipStatus status;
//   final bool isRequester;
//   final int mutualFriendsCount;
//   final String? friendshipId;

//   bool get isAccepted => status == FriendshipStatus.accepted;
//   bool get isPending => status == FriendshipStatus.pending;
// }

// class FollowEntity {
//   const FollowEntity({
//     required this.userId,
//     required this.displayName,
//     this.username,
//     this.avatarUrl,
//     this.avatarConfig,
//     this.isPremium = false,
//     required this.followedAt,
//     this.isVerified = false,
//   });

//   final String userId;
//   final String displayName;
//   final String? username;
//   final String? avatarUrl;
//   final Map<String, dynamic>? avatarConfig;
//   final bool isPremium;
//   final DateTime followedAt;
//   final bool isVerified;
// }

// class SocialProfile {
//   const SocialProfile({
//     required this.userId,
//     required this.displayName,
//     this.username,
//     this.avatarUrl,
//     this.avatarConfig,
//     this.isPremium = false,
//     this.bio,
//     required this.followersCount,
//     required this.followingCount,
//     required this.friendsCount,
//     this.gamesPlayed = 0,
//     this.packsCount = 0,
//     this.friendshipStatus,
//     this.isFollowing = false,
//     this.isFollowedBy = false,
//     this.isBlocked = false,
//     this.isBlockedBy = false,
//     this.isVerified = false,
//   });

//   final String userId;
//   final String displayName;
//   final String? username;
//   final String? avatarUrl;
//   final Map<String, dynamic>? avatarConfig;
//   final bool isPremium;
//   final String? bio;
//   final int followersCount;
//   final int followingCount;
//   final int friendsCount;
//   final int gamesPlayed;
//   final int packsCount;
//   final FriendshipStatus? friendshipStatus;
//   final bool isFollowing;
//   final bool isFollowedBy;
//   final bool isBlocked;
//   final bool isBlockedBy;
//   final bool isVerified;

//   bool get canInteract => !isBlocked && !isBlockedBy;
// }

// class FriendsRepository extends BaseRepository {
//   FriendsRepository._();
//   static final FriendsRepository _instance = FriendsRepository._();
//   static FriendsRepository get instance => _instance;

//   final _supabase = Supabase.instance.client;

//   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
//     operationName: 'getFriends',
//     operation: () async {
//       final rows = await _supabase
//           .from('friendships')
//           .select(
//             'id,status,requester_id,addressee_id,'
//             'requester:profiles!requester_id(id,display_name,username,avatar_url,avatar_config,is_premium),'
//             'addressee:profiles!addressee_id(id,display_name,username,avatar_url,avatar_config,is_premium)',
//           )
//           .or('requester_id.eq.$userId,addressee_id.eq.$userId')
//           .eq('status', 'accepted');
//       return rows.map((r) => _toFriendEntity(r, userId)).toList();
//     },
//   );

//   Future<List<FriendEntity>> getPendingRequests(String userId) => guardedCall(
//     operationName: 'getPendingRequests',
//     operation: () async {
//       final rows = await _supabase
//           .from('friendships')
//           .select('id,status,requester_id,addressee_id')
//           .eq('addressee_id', userId)
//           .eq('status', 'pending');
//       if ((rows as List).isEmpty) return [];
//       final requesterIds = rows
//           .map((r) => r['requester_id'] as String)
//           .toList();
//       final profiles = await _supabase
//           .from('profiles')
//           .select(
//             'id,display_name,username,avatar_url,avatar_config,is_premium',
//           )
//           .inFilter('id', requesterIds);
//       final profileMap = {
//         for (final p in profiles as List)
//           p['id'] as String: Map<String, dynamic>.from(p as Map),
//       };
//       return rows.map((r) {
//         final row = Map<String, dynamic>.from(r as Map);
//         row['requester'] = profileMap[row['requester_id']] ?? {};
//         return _toFriendEntity(row, userId);
//       }).toList();
//     },
//   );

//   Future<List<FriendEntity>> getSentRequests(String userId) => guardedCall(
//     operationName: 'getSentRequests',
//     operation: () async {
//       final rows = await _supabase
//           .from('friendships')
//           .select('id,status,requester_id,addressee_id')
//           .eq('requester_id', userId)
//           .eq('status', 'pending');
//       if ((rows as List).isEmpty) return [];
//       final addresseeIds = rows
//           .map((r) => r['addressee_id'] as String)
//           .toList();
//       final profiles = await _supabase
//           .from('profiles')
//           .select(
//             'id,display_name,username,avatar_url,avatar_config,is_premium',
//           )
//           .inFilter('id', addresseeIds);
//       final profileMap = {
//         for (final p in profiles as List)
//           p['id'] as String: Map<String, dynamic>.from(p as Map),
//       };
//       return rows.map((r) {
//         final row = Map<String, dynamic>.from(r as Map);
//         row['addressee'] = profileMap[row['addressee_id']] ?? {};
//         return _toFriendEntity(row, userId);
//       }).toList();
//     },
//   );

//   Future<void> sendFriendRequest({
//     required String requesterId,
//     required String addresseeId,
//   }) => guardedCall(
//     operationName: 'sendFriendRequest',
//     operation: () async {
//       await _checkNotBlocked(requesterId, addresseeId);
//       await _supabase.from('friendships').insert({
//         'requester_id': requesterId,
//         'addressee_id': addresseeId,
//         'status': 'pending',
//       });
//     },
//   );

//   Future<void> respondToRequest({
//     required String requesterId,
//     required String addresseeId,
//     required bool accept,
//   }) => guardedCall(
//     operationName: 'respondToRequest',
//     operation: () async {
//       await _supabase
//           .from('friendships')
//           .update({'status': accept ? 'accepted' : 'rejected'})
//           .eq('requester_id', requesterId)
//           .eq('addressee_id', addresseeId);
//     },
//   );

//   Future<void> removeFriend({
//     required String userId,
//     required String friendId,
//   }) => guardedCall(
//     operationName: 'removeFriend',
//     operation: () async {
//       await _supabase
//           .from('friendships')
//           .delete()
//           .or(
//             'and(requester_id.eq.$userId,addressee_id.eq.$friendId),'
//             'and(requester_id.eq.$friendId,addressee_id.eq.$userId)',
//           );
//     },
//   );

//   Future<void> cancelRequest({
//     required String requesterId,
//     required String addresseeId,
//   }) => guardedCall(
//     operationName: 'cancelRequest',
//     operation: () async {
//       await _supabase
//           .from('friendships')
//           .delete()
//           .eq('requester_id', requesterId)
//           .eq('addressee_id', addresseeId)
//           .eq('status', 'pending');
//     },
//   );

//   Future<void> followUser(String followerId, String followingId) => guardedCall(
//     operationName: 'followUser',
//     operation: () async {
//       await _checkNotBlocked(followerId, followingId);
//       await _supabase.from('follows').upsert({
//         'follower_id': followerId,
//         'followee_id': followingId,
//       }, onConflict: 'follower_id,followee_id');
//     },
//   );

//   Future<void> unfollowUser(String followerId, String followingId) =>
//       guardedCall(
//         operationName: 'unfollowUser',
//         operation: () async {
//           await _supabase
//               .from('follows')
//               .delete()
//               .eq('follower_id', followerId)
//               .eq('followee_id', followingId);
//         },
//       );

//   Future<List<FollowEntity>> getFollowers(
//     String userId, {
//     int limit = 50,
//   }) => guardedCall(
//     operationName: 'getFollowers',
//     operation: () async {
//       final rows = await _supabase
//           .from('follows')
//           .select(
//             'follower_id,created_at,'
//             'profiles!follower_id(id,display_name,username,avatar_url,avatar_config,is_premium,verification_status)',
//           )
//           .eq('followee_id', userId)
//           .order('created_at', ascending: false)
//           .limit(limit);
//       return rows.map(_toFollowEntity).toList();
//     },
//   );

//   Future<List<FollowEntity>> getFollowing(
//     String userId, {
//     int limit = 50,
//   }) => guardedCall(
//     operationName: 'getFollowing',
//     operation: () async {
//       final rows = await _supabase
//           .from('follows')
//           .select(
//             'followee_id,created_at,'
//             'profiles!followee_id(id,display_name,username,avatar_url,avatar_config,is_premium,verification_status)',
//           )
//           .eq('follower_id', userId)
//           .order('created_at', ascending: false)
//           .limit(limit);
//       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
//     },
//   );

//   Future<void> blockUser({
//     required String blockerId,
//     required String blockedId,
//   }) => guardedCall(
//     operationName: 'blockUser',
//     operation: () async {
//       await _supabase.from('blocked_users').upsert({
//         'blocker_id': blockerId,
//         'blocked_id': blockedId,
//       }, onConflict: 'blocker_id,blocked_id');
//       await removeFriend(
//         userId: blockerId,
//         friendId: blockedId,
//       ).catchError((_) {});
//       await unfollowUser(blockerId, blockedId).catchError((_) {});
//       await unfollowUser(blockedId, blockerId).catchError((_) {});
//     },
//   );

//   Future<void> unblockUser({
//     required String blockerId,
//     required String blockedId,
//   }) => guardedCall(
//     operationName: 'unblockUser',
//     operation: () async {
//       await _supabase
//           .from('blocked_users')
//           .delete()
//           .eq('blocker_id', blockerId)
//           .eq('blocked_id', blockedId);
//     },
//   );

//   Future<List<FriendEntity>> getBlockedUsers(String userId) => guardedCall(
//     operationName: 'getBlockedUsers',
//     operation: () async {
//       final rows = await _supabase
//           .from('blocked_users')
//           .select(
//             'blocked_id,created_at,'
//             'profiles!blocked_id(id,display_name,username,avatar_url,avatar_config,is_premium)',
//           )
//           .eq('blocker_id', userId)
//           .order('created_at', ascending: false);
//       return rows.map((r) {
//         final profile = r['profiles'] as Map<String, dynamic>? ?? {};
//         return FriendEntity(
//           userId: profile['id'] as String? ?? '',
//           displayName: profile['display_name'] as String? ?? 'User',
//           username: profile['username'] as String?,
//           avatarUrl: profile['avatar_url'] as String?,
//           avatarConfig: profile['avatar_config'] != null
//               ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
//               : null,
//           isPremium: profile['is_premium'] as bool? ?? false,
//           status: FriendshipStatus.blocked,
//           isRequester: true,
//         );
//       }).toList();
//     },
//   );

//   Future<SocialProfile> getSocialProfile({
//     required String targetUserId,
//     required String viewerUserId,
//   }) => guardedCall(
//     operationName: 'getSocialProfile',
//     operation: () async {
//       final profileRows = await _supabase
//           .from('profiles_public')
//           .select()
//           .eq('id', targetUserId)
//           .limit(1);
//       Map<String, dynamic>? profile = profileRows.isNotEmpty
//           ? Map<String, dynamic>.from(profileRows.first as Map)
//           : null;

//       if (profile == null) {
//         final fallbackRows = await _supabase
//             .from('profiles')
//             .select(
//               'id, display_name, username, avatar_url, avatar_config, is_premium, bio',
//             )
//             .eq('id', targetUserId)
//             .limit(1);
//         profile = fallbackRows.isNotEmpty
//             ? Map<String, dynamic>.from(fallbackRows.first as Map)
//             : null;
//       }
//       if (profile == null) throw Exception('Profile not found');

//       if (!profile.containsKey('avatar_config') ||
//           !profile.containsKey('is_premium')) {
//         final avatarRows = await _supabase
//             .from('profiles')
//             .select('avatar_config, is_premium')
//             .eq('id', targetUserId)
//             .limit(1);
//         if (avatarRows.isNotEmpty) {
//           profile['avatar_config'] = avatarRows.first['avatar_config'];
//           profile['is_premium'] = avatarRows.first['is_premium'];
//         }
//       }

//       final hasFullData = profile.containsKey('followers_count');
//       if (!hasFullData) {
//         return SocialProfile(
//           userId: profile['id'] as String,
//           displayName: profile['display_name'] as String? ?? 'Player',
//           username: profile['username'] as String?,
//           avatarUrl: profile['avatar_url'] as String?,
//           avatarConfig: profile['avatar_config'] != null
//               ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
//               : null,
//           isPremium: profile['is_premium'] as bool? ?? false,
//           bio: profile['bio'] as String?,
//           followersCount: 0,
//           followingCount: 0,
//           friendsCount: 0,
//           gamesPlayed: 0,
//           packsCount: 0,
//         );
//       }

//       final [
//         blockedByMe,
//         blockedByThem,
//         friendshipRow,
//         followingRow,
//         followedByRow,
//       ] = await Future.wait([
//         _supabase
//             .from('blocked_users')
//             .select('blocker_id')
//             .eq('blocker_id', viewerUserId)
//             .eq('blocked_id', targetUserId)
//             .maybeSingle(),
//         _supabase
//             .from('blocked_users')
//             .select('blocker_id')
//             .eq('blocker_id', targetUserId)
//             .eq('blocked_id', viewerUserId)
//             .maybeSingle(),
//         _supabase
//             .from('friendships')
//             .select('status')
//             .or(
//               'and(requester_id.eq.$viewerUserId,addressee_id.eq.$targetUserId),'
//               'and(requester_id.eq.$targetUserId,addressee_id.eq.$viewerUserId)',
//             )
//             .maybeSingle(),
//         _supabase
//             .from('follows')
//             .select('follower_id')
//             .eq('follower_id', viewerUserId)
//             .eq('followee_id', targetUserId)
//             .maybeSingle(),
//         _supabase
//             .from('follows')
//             .select('follower_id')
//             .eq('follower_id', targetUserId)
//             .eq('followee_id', viewerUserId)
//             .maybeSingle(),
//       ]);

//       FriendshipStatus? friendStatus;
//       if (friendshipRow != null) {
//         friendStatus = FriendshipStatus.values.firstWhere(
//           (s) => s.name == (friendshipRow as Map)['status'],
//           orElse: () => FriendshipStatus.pending,
//         );
//       }

//       return SocialProfile(
//         userId: profile['id'] as String,
//         displayName: profile['display_name'] as String? ?? 'User',
//         username: profile['username'] as String?,
//         avatarUrl: profile['avatar_url'] as String?,
//         avatarConfig: profile['avatar_config'] != null
//             ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
//             : null,
//         isPremium: profile['is_premium'] as bool? ?? false,
//         bio: profile['bio'] as String?,
//         followersCount: (profile['followers_count'] as num?)?.toInt() ?? 0,
//         followingCount: (profile['following_count'] as num?)?.toInt() ?? 0,
//         friendsCount: (profile['friends_count'] as num?)?.toInt() ?? 0,
//         gamesPlayed: (profile['games_played'] as num?)?.toInt() ?? 0,
//         packsCount: (profile['packs_count'] as num?)?.toInt() ?? 0,
//         friendshipStatus: friendStatus,
//         isFollowing: followingRow != null,
//         isFollowedBy: followedByRow != null,
//         isBlocked: blockedByMe != null,
//         isBlockedBy: blockedByThem != null,
//         isVerified: profile['verification_status'] == 'verified',
//       );
//     },
//   );

//   Future<List<UserEntity>> searchUsers(
//     String query, {
//     required String excludeUserId,
//     int limit = 20,
//   }) => guardedCall(
//     operationName: 'searchUsers',
//     operation: () async {
//       final rows = await _supabase
//           .from('profiles_public')
//           .select(
//             'id,username,display_name,avatar_url,avatar_config,is_premium',
//           )
//           .or('username.ilike.%$query%,display_name.ilike.%$query%')
//           .neq('id', excludeUserId)
//           .limit(limit);
//       return rows
//           .map(
//             (r) => UserEntity(
//               id: r['id'] as String,
//               email: '',
//               username: r['username'] as String?,
//               displayName: r['display_name'] as String?,
//               avatarUrl: r['avatar_url'] as String?,
//               avatarConfig: r['avatar_config'] != null
//                   ? Map<String, dynamic>.from(r['avatar_config'] as Map)
//                   : null,
//               isPremium: r['is_premium'] as bool? ?? false,
//               // avatarConfig: r['avatar_config'] != null
//               //     ? Map<String, dynamic>.from(r['avatar_config'] as Map)
//               //     : null,
//               // isPremium: r['is_premium'] as bool? ?? false,
//             ),
//           )
//           .toList();
//     },
//   );

//   Future<FriendEntity?> getFriendshipStatus({
//     required String userId,
//     required String otherId,
//   }) => guardedCall(
//     operationName: 'getFriendshipStatus',
//     operation: () async {
//       final row = await _supabase
//           .from('friendships')
//           .select()
//           .or(
//             'and(requester_id.eq.$userId,addressee_id.eq.$otherId),'
//             'and(requester_id.eq.$otherId,addressee_id.eq.$userId)',
//           )
//           .maybeSingle();
//       if (row == null) return null;
//       return FriendEntity(
//         userId: otherId,
//         displayName: '',
//         status: FriendshipStatus.values.firstWhere(
//           (s) => s.name == (row['status'] as String? ?? 'pending'),
//           orElse: () => FriendshipStatus.pending,
//         ),
//         isRequester: (row['requester_id'] as String?) == userId,
//         friendshipId: row['id'] as String?,
//       );
//     },
//   );

//   Future<void> _checkNotBlocked(String a, String b) async {
//     try {
//       final block = await _supabase
//           .from('blocked_users')
//           .select('blocker_id')
//           .or(
//             'and(blocker_id.eq.$a,blocked_id.eq.$b),'
//             'and(blocker_id.eq.$b,blocked_id.eq.$a)',
//           )
//           .maybeSingle();
//       if (block != null) {
//         throw const ForbiddenFailure(
//           message: 'Cannot interact with this user.',
//         );
//       }
//     } on ForbiddenFailure {
//       rethrow;
//     } catch (_) {}
//   }

//   FriendEntity _toFriendEntity(Map<String, dynamic> row, String currentUserId) {
//     final requesterId = row['requester_id'] as String? ?? '';
//     final isRequester = requesterId == currentUserId;
//     final rawOther = isRequester ? row['addressee'] : row['requester'];
//     final other = (rawOther is Map)
//         ? Map<String, dynamic>.from(rawOther)
//         : <String, dynamic>{};
//     return FriendEntity(
//       friendshipId: row['id'] as String?,
//       userId: other['id'] as String? ?? '',
//       displayName: other['display_name'] as String? ?? 'Player',
//       username: other['username'] as String?,
//       avatarUrl: other['avatar_url'] as String?,
//       avatarConfig: other['avatar_config'] != null
//           ? Map<String, dynamic>.from(other['avatar_config'] as Map)
//           : null,
//       isPremium: other['is_premium'] as bool? ?? false,
//       status: FriendshipStatus.values.firstWhere(
//         (s) => s.name == (row['status'] as String? ?? ''),
//         orElse: () => FriendshipStatus.pending,
//       ),
//       isRequester: isRequester,
//     );
//   }

//   FollowEntity _toFollowEntity(
//     Map<String, dynamic> row, {
//     bool followingMode = false,
//   }) {
//     final profile =
//         row[followingMode ? 'profiles!followee_id' : 'profiles!follower_id']
//             as Map<String, dynamic>? ??
//         {};
//     return FollowEntity(
//       userId: profile['id'] as String? ?? '',
//       displayName: profile['display_name'] as String? ?? 'User',
//       username: profile['username'] as String?,
//       avatarUrl: profile['avatar_url'] as String?,
//       avatarConfig: profile['avatar_config'] != null
//           ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
//           : null,
//       isPremium: profile['is_premium'] as bool? ?? false,
//       followedAt: DateTime.parse(row['created_at'] as String),
//       isVerified: profile['verification_status'] == 'verified',
//     );
//   }
// }

// import '../../../features/auth/domain/entities/user_entity.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/app_logger.dart';
import '../../../features/auth/domain/entities/user_entity.dart';

enum FriendshipStatus { pending, accepted, rejected, blocked }

class FriendEntity {
  const FriendEntity({
    required this.userId,
    required this.displayName,
    this.username,
    this.avatarUrl,
    this.avatarConfig,
    this.isPremium = false,
    required this.status,
    required this.isRequester,
    this.mutualFriendsCount = 0,
    this.friendshipId,
  });

  final String userId;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? avatarConfig;
  final bool isPremium;
  final FriendshipStatus status;
  final bool isRequester;
  final int mutualFriendsCount;
  final String? friendshipId;

  bool get isAccepted => status == FriendshipStatus.accepted;
  bool get isPending => status == FriendshipStatus.pending;
}

class FollowEntity {
  const FollowEntity({
    required this.userId,
    required this.displayName,
    this.username,
    this.avatarUrl,
    this.avatarConfig,
    this.isPremium = false,
    required this.followedAt,
    this.isVerified = false,
  });

  final String userId;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? avatarConfig;
  final bool isPremium;
  final DateTime followedAt;
  final bool isVerified;
}

class SocialProfile {
  const SocialProfile({
    required this.userId,
    required this.displayName,
    this.username,
    this.avatarUrl,
    this.avatarConfig,
    this.isPremium = false,
    this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.friendsCount,
    this.gamesPlayed = 0,
    this.packsCount = 0,
    this.generalScore = 0,
    this.currentStreak = 0,
    this.honestyPoints = 0,
    this.friendshipStatus,
    this.isFriendshipRequester = false,
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.isBlocked = false,
    this.isBlockedBy = false,
    this.isVerified = false,
    this.isOfficial = false,
  });

  final String userId;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? avatarConfig;
  final bool isPremium;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  final int gamesPlayed;
  final int packsCount;

  /// Task item 4 — server-authoritative (score_events); task item 5 —
  /// from user_streaks. Same public visibility as gamesPlayed/packsCount
  /// above (profiles_public / user_streaks have no per-viewer
  /// restriction beyond banned/deleted).
  final int generalScore;
  final int currentStreak;

  /// Separate ledger from [generalScore] — see honesty_events/
  /// apply_honesty_event(). Same public visibility as the rest of this
  /// bucket. Can be negative.
  final int honestyPoints;
  final FriendshipStatus? friendshipStatus;

  /// True when the VIEWER sent this friendship's request — only
  /// meaningful while [friendshipStatus] is pending. Distinguishes "I
  /// sent this" (cancel makes sense) from "they sent me this" (accept/
  /// reject makes sense), which the status alone can't tell apart.
  final bool isFriendshipRequester;
  final bool isFollowing;
  final bool isFollowedBy;
  final bool isBlocked;
  final bool isBlockedBy;
  final bool isVerified;

  /// The official Jma3a system creator profile
  /// (profiles.is_official_account) — UserProfileScreen renders a
  /// completely different, minimal layout for this (logo, name, verified
  /// badge, packs only) instead of the normal profile UI. Not something a
  /// real user's profile can ever have set.
  final bool isOfficial;

  bool get canInteract => !isBlocked && !isBlockedBy;
}

/// One row from the explore_people() discovery feed — see
/// 20260901090100_explore_people.sql for the full ranking/50%-pool/
/// pagination contract this mirrors. Deliberately reuses the same
/// honesty/score field shape as [SocialProfile] rather than a third DTO;
/// kept as its own lightweight class (not SocialProfile itself) because
/// every candidate here is, by construction, someone with NO existing
/// friendship/block relationship to the viewer — none of SocialProfile's
/// friendship/block/follow fields are meaningful for a row this endpoint
/// can ever return.
class ExplorePerson {
  const ExplorePerson({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.honestyPoints,
    required this.generalScore,
    required this.rankPosition,
    required this.totalEligible,
    required this.discoveryPoolSize,
    this.isOfficial = false,
  });

  final String userId;
  final String? username;
  final String displayName;
  final String? avatarUrl;
  final int honestyPoints;
  final int generalScore;

  /// This candidate's 1-based ordinal in the deterministic
  /// reputation_rank DESC, id ASC ordering — the pagination cursor for
  /// the NEXT page (see FriendsRepository.explorePeople).
  final int rankPosition;
  final int totalEligible;
  final int discoveryPoolSize;

  /// Same flag as SocialProfile.isOfficial (profiles.is_official_account —
  /// see that field's own doc comment). This RPC's own eligibility rules
  /// are out of this app's control (server-side, see explore_people.sql),
  /// so this repo cannot assume the official account is excluded from the
  /// discovery feed. Per current product decision, the official account
  /// must NEVER appear in Discover at all — see [isDiscoverable], which is
  /// the actual filter FriendsProvider/ExplorePersonCard apply. This flag
  /// itself is kept (not removed) because it's still the correct, stable
  /// identifier for that exclusion — never re-derive "is this official"
  /// from displayName or any other heuristic. Read defensively
  /// (`as bool? ?? false`): if the RPC doesn't return this column at all,
  /// every candidate simply falls back to `isOfficial == false`.
  final bool isOfficial;

  /// A profile with a real, chosen username and display name — mirrors
  /// UserEntity.hasCompletedProfile's EXISTING criteria (`username != null
  /// && displayName != null`) rather than inventing a new definition; the
  /// only adaptation is that ExplorePerson.fromMap already collapses a
  /// null display_name to '' at the mapping layer, so "empty" here is
  /// treated the same as "was null" there. Deliberately says nothing
  /// about whether the account is official — see [isDiscoverable] for the
  /// actual "should this ever render in Discover" answer.
  bool get hasCompletedProfile =>
      (username?.trim().isNotEmpty ?? false) && displayName.trim().isNotEmpty;

  /// Whether this candidate should EVER appear anywhere in Discover
  /// Friends — search results, the ranked list, or any future recommended-
  /// people surface built on top of [FriendsRepository.explorePeople]. Two
  /// independent, deliberately separate reasons a row is excluded:
  /// [isOfficial] (current product decision — see this task's own item 1:
  /// Jma3a Official must not be presented as a discoverable user at all,
  /// full stop, not even with special treatment) and an incomplete profile
  /// (item 8, unchanged). This is deliberately a pure, client-side,
  /// defensive check (see FriendsProvider.loadExplorePeople/
  /// loadMoreExplorePeople AND ExplorePersonCard's own top-of-build guard
  /// — both apply it, so a stray render path can never slip through):
  /// whether explore_people() already excludes either case server-side is
  /// not something this repo can verify without a live database, so
  /// filtering happens again here regardless, as the safest available
  /// protection if it doesn't.
  bool get isDiscoverable => !isOfficial && hasCompletedProfile;

  /// Item 1 (Discover-exclusion re-investigation pass) — used by
  /// [FriendsRepository.explorePeople] to correct a row's [isOfficial]
  /// flag after a separate lookup, since explore_people() itself never
  /// returns `is_official_account` (see that method's own doc comment
  /// for the full root-cause explanation). Deliberately narrow (just
  /// this one field) rather than a full generic copyWith — nothing else
  /// in this codebase needs to mutate any other field of a fetched
  /// ExplorePerson.
  ExplorePerson copyWithOfficial(bool isOfficial) => ExplorePerson(
    userId: userId,
    username: username,
    displayName: displayName,
    avatarUrl: avatarUrl,
    honestyPoints: honestyPoints,
    generalScore: generalScore,
    rankPosition: rankPosition,
    totalEligible: totalEligible,
    discoveryPoolSize: discoveryPoolSize,
    isOfficial: isOfficial,
  );

  static ExplorePerson fromMap(Map<String, dynamic> m) => ExplorePerson(
    userId: m['id'] as String,
    username: m['username'] as String?,
    displayName:
        (m['display_name'] as String?) ?? (m['username'] as String?) ?? '',
    avatarUrl: m['avatar_url'] as String?,
    honestyPoints: (m['honesty_points'] as num?)?.toInt() ?? 0,
    generalScore: (m['general_score'] as num?)?.toInt() ?? 0,
    rankPosition: (m['rank_position'] as num?)?.toInt() ?? 0,
    totalEligible: (m['total_eligible'] as num?)?.toInt() ?? 0,
    discoveryPoolSize: (m['discovery_pool_size'] as num?)?.toInt() ?? 0,
    isOfficial: m['is_official_account'] as bool? ?? false,
  );
}

class FriendsRepository extends BaseRepository {
  FriendsRepository._();
  static final FriendsRepository _instance = FriendsRepository._();
  static FriendsRepository get instance => _instance;

  final _supabase = Supabase.instance.client;

  /// Item 2 (official-account re-investigation pass, real-device report:
  /// the account still appeared after the prior is_official_account-only
  /// fix) — a second, INDEPENDENT identifier for the official account,
  /// beyond `profiles.is_official_account`: the single canonical id
  /// recorded in `app_settings.official_creator_profile_id` by the
  /// one-off setup script that creates/maintains this account
  /// (jma3a-api/scripts/createOfficialCreatorAccount.js — see its own
  /// header comment). That script is the ONLY thing that ever sets
  /// `is_official_account = true`; if it was never (re-)run against the
  /// live database, or the flag was reset on that row by some other
  /// operation, the boolean-flag check alone silently finds nothing —
  /// exactly the symptom reported here. This id-based check is
  /// belt-and-suspenders on top of that flag, not a replacement for it:
  /// deliberately NOT a display-name/username heuristic, just a second
  /// stable id already recorded by the app's own setup process. Cached
  /// per repository instance (this pointer never changes at runtime); a
  /// lookup failure is NOT cached, so a transient error doesn't
  /// permanently disable the check for the rest of the app session.
  String? _officialAccountId;

  Future<String?> _fetchOfficialAccountId() async {
    if (_officialAccountId != null) return _officialAccountId;
    try {
      final row = await _supabase
          .from('app_settings')
          .select('value')
          .eq('key', 'official_creator_profile_id')
          .maybeSingle();
      final id = parseOfficialAccountIdValue(row?['value']);
      if (id != null && id.isNotEmpty) _officialAccountId = id;
      return id;
    } catch (e) {
      AppLogger.warning('official account id lookup failed: $e');
      return null;
    }
  }

  Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
    operationName: 'getFriends',
    operation: () async {
      final rows = await _supabase
          .from('friendships')
          .select(
            'id,status,requester_id,addressee_id,'
            'requester:profiles!requester_id(id,display_name,username,avatar_url,avatar_config,is_premium),'
            'addressee:profiles!addressee_id(id,display_name,username,avatar_url,avatar_config,is_premium)',
          )
          .or('requester_id.eq.$userId,addressee_id.eq.$userId')
          .eq('status', 'accepted');
      return rows.map((r) => _toFriendEntity(r, userId)).toList();
    },
  );

  Future<List<FriendEntity>> getPendingRequests(String userId) => guardedCall(
    operationName: 'getPendingRequests',
    operation: () async {
      final rows = await _supabase
          .from('friendships')
          .select('id,status,requester_id,addressee_id')
          .eq('addressee_id', userId)
          .eq('status', 'pending');
      if ((rows as List).isEmpty) return [];
      final requesterIds = rows
          .map((r) => r['requester_id'] as String)
          .toList();
      final profiles = await _supabase
          .from('profiles')
          .select(
            'id,display_name,username,avatar_url,avatar_config,is_premium',
          )
          .inFilter('id', requesterIds);
      final profileMap = {
        for (final p in profiles as List)
          p['id'] as String: Map<String, dynamic>.from(p as Map),
      };
      return rows.map((r) {
        final row = Map<String, dynamic>.from(r as Map);
        row['requester'] = profileMap[row['requester_id']] ?? {};
        return _toFriendEntity(row, userId);
      }).toList();
    },
  );

  Future<List<FriendEntity>> getSentRequests(String userId) => guardedCall(
    operationName: 'getSentRequests',
    operation: () async {
      final rows = await _supabase
          .from('friendships')
          .select('id,status,requester_id,addressee_id')
          .eq('requester_id', userId)
          .eq('status', 'pending');
      if ((rows as List).isEmpty) return [];
      final addresseeIds = rows
          .map((r) => r['addressee_id'] as String)
          .toList();
      final profiles = await _supabase
          .from('profiles')
          .select(
            'id,display_name,username,avatar_url,avatar_config,is_premium',
          )
          .inFilter('id', addresseeIds);
      final profileMap = {
        for (final p in profiles as List)
          p['id'] as String: Map<String, dynamic>.from(p as Map),
      };
      return rows.map((r) {
        final row = Map<String, dynamic>.from(r as Map);
        row['addressee'] = profileMap[row['addressee_id']] ?? {};
        return _toFriendEntity(row, userId);
      }).toList();
    },
  );

  Future<void> sendFriendRequest({
    required String requesterId,
    required String addresseeId,
  }) => guardedCall(
    operationName: 'sendFriendRequest',
    operation: () async {
      await _checkNotOfficial(requesterId, addresseeId);
      await _checkNotBlocked(requesterId, addresseeId);
      // Defense in depth against the "both users request each other"
      // race: the UI's own state can be stale (e.g. before a realtime
      // update lands), so re-check the live relationship state right
      // before inserting rather than trusting only the caller's cache.
      // uq_friendship_unordered_pair backs this up server-side too.
      final existing = await getFriendshipStatus(
        userId: requesterId,
        otherId: addresseeId,
      );
      if (existing != null) {
        throw const ConflictFailure(
          message: 'A friend request already exists between these users.',
        );
      }
      await _supabase.from('friendships').insert({
        'requester_id': requesterId,
        'addressee_id': addresseeId,
        'status': 'pending',
      });
    },
  );

  Future<void> respondToRequest({
    required String requesterId,
    required String addresseeId,
    required bool accept,
  }) => guardedCall(
    operationName: 'respondToRequest',
    operation: () async {
      await _supabase
          .from('friendships')
          .update({'status': accept ? 'accepted' : 'rejected'})
          .eq('requester_id', requesterId)
          .eq('addressee_id', addresseeId);
    },
  );

  Future<void> removeFriend({
    required String userId,
    required String friendId,
  }) => guardedCall(
    operationName: 'removeFriend',
    operation: () async {
      await _supabase
          .from('friendships')
          .delete()
          .or(
            'and(requester_id.eq.$userId,addressee_id.eq.$friendId),'
            'and(requester_id.eq.$friendId,addressee_id.eq.$userId)',
          );
    },
  );

  Future<void> cancelRequest({
    required String requesterId,
    required String addresseeId,
  }) => guardedCall(
    operationName: 'cancelRequest',
    operation: () async {
      await _supabase
          .from('friendships')
          .delete()
          .eq('requester_id', requesterId)
          .eq('addressee_id', addresseeId)
          .eq('status', 'pending');
    },
  );

  Future<void> followUser(String followerId, String followingId) => guardedCall(
    operationName: 'followUser',
    operation: () async {
      await _checkNotBlocked(followerId, followingId);
      await _supabase.from('follows').upsert({
        'follower_id': followerId,
        'followee_id': followingId,
      }, onConflict: 'follower_id,followee_id');
    },
  );

  Future<void> unfollowUser(String followerId, String followingId) =>
      guardedCall(
        operationName: 'unfollowUser',
        operation: () async {
          await _supabase
              .from('follows')
              .delete()
              .eq('follower_id', followerId)
              .eq('followee_id', followingId);
        },
      );

  Future<List<FollowEntity>> getFollowers(
    String userId, {
    int limit = 50,
  }) => guardedCall(
    operationName: 'getFollowers',
    operation: () async {
      final rows = await _supabase
          .from('follows')
          .select(
            'follower_id,created_at,'
            'profiles!follower_id(id,display_name,username,avatar_url,avatar_config,is_premium,verification_status)',
          )
          .eq('followee_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      // Item 8 (followers investigation pass) — diagnostic-grade logging,
      // left in permanently (AppLogger.debug is a no-op in release
      // builds' default log level, same as every other debug() call in
      // this file) so a real-device report of "I have followers but see
      // none" can be root-caused from logs alone next time, without
      // needing live DB access to reproduce. Logs the raw row count and,
      // per row, whether the embedded profile actually resolved — the
      // exact two numbers that distinguish "the follows query itself
      // returned nothing" from "rows came back but every profile embed
      // was null" from "rows + profiles both fine, something later drops
      // them".
      AppLogger.debug(
        'getFollowers($userId): ${rows.length} raw follow row(s)',
      );
      for (final row in rows) {
        final hasProfile = row['profiles'] != null;
        if (!hasProfile) {
          AppLogger.warning(
            'getFollowers($userId): row with follower_id='
            '${row['follower_id']} has a NULL embedded profile — this '
            'follower will show as "User" with no working profile link',
          );
        }
      }
      return mapFollowRowsSafely(
        rows,
        operationName: 'getFollowers',
        toEntity: _toFollowEntity,
      );
    },
  );

  /// Item 4 (this pass) — an exact row count against the SAME table/filter
  /// [getFollowers] itself queries (`follows` where `followee_id = userId`),
  /// so a count shown elsewhere (e.g. ProfileProvider's stats tile) can
  /// never disagree with what FollowersScreen's list actually shows. This
  /// exists because the count was previously read from a separate,
  /// denormalized `profiles_public.followers_count` column — a different
  /// source of truth that this repo cannot verify stays perfectly in sync
  /// with the live `follows` table without a live database, and a mismatch
  /// there is exactly the kind of "stats tile says N, but the list looks
  /// empty/different" symptom that reads as "Followers is broken" even
  /// when the list query itself is working correctly. Uses PostgREST's
  /// dedicated count-only query (HEAD request, no rows fetched) rather than
  /// `getFollowers(...).length`, which would need to fetch and join full
  /// profile rows just to discard them.
  Future<int> getFollowersCount(String userId) => guardedCall(
    operationName: 'getFollowersCount',
    operation: () => _supabase
        .from('follows')
        .count(CountOption.exact)
        .eq('followee_id', userId),
  );

  Future<List<FollowEntity>> getFollowing(
    String userId, {
    int limit = 50,
  }) => guardedCall(
    operationName: 'getFollowing',
    operation: () async {
      final rows = await _supabase
          .from('follows')
          .select(
            'followee_id,created_at,'
            'profiles!followee_id(id,display_name,username,avatar_url,avatar_config,is_premium,verification_status)',
          )
          .eq('follower_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      // Item 8 (followers investigation pass) — same per-row isolation
      // as getFollowers above (see mapFollowRowsSafely's own doc
      // comment): one malformed row must never discard this whole list.
      return mapFollowRowsSafely(
        rows,
        operationName: 'getFollowing',
        toEntity: _toFollowEntity,
      );
    },
  );

  /// Bulk "does [viewerId] already follow each of [otherIds]" — one round
  /// trip, same idiom as [getFriendshipStatuses], so a followers-list
  /// screen can show a correct Follow/Following state per row without an
  /// N+1 query per follower.
  Future<Map<String, bool>> getFollowStatuses({
    required String viewerId,
    required List<String> otherIds,
  }) => guardedCall(
    operationName: 'getFollowStatuses',
    operation: () async {
      if (otherIds.isEmpty) return <String, bool>{};
      final rows = await _supabase
          .from('follows')
          .select('followee_id')
          .eq('follower_id', viewerId)
          .inFilter('followee_id', otherIds);
      final followedIds = rows.map((r) => r['followee_id'] as String).toSet();
      return {for (final id in otherIds) id: followedIds.contains(id)};
    },
  );

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) => guardedCall(
    operationName: 'blockUser',
    operation: () async {
      await _supabase.from('blocked_users').upsert({
        'blocker_id': blockerId,
        'blocked_id': blockedId,
      }, onConflict: 'blocker_id,blocked_id');
      await removeFriend(
        userId: blockerId,
        friendId: blockedId,
      ).catchError((_) {});
      await unfollowUser(blockerId, blockedId).catchError((_) {});
      await unfollowUser(blockedId, blockerId).catchError((_) {});
    },
  );

  /// Item 9 — reports a user's PROFILE. Reuses the same generic `reports`
  /// table (target_type already supports 'profile' — no migration
  /// needed) and the exact same duplicate-handling convention as
  /// PackRepository.reportPack: uq_report (reporter_id, target_type,
  /// target_id) is DEFERRABLE, so Postgres can't take it as an ON
  /// CONFLICT arbiter — a second report for the same user surfaces as a
  /// plain 23505 unique-violation, treated as a silent success (the
  /// reporter has, from their point of view, already reported this
  /// person).
  Future<void> reportUser({
    required String targetUserId,
    required String reporterId,
    required String reason,
    String? details,
  }) => guardedCall(
    operationName: 'reportUser',
    operation: () async {
      try {
        await _supabase.from('reports').insert({
          'target_type': 'profile',
          'target_id': targetUserId,
          'reporter_id': reporterId,
          'reason': reason,
          'details': details,
        });
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow;
      }
    },
  );

  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) => guardedCall(
    operationName: 'unblockUser',
    operation: () async {
      await _supabase
          .from('blocked_users')
          .delete()
          .eq('blocker_id', blockerId)
          .eq('blocked_id', blockedId);
    },
  );

  Future<List<FriendEntity>> getBlockedUsers(String userId) => guardedCall(
    operationName: 'getBlockedUsers',
    operation: () async {
      final rows = await _supabase
          .from('blocked_users')
          .select(
            'blocked_id,created_at,'
            'profiles!blocked_id(id,display_name,username,avatar_url,avatar_config,is_premium)',
          )
          .eq('blocker_id', userId)
          .order('created_at', ascending: false);
      return rows.map((r) {
        final profile = r['profiles'] as Map<String, dynamic>? ?? {};
        return FriendEntity(
          userId: profile['id'] as String? ?? '',
          displayName: profile['display_name'] as String? ?? 'User',
          username: profile['username'] as String?,
          avatarUrl: profile['avatar_url'] as String?,
          avatarConfig: profile['avatar_config'] != null
              ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
              : null,
          isPremium: profile['is_premium'] as bool? ?? false,
          status: FriendshipStatus.blocked,
          isRequester: true,
        );
      }).toList();
    },
  );

  Future<SocialProfile> getSocialProfile({
    required String targetUserId,
    required String viewerUserId,
  }) => guardedCall(
    operationName: 'getSocialProfile',
    operation: () async {
      final profileRows = await _supabase
          .from('profiles_public')
          .select()
          .eq('id', targetUserId)
          .limit(1);
      Map<String, dynamic>? profile = profileRows.isNotEmpty
          ? Map<String, dynamic>.from(profileRows.first as Map)
          : null;

      if (profile == null) {
        final fallbackRows = await _supabase
            .from('profiles')
            .select(
              'id, display_name, username, avatar_url, avatar_config, is_premium, bio, is_official_account',
            )
            .eq('id', targetUserId)
            .limit(1);
        profile = fallbackRows.isNotEmpty
            ? Map<String, dynamic>.from(fallbackRows.first as Map)
            : null;
      }
      if (profile == null) throw Exception('Profile not found');

      if (!profile.containsKey('avatar_config') ||
          !profile.containsKey('is_premium')) {
        final avatarRows = await _supabase
            .from('profiles')
            .select('avatar_config, is_premium')
            .eq('id', targetUserId)
            .limit(1);
        if (avatarRows.isNotEmpty) {
          profile['avatar_config'] = avatarRows.first['avatar_config'];
          profile['is_premium'] = avatarRows.first['is_premium'];
        }
      }

      final hasFullData = profile.containsKey('followers_count');
      if (!hasFullData) {
        return SocialProfile(
          userId: profile['id'] as String,
          displayName: profile['display_name'] as String? ?? 'Player',
          username: profile['username'] as String?,
          avatarUrl: profile['avatar_url'] as String?,
          avatarConfig: profile['avatar_config'] != null
              ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
              : null,
          isPremium: profile['is_premium'] as bool? ?? false,
          bio: profile['bio'] as String?,
          followersCount: 0,
          followingCount: 0,
          friendsCount: 0,
          gamesPlayed: 0,
          packsCount: 0,
          generalScore: (profile['general_score'] as num?)?.toInt() ?? 0,
          honestyPoints: (profile['honesty_points'] as num?)?.toInt() ?? 0,
          isOfficial: profile['is_official_account'] as bool? ?? false,
        );
      }

      final [
        blockedByMe,
        blockedByThem,
        friendshipRow,
        followingRow,
        followedByRow,
        streakRow,
      ] = await Future.wait([
        _supabase
            .from('blocked_users')
            .select('blocker_id')
            .eq('blocker_id', viewerUserId)
            .eq('blocked_id', targetUserId)
            .maybeSingle(),
        _supabase
            .from('blocked_users')
            .select('blocker_id')
            .eq('blocker_id', targetUserId)
            .eq('blocked_id', viewerUserId)
            .maybeSingle(),
        _supabase
            .from('friendships')
            .select('status, requester_id')
            .or(
              'and(requester_id.eq.$viewerUserId,addressee_id.eq.$targetUserId),'
              'and(requester_id.eq.$targetUserId,addressee_id.eq.$viewerUserId)',
            )
            .maybeSingle(),
        _supabase
            .from('follows')
            .select('follower_id')
            .eq('follower_id', viewerUserId)
            .eq('followee_id', targetUserId)
            .maybeSingle(),
        _supabase
            .from('follows')
            .select('follower_id')
            .eq('follower_id', targetUserId)
            .eq('followee_id', viewerUserId)
            .maybeSingle(),
        _supabase
            .from('user_streaks')
            .select('current_streak')
            .eq('user_id', targetUserId)
            .maybeSingle(),
      ]);

      FriendshipStatus? friendStatus;
      var isFriendshipRequester = false;
      if (friendshipRow != null) {
        final row = friendshipRow as Map;
        friendStatus = FriendshipStatus.values.firstWhere(
          (s) => s.name == row['status'],
          orElse: () => FriendshipStatus.pending,
        );
        isFriendshipRequester = row['requester_id'] == viewerUserId;
      }

      return SocialProfile(
        userId: profile['id'] as String,
        displayName: profile['display_name'] as String? ?? 'User',
        username: profile['username'] as String?,
        avatarUrl: profile['avatar_url'] as String?,
        avatarConfig: profile['avatar_config'] != null
            ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
            : null,
        isPremium: profile['is_premium'] as bool? ?? false,
        bio: profile['bio'] as String?,
        followersCount: (profile['followers_count'] as num?)?.toInt() ?? 0,
        followingCount: (profile['following_count'] as num?)?.toInt() ?? 0,
        friendsCount: (profile['friends_count'] as num?)?.toInt() ?? 0,
        gamesPlayed: (profile['games_played'] as num?)?.toInt() ?? 0,
        packsCount: (profile['packs_count'] as num?)?.toInt() ?? 0,
        generalScore: (profile['general_score'] as num?)?.toInt() ?? 0,
        honestyPoints: (profile['honesty_points'] as num?)?.toInt() ?? 0,
        currentStreak:
            ((streakRow as Map?)?['current_streak'] as num?)?.toInt() ?? 0,
        friendshipStatus: friendStatus,
        isFriendshipRequester: isFriendshipRequester,
        isFollowing: followingRow != null,
        isFollowedBy: followedByRow != null,
        isBlocked: blockedByMe != null,
        isBlockedBy: blockedByThem != null,
        isVerified: profile['verification_status'] == 'verified',
        isOfficial: profile['is_official_account'] as bool? ?? false,
      );
    },
  );

  Future<List<UserEntity>> searchUsers(
    String query, {
    required String excludeUserId,
    int limit = 20,
  }) => guardedCall(
    operationName: 'searchUsers',
    operation: () async {
      // Item 13 — the official account must be excluded at the QUERY
      // boundary, not by filtering the already-fetched page afterward.
      // The previous version applied `.limit(limit)` in Postgrest FIRST
      // and only removed the official row from the Dart List afterward:
      // harmless in that the account could never actually reach the UI,
      // but a real, if quieter, bug in its own right — if the official
      // account matched the search and was one of the `limit` rows
      // Postgres returned, the caller silently got back one row FEWER
      // than requested, and this shape is exactly the "client-side
      // guard on top of a query that can still return the row" pattern
      // that must not be reintroduced (see explore_people(), which
      // already excludes correctly inside its own WHERE/CTE). Both the
      // flag and the independent app_settings id pointer are now real
      // .eq()/.neq() predicates evaluated by Postgres before LIMIT is
      // ever applied.
      final officialAccountId = await _fetchOfficialAccountId();
      var q = _supabase
          .from('profiles')
          .select('id,username,display_name,avatar_url,avatar_config,is_premium')
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .neq('id', excludeUserId)
          .eq('is_official_account', false);
      if (officialAccountId != null && officialAccountId.isNotEmpty) {
        q = q.neq('id', officialAccountId);
      }
      final rows = await q.limit(limit);
      return rows
          .map(
            (r) => UserEntity(
              id: r['id'] as String,
              email: '',
              username: r['username'] as String?,
              displayName: r['display_name'] as String?,
              avatarUrl: r['avatar_url'] as String?,
              avatarConfig: r['avatar_config'] != null
                  ? Map<String, dynamic>.from(r['avatar_config'] as Map)
                  : null,
              isPremium: r['is_premium'] as bool? ?? false,
            ),
          )
          .toList();
    },
  );

  /// Bulk equivalent of [getFriendshipStatus] — one round trip covering
  /// every id in [otherIds], keyed by the other user's id. Used by search
  /// results so each row reflects the live relationship state instead of
  /// FriendsProvider's cached friends/sentRequests/pendingRequests lists
  /// (which only update on login/refresh/realtime and can show a stale
  /// "Add Friend" for a relationship that already exists).
  Future<Map<String, FriendEntity>> getFriendshipStatuses({
    required String userId,
    required List<String> otherIds,
  }) => guardedCall(
    operationName: 'getFriendshipStatuses',
    operation: () async {
      if (otherIds.isEmpty) return <String, FriendEntity>{};
      final idList = otherIds.map((id) => '"$id"').join(',');
      final rows = await _supabase
          .from('friendships')
          .select()
          .or(
            'and(requester_id.eq.$userId,addressee_id.in.($idList)),'
            'and(addressee_id.eq.$userId,requester_id.in.($idList))',
          );
      final result = <String, FriendEntity>{};
      for (final row in rows) {
        final requesterId = row['requester_id'] as String;
        final addresseeId = row['addressee_id'] as String;
        final otherId = requesterId == userId ? addresseeId : requesterId;
        result[otherId] = FriendEntity(
          userId: otherId,
          displayName: '',
          status: FriendshipStatus.values.firstWhere(
            (s) => s.name == (row['status'] as String? ?? 'pending'),
            orElse: () => FriendshipStatus.pending,
          ),
          isRequester: requesterId == userId,
          friendshipId: row['id'] as String?,
        );
      }
      return result;
    },
  );

  Future<FriendEntity?> getFriendshipStatus({
    required String userId,
    required String otherId,
  }) => guardedCall(
    operationName: 'getFriendshipStatus',
    operation: () async {
      final row = await _supabase
          .from('friendships')
          .select()
          .or(
            'and(requester_id.eq.$userId,addressee_id.eq.$otherId),'
            'and(requester_id.eq.$otherId,addressee_id.eq.$userId)',
          )
          .maybeSingle();
      if (row == null) return null;
      return FriendEntity(
        userId: otherId,
        displayName: '',
        status: FriendshipStatus.values.firstWhere(
          (s) => s.name == (row['status'] as String? ?? 'pending'),
          orElse: () => FriendshipStatus.pending,
        ),
        isRequester: (row['requester_id'] as String?) == userId,
        friendshipId: row['id'] as String?,
      );
    },
  );

  /// Jma3a Official (profiles.is_official_account) can never send or
  /// receive a friend request in either direction — this is a friendly,
  /// fast client-side pre-check for a clear error message; the real
  /// authority is the "friendships: requester insert" RLS policy (see
  /// 20260901090700_block_official_account_friend_requests.sql), which
  /// rejects the insert regardless of what this check does or whether a
  /// client bypasses it entirely.
  /// Public, reusable version of the same officialness check — for UI call
  /// sites (e.g. a room member's action sheet) that need to decide whether
  /// to show a friend-request affordance at all, not just validate a send
  /// attempt. Same source of truth as [_checkNotOfficial]; never guesses
  /// from a username. Fails open (false) on error so a transient lookup
  /// failure can never itself block a normal user's friend-request UI —
  /// the RLS policy remains the real backstop either way.
  Future<bool> isOfficialAccount(String userId) async {
    try {
      final row = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .eq('is_official_account', true)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkNotOfficial(String a, String b) async {
    try {
      final rows = await _supabase
          .from('profiles')
          .select('id')
          .inFilter('id', [a, b])
          .eq('is_official_account', true)
          .limit(1);
      if ((rows as List).isNotEmpty) {
        throw const ForbiddenFailure(
          message: 'Jma3a Official cannot send or receive friend requests.',
        );
      }
    } on ForbiddenFailure {
      rethrow;
    } catch (_) {}
  }

  Future<void> _checkNotBlocked(String a, String b) async {
    try {
      final block = await _supabase
          .from('blocked_users')
          .select('blocker_id')
          .or(
            'and(blocker_id.eq.$a,blocked_id.eq.$b),'
            'and(blocker_id.eq.$b,blocked_id.eq.$a)',
          )
          .maybeSingle();
      if (block != null) {
        throw const ForbiddenFailure(
          message: 'Cannot interact with this user.',
        );
      }
    } on ForbiddenFailure {
      rethrow;
    } catch (_) {}
  }

  FriendEntity _toFriendEntity(Map<String, dynamic> row, String currentUserId) {
    final requesterId = row['requester_id'] as String? ?? '';
    final isRequester = requesterId == currentUserId;
    final rawOther = isRequester ? row['addressee'] : row['requester'];
    final other = (rawOther is Map)
        ? Map<String, dynamic>.from(rawOther)
        : <String, dynamic>{};
    return FriendEntity(
      friendshipId: row['id'] as String?,
      userId: other['id'] as String? ?? '',
      displayName: other['display_name'] as String? ?? 'Player',
      username: other['username'] as String?,
      avatarUrl: other['avatar_url'] as String?,
      avatarConfig: other['avatar_config'] != null
          ? Map<String, dynamic>.from(other['avatar_config'] as Map)
          : null,
      isPremium: other['is_premium'] as bool? ?? false,
      status: FriendshipStatus.values.firstWhere(
        (s) => s.name == (row['status'] as String? ?? ''),
        orElse: () => FriendshipStatus.pending,
      ),
      isRequester: isRequester,
    );
  }

  FollowEntity _toFollowEntity(Map<String, dynamic> row) {
    // PostgREST's response key for an unaliased embed hint
    // (`profiles!follower_id(...)`) is always the plain table name
    // ('profiles') — the `!hint` suffix only disambiguates which FK to
    // join on and is dropped from the response. Reading
    // 'profiles!follower_id' here always missed, silently defaulting
    // every follower's userId to '' (matches getBlockedUsers' correct
    // `r['profiles']` read a few methods up).
    final profile = row['profiles'] as Map<String, dynamic>? ?? {};
    return FollowEntity(
      userId: profile['id'] as String? ?? '',
      displayName: profile['display_name'] as String? ?? 'User',
      username: profile['username'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
      avatarConfig: profile['avatar_config'] != null
          ? Map<String, dynamic>.from(profile['avatar_config'] as Map)
          : null,
      isPremium: profile['is_premium'] as bool? ?? false,
      followedAt: DateTime.parse(row['created_at'] as String),
      isVerified: profile['verification_status'] == 'verified',
    );
  }

  /// Server-authoritative, ranked, privacy-limited discovery feed — see
  /// public.explore_people() for the full contract (eligibility
  /// exclusions, the 0.5/0.5 percent_rank reputation formula, the
  /// >100-eligible-users 50% discovery-pool rule, and keyset pagination).
  /// Every exclusion (self, friends, pending either direction, blocked
  /// either direction, banned/deleted, the 50% cutoff) is enforced by the
  /// RPC itself — this is a thin pass-through, never a second place that
  /// could disagree with the server about who's discoverable.
  ///
  /// Pagination is keyset-based on [afterRankPosition] (the last row's
  /// `rankPosition` from the previous page) rather than an offset, so
  /// scrolling can never duplicate or skip a candidate even as the
  /// underlying ranking is recomputed per call — see the migration's own
  /// header for why this was chosen over OFFSET.
  ///
  /// [search] filters WITHIN the already-privacy-limited discovery pool
  /// (by username/display name) — it can never surface someone outside
  /// the 50% cutoff; this is enforced server-side, not merely a client
  /// convention.
  ///
  /// Item 1 (Discover-exclusion re-investigation pass) — root cause of
  /// Jma3a Official still appearing in Discover despite
  /// ExplorePerson.isDiscoverable already excluding `isOfficial` rows:
  /// public.explore_people()'s result rows never included
  /// `is_official_account` in the first place (confirmed against this
  /// project's own test/explore_people_test.dart fixture, which mirrors
  /// the RPC's real response shape and has no such column) — so
  /// ExplorePerson.fromMap's `m['is_official_account'] as bool? ?? false`
  /// silently read a key that was never present and always fell back to
  /// `false`. isDiscoverable's own logic was correct the whole time; it
  /// was filtering on a flag that could never be true. Since the RPC
  /// itself can't be changed (no migrations), this does ONE extra
  /// batched lookup — same `is_official_account` column, same
  /// `.inFilter(...).eq('is_official_account', true)` shape
  /// [isOfficialAccount]/[_checkNotOfficial] already use elsewhere in
  /// this file — against just the ids this page actually returned, and
  /// corrects each row's `isOfficial` before handing the list back. Every
  /// existing exclusion the RPC already enforces (self/friends/pending/
  /// blocked/banned/deleted/50% cutoff) is completely unaffected; this
  /// only ever narrows the result further, never widens it.
  Future<List<ExplorePerson>> explorePeople({
    int limit = 20,
    int? afterRankPosition,
    String? search,
  }) => guardedCall(
    operationName: 'explorePeople',
    operation: () async {
      final rows = await _supabase.rpc(
        'explore_people',
        params: {
          'p_limit': limit,
          'p_after_rank_position': afterRankPosition,
          'p_search': (search == null || search.trim().isEmpty)
              ? null
              : search.trim(),
        },
      );
      final people = (rows as List)
          .map(
            (r) => ExplorePerson.fromMap(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
      if (people.isEmpty) return people;

      final officialIds = <String>{};
      try {
        final officialRows = await _supabase
            .from('profiles')
            .select('id')
            .inFilter('id', people.map((p) => p.userId).toList())
            .eq('is_official_account', true);
        officialIds.addAll(officialRows.map((r) => r['id'] as String));
      } catch (e) {
        // Fails closed toward "unknown -> not official" (matches
        // isOfficialAccount's own fail-open-to-false precedent above) —
        // a transient lookup failure here must never block normal
        // Discover usage; isDiscoverable's other real condition
        // (hasCompletedProfile) still applies regardless. The second,
        // id-based check below is independent of this one and still
        // runs even if this lookup fails.
        AppLogger.warning('explorePeople: official-account lookup failed: $e');
      }

      // Belt-and-suspenders second check (see _fetchOfficialAccountId's
      // own doc comment) — catches the case where the flag above is
      // unset/wrong on the live row but the canonical id pointer is
      // still correct.
      final officialAccountId = await _fetchOfficialAccountId();
      if (officialAccountId != null) officialIds.add(officialAccountId);

      return applyOfficialIds(people, officialIds);
    },
  );
}

/// Item 1 (Discover-exclusion re-investigation pass) — corrects
/// [ExplorePerson.isOfficial] for every row whose id is in [officialIds]
/// (the batched lookup [FriendsRepository.explorePeople] runs against
/// `profiles.is_official_account`, since the explore_people() RPC never
/// returns that column itself). A top-level pure function (not inlined)
/// so this exact "mark the official rows" step is independently
/// unit-testable without a live Supabase client — see that method's own
/// doc comment for the full root-cause explanation.
List<ExplorePerson> applyOfficialIds(
  List<ExplorePerson> people,
  Set<String> officialIds,
) {
  if (officialIds.isEmpty) return people;
  return people
      .map((p) => officialIds.contains(p.userId) ? p.copyWithOfficial(true) : p)
      .toList();
}

/// Item 1 (this pass) — the same `is_official_account` identifier
/// [ExplorePerson.isOfficial]/[ExplorePerson.isDiscoverable] key off of,
/// applied to a raw `profiles` search row so [FriendsRepository.searchUsers]
/// can exclude Jma3a Official from search results too. A top-level pure
/// function (not inlined in the query) so it's independently unit-testable
/// without a live Supabase client.
bool searchRowIsOfficialAccount(Map<String, dynamic> row) =>
    row['is_official_account'] as bool? ?? false;

/// Item 2 (official-account re-investigation pass) — the combined
/// exclusion [FriendsRepository.searchUsers] applies: official either by
/// the [searchRowIsOfficialAccount] flag OR by matching the independent
/// `app_settings.official_creator_profile_id` pointer ([officialAccountId]
/// — see [FriendsRepository._fetchOfficialAccountId]'s own doc comment
/// for why this second, id-based check exists). A top-level pure
/// function so the combined behavior is independently unit-testable
/// without a live Supabase client, including the exact scenario that
/// caused the original bug report: the flag is false/missing on a row
/// but its id still matches the canonical official-account pointer.
bool isOfficialAccountRow(
  Map<String, dynamic> row, {
  required String? officialAccountId,
}) =>
    searchRowIsOfficialAccount(row) ||
    (officialAccountId != null && row['id'] == officialAccountId);

/// Item 2 (official-account re-investigation pass, real-device report:
/// STILL visible after re-running the setup script) — parses
/// `app_settings.official_creator_profile_id`'s `value` column into a
/// plain id string. `app_settings.value` is `jsonb`, and
/// createOfficialCreatorAccount.js writes a bare string into it
/// (`{key, value: id}`), which PostgREST embeds as a plain JSON string —
/// so the common case is [raw] already being a `String`. This is
/// slightly more defensive than a bare `as String?` cast: it also
/// accepts a nested `{'id': ...}`/`{'value': ...}` shape (in case a
/// future write path or manual edit stores the pointer wrapped in an
/// object instead of a bare string) before giving up, since a silent
/// cast failure here is exactly what would make this whole
/// belt-and-suspenders check quietly do nothing — see
/// [FriendsRepository._fetchOfficialAccountId]'s own doc comment. Still
/// purely id-based — never falls back to any name/username heuristic.
String? parseOfficialAccountIdValue(dynamic raw) {
  if (raw is String && raw.isNotEmpty) return raw;
  if (raw is Map) {
    final nested = raw['id'] ?? raw['value'];
    if (nested is String && nested.isNotEmpty) return nested;
  }
  return null;
}

/// Item 8 (followers investigation pass) — maps every raw `follows` row
/// to a [FollowEntity] via [toEntity], with PER-ROW error isolation.
/// Before this, [FriendsRepository.getFollowers]/[getFollowing] used
/// `rows.map(_toFollowEntity).toList()` directly: `.map().toList()`
/// evaluates eagerly, so a SINGLE row that fails to parse (a malformed
/// `avatar_config` that isn't actually a JSON object, a genuinely
/// unexpected null somewhere the mapper doesn't defend against, etc.)
/// throws and discards the ENTIRE list — not just that one row — via
/// guardedCall's own catch converting it into a Failure. That reads as a
/// total, unconditional "I have followers but I can't see any of them",
/// exactly matching this task's reported symptom, and is
/// indistinguishable from a genuinely empty list once it reaches
/// FollowersScreen as an error/failure. Now: a bad row is logged and
/// skipped, every other row still renders normally. A top-level function
/// taking [toEntity] as a parameter (rather than being a method that
/// calls the repository's own private mapper directly) so the
/// isolation behavior itself is independently unit-testable without a
/// live Supabase client or a real PostgREST row shape.
List<FollowEntity> mapFollowRowsSafely(
  List<Map<String, dynamic>> rows, {
  required String operationName,
  required FollowEntity Function(Map<String, dynamic>) toEntity,
}) {
  final result = <FollowEntity>[];
  for (final row in rows) {
    try {
      result.add(toEntity(row));
    } catch (e, st) {
      AppLogger.error(
        '$operationName: failed to map one row (skipped, not fatal to '
        'the rest of the list): $row',
        error: e,
        stackTrace: st,
      );
    }
  }
  return result;
}
