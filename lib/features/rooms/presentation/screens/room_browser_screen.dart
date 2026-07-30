// // // // // // // // // import 'dart:async';
// // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // import 'package:provider/provider.dart';
// // // // // // // // // import '../../../../core/di/service_locator.dart';
// // // // // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // // // // import '../../../../core/providers/auth_provider.dart';
// // // // // // // // // import '../../../../core/router/route_names.dart';
// // // // // // // // // import '../../../../core/router/app_router.dart';
// // // // // // // // // import '../../../../core/storage/database/app_database.dart';
// // // // // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // // // // import '../../../../shared/widgets/cards/j_card.dart';
// // // // // // // // // import '../../../../shared/widgets/feedback/error_view.dart';
// // // // // // // // // import '../../data/room_cache_service.dart';
// // // // // // // // // import '../../domain/room_entity.dart';
// // // // // // // // // import '../widgets/create_room_sheet.dart';
// // // // // // // // // import '../widgets/join_code_dialog.dart';
// // // // // // // // // import '../widgets/room_card.dart';

// // // // // // // // // class RoomBrowserScreen extends StatefulWidget {
// // // // // // // // //   const RoomBrowserScreen({super.key});
// // // // // // // // //   @override
// // // // // // // // //   State<RoomBrowserScreen> createState() => _RoomBrowserScreenState();
// // // // // // // // // }

// // // // // // // // // class _RoomBrowserScreenState extends State<RoomBrowserScreen>
// // // // // // // // //     with WidgetsBindingObserver {
// // // // // // // // //   List<RoomEntity> _rooms = [];
// // // // // // // // //   bool _isLoading = true;
// // // // // // // // //   bool _hasError = false;
// // // // // // // // //   String? _gameTypeFilter;
// // // // // // // // //   Timer? _autoRefreshTimer;

// // // // // // // // //   @override
// // // // // // // // //   void initState() {
// // // // // // // // //     super.initState();
// // // // // // // // //     WidgetsBinding.instance.addObserver(this);
// // // // // // // // //     _loadRooms(fromCache: true);
// // // // // // // // //     // Auto-refresh every 30 seconds while screen is active
// // // // // // // // //     _autoRefreshTimer = Timer.periodic(
// // // // // // // // //       const Duration(seconds: 30),
// // // // // // // // //       (_) => _loadRooms(),
// // // // // // // // //     );
// // // // // // // // //   }

// // // // // // // // //   @override
// // // // // // // // //   void dispose() {
// // // // // // // // //     WidgetsBinding.instance.removeObserver(this);
// // // // // // // // //     _autoRefreshTimer?.cancel();
// // // // // // // // //     super.dispose();
// // // // // // // // //   }

// // // // // // // // //   @override
// // // // // // // // //   void didChangeAppLifecycleState(AppLifecycleState state) {
// // // // // // // // //     if (state == AppLifecycleState.resumed) _loadRooms();
// // // // // // // // //   }

// // // // // // // // //   Future<void> _loadRooms({bool fromCache = false}) async {
// // // // // // // // //     if (fromCache) {
// // // // // // // // //       // Show cached rooms instantly (no-op if DB not ready yet)
// // // // // // // // //       final cached = await RoomCacheService.instance.getCachedRooms();
// // // // // // // // //       if (cached.isNotEmpty && mounted) {
// // // // // // // // //         setState(() {
// // // // // // // // //           _rooms = cached;
// // // // // // // // //           _isLoading = false;
// // // // // // // // //         });
// // // // // // // // //       }
// // // // // // // // //     }

// // // // // // // // //     if (!mounted) return;
// // // // // // // // //     setState(() {
// // // // // // // // //       _isLoading = _rooms.isEmpty;
// // // // // // // // //       _hasError = false;
// // // // // // // // //     });

// // // // // // // // //     try {
// // // // // // // // //       final userId = context.read<AuthProvider>().currentUser?.id;
// // // // // // // // //       final rooms = await sl.roomRepository.getPublicRooms(
// // // // // // // // //         gameTypeFilter: _gameTypeFilter,
// // // // // // // // //         userId: userId,
// // // // // // // // //       );
// // // // // // // // //       if (!mounted) return;
// // // // // // // // //       setState(() {
// // // // // // // // //         _rooms = rooms;
// // // // // // // // //         _isLoading = false;
// // // // // // // // //       });
// // // // // // // // //       await RoomCacheService.instance.cacheRooms(rooms);
// // // // // // // // //     } catch (e, st) {
// // // // // // // // //       debugPrint('RoomBrowser error: $e\n$st');
// // // // // // // // //       if (!mounted) return;
// // // // // // // // //       setState(() {
// // // // // // // // //         _hasError = _rooms.isEmpty;
// // // // // // // // //         _isLoading = false;
// // // // // // // // //       });
// // // // // // // // //     }
// // // // // // // // //   }

// // // // // // // // //   Future<void> _createRoom() async {
// // // // // // // // //     final user = context.read<AuthProvider>().currentUser;
// // // // // // // // //     if (user == null) return;

// // // // // // // // //     final room = await showModalBottomSheet<RoomEntity>(
// // // // // // // // //       context: context,
// // // // // // // // //       isScrollControlled: true,
// // // // // // // // //       backgroundColor: Colors.transparent,
// // // // // // // // //       builder: (_) => const CreateRoomSheet(),
// // // // // // // // //     );
// // // // // // // // //     if (room != null && mounted) {
// // // // // // // // //       AppRouter.router.push('/home/room/${room.id}');
// // // // // // // // //     }
// // // // // // // // //   }

// // // // // // // // //   Future<void> _joinByCode() async {
// // // // // // // // //     final room = await showDialog<RoomEntity>(
// // // // // // // // //       context: context,
// // // // // // // // //       builder: (_) => const JoinCodeDialog(),
// // // // // // // // //     );
// // // // // // // // //     if (room != null && mounted) {
// // // // // // // // //       AppRouter.router.push('/home/room/${room.id}');
// // // // // // // // //     }
// // // // // // // // //   }

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     final l10n = context.l10n;
// // // // // // // // //     final theme = context.theme;

// // // // // // // // //     return Scaffold(
// // // // // // // // //       body: NestedScrollView(
// // // // // // // // //         headerSliverBuilder: (_, __) => [
// // // // // // // // //           SliverAppBar(
// // // // // // // // //             floating: true,
// // // // // // // // //             snap: true,
// // // // // // // // //             title: Text(l10n.roomsTitle),
// // // // // // // // //             actions: [
// // // // // // // // //               IconButton(
// // // // // // // // //                 onPressed: _joinByCode,
// // // // // // // // //                 icon: const Icon(Icons.qr_code_scanner_rounded),
// // // // // // // // //                 tooltip: l10n.roomsJoinCode,
// // // // // // // // //               ),
// // // // // // // // //             ],
// // // // // // // // //             bottom: PreferredSize(
// // // // // // // // //               preferredSize: const Size.fromHeight(48),
// // // // // // // // //               child: _GameTypeFilterBar(
// // // // // // // // //                 selected: _gameTypeFilter,
// // // // // // // // //                 onChanged: (f) {
// // // // // // // // //                   setState(() => _gameTypeFilter = f);
// // // // // // // // //                   _loadRooms();
// // // // // // // // //                 },
// // // // // // // // //               ),
// // // // // // // // //             ),
// // // // // // // // //           ),
// // // // // // // // //         ],
// // // // // // // // //         body: RefreshIndicator(
// // // // // // // // //           onRefresh: _loadRooms,
// // // // // // // // //           child: _buildBody(theme, l10n),
// // // // // // // // //         ),
// // // // // // // // //       ),
// // // // // // // // //       floatingActionButton: FloatingActionButton.extended(
// // // // // // // // //         heroTag: 'room_browser_create_fab',
// // // // // // // // //         onPressed: _createRoom,
// // // // // // // // //         icon: const Icon(Icons.add_rounded),
// // // // // // // // //         label: Text(l10n.roomsCreate),
// // // // // // // // //         backgroundColor: theme.colorScheme.primary,
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }

