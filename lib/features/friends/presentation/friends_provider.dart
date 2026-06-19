import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/base_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../features/auth/domain/entities/user_entity.dart';
import '../data/friends_repository.dart';

export '../data/friends_repository.dart';

/// Complete social provider: friends, followers, blocks, search, presence.
///
/// Lifecycle: lives for the user session.
/// CDC subscription on friendships table delivers friend request changes
/// without polling. Presence stream delivers online/in-game status.
class FriendsProvider extends BaseProvider {
  FriendsProvider({required FriendsRepository friendsRepository})
    : _repo = friendsRepository;

  final FriendsRepository _repo;

  // ── State ──────────────────────────────────────────────────────────────────
  List<FriendEntity> _friends = [];
  List<FriendEntity> _pendingRequests = [];
  List<FriendEntity> _sentRequests = [];
  List<FollowEntity> _followers = [];
  List<FollowEntity> _following = [];
  List<FriendEntity> _blockedUsers = [];
  List<UserEntity> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  // Presence: userId → status
  Map<String, UserPresenceStatus> _presenceMap = {};

  // CDC subscription for friendship table
  RealtimeChannel? _friendshipChannel;
  StreamSubscription<Map<String, UserPresence>>? _presenceSub;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<FriendEntity> get friends => _friends;
  List<FriendEntity> get pendingRequests => _pendingRequests;
  List<FriendEntity> get sentRequests => _sentRequests;
  List<FollowEntity> get followers => _followers;
  List<FollowEntity> get following => _following;
  List<FriendEntity> get blockedUsers => _blockedUsers;
  List<UserEntity> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  int get pendingCount => _pendingRequests.length;

  // Online friends sorted by status (inGame > online > offline)
  List<FriendEntity> get onlineFriends =>
      _friends
          .where(
            (f) =>
                _presenceMap[f.userId] != UserPresenceStatus.offline &&
                _presenceMap.containsKey(f.userId),
          )
          .toList()
        ..sort((a, b) {
          final sa = _presenceOf(a.userId);
          final sb = _presenceOf(b.userId);
          if (sa == sb) return 0;
          if (sa == UserPresenceStatus.inGame) return -1;
          if (sb == UserPresenceStatus.inGame) return 1;
          return 0;
        });

  UserPresenceStatus statusOf(String userId) =>
      _presenceMap[userId] ?? UserPresenceStatus.offline;

  bool isOnline(String userId) =>
      _presenceMap[userId] != UserPresenceStatus.offline &&
      _presenceMap.containsKey(userId);

  bool isInGame(String userId) =>
      _presenceMap[userId] == UserPresenceStatus.inGame;

  String? roomIdOf(String userId) =>
      PresenceService.instance.currentPresence[userId]?.roomId;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onUserLoggedIn(String userId) {
    runAsync(() async {
      await Future.wait([
        _loadFriends(userId),
        _loadPendingRequests(userId),
        _loadSentRequests(userId),
      ]);
    });
    _subscribeFriendshipCDC(userId);
    _subscribePresence();
  }

  @override
  void onUserLoggedOut() {
    _presenceSub?.cancel();
    _friendshipChannel?.unsubscribe();
    _friends = [];
    _pendingRequests = [];
    _sentRequests = [];
    _followers = [];
    _following = [];
    _blockedUsers = [];
    _searchResults = [];
    _presenceMap = {};
    super.onUserLoggedOut();
  }

  @override
  void dispose() {
    _presenceSub?.cancel();
    _friendshipChannel?.unsubscribe();
    super.dispose();
  }

  // ── Load helpers ───────────────────────────────────────────────────────────

  Future<void> refresh() async {
    if (currentUserId == null) return;
    await Future.wait([
      _loadFriends(currentUserId!),
      _loadPendingRequests(currentUserId!),
      _loadSentRequests(currentUserId!),
    ]);
    notifyListeners();
  }

  Future<void> _loadFriends(String userId) async {
    try {
      _friends = await _repo.getFriends(userId);
      notifyListeners();
    } catch (e) {
      AppLogger.error('FriendsProvider: loadFriends failed', error: e);
    }
  }

  Future<void> _loadPendingRequests(String userId) async {
    try {
      _pendingRequests = await _repo.getPendingRequests(userId);
      notifyListeners();
    } catch (e) {
      AppLogger.error('FriendsProvider: loadPendingRequests failed', error: e);
    }
  }

  Future<void> _loadSentRequests(String userId) async {
    try {
      _sentRequests = await _repo.getSentRequests(userId);
      notifyListeners();
    } catch (e) {
      AppLogger.error('FriendsProvider: loadSentRequests failed', error: e);
    }
  }

  Future<void> loadFollowers() async {
    if (currentUserId == null) return;
    _followers = await _repo.getFollowers(currentUserId!);
    notifyListeners();
  }

  Future<void> loadFollowing() async {
    if (currentUserId == null) return;
    _following = await _repo.getFollowing(currentUserId!);
    notifyListeners();
  }

  Future<void> loadBlockedUsers() async {
    if (currentUserId == null) return;
    _blockedUsers = await _repo.getBlockedUsers(currentUserId!);
    notifyListeners();
  }

