// import 'dart:async';
// import 'package:jma3a/features/rooms/domain/room_entity.dart';
// import 'package:jma3a/shared/widgets/playful_background.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import '../../../../core/di/service_locator.dart';
// import '../../data/room_repository.dart';
// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/providers/auth_provider.dart';
// import '../../../friends/data/friends_repository.dart';
// import '../../../../core/router/app_router.dart';
// import '../../../../core/router/route_names.dart';
// import '../../../../core/theme/app_colors.dart';
// import 'package:share_plus/share_plus.dart';

// import '../../../../shared/widgets/buttons/j_button.dart';
// import '../../../friends/presentation/friends_provider.dart';
// import '../../../../shared/widgets/feedback/error_view.dart';
// import '../../../../shared/widgets/overlays/confirm_dialog.dart';
// import '../../../packs/data/pack_repository.dart';
// import '../../../packs/presentation/pack_provider.dart';
// import '../room_provider.dart';
// import '../../../../features/games/engine/base_game_engine.dart';
// import '../widgets/chat_panel.dart';
// import '../widgets/game_settings_sheet.dart';
// import '../widgets/member_tile.dart';
// import '../widgets/moderation_sheet.dart';

// class LobbyScreen extends StatefulWidget {
//   const LobbyScreen({super.key, required this.roomId});
//   final String roomId;

//   @override
//   State<LobbyScreen> createState() => _LobbyScreenState();
// }

// class _LobbyScreenState extends State<LobbyScreen>
//     with SingleTickerProviderStateMixin {
//   late final TabController _tabs;

//   late final RoomProvider _provider;
//   StreamSubscription<RoomLifecycleEvent>? _lifecycleSub;
//   List<String>? _sessionPlayerIds;
//   bool _fetchingSessionPlayerIds = false;
//   List<Map<String, dynamic>> _pendingSpectatorRequests = [];
//   bool _fetchingSpectatorRequests = false;
//   @override
//   void initState() {
//     super.initState();
//     _tabs = TabController(length: 2, vsync: this);

//     final auth = context.read<AuthProvider>();
//     _provider = RoomProvider(
//       roomRepository: sl.roomRepository,
//       realtimeService: sl.realtimeService,
//       presenceService: sl.presenceService,
//       cacheService: sl.roomCacheService,
//       currentUserId: auth.currentUser!.id,
//       currentDisplayName: auth.currentUser!.displayName ?? 'Player',
//       currentAvatarUrl: auth.currentUser!.avatarUrl,
//     );

//     _initializeWithRoleCheck();

//     _lifecycleSub = _provider.lifecycleEvents.listen(_onLifecycleEvent);

//     _provider.addListener(_onRoomStateChanged);
//   }

//   Future<void> _initializeWithRoleCheck() async {
//     final myId = Supabase.instance.client.auth.currentUser?.id;
//     bool isRoomOwner = false;
//     try {
//       final roomInfo = await Supabase.instance.client
//           .from('rooms')
//           .select('status, owner_id')
//           .eq('id', widget.roomId)
//           .maybeSingle();
//       final settingsInfo = await Supabase.instance.client
//           .from('room_settings')
//           .select('allow_spectators')
//           .eq('room_id', widget.roomId)
//           .maybeSingle();

//       final isInGame = roomInfo?['status'] == 'in_game';
//       final allowSpectators =
//           settingsInfo?['allow_spectators'] as bool? ?? false;
//       isRoomOwner = roomInfo?['owner_id'] == myId;

//       if (isRoomOwner) {
//         await sl.roomRepository.clearPack(widget.roomId).catchError((_) {});
//       }

//       String role = 'player';
//       if (allowSpectators && !isRoomOwner && mounted) {
//         final picked = await showDialog<String>(
//           context: context,
//           barrierDismissible: false,
//           builder: (_) => _JoinRoleDialog(isInGame: isInGame),
//         );
//         role = picked ?? 'player';
//       }

//       if (mounted) {
//         _provider.initialize(widget.roomId, role: role);
//       }
//     } catch (_) {
//       if (isRoomOwner) {
//         sl.roomRepository.clearPack(widget.roomId).catchError((_) {});
//       }
//       if (mounted) {
//         _provider.initialize(widget.roomId);
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _provider.removeListener(_onRoomStateChanged);
//     _ownerLeftTimer?.cancel();
//     _lifecycleSub?.cancel();
//     _tabs.dispose();
//     _provider.dispose();
//     super.dispose();
//   }

