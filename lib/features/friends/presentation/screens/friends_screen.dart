import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../data/friends_repository.dart';
import '../../presentation/friends_provider.dart';
import '../widgets/friend_tile.dart';
import '../widgets/online_indicator.dart';
import 'user_profile_screen.dart';

/// Friends screen — 3 tabs: Friends, Requests, Search.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendsProvider>(
      builder: (ctx, friends, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Friends'),
            bottom: TabBar(
              controller: _tabs,
              tabs: [
                const Tab(text: 'Friends'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Requests'),
                      if (friends.pendingCount > 0) ...[
                        const SizedBox(width: 4),
                        _Badge(count: friends.pendingCount),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Search'),
                const Tab(text: 'Blocked'),
              ],
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => friends.refresh(),
            child: TabBarView(
              controller: _tabs,
              children: [
                _FriendsTab(friends: friends),
                _RequestsTab(friends: friends),
                _SearchTab(friends: friends, controller: _searchCtrl),
                _BlockedTab(friends: friends),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Friends tab ────────────────────────────────────────────────────────────────
class _FriendsTab extends StatelessWidget {
  const _FriendsTab({required this.friends});
  final FriendsProvider friends;

  @override
  Widget build(BuildContext context) {
    final all = friends.friends;

    if (all.isEmpty && !friends.isLoading) {
      return _EmptyState(
        emoji: '👥',
        title: 'No friends yet',
        subtitle: 'Search for people and send friend requests.',
      );
    }

    // Separate online from offline
    final online = all.where((f) => friends.isOnline(f.userId)).toList();
    final offline = all.where((f) => !friends.isOnline(f.userId)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (online.isNotEmpty) ...[
          _SectionHeader(
            label: 'Online — ${online.length}',
            color: AppColors.successGreen,
          ),
          ...online.asMap().entries.map(
            (e) => FriendTile(
              friend: e.value,
              status: friends.statusOf(e.value.userId),
              roomId: friends.roomIdOf(e.value.userId),
              onTap: () => _openProfile(context, e.value.userId),
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
            label: 'Offline — ${offline.length}',
            color: AppColors.textTertiaryLight,
          ),
          ...offline.asMap().entries.map(
            (e) => FriendTile(
              friend: e.value,
              status: friends.statusOf(e.value.userId),
              onTap: () => _openProfile(context, e.value.userId),
              onRemove: () => friends.removeFriend(e.value.userId),
              onBlock: () => friends.blockUser(e.value.userId),
            ).animate(delay: (e.key * 20).ms).fadeIn(),
          ),
        ],
      ],
    );
  }

  void _openProfile(BuildContext ctx, String userId) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: ctx.read<FriendsProvider>(),
          child: UserProfileScreen(userId: userId),
        ),
      ),
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

// ── Requests tab ──────────────────────────────────────────────────────────────
class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.friends});
  final FriendsProvider friends;

  @override
  Widget build(BuildContext context) {
    final pending = friends.pendingRequests;
    final sent = friends.sentRequests;

    if (pending.isEmpty && sent.isEmpty) {
      return _EmptyState(
        emoji: '👋',
        title: 'No pending requests',
        subtitle: 'Friend requests you receive will appear here.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          const _SectionHeader(label: 'Received', color: AppColors.infoBlue),
          const SizedBox(height: 4),
          ...pending.asMap().entries.map(
            (e) => _RequestCard(
              friend: e.value,
              incoming: true,
              onAccept: () => friends.acceptRequest(e.value.userId),
              onReject: () => friends.rejectRequest(e.value.userId),
            ).animate(delay: (e.key * 40).ms).fadeIn(),
          ),
          const SizedBox(height: 16),
        ],

        if (sent.isNotEmpty) ...[
          _SectionHeader(
            label: 'Sent — ${sent.length}',
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
              displayName: friend.displayName,
              size: 42,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    friend.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
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
            // Action buttons — explicit fixed sizes to prevent infinite width
            if (incoming) ...[
              InkWell(
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
                  child: const Text('Accept', style: TextStyle(fontSize: 13)),
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
                  child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Search tab ────────────────────────────────────────────────────────────────
class _SearchTab extends StatelessWidget {
  const _SearchTab({required this.friends, required this.controller});
  final FriendsProvider friends;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: controller,
            autofocus: false,
            onChanged: friends.search,
            decoration: InputDecoration(
              hintText: 'Search by username or name…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        controller.clear();
                        friends.clearSearch();
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: friends.isSearching
              ? const Center(child: CircularProgressIndicator())
              : friends.searchResults.isEmpty
              ? (controller.text.length >= 2
                    ? _EmptyState(
                        emoji: '🔍',
                        title: 'No results',
                        subtitle: 'Try a different name or username.',
                      )
                    : _EmptyState(
                        emoji: '🔍',
                        title: 'Search for friends',
                        subtitle: 'Enter at least 2 characters.',
                      ))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: friends.searchResults.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 60),
                  itemBuilder: (ctx, i) {
                    final user = friends.searchResults[i];
                    final isFriend = friends.friends.any(
                      (f) => f.userId == user.id,
                    );
                    final hasSent = friends.sentRequests.any(
                      (r) => r.userId == user.id,
                    );
                    // They sent us a request — show Accept
                    final hasIncoming = friends.pendingRequests.any(
                      (r) => r.userId == user.id,
                    );

                    return ListTile(
                      leading: UserAvatar(
                        avatarUrl: user.avatarUrl,
                        displayName: user.displayName ?? 'User',
                        size: 40,
                      ),
                      title: Text(user.displayName ?? 'User'),
                      subtitle: user.username != null
                          ? Text('@${user.username}')
                          : null,
                      trailing: SizedBox(
                        width: 90,
                        child: isFriend
                            ? const Chip(
                                label: Text('Friends'),
                                visualDensity: VisualDensity.compact,
                              )
                            : hasIncoming
                            ? SizedBox(
                                height: 34,
                                child: FilledButton(
                                  onPressed: () =>
                                      friends.acceptRequest(user.id),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Accept',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                            : hasSent
                            ? const Chip(
                                label: Text('Pending'),
                                visualDensity: VisualDensity.compact,
                              )
                            : FilledButton.tonal(
                                onPressed: () =>
                                    friends.sendFriendRequest(user.id),
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                child: const Text('Add'),
                              ),
                      ),
                      onTap: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: friends,
                            child: UserProfileScreen(userId: user.id),
                          ),
                        ),
                      ),
                    ).animate(delay: (i * 25).ms).fadeIn();
                  },
                ),
        ),
      ],
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
  });
  final String emoji;
  final String title;
  final String subtitle;

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
    if (blocked.isEmpty)
      return const Center(
        child: Text('No blocked users.', style: TextStyle(color: Colors.grey)),
      );
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: blocked.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final user = blocked[i];
        return ListTile(
          leading: CircleAvatar(child: Text(user.displayName[0].toUpperCase())),
          title: Text(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('Blocked'),
          trailing: TextButton(
            onPressed: () async {
              final ok = await friends.unblockUser(user.userId);
              if (ok && context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(user.displayName + ' unblocked')),
                );
            },
            child: const Text('Unblock', style: TextStyle(color: Colors.blue)),
          ),
        );
      },
    );
  }
}
