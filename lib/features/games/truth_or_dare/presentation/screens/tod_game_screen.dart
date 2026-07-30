// // // // // // import 'dart:async';

// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // import 'package:go_router/go_router.dart';
// // // // // // import 'package:jma3a/core/router/app_router.dart';
// // // // // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // // // // import 'package:jma3a/features/rooms/domain/room_entity.dart';
// // // // // // import 'package:jma3a/features/settings/presentation/screen_security_service.dart';
// // // // // // import 'package:provider/provider.dart';
// // // // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // // // import '../../../../../core/di/service_locator.dart';
// // // // // // import '../../../../../core/extensions/context_ext.dart';
// // // // // // import '../../../../../core/providers/auth_provider.dart';
// // // // // // import '../../../../../core/router/route_names.dart';
// // // // // // import '../../../../../core/services/realtime_service.dart';
// // // // // // // import '../../../../../core/services/screen_security_service.dart';
// // // // // // import '../../../../../core/theme/app_colors.dart';
// // // // // // import '../../../../../shared/widgets/feedback/error_view.dart';
// // // // // // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // // // // // // import '../../engine/base_game_engine.dart';
// // // // // // import '../../domain/tod_models.dart';
// // // // // // import '../../tod_game_provider.dart';

// // // // // // import '../../data/tod_repository.dart';
// // // // // // import 'tod_card_screen.dart';
// // // // // // import 'tod_end_screen.dart';
// // // // // // import 'tod_loading_screen.dart';
// // // // // // import 'tod_punishment_screen.dart';
// // // // // // import '../widgets/tod_hud.dart';

// // // // // // /// Entry point for an active Truth or Dare session.
// // // // // // ///
// // // // // // /// Responsibilities:
// // // // // // ///  - Owns and scopes TodGameProvider for this session
// // // // // // ///  - Wires RealtimeService callbacks → TodGameProvider
// // // // // // ///  - Routes between loading / error / active / game-over screens
// // // // // // ///  - Forwards game_state and player_action from the room Broadcast channel
// // // // // // class TodGameScreen extends StatefulWidget {
// // // // // //   const TodGameScreen({
// // // // // //     super.key,
// // // // // //     required this.roomId,
// // // // // //     required this.config,
// // // // // //     required this.playerIds,
// // // // // //     required this.playerDisplayNames,
// // // // // //     required this.packId,
// // // // // //     required this.isOwner,
// // // // // //     this.sessionId,
// // // // // //     this.isModerator = false,
// // // // // //     this.packCoverUrl,
// // // // // //   });

// // // // // //   final String roomId;
// // // // // //   final GameConfig config;
// // // // // //   final List<String> playerIds;
// // // // // //   final Map<String, String> playerDisplayNames; // userId → displayName
// // // // // //   final String packId;
// // // // // //   final bool isOwner;
// // // // // //   final String? sessionId;
// // // // // //   final bool isModerator;
// // // // // //   final String? packCoverUrl;

// // // // // //   @override
// // // // // //   State<TodGameScreen> createState() => _TodGameScreenState();
// // // // // // }

// // // // // // class _TodGameScreenState extends State<TodGameScreen> {
// // // // // //   late final TodGameProvider _provider;

// // // // // //   // Subscriptions to the room Broadcast channel
// // // // // //   // (channel already open by RoomProvider — we just register callbacks)
// // // // // //   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();

// // // // // //     // Block screenshots/screen recording for the duration of gameplay —
// // // // // //     // proof photos/videos and responses shouldn't be capturable.
// // // // // //     ScreenSecurityService.instance.enable();
// // // // // //     ScreenSecurityService.instance.enableScreenshotDetection(() {
// // // // // //       // iOS can't block screenshots outright, only detect them — let the
// // // // // //       // room know, Snapchat-style, since it can't be silently captured.
// // // // // //       sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // // // //         'type': 'screenshot_taken',
// // // // // //         'user_id': context.read<AuthProvider>().currentUser?.id,
// // // // // //       }).ignore();
// // // // // //     });

// // // // // //     final auth = context.read<AuthProvider>();
// // // // // //     final user = auth.currentUser!;

// // // // // //     _provider = TodGameProvider(
// // // // // //       realtimeService: sl.realtimeService,
// // // // // //       repository: TodRepository.instance,
// // // // // //       currentUserId: user.id,
// // // // // //       currentDisplayName: user.displayName ?? user.username ?? 'Player',
// // // // // //       isModerator: widget.isModerator,
// // // // // //     );

// // // // // //     // ── Wire Broadcast callbacks ────────────────────────────────────────────
// // // // // //     // The room channel is already subscribed by RoomProvider/LobbyScreen.
// // // // // //     // TodGameScreen registers its own game-specific handlers for game_state
// // // // // //     // and player_action by re-subscribing with extended handlers.
// // // // // //     //
// // // // // //     // We do this by using the RealtimeService._bcast pattern:
// // // // // //     // The channel already has onGameState/onPlayerAction wired to no-ops
// // // // // //     // in RoomProvider. We replace them here by storing callbacks and
// // // // // //     // intercepting from the top-level channel via a dedicated subscription.
// // // // // //     _wireRealtimeCallbacks();

// // // // // //     if (widget.isOwner) {
// // // // // //       final isPremium =
// // // // // //           context.read<AuthProvider>().currentUser?.isPremium ?? false;
// // // // // //       _provider.initAsOwner(
// // // // // //         roomId: widget.roomId,
// // // // // //         config: widget.config,
// // // // // //         playerIds: widget.playerIds,
// // // // // //         playerDisplayNames: widget.playerDisplayNames,
// // // // // //         packId: widget.packId,
// // // // // //         isPremium: isPremium,
// // // // // //         packCoverUrl: widget.packCoverUrl,
// // // // // //       );
// // // // // //     } else {
// // // // // //       _provider.initAsFollower(
// // // // // //         roomId: widget.roomId,
// // // // // //         config: widget.config,
// // // // // //         sessionId: widget.sessionId,
// // // // // //         packCoverUrl: widget.packCoverUrl,
// // // // // //       );
// // // // // //     }
// // // // // //   }

// // // // // //   @override
// // // // // //   void dispose() {
// // // // // //     ScreenSecurityService.instance.disable();
// // // // // //     _statusSub?.cancel();
// // // // // //     // Re-subscribe the room channel with lobby-mode handlers so the lobby
// // // // // //     // (which is still on the stack) continues to receive events after we pop.
// // // // // //     // DO NOT fully unsubscribe — that would cut off followers still in-game.
// // // // // //     sl.realtimeService
// // // // // //         .subscribe(
// // // // // //           roomId: widget.roomId,
// // // // // //           onGameState: (_) {},
// // // // // //           onPlayerAction: (_) {},
// // // // // //           onSyncRequest: (_) {},
// // // // // //           onGameStarted: (_) {},
// // // // // //           onGameEnded: (_) {},
// // // // // //           onRoomEvent: (_) {},
// // // // // //           onChatMessage: (_) {},
// // // // // //           onModeration: (_) {},
// // // // // //           onSettingsChange: (_) {},
// // // // // //           onPresenceSync: (_) {},
// // // // // //           onPresenceJoin: (_) {},
// // // // // //           onPresenceLeave: (_) {},
// // // // // //           onStatusChange: (_) {},
// // // // // //         )
// // // // // //         .ignore();
// // // // // //     _provider.dispose();
// // // // // //     super.dispose();
// // // // // //   }

// // // // // //   /// Wire game-specific callbacks into the existing room channel.
// // // // // //   ///
// // // // // //   /// Strategy: re-subscribe to the room channel with updated handlers that
// // // // // //   /// forward game_state and player_action to this provider.
// // // // // //   /// The channel is already open; we track callbacks via a thin interceptor.
// // // // // //   void _wireRealtimeCallbacks() {
// // // // // //     // Listen to channel status changes for reconnection awareness
// // // // // //     _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
// // // // // //       status,
// // // // // //     ) {
// // // // // //       if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // //           !_provider.hasSyncedState) {
// // // // // //         // Channel reconnected — request state sync
// // // // // //         sl.realtimeService.broadcastSyncRequest(
// // // // // //           widget.roomId,
// // // // // //           context.read<AuthProvider>().currentUser!.id,
// // // // // //           0,
// // // // // //         );
// // // // // //       }
// // // // // //     });

// // // // // //     // Re-subscribe with game handlers added.
// // // // // //     // This safely replaces the channel subscription with game callbacks.
// // // // // //     // (No-op handlers in RoomProvider are replaced with active ones here.)
// // // // // //     _resubscribeWithGameHandlers();
// // // // // //   }

// // // // // //   void _resubscribeWithGameHandlers() {
// // // // // //     final userId = context.read<AuthProvider>().currentUser!.id;

// // // // // //     // Unsubscribe existing channel and re-subscribe with game callbacks merged
// // // // // //     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
// // // // // //       sl.realtimeService.subscribe(
// // // // // //         roomId: widget.roomId,
// // // // // //         // ── Game-specific handlers ─────────────────────────────────────────
// // // // // //         onGameState: (p) => _provider.onStateBroadcast(p),
// // // // // //         onPlayerAction: (p) => _provider.onPlayerAction(p),
// // // // // //         onSyncRequest: (p) => _provider.onSyncRequest(p),
// // // // // //         onGameStarted: (_) {},
// // // // // //         onGameEnded: (p) {
// // // // // //           // Admin ended the game — take everyone back to the lobby
// // // // // //           if (mounted) {
// // // // // //             ScaffoldMessenger.of(context).showSnackBar(
// // // // // //               const SnackBar(content: Text('The host ended the game')),
// // // // // //             );
// // // // // //             // Pop back to lobby (the LobbyScreen is still on the stack)
// // // // // //             if (context.canPop())
// // // // // //               context.pop();
// // // // // //             else
// // // // // //               context.go(RouteNames.home);
// // // // // //           }
// // // // // //         },
// // // // // //         // ── Room lifecycle (passthrough — RoomProvider is disposed) ─────────
// // // // // //         onRoomEvent: (p) {
// // // // // //           final type = p['type'] as String?;
// // // // // //           if (type == 'screenshot_taken') {
// // // // // //             final shooterId = p['user_id'] as String?;
// // // // // //             final myId = context.read<AuthProvider>().currentUser?.id;
// // // // // //             if (shooterId != null && shooterId != myId && mounted) {
// // // // // //               ScaffoldMessenger.of(context).showSnackBar(
// // // // // //                 SnackBar(
// // // // // //                   content: Text(
// // // // // //                     '📸 ${widget.playerDisplayNames[shooterId] ?? 'Someone'} took a screenshot',
// // // // // //                   ),
// // // // // //                   backgroundColor: Colors.black87,
// // // // // //                 ),
// // // // // //               );
// // // // // //             }
// // // // // //             return;
// // // // // //           }
// // // // // //           if (type == 'player_left' && mounted) {
// // // // // //             final name = p['display_name'] as String? ?? 'A player';
// // // // // //             final forGood = p['for_good'] as bool? ?? true;
// // // // // //             final leavingId = p['user_id'] as String?;
// // // // // //             final returnMins = p['return_mins'] as int?;
// // // // // //             if (leavingId != null && widget.isOwner) {
// // // // // //               _provider.markPlayerAway(leavingId, forGood: forGood);
// // // // // //               // Auto-quit if owner is now the only active player
// // // // // //               final activePlayers =
// // // // // //                   _provider.state?.playerOrder
// // // // // //                       .where((id) => !_provider.awayPlayerIds.contains(id))
// // // // // //                       .toList() ??
// // // // // //                   [];
// // // // // //               if (activePlayers.length <= 1 && activePlayers.isNotEmpty) {
// // // // // //                 WidgetsBinding.instance.addPostFrameCallback((_) async {
// // // // // //                   if (!mounted) return;
// // // // // //                   await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // // // //                     'type': 'game_ended',
// // // // // //                     'reason': 'all_players_left',
// // // // // //                   });
// // // // // //                   await sl.roomRepository.updateStatus(
// // // // // //                     widget.roomId,
// // // // // //                     RoomStatus.waiting,
// // // // // //                   );
// // // // // //                   if (mounted) {
// // // // // //                     ScaffoldMessenger.of(context).showSnackBar(
// // // // // //                       const SnackBar(
// // // // // //                         content: Text('All players left — game ended'),
// // // // // //                         backgroundColor: Colors.orange,
// // // // // //                       ),
// // // // // //                     );
// // // // // //                     await Future.delayed(const Duration(milliseconds: 800));
// // // // // //                     if (mounted) {
// // // // // //                       if (context.canPop())
// // // // // //                         context.pop();
// // // // // //                       else
// // // // // //                         context.go('/home/room/${widget.roomId}');
// // // // // //                     }
// // // // // //                   }
// // // // // //                 });
// // // // // //               }
// // // // // //             }
// // // // // //             final msg = forGood
// // // // // //                 ? '👋 $name left the game'
// // // // // //                 : '🕐 $name stepped away (${returnMins != null ? 'back in ${returnMins}m' : 'coming back'})';
// // // // // //             ScaffoldMessenger.of(context).showSnackBar(
// // // // // //               SnackBar(
// // // // // //                 content: Text(msg),
// // // // // //                 backgroundColor: forGood
// // // // // //                     ? Colors.red.shade700
// // // // // //                     : Colors.orange.shade700,
// // // // // //                 duration: const Duration(seconds: 4),
// // // // // //               ),
// // // // // //             );
// // // // // //             return;
// // // // // //           }
// // // // // //           if (type == 'ownership_transferred' && mounted) {
// // // // // //             final myId = context.read<AuthProvider>().currentUser?.id;
// // // // // //             final newOwnerId = p['new_owner_id'] as String?;
// // // // // //             if (newOwnerId == myId) {
// // // // // //               ScaffoldMessenger.of(context).showSnackBar(
// // // // // //                 const SnackBar(
// // // // // //                   content: Text('👑 You are now the game host!'),
// // // // // //                   backgroundColor: Colors.purple,
// // // // // //                 ),
// // // // // //               );
// // // // // //             }
// // // // // //             return;
// // // // // //           }
// // // // // //           if (type == 'game_ended' && mounted) {
// // // // // //             final reason = p['reason'] as String?;
// // // // // //             if (reason == 'host_quit_to_lobby') {
// // // // // //               WidgetsBinding.instance.addPostFrameCallback((_) {
// // // // // //                 if (!mounted) return;
// // // // // //                 ScaffoldMessenger.of(context).showSnackBar(
// // // // // //                   const SnackBar(
// // // // // //                     content: Text('🔄 Host ended the game — back to lobby'),
// // // // // //                     duration: Duration(seconds: 3),
// // // // // //                   ),
// // // // // //                 );
// // // // // //                 if (context.canPop()) {
// // // // // //                   context.pop();
// // // // // //                 } else {
// // // // // //                   context.go('/home/room/${widget.roomId}');
// // // // // //                 }
// // // // // //               });
// // // // // //             }
// // // // // //             return;
// // // // // //           }
// // // // // //           if (type == 'tod_ready_count') {
// // // // // //             final ids = (p['ready_user_ids'] as List?)?.cast<String>() ?? [];
// // // // // //             _provider.onReadyCountUpdate(ids);
// // // // // //             return;
// // // // // //           }
// // // // // //           if ((type == 'room_closed' || type == 'owner_left') && mounted) {
// // // // // //             WidgetsBinding.instance.addPostFrameCallback((_) {
// // // // // //               if (mounted) {
// // // // // //                 showDialog(
// // // // // //                   context: context,
// // // // // //                   barrierDismissible: false,
// // // // // //                   builder: (ctx2) => AlertDialog(
// // // // // //                     title: const Text('Room Closed'),
// // // // // //                     content: const Text('The host closed the room.'),
// // // // // //                     actions: [
// // // // // //                       FilledButton(
// // // // // //                         onPressed: () {
// // // // // //                           Navigator.of(ctx2).pop();
// // // // // //                           AppRouter.router.go(RouteNames.home);
// // // // // //                         },
// // // // // //                         child: const Text('OK'),
// // // // // //                       ),
// // // // // //                     ],
// // // // // //                   ),
// // // // // //                 );
// // // // // //               } else {
// // // // // //                 AppRouter.router.go(RouteNames.home);
// // // // // //               }
// // // // // //             });
// // // // // //           }
// // // // // //         },
// // // // // //         onChatMessage: (p) {
// // // // // //           final msg = TodChatMsg(
// // // // // //             senderId: p['user_id'] as String? ?? '',
// // // // // //             senderName: p['display_name'] as String? ?? 'Player',
// // // // // //             text: p['content'] as String? ?? '',
// // // // // //             ts: DateTime.fromMillisecondsSinceEpoch(
// // // // // //               (p['ts'] as num?)?.toInt() ??
// // // // // //                   DateTime.now().millisecondsSinceEpoch,
// // // // // //             ),
// // // // // //           );
// // // // // //           _provider.addChatMessage(msg);
// // // // // //         },
// // // // // //         onModeration: (p) => _handleModerationEvent(p),
// // // // // //         onSettingsChange: (_) {},
// // // // // //         // ── Presence ──────────────────────────────────────────────────────
// // // // // //         onPresenceSync: (_) {},
// // // // // //         onPresenceJoin: (_) {},
// // // // // //         onPresenceLeave: (_) {},
// // // // // //         onStatusChange: (status) {
// // // // // //           if (!mounted) return;
// // // // // //           if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // //               !_provider.hasSyncedState) {
// // // // // //             sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
// // // // // //           }
// // // // // //         },
// // // // // //       );
// // // // // //     });
// // // // // //   }

// // // // // //   void _handleModerationEvent(Map<String, dynamic> p) {
// // // // // //     final type = p['type'] as String?;
// // // // // //     final targetId = p['target_user_id'] as String?;
// // // // // //     final currentId = context.read<AuthProvider>().currentUser?.id;

// // // // // //     // If kicked or banned, navigate back to lobby
// // // // // //     if ((type == 'kick' || type == 'ban') && targetId == currentId) {
// // // // // //       if (mounted) {
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           const SnackBar(content: Text('You were removed from the room')),
// // // // // //         );
// // // // // //         context.go(RouteNames.home);
// // // // // //       }
// // // // // //     }
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return ChangeNotifierProvider.value(
// // // // // //       value: _provider,
// // // // // //       child: Consumer<TodGameProvider>(
// // // // // //         builder: (ctx, game, _) => _build(ctx, game),
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   Widget _build(BuildContext ctx, TodGameProvider game) {
// // // // // //     if (game.loadState == TodLoadState.loading) {
// // // // // //       return const TodLoadingScreen();
// // // // // //     }

// // // // // //     if (game.loadState == TodLoadState.error) {
// // // // // //       return Scaffold(
// // // // // //         appBar: AppBar(
// // // // // //           leading: BackButton(
// // // // // //             onPressed: () async {
// // // // // //               if (widget.isOwner) {
// // // // // //                 // Owner leaving game → end game for everyone, go back to lobby
// // // // // //                 try {
// // // // // //                   await sl.realtimeService.broadcastGameEnded(widget.roomId, {
// // // // // //                     'reason': 'host_left',
// // // // // //                   });
// // // // // //                   await sl.roomRepository.updateStatus(
// // // // // //                     widget.roomId,
// // // // // //                     RoomStatus.waiting,
// // // // // //                   );
// // // // // //                 } catch (_) {}
// // // // // //               }
// // // // // //               if (ctx.mounted) ctx.go(RouteNames.home);
// // // // // //             },
// // // // // //           ),
// // // // // //         ),
// // // // // //         body: ErrorView(
// // // // // //           message: game.error ?? 'Failed to load game',
// // // // // //           onRetry: () => ctx.go(RouteNames.home),
// // // // // //         ),
// // // // // //       );
// // // // // //     }

// // // // // //     if (game.loadState == TodLoadState.gameOver ||
// // // // // //         (game.state?.isOver ?? false)) {
// // // // // //       return TodEndScreen(
// // // // // //         state: game.state!,
// // // // // //         displayNames: widget.playerDisplayNames,
// // // // // //         onLeave: () => ctx.go(RouteNames.home),
// // // // // //       );
// // // // // //     }

// // // // // //     final state = game.state;
// // // // // //     if (state == null) return const TodLoadingScreen();

// // // // // //     return _TodGameScaffold(
// // // // // //       state: state,
// // // // // //       game: game,
// // // // // //       displayNames: widget.playerDisplayNames,
// // // // // //       roomId: widget.roomId,
// // // // // //       isOwner: widget.isOwner,
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // // ── Scaffold with history support ─────────────────────────────────────────────

// // // // // // class _TodGameScaffold extends StatefulWidget {
// // // // // //   const _TodGameScaffold({
// // // // // //     required this.state,
// // // // // //     required this.game,
// // // // // //     required this.displayNames,
// // // // // //     required this.roomId,
// // // // // //     required this.isOwner,
// // // // // //   });
// // // // // //   final TodState state;
// // // // // //   final TodGameProvider game;
// // // // // //   final Map<String, String> displayNames;
// // // // // //   final String roomId;
// // // // // //   final bool isOwner;
// // // // // //   @override
// // // // // //   State<_TodGameScaffold> createState() => _TodGameScaffoldState();
// // // // // // }

// // // // // // class _TodGameScaffoldState extends State<_TodGameScaffold> {
// // // // // //   bool _showHistory = false;
// // // // // //   bool _showChat = false;
// // // // // //   int _unreadChat = 0;

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final state = widget.state;
// // // // // //     final game = widget.game;

// // // // // //     if (_showHistory) {
// // // // // //       return Scaffold(
// // // // // //         appBar: AppBar(
// // // // // //           leading: BackButton(
// // // // // //             onPressed: () => setState(() => _showHistory = false),
// // // // // //           ),
// // // // // //           title: Text('History (${state.history.length} rounds)'),
// // // // // //         ),
// // // // // //         body: _HistoryPanel(
// // // // // //           history: state.history,
// // // // // //           displayNames: widget.displayNames,
// // // // // //         ),
// // // // // //       );
// // // // // //     }

// // // // // //     return PopScope(
// // // // // //       canPop: false,
// // // // // //       onPopInvoked: (_) => WidgetsBinding.instance.addPostFrameCallback(
// // // // // //         (_) => _showLeaveDialog(context, game, state),
// // // // // //       ),
// // // // // //       child: Scaffold(
// // // // // //         appBar: AppBar(
// // // // // //           automaticallyImplyLeading: false,
// // // // // //           title: const Text(''),
// // // // // //           leading: IconButton(
// // // // // //             icon: const Icon(Icons.arrow_back),
// // // // // //             onPressed: () => _showLeaveDialog(context, game, state),
// // // // // //           ),
// // // // // //           actions: [
// // // // // //             // Chat button with unread badge
// // // // // //             Consumer<TodGameProvider>(
// // // // // //               builder: (_, g, __) => Stack(
// // // // // //                 alignment: Alignment.topRight,
// // // // // //                 children: [
// // // // // //                   IconButton(
// // // // // //                     icon: const Icon(Icons.chat_bubble_outline_rounded),
// // // // // //                     onPressed: () {
// // // // // //                       g.clearUnreadChat();
// // // // // //                       showModalBottomSheet(
// // // // // //                         context: context,
// // // // // //                         isScrollControlled: true,
// // // // // //                         backgroundColor: Colors.transparent,
// // // // // //                         builder: (_) =>
// // // // // //                             _InGameChatSheet(game: g, myId: g.currentUserId),
// // // // // //                       );
// // // // // //                     },
// // // // // //                   ),
// // // // // //                   if (g.unreadChat > 0)
// // // // // //                     Positioned(
// // // // // //                       top: 8,
// // // // // //                       right: 8,
// // // // // //                       child: Container(
// // // // // //                         width: 8,
// // // // // //                         height: 8,
// // // // // //                         decoration: const BoxDecoration(
// // // // // //                           color: Colors.red,
// // // // // //                           shape: BoxShape.circle,
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                 ],
// // // // // //               ),
// // // // // //             ),
// // // // // //             if (state.history.isNotEmpty)
// // // // // //               IconButton(
// // // // // //                 icon: const Icon(Icons.history_rounded),
// // // // // //                 tooltip: 'History',
// // // // // //                 onPressed: () => setState(() => _showHistory = true),
// // // // // //               ),
// // // // // //           ],
// // // // // //         ),
// // // // // //         body: SafeArea(
// // // // // //           child: Column(
// // // // // //             children: [
// // // // // //               TodHud(
// // // // // //                 state: state,
// // // // // //                 game: game,
// // // // // //                 displayNames: widget.displayNames,
// // // // // //               ),
// // // // // //               Expanded(
// // // // // //                 child: AnimatedSwitcher(
// // // // // //                   duration: const Duration(milliseconds: 300),
// // // // // //                   transitionBuilder: (child, anim) => FadeTransition(
// // // // // //                     opacity: anim,
// // // // // //                     child: SlideTransition(
// // // // // //                       position:
// // // // // //                           Tween<Offset>(
// // // // // //                             begin: const Offset(0, 0.05),
// // // // // //                             end: Offset.zero,
// // // // // //                           ).animate(
// // // // // //                             CurvedAnimation(
// // // // // //                               parent: anim,
// // // // // //                               curve: Curves.easeOutCubic,
// // // // // //                             ),
// // // // // //                           ),
// // // // // //                       child: child,
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                   child: KeyedSubtree(
// // // // // //                     key: ValueKey('${state.phase}-${state.currentPlayerId}'),
// // // // // //                     child: _phaseWidget(
// // // // // //                       context,
// // // // // //                       game,
// // // // // //                       widget.displayNames,
// // // // // //                       state,
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ],
// // // // // //           ),
// // // // // //         ),
// // // // // //       ), // end Scaffold (PopScope child)
// // // // // //     ); // end PopScope
// // // // // //   }

// // // // // //   Future<void> _showLeaveDialog(
// // // // // //     BuildContext ctx,
// // // // // //     TodGameProvider game,
// // // // // //     TodState state,
// // // // // //   ) async {
// // // // // //     if (!ctx.mounted) return;
// // // // // //     final isOwner = widget.isOwner;
// // // // // //     final myUserId = game.currentUserId;
// // // // // //     final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

// // // // // //     if (isOwner) {
// // // // // //       final confirmed = await showDialog<bool>(
// // // // // //         context: ctx,
// // // // // //         builder: (dCtx) => AlertDialog(
// // // // // //           title: const Text('Quit Game?'),
// // // // // //           content: const Text(
// // // // // //             'The game will end for everyone and all players will return to the lobby.',
// // // // // //           ),
// // // // // //           actions: [
// // // // // //             TextButton(
// // // // // //               onPressed: () => Navigator.of(dCtx).pop(false),
// // // // // //               child: const Text('Cancel'),
// // // // // //             ),
// // // // // //             FilledButton(
// // // // // //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // // // // //               onPressed: () => Navigator.of(dCtx).pop(true),
// // // // // //               child: const Text('End Game for Everyone'),
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
// // // // // //       );
// // // // // //       if (confirmed != true || !ctx.mounted) return;

// // // // // //       try {
// // // // // //         await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // // // //           'type': 'game_ended',
// // // // // //           'reason': 'host_quit_to_lobby',
// // // // // //         });
// // // // // //         await Future.delayed(const Duration(milliseconds: 400));
// // // // // //         await sl.roomRepository.updateStatus(widget.roomId, RoomStatus.waiting);
// // // // // //       } catch (_) {}
// // // // // //       if (ctx.mounted) {
// // // // // //         if (ctx.canPop()) {
// // // // // //           ctx.pop();
// // // // // //         } else {
// // // // // //           ctx.go('/home/room/${widget.roomId}');
// // // // // //         }
// // // // // //       }
// // // // // //     } else {
// // // // // //       // ── Player options ───────────────────────────────────────────────────
// // // // // //       final returnMins = isPremium ? 10 : 5;
// // // // // //       final choice = await showDialog<String>(
// // // // // //         context: ctx,
// // // // // //         builder: (_) => AlertDialog(
// // // // // //           title: const Text('Leave Game?'),
// // // // // //           content: Text(
// // // // // //             "If you'll return, your turns will be skipped until you're "
// // // // // //             'back. You have $returnMins minutes — after that your seat '
// // // // // //             'is lost.',
// // // // // //           ),
// // // // // //           actions: [
// // // // // //             TextButton(
// // // // // //               onPressed: () => Navigator.pop(ctx, 'cancel'),
// // // // // //               child: const Text('Stay'),
// // // // // //             ),
// // // // // //             FilledButton.tonal(
// // // // // //               onPressed: () => Navigator.pop(ctx, 'return'),
// // // // // //               child: Text("I'll Return ($returnMins min)"),
// // // // // //             ),
// // // // // //             FilledButton(
// // // // // //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // // // // //               onPressed: () => Navigator.pop(ctx, 'definitive'),
// // // // // //               child: const Text('Leave for Good'),
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
// // // // // //       );
// // // // // //       if (choice == null || choice == 'cancel' || !ctx.mounted) return;

// // // // // //       final displayName = widget.displayNames[myUserId] ?? 'A player';

// // // // // //       if (choice == 'return') {
// // // // // //         try {
// // // // // //           await sl.roomRepository.setMemberAway(
// // // // // //             widget.roomId,
// // // // // //             myUserId,
// // // // // //             away: true,
// // // // // //           );
// // // // // //           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // // // //             'type': 'player_left',
// // // // // //             'user_id': myUserId,
// // // // // //             'display_name': displayName,
// // // // // //             'for_good': false,
// // // // // //             'return_mins': returnMins,
// // // // // //           });
// // // // // //         } catch (_) {}
// // // // // //         if (ctx.mounted) {
// // // // // //           ScaffoldMessenger.of(ctx).showSnackBar(
// // // // // //             SnackBar(
// // // // // //               content: Text(
// // // // // //                 "You'll be back in $returnMins min — seat reserved",
// // // // // //               ),
// // // // // //               backgroundColor: Colors.orange.shade700,
// // // // // //               duration: const Duration(seconds: 3),
// // // // // //             ),
// // // // // //           );
// // // // // //           await Future.delayed(const Duration(milliseconds: 800));
// // // // // //           if (ctx.mounted) ctx.go('/home/room/${widget.roomId}');
// // // // // //         }
// // // // // //       } else {
// // // // // //         // Leave for good
// // // // // //         try {
// // // // // //           await sl.roomRepository.setMemberDefinitiveLeave(
// // // // // //             widget.roomId,
// // // // // //             myUserId,
// // // // // //           );
// // // // // //           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // // // //             'type': 'player_left',
// // // // // //             'user_id': myUserId,
// // // // // //             'display_name': displayName,
// // // // // //             'for_good': true,
// // // // // //           });
// // // // // //         } catch (_) {}
// // // // // //         if (ctx.mounted) {
// // // // // //           // Check if admin is now alone — if so, admin auto-quits game
// // // // // //           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // // // //             'type': 'check_auto_quit',
// // // // // //             'user_id': myUserId,
// // // // // //           });
// // // // // //           ctx.go('/home/room/${widget.roomId}');
// // // // // //         }
// // // // // //       }
// // // // // //     }
// // // // // //   }

// // // // // //   Widget _phaseWidget(
// // // // // //     BuildContext ctx,
// // // // // //     TodGameProvider game,
// // // // // //     Map<String, String> displayNames,
// // // // // //     TodState state,
// // // // // //   ) {
// // // // // //     return switch (state.phase) {
// // // // // //       TodTurnPhase.punishmentVoting => TodPunishmentScreen(
// // // // // //         state: state,
// // // // // //         game: game,
// // // // // //         displayNames: widget.displayNames,
// // // // // //       ),
// // // // // //       _ => TodCardScreen(
// // // // // //         state: state,
// // // // // //         game: game,
// // // // // //         displayNames: widget.displayNames,
// // // // // //       ),
// // // // // //     };
// // // // // //   }
// // // // // // }

// // // // // // // ── History panel ─────────────────────────────────────────────────────────────

// // // // // // class _HistoryPanel extends StatelessWidget {
// // // // // //   const _HistoryPanel({required this.history, required this.displayNames});
// // // // // //   final List<TodRoundRecord> history;
// // // // // //   final Map<String, String> displayNames;

// // // // // //   String _name(String id) =>
// // // // // //       displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final theme = context.theme;
// // // // // //     if (history.isEmpty) {
// // // // // //       return const Center(child: Text('No rounds completed yet.'));
// // // // // //     }
// // // // // //     return ListView.builder(
// // // // // //       padding: const EdgeInsets.all(12),
// // // // // //       itemCount: history.length,
// // // // // //       itemBuilder: (_, i) {
// // // // // //         final round = history[history.length - 1 - i]; // newest first
// // // // // //         final reactTally = <String, int>{};
// // // // // //         for (final r in round.reactions) {
// // // // // //           reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
// // // // // //         }
// // // // // //         return Card(
// // // // // //           margin: const EdgeInsets.only(bottom: 10),
// // // // // //           child: ExpansionTile(
// // // // // //             leading: CircleAvatar(
// // // // // //               backgroundColor: theme.colorScheme.primaryContainer,
// // // // // //               child: Text(
// // // // // //                 '${round.roundNumber}',
// // // // // //                 style: theme.textTheme.labelLarge,
// // // // // //               ),
// // // // // //             ),
// // // // // //             title: Text(
// // // // // //               _name(round.playerId),
// // // // // //               style: theme.textTheme.bodyMedium?.copyWith(
// // // // // //                 fontWeight: FontWeight.w700,
// // // // // //               ),
// // // // // //             ),
// // // // // //             subtitle: Text(
// // // // // //               round.card != null
// // // // // //                   ? '${round.card!.type == TodCardType.truth ? "Truth" : "Dare"}: ${round.card!.content}'
// // // // // //                   : 'Skipped',
// // // // // //               maxLines: 1,
// // // // // //               overflow: TextOverflow.ellipsis,
// // // // // //               style: theme.textTheme.bodySmall,
// // // // // //             ),
// // // // // //             children: [
// // // // // //               Padding(
// // // // // //                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
// // // // // //                 child: Column(
// // // // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //                   children: [
// // // // // //                     // Card content
// // // // // //                     if (round.card != null)
// // // // // //                       Container(
// // // // // //                         width: double.infinity,
// // // // // //                         padding: const EdgeInsets.all(10),
// // // // // //                         decoration: BoxDecoration(
// // // // // //                           color: round.card!.type == TodCardType.truth
// // // // // //                               ? Colors.blue.withOpacity(0.08)
// // // // // //                               : Colors.orange.withOpacity(0.08),
// // // // // //                           borderRadius: BorderRadius.circular(8),
// // // // // //                         ),
// // // // // //                         child: Text(
// // // // // //                           round.card!.content,
// // // // // //                           style: theme.textTheme.bodyMedium,
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                     // Response
// // // // // //                     if (round.response.isNotEmpty) ...[
// // // // // //                       const SizedBox(height: 8),
// // // // // //                       Row(
// // // // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //                         children: [
// // // // // //                           const Text('💬 ', style: TextStyle(fontSize: 14)),
// // // // // //                           Expanded(
// // // // // //                             child: Text(
// // // // // //                               '"${round.response}"',
// // // // // //                               style: theme.textTheme.bodySmall?.copyWith(
// // // // // //                                 fontStyle: FontStyle.italic,
// // // // // //                               ),
// // // // // //                             ),
// // // // // //                           ),
// // // // // //                         ],
// // // // // //                       ),
// // // // // //                     ],
// // // // // //                     // Votes
// // // // // //                     if (round.voteCount > 0) ...[
// // // // // //                       const SizedBox(height: 6),
// // // // // //                       Text(
// // // // // //                         '👍 ${round.voteCount} vote${round.voteCount != 1 ? "s" : ""}',
// // // // // //                         style: theme.textTheme.bodySmall?.copyWith(
// // // // // //                           color: theme.colorScheme.primary,
// // // // // //                           fontWeight: FontWeight.w600,
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                     ],
// // // // // //                     // Proof — history NEVER shows the actual photo/video,
// // // // // //                     // only whether one existed and who watched it.
// // // // // //                     if (round.hadProof) ...[
// // // // // //                       const SizedBox(height: 8),
// // // // // //                       _ProofWatchedBadge(watchedBy: round.proofWatchedBy),
// // // // // //                     ],
// // // // // //                     // Reactions
// // // // // //                     if (reactTally.isNotEmpty) ...[
// // // // // //                       const SizedBox(height: 8),
// // // // // //                       Wrap(
// // // // // //                         spacing: 6,
// // // // // //                         runSpacing: 4,
// // // // // //                         children: reactTally.entries
// // // // // //                             .map(
// // // // // //                               (e) => Container(
// // // // // //                                 padding: const EdgeInsets.symmetric(
// // // // // //                                   horizontal: 8,
// // // // // //                                   vertical: 3,
// // // // // //                                 ),
// // // // // //                                 decoration: BoxDecoration(
// // // // // //                                   color:
// // // // // //                                       theme.colorScheme.surfaceContainerHighest,
// // // // // //                                   borderRadius: BorderRadius.circular(16),
// // // // // //                                 ),
// // // // // //                                 child: Text(
// // // // // //                                   '${e.key} ${e.value}',
// // // // // //                                   style: const TextStyle(fontSize: 13),
// // // // // //                                 ),
// // // // // //                               ),
// // // // // //                             )
// // // // // //                             .toList(),
// // // // // //                       ),
// // // // // //                     ],
// // // // // //                   ],
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ],
// // // // // //           ),
// // // // // //         );
// // // // // //       },
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // // Proof existed for this round — history shows only whether/who watched
// // // // // // // it, never the actual photo or video (that's only ever live during the
// // // // // // // turn itself, see TodState.turnProofUrl).
// // // // // // class _ProofWatchedBadge extends StatelessWidget {
// // // // // //   const _ProofWatchedBadge({required this.watchedBy});
// // // // // //   final List<String> watchedBy;

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final watched = watchedBy.isNotEmpty;
// // // // // //     return Container(
// // // // // //       height: 36,
// // // // // //       padding: const EdgeInsets.symmetric(horizontal: 10),
// // // // // //       decoration: BoxDecoration(
// // // // // //         color: Colors.grey.shade200,
// // // // // //         borderRadius: BorderRadius.circular(8),
// // // // // //       ),
// // // // // //       alignment: Alignment.centerLeft,
// // // // // //       child: Row(
// // // // // //         mainAxisSize: MainAxisSize.min,
// // // // // //         children: [
// // // // // //           Icon(
// // // // // //             watched ? Icons.visibility_outlined : Icons.visibility_off_outlined,
// // // // // //             size: 16,
// // // // // //             color: Colors.grey.shade600,
// // // // // //           ),
// // // // // //           const SizedBox(width: 6),
// // // // // //           Text(
// // // // // //             watched
// // // // // //                 ? 'Proof watched by ${watchedBy.length}'
// // // // // //                 : 'Proof sent — not watched',
// // // // // //             style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
// // // // // //           ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // // ── In-game chat sheet ─────────────────────────────────────────────────────────
// // // // // // class _InGameChatSheet extends StatefulWidget {
// // // // // //   const _InGameChatSheet({required this.game, required this.myId});
// // // // // //   final TodGameProvider game;
// // // // // //   final String myId;
// // // // // //   @override
// // // // // //   State<_InGameChatSheet> createState() => _InGameChatSheetState();
// // // // // // }