//   void _onLifecycleEvent(RoomLifecycleEvent event) {
//     if (!mounted) return;
//     switch (event) {
//       case RoomLifecycleEvent.kicked:
//         _showEventBanner(
//           'You were removed from the room by the host',
//           isError: true,
//         );
//         context.go(RouteNames.home);
//       case RoomLifecycleEvent.banned:
//         _showEventBanner('You were banned from this room', isError: true);
//         context.go(RouteNames.home);
//       case RoomLifecycleEvent.roomClosed:
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (!mounted) {
//             AppRouter.router.go(RouteNames.home);
//             return;
//           }
//           showDialog(
//             context: context,
//             barrierDismissible: false,
//             builder: (dialogCtx) => AlertDialog(
//               title: const Text('Room Closed'),
//               content: const Text('The host closed the room.'),
//               actions: [
//                 FilledButton(
//                   onPressed: () {
//                     Navigator.of(dialogCtx).pop();
//                     AppRouter.router.go(RouteNames.home);
//                   },
//                   child: const Text('OK'),
//                 ),
//               ],
//             ),
//           );
//         });
//       case RoomLifecycleEvent.ownershipTransferred:
//         _showEventBanner("You're now the room owner 👑");
//     }
//   }

//   void _showEventBanner(String message, {bool isError = false}) {
//     if (!mounted) return;
//     context.showSnackBar(message, isError: isError);
//   }

//   bool _navigatedToGame = false;

//   Timer? _ownerLeftTimer;
//   int _maxMembersSeen = 0;

//   void _onRoomStateChanged() {
//     if (!mounted) return;
//     final room = _provider;

//     if (room.room?.status == RoomStatus.closed && !room.isOwner) {
//       _showEventBanner('The host closed the room.');
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (!mounted) return;
//         if (context.canPop())
//           context.pop();
//         else
//           context.go(RouteNames.home);
//       });
//       return;
//     }

//     if (room.members.length > _maxMembersSeen) {
//       _maxMembersSeen = room.members.length;
//     }

//     final ownerGone =
//         room.isInitialized &&
//         !room.isOwner &&
//         _maxMembersSeen >= 2 &&
//         room.members.isNotEmpty &&
//         room.room?.status != RoomStatus.inGame &&
//         !room.members.any((m) => m.isOwner);

//     if (ownerGone) {
//       _ownerLeftTimer ??= Timer(const Duration(seconds: 2), () {
//         _ownerLeftTimer = null;
//         if (!mounted) return;
//         final r2 = _provider;
//         if (r2.isInitialized &&
//             !r2.isOwner &&
//             r2.members.isNotEmpty &&
//             r2.room?.status != RoomStatus.inGame &&
//             !r2.members.any((m) => m.isOwner)) {
//           _showEventBanner('The host left the room.');
//           if (context.canPop())
//             context.pop();
//           else
//             context.go(RouteNames.home);
//         }
//       });
//     } else {
//       _ownerLeftTimer?.cancel();
//       _ownerLeftTimer = null;
//     }

//     if (ownerGone) return;

//     if (room.room?.status == RoomStatus.waiting) {
//       _navigatedToGame = false;
//     }

//     if (!_navigatedToGame &&
//         room.room?.status == RoomStatus.inGame &&
//         room.isInitialized &&
//         !room.isOwner &&
//         room.room?.gameType != null) {
//       _navigatedToGame = true;
//       final gameType = room.room!.gameType!.toDbString();
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (!mounted) return;
//         _navigateFollowerToGame(gameType);
//       });
//       return;
//     }

//     if (!_navigatedToGame &&
//         room.room?.status == RoomStatus.inGame &&
//         room.isInitialized &&
//         room.isOwner &&
//         room.room?.gameType != null) {
//       _navigatedToGame = true;
//       final gameType = room.room!.gameType!.toDbString();
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (!mounted) return;
//         _navigateOwnerToGame(gameType);
//       });
//     }
//   }

//   void _navigateOwnerToGame(String gameType) {
//     if (!mounted) return;
//     final r = _provider.room;
//     if (r == null) return;
//     final displayNames = {
//       for (final m in _provider.members) m.userId: m.displayName,
//     };
//     final packs = context.read<PackProvider>();
//     final pack = packs.allPacks
//         .where((p) => p.id == (r.packId ?? ''))
//         .firstOrNull;

//     sl.realtimeService
//         .broadcastRoomEvent(r.id, {
//           'type': 'game_started',
//           'game_type': gameType,
//           'pack_id': r.packId ?? '',
//           'language': r.language,
//           'max_rounds': _provider.settings.maxRounds,
//           'turn_timer_secs': _provider.settings.turnTimerSeconds,
//           'allow_skip': _provider.settings.allowSkip,
//           'allow_spicy': r.allowSpicy,
//           'player_ids': _provider.members.where((m) => !m.isSpectator).map((m) => m.userId).toList(),
//           'display_names': displayNames,
//         })
//         .catchError((_) {});

//     AppRouter.router.push(
//       '${RouteNames.home}/room/${r.id}/game',
//       extra: {
//         'config': GameConfig(
//           maxRounds: _provider.settings.maxRounds,
//           turnTimerSeconds: _provider.settings.turnTimerSeconds,
//           allowSkip: _provider.settings.allowSkip,
//           allowSpicy: r.allowSpicy,
//           enablePunishments: true,
//           packId: r.packId,
//           language: r.language,
//         ),
//         'playerIds': _provider.members.where((m) => !m.isSpectator).map((m) => m.userId).toList(),
//         'displayNames': displayNames,
//         'packId': r.packId ?? '',
//         'packCoverUrl': pack?.coverImageUrl ?? '',
//         'isOwner': true,
//         'gameType': gameType,
//       },
//     );
//   }

//   void _navigateFollowerToGame(String gameType) {
//     if (!mounted) return;
//     final r = _provider.room;
//     if (r == null) return;

//     final displayNames = {
//       for (final m in _provider.members) m.userId: m.displayName,
//     };

//     String followerCoverUrl = '';
//     try {
//       final packProv = context.read<PackProvider>();
//       final pack = packProv.allPacks
//           .where((p) => p.id == (r.packId ?? ''))
//           .firstOrNull;
//       followerCoverUrl = pack?.coverImageUrl ?? '';
//     } catch (_) {}

//     final extra = {
//       'config': GameConfig(
//         maxRounds: _provider.settings.maxRounds,
//         turnTimerSeconds: _provider.settings.turnTimerSeconds,
//         allowSkip: _provider.settings.allowSkip,
//         allowSpicy: r.allowSpicy,
//         enablePunishments: true,
//         packId: r.packId,
//         language: r.language,
//       ),
//       'playerIds': _provider.members.where((m) => !m.isSpectator).map((m) => m.userId).toList(),
//       'displayNames': displayNames,
//       'packId': r.packId ?? '',
//       'packCoverUrl': followerCoverUrl,
//       'isOwner': false,
//       'isModerator': _provider.currentMember?.isModerator ?? false,
//       'gameType': gameType,
//     };

//     AppRouter.router.push('${RouteNames.home}/room/${r.id}/game', extra: extra);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider.value(
//       value: _provider,
//       child: Consumer<RoomProvider>(
//         builder: (ctx, room, _) => _build(ctx, room),
//       ),
//     );
//   }

//   Widget _build(BuildContext ctx, RoomProvider room) {
//     if (room.connectionState == RoomConnectionState.failed &&
//         !room.isInitialized) {
//       final errorMsg = room.failure?.message ?? 'Connection failed';
//       return Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(),
//         body: ErrorView(
//           message: errorMsg,
//           onRetry: () => _provider.initialize(widget.roomId),
//         ),
//       );
//     }

//     if (room.connectionState == RoomConnectionState.pendingApproval) {
//       return Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(title: const Text('Join Request Sent')),
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(Icons.hourglass_top_rounded, size: 56),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Waiting for the host to approve your request to join.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "You'll be let in automatically once they approve.",
//                   textAlign: TextAlign.center,
//                   style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
//                     color: Theme.of(ctx).colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 OutlinedButton(
//                   onPressed: () => ctx.go(RouteNames.home),
//                   child: const Text('Back to Home'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     final gameIsActive =
//         room.room?.gameType != null && (room.room?.status == RoomStatus.inGame);
//     if (gameIsActive &&
//         !room.isOwner &&
//         _sessionPlayerIds == null &&
//         !_fetchingSessionPlayerIds) {
//       _fetchingSessionPlayerIds = true;
//       sl.roomRepository
//           .getActiveSessionPlayerIds(widget.roomId)
//           .then((ids) {
//             if (!mounted) return;
//             setState(() {
//               _sessionPlayerIds = ids;
//               _fetchingSessionPlayerIds = false;
//             });
//           })
//           .catchError((_) {
//             if (!mounted) return;
//             setState(() => _fetchingSessionPlayerIds = false);
//           });
//     }
//     if (!gameIsActive && _sessionPlayerIds != null) {
//       _sessionPlayerIds = null;
//     }

//     return PopScope(
//       canPop: false,
//       // onPopInvoked: (didPop) {
//       //   if (didPop) return;
//       //   WidgetsBinding.instance.addPostFrameCallback((_) {
//       //     if (mounted) _leaveRoom();
//       //   });
//       // },
//       child: PlayfulBackground(
//         child: Scaffold(
//           // backgroundColor: Colors.transparent,
//           appBar: _LobbyAppBar(room: room, tabs: _tabs, onLeave: _leaveRoom),
//           body: Column(
//             children: [
//               if (room.connectionState != RoomConnectionState.connected &&
//                   room.connectionState != RoomConnectionState.connecting)
//                 _ConnectionBanner(
//                   state: room.connectionState,
//                   onRetry: room.retryConnection,
//                 ),
//               if (room.room?.status == RoomStatus.inGame &&
//                   room.room?.gameType != null)
//                 _RejoinBanner(
//                   onRejoin: () {
//                     _navigatedToGame = false;
//                     final r = room.room!;
//                     final gameType = r.gameType!.toDbString();
//                     final displayNames = {
//                       for (final m in room.members) m.userId: m.displayName,
//                     };
//                     final config = GameConfig(
//                       maxRounds: room.settings.maxRounds,
//                       turnTimerSeconds: room.settings.turnTimerSeconds,
//                       allowSkip: room.settings.allowSkip,
//                       allowSpicy: r.allowSpicy,
//                       enablePunishments: true,
//                       packId: r.packId,
//                     );
//                     AppRouter.router.push(
//                       '${RouteNames.home}/room/${r.id}/game',
//                       extra: {
//                         'config': config,
//                         'playerIds': room.members.where((m) => !m.isSpectator).map((m) => m.userId).toList(),
//                         'displayNames': displayNames,
//                         'packId': r.packId ?? '',
//                         'isOwner': room.isOwner,
//                         'isModerator': room.currentMember?.isModerator ?? false,
//                         'gameType': gameType,
//                       },
//                     );
//                   },
//                 ),
//               Expanded(
//                 child: TabBarView(
//                   controller: _tabs,
//                   physics: const NeverScrollableScrollPhysics(),
//                   children: [
//                     _LobbyTab(room: room),
//                     ChatPanel(room: room),
//                   ],
//                 ),
//               ),
//               _BottomActionBar(
//                 room: room,
//                 wasInActiveSession:
//                     _sessionPlayerIds == null ||
//                     _sessionPlayerIds!.contains(
//                       context.read<AuthProvider>().currentUser?.id,
//                     ),
//                 onLeave: _leaveRoom,
//                 onContinueGame: () async {
//                   final gt = room.room?.gameType;
//                   if (gt == null) return;
//                   if (room.isOwner) {
//                     _navigateOwnerToGame(gt.toDbString());
//                   } else {
//                     _navigateFollowerToGame(gt.toDbString());
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _leaveRoom() async {
//     if (!mounted) return;
//     final isOwner = _provider.isOwner;

//     if (isOwner) {
//       final confirmed = await showDialog<bool>(
//         context: context,
//         builder: (dCtx) => AlertDialog(
//           title: const Text('Close Room?'),
//           content: const Text('Closing the room will remove all players.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(dCtx).pop(false),
//               child: const Text('Cancel'),
//             ),
//             FilledButton(
//               style: FilledButton.styleFrom(backgroundColor: Colors.red),
//               onPressed: () => Navigator.of(dCtx).pop(true),
//               child: const Text('Close Room'),
//             ),
//           ],
//         ),
//       );
//       if (confirmed != true || !mounted) return;

//       try {
//         await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
//           'type': 'owner_left',
//           'reason': 'host_left',
//         });
//         await Future.delayed(const Duration(milliseconds: 400));
//       } catch (_) {}
//       await _provider.leaveRoom(permanent: true);
//       if (mounted) context.go(RouteNames.home);
//     } else {
//       final confirmed = await showDialog<bool>(
//         context: context,
//         builder: (dCtx) => AlertDialog(
//           title: const Text('Leave Room?'),
//           content: const Text('Are you sure you want to leave this room?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(dCtx).pop(false),
//               child: const Text('Cancel'),
//             ),
//             FilledButton(
//               style: FilledButton.styleFrom(backgroundColor: Colors.red),
//               onPressed: () => Navigator.of(dCtx).pop(true),
//               child: const Text('Leave'),
//             ),
//           ],
//         ),
//       );
//       if (confirmed != true || !mounted) return;

//       final myId = context.read<AuthProvider>().currentUser?.id ?? '';
//       final displayName =
//           context.read<AuthProvider>().currentUser?.displayName ?? 'A player';
//       try {
//         await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
//           'type': 'player_left',
//           'user_id': myId,
//           'display_name': displayName,
//           'for_good': true,
//         });
//         await sl.roomRepository.setMemberDefinitiveLeave(widget.roomId, myId);
//       } catch (_) {}
//       if (mounted) context.go(RouteNames.home);
//     }
//   }
// }

// class _LobbyAppBar extends StatelessWidget implements PreferredSizeWidget {
//   const _LobbyAppBar({
//     required this.room,
//     required this.tabs,
//     required this.onLeave,
//   });

//   final RoomProvider room;
//   final TabController tabs;
//   final VoidCallback onLeave;

//   @override
//   Size get preferredSize =>
//       const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final r = room.room;
//     final l10n = context.l10n;

//     return AppBar(
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back_rounded),
//         onPressed: onLeave,
//       ),
//       title: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             r?.name ?? l10n.lobbyTitle,
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           _ConnectionIndicator(state: room.connectionState),
//         ],
//       ),
//       actions: [
//         if (r?.inviteCode != null && room.isOwner)
//           _InviteCodeChip(code: r!.inviteCode!),

//         Consumer<RoomProvider>(
//           builder: (_, rp, __) {
//             final specs = rp.members.where((m) => m.isSpectator).toList();
//             if (specs.isEmpty) return const SizedBox.shrink();
//             return TextButton.icon(
//               onPressed: () => showModalBottomSheet(
//                 context: context,
//                 builder: (_) => _SpectatorsSheet(spectators: specs),
//               ),
//               icon: const Icon(Icons.visibility_outlined, size: 16),
//               label: Text('\${specs.length}'),
//               style: TextButton.styleFrom(foregroundColor: Colors.white70),
//             );
//           },
//         ),

//         if (room.canApproveSpectators &&
//             (room.room?.status == RoomStatus.inGame || false))
//           FutureBuilder<List<Map<String, dynamic>>>(
//             future: room.fetchPendingSpectatorRequests(),
//             builder: (ctx, snap) {
//               final requests = snap.data ?? [];
//               if (requests.isEmpty) return const SizedBox.shrink();
//               return IconButton(
//                 tooltip:
//                     '\${requests.length} spectator request\${requests.length == 1 ? '
//                     ' : "s"}',
//                 icon: Badge(
//                   label: Text('\${requests.length}'),
//                   child: const Icon(
//                     Icons.person_add_outlined,
//                     size: 20,
//                     color: Colors.white70,
//                   ),
//                 ),
//                 onPressed: () => showModalBottomSheet(
//                   context: ctx,
//                   isScrollControlled: true,
//                   builder: (_) =>
//                       _SpectatorRequestsSheet(requests: requests, room: room),
//                 ),
//               );
//             },
//           ),
//         const SizedBox(width: 4),
//       ],
//       bottom: TabBar(
//         controller: tabs,
//         tabs: [
//           Tab(text: l10n.lobbyTitle),
//           Tab(
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text('Chat'),
//                 if (!context.watch<RoomProvider>().settings.chatEnabled)
//                   const Padding(
//                     padding: EdgeInsets.only(left: 4),
//                     child: Icon(Icons.voice_over_off_rounded, size: 14),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ConnectionIndicator extends StatelessWidget {
//   const _ConnectionIndicator({required this.state});
//   final RoomConnectionState state;

//   @override
//   Widget build(BuildContext context) {
//     final (label, color) = switch (state) {
//       RoomConnectionState.connected => ('Live', AppColors.successGreen),
//       RoomConnectionState.reconnecting => (
//         'Reconnecting…',
//         AppColors.warningAmber,
//       ),
//       RoomConnectionState.recovering => ('Syncing…', AppColors.infoBlue),
//       RoomConnectionState.failed => ('Disconnected', AppColors.errorRed),
//       _ => ('Connecting…', AppColors.textTertiaryLight),
//     };

//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 6,
//           height: 6,
//           decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//         ),
//         const SizedBox(width: 4),
//         Text(
//           label,
//           style: context.textTheme.labelSmall?.copyWith(
//             color: color,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _InviteCodeChip extends StatelessWidget {
//   const _InviteCodeChip({required this.code});
//   final String code;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Clipboard.setData(ClipboardData(text: code));
//         context.showSnackBar(context.l10n.lobbyCopied);
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//         margin: const EdgeInsets.only(right: 4),
//         decoration: BoxDecoration(
//           color: context.colorScheme.primaryContainer,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.copy_rounded,
//               size: 12,
//               color: context.colorScheme.onPrimaryContainer,
//             ),
//             const SizedBox(width: 4),
//             Text(
//               code,
//               style: context.textTheme.labelMedium?.copyWith(
//                 color: context.colorScheme.onPrimaryContainer,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 2,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ConnectionBanner extends StatelessWidget {
//   const _ConnectionBanner({required this.state, required this.onRetry});
//   final RoomConnectionState state;
//   final VoidCallback onRetry;

//   @override
//   Widget build(BuildContext context) {
//     final isFailed = state == RoomConnectionState.failed;
//     final color = isFailed ? AppColors.errorRed : AppColors.warningAmber;
//     final message = isFailed
//         ? context.l10n.gameConnectionLost
//         : context.l10n.gameReconnecting;

//     return Container(
//       width: double.infinity,
//       color: color.withOpacity(0.12),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         children: [
//           if (!isFailed)
//             SizedBox(
//               width: 14,
//               height: 14,
//               child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
//             )
//           else
//             Icon(Icons.wifi_off_rounded, size: 16, color: color),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               message,
//               style: context.textTheme.labelSmall?.copyWith(color: color),
//             ),
//           ),
//           if (isFailed)
//             TextButton(
//               onPressed: onRetry,
//               style: TextButton.styleFrom(
//                 foregroundColor: color,
//                 visualDensity: VisualDensity.compact,
//               ),
//               child: Text(context.l10n.gameTryAgain),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class _LobbyTab extends StatelessWidget {
//   const _LobbyTab({required this.room});
//   final RoomProvider room;

//   @override
//   Widget build(BuildContext context) {
//     final members = room.members;
//     final theme = context.theme;

//     if (members.isEmpty &&
//         room.connectionState == RoomConnectionState.connecting) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         Row(
//           children: [
//             Text(
//               '${members.length} / ${room.room?.maxPlayers ?? 6} players',
//               style: theme.textTheme.labelLarge?.copyWith(
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//             ),
//             const Spacer(),
//             if (room.isOwner)
//               Text(
//                 'You are the host',
//                 style: theme.textTheme.labelSmall?.copyWith(
//                   color: AppColors.ownerBadge,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//           ],
//         ),
//         const SizedBox(height: 12),

//         if (room.canAcceptJoins)
//           _JoinRequestsPanel(
//             roomId: room.room!.id,
//             showAlways: room.settings.requiresApproval,
//           ),

//         if (room.canAcceptJoins)
//           const SizedBox(height: 4),

//         ...members.asMap().entries.map((e) {
//           final member = e.value;
//           final myId = context.read<AuthProvider>().currentUser?.id ?? '';
//           return Column(
//             children: [
//               GestureDetector(
//                 onTap: member.userId != myId
//                     ? () => _showMemberPopup(context, member, myId)
//                     : null,
//                 child: MemberTile(
//                   member: member,
//                   isCurrentUser: member.userId == myId,
//                   canModerate: room.canModerate(member.userId),
//                   onKick: () => _kickConfirm(context, room, member),
//                   onMute: () =>
//                       room.mutePlayer(member.userId, muted: !member.isMuted),
//                   onBan: () => _banConfirm(context, room, member),
//                   onTransferOwnership: room.isOwner
//                       ? () => _transferConfirm(context, room, member)
//                       : null,
//                   onToggleModerator: room.isOwner
//                       ? () => member.isModerator
//                             ? room.revokeModerator(member.userId)
//                             : room.grantModerator(member.userId)
//                       : null,
//                 ).animate(delay: (e.key * 40).ms).fadeIn(),
//               ),
//             ],
//           );
//         }),
//       ],
//     );
//   }

//   void _showMemberPopup(
//     BuildContext ctx,
//     RoomMemberEntity member,
//     String myId,
//   ) {
//     showModalBottomSheet(
//       context: ctx,
//       backgroundColor: Colors.transparent,
//       builder: (_) => Container(
//         padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
//         decoration: BoxDecoration(
//           color: Theme.of(ctx).colorScheme.surface,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 36,
//               height: 4,
//               margin: const EdgeInsets.only(bottom: 12),
//               decoration: BoxDecoration(
//                 color: Colors.white24,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             ListTile(
//               leading: CircleAvatar(
//                 child: Text(member.displayName[0].toUpperCase()),
//               ),
//               title: Text(
//                 member.displayName,
//                 style: const TextStyle(fontWeight: FontWeight.w700),
//               ),
//               subtitle: Text(member.isSpectator ? '👁 Spectator' : '🎮 Player'),
//             ),
//             const Divider(),
//             _FriendRequestButton(
//               targetUserId: member.userId,
//               displayName: member.displayName,
//               myId: myId,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _kickConfirm(
//     BuildContext ctx,
//     RoomProvider room,
//     RoomMemberEntity m,
//   ) async {
//     final confirmed = await showConfirmDialog(
//       context: ctx,
//       title: ctx.l10n.moderationKick,
//       message: ctx.l10n.moderationKickConfirm(m.displayName),
//       confirmLabel: ctx.l10n.moderationKick,
//       isDestructive: true,
//     );
//     if (confirmed == true) await room.kickPlayer(m.userId);
//   }

//   Future<void> _banConfirm(
//     BuildContext ctx,
//     RoomProvider room,
//     RoomMemberEntity m,
//   ) async {
//     await showModalBottomSheet(
//       context: ctx,
//       backgroundColor: Colors.transparent,
//       builder: (_) => ChangeNotifierProvider.value(
//         value: room,
//         child: BanConfirmSheet(targetMember: m),
//       ),
//     );
//   }

//   Future<void> _transferConfirm(
//     BuildContext ctx,
//     RoomProvider room,
//     RoomMemberEntity m,
//   ) async {
//     final confirmed = await showConfirmDialog(
//       context: ctx,
//       title: 'Transfer ownership',
//       message:
//           'Transfer room ownership to ${m.displayName}? You will become a regular player.',
//     );
//     if (confirmed == true) await room.transferOwnership(m.userId);
//   }
// }

// class _BottomActionBar extends StatelessWidget {
//   const _BottomActionBar({
//     required this.room,
//     required this.onLeave,
//     required this.onContinueGame,
//     required this.wasInActiveSession,
//   });
//   final RoomProvider room;
//   final VoidCallback onLeave;
//   final VoidCallback onContinueGame;
//   final bool wasInActiveSession;

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n;
//     final isReady = room.currentMember?.isReady ?? false;
//     final hasPack = room.room?.packId?.isNotEmpty == true;
//     final r = room.room;
//     final nonOwners = room.members.where((m) => !m.isOwner).toList();
//     final activePlayers = room.members.where((m) => !m.isSpectator).toList();
//     final hasEnough = activePlayers.length >= 1;
//     final allReady =
//         nonOwners.where((m) => !m.isSpectator).isEmpty ||
//         nonOwners.where((m) => !m.isSpectator).every((m) => m.isReady);
//     final canStart = hasPack && allReady && hasEnough;
//     return SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (room.isOwner) ...[
//               if (!hasPack)
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 4),
//                   child: Text(
//                     'Select a pack in settings to start',
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: Theme.of(context).colorScheme.error,
//                     ),
//                   ),
//                 ),
//               JButton(
//                 label: l10n.lobbyStartGame,
//                 onPressed: canStart ? _onStartGame(context, room) : null,
//                 icon: Icons.play_arrow_rounded,
//               ),
//             ] else if (room.isConnected) ...[
//               if (!(room.currentMember?.isSpectator ?? false))
//                 _ReadyButton(
//                   isReady: isReady,
//                   onToggle: () => room.toggleReady(),
//                 ),
//             ] else ...[
//               const SizedBox(
//                 height: 48,
//                 child: Center(
//                   child: SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   ),
//                 ),
//               ),
//             ],

