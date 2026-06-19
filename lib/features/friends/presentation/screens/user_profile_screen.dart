// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/buttons/j_button.dart';
// import '../../../../shared/widgets/cards/user_avatar.dart';
// import '../../../../shared/widgets/feedback/error_view.dart';
// import '../../data/friends_repository.dart';
// import '../../presentation/friends_provider.dart';
// import '../widgets/online_indicator.dart';

// class UserProfileScreen extends StatefulWidget {
//   const UserProfileScreen({super.key, required this.userId});
//   final String userId;

//   @override
//   State<UserProfileScreen> createState() => _UserProfileScreenState();
// }

// class _UserProfileScreenState extends State<UserProfileScreen> {
//   SocialProfile? _profile;
//   bool _isLoading = true;
//   bool _isActing  = false;
//   Object? _error;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     setState(() { _isLoading = true; _error = null; });
//     try {
//       _profile = await context.read<FriendsProvider>()
//           .getSocialProfile(widget.userId);
//       if (mounted) setState(() => _isLoading = false);
//     } catch (e) {
//       if (mounted) setState(() { _error = e; _isLoading = false; });
//     }
//   }

//   Future<void> _act(Future<void> Function() fn) async {
//     setState(() => _isActing = true);
//     await fn();
//     await _load();
//     setState(() => _isActing = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (_error != null || _profile == null) {
//       return Scaffold(
//         appBar: AppBar(),
//         body: ErrorView(message: 'Profile not found.', onRetry: _load),
//       );
//     }