// // // // // // class _InGameChatSheetState extends State<_InGameChatSheet> {
// // // // // //   final _ctrl = TextEditingController();
// // // // // //   final _scroll = ScrollController();
// // // // // //   @override
// // // // // //   void dispose() {
// // // // // //     _ctrl.dispose();
// // // // // //     _scroll.dispose();
// // // // // //     super.dispose();
// // // // // //   }

// // // // // //   void _send() {
// // // // // //     final t = _ctrl.text.trim();
// // // // // //     if (t.isEmpty) return;
// // // // // //     widget.game.sendChat(t);
// // // // // //     _ctrl.clear();
// // // // // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // // // // //       if (_scroll.hasClients)
// // // // // //         _scroll.animateTo(
// // // // // //           _scroll.position.maxScrollExtent,
// // // // // //           duration: 200.ms,
// // // // // //           curve: Curves.easeOut,
// // // // // //         );
// // // // // //     });
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Container(
// // // // // //       height: MediaQuery.sizeOf(context).height * 0.65,
// // // // // //       decoration: const BoxDecoration(
// // // // // //         color: Color(0xFF1A2E45),
// // // // // //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// // // // // //       ),
// // // // // //       child: Column(
// // // // // //         children: [
// // // // // //           Container(
// // // // // //             width: 36,
// // // // // //             height: 4,
// // // // // //             margin: const EdgeInsets.symmetric(vertical: 10),
// // // // // //             decoration: BoxDecoration(
// // // // // //               color: Colors.white24,
// // // // // //               borderRadius: BorderRadius.circular(2),
// // // // // //             ),
// // // // // //           ),
// // // // // //           const Text(
// // // // // //             '💬 Chat',
// // // // // //             style: TextStyle(
// // // // // //               color: Colors.white,
// // // // // //               fontWeight: FontWeight.w800,
// // // // // //               fontSize: 16,
// // // // // //             ),
// // // // // //           ),
// // // // // //           const Divider(color: Colors.white12),
// // // // // //           Expanded(
// // // // // //             child: ListenableBuilder(
// // // // // //               listenable: widget.game,
// // // // // //               builder: (_, __) {
// // // // // //                 final msgs = widget.game.chatMessages;
// // // // // //                 return msgs.isEmpty
// // // // // //                     ? const Center(
// // // // // //                         child: Text(
// // // // // //                           'No messages yet',
// // // // // //                           style: TextStyle(color: Colors.white38),
// // // // // //                         ),
// // // // // //                       )
// // // // // //                     : ListView.builder(
// // // // // //                         controller: _scroll,
// // // // // //                         padding: const EdgeInsets.all(12),
// // // // // //                         itemCount: msgs.length,
// // // // // //                         itemBuilder: (_, i) {
// // // // // //                           final m = msgs[i];
// // // // // //                           final isMe = m.senderId == widget.myId;
// // // // // //                           final color =
// // // // // //                               _kChatColors[m.senderId.hashCode.abs() %
// // // // // //                                   _kChatColors.length];
// // // // // //                           return Padding(
// // // // // //                             padding: EdgeInsets.only(
// // // // // //                               bottom: 8,
// // // // // //                               left: isMe ? 48 : 0,
// // // // // //                               right: isMe ? 0 : 48,
// // // // // //                             ),
// // // // // //                             child: Column(
// // // // // //                               crossAxisAlignment: isMe
// // // // // //                                   ? CrossAxisAlignment.end
// // // // // //                                   : CrossAxisAlignment.start,
// // // // // //                               children: [
// // // // // //                                 if (!isMe)
// // // // // //                                   Padding(
// // // // // //                                     padding: const EdgeInsets.only(
// // // // // //                                       left: 4,
// // // // // //                                       bottom: 2,
// // // // // //                                     ),
// // // // // //                                     child: Text(
// // // // // //                                       m.senderName,
// // // // // //                                       style: TextStyle(
// // // // // //                                         color: color,
// // // // // //                                         fontSize: 11,
// // // // // //                                         fontWeight: FontWeight.w700,
// // // // // //                                       ),
// // // // // //                                     ),
// // // // // //                                   ),
// // // // // //                                 Container(
// // // // // //                                   padding: const EdgeInsets.symmetric(
// // // // // //                                     horizontal: 12,
// // // // // //                                     vertical: 8,
// // // // // //                                   ),
// // // // // //                                   decoration: BoxDecoration(
// // // // // //                                     color: isMe
// // // // // //                                         ? const Color(0xFFFFD60A)
// // // // // //                                         : color.withOpacity(0.18),
// // // // // //                                     borderRadius: BorderRadius.circular(16)
// // // // // //                                         .copyWith(
// // // // // //                                           bottomRight: isMe
// // // // // //                                               ? const Radius.circular(4)
// // // // // //                                               : null,
// // // // // //                                           bottomLeft: isMe
// // // // // //                                               ? null
// // // // // //                                               : const Radius.circular(4),
// // // // // //                                         ),
// // // // // //                                   ),
// // // // // //                                   child: Text(
// // // // // //                                     m.text,
// // // // // //                                     style: TextStyle(
// // // // // //                                       color: isMe
// // // // // //                                           ? const Color(0xFF0D1B2A)
// // // // // //                                           : Colors.white,
// // // // // //                                       fontWeight: isMe
// // // // // //                                           ? FontWeight.w700
// // // // // //                                           : FontWeight.w400,
// // // // // //                                     ),
// // // // // //                                   ),
// // // // // //                                 ),
// // // // // //                               ],
// // // // // //                             ),
// // // // // //                           );
// // // // // //                         },
// // // // // //                       );
// // // // // //               },
// // // // // //             ),
// // // // // //           ),
// // // // // //           Container(
// // // // // //             padding: EdgeInsets.fromLTRB(
// // // // // //               12,
// // // // // //               8,
// // // // // //               12,
// // // // // //               MediaQuery.viewInsetsOf(context).bottom + 12,
// // // // // //             ),
// // // // // //             color: const Color(0xFF1A2E45),
// // // // // //             child: Row(
// // // // // //               children: [
// // // // // //                 Expanded(
// // // // // //                   child: TextField(
// // // // // //                     controller: _ctrl,
// // // // // //                     style: const TextStyle(color: Colors.white),
// // // // // //                     textInputAction: TextInputAction.send,
// // // // // //                     onSubmitted: (_) => _send(),
// // // // // //                     decoration: InputDecoration(
// // // // // //                       hintText: 'Say something…',
// // // // // //                       hintStyle: const TextStyle(color: Colors.white38),
// // // // // //                       filled: true,
// // // // // //                       fillColor: Colors.white.withOpacity(0.07),
// // // // // //                       border: OutlineInputBorder(
// // // // // //                         borderRadius: BorderRadius.circular(24),
// // // // // //                         borderSide: BorderSide.none,
// // // // // //                       ),
// // // // // //                       contentPadding: const EdgeInsets.symmetric(
// // // // // //                         horizontal: 16,
// // // // // //                         vertical: 10,
// // // // // //                       ),
// // // // // //                       isDense: true,
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 const SizedBox(width: 8),
// // // // // //                 GestureDetector(
// // // // // //                   onTap: _send,
// // // // // //                   child: Container(
// // // // // //                     width: 44,
// // // // // //                     height: 44,
// // // // // //                     decoration: const BoxDecoration(
// // // // // //                       color: Color(0xFFFFD60A),
// // // // // //                       shape: BoxShape.circle,
// // // // // //                     ),
// // // // // //                     child: const Icon(
// // // // // //                       Icons.send_rounded,
// // // // // //                       color: Color(0xFF0D1B2A),
// // // // // //                       size: 20,
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                 ),
// // // // // //               ],
// // // // // //             ),
// // // // // //           ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // const _kChatColors = [
// // // // // //   Color(0xFF4ECDC4),
// // // // // //   Color(0xFFA855F7),
// // // // // //   Color(0xFFFF6B6B),
// // // // // //   Color(0xFF4ADE80),
// // // // // //   Color(0xFFFB923C),
// // // // // //   Color(0xFF60A5FA),
// // // // // //   Color(0xFFF472B6),
// // // // // //   Color(0xFFFFD60A),
// // // // // //   Color(0xFF34D399),
// // // // // //   Color(0xFFC084FC),
// // // // // // ];

// // // // // // // ── Paused overlay ────────────────────────────────────────────────────────────
// // // // // // class _PausedOverlay extends StatefulWidget {
// // // // // //   const _PausedOverlay({required this.onLeave});
// // // // // //   final VoidCallback onLeave;

// // // // // //   @override
// // // // // //   State<_PausedOverlay> createState() => _PausedOverlayState();
// // // // // // }

// // // // // // class _PausedOverlayState extends State<_PausedOverlay>
// // // // // //     with SingleTickerProviderStateMixin {
// // // // // //   late final AnimationController _pulse;

// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();
// // // // // //     _pulse = AnimationController(
// // // // // //       vsync: this,
// // // // // //       duration: const Duration(milliseconds: 1400),
// // // // // //     )..repeat(reverse: true);
// // // // // //   }

// // // // // //   @override
// // // // // //   void dispose() {
// // // // // //     _pulse.dispose();
// // // // // //     super.dispose();
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Dialog.fullscreen(
// // // // // //       backgroundColor: Colors.transparent,
// // // // // //       child: Scaffold(
// // // // // //         backgroundColor: Colors.transparent,
// // // // // //         body: Center(
// // // // // //           child: Padding(
// // // // // //             padding: const EdgeInsets.all(32),
// // // // // //             child: Column(
// // // // // //               mainAxisSize: MainAxisSize.min,
// // // // // //               children: [
// // // // // //                 AnimatedBuilder(
// // // // // //                   animation: _pulse,
// // // // // //                   builder: (_, child) =>
// // // // // //                       Opacity(opacity: 0.6 + _pulse.value * 0.4, child: child),
// // // // // //                   child: const Text('⏸', style: TextStyle(fontSize: 72)),
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 24),
// // // // // //                 const Text(
// // // // // //                   'Game Paused',
// // // // // //                   style: TextStyle(
// // // // // //                     color: Colors.white,
// // // // // //                     fontSize: 28,
// // // // // //                     fontWeight: FontWeight.w800,
// // // // // //                     letterSpacing: -0.5,
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 12),
// // // // // //                 const Text(
// // // // // //                   'The host stepped away and will\nreturn shortly.',
// // // // // //                   textAlign: TextAlign.center,
// // // // // //                   style: TextStyle(
// // // // // //                     color: Colors.white70,
// // // // // //                     fontSize: 16,
// // // // // //                     height: 1.5,
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 40),
// // // // // //                 OutlinedButton(
// // // // // //                   style: OutlinedButton.styleFrom(
// // // // // //                     foregroundColor: Colors.white,
// // // // // //                     side: const BorderSide(color: Colors.white38),
// // // // // //                     padding: const EdgeInsets.symmetric(
// // // // // //                       horizontal: 32,
// // // // // //                       vertical: 14,
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                   onPressed: widget.onLeave,
// // // // // //                   child: const Text('Leave for Now'),
// // // // // //                 ),
// // // // // //               ],
// // // // // //             ),
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // import 'dart:async';

// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // import 'package:go_router/go_router.dart';
// // // // // import 'package:jma3a/core/router/app_router.dart';
// // // // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // // // import 'package:jma3a/features/rooms/domain/room_entity.dart';
// // // // // import 'package:jma3a/features/settings/presentation/screen_security_service.dart';
// // // // // import 'package:provider/provider.dart';
// // // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // // import '../../../../../core/di/service_locator.dart';
// // // // // import '../../../../../core/extensions/context_ext.dart';
// // // // // import '../../../../../core/providers/auth_provider.dart';
// // // // // import '../../../../../core/router/route_names.dart';
// // // // // import '../../../../../core/services/realtime_service.dart';
// // // // // // import '../../../../../core/services/screen_security_service.dart';
// // // // // import '../../../../../core/theme/app_colors.dart';
// // // // // import '../../../../../shared/widgets/feedback/error_view.dart';
// // // // // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // // // // // import '../../engine/base_game_engine.dart';
// // // // // import '../../domain/tod_models.dart';
// // // // // import '../../tod_game_provider.dart';

// // // // // import '../../data/tod_repository.dart';
// // // // // import 'tod_card_screen.dart';
// // // // // import 'tod_end_screen.dart';
// // // // // import 'tod_loading_screen.dart';
// // // // // import 'tod_punishment_screen.dart';
// // // // // import '../widgets/tod_hud.dart';

// // // // // /// Entry point for an active Truth or Dare session.
// // // // // ///
// // // // // /// Responsibilities:
// // // // // ///  - Owns and scopes TodGameProvider for this session
// // // // // ///  - Wires RealtimeService callbacks → TodGameProvider
// // // // // ///  - Routes between loading / error / active / game-over screens
// // // // // ///  - Forwards game_state and player_action from the room Broadcast channel
// // // // // class TodGameScreen extends StatefulWidget {
// // // // //   const TodGameScreen({
// // // // //     super.key,
// // // // //     required this.roomId,
// // // // //     required this.config,
// // // // //     required this.playerIds,
// // // // //     required this.playerDisplayNames,
// // // // //     required this.packId,
// // // // //     required this.isOwner,
// // // // //     this.sessionId,
// // // // //     this.isModerator = false,
// // // // //     this.packCoverUrl,
// // // // //   });

// // // // //   final String roomId;
// // // // //   final GameConfig config;
// // // // //   final List<String> playerIds;
// // // // //   final Map<String, String> playerDisplayNames; // userId → displayName
// // // // //   final String packId;
// // // // //   final bool isOwner;
// // // // //   final String? sessionId;
// // // // //   final bool isModerator;
// // // // //   final String? packCoverUrl;

// // // // //   @override
// // // // //   State<TodGameScreen> createState() => _TodGameScreenState();
// // // // // }

// // // // // class _TodGameScreenState extends State<TodGameScreen> {
// // // // //   late final TodGameProvider _provider;

// // // // //   // Subscriptions to the room Broadcast channel
// // // // //   // (channel already open by RoomProvider — we just register callbacks)
// // // // //   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();

// // // // //     // Block screenshots/screen recording for the duration of gameplay —
// // // // //     // proof photos/videos and responses shouldn't be capturable.
// // // // //     ScreenSecurityService.instance.enable();
// // // // //     ScreenSecurityService.instance.enableScreenshotDetection(() {
// // // // //       // iOS can't block screenshots outright, only detect them — let the
// // // // //       // room know, Snapchat-style, since it can't be silently captured.
// // // // //       sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // // //         'type': 'screenshot_taken',
// // // // //         'user_id': context.read<AuthProvider>().currentUser?.id,
// // // // //       }).ignore();
// // // // //     });

// // // // //     final auth = context.read<AuthProvider>();
// // // // //     final user = auth.currentUser!;

// // // // //     _provider = TodGameProvider(
// // // // //       realtimeService: sl.realtimeService,
// // // // //       repository: TodRepository.instance,
// // // // //       currentUserId: user.id,
// // // // //       currentDisplayName: user.displayName ?? user.username ?? 'Player',
// // // // //       isModerator: widget.isModerator,
// // // // //     );

// // // // //     // ── Wire Broadcast callbacks ────────────────────────────────────────────
// // // // //     // The room channel is already subscribed by RoomProvider/LobbyScreen.
// // // // //     // TodGameScreen registers its own game-specific handlers for game_state
// // // // //     // and player_action by re-subscribing with extended handlers.
// // // // //     //
// // // // //     // We do this by using the RealtimeService._bcast pattern:
// // // // //     // The channel already has onGameState/onPlayerAction wired to no-ops
// // // // //     // in RoomProvider. We replace them here by storing callbacks and
// // // // //     // intercepting from the top-level channel via a dedicated subscription.
// // // // //     _wireRealtimeCallbacks();

// // // // //     if (widget.isOwner) {
// // // // //       final isPremium =
// // // // //           context.read<AuthProvider>().currentUser?.isPremium ?? false;
// // // // //       _provider.initAsOwner(
// // // // //         roomId: widget.roomId,
// // // // //         config: widget.config,
// // // // //         playerIds: widget.playerIds,
// // // // //         playerDisplayNames: widget.playerDisplayNames,
// // // // //         packId: widget.packId,
// // // // //         isPremium: isPremium,
// // // // //         packCoverUrl: widget.packCoverUrl,
// // // // //       );
// // // // //     } else {
// // // // //       _provider.initAsFollower(
// // // // //         roomId: widget.roomId,
// // // // //         config: widget.config,
// // // // //         sessionId: widget.sessionId,
// // // // //         packCoverUrl: widget.packCoverUrl,
// // // // //       );
// // // // //     }
// // // // //   }

// // // // //   @override
// // // // //   void dispose() {
// // // // //     ScreenSecurityService.instance.disable();
// // // // //     _statusSub?.cancel();
// // // // //     // Re-subscribe the room channel with lobby-mode handlers so the lobby
// // // // //     // (which is still on the stack) continues to receive events after we pop.
// // // // //     // DO NOT fully unsubscribe — that would cut off followers still in-game.
// // // // //     sl.realtimeService
// // // // //         .subscribe(
// // // // //           roomId: widget.roomId,
// // // // //           onGameState: (_) {},
// // // // //           onPlayerAction: (_) {},
// // // // //           onSyncRequest: (_) {},
// // // // //           onGameStarted: (_) {},
// // // // //           onGameEnded: (_) {},
// // // // //           onRoomEvent: (_) {},
// // // // //           onChatMessage: (_) {},
// // // // //           onModeration: (_) {},
// // // // //           onSettingsChange: (_) {},
// // // // //           onPresenceSync: (_) {},
// // // // //           onPresenceJoin: (_) {},
// // // // //           onPresenceLeave: (_) {},
// // // // //           onStatusChange: (_) {},
// // // // //         )
// // // // //         .ignore();
// // // // //     _provider.dispose();
// // // // //     super.dispose();
// // // // //   }

// // // // //   /// Wire game-specific callbacks into the existing room channel.
// // // // //   ///
// // // // //   /// Strategy: re-subscribe to the room channel with updated handlers that
// // // // //   /// forward game_state and player_action to this provider.
// // // // //   /// The channel is already open; we track callbacks via a thin interceptor.
// // // // //   void _wireRealtimeCallbacks() {
// // // // //     // Listen to channel status changes for reconnection awareness
// // // // //     _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
// // // // //       status,
// // // // //     ) {
// // // // //       if (status == RealtimeSubscribeStatus.subscribed &&
// // // // //           !_provider.hasSyncedState) {
// // // // //         // Channel reconnected — request state sync
// // // // //         sl.realtimeService.broadcastSyncRequest(
// // // // //           widget.roomId,
// // // // //           context.read<AuthProvider>().currentUser!.id,
// // // // //           0,
// // // // //         );
// // // // //       }
// // // // //     });

// // // // //     // Re-subscribe with game handlers added.
// // // // //     // This safely replaces the channel subscription with game callbacks.
// // // // //     // (No-op handlers in RoomProvider are replaced with active ones here.)
// // // // //     _resubscribeWithGameHandlers();
// // // // //   }

// // // // //   void _resubscribeWithGameHandlers() {
// // // // //     final userId = context.read<AuthProvider>().currentUser!.id;

// // // // //     // Unsubscribe existing channel and re-subscribe with game callbacks merged
// // // // //     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
// // // // //       sl.realtimeService.subscribe(
// // // // //         roomId: widget.roomId,
// // // // //         // ── Game-specific handlers ─────────────────────────────────────────
// // // // //         onGameState: (p) => _provider.onStateBroadcast(p),
// // // // //         onPlayerAction: (p) => _provider.onPlayerAction(p),
// // // // //         onSyncRequest: (p) => _provider.onSyncRequest(p),
// // // // //         onGameStarted: (_) {},
// // // // //         onGameEnded: (p) {
// // // // //           // Admin ended the game — take everyone back to the lobby
// // // // //           if (mounted) {
// // // // //             ScaffoldMessenger.of(context).showSnackBar(
// // // // //               const SnackBar(content: Text('The host ended the game')),
// // // // //             );
// // // // //             // Pop back to lobby (the LobbyScreen is still on the stack)
// // // // //             if (context.canPop())
// // // // //               context.pop();
// // // // //             else
// // // // //               context.go(RouteNames.home);
// // // // //           }
// // // // //         },
// // // // //         // ── Room lifecycle (passthrough — RoomProvider is disposed) ─────────
// // // // //         onRoomEvent: (p) {
// // // // //           final type = p['type'] as String?;
// // // // //           if (type == 'screenshot_taken') {
// // // // //             final shooterId = p['user_id'] as String?;
// // // // //             final myId = context.read<AuthProvider>().currentUser?.id;
// // // // //             if (shooterId != null && shooterId != myId && mounted) {
// // // // //               ScaffoldMessenger.of(context).showSnackBar(
// // // // //                 SnackBar(
// // // // //                   content: Text(
// // // // //                     '📸 ${widget.playerDisplayNames[shooterId] ?? 'Someone'} took a screenshot',
// // // // //                   ),
// // // // //                   backgroundColor: Colors.black87,
// // // // //                 ),
// // // // //               );
// // // // //             }
// // // // //             return;
// // // // //           }
// // // // //           if (type == 'player_left' && mounted) {
// // // // //             final name = p['display_name'] as String? ?? 'A player';
// // // // //             final forGood = p['for_good'] as bool? ?? true;
// // // // //             final leavingId = p['user_id'] as String?;
// // // // //             final returnMins = p['return_mins'] as int?;
// // // // //             if (leavingId != null && widget.isOwner) {
// // // // //               _provider.markPlayerAway(leavingId, forGood: forGood);
// // // // //               // Auto-quit if owner is now the only active player
// // // // //               final activePlayers =
// // // // //                   _provider.state?.playerOrder
// // // // //                       .where((id) => !_provider.awayPlayerIds.contains(id))
// // // // //                       .toList() ??
// // // // //                   [];
// // // // //               if (activePlayers.length <= 1 && activePlayers.isNotEmpty) {
// // // // //                 WidgetsBinding.instance.addPostFrameCallback((_) async {
// // // // //                   if (!mounted) return;
// // // // //                   await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // // //                     'type': 'game_ended',
// // // // //                     'reason': 'all_players_left',
// // // // //                   });
// // // // //                   await sl.roomRepository.updateStatus(
// // // // //                     widget.roomId,
// // // // //                     RoomStatus.waiting,
// // // // //                   );
// // // // //                   if (mounted) {
// // // // //                     ScaffoldMessenger.of(context).showSnackBar(
// // // // //                       const SnackBar(
// // // // //                         content: Text('All players left — game ended'),
// // // // //                         backgroundColor: Colors.orange,
// // // // //                       ),
// // // // //                     );
// // // // //                     await Future.delayed(const Duration(milliseconds: 800));
// // // // //                     if (mounted) {
// // // // //                       if (context.canPop())
// // // // //                         context.pop();
// // // // //                       else
// // // // //                         context.go('/home/room/${widget.roomId}');
// // // // //                     }
// // // // //                   }
// // // // //                 });
// // // // //               }
// // // // //             }
// // // // //             final msg = forGood
// // // // //                 ? '👋 $name left the game'
// // // // //                 : '🕐 $name stepped away (${returnMins != null ? 'back in ${returnMins}m' : 'coming back'})';
// // // // //             ScaffoldMessenger.of(context).showSnackBar(
// // // // //               SnackBar(
// // // // //                 content: Text(msg),
// // // // //                 backgroundColor: forGood
// // // // //                     ? Colors.red.shade700
// // // // //                     : Colors.orange.shade700,
// // // // //                 duration: const Duration(seconds: 4),
// // // // //               ),
// // // // //             );
// // // // //             return;
// // // // //           }
// // // // //           if (type == 'ownership_transferred' && mounted) {
// // // // //             final myId = context.read<AuthProvider>().currentUser?.id;
// // // // //             final newOwnerId = p['new_owner_id'] as String?;
// // // // //             if (newOwnerId == myId) {
// // // // //               ScaffoldMessenger.of(context).showSnackBar(
// // // // //                 const SnackBar(
// // // // //                   content: Text('👑 You are now the game host!'),
// // // // //                   backgroundColor: Colors.purple,
// // // // //                 ),
// // // // //               );
// // // // //             }
// // // // //             return;
// // // // //           }
// // // // //           if (type == 'game_ended' && mounted) {
// // // // //             final reason = p['reason'] as String?;
// // // // //             if (reason == 'host_quit_to_lobby') {
// // // // //               WidgetsBinding.instance.addPostFrameCallback((_) {
// // // // //                 if (!mounted) return;
// // // // //                 ScaffoldMessenger.of(context).showSnackBar(
// // // // //                   const SnackBar(
// // // // //                     content: Text('🔄 Host ended the game — back to lobby'),
// // // // //                     duration: Duration(seconds: 3),
// // // // //                   ),
// // // // //                 );
// // // // //                 if (context.canPop()) {
// // // // //                   context.pop();
// // // // //                 } else {
// // // // //                   context.go('/home/room/${widget.roomId}');
// // // // //                 }
// // // // //               });
// // // // //             }
// // // // //             return;
// // // // //           }
// // // // //           if (type == 'tod_ready_count') {
// // // // //             final ids = (p['ready_user_ids'] as List?)?.cast<String>() ?? [];
// // // // //             _provider.onReadyCountUpdate(ids);
// // // // //             return;
// // // // //           }
// // // // //           if ((type == 'room_closed' || type == 'owner_left') && mounted) {
// // // // //             WidgetsBinding.instance.addPostFrameCallback((_) {
// // // // //               if (mounted) {
// // // // //                 showDialog(
// // // // //                   context: context,
// // // // //                   barrierDismissible: false,
// // // // //                   builder: (ctx2) => AlertDialog(
// // // // //                     title: const Text('Room Closed'),
// // // // //                     content: const Text('The host closed the room.'),
// // // // //                     actions: [
// // // // //                       FilledButton(
// // // // //                         onPressed: () {
// // // // //                           Navigator.of(ctx2).pop();
// // // // //                           AppRouter.router.go(RouteNames.home);
// // // // //                         },
// // // // //                         child: const Text('OK'),
// // // // //                       ),
// // // // //                     ],
// // // // //                   ),
// // // // //                 );
// // // // //               } else {
// // // // //                 AppRouter.router.go(RouteNames.home);
// // // // //               }
// // // // //             });
// // // // //           }
// // // // //         },
// // // // //         onChatMessage: (p) {
// // // // //           final msg = TodChatMsg(
// // // // //             senderId: p['user_id'] as String? ?? '',
// // // // //             senderName: p['display_name'] as String? ?? 'Player',
// // // // //             text: p['content'] as String? ?? '',
// // // // //             ts: DateTime.fromMillisecondsSinceEpoch(
// // // // //               (p['ts'] as num?)?.toInt() ??
// // // // //                   DateTime.now().millisecondsSinceEpoch,
// // // // //             ),
// // // // //           );
// // // // //           _provider.addChatMessage(msg);
// // // // //         },
// // // // //         onModeration: (p) => _handleModerationEvent(p),
// // // // //         onSettingsChange: (_) {},
// // // // //         // ── Presence ──────────────────────────────────────────────────────
// // // // //         onPresenceSync: (_) {},
// // // // //         onPresenceJoin: (_) {},
// // // // //         onPresenceLeave: (_) {},
// // // // //         onStatusChange: (status) {
// // // // //           if (!mounted) return;
// // // // //           if (status == RealtimeSubscribeStatus.subscribed &&
// // // // //               !_provider.hasSyncedState) {
// // // // //             sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
// // // // //           }
// // // // //         },
// // // // //       );
// // // // //     });
// // // // //   }

// // // // //   void _handleModerationEvent(Map<String, dynamic> p) {
// // // // //     final type = p['type'] as String?;
// // // // //     final targetId = p['target_user_id'] as String?;
// // // // //     final currentId = context.read<AuthProvider>().currentUser?.id;