//             const SizedBox(height: 8),

//             Row(
//               children: [
//                 if (room.isOwner) ...[
//                   Expanded(
//                     child: _ActionBtn(
//                       icon: Icons.tune_rounded,
//                       label: 'Settings',
//                       onTap: () => _showLobbySettings(context, room),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: _ActionBtn(
//                       icon: Icons.gavel_rounded,
//                       label: 'Moderation',
//                       onTap: () => showModalBottomSheet(
//                         context: context,
//                         isScrollControlled: true,
//                         backgroundColor: Colors.transparent,
//                         builder: (_) => ChangeNotifierProvider.value(
//                           value: room,
//                           child: _ModerationSheet(roomId: r?.id ?? ''),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: _ActionBtn(
//                       icon: Icons.person_add_rounded,
//                       label: 'Invite',
//                       onTap: r?.inviteCode != null
//                           ? () => showModalBottomSheet(
//                               context: context,
//                               isScrollControlled: true,
//                               backgroundColor: Colors.transparent,
//                               builder: (_) => _InviteFriendsSheet(
//                                 roomId: r!.id,
//                                 inviteCode: r.inviteCode!,
//                               ),
//                             )
//                           : null,
//                     ),
//                   ),
//                 ] else ...[
//                   Expanded(
//                     child: _ActionBtn(
//                       icon: Icons.exit_to_app_rounded,
//                       label: 'Leave',
//                       color: Theme.of(context).colorScheme.error,
//                       onTap: onLeave,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   VoidCallback? _onStartGame(BuildContext ctx, RoomProvider room) {
//     return () async {
//       final r = room.room;
//       if (r == null) return;

//       if (r.packId == null || r.packId!.isEmpty) {
//         ctx.showErrorSnackBar('Please select a pack before starting the game.');
//         return;
//       }

//       String gameType = r.gameType?.toDbString() ?? 'truth_or_dare';
//       try {
//         final packs = ctx.read<PackProvider>();
//         final cached = packs.allPacks
//             .where((p) => p.id == r.packId)
//             .firstOrNull;
//         if (cached != null) {
//           gameType = cached.gameType;
//         } else {
//           final fetched = await PackRepository.instance.getPackDetail(
//             r.packId!,
//           );
//           gameType = fetched.gameType;
//         }
//       } catch (_) {}

//       final displayNames = {
//         for (final m in room.members) m.userId: m.displayName,
//       };

//       final config = GameConfig(
//         maxRounds: room.settings.maxRounds,
//         turnTimerSeconds: room.settings.turnTimerSeconds,
//         allowSkip: room.settings.allowSkip,
//         allowSpicy: r.allowSpicy,
//         enablePunishments: true,
//         packId: r.packId,
//         language: r.language,
//       );

//       await sl.realtimeService.broadcastGameStarted(r.id, {
//         'game_type': gameType,
//         'pack_id': r.packId,
//         'config': config.toMap(),
//         'player_ids': room.members.where((m) => !m.isSpectator).map((m) => m.userId).toList(),
//         'display_names': displayNames,
//       });

//       await sl.roomRepository.updateStatus(
//         r.id,
//         RoomStatus.inGame,
//         gameType: gameType,
//       );

//       if (ctx.mounted) {
//         final packs = ctx.read<PackProvider>();
//         final pack = packs.allPacks
//             .where((p) => p.id == (r.packId ?? ''))
//             .firstOrNull;
//         final coverUrl = pack?.coverImageUrl ?? '';

//         AppRouter.router.push(
//           '${RouteNames.home}/room/${r.id}/game',
//           extra: {
//             'config': config,
//             'playerIds': room.members.where((m) => !m.isSpectator).map((m) => m.userId).toList(),
//             'displayNames': displayNames,
//             'packId': r.packId ?? '',
//             'packCoverUrl': coverUrl,
//             'isOwner': true,
//             'gameType': gameType,
//           },
//         );
//       }
//     };
//   }

//   void _showLobbySettings(BuildContext ctx, RoomProvider room) {
//     if (!room.isOwner) return;
//     showModalBottomSheet(
//       context: ctx,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => ChangeNotifierProvider.value(
//         value: room,
//         child: const GameSettingsSheet(),
//       ),
//     );
//   }
// }

// class _ActionBtn extends StatelessWidget {
//   const _ActionBtn({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//     this.color,
//   });
//   final IconData icon;
//   final String label;
//   final VoidCallback? onTap;
//   final Color? color;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final c = color ?? theme.colorScheme.primary;
//     return Material(
//       color: c.withOpacity(0.10),
//       borderRadius: BorderRadius.circular(12),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 10),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 icon,
//                 size: 20,
//                 color: onTap != null ? c : theme.disabledColor,
//               ),
//               const SizedBox(height: 3),
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.w600,
//                   color: onTap != null ? c : theme.disabledColor,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ReadyButton extends StatelessWidget {
//   const _ReadyButton({required this.isReady, required this.onToggle});
//   final bool isReady;
//   final VoidCallback onToggle;

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       child: OutlinedButton(
//         onPressed: onToggle,
//         style: OutlinedButton.styleFrom(
//           minimumSize: const Size(double.infinity, 52),
//           backgroundColor: isReady
//               ? AppColors.successGreen.withOpacity(0.08)
//               : null,
//           side: BorderSide(
//             color: isReady
//                 ? AppColors.successGreen
//                 : context.colorScheme.outline,
//             width: isReady ? 2 : 1,
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               isReady
//                   ? Icons.check_circle_rounded
//                   : Icons.radio_button_unchecked_rounded,
//               color: isReady
//                   ? AppColors.successGreen
//                   : context.colorScheme.onSurfaceVariant,
//             ),
//             const SizedBox(width: 8),
//             Text(
//               isReady ? context.l10n.lobbyReady : context.l10n.lobbyNotReady,
//               style: context.textTheme.labelLarge?.copyWith(
//                 fontWeight: FontWeight.w700,
//                 color: isReady
//                     ? AppColors.successGreen
//                     : context.colorScheme.onSurface,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _RejoinBanner extends StatelessWidget {
//   const _RejoinBanner({required this.onRejoin});
//   final VoidCallback onRejoin;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       color: AppColors.tealGreen.withOpacity(0.15),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       child: Row(
//         children: [
//           const Icon(Icons.sports_esports_rounded, color: AppColors.tealGreen),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               'Game in progress',
//               style: context.textTheme.bodyMedium?.copyWith(
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           FilledButton(
//             onPressed: onRejoin,
//             style: FilledButton.styleFrom(
//               backgroundColor: AppColors.tealGreen,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             ),
//             child: const Text('Rejoin'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _JoinRequestsPanel extends StatefulWidget {
//   const _JoinRequestsPanel({required this.roomId, this.showAlways = false});
//   final String roomId;
//   final bool showAlways;
//   @override
//   State<_JoinRequestsPanel> createState() => _JoinRequestsPanelState();
// }

// class _JoinRequestsPanelState extends State<_JoinRequestsPanel> {
//   List<Map<String, dynamic>> _requests = [];
//   bool _loading = true;
//   Timer? _refreshTimer;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//     _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
//   }

//   @override
//   void dispose() {
//     _refreshTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       final rows = await sl.roomRepository.getPendingRequests(widget.roomId);
//       if (mounted)
//         setState(() {
//           _requests = rows;
//           _loading = false;
//         });
//     } catch (_) {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _resolve(String requestId, String userId, bool approve) async {
//     try {
//       await sl.roomRepository.resolveJoinRequest(
//         requestId: requestId,
//         approve: approve,
//         roomId: widget.roomId,
//         targetUserId: userId,
//       );
//       await _load();
//     } catch (e) {
//       if (mounted) context.showErrorSnackBar('Failed: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     if (_loading && _requests.isEmpty) return const LinearProgressIndicator();
//     if (_requests.isEmpty && !widget.showAlways) return const SizedBox.shrink();
//     if (_requests.isEmpty) {
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 4),
//         child: Row(
//           children: [
//             const Icon(
//               Icons.check_circle_outline,
//               size: 14,
//               color: Colors.green,
//             ),
//             const SizedBox(width: 6),
//             Text(
//               'No pending join requests',
//               style: theme.textTheme.labelSmall?.copyWith(
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(
//               'Join Requests (${_requests.length})',
//               style: theme.textTheme.titleSmall?.copyWith(
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const Spacer(),
//             IconButton(
//               icon: const Icon(Icons.refresh, size: 18),
//               onPressed: _load,
//             ),
//           ],
//         ),
//         ..._requests.map((req) {
//           final profile = req['profiles'] as Map<String, dynamic>? ?? {};
//           final name = profile['display_name'] as String? ?? 'Player';
//           final msg = req['message'] as String?;
//           return Card(
//             margin: const EdgeInsets.only(bottom: 8),
//             child: ListTile(
//               leading: CircleAvatar(child: Text(name[0].toUpperCase())),
//               title: Text(
//                 name,
//                 style: const TextStyle(fontWeight: FontWeight.w600),
//               ),
//               subtitle: msg != null && msg.isNotEmpty ? Text(msg) : null,
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     icon: const Icon(
//                       Icons.check_circle_rounded,
//                       color: Colors.green,
//                     ),
//                     onPressed: () => _resolve(
//                       req['id'] as String,
//                       req['user_id'] as String,
//                       true,
//                     ),
//                     tooltip: 'Approve',
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.cancel_rounded, color: Colors.red),
//                     onPressed: () => _resolve(
//                       req['id'] as String,
//                       req['user_id'] as String,
//                       false,
//                     ),
//                     tooltip: 'Reject',
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }),
//         const Divider(),
//       ],
//     );
//   }
// }