//     final p       = _profile!;
//     final friends = context.watch<FriendsProvider>();
//     final theme   = context.theme;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(p.displayName),
//         actions: [
//           if (!p.isBlocked && !p.isBlockedBy)
//             PopupMenuButton<String>(
//               itemBuilder: (_) => [
//                 PopupMenuItem(
//                   value: 'block',
//                   child: Row(
//                     children: [
//                       Icon(Icons.block_rounded, color: AppColors.errorRed),
//                       const SizedBox(width: 8),
//                       Text('Block',
//                           style: TextStyle(color: AppColors.errorRed)),
//                     ],
//                   ),
//                 ),
//               ],
//               onSelected: (v) {
//                 if (v == 'block') {
//                   _act(() => friends.blockUser(p.userId));
//                 }
//               },
//             ),
//         ],
//       ),
//       body: _isActing
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               child: Column(
//                 children: [
//                   // ── Header ─────────────────────────────────────────────
//                   Container(
//                     width: double.infinity,
//                     color: theme.colorScheme.surfaceContainerHighest,
//                     padding: const EdgeInsets.all(24),
//                     child: Column(
//                       children: [
//                         UserAvatar(
//                           avatarUrl:   p.avatarUrl,
//                           displayName: p.displayName,
//                           size:        80,
//                           showOnlineStatus: !p.isBlockedBy && !p.isBlocked,
//                           isOnline: friends.isOnline(p.userId),
//                         ).animate().scale(
//                               begin: const Offset(0.8, 0.8),
//                               end: const Offset(1, 1),
//                               duration: 300.ms),
//                         const SizedBox(height: 12),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(p.displayName,
//                                 style: theme.textTheme.headlineSmall?.copyWith(
//                                     fontWeight: FontWeight.w800)),
//                             if (p.isVerified) ...[
//                               const SizedBox(width: 4),
//                               const Icon(Icons.verified_rounded,
//                                   size: 20, color: AppColors.infoBlue),
//                             ],
//                           ],
//                         ),
//                         if (p.username != null)
//                           Text('@${p.username}',
//                               style: theme.textTheme.bodyMedium?.copyWith(
//                                   color: theme.colorScheme.onSurfaceVariant)),
//                         if (p.bio != null && p.bio!.isNotEmpty) ...[
//                           const SizedBox(height: 8),
//                           Text(p.bio!,
//                               style: theme.textTheme.bodyMedium,
//                               textAlign: TextAlign.center),
//                         ],

//                         // Online status
//                         if (!p.isBlockedBy && !p.isBlocked) ...[
//                           const SizedBox(height: 8),
//                           OnlineIndicator(
//                             status:     friends.statusOf(p.userId),
//                             showLabel:  true,
//                           ),
//                         ],
//                       ],
//                     ),
//                   ).animate().fadeIn().slideY(begin: -0.05, end: 0),

//                   // ── Stats ──────────────────────────────────────────────
//                   Padding(
//                     padding: const EdgeInsets.symmetric(
//                         vertical: 16, horizontal: 24),
//                     child: Row(
//                       children: [
//                         _StatCell(label: 'Friends',
//                             value: '${p.friendsCount}'),
//                         _Divider(),
//                         _StatCell(label: 'Followers',
//                             value: '${p.followersCount}'),
//                         _Divider(),
//                         _StatCell(label: 'Following',
//                             value: '${p.followingCount}'),
//                       ],
//                     ),
//                   ).animate(delay: 80.ms).fadeIn(),

//                   // ── Blocked notice ─────────────────────────────────────
//                   if (p.isBlocked || p.isBlockedBy)
//                     Padding(
//                       padding: const EdgeInsets.all(20),
//                       child: Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: AppColors.errorRed.withOpacity(0.07),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.block_rounded,
//                                 color: AppColors.errorRed),
//                             const SizedBox(width: 10),
//                             Text(
//                               p.isBlocked
//                                   ? 'You have blocked this user.'
//                                   : 'You cannot interact with this user.',
//                               style: const TextStyle(
//                                   color: AppColors.errorRed),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),

//                   // ── Actions ────────────────────────────────────────────
//                   if (p.canInteract)
//                     Padding(
//                       padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//                       child: Column(
//                         children: [
//                           // Friendship action
//                           _FriendshipAction(
//                               profile: p, friends: friends, onAct: _act),
//                           const SizedBox(height: 10),
//                           // Follow action
//                           _FollowAction(
//                               profile: p, friends: friends, onAct: _act),
//                           // Unblock action
//                           if (p.isBlocked) ...[
//                             const SizedBox(height: 10),
//                             OutlinedButton(
//                               onPressed: () =>
//                                   _act(() => friends.unblockUser(p.userId)),
//                               style: OutlinedButton.styleFrom(
//                                 minimumSize: const Size(double.infinity, 44),
//                               ),
//                               child: const Text('Unblock'),
//                             ),
//                           ],
//                         ],
//                       ).animate(delay: 120.ms).fadeIn(),
//                     ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

// class _StatCell extends StatelessWidget {
//   const _StatCell({required this.label, required this.value});
//   final String label;
//   final String value;

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Column(
//         children: [
//           Text(value,
//               style: context.textTheme.titleLarge?.copyWith(
//                   fontWeight: FontWeight.w800)),
//           Text(label,
//               style: context.textTheme.bodySmall?.copyWith(
//                   color: context.colorScheme.onSurfaceVariant)),
//         ],
//       ),
//     );
//   }
// }

// class _Divider extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 1, height: 32,
//       color: context.colorScheme.outlineVariant,
//     );
//   }
// }

// class _FriendshipAction extends StatelessWidget {
//   const _FriendshipAction({
//     required this.profile,
//     required this.friends,
//     required this.onAct,
//   });
//   final SocialProfile  profile;
//   final FriendsProvider friends;
//   final Future<void> Function(Future<void> Function()) onAct;

//   @override
//   Widget build(BuildContext context) {
//     final status = profile.friendshipStatus;
//     final isSentRequest = friends.sentRequests
//         .any((r) => r.userId == profile.userId);

//     if (status == FriendshipStatus.accepted) {
//       return OutlinedButton.icon(
//         onPressed: () =>
//             onAct(() => friends.removeFriend(profile.userId)),
//         icon:  const Icon(Icons.person_remove_outlined),
//         label: const Text('Remove friend'),
//         style: OutlinedButton.styleFrom(
//             minimumSize: const Size(double.infinity, 44)),
//       );
//     }

//     if (status == FriendshipStatus.pending || isSentRequest) {
//       return OutlinedButton.icon(
//         onPressed: () =>
//             onAct(() => friends.cancelRequest(profile.userId)),
//         icon:  const Icon(Icons.cancel_outlined),
//         label: const Text('Cancel request'),
//         style: OutlinedButton.styleFrom(
//             minimumSize: const Size(double.infinity, 44)),
//       );
//     }

//     return JButton(
//       label:     'Add friend',
//       onPressed: () =>
//           onAct(() => friends.sendFriendRequest(profile.userId).then((_) {})),
//       icon:      Icons.person_add_outlined,
//     );
//   }
// }

// class _FollowAction extends StatelessWidget {
//   const _FollowAction({
//     required this.profile,
//     required this.friends,
//     required this.onAct,
//   });
//   final SocialProfile  profile;
//   final FriendsProvider friends;
//   final Future<void> Function(Future<void> Function()) onAct;

//   @override
//   Widget build(BuildContext context) {
//     if (profile.isFollowing) {
//       return OutlinedButton.icon(
//         onPressed: () =>
//             onAct(() => friends.unfollowUser(profile.userId).then((_) {})),
//         icon:  const Icon(Icons.remove_circle_outline_rounded),
//         label: const Text('Unfollow'),
//         style: OutlinedButton.styleFrom(
//             minimumSize: const Size(double.infinity, 44)),
//       );
//     }

//     return FilledButton.tonal(
//       onPressed: () =>
//           onAct(() => friends.followUser(profile.userId).then((_) {})),
//       style: FilledButton.styleFrom(
//           minimumSize: const Size(double.infinity, 44)),
//       child: const Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.add_rounded),
//           SizedBox(width: 6),
//           Text('Follow'),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../data/friends_repository.dart';
import '../../presentation/friends_provider.dart';
import '../widgets/online_indicator.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  SocialProfile? _profile;
  bool _isLoading = true;
  bool _isActing = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _profile = await context.read<FriendsProvider>().getSocialProfile(
        widget.userId,
      );
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e;
          _isLoading = false;
        });
    }
  }

  Future<void> _act(Future<void> Function() fn) async {
    setState(() => _isActing = true);
    await fn();
    await _load();
    setState(() => _isActing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: 'Profile not found.', onRetry: _load),
      );
    }

    final p = _profile!;
    final friends = context.watch<FriendsProvider>();
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.displayName),
        actions: [
          if (!p.isBlocked && !p.isBlockedBy)
            PopupMenuButton<String>(
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block_rounded, color: AppColors.errorRed),
                      const SizedBox(width: 8),
                      Text(
                        'Block',
                        style: TextStyle(color: AppColors.errorRed),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (v) {
                if (v == 'block') {
                  _act(() => friends.blockUser(p.userId));
                }
              },
            ),
        ],
      ),
      body: _isActing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    color: theme.colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        UserAvatar(
                          avatarUrl: p.avatarUrl,
                          displayName: p.displayName,
                          size: 80,
                          showOnlineStatus: !p.isBlockedBy && !p.isBlocked,
                          isOnline: friends.isOnline(p.userId),
                        ).animate().scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                          duration: 300.ms,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              p.displayName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (p.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                size: 20,
                                color: AppColors.infoBlue,
                              ),
                            ],
                          ],
                        ),
                        if (p.username != null)
                          Text(
                            '@${p.username}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (p.bio != null && p.bio!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            p.bio!,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],

                        // Online status
                        if (!p.isBlockedBy && !p.isBlocked) ...[
                          const SizedBox(height: 8),
                          OnlineIndicator(
                            status: friends.statusOf(p.userId),
                            showLabel: true,
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.05, end: 0),

                  // ── Stats ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    child: Row(
                      children: [
                        _StatCell(
                          label: context.l10n.profileFriends,
                          value: '${p.friendsCount}',
                        ),
                        _Divider(),
                        _StatCell(
                          label: context.l10n.profileFollowers,
                          value: '${p.followersCount}',
                        ),
                        _Divider(),
                        _StatCell(
                          label: context.l10n.profileGames,
                          value: '${p.gamesPlayed}',
                        ),
                        _Divider(),
                        _StatCell(
                          label: context.l10n.profilePacks,
                          value: '${p.packsCount}',
                        ),
                      ],
                    ),
                  ).animate(delay: 80.ms).fadeIn(),

                  // ── Blocked notice ─────────────────────────────────────
                  if (p.isBlocked || p.isBlockedBy)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.block_rounded,
                              color: AppColors.errorRed,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              p.isBlocked
                                  ? 'You have blocked this user.'
                                  : 'You cannot interact with this user.',
                              style: const TextStyle(color: AppColors.errorRed),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Actions ────────────────────────────────────────────
                  if (p.canInteract)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        children: [
                          // Friendship action
                          _FriendshipAction(
                            profile: p,
                            friends: friends,
                            onAct: _act,
                          ),
                          const SizedBox(height: 10),
                          // Follow action
                          _FollowAction(
                            profile: p,
                            friends: friends,
                            onAct: _act,
                          ),
                          // Unblock action
                          if (p.isBlocked) ...[
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () =>
                                  _act(() => friends.unblockUser(p.userId)),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 44),
                              ),
                              child: const Text('Unblock'),
                            ),
                          ],
                        ],
                      ).animate(delay: 120.ms).fadeIn(),
                    ),
                ],
              ),
            ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: context.colorScheme.outlineVariant,
    );
  }
}

