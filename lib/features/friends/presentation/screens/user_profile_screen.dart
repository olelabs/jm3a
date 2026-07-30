// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // import 'package:go_router/go_router.dart';
// // // // import 'package:provider/provider.dart';

// // // // import '../../../../core/extensions/context_ext.dart';
// // // // import '../../../../core/theme/app_colors.dart';
// // // // import '../../../../shared/widgets/buttons/j_button.dart';
// // // // import '../../../../shared/widgets/cards/user_avatar.dart';
// // // // import '../../../../shared/widgets/feedback/error_view.dart';
// // // // import '../../data/friends_repository.dart';
// // // // import '../../presentation/friends_provider.dart';
// // // // import '../widgets/online_indicator.dart';

// // // // class UserProfileScreen extends StatefulWidget {
// // // //   const UserProfileScreen({super.key, required this.userId});
// // // //   final String userId;

// // // //   @override
// // // //   State<UserProfileScreen> createState() => _UserProfileScreenState();
// // // // }

// // // // class _UserProfileScreenState extends State<UserProfileScreen> {
// // // //   SocialProfile? _profile;
// // // //   bool _isLoading = true;
// // // //   bool _isActing  = false;
// // // //   Object? _error;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _load();
// // // //   }

// // // //   Future<void> _load() async {
// // // //     setState(() { _isLoading = true; _error = null; });
// // // //     try {
// // // //       _profile = await context.read<FriendsProvider>()
// // // //           .getSocialProfile(widget.userId);
// // // //       if (mounted) setState(() => _isLoading = false);
// // // //     } catch (e) {
// // // //       if (mounted) setState(() { _error = e; _isLoading = false; });
// // // //     }
// // // //   }