// // // // //     // If kicked or banned, navigate back to lobby
// // // // //     if ((type == 'kick' || type == 'ban') && targetId == currentId) {
// // // // //       if (mounted) {
// // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // //           const SnackBar(content: Text('You were removed from the room')),
// // // // //         );
// // // // //         context.go(RouteNames.home);
// // // // //       }
// // // // //     }
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return ChangeNotifierProvider.value(
// // // // //       value: _provider,
// // // // //       child: Consumer<TodGameProvider>(
// // // // //         builder: (ctx, game, _) => _build(ctx, game),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Widget _build(BuildContext ctx, TodGameProvider game) {
// // // // //     if (game.loadState == TodLoadState.loading) {
// // // // //       return const TodLoadingScreen();
// // // // //     }

// // // // //     if (game.loadState == TodLoadState.error) {
// // // // //       return Scaffold(
// // // // //         appBar: AppBar(
// // // // //           leading: BackButton(
// // // // //             onPressed: () async {
// // // // //               if (widget.isOwner) {
// // // // //                 // Owner leaving game → end game for everyone, go back to lobby
// // // // //                 try {
// // // // //                   await sl.realtimeService.broadcastGameEnded(widget.roomId, {
// // // // //                     'reason': 'host_left',
// // // // //                   });
// // // // //                   await sl.roomRepository.updateStatus(
// // // // //                     widget.roomId,
// // // // //                     RoomStatus.waiting,
// // // // //                   );
// // // // //                 } catch (_) {}
// // // // //               }
// // // // //               if (ctx.mounted) ctx.go(RouteNames.home);
// // // // //             },
// // // // //           ),
// // // // //         ),
// // // // //         body: ErrorView(
// // // // //           message: game.error ?? 'Failed to load game',
// // // // //           onRetry: () => ctx.go(RouteNames.home),
// // // // //         ),
// // // // //       );
// // // // //     }

// // // // //     if (game.loadState == TodLoadState.gameOver ||
// // // // //         (game.state?.isOver ?? false)) {
// // // // //       return TodEndScreen(
// // // // //         state: game.state!,
// // // // //         displayNames: widget.playerDisplayNames,
// // // // //         onLeave: () => ctx.go(RouteNames.home),
// // // // //       );
// // // // //     }

// // // // //     final state = game.state;
// // // // //     if (state == null) return const TodLoadingScreen();

// // // // //     return _TodGameScaffold(
// // // // //       state: state,
// // // // //       game: game,
// // // // //       displayNames: widget.playerDisplayNames,
// // // // //       roomId: widget.roomId,
// // // // //       isOwner: widget.isOwner,
// // // // //     );
// // // // //   }
// // // // // }

// // // // // // ── Scaffold with history support ─────────────────────────────────────────────

// // // // // class _TodGameScaffold extends StatefulWidget {
// // // // //   const _TodGameScaffold({
// // // // //     required this.state,
// // // // //     required this.game,
// // // // //     required this.displayNames,
// // // // //     required this.roomId,
// // // // //     required this.isOwner,
// // // // //   });
// // // // //   final TodState state;
// // // // //   final TodGameProvider game;
// // // // //   final Map<String, String> displayNames;
// // // // //   final String roomId;
// // // // //   final bool isOwner;
// // // // //   @override
// // // // //   State<_TodGameScaffold> createState() => _TodGameScaffoldState();
// // // // // }

// // // // // class _TodGameScaffoldState extends State<_TodGameScaffold> {
// // // // //   bool _showHistory = false;
// // // // //   bool _showChat = false;
// // // // //   int _unreadChat = 0;
// // // // //   bool _isNavigatingAway = false;

// // // // //   void _navigateAway(BuildContext ctx, String location) {
// // // // //     _isNavigatingAway = true;
// // // // //     if (ctx.canPop()) {
// // // // //       ctx.pop();
// // // // //     } else {
// // // // //       ctx.go(location);
// // // // //     }
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final state = widget.state;
// // // // //     final game = widget.game;

// // // // //     if (_showHistory) {
// // // // //       return Scaffold(
// // // // //         appBar: AppBar(
// // // // //           leading: BackButton(
// // // // //             onPressed: () => setState(() => _showHistory = false),
// // // // //           ),
// // // // //           title: Text('History (${state.history.length} rounds)'),
// // // // //         ),
// // // // //         body: _HistoryPanel(
// // // // //           history: state.history,
// // // // //           displayNames: widget.displayNames,
// // // // //         ),
// // // // //       );
// // // // //     }

// // // // //     return PopScope(
// // // // //       canPop: false,
// // // // //       onPopInvoked: (_) {
// // // // //         if (_isNavigatingAway) return;
// // // // //         WidgetsBinding.instance.addPostFrameCallback(
// // // // //           (_) => _showLeaveDialog(context, game, state),
// // // // //         );
// // // // //       },
// // // // //       child: Scaffold(
// // // // //         appBar: AppBar(
// // // // //           automaticallyImplyLeading: false,
// // // // //           title: const Text(''),
// // // // //           leading: IconButton(
// // // // //             icon: const Icon(Icons.arrow_back),
// // // // //             onPressed: () => _showLeaveDialog(context, game, state),
// // // // //           ),
// // // // //           actions: [
// // // // //             // Chat button with unread badge
// // // // //             Consumer<TodGameProvider>(
// // // // //               builder: (_, g, __) => Stack(
// // // // //                 alignment: Alignment.topRight,
// // // // //                 children: [
// // // // //                   IconButton(
// // // // //                     icon: const Icon(Icons.chat_bubble_outline_rounded),
// // // // //                     onPressed: () {
// // // // //                       g.clearUnreadChat();
// // // // //                       showModalBottomSheet(
// // // // //                         context: context,
// // // // //                         isScrollControlled: true,
// // // // //                         backgroundColor: Colors.transparent,
// // // // //                         builder: (_) =>
// // // // //                             _InGameChatSheet(game: g, myId: g.currentUserId),
// // // // //                       );
// // // // //                     },
// // // // //                   ),
// // // // //                   if (g.unreadChat > 0)
// // // // //                     Positioned(
// // // // //                       top: 8,
// // // // //                       right: 8,
// // // // //                       child: Container(
// // // // //                         width: 8,
// // // // //                         height: 8,
// // // // //                         decoration: const BoxDecoration(
// // // // //                           color: Colors.red,
// // // // //                           shape: BoxShape.circle,
// // // // //                         ),
// // // // //                       ),
// // // // //                     ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //             if (state.history.isNotEmpty)
// // // // //               IconButton(
// // // // //                 icon: const Icon(Icons.history_rounded),
// // // // //                 tooltip: 'History',
// // // // //                 onPressed: () => setState(() => _showHistory = true),
// // // // //               ),
// // // // //           ],
// // // // //         ),
// // // // //         body: SafeArea(
// // // // //           child: Column(
// // // // //             children: [
// // // // //               TodHud(
// // // // //                 state: state,
// // // // //                 game: game,
// // // // //                 displayNames: widget.displayNames,
// // // // //               ),
// // // // //               Expanded(
// // // // //                 child: AnimatedSwitcher(
// // // // //                   duration: const Duration(milliseconds: 300),
// // // // //                   transitionBuilder: (child, anim) => FadeTransition(
// // // // //                     opacity: anim,
// // // // //                     child: SlideTransition(
// // // // //                       position:
// // // // //                           Tween<Offset>(
// // // // //                             begin: const Offset(0, 0.05),
// // // // //                             end: Offset.zero,
// // // // //                           ).animate(
// // // // //                             CurvedAnimation(
// // // // //                               parent: anim,
// // // // //                               curve: Curves.easeOutCubic,
// // // // //                             ),
// // // // //                           ),
// // // // //                       child: child,
// // // // //                     ),
// // // // //                   ),
// // // // //                   child: KeyedSubtree(
// // // // //                     key: ValueKey('${state.phase}-${state.currentPlayerId}'),
// // // // //                     child: _phaseWidget(
// // // // //                       context,
// // // // //                       game,
// // // // //                       widget.displayNames,
// // // // //                       state,
// // // // //                     ),
// // // // //                   ),
// // // // //                 ),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //         ),
// // // // //       ), // end Scaffold (PopScope child)
// // // // //     ); // end PopScope
// // // // //   }

// // // // //   Future<void> _showLeaveDialog(
// // // // //     BuildContext ctx,
// // // // //     TodGameProvider game,
// // // // //     TodState state,
// // // // //   ) async {
// // // // //     if (!ctx.mounted) return;
// // // // //     final isOwner = widget.isOwner;
// // // // //     final myUserId = game.currentUserId;
// // // // //     final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

// // // // //     if (isOwner) {
// // // // //       final confirmed = await showDialog<bool>(
// // // // //         context: ctx,
// // // // //         builder: (dCtx) => AlertDialog(
// // // // //           title: const Text('Quit Game?'),
// // // // //           content: const Text(
// // // // //             'The game will end for everyone and all players will return to the lobby.',
// // // // //           ),
// // // // //           actions: [
// // // // //             TextButton(
// // // // //               onPressed: () => Navigator.of(dCtx).pop(false),
// // // // //               child: const Text('Cancel'),
// // // // //             ),
// // // // //             FilledButton(
// // // // //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // // // //               onPressed: () => Navigator.of(dCtx).pop(true),
// // // // //               child: const Text('End Game for Everyone'),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       );
// // // // //       if (confirmed != true || !ctx.mounted) return;

// // // // //       try {
// // // // //         await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // // //           'type': 'game_ended',
// // // // //           'reason': 'host_quit_to_lobby',
// // // // //         });
// // // // //         await Future.delayed(const Duration(milliseconds: 400));
// // // // //         await sl.roomRepository.updateStatus(widget.roomId, RoomStatus.waiting);
// // // // //       } catch (_) {}
// // // // //       if (ctx.mounted) {
// // // // //         _isNavigatingAway = true;
// // // // //         if (ctx.canPop()) {
// // // // //           ctx.pop();
// // // // //         } else {
// // // // //           ctx.go('/home/room/${widget.roomId}');
// // // // //         }
// // // // //       }
// // // // //     } else {
// // // // //       // ── Player options ───────────────────────────────────────────────────
// // // // //       final returnMins = isPremium ? 10 : 5;
// // // // //       final choice = await showDialog<String>(
// // // // //         context: ctx,
// // // // //         builder: (_) => AlertDialog(
// // // // //           title: const Text('Leave Game?'),
// // // // //           content: Text(
// // // // //             "If you'll return, your turns will be skipped until you're "
// // // // //             'back. You have $returnMins minutes — after that your seat '
// // // // //             'is lost.',
// // // // //           ),
// // // // //           actions: [
// // // // //             TextButton(
// // // // //               onPressed: () => Navigator.pop(ctx, 'cancel'),
// // // // //               child: const Text('Stay'),
// // // // //             ),
// // // // //             FilledButton.tonal(
// // // // //               onPressed: () => Navigator.pop(ctx, 'return'),
// // // // //               child: Text("I'll Return ($returnMins min)"),
// // // // //             ),
// // // // //             FilledButton(
// // // // //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // // // //               onPressed: () => Navigator.pop(ctx, 'definitive'),
// // // // //               child: const Text('Leave for Good'),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       );
// // // // //       if (choice == null || choice == 'cancel' || !ctx.mounted) return;

// // // // //       final displayName = widget.displayNames[myUserId] ?? 'A player';

// // // // //       if (choice == 'return') {
// // // // //         try {
// // // // //           await sl.roomRepository.setMemberAway(
// // // // //             widget.roomId,
// // // // //             myUserId,
// // // // //             away: true,
// // // // //           );
// // // // //           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // // //             'type': 'player_left',
// // // // //             'user_id': myUserId,
// // // // //             'display_name': displayName,
// // // // //             'for_good': false,
// // // // //             'return_mins': returnMins,
// // // // //           });
// // // // //         } catch (_) {}
// // // // //         if (ctx.mounted) {
// // // // //           ScaffoldMessenger.of(ctx).showSnackBar(
// // // // //             SnackBar(
// // // // //               content: Text(
// // // // //                 "You'll be back in $returnMins min — seat reserved",
// // // // //               ),
// // // // //               backgroundColor: Colors.orange.shade700,
// // // // //               duration: const Duration(seconds: 3),
// // // // //             ),
// // // // //           );
// // // // //           await Future.delayed(const Duration(milliseconds: 800));
// // // // //           if (ctx.mounted) {
// // // // //             _isNavigatingAway = true;
// // // // //             ctx.go('/home/room/${widget.roomId}');
// // // // //           }
// // // // //         }
// // // // //       } else {
// // // // //         // Leave for good
// // // // //         try {
// // // // //           await sl.roomRepository.setMemberDefinitiveLeave(
// // // // //             widget.roomId,
// // // // //             myUserId,
// // // // //           );
// // // // //           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // // //             'type': 'player_left',
// // // // //             'user_id': myUserId,
// // // // //             'display_name': displayName,
// // // // //             'for_good': true,
// // // // //           });
// // // // //         } catch (_) {}
// // // // //         if (ctx.mounted) {
// // // // //           // Check if admin is now alone — if so, admin auto-quits game
// // // // //           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // // //             'type': 'check_auto_quit',
// // // // //             'user_id': myUserId,
// // // // //           });
// // // // //           ctx.go('/home/room/${widget.roomId}');
// // // // //         }
// // // // //       }
// // // // //     }
// // // // //   }

// // // // //   Widget _phaseWidget(
// // // // //     BuildContext ctx,
// // // // //     TodGameProvider game,
// // // // //     Map<String, String> displayNames,
// // // // //     TodState state,
// // // // //   ) {
// // // // //     return switch (state.phase) {
// // // // //       TodTurnPhase.punishmentVoting => TodPunishmentScreen(
// // // // //         state: state,
// // // // //         game: game,
// // // // //         displayNames: widget.displayNames,
// // // // //       ),
// // // // //       _ => TodCardScreen(
// // // // //         state: state,
// // // // //         game: game,
// // // // //         displayNames: widget.displayNames,
// // // // //       ),
// // // // //     };
// // // // //   }
// // // // // }

// // // // // // ── History panel ─────────────────────────────────────────────────────────────

// // // // // class _HistoryPanel extends StatelessWidget {
// // // // //   const _HistoryPanel({required this.history, required this.displayNames});
// // // // //   final List<TodRoundRecord> history;
// // // // //   final Map<String, String> displayNames;

// // // // //   String _name(String id) =>
// // // // //       displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final theme = context.theme;
// // // // //     if (history.isEmpty) {
// // // // //       return const Center(child: Text('No rounds completed yet.'));
// // // // //     }
// // // // //     return ListView.builder(
// // // // //       padding: const EdgeInsets.all(12),
// // // // //       itemCount: history.length,
// // // // //       itemBuilder: (_, i) {
// // // // //         final round = history[history.length - 1 - i]; // newest first
// // // // //         final reactTally = <String, int>{};
// // // // //         for (final r in round.reactions) {
// // // // //           reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
// // // // //         }
// // // // //         return Card(
// // // // //           margin: const EdgeInsets.only(bottom: 10),
// // // // //           child: ExpansionTile(
// // // // //             leading: CircleAvatar(
// // // // //               backgroundColor: theme.colorScheme.primaryContainer,
// // // // //               child: Text(
// // // // //                 '${round.roundNumber}',
// // // // //                 style: theme.textTheme.labelLarge,
// // // // //               ),
// // // // //             ),
// // // // //             title: Text(
// // // // //               _name(round.playerId),
// // // // //               style: theme.textTheme.bodyMedium?.copyWith(
// // // // //                 fontWeight: FontWeight.w700,
// // // // //               ),
// // // // //             ),
// // // // //             subtitle: Text(
// // // // //               round.card != null
// // // // //                   ? '${round.card!.type == TodCardType.truth ? "Truth" : "Dare"}: ${round.card!.content}'
// // // // //                   : 'Skipped',
// // // // //               maxLines: 1,
// // // // //               overflow: TextOverflow.ellipsis,
// // // // //               style: theme.textTheme.bodySmall,
// // // // //             ),
// // // // //             children: [
// // // // //               Padding(
// // // // //                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
// // // // //                 child: Column(
// // // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // // //                   children: [
// // // // //                     // Card content
// // // // //                     if (round.card != null)
// // // // //                       Container(
// // // // //                         width: double.infinity,
// // // // //                         padding: const EdgeInsets.all(10),
// // // // //                         decoration: BoxDecoration(
// // // // //                           color: round.card!.type == TodCardType.truth
// // // // //                               ? Colors.blue.withOpacity(0.08)
// // // // //                               : Colors.orange.withOpacity(0.08),
// // // // //                           borderRadius: BorderRadius.circular(8),
// // // // //                         ),
// // // // //                         child: Text(
// // // // //                           round.card!.content,
// // // // //                           style: theme.textTheme.bodyMedium,
// // // // //                         ),
// // // // //                       ),
// // // // //                     // Response
// // // // //                     if (round.response.isNotEmpty) ...[
// // // // //                       const SizedBox(height: 8),
// // // // //                       Row(
// // // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // // //                         children: [
// // // // //                           const Text('💬 ', style: TextStyle(fontSize: 14)),
// // // // //                           Expanded(
// // // // //                             child: Text(
// // // // //                               '"${round.response}"',
// // // // //                               style: theme.textTheme.bodySmall?.copyWith(
// // // // //                                 fontStyle: FontStyle.italic,
// // // // //                               ),
// // // // //                             ),
// // // // //                           ),
// // // // //                         ],
// // // // //                       ),
// // // // //                     ],
// // // // //                     // Votes
// // // // //                     if (round.voteCount > 0) ...[
// // // // //                       const SizedBox(height: 6),
// // // // //                       Text(
// // // // //                         '👍 ${round.voteCount} vote${round.voteCount != 1 ? "s" : ""}',
// // // // //                         style: theme.textTheme.bodySmall?.copyWith(
// // // // //                           color: theme.colorScheme.primary,
// // // // //                           fontWeight: FontWeight.w600,
// // // // //                         ),
// // // // //                       ),
// // // // //                     ],
// // // // //                     // Proof — history NEVER shows the actual photo/video,
// // // // //                     // only whether one existed and who watched it.
// // // // //                     if (round.hadProof) ...[
// // // // //                       const SizedBox(height: 8),
// // // // //                       _ProofWatchedBadge(watchedBy: round.proofWatchedBy),
// // // // //                     ],
// // // // //                     // Reactions
// // // // //                     if (reactTally.isNotEmpty) ...[
// // // // //                       const SizedBox(height: 8),
// // // // //                       Wrap(
// // // // //                         spacing: 6,
// // // // //                         runSpacing: 4,
// // // // //                         children: reactTally.entries
// // // // //                             .map(
// // // // //                               (e) => Container(
// // // // //                                 padding: const EdgeInsets.symmetric(
// // // // //                                   horizontal: 8,
// // // // //                                   vertical: 3,
// // // // //                                 ),
// // // // //                                 decoration: BoxDecoration(
// // // // //                                   color:
// // // // //                                       theme.colorScheme.surfaceContainerHighest,
// // // // //                                   borderRadius: BorderRadius.circular(16),
// // // // //                                 ),
// // // // //                                 child: Text(
// // // // //                                   '${e.key} ${e.value}',
// // // // //                                   style: const TextStyle(fontSize: 13),
// // // // //                                 ),
// // // // //                               ),
// // // // //                             )
// // // // //                             .toList(),
// // // // //                       ),
// // // // //                     ],
// // // // //                   ],
// // // // //                 ),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //         );
// // // // //       },
// // // // //     );
// // // // //   }
// // // // // }

// // // // // // Proof existed for this round — history shows only whether/who watched
// // // // // // it, never the actual photo or video (that's only ever live during the
// // // // // // turn itself, see TodState.turnProofUrl).
// // // // // class _ProofWatchedBadge extends StatelessWidget {
// // // // //   const _ProofWatchedBadge({required this.watchedBy});
// // // // //   final List<String> watchedBy;

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final watched = watchedBy.isNotEmpty;
// // // // //     return Container(
// // // // //       height: 36,
// // // // //       padding: const EdgeInsets.symmetric(horizontal: 10),
// // // // //       decoration: BoxDecoration(
// // // // //         color: Colors.grey.shade200,
// // // // //         borderRadius: BorderRadius.circular(8),
// // // // //       ),
// // // // //       alignment: Alignment.centerLeft,
// // // // //       child: Row(
// // // // //         mainAxisSize: MainAxisSize.min,
// // // // //         children: [
// // // // //           Icon(
// // // // //             watched ? Icons.visibility_outlined : Icons.visibility_off_outlined,
// // // // //             size: 16,
// // // // //             color: Colors.grey.shade600,
// // // // //           ),
// // // // //           const SizedBox(width: 6),
// // // // //           Text(
// // // // //             watched
// // // // //                 ? 'Proof watched by ${watchedBy.length}'
// // // // //                 : 'Proof sent — not watched',
// // // // //             style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // // ── In-game chat sheet ─────────────────────────────────────────────────────────
// // // // // class _InGameChatSheet extends StatefulWidget {
// // // // //   const _InGameChatSheet({required this.game, required this.myId});
// // // // //   final TodGameProvider game;
// // // // //   final String myId;
// // // // //   @override
// // // // //   State<_InGameChatSheet> createState() => _InGameChatSheetState();
// // // // // }

// // // // // class _InGameChatSheetState extends State<_InGameChatSheet> {
// // // // //   final _ctrl = TextEditingController();
// // // // //   final _scroll = ScrollController();
// // // // //   @override
// // // // //   void dispose() {
// // // // //     _ctrl.dispose();
// // // // //     _scroll.dispose();
// // // // //     super.dispose();
// // // // //   }

// // // // //   void _send() {
// // // // //     final t = _ctrl.text.trim();
// // // // //     if (t.isEmpty) return;
// // // // //     widget.game.sendChat(t);
// // // // //     _ctrl.clear();
// // // // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // // // //       if (_scroll.hasClients)
// // // // //         _scroll.animateTo(
// // // // //           _scroll.position.maxScrollExtent,
// // // // //           duration: 200.ms,
// // // // //           curve: Curves.easeOut,
// // // // //         );
// // // // //     });
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Container(
// // // // //       height: MediaQuery.sizeOf(context).height * 0.65,
// // // // //       decoration: const BoxDecoration(
// // // // //         color: Color(0xFF1A2E45),
// // // // //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// // // // //       ),
// // // // //       child: Column(
// // // // //         children: [
// // // // //           Container(
// // // // //             width: 36,
// // // // //             height: 4,
// // // // //             margin: const EdgeInsets.symmetric(vertical: 10),
// // // // //             decoration: BoxDecoration(
// // // // //               color: Colors.white24,
// // // // //               borderRadius: BorderRadius.circular(2),
// // // // //             ),
// // // // //           ),
// // // // //           const Text(
// // // // //             '💬 Chat',
// // // // //             style: TextStyle(
// // // // //               color: Colors.white,
// // // // //               fontWeight: FontWeight.w800,
// // // // //               fontSize: 16,
// // // // //             ),
// // // // //           ),
// // // // //           const Divider(color: Colors.white12),
// // // // //           Expanded(
// // // // //             child: ListenableBuilder(
// // // // //               listenable: widget.game,
// // // // //               builder: (_, __) {
// // // // //                 final msgs = widget.game.chatMessages;
// // // // //                 return msgs.isEmpty
// // // // //                     ? const Center(
// // // // //                         child: Text(
// // // // //                           'No messages yet',
// // // // //                           style: TextStyle(color: Colors.white38),
// // // // //                         ),
// // // // //                       )
// // // // //                     : ListView.builder(
// // // // //                         controller: _scroll,
// // // // //                         padding: const EdgeInsets.all(12),
// // // // //                         itemCount: msgs.length,
// // // // //                         itemBuilder: (_, i) {
// // // // //                           final m = msgs[i];
// // // // //                           final isMe = m.senderId == widget.myId;
// // // // //                           final color =
// // // // //                               _kChatColors[m.senderId.hashCode.abs() %
// // // // //                                   _kChatColors.length];
// // // // //                           return Padding(
// // // // //                             padding: EdgeInsets.only(
// // // // //                               bottom: 8,
// // // // //                               left: isMe ? 48 : 0,
// // // // //                               right: isMe ? 0 : 48,
// // // // //                             ),
// // // // //                             child: Column(
// // // // //                               crossAxisAlignment: isMe
// // // // //                                   ? CrossAxisAlignment.end
// // // // //                                   : CrossAxisAlignment.start,
// // // // //                               children: [
// // // // //                                 if (!isMe)
// // // // //                                   Padding(
// // // // //                                     padding: const EdgeInsets.only(
// // // // //                                       left: 4,
// // // // //                                       bottom: 2,
// // // // //                                     ),
// // // // //                                     child: Text(
// // // // //                                       m.senderName,
// // // // //                                       style: TextStyle(
// // // // //                                         color: color,
// // // // //                                         fontSize: 11,
// // // // //                                         fontWeight: FontWeight.w700,
// // // // //                                       ),
// // // // //                                     ),
// // // // //                                   ),
// // // // //                                 Container(
// // // // //                                   padding: const EdgeInsets.symmetric(
// // // // //                                     horizontal: 12,
// // // // //                                     vertical: 8,
// // // // //                                   ),
// // // // //                                   decoration: BoxDecoration(
// // // // //                                     color: isMe
// // // // //                                         ? const Color(0xFFFFD60A)
// // // // //                                         : color.withOpacity(0.18),
// // // // //                                     borderRadius: BorderRadius.circular(16)
// // // // //                                         .copyWith(
// // // // //                                           bottomRight: isMe
// // // // //                                               ? const Radius.circular(4)
// // // // //                                               : null,
// // // // //                                           bottomLeft: isMe
// // // // //                                               ? null
// // // // //                                               : const Radius.circular(4),
// // // // //                                         ),
// // // // //                                   ),
// // // // //                                   child: Text(
// // // // //                                     m.text,
// // // // //                                     style: TextStyle(
// // // // //                                       color: isMe
// // // // //                                           ? const Color(0xFF0D1B2A)
// // // // //                                           : Colors.white,
// // // // //                                       fontWeight: isMe
// // // // //                                           ? FontWeight.w700
// // // // //                                           : FontWeight.w400,
// // // // //                                     ),
// // // // //                                   ),
// // // // //                                 ),
// // // // //                               ],
// // // // //                             ),
// // // // //                           );
// // // // //                         },
// // // // //                       );
// // // // //               },
// // // // //             ),
// // // // //           ),
// // // // //           Container(
// // // // //             padding: EdgeInsets.fromLTRB(
// // // // //               12,
// // // // //               8,
// // // // //               12,
// // // // //               MediaQuery.viewInsetsOf(context).bottom + 12,
// // // // //             ),
// // // // //             color: const Color(0xFF1A2E45),
// // // // //             child: Row(
// // // // //               children: [
// // // // //                 Expanded(
// // // // //                   child: TextField(
// // // // //                     controller: _ctrl,
// // // // //                     style: const TextStyle(color: Colors.white),
// // // // //                     textInputAction: TextInputAction.send,
// // // // //                     onSubmitted: (_) => _send(),
// // // // //                     decoration: InputDecoration(
// // // // //                       hintText: 'Say something…',
// // // // //                       hintStyle: const TextStyle(color: Colors.white38),
// // // // //                       filled: true,
// // // // //                       fillColor: Colors.white.withOpacity(0.07),
// // // // //                       border: OutlineInputBorder(
// // // // //                         borderRadius: BorderRadius.circular(24),
// // // // //                         borderSide: BorderSide.none,
// // // // //                       ),
// // // // //                       contentPadding: const EdgeInsets.symmetric(
// // // // //                         horizontal: 16,
// // // // //                         vertical: 10,
// // // // //                       ),
// // // // //                       isDense: true,
// // // // //                     ),
// // // // //                   ),
// // // // //                 ),
// // // // //                 const SizedBox(width: 8),
// // // // //                 GestureDetector(
// // // // //                   onTap: _send,
// // // // //                   child: Container(
// // // // //                     width: 44,
// // // // //                     height: 44,
// // // // //                     decoration: const BoxDecoration(
// // // // //                       color: Color(0xFFFFD60A),
// // // // //                       shape: BoxShape.circle,
// // // // //                     ),
// // // // //                     child: const Icon(
// // // // //                       Icons.send_rounded,
// // // // //                       color: Color(0xFF0D1B2A),
// // // // //                       size: 20,
// // // // //                     ),
// // // // //                   ),
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // const _kChatColors = [
// // // // //   Color(0xFF4ECDC4),
// // // // //   Color(0xFFA855F7),
// // // // //   Color(0xFFFF6B6B),
// // // // //   Color(0xFF4ADE80),
// // // // //   Color(0xFFFB923C),
// // // // //   Color(0xFF60A5FA),
// // // // //   Color(0xFFF472B6),
// // // // //   Color(0xFFFFD60A),
// // // // //   Color(0xFF34D399),
// // // // //   Color(0xFFC084FC),
// // // // // ];

// // // // // // ── Paused overlay ────────────────────────────────────────────────────────────
// // // // // class _PausedOverlay extends StatefulWidget {
// // // // //   const _PausedOverlay({required this.onLeave});
// // // // //   final VoidCallback onLeave;

// // // // //   @override
// // // // //   State<_PausedOverlay> createState() => _PausedOverlayState();
// // // // // }

// // // // // class _PausedOverlayState extends State<_PausedOverlay>
// // // // //     with SingleTickerProviderStateMixin {
// // // // //   late final AnimationController _pulse;

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     _pulse = AnimationController(
// // // // //       vsync: this,
// // // // //       duration: const Duration(milliseconds: 1400),
// // // // //     )..repeat(reverse: true);
// // // // //   }

// // // // //   @override
// // // // //   void dispose() {
// // // // //     _pulse.dispose();
// // // // //     super.dispose();
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Dialog.fullscreen(
// // // // //       backgroundColor: Colors.transparent,
// // // // //       child: Scaffold(
// // // // //         backgroundColor: Colors.transparent,
// // // // //         body: Center(
// // // // //           child: Padding(
// // // // //             padding: const EdgeInsets.all(32),
// // // // //             child: Column(
// // // // //               mainAxisSize: MainAxisSize.min,
// // // // //               children: [
// // // // //                 AnimatedBuilder(
// // // // //                   animation: _pulse,
// // // // //                   builder: (_, child) =>
// // // // //                       Opacity(opacity: 0.6 + _pulse.value * 0.4, child: child),
// // // // //                   child: const Text('⏸', style: TextStyle(fontSize: 72)),
// // // // //                 ),
// // // // //                 const SizedBox(height: 24),
// // // // //                 const Text(
// // // // //                   'Game Paused',
// // // // //                   style: TextStyle(
// // // // //                     color: Colors.white,
// // // // //                     fontSize: 28,
// // // // //                     fontWeight: FontWeight.w800,
// // // // //                     letterSpacing: -0.5,
// // // // //                   ),
// // // // //                 ),
// // // // //                 const SizedBox(height: 12),
// // // // //                 const Text(
// // // // //                   'The host stepped away and will\nreturn shortly.',
// // // // //                   textAlign: TextAlign.center,
// // // // //                   style: TextStyle(
// // // // //                     color: Colors.white70,
// // // // //                     fontSize: 16,
// // // // //                     height: 1.5,
// // // // //                   ),
// // // // //                 ),
// // // // //                 const SizedBox(height: 40),
// // // // //                 OutlinedButton(
// // // // //                   style: OutlinedButton.styleFrom(
// // // // //                     foregroundColor: Colors.white,
// // // // //                     side: const BorderSide(color: Colors.white38),
// // // // //                     padding: const EdgeInsets.symmetric(
// // // // //                       horizontal: 32,
// // // // //                       vertical: 14,
// // // // //                     ),
// // // // //                   ),
// // // // //                   onPressed: widget.onLeave,
// // // // //                   child: const Text('Leave for Now'),
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // import 'dart:async';

// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // import 'package:go_router/go_router.dart';
// // // // import 'package:jma3a/core/router/app_router.dart';
// // // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // // import 'package:jma3a/features/rooms/domain/room_entity.dart';
// // // // import 'package:jma3a/features/settings/presentation/screen_security_service.dart';
// // // // import 'package:provider/provider.dart';
// // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // import '../../../../../core/di/service_locator.dart';
// // // // import '../../../../../core/extensions/context_ext.dart';
// // // // import '../../../../../core/providers/auth_provider.dart';
// // // // import '../../../../../core/router/route_names.dart';
// // // // import '../../../../../core/services/realtime_service.dart';
// // // // // import '../../../../../core/services/screen_security_service.dart';
// // // // import '../../../../../core/theme/app_colors.dart';
// // // // import '../../../../../shared/widgets/feedback/error_view.dart';
// // // // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // // // import '../../domain/tod_models.dart';
// // // // import '../../tod_game_provider.dart';

// // // // import '../../data/tod_repository.dart';
// // // // import 'tod_card_screen.dart';
// // // // import 'tod_end_screen.dart';
// // // // import 'tod_loading_screen.dart';
// // // // import 'tod_punishment_screen.dart';
// // // // import '../widgets/tod_hud.dart';

// // // // class TodGameScreen extends StatefulWidget {
// // // //   const TodGameScreen({
// // // //     super.key,
// // // //     required this.roomId,
// // // //     required this.config,
// // // //     required this.playerIds,
// // // //     required this.playerDisplayNames,
// // // //     required this.packId,
// // // //     required this.isOwner,
// // // //     this.sessionId,
// // // //     this.isModerator = false,
// // // //     this.packCoverUrl,
// // // //   });

// // // //   final String roomId;
// // // //   final GameConfig config;
// // // //   final List<String> playerIds;
// // // //   final Map<String, String> playerDisplayNames;
// // // //   final String packId;
// // // //   final bool isOwner;
// // // //   final String? sessionId;
// // // //   final bool isModerator;
// // // //   final String? packCoverUrl;

// // // //   @override
// // // //   State<TodGameScreen> createState() => _TodGameScreenState();
// // // // }

// // // // class _TodGameScreenState extends State<TodGameScreen> {
// // // //   late final TodGameProvider _provider;

// // // //   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();

// // // //     ScreenSecurityService.instance.enable();
// // // //     ScreenSecurityService.instance.enableScreenshotDetection(() {
// // // //       sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // //         'type': 'screenshot_taken',
// // // //         'user_id': context.read<AuthProvider>().currentUser?.id,
// // // //       }).ignore();
// // // //     });

// // // //     final auth = context.read<AuthProvider>();
// // // //     final user = auth.currentUser!;

// // // //     _provider = TodGameProvider(
// // // //       realtimeService: sl.realtimeService,
// // // //       repository: TodRepository.instance,
// // // //       currentUserId: user.id,
// // // //       currentDisplayName: user.displayName ?? user.username ?? 'Player',
// // // //       isModerator: widget.isModerator,
// // // //     );

// // // //     _wireRealtimeCallbacks();

// // // //     if (widget.isOwner) {
// // // //       final isPremium =
// // // //           context.read<AuthProvider>().currentUser?.isPremium ?? false;
// // // //       _provider.initAsOwner(
// // // //         roomId: widget.roomId,
// // // //         config: widget.config,
// // // //         playerIds: widget.playerIds,
// // // //         playerDisplayNames: widget.playerDisplayNames,
// // // //         packId: widget.packId,
// // // //         isPremium: isPremium,
// // // //         packCoverUrl: widget.packCoverUrl,
// // // //       );
// // // //     } else {
// // // //       _provider.initAsFollower(
// // // //         roomId: widget.roomId,
// // // //         config: widget.config,
// // // //         sessionId: widget.sessionId,
// // // //         packCoverUrl: widget.packCoverUrl,
// // // //       );
// // // //     }
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     ScreenSecurityService.instance.disable();
// // // //     _statusSub?.cancel();
// // // //     sl.realtimeService
// // // //         .subscribe(
// // // //           roomId: widget.roomId,
// // // //           onGameState: (_) {},
// // // //           onPlayerAction: (_) {},
// // // //           onSyncRequest: (_) {},
// // // //           onGameStarted: (_) {},
// // // //           onGameEnded: (_) {},
// // // //           onRoomEvent: (_) {},
// // // //           onChatMessage: (_) {},
// // // //           onModeration: (_) {},
// // // //           onSettingsChange: (_) {},
// // // //           onPresenceSync: (_) {},
// // // //           onPresenceJoin: (_) {},
// // // //           onPresenceLeave: (_) {},
// // // //           onStatusChange: (_) {},
// // // //         )
// // // //         .ignore();
// // // //     _provider.dispose();
// // // //     super.dispose();
// // // //   }

// // // //   void _wireRealtimeCallbacks() {
// // // //     _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
// // // //       status,
// // // //     ) {
// // // //       if (status == RealtimeSubscribeStatus.subscribed &&
// // // //           !_provider.hasSyncedState) {
// // // //         sl.realtimeService.broadcastSyncRequest(
// // // //           widget.roomId,
// // // //           context.read<AuthProvider>().currentUser!.id,
// // // //           0,
// // // //         );
// // // //       }
// // // //     });

// // // //     _resubscribeWithGameHandlers();
// // // //   }

// // // //   void _resubscribeWithGameHandlers() {
// // // //     final userId = context.read<AuthProvider>().currentUser!.id;

// // // //     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
// // // //       sl.realtimeService.subscribe(
// // // //         roomId: widget.roomId,
// // // //         onGameState: (p) => _provider.onStateBroadcast(p),
// // // //         onPlayerAction: (p) => _provider.onPlayerAction(p),
// // // //         onSyncRequest: (p) => _provider.onSyncRequest(p),
// // // //         onGameStarted: (_) {},
// // // //         onGameEnded: (p) {
// // // //           if (mounted) {
// // // //             ScaffoldMessenger.of(context).showSnackBar(
// // // //               const SnackBar(content: Text('The host ended the game')),
// // // //             );
// // // //             if (context.canPop())
// // // //               context.pop();
// // // //             else
// // // //               context.go(RouteNames.home);
// // // //           }
// // // //         },
// // // //         onRoomEvent: (p) {
// // // //           final type = p['type'] as String?;
// // // //           if (type == 'screenshot_taken') {
// // // //             final shooterId = p['user_id'] as String?;
// // // //             final myId = context.read<AuthProvider>().currentUser?.id;
// // // //             if (shooterId != null && shooterId != myId && mounted) {
// // // //               ScaffoldMessenger.of(context).showSnackBar(
// // // //                 SnackBar(
// // // //                   content: Text(
// // // //                     '📸 ${widget.playerDisplayNames[shooterId] ?? 'Someone'} took a screenshot',
// // // //                   ),
// // // //                   backgroundColor: Colors.black87,
// // // //                 ),
// // // //               );
// // // //             }
// // // //             return;
// // // //           }
// // // //           if (type == 'player_left' && mounted) {
// // // //             final name = p['display_name'] as String? ?? 'A player';
// // // //             final forGood = p['for_good'] as bool? ?? true;
// // // //             final leavingId = p['user_id'] as String?;
// // // //             final returnMins = p['return_mins'] as int?;
// // // //             if (leavingId != null && widget.isOwner) {
// // // //               _provider.markPlayerAway(leavingId, forGood: forGood);
// // // //               final activePlayers =
// // // //                   _provider.state?.playerOrder
// // // //                       .where((id) => !_provider.awayPlayerIds.contains(id))
// // // //                       .toList() ??
// // // //                   [];
// // // //               if (activePlayers.length <= 1 && activePlayers.isNotEmpty) {
// // // //                 WidgetsBinding.instance.addPostFrameCallback((_) async {
// // // //                   if (!mounted) return;
// // // //                   await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // //                     'type': 'game_ended',
// // // //                     'reason': 'all_players_left',
// // // //                   });
// // // //                   await sl.roomRepository.updateStatus(
// // // //                     widget.roomId,
// // // //                     RoomStatus.waiting,
// // // //                   );
// // // //                   if (mounted) {
// // // //                     ScaffoldMessenger.of(context).showSnackBar(
// // // //                       const SnackBar(
// // // //                         content: Text('All players left — game ended'),
// // // //                         backgroundColor: Colors.orange,
// // // //                       ),
// // // //                     );
// // // //                     await Future.delayed(const Duration(milliseconds: 800));
// // // //                     if (mounted) {
// // // //                       if (context.canPop())
// // // //                         context.pop();
// // // //                       else
// // // //                         context.go('/home/room/${widget.roomId}');
// // // //                     }
// // // //                   }
// // // //                 });
// // // //               }
// // // //             }
// // // //             final msg = forGood
// // // //                 ? '👋 $name left the game'
// // // //                 : '🕐 $name stepped away (${returnMins != null ? 'back in ${returnMins}m' : 'coming back'})';
// // // //             ScaffoldMessenger.of(context).showSnackBar(
// // // //               SnackBar(
// // // //                 content: Text(msg),
// // // //                 backgroundColor: forGood
// // // //                     ? Colors.red.shade700
// // // //                     : Colors.orange.shade700,
// // // //                 duration: const Duration(seconds: 4),
// // // //               ),
// // // //             );
// // // //             return;
// // // //           }
// // // //           if (type == 'ownership_transferred' && mounted) {
// // // //             final myId = context.read<AuthProvider>().currentUser?.id;
// // // //             final newOwnerId = p['new_owner_id'] as String?;
// // // //             if (newOwnerId == myId) {
// // // //               ScaffoldMessenger.of(context).showSnackBar(
// // // //                 const SnackBar(
// // // //                   content: Text('👑 You are now the game host!'),
// // // //                   backgroundColor: Colors.purple,
// // // //                 ),
// // // //               );
// // // //             }
// // // //             return;
// // // //           }
// // // //           if (type == 'game_ended' && mounted) {
// // // //             final reason = p['reason'] as String? ?? '';
// // // //             WidgetsBinding.instance.addPostFrameCallback((_) {
// // // //               if (!mounted) return;
// // // //               final msg = reason == 'all_players_left'
// // // //                   ? '👋 All players left — game ended'
// // // //                   : '🔄 Host ended the game';
// // // //               ScaffoldMessenger.of(context).showSnackBar(
// // // //                 SnackBar(
// // // //                   content: Text(msg),
// // // //                   duration: const Duration(seconds: 3),
// // // //                   behavior: SnackBarBehavior.fixed,
// // // //                 ),
// // // //               );
// // // //               if (context.canPop()) {
// // // //                 context.pop();
// // // //               } else {
// // // //                 context.go('/home/room/\${widget.roomId}');
// // // //               }
// // // //             });
// // // //             return;
// // // //           }
// // // //           if (type == 'tod_ready_count') {
// // // //             final ids = (p['ready_user_ids'] as List?)?.cast<String>() ?? [];
// // // //             _provider.onReadyCountUpdate(ids);
// // // //             return;
// // // //           }
// // // //           if ((type == 'room_closed' || type == 'owner_left') && mounted) {
// // // //             WidgetsBinding.instance.addPostFrameCallback((_) {
// // // //               if (!mounted) {
// // // //                 AppRouter.router.go(RouteNames.home);
// // // //                 return;
// // // //               }
// // // //               showDialog(
// // // //                 context: context,
// // // //                 barrierDismissible: false,
// // // //                 builder: (ctx2) => AlertDialog(
// // // //                   title: const Text('Room Closed'),
// // // //                   content: const Text('The host closed the room.'),
// // // //                   actions: [
// // // //                     FilledButton(
// // // //                       onPressed: () {
// // // //                         Navigator.of(ctx2).pop();
// // // //                         AppRouter.router.go(RouteNames.home);
// // // //                       },
// // // //                       child: const Text('OK'),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               );
// // // //             });
// // // //             return;
// // // //           }
// // // //         },
// // // //         onChatMessage: (p) {
// // // //           final msg = TodChatMsg(
// // // //             senderId: p['user_id'] as String? ?? '',
// // // //             senderName: p['display_name'] as String? ?? 'Player',
// // // //             text: p['content'] as String? ?? '',
// // // //             ts: DateTime.fromMillisecondsSinceEpoch(
// // // //               (p['ts'] as num?)?.toInt() ??
// // // //                   DateTime.now().millisecondsSinceEpoch,
// // // //             ),
// // // //           );
// // // //           _provider.addChatMessage(msg);
// // // //         },
// // // //         onModeration: (p) => _handleModerationEvent(p),
// // // //         onSettingsChange: (_) {},
// // // //         onPresenceSync: (_) {},
// // // //         onPresenceJoin: (_) {},
// // // //         onPresenceLeave: (_) {},
// // // //         onStatusChange: (status) {
// // // //           if (!mounted) return;
// // // //           if (status == RealtimeSubscribeStatus.subscribed &&
// // // //               !_provider.hasSyncedState) {
// // // //             sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
// // // //           }
// // // //         },
// // // //       );
// // // //     });
// // // //   }

// // // //   void _handleModerationEvent(Map<String, dynamic> p) {
// // // //     final type = p['type'] as String?;
// // // //     final targetId = p['target_user_id'] as String?;
// // // //     final currentId = context.read<AuthProvider>().currentUser?.id;

// // // //     if ((type == 'kick' || type == 'ban') && targetId == currentId) {
// // // //       if (mounted) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(content: Text('You were removed from the room')),
// // // //         );
// // // //         context.go(RouteNames.home);
// // // //       }
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return ChangeNotifierProvider.value(
// // // //       value: _provider,
// // // //       child: Consumer<TodGameProvider>(
// // // //         builder: (ctx, game, _) => _build(ctx, game),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _build(BuildContext ctx, TodGameProvider game) {
// // // //     if (game.loadState == TodLoadState.loading) {
// // // //       return const TodLoadingScreen();
// // // //     }

// // // //     if (game.loadState == TodLoadState.error) {
// // // //       return Scaffold(
// // // //         appBar: AppBar(
// // // //           leading: BackButton(
// // // //             onPressed: () async {
// // // //               if (widget.isOwner) {
// // // //                 try {
// // // //                   await sl.realtimeService.broadcastGameEnded(widget.roomId, {
// // // //                     'reason': 'host_left',
// // // //                   });
// // // //                   await sl.roomRepository.updateStatus(
// // // //                     widget.roomId,
// // // //                     RoomStatus.waiting,
// // // //                   );
// // // //                 } catch (_) {}
// // // //               }
// // // //               if (ctx.mounted) ctx.go(RouteNames.home);
// // // //             },
// // // //           ),
// // // //         ),
// // // //         body: ErrorView(
// // // //           message: game.error ?? 'Failed to load game',
// // // //           onRetry: () => ctx.go(RouteNames.home),
// // // //         ),
// // // //       );
// // // //     }

// // // //     if (game.loadState == TodLoadState.gameOver ||
// // // //         (game.state?.isOver ?? false)) {
// // // //       return TodEndScreen(
// // // //         state: game.state!,
// // // //         displayNames: widget.playerDisplayNames,
// // // //         onLeave: () => ctx.go(RouteNames.home),
// // // //       );
// // // //     }

// // // //     final state = game.state;
// // // //     if (state == null) return const TodLoadingScreen();

// // // //     return _TodGameScaffold(
// // // //       state: state,
// // // //       game: game,
// // // //       displayNames: widget.playerDisplayNames,
// // // //       roomId: widget.roomId,
// // // //       isOwner: widget.isOwner,
// // // //     );
// // // //   }
// // // // }

// // // // class _TodGameScaffold extends StatefulWidget {
// // // //   const _TodGameScaffold({
// // // //     required this.state,
// // // //     required this.game,
// // // //     required this.displayNames,
// // // //     required this.roomId,
// // // //     required this.isOwner,
// // // //   });
// // // //   final TodState state;
// // // //   final TodGameProvider game;
// // // //   final Map<String, String> displayNames;
// // // //   final String roomId;
// // // //   final bool isOwner;
// // // //   @override
// // // //   State<_TodGameScaffold> createState() => _TodGameScaffoldState();
// // // // }

// // // // class _TodGameScaffoldState extends State<_TodGameScaffold> {
// // // //   bool _showHistory = false;
// // // //   bool _showChat = false;
// // // //   int _unreadChat = 0;
// // // //   bool _isNavigatingAway = false;

// // // //   void _navigateAway(BuildContext ctx, String location) {
// // // //     _isNavigatingAway = true;
// // // //     if (ctx.canPop()) {
// // // //       ctx.pop();
// // // //     } else {
// // // //       ctx.go(location);
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final state = widget.state;
// // // //     final game = widget.game;

// // // //     if (_showHistory) {
// // // //       return Scaffold(
// // // //         appBar: AppBar(
// // // //           leading: BackButton(
// // // //             onPressed: () => setState(() => _showHistory = false),
// // // //           ),
// // // //           title: Text('History (${state.history.length} rounds)'),
// // // //         ),
// // // //         body: _HistoryPanel(
// // // //           history: state.history,
// // // //           displayNames: widget.displayNames,
// // // //         ),
// // // //       );
// // // //     }

// // // //     return PopScope(
// // // //       canPop: false,
// // // //       onPopInvoked: (_) {
// // // //         if (_isNavigatingAway) return;
// // // //         WidgetsBinding.instance.addPostFrameCallback(
// // // //           (_) => _showLeaveDialog(context, game, state),
// // // //         );
// // // //       },
// // // //       child: Scaffold(
// // // //         appBar: AppBar(
// // // //           automaticallyImplyLeading: false,
// // // //           title: const Text(''),
// // // //           leading: IconButton(
// // // //             icon: const Icon(Icons.arrow_back),
// // // //             onPressed: () => _showLeaveDialog(context, game, state),
// // // //           ),
// // // //           actions: [
// // // //             Consumer<TodGameProvider>(
// // // //               builder: (_, g, __) => Stack(
// // // //                 alignment: Alignment.topRight,
// // // //                 children: [
// // // //                   IconButton(
// // // //                     icon: const Icon(Icons.chat_bubble_outline_rounded),
// // // //                     onPressed: () {
// // // //                       g.clearUnreadChat();
// // // //                       showModalBottomSheet(
// // // //                         context: context,
// // // //                         isScrollControlled: true,
// // // //                         backgroundColor: Colors.transparent,
// // // //                         builder: (_) =>
// // // //                             _InGameChatSheet(game: g, myId: g.currentUserId),
// // // //                       );
// // // //                     },
// // // //                   ),
// // // //                   if (g.unreadChat > 0)
// // // //                     Positioned(
// // // //                       top: 8,
// // // //                       right: 8,
// // // //                       child: Container(
// // // //                         width: 8,
// // // //                         height: 8,
// // // //                         decoration: const BoxDecoration(
// // // //                           color: Colors.red,
// // // //                           shape: BoxShape.circle,
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //             if (state.history.isNotEmpty)
// // // //               IconButton(
// // // //                 icon: const Icon(Icons.history_rounded),
// // // //                 tooltip: 'History',
// // // //                 onPressed: () => setState(() => _showHistory = true),
// // // //               ),
// // // //           ],
// // // //         ),
// // // //         body: SafeArea(
// // // //           child: Column(
// // // //             children: [
// // // //               TodHud(
// // // //                 state: state,
// // // //                 game: game,
// // // //                 displayNames: widget.displayNames,
// // // //               ),
// // // //               Expanded(
// // // //                 child: AnimatedSwitcher(
// // // //                   duration: const Duration(milliseconds: 300),
// // // //                   transitionBuilder: (child, anim) => FadeTransition(
// // // //                     opacity: anim,
// // // //                     child: SlideTransition(
// // // //                       position:
// // // //                           Tween<Offset>(
// // // //                             begin: const Offset(0, 0.05),
// // // //                             end: Offset.zero,
// // // //                           ).animate(
// // // //                             CurvedAnimation(
// // // //                               parent: anim,
// // // //                               curve: Curves.easeOutCubic,
// // // //                             ),
// // // //                           ),
// // // //                       child: child,
// // // //                     ),
// // // //                   ),
// // // //                   child: KeyedSubtree(
// // // //                     key: ValueKey('${state.phase}-${state.currentPlayerId}'),
// // // //                     child: _phaseWidget(
// // // //                       context,
// // // //                       game,
// // // //                       widget.displayNames,
// // // //                       state,
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Future<void> _showLeaveDialog(
// // // //     BuildContext ctx,
// // // //     TodGameProvider game,
// // // //     TodState state,
// // // //   ) async {
// // // //     if (!ctx.mounted) return;
// // // //     final isOwner = widget.isOwner;
// // // //     final myUserId = game.currentUserId;
// // // //     final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

// // // //     if (isOwner) {
// // // //       final confirmed = await showDialog<bool>(
// // // //         context: ctx,
// // // //         builder: (dCtx) => AlertDialog(
// // // //           title: const Text('Quit Game?'),
// // // //           content: const Text(
// // // //             'The game will end for everyone and all players will return to the lobby.',
// // // //           ),
// // // //           actions: [
// // // //             TextButton(
// // // //               onPressed: () => Navigator.of(dCtx).pop(false),
// // // //               child: const Text('Cancel'),
// // // //             ),
// // // //             FilledButton(
// // // //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // // //               onPressed: () => Navigator.of(dCtx).pop(true),
// // // //               child: const Text('End Game for Everyone'),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       );
// // // //       if (confirmed != true || !ctx.mounted) return;

// // // //       try {
// // // //         await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // //           'type': 'game_ended',
// // // //           'reason': 'host_quit_to_lobby',
// // // //         });
// // // //         await Future.delayed(const Duration(milliseconds: 400));
// // // //         await sl.roomRepository.updateStatus(widget.roomId, RoomStatus.waiting);
// // // //       } catch (_) {}
// // // //       if (ctx.mounted) {
// // // //         _isNavigatingAway = true;
// // // //         if (ctx.canPop()) {
// // // //           ctx.pop();
// // // //         } else {
// // // //           ctx.go('/home/room/${widget.roomId}');
// // // //         }
// // // //       }
// // // //     } else {
// // // //       final returnMins = isPremium ? 10 : 5;
// // // //       final choice = await showDialog<String>(
// // // //         context: ctx,
// // // //         builder: (_) => AlertDialog(
// // // //           title: const Text('Leave Game?'),
// // // //           content: Text(
// // // //             "If you'll return, your turns will be skipped until you're "
// // // //             'back. You have $returnMins minutes — after that your seat '
// // // //             'is lost.',
// // // //           ),
// // // //           actions: [
// // // //             TextButton(
// // // //               onPressed: () => Navigator.pop(ctx, 'cancel'),
// // // //               child: const Text('Stay'),
// // // //             ),
// // // //             FilledButton.tonal(
// // // //               onPressed: () => Navigator.pop(ctx, 'return'),
// // // //               child: Text("I'll Return ($returnMins min)"),
// // // //             ),
// // // //             FilledButton(
// // // //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // // //               onPressed: () => Navigator.pop(ctx, 'definitive'),
// // // //               child: const Text('Leave for Good'),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       );
// // // //       if (choice == null || choice == 'cancel' || !ctx.mounted) return;

// // // //       final displayName = widget.displayNames[myUserId] ?? 'A player';

// // // //       if (choice == 'return') {
// // // //         try {
// // // //           await sl.roomRepository.setMemberAway(
// // // //             widget.roomId,
// // // //             myUserId,
// // // //             away: true,
// // // //           );
// // // //           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // //             'type': 'player_left',
// // // //             'user_id': myUserId,
// // // //             'display_name': displayName,
// // // //             'for_good': false,
// // // //             'return_mins': returnMins,
// // // //           });
// // // //         } catch (_) {}
// // // //         if (ctx.mounted) {
// // // //           ScaffoldMessenger.of(ctx).showSnackBar(
// // // //             SnackBar(
// // // //               content: Text(
// // // //                 "You'll be back in $returnMins min — seat reserved",
// // // //               ),
// // // //               backgroundColor: Colors.orange.shade700,
// // // //               duration: const Duration(seconds: 3),
// // // //             ),
// // // //           );
// // // //           await Future.delayed(const Duration(milliseconds: 800));
// // // //           if (ctx.mounted) {
// // // //             _isNavigatingAway = true;
// // // //             ctx.go('/home/room/${widget.roomId}');
// // // //           }
// // // //         }
// // // //       } else {
// // // //         try {
// // // //           await sl.roomRepository.setMemberDefinitiveLeave(
// // // //             widget.roomId,
// // // //             myUserId,
// // // //           );
// // // //           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // //             'type': 'player_left',
// // // //             'user_id': myUserId,
// // // //             'display_name': displayName,
// // // //             'for_good': true,
// // // //           });
// // // //         } catch (_) {}
// // // //         if (ctx.mounted) {
// // // //           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // //             'type': 'check_auto_quit',
// // // //             'user_id': myUserId,
// // // //           });
// // // //           ctx.go('/home/room/${widget.roomId}');
// // // //         }
// // // //       }
// // // //     }
// // // //   }

// // // //   Widget _phaseWidget(
// // // //     BuildContext ctx,
// // // //     TodGameProvider game,
// // // //     Map<String, String> displayNames,
// // // //     TodState state,
// // // //   ) {
// // // //     return switch (state.phase) {
// // // //       TodTurnPhase.punishmentVoting => TodPunishmentScreen(
// // // //         state: state,
// // // //         game: game,
// // // //         displayNames: widget.displayNames,
// // // //       ),
// // // //       _ => TodCardScreen(
// // // //         state: state,
// // // //         game: game,
// // // //         displayNames: widget.displayNames,
// // // //       ),
// // // //     };
// // // //   }
// // // // }

// // // // class _HistoryPanel extends StatelessWidget {
// // // //   const _HistoryPanel({required this.history, required this.displayNames});
// // // //   final List<TodRoundRecord> history;
// // // //   final Map<String, String> displayNames;

// // // //   String _name(String id) =>
// // // //       displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = context.theme;
// // // //     if (history.isEmpty) {
// // // //       return const Center(child: Text('No rounds completed yet.'));
// // // //     }
// // // //     return ListView.builder(
// // // //       padding: const EdgeInsets.all(12),
// // // //       itemCount: history.length,
// // // //       itemBuilder: (_, i) {
// // // //         final round = history[history.length - 1 - i];
// // // //         final reactTally = <String, int>{};
// // // //         for (final r in round.reactions) {
// // // //           reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
// // // //         }
// // // //         return Card(
// // // //           margin: const EdgeInsets.only(bottom: 10),
// // // //           child: ExpansionTile(
// // // //             leading: CircleAvatar(
// // // //               backgroundColor: theme.colorScheme.primaryContainer,
// // // //               child: Text(
// // // //                 '${round.roundNumber}',
// // // //                 style: theme.textTheme.labelLarge,
// // // //               ),
// // // //             ),
// // // //             title: Text(
// // // //               _name(round.playerId),
// // // //               style: theme.textTheme.bodyMedium?.copyWith(
// // // //                 fontWeight: FontWeight.w700,
// // // //               ),
// // // //             ),
// // // //             subtitle: Text(
// // // //               round.card != null
// // // //                   ? '${round.card!.type == TodCardType.truth ? "Truth" : "Dare"}: ${round.card!.content}'
// // // //                   : 'Skipped',
// // // //               maxLines: 1,
// // // //               overflow: TextOverflow.ellipsis,
// // // //               style: theme.textTheme.bodySmall,
// // // //             ),
// // // //             children: [
// // // //               Padding(
// // // //                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
// // // //                 child: Column(
// // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // //                   children: [
// // // //                     if (round.card != null)
// // // //                       Container(
// // // //                         width: double.infinity,
// // // //                         padding: const EdgeInsets.all(10),
// // // //                         decoration: BoxDecoration(
// // // //                           color: round.card!.type == TodCardType.truth
// // // //                               ? Colors.blue.withOpacity(0.08)
// // // //                               : Colors.orange.withOpacity(0.08),
// // // //                           borderRadius: BorderRadius.circular(8),
// // // //                         ),
// // // //                         child: Text(
// // // //                           round.card!.content,
// // // //                           style: theme.textTheme.bodyMedium,
// // // //                         ),
// // // //                       ),
// // // //                     if (round.response.isNotEmpty) ...[
// // // //                       const SizedBox(height: 8),
// // // //                       Row(
// // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // //                         children: [
// // // //                           const Text('💬 ', style: TextStyle(fontSize: 14)),
// // // //                           Expanded(
// // // //                             child: Text(
// // // //                               '"${round.response}"',
// // // //                               style: theme.textTheme.bodySmall?.copyWith(
// // // //                                 fontStyle: FontStyle.italic,
// // // //                               ),
// // // //                             ),
// // // //                           ),
// // // //                         ],
// // // //                       ),
// // // //                     ],
// // // //                     if (round.voteCount > 0) ...[
// // // //                       const SizedBox(height: 6),
// // // //                       Text(
// // // //                         '👍 ${round.voteCount} vote${round.voteCount != 1 ? "s" : ""}',
// // // //                         style: theme.textTheme.bodySmall?.copyWith(
// // // //                           color: theme.colorScheme.primary,
// // // //                           fontWeight: FontWeight.w600,
// // // //                         ),
// // // //                       ),
// // // //                     ],
// // // //                     if (round.hadProof) ...[
// // // //                       const SizedBox(height: 8),
// // // //                       _ProofWatchedBadge(watchedBy: round.proofWatchedBy),
// // // //                     ],
// // // //                     if (reactTally.isNotEmpty) ...[
// // // //                       const SizedBox(height: 8),
// // // //                       Wrap(
// // // //                         spacing: 6,
// // // //                         runSpacing: 4,
// // // //                         children: reactTally.entries
// // // //                             .map(
// // // //                               (e) => Container(
// // // //                                 padding: const EdgeInsets.symmetric(
// // // //                                   horizontal: 8,
// // // //                                   vertical: 3,
// // // //                                 ),
// // // //                                 decoration: BoxDecoration(
// // // //                                   color:
// // // //                                       theme.colorScheme.surfaceContainerHighest,
// // // //                                   borderRadius: BorderRadius.circular(16),
// // // //                                 ),
// // // //                                 child: Text(
// // // //                                   '${e.key} ${e.value}',
// // // //                                   style: const TextStyle(fontSize: 13),
// // // //                                 ),
// // // //                               ),
// // // //                             )
// // // //                             .toList(),
// // // //                       ),
// // // //                     ],
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         );
// // // //       },
// // // //     );
// // // //   }
// // // // }

// // // // class _ProofWatchedBadge extends StatelessWidget {
// // // //   const _ProofWatchedBadge({required this.watchedBy});
// // // //   final List<String> watchedBy;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final watched = watchedBy.isNotEmpty;
// // // //     return Container(
// // // //       height: 36,
// // // //       padding: const EdgeInsets.symmetric(horizontal: 10),
// // // //       decoration: BoxDecoration(
// // // //         color: Colors.grey.shade200,
// // // //         borderRadius: BorderRadius.circular(8),
// // // //       ),
// // // //       alignment: Alignment.centerLeft,
// // // //       child: Row(
// // // //         mainAxisSize: MainAxisSize.min,
// // // //         children: [
// // // //           Icon(
// // // //             watched ? Icons.visibility_outlined : Icons.visibility_off_outlined,
// // // //             size: 16,
// // // //             color: Colors.grey.shade600,
// // // //           ),
// // // //           const SizedBox(width: 6),
// // // //           Text(
// // // //             watched
// // // //                 ? 'Proof watched by ${watchedBy.length}'
// // // //                 : 'Proof sent — not watched',
// // // //             style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _InGameChatSheet extends StatefulWidget {
// // // //   const _InGameChatSheet({required this.game, required this.myId});
// // // //   final TodGameProvider game;
// // // //   final String myId;
// // // //   @override
// // // //   State<_InGameChatSheet> createState() => _InGameChatSheetState();
// // // // }

// // // // class _InGameChatSheetState extends State<_InGameChatSheet> {
// // // //   final _ctrl = TextEditingController();
// // // //   final _scroll = ScrollController();
// // // //   @override
// // // //   void dispose() {
// // // //     _ctrl.dispose();
// // // //     _scroll.dispose();
// // // //     super.dispose();
// // // //   }

// // // //   void _send() {
// // // //     final t = _ctrl.text.trim();
// // // //     if (t.isEmpty) return;
// // // //     widget.game.sendChat(t);
// // // //     _ctrl.clear();
// // // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // // //       if (_scroll.hasClients)
// // // //         _scroll.animateTo(
// // // //           _scroll.position.maxScrollExtent,
// // // //           duration: 200.ms,
// // // //           curve: Curves.easeOut,
// // // //         );
// // // //     });
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Container(
// // // //       height: MediaQuery.sizeOf(context).height * 0.65,
// // // //       decoration: const BoxDecoration(
// // // //         color: Color(0xFF1A2E45),
// // // //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// // // //       ),
// // // //       child: Column(
// // // //         children: [
// // // //           Container(
// // // //             width: 36,
// // // //             height: 4,
// // // //             margin: const EdgeInsets.symmetric(vertical: 10),
// // // //             decoration: BoxDecoration(
// // // //               color: Colors.white24,
// // // //               borderRadius: BorderRadius.circular(2),
// // // //             ),
// // // //           ),
// // // //           const Text(
// // // //             '💬 Chat',
// // // //             style: TextStyle(
// // // //               color: Colors.white,
// // // //               fontWeight: FontWeight.w800,
// // // //               fontSize: 16,
// // // //             ),
// // // //           ),
// // // //           const Divider(color: Colors.white12),
// // // //           Expanded(
// // // //             child: ListenableBuilder(
// // // //               listenable: widget.game,
// // // //               builder: (_, __) {
// // // //                 final msgs = widget.game.chatMessages;
// // // //                 return msgs.isEmpty
// // // //                     ? const Center(
// // // //                         child: Text(
// // // //                           'No messages yet',
// // // //                           style: TextStyle(color: Colors.white38),
// // // //                         ),
// // // //                       )
// // // //                     : ListView.builder(
// // // //                         controller: _scroll,
// // // //                         padding: const EdgeInsets.all(12),
// // // //                         itemCount: msgs.length,
// // // //                         itemBuilder: (_, i) {
// // // //                           final m = msgs[i];
// // // //                           final isMe = m.senderId == widget.myId;
// // // //                           final color =
// // // //                               _kChatColors[m.senderId.hashCode.abs() %
// // // //                                   _kChatColors.length];
// // // //                           return Padding(
// // // //                             padding: EdgeInsets.only(
// // // //                               bottom: 8,
// // // //                               left: isMe ? 48 : 0,
// // // //                               right: isMe ? 0 : 48,
// // // //                             ),
// // // //                             child: Column(
// // // //                               crossAxisAlignment: isMe
// // // //                                   ? CrossAxisAlignment.end
// // // //                                   : CrossAxisAlignment.start,
// // // //                               children: [
// // // //                                 if (!isMe)
// // // //                                   Padding(
// // // //                                     padding: const EdgeInsets.only(
// // // //                                       left: 4,
// // // //                                       bottom: 2,
// // // //                                     ),
// // // //                                     child: Text(
// // // //                                       m.senderName,
// // // //                                       style: TextStyle(
// // // //                                         color: color,
// // // //                                         fontSize: 11,
// // // //                                         fontWeight: FontWeight.w700,
// // // //                                       ),
// // // //                                     ),
// // // //                                   ),
// // // //                                 Container(
// // // //                                   padding: const EdgeInsets.symmetric(
// // // //                                     horizontal: 12,
// // // //                                     vertical: 8,
// // // //                                   ),
// // // //                                   decoration: BoxDecoration(
// // // //                                     color: isMe
// // // //                                         ? const Color(0xFFFFD60A)
// // // //                                         : color.withOpacity(0.18),
// // // //                                     borderRadius: BorderRadius.circular(16)
// // // //                                         .copyWith(
// // // //                                           bottomRight: isMe
// // // //                                               ? const Radius.circular(4)
// // // //                                               : null,
// // // //                                           bottomLeft: isMe
// // // //                                               ? null
// // // //                                               : const Radius.circular(4),
// // // //                                         ),
// // // //                                   ),
// // // //                                   child: Text(
// // // //                                     m.text,
// // // //                                     style: TextStyle(
// // // //                                       color: isMe
// // // //                                           ? const Color(0xFF0D1B2A)
// // // //                                           : Colors.white,
// // // //                                       fontWeight: isMe
// // // //                                           ? FontWeight.w700
// // // //                                           : FontWeight.w400,
// // // //                                     ),
// // // //                                   ),
// // // //                                 ),
// // // //                               ],
// // // //                             ),
// // // //                           );
// // // //                         },
// // // //                       );
// // // //               },
// // // //             ),
// // // //           ),
// // // //           Container(
// // // //             padding: EdgeInsets.fromLTRB(
// // // //               12,
// // // //               8,
// // // //               12,
// // // //               MediaQuery.viewInsetsOf(context).bottom + 12,
// // // //             ),
// // // //             color: const Color(0xFF1A2E45),
// // // //             child: Row(
// // // //               children: [
// // // //                 Expanded(
// // // //                   child: TextField(
// // // //                     controller: _ctrl,
// // // //                     style: const TextStyle(color: Colors.white),
// // // //                     textInputAction: TextInputAction.send,
// // // //                     onSubmitted: (_) => _send(),
// // // //                     decoration: InputDecoration(
// // // //                       hintText: 'Say something…',
// // // //                       hintStyle: const TextStyle(color: Colors.white38),
// // // //                       filled: true,
// // // //                       fillColor: Colors.white.withOpacity(0.07),
// // // //                       border: OutlineInputBorder(
// // // //                         borderRadius: BorderRadius.circular(24),
// // // //                         borderSide: BorderSide.none,
// // // //                       ),
// // // //                       contentPadding: const EdgeInsets.symmetric(
// // // //                         horizontal: 16,
// // // //                         vertical: 10,
// // // //                       ),
// // // //                       isDense: true,
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //                 const SizedBox(width: 8),
// // // //                 GestureDetector(
// // // //                   onTap: _send,
// // // //                   child: Container(
// // // //                     width: 44,
// // // //                     height: 44,
// // // //                     decoration: const BoxDecoration(
// // // //                       color: Color(0xFFFFD60A),
// // // //                       shape: BoxShape.circle,
// // // //                     ),
// // // //                     child: const Icon(
// // // //                       Icons.send_rounded,
// // // //                       color: Color(0xFF0D1B2A),
// // // //                       size: 20,
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // const _kChatColors = [
// // // //   Color(0xFF4ECDC4),
// // // //   Color(0xFFA855F7),
// // // //   Color(0xFFFF6B6B),
// // // //   Color(0xFF4ADE80),
// // // //   Color(0xFFFB923C),
// // // //   Color(0xFF60A5FA),
// // // //   Color(0xFFF472B6),
// // // //   Color(0xFFFFD60A),
// // // //   Color(0xFF34D399),
// // // //   Color(0xFFC084FC),
// // // // ];

// // // // class _PausedOverlay extends StatefulWidget {
// // // //   const _PausedOverlay({required this.onLeave});
// // // //   final VoidCallback onLeave;

// // // //   @override
// // // //   State<_PausedOverlay> createState() => _PausedOverlayState();
// // // // }

// // // // class _PausedOverlayState extends State<_PausedOverlay>
// // // //     with SingleTickerProviderStateMixin {
// // // //   late final AnimationController _pulse;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _pulse = AnimationController(
// // // //       vsync: this,
// // // //       duration: const Duration(milliseconds: 1400),
// // // //     )..repeat(reverse: true);
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _pulse.dispose();
// // // //     super.dispose();
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Dialog.fullscreen(
// // // //       backgroundColor: Colors.transparent,
// // // //       child: Scaffold(
// // // //         backgroundColor: Colors.transparent,
// // // //         body: Center(
// // // //           child: Padding(
// // // //             padding: const EdgeInsets.all(32),
// // // //             child: Column(
// // // //               mainAxisSize: MainAxisSize.min,
// // // //               children: [
// // // //                 AnimatedBuilder(
// // // //                   animation: _pulse,
// // // //                   builder: (_, child) =>
// // // //                       Opacity(opacity: 0.6 + _pulse.value * 0.4, child: child),
// // // //                   child: const Text('⏸', style: TextStyle(fontSize: 72)),
// // // //                 ),
// // // //                 const SizedBox(height: 24),
// // // //                 const Text(
// // // //                   'Game Paused',
// // // //                   style: TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontSize: 28,
// // // //                     fontWeight: FontWeight.w800,
// // // //                     letterSpacing: -0.5,
// // // //                   ),
// // // //                 ),
// // // //                 const SizedBox(height: 12),
// // // //                 const Text(
// // // //                   'The host stepped away and will\nreturn shortly.',
// // // //                   textAlign: TextAlign.center,
// // // //                   style: TextStyle(
// // // //                     color: Colors.white70,
// // // //                     fontSize: 16,
// // // //                     height: 1.5,
// // // //                   ),
// // // //                 ),
// // // //                 const SizedBox(height: 40),
// // // //                 OutlinedButton(
// // // //                   style: OutlinedButton.styleFrom(
// // // //                     foregroundColor: Colors.white,
// // // //                     side: const BorderSide(color: Colors.white38),
// // // //                     padding: const EdgeInsets.symmetric(
// // // //                       horizontal: 32,
// // // //                       vertical: 14,
// // // //                     ),
// // // //                   ),
// // // //                   onPressed: widget.onLeave,
// // // //                   child: const Text('Leave for Now'),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // import 'dart:async';

// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_animate/flutter_animate.dart';
// // // import 'package:go_router/go_router.dart';
// // // import 'package:jma3a/core/router/app_router.dart';
// // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // import 'package:jma3a/features/rooms/domain/room_entity.dart';
// // // import 'package:jma3a/features/settings/presentation/screen_security_service.dart';
// // // import 'package:provider/provider.dart';
// // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // import '../../../../../core/di/service_locator.dart';
// // // import '../../../../../core/extensions/context_ext.dart';
// // // import '../../../../../core/providers/auth_provider.dart';
// // // import '../../../../../core/router/route_names.dart';
// // // import '../../../../../core/services/realtime_service.dart';
// // // // import '../../../../../core/services/screen_security_service.dart';
// // // import '../../../../../core/theme/app_colors.dart';
// // // import '../../../../../shared/widgets/feedback/error_view.dart';
// // // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // // import '../../domain/tod_models.dart';
// // // import '../../tod_game_provider.dart';

// // // import '../../data/tod_repository.dart';
// // // import 'tod_card_screen.dart';
// // // import 'tod_end_screen.dart';
// // // import 'tod_loading_screen.dart';
// // // import 'tod_punishment_screen.dart';
// // // import '../widgets/tod_hud.dart';

// // // class TodGameScreen extends StatefulWidget {
// // //   const TodGameScreen({
// // //     super.key,
// // //     required this.roomId,
// // //     required this.config,
// // //     required this.playerIds,
// // //     required this.playerDisplayNames,
// // //     required this.packId,
// // //     required this.isOwner,
// // //     this.sessionId,
// // //     this.isModerator = false,
// // //     this.packCoverUrl,
// // //   });

// // //   final String roomId;
// // //   final GameConfig config;
// // //   final List<String> playerIds;
// // //   final Map<String, String> playerDisplayNames;
// // //   final String packId;
// // //   final bool isOwner;
// // //   final String? sessionId;
// // //   final bool isModerator;
// // //   final String? packCoverUrl;

// // //   @override
// // //   State<TodGameScreen> createState() => _TodGameScreenState();
// // // }

// // // class _TodGameScreenState extends State<TodGameScreen> {
// // //   late final TodGameProvider _provider;

// // //   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;
// // //   bool _isNavigatingAway = false;
// // //   @override
// // //   void initState() {
// // //     super.initState();

// // //     ScreenSecurityService.instance.enable();
// // //     ScreenSecurityService.instance.enableScreenshotDetection(() {
// // //       sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // //         'type': 'screenshot_taken',
// // //         'user_id': context.read<AuthProvider>().currentUser?.id,
// // //       }).ignore();
// // //     });

// // //     final auth = context.read<AuthProvider>();
// // //     final user = auth.currentUser!;

// // //     _provider = TodGameProvider(
// // //       realtimeService: sl.realtimeService,
// // //       repository: TodRepository.instance,
// // //       currentUserId: user.id,
// // //       currentDisplayName: user.displayName ?? user.username ?? 'Player',
// // //       isModerator: widget.isModerator,
// // //     );

// // //     _wireRealtimeCallbacks();

// // //     if (widget.isOwner) {
// // //       final isPremium =
// // //           context.read<AuthProvider>().currentUser?.isPremium ?? false;
// // //       _provider.initAsOwner(
// // //         roomId: widget.roomId,
// // //         config: widget.config,
// // //         playerIds: widget.playerIds,
// // //         playerDisplayNames: widget.playerDisplayNames,
// // //         packId: widget.packId,
// // //         isPremium: isPremium,
// // //         packCoverUrl: widget.packCoverUrl,
// // //       );
// // //     } else {
// // //       _provider.initAsFollower(
// // //         roomId: widget.roomId,
// // //         config: widget.config,
// // //         sessionId: widget.sessionId,
// // //         packCoverUrl: widget.packCoverUrl,
// // //       );
// // //     }
// // //   }

// // //   @override
// // //   void dispose() {
// // //     ScreenSecurityService.instance.disable();
// // //     _statusSub?.cancel();
// // //     sl.realtimeService
// // //         .subscribe(
// // //           roomId: widget.roomId,
// // //           onGameState: (_) {},
// // //           onPlayerAction: (_) {},
// // //           onSyncRequest: (_) {},
// // //           onGameStarted: (_) {},
// // //           onGameEnded: (_) {},
// // //           onRoomEvent: (_) {},
// // //           onChatMessage: (_) {},
// // //           onModeration: (_) {},
// // //           onSettingsChange: (_) {},
// // //           onPresenceSync: (_) {},
// // //           onPresenceJoin: (_) {},
// // //           onPresenceLeave: (_) {},
// // //           onStatusChange: (_) {},
// // //         )
// // //         .ignore();
// // //     _provider.dispose();
// // //     super.dispose();
// // //   }

// // //   void _wireRealtimeCallbacks() {
// // //     _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
// // //       status,
// // //     ) {
// // //       if (status == RealtimeSubscribeStatus.subscribed &&
// // //           !_provider.hasSyncedState) {
// // //         sl.realtimeService.broadcastSyncRequest(
// // //           widget.roomId,
// // //           context.read<AuthProvider>().currentUser!.id,
// // //           0,
// // //         );
// // //       }
// // //     });

// // //     _resubscribeWithGameHandlers();
// // //   }

// // //   void _resubscribeWithGameHandlers() {
// // //     final userId = context.read<AuthProvider>().currentUser!.id;

// // //     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
// // //       sl.realtimeService.subscribe(
// // //         roomId: widget.roomId,
// // //         onGameState: (p) => _provider.onStateBroadcast(p),
// // //         onPlayerAction: (p) => _provider.onPlayerAction(p),
// // //         onSyncRequest: (p) => _provider.onSyncRequest(p),
// // //         onGameStarted: (_) {},
// // //         onGameEnded: (p) {
// // //           if (mounted) {
// // //             ScaffoldMessenger.of(context).showSnackBar(
// // //               const SnackBar(content: Text('The host ended the game')),
// // //             );
// // //             if (context.canPop())
// // //               context.pop();
// // //             else
// // //               context.go(RouteNames.home);
// // //           }
// // //         },
// // //         onRoomEvent: (p) {
// // //           final type = p['type'] as String?;
// // //           if (type == 'screenshot_taken') {
// // //             final shooterId = p['user_id'] as String?;
// // //             final myId = context.read<AuthProvider>().currentUser?.id;
// // //             if (shooterId != null && shooterId != myId && mounted) {
// // //               ScaffoldMessenger.of(context).showSnackBar(
// // //                 SnackBar(
// // //                   content: Text(
// // //                     '📸 ${widget.playerDisplayNames[shooterId] ?? 'Someone'} took a screenshot',
// // //                   ),
// // //                   backgroundColor: Colors.black87,
// // //                 ),
// // //               );
// // //             }
// // //             return;
// // //           }
// // //           if (type == 'player_left' && mounted) {
// // //             final name = p['display_name'] as String? ?? 'A player';
// // //             final leavingId = p['user_id'] as String?;
// // //             if (leavingId != null) {
// // //               _provider.markPlayerAway(leavingId, forGood: true);
// // //               if (widget.isOwner) {
// // //                 final active =
// // //                     _provider.state?.playerOrder
// // //                         .where((id) => !_provider.awayPlayerIds.contains(id))
// // //                         .toList() ??
// // //                     [];
// // //                 if (active.length <= 1) {
// // //                   WidgetsBinding.instance.addPostFrameCallback((_) async {
// // //                     if (!mounted) return;
// // //                     try {
// // //                       await sl.realtimeService.broadcastRoomEvent(
// // //                         widget.roomId,
// // //                         {'type': 'game_ended', 'reason': 'all_players_left'},
// // //                       );
// // //                       await sl.roomRepository.updateStatus(
// // //                         widget.roomId,
// // //                         RoomStatus.waiting,
// // //                       );
// // //                     } catch (_) {}
// // //                     if (mounted) {
// // //                       ScaffoldMessenger.of(context).showSnackBar(
// // //                         const SnackBar(
// // //                           content: Text('All players left — game ended'),
// // //                           behavior: SnackBarBehavior.fixed,
// // //                         ),
// // //                       );
// // //                       await Future.delayed(const Duration(milliseconds: 600));
// // //                       if (mounted) {
// // //                         _isNavigatingAway = true;
// // //                         if (context.canPop())
// // //                           context.pop();
// // //                         else
// // //                           context.go('/home/room/${widget.roomId}');
// // //                       }
// // //                     }
// // //                   });
// // //                   return;
// // //                 }
// // //               }
// // //             }
// // //             ScaffoldMessenger.of(context).showSnackBar(
// // //               SnackBar(
// // //                 content: Text('👋 $name left the game'),
// // //                 backgroundColor: Colors.red.shade700,
// // //                 duration: const Duration(seconds: 3),
// // //                 behavior: SnackBarBehavior.fixed,
// // //               ),
// // //             );
// // //             return;
// // //           }
// // //           if (type == 'ownership_transferred' && mounted) {
// // //             final myId = context.read<AuthProvider>().currentUser?.id;
// // //             final newOwnerId = p['new_owner_id'] as String?;
// // //             if (newOwnerId == myId) {
// // //               ScaffoldMessenger.of(context).showSnackBar(
// // //                 const SnackBar(
// // //                   content: Text('👑 You are now the game host!'),
// // //                   backgroundColor: Colors.purple,
// // //                 ),
// // //               );
// // //             }
// // //             return;
// // //           }
// // //           if (type == 'game_ended' && mounted) {
// // //             final reason = p['reason'] as String? ?? '';
// // //             WidgetsBinding.instance.addPostFrameCallback((_) {
// // //               if (!mounted) return;
// // //               final msg = reason == 'all_players_left'
// // //                   ? '👋 All players left — game ended'
// // //                   : '🔄 Host ended the game';
// // //               ScaffoldMessenger.of(context).showSnackBar(
// // //                 SnackBar(
// // //                   content: Text(msg),
// // //                   duration: const Duration(seconds: 3),
// // //                   behavior: SnackBarBehavior.fixed,
// // //                 ),
// // //               );
// // //               if (context.canPop()) {
// // //                 context.pop();
// // //               } else {
// // //                 context.go('/home/room/\${widget.roomId}');
// // //               }
// // //             });
// // //             return;
// // //           }
// // //           if (type == 'tod_ready_count') {
// // //             final ids = (p['ready_user_ids'] as List?)?.cast<String>() ?? [];
// // //             _provider.onReadyCountUpdate(ids);
// // //             return;
// // //           }
// // //           if ((type == 'room_closed' || type == 'owner_left') && mounted) {
// // //             WidgetsBinding.instance.addPostFrameCallback((_) {
// // //               if (!mounted) {
// // //                 AppRouter.router.go(RouteNames.home);
// // //                 return;
// // //               }
// // //               showDialog(
// // //                 context: context,
// // //                 barrierDismissible: false,
// // //                 builder: (ctx2) => AlertDialog(
// // //                   title: const Text('Room Closed'),
// // //                   content: const Text('The host closed the room.'),
// // //                   actions: [
// // //                     FilledButton(
// // //                       onPressed: () {
// // //                         Navigator.of(ctx2).pop();
// // //                         AppRouter.router.go(RouteNames.home);
// // //                       },
// // //                       child: const Text('OK'),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               );
// // //             });
// // //             return;
// // //           }
// // //         },
// // //         onChatMessage: (p) {
// // //           final msg = TodChatMsg(
// // //             senderId: p['user_id'] as String? ?? '',
// // //             senderName: p['display_name'] as String? ?? 'Player',
// // //             text: p['content'] as String? ?? '',
// // //             ts: DateTime.fromMillisecondsSinceEpoch(
// // //               (p['ts'] as num?)?.toInt() ??
// // //                   DateTime.now().millisecondsSinceEpoch,
// // //             ),
// // //           );
// // //           _provider.addChatMessage(msg);
// // //         },
// // //         onModeration: (p) => _handleModerationEvent(p),
// // //         onSettingsChange: (_) {},
// // //         onPresenceSync: (_) {},
// // //         onPresenceJoin: (_) {},
// // //         onPresenceLeave: (_) {},
// // //         onStatusChange: (status) {
// // //           if (!mounted) return;
// // //           if (status == RealtimeSubscribeStatus.subscribed &&
// // //               !_provider.hasSyncedState) {
// // //             sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
// // //           }
// // //         },
// // //       );
// // //     });
// // //   }

// // //   void _handleModerationEvent(Map<String, dynamic> p) {
// // //     final type = p['type'] as String?;
// // //     final targetId = p['target_user_id'] as String?;
// // //     final currentId = context.read<AuthProvider>().currentUser?.id;

// // //     if ((type == 'kick' || type == 'ban') && targetId == currentId) {
// // //       if (mounted) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(content: Text('You were removed from the room')),
// // //         );
// // //         context.go(RouteNames.home);
// // //       }
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return ChangeNotifierProvider.value(
// // //       value: _provider,
// // //       child: Consumer<TodGameProvider>(
// // //         builder: (ctx, game, _) => _build(ctx, game),
// // //       ),
// // //     );
// // //   }

// // //   Widget _build(BuildContext ctx, TodGameProvider game) {
// // //     if (game.loadState == TodLoadState.loading) {
// // //       return const TodLoadingScreen();
// // //     }

// // //     if (game.loadState == TodLoadState.error) {
// // //       return Scaffold(
// // //         appBar: AppBar(
// // //           leading: BackButton(
// // //             onPressed: () async {
// // //               if (widget.isOwner) {
// // //                 try {
// // //                   await sl.realtimeService.broadcastGameEnded(widget.roomId, {
// // //                     'reason': 'host_left',
// // //                   });
// // //                   await sl.roomRepository.updateStatus(
// // //                     widget.roomId,
// // //                     RoomStatus.waiting,
// // //                   );
// // //                 } catch (_) {}
// // //               }
// // //               if (ctx.mounted) ctx.go(RouteNames.home);
// // //             },
// // //           ),
// // //         ),
// // //         body: ErrorView(
// // //           message: game.error ?? 'Failed to load game',
// // //           onRetry: () => ctx.go(RouteNames.home),
// // //         ),
// // //       );
// // //     }

// // //     if (game.loadState == TodLoadState.gameOver ||
// // //         (game.state?.isOver ?? false)) {
// // //       return TodEndScreen(
// // //         state: game.state!,
// // //         displayNames: widget.playerDisplayNames,
// // //         onLeave: () => ctx.go(RouteNames.home),
// // //       );
// // //     }

// // //     final state = game.state;
// // //     if (state == null) return const TodLoadingScreen();

// // //     return _TodGameScaffold(
// // //       state: state,
// // //       game: game,
// // //       displayNames: widget.playerDisplayNames,
// // //       roomId: widget.roomId,
// // //       isOwner: widget.isOwner,
// // //     );
// // //   }
// // // }

// // // class _TodGameScaffold extends StatefulWidget {
// // //   const _TodGameScaffold({
// // //     required this.state,
// // //     required this.game,
// // //     required this.displayNames,
// // //     required this.roomId,
// // //     required this.isOwner,
// // //   });
// // //   final TodState state;
// // //   final TodGameProvider game;
// // //   final Map<String, String> displayNames;
// // //   final String roomId;
// // //   final bool isOwner;
// // //   @override
// // //   State<_TodGameScaffold> createState() => _TodGameScaffoldState();
// // // }

// // // class _TodGameScaffoldState extends State<_TodGameScaffold> {
// // //   bool _showHistory = false;
// // //   bool _showChat = false;
// // //   int _unreadChat = 0;
// // //   bool _isNavigatingAway = false;

// // //   void _navigateAway(BuildContext ctx, String location) {
// // //     _isNavigatingAway = true;
// // //     if (ctx.canPop()) {
// // //       ctx.pop();
// // //     } else {
// // //       ctx.go(location);
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final state = widget.state;
// // //     final game = widget.game;

// // //     if (_showHistory) {
// // //       return Scaffold(
// // //         appBar: AppBar(
// // //           leading: BackButton(
// // //             onPressed: () => setState(() => _showHistory = false),
// // //           ),
// // //           title: Text('History (${state.history.length} rounds)'),
// // //         ),
// // //         body: _HistoryPanel(
// // //           history: state.history,
// // //           displayNames: widget.displayNames,
// // //         ),
// // //       );
// // //     }

// // //     return PopScope(
// // //       canPop: false,
// // //       onPopInvoked: (_) {
// // //         if (_isNavigatingAway) return;
// // //         WidgetsBinding.instance.addPostFrameCallback(
// // //           (_) => _showLeaveDialog(context, game, state),
// // //         );
// // //       },
// // //       child: Scaffold(
// // //         appBar: AppBar(
// // //           automaticallyImplyLeading: false,
// // //           title: const Text(''),
// // //           leading: IconButton(
// // //             icon: const Icon(Icons.arrow_back),
// // //             onPressed: () => _showLeaveDialog(context, game, state),
// // //           ),
// // //           actions: [
// // //             Consumer<TodGameProvider>(
// // //               builder: (_, g, __) => Stack(
// // //                 alignment: Alignment.topRight,
// // //                 children: [
// // //                   IconButton(
// // //                     icon: const Icon(Icons.chat_bubble_outline_rounded),
// // //                     onPressed: () {
// // //                       g.clearUnreadChat();
// // //                       showModalBottomSheet(
// // //                         context: context,
// // //                         isScrollControlled: true,
// // //                         backgroundColor: Colors.transparent,
// // //                         builder: (_) =>
// // //                             _InGameChatSheet(game: g, myId: g.currentUserId),
// // //                       );
// // //                     },
// // //                   ),
// // //                   if (g.unreadChat > 0)
// // //                     Positioned(
// // //                       top: 8,
// // //                       right: 8,
// // //                       child: Container(
// // //                         width: 8,
// // //                         height: 8,
// // //                         decoration: const BoxDecoration(
// // //                           color: Colors.red,
// // //                           shape: BoxShape.circle,
// // //                         ),
// // //                       ),
// // //                     ),
// // //                 ],
// // //               ),
// // //             ),
// // //             if (state.history.isNotEmpty)
// // //               IconButton(
// // //                 icon: const Icon(Icons.history_rounded),
// // //                 tooltip: 'History',
// // //                 onPressed: () => setState(() => _showHistory = true),
// // //               ),
// // //           ],
// // //         ),
// // //         body: SafeArea(
// // //           child: Column(
// // //             children: [
// // //               TodHud(
// // //                 state: state,
// // //                 game: game,
// // //                 displayNames: widget.displayNames,
// // //               ),
// // //               Expanded(
// // //                 child: AnimatedSwitcher(
// // //                   duration: const Duration(milliseconds: 300),
// // //                   transitionBuilder: (child, anim) => FadeTransition(
// // //                     opacity: anim,
// // //                     child: SlideTransition(
// // //                       position:
// // //                           Tween<Offset>(
// // //                             begin: const Offset(0, 0.05),
// // //                             end: Offset.zero,
// // //                           ).animate(
// // //                             CurvedAnimation(
// // //                               parent: anim,
// // //                               curve: Curves.easeOutCubic,
// // //                             ),
// // //                           ),
// // //                       child: child,
// // //                     ),
// // //                   ),
// // //                   child: KeyedSubtree(
// // //                     key: ValueKey('${state.phase}-${state.currentPlayerId}'),
// // //                     child: _phaseWidget(
// // //                       context,
// // //                       game,
// // //                       widget.displayNames,
// // //                       state,
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   Future<void> _showLeaveDialog(
// // //     BuildContext ctx,
// // //     TodGameProvider game,
// // //     TodState state,
// // //   ) async {
// // //     if (!ctx.mounted) return;
// // //     final isOwner = widget.isOwner;
// // //     final myUserId = game.currentUserId;
// // //     final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

// // //     if (isOwner) {
// // //       final confirmed = await showDialog<bool>(
// // //         context: ctx,
// // //         builder: (dCtx) => AlertDialog(
// // //           title: const Text('Quit Game?'),
// // //           content: const Text(
// // //             'The game will end for everyone and all players will return to the lobby.',
// // //           ),
// // //           actions: [
// // //             TextButton(
// // //               onPressed: () => Navigator.of(dCtx).pop(false),
// // //               child: const Text('Cancel'),
// // //             ),
// // //             FilledButton(
// // //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // //               onPressed: () => Navigator.of(dCtx).pop(true),
// // //               child: const Text('End Game for Everyone'),
// // //             ),
// // //           ],
// // //         ),
// // //       );
// // //       if (confirmed != true || !ctx.mounted) return;

// // //       try {
// // //         await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // //           'type': 'game_ended',
// // //           'reason': 'host_quit_to_lobby',
// // //         });
// // //         await Future.delayed(const Duration(milliseconds: 400));
// // //         await sl.roomRepository.updateStatus(widget.roomId, RoomStatus.waiting);
// // //       } catch (_) {}
// // //       if (ctx.mounted) {
// // //         _isNavigatingAway = true;
// // //         if (ctx.canPop()) {
// // //           ctx.pop();
// // //         } else {
// // //           ctx.go('/home/room/${widget.roomId}');
// // //         }
// // //       }
// // //     } else {
// // //       final confirmed = await showDialog<bool>(
// // //         context: ctx,
// // //         builder: (_) => AlertDialog(
// // //           title: const Text('Leave Game?'),
// // //           content: const Text('You will be removed from the game.'),
// // //           actions: [
// // //             TextButton(
// // //               onPressed: () => Navigator.pop(ctx, false),
// // //               child: const Text('Stay'),
// // //             ),
// // //             FilledButton(
// // //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // //               onPressed: () => Navigator.pop(ctx, true),
// // //               child: const Text('Quit Game'),
// // //             ),
// // //           ],
// // //         ),
// // //       );
// // //       if (confirmed != true || !ctx.mounted) return;

// // //       final displayName = widget.displayNames[myUserId] ?? 'A player';
// // //       try {
// // //         await sl.roomRepository.setMemberDefinitiveLeave(
// // //           widget.roomId,
// // //           myUserId,
// // //         );
// // //         await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // //           'type': 'player_left',
// // //           'user_id': myUserId,
// // //           'display_name': displayName,
// // //           'for_good': true,
// // //         });
// // //       } catch (_) {}
// // //       if (ctx.mounted) {
// // //         _isNavigatingAway = true;
// // //         ctx.go('/home/room/${widget.roomId}');
// // //       }
// // //     }
// // //   }

// // //   Widget _phaseWidget(
// // //     BuildContext ctx,
// // //     TodGameProvider game,
// // //     Map<String, String> displayNames,
// // //     TodState state,
// // //   ) {
// // //     return switch (state.phase) {
// // //       TodTurnPhase.punishmentVoting => TodPunishmentScreen(
// // //         state: state,
// // //         game: game,
// // //         displayNames: widget.displayNames,
// // //       ),
// // //       _ => TodCardScreen(
// // //         state: state,
// // //         game: game,
// // //         displayNames: widget.displayNames,
// // //       ),
// // //     };
// // //   }
// // // }

// // // class _HistoryPanel extends StatelessWidget {
// // //   const _HistoryPanel({required this.history, required this.displayNames});
// // //   final List<TodRoundRecord> history;
// // //   final Map<String, String> displayNames;

// // //   String _name(String id) =>
// // //       displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;
// // //     if (history.isEmpty) {
// // //       return const Center(child: Text('No rounds completed yet.'));
// // //     }
// // //     return ListView.builder(
// // //       padding: const EdgeInsets.all(12),
// // //       itemCount: history.length,
// // //       itemBuilder: (_, i) {
// // //         final round = history[history.length - 1 - i];
// // //         final reactTally = <String, int>{};
// // //         for (final r in round.reactions) {
// // //           reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
// // //         }
// // //         return Card(
// // //           margin: const EdgeInsets.only(bottom: 10),
// // //           child: ExpansionTile(
// // //             leading: CircleAvatar(
// // //               backgroundColor: theme.colorScheme.primaryContainer,
// // //               child: Text(
// // //                 '${round.roundNumber}',
// // //                 style: theme.textTheme.labelLarge,
// // //               ),
// // //             ),
// // //             title: Text(
// // //               _name(round.playerId),
// // //               style: theme.textTheme.bodyMedium?.copyWith(
// // //                 fontWeight: FontWeight.w700,
// // //               ),
// // //             ),
// // //             subtitle: Text(
// // //               round.card != null
// // //                   ? '${round.card!.type == TodCardType.truth ? "Truth" : "Dare"}: ${round.card!.content}'
// // //                   : 'Skipped',
// // //               maxLines: 1,
// // //               overflow: TextOverflow.ellipsis,
// // //               style: theme.textTheme.bodySmall,
// // //             ),
// // //             children: [
// // //               Padding(
// // //                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
// // //                 child: Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   children: [
// // //                     if (round.card != null)
// // //                       Container(
// // //                         width: double.infinity,
// // //                         padding: const EdgeInsets.all(10),
// // //                         decoration: BoxDecoration(
// // //                           color: round.card!.type == TodCardType.truth
// // //                               ? Colors.blue.withOpacity(0.08)
// // //                               : Colors.orange.withOpacity(0.08),
// // //                           borderRadius: BorderRadius.circular(8),
// // //                         ),
// // //                         child: Text(
// // //                           round.card!.content,
// // //                           style: theme.textTheme.bodyMedium,
// // //                         ),
// // //                       ),
// // //                     if (round.response.isNotEmpty) ...[
// // //                       const SizedBox(height: 8),
// // //                       Row(
// // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // //                         children: [
// // //                           const Text('💬 ', style: TextStyle(fontSize: 14)),
// // //                           Expanded(
// // //                             child: Text(
// // //                               '"${round.response}"',
// // //                               style: theme.textTheme.bodySmall?.copyWith(
// // //                                 fontStyle: FontStyle.italic,
// // //                               ),
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                     ],
// // //                     if (round.voteCount > 0) ...[
// // //                       const SizedBox(height: 6),
// // //                       Text(
// // //                         '👍 ${round.voteCount} vote${round.voteCount != 1 ? "s" : ""}',
// // //                         style: theme.textTheme.bodySmall?.copyWith(
// // //                           color: theme.colorScheme.primary,
// // //                           fontWeight: FontWeight.w600,
// // //                         ),
// // //                       ),
// // //                     ],
// // //                     if (round.hadProof) ...[
// // //                       const SizedBox(height: 8),
// // //                       _ProofWatchedBadge(watchedBy: round.proofWatchedBy),
// // //                     ],
// // //                     if (reactTally.isNotEmpty) ...[
// // //                       const SizedBox(height: 8),
// // //                       Wrap(
// // //                         spacing: 6,
// // //                         runSpacing: 4,
// // //                         children: reactTally.entries
// // //                             .map(
// // //                               (e) => Container(
// // //                                 padding: const EdgeInsets.symmetric(
// // //                                   horizontal: 8,
// // //                                   vertical: 3,
// // //                                 ),
// // //                                 decoration: BoxDecoration(
// // //                                   color:
// // //                                       theme.colorScheme.surfaceContainerHighest,
// // //                                   borderRadius: BorderRadius.circular(16),
// // //                                 ),
// // //                                 child: Text(
// // //                                   '${e.key} ${e.value}',
// // //                                   style: const TextStyle(fontSize: 13),
// // //                                 ),
// // //                               ),
// // //                             )
// // //                             .toList(),
// // //                       ),
// // //                     ],
// // //                   ],
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // // }

// // // class _ProofWatchedBadge extends StatelessWidget {
// // //   const _ProofWatchedBadge({required this.watchedBy});
// // //   final List<String> watchedBy;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final watched = watchedBy.isNotEmpty;
// // //     return Container(
// // //       height: 36,
// // //       padding: const EdgeInsets.symmetric(horizontal: 10),
// // //       decoration: BoxDecoration(
// // //         color: Colors.grey.shade200,
// // //         borderRadius: BorderRadius.circular(8),
// // //       ),
// // //       alignment: Alignment.centerLeft,
// // //       child: Row(
// // //         mainAxisSize: MainAxisSize.min,
// // //         children: [
// // //           Icon(
// // //             watched ? Icons.visibility_outlined : Icons.visibility_off_outlined,
// // //             size: 16,
// // //             color: Colors.grey.shade600,
// // //           ),
// // //           const SizedBox(width: 6),
// // //           Text(
// // //             watched
// // //                 ? 'Proof watched by ${watchedBy.length}'
// // //                 : 'Proof sent — not watched',
// // //             style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _InGameChatSheet extends StatefulWidget {
// // //   const _InGameChatSheet({required this.game, required this.myId});
// // //   final TodGameProvider game;
// // //   final String myId;
// // //   @override
// // //   State<_InGameChatSheet> createState() => _InGameChatSheetState();
// // // }

// // // class _InGameChatSheetState extends State<_InGameChatSheet> {
// // //   final _ctrl = TextEditingController();
// // //   final _scroll = ScrollController();
// // //   @override
// // //   void dispose() {
// // //     _ctrl.dispose();
// // //     _scroll.dispose();
// // //     super.dispose();
// // //   }

// // //   void _send() {
// // //     final t = _ctrl.text.trim();
// // //     if (t.isEmpty) return;
// // //     widget.game.sendChat(t);
// // //     _ctrl.clear();
// // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // //       if (_scroll.hasClients)
// // //         _scroll.animateTo(
// // //           _scroll.position.maxScrollExtent,
// // //           duration: 200.ms,
// // //           curve: Curves.easeOut,
// // //         );
// // //     });
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       height: MediaQuery.sizeOf(context).height * 0.65,
// // //       decoration: const BoxDecoration(
// // //         color: Color(0xFF1A2E45),
// // //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// // //       ),
// // //       child: Column(
// // //         children: [
// // //           Container(
// // //             width: 36,
// // //             height: 4,
// // //             margin: const EdgeInsets.symmetric(vertical: 10),
// // //             decoration: BoxDecoration(
// // //               color: Colors.white24,
// // //               borderRadius: BorderRadius.circular(2),
// // //             ),
// // //           ),
// // //           const Text(
// // //             '💬 Chat',
// // //             style: TextStyle(
// // //               color: Colors.white,
// // //               fontWeight: FontWeight.w800,
// // //               fontSize: 16,
// // //             ),
// // //           ),
// // //           const Divider(color: Colors.white12),
// // //           Expanded(
// // //             child: ListenableBuilder(
// // //               listenable: widget.game,
// // //               builder: (_, __) {
// // //                 final msgs = widget.game.chatMessages;
// // //                 return msgs.isEmpty
// // //                     ? const Center(
// // //                         child: Text(
// // //                           'No messages yet',
// // //                           style: TextStyle(color: Colors.white38),
// // //                         ),
// // //                       )
// // //                     : ListView.builder(
// // //                         controller: _scroll,
// // //                         padding: const EdgeInsets.all(12),
// // //                         itemCount: msgs.length,
// // //                         itemBuilder: (_, i) {
// // //                           final m = msgs[i];
// // //                           final isMe = m.senderId == widget.myId;
// // //                           final color =
// // //                               _kChatColors[m.senderId.hashCode.abs() %
// // //                                   _kChatColors.length];
// // //                           return Padding(
// // //                             padding: EdgeInsets.only(
// // //                               bottom: 8,
// // //                               left: isMe ? 48 : 0,
// // //                               right: isMe ? 0 : 48,
// // //                             ),
// // //                             child: Column(
// // //                               crossAxisAlignment: isMe
// // //                                   ? CrossAxisAlignment.end
// // //                                   : CrossAxisAlignment.start,
// // //                               children: [
// // //                                 if (!isMe)
// // //                                   Padding(
// // //                                     padding: const EdgeInsets.only(
// // //                                       left: 4,
// // //                                       bottom: 2,
// // //                                     ),
// // //                                     child: Text(
// // //                                       m.senderName,
// // //                                       style: TextStyle(
// // //                                         color: color,
// // //                                         fontSize: 11,
// // //                                         fontWeight: FontWeight.w700,
// // //                                       ),
// // //                                     ),
// // //                                   ),
// // //                                 Container(
// // //                                   padding: const EdgeInsets.symmetric(
// // //                                     horizontal: 12,
// // //                                     vertical: 8,
// // //                                   ),
// // //                                   decoration: BoxDecoration(
// // //                                     color: isMe
// // //                                         ? const Color(0xFFFFD60A)
// // //                                         : color.withOpacity(0.18),
// // //                                     borderRadius: BorderRadius.circular(16)
// // //                                         .copyWith(
// // //                                           bottomRight: isMe
// // //                                               ? const Radius.circular(4)
// // //                                               : null,
// // //                                           bottomLeft: isMe
// // //                                               ? null
// // //                                               : const Radius.circular(4),
// // //                                         ),
// // //                                   ),
// // //                                   child: Text(
// // //                                     m.text,
// // //                                     style: TextStyle(
// // //                                       color: isMe
// // //                                           ? const Color(0xFF0D1B2A)
// // //                                           : Colors.white,
// // //                                       fontWeight: isMe
// // //                                           ? FontWeight.w700
// // //                                           : FontWeight.w400,
// // //                                     ),
// // //                                   ),
// // //                                 ),
// // //                               ],
// // //                             ),
// // //                           );
// // //                         },
// // //                       );
// // //               },
// // //             ),
// // //           ),
// // //           Container(
// // //             padding: EdgeInsets.fromLTRB(
// // //               12,
// // //               8,
// // //               12,
// // //               MediaQuery.viewInsetsOf(context).bottom + 12,
// // //             ),
// // //             color: const Color(0xFF1A2E45),
// // //             child: Row(
// // //               children: [
// // //                 Expanded(
// // //                   child: TextField(
// // //                     controller: _ctrl,
// // //                     style: const TextStyle(color: Colors.white),
// // //                     textInputAction: TextInputAction.send,
// // //                     onSubmitted: (_) => _send(),
// // //                     decoration: InputDecoration(
// // //                       hintText: 'Say something…',
// // //                       hintStyle: const TextStyle(color: Colors.white38),
// // //                       filled: true,
// // //                       fillColor: Colors.white.withOpacity(0.07),
// // //                       border: OutlineInputBorder(
// // //                         borderRadius: BorderRadius.circular(24),
// // //                         borderSide: BorderSide.none,
// // //                       ),
// // //                       contentPadding: const EdgeInsets.symmetric(
// // //                         horizontal: 16,
// // //                         vertical: 10,
// // //                       ),
// // //                       isDense: true,
// // //                     ),
// // //                   ),
// // //                 ),
// // //                 const SizedBox(width: 8),
// // //                 GestureDetector(
// // //                   onTap: _send,
// // //                   child: Container(
// // //                     width: 44,
// // //                     height: 44,
// // //                     decoration: const BoxDecoration(
// // //                       color: Color(0xFFFFD60A),
// // //                       shape: BoxShape.circle,
// // //                     ),
// // //                     child: const Icon(
// // //                       Icons.send_rounded,
// // //                       color: Color(0xFF0D1B2A),
// // //                       size: 20,
// // //                     ),
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

// // // const _kChatColors = [
// // //   Color(0xFF4ECDC4),
// // //   Color(0xFFA855F7),
// // //   Color(0xFFFF6B6B),
// // //   Color(0xFF4ADE80),
// // //   Color(0xFFFB923C),
// // //   Color(0xFF60A5FA),
// // //   Color(0xFFF472B6),
// // //   Color(0xFFFFD60A),
// // //   Color(0xFF34D399),
// // //   Color(0xFFC084FC),
// // // ];

// // // class _PausedOverlay extends StatefulWidget {
// // //   const _PausedOverlay({required this.onLeave});
// // //   final VoidCallback onLeave;

// // //   @override
// // //   State<_PausedOverlay> createState() => _PausedOverlayState();
// // // }

// // // class _PausedOverlayState extends State<_PausedOverlay>
// // //     with SingleTickerProviderStateMixin {
// // //   late final AnimationController _pulse;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _pulse = AnimationController(
// // //       vsync: this,
// // //       duration: const Duration(milliseconds: 1400),
// // //     )..repeat(reverse: true);
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _pulse.dispose();
// // //     super.dispose();
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Dialog.fullscreen(
// // //       backgroundColor: Colors.transparent,
// // //       child: Scaffold(
// // //         backgroundColor: Colors.transparent,
// // //         body: Center(
// // //           child: Padding(
// // //             padding: const EdgeInsets.all(32),
// // //             child: Column(
// // //               mainAxisSize: MainAxisSize.min,
// // //               children: [
// // //                 AnimatedBuilder(
// // //                   animation: _pulse,
// // //                   builder: (_, child) =>
// // //                       Opacity(opacity: 0.6 + _pulse.value * 0.4, child: child),
// // //                   child: const Text('⏸', style: TextStyle(fontSize: 72)),
// // //                 ),
// // //                 const SizedBox(height: 24),
// // //                 const Text(
// // //                   'Game Paused',
// // //                   style: TextStyle(
// // //                     color: Colors.white,
// // //                     fontSize: 28,
// // //                     fontWeight: FontWeight.w800,
// // //                     letterSpacing: -0.5,
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 12),
// // //                 const Text(
// // //                   'The host stepped away and will\nreturn shortly.',
// // //                   textAlign: TextAlign.center,
// // //                   style: TextStyle(
// // //                     color: Colors.white70,
// // //                     fontSize: 16,
// // //                     height: 1.5,
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 40),
// // //                 OutlinedButton(
// // //                   style: OutlinedButton.styleFrom(
// // //                     foregroundColor: Colors.white,
// // //                     side: const BorderSide(color: Colors.white38),
// // //                     padding: const EdgeInsets.symmetric(
// // //                       horizontal: 32,
// // //                       vertical: 14,
// // //                     ),
// // //                   ),
// // //                   onPressed: widget.onLeave,
// // //                   child: const Text('Leave for Now'),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'dart:async';

// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:jma3a/core/router/app_router.dart';
// // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // import 'package:jma3a/features/rooms/domain/room_entity.dart';
// // import 'package:jma3a/features/settings/presentation/screen_security_service.dart';
// // import 'package:provider/provider.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';

// // import '../../../../../core/di/service_locator.dart';
// // import '../../../../../core/extensions/context_ext.dart';
// // import '../../../../../core/providers/auth_provider.dart';
// // import '../../../../../core/router/route_names.dart';
// // import '../../../../../core/services/realtime_service.dart';
// // import '../../../../../core/services/screen_security_service.dart';
// // import '../../../../../core/theme/app_colors.dart';
// // import '../../../../../shared/widgets/feedback/error_view.dart';
// // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // import '../../domain/tod_models.dart';
// // import '../../tod_game_provider.dart';

// // import '../../data/tod_repository.dart';
// // import 'tod_card_screen.dart';
// // import 'tod_end_screen.dart';
// // import 'tod_loading_screen.dart';
// // import 'tod_punishment_screen.dart';
// // import '../widgets/tod_hud.dart';

// // class TodGameScreen extends StatefulWidget {
// //   const TodGameScreen({
// //     super.key,
// //     required this.roomId,
// //     required this.config,
// //     required this.playerIds,
// //     required this.playerDisplayNames,
// //     required this.packId,
// //     required this.isOwner,
// //     this.sessionId,
// //     this.isModerator = false,
// //     this.packCoverUrl,
// //   });

// //   final String roomId;
// //   final GameConfig config;
// //   final List<String> playerIds;
// //   final Map<String, String> playerDisplayNames;
// //   final String packId;
// //   final bool isOwner;
// //   final String? sessionId;
// //   final bool isModerator;
// //   final String? packCoverUrl;

// //   @override
// //   State<TodGameScreen> createState() => _TodGameScreenState();
// // }

// // class _TodGameScreenState extends State<TodGameScreen> {
// //   late final TodGameProvider _provider;

// //   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

// //   @override
// //   void initState() {
// //     super.initState();

// //     ScreenSecurityService.instance.enable();
// //     ScreenSecurityService.instance.enableScreenshotDetection(() {
// //       sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// //         'type': 'screenshot_taken',
// //         'user_id': context.read<AuthProvider>().currentUser?.id,
// //       }).ignore();
// //     });

// //     final auth = context.read<AuthProvider>();
// //     final user = auth.currentUser!;

// //     _provider = TodGameProvider(
// //       realtimeService: sl.realtimeService,
// //       repository: TodRepository.instance,
// //       currentUserId: user.id,
// //       currentDisplayName: user.displayName ?? user.username ?? 'Player',
// //       isModerator: widget.isModerator,
// //     );

// //     _wireRealtimeCallbacks();

// //     if (widget.isOwner) {
// //       final isPremium =
// //           context.read<AuthProvider>().currentUser?.isPremium ?? false;
// //       _provider.initAsOwner(
// //         roomId: widget.roomId,
// //         config: widget.config,
// //         playerIds: widget.playerIds,
// //         playerDisplayNames: widget.playerDisplayNames,
// //         packId: widget.packId,
// //         isPremium: isPremium,
// //         packCoverUrl: widget.packCoverUrl,
// //       );
// //     } else {
// //       _provider.initAsFollower(
// //         roomId: widget.roomId,
// //         config: widget.config,
// //         sessionId: widget.sessionId,
// //         packCoverUrl: widget.packCoverUrl,
// //       );
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     ScreenSecurityService.instance.disable();
// //     _statusSub?.cancel();
// //     sl.realtimeService.subscribe(
// //       roomId: widget.roomId,
// //       onGameState: (_) {},
// //       onPlayerAction: (_) {},
// //       onSyncRequest: (_) {},
// //       onGameStarted: (_) {},
// //       onGameEnded: (_) {},
// //       onRoomEvent: (_) {},
// //       onChatMessage: (_) {},
// //       onModeration: (_) {},
// //       onSettingsChange: (_) {},
// //       onPresenceSync: (_) {},
// //       onPresenceJoin: (_) {},
// //       onPresenceLeave: (_) {},
// //       onStatusChange: (_) {},
// //     ).ignore();
// //     _provider.dispose();
// //     super.dispose();
// //   }

// //   void _wireRealtimeCallbacks() {
// //     _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
// //       status,
// //     ) {
// //       if (status == RealtimeSubscribeStatus.subscribed &&
// //           !_provider.hasSyncedState) {
// //         sl.realtimeService.broadcastSyncRequest(
// //           widget.roomId,
// //           context.read<AuthProvider>().currentUser!.id,
// //           0,
// //         );
// //       }
// //     });

// //     _resubscribeWithGameHandlers();
// //   }

// //   void _resubscribeWithGameHandlers() {
// //     final userId = context.read<AuthProvider>().currentUser!.id;

// //     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
// //       sl.realtimeService.subscribe(
// //         roomId: widget.roomId,
// //         onGameState: (p) => _provider.onStateBroadcast(p),
// //         onPlayerAction: (p) => _provider.onPlayerAction(p),
// //         onSyncRequest: (p) => _provider.onSyncRequest(p),
// //         onGameStarted: (_) {},
// //         onGameEnded: (p) {
// //           if (mounted) {
// //             ScaffoldMessenger.of(context).showSnackBar(
// //               const SnackBar(content: Text('The host ended the game')),
// //             );
// //             if (context.canPop())
// //               context.pop();
// //             else
// //               context.go(RouteNames.home);
// //           }
// //         },
// //         onRoomEvent: (p) {
// //           final type = p['type'] as String?;
// //           if (type == 'screenshot_taken') {
// //             final shooterId = p['user_id'] as String?;
// //             final myId = context.read<AuthProvider>().currentUser?.id;
// //             if (shooterId != null && shooterId != myId && mounted) {
// //               ScaffoldMessenger.of(context).showSnackBar(
// //                 SnackBar(
// //                   content: Text(
// //                     '📸 ${widget.playerDisplayNames[shooterId] ?? 'Someone'} took a screenshot',
// //                   ),
// //                   backgroundColor: Colors.black87,
// //                 ),
// //               );
// //             }
// //             return;
// //           }
// //           if (type == 'player_left' && mounted) {
// //             final name = p['display_name'] as String? ?? 'A player';
// //             final leavingId = p['user_id'] as String?;
// //             if (leavingId != null) {
// //               _provider.markPlayerAway(leavingId, forGood: true);
// //               if (widget.isOwner) {
// //                 final active = _provider.state?.playerOrder
// //                     .where((id) => !_provider.awayPlayerIds.contains(id))
// //                     .toList() ?? [];
// //                 if (active.length <= 1) {
// //                   WidgetsBinding.instance.addPostFrameCallback((_) async {
// //                     if (!mounted) return;
// //                     try {
// //                       await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// //                         'type': 'game_ended',
// //                         'reason': 'all_players_left',
// //                       });
// //                       await sl.roomRepository.updateStatus(widget.roomId, RoomStatus.waiting);
// //                     } catch (_) {}
// //                     if (mounted) {
// //                       ScaffoldMessenger.of(context).showSnackBar(
// //                         const SnackBar(
// //                           content: Text('All players left — game ended'),
// //                           behavior: SnackBarBehavior.fixed,
// //                         ),
// //                       );
// //                       await Future.delayed(const Duration(milliseconds: 600));
// //                       if (mounted) {
// //                         _isNavigatingAway = true;
// //                         if (context.canPop()) context.pop();
// //                         else context.go('/home/room/${widget.roomId}');
// //                       }
// //                     }
// //                   });
// //                   return;
// //                 }
// //               }
// //             }
// //             ScaffoldMessenger.of(context).showSnackBar(
// //               SnackBar(
// //                 content: Text('👋 $name left the game'),
// //                 backgroundColor: Colors.red.shade700,
// //                 duration: const Duration(seconds: 3),
// //                 behavior: SnackBarBehavior.fixed,
// //               ),
// //             );
// //             return;
// //           }
// //           if (type == 'ownership_transferred' && mounted) {
// //             final myId = context.read<AuthProvider>().currentUser?.id;
// //             final newOwnerId = p['new_owner_id'] as String?;
// //             if (newOwnerId == myId) {
// //               ScaffoldMessenger.of(context).showSnackBar(
// //                 const SnackBar(
// //                   content: Text('👑 You are now the game host!'),
// //                   backgroundColor: Colors.purple,
// //                 ),
// //               );
// //             }
// //             return;
// //           }
// //           if (type == 'game_ended' && mounted) {
// //             final reason = p['reason'] as String? ?? '';
// //             WidgetsBinding.instance.addPostFrameCallback((_) {
// //               if (!mounted) return;
// //               final isAllLeft = reason == 'all_players_left';
// //               showDialog(
// //                 context: context,
// //                 barrierDismissible: false,
// //                 builder: (ctx2) => AlertDialog(
// //                   title: Text(isAllLeft ? 'Game Over' : 'Game Ended'),
// //                   content: Text(
// //                     isAllLeft
// //                         ? 'All players left the game.'
// //                         : 'The host ended the game.',
// //                   ),
// //                   actions: [
// //                     FilledButton(
// //                       onPressed: () {
// //                         Navigator.of(ctx2).pop();
// //                         _isNavigatingAway = true;
// //                         if (context.canPop()) {
// //                           context.pop();
// //                         } else {
// //                           context.go('/home/room/${widget.roomId}');
// //                         }
// //                       },
// //                       child: const Text('Go to Lobby'),
// //                     ),
// //                   ],
// //                 ),
// //               );
// //             });
// //             return;
// //           }
// //           if (type == 'tod_ready_count') {
// //             final ids = (p['ready_user_ids'] as List?)?.cast<String>() ?? [];
// //             _provider.onReadyCountUpdate(ids);
// //             return;
// //           }
// //           if ((type == 'room_closed' || type == 'owner_left') && mounted) {
// //             WidgetsBinding.instance.addPostFrameCallback((_) {
// //               if (!mounted) { AppRouter.router.go(RouteNames.home); return; }
// //               showDialog(
// //                 context: context,
// //                 barrierDismissible: false,
// //                 builder: (ctx2) => AlertDialog(
// //                   title: const Text('Room Closed'),
// //                   content: const Text('The host closed the room.'),
// //                   actions: [
// //                     FilledButton(
// //                       onPressed: () {
// //                         Navigator.of(ctx2).pop();
// //                         AppRouter.router.go(RouteNames.home);
// //                       },
// //                       child: const Text('OK'),
// //                     ),
// //                   ],
// //                 ),
// //               );
// //             });
// //             return;
// //           }
// //         },
// //         onChatMessage: (p) {
// //           final msg = TodChatMsg(
// //             senderId: p['user_id'] as String? ?? '',
// //             senderName: p['display_name'] as String? ?? 'Player',
// //             text: p['content'] as String? ?? '',
// //             ts: DateTime.fromMillisecondsSinceEpoch(
// //               (p['ts'] as num?)?.toInt() ??
// //                   DateTime.now().millisecondsSinceEpoch,
// //             ),
// //           );
// //           _provider.addChatMessage(msg);
// //         },
// //         onModeration: (p) => _handleModerationEvent(p),
// //         onSettingsChange: (_) {},
// //         onPresenceSync: (_) {},
// //         onPresenceJoin: (_) {},
// //         onPresenceLeave: (_) {},
// //         onStatusChange: (status) {
// //           if (!mounted) return;
// //           if (status == RealtimeSubscribeStatus.subscribed &&
// //               !_provider.hasSyncedState) {
// //             sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
// //           }
// //         },
// //       );
// //     });
// //   }

// //   void _handleModerationEvent(Map<String, dynamic> p) {
// //     final type = p['type'] as String?;
// //     final targetId = p['target_user_id'] as String?;
// //     final currentId = context.read<AuthProvider>().currentUser?.id;

// //     if ((type == 'kick' || type == 'ban') && targetId == currentId) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('You were removed from the room')),
// //         );
// //         context.go(RouteNames.home);
// //       }
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return ChangeNotifierProvider.value(
// //       value: _provider,
// //       child: Consumer<TodGameProvider>(
// //         builder: (ctx, game, _) => _build(ctx, game),
// //       ),
// //     );
// //   }

// //   Widget _build(BuildContext ctx, TodGameProvider game) {
// //     if (game.loadState == TodLoadState.loading) {
// //       return const TodLoadingScreen();
// //     }

// //     if (game.loadState == TodLoadState.error) {
// //       return Scaffold(
// //         appBar: AppBar(
// //           leading: BackButton(
// //             onPressed: () async {
// //               if (widget.isOwner) {
// //                 try {
// //                   await sl.realtimeService.broadcastGameEnded(widget.roomId, {
// //                     'reason': 'host_left',
// //                   });
// //                   await sl.roomRepository.updateStatus(
// //                     widget.roomId,
// //                     RoomStatus.waiting,
// //                   );
// //                 } catch (_) {}
// //               }
// //               if (ctx.mounted) ctx.go(RouteNames.home);
// //             },
// //           ),
// //         ),
// //         body: ErrorView(
// //           message: game.error ?? 'Failed to load game',
// //           onRetry: () => ctx.go(RouteNames.home),
// //         ),
// //       );
// //     }

// //     if (game.loadState == TodLoadState.gameOver ||
// //         (game.state?.isOver ?? false)) {
// //       return TodEndScreen(
// //         state: game.state!,
// //         displayNames: widget.playerDisplayNames,
// //         onLeave: () => ctx.go(RouteNames.home),
// //       );
// //     }

// //     final state = game.state;
// //     if (state == null) return const TodLoadingScreen();

// //     return _TodGameScaffold(
// //       state: state,
// //       game: game,
// //       displayNames: widget.playerDisplayNames,
// //       roomId: widget.roomId,
// //       isOwner: widget.isOwner,
// //     );
// //   }
// // }

// // class _TodGameScaffold extends StatefulWidget {
// //   const _TodGameScaffold({
// //     required this.state,
// //     required this.game,
// //     required this.displayNames,
// //     required this.roomId,
// //     required this.isOwner,
// //   });
// //   final TodState state;
// //   final TodGameProvider game;
// //   final Map<String, String> displayNames;
// //   final String roomId;
// //   final bool isOwner;
// //   @override
// //   State<_TodGameScaffold> createState() => _TodGameScaffoldState();
// // }

// // class _TodGameScaffoldState extends State<_TodGameScaffold> {
// //   bool _showHistory = false;
// //   bool _showChat = false;
// //   int _unreadChat = 0;
// //   bool _isNavigatingAway = false;

// //   void _navigateAway(BuildContext ctx, String location) {
// //     _isNavigatingAway = true;
// //     if (ctx.canPop()) {
// //       ctx.pop();
// //     } else {
// //       ctx.go(location);
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final state = widget.state;
// //     final game = widget.game;

// //     if (_showHistory) {
// //       return Scaffold(
// //         appBar: AppBar(
// //           leading: BackButton(
// //             onPressed: () => setState(() => _showHistory = false),
// //           ),
// //           title: Text('History (${state.history.length} rounds)'),
// //         ),
// //         body: _HistoryPanel(
// //           history: state.history,
// //           displayNames: widget.displayNames,
// //         ),
// //       );
// //     }

// //     return PopScope(
// //       canPop: false,
// //       onPopInvoked: (_) {
// //         if (_isNavigatingAway) return;
// //         WidgetsBinding.instance.addPostFrameCallback(
// //           (_) => _showLeaveDialog(context, game, state),
// //         );
// //       },
// //       child: Scaffold(
// //         appBar: AppBar(
// //           automaticallyImplyLeading: false,
// //           title: const Text(''),
// //           leading: IconButton(
// //             icon: const Icon(Icons.arrow_back),
// //             onPressed: () => _showLeaveDialog(context, game, state),
// //           ),
// //           actions: [
// //             Consumer<TodGameProvider>(
// //               builder: (_, g, __) => Stack(
// //                 alignment: Alignment.topRight,
// //                 children: [
// //                   IconButton(
// //                     icon: const Icon(Icons.chat_bubble_outline_rounded),
// //                     onPressed: () {
// //                       g.clearUnreadChat();
// //                       showModalBottomSheet(
// //                         context: context,
// //                         isScrollControlled: true,
// //                         backgroundColor: Colors.transparent,
// //                         builder: (_) =>
// //                             _InGameChatSheet(game: g, myId: g.currentUserId),
// //                       );
// //                     },
// //                   ),
// //                   if (g.unreadChat > 0)
// //                     Positioned(
// //                       top: 8,
// //                       right: 8,
// //                       child: Container(
// //                         width: 8,
// //                         height: 8,
// //                         decoration: const BoxDecoration(
// //                           color: Colors.red,
// //                           shape: BoxShape.circle,
// //                         ),
// //                       ),
// //                     ),
// //                 ],
// //               ),
// //             ),
// //             if (state.history.isNotEmpty)
// //               IconButton(
// //                 icon: const Icon(Icons.history_rounded),
// //                 tooltip: 'History',
// //                 onPressed: () => setState(() => _showHistory = true),
// //               ),
// //           ],
// //         ),
// //         body: SafeArea(
// //           child: Column(
// //             children: [
// //               TodHud(
// //                 state: state,
// //                 game: game,
// //                 displayNames: widget.displayNames,
// //               ),
// //               Expanded(
// //                 child: AnimatedSwitcher(
// //                   duration: const Duration(milliseconds: 300),
// //                   transitionBuilder: (child, anim) => FadeTransition(
// //                     opacity: anim,
// //                     child: SlideTransition(
// //                       position:
// //                           Tween<Offset>(
// //                             begin: const Offset(0, 0.05),
// //                             end: Offset.zero,
// //                           ).animate(
// //                             CurvedAnimation(
// //                               parent: anim,
// //                               curve: Curves.easeOutCubic,
// //                             ),
// //                           ),
// //                       child: child,
// //                     ),
// //                   ),
// //                   child: KeyedSubtree(
// //                     key: ValueKey('${state.phase}-${state.currentPlayerId}'),
// //                     child: _phaseWidget(
// //                       context,
// //                       game,
// //                       widget.displayNames,
// //                       state,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Future<void> _showLeaveDialog(
// //     BuildContext ctx,
// //     TodGameProvider game,
// //     TodState state,
// //   ) async {
// //     if (!ctx.mounted) return;
// //     final isOwner = widget.isOwner;
// //     final myUserId = game.currentUserId;
// //     final isPremium =
// //         ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

// //     if (isOwner) {
// //       final confirmed = await showDialog<bool>(
// //         context: ctx,
// //         builder: (dCtx) => AlertDialog(
// //           title: const Text('Quit Game?'),
// //           content: const Text(
// //             'The game will end for everyone and all players will return to the lobby.',
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.of(dCtx).pop(false),
// //               child: const Text('Cancel'),
// //             ),
// //             FilledButton(
// //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// //               onPressed: () => Navigator.of(dCtx).pop(true),
// //               child: const Text('End Game for Everyone'),
// //             ),
// //           ],
// //         ),
// //       );
// //       if (confirmed != true || !ctx.mounted) return;

// //       try {
// //         await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// //           'type': 'game_ended',
// //           'reason': 'host_quit_to_lobby',
// //         });
// //         await Future.delayed(const Duration(milliseconds: 400));
// //         await sl.roomRepository.updateStatus(widget.roomId, RoomStatus.waiting);
// //       } catch (_) {}
// //       if (ctx.mounted) {
// //         _isNavigatingAway = true;
// //         if (ctx.canPop()) {
// //           ctx.pop();
// //         } else {
// //           ctx.go('/home/room/${widget.roomId}');
// //         }
// //       }
// //     } else {
// //       final confirmed = await showDialog<bool>(
// //         context: ctx,
// //         builder: (_) => AlertDialog(
// //           title: const Text('Leave Game?'),
// //           content: const Text('You will be removed from the game.'),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.pop(ctx, false),
// //               child: const Text('Stay'),
// //             ),
// //             FilledButton(
// //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// //               onPressed: () => Navigator.pop(ctx, true),
// //               child: const Text('Quit Game'),
// //             ),
// //           ],
// //         ),
// //       );
// //       if (confirmed != true || !ctx.mounted) return;

// //       final displayName = widget.displayNames[myUserId] ?? 'A player';
// //       try {
// //         await sl.roomRepository.setMemberDefinitiveLeave(widget.roomId, myUserId);
// //         await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// //           'type': 'player_left',
// //           'user_id': myUserId,
// //           'display_name': displayName,
// //           'for_good': true,
// //         });
// //       } catch (_) {}
// //       if (ctx.mounted) {
// //         _isNavigatingAway = true;
// //         ctx.go('/home/room/${widget.roomId}');
// //       }
// //     }
// //   }

// //   Widget _phaseWidget(
// //     BuildContext ctx,
// //     TodGameProvider game,
// //     Map<String, String> displayNames,
// //     TodState state,
// //   ) {
// //     return switch (state.phase) {
// //       TodTurnPhase.punishmentVoting => TodPunishmentScreen(
// //         state: state,
// //         game: game,
// //         displayNames: widget.displayNames,
// //       ),
// //       _ => TodCardScreen(
// //         state: state,
// //         game: game,
// //         displayNames: widget.displayNames,
// //       ),
// //     };
// //   }
// // }

// // class _HistoryPanel extends StatelessWidget {
// //   const _HistoryPanel({required this.history, required this.displayNames});
// //   final List<TodRoundRecord> history;
// //   final Map<String, String> displayNames;

// //   String _name(String id) =>
// //       displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     if (history.isEmpty) {
// //       return const Center(child: Text('No rounds completed yet.'));
// //     }
// //     return ListView.builder(
// //       padding: const EdgeInsets.all(12),
// //       itemCount: history.length,
// //       itemBuilder: (_, i) {
// //         final round = history[history.length - 1 - i];
// //         final reactTally = <String, int>{};
// //         for (final r in round.reactions) {
// //           reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
// //         }
// //         return Card(
// //           margin: const EdgeInsets.only(bottom: 10),
// //           child: ExpansionTile(
// //             leading: CircleAvatar(
// //               backgroundColor: theme.colorScheme.primaryContainer,
// //               child: Text(
// //                 '${round.roundNumber}',
// //                 style: theme.textTheme.labelLarge,
// //               ),
// //             ),
// //             title: Text(
// //               _name(round.playerId),
// //               style: theme.textTheme.bodyMedium?.copyWith(
// //                 fontWeight: FontWeight.w700,
// //               ),
// //             ),
// //             subtitle: Text(
// //               round.card != null
// //                   ? '${round.card!.type == TodCardType.truth ? "Truth" : "Dare"}: ${round.card!.content}'
// //                   : 'Skipped',
// //               maxLines: 1,
// //               overflow: TextOverflow.ellipsis,
// //               style: theme.textTheme.bodySmall,
// //             ),
// //             children: [
// //               Padding(
// //                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     if (round.card != null)
// //                       Container(
// //                         width: double.infinity,
// //                         padding: const EdgeInsets.all(10),
// //                         decoration: BoxDecoration(
// //                           color: round.card!.type == TodCardType.truth
// //                               ? Colors.blue.withOpacity(0.08)
// //                               : Colors.orange.withOpacity(0.08),
// //                           borderRadius: BorderRadius.circular(8),
// //                         ),
// //                         child: Text(
// //                           round.card!.content,
// //                           style: theme.textTheme.bodyMedium,
// //                         ),
// //                       ),
// //                     if (round.response.isNotEmpty) ...[
// //                       const SizedBox(height: 8),
// //                       Row(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           const Text('💬 ', style: TextStyle(fontSize: 14)),
// //                           Expanded(
// //                             child: Text(
// //                               '"${round.response}"',
// //                               style: theme.textTheme.bodySmall?.copyWith(
// //                                 fontStyle: FontStyle.italic,
// //                               ),
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ],
// //                     if (round.voteCount > 0) ...[
// //                       const SizedBox(height: 6),
// //                       Text(
// //                         '👍 ${round.voteCount} vote${round.voteCount != 1 ? "s" : ""}',
// //                         style: theme.textTheme.bodySmall?.copyWith(
// //                           color: theme.colorScheme.primary,
// //                           fontWeight: FontWeight.w600,
// //                         ),
// //                       ),
// //                     ],
// //                     if (round.hadProof) ...[
// //                       const SizedBox(height: 8),
// //                       _ProofWatchedBadge(watchedBy: round.proofWatchedBy),
// //                     ],
// //                     if (reactTally.isNotEmpty) ...[
// //                       const SizedBox(height: 8),
// //                       Wrap(
// //                         spacing: 6,
// //                         runSpacing: 4,
// //                         children: reactTally.entries
// //                             .map(
// //                               (e) => Container(
// //                                 padding: const EdgeInsets.symmetric(
// //                                   horizontal: 8,
// //                                   vertical: 3,
// //                                 ),
// //                                 decoration: BoxDecoration(
// //                                   color:
// //                                       theme.colorScheme.surfaceContainerHighest,
// //                                   borderRadius: BorderRadius.circular(16),
// //                                 ),
// //                                 child: Text(
// //                                   '${e.key} ${e.value}',
// //                                   style: const TextStyle(fontSize: 13),
// //                                 ),
// //                               ),
// //                             )
// //                             .toList(),
// //                       ),
// //                     ],
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// // }

// // class _ProofWatchedBadge extends StatelessWidget {
// //   const _ProofWatchedBadge({required this.watchedBy});
// //   final List<String> watchedBy;

// //   @override
// //   Widget build(BuildContext context) {
// //     final watched = watchedBy.isNotEmpty;
// //     return Container(
// //       height: 36,
// //       padding: const EdgeInsets.symmetric(horizontal: 10),
// //       decoration: BoxDecoration(
// //         color: Colors.grey.shade200,
// //         borderRadius: BorderRadius.circular(8),
// //       ),
// //       alignment: Alignment.centerLeft,
// //       child: Row(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           Icon(
// //             watched ? Icons.visibility_outlined : Icons.visibility_off_outlined,
// //             size: 16,
// //             color: Colors.grey.shade600,
// //           ),
// //           const SizedBox(width: 6),
// //           Text(
// //             watched
// //                 ? 'Proof watched by ${watchedBy.length}'
// //                 : 'Proof sent — not watched',
// //             style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _InGameChatSheet extends StatefulWidget {
// //   const _InGameChatSheet({required this.game, required this.myId});
// //   final TodGameProvider game;
// //   final String myId;
// //   @override
// //   State<_InGameChatSheet> createState() => _InGameChatSheetState();
// // }

// // class _InGameChatSheetState extends State<_InGameChatSheet> {
// //   final _ctrl = TextEditingController();
// //   final _scroll = ScrollController();
// //   @override
// //   void dispose() {
// //     _ctrl.dispose();
// //     _scroll.dispose();
// //     super.dispose();
// //   }

// //   void _send() {
// //     final t = _ctrl.text.trim();
// //     if (t.isEmpty) return;
// //     widget.game.sendChat(t);
// //     _ctrl.clear();
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       if (_scroll.hasClients)
// //         _scroll.animateTo(
// //           _scroll.position.maxScrollExtent,
// //           duration: 200.ms,
// //           curve: Curves.easeOut,
// //         );
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       height: MediaQuery.sizeOf(context).height * 0.65,
// //       decoration: const BoxDecoration(
// //         color: Color(0xFF1A2E45),
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       child: Column(
// //         children: [
// //           Container(
// //             width: 36,
// //             height: 4,
// //             margin: const EdgeInsets.symmetric(vertical: 10),
// //             decoration: BoxDecoration(
// //               color: Colors.white24,
// //               borderRadius: BorderRadius.circular(2),
// //             ),
// //           ),
// //           const Text(
// //             '💬 Chat',
// //             style: TextStyle(
// //               color: Colors.white,
// //               fontWeight: FontWeight.w800,
// //               fontSize: 16,
// //             ),
// //           ),
// //           const Divider(color: Colors.white12),
// //           Expanded(
// //             child: ListenableBuilder(
// //               listenable: widget.game,
// //               builder: (_, __) {
// //                 final msgs = widget.game.chatMessages;
// //                 return msgs.isEmpty
// //                     ? const Center(
// //                         child: Text(
// //                           'No messages yet',
// //                           style: TextStyle(color: Colors.white38),
// //                         ),
// //                       )
// //                     : ListView.builder(
// //                         controller: _scroll,
// //                         padding: const EdgeInsets.all(12),
// //                         itemCount: msgs.length,
// //                         itemBuilder: (_, i) {
// //                           final m = msgs[i];
// //                           final isMe = m.senderId == widget.myId;
// //                           final color =
// //                               _kChatColors[m.senderId.hashCode.abs() %
// //                                   _kChatColors.length];
// //                           return Padding(
// //                             padding: EdgeInsets.only(
// //                               bottom: 8,
// //                               left: isMe ? 48 : 0,
// //                               right: isMe ? 0 : 48,
// //                             ),
// //                             child: Column(
// //                               crossAxisAlignment: isMe
// //                                   ? CrossAxisAlignment.end
// //                                   : CrossAxisAlignment.start,
// //                               children: [
// //                                 if (!isMe)
// //                                   Padding(
// //                                     padding: const EdgeInsets.only(
// //                                       left: 4,
// //                                       bottom: 2,
// //                                     ),
// //                                     child: Text(
// //                                       m.senderName,
// //                                       style: TextStyle(
// //                                         color: color,
// //                                         fontSize: 11,
// //                                         fontWeight: FontWeight.w700,
// //                                       ),
// //                                     ),
// //                                   ),
// //                                 Container(
// //                                   padding: const EdgeInsets.symmetric(
// //                                     horizontal: 12,
// //                                     vertical: 8,
// //                                   ),
// //                                   decoration: BoxDecoration(
// //                                     color: isMe
// //                                         ? const Color(0xFFFFD60A)
// //                                         : color.withOpacity(0.18),
// //                                     borderRadius: BorderRadius.circular(16)
// //                                         .copyWith(
// //                                           bottomRight: isMe
// //                                               ? const Radius.circular(4)
// //                                               : null,
// //                                           bottomLeft: isMe
// //                                               ? null
// //                                               : const Radius.circular(4),
// //                                         ),
// //                                   ),
// //                                   child: Text(
// //                                     m.text,
// //                                     style: TextStyle(
// //                                       color: isMe
// //                                           ? const Color(0xFF0D1B2A)
// //                                           : Colors.white,
// //                                       fontWeight: isMe
// //                                           ? FontWeight.w700
// //                                           : FontWeight.w400,
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                           );
// //                         },
// //                       );
// //               },
// //             ),
// //           ),
// //           Container(
// //             padding: EdgeInsets.fromLTRB(
// //               12,
// //               8,
// //               12,
// //               MediaQuery.viewInsetsOf(context).bottom + 12,
// //             ),
// //             color: const Color(0xFF1A2E45),
// //             child: Row(
// //               children: [
// //                 Expanded(
// //                   child: TextField(
// //                     controller: _ctrl,
// //                     style: const TextStyle(color: Colors.white),
// //                     textInputAction: TextInputAction.send,
// //                     onSubmitted: (_) => _send(),
// //                     decoration: InputDecoration(
// //                       hintText: 'Say something…',
// //                       hintStyle: const TextStyle(color: Colors.white38),
// //                       filled: true,
// //                       fillColor: Colors.white.withOpacity(0.07),
// //                       border: OutlineInputBorder(
// //                         borderRadius: BorderRadius.circular(24),
// //                         borderSide: BorderSide.none,
// //                       ),
// //                       contentPadding: const EdgeInsets.symmetric(
// //                         horizontal: 16,
// //                         vertical: 10,
// //                       ),
// //                       isDense: true,
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(width: 8),
// //                 GestureDetector(
// //                   onTap: _send,
// //                   child: Container(
// //                     width: 44,
// //                     height: 44,
// //                     decoration: const BoxDecoration(
// //                       color: Color(0xFFFFD60A),
// //                       shape: BoxShape.circle,
// //                     ),
// //                     child: const Icon(
// //                       Icons.send_rounded,
// //                       color: Color(0xFF0D1B2A),
// //                       size: 20,
// //                     ),
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

// // const _kChatColors = [
// //   Color(0xFF4ECDC4),
// //   Color(0xFFA855F7),
// //   Color(0xFFFF6B6B),
// //   Color(0xFF4ADE80),
// //   Color(0xFFFB923C),
// //   Color(0xFF60A5FA),
// //   Color(0xFFF472B6),
// //   Color(0xFFFFD60A),
// //   Color(0xFF34D399),
// //   Color(0xFFC084FC),
// // ];

// // class _PausedOverlay extends StatefulWidget {
// //   const _PausedOverlay({required this.onLeave});
// //   final VoidCallback onLeave;

// //   @override
// //   State<_PausedOverlay> createState() => _PausedOverlayState();
// // }

// // class _PausedOverlayState extends State<_PausedOverlay>
// //     with SingleTickerProviderStateMixin {
// //   late final AnimationController _pulse;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _pulse = AnimationController(
// //       vsync: this,
// //       duration: const Duration(milliseconds: 1400),
// //     )..repeat(reverse: true);
// //   }

// //   @override
// //   void dispose() {
// //     _pulse.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Dialog.fullscreen(
// //       backgroundColor: Colors.transparent,
// //       child: Scaffold(
// //         backgroundColor: Colors.transparent,
// //         body: Center(
// //           child: Padding(
// //             padding: const EdgeInsets.all(32),
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 AnimatedBuilder(
// //                   animation: _pulse,
// //                   builder: (_, child) => Opacity(
// //                     opacity: 0.6 + _pulse.value * 0.4,
// //                     child: child,
// //                   ),
// //                   child: const Text(
// //                     '⏸',
// //                     style: TextStyle(fontSize: 72),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 24),
// //                 const Text(
// //                   'Game Paused',
// //                   style: TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 28,
// //                     fontWeight: FontWeight.w800,
// //                     letterSpacing: -0.5,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 12),
// //                 const Text(
// //                   'The host stepped away and will\nreturn shortly.',
// //                   textAlign: TextAlign.center,
// //                   style: TextStyle(
// //                     color: Colors.white70,
// //                     fontSize: 16,
// //                     height: 1.5,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 40),
// //                 OutlinedButton(
// //                   style: OutlinedButton.styleFrom(
// //                     foregroundColor: Colors.white,
// //                     side: const BorderSide(color: Colors.white38),
// //                     padding: const EdgeInsets.symmetric(
// //                       horizontal: 32,
// //                       vertical: 14,
// //                     ),
// //                   ),
// //                   onPressed: widget.onLeave,
// //                   child: const Text('Leave for Now'),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:jma3a/core/router/app_router.dart';
// import 'package:jma3a/features/games/engine/base_game_engine.dart';
// import 'package:jma3a/features/rooms/domain/room_entity.dart';
// import 'package:jma3a/features/settings/presentation/screen_security_service.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../../../../core/di/service_locator.dart';
// import '../../../../../core/extensions/context_ext.dart';
// import '../../../../../core/providers/auth_provider.dart';
// import '../../../../../core/router/route_names.dart';
// import '../../../../../core/services/realtime_service.dart';
// // import '../../../../../core/services/screen_security_service.dart';
// import '../../../../../core/theme/app_colors.dart';
// import '../../../../../shared/widgets/feedback/error_view.dart';
// import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// import '../../domain/tod_models.dart';
// import '../../tod_game_provider.dart';

// import '../../data/tod_repository.dart';
// import 'tod_card_screen.dart';
// import 'tod_end_screen.dart';
// import 'tod_loading_screen.dart';
// import 'tod_punishment_screen.dart';
// import '../widgets/tod_hud.dart';

// class TodGameScreen extends StatefulWidget {
//   const TodGameScreen({
//     super.key,
//     required this.roomId,
//     required this.config,
//     required this.playerIds,
//     required this.playerDisplayNames,
//     required this.packId,
//     required this.isOwner,
//     this.sessionId,
//     this.isModerator = false,
//     this.packCoverUrl,
//   });

//   final String roomId;
//   final GameConfig config;
//   final List<String> playerIds;
//   final Map<String, String> playerDisplayNames;
//   final String packId;
//   final bool isOwner;
//   final String? sessionId;
//   final bool isModerator;
//   final String? packCoverUrl;

//   @override
//   State<TodGameScreen> createState() => _TodGameScreenState();
// }

// class _TodGameScreenState extends State<TodGameScreen> {
//   late final TodGameProvider _provider;

//   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

//   @override
//   void initState() {
//     super.initState();

//     ScreenSecurityService.instance.enable();
//     ScreenSecurityService.instance.enableScreenshotDetection(() {
//       sl.realtimeService.broadcastRoomEvent(widget.roomId, {
//         'type': 'screenshot_taken',
//         'user_id': context.read<AuthProvider>().currentUser?.id,
//       }).ignore();
//     });

//     final auth = context.read<AuthProvider>();
//     final user = auth.currentUser!;

//     _provider = TodGameProvider(
//       realtimeService: sl.realtimeService,
//       repository: TodRepository.instance,
//       currentUserId: user.id,
//       currentDisplayName: user.displayName ?? user.username ?? 'Player',
//       isModerator: widget.isModerator,
//     );

//     _wireRealtimeCallbacks();

//     if (widget.isOwner) {
//       final isPremium =
//           context.read<AuthProvider>().currentUser?.isPremium ?? false;
//       _provider.initAsOwner(
//         roomId: widget.roomId,
//         config: widget.config,
//         playerIds: widget.playerIds,
//         playerDisplayNames: widget.playerDisplayNames,
//         packId: widget.packId,
//         isPremium: isPremium,
//         packCoverUrl: widget.packCoverUrl,
//       );
//     } else {
//       _provider.initAsFollower(
//         roomId: widget.roomId,
//         config: widget.config,
//         sessionId: widget.sessionId,
//         packCoverUrl: widget.packCoverUrl,
//       );
//     }
//   }

//   @override
//   void dispose() {
//     ScreenSecurityService.instance.disable();
//     _statusSub?.cancel();
//     sl.realtimeService
//         .subscribe(
//           roomId: widget.roomId,
//           onGameState: (_) {},
//           onPlayerAction: (_) {},
//           onSyncRequest: (_) {},
//           onGameStarted: (_) {},
//           onGameEnded: (_) {},
//           onRoomEvent: (_) {},
//           onChatMessage: (_) {},
//           onModeration: (_) {},
//           onSettingsChange: (_) {},
//           onPresenceSync: (_) {},
//           onPresenceJoin: (_) {},
//           onPresenceLeave: (_) {},
//           onStatusChange: (_) {},
//         )
//         .ignore();
//     _provider.dispose();
//     super.dispose();
//   }

//   void _wireRealtimeCallbacks() {
//     _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
//       status,
//     ) {
//       if (status == RealtimeSubscribeStatus.subscribed &&
//           !_provider.hasSyncedState) {
//         sl.realtimeService.broadcastSyncRequest(
//           widget.roomId,
//           context.read<AuthProvider>().currentUser!.id,
//           0,
//         );
//       }
//     });

//     _resubscribeWithGameHandlers();
//   }

//   void _resubscribeWithGameHandlers() {
//     final userId = context.read<AuthProvider>().currentUser!.id;

//     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
//       sl.realtimeService.subscribe(
//         roomId: widget.roomId,
//         onGameState: (p) => _provider.onStateBroadcast(p),
//         onPlayerAction: (p) => _provider.onPlayerAction(p),
//         onSyncRequest: (p) => _provider.onSyncRequest(p),
//         onGameStarted: (_) {},
//         onGameEnded: (p) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('The host ended the game')),
//             );
//             if (context.canPop())
//               context.pop();
//             else
//               context.go(RouteNames.home);
//           }
//         },
//         onRoomEvent: (p) {
//           final type = p['type'] as String?;
//           if (type == 'screenshot_taken') {
//             final shooterId = p['user_id'] as String?;
//             final myId = context.read<AuthProvider>().currentUser?.id;
//             if (shooterId != null && shooterId != myId && mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(
//                     '📸 ${widget.playerDisplayNames[shooterId] ?? 'Someone'} took a screenshot',
//                   ),
//                   backgroundColor: Colors.black87,
//                 ),
//               );
//             }
//             return;
//           }
//           if (type == 'player_left' && mounted) {
//             final name = p['display_name'] as String? ?? 'A player';
//             final leavingId = p['user_id'] as String?;
//             if (leavingId != null) {
//               _provider.markPlayerAway(leavingId, forGood: true);
//               if (widget.isOwner) {
//                 final active =
//                     _provider.state?.playerOrder
//                         .where((id) => !_provider.awayPlayerIds.contains(id))
//                         .toList() ??
//                     [];
//                 if (active.length <= 1) {
//                   WidgetsBinding.instance.addPostFrameCallback((_) async {
//                     if (!mounted) return;
//                     try {
//                       await sl.realtimeService.broadcastRoomEvent(
//                         widget.roomId,
//                         {'type': 'game_ended', 'reason': 'all_players_left'},
//                       );
//                       await sl.roomRepository.updateStatus(
//                         widget.roomId,
//                         RoomStatus.waiting,
//                       );
//                     } catch (_) {}
//                     if (mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('All players left — game ended'),
//                           behavior: SnackBarBehavior.fixed,
//                         ),
//                       );
//                       await Future.delayed(const Duration(milliseconds: 600));
//                       if (mounted) {
//                         if (context.canPop())
//                           context.pop();
//                         else
//                           context.go('/home/room/${widget.roomId}');
//                       }
//                     }
//                   });
//                   return;
//                 }
//               }
//             }
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('👋 $name left the game'),
//                 backgroundColor: Colors.red.shade700,
//                 duration: const Duration(seconds: 3),
//                 behavior: SnackBarBehavior.fixed,
//               ),
//             );
//             return;
//           }
//           if (type == 'ownership_transferred' && mounted) {
//             final myId = context.read<AuthProvider>().currentUser?.id;
//             final newOwnerId = p['new_owner_id'] as String?;
//             if (newOwnerId == myId) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('👑 You are now the game host!'),
//                   backgroundColor: Colors.purple,
//                 ),
//               );
//             }
//             return;
//           }
//           if (type == 'game_ended' && mounted) {
//             final reason = p['reason'] as String? ?? '';
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (!mounted) return;
//               final isAllLeft = reason == 'all_players_left';
//               showDialog(
//                 context: context,
//                 barrierDismissible: false,
//                 builder: (ctx2) => AlertDialog(
//                   title: Text(isAllLeft ? 'Game Over' : 'Game Ended'),
//                   content: Text(
//                     isAllLeft
//                         ? 'All players left the game.'
//                         : 'The host ended the game.',
//                   ),
//                   actions: [
//                     FilledButton(
//                       onPressed: () {
//                         Navigator.of(ctx2).pop();
//                         if (context.canPop()) {
//                           context.pop();
//                         } else {
//                           context.go('/home/room/${widget.roomId}');
//                         }
//                       },
//                       child: const Text('Go to Lobby'),
//                     ),
//                   ],
//                 ),
//               );
//             });
//             return;
//           }
//           if (type == 'tod_ready_count') {
//             final ids = (p['ready_user_ids'] as List?)?.cast<String>() ?? [];
//             _provider.onReadyCountUpdate(ids);
//             return;
//           }
//           if ((type == 'room_closed' || type == 'owner_left') && mounted) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (!mounted) {
//                 AppRouter.router.go(RouteNames.home);
//                 return;
//               }
//               showDialog(
//                 context: context,
//                 barrierDismissible: false,
//                 builder: (ctx2) => AlertDialog(
//                   title: const Text('Room Closed'),
//                   content: const Text('The host closed the room.'),
//                   actions: [
//                     FilledButton(
//                       onPressed: () {
//                         Navigator.of(ctx2).pop();
//                         AppRouter.router.go(RouteNames.home);
//                       },
//                       child: const Text('OK'),
//                     ),
//                   ],
//                 ),
//               );
//             });
//             return;
//           }
//         },
//         onChatMessage: (p) {
//           final msg = TodChatMsg(
//             senderId: p['user_id'] as String? ?? '',
//             senderName: p['display_name'] as String? ?? 'Player',
//             text: p['content'] as String? ?? '',
//             ts: DateTime.fromMillisecondsSinceEpoch(
//               (p['ts'] as num?)?.toInt() ??
//                   DateTime.now().millisecondsSinceEpoch,
//             ),
//           );
//           _provider.addChatMessage(msg);
//         },
//         onModeration: (p) => _handleModerationEvent(p),
//         onSettingsChange: (_) {},
//         onPresenceSync: (_) {},
//         onPresenceJoin: (_) {},
//         onPresenceLeave: (_) {},
//         onStatusChange: (status) {
//           if (!mounted) return;
//           if (status == RealtimeSubscribeStatus.subscribed &&
//               !_provider.hasSyncedState) {
//             sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
//           }
//         },
//       );
//     });
//   }

//   void _handleModerationEvent(Map<String, dynamic> p) {
//     final type = p['type'] as String?;
//     final targetId = p['target_user_id'] as String?;
//     final currentId = context.read<AuthProvider>().currentUser?.id;

//     if ((type == 'kick' || type == 'ban') && targetId == currentId) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('You were removed from the room')),
//         );
//         context.go(RouteNames.home);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider.value(
//       value: _provider,
//       child: Consumer<TodGameProvider>(
//         builder: (ctx, game, _) => _build(ctx, game),
//       ),
//     );
//   }

//   Widget _build(BuildContext ctx, TodGameProvider game) {
//     if (game.loadState == TodLoadState.loading) {
//       return const TodLoadingScreen();
//     }

//     if (game.loadState == TodLoadState.error) {
//       return Scaffold(
//         appBar: AppBar(
//           leading: BackButton(
//             onPressed: () async {
//               if (widget.isOwner) {
//                 try {
//                   await sl.realtimeService.broadcastGameEnded(widget.roomId, {
//                     'reason': 'host_left',
//                   });
//                   await sl.roomRepository.updateStatus(
//                     widget.roomId,
//                     RoomStatus.waiting,
//                   );
//                 } catch (_) {}
//               }
//               if (ctx.mounted) ctx.go(RouteNames.home);
//             },
//           ),
//         ),
//         body: ErrorView(
//           message: game.error ?? 'Failed to load game',
//           onRetry: () => ctx.go(RouteNames.home),
//         ),
//       );
//     }

//     if (game.loadState == TodLoadState.gameOver ||
//         (game.state?.isOver ?? false)) {
//       return TodEndScreen(
//         state: game.state!,
//         displayNames: widget.playerDisplayNames,
//         onLeave: () => ctx.go(RouteNames.home),
//       );
//     }

//     final state = game.state;
//     if (state == null) return const TodLoadingScreen();

//     return _TodGameScaffold(
//       state: state,
//       game: game,
//       displayNames: widget.playerDisplayNames,
//       roomId: widget.roomId,
//       isOwner: widget.isOwner,
//     );
//   }
// }

// class _TodGameScaffold extends StatefulWidget {
//   const _TodGameScaffold({
//     required this.state,
//     required this.game,
//     required this.displayNames,
//     required this.roomId,
//     required this.isOwner,
//   });
//   final TodState state;
//   final TodGameProvider game;
//   final Map<String, String> displayNames;
//   final String roomId;
//   final bool isOwner;
//   @override
//   State<_TodGameScaffold> createState() => _TodGameScaffoldState();
// }

// class _TodGameScaffoldState extends State<_TodGameScaffold> {
//   bool _showHistory = false;
//   bool _showChat = false;
//   int _unreadChat = 0;
//   bool _isNavigatingAway = false;

//   void _navigateAway(BuildContext ctx, String location) {
//     _isNavigatingAway = true;
//     if (ctx.canPop()) {
//       ctx.pop();
//     } else {
//       ctx.go(location);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state = widget.state;
//     final game = widget.game;

//     if (_showHistory) {
//       return Scaffold(
//         appBar: AppBar(
//           leading: BackButton(
//             onPressed: () => setState(() => _showHistory = false),
//           ),
//           title: Text('History (${state.history.length} rounds)'),
//         ),
//         body: _HistoryPanel(
//           history: state.history,
//           displayNames: widget.displayNames,
//         ),
//       );
//     }

//     return PopScope(
//       canPop: false,
//       onPopInvoked: (_) {
//         if (_isNavigatingAway) return;
//         WidgetsBinding.instance.addPostFrameCallback(
//           (_) => _showLeaveDialog(context, game, state),
//         );
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           automaticallyImplyLeading: false,
//           title: const Text(''),
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () => _showLeaveDialog(context, game, state),
//           ),
//           actions: [
//             Consumer<TodGameProvider>(
//               builder: (_, g, __) => Stack(
//                 alignment: Alignment.topRight,
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.chat_bubble_outline_rounded),
//                     onPressed: () {
//                       g.clearUnreadChat();
//                       showModalBottomSheet(
//                         context: context,
//                         isScrollControlled: true,
//                         backgroundColor: Colors.transparent,
//                         builder: (_) =>
//                             _InGameChatSheet(game: g, myId: g.currentUserId),
//                       );
//                     },
//                   ),
//                   if (g.unreadChat > 0)
//                     Positioned(
//                       top: 8,
//                       right: 8,
//                       child: Container(
//                         width: 8,
//                         height: 8,
//                         decoration: const BoxDecoration(
//                           color: Colors.red,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//             if (state.history.isNotEmpty)
//               IconButton(
//                 icon: const Icon(Icons.history_rounded),
//                 tooltip: 'History',
//                 onPressed: () => setState(() => _showHistory = true),
//               ),
//           ],
//         ),
//         body: SafeArea(
//           child: Column(
//             children: [
//               TodHud(
//                 state: state,
//                 game: game,
//                 displayNames: widget.displayNames,
//               ),
//               Expanded(
//                 child: AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 300),
//                   transitionBuilder: (child, anim) => FadeTransition(
//                     opacity: anim,
//                     child: SlideTransition(
//                       position:
//                           Tween<Offset>(
//                             begin: const Offset(0, 0.05),
//                             end: Offset.zero,
//                           ).animate(
//                             CurvedAnimation(
//                               parent: anim,
//                               curve: Curves.easeOutCubic,
//                             ),
//                           ),
//                       child: child,
//                     ),
//                   ),
//                   child: KeyedSubtree(
//                     key: ValueKey('${state.phase}-${state.currentPlayerId}'),
//                     child: _phaseWidget(
//                       context,
//                       game,
//                       widget.displayNames,
//                       state,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _showLeaveDialog(
//     BuildContext ctx,
//     TodGameProvider game,
//     TodState state,
//   ) async {
//     if (!ctx.mounted) return;
//     final isOwner = widget.isOwner;
//     final myUserId = game.currentUserId;
//     final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

//     if (isOwner) {
//       final confirmed = await showDialog<bool>(
//         context: ctx,
//         builder: (dCtx) => AlertDialog(
//           title: const Text('Quit Game?'),
//           content: const Text(
//             'The game will end for everyone and all players will return to the lobby.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(dCtx).pop(false),
//               child: const Text('Cancel'),
//             ),
//             FilledButton(
//               style: FilledButton.styleFrom(backgroundColor: Colors.red),
//               onPressed: () => Navigator.of(dCtx).pop(true),
//               child: const Text('End Game for Everyone'),
//             ),
//           ],
//         ),
//       );
//       if (confirmed != true || !ctx.mounted) return;

//       try {
//         await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
//           'type': 'game_ended',
//           'reason': 'host_quit_to_lobby',
//         });
//         await Future.delayed(const Duration(milliseconds: 400));
//         await sl.roomRepository.updateStatus(widget.roomId, RoomStatus.waiting);
//       } catch (_) {}
//       if (ctx.mounted) {
//         _isNavigatingAway = true;
//         if (ctx.canPop()) {
//           ctx.pop();
//         } else {
//           ctx.go('/home/room/${widget.roomId}');
//         }
//       }
//     } else {
//       final confirmed = await showDialog<bool>(
//         context: ctx,
//         builder: (_) => AlertDialog(
//           title: const Text('Leave Game?'),
//           content: const Text('You will be removed from the game.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(ctx, false),
//               child: const Text('Stay'),
//             ),
//             FilledButton(
//               style: FilledButton.styleFrom(backgroundColor: Colors.red),
//               onPressed: () => Navigator.pop(ctx, true),
//               child: const Text('Quit Game'),
//             ),
//           ],
//         ),
//       );
//       if (confirmed != true || !ctx.mounted) return;

//       final displayName = widget.displayNames[myUserId] ?? 'A player';
//       try {
//         await sl.roomRepository.setMemberDefinitiveLeave(
//           widget.roomId,
//           myUserId,
//         );
//         await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
//           'type': 'player_left',
//           'user_id': myUserId,
//           'display_name': displayName,
//           'for_good': true,
//         });
//       } catch (_) {}
//       if (ctx.mounted) {
//         _isNavigatingAway = true;
//         ctx.go('/home/room/${widget.roomId}');
//       }
//     }
//   }

//   Widget _phaseWidget(
//     BuildContext ctx,
//     TodGameProvider game,
//     Map<String, String> displayNames,
//     TodState state,
//   ) {
//     return switch (state.phase) {
//       TodTurnPhase.punishmentVoting => TodPunishmentScreen(
//         state: state,
//         game: game,
//         displayNames: widget.displayNames,
//       ),
//       _ => TodCardScreen(
//         state: state,
//         game: game,
//         displayNames: widget.displayNames,
//       ),
//     };
//   }
// }

// class _HistoryPanel extends StatelessWidget {
//   const _HistoryPanel({required this.history, required this.displayNames});
//   final List<TodRoundRecord> history;
//   final Map<String, String> displayNames;

//   String _name(String id) =>
//       displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     if (history.isEmpty) {
//       return const Center(child: Text('No rounds completed yet.'));
//     }
//     return ListView.builder(
//       padding: const EdgeInsets.all(12),
//       itemCount: history.length,
//       itemBuilder: (_, i) {
//         final round = history[history.length - 1 - i];
//         final reactTally = <String, int>{};
//         for (final r in round.reactions) {
//           reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
//         }
//         return Card(
//           margin: const EdgeInsets.only(bottom: 10),
//           child: ExpansionTile(
//             leading: CircleAvatar(
//               backgroundColor: theme.colorScheme.primaryContainer,
//               child: Text(
//                 '${round.roundNumber}',
//                 style: theme.textTheme.labelLarge,
//               ),
//             ),
//             title: Text(
//               _name(round.playerId),
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             subtitle: Text(
//               round.card != null
//                   ? '${round.card!.type == TodCardType.truth ? "Truth" : "Dare"}: ${round.card!.content}'
//                   : 'Skipped',
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: theme.textTheme.bodySmall,
//             ),
//             children: [
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (round.card != null)
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(10),
//                         decoration: BoxDecoration(
//                           color: round.card!.type == TodCardType.truth
//                               ? Colors.blue.withOpacity(0.08)
//                               : Colors.orange.withOpacity(0.08),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           round.card!.content,
//                           style: theme.textTheme.bodyMedium,
//                         ),
//                       ),
//                     if (round.response.isNotEmpty) ...[
//                       const SizedBox(height: 8),
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text('💬 ', style: TextStyle(fontSize: 14)),
//                           Expanded(
//                             child: Text(
//                               '"${round.response}"',
//                               style: theme.textTheme.bodySmall?.copyWith(
//                                 fontStyle: FontStyle.italic,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                     if (round.voteCount > 0) ...[
//                       const SizedBox(height: 6),
//                       Text(
//                         '👍 ${round.voteCount} vote${round.voteCount != 1 ? "s" : ""}',
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           color: theme.colorScheme.primary,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                     if (round.hadProof) ...[
//                       const SizedBox(height: 8),
//                       _ProofWatchedBadge(watchedBy: round.proofWatchedBy),
//                     ],
//                     if (reactTally.isNotEmpty) ...[
//                       const SizedBox(height: 8),
//                       Wrap(
//                         spacing: 6,
//                         runSpacing: 4,
//                         children: reactTally.entries
//                             .map(
//                               (e) => Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 3,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color:
//                                       theme.colorScheme.surfaceContainerHighest,
//                                   borderRadius: BorderRadius.circular(16),
//                                 ),
//                                 child: Text(
//                                   '${e.key} ${e.value}',
//                                   style: const TextStyle(fontSize: 13),
//                                 ),
//                               ),
//                             )
//                             .toList(),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class _ProofWatchedBadge extends StatelessWidget {
//   const _ProofWatchedBadge({required this.watchedBy});
//   final List<String> watchedBy;

//   @override
//   Widget build(BuildContext context) {
//     final watched = watchedBy.isNotEmpty;
//     return Container(
//       height: 36,
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       alignment: Alignment.centerLeft,
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             watched ? Icons.visibility_outlined : Icons.visibility_off_outlined,
//             size: 16,
//             color: Colors.grey.shade600,
//           ),
//           const SizedBox(width: 6),
//           Text(
//             watched
//                 ? 'Proof watched by ${watchedBy.length}'
//                 : 'Proof sent — not watched',
//             style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _InGameChatSheet extends StatefulWidget {
//   const _InGameChatSheet({required this.game, required this.myId});
//   final TodGameProvider game;
//   final String myId;
//   @override
//   State<_InGameChatSheet> createState() => _InGameChatSheetState();
// }

// class _InGameChatSheetState extends State<_InGameChatSheet> {
//   final _ctrl = TextEditingController();
//   final _scroll = ScrollController();
//   @override
//   void dispose() {
//     _ctrl.dispose();
//     _scroll.dispose();
//     super.dispose();
//   }

//   void _send() {
//     final t = _ctrl.text.trim();
//     if (t.isEmpty) return;
//     widget.game.sendChat(t);
//     _ctrl.clear();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scroll.hasClients)
//         _scroll.animateTo(
//           _scroll.position.maxScrollExtent,
//           duration: 200.ms,
//           curve: Curves.easeOut,
//         );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.sizeOf(context).height * 0.65,
//       decoration: const BoxDecoration(
//         color: Color(0xFF1A2E45),
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         children: [
//           Container(
//             width: 36,
//             height: 4,
//             margin: const EdgeInsets.symmetric(vertical: 10),
//             decoration: BoxDecoration(
//               color: Colors.white24,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           const Text(
//             '💬 Chat',
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w800,
//               fontSize: 16,
//             ),
//           ),
//           const Divider(color: Colors.white12),
//           Expanded(
//             child: ListenableBuilder(
//               listenable: widget.game,
//               builder: (_, __) {
//                 final msgs = widget.game.chatMessages;
//                 return msgs.isEmpty
//                     ? const Center(
//                         child: Text(
//                           'No messages yet',
//                           style: TextStyle(color: Colors.white38),
//                         ),
//                       )
//                     : ListView.builder(
//                         controller: _scroll,
//                         padding: const EdgeInsets.all(12),
//                         itemCount: msgs.length,
//                         itemBuilder: (_, i) {
//                           final m = msgs[i];
//                           final isMe = m.senderId == widget.myId;
//                           final color =
//                               _kChatColors[m.senderId.hashCode.abs() %
//                                   _kChatColors.length];
//                           return Padding(
//                             padding: EdgeInsets.only(
//                               bottom: 8,
//                               left: isMe ? 48 : 0,
//                               right: isMe ? 0 : 48,
//                             ),
//                             child: Column(
//                               crossAxisAlignment: isMe
//                                   ? CrossAxisAlignment.end
//                                   : CrossAxisAlignment.start,
//                               children: [
//                                 if (!isMe)
//                                   Padding(
//                                     padding: const EdgeInsets.only(
//                                       left: 4,
//                                       bottom: 2,
//                                     ),
//                                     child: Text(
//                                       m.senderName,
//                                       style: TextStyle(
//                                         color: color,
//                                         fontSize: 11,
//                                         fontWeight: FontWeight.w700,
//                                       ),
//                                     ),
//                                   ),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 12,
//                                     vertical: 8,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: isMe
//                                         ? const Color(0xFFFFD60A)
//                                         : color.withOpacity(0.18),
//                                     borderRadius: BorderRadius.circular(16)
//                                         .copyWith(
//                                           bottomRight: isMe
//                                               ? const Radius.circular(4)
//                                               : null,
//                                           bottomLeft: isMe
//                                               ? null
//                                               : const Radius.circular(4),
//                                         ),
//                                   ),
//                                   child: Text(
//                                     m.text,
//                                     style: TextStyle(
//                                       color: isMe
//                                           ? const Color(0xFF0D1B2A)
//                                           : Colors.white,
//                                       fontWeight: isMe
//                                           ? FontWeight.w700
//                                           : FontWeight.w400,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       );
//               },
//             ),
//           ),
//           Container(
//             padding: EdgeInsets.fromLTRB(
//               12,
//               8,
//               12,
//               MediaQuery.viewInsetsOf(context).bottom + 12,
//             ),
//             color: const Color(0xFF1A2E45),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _ctrl,
//                     style: const TextStyle(color: Colors.white),
//                     textInputAction: TextInputAction.send,
//                     onSubmitted: (_) => _send(),
//                     decoration: InputDecoration(
//                       hintText: 'Say something…',
//                       hintStyle: const TextStyle(color: Colors.white38),
//                       filled: true,
//                       fillColor: Colors.white.withOpacity(0.07),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(24),
//                         borderSide: BorderSide.none,
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 10,
//                       ),
//                       isDense: true,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 GestureDetector(
//                   onTap: _send,
//                   child: Container(
//                     width: 44,
//                     height: 44,
//                     decoration: const BoxDecoration(
//                       color: Color(0xFFFFD60A),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.send_rounded,
//                       color: Color(0xFF0D1B2A),
//                       size: 20,
//                     ),
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

// const _kChatColors = [
//   Color(0xFF4ECDC4),
//   Color(0xFFA855F7),
//   Color(0xFFFF6B6B),
//   Color(0xFF4ADE80),
//   Color(0xFFFB923C),
//   Color(0xFF60A5FA),
//   Color(0xFFF472B6),
//   Color(0xFFFFD60A),
//   Color(0xFF34D399),
//   Color(0xFFC084FC),
// ];

// class _PausedOverlay extends StatefulWidget {
//   const _PausedOverlay({required this.onLeave});
//   final VoidCallback onLeave;

//   @override
//   State<_PausedOverlay> createState() => _PausedOverlayState();
// }

// class _PausedOverlayState extends State<_PausedOverlay>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _pulse;

//   @override
//   void initState() {
//     super.initState();
//     _pulse = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1400),
//     )..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _pulse.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog.fullscreen(
//       backgroundColor: Colors.transparent,
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(32),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 AnimatedBuilder(
//                   animation: _pulse,
//                   builder: (_, child) =>
//                       Opacity(opacity: 0.6 + _pulse.value * 0.4, child: child),
//                   child: const Text('⏸', style: TextStyle(fontSize: 72)),
//                 ),
//                 const SizedBox(height: 24),
//                 const Text(
//                   'Game Paused',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 28,
//                     fontWeight: FontWeight.w800,
//                     letterSpacing: -0.5,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 const Text(
//                   'The host stepped away and will\nreturn shortly.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 16,
//                     height: 1.5,
//                   ),
//                 ),
//                 const SizedBox(height: 40),
//                 OutlinedButton(
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: Colors.white,
//                     side: const BorderSide(color: Colors.white38),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 32,
//                       vertical: 14,
//                     ),
//                   ),
//                   onPressed: widget.onLeave,
//                   child: const Text('Leave for Now'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:jma3a/core/router/app_router.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/features/rooms/presentation/room_provider.dart';
import 'package:jma3a/features/settings/presentation/screen_security_service.dart';
import 'package:jma3a/shared/widgets/animated_reaction_overlay.dart';
import 'package:jma3a/shared/widgets/game_rules_sheet.dart';
import 'package:jma3a/shared/widgets/no_active_players_banner.dart';
import 'package:jma3a/shared/widgets/join_requests_panel.dart';
import 'package:jma3a/shared/widgets/room_members_management_sheet.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../../core/extensions/context_ext.dart';
import '../../../../../core/providers/auth_provider.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/services/realtime_service.dart';
// import '../../../../../core/services/screen_security_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/game_end_navigation.dart';
import '../../../../../shared/widgets/feedback/error_view.dart';
import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
import '../../domain/tod_models.dart';
import '../../tod_game_provider.dart';

import '../../data/tod_repository.dart';
import 'tod_card_screen.dart';
import 'tod_end_screen.dart';
import 'tod_loading_screen.dart';
import 'tod_punishment_screen.dart';
import '../widgets/tod_hud.dart';

class TodGameScreen extends StatefulWidget {
  const TodGameScreen({
    super.key,
    required this.roomId,
    required this.config,
    required this.playerIds,
    required this.playerDisplayNames,
    required this.packId,
    required this.isOwner,
    this.sessionId,
    this.isModerator = false,
    this.isSpectator = false,
    this.packCoverUrl,
    this.roomProvider,
  });

  final String roomId;
  final GameConfig config;
  final List<String> playerIds;
  final Map<String, String> playerDisplayNames;
  final String packId;
  final bool isOwner;
  final String? sessionId;
  final bool isModerator;
  final bool isSpectator;
  final String? packCoverUrl;
  final RoomProvider? roomProvider;

  @override
  State<TodGameScreen> createState() => _TodGameScreenState();
}

class _TodGameScreenState extends State<TodGameScreen> {
  late final TodGameProvider _provider;

  StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

  // Tracks whether we've reached `subscribed` before. hasSyncedState alone
  // isn't enough to gate the resync request — it stays true forever after
  // the first sync, so a later reconnect (network drop, backgrounding)
  // would otherwise never trigger a fresh sync even though state broadcasts
  // sent while disconnected were permanently missed (Realtime Broadcast has
  // no delivery guarantee or replay).
  bool _hasEverSubscribed = false;

  // Room ownership can be transferred mid-game (see RoomProvider.
  // transferOwnership); this provider's own `_isOwner` is otherwise cached
  // once at game start and never re-derived, so this listener is what
  // actually moves game-authority (state broadcasting) to the new owner.
  bool? _lastKnownRoomOwner;

  void _onRoomOwnershipChanged() {
    final rp = widget.roomProvider;
    if (rp == null) return;
    final amOwner = rp.isOwner;
    if (_lastKnownRoomOwner == amOwner) return;
    _lastKnownRoomOwner = amOwner;
    _provider.applyOwnershipChange(amOwner);
  }

  // Previously nothing in this screen listened to RoomProvider's lifecycle
  // stream at all — a player sitting inside an active game when the owner
  // vanished (and no other member was eligible for auto-promotion) got no
  // notification and no fallback; the screen just hung indefinitely.
  StreamSubscription<RoomLifecycleEvent>? _lifecycleSub;

  void _onRoomLifecycleEvent(RoomLifecycleEvent event) {
    if (!mounted) return;
    switch (event) {
      case RoomLifecycleEvent.roomClosed:
      case RoomLifecycleEvent.kicked:
      case RoomLifecycleEvent.banned:
      case RoomLifecycleEvent.ownershipTransferred:
        // handled by _onRoomOwnershipChanged / the target's own nav — and,
        // for roomClosed specifically, by LobbyScreen's own listener, which
        // stays mounted underneath this pushed route (see app_router.dart's
        // parentNavigatorKey:rootKey). This screen previously ALSO reacted
        // to roomClosed with its own snackbar + AppRouter.router.go(), which
        // raced against LobbyScreen's showDialog for the same event — both
        // are registered on the same broadcast RoomLifecycleEvent stream,
        // and go() replacing the entire route stack while the lobby's
        // AlertDialog was still mid-transition left a semantics-blocking
        // barrier that never got to cleanly rejoin the tree, producing a
        // permanently corrupted semantics node (RenderObject.
        // debugCheckForParentData's `!semantics.parentDataDirty` assertion,
        // repeating every frame thereafter). roomClosed now has exactly one
        // owner — LobbyScreen — same as the other three events here.
        break;
      case RoomLifecycleEvent.memberLeft:
        final name = widget.roomProvider?.lastDepartedMemberName;
        if (name != null && name.isNotEmpty) {
          context.showSnackBar('$name left the game');
        }
    }
  }

  // Single presence pipeline: RoomProvider already tracks connected/
  // disconnected members reliably (presence sync + a debounced grace
  // period); rather than a second, separate presence system here, the
  // owner's client derives/updates away status straight from that one
  // source of truth. This also fixes _awayPlayerIds never surviving a
  // full app restart (it's normally only set by runtime moderation
  // events) — this runs once immediately on init too, deriving the
  // correct set from the DB-backed member list right away.
  void _syncAwayFromPresence() {
    final rp = widget.roomProvider;
    final state = _provider.state;
    if (rp == null || !_provider.isOwner || state == null) return;
    for (final id in state.playerOrder) {
      final member = rp.members.where((m) => m.userId == id).firstOrNull;
      final isPresent = member != null && !member.isDisconnected;
      final isAway = _provider.awayPlayerIds.contains(id);
      if (isPresent && isAway) {
        _provider.markPlayerReturned(id);
      } else if (!isPresent && !isAway) {
        _provider.markPlayerAway(id);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // ScreenSecurityService.instance.enable();
    // ScreenSecurityService.instance.enableScreenshotDetection(() {
    //   sl.realtimeService.broadcastRoomEvent(widget.roomId, {
    //     'type': 'screenshot_taken',
    //     'user_id': context.read<AuthProvider>().currentUser?.id,
    //   }).ignore();
    // });

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;

    _provider = TodGameProvider(
      realtimeService: sl.realtimeService,
      repository: TodRepository.instance,
      currentUserId: user.id,
      currentDisplayName: user.displayName ?? user.username ?? 'Player',
      isModerator: widget.isModerator,
    );

    _wireRealtimeCallbacks();

    if (widget.isOwner) {
      final isPremium =
          context.read<AuthProvider>().currentUser?.isPremium ?? false;
      _provider.initAsOwner(
        roomId: widget.roomId,
        config: widget.config,
        playerIds: widget.playerIds,
        playerDisplayNames: widget.playerDisplayNames,
        packId: widget.packId,
        isPremium: isPremium,
        packCoverUrl: widget.packCoverUrl,
      );
    } else {
      _provider.initAsFollower(
        roomId: widget.roomId,
        config: widget.config,
        sessionId: widget.sessionId,
        packCoverUrl: widget.packCoverUrl,
      );
    }

    _lastKnownRoomOwner = widget.isOwner;
    widget.roomProvider?.addListener(_onRoomOwnershipChanged);
    widget.roomProvider?.addListener(_syncAwayFromPresence);
    // initAsOwner/initAsFollower are async — _provider.state isn't
    // populated yet at this point, so also re-run once the game provider
    // itself notifies (e.g. once its initial state loads), not just when
    // RoomProvider changes.
    _provider.addListener(_syncAwayFromPresence);
    _provider.permissionChecker = widget.roomProvider?.memberHasPermission;
    _provider.roomProvider = widget.roomProvider;
    _lifecycleSub = widget.roomProvider?.lifecycleEvents.listen(
      _onRoomLifecycleEvent,
    );
  }

  @override
  void dispose() {
    widget.roomProvider?.removeListener(_onRoomOwnershipChanged);
    widget.roomProvider?.removeListener(_syncAwayFromPresence);
    _provider.removeListener(_syncAwayFromPresence);
    _lifecycleSub?.cancel();
    // ScreenSecurityService.instance.disable();
    _statusSub?.cancel();
    // Only removes this screen's own 'game' listener — the room channel,
    // RoomProvider's 'room' listener, and presence tracking are untouched.
    sl.realtimeService.unsubscribeListener(
      widget.roomId,
      RoomChannelSubscriber.game,
    );
    _provider.dispose();
    super.dispose();
  }

  void _wireRealtimeCallbacks() {
    _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
      status,
    ) {
      if (status == RealtimeSubscribeStatus.subscribed &&
          !_provider.hasSyncedState) {
        sl.realtimeService.broadcastSyncRequest(
          widget.roomId,
          context.read<AuthProvider>().currentUser!.id,
          0,
        );
      }
    });

    _resubscribeWithGameHandlers();
  }

  void _resubscribeWithGameHandlers() {
    final userId = context.read<AuthProvider>().currentUser!.id;

    // Registers this screen's own 'game' listener alongside RoomProvider's
    // 'room' listener on the shared channel — no full unsubscribe/rebuild,
    // so RoomProvider's own subscription (and presence tracking) is never
    // disturbed.
    sl.realtimeService.subscribe(
      roomId: widget.roomId,
      subscriberId: RoomChannelSubscriber.game,
      onGameState: (p) => _provider.onStateBroadcast(p),
      onPlayerAction: (p) {
        // Receiving a live action from a member is proof they're
        // connected — clear any presence grace-period in progress for
        // them immediately rather than waiting on the next heartbeat.
        final uid = p['user_id'] as String?;
        if (uid != null) widget.roomProvider?.markMemberActive(uid);
        _provider.onPlayerAction(p);
      },
      onSyncRequest: (p) => _provider.onSyncRequest(p),
      onGameStarted: (_) {},
      onGameEnded: (p) {
        if (mounted) {
          // Mark this as a programmatic exit before popping, so the
          // _TodGameScaffold's PopScope (which shares this same
          // TodGameProvider instance) doesn't mistake it for the user
          // backing out and open the Quit Game dialog on top of it.
          _provider.isNavigatingAway = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The host ended the game')),
          );
          if (context.canPop())
            context.pop();
          else
            context.go(RouteNames.home);
        }
      },
      onRoomEvent: (p) {
        final type = p['type'] as String?;
        if (type == 'screenshot_taken') {
          final shooterId = p['user_id'] as String?;
          final myId = context.read<AuthProvider>().currentUser?.id;
          if (shooterId != null && shooterId != myId && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '📸 ${widget.playerDisplayNames[shooterId] ?? 'Someone'} took a screenshot',
                ),
                backgroundColor: Colors.black87,
              ),
            );
          }
          return;
        }
        if (type == 'player_left' && mounted) {
          final name = p['display_name'] as String? ?? 'A player';
          final leavingId = p['user_id'] as String?;
          if (leavingId != null) {
            _provider.markPlayerAway(leavingId, forGood: true);
            if (widget.isOwner) {
              final active =
                  _provider.state?.playerOrder
                      .where((id) => !_provider.awayPlayerIds.contains(id))
                      .toList() ??
                  [];
              if (active.length <= 1) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted) return;
                  try {
                    await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
                      'type': 'game_ended',
                      'reason': 'all_players_left',
                    });
                    await sl.roomRepository.updateStatus(
                      widget.roomId,
                      RoomStatus.waiting,
                    );
                  } catch (_) {}
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All players left — game ended'),
                        behavior: SnackBarBehavior.fixed,
                      ),
                    );
                    await Future.delayed(const Duration(milliseconds: 600));
                    if (mounted) {
                      if (context.canPop())
                        context.pop();
                      else
                        context.go('/home/room/${widget.roomId}');
                    }
                  }
                });
                return;
              }
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('👋 $name left the game'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.fixed,
            ),
          );
          return;
        }
        // RoomProvider's own manual-transfer and automatic-failover paths
        // both broadcast 'ownership_transfer' (see room_provider.dart) —
        // this screen previously only matched 'ownership_transferred',
        // so this snackbar never fired for either of those, only for a
        // (currently ToD-absent) in-game handoff feature that would send
        // the other spelling.
        if ((type == 'ownership_transferred' || type == 'ownership_transfer') &&
            mounted) {
          final myId = context.read<AuthProvider>().currentUser?.id;
          final newOwnerId = p['new_owner_id'] as String?;
          if (newOwnerId == myId) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('👑 You are now the game host!'),
                backgroundColor: Colors.purple,
              ),
            );
          }
          return;
        }
        if (type == 'game_ended' && mounted) {
          final reason = p['reason'] as String? ?? '';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final isAllLeft = reason == 'all_players_left';
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx2) => AlertDialog(
                title: Text(isAllLeft ? 'Game Over' : 'Game Ended'),
                content: Text(
                  isAllLeft
                      ? 'All players left the game.'
                      : 'The host ended the game.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx2).pop();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home/room/${widget.roomId}');
                      }
                    },
                    child: const Text('Go to Lobby'),
                  ),
                ],
              ),
            );
          });
          return;
        }
        if (type == 'tod_ready_count') {
          final ids = (p['ready_user_ids'] as List?)?.cast<String>() ?? [];
          _provider.onReadyCountUpdate(
            ids,
            ts: p['ts'] as int?,
            turnStartedAt: p['turn_started_at'] as int?,
          );
          return;
        }
        if (type == 'tod_player_activity') {
          _provider.onPlayerActivityUpdate(p);
          return;
        }
        if ((type == 'room_closed' || type == 'owner_left') && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              AppRouter.router.go(RouteNames.home);
              return;
            }
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx2) => AlertDialog(
                title: const Text('Room Closed'),
                content: const Text('The host closed the room.'),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx2).pop();
                      AppRouter.router.go(RouteNames.home);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          });
          return;
        }
      },
      onChatMessage: (p) {
        final msg = TodChatMsg(
          senderId: p['user_id'] as String? ?? '',
          senderName: p['display_name'] as String? ?? 'Player',
          text: p['content'] as String? ?? '',
          ts: DateTime.fromMillisecondsSinceEpoch(
            (p['ts'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
          ),
        );
        _provider.addChatMessage(msg);
      },
      onModeration: (p) => _handleModerationEvent(p),
      onSettingsChange: (_) {},
      onPresenceSync: (_) {},
      onStatusChange: (status) {
        if (!mounted) return;
        if (status == RealtimeSubscribeStatus.subscribed) {
          if (!_provider.hasSyncedState || _hasEverSubscribed) {
            sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
          }
          _hasEverSubscribed = true;
        }
      },
    );
  }

  void _handleModerationEvent(Map<String, dynamic> p) {
    final type = p['type'] as String?;
    final targetId = p['target_user_id'] as String?;
    final currentId = context.read<AuthProvider>().currentUser?.id;

    if (type == 'game_kick' && targetId != null) {
      _provider.markPlayerAway(targetId, forGood: true);
      if (targetId == currentId && mounted) {
        _provider.isNavigatingAway = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You were removed from this game')),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home/room/${widget.roomId}');
        }
      }
      return;
    }

    if ((type == 'kick' || type == 'ban') && targetId != null) {
      // Room-level kick/ban (e.g. from the lobby's member panel, or a ban
      // triggered from inside a game) previously only told the TARGET's
      // own client to leave — every other client's game provider never
      // learned the target was gone, so it kept waiting on their
      // turn/vote/submission indefinitely even though they'd already been
      // removed from the room. Mark them away for everyone, same as
      // game_kick, regardless of whose client this is.
      _provider.markPlayerAway(targetId, forGood: true);
      if (targetId == currentId && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You were removed from the room')),
        );
        context.go(RouteNames.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Stacked so the members management entry point stays reachable across
    // every phase this screen can render (choosing/reading/awaiting/
    // punishment-voting/game-over) without needing to be threaded into each
    // phase's own Scaffold individually.
    return Stack(
      children: [
        ChangeNotifierProvider.value(
          value: _provider,
          child: Consumer<TodGameProvider>(
            builder: (ctx, game, _) => _build(ctx, game),
          ),
        ),
        RoomMembersFab(
          roomProvider: widget.roomProvider,
          gameKickPlayer: _provider.kickPlayerFromGame,
          gameBanPlayer: _provider.banPlayerFromGame,
          heroTag: 'tod_members_${widget.roomId}',
        ),
        NoActivePlayersBanner(
          roomProvider: widget.roomProvider,
          isOwner: widget.isOwner,
          onEndGame: () => _provider.endGame(),
        ),
        // LobbyScreen stays mounted underneath this pushed game route, but
        // isn't visible while a moderator is actively here — mirror its
        // join-requests panel so requests filed mid-game (see
        // RoomProvider.initialize's new brand-new-player gate) are seen.
        if (widget.roomProvider?.canAcceptJoins ?? false)
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: JoinRequestsPanel(
                      roomId: widget.roomId,
                      inGame: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ChangeNotifierProvider.value(
          value: _provider,
          child: Consumer<TodGameProvider>(
            builder: (ctx, game, _) => AnimatedReactionOverlay(
              reactions: (game.state?.currentReactions ?? const [])
                  .map((r) => (emoji: r.emoji, ts: r.ts))
                  .toList(),
            ),
          ),
        ),
        // Persistent indicator so everyone understands the rules before
        // playing, not just when someone happens to skip — per the room
        // owner's punishment-mode setting.
        if (_provider.config?.enablePunishments ?? false)
          const Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(child: _PunishmentModeBadge()),
          ),
      ],
    );
  }

  Widget _build(BuildContext ctx, TodGameProvider game) {
    if (game.loadState == TodLoadState.loading) {
      return const TodLoadingScreen();
    }

    if (game.loadState == TodLoadState.error) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () async {
              if (widget.isOwner) {
                try {
                  await sl.realtimeService.broadcastGameEnded(widget.roomId, {
                    'reason': 'host_left',
                  });
                  await sl.roomRepository.updateStatus(
                    widget.roomId,
                    RoomStatus.waiting,
                  );
                } catch (_) {}
              }
              if (ctx.mounted) ctx.go(RouteNames.home);
            },
          ),
        ),
        body: ErrorView(
          message: game.error ?? 'Failed to load game',
          onRetry: () => ctx.go(RouteNames.home),
        ),
      );
    }

    if (game.loadState == TodLoadState.gameOver ||
        (game.state?.isOver ?? false)) {
      return TodEndScreen(
        state: game.state!,
        displayNames: widget.playerDisplayNames,
        onLeave: () => goToLobbyOrHome(ctx, widget.roomId),
      );
    }

    final state = game.state;
    if (state == null) return const TodLoadingScreen();

    return _TodGameScaffold(
      state: state,
      game: game,
      displayNames: widget.playerDisplayNames,
      roomId: widget.roomId,
      isOwner: widget.isOwner,
    );
  }
}