class _FriendshipAction extends StatelessWidget {
  const _FriendshipAction({
    required this.profile,
    required this.friends,
    required this.onAct,
  });
  final SocialProfile profile;
  final FriendsProvider friends;
  final Future<void> Function(Future<void> Function()) onAct;

  @override
  Widget build(BuildContext context) {
    final status = profile.friendshipStatus;
    final isSentRequest = friends.sentRequests.any(
      (r) => r.userId == profile.userId,
    );

    if (status == FriendshipStatus.accepted) {
      return OutlinedButton.icon(
        onPressed: () => onAct(() => friends.removeFriend(profile.userId)),
        icon: const Icon(Icons.person_remove_outlined),
        label: const Text('Remove friend'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
        ),
      );
    }

    if (status == FriendshipStatus.pending || isSentRequest) {
      return OutlinedButton.icon(
        onPressed: () => onAct(() => friends.cancelRequest(profile.userId)),
        icon: const Icon(Icons.cancel_outlined),
        label: const Text('Cancel request'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
        ),
      );
    }

    return JButton(
      label: 'Add friend',
      onPressed: () =>
          onAct(() => friends.sendFriendRequest(profile.userId).then((_) {})),
      icon: Icons.person_add_outlined,
    );
  }
}

class _FollowAction extends StatelessWidget {
  const _FollowAction({
    required this.profile,
    required this.friends,
    required this.onAct,
  });
  final SocialProfile profile;
  final FriendsProvider friends;
  final Future<void> Function(Future<void> Function()) onAct;

  @override
  Widget build(BuildContext context) {
    if (profile.isFollowing) {
      return OutlinedButton.icon(
        onPressed: () =>
            onAct(() => friends.unfollowUser(profile.userId).then((_) {})),
        icon: const Icon(Icons.remove_circle_outline_rounded),
        label: const Text('Unfollow'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
        ),
      );
    }

    return FilledButton.tonal(
      onPressed: () =>
          onAct(() => friends.followUser(profile.userId).then((_) {})),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(Icons.add_rounded), SizedBox(width: 6), Text('Follow')],
      ),
    );
  }
}
