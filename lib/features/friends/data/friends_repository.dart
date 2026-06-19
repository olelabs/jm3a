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
// // // // // // // // //         'following_id': followingId,
// // // // // // // // //       }, onConflict: 'follower_id,following_id');
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
// // // // // // // // //               .eq('following_id', followingId);
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
// // // // // // // // //           .eq('following_id', userId)
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
// // // // // // // // //             'following_id,created_at,'
// // // // // // // // //             'profiles!following_id(id,display_name,username,avatar_url,verification_status)',
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
// // // // // // // // //       final profile = await _supabase
// // // // // // // // //           .from('profiles_public')
// // // // // // // // //           .select()
// // // // // // // // //           .eq('id', targetUserId)
// // // // // // // // //           .single();

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
// // // // // // // // //             .eq('following_id', targetUserId)
// // // // // // // // //             .maybeSingle(),
// // // // // // // // //         _supabase
// // // // // // // // //             .from('follows')
// // // // // // // // //             .select('id')
// // // // // // // // //             .eq('follower_id', targetUserId)
// // // // // // // // //             .eq('following_id', viewerUserId)
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
// // // // // // // // //         row[followingMode ? 'profiles!following_id' : 'profiles!follower_id']
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
// // // // // // // //         'following_id': followingId,
// // // // // // // //       }, onConflict: 'follower_id,following_id');
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
// // // // // // // //               .eq('following_id', followingId);
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
// // // // // // // //           .eq('following_id', userId)
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
// // // // // // // //             'following_id,created_at,'
// // // // // // // //             'profiles!following_id(id,display_name,username,avatar_url,verification_status)',
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
// // // // // // // //       final profile = await _supabase
// // // // // // // //           .from('profiles_public')
// // // // // // // //           .select()
// // // // // // // //           .eq('id', targetUserId)
// // // // // // // //           .maybeSingle();

// // // // // // // //       if (profile == null) {
// // // // // // // //         // Fallback: try profiles table directly
// // // // // // // //         final fallback = await _supabase
// // // // // // // //             .from('profiles')
// // // // // // // //             .select('id, display_name, username, avatar_url, bio')
// // // // // // // //             .eq('id', targetUserId)
// // // // // // // //             .maybeSingle();
// // // // // // // //         if (fallback == null) throw Exception('Profile not found');
// // // // // // // //         // Build minimal profile from profiles table
// // // // // // // //         return SocialProfile(
// // // // // // // //           userId: fallback['id'] as String,
// // // // // // // //           displayName: fallback['display_name'] as String? ?? 'Player',
// // // // // // // //           username: fallback['username'] as String?,
// // // // // // // //           avatarUrl: fallback['avatar_url'] as String?,
// // // // // // // //           bio: fallback['bio'] as String?,
// // // // // // // //           followersCount: 0,
// // // // // // // //           followingCount: 0,
// // // // // // // //           friendsCount: 0,
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
// // // // // // // //             .eq('following_id', targetUserId)
// // // // // // // //             .maybeSingle(),
// // // // // // // //         _supabase
// // // // // // // //             .from('follows')
// // // // // // // //             .select('id')
// // // // // // // //             .eq('follower_id', targetUserId)
// // // // // // // //             .eq('following_id', viewerUserId)
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
// // // // // // // //         followersCount: profile['followers_count'] as int? ?? 0,
// // // // // // // //         followingCount: profile['following_count'] as int? ?? 0,
// // // // // // // //         friendsCount: profile['friends_count'] as int? ?? 0,
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
// // // // // // // //         row[followingMode ? 'profiles!following_id' : 'profiles!follower_id']
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
// // // // // // //         'following_id': followingId,
// // // // // // //       }, onConflict: 'follower_id,following_id');
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
// // // // // // //               .eq('following_id', followingId);
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
// // // // // // //           .eq('following_id', userId)
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
// // // // // // //             'following_id,created_at,'
// // // // // // //             'profiles!following_id(id,display_name,username,avatar_url,verification_status)',
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
// // // // // // //       final profile = await _supabase
// // // // // // //           .from('profiles_public')
// // // // // // //           .select()
// // // // // // //           .eq('id', targetUserId)
// // // // // // //           .maybeSingle();

// // // // // // //       if (profile == null) {
// // // // // // //         // Fallback: try profiles table directly
// // // // // // //         final fallback = await _supabase
// // // // // // //             .from('profiles')
// // // // // // //             .select('id, display_name, username, avatar_url, bio')
// // // // // // //             .eq('id', targetUserId)
// // // // // // //             .maybeSingle();
// // // // // // //         if (fallback == null) throw Exception('Profile not found');
// // // // // // //         // Build minimal profile from profiles table
// // // // // // //         return SocialProfile(
// // // // // // //           userId: fallback['id'] as String,
// // // // // // //           displayName: fallback['display_name'] as String? ?? 'Player',
// // // // // // //           username: fallback['username'] as String?,
// // // // // // //           avatarUrl: fallback['avatar_url'] as String?,
// // // // // // //           bio: fallback['bio'] as String?,
// // // // // // //           followersCount: 0,
// // // // // // //           followingCount: 0,
// // // // // // //           friendsCount: 0,
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
// // // // // // //             .select('id')
// // // // // // //             .eq('follower_id', viewerUserId)
// // // // // // //             .eq('following_id', targetUserId)
// // // // // // //             .maybeSingle(),
// // // // // // //         _supabase
// // // // // // //             .from('follows')
// // // // // // //             .select('id')
// // // // // // //             .eq('follower_id', targetUserId)
// // // // // // //             .eq('following_id', viewerUserId)
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
// // // // // // //         followersCount: profile['followers_count'] as int? ?? 0,
// // // // // // //         followingCount: profile['following_count'] as int? ?? 0,
// // // // // // //         friendsCount: profile['friends_count'] as int? ?? 0,
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
// // // // // // //         row[followingMode ? 'profiles!following_id' : 'profiles!follower_id']
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
// // // // // //         'following_id': followingId,
// // // // // //       }, onConflict: 'follower_id,following_id');
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
// // // // // //               .eq('following_id', followingId);
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
// // // // // //           .eq('following_id', userId)
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
// // // // // //             'following_id,created_at,'
// // // // // //             'profiles!following_id(id,display_name,username,avatar_url,verification_status)',
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
// // // // // //       Map<String, dynamic>? profile = await _supabase
// // // // // //           .from('profiles_public')
// // // // // //           .select()
// // // // // //           .eq('id', targetUserId)
// // // // // //           .maybeSingle();

