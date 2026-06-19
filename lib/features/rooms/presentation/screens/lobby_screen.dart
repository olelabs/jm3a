// import 'dart:async';
// import 'package:jma3a/features/rooms/domain/room_entity.dart';
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
// // import '../../../domain/room_entity.dart';
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

//     // Check if room is in-game + allows spectators → show role picker
//     _initializeWithRoleCheck();

//     _lifecycleSub = _provider.lifecycleEvents.listen(_onLifecycleEvent);

//     // Listen for room state changes to handle navigation properly
//     _provider.addListener(_onRoomStateChanged);
//   }

//   Future<void> _initializeWithRoleCheck() async {
//     try {
//       // Quick check: is room in-game and allows spectators?
//       final roomInfo = await Supabase.instance.client
//           .from('rooms')
//           .select('status')
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
//       // Owner always joins as player — no dialog needed
//       final myId = Supabase.instance.client.auth.currentUser?.id;
//       final isRoomOwner = roomInfo?['owner_id'] == myId;

//       // Check if this player was previously away (left with "I'll Return")
//       // If so, skip role dialog and rejoin directly
//       bool wasAway = false;
//       if (myId != null && !isRoomOwner) {
//         try {
//           final memberRow = await Supabase.instance.client
//               .from('room_members')
//               .select('is_away, left_definitively, role')
//               .eq('room_id', widget.roomId)
//               .eq('user_id', myId)
//               .maybeSingle();
//           wasAway = memberRow?['is_away'] as bool? ?? false;
//           if (wasAway) {
//             // Clear the away flag
//             await Supabase.instance.client
//                 .from('room_members')
//                 .update({'is_away': false})
//                 .eq('room_id', widget.roomId)
//                 .eq('user_id', myId);
//           }
//         } catch (_) {}
//       }

//       String role = 'player';
//       // Show role picker only if: spectators enabled, not the owner, not already a member, not returning
//       if (allowSpectators && !isRoomOwner && !wasAway && mounted) {
//         final picked = await showDialog<String>(
//           context: context,
//           barrierDismissible: false,
//           builder: (_) => _JoinRoleDialog(isInGame: isInGame),
//         );
//         role = picked ?? 'player';
//       }

