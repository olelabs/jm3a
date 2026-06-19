// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // import 'package:go_router/go_router.dart';
// // // // import 'package:provider/provider.dart';

// // // // import '../../../../core/extensions/context_ext.dart';
// // // // import '../../../../core/providers/auth_provider.dart';
// // // // import '../../../../core/router/route_names.dart';
// // // // import '../../../../core/theme/app_colors.dart';
// // // // import '../../../../shared/widgets/cards/j_card.dart';
// // // // import '../../../../shared/widgets/cards/user_avatar.dart';

// // // // class ProfileScreen extends StatelessWidget {
// // // //   const ProfileScreen({super.key});

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final auth = context.watch<AuthProvider>();
// // // //     final user = auth.currentUser;
// // // //     final theme = context.theme;
// // // //     final l10n = context.l10n;

// // // //     if (user == null) return const SizedBox.shrink();

// // // //     return Scaffold(
// // // //       body: CustomScrollView(
// // // //         slivers: [
// // // //           // Profile header
// // // //           SliverAppBar(
// // // //             expandedHeight: 200,
// // // //             pinned: true,
// // // //             actions: [
// // // //               IconButton(
// // // //                 icon: const Icon(Icons.settings_outlined),
// // // //                 onPressed: () => context.push(RouteNames.settings),
// // // //               ),
// // // //             ],
// // // //             flexibleSpace: FlexibleSpaceBar(
// // // //               background: _ProfileHeader(user: user),
// // // //             ),
// // // //           ),

// // // //           // Content
// // // //           SliverPadding(
// // // //             padding: const EdgeInsets.all(16),
// // // //             sliver: SliverList(
// // // //               delegate: SliverChildListDelegate([
// // // //                 // Stats row
// // // //                 _StatsRow(user: user)
// // // //                     .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

// // // //                 const SizedBox(height: 20),

// // // //                 // Bio
// // // //                 if (user.bio?.isNotEmpty == true) ...[
// // // //                   JCard(
// // // //                     child: Column(
// // // //                       crossAxisAlignment: CrossAxisAlignment.start,
// // // //                       children: [
// // // //                         Text('About',
// // // //                             style: theme.textTheme.titleSmall?.copyWith(
// // // //                                 fontWeight: FontWeight.w600,
// // // //                                 color: theme.colorScheme.onSurfaceVariant)),
// // // //                         const SizedBox(height: 8),
// // // //                         Text(user.bio!,
// // // //                             style: theme.textTheme.bodyMedium),
// // // //                       ],
// // // //                     ),
// // // //                   ).animate(delay: 150.ms).fadeIn(),
// // // //                   const SizedBox(height: 16),
// // // //                 ],

// // // //                 // Edit profile button
// // // //                 OutlinedButton.icon(
// // // //                   onPressed: () => context.push('/profile/edit'),
// // // //                   icon: const Icon(Icons.edit_outlined, size: 18),
// // // //                   label: Text(l10n.profileEditTitle),
// // // //                   style: OutlinedButton.styleFrom(
// // // //                     minimumSize: const Size(double.infinity, 48),
// // // //                   ),
// // // //                 ).animate(delay: 200.ms).fadeIn(),

// // // //                 const SizedBox(height: 12),

// // // //                 // Wallet quick access
// // // //                 ListTile(
// // // //                   leading: Container(
// // // //                     width: 40, height: 40,
// // // //                     decoration: BoxDecoration(
// // // //                       color: AppColors.amberOrangeLight.withOpacity(0.12),
// // // //                       borderRadius: BorderRadius.circular(10),
// // // //                     ),
// // // //                     child: Icon(Icons.account_balance_wallet_outlined,
// // // //                         color: AppColors.amberOrangeLight, size: 20),
// // // //                   ),
// // // //                   title: const Text('Wallet'),
// // // //                   subtitle: const Text('Balance & transactions'),
// // // //                   trailing: const Icon(Icons.chevron_right_rounded),
// // // //                   shape: RoundedRectangleBorder(
// // // //                       borderRadius: BorderRadius.circular(12)),
// // // //                   onTap: () => context.push(RouteNames.wallet),
// // // //                 ).animate(delay: 250.ms).fadeIn(),

