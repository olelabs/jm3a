import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/providers/base_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../features/auth/domain/entities/user_entity.dart';
import '../../rooms/data/room_repository.dart' show isDirectlyJoinableRoom;
import '../data/friends_repository.dart';

export '../data/friends_repository.dart';
export 'friend_request_messages.dart';

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
  Map<String, FriendEntity> _searchStatuses = {};
  bool _isSearching = false;
  String _searchQuery = '';

  // ── Explore People (see FriendsRepository.explorePeople /
  // public.explore_people()) — kept on this SAME provider rather than a
  // new one, so "Add Friend" on an Explore card reuses the exact
  // sendFriendRequest() path/optimistic-update below, and so a request
  // accepted elsewhere (via the friendships CDC subscription) can
  // eventually be reflected here too without a second live channel. ────
  List<ExplorePerson> _explorePeople = [];
  bool _exploreLoading = false;
  bool _exploreLoadingMore = false;
  bool _exploreHasMore = true;
  bool _exploreFailed = false;
  int? _exploreCursor;
  String _exploreSearch = '';
  final Set<String> _exploreSentRequestIds = {};

  // Presence: userId → status
  Map<String, UserPresenceStatus> _presenceMap = {};

  // Phase 3 (Friends room Join eligibility) — userId → whether that
  // friend's current room passes isDirectlyJoinableRoom. Populated
  // lazily from presence (see _refreshJoinEligibility) rather than
  // eagerly for every friend, since it needs a real `rooms` read
  // PresenceService's own payload doesn't carry.
  final Map<String, bool> _joinEligibilityCache = {};
  final Set<String> _eligibilityInFlight = {};

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
  Map<String, FriendEntity> get searchStatuses => _searchStatuses;
  bool get isSearching => _isSearching;
  int get pendingCount => _pendingRequests.length;

  List<ExplorePerson> get explorePeople => _explorePeople;
  bool get exploreLoading => _exploreLoading;
  bool get exploreLoadingMore => _exploreLoadingMore;
  bool get exploreHasMore => _exploreHasMore;
  bool get exploreFailed => _exploreFailed;
  bool hasSentExploreRequest(String userId) =>
      _exploreSentRequestIds.contains(userId);

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

  /// 'lobby' or 'in_game' — the detail behind the coarse inGame status,
  /// shown to premium viewers only (see FriendTile). Reads straight
  /// through to PresenceService rather than duplicating it in
  /// _presenceMap, same as roomIdOf above.
  String? roomStatusOf(String userId) =>
      PresenceService.instance.currentPresence[userId]?.roomStatus;

  /// GameType.toDbString() of the game currently in progress in that
  /// room, if any — null while the friend is only in the room's lobby.
  String? gameTypeOf(String userId) =>
      PresenceService.instance.currentPresence[userId]?.gameType;

  /// Phase 3 (Friends room Join eligibility) — whether the Join button
  /// should be shown for this friend's current room. Always false until
  /// a real eligibility check has actually completed for them (see
  /// _refreshJoinEligibility) — defaulting to "don't show" rather than
  /// "show", since PresenceService's own roomId/roomStatus alone can
  /// never prove direct-join eligibility (no capacity/visibility/
  /// approval data in presence — see isDirectlyJoinableRoom's own doc
  /// comment). Tapping Join (unchanged) still goes through the real,
  /// server-enforced room-join flow regardless of this cache.
  bool joinEligible(String userId) => _joinEligibilityCache[userId] ?? false;

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
    // PresenceService.start() actually joins+tracks on the shared
    // presence channel — without this, statusOf()/currentPresence stayed
    // permanently empty (nobody was ever marked online), and the whole
    // online/offline friend-status feature this subscribes to below was
    // silently non-functional.
    PresenceService.instance.start(userId);
    _subscribePresence();
  }

  @override
  void onUserLoggedOut() {
    _presenceSub?.cancel();
    PresenceService.instance.stop();
    _friendshipChannel?.unsubscribe();
    _friends = [];
    _pendingRequests = [];
    _sentRequests = [];
    _followers = [];
    _following = [];
    _blockedUsers = [];
    _searchResults = [];
    _searchStatuses = {};
    _presenceMap = {};
    _explorePeople = [];
    _exploreSentRequestIds.clear();
    _sendingRequestIds.clear();
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
      // Re-derive _presenceMap against the friend list that just changed,
      // not just on the next presence stream event. Without this: if the
      // presence channel's initial sync (or any join/leave) fires BEFORE
      // this DB load finishes — a real race, one is a websocket
      // handshake, the other a DB round-trip, either can win —
      // _presenceMap gets computed against an empty _friends and stays
      // stuck empty (every friend shows offline) until some OTHER
      // unrelated presence event happens to re-run the filter, which may
      // never happen. This was the root cause of friends who were
      // already online before the app opened showing as offline.
      _refreshPresenceMap();
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
            final requesterId = payload.newRecord['requester_id'] as String?;
            if (requesterId != null) {
              _searchStatuses = {
                ..._searchStatuses,
                requesterId: FriendEntity(
                  userId: requesterId,
                  displayName: '',
                  status: FriendshipStatus.pending,
                  isRequester: false,
                ),
              };
              notifyListeners();
            }
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
            AppLogger.debug('FriendsProvider: friendship UPDATE (addressee)');
            _loadPendingRequests(userId);
            _loadFriends(userId);
          },
        )
        // The requester side of an UPDATE (addressee accepted/rejected)
        // never matches the addressee_id filter above — without this,
        // the SENDER of a request never found out live that it was
        // accepted, and kept showing "pending" until an app restart or
        // a fresh search.
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'friendships',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'requester_id',
            value: userId,
          ),
          callback: (payload) {
            AppLogger.debug('FriendsProvider: friendship UPDATE (requester)');
            _loadSentRequests(userId);
            _loadFriends(userId);
            final addresseeId = payload.newRecord['addressee_id'] as String?;
            final status = payload.newRecord['status'] as String?;
            if (addresseeId != null && status != null) {
              final parsed = FriendshipStatus.values.firstWhere(
                (s) => s.name == status,
                orElse: () => FriendshipStatus.pending,
              );
              _searchStatuses = {
                ..._searchStatuses,
                addresseeId: FriendEntity(
                  userId: addresseeId,
                  displayName: '',
                  status: parsed,
                  isRequester: true,
                ),
              };
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  // ── Presence ──────────────────────────────────────────────────────────────
  void _subscribePresence() {
    _presenceSub?.cancel();
    _presenceSub = PresenceService.instance.presenceStream.listen((_) {
      _refreshPresenceMap();
      notifyListeners();
      _refreshJoinEligibility();
    });
  }

  /// Phase 3 (Friends room Join eligibility) — recomputes _joinEligibilityCache
  /// against the CURRENT presence snapshot. Cheap pre-filter first: a
  /// friend whose presence shows `roomStatus == 'in_game'` (or no room at
  /// all) already fails isDirectlyJoinableRoom's `!gameStarted`/room-
  /// presence requirement, so those are resolved to false/removed with NO
  /// query at all — a `rooms` read is only ever issued for a friend
  /// currently shown as being in a room's LOBBY, and only once per such
  /// friend at a time (see _eligibilityInFlight).
  Future<void> _refreshJoinEligibility() async {
    final currentlyInLobby = <String, String>{}; // userId -> roomId
    for (final f in _friends) {
      final roomId = roomIdOf(f.userId);
      if (roomId != null && roomStatusOf(f.userId) == 'lobby') {
        currentlyInLobby[f.userId] = roomId;
      }
    }

    // Drop cache entries for anyone no longer shown as being in a lobby —
    // a stale `true` must never linger after a friend leaves/the game
    // starts.
    _joinEligibilityCache.removeWhere(
      (userId, _) => !currentlyInLobby.containsKey(userId),
    );

    for (final entry in currentlyInLobby.entries) {
      final userId = entry.key;
      final roomId = entry.value;
      if (_eligibilityInFlight.contains(userId)) continue;
      _eligibilityInFlight.add(userId);
      try {
        final info = await sl.roomRepository.getRoomJoinEligibility(roomId);
        final eligible =
            info != null &&
            isDirectlyJoinableRoom(
              isOwnedByDisplayedUser: info.ownerId == userId,
              isPublic: info.isPublic,
              hasCapacity: info.hasCapacity,
              gameStarted: info.gameStarted,
              requiresApproval: info.requiresApproval,
            );
        _joinEligibilityCache[userId] = eligible;
        notifyListeners();
      } catch (e) {
        AppLogger.warning('getRoomJoinEligibility failed for $userId: $e');
        _joinEligibilityCache.remove(userId);
      } finally {
        _eligibilityInFlight.remove(userId);
      }
    }
  }

  /// Single source of truth for deriving _presenceMap: always reads the
  /// *current* presence snapshot and the *current* friend list, rather
  /// than trusting whichever stale copy either side had at the moment
  /// some earlier event fired. Called both from the presence stream
  /// listener (friend's status changed) and from _loadFriends (friend
  /// list itself changed) — the same two-sided race that made "friends
  /// already online show offline" possible.
  void _refreshPresenceMap() {
    final friendIds = _friends.map((f) => f.userId).toSet();
    final presence = PresenceService.instance.currentPresence;
    _presenceMap = {
      for (final entry in presence.entries)
        if (friendIds.contains(entry.key)) entry.key: entry.value.status,
    };
  }

  // ── Friend actions ────────────────────────────────────────────────────────

  /// User ids with a friend request currently in flight — lets every Add
  /// Friend control disable itself so a double tap can't fire twice.
  final Set<String> _sendingRequestIds = {};
  bool isSendingFriendRequest(String userId) =>
      _sendingRequestIds.contains(userId);

  /// Sends a friend request and updates local state to match what the
  /// server now holds. Returns null on failure (see [failure] for why) —
  /// including when a request to [addresseeId] is already in flight.
  ///
  /// Pre-release audit (Add Friend fix): this used to return
  /// `runAsync(...) != null`, but runAsync's result for a closure with no
  /// return value is always null, so it reported FALSE on every
  /// successful send. sendExploreFriendRequest relied on that bool to
  /// flip the Explore card to "Request Sent", so the card stayed "Add
  /// Friend" after a successful request (and a second tap then failed
  /// silently on the existing row).
  Future<FriendRequestOutcome?> sendFriendRequest(String addresseeId) async {
    final me = currentUserId;
    if (me == null) return null;
    if (!_sendingRequestIds.add(addresseeId)) return null;
    notifyListeners();
    try {
      final outcome = await runAsync(
        () => _repo.sendFriendRequest(requesterId: me, addresseeId: addresseeId),
        setLoading: false,
      );
      if (outcome != null) {
        await _applyFriendRequestOutcome(me, addresseeId, outcome);
      }
      return outcome;
    } finally {
      _sendingRequestIds.remove(addresseeId);
      notifyListeners();
    }
  }

  Future<void> _applyFriendRequestOutcome(
    String me,
    String otherId,
    FriendRequestOutcome outcome,
  ) async {
    switch (outcome) {
      case FriendRequestOutcome.sent:
      case FriendRequestOutcome.alreadySent:
        _searchStatuses = {
          ..._searchStatuses,
          otherId: FriendEntity(
            userId: otherId,
            displayName: '',
            status: FriendshipStatus.pending,
            isRequester: true,
          ),
        };
        _exploreSentRequestIds.add(otherId);
        notifyListeners(); // update UI immediately
        await _loadSentRequests(me);
      case FriendRequestOutcome.incomingPending:
        _searchStatuses = {
          ..._searchStatuses,
          otherId: FriendEntity(
            userId: otherId,
            displayName: '',
            status: FriendshipStatus.pending,
            isRequester: false,
          ),
        };
        // explore_people() excludes pending pairs, so this card would not
        // be returned on the next refresh anyway.
        _explorePeople = _explorePeople
            .where((p) => p.userId != otherId)
            .toList();
        notifyListeners();
        await _loadPendingRequests(me);
      case FriendRequestOutcome.alreadyFriends:
        _searchStatuses = {
          ..._searchStatuses,
          otherId: FriendEntity(
            userId: otherId,
            displayName: '',
            status: FriendshipStatus.accepted,
            isRequester: false,
          ),
        };
        _explorePeople = _explorePeople
            .where((p) => p.userId != otherId)
            .toList();
        notifyListeners();
        await _loadFriends(me);
    }
  }

  // ── Explore People ──────────────────────────────────────────────────────

  /// Loads (or reloads, e.g. pull-to-refresh) the first page. Resets
  /// pagination/cursor state — never appends.
  Future<void> loadExplorePeople({String? search}) async {
    if (search != null) _exploreSearch = search;
    _exploreLoading = true;
    _exploreFailed = false;
    notifyListeners();
    final result = await runAsync(
      () => _repo.explorePeople(search: _exploreSearch),
      setLoading: false,
    );
    _exploreLoading = false;
    if (result == null) {
      _exploreFailed = true;
    } else {
      // A fresh first page is server-authoritative: explore_people()
      // never returns anyone with a pending request either way, so a
      // locally remembered "Request Sent" (e.g. for a request since
      // rejected) must not linger onto a re-surfaced card.
      _exploreSentRequestIds.clear();
      // Item 8 — never show an incomplete (non-official) account in
      // Discover Friends. Jma3a Official is always discoverable (see
      // ExplorePerson.isDiscoverable's own doc comment) but is filtered
      // separately from ever being offered a friend request — see
      // ExplorePersonCard. Enforced client-side even if explore_people()
      // itself doesn't already exclude incomplete profiles (this repo
      // cannot verify the RPC's server-side filtering without a live
      // database, so this client-side pass is the safest available
      // protection regardless). Applied AFTER pagination is computed from the raw
      // `result` (cursor/hasMore still reflect what the server actually
      // returned) — filtering only affects what's rendered, so a page that
      // was entirely non-discoverable accounts doesn't wrongly look like
      // "no more results" instead of loading the next page.
      _exploreCursor = result.isEmpty ? null : result.last.rankPosition;
      // A short page means we've reached the end of the discovery pool —
      // avoids one extra round trip that would just come back empty.
      _exploreHasMore = result.length >= 20;
      _explorePeople = result.where((p) => p.isDiscoverable).toList();
    }
    notifyListeners();
  }

  /// Appends the next page using the last row's rankPosition as the
  /// keyset cursor (see explore_people()'s own pagination contract) —
  /// never an offset, so scrolling can't duplicate/skip a candidate.
  Future<void> loadMoreExplorePeople() async {
    if (_exploreLoadingMore || !_exploreHasMore || _exploreCursor == null)
      return;
    _exploreLoadingMore = true;
    notifyListeners();
    final result = await runAsync(
      () => _repo.explorePeople(
        afterRankPosition: _exploreCursor,
        search: _exploreSearch,
      ),
      setLoading: false,
    );
    _exploreLoadingMore = false;
    if (result != null) {
      // Same item-8 filtering as loadExplorePeople — see its doc comment.
      if (result.isNotEmpty) _exploreCursor = result.last.rankPosition;
      _exploreHasMore = result.length >= 20;
      _explorePeople = [
        ..._explorePeople,
        ...result.where((p) => p.isDiscoverable),
      ];
    }
    notifyListeners();
  }

  /// Sends a friend request from an Explore card, then flips that card to
  /// "Request Sent" locally without re-fetching the whole feed — reuses
  /// the exact same server-authoritative sendFriendRequest() above (never
  /// a separate/parallel friend-request path for Explore).
  Future<FriendRequestOutcome?> sendExploreFriendRequest(String userId) =>
      sendFriendRequest(userId);

  Future<void> acceptRequest(String requesterId) async {
    final done = await runAsync(() async {
      await _repo.respondToRequest(
        requesterId: requesterId,
        addresseeId: currentUserId!,
        accept: true,
      );
      _pendingRequests.removeWhere((r) => r.userId == requesterId);
      _searchStatuses = {
        ..._searchStatuses,
        requesterId: FriendEntity(
          userId: requesterId,
          displayName: '',
          status: FriendshipStatus.accepted,
          isRequester: false,
        ),
      };
      await _loadFriends(currentUserId!);
      return true;
    }, setLoading: false);
    // The request may have been cancelled by its sender in the
    // meantime (respondToRequest now reports that instead of silently
    // updating zero rows) — resync so the stale entry disappears.
    if (done == null && currentUserId != null) {
      await _loadPendingRequests(currentUserId!);
    }
  }

  Future<void> rejectRequest(String requesterId) async {
    final done = await runAsync(() async {
      await _repo.respondToRequest(
        requesterId: requesterId,
        addresseeId: currentUserId!,
        accept: false,
      );
      _pendingRequests.removeWhere((r) => r.userId == requesterId);
      _searchStatuses = {
        ..._searchStatuses,
        requesterId: FriendEntity(
          userId: requesterId,
          displayName: '',
          status: FriendshipStatus.rejected,
          isRequester: false,
        ),
      };
      notifyListeners();
      return true;
    }, setLoading: false);
    // The request may have been cancelled by its sender in the
    // meantime (respondToRequest now reports that instead of silently
    // updating zero rows) — resync so the stale entry disappears.
    if (done == null && currentUserId != null) {
      await _loadPendingRequests(currentUserId!);
    }
  }

  Future<void> cancelRequest(String addresseeId) => runAsync(() async {
    await _repo.cancelRequest(
      requesterId: currentUserId!,
      addresseeId: addresseeId,
    );
    _sentRequests.removeWhere((r) => r.userId == addresseeId);
    _searchStatuses.remove(addresseeId);
    _exploreSentRequestIds.remove(addresseeId);
    notifyListeners();
  }, setLoading: false);

  Future<void> removeFriend(String friendId) => runAsync(() async {
    await _repo.removeFriend(userId: currentUserId!, friendId: friendId);
    _friends.removeWhere((f) => f.userId == friendId);
    _searchStatuses.remove(friendId);
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

  /// Item 9 — reports a user's profile. Mirrors [blockUser]'s shape;
  /// unlike blockUser this never mutates the friends/following lists —
  /// reporting someone doesn't imply blocking them (that's the separate
  /// "Report & Block" action, which calls both).
  Future<bool> reportUser({
    required String targetUserId,
    required String reason,
    String? details,
  }) async {
    if (currentUserId == null) return false;
    var success = false;
    await runAsync(() async {
      await _repo.reportUser(
        targetUserId: targetUserId,
        reporterId: currentUserId!,
        reason: reason,
        details: details,
      );
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
      _searchStatuses = {};
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
      // Live per-pair lookup, not the cached friends/sentRequests/
      // pendingRequests lists — those only refresh on login/pull-to-
      // refresh/realtime and previously left search showing "Add Friend"
      // for a relationship that already existed.
      _searchStatuses = currentUserId == null
          ? {}
          : await _repo.getFriendshipStatuses(
              userId: currentUserId!,
              otherIds: _searchResults.map((u) => u.id).toList(),
            );
    } catch (_) {
      _searchResults = [];
      _searchStatuses = {};
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _searchStatuses = {};
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