// // // // // //       // Fallback: profiles table directly (handles RLS edge cases)
// // // // // //       if (profile == null) {
// // // // // //         profile = await _supabase
// // // // // //             .from('profiles')
// // // // // //             .select('id, display_name, username, avatar_url, bio')
// // // // // //             .eq('id', targetUserId)
// // // // // //             .maybeSingle();
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
// // // // // //             .select('id')
// // // // // //             .eq('follower_id', viewerUserId)
// // // // // //             .eq('following_id', targetUserId)
// // // // // //             .maybeSingle(),
// // // // // //         _supabase
// // // // // //             .from('follows')
// // // // // //             .select('id')
// // // // // //             .eq('follower_id', targetUserId)
// // // // // //             .eq('following_id', viewerUserId)
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
// // // // // //         followersCount: profile['followers_count'] as int? ?? 0,
// // // // // //         followingCount: profile['following_count'] as int? ?? 0,
// // // // // //         friendsCount: profile['friends_count'] as int? ?? 0,
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
// // // // // //     final block = await _supabase
// // // // // //         .from('blocked_users')
// // // // // //         .select('blocker_id')
// // // // // //         .or(
// // // // // //           'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // // // // //           'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // // // // //         )
// // // // // //         .maybeSingle();
// // // // // //     if (block != null) {
// // // // // //       throw const ForbiddenFailure(message: 'Cannot interact with this user.');
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
// // // // // //         row[followingMode ? 'profiles!following_id' : 'profiles!follower_id']
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

// // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // import '../../../core/data/base_repository.dart';
// // // // // import '../../../core/errors/failures.dart';
// // // // // import '../../../features/auth/domain/entities/user_entity.dart';

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
// // // // //       Map<String, dynamic>? profile = await _supabase
// // // // //           .from('profiles_public')
// // // // //           .select()
// // // // //           .eq('id', targetUserId)
// // // // //           .maybeSingle();

// // // // //       // Fallback: profiles table directly (handles RLS edge cases)
// // // // //       if (profile == null) {
// // // // //         profile = await _supabase
// // // // //             .from('profiles')
// // // // //             .select('id, display_name, username, avatar_url, bio')
// // // // //             .eq('id', targetUserId)
// // // // //             .maybeSingle();
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
// // // // //             .select('id')
// // // // //             .eq('follower_id', viewerUserId)
// // // // //             .eq('followee_id', targetUserId)
// // // // //             .maybeSingle(),
// // // // //         _supabase
// // // // //             .from('follows')
// // // // //             .select('id')
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
// // // // //         followersCount: profile['followers_count'] as int? ?? 0,
// // // // //         followingCount: profile['following_count'] as int? ?? 0,
// // // // //         friendsCount: profile['friends_count'] as int? ?? 0,
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

// // // // //   Future<void> _checkNotBlocked(String a, String b) async {
// // // // //     final block = await _supabase
// // // // //         .from('blocked_users')
// // // // //         .select('blocker_id')
// // // // //         .or(
// // // // //           'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // // // //           'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // // // //         )
// // // // //         .maybeSingle();
// // // // //     if (block != null) {
// // // // //       throw const ForbiddenFailure(message: 'Cannot interact with this user.');
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

// // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // import '../../../core/data/base_repository.dart';
// // // // import '../../../core/errors/failures.dart';
// // // // import '../../../features/auth/domain/entities/user_entity.dart';

// // // // // ── Domain types ──────────────────────────────────────────────────────────────

// // // // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // // // class FriendEntity {
// // // //   const FriendEntity({
// // // //     required this.userId,
// // // //     required this.displayName,
// // // //     this.username,
// // // //     this.avatarUrl,
// // // //     required this.status,
// // // //     required this.isRequester,
// // // //     this.mutualFriendsCount = 0,
// // // //     this.friendshipId,
// // // //   });

// // // //   final String userId;
// // // //   final String displayName;
// // // //   final String? username;
// // // //   final String? avatarUrl;
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
// // // //     required this.followedAt,
// // // //     this.isVerified = false,
// // // //   });

// // // //   final String userId;
// // // //   final String displayName;
// // // //   final String? username;
// // // //   final String? avatarUrl;
// // // //   final DateTime followedAt;
// // // //   final bool isVerified;
// // // // }