// // // //                 // Notifications
// // // //                 ListTile(
// // // //                   leading: Container(
// // // //                     width: 40, height: 40,
// // // //                     decoration: BoxDecoration(
// // // //                       color: AppColors.infoBlue.withOpacity(0.12),
// // // //                       borderRadius: BorderRadius.circular(10),
// // // //                     ),
// // // //                     child: Icon(Icons.notifications_outlined,
// // // //                         color: AppColors.infoBlue, size: 20),
// // // //                   ),
// // // //                   title: const Text('Notifications'),
// // // //                   trailing: const Icon(Icons.chevron_right_rounded),
// // // //                   shape: RoundedRectangleBorder(
// // // //                       borderRadius: BorderRadius.circular(12)),
// // // //                   onTap: () => context.push(RouteNames.notifications),
// // // //                 ).animate(delay: 300.ms).fadeIn(),
// // // //               ]),
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _ProfileHeader extends StatelessWidget {
// // // //   const _ProfileHeader({required this.user});
// // // //   final dynamic user;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = context.theme;
// // // //     return Container(
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             AppColors.navyBlue,
// // // //             AppColors.navyBlue.withOpacity(0.7),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //       child: SafeArea(
// // // //         child: Padding(
// // // //           padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
// // // //           child: Row(
// // // //             children: [
// // // //               UserAvatar(
// // // //                 avatarUrl: user.avatarUrl,
// // // //                 displayName: user.displayName,
// // // //                 size: 72,
// // // //               ),
// // // //               const SizedBox(width: 16),
// // // //               Expanded(
// // // //                 child: Column(
// // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // //                   mainAxisSize: MainAxisSize.min,
// // // //                   children: [
// // // //                     Text(
// // // //                       user.displayName ?? 'Player',
// // // //                       style: theme.textTheme.titleLarge?.copyWith(
// // // //                         color: Colors.white,
// // // //                         fontWeight: FontWeight.w700,
// // // //                       ),
// // // //                     ),
// // // //                     if (user.username != null)
// // // //                       Text('@${user.username}',
// // // //                           style: theme.textTheme.bodyMedium?.copyWith(
// // // //                               color: Colors.white70)),
// // // //                     if (user.isVerifiedCreator)
// // // //                       Padding(
// // // //                         padding: const EdgeInsets.only(top: 4),
// // // //                         child: Row(
// // // //                           children: [
// // // //                             Icon(Icons.verified_rounded,
// // // //                                 size: 14, color: AppColors.amberOrangeLight),
// // // //                             const SizedBox(width: 4),
// // // //                             Text('Verified Creator',
// // // //                                 style: theme.textTheme.labelSmall?.copyWith(
// // // //                                     color: AppColors.amberOrangeLight)),
// // // //                           ],
// // // //                         ),
// // // //                       ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _StatsRow extends StatelessWidget {
// // // //   const _StatsRow({required this.user});
// // // //   final dynamic user;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Row(
// // // //       children: [
// // // //         _StatBox(label: 'Games', value: '—'),
// // // //         const SizedBox(width: 12),
// // // //         _StatBox(label: 'Friends', value: '—'),
// // // //         const SizedBox(width: 12),
// // // //         _StatBox(label: 'Packs', value: '—'),
// // // //       ],
// // // //     );
// // // //   }
// // // // }

// // // // class _StatBox extends StatelessWidget {
// // // //   const _StatBox({required this.label, required this.value});
// // // //   final String label;
// // // //   final String value;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Expanded(
// // // //       child: JCard(
// // // //         padding: const EdgeInsets.symmetric(vertical: 14),
// // // //         child: Column(
// // // //           children: [
// // // //             Text(value,
// // // //                 style: context.textTheme.titleLarge?.copyWith(
// // // //                     fontWeight: FontWeight.w700)),
// // // //             const SizedBox(height: 2),
// // // //             Text(label,
// // // //                 style: context.textTheme.bodySmall?.copyWith(
// // // //                     color: context.colorScheme.onSurfaceVariant)),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_animate/flutter_animate.dart';
// // // import 'package:go_router/go_router.dart';
// // // import 'package:provider/provider.dart';

// // // import '../../../../core/extensions/context_ext.dart';
// // // import '../../../../core/providers/auth_provider.dart';
// // // import '../../../../core/router/route_names.dart';
// // // import '../../../../core/router/app_router.dart';
// // // import '../../../../core/theme/app_colors.dart';
// // // import '../../../../shared/widgets/cards/j_card.dart';
// // // import '../../../../shared/widgets/cards/user_avatar.dart';

// // // class ProfileScreen extends StatelessWidget {
// // //   const ProfileScreen({super.key});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final auth = context.watch<AuthProvider>();
// // //     final user = auth.currentUser;
// // //     final theme = context.theme;
// // //     final l10n = context.l10n;

// // //     if (user == null) return const SizedBox.shrink();

// // //     return Scaffold(
// // //       body: CustomScrollView(
// // //         slivers: [
// // //           // Profile header
// // //           SliverAppBar(
// // //             expandedHeight: 200,
// // //             pinned: true,
// // //             actions: [
// // //               // IconButton(
// // //               //   icon: const Icon(Icons.settings_outlined),
// // //               //   onPressed: () => context.push(RouteNames.settings),
// // //               //   // AppRouter.router.push(RouteNames.settings),
// // //               // ),
// // //               IconButton(
// // //                 icon: const Icon(Icons.settings_outlined),
// // //                 onPressed: () => context.push(RouteNames.settings), // ✅
// // //               ),
// // //             ],
// // //             flexibleSpace: FlexibleSpaceBar(
// // //               background: _ProfileHeader(user: user),
// // //             ),
// // //           ),

// // //           // Content
// // //           SliverPadding(
// // //             padding: const EdgeInsets.all(16),
// // //             sliver: SliverList(
// // //               delegate: SliverChildListDelegate([
// // //                 // Stats row
// // //                 _StatsRow(
// // //                   user: user,
// // //                 ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

// // //                 const SizedBox(height: 20),

// // //                 // Bio
// // //                 if (user.bio?.isNotEmpty == true) ...[
// // //                   JCard(
// // //                     child: Column(
// // //                       crossAxisAlignment: CrossAxisAlignment.start,
// // //                       children: [
// // //                         Text(
// // //                           'About',
// // //                           style: theme.textTheme.titleSmall?.copyWith(
// // //                             fontWeight: FontWeight.w600,
// // //                             color: theme.colorScheme.onSurfaceVariant,
// // //                           ),
// // //                         ),
// // //                         const SizedBox(height: 8),
// // //                         Text(user.bio!, style: theme.textTheme.bodyMedium),
// // //                       ],
// // //                     ),
// // //                   ).animate(delay: 150.ms).fadeIn(),
// // //                   const SizedBox(height: 16),
// // //                 ],

// // //                 // Edit profile button
// // //                 OutlinedButton.icon(
// // //                   // onPressed: () => AppRouter.router.push('/profile/edit'),
// // //                   onPressed: () => context.push('/profile/edit'),
// // //                   icon: const Icon(Icons.edit_outlined, size: 18),
// // //                   label: Text(l10n.profileEditTitle),
// // //                   style: OutlinedButton.styleFrom(
// // //                     minimumSize: const Size(double.infinity, 48),
// // //                   ),
// // //                 ).animate(delay: 200.ms).fadeIn(),

// // //                 const SizedBox(height: 12),

// // //                 // Wallet quick access
// // //                 ListTile(
// // //                   leading: Container(
// // //                     width: 40,
// // //                     height: 40,
// // //                     decoration: BoxDecoration(
// // //                       color: AppColors.amberOrangeLight.withOpacity(0.12),
// // //                       borderRadius: BorderRadius.circular(10),
// // //                     ),
// // //                     child: Icon(
// // //                       Icons.account_balance_wallet_outlined,
// // //                       color: AppColors.amberOrangeLight,
// // //                       size: 20,
// // //                     ),
// // //                   ),
// // //                   title: const Text('Wallet'),
// // //                   subtitle: const Text('Balance & transactions'),
// // //                   trailing: const Icon(Icons.chevron_right_rounded),
// // //                   shape: RoundedRectangleBorder(
// // //                     borderRadius: BorderRadius.circular(12),
// // //                   ),
// // //                   onTap: () => AppRouter.router.push(RouteNames.wallet),
// // //                 ).animate(delay: 250.ms).fadeIn(),

// // //                 // Notifications
// // //                 ListTile(
// // //                   leading: Container(
// // //                     width: 40,
// // //                     height: 40,
// // //                     decoration: BoxDecoration(
// // //                       color: AppColors.infoBlue.withOpacity(0.12),
// // //                       borderRadius: BorderRadius.circular(10),
// // //                     ),
// // //                     child: Icon(
// // //                       Icons.notifications_outlined,
// // //                       color: AppColors.infoBlue,
// // //                       size: 20,
// // //                     ),
// // //                   ),
// // //                   title: const Text('Notifications'),
// // //                   trailing: const Icon(Icons.chevron_right_rounded),
// // //                   shape: RoundedRectangleBorder(
// // //                     borderRadius: BorderRadius.circular(12),
// // //                   ),
// // //                   onTap: () => AppRouter.router.push(RouteNames.notifications),
// // //                 ).animate(delay: 300.ms).fadeIn(),
// // //               ]),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _ProfileHeader extends StatelessWidget {
// // //   const _ProfileHeader({required this.user});
// // //   final dynamic user;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;
// // //     return Container(
// // //       decoration: BoxDecoration(
// // //         gradient: LinearGradient(
// // //           begin: Alignment.topLeft,
// // //           end: Alignment.bottomRight,
// // //           colors: [AppColors.navyBlue, AppColors.navyBlue.withOpacity(0.7)],
// // //         ),
// // //       ),
// // //       child: SafeArea(
// // //         child: Padding(
// // //           padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
// // //           child: Row(
// // //             children: [
// // //               UserAvatar(
// // //                 avatarUrl: user.avatarUrl,
// // //                 displayName: user.displayName,
// // //                 size: 72,
// // //               ),
// // //               const SizedBox(width: 16),
// // //               Expanded(
// // //                 child: Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   mainAxisSize: MainAxisSize.min,
// // //                   children: [
// // //                     Text(
// // //                       user.displayName ?? 'Player',
// // //                       style: theme.textTheme.titleLarge?.copyWith(
// // //                         color: Colors.white,
// // //                         fontWeight: FontWeight.w700,
// // //                       ),
// // //                     ),
// // //                     if (user.username != null)
// // //                       Text(
// // //                         '@${user.username}',
// // //                         style: theme.textTheme.bodyMedium?.copyWith(
// // //                           color: Colors.white70,
// // //                         ),
// // //                       ),
// // //                     if (user.isVerifiedCreator)
// // //                       Padding(
// // //                         padding: const EdgeInsets.only(top: 4),
// // //                         child: Row(
// // //                           children: [
// // //                             Icon(
// // //                               Icons.verified_rounded,
// // //                               size: 14,
// // //                               color: AppColors.amberOrangeLight,
// // //                             ),
// // //                             const SizedBox(width: 4),
// // //                             Text(
// // //                               'Verified Creator',
// // //                               style: theme.textTheme.labelSmall?.copyWith(
// // //                                 color: AppColors.amberOrangeLight,
// // //                               ),
// // //                             ),
// // //                           ],
// // //                         ),
// // //                       ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _StatsRow extends StatelessWidget {
// // //   const _StatsRow({required this.user});
// // //   final dynamic user;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Row(
// // //       children: [
// // //         _StatBox(label: 'Games', value: '—'),
// // //         const SizedBox(width: 12),
// // //         _StatBox(label: 'Friends', value: '—'),
// // //         const SizedBox(width: 12),
// // //         _StatBox(label: 'Packs', value: '—'),
// // //       ],
// // //     );
// // //   }
// // // }

// // // class _StatBox extends StatelessWidget {
// // //   const _StatBox({required this.label, required this.value});
// // //   final String label;
// // //   final String value;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Expanded(
// // //       child: JCard(
// // //         padding: const EdgeInsets.symmetric(vertical: 14),
// // //         child: Column(
// // //           children: [
// // //             Text(
// // //               value,
// // //               style: context.textTheme.titleLarge?.copyWith(
// // //                 fontWeight: FontWeight.w700,
// // //               ),
// // //             ),
// // //             const SizedBox(height: 2),
// // //             Text(
// // //               label,
// // //               style: context.textTheme.bodySmall?.copyWith(
// // //                 color: context.colorScheme.onSurfaceVariant,
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:provider/provider.dart';

// // import '../../../../core/extensions/context_ext.dart';
// // import '../../../../core/providers/auth_provider.dart';
// // import '../../../../core/router/route_names.dart';
// // import '../../../../core/router/app_router.dart';
// // import '../../../../core/theme/app_colors.dart';
// // import '../../../../shared/widgets/cards/j_card.dart';
// // import '../../../../shared/widgets/cards/user_avatar.dart';

// // class ProfileScreen extends StatelessWidget {
// //   const ProfileScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     final auth = context.watch<AuthProvider>();
// //     final user = auth.currentUser;
// //     final theme = context.theme;
// //     final l10n = context.l10n;

// //     if (user == null) return const SizedBox.shrink();

// //     return Scaffold(
// //       body: CustomScrollView(
// //         slivers: [
// //           // Profile header
// //           SliverAppBar(
// //             expandedHeight: 200,
// //             pinned: true,
// //             actions: [
// //               IconButton(
// //                 icon: const Icon(Icons.settings_outlined),
// //                 onPressed: () {
// //                   debugPrint('=== PUSH settings');
// //                   AppRouter.router.push(RouteNames.settings);
// //                 },
// //               ),
// //             ],
// //             flexibleSpace: FlexibleSpaceBar(
// //               background: _ProfileHeader(user: user),
// //             ),
// //           ),

// //           // Content
// //           SliverPadding(
// //             padding: const EdgeInsets.all(16),
// //             sliver: SliverList(
// //               delegate: SliverChildListDelegate([
// //                 // Stats row
// //                 _StatsRow(
// //                   user: user,
// //                 ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

// //                 const SizedBox(height: 20),

// //                 // Bio
// //                 if (user.bio?.isNotEmpty == true) ...[
// //                   JCard(
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         Text(
// //                           'About',
// //                           style: theme.textTheme.titleSmall?.copyWith(
// //                             fontWeight: FontWeight.w600,
// //                             color: theme.colorScheme.onSurfaceVariant,
// //                           ),
// //                         ),
// //                         const SizedBox(height: 8),
// //                         Text(user.bio!, style: theme.textTheme.bodyMedium),
// //                       ],
// //                     ),
// //                   ).animate(delay: 150.ms).fadeIn(),
// //                   const SizedBox(height: 16),
// //                 ],

// //                 // Edit profile button
// //                 OutlinedButton.icon(
// //                   onPressed: () {
// //                     debugPrint('=== PUSH /profile/edit');
// //                     AppRouter.router.push('/profile/edit');
// //                   },
// //                   icon: const Icon(Icons.edit_outlined, size: 18),
// //                   label: Text(l10n.profileEditTitle),
// //                   style: OutlinedButton.styleFrom(
// //                     minimumSize: const Size(double.infinity, 48),
// //                   ),
// //                 ).animate(delay: 200.ms).fadeIn(),

// //                 const SizedBox(height: 12),

// //                 // Wallet quick access
// //                 ListTile(
// //                   leading: Container(
// //                     width: 40,
// //                     height: 40,
// //                     decoration: BoxDecoration(
// //                       color: AppColors.amberOrangeLight.withOpacity(0.12),
// //                       borderRadius: BorderRadius.circular(10),
// //                     ),
// //                     child: Icon(
// //                       Icons.account_balance_wallet_outlined,
// //                       color: AppColors.amberOrangeLight,
// //                       size: 20,
// //                     ),
// //                   ),
// //                   title: const Text('Wallet'),
// //                   subtitle: const Text('Balance & transactions'),
// //                   trailing: const Icon(Icons.chevron_right_rounded),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                   ),
// //                   onTap: () {
// //                     debugPrint('=== PUSH wallet');
// //                     AppRouter.router.push(RouteNames.wallet);
// //                   },
// //                 ).animate(delay: 250.ms).fadeIn(),

// //                 // Notifications
// //                 ListTile(
// //                   leading: Container(
// //                     width: 40,
// //                     height: 40,
// //                     decoration: BoxDecoration(
// //                       color: AppColors.infoBlue.withOpacity(0.12),
// //                       borderRadius: BorderRadius.circular(10),
// //                     ),
// //                     child: Icon(
// //                       Icons.notifications_outlined,
// //                       color: AppColors.infoBlue,
// //                       size: 20,
// //                     ),
// //                   ),
// //                   title: const Text('Notifications'),
// //                   trailing: const Icon(Icons.chevron_right_rounded),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                   ),
// //                   onTap: () => AppRouter.router.push(RouteNames.notifications),
// //                 ).animate(delay: 300.ms).fadeIn(),
// //               ]),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _ProfileHeader extends StatelessWidget {
// //   const _ProfileHeader({required this.user});
// //   final dynamic user;

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     return Container(
// //       decoration: BoxDecoration(
// //         gradient: LinearGradient(
// //           begin: Alignment.topLeft,
// //           end: Alignment.bottomRight,
// //           colors: [AppColors.navyBlue, AppColors.navyBlue.withOpacity(0.7)],
// //         ),
// //       ),
// //       child: SafeArea(
// //         child: Padding(
// //           padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
// //           child: Row(
// //             children: [
// //               UserAvatar(
// //                 avatarUrl: user.avatarUrl,
// //                 displayName: user.displayName,
// //                 size: 72,
// //               ),
// //               const SizedBox(width: 16),
// //               Expanded(
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     Text(
// //                       user.displayName ?? 'Player',
// //                       style: theme.textTheme.titleLarge?.copyWith(
// //                         color: Colors.white,
// //                         fontWeight: FontWeight.w700,
// //                       ),
// //                     ),
// //                     if (user.username != null)
// //                       Text(
// //                         '@${user.username}',
// //                         style: theme.textTheme.bodyMedium?.copyWith(
// //                           color: Colors.white70,
// //                         ),
// //                       ),
// //                     if (user.isVerifiedCreator)
// //                       Padding(
// //                         padding: const EdgeInsets.only(top: 4),
// //                         child: Row(
// //                           children: [
// //                             Icon(
// //                               Icons.verified_rounded,
// //                               size: 14,
// //                               color: AppColors.amberOrangeLight,
// //                             ),
// //                             const SizedBox(width: 4),
// //                             Text(
// //                               'Verified Creator',
// //                               style: theme.textTheme.labelSmall?.copyWith(
// //                                 color: AppColors.amberOrangeLight,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class _StatsRow extends StatelessWidget {
// //   const _StatsRow({required this.user});
// //   final dynamic user;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Row(
// //       children: [
// //         _StatBox(label: 'Games', value: '—'),
// //         const SizedBox(width: 12),
// //         _StatBox(label: 'Friends', value: '—'),
// //         const SizedBox(width: 12),
// //         _StatBox(label: 'Packs', value: '—'),
// //       ],
// //     );
// //   }
// // }

// // class _StatBox extends StatelessWidget {
// //   const _StatBox({required this.label, required this.value});
// //   final String label;
// //   final String value;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Expanded(
// //       child: JCard(
// //         padding: const EdgeInsets.symmetric(vertical: 14),
// //         child: Column(
// //           children: [
// //             Text(
// //               value,
// //               style: context.textTheme.titleLarge?.copyWith(
// //                 fontWeight: FontWeight.w700,
// //               ),
// //             ),
// //             const SizedBox(height: 2),
// //             Text(
// //               label,
// //               style: context.textTheme.bodySmall?.copyWith(
// //                 color: context.colorScheme.onSurfaceVariant,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/providers/auth_provider.dart';
// import '../../../../core/router/route_names.dart';
// import '../../../../core/router/app_router.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/cards/j_card.dart';
// import '../../../../shared/widgets/cards/user_avatar.dart';

// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();
//     final user = auth.currentUser;
//     final theme = context.theme;
//     final l10n = context.l10n;

//     if (user == null) return const SizedBox.shrink();

//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           // Profile header
//           SliverAppBar(
//             expandedHeight: 200,
//             pinned: true,
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.settings_outlined),
//                 onPressed: () => AppRouter.router.push(RouteNames.settings),
//               ),
//             ],
//             flexibleSpace: FlexibleSpaceBar(
//               background: _ProfileHeader(user: user),
//             ),
//           ),

//           // Content
//           SliverPadding(
//             padding: const EdgeInsets.all(16),
//             sliver: SliverList(
//               delegate: SliverChildListDelegate([
//                 // Stats row
//                 _StatsRow(
//                   user: user,
//                 ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

//                 const SizedBox(height: 20),

//                 // Bio
//                 if (user.bio?.isNotEmpty == true) ...[
//                   JCard(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'About',
//                           style: theme.textTheme.titleSmall?.copyWith(
//                             fontWeight: FontWeight.w600,
//                             color: theme.colorScheme.onSurfaceVariant,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(user.bio!, style: theme.textTheme.bodyMedium),
//                       ],
//                     ),
//                   ).animate(delay: 150.ms).fadeIn(),
//                   const SizedBox(height: 16),
//                 ],

//                 // Edit profile button
//                 OutlinedButton.icon(
//                   onPressed: () => AppRouter.router.push('/profile/edit'),
//                   icon: const Icon(Icons.edit_outlined, size: 18),
//                   label: Text(l10n.profileEditTitle),
//                   style: OutlinedButton.styleFrom(
//                     minimumSize: const Size(double.infinity, 48),
//                   ),
//                 ).animate(delay: 200.ms).fadeIn(),

//                 const SizedBox(height: 12),

//                 // Wallet quick access
//                 ListTile(
//                   leading: Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       color: AppColors.amberOrangeLight.withOpacity(0.12),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Icon(
//                       Icons.account_balance_wallet_outlined,
//                       color: AppColors.amberOrangeLight,
//                       size: 20,
//                     ),
//                   ),
//                   title: const Text('Wallet'),
//                   subtitle: const Text('Balance & transactions'),
//                   trailing: const Icon(Icons.chevron_right_rounded),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   onTap: () => AppRouter.router.push(RouteNames.wallet),
//                 ).animate(delay: 250.ms).fadeIn(),

//                 // Notifications
//                 ListTile(
//                   leading: Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       color: AppColors.infoBlue.withOpacity(0.12),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Icon(
//                       Icons.notifications_outlined,
//                       color: AppColors.infoBlue,
//                       size: 20,
//                     ),
//                   ),
//                   title: const Text('Notifications'),
//                   trailing: const Icon(Icons.chevron_right_rounded),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   onTap: () => AppRouter.router.push(RouteNames.notifications),
//                 ).animate(delay: 300.ms).fadeIn(),
//               ]),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ProfileHeader extends StatelessWidget {
//   const _ProfileHeader({required this.user});
//   final dynamic user;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [AppColors.navyBlue, AppColors.navyBlue.withOpacity(0.7)],
//         ),
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
//           child: Row(
//             children: [
//               UserAvatar(
//                 avatarUrl: user.avatarUrl,
//                 displayName: user.displayName,
//                 size: 72,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       user.displayName ?? 'Player',
//                       style: theme.textTheme.titleLarge?.copyWith(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     if (user.username != null)
//                       Text(
//                         '@${user.username}',
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           color: Colors.white70,
//                         ),
//                       ),
//                     if (user.isVerifiedCreator)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 4),
//                         child: Row(
//                           children: [
//                             Icon(
//                               Icons.verified_rounded,
//                               size: 14,
//                               color: AppColors.amberOrangeLight,
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               'Verified Creator',
//                               style: theme.textTheme.labelSmall?.copyWith(
//                                 color: AppColors.amberOrangeLight,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _StatsRow extends StatelessWidget {
//   const _StatsRow({required this.user});
//   final dynamic user;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         _StatBox(label: 'Games', value: '—'),
//         const SizedBox(width: 12),
//         _StatBox(label: 'Friends', value: '—'),
//         const SizedBox(width: 12),
//         _StatBox(label: 'Packs', value: '—'),
//       ],
//     );
//   }
// }

// class _StatBox extends StatelessWidget {
//   const _StatBox({required this.label, required this.value});
//   final String label;
//   final String value;

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: JCard(
//         padding: const EdgeInsets.symmetric(vertical: 14),
//         child: Column(
//           children: [
//             Text(
//               value,
//               style: context.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               label,
//               style: context.textTheme.bodySmall?.copyWith(
//                 color: context.colorScheme.onSurfaceVariant,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final theme = context.theme;
    final l10n = context.l10n;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => AppRouter.router.push(RouteNames.settings),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(user: user),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                _StatsRow(
                  user: user,
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 20),

                // Bio
                if (user.bio?.isNotEmpty == true) ...[
                  JCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(user.bio!, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ).animate(delay: 150.ms).fadeIn(),
                  const SizedBox(height: 16),
                ],

                // Edit profile button
                OutlinedButton.icon(
                  onPressed: () => AppRouter.router.push('/profile/edit'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.profileEditTitle),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ).animate(delay: 200.ms).fadeIn(),

                const SizedBox(height: 12),

                // Wallet quick access
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.amberOrangeLight.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.amberOrangeLight,
                      size: 20,
                    ),
                  ),
                  title: const Text('Wallet'),
                  subtitle: const Text('Balance & transactions'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () => AppRouter.router.push(RouteNames.wallet),
                ).animate(delay: 250.ms).fadeIn(),

                // Notifications
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.infoBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.infoBlue,
                      size: 20,
                    ),
                  ),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () => AppRouter.router.push(RouteNames.notifications),
                ).animate(delay: 300.ms).fadeIn(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyBlue, AppColors.navyBlue.withOpacity(0.7)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
          child: Row(
            children: [
              UserAvatar(
                avatarUrl: user.avatarUrl,
                displayName: user.displayName,
                size: 72,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.displayName ?? 'Player',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (user.username != null)
                      Text(
                        '@${user.username}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    if (user.isVerifiedCreator)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppColors.amberOrangeLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified Creator',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.amberOrangeLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatefulWidget {
  const _StatsRow({required this.user});
  final dynamic user;

  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
  int _games = 0;
  int _friends = 0;
  int _packs = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final uid = (widget.user?.id as String?) ?? '';
    if (uid.isEmpty) return;
    try {
      final client = Supabase.instance.client;
      // Fetch from profiles_public view (has all counts after migration)
      final rows = await client
          .from('profiles_public')
          .select('friends_count, games_played, packs_count')
          .eq('id', uid)
          .limit(1);
      if (rows.isNotEmpty && mounted) {
        final r = rows.first as Map<String, dynamic>;
        setState(() {
          _friends = (r['friends_count'] as num?)?.toInt() ?? 0;
          _games = (r['games_played'] as num?)?.toInt() ?? 0;
          _packs = (r['packs_count'] as num?)?.toInt() ?? 0;
          _loaded = true;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        _StatBox(label: l10n.profileGames, value: _loaded ? '$_games' : '—'),
        const SizedBox(width: 12),
        _StatBox(
          label: l10n.profileFriends,
          value: _loaded ? '$_friends' : '—',
        ),
        const SizedBox(width: 12),
        _StatBox(label: l10n.profilePacks, value: _loaded ? '$_packs' : '—'),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: JCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
