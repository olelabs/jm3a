// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_animate/flutter_animate.dart';
// // // import 'package:go_router/go_router.dart';

// // // import '../../../../core/router/route_names.dart';
// // // import 'package:provider/provider.dart';

// // // import '../../../../core/extensions/context_ext.dart';
// // // import '../../../../core/services/image_cache_service.dart';
// // // import '../../../../core/theme/app_colors.dart';
// // // import '../../../../shared/widgets/buttons/j_button.dart';
// // // import '../../../../shared/widgets/cards/user_avatar.dart';
// // // import '../../../../shared/widgets/feedback/error_view.dart';
// // // import '../../../../shared/widgets/overlays/loading_overlay.dart';
// // // import '../../data/pack_repository.dart';
// // // import '../../domain/pack_entity.dart';
// // // import '../pack_provider.dart';
// // // import '../widgets/pack_download_button.dart';
// // // // import '../widgets/pack_rating_widget.dart';
// // // import '../widgets/report_pack_sheet.dart';
// // // import '../widgets/review_sheet.dart';

// // // /// Pack detail screen.
// // // /// Fetches full pack detail including tags and creator info.
// // // class PackDetailScreen extends StatefulWidget {
// // //   const PackDetailScreen({super.key, required this.packId});
// // //   final String packId;

// // //   @override
// // //   State<PackDetailScreen> createState() => _PackDetailScreenState();
// // // }

// // // class _PackDetailScreenState extends State<PackDetailScreen> {
// // //   PackEntity? _pack;
// // //   List<PackReview> _reviews = [];
// // //   PackRating? _myRating;
// // //   bool _isLoading = true;
// // //   bool _isPurchasing = false;
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
// // //       final repo = PackRepository.instance;
// // //       final userId = context.read<PackProvider>().currentUserId;

// // //       final results = await Future.wait([
// // //         repo.getPackDetail(widget.packId),
// // //         repo.getPackReviews(widget.packId),
// // //         if (userId != null)
// // //           repo.getMyRating(widget.packId, userId)
// // //         else
// // //           Future.value(null),
// // //       ]);

// // //       if (!mounted) return;
// // //       setState(() {
// // //         _pack = results[0] as PackEntity;
// // //         _reviews = results[1] as List<PackReview>;
// // //         _myRating = results.length > 2 ? results[2] as PackRating? : null;
// // //         _isLoading = false;
// // //       });
// // //     } catch (e) {
// // //       if (mounted)
// // //         setState(() {
// // //           _error = e;
// // //           _isLoading = false;
// // //         });
// // //     }
// // //   }

// // //   Future<void> _purchase() async {
// // //     final pack = _pack;
// // //     if (pack == null) return;

// // //     setState(() => _isPurchasing = true);
// // //     final error = await context.read<PackProvider>().purchasePack(pack);
// // //     if (!mounted) return;
// // //     setState(() => _isPurchasing = false);

// // //     if (error == null) {
// // //       context.showSnackBar('Pack purchased! You can now download it.');
// // //       await _load();
// // //     } else if (error.toLowerCase().contains('insufficient')) {
// // //       // Show friendly top-up prompt
// // //       showDialog(
// // //         context: context,
// // //         builder: (_) => AlertDialog(
// // //           title: const Text('Insufficient Balance'),
// // //           content: Text(
// // //             'You need ${pack.priceMru} MRU to purchase this pack. '
// // //             'Your current balance is too low.',
// // //           ),
// // //           actions: [
// // //             TextButton(
// // //               onPressed: () => Navigator.pop(context),
// // //               child: const Text('Cancel'),
// // //             ),
// // //             FilledButton(
// // //               onPressed: () {
// // //                 Navigator.pop(context);
// // //                 context.push(RouteNames.wallet);
// // //               },
// // //               child: const Text('Top Up Wallet'),
// // //             ),
// // //           ],
// // //         ),
// // //       );
// // //     } else {
// // //       context.showErrorSnackBar('Purchase failed: $error');
// // //     }
// // //   }

// // //   Future<void> _showReviewSheet() async {
// // //     await showModalBottomSheet(
// // //       context: context,
// // //       isScrollControlled: true,
// // //       backgroundColor: Colors.transparent,
// // //       builder: (_) => ReviewSheet(
// // //         packId: _pack!.id,
// // //         myRating: _myRating?.rating,
// // //         onSubmit: (content, rating) async {
// // //           final ok = await context.read<PackProvider>().submitReview(
// // //             packId: _pack!.id,
// // //             content: content,
// // //             rating: rating,
// // //           );
// // //           if (ok && mounted) {
// // //             context.showSnackBar('Review submitted!');
// // //             _load();
// // //           }
// // //         },
// // //       ),
// // //     );
// // //   }