// // // // class SocialProfile {
// // // //   const SocialProfile({
// // // //     required this.userId,
// // // //     required this.displayName,
// // // //     this.username,
// // // //     this.avatarUrl,
// // // //     this.bio,
// // // //     required this.followersCount,
// // // //     required this.followingCount,
// // // //     required this.friendsCount,
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
// // // //   final String? bio;
// // // //   final int followersCount;
// // // //   final int followingCount;
// // // //   final int friendsCount;
// // // //   final FriendshipStatus? friendshipStatus;
// // // //   final bool isFollowing;
// // // //   final bool isFollowedBy;
// // // //   final bool isBlocked;
// // // //   final bool isBlockedBy;
// // // //   final bool isVerified;

// // // //   bool get canInteract => !isBlocked && !isBlockedBy;
// // // // }

// // // // // ── Repository ────────────────────────────────────────────────────────────────

// // // // class FriendsRepository extends BaseRepository {
// // // //   FriendsRepository._();
// // // //   static final FriendsRepository _instance = FriendsRepository._();
// // // //   static FriendsRepository get instance => _instance;

// // // //   final _supabase = Supabase.instance.client;

// // // //   // ── Friends ───────────────────────────────────────────────────────────────

// // // //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// // // //     operationName: 'getFriends',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('friendships')
// // // //           .select(
// // // //             'id,status,requester_id,addressee_id,'
// // // //             'requester:profiles!requester_id(id,display_name,username,avatar_url),'
// // // //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url)',
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
// // // //       // Fetch requester profiles separately to avoid join ambiguity
// // // //       final requesterIds = rows
// // // //           .map((r) => r['requester_id'] as String)
// // // //           .toList();
// // // //       final profiles = await _supabase
// // // //           .from('profiles')
// // // //           .select('id,display_name,username,avatar_url')
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
// // // //       // Fetch addressee profiles separately
// // // //       final addresseeIds = rows
// // // //           .map((r) => r['addressee_id'] as String)
// // // //           .toList();
// // // //       final profiles = await _supabase
// // // //           .from('profiles')
// // // //           .select('id,display_name,username,avatar_url')
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
// // // //       // Check not blocked
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

// // // //   // ── Follow system ─────────────────────────────────────────────────────────

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
// // // //             'profiles!follower_id(id,display_name,username,avatar_url,verification_status)',
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
// // // //             'profiles!followee_id(id,display_name,username,avatar_url,verification_status)',
// // // //           )
// // // //           .eq('follower_id', userId)
// // // //           .order('created_at', ascending: false)
// // // //           .limit(limit);
// // // //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// // // //     },
// // // //   );

// // // //   // ── Block system ──────────────────────────────────────────────────────────

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
// // // //       // Also remove any existing friendship
// // // //       await removeFriend(
// // // //         userId: blockerId,
// // // //         friendId: blockedId,
// // // //       ).catchError((_) {});
// // // //       // Remove follow in both directions
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
// // // //             'profiles!blocked_id(id,display_name,username,avatar_url)',
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
// // // //           status: FriendshipStatus.blocked,
// // // //           isRequester: true,
// // // //         );
// // // //       }).toList();
// // // //     },
// // // //   );

// // // //   // ── Social profile ────────────────────────────────────────────────────────

// // // //   Future<SocialProfile> getSocialProfile({
// // // //     required String targetUserId,
// // // //     required String viewerUserId,
// // // //   }) => guardedCall(
// // // //     operationName: 'getSocialProfile',
// // // //     operation: () async {
// // // //       // Try profiles_public first (has bio + counts after migration)
// // // //       // Use limit(1) to guard against duplicate rows in view/table
// // // //       final profileRows = await _supabase
// // // //           .from('profiles_public')
// // // //           .select()
// // // //           .eq('id', targetUserId)
// // // //           .limit(1);
// // // //       Map<String, dynamic>? profile = profileRows.isNotEmpty
// // // //           ? profileRows.first as Map<String, dynamic>
// // // //           : null;

// // // //       // Fallback: profiles table directly
// // // //       if (profile == null) {
// // // //         final fallbackRows = await _supabase
// // // //             .from('profiles')
// // // //             .select('id, display_name, username, avatar_url, bio')
// // // //             .eq('id', targetUserId)
// // // //             .limit(1);
// // // //         profile = fallbackRows.isNotEmpty
// // // //             ? fallbackRows.first as Map<String, dynamic>
// // // //             : null;
// // // //       }
// // // //       if (profile == null) throw Exception('Profile not found');

// // // //       // If we only got minimal data (no counts), return basic profile
// // // //       final hasFullData = profile.containsKey('followers_count');
// // // //       if (!hasFullData) {
// // // //         return SocialProfile(
// // // //           userId: profile['id'] as String,
// // // //           displayName: profile['display_name'] as String? ?? 'Player',
// // // //           username: profile['username'] as String?,
// // // //           avatarUrl: profile['avatar_url'] as String?,
// // // //           bio: profile['bio'] as String?,
// // // //           followersCount: 0,
// // // //           followingCount: 0,
// // // //           friendsCount: 0,
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
// // // //             .select('id')
// // // //             .eq('follower_id', viewerUserId)
// // // //             .eq('followee_id', targetUserId)
// // // //             .maybeSingle(),
// // // //         _supabase
// // // //             .from('follows')
// // // //             .select('id')
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
// // // //         followersCount: profile['followers_count'] as int? ?? 0,
// // // //         followingCount: profile['following_count'] as int? ?? 0,
// // // //         friendsCount: profile['friends_count'] as int? ?? 0,
// // // //         friendshipStatus: friendStatus,
// // // //         isFollowing: followingRow != null,
// // // //         isFollowedBy: followedByRow != null,
// // // //         isBlocked: blockedByMe != null,
// // // //         isBlockedBy: blockedByThem != null,
// // // //         isVerified: profile['verification_status'] == 'verified',
// // // //       );
// // // //     },
// // // //   );

