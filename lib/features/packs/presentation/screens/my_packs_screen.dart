// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:provider/provider.dart';

// // import '../../../../core/extensions/context_ext.dart';
// // import '../../../../core/router/route_names.dart';
// // import '../../../../core/theme/app_colors.dart';
// // import '../../../../shared/widgets/cards/j_card.dart';
// // import '../../../../shared/widgets/cards/user_avatar.dart';
// // import '../../domain/pack_entity.dart';
// // import '../pack_provider.dart';
// // import '../widgets/pack_card_widget.dart';
// // import '../widgets/pack_download_button.dart';

// // /// "My Packs" tab: shows purchased and free downloaded packs.
// // /// Includes offline status and download management.
// // class MyPacksScreen extends StatelessWidget {
// //   const MyPacksScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return DefaultTabController(
// //       length: 2,
// //       child: Column(
// //         children: [
// //           const TabBar(
// //             tabs: [
// //               Tab(text: 'Purchased'),
// //               Tab(text: 'Downloaded'),
// //             ],
// //           ),
// //           Expanded(
// //             child: Consumer<PackProvider>(
// //               builder: (ctx, packs, _) {
// //                 return TabBarView(
// //                   children: [
// //                     _PurchasedList(packs: packs),
// //                     _DownloadedList(packs: packs),
// //                   ],
// //                 );
// //               },
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _PurchasedList extends StatelessWidget {
// //   const _PurchasedList({required this.packs});
// //   final PackProvider packs;

// //   @override
// //   Widget build(BuildContext context) {
// //     final purchased = packs.purchasedPacks;

// //     if (purchased.isEmpty && !packs.isLoading) {
// //       return Center(
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             const Text('🛒', style: TextStyle(fontSize: 56)),
// //             const SizedBox(height: 16),
// //             Text(
// //               'No purchased packs',
// //               style: context.textTheme.titleMedium?.copyWith(
// //                 fontWeight: FontWeight.w700,
// //               ),
// //             ),
// //             const SizedBox(height: 8),
// //             Text(
// //               'Browse the marketplace to find packs.',
// //               style: context.textTheme.bodyMedium?.copyWith(
// //                 color: context.colorScheme.onSurfaceVariant,
// //               ),
// //             ),
// //           ],
// //         ),
// //       );
// //     }

// //     return ListView.separated(
// //       padding: const EdgeInsets.all(16),
// //       itemCount: purchased.length,
// //       separatorBuilder: (_, __) => const SizedBox(height: 12),
// //       itemBuilder: (_, i) {
// //         final pack = purchased[i];
// //         final dlState = packs.downloadStateFor(pack.id);
// //         final purchase = packs.purchaseFor(pack.id);

// //         return _OwnedPackRow(
// //           pack: pack,
// //           dlState: dlState,
// //           purchase: purchase,
// //           onTap: () =>
// //               context.push('${RouteNames.marketplace}/pack/${pack.id}'),
// //           onDownload: () => packs.downloadPack(pack),
// //           onDelete: () => packs.deletePack(pack.id),
// //         ).animate(delay: (i * 35).ms).fadeIn().slideX(begin: 0.04, end: 0);
// //       },
// //     );
// //   }
// // }

// // class _DownloadedList extends StatelessWidget {
// //   const _DownloadedList({required this.packs});
// //   final PackProvider packs;

// //   @override
// //   Widget build(BuildContext context) {
// //     // Include all downloaded packs: purchased + free downloaded
// //     // Build pack lookup — include localPacks as offline fallback.
// //     // When offline, browsePacks/purchasedPacks/featuredPacks are empty,
// //     // but localPacks contains PackEntity objects read from local SQLite.
// //     final allKnownPacks = {
// //       for (final p in [
// //         ...packs.purchasedPacks,
// //         ...packs.browsePacks,
// //         ...packs.featuredPacks,
// //         ...packs.localPacks, // ← offline fallback
// //       ])
// //         p.id: p,
// //     };
// //     final downloaded = packs.allDownloadedPackIds
// //         .map((id) => allKnownPacks[id])
// //         .whereType<PackEntity>()
// //         .toList();

// //     if (downloaded.isEmpty) {
// //       return Center(
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             const Text('📥', style: TextStyle(fontSize: 56)),
// //             const SizedBox(height: 16),
// //             Text(
// //               'No offline packs',
// //               style: context.textTheme.titleMedium?.copyWith(
// //                 fontWeight: FontWeight.w700,
// //               ),
// //             ),
// //             const SizedBox(height: 8),
// //             Text(
// //               'Download packs to play without internet.',
// //               style: context.textTheme.bodyMedium?.copyWith(
// //                 color: context.colorScheme.onSurfaceVariant,
// //               ),
// //               textAlign: TextAlign.center,
// //             ),
// //           ],
// //         ),
// //       );
// //     }

// //     return ListView.separated(
// //       padding: const EdgeInsets.all(16),
// //       itemCount: downloaded.length,
// //       separatorBuilder: (_, __) => const SizedBox(height: 12),
// //       itemBuilder: (_, i) {
// //         final pack = downloaded[i];
// //         final dlState = packs.downloadStateFor(pack.id);
// //         return _OfflinePackRow(
// //           pack: pack,
// //           dlState: dlState,
// //           onDelete: () => packs.deletePack(pack.id),
// //         ).animate(delay: (i * 30).ms).fadeIn();
// //       },
// //     );
// //   }
// // }

// // class _OwnedPackRow extends StatelessWidget {
// //   const _OwnedPackRow({
// //     required this.pack,
// //     required this.dlState,
// //     required this.purchase,
// //     required this.onTap,
// //     required this.onDownload,
// //     required this.onDelete,
// //   });

// //   final PackEntity pack;
// //   final PackDownloadState dlState;
// //   final PackPurchase? purchase;
// //   final VoidCallback onTap;
// //   final VoidCallback onDownload;
// //   final VoidCallback onDelete;

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;

// //     return JCard(
// //       onTap: onTap,
// //       padding: const EdgeInsets.all(12),
// //       child: Row(
// //         children: [
// //           // Cover
// //           ClipRRect(
// //             borderRadius: BorderRadius.circular(10),
// //             child: SizedBox(
// //               width: 64,
// //               height: 64,
// //               child: pack.coverImageUrl != null
// //                   ? Image.network(pack.coverImageUrl!, fit: BoxFit.cover)
// //                   : Container(
// //                       color: theme.colorScheme.surfaceContainerHighest,
// //                       child: Center(
// //                         child: Text(
// //                           _emoji(pack.gameType),
// //                           style: const TextStyle(fontSize: 28),
// //                         ),
// //                       ),
// //                     ),
// //             ),
// //           ),
// //           const SizedBox(width: 12),

// //           // Info
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   pack.titleFor('en'),
// //                   style: theme.textTheme.titleSmall?.copyWith(
// //                     fontWeight: FontWeight.w700,
// //                   ),
// //                   maxLines: 1,
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //                 const SizedBox(height: 3),
// //                 if (purchase != null)
// //                   Text(
// //                     purchase!.daysRemaining > 0
// //                         ? 'Expires in ${purchase!.daysRemaining}d'
// //                         : 'Expired',
// //                     style: theme.textTheme.bodySmall?.copyWith(
// //                       color: purchase!.daysRemaining > 7
// //                           ? theme.colorScheme.onSurfaceVariant
// //                           : AppColors.warningAmber,
// //                     ),
// //                   ),
// //                 const SizedBox(height: 4),
// //                 Text(
// //                   '${pack.cardCount} cards',
// //                   style: theme.textTheme.bodySmall?.copyWith(
// //                     color: theme.colorScheme.onSurfaceVariant,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),

// //           // Download button
// //           PackDownloadButton(
// //             packId: pack.id,
// //             state: dlState,
// //             compact: true,
// //             onDownload: onDownload,
// //             onDelete: onDelete,
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   String _emoji(String gameType) => switch (gameType) {
// //     'truth_or_dare' => '🎯',
// //     'never_have_i_ever' => '🍹',
// //     'meme_game' => '😂',
// //     _ => '🎮',
// //   };
// // }

// // class _OfflinePackRow extends StatelessWidget {
// //   const _OfflinePackRow({
// //     required this.pack,
// //     required this.dlState,
// //     required this.onDelete,
// //   });

// //   final PackEntity pack;
// //   final PackDownloadState dlState;
// //   final VoidCallback onDelete;

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;

// //     return JCard(
// //       padding: const EdgeInsets.all(12),
// //       child: Row(
// //         children: [
// //           Container(
// //             width: 40,
// //             height: 40,
// //             decoration: BoxDecoration(
// //               color: AppColors.successGreen.withOpacity(0.1),
// //               borderRadius: BorderRadius.circular(10),
// //             ),
// //             child: const Icon(
// //               Icons.offline_pin_rounded,
// //               color: AppColors.successGreen,
// //               size: 22,
// //             ),
// //           ),
// //           const SizedBox(width: 12),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   pack.titleFor('en'),
// //                   style: theme.textTheme.titleSmall?.copyWith(
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                   maxLines: 1,
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //                 Text(
// //                   '${pack.cardCount} cards • Available offline',
// //                   style: theme.textTheme.bodySmall?.copyWith(
// //                     color: AppColors.successGreen,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.delete_outline_rounded, size: 20),
// //             onPressed: () async {
// //               final ok = await showDialog<bool>(
// //                 context: context,
// //                 builder: (ctx) => AlertDialog(
// //                   title: const Text('Remove download?'),
// //                   content: Text(
// //                     'This will remove the offline copy of "${pack.titleFor("en")}". You can re-download it later.',
// //                   ),
// //                   actions: [
// //                     TextButton(
// //                       onPressed: () => Navigator.pop(ctx, false),
// //                       child: const Text('Cancel'),
// //                     ),
// //                     TextButton(
// //                       onPressed: () => Navigator.pop(ctx, true),
// //                       style: TextButton.styleFrom(
// //                         foregroundColor: AppColors.errorRed,
// //                       ),
// //                       child: const Text('Remove'),
// //                     ),
// //                   ],
// //                 ),
// //               );
// //               if (ok == true) onDelete();
// //             },
// //             color: theme.colorScheme.error,
// //           ),
// //         ],
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
// import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/cards/j_card.dart';
// import '../../../../shared/widgets/cards/user_avatar.dart';
// import '../../domain/pack_entity.dart';
// import '../pack_provider.dart';
// import '../widgets/pack_card_widget.dart';
// import '../widgets/pack_download_button.dart';

// /// "My Packs" tab: shows purchased and free downloaded packs.
// /// Includes offline status and download management.
// class MyPacksScreen extends StatelessWidget {
//   const MyPacksScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 2,
//       child: Column(
//         children: [
//           const TabBar(
//             tabs: [
//               Tab(text: 'Purchased'),
//               Tab(text: 'Downloaded'),
//             ],
//           ),
//           Expanded(
//             child: Consumer<PackProvider>(
//               builder: (ctx, packs, _) {
//                 return TabBarView(
//                   children: [
//                     _PurchasedList(packs: packs),
//                     _DownloadedList(packs: packs),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PurchasedList extends StatelessWidget {
//   const _PurchasedList({required this.packs});
//   final PackProvider packs;

//   @override
//   Widget build(BuildContext context) {
//     final purchased = packs.purchasedPacks;

//     if (purchased.isEmpty && !packs.isLoading) {
//       return Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text('🛒', style: TextStyle(fontSize: 56)),
//             const SizedBox(height: 16),
//             Text(
//               'No purchased packs',
//               style: context.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Browse the marketplace to find packs.',
//               style: context.textTheme.bodyMedium?.copyWith(
//                 color: context.colorScheme.onSurfaceVariant,
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.separated(
//       padding: const EdgeInsets.all(16),
//       itemCount: purchased.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 12),
//       itemBuilder: (_, i) {
//         final pack = purchased[i];
//         final dlState = packs.downloadStateFor(pack.id);
//         final purchase = packs.purchaseFor(pack.id);

//         return _OwnedPackRow(
//           pack: pack,
//           dlState: dlState,
//           purchase: purchase,
//           onTap: () =>
//               context.push('${RouteNames.marketplace}/pack/${pack.id}'),
//           onDownload: () => packs.downloadPack(
//             pack,
//             isPremium:
//                 context.read<AuthProvider>().currentUser?.isPremiumActive ??
//                 false,
//           ),
//           onDelete: () => packs.deletePack(pack.id),
//         ).animate(delay: (i * 35).ms).fadeIn().slideX(begin: 0.04, end: 0);
//       },
//     );
//   }
// }

// class _DownloadedList extends StatelessWidget {
//   const _DownloadedList({required this.packs});
//   final PackProvider packs;

//   @override
//   Widget build(BuildContext context) {
//     // Include all downloaded packs: purchased + free downloaded
//     // Build pack lookup — include localPacks as offline fallback.
//     // When offline, browsePacks/purchasedPacks/featuredPacks are empty,
//     // but localPacks contains PackEntity objects read from local SQLite.
//     final allKnownPacks = {
//       for (final p in [
//         ...packs.purchasedPacks,
//         ...packs.browsePacks,
//         ...packs.featuredPacks,
//         ...packs.localPacks, // ← offline fallback
//       ])
//         p.id: p,
//     };
//     final downloaded = packs.allDownloadedPackIds
//         .map((id) => allKnownPacks[id])
//         .whereType<PackEntity>()
//         .toList();

//     if (downloaded.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text('📥', style: TextStyle(fontSize: 56)),
//             const SizedBox(height: 16),
//             Text(
//               'No offline packs',
//               style: context.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Download packs to play without internet.',
//               style: context.textTheme.bodyMedium?.copyWith(
//                 color: context.colorScheme.onSurfaceVariant,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.separated(
//       padding: const EdgeInsets.all(16),
//       itemCount: downloaded.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 12),
//       itemBuilder: (_, i) {
//         final pack = downloaded[i];
//         final dlState = packs.downloadStateFor(pack.id);
//         return _OfflinePackRow(
//           pack: pack,
//           dlState: dlState,
//           onDelete: () => packs.deletePack(pack.id),
//         ).animate(delay: (i * 30).ms).fadeIn();
//       },
//     );
//   }
// }

// class _OwnedPackRow extends StatelessWidget {
//   const _OwnedPackRow({
//     required this.pack,
//     required this.dlState,
//     required this.purchase,
//     required this.onTap,
//     required this.onDownload,
//     required this.onDelete,
//   });

//   final PackEntity pack;
//   final PackDownloadState dlState;
//   final PackPurchase? purchase;
//   final VoidCallback onTap;
//   final VoidCallback onDownload;
//   final VoidCallback onDelete;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;

//     return JCard(
//       onTap: onTap,
//       padding: const EdgeInsets.all(12),
//       child: Row(
//         children: [
//           // Cover
//           ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: SizedBox(
//               width: 64,
//               height: 64,
//               child: pack.coverImageUrl != null
//                   ? Image.network(pack.coverImageUrl!, fit: BoxFit.cover)
//                   : Container(
//                       color: theme.colorScheme.surfaceContainerHighest,
//                       child: Center(
//                         child: Text(
//                           _emoji(pack.gameType),
//                           style: const TextStyle(fontSize: 28),
//                         ),
//                       ),
//                     ),
//             ),
//           ),
//           const SizedBox(width: 12),

//           // Info
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   pack.titleFor('en'),
//                   style: theme.textTheme.titleSmall?.copyWith(
//                     fontWeight: FontWeight.w700,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 3),
//                 if (purchase != null)
//                   Text(
//                     purchase!.daysRemaining > 0
//                         ? 'Expires in ${purchase!.daysRemaining}d'
//                         : 'Expired',
//                     style: theme.textTheme.bodySmall?.copyWith(
//                       color: purchase!.daysRemaining > 7
//                           ? theme.colorScheme.onSurfaceVariant
//                           : AppColors.warningAmber,
//                     ),
//                   ),
//                 const SizedBox(height: 4),
//                 Text(
//                   '${pack.cardCount} cards',
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: theme.colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Download button
//           PackDownloadButton(
//             packId: pack.id,
//             state: dlState,
//             compact: true,
//             onDownload: onDownload,
//             onDelete: onDelete,
//           ),
//         ],
//       ),
//     );
//   }

//   String _emoji(String gameType) => switch (gameType) {
//     'truth_or_dare' => '🎯',
//     'never_have_i_ever' => '🍹',
//     'meme_game' => '😂',
//     _ => '🎮',
//   };
// }

// class _OfflinePackRow extends StatelessWidget {
//   const _OfflinePackRow({
//     required this.pack,
//     required this.dlState,
//     required this.onDelete,
//   });

//   final PackEntity pack;
//   final PackDownloadState dlState;
//   final VoidCallback onDelete;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;

//     return JCard(
//       padding: const EdgeInsets.all(12),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: AppColors.successGreen.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Icon(
//               Icons.offline_pin_rounded,
//               color: AppColors.successGreen,
//               size: 22,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   pack.titleFor('en'),
//                   style: theme.textTheme.titleSmall?.copyWith(
//                     fontWeight: FontWeight.w600,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 Text(
//                   '${pack.cardCount} cards • Available offline',
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: AppColors.successGreen,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.delete_outline_rounded, size: 20),
//             onPressed: () async {
//               final ok = await showDialog<bool>(
//                 context: context,
//                 builder: (ctx) => AlertDialog(
//                   title: const Text('Remove download?'),
//                   content: Text(
//                     'This will remove the offline copy of "${pack.titleFor("en")}". You can re-download it later.',
//                   ),
//                   actions: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(ctx, false),
//                       child: const Text('Cancel'),
//                     ),
//                     TextButton(
//                       onPressed: () => Navigator.pop(ctx, true),
//                       style: TextButton.styleFrom(
//                         foregroundColor: AppColors.errorRed,
//                       ),
//                       child: const Text('Remove'),
//                     ),
//                   ],
//                 ),
//               );
//               if (ok == true) onDelete();
//             },
//             color: theme.colorScheme.error,
//           ),
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
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../domain/pack_entity.dart';
import '../pack_provider.dart';
import '../widgets/pack_card_widget.dart';
import '../widgets/pack_download_button.dart';

class MyPacksScreen extends StatelessWidget {
  const MyPacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Purchased'),
              Tab(text: 'Downloaded'),
            ],
          ),
          Expanded(
            child: Consumer<PackProvider>(
              builder: (ctx, packs, _) {
                return TabBarView(
                  children: [
                    _PurchasedList(packs: packs),
                    _DownloadedList(packs: packs),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchasedList extends StatelessWidget {
  const _PurchasedList({required this.packs});
  final PackProvider packs;

  @override
  Widget build(BuildContext context) {
    final purchased = packs.purchasedPacks;

    if (purchased.isEmpty && !packs.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🛒', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'No purchased packs',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse the marketplace to find packs.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: purchased.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final pack = purchased[i];
        final dlState = packs.downloadStateFor(pack.id);
        final purchase = packs.purchaseFor(pack.id);

        return _OwnedPackRow(
          pack: pack,
          dlState: dlState,
          purchase: purchase,
          onTap: () =>
              context.push('${RouteNames.marketplace}/pack/${pack.id}'),
          onDownload: () async {
            final isPremium =
                context.read<AuthProvider>().currentUser?.isPremiumActive ??
                false;
            if (packs.isAtDownloadLimit(isPremium: isPremium)) {
              final limit = packs.downloadLimitFor(isPremium: isPremium);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isPremium
                        ? 'Offline limit reached ($limit packs). Delete one to download another.'
                        : 'Free plan allows 1 offline pack. Upgrade to Premium for 10.',
                  ),
                  behavior: SnackBarBehavior.fixed,
                ),
              );
              return;
            }
            await packs.downloadPack(pack, isPremium: isPremium);
          },
          onDelete: () => packs.deletePack(pack.id),
        ).animate(delay: (i * 35).ms).fadeIn().slideX(begin: 0.04, end: 0);
      },
    );
  }
}

class _DownloadedList extends StatelessWidget {
  const _DownloadedList({required this.packs});
  final PackProvider packs;

  @override
  Widget build(BuildContext context) {
    final allKnownPacks = {
      for (final p in [
        ...packs.purchasedPacks,
        ...packs.browsePacks,
        ...packs.featuredPacks,
        ...packs.localPacks,
      ])
        p.id: p,
    };
    final downloaded = packs.allDownloadedPackIds
        .map((id) => allKnownPacks[id])
        .whereType<PackEntity>()
        .toList();

    if (downloaded.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📥', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'No offline packs',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Download packs to play without internet.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: downloaded.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final pack = downloaded[i];
        final dlState = packs.downloadStateFor(pack.id);
        return _OfflinePackRow(
          pack: pack,
          dlState: dlState,
          onDelete: () => packs.deletePack(pack.id),
        ).animate(delay: (i * 30).ms).fadeIn();
      },
    );
  }
}

class _OwnedPackRow extends StatelessWidget {
  const _OwnedPackRow({
    required this.pack,
    required this.dlState,
    required this.purchase,
    required this.onTap,
    required this.onDownload,
    required this.onDelete,
  });

  final PackEntity pack;
  final PackDownloadState dlState;
  final PackPurchase? purchase;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return JCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: pack.coverImageUrl != null
                  ? Image.network(pack.coverImageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Text(
                          _emoji(pack.gameType),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pack.titleFor('en'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                if (purchase != null)
                  Text(
                    purchase!.daysRemaining > 0
                        ? 'Expires in ${purchase!.daysRemaining}d'
                        : 'Expired',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: purchase!.daysRemaining > 7
                          ? theme.colorScheme.onSurfaceVariant
                          : AppColors.warningAmber,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${pack.cardCount} cards',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          PackDownloadButton(
            packId: pack.id,
            state: dlState,
            compact: true,
            onDownload: onDownload,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }

  String _emoji(String gameType) => switch (gameType) {
    'truth_or_dare' => '🎯',
    'never_have_i_ever' => '🍹',
    'meme_game' => '😂',
    _ => '🎮',
  };
}

class _OfflinePackRow extends StatelessWidget {
  const _OfflinePackRow({
    required this.pack,
    required this.dlState,
    required this.onDelete,
  });

  final PackEntity pack;
  final PackDownloadState dlState;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return JCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.offline_pin_rounded,
              color: AppColors.successGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pack.titleFor('en'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${pack.cardCount} cards • Available offline',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove download?'),
                  content: Text(
                    'This will remove the offline copy of "${pack.titleFor("en")}". You can re-download it later.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                      ),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );
              if (ok == true) onDelete();
            },
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }
}