// class _JoinRoleDialog extends StatelessWidget {
//   const _JoinRoleDialog({this.isInGame = false});
//   final bool isInGame;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     return AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       title: Text(
//         'How do you want to join?',
//         style: theme.textTheme.titleLarge?.copyWith(
//           fontWeight: FontWeight.w800,
//         ),
//       ),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             isInGame
//                 ? 'This game is already in progress.'
//                 : 'Choose your role in this room.',
//             style: theme.textTheme.bodyMedium?.copyWith(
//               color: theme.colorScheme.onSurfaceVariant,
//             ),
//           ),
//           const SizedBox(height: 20),
//           _RoleOption(
//             icon: Icons.sports_esports_rounded,
//             title: 'Join as Player',
//             subtitle: 'Take part in the game',
//             color: AppColors.successGreen,
//             onTap: () => Navigator.pop(context, 'player'),
//           ),
//           const SizedBox(height: 10),
//           _RoleOption(
//             icon: Icons.visibility_rounded,
//             title: 'Watch as Spectator',
//             subtitle: 'Observe without playing',
//             color: AppColors.infoBlue,
//             onTap: () => Navigator.pop(context, 'spectator'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _RoleOption extends StatelessWidget {
//   const _RoleOption({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.color,
//     required this.onTap,
//   });
//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final Color color;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(14),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.08),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: color.withOpacity(0.25)),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, color: color, size: 24),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: TextStyle(fontWeight: FontWeight.w700, color: color),
//                   ),
//                   Text(
//                     subtitle,
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: color.withOpacity(0.75),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(Icons.chevron_right_rounded, color: color, size: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _SpectatorRequestsSheet extends StatefulWidget {
//   const _SpectatorRequestsSheet({required this.requests, required this.room});
//   final List<Map<String, dynamic>> requests;
//   final RoomProvider room;

//   @override
//   State<_SpectatorRequestsSheet> createState() =>
//       _SpectatorRequestsSheetState();
// }

// class _SpectatorRequestsSheetState extends State<_SpectatorRequestsSheet> {
//   final Set<String> _decided = {};

//   Future<void> _decide(Map<String, dynamic> req, bool approve) async {
//     final id = req['id'] as String;
//     final userId = req['user_id'] as String;
//     setState(() => _decided.add(id));
//     await widget.room.decideSpectatorRequest(
//       requestId: id,
//       requestingUserId: userId,
//       approve: approve,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final pending = widget.requests
//         .where((r) => !_decided.contains(r['id'] as String))
//         .toList();

//     return SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Text(
//                   'Spectator Requests',
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 if (pending.isNotEmpty) ...[
//                   const SizedBox(width: 8),
//                   Badge(label: Text('${pending.length}')),
//                 ],
//               ],
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'These players want to watch the game as spectators.',
//               style: theme.textTheme.bodySmall?.copyWith(
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//             ),
//             const SizedBox(height: 12),
//             if (pending.isEmpty)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 24),
//                 child: Center(
//                   child: Text(
//                     'All requests have been decided.',
//                     style: theme.textTheme.bodyMedium?.copyWith(
//                       color: theme.colorScheme.onSurfaceVariant,
//                     ),
//                   ),
//                 ),
//               )
//             else
//               ...pending.map((req) {
//                 final userId = req['user_id'] as String;
//                 return ListTile(
//                   contentPadding: EdgeInsets.zero,
//                   leading: CircleAvatar(
//                     child: Text(userId.substring(0, 1).toUpperCase()),
//                   ),
//                   title: Text(
//                     userId.substring(0, 8),
//                     style: const TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   subtitle: const Text('Wants to spectate'),
//                   trailing: SizedBox(
//                     width: 130,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         IconButton(
//                           tooltip: 'Deny',
//                           icon: const Icon(
//                             Icons.close_rounded,
//                             color: Colors.red,
//                           ),
//                           onPressed: () => _decide(req, false),
//                         ),
//                         IconButton(
//                           tooltip: 'Approve',
//                           icon: const Icon(
//                             Icons.check_rounded,
//                             color: Colors.green,
//                           ),
//                           onPressed: () => _decide(req, true),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ModerationSheet extends StatefulWidget {
//   const _ModerationSheet({required this.roomId});
//   final String roomId;
//   @override
//   State<_ModerationSheet> createState() => _ModerationSheetState();
// }

// class _ModerationSheetState extends State<_ModerationSheet> {
//   List<Map<String, dynamic>> _banned = [];
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     try {
//       final banned = await sl.roomRepository.getBannedMembers(widget.roomId);
//       if (mounted)
//         setState(() {
//           _banned = banned;
//           _loading = false;
//         });
//     } catch (_) {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final room = context.watch<RoomProvider>();
//     final muted = room.members.where((m) => m.isMuted).toList();

//     return Container(
//       constraints: BoxConstraints(
//         maxHeight: MediaQuery.sizeOf(context).height * 0.75,
//       ),
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surface,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Center(
//             child: Container(
//               width: 36,
//               height: 4,
//               margin: const EdgeInsets.symmetric(vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.white24,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),

//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
//             child: Text(
//               '⚖️ Moderation',
//               style: theme.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//           ),

//           Expanded(
//             child: _loading
//                 ? const Center(child: CircularProgressIndicator())
//                 : (muted.isEmpty && _banned.isEmpty)
//                 ? Center(
//                     child: Text(
//                       'No muted or banned players.',
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         color: theme.colorScheme.onSurfaceVariant,
//                       ),
//                     ),
//                   )
//                 : ListView(
//                     padding: const EdgeInsets.all(12),
//                     children: [
//                       if (muted.isNotEmpty) ...[
//                         Padding(
//                           padding: const EdgeInsets.only(bottom: 8),
//                           child: Text(
//                             '🔇 Muted',
//                             style: theme.textTheme.labelLarge?.copyWith(
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                         ...muted.map(
//                           (m) => ListTile(
//                             leading: CircleAvatar(
//                               child: Text(m.displayName[0].toUpperCase()),
//                             ),
//                             title: Text(m.displayName),
//                             subtitle: const Text('Muted'),
//                             trailing: TextButton(
//                               onPressed: () =>
//                                   room.mutePlayer(m.userId, muted: false),
//                               child: const Text('Unmute'),
//                             ),
//                             dense: true,
//                           ),
//                         ),
//                         const Divider(),
//                       ],
//                       if (_banned.isNotEmpty) ...[
//                         Padding(
//                           padding: const EdgeInsets.only(bottom: 8),
//                           child: Text(
//                             '🚫 Banned',
//                             style: theme.textTheme.labelLarge?.copyWith(
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                         ..._banned.map((b) {
//                           final name =
//                               b['display_name'] as String? ??
//                               b['user_id'] as String? ??
//                               '?';
//                           final reason = b['reason'] as String?;
//                           final userId = b['user_id'] as String;
//                           return ListTile(
//                             leading: CircleAvatar(
//                               child: Text(name[0].toUpperCase()),
//                             ),
//                             title: Text(name),
//                             subtitle: reason != null
//                                 ? Text('Reason: $reason')
//                                 : null,
//                             trailing: TextButton(
//                               onPressed: () async {
//                                 await room.unbanPlayer(userId);
//                                 _load();
//                               },
//                               child: const Text('Unban'),
//                             ),
//                             dense: true,
//                           );
//                         }),
//                       ],
//                     ],
//                   ),
//           ),
//           const SizedBox(height: 16),
//         ],
//       ),
//     );
//   }
// }

// class _SpectatorsSheet extends StatelessWidget {
//   const _SpectatorsSheet({required this.spectators});
//   final List<RoomMemberEntity> spectators;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surface,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 36,
//             height: 4,
//             margin: const EdgeInsets.only(bottom: 16),
//             decoration: BoxDecoration(
//               color: theme.colorScheme.outlineVariant,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           Row(
//             children: [
//               Icon(
//                 Icons.visibility_outlined,
//                 size: 18,
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 'Spectators (${spectators.length})',
//                 style: theme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           ...spectators.map(
//             (s) => ListTile(
//               contentPadding: EdgeInsets.zero,
//               leading: CircleAvatar(
//                 backgroundImage: s.avatarUrl != null
//                     ? NetworkImage(s.avatarUrl!)
//                     : null,
//                 child: s.avatarUrl == null
//                     ? Text(s.displayName[0].toUpperCase())
//                     : null,
//               ),
//               title: Text(s.displayName),
//               trailing: Icon(
//                 Icons.visibility_outlined,
//                 size: 14,
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//               dense: true,
//             ),
//           ),
//           const SizedBox(height: 8),
//         ],
//       ),
//     );
//   }
// }

// class _FriendRequestButton extends StatefulWidget {
//   const _FriendRequestButton({
//     required this.targetUserId,
//     required this.displayName,
//     required this.myId,
//   });
//   final String targetUserId, displayName, myId;
//   @override
//   State<_FriendRequestButton> createState() => _FriendRequestButtonState();
// }

// class _FriendRequestButtonState extends State<_FriendRequestButton> {
//   bool _sent = false, _loading = false;
//   String _status = '';

//   @override
//   void initState() {
//     super.initState();
//     _checkStatus();
//   }

//   Future<void> _checkStatus() async {
//     try {
//       final friendship = await sl.friendsRepository.getFriendshipStatus(
//         userId: widget.myId,
//         otherId: widget.targetUserId,
//       );
//       if (mounted)
//         setState(() {
//           if (friendship == null)
//             _status = 'none';
//           else if (friendship.isAccepted)
//             _status = 'friend';
//           else
//             _status = 'pending';
//         });
//     } catch (_) {
//       if (mounted) setState(() => _status = 'none');
//     }
//   }

//   Future<void> _send() async {
//     setState(() => _loading = true);
//     try {
//       await sl.friendsRepository.sendFriendRequest(
//         requesterId: widget.myId,
//         addresseeId: widget.targetUserId,
//       );
//       if (mounted)
//         setState(() {
//           _sent = true;
//           _loading = false;
//           _status = 'pending';
//         });
//       if (mounted)
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Friend request sent to ${widget.displayName} ✅'),
//           ),
//         );
//     } catch (e) {
//       if (mounted) setState(() => _loading = false);
//       final msg = e.toString().contains('Cannot interact')
//           ? 'Cannot send request to ${widget.displayName}'
//           : 'Could not send request — try again';
//       if (mounted)
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(msg)));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_status == '') {
//       return const ListTile(
//         leading: SizedBox(
//           width: 20,
//           height: 20,
//           child: CircularProgressIndicator(strokeWidth: 2),
//         ),
//         title: Text('Checking…'),
//         dense: true,
//       );
//     }
//     if (_status == 'friend') {
//       return ListTile(
//         leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
//         title: Text(
//           'You and ${widget.displayName} are friends ✓',
//           style: const TextStyle(fontSize: 13),
//         ),
//         dense: true,
//       );
//     }
//     if (_status == 'pending' || _sent) {
//       return ListTile(
//         leading: const Icon(Icons.hourglass_top_rounded, color: Colors.orange),
//         title: const Text('Friend request pending'),
//         dense: true,
//       );
//     }
//     return ListTile(
//       leading: _loading
//           ? const SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             )
//           : const Icon(Icons.person_add_outlined),
//       title: Text('Add ${widget.displayName} as friend'),
//       dense: true,
//       onTap: _loading ? null : _send,
//     );
//   }
// }

// class _InviteFriendsSheet extends StatefulWidget {
//   const _InviteFriendsSheet({required this.roomId, required this.inviteCode});
//   final String roomId, inviteCode;
//   @override
//   State<_InviteFriendsSheet> createState() => _InviteFriendsSheetState();
// }

// class _InviteFriendsSheetState extends State<_InviteFriendsSheet> {
//   Set<String> _invited = {};
//   bool _loadingInvited = true;

//   @override
//   void initState() {
//     super.initState();
//     sl.roomRepository
//         .getInvitedUserIds(widget.roomId)
//         .then((ids) {
//           if (!mounted) return;
//           setState(() {
//             _invited = ids;
//             _loadingInvited = false;
//           });
//         })
//         .catchError((_) {
//           if (!mounted) return;
//           setState(() => _loadingInvited = false);
//         });
//   }

//   Future<void> _invite(FriendEntity friend) async {
//     if (_invited.contains(friend.userId)) return;
//     try {
//       await sl.roomRepository.sendInvite(
//         roomId: widget.roomId,
//         invitedUserId: friend.userId,
//       );
//       if (!mounted) return;
//       setState(() => _invited.add(friend.userId));
//     } catch (e) {
//       if (!mounted) return;
//       context.showErrorSnackBar(
//         'Could not send invite to ${friend.displayName}',
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final friends = context
//         .watch<FriendsProvider>()
//         .friends
//         .where((f) => f.isAccepted)
//         .toList();

//     return Container(
//       constraints: BoxConstraints(
//         maxHeight: MediaQuery.sizeOf(context).height * 0.65,
//       ),
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surface,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Center(
//             child: Container(
//               width: 36,
//               height: 4,
//               margin: const EdgeInsets.symmetric(vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.white24,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
//             child: Text(
//               '👥 Invite Friends',
//               style: theme.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//           ),
//           if (friends.isEmpty)
//             Padding(
//               padding: const EdgeInsets.all(24),
//               child: Text(
//                 'No friends to invite yet.',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: theme.colorScheme.onSurfaceVariant,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             )
//           else
//             Expanded(
//               child: ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 itemCount: friends.length,
//                 itemBuilder: (_, i) {
//                   final f = friends[i];
//                   final sent = _invited.contains(f.userId);
//                   return ListTile(
//                     leading: CircleAvatar(
//                       child: Text(f.displayName[0].toUpperCase()),
//                     ),
//                     title: Text(f.displayName),
//                     trailing: SizedBox(
//                       width: sent ? 68 : 84,
//                       child: sent
//                           ? Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: const [
//                                 Icon(
//                                   Icons.check,
//                                   color: Colors.green,
//                                   size: 16,
//                                 ),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   'Invited',
//                                   style: TextStyle(
//                                     color: Colors.green,
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                               ],
//                             )
//                           : FilledButton.tonal(
//                               style: FilledButton.styleFrom(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 12,
//                                 ),
//                                 minimumSize: Size.zero,
//                                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                               ),
//                               onPressed: () => _invite(f),
//                               child: const Text(
//                                 'Invite',
//                                 style: TextStyle(fontSize: 13),
//                               ),
//                             ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Builder(
//                     builder: (ctx) {
//                       final myId =
//                           ctx.read<AuthProvider>().currentUser?.id ?? '';
//                       return OutlinedButton.icon(
//                         onPressed: () {
//                           final myId2 =
//                               context.read<AuthProvider>().currentUser?.id ??
//                               '';
//                           final code2 = widget.inviteCode;
//                           Share.share(
//                             '🎮 Join my Jma3a room!\n\nCode: \$code2\n(jma3a://join?code=\$code2&invited_by=\$myId2)',
//                             subject: '🎮 Jma3a Code: \$code2',
//                           );
//                         },
//                         icon: const Icon(Icons.share_rounded, size: 16),
//                         label: const Text('Share invite link'),
//                       );
//                     },
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

import 'dart:async';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/failures.dart';
import '../../data/room_repository.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../friends/data/friends_repository.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../../shared/widgets/cards/user_avatar.dart';
import '../../../friends/presentation/friends_provider.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../../../shared/widgets/overlays/confirm_dialog.dart';
import '../../../packs/data/pack_repository.dart';
import '../../../packs/presentation/pack_provider.dart';
import '../room_provider.dart';
import '../../../../features/games/engine/base_game_engine.dart';
import '../widgets/chat_panel.dart';
import '../widgets/game_settings_sheet.dart';
import '../widgets/member_tile.dart';
import '../widgets/moderation_sheet.dart';
import '../../../../shared/widgets/join_requests_panel.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.roomId});
  final String roomId;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  late final RoomProvider _provider;
  StreamSubscription<RoomLifecycleEvent>? _lifecycleSub;
  List<String>? _sessionPlayerIds;
  bool _fetchingSessionPlayerIds = false;
  List<Map<String, dynamic>> _pendingSpectatorRequests = [];
  bool _fetchingSpectatorRequests = false;
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);

    final auth = context.read<AuthProvider>();
    _provider = RoomProvider(
      roomRepository: sl.roomRepository,
      realtimeService: sl.realtimeService,
      presenceService: sl.presenceService,
      cacheService: sl.roomCacheService,
      currentUserId: auth.currentUser!.id,
      currentDisplayName: auth.currentUser!.displayName ?? 'Player',
      currentAvatarUrl: auth.currentUser!.avatarUrl,
    );

    _initializeWithRoleCheck();

    _lifecycleSub = _provider.lifecycleEvents.listen(_onLifecycleEvent);

    _provider.addListener(_onRoomStateChanged);
  }

  Future<void> _initializeWithRoleCheck() async {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    bool isRoomOwner = false;
    try {
      final roomInfo = await Supabase.instance.client
          .from('rooms')
          .select('status, owner_id')
          .eq('id', widget.roomId)
          .maybeSingle();
      final settingsInfo = await Supabase.instance.client
          .from('room_settings')
          .select('allow_spectators, allow_anonymous_spectators')
          .eq('room_id', widget.roomId)
          .maybeSingle();

      final isInGame = roomInfo?['status'] == 'in_game';
      final allowSpectators =
          settingsInfo?['allow_spectators'] as bool? ?? false;
      final allowAnonymousSpectators =
          settingsInfo?['allow_anonymous_spectators'] as bool? ?? true;
      isRoomOwner = roomInfo?['owner_id'] == myId;

      // Must not clear the pack while the room is mid-game — a returning
      // owner reconnecting to an in-progress/paused session needs their
      // selected pack preserved (recover_owner_room, triggered inside
      // _provider.initialize() below, resets an in-progress game back to a
      // waiting lobby without touching pack_id). Only applies to an
      // ordinary "owner opens their own still-waiting room" entry.
      if (isRoomOwner && !isInGame && roomInfo?['status'] != 'paused') {
        await sl.roomRepository.clearPack(widget.roomId).catchError((_) {});
      }

      final isPremium = mounted
          ? (context.read<AuthProvider>().currentUser?.isPremiumActive ?? false)
          : false;

      String role = 'player';
      if (allowSpectators && !isRoomOwner && mounted) {
        final picked = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _JoinRoleDialog(
            isInGame: isInGame,
            isPremium: isPremium,
            allowAnonymous: allowAnonymousSpectators,
          ),
        );
        role = picked ?? 'player';
      }

      if (mounted) {
        _provider.initialize(widget.roomId, role: role);
      }
    } catch (_) {
      // Room/settings fetch failed above, so room status is unknown here —
      // skip clearPack entirely rather than risk clobbering pack_id for a
      // room that turns out to be mid-game (see the guarded call above).
      if (mounted) {
        _provider.initialize(widget.roomId);
      }
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onRoomStateChanged);
    _ownerLeftTimer?.cancel();
    _lifecycleSub?.cancel();
    _tabs.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _onLifecycleEvent(RoomLifecycleEvent event) {
    if (!mounted) return;
    switch (event) {
      case RoomLifecycleEvent.kicked:
        _showEventBanner(_moderationMessage('You were removed'), isError: true);
        context.go(RouteNames.home);
      case RoomLifecycleEvent.banned:
        _showEventBanner(
          _moderationMessage('You were banned'),
          isError: true,
        );
        context.go(RouteNames.home);
      case RoomLifecycleEvent.roomClosed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            AppRouter.router.go(RouteNames.home);
            return;
          }
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => AlertDialog(
              title: const Text('Room Closed'),
              content: const Text('The host closed the room.'),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    AppRouter.router.go(RouteNames.home);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });
      case RoomLifecycleEvent.ownershipTransferred:
        _showEventBanner("You're now the room owner 👑");
      case RoomLifecycleEvent.memberLeft:
        final name = _provider.lastDepartedMemberName;
        if (name != null && name.isNotEmpty) {
          _showEventBanner('$name left the game');
        }
    }
  }

  void _showEventBanner(String message, {bool isError = false}) {
    if (!mounted) return;
    context.showSnackBar(message, isError: isError);
  }

  /// Builds a real "removed by X: reason" message from the actor name +
  /// reason kickPlayer/banPlayer already broadcast — falling back to
  /// [base] alone when either is missing (e.g. an older client that
  /// hasn't sent them yet).
  String _moderationMessage(String base) {
    final actor = _provider.lastModerationActorName;
    final reason = _provider.lastModerationReason;
    var message = (actor != null && actor.isNotEmpty)
        ? '$base by $actor'
        : base;
    if (reason != null && reason.trim().isNotEmpty) {
      message = '$message: ${reason.trim()}';
    }
    return message;
  }

  bool _navigatedToGame = false;

  Timer? _ownerLeftTimer;
  int _maxMembersSeen = 0;

  void _onRoomStateChanged() {
    if (!mounted) return;
    final room = _provider;

    if (room.room?.status == RoomStatus.closed && !room.isOwner) {
      _showEventBanner('The host closed the room.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (context.canPop())
          context.pop();
        else
          context.go(RouteNames.home);
      });
      return;
    }

    if (room.members.length > _maxMembersSeen) {
      _maxMembersSeen = room.members.length;
    }

    final ownerGone =
        room.isInitialized &&
        !room.isOwner &&
        _maxMembersSeen >= 2 &&
        room.members.isNotEmpty &&
        room.room?.status != RoomStatus.inGame &&
        !room.members.any((m) => m.isOwner);

    if (ownerGone) {
      _ownerLeftTimer ??= Timer(const Duration(seconds: 2), () {
        _ownerLeftTimer = null;
        if (!mounted) return;
        final r2 = _provider;
        if (r2.isInitialized &&
            !r2.isOwner &&
            r2.members.isNotEmpty &&
            r2.room?.status != RoomStatus.inGame &&
            !r2.members.any((m) => m.isOwner)) {
          _showEventBanner('The host left the room.');
          if (context.canPop())
            context.pop();
          else
            context.go(RouteNames.home);
        }
      });
    } else {
      _ownerLeftTimer?.cancel();
      _ownerLeftTimer = null;
    }

    if (ownerGone) return;

    if (room.room?.status == RoomStatus.waiting) {
      _navigatedToGame = false;
    }

    if (!_navigatedToGame &&
        room.room?.status == RoomStatus.inGame &&
        room.isInitialized &&
        !room.isOwner &&
        room.room?.gameType != null) {
      _navigatedToGame = true;
      final gameType = room.room!.gameType!.toDbString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _navigateFollowerToGame(gameType);
      });
      return;
    }

    if (!_navigatedToGame &&
        room.room?.status == RoomStatus.inGame &&
        room.isInitialized &&
        room.isOwner &&
        room.room?.gameType != null) {
      _navigatedToGame = true;
      final gameType = room.room!.gameType!.toDbString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _navigateOwnerToGame(gameType);
      });
    }
  }

  void _navigateOwnerToGame(String gameType) {
    if (!mounted) return;
    final r = _provider.room;
    if (r == null) return;
    if (r.packId == null || r.packId!.isEmpty) {
      // Room flipped to in-game before its pack_id was populated locally
      // (reconnect/race) — bail out instead of pushing the game screen with
      // an empty packId, which crashes deep in initAsOwner with a cryptic
      // Postgres "invalid input syntax for type uuid" error.
      _navigatedToGame = false;
      return;
    }
    final displayNames = {
      for (final m in _provider.members) m.userId: m.displayName,
    };
    final packs = context.read<PackProvider>();
    final pack = packs.allPacks
        .where((p) => p.id == (r.packId ?? ''))
        .firstOrNull;

    sl.realtimeService
        .broadcastRoomEvent(r.id, {
          'type': 'game_started',
          'game_type': gameType,
          'pack_id': r.packId ?? '',
          'language': r.language,
          'max_rounds': _provider.settings.maxRounds,
          'turn_timer_secs': _provider.settings.turnTimerSeconds,
          'allow_skip': _provider.settings.allowSkip,
          'allow_spicy': r.allowSpicy,
          'player_ids': _provider.members
              .where((m) => !m.isSpectator)
              .map((m) => m.userId)
              .toList(),
          'display_names': displayNames,
        })
        .catchError((_) {});
    sl.roomRepository.notifyGameStarted(r.id).ignore();

    AppRouter.router.push(
      '${RouteNames.home}/room/${r.id}/game',
      extra: {
        'config': GameConfig(
          maxRounds: _provider.settings.maxRounds,
          turnTimerSeconds: _provider.settings.turnTimerSeconds,
          allowSkip: _provider.settings.allowSkip,
          allowSpicy: r.allowSpicy,
          enablePunishments: _provider.settings.enablePunishments,
          punishmentSource: _provider.settings.punishmentSource,
          suggestedPunishments: pack?.suggestedPunishments,
          proofVisibilityPolicy: _provider.settings.proofVisibilityPolicy,
          proofViewSeconds: _provider.settings.proofViewSeconds,
          proofReplayMode: _provider.settings.proofReplayMode,
          packId: r.packId,
          language: r.language,
        ),
        'playerIds': _provider.members
            .where((m) => !m.isSpectator)
            .map((m) => m.userId)
            .toList(),
        'displayNames': displayNames,
        'packId': r.packId ?? '',
        'packCoverUrl': pack?.coverImageUrl ?? '',
        'isOwner': true,
        'isSpectator': false,
        'gameType': gameType,
        'roomProvider': _provider,
      },
    );
  }

  void _navigateFollowerToGame(String gameType) {
    if (!mounted) return;
    final r = _provider.room;
    if (r == null) return;

    final displayNames = {
      for (final m in _provider.members) m.userId: m.displayName,
    };

    String followerCoverUrl = '';
    PackEntity? pack;
    try {
      final packProv = context.read<PackProvider>();
      pack = packProv.allPacks
          .where((p) => p.id == (r.packId ?? ''))
          .firstOrNull;
      followerCoverUrl = pack?.coverImageUrl ?? '';
    } catch (_) {}

    final extra = {
      'config': GameConfig(
        maxRounds: _provider.settings.maxRounds,
        turnTimerSeconds: _provider.settings.turnTimerSeconds,
        allowSkip: _provider.settings.allowSkip,
        allowSpicy: r.allowSpicy,
        enablePunishments: _provider.settings.enablePunishments,
        punishmentSource: _provider.settings.punishmentSource,
        suggestedPunishments: pack?.suggestedPunishments,
        proofVisibilityPolicy: _provider.settings.proofVisibilityPolicy,
        proofViewSeconds: _provider.settings.proofViewSeconds,
        proofReplayMode: _provider.settings.proofReplayMode,
        packId: r.packId,
        language: r.language,
      ),
      'playerIds': _provider.members
          .where((m) => !m.isSpectator)
          .map((m) => m.userId)
          .toList(),
      'displayNames': displayNames,
      'packId': r.packId ?? '',
      'packCoverUrl': followerCoverUrl,
      'isOwner': false,
      'isModerator': _provider.currentMember?.isModerator ?? false,
      'isSpectator': _provider.currentMember?.isSpectator ?? false,
      'gameType': gameType,
      'roomProvider': _provider,
    };

    AppRouter.router.push('${RouteNames.home}/room/${r.id}/game', extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<RoomProvider>(
        builder: (ctx, room, _) => _build(ctx, room),
      ),
    );
  }

  Widget _build(BuildContext ctx, RoomProvider room) {
    if (room.connectionState == RoomConnectionState.failed &&
        !room.isInitialized) {
      final errorMsg = room.failure?.message ?? 'Connection failed';
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: errorMsg,
          onRetry: () => _provider.initialize(widget.roomId),
        ),
      );
    }

    if (room.connectionState == RoomConnectionState.pendingApproval) {
      return Scaffold(
        appBar: AppBar(title: const Text('Join Request Sent')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top_rounded, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Waiting for the host to approve your request to join.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  "You'll be let in automatically once they approve.",
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => ctx.go(RouteNames.home),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final gameIsActive =
        room.room?.gameType != null && (room.room?.status == RoomStatus.inGame);
    if (gameIsActive &&
        !room.isOwner &&
        _sessionPlayerIds == null &&
        !_fetchingSessionPlayerIds) {
      _fetchingSessionPlayerIds = true;
      sl.roomRepository
          .getActiveSessionPlayerIds(widget.roomId)
          .then((ids) {
            if (!mounted) return;
            setState(() {
              _sessionPlayerIds = ids;
              _fetchingSessionPlayerIds = false;
            });
          })
          .catchError((_) {
            if (!mounted) return;
            setState(() => _fetchingSessionPlayerIds = false);
          });
    }
    if (!gameIsActive && _sessionPlayerIds != null) {
      _sessionPlayerIds = null;
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _leaveRoom();
        });
      },
      child: Scaffold(
        appBar: _LobbyAppBar(room: room, tabs: _tabs, onLeave: _leaveRoom),
        body: Column(
          children: [
            if (room.connectionState != RoomConnectionState.connected &&
                room.connectionState != RoomConnectionState.connecting)
              _ConnectionBanner(
                state: room.connectionState,
                onRetry: room.retryConnection,
              ),
            if (room.room?.status == RoomStatus.inGame &&
                room.room?.gameType != null)
              _RejoinBanner(
                room: room,
                onRejoin: () {
                  _navigatedToGame = false;
                  final r = room.room!;
                  final gameType = r.gameType!.toDbString();
                  final displayNames = {
                    for (final m in room.members) m.userId: m.displayName,
                  };
                  final rejoinPack = context
                      .read<PackProvider>()
                      .allPacks
                      .where((p) => p.id == r.packId)
                      .firstOrNull;
                  final config = GameConfig(
                    maxRounds: room.settings.maxRounds,
                    turnTimerSeconds: room.settings.turnTimerSeconds,
                    allowSkip: room.settings.allowSkip,
                    allowSpicy: r.allowSpicy,
                    enablePunishments: room.settings.enablePunishments,
                    punishmentSource: room.settings.punishmentSource,
                    suggestedPunishments: rejoinPack?.suggestedPunishments,
                    proofVisibilityPolicy: room.settings.proofVisibilityPolicy,
                    proofViewSeconds: room.settings.proofViewSeconds,
                    proofReplayMode: room.settings.proofReplayMode,
                    packId: r.packId,
                  );
                  AppRouter.router.push(
                    '${RouteNames.home}/room/${r.id}/game',
                    extra: {
                      'config': config,
                      'playerIds': room.members
                          .where((m) => !m.isSpectator)
                          .map((m) => m.userId)
                          .toList(),
                      'displayNames': displayNames,
                      'packId': r.packId ?? '',
                      'isOwner': room.isOwner,
                      'isModerator': room.currentMember?.isModerator ?? false,
                      'isSpectator': room.currentMember?.isSpectator ?? false,
                      'gameType': gameType,
                      'roomProvider': room,
                    },
                  );
                },
              ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _LobbyTab(room: room),
                  ChatPanel(room: room),
                ],
              ),
            ),
            _BottomActionBar(
              room: room,
              wasInActiveSession:
                  _sessionPlayerIds == null ||
                  _sessionPlayerIds!.contains(
                    context.read<AuthProvider>().currentUser?.id,
                  ),
              onLeave: _leaveRoom,
              onGameStarting: () => _navigatedToGame = true,
              onContinueGame: () async {
                final gt = room.room?.gameType;
                if (gt == null) return;
                if (room.isOwner) {
                  _navigateOwnerToGame(gt.toDbString());
                } else {
                  _navigateFollowerToGame(gt.toDbString());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _leaveRoom() async {
    if (!mounted) return;
    final isOwner = _provider.isOwner;

    if (isOwner) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dCtx) => AlertDialog(
          title: const Text('Close Room?'),
          content: const Text('Closing the room will remove all players.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dCtx).pop(true),
              child: const Text('Close Room'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      // RoomProvider.leaveRoom() is the single authoritative owner-leave
      // action — it broadcasts 'owner_left' itself (now reliably fanned out
      // to every subscriber, including any active game screen, by
      // RealtimeService). No need to pre-broadcast here too.
      await _provider.leaveRoom(permanent: true);
      if (mounted) context.go(RouteNames.home);
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dCtx) => AlertDialog(
          title: const Text('Leave Room?'),
          content: const Text('Are you sure you want to leave this room?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dCtx).pop(true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      final myId = context.read<AuthProvider>().currentUser?.id ?? '';
      final displayName =
          context.read<AuthProvider>().currentUser?.displayName ?? 'A player';
      try {
        await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
          'type': 'player_left',
          'user_id': myId,
          'display_name': displayName,
          'for_good': true,
        });
        await sl.roomRepository.setMemberDefinitiveLeave(widget.roomId, myId);
      } catch (_) {}
      if (mounted) context.go(RouteNames.home);
    }
  }
}

class _LobbyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _LobbyAppBar({
    required this.room,
    required this.tabs,
    required this.onLeave,
  });

  final RoomProvider room;
  final TabController tabs;
  final VoidCallback onLeave;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final r = room.room;
    final l10n = context.l10n;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: onLeave,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r?.name ?? l10n.lobbyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          _ConnectionIndicator(state: room.connectionState),
        ],
      ),
      actions: [
        if (r?.inviteCode != null && room.isOwner)
          _InviteCodeChip(code: r!.inviteCode!),

        Consumer<RoomProvider>(
          builder: (_, rp, __) {
            final specs = rp.members
                .where((m) => m.isSpectator && !m.isHiddenSpectator)
                .toList();
            final hiddenCount = rp.members
                .where((m) => m.isSpectator && m.isHiddenSpectator)
                .length;
            if (specs.isEmpty && hiddenCount == 0)
              return const SizedBox.shrink();
            return TextButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => _SpectatorsSheet(
                  spectators: specs,
                  hiddenCount: rp.canModerateRoom ? hiddenCount : 0,
                  room: rp,
                ),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: Text('${specs.length}'),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            );
          },
        ),

        if (room.canApproveSpectators &&
            (room.room?.status == RoomStatus.inGame || false))
          FutureBuilder<List<Map<String, dynamic>>>(
            future: room.fetchPendingSpectatorRequests(),
            builder: (ctx, snap) {
              final requests = snap.data ?? [];
              if (requests.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip:
                    '\${requests.length} spectator request\${requests.length == 1 ? '
                    ' : "s"}',
                icon: Badge(
                  label: Text('\${requests.length}'),
                  child: const Icon(
                    Icons.person_add_outlined,
                    size: 20,
                    color: Colors.white70,
                  ),
                ),
                onPressed: () => showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  builder: (_) =>
                      _SpectatorRequestsSheet(requests: requests, room: room),
                ),
              );
            },
          ),
        const SizedBox(width: 4),
      ],
      bottom: TabBar(
        controller: tabs,
        tabs: [
          Tab(text: l10n.lobbyTitle),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Chat'),
                if (!context.watch<RoomProvider>().settings.chatEnabled)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.voice_over_off_rounded, size: 14),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.state});
  final RoomConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      RoomConnectionState.connected => ('Live', AppColors.successGreen),
      RoomConnectionState.reconnecting => (
        'Reconnecting…',
        AppColors.warningAmber,
      ),
      RoomConnectionState.recovering => ('Syncing…', AppColors.infoBlue),
      RoomConnectionState.failed => ('Disconnected', AppColors.errorRed),
      _ => ('Connecting…', AppColors.textTertiaryLight),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InviteCodeChip extends StatelessWidget {
  const _InviteCodeChip({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        context.showSnackBar(context.l10n.lobbyCopied);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: context.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.copy_rounded,
              size: 12,
              color: context.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              code,
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.state, required this.onRetry});
  final RoomConnectionState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isFailed = state == RoomConnectionState.failed;
    final color = isFailed ? AppColors.errorRed : AppColors.warningAmber;
    final message = isFailed
        ? context.l10n.gameConnectionLost
        : context.l10n.gameReconnecting;

    return Container(
      width: double.infinity,
      color: color.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (!isFailed)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
            )
          else
            Icon(Icons.wifi_off_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
          if (isFailed)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: color,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(context.l10n.gameTryAgain),
            ),
        ],
      ),
    );
  }
}