// // // //   // ── Search ────────────────────────────────────────────────────────────────

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
// // // //             ),
// // // //           )
// // // //           .toList();
// // // //     },
// // // //   );

// // // //   // ── Private helpers ───────────────────────────────────────────────────────

// // // //   Future<void> _checkNotBlocked(String a, String b) async {
// // // //     final block = await _supabase
// // // //         .from('blocked_users')
// // // //         .select('blocker_id')
// // // //         .or(
// // // //           'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // // //           'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // // //         )
// // // //         .maybeSingle();
// // // //     if (block != null) {
// // // //       throw const ForbiddenFailure(message: 'Cannot interact with this user.');
// // // //     }
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
// // // //       followedAt: DateTime.parse(row['created_at'] as String),
// // // //       isVerified: profile['verification_status'] == 'verified',
// // // //     );
// // // //   }
// // // // }

// // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // import '../../../core/data/base_repository.dart';
// // // import '../../../core/errors/failures.dart';
// // // import '../../../features/auth/domain/entities/user_entity.dart';

// // // // ── Domain types ──────────────────────────────────────────────────────────────

// // // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // // class FriendEntity {
// // //   const FriendEntity({
// // //     required this.userId,
// // //     required this.displayName,
// // //     this.username,
// // //     this.avatarUrl,
// // //     required this.status,
// // //     required this.isRequester,
// // //     this.mutualFriendsCount = 0,
// // //     this.friendshipId,
// // //   });

// // //   final String userId;
// // //   final String displayName;
// // //   final String? username;
// // //   final String? avatarUrl;
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
// // //     required this.followedAt,
// // //     this.isVerified = false,
// // //   });

// // //   final String userId;
// // //   final String displayName;
// // //   final String? username;
// // //   final String? avatarUrl;
// // //   final DateTime followedAt;
// // //   final bool isVerified;
// // // }

// // // class SocialProfile {
// // //   const SocialProfile({
// // //     required this.userId,
// // //     required this.displayName,
// // //     this.username,
// // //     this.avatarUrl,
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

// // // // ── Repository ────────────────────────────────────────────────────────────────

// // // class FriendsRepository extends BaseRepository {
// // //   FriendsRepository._();
// // //   static final FriendsRepository _instance = FriendsRepository._();
// // //   static FriendsRepository get instance => _instance;

// // //   final _supabase = Supabase.instance.client;

// // //   // ── Friends ───────────────────────────────────────────────────────────────

// // //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// // //     operationName: 'getFriends',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('friendships')
// // //           .select(
// // //             'id,status,requester_id,addressee_id,'
// // //             'requester:profiles!requester_id(id,display_name,username,avatar_url),'
// // //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url)',
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
// // //       // Fetch requester profiles separately to avoid join ambiguity
// // //       final requesterIds = rows
// // //           .map((r) => r['requester_id'] as String)
// // //           .toList();
// // //       final profiles = await _supabase
// // //           .from('profiles')
// // //           .select('id,display_name,username,avatar_url')
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
// // //       // Fetch addressee profiles separately
// // //       final addresseeIds = rows
// // //           .map((r) => r['addressee_id'] as String)
// // //           .toList();
// // //       final profiles = await _supabase
// // //           .from('profiles')
// // //           .select('id,display_name,username,avatar_url')
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
// // //       // Check not blocked
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

// // //   // ── Follow system ─────────────────────────────────────────────────────────

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
// // //             'profiles!follower_id(id,display_name,username,avatar_url,verification_status)',
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
// // //             'profiles!followee_id(id,display_name,username,avatar_url,verification_status)',
// // //           )
// // //           .eq('follower_id', userId)
// // //           .order('created_at', ascending: false)
// // //           .limit(limit);
// // //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// // //     },
// // //   );

// // //   // ── Block system ──────────────────────────────────────────────────────────

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
// // //       // Also remove any existing friendship
// // //       await removeFriend(
// // //         userId: blockerId,
// // //         friendId: blockedId,
// // //       ).catchError((_) {});
// // //       // Remove follow in both directions
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
// // //             'profiles!blocked_id(id,display_name,username,avatar_url)',
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
// // //           status: FriendshipStatus.blocked,
// // //           isRequester: true,
// // //         );
// // //       }).toList();
// // //     },
// // //   );

// // //   // ── Social profile ────────────────────────────────────────────────────────

// // //   Future<SocialProfile> getSocialProfile({
// // //     required String targetUserId,
// // //     required String viewerUserId,
// // //   }) => guardedCall(
// // //     operationName: 'getSocialProfile',
// // //     operation: () async {
// // //       // Try profiles_public first (has bio + counts after migration)
// // //       // Use limit(1) to guard against duplicate rows in view/table
// // //       final profileRows = await _supabase
// // //           .from('profiles_public')
// // //           .select()
// // //           .eq('id', targetUserId)
// // //           .limit(1);
// // //       Map<String, dynamic>? profile = profileRows.isNotEmpty
// // //           ? profileRows.first as Map<String, dynamic>
// // //           : null;