// // // //   Future<void> _act(Future<void> Function() fn) async {
// // // //     setState(() => _isActing = true);
// // // //     await fn();
// // // //     await _load();
// // // //     setState(() => _isActing = false);
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     if (_isLoading) {
// // // //       return const Scaffold(body: Center(child: CircularProgressIndicator()));
// // // //     }
// // // //     if (_error != null || _profile == null) {
// // // //       return Scaffold(
// // // //         appBar: AppBar(),
// // // //         body: ErrorView(message: 'Profile not found.', onRetry: _load),
// // // //       );
// // // //     }

// // // //     final p       = _profile!;
// // // //     final friends = context.watch<FriendsProvider>();
// // // //     final theme   = context.theme;

// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: Text(p.displayName),
// // // //         actions: [
// // // //           if (!p.isBlocked && !p.isBlockedBy)
// // // //             PopupMenuButton<String>(
// // // //               itemBuilder: (_) => [
// // // //                 PopupMenuItem(
// // // //                   value: 'block',
// // // //                   child: Row(
// // // //                     children: [
// // // //                       Icon(Icons.block_rounded, color: AppColors.errorRed),
// // // //                       const SizedBox(width: 8),
// // // //                       Text('Block',
// // // //                           style: TextStyle(color: AppColors.errorRed)),
// // // //                     ],
// // // //                   ),
// // // //                 ),
// // // //               ],
// // // //               onSelected: (v) {
// // // //                 if (v == 'block') {
// // // //                   _act(() => friends.blockUser(p.userId));
// // // //                 }
// // // //               },
// // // //             ),
// // // //         ],
// // // //       ),
// // // //       body: _isActing
// // // //           ? const Center(child: CircularProgressIndicator())
// // // //           : SingleChildScrollView(
// // // //               child: Column(
// // // //                 children: [
// // // //                   // ── Header ─────────────────────────────────────────────
// // // //                   Container(
// // // //                     width: double.infinity,
// // // //                     color: theme.colorScheme.surfaceContainerHighest,
// // // //                     padding: const EdgeInsets.all(24),
// // // //                     child: Column(
// // // //                       children: [
// // // //                         UserAvatar(
// // // //                           avatarUrl:   p.avatarUrl,
// // // //                           displayName: p.displayName,
// // // //                           size:        80,
// // // //                           showOnlineStatus: !p.isBlockedBy && !p.isBlocked,
// // // //                           isOnline: friends.isOnline(p.userId),
// // // //                         ).animate().scale(
// // // //                               begin: const Offset(0.8, 0.8),
// // // //                               end: const Offset(1, 1),
// // // //                               duration: 300.ms),
// // // //                         const SizedBox(height: 12),
// // // //                         Row(
// // // //                           mainAxisAlignment: MainAxisAlignment.center,
// // // //                           children: [
// // // //                             Text(p.displayName,
// // // //                                 style: theme.textTheme.headlineSmall?.copyWith(
// // // //                                     fontWeight: FontWeight.w800)),
// // // //                             if (p.isVerified) ...[
// // // //                               const SizedBox(width: 4),
// // // //                               const Icon(Icons.verified_rounded,
// // // //                                   size: 20, color: AppColors.infoBlue),
// // // //                             ],
// // // //                           ],
// // // //                         ),
// // // //                         if (p.username != null)
// // // //                           Text('@${p.username}',
// // // //                               style: theme.textTheme.bodyMedium?.copyWith(
// // // //                                   color: theme.colorScheme.onSurfaceVariant)),
// // // //                         if (p.bio != null && p.bio!.isNotEmpty) ...[
// // // //                           const SizedBox(height: 8),
// // // //                           Text(p.bio!,
// // // //                               style: theme.textTheme.bodyMedium,
// // // //                               textAlign: TextAlign.center),
// // // //                         ],

// // // //                         // Online status
// // // //                         if (!p.isBlockedBy && !p.isBlocked) ...[
// // // //                           const SizedBox(height: 8),
// // // //                           OnlineIndicator(
// // // //                             status:     friends.statusOf(p.userId),
// // // //                             showLabel:  true,
// // // //                           ),
// // // //                         ],
// // // //                       ],
// // // //                     ),
// // // //                   ).animate().fadeIn().slideY(begin: -0.05, end: 0),

// // // //                   // ── Stats ──────────────────────────────────────────────
// // // //                   Padding(
// // // //                     padding: const EdgeInsets.symmetric(
// // // //                         vertical: 16, horizontal: 24),
// // // //                     child: Row(
// // // //                       children: [
// // // //                         _StatCell(label: 'Friends',
// // // //                             value: '${p.friendsCount}'),
// // // //                         _Divider(),
// // // //                         _StatCell(label: 'Followers',
// // // //                             value: '${p.followersCount}'),
// // // //                         _Divider(),
// // // //                         _StatCell(label: 'Following',
// // // //                             value: '${p.followingCount}'),
// // // //                       ],
// // // //                     ),
// // // //                   ).animate(delay: 80.ms).fadeIn(),

// // // //                   // ── Blocked notice ─────────────────────────────────────
// // // //                   if (p.isBlocked || p.isBlockedBy)
// // // //                     Padding(
// // // //                       padding: const EdgeInsets.all(20),
// // // //                       child: Container(
// // // //                         padding: const EdgeInsets.all(16),
// // // //                         decoration: BoxDecoration(
// // // //                           color: AppColors.errorRed.withOpacity(0.07),
// // // //                           borderRadius: BorderRadius.circular(12),
// // // //                         ),
// // // //                         child: Row(
// // // //                           children: [
// // // //                             const Icon(Icons.block_rounded,
// // // //                                 color: AppColors.errorRed),
// // // //                             const SizedBox(width: 10),
// // // //                             Text(
// // // //                               p.isBlocked
// // // //                                   ? 'You have blocked this user.'
// // // //                                   : 'You cannot interact with this user.',
// // // //                               style: const TextStyle(
// // // //                                   color: AppColors.errorRed),
// // // //                             ),
// // // //                           ],
// // // //                         ),
// // // //                       ),
// // // //                     ),

// // // //                   // ── Actions ────────────────────────────────────────────
// // // //                   if (p.canInteract)
// // // //                     Padding(
// // // //                       padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
// // // //                       child: Column(
// // // //                         children: [
// // // //                           // Friendship action
// // // //                           _FriendshipAction(
// // // //                               profile: p, friends: friends, onAct: _act),
// // // //                           const SizedBox(height: 10),
// // // //                           // Follow action
// // // //                           _FollowAction(
// // // //                               profile: p, friends: friends, onAct: _act),
// // // //                           // Unblock action
// // // //                           if (p.isBlocked) ...[
// // // //                             const SizedBox(height: 10),
// // // //                             OutlinedButton(
// // // //                               onPressed: () =>
// // // //                                   _act(() => friends.unblockUser(p.userId)),
// // // //                               style: OutlinedButton.styleFrom(
// // // //                                 minimumSize: const Size(double.infinity, 44),
// // // //                               ),
// // // //                               child: const Text('Unblock'),
// // // //                             ),
// // // //                           ],
// // // //                         ],
// // // //                       ).animate(delay: 120.ms).fadeIn(),
// // // //                     ),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //     );
// // // //   }
// // // // }

// // // // class _StatCell extends StatelessWidget {
// // // //   const _StatCell({required this.label, required this.value});
// // // //   final String label;
// // // //   final String value;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Expanded(
// // // //       child: Column(
// // // //         children: [
// // // //           Text(value,
// // // //               style: context.textTheme.titleLarge?.copyWith(
// // // //                   fontWeight: FontWeight.w800)),
// // // //           Text(label,
// // // //               style: context.textTheme.bodySmall?.copyWith(
// // // //                   color: context.colorScheme.onSurfaceVariant)),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _Divider extends StatelessWidget {
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Container(
// // // //       width: 1, height: 32,
// // // //       color: context.colorScheme.outlineVariant,
// // // //     );
// // // //   }
// // // // }

// // // // class _FriendshipAction extends StatelessWidget {
// // // //   const _FriendshipAction({
// // // //     required this.profile,
// // // //     required this.friends,
// // // //     required this.onAct,
// // // //   });
// // // //   final SocialProfile  profile;
// // // //   final FriendsProvider friends;
// // // //   final Future<void> Function(Future<void> Function()) onAct;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final status = profile.friendshipStatus;
// // // //     final isSentRequest = friends.sentRequests
// // // //         .any((r) => r.userId == profile.userId);

// // // //     if (status == FriendshipStatus.accepted) {
// // // //       return OutlinedButton.icon(
// // // //         onPressed: () =>
// // // //             onAct(() => friends.removeFriend(profile.userId)),
// // // //         icon:  const Icon(Icons.person_remove_outlined),
// // // //         label: const Text('Remove friend'),
// // // //         style: OutlinedButton.styleFrom(
// // // //             minimumSize: const Size(double.infinity, 44)),
// // // //       );
// // // //     }

// // // //     if (status == FriendshipStatus.pending || isSentRequest) {
// // // //       return OutlinedButton.icon(
// // // //         onPressed: () =>
// // // //             onAct(() => friends.cancelRequest(profile.userId)),
// // // //         icon:  const Icon(Icons.cancel_outlined),
// // // //         label: const Text('Cancel request'),
// // // //         style: OutlinedButton.styleFrom(
// // // //             minimumSize: const Size(double.infinity, 44)),
// // // //       );
// // // //     }

// // // //     return JButton(
// // // //       label:     'Add friend',
// // // //       onPressed: () =>
// // // //           onAct(() => friends.sendFriendRequest(profile.userId).then((_) {})),
// // // //       icon:      Icons.person_add_outlined,
// // // //     );
// // // //   }
// // // // }

// // // // class _FollowAction extends StatelessWidget {
// // // //   const _FollowAction({
// // // //     required this.profile,
// // // //     required this.friends,
// // // //     required this.onAct,
// // // //   });
// // // //   final SocialProfile  profile;
// // // //   final FriendsProvider friends;
// // // //   final Future<void> Function(Future<void> Function()) onAct;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     if (profile.isFollowing) {
// // // //       return OutlinedButton.icon(
// // // //         onPressed: () =>
// // // //             onAct(() => friends.unfollowUser(profile.userId).then((_) {})),
// // // //         icon:  const Icon(Icons.remove_circle_outline_rounded),
// // // //         label: const Text('Unfollow'),
// // // //         style: OutlinedButton.styleFrom(
// // // //             minimumSize: const Size(double.infinity, 44)),
// // // //       );
// // // //     }

// // // //     return FilledButton.tonal(
// // // //       onPressed: () =>
// // // //           onAct(() => friends.followUser(profile.userId).then((_) {})),
// // // //       style: FilledButton.styleFrom(
// // // //           minimumSize: const Size(double.infinity, 44)),
// // // //       child: const Row(
// // // //         mainAxisAlignment: MainAxisAlignment.center,
// // // //         children: [
// // // //           Icon(Icons.add_rounded),
// // // //           SizedBox(width: 6),
// // // //           Text('Follow'),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_animate/flutter_animate.dart';
// // // import 'package:go_router/go_router.dart';
// // // import 'package:provider/provider.dart';

// // // import '../../../../core/extensions/context_ext.dart';
// // // import '../../../../core/theme/app_colors.dart';
// // // import '../../../../shared/widgets/buttons/j_button.dart';
// // // import '../../../../shared/widgets/cards/user_avatar.dart';
// // // import '../../../../shared/widgets/feedback/error_view.dart';
// // // import '../../data/friends_repository.dart';
// // // import '../../presentation/friends_provider.dart';
// // // import '../widgets/online_indicator.dart';

// // // class UserProfileScreen extends StatefulWidget {
// // //   const UserProfileScreen({super.key, required this.userId});
// // //   final String userId;

// // //   @override
// // //   State<UserProfileScreen> createState() => _UserProfileScreenState();
// // // }

// // // class _UserProfileScreenState extends State<UserProfileScreen> {
// // //   SocialProfile? _profile;
// // //   bool _isLoading = true;
// // //   bool _isActing = false;
// // //   Object? _error;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _load();
// // //   }

// // //   Future<void> _load() async {
// // //     setState(() {
// // //       _isLoading = true;
// // //       _error = null;
// // //     });
// // //     try {
// // //       _profile = await context.read<FriendsProvider>().getSocialProfile(
// // //         widget.userId,
// // //       );
// // //       if (mounted) setState(() => _isLoading = false);
// // //     } catch (e) {
// // //       if (mounted)
// // //         setState(() {
// // //           _error = e;
// // //           _isLoading = false;
// // //         });
// // //     }
// // //   }

// // //   Future<void> _act(Future<void> Function() fn) async {
// // //     setState(() => _isActing = true);
// // //     await fn();
// // //     await _load();
// // //     setState(() => _isActing = false);
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     if (_isLoading) {
// // //       return const Scaffold(body: Center(child: CircularProgressIndicator()));
// // //     }
// // //     if (_error != null || _profile == null) {
// // //       return Scaffold(
// // //         appBar: AppBar(),
// // //         body: ErrorView(message: 'Profile not found.', onRetry: _load),
// // //       );
// // //     }

// // //     final p = _profile!;
// // //     final friends = context.watch<FriendsProvider>();
// // //     final theme = context.theme;

// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: Text(p.displayName),
// // //         actions: [
// // //           if (!p.isBlocked && !p.isBlockedBy)
// // //             PopupMenuButton<String>(
// // //               itemBuilder: (_) => [
// // //                 PopupMenuItem(
// // //                   value: 'block',
// // //                   child: Row(
// // //                     children: [
// // //                       Icon(Icons.block_rounded, color: AppColors.errorRed),
// // //                       const SizedBox(width: 8),
// // //                       Text(
// // //                         'Block',
// // //                         style: TextStyle(color: AppColors.errorRed),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ],
// // //               onSelected: (v) {
// // //                 if (v == 'block') {
// // //                   _act(() => friends.blockUser(p.userId));
// // //                 }
// // //               },
// // //             ),
// // //         ],
// // //       ),
// // //       body: _isActing
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : SingleChildScrollView(
// // //               child: Column(
// // //                 children: [
// // //                   // ── Header ─────────────────────────────────────────────
// // //                   Container(
// // //                     width: double.infinity,
// // //                     color: theme.colorScheme.surfaceContainerHighest,
// // //                     padding: const EdgeInsets.all(24),
// // //                     child: Column(
// // //                       children: [
// // //                         UserAvatar(
// // //                           avatarUrl: p.avatarUrl,
// // //                           displayName: p.displayName,
// // //                           size: 80,
// // //                           showOnlineStatus: !p.isBlockedBy && !p.isBlocked,
// // //                           isOnline: friends.isOnline(p.userId),
// // //                         ).animate().scale(
// // //                           begin: const Offset(0.8, 0.8),
// // //                           end: const Offset(1, 1),
// // //                           duration: 300.ms,
// // //                         ),
// // //                         const SizedBox(height: 12),
// // //                         Row(
// // //                           mainAxisAlignment: MainAxisAlignment.center,
// // //                           children: [
// // //                             Text(
// // //                               p.displayName,
// // //                               style: theme.textTheme.headlineSmall?.copyWith(
// // //                                 fontWeight: FontWeight.w800,
// // //                               ),
// // //                             ),
// // //                             if (p.isVerified) ...[
// // //                               const SizedBox(width: 4),
// // //                               const Icon(
// // //                                 Icons.verified_rounded,
// // //                                 size: 20,
// // //                                 color: AppColors.infoBlue,
// // //                               ),
// // //                             ],
// // //                           ],
// // //                         ),
// // //                         if (p.username != null)
// // //                           Text(
// // //                             '@${p.username}',
// // //                             style: theme.textTheme.bodyMedium?.copyWith(
// // //                               color: theme.colorScheme.onSurfaceVariant,
// // //                             ),
// // //                           ),
// // //                         if (p.bio != null && p.bio!.isNotEmpty) ...[
// // //                           const SizedBox(height: 8),
// // //                           Text(
// // //                             p.bio!,
// // //                             style: theme.textTheme.bodyMedium,
// // //                             textAlign: TextAlign.center,
// // //                           ),
// // //                         ],

// // //                         // Online status
// // //                         if (!p.isBlockedBy && !p.isBlocked) ...[
// // //                           const SizedBox(height: 8),
// // //                           OnlineIndicator(
// // //                             status: friends.statusOf(p.userId),
// // //                             showLabel: true,
// // //                           ),
// // //                         ],
// // //                       ],
// // //                     ),
// // //                   ).animate().fadeIn().slideY(begin: -0.05, end: 0),

// // //                   // ── Stats ──────────────────────────────────────────────
// // //                   Padding(
// // //                     padding: const EdgeInsets.symmetric(
// // //                       vertical: 16,
// // //                       horizontal: 24,
// // //                     ),
// // //                     child: Row(
// // //                       children: [
// // //                         _StatCell(
// // //                           label: context.l10n.profileFriends,
// // //                           value: '${p.friendsCount}',
// // //                         ),
// // //                         _Divider(),
// // //                         _StatCell(
// // //                           label: context.l10n.profileFollowers,
// // //                           value: '${p.followersCount}',
// // //                         ),
// // //                         _Divider(),
// // //                         _StatCell(
// // //                           label: context.l10n.profileGames,
// // //                           value: '${p.gamesPlayed}',
// // //                         ),
// // //                         _Divider(),
// // //                         _StatCell(
// // //                           label: context.l10n.profilePacks,
// // //                           value: '${p.packsCount}',
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ).animate(delay: 80.ms).fadeIn(),

// // //                   // ── Blocked notice ─────────────────────────────────────
// // //                   if (p.isBlocked || p.isBlockedBy)
// // //                     Padding(
// // //                       padding: const EdgeInsets.all(20),
// // //                       child: Container(
// // //                         padding: const EdgeInsets.all(16),
// // //                         decoration: BoxDecoration(
// // //                           color: AppColors.errorRed.withOpacity(0.07),
// // //                           borderRadius: BorderRadius.circular(12),
// // //                         ),
// // //                         child: Row(
// // //                           children: [
// // //                             const Icon(
// // //                               Icons.block_rounded,
// // //                               color: AppColors.errorRed,
// // //                             ),
// // //                             const SizedBox(width: 10),
// // //                             Text(
// // //                               p.isBlocked
// // //                                   ? 'You have blocked this user.'
// // //                                   : 'You cannot interact with this user.',
// // //                               style: const TextStyle(color: AppColors.errorRed),
// // //                             ),
// // //                           ],
// // //                         ),
// // //                       ),
// // //                     ),

// // //                   // ── Actions ────────────────────────────────────────────
// // //                   if (p.canInteract)
// // //                     Padding(
// // //                       padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
// // //                       child: Column(
// // //                         children: [
// // //                           // Friendship action
// // //                           _FriendshipAction(
// // //                             profile: p,
// // //                             friends: friends,
// // //                             onAct: _act,
// // //                           ),
// // //                           const SizedBox(height: 10),
// // //                           // Follow action
// // //                           _FollowAction(
// // //                             profile: p,
// // //                             friends: friends,
// // //                             onAct: _act,
// // //                           ),
// // //                           // Unblock action
// // //                           if (p.isBlocked) ...[
// // //                             const SizedBox(height: 10),
// // //                             OutlinedButton(
// // //                               onPressed: () =>
// // //                                   _act(() => friends.unblockUser(p.userId)),
// // //                               style: OutlinedButton.styleFrom(
// // //                                 minimumSize: const Size(double.infinity, 44),
// // //                               ),
// // //                               child: const Text('Unblock'),
// // //                             ),
// // //                           ],
// // //                         ],
// // //                       ).animate(delay: 120.ms).fadeIn(),
// // //                     ),
// // //                 ],
// // //               ),
// // //             ),
// // //     );
// // //   }
// // // }

// // // class _StatCell extends StatelessWidget {
// // //   const _StatCell({required this.label, required this.value});
// // //   final String label;
// // //   final String value;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Expanded(
// // //       child: Column(
// // //         children: [
// // //           Text(
// // //             value,
// // //             style: context.textTheme.titleLarge?.copyWith(
// // //               fontWeight: FontWeight.w800,
// // //             ),
// // //           ),
// // //           Text(
// // //             label,
// // //             style: context.textTheme.bodySmall?.copyWith(
// // //               color: context.colorScheme.onSurfaceVariant,
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _Divider extends StatelessWidget {
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       width: 1,
// // //       height: 32,
// // //       color: context.colorScheme.outlineVariant,
// // //     );
// // //   }
// // // }

// // // class _FriendshipAction extends StatelessWidget {
// // //   const _FriendshipAction({
// // //     required this.profile,
// // //     required this.friends,
// // //     required this.onAct,
// // //   });
// // //   final SocialProfile profile;
// // //   final FriendsProvider friends;
// // //   final Future<void> Function(Future<void> Function()) onAct;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final status = profile.friendshipStatus;
// // //     final isSentRequest = friends.sentRequests.any(
// // //       (r) => r.userId == profile.userId,
// // //     );

// // //     if (status == FriendshipStatus.accepted) {
// // //       return OutlinedButton.icon(
// // //         onPressed: () => onAct(() => friends.removeFriend(profile.userId)),
// // //         icon: const Icon(Icons.person_remove_outlined),
// // //         label: const Text('Remove friend'),
// // //         style: OutlinedButton.styleFrom(
// // //           minimumSize: const Size(double.infinity, 44),
// // //         ),
// // //       );
// // //     }

// // //     if (status == FriendshipStatus.pending || isSentRequest) {
// // //       return OutlinedButton.icon(
// // //         onPressed: () => onAct(() => friends.cancelRequest(profile.userId)),
// // //         icon: const Icon(Icons.cancel_outlined),
// // //         label: const Text('Cancel request'),
// // //         style: OutlinedButton.styleFrom(
// // //           minimumSize: const Size(double.infinity, 44),
// // //         ),
// // //       );
// // //     }

// // //     return JButton(
// // //       label: 'Add friend',
// // //       onPressed: () =>
// // //           onAct(() => friends.sendFriendRequest(profile.userId).then((_) {})),
// // //       icon: Icons.person_add_outlined,
// // //     );
// // //   }
// // // }

// // // class _FollowAction extends StatelessWidget {
// // //   const _FollowAction({
// // //     required this.profile,
// // //     required this.friends,
// // //     required this.onAct,
// // //   });
// // //   final SocialProfile profile;
// // //   final FriendsProvider friends;
// // //   final Future<void> Function(Future<void> Function()) onAct;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     if (profile.isFollowing) {
// // //       return OutlinedButton.icon(
// // //         onPressed: () =>
// // //             onAct(() => friends.unfollowUser(profile.userId).then((_) {})),
// // //         icon: const Icon(Icons.remove_circle_outline_rounded),
// // //         label: const Text('Unfollow'),
// // //         style: OutlinedButton.styleFrom(
// // //           minimumSize: const Size(double.infinity, 44),
// // //         ),
// // //       );
// // //     }

// // //     return FilledButton.tonal(
// // //       onPressed: () =>
// // //           onAct(() => friends.followUser(profile.userId).then((_) {})),
// // //       style: FilledButton.styleFrom(
// // //         minimumSize: const Size(double.infinity, 44),
// // //       ),
// // //       child: const Row(
// // //         mainAxisAlignment: MainAxisAlignment.center,
// // //         children: [Icon(Icons.add_rounded), SizedBox(width: 6), Text('Follow')],
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:provider/provider.dart';

// // import '../../../../core/extensions/context_ext.dart';
// // import '../../../../core/theme/app_colors.dart';
// // import '../../../../shared/widgets/buttons/j_button.dart';
// // import '../../../../shared/widgets/cards/user_avatar.dart';
// // import '../../../../shared/widgets/feedback/error_view.dart';
// // import '../../data/friends_repository.dart';
// // import '../../presentation/friends_provider.dart';
// // import '../widgets/online_indicator.dart';

// // class UserProfileScreen extends StatefulWidget {
// //   const UserProfileScreen({super.key, required this.userId});
// //   final String userId;

// //   @override
// //   State<UserProfileScreen> createState() => _UserProfileScreenState();
// // }

// // class _UserProfileScreenState extends State<UserProfileScreen> {
// //   SocialProfile? _profile;
// //   bool _isLoading = true;
// //   bool _isActing = false;
// //   Object? _error;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _load();
// //   }

// //   Future<void> _load() async {
// //     setState(() {
// //       _isLoading = true;
// //       _error = null;
// //     });
// //     try {
// //       _profile = await context.read<FriendsProvider>().getSocialProfile(
// //         widget.userId,
// //       );
// //       if (mounted) setState(() => _isLoading = false);
// //     } catch (e) {
// //       if (mounted)
// //         setState(() {
// //           _error = e;
// //           _isLoading = false;
// //         });
// //     }
// //   }

// //   Future<void> _act(Future<void> Function() fn) async {
// //     setState(() => _isActing = true);
// //     await fn();
// //     await _load();
// //     setState(() => _isActing = false);
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (_isLoading) {
// //       return const Scaffold(body: Center(child: CircularProgressIndicator()));
// //     }
// //     if (_error != null || _profile == null) {
// //       return Scaffold(
// //         appBar: AppBar(),
// //         body: ErrorView(message: 'Profile not found.', onRetry: _load),
// //       );
// //     }

// //     final p = _profile!;
// //     final friends = context.watch<FriendsProvider>();
// //     final theme = context.theme;

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(p.displayName),
// //         actions: [
// //           if (!p.isBlocked && !p.isBlockedBy)
// //             PopupMenuButton<String>(
// //               itemBuilder: (_) => [
// //                 PopupMenuItem(
// //                   value: 'block',
// //                   child: Row(
// //                     children: [
// //                       Icon(Icons.block_rounded, color: AppColors.errorRed),
// //                       const SizedBox(width: 8),
// //                       Text(
// //                         'Block',
// //                         style: TextStyle(color: AppColors.errorRed),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //               onSelected: (v) {
// //                 if (v == 'block') {
// //                   _act(() => friends.blockUser(p.userId));
// //                 }
// //               },
// //             ),
// //         ],
// //       ),
// //       body: _isActing
// //           ? const Center(child: CircularProgressIndicator())
// //           : SingleChildScrollView(
// //               child: Column(
// //                 children: [
// //                   Container(
// //                     width: double.infinity,
// //                     color: theme.colorScheme.surfaceContainerHighest,
// //                     padding: const EdgeInsets.all(24),
// //                     child: Column(
// //                       children: [
// //                         UserAvatar(
// //                           avatarUrl: p.avatarUrl,
// //                           avatarConfig: p.avatarConfig,
// //                           isPremium: p.isPremium,
// //                           displayName: p.displayName,
// //                           size: 80,
// //                           showOnlineStatus: !p.isBlockedBy && !p.isBlocked,
// //                           isOnline: friends.isOnline(p.userId),
// //                         ).animate().scale(
// //                           begin: const Offset(0.8, 0.8),
// //                           end: const Offset(1, 1),
// //                           duration: 300.ms,
// //                         ),
// //                         const SizedBox(height: 12),
// //                         Row(
// //                           mainAxisAlignment: MainAxisAlignment.center,
// //                           children: [
// //                             Text(
// //                               p.displayName,
// //                               style: theme.textTheme.headlineSmall?.copyWith(
// //                                 fontWeight: FontWeight.w800,
// //                               ),
// //                             ),
// //                             if (p.isVerified) ...[
// //                               const SizedBox(width: 4),
// //                               const Icon(
// //                                 Icons.verified_rounded,
// //                                 size: 20,
// //                                 color: AppColors.infoBlue,
// //                               ),
// //                             ],
// //                           ],
// //                         ),
// //                         if (p.username != null)
// //                           Text(
// //                             '@${p.username}',
// //                             style: theme.textTheme.bodyMedium?.copyWith(
// //                               color: theme.colorScheme.onSurfaceVariant,
// //                             ),
// //                           ),
// //                         if (p.bio != null && p.bio!.isNotEmpty) ...[
// //                           const SizedBox(height: 8),
// //                           Text(
// //                             p.bio!,
// //                             style: theme.textTheme.bodyMedium,
// //                             textAlign: TextAlign.center,
// //                           ),
// //                         ],

// //                         if (!p.isBlockedBy && !p.isBlocked) ...[
// //                           const SizedBox(height: 8),
// //                           OnlineIndicator(
// //                             status: friends.statusOf(p.userId),
// //                             showLabel: true,
// //                           ),
// //                         ],
// //                       ],
// //                     ),
// //                   ).animate().fadeIn().slideY(begin: -0.05, end: 0),

// //                   Padding(
// //                     padding: const EdgeInsets.symmetric(
// //                       vertical: 16,
// //                       horizontal: 24,
// //                     ),
// //                     child: Row(
// //                       children: [
// //                         _StatCell(
// //                           label: context.l10n.profileFriends,
// //                           value: '${p.friendsCount}',
// //                         ),
// //                         _Divider(),
// //                         _StatCell(
// //                           label: context.l10n.profileFollowers,
// //                           value: '${p.followersCount}',
// //                         ),
// //                         _Divider(),
// //                         _StatCell(
// //                           label: context.l10n.profileGames,
// //                           value: '${p.gamesPlayed}',
// //                         ),
// //                         _Divider(),
// //                         _StatCell(
// //                           label: context.l10n.profilePacks,
// //                           value: '${p.packsCount}',
// //                         ),
// //                       ],
// //                     ),
// //                   ).animate(delay: 80.ms).fadeIn(),

// //                   if (p.isBlocked || p.isBlockedBy)
// //                     Padding(
// //                       padding: const EdgeInsets.all(20),
// //                       child: Container(
// //                         padding: const EdgeInsets.all(16),
// //                         decoration: BoxDecoration(
// //                           color: AppColors.errorRed.withOpacity(0.07),
// //                           borderRadius: BorderRadius.circular(12),
// //                         ),
// //                         child: Row(
// //                           children: [
// //                             const Icon(
// //                               Icons.block_rounded,
// //                               color: AppColors.errorRed,
// //                             ),
// //                             const SizedBox(width: 10),
// //                             Text(
// //                               p.isBlocked
// //                                   ? 'You have blocked this user.'
// //                                   : 'You cannot interact with this user.',
// //                               style: const TextStyle(color: AppColors.errorRed),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),

// //                   if (p.canInteract)
// //                     Padding(
// //                       padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
// //                       child: Column(
// //                         children: [
// //                           _FriendshipAction(
// //                             profile: p,
// //                             friends: friends,
// //                             onAct: _act,
// //                           ),
// //                           const SizedBox(height: 10),
// //                           _FollowAction(
// //                             profile: p,
// //                             friends: friends,
// //                             onAct: _act,
// //                           ),
// //                           if (p.isBlocked) ...[
// //                             const SizedBox(height: 10),
// //                             OutlinedButton(
// //                               onPressed: () =>
// //                                   _act(() => friends.unblockUser(p.userId)),
// //                               style: OutlinedButton.styleFrom(
// //                                 minimumSize: const Size(double.infinity, 44),
// //                               ),
// //                               child: const Text('Unblock'),
// //                             ),
// //                           ],
// //                         ],
// //                       ).animate(delay: 120.ms).fadeIn(),
// //                     ),
// //                 ],
// //               ),
// //             ),
// //     );
// //   }
// // }

// // class _StatCell extends StatelessWidget {
// //   const _StatCell({required this.label, required this.value});
// //   final String label;
// //   final String value;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Expanded(
// //       child: Column(
// //         children: [
// //           Text(
// //             value,
// //             style: context.textTheme.titleLarge?.copyWith(
// //               fontWeight: FontWeight.w800,
// //             ),
// //           ),
// //           Text(
// //             label,
// //             style: context.textTheme.bodySmall?.copyWith(
// //               color: context.colorScheme.onSurfaceVariant,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _Divider extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       width: 1,
// //       height: 32,
// //       color: context.colorScheme.outlineVariant,
// //     );
// //   }
// // }

// // class _FriendshipAction extends StatelessWidget {
// //   const _FriendshipAction({
// //     required this.profile,
// //     required this.friends,
// //     required this.onAct,
// //   });
// //   final SocialProfile profile;
// //   final FriendsProvider friends;
// //   final Future<void> Function(Future<void> Function()) onAct;

// //   @override
// //   Widget build(BuildContext context) {
// //     final status = profile.friendshipStatus;
// //     final isSentRequest = friends.sentRequests.any(
// //       (r) => r.userId == profile.userId,
// //     );

// //     if (status == FriendshipStatus.accepted) {
// //       return OutlinedButton.icon(
// //         onPressed: () => onAct(() => friends.removeFriend(profile.userId)),
// //         icon: const Icon(Icons.person_remove_outlined),
// //         label: const Text('Remove friend'),
// //         style: OutlinedButton.styleFrom(
// //           minimumSize: const Size(double.infinity, 44),
// //         ),
// //       );
// //     }

// //     if (status == FriendshipStatus.pending || isSentRequest) {
// //       return OutlinedButton.icon(
// //         onPressed: () => onAct(() => friends.cancelRequest(profile.userId)),
// //         icon: const Icon(Icons.cancel_outlined),
// //         label: const Text('Cancel request'),
// //         style: OutlinedButton.styleFrom(
// //           minimumSize: const Size(double.infinity, 44),
// //         ),
// //       );
// //     }

// //     return JButton(
// //       label: 'Add friend',
// //       onPressed: () =>
// //           onAct(() => friends.sendFriendRequest(profile.userId).then((_) {})),
// //       icon: Icons.person_add_outlined,
// //     );
// //   }
// // }

// // class _FollowAction extends StatelessWidget {
// //   const _FollowAction({
// //     required this.profile,
// //     required this.friends,
// //     required this.onAct,
// //   });
// //   final SocialProfile profile;
// //   final FriendsProvider friends;
// //   final Future<void> Function(Future<void> Function()) onAct;

// //   @override
// //   Widget build(BuildContext context) {
// //     if (profile.isFollowing) {
// //       return OutlinedButton.icon(
// //         onPressed: () =>
// //             onAct(() => friends.unfollowUser(profile.userId).then((_) {})),
// //         icon: const Icon(Icons.remove_circle_outline_rounded),
// //         label: const Text('Unfollow'),
// //         style: OutlinedButton.styleFrom(
// //           minimumSize: const Size(double.infinity, 44),
// //         ),
// //       );
// //     }

// //     return FilledButton.tonal(
// //       onPressed: () =>
// //           onAct(() => friends.followUser(profile.userId).then((_) {})),
// //       style: FilledButton.styleFrom(
// //         minimumSize: const Size(double.infinity, 44),
// //       ),
// //       child: const Row(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [Icon(Icons.add_rounded), SizedBox(width: 6), Text('Follow')],
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/di/service_locator.dart';
// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/router/route_names.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/buttons/j_button.dart';
// import '../../../../shared/widgets/cards/user_avatar.dart';
// import '../../../../shared/widgets/feedback/error_view.dart';
// import '../../../packs/data/pack_repository.dart';
// import '../../../packs/domain/pack_entity.dart';
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
//   List<PackEntity> _packs = [];
//   bool _isLoading = true;
//   bool _isActing = false;
//   Object? _error;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//     try {
//       final results = await Future.wait([
//         context.read<FriendsProvider>().getSocialProfile(widget.userId),
//         sl.packRepository.getPublicPacksByCreator(widget.userId),
//       ]);
//       if (mounted) {
//         setState(() {
//           _profile = results[0] as SocialProfile;
//           _packs = results[1] as List<PackEntity>;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted)
//         setState(() {
//           _error = e;
//           _isLoading = false;
//         });
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
//     if (_isLoading)
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     if (_error != null || _profile == null) {
//       return Scaffold(
//         appBar: AppBar(),
//         body: ErrorView(message: 'Profile not found.', onRetry: _load),
//       );
//     }

//     final p = _profile!;
//     final friends = context.watch<FriendsProvider>();
//     final theme = context.theme;

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
//                       Text(
//                         'Block',
//                         style: TextStyle(color: AppColors.errorRed),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//               onSelected: (v) {
//                 if (v == 'block') _act(() => friends.blockUser(p.userId));
//               },
//             ),
//         ],
//       ),
//       body: _isActing
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _ProfileHeader(
//                     p: p,
//                     friends: friends,
//                   ).animate().fadeIn().slideY(begin: -0.05, end: 0),
//                   _StatsRow(p: p).animate(delay: 80.ms).fadeIn(),
//                   if (p.isBlocked || p.isBlockedBy) _BlockedBanner(p: p),
//                   if (p.canInteract)
//                     Padding(
//                       padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
//                       child: Column(
//                         children: [
//                           _FriendshipAction(
//                             profile: p,
//                             friends: friends,
//                             onAct: _act,
//                           ),
//                           const SizedBox(height: 10),
//                           _FollowAction(
//                             profile: p,
//                             friends: friends,
//                             onAct: _act,
//                           ),
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
//                   if (!p.isBlocked && !p.isBlockedBy && _packs.isNotEmpty) ...[
//                     _SectionHeader(
//                       title: 'Packs by ${p.displayName}',
//                       emoji: '🎴',
//                     ),
//                     SizedBox(
//                       height: 160,
//                       child: ListView.builder(
//                         scrollDirection: Axis.horizontal,
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         itemCount: _packs.length,
//                         itemBuilder: (_, i) =>
//                             _PackCard(
//                                   pack: _packs[i],
//                                   onTap: () => context.push(
//                                     '${RouteNames.marketplace}/pack/${_packs[i].id}',
//                                   ),
//                                 )
//                                 .animate(delay: (i * 40).ms)
//                                 .fadeIn()
//                                 .slideX(begin: 0.1, end: 0),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                   ],
//                   const SizedBox(height: 24),
//                 ],
//               ),
//             ),
//     );
//   }
// }

// class _ProfileHeader extends StatelessWidget {
//   const _ProfileHeader({required this.p, required this.friends});
//   final SocialProfile p;
//   final FriendsProvider friends;
//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     return Container(
//       width: double.infinity,
//       color: theme.colorScheme.surfaceContainerHighest,
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         children: [
//           UserAvatar(
//             avatarUrl: p.avatarUrl,
//             avatarConfig: p.avatarConfig,
//             isPremium: p.isPremium,
//             displayName: p.displayName,
//             size: 80,
//             showOnlineStatus: !p.isBlockedBy && !p.isBlocked,
//             isOnline: friends.isOnline(p.userId),
//           ).animate().scale(
//             begin: const Offset(0.8, 0.8),
//             end: const Offset(1, 1),
//             duration: 300.ms,
//           ),
//           const SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 p.displayName,
//                 style: theme.textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//               if (p.isPremium) ...[
//                 const SizedBox(width: 6),
//                 const Text(
//                   '✦',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Color(0xFFF5A623),
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//               ],
//               if (p.isVerified) ...[
//                 const SizedBox(width: 4),
//                 const Icon(
//                   Icons.verified_rounded,
//                   size: 20,
//                   color: AppColors.infoBlue,
//                 ),
//               ],
//             ],
//           ),
//           if (p.username != null)
//             Text(
//               '@${p.username}',
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//             ),
//           if (p.bio != null && p.bio!.isNotEmpty) ...[
//             const SizedBox(height: 8),
//             Text(
//               p.bio!,
//               style: theme.textTheme.bodyMedium,
//               textAlign: TextAlign.center,
//             ),
//           ],
//           if (!p.isBlockedBy && !p.isBlocked) ...[
//             const SizedBox(height: 8),
//             OnlineIndicator(
//               status: friends.statusOf(p.userId),
//               showLabel: true,
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class _StatsRow extends StatelessWidget {
//   const _StatsRow({required this.p});
//   final SocialProfile p;
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
//       child: Row(
//         children: [
//           _StatCell(
//             label: context.l10n.profileFriends,
//             value: '${p.friendsCount}',
//           ),
//           _Divider(),
//           _StatCell(
//             label: context.l10n.profileFollowers,
//             value: '${p.followersCount}',
//           ),
//           _Divider(),
//           _StatCell(
//             label: context.l10n.profileGames,
//             value: '${p.gamesPlayed}',
//           ),
//           _Divider(),
//           _StatCell(label: context.l10n.profilePacks, value: '${p.packsCount}'),
//         ],
//       ),
//     );
//   }
// }

// class _BlockedBanner extends StatelessWidget {
//   const _BlockedBanner({required this.p});
//   final SocialProfile p;
//   @override
//   Widget build(BuildContext context) => Padding(
//     padding: const EdgeInsets.all(20),
//     child: Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.errorRed.withOpacity(0.07),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.block_rounded, color: AppColors.errorRed),
//           const SizedBox(width: 10),
//           Text(
//             p.isBlocked
//                 ? 'You have blocked this user.'
//                 : 'You cannot interact with this user.',
//             style: const TextStyle(color: AppColors.errorRed),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// class _SectionHeader extends StatelessWidget {
//   const _SectionHeader({required this.title, required this.emoji});
//   final String title, emoji;
//   @override
//   Widget build(BuildContext context) => Padding(
//     padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
//     child: Row(
//       children: [
//         Text(emoji, style: const TextStyle(fontSize: 18)),
//         const SizedBox(width: 8),
//         Text(
//           title,
//           style: context.textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.w800,
//           ),
//         ),
//       ],
//     ),
//   );
// }

// class _PackCard extends StatelessWidget {
//   const _PackCard({required this.pack, required this.onTap});
//   final PackEntity pack;
//   final VoidCallback onTap;
//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 130,
//         margin: const EdgeInsets.only(right: 12),
//         decoration: BoxDecoration(
//           color: theme.colorScheme.surfaceContainerHighest,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: theme.colorScheme.outlineVariant),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ClipRRect(
//               borderRadius: const BorderRadius.vertical(
//                 top: Radius.circular(14),
//               ),
//               child: pack.coverImageUrl != null
//                   ? Image.network(
//                       pack.coverImageUrl!,
//                       height: 80,
//                       width: 130,
//                       fit: BoxFit.cover,
//                       errorBuilder: (_, __, ___) =>
//                           _PackCoverPlaceholder(pack: pack),
//                     )
//                   : _PackCoverPlaceholder(pack: pack),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(8),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     pack.titleFor(Localizations.localeOf(context).languageCode),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: theme.textTheme.bodySmall?.copyWith(
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Row(
//                     children: [
//                       const Icon(
//                         Icons.star_rounded,
//                         size: 12,
//                         color: Color(0xFFF5A623),
//                       ),
//                       const SizedBox(width: 2),
//                       Text(
//                         '${pack.avgRating.toStringAsFixed(1)}',
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           fontSize: 10,
//                         ),
//                       ),
//                       const Spacer(),
//                       Text(
//                         '${pack.totalPlays} 🎮',
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           fontSize: 10,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _PackCoverPlaceholder extends StatelessWidget {
//   const _PackCoverPlaceholder({required this.pack});
//   final PackEntity pack;
//   @override
//   Widget build(BuildContext context) => Container(
//     height: 80,
//     width: 130,
//     color: Theme.of(context).colorScheme.primaryContainer,
//     child: Center(
//       child: Text(
//         pack.gameType == 'truth_or_dare'
//             ? '🎯'
//             : pack.gameType == 'never_have_i_ever'
//             ? '🍹'
//             : '😂',
//         style: const TextStyle(fontSize: 32),
//       ),
//     ),
//   );
// }

// class _StatCell extends StatelessWidget {
//   const _StatCell({required this.label, required this.value});
//   final String label, value;
//   @override
//   Widget build(BuildContext context) => Expanded(
//     child: Column(
//       children: [
//         Text(
//           value,
//           style: context.textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.w800,
//           ),
//         ),
//         Text(
//           label,
//           style: context.textTheme.bodySmall?.copyWith(
//             color: context.colorScheme.onSurfaceVariant,
//           ),
//         ),
//       ],
//     ),
//   );
// }

// class _Divider extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) => Container(
//     width: 1,
//     height: 32,
//     color: context.colorScheme.outlineVariant,
//   );
// }

// class _FriendshipAction extends StatelessWidget {
//   const _FriendshipAction({
//     required this.profile,
//     required this.friends,
//     required this.onAct,
//   });
//   final SocialProfile profile;
//   final FriendsProvider friends;
//   final Future<void> Function(Future<void> Function()) onAct;
//   @override
//   Widget build(BuildContext context) {
//     final status = profile.friendshipStatus;
//     final isSentRequest = friends.sentRequests.any(
//       (r) => r.userId == profile.userId,
//     );
//     if (status == FriendshipStatus.accepted) {
//       return OutlinedButton.icon(
//         onPressed: () => onAct(() => friends.removeFriend(profile.userId)),
//         icon: const Icon(Icons.person_remove_outlined),
//         label: const Text('Remove friend'),
//         style: OutlinedButton.styleFrom(
//           minimumSize: const Size(double.infinity, 44),
//         ),
//       );
//     }
//     if (status == FriendshipStatus.pending || isSentRequest) {
//       return OutlinedButton.icon(
//         onPressed: () => onAct(() => friends.cancelRequest(profile.userId)),
//         icon: const Icon(Icons.cancel_outlined),
//         label: const Text('Cancel request'),
//         style: OutlinedButton.styleFrom(
//           minimumSize: const Size(double.infinity, 44),
//         ),
//       );
//     }
//     return JButton(
//       label: 'Add friend',
//       onPressed: () =>
//           onAct(() => friends.sendFriendRequest(profile.userId).then((_) {})),
//       icon: Icons.person_add_outlined,
//     );
//   }
// }

// class _FollowAction extends StatelessWidget {
//   const _FollowAction({
//     required this.profile,
//     required this.friends,
//     required this.onAct,
//   });
//   final SocialProfile profile;
//   final FriendsProvider friends;
//   final Future<void> Function(Future<void> Function()) onAct;
//   @override
//   Widget build(BuildContext context) {
//     if (profile.isFollowing) {
//       return OutlinedButton.icon(
//         onPressed: () =>
//             onAct(() => friends.unfollowUser(profile.userId).then((_) {})),
//         icon: const Icon(Icons.remove_circle_outline_rounded),
//         label: const Text('Unfollow'),
//         style: OutlinedButton.styleFrom(
//           minimumSize: const Size(double.infinity, 44),
//         ),
//       );
//     }
//     return FilledButton.tonal(
//       onPressed: () =>
//           onAct(() => friends.followUser(profile.userId).then((_) {})),
//       style: FilledButton.styleFrom(
//         minimumSize: const Size(double.infinity, 44),
//       ),
//       child: const Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [Icon(Icons.add_rounded), SizedBox(width: 6), Text('Follow')],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../../packs/data/pack_repository.dart';
import '../../../packs/domain/pack_entity.dart';
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
  List<PackEntity> _packs = [];
  List<PackEntity> _mostPlayed = [];
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
      final results = await Future.wait([
        context.read<FriendsProvider>().getSocialProfile(widget.userId),
        sl.packRepository.getPublicPacksByCreator(widget.userId),
        sl.packRepository.getMostPlayedPacksForUser(widget.userId),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as SocialProfile;
          _packs = results[1] as List<PackEntity>;
          _mostPlayed = results[2] as List<PackEntity>;
          _isLoading = false;
        });
      }
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
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                if (v == 'block') _act(() => friends.blockUser(p.userId));
              },
            ),
        ],
      ),
      body: _isActing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(
                    p: p,
                    friends: friends,
                  ).animate().fadeIn().slideY(begin: -0.05, end: 0),
                  _StatsRow(p: p).animate(delay: 80.ms).fadeIn(),
                  if (p.isBlocked || p.isBlockedBy) _BlockedBanner(p: p),
                  if (p.canInteract)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        children: [
                          _FriendshipAction(
                            profile: p,
                            friends: friends,
                            onAct: _act,
                          ),
                          const SizedBox(height: 10),
                          _FollowAction(
                            profile: p,
                            friends: friends,
                            onAct: _act,
                          ),
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
                  if (!p.isBlocked &&
                      !p.isBlockedBy &&
                      _mostPlayed.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Most Played by ${p.displayName}',
                      emoji: '🔥',
                    ),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _mostPlayed.length,
                        itemBuilder: (_, i) =>
                            _PackCard(
                                  pack: _mostPlayed[i],
                                  onTap: () => context.push(
                                    '${RouteNames.marketplace}/pack/${_mostPlayed[i].id}',
                                  ),
                                )
                                .animate(delay: (i * 40).ms)
                                .fadeIn()
                                .slideX(begin: 0.1, end: 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!p.isBlocked && !p.isBlockedBy && _packs.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Created by ${p.displayName}',
                      emoji: '🎴',
                    ),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _packs.length,
                        itemBuilder: (_, i) =>
                            _PackCard(
                                  pack: _packs[i],
                                  onTap: () => context.push(
                                    '${RouteNames.marketplace}/pack/${_packs[i].id}',
                                  ),
                                )
                                .animate(delay: (i * 40).ms)
                                .fadeIn()
                                .slideX(begin: 0.1, end: 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!p.isBlocked &&
                      !p.isBlockedBy &&
                      _packs.isEmpty &&
                      _mostPlayed.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No packs yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.p, required this.friends});
  final SocialProfile p;
  final FriendsProvider friends;
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          UserAvatar(
            avatarUrl: p.avatarUrl,
            avatarConfig: p.avatarConfig,
            isPremium: p.isPremium,
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
              if (p.isPremium) ...[
                const SizedBox(width: 6),
                const Text(
                  '✦',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFF5A623),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
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
          if (!p.isBlockedBy && !p.isBlocked) ...[
            const SizedBox(height: 8),
            OnlineIndicator(
              status: friends.statusOf(p.userId),
              showLabel: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.p});
  final SocialProfile p;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
          _StatCell(label: context.l10n.profilePacks, value: '${p.packsCount}'),
        ],
      ),
    );
  }
}

class _BlockedBanner extends StatelessWidget {
  const _BlockedBanner({required this.p});
  final SocialProfile p;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.block_rounded, color: AppColors.errorRed),
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
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.emoji});
  final String title, emoji;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _PackCard extends StatelessWidget {
  const _PackCard({required this.pack, required this.onTap});
  final PackEntity pack;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: pack.coverImageUrl != null
                  ? Image.network(
                      pack.coverImageUrl!,
                      height: 80,
                      width: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _PackCoverPlaceholder(pack: pack),
                    )
                  : _PackCoverPlaceholder(pack: pack),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.titleFor(Localizations.localeOf(context).languageCode),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Color(0xFFF5A623),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${pack.avgRating.toStringAsFixed(1)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${pack.totalPlays} 🎮',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackCoverPlaceholder extends StatelessWidget {
  const _PackCoverPlaceholder({required this.pack});
  final PackEntity pack;
  @override
  Widget build(BuildContext context) => Container(
    height: 80,
    width: 130,
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Center(
      child: Text(
        pack.gameType == 'truth_or_dare'
            ? '🎯'
            : pack.gameType == 'never_have_i_ever'
            ? '🍹'
            : '😂',
        style: const TextStyle(fontSize: 32),
      ),
    ),
  );
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Expanded(
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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 32,
    color: context.colorScheme.outlineVariant,
  );
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