// // // // // // // // //   Widget _buildBody(ThemeData theme, dynamic l10n) {
// // // // // // // // //     if (_isLoading) {
// // // // // // // // //       return _LoadingGrid();
// // // // // // // // //     }
// // // // // // // // //     if (_hasError) {
// // // // // // // // //       return ErrorView(
// // // // // // // // //         message: context.l10n.errorUnexpected,
// // // // // // // // //         onRetry: _loadRooms,
// // // // // // // // //       );
// // // // // // // // //     }
// // // // // // // // //     if (_rooms.isEmpty) {
// // // // // // // // //       return JEmptyState(
// // // // // // // // //         emoji: '🚪',
// // // // // // // // //         title: l10n.roomsEmpty,
// // // // // // // // //         subtitle: l10n.roomsEmptySubtitle,
// // // // // // // // //         action: FilledButton.icon(
// // // // // // // // //           onPressed: _createRoom,
// // // // // // // // //           icon: const Icon(Icons.add_rounded),
// // // // // // // // //           label: Text(l10n.roomsCreate),
// // // // // // // // //         ),
// // // // // // // // //       );
// // // // // // // // //     }
// // // // // // // // //     return ListView.separated(
// // // // // // // // //       padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
// // // // // // // // //       itemCount: _rooms.length,
// // // // // // // // //       separatorBuilder: (_, __) => const SizedBox(height: 10),
// // // // // // // // //       itemBuilder: (_, i) => RoomCard(
// // // // // // // // //         room: _rooms[i],
// // // // // // // // //         onTap: () => AppRouter.router.push('/home/room/${_rooms[i].id}'),
// // // // // // // // //       ).animate(delay: (i * 35).ms).fadeIn().slideY(begin: 0.06, end: 0),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // // class _GameTypeFilterBar extends StatelessWidget {
// // // // // // // // //   const _GameTypeFilterBar({required this.selected, required this.onChanged});
// // // // // // // // //   final String? selected;
// // // // // // // // //   final void Function(String?) onChanged;

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     const filters = [
// // // // // // // // //       (null, 'All', '🎮'),
// // // // // // // // //       ('truth_or_dare', 'Truth or Dare', '🎯'),
// // // // // // // // //       ('never_have_i_ever', 'Never Have I', '🍹'),
// // // // // // // // //       ('meme_game', 'Meme Game', '😂'),
// // // // // // // // //     ];

// // // // // // // // //     return SizedBox(
// // // // // // // // //       height: 48,
// // // // // // // // //       child: ListView(
// // // // // // // // //         scrollDirection: Axis.horizontal,
// // // // // // // // //         padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
// // // // // // // // //         children: filters.map((f) {
// // // // // // // // //           final isSelected = selected == f.$1;
// // // // // // // // //           return Padding(
// // // // // // // // //             padding: const EdgeInsets.only(right: 8),
// // // // // // // // //             child: FilterChip(
// // // // // // // // //               label: Text('${f.$3} ${f.$2}'),
// // // // // // // // //               selected: isSelected,
// // // // // // // // //               onSelected: (_) => onChanged(isSelected ? null : f.$1),
// // // // // // // // //               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
// // // // // // // // //             ),
// // // // // // // // //           );
// // // // // // // // //         }).toList(),
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // // class _LoadingGrid extends StatelessWidget {
// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     return ListView(
// // // // // // // // //       padding: const EdgeInsets.all(16),
// // // // // // // // //       children: List.generate(
// // // // // // // // //         4,
// // // // // // // // //         (i) => Padding(
// // // // // // // // //           padding: const EdgeInsets.only(bottom: 12),
// // // // // // // // //           child: ShimmerBox(width: double.infinity, height: 88, radius: 16),
// // // // // // // // //         ).animate(delay: (i * 60).ms).fadeIn(),
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // import 'dart:async';
// // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // import 'package:provider/provider.dart';
// // // // // // // // import '../../../../core/di/service_locator.dart';
// // // // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // // // import '../../../../core/providers/auth_provider.dart';
// // // // // // // // import '../../../../core/router/route_names.dart';
// // // // // // // // import '../../../../core/router/app_router.dart';
// // // // // // // // import '../../../../core/storage/database/app_database.dart';
// // // // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // // // import '../../../../shared/widgets/cards/j_card.dart';
// // // // // // // // import '../../../../shared/widgets/feedback/error_view.dart';
// // // // // // // // import '../../data/room_cache_service.dart';
// // // // // // // // import '../../domain/room_entity.dart';
// // // // // // // // import '../widgets/create_room_sheet.dart';
// // // // // // // // import '../widgets/join_code_dialog.dart';
// // // // // // // // import '../widgets/room_card.dart';

// // // // // // // // class RoomBrowserScreen extends StatefulWidget {
// // // // // // // //   const RoomBrowserScreen({super.key});
// // // // // // // //   @override
// // // // // // // //   State<RoomBrowserScreen> createState() => _RoomBrowserScreenState();
// // // // // // // // }

// // // // // // // // class _RoomBrowserScreenState extends State<RoomBrowserScreen>
// // // // // // // //     with WidgetsBindingObserver {
// // // // // // // //   List<RoomEntity> _rooms = [];
// // // // // // // //   bool _isLoading = true;
// // // // // // // //   bool _hasError = false;
// // // // // // // //   String? _gameTypeFilter;
// // // // // // // //   Timer? _autoRefreshTimer;

// // // // // // // //   @override
// // // // // // // //   void initState() {
// // // // // // // //     super.initState();
// // // // // // // //     WidgetsBinding.instance.addObserver(this);
// // // // // // // //     // Clean up any lingering realtime subscriptions from previous rooms
// // // // // // // //     try {
// // // // // // // //       sl.realtimeService.unsubscribeAll();
// // // // // // // //     } catch (_) {}
// // // // // // // //     _loadRooms(fromCache: true);
// // // // // // // //     // Auto-refresh every 30 seconds while screen is active
// // // // // // // //     _autoRefreshTimer = Timer.periodic(
// // // // // // // //       const Duration(seconds: 30),
// // // // // // // //       (_) => _loadRooms(),
// // // // // // // //     );
// // // // // // // //   }

// // // // // // // //   @override
// // // // // // // //   void dispose() {
// // // // // // // //     WidgetsBinding.instance.removeObserver(this);
// // // // // // // //     _autoRefreshTimer?.cancel();
// // // // // // // //     super.dispose();
// // // // // // // //   }

// // // // // // // //   @override
// // // // // // // //   void didChangeAppLifecycleState(AppLifecycleState state) {
// // // // // // // //     if (state == AppLifecycleState.resumed) _loadRooms();
// // // // // // // //   }

// // // // // // // //   Future<void> _loadRooms({bool fromCache = false}) async {
// // // // // // // //     if (fromCache) {
// // // // // // // //       // Show cached rooms instantly (no-op if DB not ready yet)
// // // // // // // //       final cached = await RoomCacheService.instance.getCachedRooms();
// // // // // // // //       if (cached.isNotEmpty && mounted) {
// // // // // // // //         setState(() {
// // // // // // // //           _rooms = cached;
// // // // // // // //           _isLoading = false;
// // // // // // // //         });
// // // // // // // //       }
// // // // // // // //     }

// // // // // // // //     if (!mounted) return;
// // // // // // // //     setState(() {
// // // // // // // //       _isLoading = _rooms.isEmpty;
// // // // // // // //       _hasError = false;
// // // // // // // //     });

// // // // // // // //     try {
// // // // // // // //       final userId = context.read<AuthProvider>().currentUser?.id;
// // // // // // // //       final rooms = await sl.roomRepository.getPublicRooms(
// // // // // // // //         gameTypeFilter: _gameTypeFilter,
// // // // // // // //         userId: userId,
// // // // // // // //       );
// // // // // // // //       if (!mounted) return;
// // // // // // // //       setState(() {
// // // // // // // //         _rooms = rooms;
// // // // // // // //         _isLoading = false;
// // // // // // // //       });
// // // // // // // //       await RoomCacheService.instance.cacheRooms(rooms);
// // // // // // // //     } catch (e, st) {
// // // // // // // //       debugPrint('RoomBrowser error: $e\n$st');
// // // // // // // //       if (!mounted) return;
// // // // // // // //       // Only show error UI if we have no rooms to show at all
// // // // // // // //       setState(() {
// // // // // // // //         _hasError = _rooms.isEmpty;
// // // // // // // //         _isLoading = false;
// // // // // // // //       });
// // // // // // // //       // Silently retry once after a short delay
// // // // // // // //       if (_rooms.isEmpty) {
// // // // // // // //         await Future.delayed(const Duration(seconds: 2));
// // // // // // // //         if (mounted) _loadRooms();
// // // // // // // //       }
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   Future<void> _createRoom() async {
// // // // // // // //     final user = context.read<AuthProvider>().currentUser;
// // // // // // // //     if (user == null) return;

// // // // // // // //     final room = await showModalBottomSheet<RoomEntity>(
// // // // // // // //       context: context,
// // // // // // // //       isScrollControlled: true,
// // // // // // // //       backgroundColor: Colors.transparent,
// // // // // // // //       builder: (_) => const CreateRoomSheet(),
// // // // // // // //     );
// // // // // // // //     if (room != null && mounted) {
// // // // // // // //       AppRouter.router.push('/home/room/${room.id}');
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   Future<void> _joinByCode() async {
// // // // // // // //     final room = await showDialog<RoomEntity>(
// // // // // // // //       context: context,
// // // // // // // //       builder: (_) => const JoinCodeDialog(),
// // // // // // // //     );
// // // // // // // //     if (room != null && mounted) {
// // // // // // // //       AppRouter.router.push('/home/room/${room.id}');
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     final l10n = context.l10n;
// // // // // // // //     final theme = context.theme;

// // // // // // // //     return Scaffold(
// // // // // // // //       body: NestedScrollView(
// // // // // // // //         headerSliverBuilder: (_, __) => [
// // // // // // // //           SliverAppBar(
// // // // // // // //             floating: true,
// // // // // // // //             snap: true,
// // // // // // // //             title: Text(l10n.roomsTitle),
// // // // // // // //             actions: [
// // // // // // // //               IconButton(
// // // // // // // //                 onPressed: _joinByCode,
// // // // // // // //                 icon: const Icon(Icons.qr_code_scanner_rounded),
// // // // // // // //                 tooltip: l10n.roomsJoinCode,
// // // // // // // //               ),
// // // // // // // //             ],
// // // // // // // //             bottom: PreferredSize(
// // // // // // // //               preferredSize: const Size.fromHeight(48),
// // // // // // // //               child: _GameTypeFilterBar(
// // // // // // // //                 selected: _gameTypeFilter,
// // // // // // // //                 onChanged: (f) {
// // // // // // // //                   setState(() => _gameTypeFilter = f);
// // // // // // // //                   _loadRooms();
// // // // // // // //                 },
// // // // // // // //               ),
// // // // // // // //             ),
// // // // // // // //           ),
// // // // // // // //         ],
// // // // // // // //         body: RefreshIndicator(
// // // // // // // //           onRefresh: _loadRooms,
// // // // // // // //           child: _buildBody(theme, l10n),
// // // // // // // //         ),
// // // // // // // //       ),
// // // // // // // //       floatingActionButton: FloatingActionButton.extended(
// // // // // // // //         heroTag: 'room_browser_create_fab',
// // // // // // // //         onPressed: _createRoom,
// // // // // // // //         icon: const Icon(Icons.add_rounded),
// // // // // // // //         label: Text(l10n.roomsCreate),
// // // // // // // //         backgroundColor: theme.colorScheme.primary,
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }

// // // // // // // //   Widget _buildBody(ThemeData theme, dynamic l10n) {
// // // // // // // //     if (_isLoading) {
// // // // // // // //       return _LoadingGrid();
// // // // // // // //     }
// // // // // // // //     if (_hasError) {
// // // // // // // //       return ErrorView(
// // // // // // // //         message: context.l10n.errorUnexpected,
// // // // // // // //         onRetry: _loadRooms,
// // // // // // // //       );
// // // // // // // //     }
// // // // // // // //     if (_rooms.isEmpty) {
// // // // // // // //       return JEmptyState(
// // // // // // // //         emoji: '🚪',
// // // // // // // //         title: l10n.roomsEmpty,
// // // // // // // //         subtitle: l10n.roomsEmptySubtitle,
// // // // // // // //         action: FilledButton.icon(
// // // // // // // //           onPressed: _createRoom,
// // // // // // // //           icon: const Icon(Icons.add_rounded),
// // // // // // // //           label: Text(l10n.roomsCreate),
// // // // // // // //         ),
// // // // // // // //       );
// // // // // // // //     }
// // // // // // // //     return ListView.separated(
// // // // // // // //       padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
// // // // // // // //       itemCount: _rooms.length,
// // // // // // // //       separatorBuilder: (_, __) => const SizedBox(height: 10),
// // // // // // // //       itemBuilder: (_, i) => RoomCard(
// // // // // // // //         room: _rooms[i],
// // // // // // // //         onTap: () => AppRouter.router.push('/home/room/${_rooms[i].id}'),
// // // // // // // //       ).animate(delay: (i * 35).ms).fadeIn().slideY(begin: 0.06, end: 0),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // class _GameTypeFilterBar extends StatelessWidget {
// // // // // // // //   const _GameTypeFilterBar({required this.selected, required this.onChanged});
// // // // // // // //   final String? selected;
// // // // // // // //   final void Function(String?) onChanged;

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     const filters = [
// // // // // // // //       (null, 'All', '🎮'),
// // // // // // // //       ('truth_or_dare', 'Truth or Dare', '🎯'),
// // // // // // // //       ('never_have_i_ever', 'Never Have I', '🍹'),
// // // // // // // //       ('meme_game', 'Meme Game', '😂'),
// // // // // // // //     ];

// // // // // // // //     return SizedBox(
// // // // // // // //       height: 48,
// // // // // // // //       child: ListView(
// // // // // // // //         scrollDirection: Axis.horizontal,
// // // // // // // //         padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
// // // // // // // //         children: filters.map((f) {
// // // // // // // //           final isSelected = selected == f.$1;
// // // // // // // //           return Padding(
// // // // // // // //             padding: const EdgeInsets.only(right: 8),
// // // // // // // //             child: FilterChip(
// // // // // // // //               label: Text('${f.$3} ${f.$2}'),
// // // // // // // //               selected: isSelected,
// // // // // // // //               onSelected: (_) => onChanged(isSelected ? null : f.$1),
// // // // // // // //               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
// // // // // // // //             ),
// // // // // // // //           );
// // // // // // // //         }).toList(),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // class _LoadingGrid extends StatelessWidget {
// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     return ListView(
// // // // // // // //       padding: const EdgeInsets.all(16),
// // // // // // // //       children: List.generate(
// // // // // // // //         4,
// // // // // // // //         (i) => Padding(
// // // // // // // //           padding: const EdgeInsets.only(bottom: 12),
// // // // // // // //           child: ShimmerBox(width: double.infinity, height: 88, radius: 16),
// // // // // // // //         ).animate(delay: (i * 60).ms).fadeIn(),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // import 'dart:async';
// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // import 'package:jma3a/deep_links.dart';
// // // // // // // import 'package:provider/provider.dart';
// // // // // // // import '../../../../core/di/service_locator.dart';
// // // // // // // // import '../../../../core/services/deep_link_service.dart';
// // // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // // import '../../../../core/providers/auth_provider.dart';
// // // // // // // import '../../../../core/router/route_names.dart';
// // // // // // // import '../../../../core/router/app_router.dart';
// // // // // // // import '../../../../core/storage/database/app_database.dart';
// // // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // // import '../../../../shared/widgets/cards/j_card.dart';
// // // // // // // import '../../../../shared/widgets/feedback/error_view.dart';
// // // // // // // import '../../data/room_cache_service.dart';
// // // // // // // import '../../domain/room_entity.dart';
// // // // // // // import '../widgets/create_room_sheet.dart';
// // // // // // // import '../widgets/join_code_dialog.dart';
// // // // // // // import '../widgets/room_card.dart';

// // // // // // // class RoomBrowserScreen extends StatefulWidget {
// // // // // // //   const RoomBrowserScreen({super.key});
// // // // // // //   @override
// // // // // // //   State<RoomBrowserScreen> createState() => _RoomBrowserScreenState();
// // // // // // // }

// // // // // // // class _RoomBrowserScreenState extends State<RoomBrowserScreen>
// // // // // // //     with WidgetsBindingObserver {
// // // // // // //   List<RoomEntity> _rooms = [];
// // // // // // //   bool _isLoading = true;
// // // // // // //   bool _hasError = false;
// // // // // // //   String? _gameTypeFilter;
// // // // // // //   Timer? _autoRefreshTimer;
// // // // // // //   StreamSubscription<RoomInvitePayload>? _deepLinkSub;

// // // // // // //   @override
// // // // // // //   void initState() {
// // // // // // //     super.initState();
// // // // // // //     WidgetsBinding.instance.addObserver(this);
// // // // // // //     // Clean up any lingering realtime subscriptions from previous rooms
// // // // // // //     try {
// // // // // // //       sl.realtimeService.unsubscribeAll();
// // // // // // //     } catch (_) {}
// // // // // // //     _loadRooms(fromCache: true);
// // // // // // //     // Listen for deep link invite codes
// // // // // // //     _deepLinkSub = DeepLinkService.instance.inviteStream.listen(_onInvite);
// // // // // // //     // Auto-refresh every 30 seconds while screen is active
// // // // // // //     _autoRefreshTimer = Timer.periodic(
// // // // // // //       const Duration(seconds: 30),
// // // // // // //       (_) => _loadRooms(),
// // // // // // //     );
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   void dispose() {
// // // // // // //     WidgetsBinding.instance.removeObserver(this);
// // // // // // //     _autoRefreshTimer?.cancel();
// // // // // // //     _deepLinkSub?.cancel();
// // // // // // //     super.dispose();
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   void didChangeAppLifecycleState(AppLifecycleState state) {
// // // // // // //     if (state == AppLifecycleState.resumed) _loadRooms();
// // // // // // //   }

// // // // // // //   Future<void> _loadRooms({bool fromCache = false}) async {
// // // // // // //     if (fromCache) {
// // // // // // //       // Show cached rooms instantly (no-op if DB not ready yet)
// // // // // // //       final cached = await RoomCacheService.instance.getCachedRooms();
// // // // // // //       if (cached.isNotEmpty && mounted) {
// // // // // // //         setState(() {
// // // // // // //           _rooms = cached;
// // // // // // //           _isLoading = false;
// // // // // // //         });
// // // // // // //       }
// // // // // // //     }

// // // // // // //     if (!mounted) return;
// // // // // // //     setState(() {
// // // // // // //       _isLoading = _rooms.isEmpty;
// // // // // // //       _hasError = false;
// // // // // // //     });

// // // // // // //     try {
// // // // // // //       final userId = context.read<AuthProvider>().currentUser?.id;
// // // // // // //       final rooms = await sl.roomRepository.getPublicRooms(
// // // // // // //         gameTypeFilter: _gameTypeFilter,
// // // // // // //         userId: userId,
// // // // // // //       );
// // // // // // //       if (!mounted) return;
// // // // // // //       setState(() {
// // // // // // //         _rooms = rooms;
// // // // // // //         _isLoading = false;
// // // // // // //       });
// // // // // // //       await RoomCacheService.instance.cacheRooms(rooms);
// // // // // // //     } catch (e, st) {
// // // // // // //       debugPrint('RoomBrowser error: $e\n$st');
// // // // // // //       if (!mounted) return;
// // // // // // //       // Only show error UI if we have no rooms to show at all
// // // // // // //       setState(() {
// // // // // // //         _hasError = _rooms.isEmpty;
// // // // // // //         _isLoading = false;
// // // // // // //       });
// // // // // // //       // Silently retry once after a short delay
// // // // // // //       if (_rooms.isEmpty) {
// // // // // // //         await Future.delayed(const Duration(seconds: 2));
// // // // // // //         if (mounted) _loadRooms();
// // // // // // //       }
// // // // // // //     }
// // // // // // //   }

// // // // // // //   Future<void> _createRoom() async {
// // // // // // //     final user = context.read<AuthProvider>().currentUser;
// // // // // // //     if (user == null) return;

// // // // // // //     final room = await showModalBottomSheet<RoomEntity>(
// // // // // // //       context: context,
// // // // // // //       isScrollControlled: true,
// // // // // // //       backgroundColor: Colors.transparent,
// // // // // // //       builder: (_) => const CreateRoomSheet(),
// // // // // // //     );
// // // // // // //     if (room != null && mounted) {
// // // // // // //       AppRouter.router.push('/home/room/${room.id}');
// // // // // // //     }
// // // // // // //   }

// // // // // // //   Future<void> _onInvite(RoomInvitePayload payload) async {
// // // // // // //     if (!mounted) return;
// // // // // // //     final room = await showDialog<RoomEntity>(
// // // // // // //       context: context,
// // // // // // //       builder: (_) => JoinCodeDialog(
// // // // // // //         prefillCode: payload.code,
// // // // // // //         invitedBy: payload.invitedBy,
// // // // // // //       ),
// // // // // // //     );
// // // // // // //     if (room != null && mounted) AppRouter.router.push('/home/room/${room.id}');
// // // // // // //   }

// // // // // // //   Future<void> _joinByCode() async {
// // // // // // //     final room = await showDialog<RoomEntity>(
// // // // // // //       context: context,
// // // // // // //       builder: (_) => const JoinCodeDialog(),
// // // // // // //     );
// // // // // // //     if (room != null && mounted) {
// // // // // // //       AppRouter.router.push('/home/room/${room.id}');
// // // // // // //     }
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     final l10n = context.l10n;
// // // // // // //     final theme = context.theme;

// // // // // // //     return Scaffold(
// // // // // // //       body: NestedScrollView(
// // // // // // //         headerSliverBuilder: (_, __) => [
// // // // // // //           SliverAppBar(
// // // // // // //             floating: true,
// // // // // // //             snap: true,
// // // // // // //             title: Text(l10n.roomsTitle),
// // // // // // //             actions: [
// // // // // // //               IconButton(
// // // // // // //                 onPressed: _joinByCode,
// // // // // // //                 icon: const Icon(Icons.qr_code_scanner_rounded),
// // // // // // //                 tooltip: l10n.roomsJoinCode,
// // // // // // //               ),
// // // // // // //             ],
// // // // // // //             bottom: PreferredSize(
// // // // // // //               preferredSize: const Size.fromHeight(48),
// // // // // // //               child: _GameTypeFilterBar(
// // // // // // //                 selected: _gameTypeFilter,
// // // // // // //                 onChanged: (f) {
// // // // // // //                   setState(() => _gameTypeFilter = f);
// // // // // // //                   _loadRooms();
// // // // // // //                 },
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         ],
// // // // // // //         body: RefreshIndicator(
// // // // // // //           onRefresh: _loadRooms,
// // // // // // //           child: _buildBody(theme, l10n),
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //       floatingActionButton: FloatingActionButton.extended(
// // // // // // //         heroTag: 'room_browser_create_fab',
// // // // // // //         onPressed: _createRoom,
// // // // // // //         icon: const Icon(Icons.add_rounded),
// // // // // // //         label: Text(l10n.roomsCreate),
// // // // // // //         backgroundColor: theme.colorScheme.primary,
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }

// // // // // // //   Widget _buildBody(ThemeData theme, dynamic l10n) {
// // // // // // //     if (_isLoading) {
// // // // // // //       return _LoadingGrid();
// // // // // // //     }
// // // // // // //     if (_hasError) {
// // // // // // //       return ErrorView(
// // // // // // //         message: context.l10n.errorUnexpected,
// // // // // // //         onRetry: _loadRooms,
// // // // // // //       );
// // // // // // //     }
// // // // // // //     if (_rooms.isEmpty) {
// // // // // // //       return JEmptyState(
// // // // // // //         emoji: '🚪',
// // // // // // //         title: l10n.roomsEmpty,
// // // // // // //         subtitle: l10n.roomsEmptySubtitle,
// // // // // // //         action: FilledButton.icon(
// // // // // // //           onPressed: _createRoom,
// // // // // // //           icon: const Icon(Icons.add_rounded),
// // // // // // //           label: Text(l10n.roomsCreate),
// // // // // // //         ),
// // // // // // //       );
// // // // // // //     }
// // // // // // //     return ListView.separated(
// // // // // // //       padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
// // // // // // //       itemCount: _rooms.length,
// // // // // // //       separatorBuilder: (_, __) => const SizedBox(height: 10),
// // // // // // //       itemBuilder: (_, i) => RoomCard(
// // // // // // //         room: _rooms[i],
// // // // // // //         onTap: () => AppRouter.router.push('/home/room/${_rooms[i].id}'),
// // // // // // //       ).animate(delay: (i * 35).ms).fadeIn().slideY(begin: 0.06, end: 0),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // class _GameTypeFilterBar extends StatelessWidget {
// // // // // // //   const _GameTypeFilterBar({required this.selected, required this.onChanged});
// // // // // // //   final String? selected;
// // // // // // //   final void Function(String?) onChanged;

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     const filters = [
// // // // // // //       (null, 'All', '🎮'),
// // // // // // //       ('truth_or_dare', 'Truth or Dare', '🎯'),
// // // // // // //       ('never_have_i_ever', 'Never Have I', '🍹'),
// // // // // // //       ('meme_game', 'Meme Game', '😂'),
// // // // // // //     ];

// // // // // // //     return SizedBox(
// // // // // // //       height: 48,
// // // // // // //       child: ListView(
// // // // // // //         scrollDirection: Axis.horizontal,
// // // // // // //         padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
// // // // // // //         children: filters.map((f) {
// // // // // // //           final isSelected = selected == f.$1;
// // // // // // //           return Padding(
// // // // // // //             padding: const EdgeInsets.only(right: 8),
// // // // // // //             child: FilterChip(
// // // // // // //               label: Text('${f.$3} ${f.$2}'),
// // // // // // //               selected: isSelected,
// // // // // // //               onSelected: (_) => onChanged(isSelected ? null : f.$1),
// // // // // // //               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
// // // // // // //             ),
// // // // // // //           );
// // // // // // //         }).toList(),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // class _LoadingGrid extends StatelessWidget {
// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     return ListView(
// // // // // // //       padding: const EdgeInsets.all(16),
// // // // // // //       children: List.generate(
// // // // // // //         4,
// // // // // // //         (i) => Padding(
// // // // // // //           padding: const EdgeInsets.only(bottom: 12),
// // // // // // //           child: ShimmerBox(width: double.infinity, height: 88, radius: 16),
// // // // // // //         ).animate(delay: (i * 60).ms).fadeIn(),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // import 'dart:async';
// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // import 'package:go_router/go_router.dart';
// // // // // // import 'package:jma3a/deep_links.dart';
// // // // // // import 'package:provider/provider.dart';
// // // // // // import '../../../../core/di/service_locator.dart';
// // // // // // // import '../../../../core/services/deep_link_service.dart';
// // // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // // import '../../../../core/providers/auth_provider.dart';
// // // // // // import '../../../../core/router/route_names.dart';
// // // // // // import '../../../../core/router/app_router.dart';
// // // // // // import '../../../../core/storage/database/app_database.dart';
// // // // // // import '../../../../core/theme/app_colors.dart';
// // // // // // import '../../../../shared/widgets/cards/j_card.dart';
// // // // // // import '../../../../shared/widgets/feedback/error_view.dart';
// // // // // // import '../../data/room_cache_service.dart';
// // // // // // import '../../domain/room_entity.dart';
// // // // // // import '../widgets/create_room_sheet.dart';
// // // // // // import '../widgets/join_code_dialog.dart';
// // // // // // import '../widgets/room_card.dart';

// // // // // // class RoomBrowserScreen extends StatefulWidget {
// // // // // //   const RoomBrowserScreen({super.key});
// // // // // //   @override
// // // // // //   State<RoomBrowserScreen> createState() => _RoomBrowserScreenState();
// // // // // // }

// // // // // // class _RoomBrowserScreenState extends State<RoomBrowserScreen>
// // // // // //     with WidgetsBindingObserver {
// // // // // //   List<RoomEntity> _rooms = [];
// // // // // //   bool _isLoading = true;
// // // // // //   bool _hasError = false;
// // // // // //   String? _gameTypeFilter;
// // // // // //   Timer? _autoRefreshTimer;
// // // // // //   StreamSubscription<RoomInvitePayload>? _deepLinkSub;

// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();
// // // // // //     WidgetsBinding.instance.addObserver(this);
// // // // // //     // Clean up any lingering realtime subscriptions from previous rooms
// // // // // //     try {
// // // // // //       sl.realtimeService.unsubscribeAll();
// // // // // //     } catch (_) {}
// // // // // //     _loadRooms(fromCache: true);
// // // // // //     // Listen for deep link invite codes
// // // // // //     _deepLinkSub = DeepLinkService.instance.inviteStream.listen(_onInvite);
// // // // // //     // Auto-refresh every 30 seconds while screen is active
// // // // // //     _autoRefreshTimer = Timer.periodic(
// // // // // //       const Duration(seconds: 30),
// // // // // //       (_) => _loadRooms(),
// // // // // //     );
// // // // // //   }

// // // // // //   @override
// // // // // //   void dispose() {
// // // // // //     WidgetsBinding.instance.removeObserver(this);
// // // // // //     _autoRefreshTimer?.cancel();
// // // // // //     _deepLinkSub?.cancel();
// // // // // //     super.dispose();
// // // // // //   }

// // // // // //   @override
// // // // // //   void didChangeAppLifecycleState(AppLifecycleState state) {
// // // // // //     if (state == AppLifecycleState.resumed) _loadRooms();
// // // // // //   }

// // // // // //   Future<void> _loadRooms({bool fromCache = false}) async {
// // // // // //     if (fromCache) {
// // // // // //       // Show cached rooms instantly (no-op if DB not ready yet)
// // // // // //       final cached = await RoomCacheService.instance.getCachedRooms();
// // // // // //       if (cached.isNotEmpty && mounted) {
// // // // // //         setState(() {
// // // // // //           _rooms = cached;
// // // // // //           _isLoading = false;
// // // // // //         });
// // // // // //       }
// // // // // //     }

// // // // // //     if (!mounted) return;
// // // // // //     setState(() {
// // // // // //       _isLoading = _rooms.isEmpty;
// // // // // //       _hasError = false;
// // // // // //     });

// // // // // //     try {
// // // // // //       final userId = context.read<AuthProvider>().currentUser?.id;
// // // // // //       final rooms = await sl.roomRepository.getPublicRooms(
// // // // // //         gameTypeFilter: _gameTypeFilter,
// // // // // //         userId: userId,
// // // // // //       );
// // // // // //       if (!mounted) return;
// // // // // //       setState(() {
// // // // // //         _rooms = rooms;
// // // // // //         _isLoading = false;
// // // // // //       });
// // // // // //       await RoomCacheService.instance.cacheRooms(rooms);
// // // // // //     } catch (e, st) {
// // // // // //       debugPrint('RoomBrowser error: $e\n$st');
// // // // // //       if (!mounted) return;
// // // // // //       // Only show error UI if we have no rooms to show at all
// // // // // //       setState(() {
// // // // // //         _hasError = _rooms.isEmpty;
// // // // // //         _isLoading = false;
// // // // // //       });
// // // // // //       // Silently retry once after a short delay
// // // // // //       if (_rooms.isEmpty) {
// // // // // //         await Future.delayed(const Duration(seconds: 2));
// // // // // //         if (mounted) _loadRooms();
// // // // // //       }
// // // // // //     }
// // // // // //   }

// // // // // //   Future<void> _createRoom() async {
// // // // // //     final user = context.read<AuthProvider>().currentUser;
// // // // // //     if (user == null) return;

// // // // // //     // ── Gate 1: only one active room per user ──────────────────────────────
// // // // // //     final existingRoom = await sl.roomRepository.getActiveOwnedRoom(user.id);
// // // // // //     if (existingRoom != null) {
// // // // // //       if (!mounted) return;
// // // // // //       final goToRoom = await showDialog<bool>(
// // // // // //         context: context,
// // // // // //         builder: (ctx) => AlertDialog(
// // // // // //           title: const Text('You already have an active room'),
// // // // // //           content: Text(
// // // // // //             existingRoom.status == RoomStatus.paused
// // // // // //                 ? 'Your room "${existingRoom.name}" is paused. Finish or close it before creating a new one.'
// // // // // //                 : 'Your room "${existingRoom.name}" is still open. Finish or close it before creating a new one.',
// // // // // //           ),
// // // // // //           actions: [
// // // // // //             TextButton(
// // // // // //               onPressed: () => Navigator.pop(ctx, false),
// // // // // //               child: const Text('Cancel'),
// // // // // //             ),
// // // // // //             FilledButton(
// // // // // //               onPressed: () => Navigator.pop(ctx, true),
// // // // // //               child: const Text('Go to Room'),
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
// // // // // //       );
// // // // // //       if (goToRoom == true && mounted) {
// // // // // //         AppRouter.router.push('/home/room/${existingRoom.id}');
// // // // // //       }
// // // // // //       return;
// // // // // //     }

// // // // // //     // ── Gate 2: must have at least one pack available (owned or free) ──────
// // // // // //     final myPacks = await sl.packRepository.getMyPurchasedPacks(user.id);
// // // // // //     if (myPacks.isEmpty) {
// // // // // //       final freeAvailable = await sl.packRepository.hasFreePacksAvailable();
// // // // // //       if (!freeAvailable) {
// // // // // //         if (!mounted) return;
// // // // // //         await showDialog<void>(
// // // // // //           context: context,
// // // // // //           builder: (ctx) => AlertDialog(
// // // // // //             title: const Text('No packs available'),
// // // // // //             content: const Text(
// // // // // //               "You need at least one pack to create a room — get a free pack or purchase one from the marketplace first.",
// // // // // //             ),
// // // // // //             actions: [
// // // // // //               TextButton(
// // // // // //                 onPressed: () => Navigator.pop(ctx),
// // // // // //                 child: const Text('Cancel'),
// // // // // //               ),
// // // // // //               FilledButton(
// // // // // //                 onPressed: () {
// // // // // //                   Navigator.pop(ctx);
// // // // // //                   AppRouter.router.go(RouteNames.marketplace);
// // // // // //                 },
// // // // // //                 child: const Text('Browse Packs'),
// // // // // //               ),
// // // // // //             ],
// // // // // //           ),
// // // // // //         );
// // // // // //         return;
// // // // // //       }
// // // // // //     }

// // // // // //     if (!mounted) return;
// // // // // //     final room = await showModalBottomSheet<RoomEntity>(
// // // // // //       context: context,
// // // // // //       isScrollControlled: true,
// // // // // //       backgroundColor: Colors.transparent,
// // // // // //       builder: (_) => const CreateRoomSheet(),
// // // // // //     );
// // // // // //     if (room != null && mounted) {
// // // // // //       AppRouter.router.push('/home/room/${room.id}');
// // // // // //     }
// // // // // //   }

// // // // // //   Future<void> _onInvite(RoomInvitePayload payload) async {
// // // // // //     if (!mounted) return;
// // // // // //     final room = await showDialog<RoomEntity>(
// // // // // //       context: context,
// // // // // //       builder: (_) => JoinCodeDialog(
// // // // // //         prefillCode: payload.code,
// // // // // //         invitedBy: payload.invitedBy,
// // // // // //       ),
// // // // // //     );
// // // // // //     if (room != null && mounted) AppRouter.router.push('/home/room/${room.id}');
// // // // // //   }

// // // // // //   Future<void> _joinByCode() async {
// // // // // //     final room = await showDialog<RoomEntity>(
// // // // // //       context: context,
// // // // // //       builder: (_) => const JoinCodeDialog(),
// // // // // //     );
// // // // // //     if (room != null && mounted) {
// // // // // //       AppRouter.router.push('/home/room/${room.id}');
// // // // // //     }
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final l10n = context.l10n;
// // // // // //     final theme = context.theme;

// // // // // //     return Scaffold(
// // // // // //       body: NestedScrollView(
// // // // // //         headerSliverBuilder: (_, __) => [
// // // // // //           SliverAppBar(
// // // // // //             floating: true,
// // // // // //             snap: true,
// // // // // //             title: Text(l10n.roomsTitle),
// // // // // //             actions: [
// // // // // //               IconButton(
// // // // // //                 onPressed: _joinByCode,
// // // // // //                 icon: const Icon(Icons.qr_code_scanner_rounded),
// // // // // //                 tooltip: l10n.roomsJoinCode,
// // // // // //               ),
// // // // // //             ],
// // // // // //             bottom: PreferredSize(
// // // // // //               preferredSize: const Size.fromHeight(48),
// // // // // //               child: _GameTypeFilterBar(
// // // // // //                 selected: _gameTypeFilter,
// // // // // //                 onChanged: (f) {
// // // // // //                   setState(() => _gameTypeFilter = f);
// // // // // //                   _loadRooms();
// // // // // //                 },
// // // // // //               ),
// // // // // //             ),
// // // // // //           ),
// // // // // //         ],
// // // // // //         body: RefreshIndicator(
// // // // // //           onRefresh: _loadRooms,
// // // // // //           child: _buildBody(theme, l10n),
// // // // // //         ),
// // // // // //       ),
// // // // // //       floatingActionButton: FloatingActionButton.extended(
// // // // // //         heroTag: 'room_browser_create_fab',
// // // // // //         onPressed: _createRoom,
// // // // // //         icon: const Icon(Icons.add_rounded),
// // // // // //         label: Text(l10n.roomsCreate),
// // // // // //         backgroundColor: theme.colorScheme.primary,
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   Widget _buildBody(ThemeData theme, dynamic l10n) {
// // // // // //     if (_isLoading) {
// // // // // //       return _LoadingGrid();
// // // // // //     }
// // // // // //     if (_hasError) {
// // // // // //       return ErrorView(
// // // // // //         message: context.l10n.errorUnexpected,
// // // // // //         onRetry: _loadRooms,
// // // // // //       );
// // // // // //     }
// // // // // //     if (_rooms.isEmpty) {
// // // // // //       return JEmptyState(
// // // // // //         emoji: '🚪',
// // // // // //         title: l10n.roomsEmpty,
// // // // // //         subtitle: l10n.roomsEmptySubtitle,
// // // // // //         action: FilledButton.icon(
// // // // // //           onPressed: _createRoom,
// // // // // //           icon: const Icon(Icons.add_rounded),
// // // // // //           label: Text(l10n.roomsCreate),
// // // // // //         ),
// // // // // //       );
// // // // // //     }
// // // // // //     return ListView.separated(
// // // // // //       padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
// // // // // //       itemCount: _rooms.length,
// // // // // //       separatorBuilder: (_, __) => const SizedBox(height: 10),
// // // // // //       itemBuilder: (_, i) => RoomCard(
// // // // // //         room: _rooms[i],
// // // // // //         onTap: () => AppRouter.router.push('/home/room/${_rooms[i].id}'),
// // // // // //       ).animate(delay: (i * 35).ms).fadeIn().slideY(begin: 0.06, end: 0),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // class _GameTypeFilterBar extends StatelessWidget {
// // // // // //   const _GameTypeFilterBar({required this.selected, required this.onChanged});
// // // // // //   final String? selected;
// // // // // //   final void Function(String?) onChanged;

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     const filters = [
// // // // // //       (null, 'All', '🎮'),
// // // // // //       ('truth_or_dare', 'Truth or Dare', '🎯'),
// // // // // //       ('never_have_i_ever', 'Never Have I', '🍹'),
// // // // // //       ('meme_game', 'Meme Game', '😂'),
// // // // // //     ];

// // // // // //     return SizedBox(
// // // // // //       height: 48,
// // // // // //       child: ListView(
// // // // // //         scrollDirection: Axis.horizontal,
// // // // // //         padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
// // // // // //         children: filters.map((f) {
// // // // // //           final isSelected = selected == f.$1;
// // // // // //           return Padding(
// // // // // //             padding: const EdgeInsets.only(right: 8),
// // // // // //             child: FilterChip(
// // // // // //               label: Text('${f.$3} ${f.$2}'),
// // // // // //               selected: isSelected,
// // // // // //               onSelected: (_) => onChanged(isSelected ? null : f.$1),
// // // // // //               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
// // // // // //             ),
// // // // // //           );
// // // // // //         }).toList(),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // class _LoadingGrid extends StatelessWidget {
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return ListView(
// // // // // //       padding: const EdgeInsets.all(16),
// // // // // //       children: List.generate(
// // // // // //         4,
// // // // // //         (i) => Padding(
// // // // // //           padding: const EdgeInsets.only(bottom: 12),
// // // // // //           child: ShimmerBox(width: double.infinity, height: 88, radius: 16),
// // // // // //         ).animate(delay: (i * 60).ms).fadeIn(),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // import 'dart:async';
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // import 'package:go_router/go_router.dart';
// // // // // import 'package:jma3a/deep_links.dart';
// // // // // import 'package:provider/provider.dart';
// // // // // import '../../../../core/di/service_locator.dart';
// // // // // // import '../../../../core/services/deep_link_service.dart';
// // // // // import '../../../../core/extensions/context_ext.dart';
// // // // // import '../../../../core/providers/auth_provider.dart';
// // // // // import '../../../../core/router/route_names.dart';
// // // // // import '../../../../core/router/app_router.dart';
// // // // // import '../../../../core/storage/database/app_database.dart';
// // // // // import '../../../../core/theme/app_colors.dart';
// // // // // import '../../../../shared/widgets/cards/j_card.dart';
// // // // // import '../../../../shared/widgets/feedback/error_view.dart';
// // // // // import '../../data/room_cache_service.dart';
// // // // // import '../../domain/room_entity.dart';
// // // // // import '../widgets/create_room_sheet.dart';
// // // // // import '../widgets/join_code_dialog.dart';
// // // // // import '../widgets/room_card.dart';

// // // // // class RoomBrowserScreen extends StatefulWidget {
// // // // //   const RoomBrowserScreen({super.key});
// // // // //   @override
// // // // //   State<RoomBrowserScreen> createState() => _RoomBrowserScreenState();
// // // // // }

// // // // // class _RoomBrowserScreenState extends State<RoomBrowserScreen>
// // // // //     with WidgetsBindingObserver {
// // // // //   List<RoomEntity> _rooms = [];
// // // // //   bool _isLoading = true;
// // // // //   bool _hasError = false;
// // // // //   String? _gameTypeFilter;
// // // // //   Timer? _autoRefreshTimer;
// // // // //   StreamSubscription<RoomInvitePayload>? _deepLinkSub;

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     WidgetsBinding.instance.addObserver(this);
// // // // //     // Clean up any lingering realtime subscriptions from previous rooms
// // // // //     try {
// // // // //       sl.realtimeService.unsubscribeAll();
// // // // //     } catch (_) {}
// // // // //     _loadRooms(fromCache: true);
// // // // //     // Listen for deep link invite codes
// // // // //     _deepLinkSub = DeepLinkService.instance.inviteStream.listen(_onInvite);
// // // // //     // Auto-refresh every 30 seconds while screen is active
// // // // //     _autoRefreshTimer = Timer.periodic(
// // // // //       const Duration(seconds: 30),
// // // // //       (_) => _loadRooms(),
// // // // //     );
// // // // //   }

// // // // //   @override
// // // // //   void dispose() {
// // // // //     WidgetsBinding.instance.removeObserver(this);
// // // // //     _autoRefreshTimer?.cancel();
// // // // //     _deepLinkSub?.cancel();
// // // // //     super.dispose();
// // // // //   }

// // // // //   @override
// // // // //   void didChangeAppLifecycleState(AppLifecycleState state) {
// // // // //     if (state == AppLifecycleState.resumed) _loadRooms();
// // // // //   }

// // // // //   Future<void> _loadRooms({bool fromCache = false}) async {
// // // // //     if (fromCache) {
// // // // //       // Show cached rooms instantly (no-op if DB not ready yet)
// // // // //       final cached = await RoomCacheService.instance.getCachedRooms();
// // // // //       if (cached.isNotEmpty && mounted) {
// // // // //         setState(() {
// // // // //           _rooms = cached;
// // // // //           _isLoading = false;
// // // // //         });
// // // // //       }
// // // // //     }

// // // // //     if (!mounted) return;
// // // // //     setState(() {
// // // // //       _isLoading = _rooms.isEmpty;
// // // // //       _hasError = false;
// // // // //     });

// // // // //     try {
// // // // //       final userId = context.read<AuthProvider>().currentUser?.id;
// // // // //       final rooms = await sl.roomRepository.getPublicRooms(
// // // // //         gameTypeFilter: _gameTypeFilter,
// // // // //         userId: userId,
// // // // //       );
// // // // //       if (!mounted) return;
// // // // //       setState(() {
// // // // //         _rooms = rooms;
// // // // //         _isLoading = false;
// // // // //       });
// // // // //       await RoomCacheService.instance.cacheRooms(rooms);
// // // // //     } catch (e, st) {
// // // // //       debugPrint('RoomBrowser error: $e\n$st');
// // // // //       if (!mounted) return;
// // // // //       // Only show error UI if we have no rooms to show at all
// // // // //       setState(() {
// // // // //         _hasError = _rooms.isEmpty;
// // // // //         _isLoading = false;
// // // // //       });
// // // // //       // Silently retry once after a short delay
// // // // //       if (_rooms.isEmpty) {
// // // // //         await Future.delayed(const Duration(seconds: 2));
// // // // //         if (mounted) _loadRooms();
// // // // //       }
// // // // //     }
// // // // //   }

// // // // //   Future<void> _createRoom() async {
// // // // //     final user = context.read<AuthProvider>().currentUser;
// // // // //     if (user == null) return;

// // // // //     // ── Gate 1: only one active room per user (owned OR joined) ────────────
// // // // //     final active = await sl.roomRepository.getActiveMembership(user.id);
// // // // //     if (active != null) {
// // // // //       if (!mounted) return;
// // // // //       final isOwner = active['is_owner'] == true;
// // // // //       final isPaused = active['status'] == 'paused';
// // // // //       final goToRoom = await showDialog<bool>(
// // // // //         context: context,
// // // // //         builder: (ctx) => AlertDialog(
// // // // //           title: const Text("You're already in a room"),
// // // // //           content: Text(
// // // // //             isOwner
// // // // //                 ? (isPaused
// // // // //                       ? 'Your room "${active['room_name']}" is paused. Finish or close it before creating a new one.'
// // // // //                       : 'Your room "${active['room_name']}" is still open. Finish or close it before creating a new one.')
// // // // //                 : 'You\'re still in "${active['room_name']}". Leave it before creating a new room.',
// // // // //           ),
// // // // //           actions: [
// // // // //             TextButton(
// // // // //               onPressed: () => Navigator.pop(ctx, false),
// // // // //               child: const Text('Cancel'),
// // // // //             ),
// // // // //             FilledButton(
// // // // //               onPressed: () => Navigator.pop(ctx, true),
// // // // //               child: const Text('Go to Room'),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       );
// // // // //       if (goToRoom == true && mounted) {
// // // // //         AppRouter.router.push('/home/room/${active['room_id']}');
// // // // //       }
// // // // //       return;
// // // // //     }

// // // // //     // ── Gate 2: must have at least one pack available (owned or free) ──────
// // // // //     final myPacks = await sl.packRepository.getMyPurchasedPacks(user.id);
// // // // //     if (myPacks.isEmpty) {
// // // // //       final freeAvailable = await sl.packRepository.hasFreePacksAvailable();
// // // // //       if (!freeAvailable) {
// // // // //         if (!mounted) return;
// // // // //         await showDialog<void>(
// // // // //           context: context,
// // // // //           builder: (ctx) => AlertDialog(
// // // // //             title: const Text('No packs available'),
// // // // //             content: const Text(
// // // // //               "You need at least one pack to create a room — get a free pack or purchase one from the marketplace first.",
// // // // //             ),
// // // // //             actions: [
// // // // //               TextButton(
// // // // //                 onPressed: () => Navigator.pop(ctx),
// // // // //                 child: const Text('Cancel'),
// // // // //               ),
// // // // //               FilledButton(
// // // // //                 onPressed: () {
// // // // //                   Navigator.pop(ctx);
// // // // //                   AppRouter.router.go(RouteNames.marketplace);
// // // // //                 },
// // // // //                 child: const Text('Browse Packs'),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //         );
// // // // //         return;
// // // // //       }
// // // // //     }

// // // // //     if (!mounted) return;
// // // // //     final room = await showModalBottomSheet<RoomEntity>(
// // // // //       context: context,
// // // // //       isScrollControlled: true,
// // // // //       backgroundColor: Colors.transparent,
// // // // //       builder: (_) => const CreateRoomSheet(),
// // // // //     );
// // // // //     if (room != null && mounted) {
// // // // //       AppRouter.router.push('/home/room/${room.id}');
// // // // //     }
// // // // //   }

// // // // //   Future<void> _onInvite(RoomInvitePayload payload) async {
// // // // //     if (!mounted) return;
// // // // //     final room = await showDialog<RoomEntity>(
// // // // //       context: context,
// // // // //       builder: (_) => JoinCodeDialog(
// // // // //         prefillCode: payload.code,
// // // // //         invitedBy: payload.invitedBy,
// // // // //       ),
// // // // //     );
// // // // //     if (room != null && mounted) AppRouter.router.push('/home/room/${room.id}');
// // // // //   }

// // // // //   /// Single entry point for navigating into any room (browsed or joined by
// // // // //   /// code). Stops a user from being a member of two rooms at once — if
// // // // //   /// they're already an active member of a different room, they must
// // // // //   /// explicitly choose to return to it or leave it for good first.
// // // // //   Future<void> _enterRoom(String targetRoomId) async {
// // // // //     final userId = context.read<AuthProvider>().currentUser?.id;
// // // // //     if (userId == null) return;

// // // // //     final active = await sl.roomRepository.getActiveMembership(userId);

// // // // //     // No active room, or it IS the room being entered — nothing to confirm.
// // // // //     if (active == null || active['room_id'] == targetRoomId) {
// // // // //       if (mounted) AppRouter.router.push('/home/room/$targetRoomId');
// // // // //       return;
// // // // //     }

// // // // //     if (!mounted) return;
// // // // //     final choice = await showDialog<String>(
// // // // //       context: context,
// // // // //       builder: (ctx) => AlertDialog(
// // // // //         title: const Text("You're already in a room"),
// // // // //         content: Text(
// // // // //           'You\'re still in "${active['room_name']}". You can\'t be a '
// // // // //           'player or spectator in two rooms at once — return to it, or '
// // // // //           'leave it for good to join this one instead.',
// // // // //         ),
// // // // //         actions: [
// // // // //           TextButton(
// // // // //             onPressed: () => Navigator.pop(ctx, 'cancel'),
// // // // //             child: const Text('Cancel'),
// // // // //           ),
// // // // //           FilledButton.tonal(
// // // // //             onPressed: () => Navigator.pop(ctx, 'return'),
// // // // //             child: const Text('Return to my room'),
// // // // //           ),
// // // // //           FilledButton(
// // // // //             style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // // // //             onPressed: () => Navigator.pop(ctx, 'leave'),
// // // // //             child: const Text('Leave for good'),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );

// // // // //     if (choice == null || choice == 'cancel' || !mounted) return;

// // // // //     if (choice == 'return') {
// // // // //       AppRouter.router.push('/home/room/${active['room_id']}');
// // // // //       return;
// // // // //     }

// // // // //     // choice == 'leave'
// // // // //     final oldRoomId = active['room_id'] as String;
// // // // //     final wasOwner = active['is_owner'] == true;
// // // // //     final wasActive = active['status'] != 'waiting';

// // // // //     await sl.roomRepository.forceLeaveRoom(userId: userId, roomId: oldRoomId);

// // // // //     // If they owned that room, close it for everyone else still in it too.
// // // // //     if (wasOwner) {
// // // // //       try {
// // // // //         if (wasActive) {
// // // // //           await sl.realtimeService.broadcastGameEnded(oldRoomId, {
// // // // //             'reason': 'host_left',
// // // // //           });
// // // // //         }
// // // // //         await sl.realtimeService.broadcastRoomEvent(oldRoomId, {
// // // // //           'type': 'owner_left',
// // // // //           'reason': 'host_left',
// // // // //         });
// // // // //       } catch (_) {}
// // // // //     }

// // // // //     if (mounted) AppRouter.router.push('/home/room/$targetRoomId');
// // // // //   }

// // // // //   Future<void> _joinByCode() async {
// // // // //     final room = await showDialog<RoomEntity>(
// // // // //       context: context,
// // // // //       builder: (_) => const JoinCodeDialog(),
// // // // //     );
// // // // //     if (room != null && mounted) {
// // // // //       await _enterRoom(room.id);
// // // // //     }
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final l10n = context.l10n;
// // // // //     final theme = context.theme;

// // // // //     return Scaffold(
// // // // //       body: NestedScrollView(
// // // // //         headerSliverBuilder: (_, __) => [
// // // // //           SliverAppBar(
// // // // //             floating: true,
// // // // //             snap: true,
// // // // //             title: Text(l10n.roomsTitle),
// // // // //             actions: [
// // // // //               IconButton(
// // // // //                 onPressed: _joinByCode,
// // // // //                 icon: const Icon(Icons.qr_code_scanner_rounded),
// // // // //                 tooltip: l10n.roomsJoinCode,
// // // // //               ),
// // // // //             ],
// // // // //             bottom: PreferredSize(
// // // // //               preferredSize: const Size.fromHeight(48),
// // // // //               child: _GameTypeFilterBar(
// // // // //                 selected: _gameTypeFilter,
// // // // //                 onChanged: (f) {
// // // // //                   setState(() => _gameTypeFilter = f);
// // // // //                   _loadRooms();
// // // // //                 },
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //         body: RefreshIndicator(
// // // // //           onRefresh: _loadRooms,
// // // // //           child: _buildBody(theme, l10n),
// // // // //         ),
// // // // //       ),
// // // // //       floatingActionButton: FloatingActionButton.extended(
// // // // //         heroTag: 'room_browser_create_fab',
// // // // //         onPressed: _createRoom,
// // // // //         icon: const Icon(Icons.add_rounded),
// // // // //         label: Text(l10n.roomsCreate),
// // // // //         backgroundColor: theme.colorScheme.primary,
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Widget _buildBody(ThemeData theme, dynamic l10n) {
// // // // //     if (_isLoading) {
// // // // //       return _LoadingGrid();
// // // // //     }
// // // // //     if (_hasError) {
// // // // //       return ErrorView(
// // // // //         message: context.l10n.errorUnexpected,
// // // // //         onRetry: _loadRooms,
// // // // //       );
// // // // //     }
// // // // //     if (_rooms.isEmpty) {
// // // // //       return JEmptyState(
// // // // //         emoji: '🚪',
// // // // //         title: l10n.roomsEmpty,
// // // // //         subtitle: l10n.roomsEmptySubtitle,
// // // // //         action: FilledButton.icon(
// // // // //           onPressed: _createRoom,
// // // // //           icon: const Icon(Icons.add_rounded),
// // // // //           label: Text(l10n.roomsCreate),
// // // // //         ),
// // // // //       );
// // // // //     }
// // // // //     return ListView.separated(
// // // // //       padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
// // // // //       itemCount: _rooms.length,
// // // // //       separatorBuilder: (_, __) => const SizedBox(height: 10),
// // // // //       itemBuilder: (_, i) => RoomCard(
// // // // //         room: _rooms[i],
// // // // //         onTap: () => _enterRoom(_rooms[i].id),
// // // // //       ).animate(delay: (i * 35).ms).fadeIn().slideY(begin: 0.06, end: 0),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _GameTypeFilterBar extends StatelessWidget {
// // // // //   const _GameTypeFilterBar({required this.selected, required this.onChanged});
// // // // //   final String? selected;
// // // // //   final void Function(String?) onChanged;

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     const filters = [
// // // // //       (null, 'All', '🎮'),
// // // // //       ('truth_or_dare', 'Truth or Dare', '🎯'),
// // // // //       ('never_have_i_ever', 'Never Have I', '🍹'),
// // // // //       ('meme_game', 'Meme Game', '😂'),
// // // // //     ];

// // // // //     return SizedBox(
// // // // //       height: 48,
// // // // //       child: ListView(
// // // // //         scrollDirection: Axis.horizontal,
// // // // //         padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
// // // // //         children: filters.map((f) {
// // // // //           final isSelected = selected == f.$1;
// // // // //           return Padding(
// // // // //             padding: const EdgeInsets.only(right: 8),
// // // // //             child: FilterChip(
// // // // //               label: Text('${f.$3} ${f.$2}'),
// // // // //               selected: isSelected,
// // // // //               onSelected: (_) => onChanged(isSelected ? null : f.$1),
// // // // //               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
// // // // //             ),
// // // // //           );
// // // // //         }).toList(),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _LoadingGrid extends StatelessWidget {
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return ListView(
// // // // //       padding: const EdgeInsets.all(16),
// // // // //       children: List.generate(
// // // // //         4,
// // // // //         (i) => Padding(
// // // // //           padding: const EdgeInsets.only(bottom: 12),
// // // // //           child: ShimmerBox(width: double.infinity, height: 88, radius: 16),
// // // // //         ).animate(delay: (i * 60).ms).fadeIn(),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // import 'dart:async';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // import 'package:go_router/go_router.dart';
// // // // import 'package:jma3a/deep_links.dart';
// // // // import 'package:provider/provider.dart';
// // // // import '../../../../core/di/service_locator.dart';
// // // // // import '../../../../core/services/deep_link_service.dart';
// // // // import '../../../../core/extensions/context_ext.dart';
// // // // import '../../../../core/providers/auth_provider.dart';
// // // // import '../../../../core/router/route_names.dart';
// // // // import '../../../../core/router/app_router.dart';
// // // // import '../../../../core/storage/database/app_database.dart';
// // // // import '../../../../core/theme/app_colors.dart';
// // // // import '../../../../shared/widgets/cards/j_card.dart';
// // // // import '../../../../shared/widgets/feedback/error_view.dart';
// // // // import '../../data/room_cache_service.dart';
// // // // import '../../domain/room_entity.dart';
// // // // import '../widgets/create_room_sheet.dart';
// // // // import '../widgets/join_code_dialog.dart';
// // // // import '../widgets/room_card.dart';

// // // // class RoomBrowserScreen extends StatefulWidget {
// // // //   const RoomBrowserScreen({super.key});
// // // //   @override
// // // //   State<RoomBrowserScreen> createState() => _RoomBrowserScreenState();
// // // // }

// // // // class _RoomBrowserScreenState extends State<RoomBrowserScreen>
// // // //     with WidgetsBindingObserver {
// // // //   List<RoomEntity> _rooms = [];
// // // //   bool _isLoading = true;
// // // //   bool _hasError = false;
// // // //   String? _gameTypeFilter;
// // // //   Timer? _autoRefreshTimer;
// // // //   StreamSubscription<RoomInvitePayload>? _deepLinkSub;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     WidgetsBinding.instance.addObserver(this);
// // // //     // Clean up any lingering realtime subscriptions from previous rooms
// // // //     try {
// // // //       sl.realtimeService.unsubscribeAll();
// // // //     } catch (_) {}
// // // //     _loadRooms(fromCache: true);
// // // //     // Listen for deep link invite codes
// // // //     _deepLinkSub = DeepLinkService.instance.inviteStream.listen(_onInvite);
// // // //     // Auto-refresh every 30 seconds while screen is active
// // // //     _autoRefreshTimer = Timer.periodic(
// // // //       const Duration(seconds: 30),
// // // //       (_) => _loadRooms(),
// // // //     );
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     WidgetsBinding.instance.removeObserver(this);
// // // //     _autoRefreshTimer?.cancel();
// // // //     _deepLinkSub?.cancel();
// // // //     super.dispose();
// // // //   }

// // // //   @override
// // // //   void didChangeAppLifecycleState(AppLifecycleState state) {
// // // //     if (state == AppLifecycleState.resumed) _loadRooms();
// // // //   }

// // // //   Future<void> _loadRooms({bool fromCache = false}) async {
// // // //     if (fromCache) {
// // // //       // Show cached rooms instantly (no-op if DB not ready yet)
// // // //       final cached = await RoomCacheService.instance.getCachedRooms();
// // // //       if (cached.isNotEmpty && mounted) {
// // // //         setState(() {
// // // //           _rooms = cached;
// // // //           _isLoading = false;
// // // //         });
// // // //       }
// // // //     }

// // // //     if (!mounted) return;
// // // //     setState(() {
// // // //       _isLoading = _rooms.isEmpty;
// // // //       _hasError = false;
// // // //     });

// // // //     try {
// // // //       final userId = context.read<AuthProvider>().currentUser?.id;
// // // //       final rooms = await sl.roomRepository.getPublicRooms(
// // // //         gameTypeFilter: _gameTypeFilter,
// // // //         userId: userId,
// // // //       );
// // // //       if (!mounted) return;
// // // //       setState(() {
// // // //         _rooms = rooms;
// // // //         _isLoading = false;
// // // //       });
// // // //       await RoomCacheService.instance.cacheRooms(rooms);
// // // //     } catch (e, st) {
// // // //       debugPrint('RoomBrowser error: $e\n$st');
// // // //       if (!mounted) return;
// // // //       // Only show error UI if we have no rooms to show at all
// // // //       setState(() {
// // // //         _hasError = _rooms.isEmpty;
// // // //         _isLoading = false;
// // // //       });
// // // //       // Silently retry once after a short delay
// // // //       if (_rooms.isEmpty) {
// // // //         await Future.delayed(const Duration(seconds: 2));
// // // //         if (mounted) _loadRooms();
// // // //       }
// // // //     }
// // // //   }

// // // //   Future<void> _createRoom() async {
// // // //     final user = context.read<AuthProvider>().currentUser;
// // // //     if (user == null) return;

// // // //     // ── Gate 1: only one active room per user (owned OR joined) ────────────
// // // //     final active = await sl.roomRepository.getActiveMembership(user.id);
// // // //     if (active != null) {
// // // //       if (!mounted) return;
// // // //       final isOwner = active['is_owner'] == true;
// // // //       final isPaused = active['status'] == 'paused';
// // // //       final goToRoom = await showDialog<bool>(
// // // //         context: context,
// // // //         builder: (ctx) => AlertDialog(
// // // //           title: const Text("You're already in a room"),
// // // //           content: Text(
// // // //             isOwner
// // // //                 ? (isPaused
// // // //                       ? 'Your room "${active['room_name']}" is paused. Finish or close it before creating a new one.'
// // // //                       : 'Your room "${active['room_name']}" is still open. Finish or close it before creating a new one.')
// // // //                 : 'You\'re still in "${active['room_name']}". Leave it before creating a new room.',
// // // //           ),
// // // //           actions: [
// // // //             TextButton(
// // // //               onPressed: () => Navigator.pop(ctx, false),
// // // //               child: const Text('Cancel'),
// // // //             ),
// // // //             FilledButton(
// // // //               onPressed: () => Navigator.pop(ctx, true),
// // // //               child: const Text('Go to Room'),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       );
// // // //       if (goToRoom == true && mounted) {
// // // //         AppRouter.router.push('/home/room/${active['room_id']}');
// // // //       }
// // // //       return;
// // // //     }

// // // //     // ── Gate 2: must have at least one pack available (owned or free) ──────
// // // //     final myPacks = await sl.packRepository.getMyPurchasedPacks(user.id);
// // // //     if (myPacks.isEmpty) {
// // // //       final freeAvailable = await sl.packRepository.hasFreePacksAvailable();
// // // //       if (!freeAvailable) {
// // // //         if (!mounted) return;
// // // //         await showDialog<void>(
// // // //           context: context,
// // // //           builder: (ctx) => AlertDialog(
// // // //             title: const Text('No packs available'),
// // // //             content: const Text(
// // // //               "You need at least one pack to create a room — get a free pack or purchase one from the marketplace first.",
// // // //             ),
// // // //             actions: [
// // // //               TextButton(
// // // //                 onPressed: () => Navigator.pop(ctx),
// // // //                 child: const Text('Cancel'),
// // // //               ),
// // // //               FilledButton(
// // // //                 onPressed: () {
// // // //                   Navigator.pop(ctx);
// // // //                   AppRouter.router.go(RouteNames.marketplace);
// // // //                 },
// // // //                 child: const Text('Browse Packs'),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         );
// // // //         return;
// // // //       }
// // // //     }

// // // //     // ── Gate 3: daily room-creation quota ────────────────────────────────────
// // // //     final isPremium =
// // // //         context.read<AuthProvider>().currentUser?.isPremium ?? false;
// // // //     final hitLimit = await sl.roomRepository.hasHitDailyRoomLimit(
// // // //       userId: user.id,
// // // //       isPremium: isPremium,
// // // //     );
// // // //     if (hitLimit) {
// // // //       if (!mounted) return;
// // // //       await showDialog<void>(
// // // //         context: context,
// // // //         builder: (ctx) => AlertDialog(
// // // //           title: const Text('Daily limit reached'),
// // // //           content: Text(
// // // //             isPremium
// // // //                 ? 'Premium plan allows 1 room per day. Your room from today is still active — finish or close it first, or try again tomorrow.'
// // // //                 : 'Free plan allows 2 rooms per day. Try again tomorrow, or upgrade to premium for a higher-quality room experience.',
// // // //           ),
// // // //           actions: [
// // // //             TextButton(
// // // //               onPressed: () => Navigator.pop(ctx),
// // // //               child: const Text('OK'),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       );
// // // //       return;
// // // //     }

// // // //     if (!mounted) return;
// // // //     final room = await showModalBottomSheet<RoomEntity>(
// // // //       context: context,
// // // //       isScrollControlled: true,
// // // //       backgroundColor: Colors.transparent,
// // // //       builder: (_) => const CreateRoomSheet(),
// // // //     );
// // // //     if (room != null && mounted) {
// // // //       AppRouter.router.push('/home/room/${room.id}');
// // // //       // Public rooms auto-notify friends to join — private rooms rely on
// // // //       // explicit per-friend invites instead (no auto-blast).
// // // //       if (room.visibility == RoomVisibility.public) {
// // // //         sl.roomRepository.notifyFriendsRoomCreated(room.id).catchError((_) {
// // // //           // Best-effort — room creation itself already succeeded, a failed
// // // //           // notification shouldn't surface as an error to the creator.
// // // //         });
// // // //       }
// // // //     }
// // // //   }

// // // //   Future<void> _onInvite(RoomInvitePayload payload) async {
// // // //     if (!mounted) return;
// // // //     final room = await showDialog<RoomEntity>(
// // // //       context: context,
// // // //       builder: (_) => JoinCodeDialog(
// // // //         prefillCode: payload.code,
// // // //         invitedBy: payload.invitedBy,
// // // //       ),
// // // //     );
// // // //     if (room != null && mounted) AppRouter.router.push('/home/room/${room.id}');
// // // //   }

// // // //   /// Single entry point for navigating into any room (browsed or joined by
// // // //   /// code). Stops a user from being a member of two rooms at once — if
// // // //   /// they're already an active member of a different room, they must
// // // //   /// explicitly choose to return to it or leave it for good first.
// // // //   Future<void> _enterRoom(String targetRoomId) async {
// // // //     final userId = context.read<AuthProvider>().currentUser?.id;
// // // //     if (userId == null) return;

// // // //     final active = await sl.roomRepository.getActiveMembership(userId);

// // // //     // No active room, or it IS the room being entered — nothing to confirm.
// // // //     if (active == null || active['room_id'] == targetRoomId) {
// // // //       if (mounted) AppRouter.router.push('/home/room/$targetRoomId');
// // // //       return;
// // // //     }

// // // //     if (!mounted) return;
// // // //     final choice = await showDialog<String>(
// // // //       context: context,
// // // //       builder: (ctx) => AlertDialog(
// // // //         title: const Text("You're already in a room"),
// // // //         content: Text(
// // // //           'You\'re still in "${active['room_name']}". You can\'t be a '
// // // //           'player or spectator in two rooms at once — return to it, or '
// // // //           'leave it for good to join this one instead.',
// // // //         ),
// // // //         actions: [
// // // //           TextButton(
// // // //             onPressed: () => Navigator.pop(ctx, 'cancel'),
// // // //             child: const Text('Cancel'),
// // // //           ),
// // // //           FilledButton.tonal(
// // // //             onPressed: () => Navigator.pop(ctx, 'return'),
// // // //             child: const Text('Return to my room'),
// // // //           ),
// // // //           FilledButton(
// // // //             style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // // //             onPressed: () => Navigator.pop(ctx, 'leave'),
// // // //             child: const Text('Leave for good'),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );

// // // //     if (choice == null || choice == 'cancel' || !mounted) return;

// // // //     if (choice == 'return') {
// // // //       AppRouter.router.push('/home/room/${active['room_id']}');
// // // //       return;
// // // //     }

// // // //     // choice == 'leave'
// // // //     final oldRoomId = active['room_id'] as String;
// // // //     final wasOwner = active['is_owner'] == true;
// // // //     final wasActive = active['status'] != 'waiting';

// // // //     await sl.roomRepository.forceLeaveRoom(userId: userId, roomId: oldRoomId);

// // // //     // If they owned that room, close it for everyone else still in it too.
// // // //     if (wasOwner) {
// // // //       try {
// // // //         if (wasActive) {
// // // //           await sl.realtimeService.broadcastGameEnded(oldRoomId, {
// // // //             'reason': 'host_left',
// // // //           });
// // // //         }
// // // //         await sl.realtimeService.broadcastRoomEvent(oldRoomId, {
// // // //           'type': 'owner_left',
// // // //           'reason': 'host_left',
// // // //         });
// // // //       } catch (_) {}
// // // //     }

// // // //     if (mounted) AppRouter.router.push('/home/room/$targetRoomId');
// // // //   }

// // // //   Future<void> _joinByCode() async {
// // // //     final room = await showDialog<RoomEntity>(
// // // //       context: context,
// // // //       builder: (_) => const JoinCodeDialog(),
// // // //     );
// // // //     if (room != null && mounted) {
// // // //       await _enterRoom(room.id);
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final l10n = context.l10n;
// // // //     final theme = context.theme;

// // // //     return Scaffold(
// // // //       body: NestedScrollView(
// // // //         headerSliverBuilder: (_, __) => [
// // // //           SliverAppBar(
// // // //             floating: true,
// // // //             snap: true,
// // // //             title: Text(l10n.roomsTitle),
// // // //             actions: [
// // // //               IconButton(
// // // //                 onPressed: _joinByCode,
// // // //                 icon: const Icon(Icons.qr_code_scanner_rounded),
// // // //                 tooltip: l10n.roomsJoinCode,
// // // //               ),
// // // //             ],
// // // //             bottom: PreferredSize(
// // // //               preferredSize: const Size.fromHeight(48),
// // // //               child: _GameTypeFilterBar(
// // // //                 selected: _gameTypeFilter,
// // // //                 onChanged: (f) {
// // // //                   setState(() => _gameTypeFilter = f);
// // // //                   _loadRooms();
// // // //                 },
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         ],
// // // //         body: RefreshIndicator(
// // // //           onRefresh: _loadRooms,
// // // //           child: _buildBody(theme, l10n),
// // // //         ),
// // // //       ),
// // // //       floatingActionButton: FloatingActionButton.extended(
// // // //         heroTag: 'room_browser_create_fab',
// // // //         onPressed: _createRoom,
// // // //         icon: const Icon(Icons.add_rounded),
// // // //         label: Text(l10n.roomsCreate),
// // // //         backgroundColor: theme.colorScheme.primary,
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildBody(ThemeData theme, dynamic l10n) {
// // // //     if (_isLoading) {
// // // //       return _LoadingGrid();
// // // //     }
// // // //     if (_hasError) {
// // // //       return ErrorView(
// // // //         message: context.l10n.errorUnexpected,
// // // //         onRetry: _loadRooms,
// // // //       );
// // // //     }
// // // //     if (_rooms.isEmpty) {
// // // //       return JEmptyState(
// // // //         emoji: '🚪',
// // // //         title: l10n.roomsEmpty,
// // // //         subtitle: l10n.roomsEmptySubtitle,
// // // //         action: FilledButton.icon(
// // // //           onPressed: _createRoom,
// // // //           icon: const Icon(Icons.add_rounded),
// // // //           label: Text(l10n.roomsCreate),
// // // //         ),
// // // //       );
// // // //     }
// // // //     return ListView.separated(
// // // //       padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
// // // //       itemCount: _rooms.length,
// // // //       separatorBuilder: (_, __) => const SizedBox(height: 10),
// // // //       itemBuilder: (_, i) => RoomCard(
// // // //         room: _rooms[i],
// // // //         onTap: () => _enterRoom(_rooms[i].id),
// // // //       ).animate(delay: (i * 35).ms).fadeIn().slideY(begin: 0.06, end: 0),
// // // //     );
// // // //   }
// // // // }

// // // // class _GameTypeFilterBar extends StatelessWidget {
// // // //   const _GameTypeFilterBar({required this.selected, required this.onChanged});
// // // //   final String? selected;
// // // //   final void Function(String?) onChanged;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     const filters = [
// // // //       (null, 'All', '🎮'),
// // // //       ('truth_or_dare', 'Truth or Dare', '🎯'),
// // // //       ('never_have_i_ever', 'Never Have I', '🍹'),
// // // //       ('meme_game', 'Meme Game', '😂'),
// // // //     ];

// // // //     return SizedBox(
// // // //       height: 48,
// // // //       child: ListView(
// // // //         scrollDirection: Axis.horizontal,
// // // //         padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
// // // //         children: filters.map((f) {
// // // //           final isSelected = selected == f.$1;
// // // //           return Padding(
// // // //             padding: const EdgeInsets.only(right: 8),
// // // //             child: FilterChip(
// // // //               label: Text('${f.$3} ${f.$2}'),
// // // //               selected: isSelected,
// // // //               onSelected: (_) => onChanged(isSelected ? null : f.$1),
// // // //               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
// // // //             ),
// // // //           );
// // // //         }).toList(),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _LoadingGrid extends StatelessWidget {
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return ListView(
// // // //       padding: const EdgeInsets.all(16),
// // // //       children: List.generate(
// // // //         4,
// // // //         (i) => Padding(
// // // //           padding: const EdgeInsets.only(bottom: 12),
// // // //           child: ShimmerBox(width: double.infinity, height: 88, radius: 16),
// // // //         ).animate(delay: (i * 60).ms).fadeIn(),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // import 'dart:async';
// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_animate/flutter_animate.dart';
// // // import 'package:go_router/go_router.dart';
// // // import 'package:jma3a/deep_links.dart';
// // // import 'package:provider/provider.dart';
// // // import '../../../../core/di/service_locator.dart';
// // // import '../../../../core/extensions/context_ext.dart';
// // // import '../../../../core/providers/auth_provider.dart';
// // // import '../../../../core/router/route_names.dart';
// // // import '../../../../core/router/app_router.dart';
// // // import '../../../../core/storage/database/app_database.dart';
// // // import '../../../../core/theme/app_colors.dart';
// // // import '../../../../shared/widgets/cards/j_card.dart';
// // // import '../../../../shared/widgets/feedback/error_view.dart';
// // // import '../../data/room_cache_service.dart';
// // // import '../../domain/room_entity.dart';
// // // import '../widgets/create_room_sheet.dart';
// // // import '../widgets/join_code_dialog.dart';
// // // import '../widgets/room_card.dart';

// // // class RoomBrowserScreen extends StatefulWidget {
// // //   const RoomBrowserScreen({super.key});
// // //   @override
// // //   State<RoomBrowserScreen> createState() => _RoomBrowserScreenState();
// // // }

// // // class _RoomBrowserScreenState extends State<RoomBrowserScreen>
// // //     with WidgetsBindingObserver {
// // //   List<RoomEntity> _rooms = [];
// // //   bool _isLoading = true;
// // //   bool _hasError = false;
// // //   String? _gameTypeFilter;
// // //   Timer? _autoRefreshTimer;
// // //   StreamSubscription<RoomInvitePayload>? _deepLinkSub;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     WidgetsBinding.instance.addObserver(this);
// // //     try {
// // //       sl.realtimeService.unsubscribeAll();
// // //     } catch (_) {}
// // //     _loadRooms(fromCache: true);
// // //     _deepLinkSub = DeepLinkService.instance.inviteStream.listen(_onInvite);
// // //     _autoRefreshTimer = Timer.periodic(
// // //       const Duration(seconds: 30),
// // //       (_) => _loadRooms(),
// // //     );
// // //   }

// // //   @override
// // //   void dispose() {
// // //     WidgetsBinding.instance.removeObserver(this);
// // //     _autoRefreshTimer?.cancel();
// // //     _deepLinkSub?.cancel();
// // //     super.dispose();
// // //   }

// // //   @override
// // //   void didChangeAppLifecycleState(AppLifecycleState state) {
// // //     if (state == AppLifecycleState.resumed) _loadRooms();
// // //   }

// // //   Future<void> _loadRooms({bool fromCache = false}) async {
// // //     if (fromCache) {
// // //       final cached = await RoomCacheService.instance.getCachedRooms();
// // //       if (cached.isNotEmpty && mounted) {
// // //         setState(() {
// // //           _rooms = cached;
// // //           _isLoading = false;
// // //         });
// // //       }
// // //     }

// // //     if (!mounted) return;
// // //     setState(() {
// // //       _isLoading = _rooms.isEmpty;
// // //       _hasError = false;
// // //     });

// // //     try {
// // //       final userId = context.read<AuthProvider>().currentUser?.id;
// // //       final rooms = await sl.roomRepository.getPublicRooms(
// // //         gameTypeFilter: _gameTypeFilter,
// // //         userId: userId,
// // //       );
// // //       if (!mounted) return;
// // //       setState(() {
// // //         _rooms = rooms;
// // //         _isLoading = false;
// // //       });
// // //       await RoomCacheService.instance.cacheRooms(rooms);
// // //     } catch (e, st) {
// // //       debugPrint('RoomBrowser error: $e\n$st');
// // //       if (!mounted) return;
// // //       setState(() {
// // //         _hasError = _rooms.isEmpty;
// // //         _isLoading = false;
// // //       });
// // //       if (_rooms.isEmpty) {
// // //         await Future.delayed(const Duration(seconds: 2));
// // //         if (mounted) _loadRooms();
// // //       }
// // //     }
// // //   }

// // //   Future<void> _createRoom() async {
// // //     final user = context.read<AuthProvider>().currentUser;
// // //     if (user == null) return;

// // //     final active = await sl.roomRepository.getActiveMembership(user.id);
// // //     if (active != null) {
// // //       if (!mounted) return;
// // //       final isOwner = active['is_owner'] == true;
// // //       final isPaused = active['status'] == 'paused';
// // //       final goToRoom = await showDialog<bool>(
// // //         context: context,
// // //         builder: (ctx) => AlertDialog(
// // //           title: const Text("You're already in a room"),
// // //           content: Text(
// // //             isOwner
// // //                 ? (isPaused
// // //                       ? 'Your room "${active['room_name']}" is paused. Finish or close it before creating a new one.'
// // //                       : 'Your room "${active['room_name']}" is still open. Finish or close it before creating a new one.')
// // //                 : 'You\'re still in "${active['room_name']}". Leave it before creating a new room.',
// // //           ),
// // //           actions: [
// // //             TextButton(
// // //               onPressed: () => Navigator.pop(ctx, false),
// // //               child: const Text('Cancel'),
// // //             ),
// // //             FilledButton(
// // //               onPressed: () => Navigator.pop(ctx, true),
// // //               child: const Text('Go to Room'),
// // //             ),
// // //           ],
// // //         ),
// // //       );
// // //       if (goToRoom == true && mounted) {
// // //         AppRouter.router.push('/home/room/${active['room_id']}');
// // //       }
// // //       return;
// // //     }

// // //     final myPacks = await sl.packRepository.getMyPurchasedPacks(user.id);
// // //     if (myPacks.isEmpty) {
// // //       final freeAvailable = await sl.packRepository.hasFreePacksAvailable();
// // //       if (!freeAvailable) {
// // //         if (!mounted) return;
// // //         await showDialog<void>(
// // //           context: context,
// // //           builder: (ctx) => AlertDialog(
// // //             title: const Text('No packs available'),
// // //             content: const Text(
// // //               "You need at least one pack to create a room — get a free pack or purchase one from the marketplace first.",
// // //             ),
// // //             actions: [
// // //               TextButton(
// // //                 onPressed: () => Navigator.pop(ctx),
// // //                 child: const Text('Cancel'),
// // //               ),
// // //               FilledButton(
// // //                 onPressed: () {
// // //                   Navigator.pop(ctx);
// // //                   AppRouter.router.go(RouteNames.marketplace);
// // //                 },
// // //                 child: const Text('Browse Packs'),
// // //               ),
// // //             ],
// // //           ),
// // //         );
// // //         return;
// // //       }
// // //     }

// // //     final isPremium =
// // //         context.read<AuthProvider>().currentUser?.isPremium ?? false;
// // //     final hitLimit = await sl.roomRepository.hasHitDailyRoomLimit(
// // //       userId: user.id,
// // //       isPremium: isPremium,
// // //     );
// // //     if (hitLimit) {
// // //       if (!mounted) return;
// // //       await showDialog<void>(
// // //         context: context,
// // //         builder: (ctx) => AlertDialog(
// // //           title: const Text('Daily limit reached'),
// // //           content: Text(
// // //             isPremium
// // //                 ? 'Premium plan allows 1 room per day. Your room from today is still active — finish or close it first, or try again tomorrow.'
// // //                 : 'Free plan allows 5 rooms per day. Try again tomorrow, or upgrade to premium for a higher-quality room experience.',
// // //           ),
// // //           actions: [
// // //             TextButton(
// // //               onPressed: () => Navigator.pop(ctx),
// // //               child: const Text('OK'),
// // //             ),
// // //           ],
// // //         ),
// // //       );
// // //       return;
// // //     }

// // //     if (!mounted) return;
// // //     final room = await showModalBottomSheet<RoomEntity>(
// // //       context: context,
// // //       isScrollControlled: true,
// // //       backgroundColor: Colors.transparent,
// // //       builder: (_) => const CreateRoomSheet(),
// // //     );
// // //     if (room != null && mounted) {
// // //       AppRouter.router.push('/home/room/${room.id}');
// // //       if (room.visibility == RoomVisibility.public) {
// // //         sl.roomRepository.notifyFriendsRoomCreated(room.id).catchError((_) {});
// // //       }
// // //     }
// // //   }

// // //   Future<void> _onInvite(RoomInvitePayload payload) async {
// // //     if (!mounted) return;
// // //     final room = await showDialog<RoomEntity>(
// // //       context: context,
// // //       builder: (_) => JoinCodeDialog(
// // //         prefillCode: payload.code,
// // //         invitedBy: payload.invitedBy,
// // //       ),
// // //     );
// // //     if (room != null && mounted) AppRouter.router.push('/home/room/${room.id}');
// // //   }

// // //   Future<void> _enterRoom(String targetRoomId) async {
// // //     final userId = context.read<AuthProvider>().currentUser?.id;
// // //     if (userId == null) return;

// // //     final active = await sl.roomRepository.getActiveMembership(userId);

// // //     if (active == null || active['room_id'] == targetRoomId) {
// // //       if (mounted) AppRouter.router.push('/home/room/$targetRoomId');
// // //       return;
// // //     }

// // //     if (!mounted) return;
// // //     final choice = await showDialog<String>(
// // //       context: context,
// // //       builder: (ctx) => AlertDialog(
// // //         title: const Text("You're already in a room"),
// // //         content: Text(
// // //           'You\'re still in "${active['room_name']}". You can\'t be a '
// // //           'player or spectator in two rooms at once — return to it, or '
// // //           'leave it for good to join this one instead.',
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Navigator.pop(ctx, 'cancel'),
// // //             child: const Text('Cancel'),
// // //           ),
// // //           FilledButton.tonal(
// // //             onPressed: () => Navigator.pop(ctx, 'return'),
// // //             child: const Text('Return to my room'),
// // //           ),
// // //           FilledButton(
// // //             style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // //             onPressed: () => Navigator.pop(ctx, 'leave'),
// // //             child: const Text('Leave for good'),
// // //           ),
// // //         ],
// // //       ),
// // //     );

// // //     if (choice == null || choice == 'cancel' || !mounted) return;

// // //     if (choice == 'return') {
// // //       AppRouter.router.push('/home/room/${active['room_id']}');
// // //       return;
// // //     }

// // //     final oldRoomId = active['room_id'] as String;
// // //     final wasOwner = active['is_owner'] == true;
// // //     final wasActive = active['status'] != 'waiting';

// // //     await sl.roomRepository.forceLeaveRoom(userId: userId, roomId: oldRoomId);

// // //     if (wasOwner) {
// // //       try {
// // //         if (wasActive) {
// // //           await sl.realtimeService.broadcastGameEnded(oldRoomId, {
// // //             'reason': 'host_left',
// // //           });
// // //         }
// // //         await sl.realtimeService.broadcastRoomEvent(oldRoomId, {
// // //           'type': 'owner_left',
// // //           'reason': 'host_left',
// // //         });
// // //       } catch (_) {}
// // //     }

// // //     if (mounted) AppRouter.router.push('/home/room/$targetRoomId');
// // //   }

// // //   Future<void> _joinByCode() async {
// // //     final room = await showDialog<RoomEntity>(
// // //       context: context,
// // //       builder: (_) => const JoinCodeDialog(),
// // //     );
// // //     if (room != null && mounted) {
// // //       await _enterRoom(room.id);
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final l10n = context.l10n;
// // //     final theme = context.theme;

// // //     return Scaffold(
// // //       body: NestedScrollView(
// // //         headerSliverBuilder: (_, __) => [
// // //           SliverAppBar(
// // //             floating: true,
// // //             snap: true,
// // //             title: Text(l10n.roomsTitle),
// // //             actions: [
// // //               IconButton(
// // //                 onPressed: _joinByCode,
// // //                 icon: const Icon(Icons.qr_code_scanner_rounded),
// // //                 tooltip: l10n.roomsJoinCode,
// // //               ),
// // //             ],
// // //             bottom: PreferredSize(
// // //               preferredSize: const Size.fromHeight(48),
// // //               child: _GameTypeFilterBar(
// // //                 selected: _gameTypeFilter,
// // //                 onChanged: (f) {
// // //                   setState(() => _gameTypeFilter = f);
// // //                   _loadRooms();
// // //                 },
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //         body: RefreshIndicator(
// // //           onRefresh: _loadRooms,
// // //           child: _buildBody(theme, l10n),
// // //         ),
// // //       ),
// // //       floatingActionButton: FloatingActionButton.extended(
// // //         heroTag: 'room_browser_create_fab',
// // //         onPressed: _createRoom,
// // //         icon: const Icon(Icons.add_rounded),
// // //         label: Text(l10n.roomsCreate),
// // //         backgroundColor: theme.colorScheme.primary,
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildBody(ThemeData theme, dynamic l10n) {
// // //     if (_isLoading) {
// // //       return _LoadingGrid();
// // //     }
// // //     if (_hasError) {
// // //       return ErrorView(
// // //         message: context.l10n.errorUnexpected,
// // //         onRetry: _loadRooms,
// // //       );
// // //     }
// // //     if (_rooms.isEmpty) {
// // //       return JEmptyState(
// // //         emoji: '🚪',
// // //         title: l10n.roomsEmpty,
// // //         subtitle: l10n.roomsEmptySubtitle,
// // //         action: FilledButton.icon(
// // //           onPressed: _createRoom,
// // //           icon: const Icon(Icons.add_rounded),
// // //           label: Text(l10n.roomsCreate),
// // //         ),
// // //       );
// // //     }
// // //     return ListView.separated(
// // //       padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
// // //       itemCount: _rooms.length,
// // //       separatorBuilder: (_, __) => const SizedBox(height: 10),
// // //       itemBuilder: (_, i) => RoomCard(
// // //         room: _rooms[i],
// // //         onTap: () => _enterRoom(_rooms[i].id),
// // //       ).animate(delay: (i * 35).ms).fadeIn().slideY(begin: 0.06, end: 0),
// // //     );
// // //   }
// // // }

// // // class _GameTypeFilterBar extends StatelessWidget {
// // //   const _GameTypeFilterBar({required this.selected, required this.onChanged});
// // //   final String? selected;
// // //   final void Function(String?) onChanged;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     const filters = [
// // //       (null, 'All', '🎮'),
// // //       ('truth_or_dare', 'Truth or Dare', '🎯'),
// // //       ('never_have_i_ever', 'Never Have I', '🍹'),
// // //       ('meme_game', 'Meme Game', '😂'),
// // //     ];

// // //     return SizedBox(
// // //       height: 48,
// // //       child: ListView(
// // //         scrollDirection: Axis.horizontal,
// // //         padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
// // //         children: filters.map((f) {
// // //           final isSelected = selected == f.$1;
// // //           return Padding(
// // //             padding: const EdgeInsets.only(right: 8),
// // //             child: FilterChip(
// // //               label: Text('${f.$3} ${f.$2}'),
// // //               selected: isSelected,
// // //               onSelected: (_) => onChanged(isSelected ? null : f.$1),
// // //               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
// // //             ),
// // //           );
// // //         }).toList(),
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _LoadingGrid extends StatelessWidget {
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return ListView(
// // //       padding: const EdgeInsets.all(16),
// // //       children: List.generate(
// // //         4,
// // //         (i) => Padding(
// // //           padding: const EdgeInsets.only(bottom: 12),
// // //           child: ShimmerBox(width: double.infinity, height: 88, radius: 16),
// // //         ).animate(delay: (i * 60).ms).fadeIn(),
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'dart:async';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:jma3a/deep_links.dart';
// // import 'package:provider/provider.dart';
// // import '../../../../core/di/service_locator.dart';
// // import '../../../../core/extensions/context_ext.dart';
// // import '../../../../core/providers/auth_provider.dart';
// // import '../../../../core/router/route_names.dart';
// // import '../../../../core/router/app_router.dart';
// // import '../../../../core/storage/database/app_database.dart';
// // import '../../../../core/theme/app_colors.dart';
// // import '../../../../shared/widgets/cards/j_card.dart';
// // import '../../../../shared/widgets/feedback/error_view.dart';
// // import '../../data/room_cache_service.dart';
// // import '../../domain/room_entity.dart';
// // import '../widgets/create_room_sheet.dart';
// // import '../widgets/join_code_dialog.dart';
// // import '../widgets/room_card.dart';

// // class RoomBrowserScreen extends StatefulWidget {
// //   const RoomBrowserScreen({super.key});
// //   @override
// //   State<RoomBrowserScreen> createState() => _RoomBrowserScreenState();
// // }

// // class _RoomBrowserScreenState extends State<RoomBrowserScreen>
// //     with WidgetsBindingObserver {
// //   List<RoomEntity> _rooms = [];
// //   bool _isLoading = true;
// //   bool _hasError = false;
// //   bool _isCreating = false;
// //   String? _gameTypeFilter;
// //   Timer? _autoRefreshTimer;
// //   StreamSubscription<RoomInvitePayload>? _deepLinkSub;

// //   @override
// //   void initState() {
// //     super.initState();
// //     WidgetsBinding.instance.addObserver(this);
// //     try {
// //       sl.realtimeService.unsubscribeAll();
// //     } catch (_) {}
// //     _loadRooms(fromCache: true);
// //     _deepLinkSub = DeepLinkService.instance.inviteStream.listen(_onInvite);
// //     _autoRefreshTimer = Timer.periodic(
// //       const Duration(seconds: 30),
// //       (_) => _loadRooms(),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     WidgetsBinding.instance.removeObserver(this);
// //     _autoRefreshTimer?.cancel();
// //     _deepLinkSub?.cancel();
// //     super.dispose();
// //   }

// //   @override
// //   void didChangeAppLifecycleState(AppLifecycleState state) {
// //     if (state == AppLifecycleState.resumed) _loadRooms();
// //   }

// //   Future<void> _loadRooms({bool fromCache = false}) async {
// //     if (fromCache) {
// //       final cached = await RoomCacheService.instance.getCachedRooms();
// //       if (cached.isNotEmpty && mounted) {
// //         setState(() {
// //           _rooms = cached;
// //           _isLoading = false;
// //         });
// //       }
// //     }

// //     if (!mounted) return;
// //     setState(() {
// //       _isLoading = _rooms.isEmpty;
// //       _hasError = false;
// //     });

// //     try {
// //       final userId = context.read<AuthProvider>().currentUser?.id;
// //       final rooms = await sl.roomRepository.getPublicRooms(
// //         gameTypeFilter: _gameTypeFilter,
// //         userId: userId,
// //       );
// //       if (!mounted) return;
// //       setState(() {
// //         _rooms = rooms;
// //         _isLoading = false;
// //       });
// //       await RoomCacheService.instance.cacheRooms(rooms);
// //     } catch (e, st) {
// //       debugPrint('RoomBrowser error: $e\n$st');
// //       if (!mounted) return;
// //       setState(() {
// //         _hasError = _rooms.isEmpty;
// //         _isLoading = false;
// //       });
// //       if (_rooms.isEmpty) {
// //         await Future.delayed(const Duration(seconds: 2));
// //         if (mounted) _loadRooms();
// //       }
// //     }
// //   }

// //   Future<void> _createRoom() async {
// //     if (_isCreating) return;
// //     setState(() => _isCreating = true);
// //     try {
// //       await _doCreateRoom();
// //     } finally {
// //       if (mounted) setState(() => _isCreating = false);
// //     }
// //   }

// //   Future<void> _doCreateRoom() async {
// //     final user = context.read<AuthProvider>().currentUser;
// //     if (user == null) return;

// //     final active = await sl.roomRepository.getActiveMembership(user.id);
// //     if (active != null) {
// //       if (!mounted) return;
// //       final isOwner = active['is_owner'] == true;
// //       final isPaused = active['status'] == 'paused';
// //       final goToRoom = await showDialog<bool>(
// //         context: context,
// //         builder: (ctx) => AlertDialog(
// //           title: const Text("You're already in a room"),
// //           content: Text(
// //             isOwner
// //                 ? (isPaused
// //                       ? 'Your room "${active['room_name']}" is paused. Finish or close it before creating a new one.'
// //                       : 'Your room "${active['room_name']}" is still open. Finish or close it before creating a new one.')
// //                 : 'You\'re still in "${active['room_name']}". Leave it before creating a new room.',
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.pop(ctx, false),
// //               child: const Text('Cancel'),
// //             ),
// //             FilledButton(
// //               onPressed: () => Navigator.pop(ctx, true),
// //               child: const Text('Go to Room'),
// //             ),
// //           ],
// //         ),
// //       );
// //       if (goToRoom == true && mounted) {
// //         AppRouter.router.push('/home/room/${active['room_id']}');
// //       }
// //       return;
// //     }

// //     final myPacks = await sl.packRepository.getMyPurchasedPacks(user.id);
// //     if (myPacks.isEmpty) {
// //       final freeAvailable = await sl.packRepository.hasFreePacksAvailable();
// //       if (!freeAvailable) {
// //         if (!mounted) return;
// //         await showDialog<void>(
// //           context: context,
// //           builder: (ctx) => AlertDialog(
// //             title: const Text('No packs available'),
// //             content: const Text(
// //               "You need at least one pack to create a room — get a free pack or purchase one from the marketplace first.",
// //             ),
// //             actions: [
// //               TextButton(
// //                 onPressed: () => Navigator.pop(ctx),
// //                 child: const Text('Cancel'),
// //               ),
// //               FilledButton(
// //                 onPressed: () {
// //                   Navigator.pop(ctx);
// //                   AppRouter.router.go(RouteNames.marketplace);
// //                 },
// //                 child: const Text('Browse Packs'),
// //               ),
// //             ],
// //           ),
// //         );
// //         return;
// //       }
// //     }

// //     final isPremium =
// //         context.read<AuthProvider>().currentUser?.isPremium ?? false;
// //     final hitLimit = await sl.roomRepository.hasHitDailyRoomLimit(
// //       userId: user.id,
// //       isPremium: isPremium,
// //     );
// //     if (hitLimit) {
// //       if (!mounted) return;
// //       await showDialog<void>(
// //         context: context,
// //         builder: (ctx) => AlertDialog(
// //           title: const Text('Daily limit reached'),
// //           content: Text(
// //             isPremium
// //                 ? 'Premium plan allows 1 room per day. Your room from today is still active — finish or close it first, or try again tomorrow.'
// //                 : 'Free plan allows 5 rooms per day. Try again tomorrow, or upgrade to premium for a higher-quality room experience.',
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.pop(ctx),
// //               child: const Text('OK'),
// //             ),
// //           ],
// //         ),
// //       );
// //       return;
// //     }

// //     if (!mounted) return;
// //     final room = await showModalBottomSheet<RoomEntity>(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder: (_) => const CreateRoomSheet(),
// //     );
// //     if (room != null && mounted) {
// //       AppRouter.router.push('/home/room/${room.id}');
// //       if (room.visibility == RoomVisibility.public) {
// //         sl.roomRepository.notifyFriendsRoomCreated(room.id).catchError((_) {});
// //       }
// //     }
// //   }

// //   Future<void> _onInvite(RoomInvitePayload payload) async {
// //     if (!mounted) return;
// //     final room = await showDialog<RoomEntity>(
// //       context: context,
// //       builder: (_) => JoinCodeDialog(
// //         prefillCode: payload.code,
// //         invitedBy: payload.invitedBy,
// //       ),
// //     );
// //     if (room != null && mounted) AppRouter.router.push('/home/room/${room.id}');
// //   }

// //   Future<void> _enterRoom(String targetRoomId) async {
// //     final userId = context.read<AuthProvider>().currentUser?.id;
// //     if (userId == null) return;

// //     final active = await sl.roomRepository.getActiveMembership(userId);

// //     if (active == null || active['room_id'] == targetRoomId) {
// //       if (mounted) AppRouter.router.push('/home/room/$targetRoomId');
// //       return;
// //     }

// //     if (!mounted) return;
// //     final choice = await showDialog<String>(
// //       context: context,
// //       builder: (ctx) => AlertDialog(
// //         title: const Text("You're already in a room"),
// //         content: Text(
// //           'You\'re still in "${active['room_name']}". You can\'t be a '
// //           'player or spectator in two rooms at once — return to it, or '
// //           'leave it for good to join this one instead.',
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(ctx, 'cancel'),
// //             child: const Text('Cancel'),
// //           ),
// //           FilledButton.tonal(
// //             onPressed: () => Navigator.pop(ctx, 'return'),
// //             child: const Text('Return to my room'),
// //           ),
// //           FilledButton(
// //             style: FilledButton.styleFrom(backgroundColor: Colors.red),
// //             onPressed: () => Navigator.pop(ctx, 'leave'),
// //             child: const Text('Leave for good'),
// //           ),
// //         ],
// //       ),
// //     );

// //     if (choice == null || choice == 'cancel' || !mounted) return;

// //     if (choice == 'return') {
// //       AppRouter.router.push('/home/room/${active['room_id']}');
// //       return;
// //     }

// //     final oldRoomId = active['room_id'] as String;
// //     final wasOwner = active['is_owner'] == true;
// //     final wasActive = active['status'] != 'waiting';

// //     await sl.roomRepository.forceLeaveRoom(userId: userId, roomId: oldRoomId);

// //     if (wasOwner) {
// //       try {
// //         if (wasActive) {
// //           await sl.realtimeService.broadcastGameEnded(oldRoomId, {
// //             'reason': 'host_left',
// //           });
// //         }
// //         await sl.realtimeService.broadcastRoomEvent(oldRoomId, {
// //           'type': 'owner_left',
// //           'reason': 'host_left',
// //         });
// //       } catch (_) {}
// //     }

// //     if (mounted) AppRouter.router.push('/home/room/$targetRoomId');
// //   }

// //   Future<void> _joinByCode() async {
// //     final room = await showDialog<RoomEntity>(
// //       context: context,
// //       builder: (_) => const JoinCodeDialog(),
// //     );
// //     if (room != null && mounted) {
// //       await _enterRoom(room.id);
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final l10n = context.l10n;
// //     final theme = context.theme;

// //     return Scaffold(
// //       body: NestedScrollView(
// //         headerSliverBuilder: (_, __) => [
// //           SliverAppBar(
// //             floating: true,
// //             snap: true,
// //             title: Text(l10n.roomsTitle),
// //             actions: [
// //               IconButton(
// //                 onPressed: _joinByCode,
// //                 icon: const Icon(Icons.qr_code_scanner_rounded),
// //                 tooltip: l10n.roomsJoinCode,
// //               ),
// //             ],
// //             bottom: PreferredSize(
// //               preferredSize: const Size.fromHeight(48),
// //               child: _GameTypeFilterBar(
// //                 selected: _gameTypeFilter,
// //                 onChanged: (f) {
// //                   setState(() => _gameTypeFilter = f);
// //                   _loadRooms();
// //                 },
// //               ),
// //             ),
// //           ),
// //         ],
// //         body: RefreshIndicator(
// //           onRefresh: _loadRooms,
// //           child: _buildBody(theme, l10n),
// //         ),
// //       ),
// //       floatingActionButton: FloatingActionButton.extended(
// //         heroTag: 'room_browser_create_fab',
// //         onPressed: _isCreating ? null : _createRoom,
// //         icon: _isCreating
// //             ? const SizedBox(
// //                 width: 18,
// //                 height: 18,
// //                 child: CircularProgressIndicator(
// //                   strokeWidth: 2,
// //                   color: Colors.white,
// //                 ),
// //               )
// //             : const Icon(Icons.add_rounded),
// //         label: Text(l10n.roomsCreate),
// //         backgroundColor: theme.colorScheme.primary,
// //       ),
// //     );
// //   }

// //   Widget _buildBody(ThemeData theme, dynamic l10n) {
// //     if (_isLoading) {
// //       return _LoadingGrid();
// //     }
// //     if (_hasError) {
// //       return ErrorView(
// //         message: context.l10n.errorUnexpected,
// //         onRetry: _loadRooms,
// //       );
// //     }
// //     if (_rooms.isEmpty) {
// //       return JEmptyState(
// //         emoji: '🚪',
// //         title: l10n.roomsEmpty,
// //         subtitle: l10n.roomsEmptySubtitle,
// //         action: FilledButton.icon(
// //           onPressed: _createRoom,
// //           icon: const Icon(Icons.add_rounded),
// //           label: Text(l10n.roomsCreate),
// //         ),
// //       );
// //     }
// //     return ListView.separated(
// //       padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
// //       itemCount: _rooms.length,
// //       separatorBuilder: (_, __) => const SizedBox(height: 10),
// //       itemBuilder: (_, i) => RoomCard(
// //         room: _rooms[i],
// //         onTap: () => _enterRoom(_rooms[i].id),
// //       ).animate(delay: (i * 35).ms).fadeIn().slideY(begin: 0.06, end: 0),
// //     );
// //   }
// // }

// // class _GameTypeFilterBar extends StatelessWidget {
// //   const _GameTypeFilterBar({required this.selected, required this.onChanged});
// //   final String? selected;
// //   final void Function(String?) onChanged;

// //   @override
// //   Widget build(BuildContext context) {
// //     const filters = [
// //       (null, 'All', '🎮'),
// //       ('truth_or_dare', 'Truth or Dare', '🎯'),
// //       ('never_have_i_ever', 'Never Have I', '🍹'),
// //       ('meme_game', 'Meme Game', '😂'),
// //     ];

// //     return SizedBox(
// //       height: 48,
// //       child: ListView(
// //         scrollDirection: Axis.horizontal,
// //         padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
// //         children: filters.map((f) {
// //           final isSelected = selected == f.$1;
// //           return Padding(
// //             padding: const EdgeInsets.only(right: 8),
// //             child: FilterChip(
// //               label: Text('${f.$3} ${f.$2}'),
// //               selected: isSelected,
// //               onSelected: (_) => onChanged(isSelected ? null : f.$1),
// //               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
// //             ),
// //           );
// //         }).toList(),
// //       ),
// //     );
// //   }
// // }

// // class _LoadingGrid extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return ListView(
// //       padding: const EdgeInsets.all(16),
// //       children: List.generate(
// //         4,
// //         (i) => Padding(
// //           padding: const EdgeInsets.only(bottom: 12),
// //           child: ShimmerBox(width: double.infinity, height: 88, radius: 16),
// //         ).animate(delay: (i * 60).ms).fadeIn(),
// //       ),
// //     );
// //   }
// // }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:jma3a/deep_links.dart';
// import 'package:provider/provider.dart';
// import '../../../../core/di/service_locator.dart';
// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/providers/auth_provider.dart';
// import '../../../../core/router/route_names.dart';
// import '../../../../core/router/app_router.dart';
// import '../../../../core/storage/database/app_database.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../shared/widgets/cards/j_card.dart';
// import '../../../../shared/widgets/feedback/error_view.dart';
// import '../../data/room_cache_service.dart';
// import '../../domain/room_entity.dart';
// import '../widgets/create_room_sheet.dart';
// import '../widgets/join_code_dialog.dart';
// import '../widgets/room_card.dart';

// class RoomBrowserScreen extends StatefulWidget {
//   const RoomBrowserScreen({super.key});
//   @override
//   State<RoomBrowserScreen> createState() => _RoomBrowserScreenState();
// }

// class _RoomBrowserScreenState extends State<RoomBrowserScreen>
//     with WidgetsBindingObserver {
//   List<RoomEntity> _rooms = [];
//   bool _isLoading = true;
//   bool _hasError = false;
//   bool _isCreating = false;
//   String? _gameTypeFilter;
//   Timer? _autoRefreshTimer;
//   StreamSubscription<RoomInvitePayload>? _deepLinkSub;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     try {
//       sl.realtimeService.unsubscribeAll();
//     } catch (_) {}
//     _loadRooms(fromCache: true);
//     _deepLinkSub = DeepLinkService.instance.inviteStream.listen(_onInvite);
//     _autoRefreshTimer = Timer.periodic(
//       const Duration(seconds: 30),
//       (_) => _loadRooms(),
//     );
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _autoRefreshTimer?.cancel();
//     _deepLinkSub?.cancel();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) _loadRooms();
//   }

//   Future<void> _loadRooms({bool fromCache = false}) async {
//     if (fromCache) {
//       final cached = await RoomCacheService.instance.getCachedRooms();
//       if (cached.isNotEmpty && mounted) {
//         setState(() {
//           _rooms = cached;
//           _isLoading = false;
//         });
//       }
//     }

//     if (!mounted) return;
//     setState(() {
//       _isLoading = _rooms.isEmpty;
//       _hasError = false;
//     });

//     try {
//       final userId = context.read<AuthProvider>().currentUser?.id;
//       final rooms = await sl.roomRepository.getPublicRooms(
//         gameTypeFilter: _gameTypeFilter,
//         userId: userId,
//       );
//       if (!mounted) return;
//       setState(() {
//         _rooms = rooms;
//         _isLoading = false;
//       });
//       await RoomCacheService.instance.cacheRooms(rooms);
//     } catch (e, st) {
//       debugPrint('RoomBrowser error: $e\n$st');
//       if (!mounted) return;
//       setState(() {
//         _hasError = _rooms.isEmpty;
//         _isLoading = false;
//       });
//       if (_rooms.isEmpty) {
//         await Future.delayed(const Duration(seconds: 2));
//         if (mounted) _loadRooms();
//       }
//     }
//   }

//   Future<void> _createRoom() async {
//     if (_isCreating) return;
//     setState(() => _isCreating = true);
//     try {
//       await _doCreateRoom();
//     } finally {
//       if (mounted) setState(() => _isCreating = false);
//     }
//   }

//   Future<void> _doCreateRoom() async {
//     final user = context.read<AuthProvider>().currentUser;
//     if (user == null) return;

//     final active = await sl.roomRepository.getActiveMembership(user.id);
//     if (active != null) {
//       if (!mounted) return;
//       final isOwner = active['is_owner'] == true;
//       final isPaused = active['status'] == 'paused';
//       final goToRoom = await showDialog<bool>(
//         context: context,
//         builder: (ctx) => AlertDialog(
//           title: const Text("You're already in a room"),
//           content: Text(
//             isOwner
//                 ? (isPaused
//                       ? 'Your room "${active['room_name']}" is paused. Finish or close it before creating a new one.'
//                       : 'Your room "${active['room_name']}" is still open. Finish or close it before creating a new one.')
//                 : 'You\'re still in "${active['room_name']}". Leave it before creating a new room.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(ctx, false),
//               child: const Text('Cancel'),
//             ),
//             FilledButton(
//               onPressed: () => Navigator.pop(ctx, true),
//               child: const Text('Go to Room'),
//             ),
//           ],
//         ),
//       );
//       if (goToRoom == true && mounted) {
//         AppRouter.router.push('/home/room/${active['room_id']}');
//       }
//       return;
//     }

//     final myPacks = await sl.packRepository.getMyPurchasedPacks(user.id);
//     if (myPacks.isEmpty) {
//       final freeAvailable = await sl.packRepository.hasFreePacksAvailable();
//       if (!freeAvailable) {
//         if (!mounted) return;
//         await showDialog<void>(
//           context: context,
//           builder: (ctx) => AlertDialog(
//             title: const Text('No packs available'),
//             content: const Text(
//               "You need at least one pack to create a room — get a free pack or purchase one from the marketplace first.",
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(ctx),
//                 child: const Text('Cancel'),
//               ),
//               FilledButton(
//                 onPressed: () {
//                   Navigator.pop(ctx);
//                   AppRouter.router.go(RouteNames.marketplace);
//                 },
//                 child: const Text('Browse Packs'),
//               ),
//             ],
//           ),
//         );
//         return;
//       }
//     }

//     final isPremium =
//         context.read<AuthProvider>().currentUser?.isPremium ?? false;
//     final hitLimit = await sl.roomRepository.hasHitDailyRoomLimit(
//       userId: user.id,
//       isPremium: isPremium,
//     );
//     if (hitLimit) {
//       if (!mounted) return;
//       await showDialog<void>(
//         context: context,
//         builder: (ctx) => AlertDialog(
//           title: const Text('Daily limit reached'),
//           content: Text(
//             isPremium
//                 ? 'Premium plan allows 15 rooms per day. Try again tomorrow.'
//                 : 'Free plan allows 5 rooms per day. Try again tomorrow, or upgrade to Premium for 15 rooms/day.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(ctx),
//               child: const Text('OK'),
//             ),
//           ],
//         ),
//       );
//       return;
//     }

//     if (!mounted) return;
//     final room = await showModalBottomSheet<RoomEntity>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => const CreateRoomSheet(),
//     );
//     if (room != null && mounted) {
//       AppRouter.router.push('/home/room/${room.id}');
//       if (room.visibility == RoomVisibility.public) {
//         sl.roomRepository.notifyFriendsRoomCreated(room.id).catchError((_) {});
//       }
//     }
//   }

//   Future<void> _onInvite(RoomInvitePayload payload) async {
//     if (!mounted) return;
//     final room = await showDialog<RoomEntity>(
//       context: context,
//       builder: (_) => JoinCodeDialog(
//         prefillCode: payload.code,
//         invitedBy: payload.invitedBy,
//       ),
//     );
//     if (room != null && mounted) AppRouter.router.push('/home/room/${room.id}');
//   }

//   Future<void> _enterRoom(String targetRoomId) async {
//     final userId = context.read<AuthProvider>().currentUser?.id;
//     if (userId == null) return;

//     final active = await sl.roomRepository.getActiveMembership(userId);

//     if (active == null || active['room_id'] == targetRoomId) {
//       if (mounted) AppRouter.router.push('/home/room/$targetRoomId');
//       return;
//     }

//     if (!mounted) return;
//     final choice = await showDialog<String>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("You're already in a room"),
//         content: Text(
//           'You\'re still in "${active['room_name']}". You can\'t be a '
//           'player or spectator in two rooms at once — return to it, or '
//           'leave it for good to join this one instead.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, 'cancel'),
//             child: const Text('Cancel'),
//           ),
//           FilledButton.tonal(
//             onPressed: () => Navigator.pop(ctx, 'return'),
//             child: const Text('Return to my room'),
//           ),
//           FilledButton(
//             style: FilledButton.styleFrom(backgroundColor: Colors.red),
//             onPressed: () => Navigator.pop(ctx, 'leave'),
//             child: const Text('Leave for good'),
//           ),
//         ],
//       ),
//     );

//     if (choice == null || choice == 'cancel' || !mounted) return;

//     if (choice == 'return') {
//       AppRouter.router.push('/home/room/${active['room_id']}');
//       return;
//     }

//     final oldRoomId = active['room_id'] as String;
//     final wasOwner = active['is_owner'] == true;
//     final wasActive = active['status'] != 'waiting';

//     await sl.roomRepository.forceLeaveRoom(userId: userId, roomId: oldRoomId);

//     if (wasOwner) {
//       try {
//         if (wasActive) {
//           await sl.realtimeService.broadcastGameEnded(oldRoomId, {
//             'reason': 'host_left',
//           });
//         }
//         await sl.realtimeService.broadcastRoomEvent(oldRoomId, {
//           'type': 'owner_left',
//           'reason': 'host_left',
//         });
//       } catch (_) {}
//     }

//     if (mounted) AppRouter.router.push('/home/room/$targetRoomId');
//   }

//   Future<void> _joinByCode() async {
//     final room = await showDialog<RoomEntity>(
//       context: context,
//       builder: (_) => const JoinCodeDialog(),
//     );
//     if (room != null && mounted) {
//       await _enterRoom(room.id);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n;
//     final theme = context.theme;

//     return Scaffold(
//       backgroundColor: Colors.transparent, // <-- Add this
//       // appBar: AppBar(
//       //   backgroundColor: Colors.transparent, // optional
//       //   elevation: 0,
//       // ),
//       body: NestedScrollView(
//         headerSliverBuilder: (_, __) => [
//           SliverAppBar(
//             floating: true,
//             snap: true,
//             title: Text(l10n.roomsTitle),
//             actions: [
//               IconButton(
//                 onPressed: _joinByCode,
//                 icon: const Icon(Icons.qr_code_scanner_rounded),
//                 tooltip: l10n.roomsJoinCode,
//               ),
//             ],
//             bottom: PreferredSize(
//               preferredSize: const Size.fromHeight(48),
//               child: _GameTypeFilterBar(
//                 selected: _gameTypeFilter,
//                 onChanged: (f) {
//                   setState(() => _gameTypeFilter = f);
//                   _loadRooms();
//                 },
//               ),
//             ),
//           ),
//         ],
//         body: RefreshIndicator(
//           onRefresh: _loadRooms,
//           child: _buildBody(theme, l10n),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         heroTag: 'room_browser_create_fab',
//         onPressed: _isCreating ? null : _createRoom,
//         icon: _isCreating
//             ? const SizedBox(
//                 width: 18,
//                 height: 18,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   color: Colors.white,
//                 ),
//               )
//             : const Icon(Icons.add_rounded),
//         label: Text(l10n.roomsCreate),
//         backgroundColor: theme.colorScheme.primary,
//       ),
//     );
//   }

//   Widget _buildBody(ThemeData theme, dynamic l10n) {
//     if (_isLoading) {
//       return _LoadingGrid();
//     }
//     if (_hasError) {
//       return ErrorView(
//         message: context.l10n.errorUnexpected,
//         onRetry: _loadRooms,
//       );
//     }
//     if (_rooms.isEmpty) {
//       return JEmptyState(
//         emoji: '🚪',
//         title: l10n.roomsEmpty,
//         subtitle: l10n.roomsEmptySubtitle,
//         action: FilledButton.icon(
//           onPressed: _createRoom,
//           icon: const Icon(Icons.add_rounded),
//           label: Text(l10n.roomsCreate),
//         ),
//       );
//     }
//     return ListView.separated(
//       padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
//       itemCount: _rooms.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 10),
//       itemBuilder: (_, i) => RoomCard(
//         room: _rooms[i],
//         onTap: () => _enterRoom(_rooms[i].id),
//       ).animate(delay: (i * 35).ms).fadeIn().slideY(begin: 0.06, end: 0),
//     );
//   }
// }

// class _GameTypeFilterBar extends StatelessWidget {
//   const _GameTypeFilterBar({required this.selected, required this.onChanged});
//   final String? selected;
//   final void Function(String?) onChanged;

//   @override
//   Widget build(BuildContext context) {
//     const filters = [
//       (null, 'All', '🎮'),
//       ('truth_or_dare', 'Truth or Dare', '🎯'),
//       ('never_have_i_ever', 'Never Have I', '🍹'),
//       ('meme_game', 'Meme Game', '😂'),
//     ];

//     return SizedBox(
//       height: 48,
//       child: ListView(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//         children: filters.map((f) {
//           final isSelected = selected == f.$1;
//           return Padding(
//             padding: const EdgeInsets.only(right: 8),
//             child: FilterChip(
//               label: Text('${f.$3} ${f.$2}'),
//               selected: isSelected,
//               onSelected: (_) => onChanged(isSelected ? null : f.$1),
//               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
// }

// class _LoadingGrid extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: List.generate(
//         4,
//         (i) => Padding(
//           padding: const EdgeInsets.only(bottom: 12),
//           child: ShimmerBox(width: double.infinity, height: 88, radius: 16),
//         ).animate(delay: (i * 60).ms).fadeIn(),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:jma3a/deep_links.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../notifications/presentation/notification_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/j_card.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../data/room_cache_service.dart';
import '../../domain/room_entity.dart';
import '../widgets/create_room_sheet.dart';
import '../widgets/join_code_dialog.dart';
import '../widgets/room_card.dart';
import 'closed_rooms_screen.dart';

class RoomBrowserScreen extends StatefulWidget {
  const RoomBrowserScreen({super.key});
  @override
  State<RoomBrowserScreen> createState() => _RoomBrowserScreenState();
}

class _RoomBrowserScreenState extends State<RoomBrowserScreen>
    with WidgetsBindingObserver {
  List<RoomEntity> _rooms = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isCreating = false;
  String? _gameTypeFilter;
  Timer? _autoRefreshTimer;
  StreamSubscription<RoomInvitePayload>? _deepLinkSub;
  RealtimeChannel? _roomsCdcChannel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      sl.realtimeService.unsubscribeAll();
    } catch (_) {}
    _loadRooms(fromCache: true);
    _deepLinkSub = DeepLinkService.instance.inviteStream.listen(_onInvite);
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadRooms(),
    );
    // A closed room previously lingered in this list for up to 30s (the
    // poll interval above) — RLS already scopes visible rows to public/
    // member rooms, so no extra filter is needed here, just an instant
    // removal the moment a currently-displayed room's status flips.
    _roomsCdcChannel = Supabase.instance.client
        .channel('room_browser_rooms_cdc')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'rooms',
          callback: (payload) {
            final row = payload.newRecord;
            final isClosed =
                row['status'] == 'closed' || row['deleted_at'] != null;
            if (!isClosed || !mounted) return;
            final id = row['id'] as String?;
            if (id == null) return;
            setState(() => _rooms.removeWhere((r) => r.id == id));
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _deepLinkSub?.cancel();
    _roomsCdcChannel?.unsubscribe();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadRooms();
  }

  Future<void> _loadRooms({bool fromCache = false}) async {
    if (fromCache) {
      final cached = await RoomCacheService.instance.getCachedRooms();
      if (cached.isNotEmpty && mounted) {
        setState(() {
          _rooms = cached;
          _isLoading = false;
        });
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = _rooms.isEmpty;
      _hasError = false;
    });

    try {
      final userId = context.read<AuthProvider>().currentUser?.id;
      final rooms = await sl.roomRepository.getPublicRooms(
        gameTypeFilter: _gameTypeFilter,
        userId: userId,
      );
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
      await RoomCacheService.instance.cacheRooms(rooms);
    } catch (e, st) {
      debugPrint('RoomBrowser error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _hasError = _rooms.isEmpty;
        _isLoading = false;
      });
      if (_rooms.isEmpty) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _loadRooms();
      }
    }
  }

  Future<void> _createRoom() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);
    try {
      await _doCreateRoom();
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _doCreateRoom() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final active = await sl.roomRepository.getActiveMembership(user.id);
    if (active != null) {
      if (!mounted) return;
      final isOwner = active['is_owner'] == true;
      final isPaused = active['status'] == 'paused';
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('You already have an active room'),
          content: Text(
            isOwner
                ? (isPaused
                      ? 'Your room "${active['room_name']}" is paused. Return to it, or close it to create a new one.'
                      : 'Your room "${active['room_name']}" is still open. Return to it, or close it to create a new one.')
                : 'You\'re still in "${active['room_name']}". Leave it before creating a new room.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Cancel'),
            ),
            if (isOwner)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, 'close'),
                child: const Text('Close Existing Room and Create New Room'),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'go'),
              child: const Text('Return to My Room'),
            ),
          ],
        ),
      );

      if (choice == 'go' && mounted) {
        AppRouter.router.push('/home/room/${active['room_id']}');
      } else if (choice == 'close' && mounted) {
        final roomId = active['room_id'] as String;
        try {
          await sl.realtimeService.broadcastRoomEvent(roomId, {
            'type': 'owner_left',
            'reason': 'host_closed_remotely',
          });
        } catch (_) {}
        await sl.roomRepository.softDeleteRoom(roomId);
        if (mounted) {
          context.showSnackBar('Room closed');
          _doCreateRoom();
        }
      }
      return;
    }

    final myPacks = await sl.packRepository.getMyPurchasedPacks(user.id);
    if (myPacks.isEmpty) {
      final freeAvailable = await sl.packRepository.hasFreePacksAvailable();
      if (!freeAvailable) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('No packs available'),
            content: const Text(
              "You need at least one pack to create a room — get a free pack or purchase one from the marketplace first.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  AppRouter.router.go(RouteNames.marketplace);
                },
                child: const Text('Browse Packs'),
              ),
            ],
          ),
        );
        return;
      }
    }

    final isPremium =
        context.read<AuthProvider>().currentUser?.isPremium ?? false;
    final hitLimit = await sl.roomRepository.hasHitDailyRoomLimit(
      userId: user.id,
      isPremium: isPremium,
    );
    if (hitLimit) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Daily limit reached'),
          content: Text(
            isPremium
                ? 'Premium plan allows 15 rooms per day. Try again tomorrow.'
                : 'Free plan allows 5 rooms per day. Try again tomorrow, or upgrade to Premium for 15 rooms/day.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final room = await showModalBottomSheet<RoomEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateRoomSheet(),
    );
    if (room != null && mounted) {
      AppRouter.router.push('/home/room/${room.id}');
      if (room.visibility == RoomVisibility.public) {
        sl.roomRepository.notifyFriendsRoomCreated(room.id).catchError((_) {});
      }
    }
  }

  Future<void> _onInvite(RoomInvitePayload payload) async {
    if (!mounted) return;
    final room = await showDialog<RoomEntity>(
      context: context,
      builder: (_) => JoinCodeDialog(
        prefillCode: payload.code,
        invitedBy: payload.invitedBy,
      ),
    );
    if (room != null && mounted) AppRouter.router.push('/home/room/${room.id}');
  }

  Future<void> _enterRoom(String targetRoomId) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final active = await sl.roomRepository.getActiveMembership(userId);

    if (active == null || active['room_id'] == targetRoomId) {
      if (mounted) AppRouter.router.push('/home/room/$targetRoomId');
      return;
    }

    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("You're already in a room"),
        content: Text(
          'You\'re still in "${active['room_name']}". You can\'t be a '
          'player or spectator in two rooms at once — return to it, or '
          'leave it for good to join this one instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, 'return'),
            child: const Text('Return to my room'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, 'leave'),
            child: const Text('Leave for good'),
          ),
        ],
      ),
    );

    if (choice == null || choice == 'cancel' || !mounted) return;

    if (choice == 'return') {
      AppRouter.router.push('/home/room/${active['room_id']}');
      return;
    }

    final oldRoomId = active['room_id'] as String;
    final wasOwner = active['is_owner'] == true;
    final wasActive = active['status'] != 'waiting';

    await sl.roomRepository.forceLeaveRoom(userId: userId, roomId: oldRoomId);

    if (wasOwner) {
      try {
        if (wasActive) {
          await sl.realtimeService.broadcastGameEnded(oldRoomId, {
            'reason': 'host_left',
          });
        }
        await sl.realtimeService.broadcastRoomEvent(oldRoomId, {
          'type': 'owner_left',
          'reason': 'host_left',
        });
      } catch (_) {}
    }

    if (mounted) AppRouter.router.push('/home/room/$targetRoomId');
  }

  Future<void> _joinByCode() async {
    final room = await showDialog<RoomEntity>(
      context: context,
      builder: (_) => const JoinCodeDialog(),
    );
    if (room != null && mounted) {
      await _enterRoom(room.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final isPremium =
        context.watch<AuthProvider>().currentUser?.isPremiumActive ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text(l10n.roomsTitle),
            actions: [
              Consumer<NotificationProvider>(
                builder: (_, notifs, __) => IconButton(
                  onPressed: () =>
                      AppRouter.router.push(RouteNames.notifications),
                  icon: Badge(
                    isLabelVisible: notifs.unreadCount > 0,
                    label: Text('${notifs.unreadCount}'),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  tooltip: 'Notifications',
                ),
              ),
              if (isPremium)
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClosedRoomsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.history_rounded),
                  tooltip: 'My Closed Rooms',
                ),
              IconButton(
                onPressed: _joinByCode,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                tooltip: l10n.roomsJoinCode,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _GameTypeFilterBar(
                selected: _gameTypeFilter,
                onChanged: (f) {
                  setState(() => _gameTypeFilter = f);
                  _loadRooms();
                },
              ),
            ),
          ),
        ],
        body: RefreshIndicator(
          onRefresh: _loadRooms,
          child: _buildBody(theme, l10n),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'room_browser_create_fab',
        onPressed: _isCreating ? null : _createRoom,
        icon: _isCreating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_rounded),
        label: Text(l10n.roomsCreate),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildBody(ThemeData theme, dynamic l10n) {
    if (_isLoading) {
      return _LoadingGrid();
    }
    if (_hasError) {
      return ErrorView(
        message: context.l10n.errorUnexpected,
        onRetry: _loadRooms,
      );
    }
    if (_rooms.isEmpty) {
      return JEmptyState(
        emoji: '🚪',
        title: l10n.roomsEmpty,
        subtitle: l10n.roomsEmptySubtitle,
        action: FilledButton.icon(
          onPressed: _createRoom,
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.roomsCreate),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: _rooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => RoomCard(
        room: _rooms[i],
        onTap: () => _enterRoom(_rooms[i].id),
      ).animate(delay: (i * 35).ms).fadeIn().slideY(begin: 0.06, end: 0),
    );
  }
}

class _GameTypeFilterBar extends StatelessWidget {
  const _GameTypeFilterBar({required this.selected, required this.onChanged});
  final String? selected;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = [
      (null, 'All', '🎮'),
      ('truth_or_dare', 'Truth or Dare', '🎯'),
      ('never_have_i_ever', 'Never Have I', '🍹'),
      ('meme_game', 'Meme Game', '😂'),
    ];

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: filters.map((f) {
          final isSelected = selected == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${f.$3} ${f.$2}'),
              selected: isSelected,
              onSelected: (_) => onChanged(isSelected ? null : f.$1),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerBox(width: double.infinity, height: 88, radius: 16),
        ).animate(delay: (i * 60).ms).fadeIn(),
      ),
    );
  }
}