// // //       // Fallback: profiles table directly
// // //       if (profile == null) {
// // //         final fallbackRows = await _supabase
// // //             .from('profiles')
// // //             .select('id, display_name, username, avatar_url, bio')
// // //             .eq('id', targetUserId)
// // //             .limit(1);
// // //         profile = fallbackRows.isNotEmpty
// // //             ? fallbackRows.first as Map<String, dynamic>
// // //             : null;
// // //       }
// // //       if (profile == null) throw Exception('Profile not found');

// // //       // If we only got minimal data (no counts), return basic profile
// // //       final hasFullData = profile.containsKey('followers_count');
// // //       if (!hasFullData) {
// // //         return SocialProfile(
// // //           userId: profile['id'] as String,
// // //           displayName: profile['display_name'] as String? ?? 'Player',
// // //           username: profile['username'] as String?,
// // //           avatarUrl: profile['avatar_url'] as String?,
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
// // //             .select('id')
// // //             .eq('follower_id', viewerUserId)
// // //             .eq('followee_id', targetUserId)
// // //             .maybeSingle(),
// // //         _supabase
// // //             .from('follows')
// // //             .select('id')
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

// // //   // ── Search ────────────────────────────────────────────────────────────────

// // //   Future<List<UserEntity>> searchUsers(
// // //     String query, {
// // //     required String excludeUserId,
// // //     int limit = 20,
// // //   }) => guardedCall(
// // //     operationName: 'searchUsers',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('profiles_public')
// // //           .select('id,username,display_name,avatar_url')
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
// // //             ),
// // //           )
// // //           .toList();
// // //     },
// // //   );

// // //   // ── Private helpers ───────────────────────────────────────────────────────

// // //   Future<void> _checkNotBlocked(String a, String b) async {
// // //     final block = await _supabase
// // //         .from('blocked_users')
// // //         .select('blocker_id')
// // //         .or(
// // //           'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// // //           'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// // //         )
// // //         .maybeSingle();
// // //     if (block != null) {
// // //       throw const ForbiddenFailure(message: 'Cannot interact with this user.');
// // //     }
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
// // //       followedAt: DateTime.parse(row['created_at'] as String),
// // //       isVerified: profile['verification_status'] == 'verified',
// // //     );
// // //   }
// // // }

// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import '../../../core/data/base_repository.dart';
// // import '../../../core/errors/failures.dart';
// // import '../../../features/auth/domain/entities/user_entity.dart';

// // // ── Domain types ──────────────────────────────────────────────────────────────

// // enum FriendshipStatus { pending, accepted, rejected, blocked }

// // class FriendEntity {
// //   const FriendEntity({
// //     required this.userId,
// //     required this.displayName,
// //     this.username,
// //     this.avatarUrl,
// //     required this.status,
// //     required this.isRequester,
// //     this.mutualFriendsCount = 0,
// //     this.friendshipId,
// //   });

// //   final String userId;
// //   final String displayName;
// //   final String? username;
// //   final String? avatarUrl;
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
// //     required this.followedAt,
// //     this.isVerified = false,
// //   });

// //   final String userId;
// //   final String displayName;
// //   final String? username;
// //   final String? avatarUrl;
// //   final DateTime followedAt;
// //   final bool isVerified;
// // }

// // class SocialProfile {
// //   const SocialProfile({
// //     required this.userId,
// //     required this.displayName,
// //     this.username,
// //     this.avatarUrl,
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

// // // ── Repository ────────────────────────────────────────────────────────────────

// // class FriendsRepository extends BaseRepository {
// //   FriendsRepository._();
// //   static final FriendsRepository _instance = FriendsRepository._();
// //   static FriendsRepository get instance => _instance;

// //   final _supabase = Supabase.instance.client;

// //   // ── Friends ───────────────────────────────────────────────────────────────

// //   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
// //     operationName: 'getFriends',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('friendships')
// //           .select(
// //             'id,status,requester_id,addressee_id,'
// //             'requester:profiles!requester_id(id,display_name,username,avatar_url),'
// //             'addressee:profiles!addressee_id(id,display_name,username,avatar_url)',
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
// //       // Fetch requester profiles separately to avoid join ambiguity
// //       final requesterIds = rows
// //           .map((r) => r['requester_id'] as String)
// //           .toList();
// //       final profiles = await _supabase
// //           .from('profiles')
// //           .select('id,display_name,username,avatar_url')
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
// //       // Fetch addressee profiles separately
// //       final addresseeIds = rows
// //           .map((r) => r['addressee_id'] as String)
// //           .toList();
// //       final profiles = await _supabase
// //           .from('profiles')
// //           .select('id,display_name,username,avatar_url')
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
// //       // Check not blocked
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

// //   // ── Follow system ─────────────────────────────────────────────────────────

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
// //             'profiles!follower_id(id,display_name,username,avatar_url,verification_status)',
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
// //             'profiles!followee_id(id,display_name,username,avatar_url,verification_status)',
// //           )
// //           .eq('follower_id', userId)
// //           .order('created_at', ascending: false)
// //           .limit(limit);
// //       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
// //     },
// //   );

// //   // ── Block system ──────────────────────────────────────────────────────────

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
// //       // Also remove any existing friendship
// //       await removeFriend(
// //         userId: blockerId,
// //         friendId: blockedId,
// //       ).catchError((_) {});
// //       // Remove follow in both directions
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
// //             'profiles!blocked_id(id,display_name,username,avatar_url)',
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
// //           status: FriendshipStatus.blocked,
// //           isRequester: true,
// //         );
// //       }).toList();
// //     },
// //   );

// //   // ── Social profile ────────────────────────────────────────────────────────

