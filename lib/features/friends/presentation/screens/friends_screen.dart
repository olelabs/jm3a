import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/app_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/blocked_user_card.dart';
import '../../../../shared/widgets/cards/explore_person_card.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../presentation/friends_provider.dart';
import '../widgets/friend_tile.dart';
import 'user_profile_screen.dart';

/// Opens [userId]'s public profile — shared by every tab (Friends,
/// Explore, ...) so "tap a person to view their profile" is wired
/// identically everywhere, instead of only wherever a friendship already
/// happens to exist. Viewing is intentionally NOT friendship-gated (see
/// UserProfileScreen/getSocialProfile — profile data is public-safe by
/// design; only specific social actions like messaging are gated).
void openUserProfile(
  BuildContext ctx,
  String userId, {
  String? knownDisplayName,
  String? knownUsername,
  String? knownAvatarUrl,
  Map<String, dynamic>? knownAvatarConfig,
  bool knownIsPremium = false,
}) {
  Navigator.push(
    ctx,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: ctx.read<FriendsProvider>(),
        child: UserProfileScreen(
          userId: userId,
          knownDisplayName: knownDisplayName,
          knownUsername: knownUsername,
          knownAvatarUrl: knownAvatarUrl,
          knownAvatarConfig: knownAvatarConfig,
          knownIsPremium: knownIsPremium,
        ),
      ),
    ),
  );
}

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  // Exactly 3 top-level sections. Pending incoming requests are content
  // AT THE TOP of Friends, not their own tab — see _FriendsTab. Search is
  // content inside Explore (its own search box), not a separate discovery
  // tab — see _ExploreTab.
  static const int tabFriends = 0;
  static const int tabExplore = 1;
  static const int tabBlocked = 2;
  static const int _tabCount = 3;

  static _FriendsScreenState? _activeState;
  static int? _pendingTabIndex;

  /// Selects a tab on the Friends screen. FriendsScreen is a fixed tab
  /// kept alive inside HomeShellScreen's IndexedStack (see
  /// `RouteNames.friends` navigation, which just switches the shell's
  /// selected index rather than pushing a new route with params) — there's
  /// no GoRouter path parameter to carry "open a specific tab" through.
  /// Animates immediately if the screen is already mounted (a second
  /// notification tap while already here), otherwise remembers the
  /// request for the next `initState`. Used by
  /// NotificationService._routeFromPayload.
  static void selectTab(int index) {
    final state = _activeState;
    if (state != null) {
      state._tabs.animateTo(index);
    } else {
      _pendingTabIndex = index;
    }
  }

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    FriendsScreen._activeState = this;
    final pending = FriendsScreen._pendingTabIndex;
    _tabs = TabController(
      length: FriendsScreen._tabCount,
      vsync: this,
      initialIndex:
          (pending != null && pending >= 0 && pending < FriendsScreen._tabCount)
          ? pending
          : 0,
    );
    FriendsScreen._pendingTabIndex = null;
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (identical(FriendsScreen._activeState, this)) {
      FriendsScreen._activeState = null;
    }
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendsProvider>(
      builder: (ctx, friends, _) {
        final l10n = ctx.l10n;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.navFriends),
            bottom: TabBar(
              controller: _tabs,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.navFriends),
                      if (friends.pendingCount > 0) ...[
                        const SizedBox(width: 4),
                        _Badge(count: friends.pendingCount),
                      ],
                    ],
                  ),
                ),
                Tab(text: l10n.exploreTabLabel),
                Tab(text: l10n.friendsBlocked),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              RefreshIndicator(
                onRefresh: () => friends.refresh(),
                child: _FriendsTab(
                  friends: friends,
                  onExplore: () => _tabs.animateTo(FriendsScreen.tabExplore),
                ),
              ),
              const _ExploreTab(),
              RefreshIndicator(
                onRefresh: () => friends.refresh(),
                child: _BlockedTab(friends: friends),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FriendsTab extends StatelessWidget {
  const _FriendsTab({required this.friends, required this.onExplore});
  final FriendsProvider friends;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final all = friends.friends;
    final pending = friends.pendingRequests;
    final sent = friends.sentRequests;

    // Only the true "nothing at all" case gets the full-screen empty
    // state — pending requests are content in their own right and must
    // stay visible even when the friend list itself is empty (a brand
    // new user with 2 incoming requests and 0 friends yet should still
    // see those requests, not a blank "no friends" screen).
    if (all.isEmpty && pending.isEmpty && sent.isEmpty && !friends.isLoading) {
      return _EmptyState(
        emoji: '👥',
        title: context.l10n.friendsNoFriendsYet,
        subtitle: context.l10n.friendsNoFriendsHint,
        actionLabel: context.l10n.exploreTabLabel,
        onAction: onExplore,
      );
    }

    // Detailed friend presence (lobby vs. specific game) is a premium
    // feature — gated on the *viewer's* own premium status, same
    // isPremiumActive check used everywhere else premium features are
    // gated in this app.
    final showDetail =
        context.watch<AuthProvider>().currentUser?.isPremiumActive ?? false;

    final online = all.where((f) => friends.isOnline(f.userId)).toList();
    final offline = all.where((f) => !friends.isOnline(f.userId)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Pending incoming requests always sit above the normal friends
        // list — never their own tab (see FriendsScreen's 3-tab layout:
        // Friends / Explore / Blocked). Never shown when empty — no
        // placeholder "Pending Friendship Requests (0)" section.
        if (pending.isNotEmpty) ...[
          _SectionHeader(
            label: context.l10n.friendsPendingRequestsHeader,
            color: AppColors.infoBlue,
          ),
          const SizedBox(height: 4),
          ...pending.asMap().entries.map(
            (e) => _RequestCard(
              friend: e.value,
              incoming: true,
              onAccept: () => friends.acceptRequest(e.value.userId),
              onReject: () => friends.rejectRequest(e.value.userId),
            ).animate(delay: (e.key * 40).ms).fadeIn(),
          ),
          const SizedBox(height: 20),
        ],

        if (all.isNotEmpty) ...[
          _SectionHeader(
            label: context.l10n.friendsYourFriendsHeader,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: 4),
          if (online.isNotEmpty) ...[
            _SectionHeader(
              label: context.l10n.friendsOnlineCount(online.length),
              color: AppColors.successGreen,
            ),
            ...online.asMap().entries.map(
              (e) => FriendTile(
                friend: e.value,
                status: friends.statusOf(e.value.userId),
                roomId: friends.roomIdOf(e.value.userId),
                roomStatus: friends.roomStatusOf(e.value.userId),
                gameType: friends.gameTypeOf(e.value.userId),
                showDetail: showDetail,
                onTap: () => openUserProfile(
                  context,
                  e.value.userId,
                  knownDisplayName: e.value.displayName,
                  knownUsername: e.value.username,
                  knownAvatarUrl: e.value.avatarUrl,
                  knownAvatarConfig: e.value.avatarConfig,
                  knownIsPremium: e.value.isPremium,
                ),
                onJoinRoom: friends.roomIdOf(e.value.userId) != null
                    ? () => AppRouter.router.go(
                        '${context.l10n.navRooms}/room/${friends.roomIdOf(e.value.userId)}',
                      )
                    : null,
                onRemove: () => friends.removeFriend(e.value.userId),
                onBlock: () => friends.blockUser(e.value.userId),
              ).animate(delay: (e.key * 30).ms).fadeIn(),
            ),
            const SizedBox(height: 16),
          ],

          if (offline.isNotEmpty) ...[
            _SectionHeader(
              label: context.l10n.friendsOfflineCount(offline.length),
              color: AppColors.textTertiaryLight,
            ),
            ...offline.asMap().entries.map(
              (e) => FriendTile(
                friend: e.value,
                status: friends.statusOf(e.value.userId),
                onTap: () => openUserProfile(
                  context,
                  e.value.userId,
                  knownDisplayName: e.value.displayName,
                  knownUsername: e.value.username,
                  knownAvatarUrl: e.value.avatarUrl,
                  knownAvatarConfig: e.value.avatarConfig,
                  knownIsPremium: e.value.isPremium,
                ),
                onRemove: () => friends.removeFriend(e.value.userId),
                onBlock: () => friends.blockUser(e.value.userId),
              ).animate(delay: (e.key * 20).ms).fadeIn(),
            ),
          ],
        ] else if (pending.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              context.l10n.friendsNoFriendsYet,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

        // Outgoing (sent) requests: not part of the task's own Friends
        // mock, but this is existing functionality (cancel a sent
        // request) that would otherwise be lost with the Requests tab
        // removed — kept as a small trailing section rather than dropped.
        if (sent.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeader(
            label: context.l10n.friendsSentCount(sent.length),
            color: AppColors.warningAmber,
          ),
          const SizedBox(height: 4),
          ...sent.asMap().entries.map(
            (e) => _RequestCard(
              friend: e.value,
              incoming: false,
              onCancel: () => friends.cancelRequest(e.value.userId),
            ).animate(delay: (e.key * 40).ms).fadeIn(),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.friend,
    required this.incoming,
    this.onAccept,
    this.onReject,
    this.onCancel,
  });

  final FriendEntity friend;
  final bool incoming;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: JCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UserAvatar(
              avatarUrl: friend.avatarUrl,
              avatarConfig: friend.avatarConfig,
              isPremium: friend.isPremium,
              displayName: friend.displayName,
              size: 42,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          friend.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (friend.isPremium)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            '✦',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFF5A623),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (friend.username != null)
                    Text(
                      '@${friend.username}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (incoming) ...[
              Tooltip(
                message: context.l10n.friendsDecline,
                child: InkWell(
                  onTap: onReject,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.errorRed,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 76,
                height: 34,
                child: FilledButton.tonal(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    context.l10n.friendsAccept,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ] else
              SizedBox(
                width: 70,
                height: 34,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                  child: Text(
                    context.l10n.cancel,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.errorRed,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BlockedTab extends StatelessWidget {
  const _BlockedTab({required this.friends});
  final FriendsProvider friends;
  @override
  Widget build(BuildContext context) {
    final blocked = friends.blockedUsers;
    if (blocked.isEmpty) {
      return _EmptyState(
        emoji: '🚫',
        title: context.l10n.friendsNoBlockedUsers,
        subtitle: context.l10n.friendsNoBlockedUsersHint,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: blocked.length,
      itemBuilder: (ctx, i) {
        final user = blocked[i];
        return BlockedUserCard(
          user: user,
          onUnblock: () async {
            final ok = await friends.unblockUser(user.userId);
            if (ok && ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(
                    ctx.l10n.friendsUnblockedNotice(user.displayName),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

/// Explore People — server-authoritative, ranked, paginated discovery feed.
/// See FriendsRepository.explorePeople / public.explore_people() for the
/// full ranking/50%-pool/pagination contract this UI is a thin view over.
class _ExploreTab extends StatefulWidget {
  const _ExploreTab();

  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<_ExploreTab> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 240) {
      context.read<FriendsProvider>().loadMoreExplorePeople();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendsProvider>();
    // First mount only — never re-triggered by a rebuild (guarded by
    // _requested, not by list-emptiness, so a genuinely-empty discovery
    // pool doesn't cause a refetch loop on every rebuild).
    if (!_requested) {
      _requested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) friends.loadExplorePeople();
      });
    }

    return RefreshIndicator(
      onRefresh: () => friends.loadExplorePeople(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => friends.loadExplorePeople(search: v),
              decoration: InputDecoration(
                hintText: context.l10n.exploreSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          friends.loadExplorePeople(search: '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.exploreSubtitle,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildBody(context, friends)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, FriendsProvider friends) {
    if (friends.exploreLoading && friends.explorePeople.isEmpty) {
      return const _ExploreLoadingSkeleton();
    }
    if (friends.exploreFailed && friends.explorePeople.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.exploreLoadFailed),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => friends.loadExplorePeople(),
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }
    if (friends.explorePeople.isEmpty) {
      return _EmptyState(
        emoji: '🧭',
        title: context.l10n.exploreEmptyTitle,
        subtitle: context.l10n.exploreEmptyHint,
      );
    }
    final people = friends.explorePeople;
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: people.length + (friends.exploreHasMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i >= people.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return _ExploreCard(
          person: people[i],
          friends: friends,
        ).animate(delay: (i * 20).ms).fadeIn();
      },
    );
  }
}

class _ExploreLoadingSkeleton extends StatelessWidget {
  const _ExploreLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 6,
      itemBuilder: (ctx, i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 84,
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.person, required this.friends});
  final ExplorePerson person;
  final FriendsProvider friends;

  @override
  Widget build(BuildContext context) {
    return ExplorePersonCard(
      person: person,
      hasSentRequest: friends.hasSentExploreRequest(person.userId),
      onAddFriend: () => friends.sendExploreFriendRequest(person.userId),
      onTap: () => openUserProfile(
        context,
        person.userId,
        knownDisplayName: person.displayName,
        knownUsername: person.username,
        knownAvatarUrl: person.avatarUrl,
      ),
    );
  }
}