//       if (mounted) _provider.initialize(widget.roomId, role: role);
//     } catch (_) {
//       // Fallback: join as player
//       if (mounted) _provider.initialize(widget.roomId);
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
//         // Use post-frame to avoid showing dialog during a build/layout phase
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (!mounted) {
//             // Widget already disposed — navigate directly via router
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

//     // Room closed → go home
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

//     // Track max members seen so we know when owner truly left vs not loaded yet
//     if (room.members.length > _maxMembersSeen) {
//       _maxMembersSeen = room.members.length;
//     }

//     // Owner left check — debounced 2s to avoid false triggers during init
//     // Only fires when: initialized, game NOT in progress, had multiple members, no owner now
//     final ownerGone =
//         room.isInitialized &&
//         !room.isOwner &&
//         _maxMembersSeen >= 2 && // someone else was in the room
//         room.members.isNotEmpty && // our own record is loaded
//         room.room?.status != RoomStatus.inGame && // not in game
//         !room.members.any((m) => m.isOwner);

//     if (ownerGone) {
//       _ownerLeftTimer ??= Timer(const Duration(seconds: 2), () {
//         _ownerLeftTimer = null;
//         if (!mounted) return;
//         // Re-check after delay — owner might have rejoined
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
//       // Cancel pending timer if owner came back
//       _ownerLeftTimer?.cancel();
//       _ownerLeftTimer = null;
//     }

//     if (ownerGone) return; // don't navigate to game if owner gone

//     // Reset navigation flag when game ends
//     if (room.room?.status == RoomStatus.waiting) {
//       _navigatedToGame = false;
//     }

//     // Auto-rejoin: if game is in progress and player just set ready, navigate immediately
//     if (!_navigatedToGame &&
//         room.room?.status == RoomStatus.inGame &&
//         room.isInitialized &&
//         room.room?.gameType != null) {
//       final myMember = room.currentMember;
//       final hasAdminOrMod = room.members.any((m) => m.isOwner || m.isModerator);
//       // Rejoin if: current player just became ready, and room has admin/mod
//       if (myMember?.isReady == true && hasAdminOrMod) {
//         _navigatedToGame = true;
//         final gameType = room.room!.gameType!.toDbString();
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (!mounted) return;
//           _navigateFollowerToGame(gameType);
//         });
//         return;
//       }
//     }

//     // First-time follower navigation when game starts
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
//     }

//     // Owner rejoin: if game in progress and owner returns to lobby
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

//   /// Owner navigates directly into game without broadcasting (game already running)
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
//         'playerIds': _provider.members.map((m) => m.userId).toList(),
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

//     // Look up pack cover in PackProvider via context
//     // (We're in LobbyScreen which has PackProvider in its tree)
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
//       'playerIds': _provider.members.map((m) => m.userId).toList(),
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
//         appBar: AppBar(),
//         body: ErrorView(
//           message: errorMsg,
//           onRetry: () => _provider.initialize(widget.roomId),
//         ),
//       );
//     }

//     return PopScope(
//       canPop:
//           false, // Prevent swipe-back / Android back button without confirmation
//       onPopInvoked: (didPop) async {
//         if (didPop) return;
//         final confirm = await showConfirmDialog(
//           context: ctx,
//           title: ctx.l10n.lobbyLeave,
//           message: ctx.l10n.lobbyLeaveConfirm,
//           confirmLabel: ctx.l10n.lobbyLeave,
//           isDestructive: true,
//         );
//         if (confirm == true && ctx.mounted) {
//           await _leaveRoom();
//         }
//       },
//       child: Scaffold(
//         appBar: _LobbyAppBar(room: room, tabs: _tabs, onLeave: _leaveRoom),
//         body: Column(
//           children: [
//             if (room.connectionState != RoomConnectionState.connected &&
//                 room.connectionState != RoomConnectionState.connecting)
//               _ConnectionBanner(
//                 state: room.connectionState,
//                 onRetry: room.retryConnection,
//               ),
//             // Rejoin banner — visible if game is in progress and player came back
//             if (room.room?.status == RoomStatus.inGame &&
//                 room.room?.gameType != null)
//               _RejoinBanner(
//                 onRejoin: () {
//                   _navigatedToGame = false;
//                   final r = room.room!;
//                   final gameType = r.gameType!.toDbString();
//                   final displayNames = {
//                     for (final m in room.members) m.userId: m.displayName,
//                   };
//                   final config = GameConfig(
//                     maxRounds: room.settings.maxRounds,
//                     turnTimerSeconds: room.settings.turnTimerSeconds,
//                     allowSkip: room.settings.allowSkip,
//                     allowSpicy: r.allowSpicy,
//                     enablePunishments: true,
//                     packId: r.packId,
//                   );
//                   AppRouter.router.push(
//                     '${RouteNames.home}/room/${r.id}/game',
//                     extra: {
//                       'config': config,
//                       'playerIds': room.members.map((m) => m.userId).toList(),
//                       'displayNames': displayNames,
//                       'packId': r.packId ?? '',
//                       'isOwner': room.isOwner,
//                       'isModerator': room.currentMember?.isModerator ?? false,
//                       'gameType': gameType,
//                     },
//                   );
//                 },
//               ),
//             Expanded(
//               child: TabBarView(
//                 controller: _tabs,
//                 physics: const NeverScrollableScrollPhysics(),
//                 children: [
//                   _LobbyTab(room: room),
//                   ChatPanel(room: room),
//                 ],
//               ),
//             ),
//             _BottomActionBar(room: room, onLeave: _leaveRoom),
//           ],
//         ),
//       ),
//     ); // closes PopScope
//   }

//   Future<void> _leaveRoom() async {
//     if (!mounted) return;
//     final isOwner = _provider.isOwner;
//     final status = _provider.room?.status;
//     final isInGame = status == RoomStatus.inGame || status == RoomStatus.paused;

//     if (isOwner) {
//       // Owner leaving — always allowed from lobby regardless of game state.
//       // If a game was in progress or paused, end it for everyone.
//       String title = 'Close Room?';
//       String message =
//           'This will permanently close the room and remove all players.';
//       if (isInGame) {
//         title = 'End Game & Close Room?';
//         message =
//             'The game is currently in progress. Closing the room will end the game for everyone.';
//       }

//       final confirmed = await showConfirmDialog(
//         context: context,
//         title: title,
//         message: message,
//         confirmLabel: 'Close Room',
//         isDestructive: true,
//       );
//       if (confirmed != true || !mounted) return;

//       // Broadcast so all players/watchers get the forced-quit dialog
//       try {
//         if (isInGame) {
//           await sl.realtimeService.broadcastGameEnded(widget.roomId, {
//             'reason': 'host_closed_room',
//           });
//         }
//         await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
//           'type': 'owner_left',
//           'reason': 'host_left',
//         });
//         await Future.delayed(const Duration(milliseconds: 500));
//       } catch (_) {}

//       await _provider.leaveRoom();
//       if (mounted) context.go(RouteNames.home);
//     } else {
//       // Non-owner leaving from lobby
//       final choice = await showDialog<String>(
//         context: context,
//         builder: (dCtx) => AlertDialog(
//           title: const Text('Leave Room?'),
//           content: const Text('Will you be coming back?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(dCtx, 'cancel'),
//               child: const Text('Stay'),
//             ),
//             FilledButton.tonal(
//               onPressed: () => Navigator.pop(dCtx, 'return'),
//               child: const Text("I'll Return"),
//             ),
//             FilledButton(
//               style: FilledButton.styleFrom(backgroundColor: Colors.red),
//               onPressed: () => Navigator.pop(dCtx, 'leave'),
//               child: const Text('Leave for Good'),
//             ),
//           ],
//         ),
//       );
//       if (choice == null || choice == 'cancel' || !mounted) return;
//       if (choice == 'return') {
//         // Navigate away but keep seat — rejoin will restore them
//         context.go(RouteNames.home);
//       } else {
//         // Permanently leave
//         await _provider.leaveRoom();
//         if (mounted) context.go(RouteNames.home);
//       }
//     }
//   }
// }

// // ── App bar ────────────────────────────────────────────────────────────────────
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
//         // Invite code chip — compact, always visible to owner
//         if (r?.inviteCode != null && room.isOwner)
//           _InviteCodeChip(code: r!.inviteCode!),

//         // Spectator count chip
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

//         // Pause/Resume — owner only, game in progress
//         if (room.isOwner && r?.status == RoomStatus.inGame)
//           IconButton(
//             icon: Icon(
//               r?.status == RoomStatus.paused
//                   ? Icons.play_arrow_rounded
//                   : Icons.pause_rounded,
//               size: 20,
//             ),
//             tooltip: r?.status == RoomStatus.paused ? 'Resume' : 'Pause',
//             onPressed: () async {
//               if (r?.status == RoomStatus.paused)
//                 await room.resumeGame();
//               else
//                 await room.pauseGame();
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

// // ── Connection banner ─────────────────────────────────────────────────────────
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

// // ── Lobby tab (member list) ────────────────────────────────────────────────────
// class _LobbyTab extends StatelessWidget {
//   const _LobbyTab({required this.room});
//   final RoomProvider room;

//   @override
//   Widget build(BuildContext context) {
//     final members = room.members;
//     final theme = context.theme;

//     // Show spinner only while still connecting — once connected, render
//     // whatever members we have (may just be the current user)
//     if (members.isEmpty &&
//         room.connectionState == RoomConnectionState.connecting) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         // Header: player count + room name
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

//         // Join requests panel (owner/mod only)
//         // Show regardless of requiresApproval flag — panel hides itself if no requests
//         if (room.isOwner || room.currentMember?.isModerator == true)
//           _JoinRequestsPanel(
//             roomId: room.room!.id,
//             showAlways: room.settings.requiresApproval,
//           ),

//         if (room.isOwner || room.currentMember?.isModerator == true)
//           const SizedBox(height: 4),

//         // Member list
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

//   /// Shows a small popup for a member with Add Friend / View Profile options
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

// // ── Bottom action bar ─────────────────────────────────────────────────────────
// class _BottomActionBar extends StatelessWidget {
//   const _BottomActionBar({required this.room, required this.onLeave});
//   final RoomProvider room;
//   final VoidCallback onLeave;

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n;
//     final isReady = room.currentMember?.isReady ?? false;
//     final hasPack = room.room?.packId?.isNotEmpty == true;
//     final r = room.room;
//     final nonOwners = room.members.where((m) => !m.isOwner).toList();
//     final activePlayers = room.members.where((m) => !m.isSpectator).toList();
//     final hasEnough = activePlayers.length >= 2;
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
//             // ── Primary action ──────────────────────────────────────────────
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
//             ] else
//               _ReadyButton(
//                 isReady: isReady,
//                 onToggle: () => room.setReady(!isReady),
//               ),

//             const SizedBox(height: 8),

//             // ── Three bottom action buttons ─────────────────────────────────
//             Row(
//               children: [
//                 // Settings
//                 if (room.isOwner) ...[
//                   Expanded(
//                     child: _ActionBtn(
//                       icon: Icons.tune_rounded,
//                       label: 'Settings',
//                       onTap: () => _showLobbySettings(context, room),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   // Moderation
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
//                   // Invite
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
//                   // Non-owner: just a leave button
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

//       // Determine game type from the selected pack — fetch directly to avoid cache miss
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
//         'player_ids': room.members.map((m) => m.userId).toList(),
//         'display_names': displayNames,
//       });

//       await sl.roomRepository.updateStatus(r.id, RoomStatus.inGame);

//       if (ctx.mounted) {
//         // Look up pack cover URL for the card background
//         final packs = ctx.read<PackProvider>();
//         final pack = packs.allPacks
//             .where((p) => p.id == (r.packId ?? ''))
//             .firstOrNull;
//         final coverUrl = pack?.coverImageUrl ?? '';

//         AppRouter.router.push(
//           '${RouteNames.home}/room/${r.id}/game',
//           extra: {
//             'config': config,
//             'playerIds': room.members.map((m) => m.userId).toList(),
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

// // ── Join requests panel ───────────────────────────────────────────────────────
// class _JoinRequestsPanel extends StatefulWidget {
//   const _JoinRequestsPanel({required this.roomId, this.showAlways = false});
//   final String roomId;
//   final bool showAlways; // if false, hides when no requests
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
//     // Auto-refresh every 5 seconds so admin sees new requests without manual reload
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
//     // When showAlways is false, hide if no requests (don't clutter UI)
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

// // ── Join role dialog ──────────────────────────────────────────────────────────
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

// // ── Spectators sheet ──────────────────────────────────────────────────────────

// // ── Moderation sheet: muted & banned players ─────────────────────────────────
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
//           // Handle
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
//                                 _load(); // refresh list
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

// // ── Friend request button for lobby / game ────────────────────────────────────
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
//   String _status = ''; // 'friend', 'pending', 'none'

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
//     // Checking
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
//     // Already friends — no button
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
//     // Request already sent or pending
//     if (_status == 'pending' || _sent) {
//       return ListTile(
//         leading: const Icon(Icons.hourglass_top_rounded, color: Colors.orange),
//         title: const Text('Friend request pending'),
//         dense: true,
//       );
//     }
//     // Can send request
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

// // ── Invite friends sheet ──────────────────────────────────────────────────────
// class _InviteFriendsSheet extends StatefulWidget {
//   const _InviteFriendsSheet({required this.roomId, required this.inviteCode});
//   final String roomId, inviteCode;
//   @override
//   State<_InviteFriendsSheet> createState() => _InviteFriendsSheetState();
// }

// class _InviteFriendsSheetState extends State<_InviteFriendsSheet> {
//   final Set<String> _invited = {};

//   Future<void> _invite(FriendEntity friend) async {
//     final myId = context.read<AuthProvider>().currentUser?.id ?? '';
//     final code = widget.inviteCode;
//     final msg =
//         '🎮 Join my Jma3a room!\n\n'
//         'Enter this code in the app:\n'
//         '👉 $code\n\n'
//         '(Or tap if app is installed: jma3a://join?code=$code&invited_by=$myId)';
//     await Share.share(msg, subject: '🎮 Jma3a Room Code: $code');
//     if (!mounted) return;
//     setState(() => _invited.add(friend.userId));
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
//                     trailing: sent
//                         ? const Icon(Icons.check, color: Colors.green)
//                         : FilledButton.tonal(
//                             onPressed: () => _invite(f),
//                             child: const Text('Invite'),
//                           ),
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
import '../../data/room_repository.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../friends/data/friends_repository.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/widgets/buttons/j_button.dart';
import '../../../friends/presentation/friends_provider.dart';
import '../../../../shared/widgets/feedback/error_view.dart';
import '../../../../shared/widgets/overlays/confirm_dialog.dart';
import '../../../packs/data/pack_repository.dart';
import '../../../packs/presentation/pack_provider.dart';
import '../room_provider.dart';
// import '../../../domain/room_entity.dart';
import '../../../../features/games/engine/base_game_engine.dart';
import '../widgets/chat_panel.dart';
import '../widgets/game_settings_sheet.dart';
import '../widgets/member_tile.dart';
import '../widgets/moderation_sheet.dart';

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

    // Check if room is in-game + allows spectators → show role picker
    _initializeWithRoleCheck();

    _lifecycleSub = _provider.lifecycleEvents.listen(_onLifecycleEvent);

    // Listen for room state changes to handle navigation properly
    _provider.addListener(_onRoomStateChanged);
  }

  Future<void> _initializeWithRoleCheck() async {
    try {
      // Quick check: is room in-game and allows spectators?
      final roomInfo = await Supabase.instance.client
          .from('rooms')
          .select('status')
          .eq('id', widget.roomId)
          .maybeSingle();
      final settingsInfo = await Supabase.instance.client
          .from('room_settings')
          .select('allow_spectators')
          .eq('room_id', widget.roomId)
          .maybeSingle();

      final isInGame = roomInfo?['status'] == 'in_game';
      final allowSpectators =
          settingsInfo?['allow_spectators'] as bool? ?? false;
      // Owner always joins as player — no dialog needed
      final myId = Supabase.instance.client.auth.currentUser?.id;
      final isRoomOwner = roomInfo?['owner_id'] == myId;

      // Check if this player was previously away (left with "I'll Return")
      // If so, skip role dialog and rejoin directly
      bool wasAway = false;
      if (myId != null && !isRoomOwner) {
        try {
          final memberRow = await Supabase.instance.client
              .from('room_members')
              .select('is_away, left_definitively, role')
              .eq('room_id', widget.roomId)
              .eq('user_id', myId)
              .maybeSingle();
          wasAway = memberRow?['is_away'] as bool? ?? false;
          if (wasAway) {
            // Clear the away flag
            await Supabase.instance.client
                .from('room_members')
                .update({'is_away': false})
                .eq('room_id', widget.roomId)
                .eq('user_id', myId);
          }
        } catch (_) {}
      }

      String role = 'player';
      // Show role picker only if: spectators enabled, not the owner, not already a member, not returning
      if (allowSpectators && !isRoomOwner && !wasAway && mounted) {
        final picked = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _JoinRoleDialog(isInGame: isInGame),
        );
        role = picked ?? 'player';
      }

      if (mounted) {
        // For returning players (wasAway), we still initialize normally
        // The upsert in joinRoom will restore their seat.
        // wasAway is stored so _onRoomStateChanged routes them to game directly.
        _isReturningPlayer = wasAway;
        _provider.initialize(widget.roomId, role: role);
      }
    } catch (_) {
      if (mounted) _provider.initialize(widget.roomId);
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
        _showEventBanner(
          'You were removed from the room by the host',
          isError: true,
        );
        context.go(RouteNames.home);
      case RoomLifecycleEvent.banned:
        _showEventBanner('You were banned from this room', isError: true);
        context.go(RouteNames.home);
      case RoomLifecycleEvent.roomClosed:
        // Use post-frame to avoid showing dialog during a build/layout phase
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            // Widget already disposed — navigate directly via router
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
    }
  }

  void _showEventBanner(String message, {bool isError = false}) {
    if (!mounted) return;
    context.showSnackBar(message, isError: isError);
  }

  bool _navigatedToGame = false;
  bool _isReturningPlayer = false;
  Timer? _ownerLeftTimer;
  int _maxMembersSeen = 0;

  void _onRoomStateChanged() {
    if (!mounted) return;
    final room = _provider;

    // Room closed → go home
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

    // Track max members seen so we know when owner truly left vs not loaded yet
    if (room.members.length > _maxMembersSeen) {
      _maxMembersSeen = room.members.length;
    }

    // Owner left check — debounced 2s to avoid false triggers during init
    // Only fires when: initialized, game NOT in progress, had multiple members, no owner now
    final ownerGone =
        room.isInitialized &&
        !room.isOwner &&
        _maxMembersSeen >= 2 && // someone else was in the room
        room.members.isNotEmpty && // our own record is loaded
        room.room?.status != RoomStatus.inGame && // not in game
        !room.members.any((m) => m.isOwner);

    if (ownerGone) {
      _ownerLeftTimer ??= Timer(const Duration(seconds: 2), () {
        _ownerLeftTimer = null;
        if (!mounted) return;
        // Re-check after delay — owner might have rejoined
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
      // Cancel pending timer if owner came back
      _ownerLeftTimer?.cancel();
      _ownerLeftTimer = null;
    }

    if (ownerGone) return; // don't navigate to game if owner gone

    // Reset navigation flag when game ends
    if (room.room?.status == RoomStatus.waiting) {
      _navigatedToGame = false;
    }

    // Auto-rejoin: if game is in progress and player just set ready, navigate immediately
    if (!_navigatedToGame &&
        room.room?.status == RoomStatus.inGame &&
        room.isInitialized &&
        room.room?.gameType != null) {
      final myMember = room.currentMember;
      final hasAdminOrMod = room.members.any((m) => m.isOwner || m.isModerator);
      // Rejoin if: current player just became ready, and room has admin/mod
      if (myMember?.isReady == true && hasAdminOrMod) {
        _navigatedToGame = true;
        final gameType = room.room!.gameType!.toDbString();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _navigateFollowerToGame(gameType);
        });
        return;
      }
    }

    // First-time follower navigation when game starts
    // Also handles returning players (_isReturningPlayer == true)
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

    // Returning player: paused game — navigate when owner resumes
    if (_isReturningPlayer &&
        !_navigatedToGame &&
        room.room?.status == RoomStatus.paused &&
        room.isInitialized) {
      // Show "game is paused, waiting for host" message
      // They'll navigate when owner resumes and status → inGame
    }

    // Owner rejoin: if game in progress and owner returns to lobby
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

  /// Owner navigates directly into game without broadcasting (game already running)
  void _navigateOwnerToGame(String gameType) {
    if (!mounted) return;
    final r = _provider.room;
    if (r == null) return;
    final displayNames = {
      for (final m in _provider.members) m.userId: m.displayName,
    };
    final packs = context.read<PackProvider>();
    final pack = packs.allPacks
        .where((p) => p.id == (r.packId ?? ''))
        .firstOrNull;
    AppRouter.router.push(
      '${RouteNames.home}/room/${r.id}/game',
      extra: {
        'config': GameConfig(
          maxRounds: _provider.settings.maxRounds,
          turnTimerSeconds: _provider.settings.turnTimerSeconds,
          allowSkip: _provider.settings.allowSkip,
          allowSpicy: r.allowSpicy,
          enablePunishments: true,
          packId: r.packId,
          language: r.language,
        ),
        'playerIds': _provider.members.map((m) => m.userId).toList(),
        'displayNames': displayNames,
        'packId': r.packId ?? '',
        'packCoverUrl': pack?.coverImageUrl ?? '',
        'isOwner': true,
        'gameType': gameType,
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

    // Look up pack cover in PackProvider via context
    // (We're in LobbyScreen which has PackProvider in its tree)
    String followerCoverUrl = '';
    try {
      final packProv = context.read<PackProvider>();
      final pack = packProv.allPacks
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
        enablePunishments: true,
        packId: r.packId,
        language: r.language,
      ),
      'playerIds': _provider.members.map((m) => m.userId).toList(),
      'displayNames': displayNames,
      'packId': r.packId ?? '',
      'packCoverUrl': followerCoverUrl,
      'isOwner': false,
      'isModerator': _provider.currentMember?.isModerator ?? false,
      'gameType': gameType,
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

    return PopScope(
      canPop:
          false, // Prevent swipe-back / Android back button without confirmation
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final confirm = await showConfirmDialog(
          context: ctx,
          title: ctx.l10n.lobbyLeave,
          message: ctx.l10n.lobbyLeaveConfirm,
          confirmLabel: ctx.l10n.lobbyLeave,
          isDestructive: true,
        );
        if (confirm == true && ctx.mounted) {
          await _leaveRoom();
        }
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
            // Rejoin banner — visible if game is in progress and player came back
            if (room.room?.status == RoomStatus.inGame &&
                room.room?.gameType != null)
              _RejoinBanner(
                onRejoin: () {
                  _navigatedToGame = false;
                  final r = room.room!;
                  final gameType = r.gameType!.toDbString();
                  final displayNames = {
                    for (final m in room.members) m.userId: m.displayName,
                  };
                  final config = GameConfig(
                    maxRounds: room.settings.maxRounds,
                    turnTimerSeconds: room.settings.turnTimerSeconds,
                    allowSkip: room.settings.allowSkip,
                    allowSpicy: r.allowSpicy,
                    enablePunishments: true,
                    packId: r.packId,
                  );
                  AppRouter.router.push(
                    '${RouteNames.home}/room/${r.id}/game',
                    extra: {
                      'config': config,
                      'playerIds': room.members.map((m) => m.userId).toList(),
                      'displayNames': displayNames,
                      'packId': r.packId ?? '',
                      'isOwner': room.isOwner,
                      'isModerator': room.currentMember?.isModerator ?? false,
                      'gameType': gameType,
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
            _BottomActionBar(room: room, onLeave: _leaveRoom),
          ],
        ),
      ),
    ); // closes PopScope
  }

  Future<void> _leaveRoom() async {
    if (!mounted) return;
    final isOwner = _provider.isOwner;
    final status = _provider.room?.status;
    final isInGame = status == RoomStatus.inGame || status == RoomStatus.paused;

    if (isOwner) {
      // Owner leaving — always allowed from lobby regardless of game state.
      // If a game was in progress or paused, end it for everyone.
      String title = 'Close Room?';
      String message =
          'This will permanently close the room and remove all players.';
      if (isInGame) {
        title = 'End Game & Close Room?';
        message =
            'The game is currently in progress. Closing the room will end the game for everyone.';
      }

      final confirmed = await showConfirmDialog(
        context: context,
        title: title,
        message: message,
        confirmLabel: 'Close Room',
        isDestructive: true,
      );
      if (confirmed != true || !mounted) return;

      // Broadcast so all players/watchers get the forced-quit dialog
      try {
        if (isInGame) {
          await sl.realtimeService.broadcastGameEnded(widget.roomId, {
            'reason': 'host_closed_room',
          });
        }
        await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
          'type': 'owner_left',
          'reason': 'host_left',
        });
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (_) {}

      await _provider.leaveRoom();
      if (mounted) context.go(RouteNames.home);
    } else {
      // Non-owner leaving from lobby
      final choice = await showDialog<String>(
        context: context,
        builder: (dCtx) => AlertDialog(
          title: const Text('Leave Room?'),
          content: const Text('Will you be coming back?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, 'cancel'),
              child: const Text('Stay'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(dCtx, 'return'),
              child: const Text("I'll Return"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dCtx, 'leave'),
              child: const Text('Leave for Good'),
            ),
          ],
        ),
      );
      if (choice == null || choice == 'cancel' || !mounted) return;
      if (choice == 'return') {
        // Navigate away but keep seat — rejoin will restore them
        context.go(RouteNames.home);
      } else {
        // Permanently leave
        await _provider.leaveRoom();
        if (mounted) context.go(RouteNames.home);
      }
    }
  }
}

// ── App bar ────────────────────────────────────────────────────────────────────
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
        // Invite code chip — compact, always visible to owner
        if (r?.inviteCode != null && room.isOwner)
          _InviteCodeChip(code: r!.inviteCode!),

        // Spectator count chip
        Consumer<RoomProvider>(
          builder: (_, rp, __) {
            final specs = rp.members.where((m) => m.isSpectator).toList();
            if (specs.isEmpty) return const SizedBox.shrink();
            return TextButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => _SpectatorsSheet(spectators: specs),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: Text('\${specs.length}'),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            );
          },
        ),

        // Pause/Resume — owner only, game in progress
        if (room.isOwner && r?.status == RoomStatus.inGame)
          IconButton(
            icon: Icon(
              r?.status == RoomStatus.paused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              size: 20,
            ),
            tooltip: r?.status == RoomStatus.paused ? 'Resume' : 'Pause',
            onPressed: () async {
              if (r?.status == RoomStatus.paused)
                await room.resumeGame();
              else
                await room.pauseGame();
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

// ── Connection banner ─────────────────────────────────────────────────────────
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

// ── Lobby tab (member list) ────────────────────────────────────────────────────
class _LobbyTab extends StatelessWidget {
  const _LobbyTab({required this.room});
  final RoomProvider room;

  @override
  Widget build(BuildContext context) {
    final members = room.members;
    final theme = context.theme;

    // Show spinner only while still connecting — once connected, render
    // whatever members we have (may just be the current user)
    if (members.isEmpty &&
        room.connectionState == RoomConnectionState.connecting) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header: player count + room name
        Row(
          children: [
            Text(
              '${members.length} / ${room.room?.maxPlayers ?? 6} players',
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

        // Join requests panel (owner/mod only)
        // Show regardless of requiresApproval flag — panel hides itself if no requests
        if (room.isOwner || room.currentMember?.isModerator == true)
          _JoinRequestsPanel(
            roomId: room.room!.id,
            showAlways: room.settings.requiresApproval,
          ),

        if (room.isOwner || room.currentMember?.isModerator == true)
          const SizedBox(height: 4),

        // Member list
        ...members.asMap().entries.map((e) {
          final member = e.value;
          final myId = context.read<AuthProvider>().currentUser?.id ?? '';
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
                  onKick: () => _kickConfirm(context, room, member),
                  onMute: () =>
                      room.mutePlayer(member.userId, muted: !member.isMuted),
                  onBan: () => _banConfirm(context, room, member),
                  onTransferOwnership: room.isOwner
                      ? () => _transferConfirm(context, room, member)
                      : null,
                  onToggleModerator: room.isOwner
                      ? () => member.isModerator
                            ? room.revokeModerator(member.userId)
                            : room.grantModerator(member.userId)
                      : null,
                ).animate(delay: (e.key * 40).ms).fadeIn(),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Shows a small popup for a member with Add Friend / View Profile options
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
    if (confirmed == true) await room.transferOwnership(m.userId);
  }
}

// ── Bottom action bar ─────────────────────────────────────────────────────────
class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.room, required this.onLeave});
  final RoomProvider room;
  final VoidCallback onLeave;

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
    final canStart = hasPack && allReady && hasEnough;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Primary action ──────────────────────────────────────────────
            if (room.isOwner) ...[
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
                ),
              JButton(
                label: l10n.lobbyStartGame,
                onPressed: canStart ? _onStartGame(context, room) : null,
                icon: Icons.play_arrow_rounded,
              ),
            ] else
              _ReadyButton(
                isReady: isReady,
                onToggle: () => room.setReady(!isReady),
              ),

            const SizedBox(height: 8),

            // ── Three bottom action buttons ─────────────────────────────────
            Row(
              children: [
                // Settings
                if (room.isOwner) ...[
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.tune_rounded,
                      label: 'Settings',
                      onTap: () => _showLobbySettings(context, room),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Moderation
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
                  // Invite
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
                  // Non-owner: just a leave button
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

  VoidCallback? _onStartGame(BuildContext ctx, RoomProvider room) {
    return () async {
      final r = room.room;
      if (r == null) return;

      if (r.packId == null || r.packId!.isEmpty) {
        ctx.showErrorSnackBar('Please select a pack before starting the game.');
        return;
      }

      // Determine game type from the selected pack — fetch directly to avoid cache miss
      String gameType = r.gameType?.toDbString() ?? 'truth_or_dare';
      try {
        final packs = ctx.read<PackProvider>();
        final cached = packs.allPacks
            .where((p) => p.id == r.packId)
            .firstOrNull;
        if (cached != null) {
          gameType = cached.gameType;
        } else {
          final fetched = await PackRepository.instance.getPackDetail(
            r.packId!,
          );
          gameType = fetched.gameType;
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
        enablePunishments: true,
        packId: r.packId,
        language: r.language,
      );

      await sl.realtimeService.broadcastGameStarted(r.id, {
        'game_type': gameType,
        'pack_id': r.packId,
        'config': config.toMap(),
        'player_ids': room.members.map((m) => m.userId).toList(),
        'display_names': displayNames,
      });

      await sl.roomRepository.updateStatus(r.id, RoomStatus.inGame);

      if (ctx.mounted) {
        // Look up pack cover URL for the card background
        final packs = ctx.read<PackProvider>();
        final pack = packs.allPacks
            .where((p) => p.id == (r.packId ?? ''))
            .firstOrNull;
        final coverUrl = pack?.coverImageUrl ?? '';

        AppRouter.router.push(
          '${RouteNames.home}/room/${r.id}/game',
          extra: {
            'config': config,
            'playerIds': room.members.map((m) => m.userId).toList(),
            'displayNames': displayNames,
            'packId': r.packId ?? '',
            'packCoverUrl': coverUrl,
            'isOwner': true,
            'gameType': gameType,
          },
        );
      }
    };
  }

  void _showLobbySettings(BuildContext ctx, RoomProvider room) {
    if (!room.isOwner) return;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: room,
        child: const GameSettingsSheet(),
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

class _RejoinBanner extends StatelessWidget {
  const _RejoinBanner({required this.onRejoin});
  final VoidCallback onRejoin;

  @override
  Widget build(BuildContext context) {
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
              'Game in progress',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: onRejoin,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.tealGreen,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Rejoin'),
          ),
        ],
      ),
    );
  }
}

// ── Join requests panel ───────────────────────────────────────────────────────
class _JoinRequestsPanel extends StatefulWidget {
  const _JoinRequestsPanel({required this.roomId, this.showAlways = false});
  final String roomId;
  final bool showAlways; // if false, hides when no requests
  @override
  State<_JoinRequestsPanel> createState() => _JoinRequestsPanelState();
}

class _JoinRequestsPanelState extends State<_JoinRequestsPanel> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // Auto-refresh every 5 seconds so admin sees new requests without manual reload
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await sl.roomRepository.getPendingRequests(widget.roomId);
      if (mounted)
        setState(() {
          _requests = rows;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolve(String requestId, String userId, bool approve) async {
    try {
      await sl.roomRepository.resolveJoinRequest(
        requestId: requestId,
        approve: approve,
        roomId: widget.roomId,
        targetUserId: userId,
      );
      await _load();
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    if (_loading && _requests.isEmpty) return const LinearProgressIndicator();
    // When showAlways is false, hide if no requests (don't clutter UI)
    if (_requests.isEmpty && !widget.showAlways) return const SizedBox.shrink();
    if (_requests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 14,
              color: Colors.green,
            ),
            const SizedBox(width: 6),
            Text(
              'No pending join requests',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Join Requests (${_requests.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _load,
            ),
          ],
        ),
        ..._requests.map((req) {
          final profile = req['profiles'] as Map<String, dynamic>? ?? {};
          final name = profile['display_name'] as String? ?? 'Player';
          final msg = req['message'] as String?;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text(name[0].toUpperCase())),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: msg != null && msg.isNotEmpty ? Text(msg) : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                    onPressed: () => _resolve(
                      req['id'] as String,
                      req['user_id'] as String,
                      true,
                    ),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                    onPressed: () => _resolve(
                      req['id'] as String,
                      req['user_id'] as String,
                      false,
                    ),
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

// ── Join role dialog ──────────────────────────────────────────────────────────
class _JoinRoleDialog extends StatelessWidget {
  const _JoinRoleDialog({this.isInGame = false});
  final bool isInGame;

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

// ── Spectators sheet ──────────────────────────────────────────────────────────

// ── Moderation sheet: muted & banned players ─────────────────────────────────
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
          // Handle
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
                                _load(); // refresh list
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
  const _SpectatorsSheet({required this.spectators});
  final List<RoomMemberEntity> spectators;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
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
          const SizedBox(height: 12),
          ...spectators.map(
            (s) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: s.avatarUrl != null
                    ? NetworkImage(s.avatarUrl!)
                    : null,
                child: s.avatarUrl == null
                    ? Text(s.displayName[0].toUpperCase())
                    : null,
              ),
              title: Text(s.displayName),
              trailing: Icon(
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

// ── Friend request button for lobby / game ────────────────────────────────────
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
  String _status = ''; // 'friend', 'pending', 'none'

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
    // Checking
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
    // Already friends — no button
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
    // Request already sent or pending
    if (_status == 'pending' || _sent) {
      return ListTile(
        leading: const Icon(Icons.hourglass_top_rounded, color: Colors.orange),
        title: const Text('Friend request pending'),
        dense: true,
      );
    }
    // Can send request
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

// ── Invite friends sheet ──────────────────────────────────────────────────────
class _InviteFriendsSheet extends StatefulWidget {
  const _InviteFriendsSheet({required this.roomId, required this.inviteCode});
  final String roomId, inviteCode;
  @override
  State<_InviteFriendsSheet> createState() => _InviteFriendsSheetState();
}

class _InviteFriendsSheetState extends State<_InviteFriendsSheet> {
  final Set<String> _invited = {};

  Future<void> _invite(FriendEntity friend) async {
    final myId = context.read<AuthProvider>().currentUser?.id ?? '';
    final code = widget.inviteCode;
    final msg =
        '🎮 Join my Jma3a room!\n\n'
        'Enter this code in the app:\n'
        '👉 $code\n\n'
        '(Or tap if app is installed: jma3a://join?code=$code&invited_by=$myId)';
    await Share.share(msg, subject: '🎮 Jma3a Room Code: $code');
    if (!mounted) return;
    setState(() => _invited.add(friend.userId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final friends = context
        .watch<FriendsProvider>()
        .friends
        .where((f) => f.isAccepted)
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.65,
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
              '👥 Invite Friends',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (friends.isEmpty)
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
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: friends.length,
                itemBuilder: (_, i) {
                  final f = friends[i];
                  final sent = _invited.contains(f.userId);
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(f.displayName[0].toUpperCase()),
                    ),
                    title: Text(f.displayName),
                    trailing: sent
                        ? const Icon(Icons.check, color: Colors.green)
                        : FilledButton.tonal(
                            onPressed: () => _invite(f),
                            child: const Text('Invite'),
                          ),
                  );
                },
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
                            '🎮 Join my Jma3a room!\n\nCode: \$code2\n(jma3a://join?code=\$code2&invited_by=\$myId2)',
                            subject: '🎮 Jma3a Code: \$code2',
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