/// Persistent "punishment mode is active" indicator — shown throughout the
/// game (not just when someone skips) so every participant understands the
/// rules before playing, per the room owner's setting.
class _PunishmentModeBadge extends StatelessWidget {
  const _PunishmentModeBadge();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.deepOrange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gavel_rounded, size: 14, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Punishment mode ON',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodGameScaffold extends StatefulWidget {
  const _TodGameScaffold({
    required this.state,
    required this.game,
    required this.displayNames,
    required this.roomId,
    required this.isOwner,
  });
  final TodState state;
  final TodGameProvider game;
  final Map<String, String> displayNames;
  final String roomId;
  final bool isOwner;
  @override
  State<_TodGameScaffold> createState() => _TodGameScaffoldState();
}

class _TodGameScaffoldState extends State<_TodGameScaffold> {
  bool _showHistory = false;
  bool _showChat = false;
  int _unreadChat = 0;

  void _navigateAway(BuildContext ctx, String location) {
    // widget.game (TodGameProvider) is shared with _TodGameScreenState,
    // which owns the realtime listeners — this is the single flag both
    // sides check, so a programmatic pop triggered by a realtime event
    // isn't misread by PopScope below as the user backing out.
    widget.game.isNavigatingAway = true;
    if (ctx.canPop()) {
      ctx.pop();
    } else {
      ctx.go(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final game = widget.game;

    if (_showHistory) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => setState(() => _showHistory = false),
          ),
          title: Text('History (${state.history.length} rounds)'),
        ),
        body: _HistoryPanel(
          history: state.history,
          displayNames: widget.displayNames,
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (_) {
        if (widget.game.isNavigatingAway) return;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _showLeaveDialog(context, game, state),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(''),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _showLeaveDialog(context, game, state),
          ),
          actions: [
            Consumer<TodGameProvider>(
              builder: (_, g, __) => Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    onPressed: () {
                      g.clearUnreadChat();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            _InGameChatSheet(game: g, myId: g.currentUserId),
                      );
                    },
                  ),
                  if (g.unreadChat > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (state.history.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: 'History',
                onPressed: () => setState(() => _showHistory = true),
              ),
            RulesButton(gameType: GameType.truthOrDare, config: game.config),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              TodHud(
                state: state,
                game: game,
                displayNames: widget.displayNames,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey('${state.phase}-${state.currentPlayerId}'),
                    child: _phaseWidget(
                      context,
                      game,
                      widget.displayNames,
                      state,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLeaveDialog(
    BuildContext ctx,
    TodGameProvider game,
    TodState state,
  ) async {
    if (!ctx.mounted) return;
    final isOwner = widget.isOwner;
    final myUserId = game.currentUserId;
    final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Quit Game?'),
        content: const Text('Leave the current game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: const Text('Quit Game'),
          ),
        ],
      ),
    );
    if (confirmed != true || !ctx.mounted) return;

    if (isOwner) {
      // Quit Game only ends the current game session — it must NOT close
      // or delete the room. Closing the room is a separate action, only
      // available from LobbyScreen's room management. Use the dedicated
      // game-ended broadcast (not 'owner_left') so every player's existing
      // onGameEnded handler fires immediately and pops back to this same
      // room's lobby — no dialog required on the receiving end.
      try {
        await sl.realtimeService.broadcastGameEnded(widget.roomId, {
          'reason': 'host_quit_to_lobby',
        });
        await sl.roomRepository.updateStatus(widget.roomId, RoomStatus.waiting);
      } catch (_) {}
      if (ctx.mounted) _navigateAway(ctx, '/home/room/${widget.roomId}');
    } else {
      // A normal player/spectator quitting the game also leaves the room
      // entirely (frees their slot, updates counts) — for_good:true tells
      // every client's RoomProvider to remove them from the member list.
      final displayName = widget.displayNames[myUserId] ?? 'A player';
      try {
        await sl.roomRepository.setMemberDefinitiveLeave(
          widget.roomId,
          myUserId,
        );
        await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
          'type': 'player_left',
          'user_id': myUserId,
          'display_name': displayName,
          'for_good': true,
        });
      } catch (_) {}
      if (ctx.mounted) {
        widget.game.isNavigatingAway = true;
        ctx.go(RouteNames.home);
      }
    }
  }