// // //   Future<void> _showReportSheet() async {
// // //     await showModalBottomSheet(
// // //       context: context,
// // //       isScrollControlled: true,
// // //       backgroundColor: Colors.transparent,
// // //       builder: (_) => ReportPackSheet(
// // //         packId: _pack!.id,
// // //         onSubmit: (reason, details) async {
// // //           final ok = await context.read<PackProvider>().reportPack(
// // //             packId: _pack!.id,
// // //             reason: reason,
// // //             details: details,
// // //           );
// // //           if (ok && mounted) context.showSnackBar('Report submitted.');
// // //         },
// // //       ),
// // //     );
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     if (_isLoading) {
// // //       return const Scaffold(body: Center(child: CircularProgressIndicator()));
// // //     }
// // //     if (_error != null || _pack == null) {
// // //       return Scaffold(
// // //         appBar: AppBar(),
// // //         body: ErrorView(message: 'Pack not found.', onRetry: _load),
// // //       );
// // //     }

// // //     final pack = _pack!;
// // //     final packs = context.watch<PackProvider>();
// // //     final isOwned = packs.isOwned(pack);
// // //     final dlState = packs.downloadStateFor(pack.id);
// // //     final purchase = packs.purchaseFor(pack.id);
// // //     final theme = context.theme;

// // //     return LoadingOverlay(
// // //       isLoading: _isPurchasing,
// // //       message: 'Processing…',
// // //       child: Scaffold(
// // //         body: CustomScrollView(
// // //           slivers: [
// // //             // ── Hero header ────────────────────────────────────────────────
// // //             SliverAppBar(
// // //               expandedHeight: 260,
// // //               pinned: true,
// // //               actions: [
// // //                 IconButton(
// // //                   icon: const Icon(Icons.flag_outlined),
// // //                   onPressed: _showReportSheet,
// // //                   tooltip: 'Report',
// // //                 ),
// // //               ],
// // //               flexibleSpace: FlexibleSpaceBar(
// // //                 background: pack.coverImageUrl != null
// // //                     ? Image.network(
// // //                         pack.coverImageUrl!,
// // //                         fit: BoxFit.cover,
// // //                         color: Colors.black.withOpacity(0.2),
// // //                         colorBlendMode: BlendMode.darken,
// // //                       )
// // //                     : Container(
// // //                         color: theme.colorScheme.surfaceContainerHighest,
// // //                         child: Center(
// // //                           child: Text(switch (pack.gameType) {
// // //                             'truth_or_dare' => '🎯',
// // //                             _ => '🎮',
// // //                           }, style: const TextStyle(fontSize: 80)),
// // //                         ),
// // //                       ),
// // //               ),
// // //             ),

// // //             SliverPadding(
// // //               padding: const EdgeInsets.all(20),
// // //               sliver: SliverList(
// // //                 delegate: SliverChildListDelegate([
// // //                   // ── Title + badges ──────────────────────────────────────
// // //                   Row(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     children: [
// // //                       Expanded(
// // //                         child: Text(
// // //                           pack.titleFor('en'),
// // //                           style: theme.textTheme.headlineSmall?.copyWith(
// // //                             fontWeight: FontWeight.w800,
// // //                           ),
// // //                         ).animate().fadeIn().slideY(begin: 0.05, end: 0),
// // //                       ),
// // //                       if (pack.hasSpicy)
// // //                         const Padding(
// // //                           padding: EdgeInsets.only(left: 8, top: 4),
// // //                           child: Text('🌶', style: TextStyle(fontSize: 24)),
// // //                         ),
// // //                     ],
// // //                   ),
// // //                   const SizedBox(height: 12),

// // //                   // ── Stats row ───────────────────────────────────────────
// // //                   Row(
// // //                     children: [
// // //                       _StatChip(
// // //                         icon: Icons.layers_rounded,
// // //                         label: '${pack.cardCount} cards',
// // //                       ),
// // //                       const SizedBox(width: 8),
// // //                       if (pack.avgRating > 0)
// // //                         _StatChip(
// // //                           icon: Icons.star_rounded,
// // //                           label: pack.avgRating.toStringAsFixed(1),
// // //                           color: AppColors.amberOrangeLight,
// // //                         ),
// // //                       const SizedBox(width: 8),
// // //                       _StatChip(
// // //                         icon: Icons.people_outline_rounded,
// // //                         label: '${pack.totalPurchases}',
// // //                       ),
// // //                     ],
// // //                   ).animate(delay: 60.ms).fadeIn(),

// // //                   const SizedBox(height: 16),

// // //                   // ── Creator ─────────────────────────────────────────────
// // //                   _CreatorRow(pack: pack),

// // //                   const SizedBox(height: 16),

// // //                   // ── Description ─────────────────────────────────────────
// // //                   if (pack.descriptionFor('en').isNotEmpty) ...[
// // //                     Text(
// // //                       pack.descriptionFor('en'),
// // //                       style: theme.textTheme.bodyMedium?.copyWith(
// // //                         color: theme.colorScheme.onSurfaceVariant,
// // //                         height: 1.55,
// // //                       ),
// // //                     ),
// // //                     const SizedBox(height: 16),
// // //                   ],

// // //                   // ── Tags ────────────────────────────────────────────────
// // //                   if (pack.tags.isNotEmpty) ...[
// // //                     Wrap(
// // //                       spacing: 8,
// // //                       runSpacing: 8,
// // //                       children: pack.tags
// // //                           .map(
// // //                             (t) => Chip(
// // //                               label: Text('#$t'),
// // //                               visualDensity: VisualDensity.compact,
// // //                               labelStyle: theme.textTheme.labelSmall,
// // //                             ),
// // //                           )
// // //                           .toList(),
// // //                     ),
// // //                     const SizedBox(height: 16),
// // //                   ],

// // //                   // ── Ownership / expiry ──────────────────────────────────
// // //                   if (isOwned && purchase != null) ...[
// // //                     _OwnershipCard(purchase: purchase),
// // //                     const SizedBox(height: 16),
// // //                   ],

// // //                   // ── Primary action ──────────────────────────────────────
// // //                   _PrimaryAction(
// // //                     pack: pack,
// // //                     isOwned: isOwned,
// // //                     dlState: dlState,
// // //                     isPurchasing: _isPurchasing,
// // //                     onPurchase: _purchase,
// // //                     onDownload: () => packs.downloadPack(pack),
// // //                     onDelete: () => packs.deletePack(pack.id),
// // //                   ),

// // //                   const SizedBox(height: 28),
// // //                   const Divider(),
// // //                   const SizedBox(height: 16),

// // //                   // ── Reviews header ──────────────────────────────────────
// // //                   Row(
// // //                     children: [
// // //                       Text(
// // //                         'Reviews',
// // //                         style: theme.textTheme.titleMedium?.copyWith(
// // //                           fontWeight: FontWeight.w700,
// // //                         ),
// // //                       ),
// // //                       const Spacer(),
// // //                       if (isOwned)
// // //                         TextButton.icon(
// // //                           onPressed: _showReviewSheet,
// // //                           icon: const Icon(
// // //                             Icons.rate_review_outlined,
// // //                             size: 16,
// // //                           ),
// // //                           label: const Text('Write review'),
// // //                         ),
// // //                     ],
// // //                   ),

// // //                   const SizedBox(height: 12),

// // //                   // ── Rating stars ────────────────────────────────────────
// // //                   if (isOwned)
// // //                     PackRatingWidget(
// // //                       packId: pack.id,
// // //                       myRating: _myRating?.rating ?? 0,
// // //                       onRated: (r) async {
// // //                         await context.read<PackProvider>().ratePack(pack.id, r);
// // //                         await _load();
// // //                       },
// // //                     ),

// // //                   const SizedBox(height: 16),

// // //                   // ── Review list ─────────────────────────────────────────
// // //                   ..._reviews.asMap().entries.map(
// // //                     (e) => _ReviewTile(
// // //                       review: e.value,
// // //                     ).animate(delay: (e.key * 40).ms).fadeIn(),
// // //                   ),

// // //                   if (_reviews.isEmpty)
// // //                     Padding(
// // //                       padding: const EdgeInsets.symmetric(vertical: 16),
// // //                       child: Center(
// // //                         child: Text(
// // //                           'No reviews yet. Be the first!',
// // //                           style: theme.textTheme.bodyMedium?.copyWith(
// // //                             color: theme.colorScheme.onSurfaceVariant,
// // //                           ),
// // //                         ),
// // //                       ),
// // //                     ),

// // //                   const SizedBox(height: 48),
// // //                 ]),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ── Sub-widgets ───────────────────────────────────────────────────────────────

// // // class _StatChip extends StatelessWidget {
// // //   const _StatChip({required this.icon, required this.label, this.color});
// // //   final IconData icon;
// // //   final String label;
// // //   final Color? color;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final effectiveColor = color ?? context.colorScheme.onSurfaceVariant;
// // //     return Container(
// // //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
// // //       decoration: BoxDecoration(
// // //         color: effectiveColor.withOpacity(0.1),
// // //         borderRadius: BorderRadius.circular(20),
// // //       ),
// // //       child: Row(
// // //         mainAxisSize: MainAxisSize.min,
// // //         children: [
// // //           Icon(icon, size: 13, color: effectiveColor),
// // //           const SizedBox(width: 4),
// // //           Text(
// // //             label,
// // //             style: TextStyle(
// // //               fontSize: 12,
// // //               fontWeight: FontWeight.w600,
// // //               color: effectiveColor,
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _CreatorRow extends StatelessWidget {
// // //   const _CreatorRow({required this.pack});
// // //   final PackEntity pack;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Row(
// // //       children: [
// // //         UserAvatar(
// // //           avatarUrl: pack.creatorAvatarUrl,
// // //           displayName: pack.creatorName,
// // //           size: 32,
// // //         ),
// // //         const SizedBox(width: 10),
// // //         Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             Row(
// // //               children: [
// // //                 Text(
// // //                   pack.creatorName ?? 'Creator',
// // //                   style: context.textTheme.titleSmall?.copyWith(
// // //                     fontWeight: FontWeight.w600,
// // //                   ),
// // //                 ),
// // //                 if (pack.isVerifiedCreator) ...[
// // //                   const SizedBox(width: 4),
// // //                   const Icon(
// // //                     Icons.verified_rounded,
// // //                     size: 14,
// // //                     color: AppColors.infoBlue,
// // //                   ),
// // //                 ],
// // //               ],
// // //             ),
// // //             Text(
// // //               'Pack creator',
// // //               style: context.textTheme.bodySmall?.copyWith(
// // //                 color: context.colorScheme.onSurfaceVariant,
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // }

// // // class _OwnershipCard extends StatelessWidget {
// // //   const _OwnershipCard({required this.purchase});
// // //   final PackPurchase purchase;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final color = purchase.daysRemaining > 7
// // //         ? AppColors.successGreen
// // //         : AppColors.warningAmber;

// // //     return Container(
// // //       padding: const EdgeInsets.all(14),
// // //       decoration: BoxDecoration(
// // //         color: color.withOpacity(0.08),
// // //         borderRadius: BorderRadius.circular(12),
// // //         border: Border.all(color: color.withOpacity(0.25)),
// // //       ),
// // //       child: Row(
// // //         children: [
// // //           Icon(Icons.check_circle_rounded, color: color, size: 20),
// // //           const SizedBox(width: 10),
// // //           Expanded(
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 Text(
// // //                   'You own this pack',
// // //                   style: TextStyle(
// // //                     color: color,
// // //                     fontWeight: FontWeight.w700,
// // //                     fontSize: 13,
// // //                   ),
// // //                 ),
// // //                 Text(
// // //                   'Expires in ${purchase.daysRemaining} days',
// // //                   style: context.textTheme.bodySmall?.copyWith(
// // //                     color: context.colorScheme.onSurfaceVariant,
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _PrimaryAction extends StatelessWidget {
// // //   const _PrimaryAction({
// // //     required this.pack,
// // //     required this.isOwned,
// // //     required this.dlState,
// // //     required this.isPurchasing,
// // //     required this.onPurchase,
// // //     required this.onDownload,
// // //     required this.onDelete,
// // //   });

// // //   final PackEntity pack;
// // //   final bool isOwned;
// // //   final PackDownloadState dlState;
// // //   final bool isPurchasing;
// // //   final VoidCallback onPurchase;
// // //   final VoidCallback onDownload;
// // //   final VoidCallback onDelete;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     if (!isOwned) {
// // //       return JButton(
// // //         label: pack.isFree ? 'Get Free Pack' : 'Buy for ${pack.priceMru} MRU',
// // //         onPressed: onPurchase,
// // //         isLoading: isPurchasing,
// // //         icon: pack.isFree ? Icons.redeem_rounded : Icons.shopping_cart_rounded,
// // //       );
// // //     }

// // //     return PackDownloadButton(
// // //       packId: pack.id,
// // //       state: dlState,
// // //       onDownload: onDownload,
// // //       onDelete: onDelete,
// // //     );
// // //   }
// // // }

// // // class _ReviewTile extends StatelessWidget {
// // //   const _ReviewTile({required this.review});
// // //   final PackReview review;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;
// // //     return Padding(
// // //       padding: const EdgeInsets.only(bottom: 14),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Row(
// // //             children: [
// // //               UserAvatar(
// // //                 avatarUrl: review.authorAvatarUrl,
// // //                 displayName: review.authorName,
// // //                 size: 28,
// // //               ),
// // //               const SizedBox(width: 8),
// // //               Expanded(
// // //                 child: Text(
// // //                   review.authorName ?? 'Player',
// // //                   style: theme.textTheme.titleSmall?.copyWith(
// // //                     fontWeight: FontWeight.w600,
// // //                   ),
// // //                 ),
// // //               ),
// // //               if (review.rating != null)
// // //                 Row(
// // //                   mainAxisSize: MainAxisSize.min,
// // //                   children: List.generate(
// // //                     5,
// // //                     (i) => Icon(
// // //                       i < review.rating!
// // //                           ? Icons.star_rounded
// // //                           : Icons.star_outline_rounded,
// // //                       size: 14,
// // //                       color: AppColors.amberOrangeLight,
// // //                     ),
// // //                   ),
// // //                 ),
// // //             ],
// // //           ),
// // //           const SizedBox(height: 6),
// // //           Text(
// // //             review.content,
// // //             style: theme.textTheme.bodyMedium?.copyWith(
// // //               color: theme.colorScheme.onSurfaceVariant,
// // //               height: 1.5,
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import 'package:go_router/go_router.dart';

// // import '../../../../core/router/route_names.dart';
// // import 'package:provider/provider.dart';

// // import '../../../../core/extensions/context_ext.dart';
// // import '../../../../core/services/image_cache_service.dart';
// // import '../../../../core/theme/app_colors.dart';
// // import '../../../../shared/widgets/buttons/j_button.dart';
// // import '../../../../shared/widgets/cards/user_avatar.dart';
// // import '../../../../shared/widgets/feedback/error_view.dart';
// // import '../../../../shared/widgets/overlays/loading_overlay.dart';
// // import '../../data/pack_repository.dart';
// // import '../../domain/pack_entity.dart';
// // import '../pack_provider.dart';
// // import '../widgets/pack_download_button.dart';
// // import '../widgets/report_pack_sheet.dart';
// // import '../widgets/review_sheet.dart';

// // class PackDetailScreen extends StatefulWidget {
// //   const PackDetailScreen({super.key, required this.packId});
// //   final String packId;

// //   @override
// //   State<PackDetailScreen> createState() => _PackDetailScreenState();
// // }

// // class _PackDetailScreenState extends State<PackDetailScreen> {
// //   PackEntity? _pack;
// //   List<PackReview> _reviews = [];
// //   PackRating? _myRating;
// //   bool _isLoading = true;
// //   bool _isPurchasing = false;
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
// //       final repo = PackRepository.instance;
// //       final userId = context.read<PackProvider>().currentUserId;

// //       final results = await Future.wait([
// //         repo.getPackDetail(widget.packId),
// //         repo.getPackReviews(widget.packId),
// //         if (userId != null)
// //           repo.getMyRating(widget.packId, userId)
// //         else
// //           Future.value(null),
// //       ]);

// //       if (!mounted) return;
// //       setState(() {
// //         _pack = results[0] as PackEntity;
// //         _reviews = results[1] as List<PackReview>;
// //         _myRating = results.length > 2 ? results[2] as PackRating? : null;
// //         _isLoading = false;
// //       });
// //     } catch (e) {
// //       if (mounted)
// //         setState(() {
// //           _error = e;
// //           _isLoading = false;
// //         });
// //     }
// //   }

// //   Future<void> _purchase() async {
// //     final pack = _pack;
// //     if (pack == null) return;

// //     setState(() => _isPurchasing = true);
// //     final error = await context.read<PackProvider>().purchasePack(pack);
// //     if (!mounted) return;
// //     setState(() => _isPurchasing = false);

// //     if (error == null) {
// //       context.showSnackBar('Pack purchased! You can now download it.');
// //       await _load();
// //     } else if (error.toLowerCase().contains('insufficient')) {
// //       showDialog(
// //         context: context,
// //         builder: (_) => AlertDialog(
// //           title: const Text('Insufficient Balance'),
// //           content: Text(
// //             'You need ${pack.priceMru} MRU to purchase this pack. '
// //             'Your current balance is too low.',
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.pop(context),
// //               child: const Text('Cancel'),
// //             ),
// //             FilledButton(
// //               onPressed: () {
// //                 Navigator.pop(context);
// //                 context.push(RouteNames.wallet);
// //               },
// //               child: const Text('Top Up Wallet'),
// //             ),
// //           ],
// //         ),
// //       );
// //     } else {
// //       context.showErrorSnackBar('Purchase failed: $error');
// //     }
// //   }

// //   Future<void> _showReviewSheet() async {
// //     await showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder: (_) => ReviewSheet(
// //         packId: _pack!.id,
// //         myRating: _myRating?.rating,
// //         onSubmit: (content, rating) async {
// //           final ok = await context.read<PackProvider>().submitReview(
// //             packId: _pack!.id,
// //             content: content,
// //             rating: rating,
// //           );
// //           if (ok && mounted) {
// //             if (rating != null) {
// //               setState(() {
// //                 _myRating = PackRating(
// //                   packId: _pack!.id,
// //                   userId: context.read<PackProvider>().currentUserId ?? '',
// //                   rating: rating,
// //                 );
// //               });
// //             }
// //             context.showSnackBar('Review submitted!');
// //             _load();
// //           }
// //         },
// //       ),
// //     );
// //   }

// //   Future<void> _showReportSheet() async {
// //     await showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder: (_) => ReportPackSheet(
// //         packId: _pack!.id,
// //         onSubmit: (reason, details) async {
// //           final ok = await context.read<PackProvider>().reportPack(
// //             packId: _pack!.id,
// //             reason: reason,
// //             details: details,
// //           );
// //           if (ok && mounted) context.showSnackBar('Report submitted.');
// //         },
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (_isLoading) {
// //       return const Scaffold(body: Center(child: CircularProgressIndicator()));
// //     }
// //     if (_error != null || _pack == null) {
// //       return Scaffold(
// //         appBar: AppBar(),
// //         body: ErrorView(message: 'Pack not found.', onRetry: _load),
// //       );
// //     }

// //     final pack = _pack!;
// //     final packs = context.watch<PackProvider>();
// //     final isOwned = packs.isOwned(pack);
// //     final dlState = packs.downloadStateFor(pack.id);
// //     final purchase = packs.purchaseFor(pack.id);
// //     final theme = context.theme;

// //     return LoadingOverlay(
// //       isLoading: _isPurchasing,
// //       message: 'Processing…',
// //       child: Scaffold(
// //         body: CustomScrollView(
// //           slivers: [
// //             SliverAppBar(
// //               expandedHeight: 260,
// //               pinned: true,
// //               actions: [
// //                 IconButton(
// //                   icon: const Icon(Icons.flag_outlined),
// //                   onPressed: _showReportSheet,
// //                   tooltip: 'Report',
// //                 ),
// //               ],
// //               flexibleSpace: FlexibleSpaceBar(
// //                 background: pack.coverImageUrl != null
// //                     ? Image.network(
// //                         pack.coverImageUrl!,
// //                         fit: BoxFit.cover,
// //                         color: Colors.black.withOpacity(0.2),
// //                         colorBlendMode: BlendMode.darken,
// //                       )
// //                     : Container(
// //                         color: theme.colorScheme.surfaceContainerHighest,
// //                         child: Center(
// //                           child: Text(switch (pack.gameType) {
// //                             'truth_or_dare' => '🎯',
// //                             _ => '🎮',
// //                           }, style: const TextStyle(fontSize: 80)),
// //                         ),
// //                       ),
// //               ),
// //             ),

// //             SliverPadding(
// //               padding: const EdgeInsets.all(20),
// //               sliver: SliverList(
// //                 delegate: SliverChildListDelegate([
// //                   Row(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Expanded(
// //                         child: Text(
// //                           pack.titleFor('en'),
// //                           style: theme.textTheme.headlineSmall?.copyWith(
// //                             fontWeight: FontWeight.w800,
// //                           ),
// //                         ).animate().fadeIn().slideY(begin: 0.05, end: 0),
// //                       ),
// //                       if (pack.hasSpicy)
// //                         const Padding(
// //                           padding: EdgeInsets.only(left: 8, top: 4),
// //                           child: Text('🌶', style: TextStyle(fontSize: 24)),
// //                         ),
// //                     ],
// //                   ),
// //                   const SizedBox(height: 12),

// //                   Row(
// //                     children: [
// //                       _StatChip(
// //                         icon: Icons.layers_rounded,
// //                         label: '${pack.cardCount} cards',
// //                       ),
// //                       const SizedBox(width: 8),
// //                       if (pack.avgRating > 0)
// //                         _StatChip(
// //                           icon: Icons.star_rounded,
// //                           label: pack.avgRating.toStringAsFixed(1),
// //                           color: AppColors.amberOrangeLight,
// //                         ),
// //                       const SizedBox(width: 8),
// //                       _StatChip(
// //                         icon: Icons.people_outline_rounded,
// //                         label: '${pack.totalPurchases}',
// //                       ),
// //                     ],
// //                   ).animate(delay: 60.ms).fadeIn(),

// //                   const SizedBox(height: 16),

// //                   _CreatorRow(pack: pack),

// //                   const SizedBox(height: 16),

// //                   if (pack.descriptionFor('en').isNotEmpty) ...[
// //                     Text(
// //                       pack.descriptionFor('en'),
// //                       style: theme.textTheme.bodyMedium?.copyWith(
// //                         color: theme.colorScheme.onSurfaceVariant,
// //                         height: 1.55,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 16),
// //                   ],

// //                   if (pack.tags.isNotEmpty) ...[
// //                     Wrap(
// //                       spacing: 8,
// //                       runSpacing: 8,
// //                       children: pack.tags
// //                           .map(
// //                             (t) => Chip(
// //                               label: Text('#$t'),
// //                               visualDensity: VisualDensity.compact,
// //                               labelStyle: theme.textTheme.labelSmall,
// //                             ),
// //                           )
// //                           .toList(),
// //                     ),
// //                     const SizedBox(height: 16),
// //                   ],

// //                   if (isOwned && purchase != null) ...[
// //                     _OwnershipCard(purchase: purchase),
// //                     const SizedBox(height: 16),
// //                   ],

// //                   _PrimaryAction(
// //                     pack: pack,
// //                     isOwned: isOwned,
// //                     dlState: dlState,
// //                     isPurchasing: _isPurchasing,
// //                     onPurchase: _purchase,
// //                     onDownload: () => packs.downloadPack(pack),
// //                     onDelete: () => packs.deletePack(pack.id),
// //                   ),

// //                   const SizedBox(height: 28),
// //                   const Divider(),
// //                   const SizedBox(height: 16),

// //                   Row(
// //                     children: [
// //                       Text(
// //                         'Reviews',
// //                         style: theme.textTheme.titleMedium?.copyWith(
// //                           fontWeight: FontWeight.w700,
// //                         ),
// //                       ),
// //                       const Spacer(),
// //                       if (isOwned)
// //                         TextButton.icon(
// //                           onPressed: _showReviewSheet,
// //                           icon: const Icon(
// //                             Icons.rate_review_outlined,
// //                             size: 16,
// //                           ),
// //                           label: const Text('Write review'),
// //                         ),
// //                     ],
// //                   ),

// //                   const SizedBox(height: 12),

// //                   if (isOwned)
// //                     PackRatingWidget(
// //                       packId: pack.id,
// //                       myRating: _myRating?.rating ?? 0,
// //                       onRated: (r) async {
// //                         final ok = await context.read<PackProvider>().ratePack(
// //                           pack.id,
// //                           r,
// //                         );
// //                         if (ok && mounted) {
// //                           setState(() {
// //                             _myRating = PackRating(
// //                               packId: pack.id,
// //                               userId:
// //                                   context.read<PackProvider>().currentUserId ??
// //                                   '',
// //                               rating: r,
// //                             );
// //                           });
// //                           _load();
// //                         }
// //                       },
// //                     ),

// //                   const SizedBox(height: 16),

// //                   ..._reviews.asMap().entries.map(
// //                     (e) => _ReviewTile(
// //                       review: e.value,
// //                     ).animate(delay: (e.key * 40).ms).fadeIn(),
// //                   ),

// //                   if (_reviews.isEmpty)
// //                     Padding(
// //                       padding: const EdgeInsets.symmetric(vertical: 16),
// //                       child: Center(
// //                         child: Text(
// //                           'No reviews yet. Be the first!',
// //                           style: theme.textTheme.bodyMedium?.copyWith(
// //                             color: theme.colorScheme.onSurfaceVariant,
// //                           ),
// //                         ),
// //                       ),
// //                     ),

// //                   const SizedBox(height: 48),
// //                 ]),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class _StatChip extends StatelessWidget {
// //   const _StatChip({required this.icon, required this.label, this.color});
// //   final IconData icon;
// //   final String label;
// //   final Color? color;

// //   @override
// //   Widget build(BuildContext context) {
// //     final effectiveColor = color ?? context.colorScheme.onSurfaceVariant;
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
// //       decoration: BoxDecoration(
// //         color: effectiveColor.withOpacity(0.1),
// //         borderRadius: BorderRadius.circular(20),
// //       ),
// //       child: Row(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           Icon(icon, size: 13, color: effectiveColor),
// //           const SizedBox(width: 4),
// //           Text(
// //             label,
// //             style: TextStyle(
// //               fontSize: 12,
// //               fontWeight: FontWeight.w600,
// //               color: effectiveColor,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _CreatorRow extends StatelessWidget {
// //   const _CreatorRow({required this.pack});
// //   final PackEntity pack;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Row(
// //       children: [
// //         UserAvatar(
// //           avatarUrl: pack.creatorAvatarUrl,
// //           displayName: pack.creatorName,
// //           size: 32,
// //         ),
// //         const SizedBox(width: 10),
// //         Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Row(
// //               children: [
// //                 Text(
// //                   pack.creatorName ?? 'Creator',
// //                   style: context.textTheme.titleSmall?.copyWith(
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //                 if (pack.isVerifiedCreator) ...[
// //                   const SizedBox(width: 4),
// //                   const Icon(
// //                     Icons.verified_rounded,
// //                     size: 14,
// //                     color: AppColors.infoBlue,
// //                   ),
// //                 ],
// //               ],
// //             ),
// //             Text(
// //               'Pack creator',
// //               style: context.textTheme.bodySmall?.copyWith(
// //                 color: context.colorScheme.onSurfaceVariant,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ],
// //     );
// //   }
// // }

// // class _OwnershipCard extends StatelessWidget {
// //   const _OwnershipCard({required this.purchase});
// //   final PackPurchase purchase;

// //   @override
// //   Widget build(BuildContext context) {
// //     final color = purchase.daysRemaining > 7
// //         ? AppColors.successGreen
// //         : AppColors.warningAmber;

// //     return Container(
// //       padding: const EdgeInsets.all(14),
// //       decoration: BoxDecoration(
// //         color: color.withOpacity(0.08),
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: color.withOpacity(0.25)),
// //       ),
// //       child: Row(
// //         children: [
// //           Icon(Icons.check_circle_rounded, color: color, size: 20),
// //           const SizedBox(width: 10),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   'You own this pack',
// //                   style: TextStyle(
// //                     color: color,
// //                     fontWeight: FontWeight.w700,
// //                     fontSize: 13,
// //                   ),
// //                 ),
// //                 Text(
// //                   'Expires in ${purchase.daysRemaining} days',
// //                   style: context.textTheme.bodySmall?.copyWith(
// //                     color: context.colorScheme.onSurfaceVariant,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _PrimaryAction extends StatelessWidget {
// //   const _PrimaryAction({
// //     required this.pack,
// //     required this.isOwned,
// //     required this.dlState,
// //     required this.isPurchasing,
// //     required this.onPurchase,
// //     required this.onDownload,
// //     required this.onDelete,
// //   });

// //   final PackEntity pack;
// //   final bool isOwned;
// //   final PackDownloadState dlState;
// //   final bool isPurchasing;
// //   final VoidCallback onPurchase;
// //   final VoidCallback onDownload;
// //   final VoidCallback onDelete;

// //   @override
// //   Widget build(BuildContext context) {
// //     if (!isOwned) {
// //       return JButton(
// //         label: pack.isFree ? 'Get Free Pack' : 'Buy for ${pack.priceMru} MRU',
// //         onPressed: onPurchase,
// //         isLoading: isPurchasing,
// //         icon: pack.isFree ? Icons.redeem_rounded : Icons.shopping_cart_rounded,
// //       );
// //     }

// //     return PackDownloadButton(
// //       packId: pack.id,
// //       state: dlState,
// //       onDownload: onDownload,
// //       onDelete: onDelete,
// //     );
// //   }
// // }

// // class _ReviewTile extends StatelessWidget {
// //   const _ReviewTile({required this.review});
// //   final PackReview review;

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 14),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               UserAvatar(
// //                 avatarUrl: review.authorAvatarUrl,
// //                 displayName: review.authorName,
// //                 size: 28,
// //               ),
// //               const SizedBox(width: 8),
// //               Expanded(
// //                 child: Text(
// //                   review.authorName ?? 'Player',
// //                   style: theme.textTheme.titleSmall?.copyWith(
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //               ),
// //               if (review.rating != null)
// //                 Row(
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: List.generate(
// //                     5,
// //                     (i) => Icon(
// //                       i < review.rating!
// //                           ? Icons.star_rounded
// //                           : Icons.star_outline_rounded,
// //                       size: 14,
// //                       color: AppColors.amberOrangeLight,
// //                     ),
// //                   ),
// //                 ),
// //             ],
// //           ),
// //           const SizedBox(height: 6),
// //           Text(
// //             review.content,
// //             style: theme.textTheme.bodyMedium?.copyWith(
// //               color: theme.colorScheme.onSurfaceVariant,
// //               height: 1.5,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';

// import '../../../../core/providers/auth_provider.dart';
// import '../../../../core/router/route_names.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/services/image_cache_service.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/buttons/j_button.dart';
// import '../../../../shared/widgets/cards/user_avatar.dart';
// import '../../../../shared/widgets/feedback/error_view.dart';
// import '../../../../shared/widgets/overlays/loading_overlay.dart';
// import '../../data/pack_repository.dart';
// import '../../domain/pack_entity.dart';
// import '../pack_provider.dart';
// import '../widgets/pack_download_button.dart';
// // import '../widgets/pack_rating_widget.dart';
// import '../widgets/report_pack_sheet.dart';
// import '../widgets/review_sheet.dart';

// /// Pack detail screen.
// /// Fetches full pack detail including tags and creator info.
// class PackDetailScreen extends StatefulWidget {
//   const PackDetailScreen({super.key, required this.packId});
//   final String packId;

//   @override
//   State<PackDetailScreen> createState() => _PackDetailScreenState();
// }

// class _PackDetailScreenState extends State<PackDetailScreen> {
//   PackEntity? _pack;
//   List<PackReview> _reviews = [];
//   PackRating? _myRating;
//   bool _isLoading = true;
//   bool _isPurchasing = false;
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
//       final repo = PackRepository.instance;
//       final userId = context.read<PackProvider>().currentUserId;

//       final results = await Future.wait([
//         repo.getPackDetail(widget.packId),
//         repo.getPackReviews(widget.packId),
//         if (userId != null)
//           repo.getMyRating(widget.packId, userId)
//         else
//           Future.value(null),
//       ]);

//       if (!mounted) return;
//       setState(() {
//         _pack = results[0] as PackEntity;
//         _reviews = results[1] as List<PackReview>;
//         _myRating = results.length > 2 ? results[2] as PackRating? : null;
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (mounted)
//         setState(() {
//           _error = e;
//           _isLoading = false;
//         });
//     }
//   }

//   Future<void> _purchase() async {
//     final pack = _pack;
//     if (pack == null) return;

//     setState(() => _isPurchasing = true);
//     final error = await context.read<PackProvider>().purchasePack(pack);
//     if (!mounted) return;
//     setState(() => _isPurchasing = false);

//     if (error == null) {
//       context.showSnackBar('Pack purchased! You can now download it.');
//       await _load();
//     } else if (error.toLowerCase().contains('insufficient')) {
//       // Show friendly top-up prompt
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text('Insufficient Balance'),
//           content: Text(
//             'You need ${pack.priceMru} MRU to purchase this pack. '
//             'Your current balance is too low.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             FilledButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 context.push(RouteNames.wallet);
//               },
//               child: const Text('Top Up Wallet'),
//             ),
//           ],
//         ),
//       );
//     } else {
//       context.showErrorSnackBar('Purchase failed: $error');
//     }
//   }

//   Future<void> _showReviewSheet() async {
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => ReviewSheet(
//         packId: _pack!.id,
//         myRating: _myRating?.rating,
//         onSubmit: (content, rating) async {
//           final ok = await context.read<PackProvider>().submitReview(
//             packId: _pack!.id,
//             content: content,
//             rating: rating,
//           );
//           if (ok && mounted) {
//             context.showSnackBar('Review submitted!');
//             _load();
//           }
//         },
//       ),
//     );
//   }

//   Future<void> _showReportSheet() async {
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => ReportPackSheet(
//         packId: _pack!.id,
//         onSubmit: (reason, details) async {
//           final ok = await context.read<PackProvider>().reportPack(
//             packId: _pack!.id,
//             reason: reason,
//             details: details,
//           );
//           if (ok && mounted) context.showSnackBar('Report submitted.');
//         },
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (_error != null || _pack == null) {
//       return Scaffold(
//         appBar: AppBar(),
//         body: ErrorView(message: 'Pack not found.', onRetry: _load),
//       );
//     }

//     final pack = _pack!;
//     final packs = context.watch<PackProvider>();
//     final isOwned = packs.isOwned(pack);
//     final dlState = packs.downloadStateFor(pack.id);
//     final purchase = packs.purchaseFor(pack.id);
//     final theme = context.theme;

//     return LoadingOverlay(
//       isLoading: _isPurchasing,
//       message: 'Processing…',
//       child: Scaffold(
//         body: CustomScrollView(
//           slivers: [
//             // ── Hero header ────────────────────────────────────────────────
//             SliverAppBar(
//               expandedHeight: 260,
//               pinned: true,
//               actions: [
//                 IconButton(
//                   icon: const Icon(Icons.flag_outlined),
//                   onPressed: _showReportSheet,
//                   tooltip: 'Report',
//                 ),
//               ],
//               flexibleSpace: FlexibleSpaceBar(
//                 background: pack.coverImageUrl != null
//                     ? Image.network(
//                         pack.coverImageUrl!,
//                         fit: BoxFit.cover,
//                         color: Colors.black.withOpacity(0.2),
//                         colorBlendMode: BlendMode.darken,
//                       )
//                     : Container(
//                         color: theme.colorScheme.surfaceContainerHighest,
//                         child: Center(
//                           child: Text(switch (pack.gameType) {
//                             'truth_or_dare' => '🎯',
//                             _ => '🎮',
//                           }, style: const TextStyle(fontSize: 80)),
//                         ),
//                       ),
//               ),
//             ),

//             SliverPadding(
//               padding: const EdgeInsets.all(20),
//               sliver: SliverList(
//                 delegate: SliverChildListDelegate([
//                   // ── Title + badges ──────────────────────────────────────
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           pack.titleFor('en'),
//                           style: theme.textTheme.headlineSmall?.copyWith(
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ).animate().fadeIn().slideY(begin: 0.05, end: 0),
//                       ),
//                       if (pack.hasSpicy)
//                         const Padding(
//                           padding: EdgeInsets.only(left: 8, top: 4),
//                           child: Text('🌶', style: TextStyle(fontSize: 24)),
//                         ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),

//                   // ── Stats row ───────────────────────────────────────────
//                   Row(
//                     children: [
//                       _StatChip(
//                         icon: Icons.layers_rounded,
//                         label: '${pack.cardCount} cards',
//                       ),
//                       const SizedBox(width: 8),
//                       if (pack.avgRating > 0)
//                         _StatChip(
//                           icon: Icons.star_rounded,
//                           label: pack.avgRating.toStringAsFixed(1),
//                           color: AppColors.amberOrangeLight,
//                         ),
//                       const SizedBox(width: 8),
//                       _StatChip(
//                         icon: Icons.people_outline_rounded,
//                         label: '${pack.totalPurchases}',
//                       ),
//                     ],
//                   ).animate(delay: 60.ms).fadeIn(),

//                   const SizedBox(height: 16),

//                   // ── Creator ─────────────────────────────────────────────
//                   _CreatorRow(pack: pack),

//                   const SizedBox(height: 16),

//                   // ── Description ─────────────────────────────────────────
//                   if (pack.descriptionFor('en').isNotEmpty) ...[
//                     Text(
//                       pack.descriptionFor('en'),
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         color: theme.colorScheme.onSurfaceVariant,
//                         height: 1.55,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                   ],

//                   // ── Tags ────────────────────────────────────────────────
//                   if (pack.tags.isNotEmpty) ...[
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: pack.tags
//                           .map(
//                             (t) => Chip(
//                               label: Text('#$t'),
//                               visualDensity: VisualDensity.compact,
//                               labelStyle: theme.textTheme.labelSmall,
//                             ),
//                           )
//                           .toList(),
//                     ),
//                     const SizedBox(height: 16),
//                   ],

//                   // ── Ownership / expiry ──────────────────────────────────
//                   if (isOwned && purchase != null) ...[
//                     _OwnershipCard(purchase: purchase),
//                     const SizedBox(height: 16),
//                   ],

//                   // ── Primary action ──────────────────────────────────────
//                   _PrimaryAction(
//                     pack: pack,
//                     isOwned: isOwned,
//                     dlState: dlState,
//                     isPurchasing: _isPurchasing,
//                     onPurchase: _purchase,
//                     onDownload: () => packs.downloadPack(
//                       pack,
//                       isPremium:
//                           context
//                               .read<AuthProvider>()
//                               .currentUser
//                               ?.isPremiumActive ??
//                           false,
//                     ),
//                     onDelete: () => packs.deletePack(pack.id),
//                   ),

//                   const SizedBox(height: 28),
//                   const Divider(),
//                   const SizedBox(height: 16),

//                   // ── Reviews header ──────────────────────────────────────
//                   Row(
//                     children: [
//                       Text(
//                         'Reviews',
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       const Spacer(),
//                       if (isOwned)
//                         TextButton.icon(
//                           onPressed: _showReviewSheet,
//                           icon: const Icon(
//                             Icons.rate_review_outlined,
//                             size: 16,
//                           ),
//                           label: const Text('Write review'),
//                         ),
//                     ],
//                   ),

//                   const SizedBox(height: 12),

//                   // ── Rating stars ────────────────────────────────────────
//                   if (isOwned)
//                     PackRatingWidget(
//                       packId: pack.id,
//                       myRating: _myRating?.rating ?? 0,
//                       onRated: (r) async {
//                         await context.read<PackProvider>().ratePack(pack.id, r);
//                         await _load();
//                       },
//                     ),

//                   const SizedBox(height: 16),

//                   // ── Review list ─────────────────────────────────────────
//                   ..._reviews.asMap().entries.map(
//                     (e) => _ReviewTile(
//                       review: e.value,
//                     ).animate(delay: (e.key * 40).ms).fadeIn(),
//                   ),

//                   if (_reviews.isEmpty)
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       child: Center(
//                         child: Text(
//                           'No reviews yet. Be the first!',
//                           style: theme.textTheme.bodyMedium?.copyWith(
//                             color: theme.colorScheme.onSurfaceVariant,
//                           ),
//                         ),
//                       ),
//                     ),

//                   const SizedBox(height: 48),
//                 ]),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Sub-widgets ───────────────────────────────────────────────────────────────

// class _StatChip extends StatelessWidget {
//   const _StatChip({required this.icon, required this.label, this.color});
//   final IconData icon;
//   final String label;
//   final Color? color;

//   @override
//   Widget build(BuildContext context) {
//     final effectiveColor = color ?? context.colorScheme.onSurfaceVariant;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: effectiveColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 13, color: effectiveColor),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: effectiveColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CreatorRow extends StatelessWidget {
//   const _CreatorRow({required this.pack});
//   final PackEntity pack;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         UserAvatar(
//           avatarUrl: pack.creatorAvatarUrl,
//           displayName: pack.creatorName,
//           size: 32,
//         ),
//         const SizedBox(width: 10),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Text(
//                   pack.creatorName ?? 'Creator',
//                   style: context.textTheme.titleSmall?.copyWith(
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 if (pack.isVerifiedCreator) ...[
//                   const SizedBox(width: 4),
//                   const Icon(
//                     Icons.verified_rounded,
//                     size: 14,
//                     color: AppColors.infoBlue,
//                   ),
//                 ],
//               ],
//             ),
//             Text(
//               'Pack creator',
//               style: context.textTheme.bodySmall?.copyWith(
//                 color: context.colorScheme.onSurfaceVariant,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// class _OwnershipCard extends StatelessWidget {
//   const _OwnershipCard({required this.purchase});
//   final PackPurchase purchase;

//   @override
//   Widget build(BuildContext context) {
//     final color = purchase.daysRemaining > 7
//         ? AppColors.successGreen
//         : AppColors.warningAmber;

//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.25)),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.check_circle_rounded, color: color, size: 20),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'You own this pack',
//                   style: TextStyle(
//                     color: color,
//                     fontWeight: FontWeight.w700,
//                     fontSize: 13,
//                   ),
//                 ),
//                 Text(
//                   'Expires in ${purchase.daysRemaining} days',
//                   style: context.textTheme.bodySmall?.copyWith(
//                     color: context.colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PrimaryAction extends StatelessWidget {
//   const _PrimaryAction({
//     required this.pack,
//     required this.isOwned,
//     required this.dlState,
//     required this.isPurchasing,
//     required this.onPurchase,
//     required this.onDownload,
//     required this.onDelete,
//   });

//   final PackEntity pack;
//   final bool isOwned;
//   final PackDownloadState dlState;
//   final bool isPurchasing;
//   final VoidCallback onPurchase;
//   final VoidCallback onDownload;
//   final VoidCallback onDelete;

//   @override
//   Widget build(BuildContext context) {
//     if (!isOwned) {
//       return JButton(
//         label: pack.isFree ? 'Get Free Pack' : 'Buy for ${pack.priceMru} MRU',
//         onPressed: onPurchase,
//         isLoading: isPurchasing,
//         icon: pack.isFree ? Icons.redeem_rounded : Icons.shopping_cart_rounded,
//       );
//     }

//     return PackDownloadButton(
//       packId: pack.id,
//       state: dlState,
//       onDownload: onDownload,
//       onDelete: onDelete,
//     );
//   }
// }

// class _ReviewTile extends StatelessWidget {
//   const _ReviewTile({required this.review});
//   final PackReview review;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 14),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               UserAvatar(
//                 avatarUrl: review.authorAvatarUrl,
//                 displayName: review.authorName,
//                 size: 28,
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   review.authorName ?? 'Player',
//                   style: theme.textTheme.titleSmall?.copyWith(
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//               if (review.rating != null)
//                 Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: List.generate(
//                     5,
//                     (i) => Icon(
//                       i < review.rating!
//                           ? Icons.star_rounded
//                           : Icons.star_outline_rounded,
//                       size: 14,
//                       color: AppColors.amberOrangeLight,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Text(
//             review.content,
//             style: theme.textTheme.bodyMedium?.copyWith(
//               color: theme.colorScheme.onSurfaceVariant,
//               height: 1.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/services/image_cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../../../shared/widgets/overlays/loading_overlay.dart';
import '../../data/pack_repository.dart';
import '../../domain/pack_entity.dart';
import '../pack_provider.dart';
import '../widgets/pack_download_button.dart';
import '../widgets/physical_pack_request_sheet.dart';
import '../widgets/report_pack_sheet.dart';
import '../widgets/review_sheet.dart';

class PackDetailScreen extends StatefulWidget {
  const PackDetailScreen({super.key, required this.packId});
  final String packId;

  @override
  State<PackDetailScreen> createState() => _PackDetailScreenState();
}

class _PackDetailScreenState extends State<PackDetailScreen> {
  PackEntity? _pack;
  List<PackReview> _reviews = [];
  PackRating? _myRating;
  bool _isLoading = true;
  bool _isPurchasing = false;
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
      final repo = PackRepository.instance;
      final userId = context.read<PackProvider>().currentUserId;

      final results = await Future.wait([
        repo.getPackDetail(widget.packId),
        repo.getPackReviews(widget.packId),
        if (userId != null)
          repo.getMyRating(widget.packId, userId)
        else
          Future.value(null),
      ]);

      if (!mounted) return;
      setState(() {
        _pack = results[0] as PackEntity;
        _reviews = results[1] as List<PackReview>;
        _myRating = results.length > 2 ? results[2] as PackRating? : null;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e;
          _isLoading = false;
        });
    }
  }

  Future<void> _purchase() async {
    final pack = _pack;
    if (pack == null) return;

    setState(() => _isPurchasing = true);
    final error = await context.read<PackProvider>().purchasePack(pack);
    if (!mounted) return;
    setState(() => _isPurchasing = false);

    if (error == null) {
      context.showSnackBar('Pack purchased! You can now download it.');
      await _load();
    } else if (error.toLowerCase().contains('insufficient')) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Insufficient Balance'),
          content: Text(
            'You need ${pack.priceMru} MRU to purchase this pack. '
            'Your current balance is too low.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(RouteNames.wallet);
              },
              child: const Text('Top Up Wallet'),
            ),
          ],
        ),
      );
    } else {
      context.showErrorSnackBar('Purchase failed: $error');
    }
  }

  Future<void> _showReviewSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewSheet(
        packId: _pack!.id,
        myRating: _myRating?.rating,
        onSubmit: (content, rating) async {
          final ok = await context.read<PackProvider>().submitReview(
            packId: _pack!.id,
            content: content,
            rating: rating,
          );
          if (ok && mounted) {
            context.showSnackBar('Review submitted!');
            _load();
          }
        },
      ),
    );
  }

  Future<void> _showPhysicalRequestSheet(String packId) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhysicalPackRequestSheet(packId: packId),
    );
    if (result == true && mounted) {
      context.showSnackBar('Physical copy requested!');
    }
  }

  Future<void> _showReportSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportPackSheet(
        packId: _pack!.id,
        onSubmit: (reason, details) async {
          final ok = await context.read<PackProvider>().reportPack(
            packId: _pack!.id,
            reason: reason,
            details: details,
          );
          if (ok && mounted) context.showSnackBar('Report submitted.');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _pack == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: 'Pack not found.', onRetry: _load),
      );
    }

    final pack = _pack!;
    final packs = context.watch<PackProvider>();
    final isOwned = packs.isOwned(pack);
    final dlState = packs.downloadStateFor(pack.id);
    final purchase = packs.purchaseFor(pack.id);
    final theme = context.theme;

    return LoadingOverlay(
      isLoading: _isPurchasing,
      message: 'Processing…',
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.flag_outlined),
                  onPressed: _showReportSheet,
                  tooltip: 'Report',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: pack.coverImageUrl != null
                    ? ImageCacheService.instance.packCover(
                        url: pack.coverImageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 0,
                        color: Colors.black.withOpacity(0.2),
                        colorBlendMode: BlendMode.darken,
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Text(switch (pack.gameType) {
                            'truth_or_dare' => '🎯',
                            _ => '🎮',
                          }, style: const TextStyle(fontSize: 80)),
                        ),
                      ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          pack.titleFor('en'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ).animate().fadeIn().slideY(begin: 0.05, end: 0),
                      ),
                      if (pack.hasSpicy)
                        const Padding(
                          padding: EdgeInsets.only(left: 8, top: 4),
                          child: Text('🌶', style: TextStyle(fontSize: 24)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.layers_rounded,
                        label: '${pack.cardCount} cards',
                      ),
                      const SizedBox(width: 8),
                      if (pack.avgRating > 0)
                        _StatChip(
                          icon: Icons.star_rounded,
                          label: pack.avgRating.toStringAsFixed(1),
                          color: AppColors.amberOrangeLight,
                        ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.people_outline_rounded,
                        label: '${pack.totalPurchases}',
                      ),
                    ],
                  ).animate(delay: 60.ms).fadeIn(),

                  const SizedBox(height: 16),

                  _CreatorRow(pack: pack),

                  const SizedBox(height: 16),

                  if (pack.descriptionFor('en').isNotEmpty) ...[
                    Text(
                      pack.descriptionFor('en'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (pack.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pack.tags
                          .map(
                            (t) => Chip(
                              label: Text('#$t'),
                              visualDensity: VisualDensity.compact,
                              labelStyle: theme.textTheme.labelSmall,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (isOwned && purchase != null) ...[
                    _OwnershipCard(purchase: purchase),
                    const SizedBox(height: 16),
                  ],

                  _PrimaryAction(
                    pack: pack,
                    isOwned: isOwned,
                    dlState: dlState,
                    isPurchasing: _isPurchasing,
                    onPurchase: _purchase,
                    onDownload: () async {
                      final isPremium =
                          context
                              .read<AuthProvider>()
                              .currentUser
                              ?.isPremiumActive ??
                          false;
                      final packs = context.read<PackProvider>();
                      if (packs.isAtDownloadLimit(isPremium: isPremium)) {
                        final limit = packs.downloadLimitFor(
                          isPremium: isPremium,
                        );
                        context.showErrorSnackBar(
                          isPremium
                              ? 'Offline limit reached ($limit packs). Delete a pack to download another.'
                              : 'Free plan allows 1 offline pack. Upgrade to Premium for 10.',
                        );
                        return;
                      }
                      await packs.downloadPack(pack, isPremium: isPremium);
                    },
                    onDelete: () => packs.deletePack(pack.id),
                  ),

                  if (isOwned) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _showPhysicalRequestSheet(pack.id),
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Request Physical Copy'),
                    ),
                  ],

                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Text(
                        'Reviews',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (isOwned)
                        TextButton.icon(
                          onPressed: _showReviewSheet,
                          icon: const Icon(
                            Icons.rate_review_outlined,
                            size: 16,
                          ),
                          label: const Text('Write review'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (isOwned)
                    PackRatingWidget(
                      packId: pack.id,
                      myRating: _myRating?.rating ?? 0,
                      onRated: (r) async {
                        await context.read<PackProvider>().ratePack(pack.id, r);
                        await _load();
                      },
                    ),

                  const SizedBox(height: 16),

                  ..._reviews.asMap().entries.map(
                    (e) => _ReviewTile(
                      review: e.value,
                    ).animate(delay: (e.key * 40).ms).fadeIn(),
                  ),

                  if (_reviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No reviews yet. Be the first!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 48),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: effectiveColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorRow extends StatelessWidget {
  const _CreatorRow({required this.pack});
  final PackEntity pack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UserAvatar(
          avatarUrl: pack.creatorAvatarUrl,
          displayName: pack.creatorName,
          size: 32,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  pack.creatorName ?? 'Creator',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (pack.isVerifiedCreator) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified_rounded,
                    size: 14,
                    color: AppColors.infoBlue,
                  ),
                ],
              ],
            ),
            Text(
              'Pack creator',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OwnershipCard extends StatelessWidget {
  const _OwnershipCard({required this.purchase});
  final PackPurchase purchase;

  @override
  Widget build(BuildContext context) {
    final color = purchase.daysRemaining > 7
        ? AppColors.successGreen
        : AppColors.warningAmber;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You own this pack',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Expires in ${purchase.daysRemaining} days',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.pack,
    required this.isOwned,
    required this.dlState,
    required this.isPurchasing,
    required this.onPurchase,
    required this.onDownload,
    required this.onDelete,
  });

  final PackEntity pack;
  final bool isOwned;
  final PackDownloadState dlState;
  final bool isPurchasing;
  final VoidCallback onPurchase;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (!isOwned) {
      return JButton(
        label: pack.isFree ? 'Get Free Pack' : 'Buy for ${pack.priceMru} MRU',
        onPressed: onPurchase,
        isLoading: isPurchasing,
        icon: pack.isFree ? Icons.redeem_rounded : Icons.shopping_cart_rounded,
      );
    }

    return PackDownloadButton(
      packId: pack.id,
      state: dlState,
      onDownload: onDownload,
      onDelete: onDelete,
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final PackReview review;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                avatarUrl: review.authorAvatarUrl,
                displayName: review.authorName,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.authorName ?? 'Player',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (review.rating != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating!
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 14,
                      color: AppColors.amberOrangeLight,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