class _LobbyTab extends StatelessWidget {
  const _LobbyTab({required this.room});
  final RoomProvider room;

  @override
  Widget build(BuildContext context) {
    final canModerate = room.canModerateRoom;
    final members = canModerate
        ? room.members
        : room.members.where((m) => !m.isHiddenSpectator).toList();
    // Players count must exclude spectators (visible or hidden) — the
    // rendered list above still shows everyone, this only fixes the count.
    final playerCount = room.members.where((m) => !m.isSpectator).length;
    final theme = context.theme;

    if (members.isEmpty &&
        room.connectionState == RoomConnectionState.connecting) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(
              '$playerCount / ${room.room?.maxPlayers ?? 6} players',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (room.isOwner)
              Text(
                'You are the host',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.ownerBadge,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (room.canAcceptJoins)
          JoinRequestsPanel(
            roomId: room.room!.id,
            showAlways: room.settings.requiresApproval,
            inGame: room.room?.status == RoomStatus.inGame,
          ),

        if (room.canAcceptJoins) const SizedBox(height: 4),

        if (room.canAcceptRejoins && room.room?.status == RoomStatus.inGame)
          _RejoinRequestsPanel(roomId: room.room!.id),

        ...members.asMap().entries.map((e) {
          final member = e.value;
          final myId = context.read<AuthProvider>().currentUser?.id ?? '';
          // Transferring ownership requires Premium — the server RPC is
          // the real enforcement, this just avoids showing an option that
          // would always be rejected.
          final iAmPremiumForTransfer =
              context.read<AuthProvider>().currentUser?.isPremiumActive ??
              false;
          return Column(
            children: [
              GestureDetector(
                onTap: member.userId != myId
                    ? () => _showMemberPopup(context, member, myId)
                    : null,
                child: MemberTile(
                  member: member,
                  isCurrentUser: member.userId == myId,
                  canModerate: room.canModerate(member.userId),
                  onKick:
                      room.canKickPlayers &&
                          member.userId != myId &&
                          !member.isOwner
                      ? () => _kickConfirm(context, room, member)
                      : null,
                  onMute: room.canMuteChat && member.userId != myId
                      ? () => room.mutePlayer(
                          member.userId,
                          muted: !member.isMuted,
                        )
                      : null,
                  onBan:
                      room.isOwner && member.userId != myId && !member.isOwner
                      ? () => _banConfirm(context, room, member)
                      : null,
                  onTransferOwnership:
                      room.canTransferOwnership &&
                          iAmPremiumForTransfer &&
                          !member.isSpectator
                      ? () => _transferConfirm(context, room, member)
                      : null,
                  onManagePermissions: room.isOwner
                      ? () => _showPermissionsSheet(context, room, member)
                      : null,
                ).animate(delay: (e.key * 40).ms).fadeIn(),
              ),
            ],
          );
        }),
      ],
    );
  }