// //   Future<SocialProfile> getSocialProfile({
// //     required String targetUserId,
// //     required String viewerUserId,
// //   }) => guardedCall(
// //     operationName: 'getSocialProfile',
// //     operation: () async {
// //       // Try profiles_public first (has bio + counts after migration)
// //       // Use limit(1) to guard against duplicate rows in view/table
// //       final profileRows = await _supabase
// //           .from('profiles_public')
// //           .select()
// //           .eq('id', targetUserId)
// //           .limit(1);
// //       Map<String, dynamic>? profile = profileRows.isNotEmpty
// //           ? profileRows.first as Map<String, dynamic>
// //           : null;

// //       // Fallback: profiles table directly
// //       if (profile == null) {
// //         final fallbackRows = await _supabase
// //             .from('profiles')
// //             .select('id, display_name, username, avatar_url, bio')
// //             .eq('id', targetUserId)
// //             .limit(1);
// //         profile = fallbackRows.isNotEmpty
// //             ? fallbackRows.first as Map<String, dynamic>
// //             : null;
// //       }
// //       if (profile == null) throw Exception('Profile not found');

// //       // If we only got minimal data (no counts), return basic profile
// //       final hasFullData = profile.containsKey('followers_count');
// //       if (!hasFullData) {
// //         return SocialProfile(
// //           userId: profile['id'] as String,
// //           displayName: profile['display_name'] as String? ?? 'Player',
// //           username: profile['username'] as String?,
// //           avatarUrl: profile['avatar_url'] as String?,
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

// //   // ── Search ────────────────────────────────────────────────────────────────

// //   Future<List<UserEntity>> searchUsers(
// //     String query, {
// //     required String excludeUserId,
// //     int limit = 20,
// //   }) => guardedCall(
// //     operationName: 'searchUsers',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('profiles_public')
// //           .select('id,username,display_name,avatar_url')
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
// //             ),
// //           )
// //           .toList();
// //     },
// //   );

// //   // ── Private helpers ───────────────────────────────────────────────────────

// //   Future<void> _checkNotBlocked(String a, String b) async {
// //     final block = await _supabase
// //         .from('blocked_users')
// //         .select('blocker_id')
// //         .or(
// //           'and(blocker_id.eq.$a,blocked_id.eq.$b),'
// //           'and(blocker_id.eq.$b,blocked_id.eq.$a)',
// //         )
// //         .maybeSingle();
// //     if (block != null) {
// //       throw const ForbiddenFailure(message: 'Cannot interact with this user.');
// //     }
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
// //       followedAt: DateTime.parse(row['created_at'] as String),
// //       isVerified: profile['verification_status'] == 'verified',
// //     );
// //   }
// // }

// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../../core/data/base_repository.dart';
// import '../../../core/errors/failures.dart';
// import '../../../features/auth/domain/entities/user_entity.dart';

// // ── Domain types ──────────────────────────────────────────────────────────────

// enum FriendshipStatus { pending, accepted, rejected, blocked }

// class FriendEntity {
//   const FriendEntity({
//     required this.userId,
//     required this.displayName,
//     this.username,
//     this.avatarUrl,
//     required this.status,
//     required this.isRequester,
//     this.mutualFriendsCount = 0,
//     this.friendshipId,
//   });

//   final String userId;
//   final String displayName;
//   final String? username;
//   final String? avatarUrl;
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
//     required this.followedAt,
//     this.isVerified = false,
//   });

//   final String userId;
//   final String displayName;
//   final String? username;
//   final String? avatarUrl;
//   final DateTime followedAt;
//   final bool isVerified;
// }

// class SocialProfile {
//   const SocialProfile({
//     required this.userId,
//     required this.displayName,
//     this.username,
//     this.avatarUrl,
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

// // ── Repository ────────────────────────────────────────────────────────────────

// class FriendsRepository extends BaseRepository {
//   FriendsRepository._();
//   static final FriendsRepository _instance = FriendsRepository._();
//   static FriendsRepository get instance => _instance;

//   final _supabase = Supabase.instance.client;

//   // ── Friends ───────────────────────────────────────────────────────────────

//   Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
//     operationName: 'getFriends',
//     operation: () async {
//       final rows = await _supabase
//           .from('friendships')
//           .select(
//             'id,status,requester_id,addressee_id,'
//             'requester:profiles!requester_id(id,display_name,username,avatar_url),'
//             'addressee:profiles!addressee_id(id,display_name,username,avatar_url)',
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
//       // Fetch requester profiles separately to avoid join ambiguity
//       final requesterIds = rows
//           .map((r) => r['requester_id'] as String)
//           .toList();
//       final profiles = await _supabase
//           .from('profiles')
//           .select('id,display_name,username,avatar_url')
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
//       // Fetch addressee profiles separately
//       final addresseeIds = rows
//           .map((r) => r['addressee_id'] as String)
//           .toList();
//       final profiles = await _supabase
//           .from('profiles')
//           .select('id,display_name,username,avatar_url')
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
//       // Check not blocked
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

//   // ── Follow system ─────────────────────────────────────────────────────────

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
//             'profiles!follower_id(id,display_name,username,avatar_url,verification_status)',
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
//             'profiles!followee_id(id,display_name,username,avatar_url,verification_status)',
//           )
//           .eq('follower_id', userId)
//           .order('created_at', ascending: false)
//           .limit(limit);
//       return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
//     },
//   );

