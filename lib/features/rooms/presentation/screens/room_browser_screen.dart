// // import 'dart:async';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import 'package:go_router/go_router.dart';
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
// //   String? _gameTypeFilter;
// //   Timer? _autoRefreshTimer;

// //   @override
// //   void initState() {
// //     super.initState();
// //     WidgetsBinding.instance.addObserver(this);
// //     _loadRooms(fromCache: true);
// //     // Auto-refresh every 30 seconds while screen is active
// //     _autoRefreshTimer = Timer.periodic(
// //       const Duration(seconds: 30),
// //       (_) => _loadRooms(),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     WidgetsBinding.instance.removeObserver(this);
// //     _autoRefreshTimer?.cancel();
// //     super.dispose();
// //   }

// //   @override
// //   void didChangeAppLifecycleState(AppLifecycleState state) {
// //     if (state == AppLifecycleState.resumed) _loadRooms();
// //   }

// //   Future<void> _loadRooms({bool fromCache = false}) async {
// //     if (fromCache) {
// //       // Show cached rooms instantly (no-op if DB not ready yet)
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
// //     }
// //   }

// //   Future<void> _createRoom() async {
// //     final user = context.read<AuthProvider>().currentUser;
// //     if (user == null) return;

// //     final room = await showModalBottomSheet<RoomEntity>(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder: (_) => const CreateRoomSheet(),
// //     );
// //     if (room != null && mounted) {
// //       AppRouter.router.push('/home/room/${room.id}');
// //     }
// //   }

// //   Future<void> _joinByCode() async {
// //     final room = await showDialog<RoomEntity>(
// //       context: context,
// //       builder: (_) => const JoinCodeDialog(),
// //     );
// //     if (room != null && mounted) {
// //       AppRouter.router.push('/home/room/${room.id}');
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
// //         onPressed: _createRoom,
// //         icon: const Icon(Icons.add_rounded),
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
// //         onTap: () => AppRouter.router.push('/home/room/${_rooms[i].id}'),
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
//   String? _gameTypeFilter;
//   Timer? _autoRefreshTimer;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     // Clean up any lingering realtime subscriptions from previous rooms
//     try {
//       sl.realtimeService.unsubscribeAll();
//     } catch (_) {}
//     _loadRooms(fromCache: true);
//     // Auto-refresh every 30 seconds while screen is active
//     _autoRefreshTimer = Timer.periodic(
//       const Duration(seconds: 30),
//       (_) => _loadRooms(),
//     );
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _autoRefreshTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) _loadRooms();
//   }

//   Future<void> _loadRooms({bool fromCache = false}) async {
//     if (fromCache) {
//       // Show cached rooms instantly (no-op if DB not ready yet)
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
//       // Only show error UI if we have no rooms to show at all
//       setState(() {
//         _hasError = _rooms.isEmpty;
//         _isLoading = false;
//       });
//       // Silently retry once after a short delay
//       if (_rooms.isEmpty) {
//         await Future.delayed(const Duration(seconds: 2));
//         if (mounted) _loadRooms();
//       }
//     }
//   }

//   Future<void> _createRoom() async {
//     final user = context.read<AuthProvider>().currentUser;
//     if (user == null) return;

//     final room = await showModalBottomSheet<RoomEntity>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => const CreateRoomSheet(),
//     );
//     if (room != null && mounted) {
//       AppRouter.router.push('/home/room/${room.id}');
//     }
//   }

//   Future<void> _joinByCode() async {
//     final room = await showDialog<RoomEntity>(
//       context: context,
//       builder: (_) => const JoinCodeDialog(),
//     );
//     if (room != null && mounted) {
//       AppRouter.router.push('/home/room/${room.id}');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n;
//     final theme = context.theme;

//     return Scaffold(
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
//         onPressed: _createRoom,
//         icon: const Icon(Icons.add_rounded),
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
//         onTap: () => AppRouter.router.push('/home/room/${_rooms[i].id}'),
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
import '../../../../core/di/service_locator.dart';
// import '../../../../core/services/deep_link_service.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
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
  String? _gameTypeFilter;
  Timer? _autoRefreshTimer;
  StreamSubscription<RoomInvitePayload>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Clean up any lingering realtime subscriptions from previous rooms
    try {
      sl.realtimeService.unsubscribeAll();
    } catch (_) {}
    _loadRooms(fromCache: true);
    // Listen for deep link invite codes
    _deepLinkSub = DeepLinkService.instance.inviteStream.listen(_onInvite);
    // Auto-refresh every 30 seconds while screen is active
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadRooms(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadRooms();
  }

  Future<void> _loadRooms({bool fromCache = false}) async {
    if (fromCache) {
      // Show cached rooms instantly (no-op if DB not ready yet)
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
      // Only show error UI if we have no rooms to show at all
      setState(() {
        _hasError = _rooms.isEmpty;
        _isLoading = false;
      });
      // Silently retry once after a short delay
      if (_rooms.isEmpty) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _loadRooms();
      }
    }
  }

  Future<void> _createRoom() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final room = await showModalBottomSheet<RoomEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateRoomSheet(),
    );
    if (room != null && mounted) {
      AppRouter.router.push('/home/room/${room.id}');
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

  Future<void> _joinByCode() async {
    final room = await showDialog<RoomEntity>(
      context: context,
      builder: (_) => const JoinCodeDialog(),
    );
    if (room != null && mounted) {
      AppRouter.router.push('/home/room/${room.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text(l10n.roomsTitle),
            actions: [
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
        onPressed: _createRoom,
        icon: const Icon(Icons.add_rounded),
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
        onTap: () => AppRouter.router.push('/home/room/${_rooms[i].id}'),
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