  // ── Realtime: CDC on friendships ──────────────────────────────────────────
  /// Supabase CDC picks up INSERT (new friend request) and UPDATE
  /// (request accepted/rejected). Re-fetches the relevant list on change.
  void _subscribeFriendshipCDC(String userId) {
    _friendshipChannel?.unsubscribe();

    // supabase_flutter v2 does not have insertOrUpdate — subscribe to each event
    _friendshipChannel = Supabase.instance.client
        .channel('friendships-cdc-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'friendships',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'addressee_id',
            value: userId,
          ),
          callback: (payload) {
            AppLogger.debug('FriendsProvider: friendship INSERT');
            _loadPendingRequests(userId);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'friendships',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'addressee_id',
            value: userId,
          ),
          callback: (payload) {
            AppLogger.debug('FriendsProvider: friendship UPDATE');
            _loadPendingRequests(userId);
            _loadFriends(userId);
          },
        )
        .subscribe();
  }

  // ── Presence ──────────────────────────────────────────────────────────────
  void _subscribePresence() {
    _presenceSub?.cancel();
    _presenceSub = PresenceService.instance.presenceStream.listen((presence) {
      final friendIds = _friends.map((f) => f.userId).toSet();
      _presenceMap = {
        for (final entry in presence.entries)
          if (friendIds.contains(entry.key)) entry.key: entry.value.status,
      };
      notifyListeners();
    });
  }

  // ── Friend actions ────────────────────────────────────────────────────────

  Future<bool> sendFriendRequest(String addresseeId) async {
    if (currentUserId == null) return false;
    final ok = await runAsync(() async {
      await _repo.sendFriendRequest(
        requesterId: currentUserId!,
        addresseeId: addresseeId,
      );
      await _loadSentRequests(currentUserId!);
      notifyListeners(); // update UI immediately
    }, setLoading: false);
    if (ok != null) notifyListeners();
    return ok != null;
  }

  Future<void> acceptRequest(String requesterId) => runAsync(() async {
    await _repo.respondToRequest(
      requesterId: requesterId,
      addresseeId: currentUserId!,
      accept: true,
    );
    _pendingRequests.removeWhere((r) => r.userId == requesterId);
    await _loadFriends(currentUserId!);
  }, setLoading: false);

  Future<void> rejectRequest(String requesterId) => runAsync(() async {
    await _repo.respondToRequest(
      requesterId: requesterId,
      addresseeId: currentUserId!,
      accept: false,
    );
    _pendingRequests.removeWhere((r) => r.userId == requesterId);
    notifyListeners();
  }, setLoading: false);

  Future<void> cancelRequest(String addresseeId) => runAsync(() async {
    await _repo.cancelRequest(
      requesterId: currentUserId!,
      addresseeId: addresseeId,
    );
    _sentRequests.removeWhere((r) => r.userId == addresseeId);
    notifyListeners();
  }, setLoading: false);

  Future<void> removeFriend(String friendId) => runAsync(() async {
    await _repo.removeFriend(userId: currentUserId!, friendId: friendId);
    _friends.removeWhere((f) => f.userId == friendId);
    notifyListeners();
  }, setLoading: false);

  // ── Follow actions ────────────────────────────────────────────────────────

  Future<bool> followUser(String targetId) async {
    if (currentUserId == null) return false;
    var success = false;
    await runAsync(() async {
      await _repo.followUser(currentUserId!, targetId);
      success = true;
    }, setLoading: false);
    if (success) await loadFollowing();
    return success;
  }

  Future<bool> unfollowUser(String targetId) async {
    if (currentUserId == null) return false;
    var success = false;
    await runAsync(() async {
      await _repo.unfollowUser(currentUserId!, targetId);
      success = true;
    }, setLoading: false);
    if (success) {
      _following.removeWhere((f) => f.userId == targetId);
      notifyListeners();
    }
    return success;
  }

  // ── Block actions ─────────────────────────────────────────────────────────

  Future<bool> blockUser(String targetId) async {
    if (currentUserId == null) return false;
    var success = false;
    await runAsync(() async {
      await _repo.blockUser(blockerId: currentUserId!, blockedId: targetId);
      _friends.removeWhere((f) => f.userId == targetId);
      _pendingRequests.removeWhere((r) => r.userId == targetId);
      _following.removeWhere((f) => f.userId == targetId);
      _followers.removeWhere((f) => f.userId == targetId);
      await loadBlockedUsers();
      success = true;
    }, setLoading: false);
    return success;
  }

  Future<bool> unblockUser(String targetId) async {
    if (currentUserId == null) return false;
    var success = false;
    await runAsync(() async {
      await _repo.unblockUser(blockerId: currentUserId!, blockedId: targetId);
      _blockedUsers.removeWhere((u) => u.userId == targetId);
      notifyListeners();
      success = true;
    }, setLoading: false);
    return success;
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    try {
      _searchResults = await _repo.searchUsers(
        query,
        excludeUserId: currentUserId ?? '',
      );
    } catch (_) {
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  // ── Social profile ────────────────────────────────────────────────────────

  Future<SocialProfile?> getSocialProfile(String targetUserId) async {
    if (currentUserId == null) return null;
    return _repo.getSocialProfile(
      targetUserId: targetUserId,
      viewerUserId: currentUserId!,
    );
  }

  // ── Private ───────────────────────────────────────────────────────────────

  UserPresenceStatus _presenceOf(String userId) =>
      _presenceMap[userId] ?? UserPresenceStatus.offline;
}