//   // ── Block system ──────────────────────────────────────────────────────────

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
//       // Also remove any existing friendship
//       await removeFriend(
//         userId: blockerId,
//         friendId: blockedId,
//       ).catchError((_) {});
//       // Remove follow in both directions
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
//             'profiles!blocked_id(id,display_name,username,avatar_url)',
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
//           status: FriendshipStatus.blocked,
//           isRequester: true,
//         );
//       }).toList();
//     },
//   );

//   // ── Social profile ────────────────────────────────────────────────────────

//   Future<SocialProfile> getSocialProfile({
//     required String targetUserId,
//     required String viewerUserId,
//   }) => guardedCall(
//     operationName: 'getSocialProfile',
//     operation: () async {
//       // Try profiles_public first (has bio + counts after migration)
//       // Use limit(1) to guard against duplicate rows in view/table
//       final profileRows = await _supabase
//           .from('profiles_public')
//           .select()
//           .eq('id', targetUserId)
//           .limit(1);
//       Map<String, dynamic>? profile = profileRows.isNotEmpty
//           ? profileRows.first as Map<String, dynamic>
//           : null;

//       // Fallback: profiles table directly
//       if (profile == null) {
//         final fallbackRows = await _supabase
//             .from('profiles')
//             .select('id, display_name, username, avatar_url, bio')
//             .eq('id', targetUserId)
//             .limit(1);
//         profile = fallbackRows.isNotEmpty
//             ? fallbackRows.first as Map<String, dynamic>
//             : null;
//       }
//       if (profile == null) throw Exception('Profile not found');

//       // If we only got minimal data (no counts), return basic profile
//       final hasFullData = profile.containsKey('followers_count');
//       if (!hasFullData) {
//         return SocialProfile(
//           userId: profile['id'] as String,
//           displayName: profile['display_name'] as String? ?? 'Player',
//           username: profile['username'] as String?,
//           avatarUrl: profile['avatar_url'] as String?,
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

//   // ── Search ────────────────────────────────────────────────────────────────

//   Future<List<UserEntity>> searchUsers(
//     String query, {
//     required String excludeUserId,
//     int limit = 20,
//   }) => guardedCall(
//     operationName: 'searchUsers',
//     operation: () async {
//       final rows = await _supabase
//           .from('profiles_public')
//           .select('id,username,display_name,avatar_url')
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
//             ),
//           )
//           .toList();
//     },
//   );

//   // ── Private helpers ───────────────────────────────────────────────────────

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
//       rethrow; // actual block — rethrow
//     } catch (_) {
//       // RLS error reading blocked_users — treat as not blocked
//     }
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
//       followedAt: DateTime.parse(row['created_at'] as String),
//       isVerified: profile['verification_status'] == 'verified',
//     );
//   }
// }

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../features/auth/domain/entities/user_entity.dart';

// ── Domain types ──────────────────────────────────────────────────────────────

enum FriendshipStatus { pending, accepted, rejected, blocked }

class FriendEntity {
  const FriendEntity({
    required this.userId,
    required this.displayName,
    this.username,
    this.avatarUrl,
    required this.status,
    required this.isRequester,
    this.mutualFriendsCount = 0,
    this.friendshipId,
  });

  final String userId;
  final String displayName;
  final String? username;
  final String? avatarUrl;
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
    required this.followedAt,
    this.isVerified = false,
  });

  final String userId;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final DateTime followedAt;
  final bool isVerified;
}

class SocialProfile {
  const SocialProfile({
    required this.userId,
    required this.displayName,
    this.username,
    this.avatarUrl,
    this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.friendsCount,
    this.gamesPlayed = 0,
    this.packsCount = 0,
    this.friendshipStatus,
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.isBlocked = false,
    this.isBlockedBy = false,
    this.isVerified = false,
  });

  final String userId;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  final int gamesPlayed;
  final int packsCount;
  final FriendshipStatus? friendshipStatus;
  final bool isFollowing;
  final bool isFollowedBy;
  final bool isBlocked;
  final bool isBlockedBy;
  final bool isVerified;

  bool get canInteract => !isBlocked && !isBlockedBy;
}

// ── Repository ────────────────────────────────────────────────────────────────

class FriendsRepository extends BaseRepository {
  FriendsRepository._();
  static final FriendsRepository _instance = FriendsRepository._();
  static FriendsRepository get instance => _instance;

  final _supabase = Supabase.instance.client;

  // ── Friends ───────────────────────────────────────────────────────────────

  Future<List<FriendEntity>> getFriends(String userId) => guardedCall(
    operationName: 'getFriends',
    operation: () async {
      final rows = await _supabase
          .from('friendships')
          .select(
            'id,status,requester_id,addressee_id,'
            'requester:profiles!requester_id(id,display_name,username,avatar_url),'
            'addressee:profiles!addressee_id(id,display_name,username,avatar_url)',
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
      // Fetch requester profiles separately to avoid join ambiguity
      final requesterIds = rows
          .map((r) => r['requester_id'] as String)
          .toList();
      final profiles = await _supabase
          .from('profiles')
          .select('id,display_name,username,avatar_url')
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
      // Fetch addressee profiles separately
      final addresseeIds = rows
          .map((r) => r['addressee_id'] as String)
          .toList();
      final profiles = await _supabase
          .from('profiles')
          .select('id,display_name,username,avatar_url')
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
      // Check not blocked
      await _checkNotBlocked(requesterId, addresseeId);
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

  // ── Follow system ─────────────────────────────────────────────────────────

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
            'profiles!follower_id(id,display_name,username,avatar_url,verification_status)',
          )
          .eq('followee_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map(_toFollowEntity).toList();
    },
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
            'profiles!followee_id(id,display_name,username,avatar_url,verification_status)',
          )
          .eq('follower_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map((r) => _toFollowEntity(r, followingMode: true)).toList();
    },
  );