  void _showMemberPopup(
    BuildContext ctx,
    RoomMemberEntity member,
    String myId,
  ) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                child: Text(member.displayName[0].toUpperCase()),
              ),
              title: Text(
                member.displayName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(member.isSpectator ? '👁 Spectator' : '🎮 Player'),
            ),
            const Divider(),
            _FriendRequestButton(
              targetUserId: member.userId,
              displayName: member.displayName,
              myId: myId,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _kickConfirm(
    BuildContext ctx,
    RoomProvider room,
    RoomMemberEntity m,
  ) async {
    final confirmed = await showConfirmDialog(
      context: ctx,
      title: ctx.l10n.moderationKick,
      message: ctx.l10n.moderationKickConfirm(m.displayName),
      confirmLabel: ctx.l10n.moderationKick,
      isDestructive: true,
    );
    if (confirmed == true) await room.kickPlayer(m.userId);
  }

  Future<void> _banConfirm(
    BuildContext ctx,
    RoomProvider room,
    RoomMemberEntity m,
  ) async {
    await showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: room,
        child: BanConfirmSheet(targetMember: m),
      ),
    );
  }

  Future<void> _transferConfirm(
    BuildContext ctx,
    RoomProvider room,
    RoomMemberEntity m,
  ) async {
    final confirmed = await showConfirmDialog(
      context: ctx,
      title: 'Transfer ownership',
      message:
          'Transfer room ownership to ${m.displayName}? You will become a regular player.',
    );
    if (confirmed != true) return;
    try {
      await room.transferOwnership(m.userId);
    } on Failure catch (e) {
      if (ctx.mounted) ctx.showErrorSnackBar(e.message);
    }
  }

  Future<void> _showPermissionsSheet(
    BuildContext ctx,
    RoomProvider room,
    RoomMemberEntity m,
  ) async {
    var selected = Set<String>.from(m.moderatorPermissions);
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permissions for ${m.displayName}',
                style: Theme.of(
                  sheetCtx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Owners can adjust these at any time.',
                style: Theme.of(sheetCtx).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final key in ModeratorPermission.all)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(ModeratorPermission.label(key)),
                  value: selected.contains(key),
                  onChanged: (v) => setSheetState(() {
                    if (v ?? false) {
                      selected.add(key);
                    } else {
                      selected.remove(key);
                    }
                  }),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.pop(sheetCtx);
                    await room.updateModeratorPermissions(m.userId, selected);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.room,
    required this.onLeave,
    required this.onContinueGame,
    required this.onGameStarting,
    required this.wasInActiveSession,
  });
  final RoomProvider room;
  final VoidCallback onLeave;
  final VoidCallback onContinueGame;
  final VoidCallback onGameStarting;
  final bool wasInActiveSession;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isReady = room.currentMember?.isReady ?? false;
    final hasPack = room.room?.packId?.isNotEmpty == true;
    final r = room.room;
    final nonOwners = room.members.where((m) => !m.isOwner).toList();
    final activePlayers = room.members.where((m) => !m.isSpectator).toList();
    final hasEnough = activePlayers.length >= 1;
    final allReady =
        nonOwners.where((m) => !m.isSpectator).isEmpty ||
        nonOwners.where((m) => !m.isSpectator).every((m) => m.isReady);

    // Same in-memory pack cache lookup _onStartGame uses — the pack must
    // already be cached since the owner selected it moments earlier via
    // the pack list in game_settings_sheet.dart.
    final selectedPack = hasPack
        ? context.watch<PackProvider>().allPacks
              .where((p) => p.id == r?.packId)
              .firstOrNull
        : null;
    final eligibleCount = room.eligiblePlayers.length;
    final notEnoughPlayers =
        selectedPack != null && eligibleCount < selectedPack.minPlayers;
    final hasReconnecting = room.members.any(
      (m) => m.isDisconnected && !m.leftDefinitively,
    );

    String? blockedReason;
    if (notEnoughPlayers) {
      blockedReason = 'This pack requires at least '
          '${selectedPack.minPlayers} players.';
    } else if (hasReconnecting) {
      blockedReason = 'Waiting for reconnecting player(s)...';
    }

    final canStart =
        hasPack && allReady && hasEnough && !notEnoughPlayers && !hasReconnecting;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (room.isOwner || room.canStartGame) ...[
              if (!hasPack)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Select a pack in settings to start',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )
              else if (blockedReason != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    blockedReason,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              JButton(
                label: l10n.lobbyStartGame,
                onPressed: canStart
                    ? _onStartGame(context, room, onGameStarting)
                    : null,
                icon: Icons.play_arrow_rounded,
              ),
            ] else if (room.isConnected) ...[
              if (!(room.currentMember?.isSpectator ?? false))
                _ReadyButton(
                  isReady: isReady,
                  onToggle: () => room.toggleReady(),
                ),
            ] else ...[
              const SizedBox(
                height: 48,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            Row(
              children: [
                if (room.isOwner || room.canManageSettings) ...[
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.tune_rounded,
                      label: 'Settings',
                      onTap: () => _showLobbySettings(context, room),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.gavel_rounded,
                      label: 'Moderation',
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ChangeNotifierProvider.value(
                          value: room,
                          child: _ModerationSheet(roomId: r?.id ?? ''),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.person_add_rounded,
                      label: 'Invite',
                      onTap: r?.inviteCode != null
                          ? () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => _InviteFriendsSheet(
                                roomId: r!.id,
                                inviteCode: r.inviteCode!,
                              ),
                            )
                          : null,
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.exit_to_app_rounded,
                      label: 'Leave',
                      color: Theme.of(context).colorScheme.error,
                      onTap: onLeave,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _onStartGame(
    BuildContext ctx,
    RoomProvider room,
    VoidCallback onGameStarting,
  ) {
    return () async {
      final r = room.room;
      if (r == null) return;

      if (r.packId == null || r.packId!.isEmpty) {
        ctx.showErrorSnackBar('Please select a pack before starting the game.');
        return;
      }

      String gameType = r.gameType?.toDbString() ?? 'truth_or_dare';
      PackEntity? startPack;
      try {
        final packs = ctx.read<PackProvider>();
        final cached = packs.allPacks
            .where((p) => p.id == r.packId)
            .firstOrNull;
        if (cached != null) {
          gameType = cached.gameType;
          startPack = cached;
        } else {
          final fetched = await PackRepository.instance.getPackDetail(
            r.packId!,
          );
          gameType = fetched.gameType;
          startPack = fetched;
        }
      } catch (_) {}

      final displayNames = {
        for (final m in room.members) m.userId: m.displayName,
      };

      final config = GameConfig(
        maxRounds: room.settings.maxRounds,
        turnTimerSeconds: room.settings.turnTimerSeconds,
        allowSkip: room.settings.allowSkip,
        allowSpicy: r.allowSpicy,
        enablePunishments: room.settings.enablePunishments,
        punishmentSource: room.settings.punishmentSource,
        suggestedPunishments: startPack?.suggestedPunishments,
        proofVisibilityPolicy: room.settings.proofVisibilityPolicy,
        proofViewSeconds: room.settings.proofViewSeconds,
        proofReplayMode: room.settings.proofReplayMode,
        packId: r.packId,
        language: r.language,
      );

      await sl.realtimeService.broadcastGameStarted(r.id, {
        'game_type': gameType,
        'pack_id': r.packId,
        'config': config.toMap(),
        'player_ids': room.members
            .where((m) => !m.isSpectator)
            .map((m) => m.userId)
            .toList(),
        'display_names': displayNames,
      });

      await sl.roomRepository.updateStatus(
        r.id,
        RoomStatus.inGame,
        gameType: gameType,
      );

      if (ctx.mounted) {
        final packs = ctx.read<PackProvider>();
        final pack = packs.allPacks
            .where((p) => p.id == (r.packId ?? ''))
            .firstOrNull;
        final coverUrl = pack?.coverImageUrl ?? '';

        // Mark as already navigated so the realtime status-change listener
        // (which will observe this same room flip to inGame a moment after
        // updateStatus above) doesn't ALSO fire _navigateOwnerToGame and
        // push a second, duplicate game screen on top of this one.
        onGameStarting();

        AppRouter.router.push(
          '${RouteNames.home}/room/${r.id}/game',
          extra: {
            'config': config,
            'playerIds': room.members
                .where((m) => !m.isSpectator)
                .map((m) => m.userId)
                .toList(),
            'displayNames': displayNames,
            'packId': r.packId ?? '',
            'packCoverUrl': coverUrl,
            'isOwner': true,
            'isSpectator': false,
            'gameType': gameType,
            'roomProvider': room,
          },
        );
      }
    };
  }

  void _showLobbySettings(BuildContext ctx, RoomProvider room) {
    if (!room.isOwner && !room.canManageSettings) return;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // DraggableScrollableSheet instead of letting the sheet grow to its
      // full unconstrained content height (which reached almost to the top
      // of the screen) — bounded, swipe-to-dismiss, and comfortable on
      // both phones and tablets since the sizes are fractions of the
      // available height rather than fixed pixel values.
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => ChangeNotifierProvider.value(
          value: room,
          child: GameSettingsSheet(scrollController: scrollController),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Material(
      color: c.withOpacity(0.10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: onTap != null ? c : theme.disabledColor,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: onTap != null ? c : theme.disabledColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyButton extends StatelessWidget {
  const _ReadyButton({required this.isReady, required this.onToggle});
  final bool isReady;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: OutlinedButton(
        onPressed: onToggle,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: isReady
              ? AppColors.successGreen.withOpacity(0.08)
              : null,
          side: BorderSide(
            color: isReady
                ? AppColors.successGreen
                : context.colorScheme.outline,
            width: isReady ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isReady
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isReady
                  ? AppColors.successGreen
                  : context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              isReady ? context.l10n.lobbyReady : context.l10n.lobbyNotReady,
              style: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isReady
                    ? AppColors.successGreen
                    : context.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RejoinBanner extends StatefulWidget {
  const _RejoinBanner({required this.room, required this.onRejoin});

  /// An intact `room_members` row (the common "briefly backgrounded" case)
  /// rejoins instantly via [onRejoin]. A row that was actually terminated
  /// (real disconnect/leave) instead has to go through a host-approved
  /// request — see `request_game_rejoin`/`decide_game_rejoin_request`.
  final RoomProvider room;
  final VoidCallback onRejoin;

  @override
  State<_RejoinBanner> createState() => _RejoinBannerState();
}

class _RejoinBannerState extends State<_RejoinBanner> {
  String? _requestStatus;
  bool _requesting = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.room.currentMember == null) {
      _loadStatus();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _loadStatus(),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    final roomId = widget.room.room?.id;
    if (userId == null || roomId == null) return;
    try {
      final status = await sl.roomRepository.getRejoinRequestStatus(
        userId: userId,
        roomId: roomId,
      );
      if (mounted) setState(() => _requestStatus = status);
    } catch (_) {
      // Keep last known status on a transient fetch failure.
    }
  }

  Future<void> _requestRejoin() async {
    final roomId = widget.room.room?.id;
    if (roomId == null) return;
    setState(() => _requesting = true);
    try {
      await sl.roomRepository.requestGameRejoin(roomId);
      if (mounted) setState(() => _requestStatus = 'pending');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to send request: $e');
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The row reappeared (approved, or it was never actually gone) — fold
    // back into the normal one-tap instant rejoin.
    final hasIntactRow = widget.room.currentMember != null;

    final String label;
    final String buttonLabel;
    final VoidCallback? onPressed;
    if (hasIntactRow) {
      label = 'Game in progress';
      buttonLabel = 'Rejoin';
      onPressed = widget.onRejoin;
    } else if (_requestStatus == 'pending') {
      label = 'Request sent — waiting for the host';
      buttonLabel = 'Pending…';
      onPressed = null;
    } else if (_requestStatus == 'rejected') {
      label = 'Your rejoin request was declined';
      buttonLabel = 'Request Again';
      onPressed = _requesting ? null : _requestRejoin;
    } else {
      label = 'Game in progress';
      buttonLabel = 'Request to Rejoin';
      onPressed = _requesting ? null : _requestRejoin;
    }

    return Container(
      width: double.infinity,
      color: AppColors.tealGreen.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.sports_esports_rounded, color: AppColors.tealGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.tealGreen,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _RejoinRequestsPanel extends StatefulWidget {
  const _RejoinRequestsPanel({required this.roomId});
  final String roomId;
  @override
  State<_RejoinRequestsPanel> createState() => _RejoinRequestsPanelState();
}

class _RejoinRequestsPanelState extends State<_RejoinRequestsPanel> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await sl.roomRepository.getPendingRejoinRequests(
        widget.roomId,
      );
      if (mounted)
        setState(() {
          _requests = rows;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolve(String requestId, bool approve) async {
    try {
      await sl.roomRepository.decideGameRejoinRequest(
        requestId: requestId,
        approve: approve,
      );
      await _load();
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    if (_loading && _requests.isEmpty) return const SizedBox.shrink();
    if (_requests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rejoin Requests (${_requests.length})',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        ..._requests.map((req) {
          final profile = req['profiles'] as Map<String, dynamic>? ?? {};
          final name = profile['display_name'] as String? ?? 'Player';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text(name[0].toUpperCase())),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Wants to rejoin the game'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                    onPressed: () => _resolve(req['id'] as String, true),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                    onPressed: () => _resolve(req['id'] as String, false),
                    tooltip: 'Reject',
                  ),
                ],
              ),
            ),
          );
        }),
        const Divider(),
      ],
    );
  }
}

class _JoinRoleDialog extends StatelessWidget {
  const _JoinRoleDialog({
    this.isInGame = false,
    this.isPremium = false,
    this.allowAnonymous = true,
  });
  final bool isInGame;
  final bool isPremium;
  final bool allowAnonymous;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'How do you want to join?',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isInGame
                ? 'This game is already in progress.'
                : 'Choose your role in this room.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _RoleOption(
            icon: Icons.sports_esports_rounded,
            title: 'Join as Player',
            subtitle: 'Take part in the game',
            color: AppColors.successGreen,
            onTap: () => Navigator.pop(context, 'player'),
          ),
          const SizedBox(height: 10),
          _RoleOption(
            icon: Icons.visibility_rounded,
            title: 'Watch as Spectator',
            subtitle: 'Observe without playing',
            color: AppColors.infoBlue,
            onTap: () => Navigator.pop(context, 'spectator'),
          ),
          if (isPremium && allowAnonymous) ...[
            const SizedBox(height: 10),
            _RoleOption(
              icon: Icons.visibility_off_rounded,
              title: 'Watch Anonymously ✦',
              subtitle: 'Hidden from players and spectator list',
              color: const Color(0xFF7B68EE),
              onTap: () => Navigator.pop(context, 'spectator_anon'),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w700, color: color),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SpectatorRequestsSheet extends StatefulWidget {
  const _SpectatorRequestsSheet({required this.requests, required this.room});
  final List<Map<String, dynamic>> requests;
  final RoomProvider room;

  @override
  State<_SpectatorRequestsSheet> createState() =>
      _SpectatorRequestsSheetState();
}

class _SpectatorRequestsSheetState extends State<_SpectatorRequestsSheet> {
  final Set<String> _decided = {};

  Future<void> _decide(Map<String, dynamic> req, bool approve) async {
    final id = req['id'] as String;
    final userId = req['user_id'] as String;
    setState(() => _decided.add(id));
    await widget.room.decideSpectatorRequest(
      requestId: id,
      requestingUserId: userId,
      approve: approve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final pending = widget.requests
        .where((r) => !_decided.contains(r['id'] as String))
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Spectator Requests',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (pending.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Badge(label: Text('${pending.length}')),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'These players want to watch the game as spectators.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (pending.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'All requests have been decided.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...pending.map((req) {
                final userId = req['user_id'] as String;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(userId.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(
                    userId.substring(0, 8),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Wants to spectate'),
                  trailing: SizedBox(
                    width: 130,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Deny',
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.red,
                          ),
                          onPressed: () => _decide(req, false),
                        ),
                        IconButton(
                          tooltip: 'Approve',
                          icon: const Icon(
                            Icons.check_rounded,
                            color: Colors.green,
                          ),
                          onPressed: () => _decide(req, true),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ModerationSheet extends StatefulWidget {
  const _ModerationSheet({required this.roomId});
  final String roomId;
  @override
  State<_ModerationSheet> createState() => _ModerationSheetState();
}

class _ModerationSheetState extends State<_ModerationSheet> {
  List<Map<String, dynamic>> _banned = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final banned = await sl.roomRepository.getBannedMembers(widget.roomId);
      if (mounted)
        setState(() {
          _banned = banned;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final room = context.watch<RoomProvider>();
    final muted = room.members.where((m) => m.isMuted).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              '⚖️ Moderation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (muted.isEmpty && _banned.isEmpty)
                ? Center(
                    child: Text(
                      'No muted or banned players.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (muted.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '🔇 Muted',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ...muted.map(
                          (m) => ListTile(
                            leading: CircleAvatar(
                              child: Text(m.displayName[0].toUpperCase()),
                            ),
                            title: Text(m.displayName),
                            subtitle: const Text('Muted'),
                            trailing: TextButton(
                              onPressed: () =>
                                  room.mutePlayer(m.userId, muted: false),
                              child: const Text('Unmute'),
                            ),
                            dense: true,
                          ),
                        ),
                        const Divider(),
                      ],
                      if (_banned.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '🚫 Banned',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ..._banned.map((b) {
                          final name =
                              b['display_name'] as String? ??
                              b['user_id'] as String? ??
                              '?';
                          final reason = b['reason'] as String?;
                          final userId = b['user_id'] as String;
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(name[0].toUpperCase()),
                            ),
                            title: Text(name),
                            subtitle: reason != null
                                ? Text('Reason: $reason')
                                : null,
                            trailing: TextButton(
                              onPressed: () async {
                                await room.unbanPlayer(userId);
                                _load();
                              },
                              child: const Text('Unban'),
                            ),
                            dense: true,
                          );
                        }),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SpectatorsSheet extends StatelessWidget {
  const _SpectatorsSheet({
    required this.spectators,
    this.hiddenCount = 0,
    this.room,
  });
  final List<RoomMemberEntity> spectators;
  final int hiddenCount;
  final RoomProvider? room;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final canModerate = room?.canModerateRoom ?? false;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Spectators (${spectators.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (hiddenCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '+ $hiddenCount anonymous (visible to mods only)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (spectators.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No visible spectators',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ...spectators.map(
            (s) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(
                avatarUrl: s.avatarUrl,
                avatarConfig: s.avatarConfig,
                isPremium: s.isPremium,
                displayName: s.displayName,
                size: 36,
              ),
              title: Text(s.displayName),
              trailing: canModerate
                  ? IconButton(
                      icon: Icon(
                        Icons.person_remove_rounded,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: 'Kick',
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('Kick spectator?'),
                            content: Text(
                              'Remove ${s.displayName} from the room.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(dCtx, true),
                                child: const Text('Kick'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await room?.kickPlayer(
                            s.userId,
                            reason: 'spectator_removed',
                          );
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                    )
                  : Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              dense: true,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FriendRequestButton extends StatefulWidget {
  const _FriendRequestButton({
    required this.targetUserId,
    required this.displayName,
    required this.myId,
  });
  final String targetUserId, displayName, myId;
  @override
  State<_FriendRequestButton> createState() => _FriendRequestButtonState();
}

class _FriendRequestButtonState extends State<_FriendRequestButton> {
  bool _sent = false, _loading = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final friendship = await sl.friendsRepository.getFriendshipStatus(
        userId: widget.myId,
        otherId: widget.targetUserId,
      );
      if (mounted)
        setState(() {
          if (friendship == null)
            _status = 'none';
          else if (friendship.isAccepted)
            _status = 'friend';
          else
            _status = 'pending';
        });
    } catch (_) {
      if (mounted) setState(() => _status = 'none');
    }
  }

  Future<void> _send() async {
    setState(() => _loading = true);
    try {
      await sl.friendsRepository.sendFriendRequest(
        requesterId: widget.myId,
        addresseeId: widget.targetUserId,
      );
      if (mounted)
        setState(() {
          _sent = true;
          _loading = false;
          _status = 'pending';
        });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${widget.displayName} ✅'),
          ),
        );
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      final msg = e.toString().contains('Cannot interact')
          ? 'Cannot send request to ${widget.displayName}'
          : 'Could not send request — try again';
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == '') {
      return const ListTile(
        leading: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Checking…'),
        dense: true,
      );
    }
    if (_status == 'friend') {
      return ListTile(
        leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
        title: Text(
          'You and ${widget.displayName} are friends ✓',
          style: const TextStyle(fontSize: 13),
        ),
        dense: true,
      );
    }
    if (_status == 'pending' || _sent) {
      return ListTile(
        leading: const Icon(Icons.hourglass_top_rounded, color: Colors.orange),
        title: const Text('Friend request pending'),
        dense: true,
      );
    }
    return ListTile(
      leading: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.person_add_outlined),
      title: Text('Add ${widget.displayName} as friend'),
      dense: true,
      onTap: _loading ? null : _send,
    );
  }
}

class _InviteFriendsSheet extends StatefulWidget {
  const _InviteFriendsSheet({required this.roomId, required this.inviteCode});
  final String roomId, inviteCode;
  @override
  State<_InviteFriendsSheet> createState() => _InviteFriendsSheetState();
}

class _InviteFriendsSheetState extends State<_InviteFriendsSheet> {
  Set<String> _invited = {};
  bool _loadingInvited = true;
  final _searchCtrl = TextEditingController();
  String _query = '';
  final Set<String> _selected = {};
  final Set<String> _sending = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
    sl.roomRepository
        .getInvitedUserIds(widget.roomId)
        .then((ids) {
          if (!mounted) return;
          setState(() {
            _invited = ids;
            _loadingInvited = false;
          });
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() => _loadingInvited = false);
        });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _invite(FriendEntity friend) async {
    if (_invited.contains(friend.userId) || _sending.contains(friend.userId)) {
      return;
    }
    setState(() => _sending.add(friend.userId));
    try {
      await sl.roomRepository.sendInvite(
        roomId: widget.roomId,
        invitedUserId: friend.userId,
      );
      if (!mounted) return;
      setState(() {
        _invited.add(friend.userId);
        _sending.remove(friend.userId);
        _selected.remove(friend.userId);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending.remove(friend.userId));
      context.showErrorSnackBar(
        'Could not send invite to ${friend.displayName}',
      );
    }
  }

  Future<void> _inviteSelected(List<FriendEntity> friends) async {
    final targets = friends.where((f) => _selected.contains(f.userId)).toList();
    for (final f in targets) {
      await _invite(f);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final allFriends = context
        .watch<FriendsProvider>()
        .friends
        .where((f) => f.isAccepted)
        .toList();
    final friends = _query.isEmpty
        ? allFriends
        : allFriends
              .where((f) => f.displayName.toLowerCase().contains(_query))
              .toList();
    final selectableCount = friends
        .where((f) => !_invited.contains(f.userId))
        .length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  '👥 Invite Friends',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (_selected.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () => _inviteSelected(friends),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: Text('Invite ${_selected.length}'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          if (allFriends.length > 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search friends…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (_loadingInvited)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (allFriends.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No friends to invite yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else if (friends.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No friends match "$_query".',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: friends.length,
                itemBuilder: (_, i) {
                  final f = friends[i];
                  final sent = _invited.contains(f.userId);
                  final sending = _sending.contains(f.userId);
                  final selected = _selected.contains(f.userId);
                  return CheckboxListTile(
                    value: sent ? true : selected,
                    onChanged: sent || sending
                        ? null
                        : (v) => setState(() {
                            if (v ?? false) {
                              _selected.add(f.userId);
                            } else {
                              _selected.remove(f.userId);
                            }
                          }),
                    controlAffinity: ListTileControlAffinity.leading,
                    secondary: CircleAvatar(
                      child: Text(f.displayName[0].toUpperCase()),
                    ),
                    title: Text(f.displayName),
                    subtitle: sent
                        ? const Text(
                            'Invited',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : sending
                        ? const Text('Sending…')
                        : null,
                  );
                },
              ),
            ),
          if (selectableCount > 1 && !_loadingInvited)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() {
                    final allSelected = friends
                        .where((f) => !_invited.contains(f.userId))
                        .every((f) => _selected.contains(f.userId));
                    _selected.clear();
                    if (!allSelected) {
                      _selected.addAll(
                        friends
                            .where((f) => !_invited.contains(f.userId))
                            .map((f) => f.userId),
                      );
                    }
                  }),
                  child: Text(
                    _selected.length >= selectableCount
                        ? 'Deselect all'
                        : 'Select all',
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (ctx) {
                      final myId =
                          ctx.read<AuthProvider>().currentUser?.id ?? '';
                      return OutlinedButton.icon(
                        onPressed: () {
                          final myId2 =
                              context.read<AuthProvider>().currentUser?.id ??
                              '';
                          final code2 = widget.inviteCode;
                          Share.share(
                            '🎮 Join my Jma3a room!\n\nCode: $code2\n(jma3a://join?code=$code2&invited_by=$myId2)',
                            subject: '🎮 Jma3a Code: $code2',
                          );
                        },
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('Share invite link'),
                      );
                    },
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