  Widget _phaseWidget(
    BuildContext ctx,
    TodGameProvider game,
    Map<String, String> displayNames,
    TodState state,
  ) {
    return switch (state.phase) {
      TodTurnPhase.punishmentVoting => TodPunishmentScreen(
        state: state,
        game: game,
        displayNames: widget.displayNames,
      ),
      _ => TodCardScreen(
        state: state,
        game: game,
        displayNames: widget.displayNames,
      ),
    };
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.history, required this.displayNames});
  final List<TodRoundRecord> history;
  final Map<String, String> displayNames;

  String _name(String id) =>
      displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    if (history.isEmpty) {
      return const Center(child: Text('No rounds completed yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: history.length,
      itemBuilder: (_, i) {
        final round = history[history.length - 1 - i];
        final reactTally = <String, int>{};
        for (final r in round.reactions) {
          reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
        }
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '${round.roundNumber}',
                style: theme.textTheme.labelLarge,
              ),
            ),
            title: Text(
              _name(round.playerId),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              round.card != null
                  ? '${round.card!.type == TodCardType.truth ? "Truth" : "Dare"}: ${round.card!.content}'
                  : 'Skipped',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (round.card != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: round.card!.type == TodCardType.truth
                              ? Colors.blue.withOpacity(0.08)
                              : Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          round.card!.content,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    if (round.response.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💬 ', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              '"${round.response}"',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (round.voteCount > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '👍 ${round.voteCount} vote${round.voteCount != 1 ? "s" : ""}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (round.hadProof) ...[
                      const SizedBox(height: 8),
                      _ProofWatchedBadge(watchedBy: round.proofWatchedBy),
                    ],
                    if (reactTally.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: reactTally.entries
                            .map(
                              (e) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${e.key} ${e.value}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProofWatchedBadge extends StatelessWidget {
  const _ProofWatchedBadge({required this.watchedBy});
  final List<String> watchedBy;

  @override
  Widget build(BuildContext context) {
    final watched = watchedBy.isNotEmpty;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            watched ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            watched
                ? 'Proof watched by ${watchedBy.length}'
                : 'Proof sent — not watched',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InGameChatSheet extends StatefulWidget {
  const _InGameChatSheet({required this.game, required this.myId});
  final TodGameProvider game;
  final String myId;
  @override
  State<_InGameChatSheet> createState() => _InGameChatSheetState();
}

class _InGameChatSheetState extends State<_InGameChatSheet> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    widget.game.sendChat(t);
    _ctrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients)
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: 200.ms,
          curve: Curves.easeOut,
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF1A2E45),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            '💬 Chat',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const Divider(color: Colors.white12),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.game,
              builder: (_, __) {
                final msgs = widget.game.chatMessages;
                return msgs.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: msgs.length,
                        itemBuilder: (_, i) {
                          final m = msgs[i];
                          final isMe = m.senderId == widget.myId;
                          final color =
                              _kChatColors[m.senderId.hashCode.abs() %
                                  _kChatColors.length];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: 8,
                              left: isMe ? 48 : 0,
                              right: isMe ? 0 : 48,
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 2,
                                    ),
                                    child: Text(
                                      m.senderName,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(0xFFFFD60A)
                                        : color.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(16)
                                        .copyWith(
                                          bottomRight: isMe
                                              ? const Radius.circular(4)
                                              : null,
                                          bottomLeft: isMe
                                              ? null
                                              : const Radius.circular(4),
                                        ),
                                  ),
                                  child: Text(
                                    m.text,
                                    style: TextStyle(
                                      color: isMe
                                          ? const Color(0xFF0D1B2A)
                                          : Colors.white,
                                      fontWeight: isMe
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.viewInsetsOf(context).bottom + 12,
            ),
            color: const Color(0xFF1A2E45),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Say something…',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.07),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD60A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF0D1B2A),
                      size: 20,
                    ),
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

const _kChatColors = [
  Color(0xFF4ECDC4),
  Color(0xFFA855F7),
  Color(0xFFFF6B6B),
  Color(0xFF4ADE80),
  Color(0xFFFB923C),
  Color(0xFF60A5FA),
  Color(0xFFF472B6),
  Color(0xFFFFD60A),
  Color(0xFF34D399),
  Color(0xFFC084FC),
];

class _PausedOverlay extends StatefulWidget {
  const _PausedOverlay({required this.onLeave});
  final VoidCallback onLeave;

  @override
  State<_PausedOverlay> createState() => _PausedOverlayState();
}

class _PausedOverlayState extends State<_PausedOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) =>
                      Opacity(opacity: 0.6 + _pulse.value * 0.4, child: child),
                  child: const Text('⏸', style: TextStyle(fontSize: 72)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Game Paused',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The host stepped away and will\nreturn shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  onPressed: widget.onLeave,
                  child: const Text('Leave for Now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