  // ── Block system ──────────────────────────────────────────────────────────

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
      // Also remove any existing friendship
      await removeFriend(
        userId: blockerId,
        friendId: blockedId,
      ).catchError((_) {});
      // Remove follow in both directions
      await unfollowUser(blockerId, blockedId).catchError((_) {});
      await unfollowUser(blockedId, blockerId).catchError((_) {});
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
            'profiles!blocked_id(id,display_name,username,avatar_url)',
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
          status: FriendshipStatus.blocked,
          isRequester: true,
        );
      }).toList();
    },
  );

  // ── Social profile ────────────────────────────────────────────────────────

  Future<SocialProfile> getSocialProfile({
    required String targetUserId,
    required String viewerUserId,
  }) => guardedCall(
    operationName: 'getSocialProfile',
    operation: () async {
      // Try profiles_public first (has bio + counts after migration)
      // Use limit(1) to guard against duplicate rows in view/table
      final profileRows = await _supabase
          .from('profiles_public')
          .select()
          .eq('id', targetUserId)
          .limit(1);
      Map<String, dynamic>? profile = profileRows.isNotEmpty
          ? profileRows.first as Map<String, dynamic>
          : null;

      // Fallback: profiles table directly
      if (profile == null) {
        final fallbackRows = await _supabase
            .from('profiles')
            .select('id, display_name, username, avatar_url, bio')
            .eq('id', targetUserId)
            .limit(1);
        profile = fallbackRows.isNotEmpty
            ? fallbackRows.first as Map<String, dynamic>
            : null;
      }
      if (profile == null) throw Exception('Profile not found');

      // If we only got minimal data (no counts), return basic profile
      final hasFullData = profile.containsKey('followers_count');
      if (!hasFullData) {
        return SocialProfile(
          userId: profile['id'] as String,
          displayName: profile['display_name'] as String? ?? 'Player',
          username: profile['username'] as String?,
          avatarUrl: profile['avatar_url'] as String?,
          bio: profile['bio'] as String?,
          followersCount: 0,
          followingCount: 0,
          friendsCount: 0,
          gamesPlayed: 0,
          packsCount: 0,
        );
      }

      final [
        blockedByMe,
        blockedByThem,
        friendshipRow,
        followingRow,
        followedByRow,
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
            .select('status')
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
      ]);

      FriendshipStatus? friendStatus;
      if (friendshipRow != null) {
        friendStatus = FriendshipStatus.values.firstWhere(
          (s) => s.name == (friendshipRow as Map)['status'],
          orElse: () => FriendshipStatus.pending,
        );
      }

      return SocialProfile(
        userId: profile['id'] as String,
        displayName: profile['display_name'] as String? ?? 'User',
        username: profile['username'] as String?,
        avatarUrl: profile['avatar_url'] as String?,
        bio: profile['bio'] as String?,
        followersCount: (profile['followers_count'] as num?)?.toInt() ?? 0,
        followingCount: (profile['following_count'] as num?)?.toInt() ?? 0,
        friendsCount: (profile['friends_count'] as num?)?.toInt() ?? 0,
        gamesPlayed: (profile['games_played'] as num?)?.toInt() ?? 0,
        packsCount: (profile['packs_count'] as num?)?.toInt() ?? 0,
        friendshipStatus: friendStatus,
        isFollowing: followingRow != null,
        isFollowedBy: followedByRow != null,
        isBlocked: blockedByMe != null,
        isBlockedBy: blockedByThem != null,
        isVerified: profile['verification_status'] == 'verified',
      );
    },
  );

  // ── Search ────────────────────────────────────────────────────────────────

  Future<List<UserEntity>> searchUsers(
    String query, {
    required String excludeUserId,
    int limit = 20,
  }) => guardedCall(
    operationName: 'searchUsers',
    operation: () async {
      final rows = await _supabase
          .from('profiles_public')
          .select('id,username,display_name,avatar_url')
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .neq('id', excludeUserId)
          .limit(limit);
      return rows
          .map(
            (r) => UserEntity(
              id: r['id'] as String,
              email: '',
              username: r['username'] as String?,
              displayName: r['display_name'] as String?,
              avatarUrl: r['avatar_url'] as String?,
            ),
          )
          .toList();
    },
  );

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Returns the friendship status between two users, or null if none exists.
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
      rethrow; // actual block — rethrow
    } catch (_) {
      // RLS error reading blocked_users — treat as not blocked
    }
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
      status: FriendshipStatus.values.firstWhere(
        (s) => s.name == (row['status'] as String? ?? ''),
        orElse: () => FriendshipStatus.pending,
      ),
      isRequester: isRequester,
    );
  }

  FollowEntity _toFollowEntity(
    Map<String, dynamic> row, {
    bool followingMode = false,
  }) {
    final profile =
        row[followingMode ? 'profiles!followee_id' : 'profiles!follower_id']
            as Map<String, dynamic>? ??
        {};
    return FollowEntity(
      userId: profile['id'] as String? ?? '',
      displayName: profile['display_name'] as String? ?? 'User',
      username: profile['username'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
      followedAt: DateTime.parse(row['created_at'] as String),
      isVerified: profile['verification_status'] == 'verified',
    );
  }
}
