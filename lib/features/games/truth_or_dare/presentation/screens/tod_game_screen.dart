// // // // // // // // // // // // // // import 'dart:async';

// // // // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // // // // // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // // // // // // // // // // // // import 'package:provider/provider.dart';
// // // // // // // // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // // // // // // // // // // // import '../../../../../core/di/service_locator.dart';
// // // // // // // // // // // // // // import '../../../../../core/extensions/context_ext.dart';
// // // // // // // // // // // // // // import '../../../../../core/providers/auth_provider.dart';
// // // // // // // // // // // // // // import '../../../../../core/router/route_names.dart';
// // // // // // // // // // // // // // import '../../../../../core/services/realtime_service.dart';
// // // // // // // // // // // // // // import '../../../../../core/theme/app_colors.dart';
// // // // // // // // // // // // // // import '../../../../../shared/widgets/feedback/error_view.dart';
// // // // // // // // // // // // // // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // // // // // // // // // // // // // // import '../../engine/base_game_engine.dart';
// // // // // // // // // // // // // // import '../../domain/tod_models.dart';
// // // // // // // // // // // // // // import '../../tod_game_provider.dart';
// // // // // // // // // // // // // // import '../../data/tod_repository.dart';
// // // // // // // // // // // // // // import 'tod_card_screen.dart';
// // // // // // // // // // // // // // import 'tod_end_screen.dart';
// // // // // // // // // // // // // // import 'tod_loading_screen.dart';
// // // // // // // // // // // // // // import 'tod_punishment_screen.dart';
// // // // // // // // // // // // // // import '../widgets/tod_hud.dart';

// // // // // // // // // // // // // // /// Entry point for an active Truth or Dare session.
// // // // // // // // // // // // // // ///
// // // // // // // // // // // // // // /// Responsibilities:
// // // // // // // // // // // // // // ///  - Owns and scopes TodGameProvider for this session
// // // // // // // // // // // // // // ///  - Wires RealtimeService callbacks → TodGameProvider
// // // // // // // // // // // // // // ///  - Routes between loading / error / active / game-over screens
// // // // // // // // // // // // // // ///  - Forwards game_state and player_action from the room Broadcast channel
// // // // // // // // // // // // // // class TodGameScreen extends StatefulWidget {
// // // // // // // // // // // // // //   const TodGameScreen({
// // // // // // // // // // // // // //     super.key,
// // // // // // // // // // // // // //     required this.roomId,
// // // // // // // // // // // // // //     required this.config,
// // // // // // // // // // // // // //     required this.playerIds,
// // // // // // // // // // // // // //     required this.playerDisplayNames,
// // // // // // // // // // // // // //     required this.packId,
// // // // // // // // // // // // // //     required this.isOwner,
// // // // // // // // // // // // // //     this.sessionId,
// // // // // // // // // // // // // //     this.isModerator = false,
// // // // // // // // // // // // // //   });

// // // // // // // // // // // // // //   final String roomId;
// // // // // // // // // // // // // //   final GameConfig config;
// // // // // // // // // // // // // //   final List<String> playerIds;
// // // // // // // // // // // // // //   final Map<String, String> playerDisplayNames; // userId → displayName
// // // // // // // // // // // // // //   final String packId;
// // // // // // // // // // // // // //   final bool isOwner;
// // // // // // // // // // // // // //   final String? sessionId;
// // // // // // // // // // // // // //   final bool isModerator;

// // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // //   State<TodGameScreen> createState() => _TodGameScreenState();
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // // class _TodGameScreenState extends State<TodGameScreen> {
// // // // // // // // // // // // // //   late final TodGameProvider _provider;

// // // // // // // // // // // // // //   // Subscriptions to the room Broadcast channel
// // // // // // // // // // // // // //   // (channel already open by RoomProvider — we just register callbacks)
// // // // // // // // // // // // // //   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

// // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // //   void initState() {
// // // // // // // // // // // // // //     super.initState();

// // // // // // // // // // // // // //     final auth = context.read<AuthProvider>();
// // // // // // // // // // // // // //     final user = auth.currentUser!;

// // // // // // // // // // // // // //     _provider = TodGameProvider(
// // // // // // // // // // // // // //       realtimeService: sl.realtimeService,
// // // // // // // // // // // // // //       repository: TodRepository.instance,
// // // // // // // // // // // // // //       currentUserId: user.id,
// // // // // // // // // // // // // //       currentDisplayName: user.displayName ?? user.username ?? 'Player',
// // // // // // // // // // // // // //       isModerator: widget.isModerator,
// // // // // // // // // // // // // //     );

// // // // // // // // // // // // // //     // ── Wire Broadcast callbacks ────────────────────────────────────────────
// // // // // // // // // // // // // //     // The room channel is already subscribed by RoomProvider/LobbyScreen.
// // // // // // // // // // // // // //     // TodGameScreen registers its own game-specific handlers for game_state
// // // // // // // // // // // // // //     // and player_action by re-subscribing with extended handlers.
// // // // // // // // // // // // // //     //
// // // // // // // // // // // // // //     // We do this by using the RealtimeService._bcast pattern:
// // // // // // // // // // // // // //     // The channel already has onGameState/onPlayerAction wired to no-ops
// // // // // // // // // // // // // //     // in RoomProvider. We replace them here by storing callbacks and
// // // // // // // // // // // // // //     // intercepting from the top-level channel via a dedicated subscription.
// // // // // // // // // // // // // //     _wireRealtimeCallbacks();

// // // // // // // // // // // // // //     if (widget.isOwner) {
// // // // // // // // // // // // // //       _provider.initAsOwner(
// // // // // // // // // // // // // //         roomId: widget.roomId,
// // // // // // // // // // // // // //         config: widget.config,
// // // // // // // // // // // // // //         playerIds: widget.playerIds,
// // // // // // // // // // // // // //         playerDisplayNames: widget.playerDisplayNames,
// // // // // // // // // // // // // //         packId: widget.packId,
// // // // // // // // // // // // // //       );
// // // // // // // // // // // // // //     } else {
// // // // // // // // // // // // // //       _provider.initAsFollower(
// // // // // // // // // // // // // //         roomId: widget.roomId,
// // // // // // // // // // // // // //         config: widget.config,
// // // // // // // // // // // // // //         sessionId: widget.sessionId,
// // // // // // // // // // // // // //       );
// // // // // // // // // // // // // //     }
// // // // // // // // // // // // // //   }

// // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // //   void dispose() {
// // // // // // // // // // // // // //     _statusSub?.cancel();
// // // // // // // // // // // // // //     _provider.dispose();
// // // // // // // // // // // // // //     super.dispose();
// // // // // // // // // // // // // //   }

// // // // // // // // // // // // // //   /// Wire game-specific callbacks into the existing room channel.
// // // // // // // // // // // // // //   ///
// // // // // // // // // // // // // //   /// Strategy: re-subscribe to the room channel with updated handlers that
// // // // // // // // // // // // // //   /// forward game_state and player_action to this provider.
// // // // // // // // // // // // // //   /// The channel is already open; we track callbacks via a thin interceptor.
// // // // // // // // // // // // // //   void _wireRealtimeCallbacks() {
// // // // // // // // // // // // // //     // Listen to channel status changes for reconnection awareness
// // // // // // // // // // // // // //     _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
// // // // // // // // // // // // // //       status,
// // // // // // // // // // // // // //     ) {
// // // // // // // // // // // // // //       if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // // // // // // // // // //           !_provider.hasSyncedState) {
// // // // // // // // // // // // // //         // Channel reconnected — request state sync
// // // // // // // // // // // // // //         sl.realtimeService.broadcastSyncRequest(
// // // // // // // // // // // // // //           widget.roomId,
// // // // // // // // // // // // // //           context.read<AuthProvider>().currentUser!.id,
// // // // // // // // // // // // // //           0,
// // // // // // // // // // // // // //         );
// // // // // // // // // // // // // //       }
// // // // // // // // // // // // // //     });

// // // // // // // // // // // // // //     // Re-subscribe with game handlers added.
// // // // // // // // // // // // // //     // This safely replaces the channel subscription with game callbacks.
// // // // // // // // // // // // // //     // (No-op handlers in RoomProvider are replaced with active ones here.)
// // // // // // // // // // // // // //     _resubscribeWithGameHandlers();
// // // // // // // // // // // // // //   }

// // // // // // // // // // // // // //   void _resubscribeWithGameHandlers() {
// // // // // // // // // // // // // //     final userId = context.read<AuthProvider>().currentUser!.id;

// // // // // // // // // // // // // //     // Unsubscribe existing channel and re-subscribe with game callbacks merged
// // // // // // // // // // // // // //     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
// // // // // // // // // // // // // //       sl.realtimeService.subscribe(
// // // // // // // // // // // // // //         roomId: widget.roomId,
// // // // // // // // // // // // // //         // ── Game-specific handlers ─────────────────────────────────────────
// // // // // // // // // // // // // //         onGameState: (p) => _provider.onStateBroadcast(p),
// // // // // // // // // // // // // //         onPlayerAction: (p) => _provider.onPlayerAction(p),
// // // // // // // // // // // // // //         onSyncRequest: (p) => _provider.onSyncRequest(p),
// // // // // // // // // // // // // //         onGameStarted: (_) {},
// // // // // // // // // // // // // //         onGameEnded: (_) {},
// // // // // // // // // // // // // //         // ── Room lifecycle (passthrough — RoomProvider is disposed) ─────────
// // // // // // // // // // // // // //         onRoomEvent: (_) {},
// // // // // // // // // // // // // //         onChatMessage: (_) {},
// // // // // // // // // // // // // //         onModeration: (p) => _handleModerationEvent(p),
// // // // // // // // // // // // // //         onSettingsChange: (_) {},
// // // // // // // // // // // // // //         // ── Presence ──────────────────────────────────────────────────────
// // // // // // // // // // // // // //         onPresenceSync: (_) {},
// // // // // // // // // // // // // //         onPresenceJoin: (_) {},
// // // // // // // // // // // // // //         onPresenceLeave: (_) {},
// // // // // // // // // // // // // //         onStatusChange: (status) {
// // // // // // // // // // // // // //           if (!mounted) return;
// // // // // // // // // // // // // //           if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // // // // // // // // // //               !_provider.hasSyncedState) {
// // // // // // // // // // // // // //             sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
// // // // // // // // // // // // // //           }
// // // // // // // // // // // // // //         },
// // // // // // // // // // // // // //       );
// // // // // // // // // // // // // //     });
// // // // // // // // // // // // // //   }

// // // // // // // // // // // // // //   void _handleModerationEvent(Map<String, dynamic> p) {
// // // // // // // // // // // // // //     final type = p['type'] as String?;
// // // // // // // // // // // // // //     final targetId = p['target_user_id'] as String?;
// // // // // // // // // // // // // //     final currentId = context.read<AuthProvider>().currentUser?.id;

// // // // // // // // // // // // // //     // If kicked or banned, navigate back to lobby
// // // // // // // // // // // // // //     if ((type == 'kick' || type == 'ban') && targetId == currentId) {
// // // // // // // // // // // // // //       if (mounted) context.go(RouteNames.home);
// // // // // // // // // // // // // //     }
// // // // // // // // // // // // // //   }

// // // // // // // // // // // // // //   @override
// // // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // // //     return ChangeNotifierProvider.value(
// // // // // // // // // // // // // //       value: _provider,
// // // // // // // // // // // // // //       child: Consumer<TodGameProvider>(
// // // // // // // // // // // // // //         builder: (ctx, game, _) => _build(ctx, game),
// // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // //     );
// // // // // // // // // // // // // //   }

// // // // // // // // // // // // // //   Widget _build(BuildContext ctx, TodGameProvider game) {
// // // // // // // // // // // // // //     if (game.loadState == TodLoadState.loading) {
// // // // // // // // // // // // // //       return const TodLoadingScreen();
// // // // // // // // // // // // // //     }

// // // // // // // // // // // // // //     if (game.loadState == TodLoadState.error) {
// // // // // // // // // // // // // //       return Scaffold(
// // // // // // // // // // // // // //         appBar: AppBar(
// // // // // // // // // // // // // //           leading: BackButton(onPressed: () => ctx.go(RouteNames.home)),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //         body: ErrorView(
// // // // // // // // // // // // // //           message: game.error ?? 'Failed to load game',
// // // // // // // // // // // // // //           onRetry: () => ctx.go(RouteNames.home),
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //       );
// // // // // // // // // // // // // //     }

// // // // // // // // // // // // // //     if (game.loadState == TodLoadState.gameOver ||
// // // // // // // // // // // // // //         (game.state?.isOver ?? false)) {
// // // // // // // // // // // // // //       return TodEndScreen(
// // // // // // // // // // // // // //         state: game.state!,
// // // // // // // // // // // // // //         displayNames: widget.playerDisplayNames,
// // // // // // // // // // // // // //         onLeave: () => ctx.go(RouteNames.home),
// // // // // // // // // // // // // //       );
// // // // // // // // // // // // // //     }

// // // // // // // // // // // // // //     final state = game.state;
// // // // // // // // // // // // // //     if (state == null) return const TodLoadingScreen();

// // // // // // // // // // // // // //     return Scaffold(
// // // // // // // // // // // // // //       body: SafeArea(
// // // // // // // // // // // // // //         child: Column(
// // // // // // // // // // // // // //           children: [
// // // // // // // // // // // // // //             TodHud(
// // // // // // // // // // // // // //               state: state,
// // // // // // // // // // // // // //               game: game,
// // // // // // // // // // // // // //               displayNames: widget.playerDisplayNames,
// // // // // // // // // // // // // //             ),
// // // // // // // // // // // // // //             Expanded(
// // // // // // // // // // // // // //               child: AnimatedSwitcher(
// // // // // // // // // // // // // //                 duration: const Duration(milliseconds: 300),
// // // // // // // // // // // // // //                 transitionBuilder: (child, anim) => FadeTransition(
// // // // // // // // // // // // // //                   opacity: anim,
// // // // // // // // // // // // // //                   child: SlideTransition(
// // // // // // // // // // // // // //                     position:
// // // // // // // // // // // // // //                         Tween<Offset>(
// // // // // // // // // // // // // //                           begin: const Offset(0, 0.05),
// // // // // // // // // // // // // //                           end: Offset.zero,
// // // // // // // // // // // // // //                         ).animate(
// // // // // // // // // // // // // //                           CurvedAnimation(
// // // // // // // // // // // // // //                             parent: anim,
// // // // // // // // // // // // // //                             curve: Curves.easeOutCubic,
// // // // // // // // // // // // // //                           ),
// // // // // // // // // // // // // //                         ),
// // // // // // // // // // // // // //                     child: child,
// // // // // // // // // // // // // //                   ),
// // // // // // // // // // // // // //                 ),
// // // // // // // // // // // // // //                 child: KeyedSubtree(
// // // // // // // // // // // // // //                   key: ValueKey('${state.phase}-${state.currentPlayerId}'),
// // // // // // // // // // // // // //                   child: _phaseWidget(ctx, game, state),
// // // // // // // // // // // // // //                 ),
// // // // // // // // // // // // // //               ),
// // // // // // // // // // // // // //             ),
// // // // // // // // // // // // // //           ],
// // // // // // // // // // // // // //         ),
// // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // //     );
// // // // // // // // // // // // // //   }

// // // // // // // // // // // // // //   Widget _phaseWidget(BuildContext ctx, TodGameProvider game, TodState state) {
// // // // // // // // // // // // // //     return switch (state.phase) {
// // // // // // // // // // // // // //       TodTurnPhase.punishmentVoting => TodPunishmentScreen(
// // // // // // // // // // // // // //         state: state,
// // // // // // // // // // // // // //         game: game,
// // // // // // // // // // // // // //         displayNames: widget.playerDisplayNames,
// // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // //       _ => TodCardScreen(
// // // // // // // // // // // // // //         state: state,
// // // // // // // // // // // // // //         game: game,
// // // // // // // // // // // // // //         displayNames: widget.playerDisplayNames,
// // // // // // // // // // // // // //       ),
// // // // // // // // // // // // // //     };
// // // // // // // // // // // // // //   }
// // // // // // // // // // // // // // }

// // // // // // // // // // // // // import 'dart:convert';
// // // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // // // // // // // // import 'package:image_picker/image_picker.dart';

// // // // // // // // // // // // // import '../../../../../core/extensions/context_ext.dart';
// // // // // // // // // // // // // import '../../../../../core/theme/app_colors.dart';
// // // // // // // // // // // // // import '../../../../../shared/widgets/buttons/j_button.dart';
// // // // // // // // // // // // // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // // // // // // // // // // // // import '../../domain/tod_models.dart';
// // // // // // // // // // // // // import '../../tod_game_provider.dart';
// // // // // // // // // // // // // import '../widgets/tod_player_banner.dart';
// // // // // // // // // // // // // import '../widgets/tod_timer_ring.dart';
// // // // // // // // // // // // // import '../widgets/tod_waiting_overlay.dart';

// // // // // // // // // // // // // /// Routes to the correct sub-view based on TodTurnPhase.
// // // // // // // // // // // // // class TodCardScreen extends StatelessWidget {
// // // // // // // // // // // // //   const TodCardScreen({
// // // // // // // // // // // // //     super.key,
// // // // // // // // // // // // //     required this.state,
// // // // // // // // // // // // //     required this.game,
// // // // // // // // // // // // //     required this.displayNames,
// // // // // // // // // // // // //   });

// // // // // // // // // // // // //   final TodState state;
// // // // // // // // // // // // //   final TodGameProvider game;
// // // // // // // // // // // // //   final Map<String, String> displayNames;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     return switch (state.phase) {
// // // // // // // // // // // // //       TodTurnPhase.choosingType => _ChoiceView(
// // // // // // // // // // // // //         state: state,
// // // // // // // // // // // // //         game: game,
// // // // // // // // // // // // //         displayNames: displayNames,
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //       TodTurnPhase.readingCard => _CardView(
// // // // // // // // // // // // //         state: state,
// // // // // // // // // // // // //         game: game,
// // // // // // // // // // // // //         displayNames: displayNames,
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //       TodTurnPhase.awaitingNextTurn => _AwaitingView(
// // // // // // // // // // // // //         state: state,
// // // // // // // // // // // // //         game: game,
// // // // // // // // // // // // //         displayNames: displayNames,
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //       TodTurnPhase.awaitingResult => _CardView(
// // // // // // // // // // // // //         state: state,
// // // // // // // // // // // // //         game: game,
// // // // // // // // // // // // //         displayNames: displayNames,
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //       _ => _ChoiceView(state: state, game: game, displayNames: displayNames),
// // // // // // // // // // // // //     };
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // // ── 1. Choice view ─────────────────────────────────────────────────────────────
// // // // // // // // // // // // // class _ChoiceView extends StatelessWidget {
// // // // // // // // // // // // //   const _ChoiceView({
// // // // // // // // // // // // //     required this.state,
// // // // // // // // // // // // //     required this.game,
// // // // // // // // // // // // //     required this.displayNames,
// // // // // // // // // // // // //   });
// // // // // // // // // // // // //   final TodState state;
// // // // // // // // // // // // //   final TodGameProvider game;
// // // // // // // // // // // // //   final Map<String, String> displayNames;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     final theme = context.theme;
// // // // // // // // // // // // //     final isMyTurn = game.isMyTurn;
// // // // // // // // // // // // //     final playerName =
// // // // // // // // // // // // //         displayNames[state.currentPlayerId] ??
// // // // // // // // // // // // //         'Player ${state.currentPlayerId.substring(0, 4)}';

// // // // // // // // // // // // //     return Stack(
// // // // // // // // // // // // //       children: [
// // // // // // // // // // // // //         Padding(
// // // // // // // // // // // // //           padding: const EdgeInsets.all(24),
// // // // // // // // // // // // //           child: Column(
// // // // // // // // // // // // //             children: [
// // // // // // // // // // // // //               TodPlayerBanner(
// // // // // // // // // // // // //                 playerId: state.currentPlayerId,
// // // // // // // // // // // // //                 playerName: playerName,
// // // // // // // // // // // // //                 playerOrder: state.playerOrder,
// // // // // // // // // // // // //                 isMyTurn: isMyTurn,
// // // // // // // // // // // // //               ),

// // // // // // // // // // // // //               const Spacer(),

// // // // // // // // // // // // //               Text(
// // // // // // // // // // // // //                 isMyTurn ? 'Choose your challenge' : '$playerName is choosing…',
// // // // // // // // // // // // //                 style: theme.textTheme.headlineSmall?.copyWith(
// // // // // // // // // // // // //                   fontWeight: FontWeight.w700,
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //                 textAlign: TextAlign.center,
// // // // // // // // // // // // //               ).animate().fadeIn().slideY(begin: 0.08, end: 0),

// // // // // // // // // // // // //               const SizedBox(height: 40),

// // // // // // // // // // // // //               if (isMyTurn) ...[
// // // // // // // // // // // // //                 _ChoiceButton(
// // // // // // // // // // // // //                   label: 'Truth',
// // // // // // // // // // // // //                   emoji: '🤔',
// // // // // // // // // // // // //                   color: AppColors.truthColor,
// // // // // // // // // // // // //                   description: 'Answer a personal question honestly.',
// // // // // // // // // // // // //                   onTap: game.chooseTruth,
// // // // // // // // // // // // //                 ).animate(delay: 80.ms).fadeIn().slideX(begin: -0.08, end: 0),

// // // // // // // // // // // // //                 const SizedBox(height: 16),

// // // // // // // // // // // // //                 _ChoiceButton(
// // // // // // // // // // // // //                   label: 'Dare',
// // // // // // // // // // // // //                   emoji: '🔥',
// // // // // // // // // // // // //                   color: AppColors.dareColor,
// // // // // // // // // // // // //                   description: 'Complete a daring challenge.',
// // // // // // // // // // // // //                   onTap: game.chooseDare,
// // // // // // // // // // // // //                 ).animate(delay: 140.ms).fadeIn().slideX(begin: 0.08, end: 0),
// // // // // // // // // // // // //               ] else
// // // // // // // // // // // // //                 _ChoiceWaiting(playerName: playerName),

// // // // // // // // // // // // //               const Spacer(),
// // // // // // // // // // // // //             ],
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //         ),

// // // // // // // // // // // // //         if (!isMyTurn) const TodWaitingOverlay(),
// // // // // // // // // // // // //       ],
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _ChoiceWaiting extends StatelessWidget {
// // // // // // // // // // // // //   const _ChoiceWaiting({required this.playerName});
// // // // // // // // // // // // //   final String playerName;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     return Column(
// // // // // // // // // // // // //       children: [
// // // // // // // // // // // // //         const SizedBox(
// // // // // // // // // // // // //           width: 48,
// // // // // // // // // // // // //           height: 48,
// // // // // // // // // // // // //           child: CircularProgressIndicator(strokeWidth: 3),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         const SizedBox(height: 16),
// // // // // // // // // // // // //         Text(
// // // // // // // // // // // // //           'Waiting for $playerName to decide…',
// // // // // // // // // // // // //           style: context.textTheme.bodyMedium?.copyWith(
// // // // // // // // // // // // //             color: context.colorScheme.onSurfaceVariant,
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //           textAlign: TextAlign.center,
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //       ],
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _ChoiceButton extends StatelessWidget {
// // // // // // // // // // // // //   const _ChoiceButton({
// // // // // // // // // // // // //     required this.label,
// // // // // // // // // // // // //     required this.emoji,
// // // // // // // // // // // // //     required this.color,
// // // // // // // // // // // // //     required this.description,
// // // // // // // // // // // // //     required this.onTap,
// // // // // // // // // // // // //   });

// // // // // // // // // // // // //   final String label;
// // // // // // // // // // // // //   final String emoji;
// // // // // // // // // // // // //   final Color color;
// // // // // // // // // // // // //   final String description;
// // // // // // // // // // // // //   final VoidCallback onTap;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     return GestureDetector(
// // // // // // // // // // // // //       onTap: onTap,
// // // // // // // // // // // // //       child: Container(
// // // // // // // // // // // // //         width: double.infinity,
// // // // // // // // // // // // //         padding: const EdgeInsets.all(24),
// // // // // // // // // // // // //         decoration: BoxDecoration(
// // // // // // // // // // // // //           gradient: LinearGradient(
// // // // // // // // // // // // //             colors: [color, color.withOpacity(0.8)],
// // // // // // // // // // // // //             begin: Alignment.topLeft,
// // // // // // // // // // // // //             end: Alignment.bottomRight,
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //           borderRadius: BorderRadius.circular(20),
// // // // // // // // // // // // //           boxShadow: [
// // // // // // // // // // // // //             BoxShadow(
// // // // // // // // // // // // //               color: color.withOpacity(0.3),
// // // // // // // // // // // // //               blurRadius: 16,
// // // // // // // // // // // // //               offset: const Offset(0, 6),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //           ],
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         child: Row(
// // // // // // // // // // // // //           children: [
// // // // // // // // // // // // //             Text(emoji, style: const TextStyle(fontSize: 40)),
// // // // // // // // // // // // //             const SizedBox(width: 20),
// // // // // // // // // // // // //             Expanded(
// // // // // // // // // // // // //               child: Column(
// // // // // // // // // // // // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // // // // // //                 children: [
// // // // // // // // // // // // //                   Text(
// // // // // // // // // // // // //                     label,
// // // // // // // // // // // // //                     style: const TextStyle(
// // // // // // // // // // // // //                       fontSize: 26,
// // // // // // // // // // // // //                       fontWeight: FontWeight.w800,
// // // // // // // // // // // // //                       color: Colors.white,
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                   const SizedBox(height: 4),
// // // // // // // // // // // // //                   Text(
// // // // // // // // // // // // //                     description,
// // // // // // // // // // // // //                     style: TextStyle(
// // // // // // // // // // // // //                       fontSize: 13,
// // // // // // // // // // // // //                       color: Colors.white.withOpacity(0.85),
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                 ],
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //             const Icon(
// // // // // // // // // // // // //               Icons.chevron_right_rounded,
// // // // // // // // // // // // //               color: Colors.white,
// // // // // // // // // // // // //               size: 28,
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //           ],
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // // ── 2. Card reading view ───────────────────────────────────────────────────────
// // // // // // // // // // // // // class _CardView extends StatelessWidget {
// // // // // // // // // // // // //   const _CardView({
// // // // // // // // // // // // //     required this.state,
// // // // // // // // // // // // //     required this.game,
// // // // // // // // // // // // //     required this.displayNames,
// // // // // // // // // // // // //   });
// // // // // // // // // // // // //   final TodState state;
// // // // // // // // // // // // //   final TodGameProvider game;
// // // // // // // // // // // // //   final Map<String, String> displayNames;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     final theme = context.theme;
// // // // // // // // // // // // //     final card = state.currentCard;
// // // // // // // // // // // // //     final isMyTurn = game.isMyTurn;

// // // // // // // // // // // // //     if (card == null) {
// // // // // // // // // // // // //       return const Center(child: Text('No card available — all cards used!'));
// // // // // // // // // // // // //     }

// // // // // // // // // // // // //     final isSpicy = card.difficulty == TodDifficulty.spicy;
// // // // // // // // // // // // //     final isTruth = card.type == TodCardType.truth;
// // // // // // // // // // // // //     final cardColor = isTruth ? AppColors.truthColor : AppColors.dareColor;
// // // // // // // // // // // // //     final playerName =
// // // // // // // // // // // // //         displayNames[state.currentPlayerId] ??
// // // // // // // // // // // // //         'Player ${state.currentPlayerId.substring(0, 4)}';

// // // // // // // // // // // // //     return Padding(
// // // // // // // // // // // // //       padding: const EdgeInsets.all(20),
// // // // // // // // // // // // //       child: Column(
// // // // // // // // // // // // //         children: [
// // // // // // // // // // // // //           TodPlayerBanner(
// // // // // // // // // // // // //             playerId: state.currentPlayerId,
// // // // // // // // // // // // //             playerName: playerName,
// // // // // // // // // // // // //             playerOrder: state.playerOrder,
// // // // // // // // // // // // //             isMyTurn: isMyTurn,
// // // // // // // // // // // // //           ),

// // // // // // // // // // // // //           const SizedBox(height: 12),

// // // // // // // // // // // // //           // Timer ring — only when active
// // // // // // // // // // // // //           if (game.timerIsRunning || game.timerRemaining > 0)
// // // // // // // // // // // // //             Padding(
// // // // // // // // // // // // //               padding: const EdgeInsets.only(bottom: 12),
// // // // // // // // // // // // //               child: TodTimerRing(
// // // // // // // // // // // // //                 remaining: game.timerRemaining,
// // // // // // // // // // // // //                 total: game.state != null
// // // // // // // // // // // // //                     ? (80) // default; actual from config
// // // // // // // // // // // // //                     : 60,
// // // // // // // // // // // // //                 color: cardColor,
// // // // // // // // // // // // //               ).animate().fadeIn(),
// // // // // // // // // // // // //             ),

// // // // // // // // // // // // //           // Card face
// // // // // // // // // // // // //           Expanded(
// // // // // // // // // // // // //             child: _CardFace(
// // // // // // // // // // // // //               card: card,
// // // // // // // // // // // // //               cardColor: cardColor,
// // // // // // // // // // // // //               isSpicy: isSpicy,
// // // // // // // // // // // // //               isTruth: isTruth,
// // // // // // // // // // // // //               coverUrl: game.packCoverUrl,
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //           ),

// // // // // // // // // // // // //           const SizedBox(height: 20),

// // // // // // // // // // // // //           // Action buttons
// // // // // // // // // // // // //           if (isMyTurn) ...[
// // // // // // // // // // // // //             JButton(
// // // // // // // // // // // // //               label: 'Done! ✅',
// // // // // // // // // // // // //               onPressed: () =>
// // // // // // // // // // // // //                   _showCompleteSheet(context, game, isTruth: isTruth),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //             const SizedBox(height: 10),
// // // // // // // // // // // // //             TextButton(
// // // // // // // // // // // // //               onPressed: () => _confirmSkip(context),
// // // // // // // // // // // // //               child: Text(
// // // // // // // // // // // // //                 'Skip',
// // // // // // // // // // // // //                 style: TextStyle(
// // // // // // // // // // // // //                   color: theme.colorScheme.onSurfaceVariant,
// // // // // // // // // // // // //                   fontWeight: FontWeight.w600,
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //           ] else
// // // // // // // // // // // // //             Text(
// // // // // // // // // // // // //               '$playerName is performing…',
// // // // // // // // // // // // //               style: theme.textTheme.bodyMedium?.copyWith(
// // // // // // // // // // // // //                 color: theme.colorScheme.onSurfaceVariant,
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ),

// // // // // // // // // // // // //           // Moderator override row
// // // // // // // // // // // // //           if (game.canModerate && !isMyTurn)
// // // // // // // // // // // // //             Padding(
// // // // // // // // // // // // //               padding: const EdgeInsets.only(top: 6),
// // // // // // // // // // // // //               child: TextButton.icon(
// // // // // // // // // // // // //                 onPressed: game.ownerAdvanceTurn,
// // // // // // // // // // // // //                 icon: const Icon(Icons.skip_next_rounded, size: 16),
// // // // // // // // // // // // //                 label: const Text('Skip turn (mod)'),
// // // // // // // // // // // // //                 style: TextButton.styleFrom(
// // // // // // // // // // // // //                   foregroundColor: AppColors.warningAmber,
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //         ],
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }

// // // // // // // // // // // // //   void _showCompleteSheet(
// // // // // // // // // // // // //     BuildContext context,
// // // // // // // // // // // // //     TodGameProvider game, {
// // // // // // // // // // // // //     bool isTruth = false,
// // // // // // // // // // // // //   }) {
// // // // // // // // // // // // //     final ctrl = TextEditingController();
// // // // // // // // // // // // //     String? imgB64;
// // // // // // // // // // // // //     bool _attempted = false;

// // // // // // // // // // // // //     showModalBottomSheet(
// // // // // // // // // // // // //       context: context,
// // // // // // // // // // // // //       isScrollControlled: true,
// // // // // // // // // // // // //       backgroundColor: Colors.transparent,
// // // // // // // // // // // // //       builder: (ctx) => StatefulBuilder(
// // // // // // // // // // // // //         builder: (ctx, setS) {
// // // // // // // // // // // // //           return Padding(
// // // // // // // // // // // // //             padding: EdgeInsets.only(
// // // // // // // // // // // // //               bottom: MediaQuery.of(ctx).viewInsets.bottom,
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //             child: Container(
// // // // // // // // // // // // //               padding: const EdgeInsets.all(20),
// // // // // // // // // // // // //               decoration: BoxDecoration(
// // // // // // // // // // // // //                 color: Theme.of(ctx).colorScheme.surface,
// // // // // // // // // // // // //                 borderRadius: const BorderRadius.vertical(
// // // // // // // // // // // // //                   top: Radius.circular(20),
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //               child: Column(
// // // // // // // // // // // // //                 mainAxisSize: MainAxisSize.min,
// // // // // // // // // // // // //                 crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // // // // // // // // // //                 children: [
// // // // // // // // // // // // //                   Center(
// // // // // // // // // // // // //                     child: Container(
// // // // // // // // // // // // //                       width: 36,
// // // // // // // // // // // // //                       height: 4,
// // // // // // // // // // // // //                       decoration: BoxDecoration(
// // // // // // // // // // // // //                         color: Colors.grey.shade300,
// // // // // // // // // // // // //                         borderRadius: BorderRadius.circular(2),
// // // // // // // // // // // // //                       ),
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                   const SizedBox(height: 16),
// // // // // // // // // // // // //                   Row(
// // // // // // // // // // // // //                     children: [
// // // // // // // // // // // // //                       Text(
// // // // // // // // // // // // //                         isTruth ? '🤔 Truth' : '🔥 Dare',
// // // // // // // // // // // // //                         style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
// // // // // // // // // // // // //                           color: isTruth
// // // // // // // // // // // // //                               ? AppColors.truthColor
// // // // // // // // // // // // //                               : AppColors.dareColor,
// // // // // // // // // // // // //                           fontWeight: FontWeight.w700,
// // // // // // // // // // // // //                         ),
// // // // // // // // // // // // //                       ),
// // // // // // // // // // // // //                       const SizedBox(width: 8),
// // // // // // // // // // // // //                       Text(
// // // // // // // // // // // // //                         'Complete Turn',
// // // // // // // // // // // // //                         style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
// // // // // // // // // // // // //                           fontWeight: FontWeight.w700,
// // // // // // // // // // // // //                         ),
// // // // // // // // // // // // //                       ),
// // // // // // // // // // // // //                     ],
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                   const SizedBox(height: 12),
// // // // // // // // // // // // //                   // Truth: response required. Dare: response optional.
// // // // // // // // // // // // //                   TextField(
// // // // // // // // // // // // //                     controller: ctrl,
// // // // // // // // // // // // //                     maxLines: 3,
// // // // // // // // // // // // //                     maxLength: 300,
// // // // // // // // // // // // //                     decoration: InputDecoration(
// // // // // // // // // // // // //                       hintText: isTruth
// // // // // // // // // // // // //                           ? 'Your answer is required…'
// // // // // // // // // // // // //                           : 'Add a description (optional)…',
// // // // // // // // // // // // //                       border: const OutlineInputBorder(),
// // // // // // // // // // // // //                       errorText:
// // // // // // // // // // // // //                           isTruth && ctrl.text.trim().isEmpty && _attempted
// // // // // // // // // // // // //                           ? 'Truth requires a response'
// // // // // // // // // // // // //                           : null,
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                     onChanged: (_) => setS(() {}),
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                   const SizedBox(height: 8),
// // // // // // // // // // // // //                   // Proof image — Dares only
// // // // // // // // // // // // //                   if (!isTruth) ...[
// // // // // // // // // // // // //                     if (imgB64 != null)
// // // // // // // // // // // // //                       Stack(
// // // // // // // // // // // // //                         children: [
// // // // // // // // // // // // //                           ClipRRect(
// // // // // // // // // // // // //                             borderRadius: BorderRadius.circular(8),
// // // // // // // // // // // // //                             child: Image.memory(
// // // // // // // // // // // // //                               base64Decode(imgB64!),
// // // // // // // // // // // // //                               height: 120,
// // // // // // // // // // // // //                               width: double.infinity,
// // // // // // // // // // // // //                               fit: BoxFit.cover,
// // // // // // // // // // // // //                             ),
// // // // // // // // // // // // //                           ),
// // // // // // // // // // // // //                           Positioned(
// // // // // // // // // // // // //                             top: 4,
// // // // // // // // // // // // //                             right: 4,
// // // // // // // // // // // // //                             child: GestureDetector(
// // // // // // // // // // // // //                               onTap: () => setS(() => imgB64 = null),
// // // // // // // // // // // // //                               child: const CircleAvatar(
// // // // // // // // // // // // //                                 radius: 12,
// // // // // // // // // // // // //                                 backgroundColor: Colors.black54,
// // // // // // // // // // // // //                                 child: Icon(
// // // // // // // // // // // // //                                   Icons.close,
// // // // // // // // // // // // //                                   size: 14,
// // // // // // // // // // // // //                                   color: Colors.white,
// // // // // // // // // // // // //                                 ),
// // // // // // // // // // // // //                               ),
// // // // // // // // // // // // //                             ),
// // // // // // // // // // // // //                           ),
// // // // // // // // // // // // //                         ],
// // // // // // // // // // // // //                       )
// // // // // // // // // // // // //                     else
// // // // // // // // // // // // //                       OutlinedButton.icon(
// // // // // // // // // // // // //                         onPressed: () async {
// // // // // // // // // // // // //                           try {
// // // // // // // // // // // // //                             final picked = await ImagePicker().pickImage(
// // // // // // // // // // // // //                               source: ImageSource.gallery,
// // // // // // // // // // // // //                               imageQuality: 40,
// // // // // // // // // // // // //                             );
// // // // // // // // // // // // //                             if (picked != null) {
// // // // // // // // // // // // //                               final bytes = await picked.readAsBytes();
// // // // // // // // // // // // //                               setS(() => imgB64 = base64Encode(bytes));
// // // // // // // // // // // // //                             }
// // // // // // // // // // // // //                           } catch (_) {}
// // // // // // // // // // // // //                         },
// // // // // // // // // // // // //                         icon: const Icon(Icons.add_photo_alternate_outlined),
// // // // // // // // // // // // //                         label: const Text('Add proof photo (view once)'),
// // // // // // // // // // // // //                       ),
// // // // // // // // // // // // //                     const SizedBox(height: 8),
// // // // // // // // // // // // //                   ],
// // // // // // // // // // // // //                   const SizedBox(height: 8),
// // // // // // // // // // // // //                   FilledButton(
// // // // // // // // // // // // //                     onPressed: () {
// // // // // // // // // // // // //                       // Truth: enforce non-empty response
// // // // // // // // // // // // //                       if (isTruth && ctrl.text.trim().isEmpty) {
// // // // // // // // // // // // //                         setS(() => _attempted = true);
// // // // // // // // // // // // //                         return;
// // // // // // // // // // // // //                       }
// // // // // // // // // // // // //                       Navigator.of(ctx).pop();
// // // // // // // // // // // // //                       game.completeTurn(
// // // // // // // // // // // // //                         response: ctrl.text.trim(),
// // // // // // // // // // // // //                         proofImageB64: imgB64 ?? '',
// // // // // // // // // // // // //                       );
// // // // // // // // // // // // //                     },
// // // // // // // // // // // // //                     child: const Text('Submit & Complete Turn ✅'),
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                   const SizedBox(height: 4),
// // // // // // // // // // // // //                   TextButton(
// // // // // // // // // // // // //                     onPressed: () => Navigator.of(ctx).pop(),
// // // // // // // // // // // // //                     child: const Text('Cancel'),
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                 ],
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //           );
// // // // // // // // // // // // //         },
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }

// // // // // // // // // // // // //   Future<void> _confirmSkip(BuildContext context) async {
// // // // // // // // // // // // //     final confirmed = await showConfirmDialog(
// // // // // // // // // // // // //       context: context,
// // // // // // // // // // // // //       title: 'Skip this card?',
// // // // // // // // // // // // //       message: 'Skipping may result in a group punishment vote.',
// // // // // // // // // // // // //       confirmLabel: 'Skip',
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //     if (confirmed == true) game.skipTurn();
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _CardFace extends StatelessWidget {
// // // // // // // // // // // // //   const _CardFace({
// // // // // // // // // // // // //     required this.card,
// // // // // // // // // // // // //     required this.cardColor,
// // // // // // // // // // // // //     required this.isSpicy,
// // // // // // // // // // // // //     required this.isTruth,
// // // // // // // // // // // // //     this.coverUrl,
// // // // // // // // // // // // //   });

// // // // // // // // // // // // //   final TodCard card;
// // // // // // // // // // // // //   final Color cardColor;
// // // // // // // // // // // // //   final bool isSpicy;
// // // // // // // // // // // // //   final bool isTruth;
// // // // // // // // // // // // //   final String? coverUrl;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     final hasCover = coverUrl != null && coverUrl!.isNotEmpty;
// // // // // // // // // // // // //     return ClipRRect(
// // // // // // // // // // // // //       borderRadius: BorderRadius.circular(24),
// // // // // // // // // // // // //       child: Container(
// // // // // // // // // // // // //         width: double.infinity,
// // // // // // // // // // // // //         decoration: BoxDecoration(
// // // // // // // // // // // // //           borderRadius: BorderRadius.circular(24),
// // // // // // // // // // // // //           border: Border.all(color: cardColor.withOpacity(0.55), width: 1.5),
// // // // // // // // // // // // //           boxShadow: [
// // // // // // // // // // // // //             BoxShadow(
// // // // // // // // // // // // //               color: cardColor.withOpacity(0.38),
// // // // // // // // // // // // //               blurRadius: 24,
// // // // // // // // // // // // //               offset: const Offset(0, 8),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //             BoxShadow(
// // // // // // // // // // // // //               color: Colors.black.withOpacity(0.25),
// // // // // // // // // // // // //               blurRadius: 10,
// // // // // // // // // // // // //               offset: const Offset(0, 3),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //           ],
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         child: Stack(
// // // // // // // // // // // // //           children: [
// // // // // // // // // // // // //             // Background image or app default
// // // // // // // // // // // // //             Positioned.fill(
// // // // // // // // // // // // //               child: hasCover
// // // // // // // // // // // // //                   ? Image.network(
// // // // // // // // // // // // //                       coverUrl!,
// // // // // // // // // // // // //                       fit: BoxFit.cover,
// // // // // // // // // // // // //                       width: double.infinity,
// // // // // // // // // // // // //                       height: double.infinity,
// // // // // // // // // // // // //                       errorBuilder: (_, __, ___) => Image.asset(
// // // // // // // // // // // // //                         'assets/images/jma3a_card_background.png',
// // // // // // // // // // // // //                         fit: BoxFit.cover,
// // // // // // // // // // // // //                         width: double.infinity,
// // // // // // // // // // // // //                         height: double.infinity,
// // // // // // // // // // // // //                       ),
// // // // // // // // // // // // //                     )
// // // // // // // // // // // // //                   : Image.asset(
// // // // // // // // // // // // //                       'assets/images/jma3a_card_background.png',
// // // // // // // // // // // // //                       fit: BoxFit.cover,
// // // // // // // // // // // // //                       width: double.infinity,
// // // // // // // // // // // // //                       height: double.infinity,
// // // // // // // // // // // // //                       errorBuilder: (_, __, ___) => Container(
// // // // // // // // // // // // //                         decoration: BoxDecoration(
// // // // // // // // // // // // //                           gradient: LinearGradient(
// // // // // // // // // // // // //                             colors: [cardColor, cardColor.withOpacity(0.78)],
// // // // // // // // // // // // //                             begin: Alignment.topLeft,
// // // // // // // // // // // // //                             end: Alignment.bottomRight,
// // // // // // // // // // // // //                           ),
// // // // // // // // // // // // //                         ),
// // // // // // // // // // // // //                       ),
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //             // Colour tint
// // // // // // // // // // // // //             Positioned.fill(
// // // // // // // // // // // // //               child: Container(
// // // // // // // // // // // // //                 decoration: BoxDecoration(
// // // // // // // // // // // // //                   gradient: LinearGradient(
// // // // // // // // // // // // //                     colors: [
// // // // // // // // // // // // //                       cardColor.withOpacity(0.45),
// // // // // // // // // // // // //                       const Color(0xFF0D1B2A).withOpacity(0.60),
// // // // // // // // // // // // //                     ],
// // // // // // // // // // // // //                     begin: Alignment.topCenter,
// // // // // // // // // // // // //                     end: Alignment.bottomCenter,
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //             // Shimmer
// // // // // // // // // // // // //             Positioned.fill(child: CustomPaint(painter: _CardShimmerPainter())),
// // // // // // // // // // // // //             // Content
// // // // // // // // // // // // //             Padding(
// // // // // // // // // // // // //               padding: const EdgeInsets.all(28),
// // // // // // // // // // // // //               child: Column(
// // // // // // // // // // // // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // // // // // //                 children: [
// // // // // // // // // // // // //                   Row(
// // // // // // // // // // // // //                     children: [
// // // // // // // // // // // // //                       _TypeBadge(label: isTruth ? '🤔  TRUTH' : '🔥  DARE'),
// // // // // // // // // // // // //                       if (isSpicy) ...[const SizedBox(width: 8), _SpicyBadge()],
// // // // // // // // // // // // //                     ],
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                   const Spacer(),
// // // // // // // // // // // // //                   Text(
// // // // // // // // // // // // //                     card.content,
// // // // // // // // // // // // //                     style: const TextStyle(
// // // // // // // // // // // // //                       fontSize: 22,
// // // // // // // // // // // // //                       fontWeight: FontWeight.w700,
// // // // // // // // // // // // //                       color: Colors.white,
// // // // // // // // // // // // //                       height: 1.45,
// // // // // // // // // // // // //                       shadows: [
// // // // // // // // // // // // //                         Shadow(
// // // // // // // // // // // // //                           color: Colors.black54,
// // // // // // // // // // // // //                           blurRadius: 8,
// // // // // // // // // // // // //                           offset: Offset(0, 2),
// // // // // // // // // // // // //                         ),
// // // // // // // // // // // // //                       ],
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                   ).animate().fadeIn(duration: 350.ms),
// // // // // // // // // // // // //                   const Spacer(),
// // // // // // // // // // // // //                 ],
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //             // Corner suit
// // // // // // // // // // // // //             Positioned(
// // // // // // // // // // // // //               top: 10,
// // // // // // // // // // // // //               left: 12,
// // // // // // // // // // // // //               child: Opacity(
// // // // // // // // // // // // //                 opacity: 0.18,
// // // // // // // // // // // // //                 child: Text(
// // // // // // // // // // // // //                   isTruth ? '🤔' : '🔥',
// // // // // // // // // // // // //                   style: const TextStyle(fontSize: 18),
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //             Positioned(
// // // // // // // // // // // // //               bottom: 10,
// // // // // // // // // // // // //               right: 12,
// // // // // // // // // // // // //               child: Opacity(
// // // // // // // // // // // // //                 opacity: 0.18,
// // // // // // // // // // // // //                 child: RotatedBox(
// // // // // // // // // // // // //                   quarterTurns: 2,
// // // // // // // // // // // // //                   child: Text(
// // // // // // // // // // // // //                     isTruth ? '🤔' : '🔥',
// // // // // // // // // // // // //                     style: const TextStyle(fontSize: 18),
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //           ],
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //     ).animate().scale(
// // // // // // // // // // // // //       begin: const Offset(0.92, 0.92),
// // // // // // // // // // // // //       end: const Offset(1, 1),
// // // // // // // // // // // // //       duration: 320.ms,
// // // // // // // // // // // // //       curve: Curves.easeOutBack,
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _CardShimmerPainter extends CustomPainter {
// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   void paint(Canvas canvas, Size size) {
// // // // // // // // // // // // //     final p = Paint()
// // // // // // // // // // // // //       ..color = Colors.white.withOpacity(0.025)
// // // // // // // // // // // // //       ..strokeWidth = 12
// // // // // // // // // // // // //       ..style = PaintingStyle.stroke;
// // // // // // // // // // // // //     for (double x = -size.height; x < size.width * 2; x += 38)
// // // // // // // // // // // // //       canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
// // // // // // // // // // // // //   }

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   bool shouldRepaint(_) => false;
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _TypeBadge extends StatelessWidget {
// // // // // // // // // // // // //   const _TypeBadge({required this.label});
// // // // // // // // // // // // //   final String label;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     return Container(
// // // // // // // // // // // // //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// // // // // // // // // // // // //       decoration: BoxDecoration(
// // // // // // // // // // // // //         color: Colors.white.withOpacity(0.2),
// // // // // // // // // // // // //         borderRadius: BorderRadius.circular(20),
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //       child: Text(
// // // // // // // // // // // // //         label,
// // // // // // // // // // // // //         style: const TextStyle(
// // // // // // // // // // // // //           color: Colors.white,
// // // // // // // // // // // // //           fontWeight: FontWeight.w800,
// // // // // // // // // // // // //           fontSize: 13,
// // // // // // // // // // // // //           letterSpacing: 1,
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _SpicyBadge extends StatelessWidget {
// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     return Container(
// // // // // // // // // // // // //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// // // // // // // // // // // // //       decoration: BoxDecoration(
// // // // // // // // // // // // //         color: AppColors.spicyColor.withOpacity(0.8),
// // // // // // // // // // // // //         borderRadius: BorderRadius.circular(20),
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //       child: const Text(
// // // // // // // // // // // // //         '🌶 SPICY',
// // // // // // // // // // // // //         style: TextStyle(
// // // // // // // // // // // // //           color: Colors.white,
// // // // // // // // // // // // //           fontWeight: FontWeight.w700,
// // // // // // // // // // // // //           fontSize: 12,
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // // ── 3. Awaiting next turn ──────────────────────────────────────────────────────
// // // // // // // // // // // // // class _AwaitingView extends StatelessWidget {
// // // // // // // // // // // // //   const _AwaitingView({
// // // // // // // // // // // // //     required this.state,
// // // // // // // // // // // // //     required this.game,
// // // // // // // // // // // // //     required this.displayNames,
// // // // // // // // // // // // //   });
// // // // // // // // // // // // //   final TodState state;
// // // // // // // // // // // // //   final TodGameProvider game;
// // // // // // // // // // // // //   final Map<String, String> displayNames;

// // // // // // // // // // // // //   Future<void> _confirmEndGame(BuildContext context) async {
// // // // // // // // // // // // //     final confirmed = await showDialog<bool>(
// // // // // // // // // // // // //       context: context,
// // // // // // // // // // // // //       builder: (_) => AlertDialog(
// // // // // // // // // // // // //         title: const Text('End Game?'),
// // // // // // // // // // // // //         content: const Text('This will end the game for all players.'),
// // // // // // // // // // // // //         actions: [
// // // // // // // // // // // // //           TextButton(
// // // // // // // // // // // // //             onPressed: () => Navigator.pop(context, false),
// // // // // // // // // // // // //             child: const Text('Cancel'),
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //           FilledButton(
// // // // // // // // // // // // //             onPressed: () => Navigator.pop(context, true),
// // // // // // // // // // // // //             style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
// // // // // // // // // // // // //             child: const Text('End Game'),
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //         ],
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //     if (confirmed == true) game.endGame();
// // // // // // // // // // // // //   }

// // // // // // // // // // // // //   String _name(String id) =>
// // // // // // // // // // // // //       displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     final theme = context.theme;
// // // // // // // // // // // // //     final myReacted = state.currentReactions.any(
// // // // // // // // // // // // //       (r) => r.userId == game.currentUserId,
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //     final myVoted = state.currentVotes.any(
// // // // // // // // // // // // //       (v) => v.voterId == game.currentUserId,
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //     final isMyTurn = state.currentPlayerId == game.currentUserId;

// // // // // // // // // // // // //     // Group reactions
// // // // // // // // // // // // //     final reactTally = <String, int>{};
// // // // // // // // // // // // //     for (final r in state.currentReactions) {
// // // // // // // // // // // // //       reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
// // // // // // // // // // // // //     }

// // // // // // // // // // // // //     return SingleChildScrollView(
// // // // // // // // // // // // //       padding: const EdgeInsets.all(20),
// // // // // // // // // // // // //       child: Column(
// // // // // // // // // // // // //         crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // // // // // // // // // //         children: [
// // // // // // // // // // // // //           // ── Turn complete card ───────────────────────────────────────────────
// // // // // // // // // // // // //           Container(
// // // // // // // // // // // // //             padding: const EdgeInsets.all(20),
// // // // // // // // // // // // //             decoration: BoxDecoration(
// // // // // // // // // // // // //               color: theme.colorScheme.surfaceContainerHighest,
// // // // // // // // // // // // //               borderRadius: BorderRadius.circular(20),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //             child: Column(
// // // // // // // // // // // // //               children: [
// // // // // // // // // // // // //                 const Text('🎉', style: TextStyle(fontSize: 44)),
// // // // // // // // // // // // //                 const SizedBox(height: 8),
// // // // // // // // // // // // //                 Text(
// // // // // // // // // // // // //                   _name(state.currentPlayerId),
// // // // // // // // // // // // //                   style: theme.textTheme.titleMedium?.copyWith(
// // // // // // // // // // // // //                     fontWeight: FontWeight.w700,
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //                 Text(
// // // // // // // // // // // // //                   'completed their turn!',
// // // // // // // // // // // // //                   style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // // // // //                     color: theme.colorScheme.onSurfaceVariant,
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //                 if (state.currentCard != null) ...[
// // // // // // // // // // // // //                   const SizedBox(height: 10),
// // // // // // // // // // // // //                   Container(
// // // // // // // // // // // // //                     padding: const EdgeInsets.symmetric(
// // // // // // // // // // // // //                       horizontal: 12,
// // // // // // // // // // // // //                       vertical: 8,
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                     decoration: BoxDecoration(
// // // // // // // // // // // // //                       color: state.currentCard!.type == TodCardType.truth
// // // // // // // // // // // // //                           ? Colors.blue.withOpacity(0.1)
// // // // // // // // // // // // //                           : Colors.orange.withOpacity(0.1),
// // // // // // // // // // // // //                       borderRadius: BorderRadius.circular(8),
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                     child: Text(
// // // // // // // // // // // // //                       state.currentCard!.content,
// // // // // // // // // // // // //                       textAlign: TextAlign.center,
// // // // // // // // // // // // //                       style: theme.textTheme.bodyMedium?.copyWith(
// // // // // // // // // // // // //                         fontWeight: FontWeight.w600,
// // // // // // // // // // // // //                       ),
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                 ],
// // // // // // // // // // // // //                 // Response message
// // // // // // // // // // // // //                 if (state.turnResponse.isNotEmpty) ...[
// // // // // // // // // // // // //                   const SizedBox(height: 12),
// // // // // // // // // // // // //                   Container(
// // // // // // // // // // // // //                     padding: const EdgeInsets.all(12),
// // // // // // // // // // // // //                     decoration: BoxDecoration(
// // // // // // // // // // // // //                       color: theme.colorScheme.primaryContainer.withOpacity(
// // // // // // // // // // // // //                         0.4,
// // // // // // // // // // // // //                       ),
// // // // // // // // // // // // //                       borderRadius: BorderRadius.circular(12),
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                     child: Text(
// // // // // // // // // // // // //                       '"${state.turnResponse}"',
// // // // // // // // // // // // //                       textAlign: TextAlign.center,
// // // // // // // // // // // // //                       style: theme.textTheme.bodyMedium?.copyWith(
// // // // // // // // // // // // //                         fontStyle: FontStyle.italic,
// // // // // // // // // // // // //                       ),
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                 ],
// // // // // // // // // // // // //                 // Proof image (view-once)
// // // // // // // // // // // // //                 if (state.turnProofImageB64.isNotEmpty) ...[
// // // // // // // // // // // // //                   const SizedBox(height: 12),
// // // // // // // // // // // // //                   _ViewOnceImage(b64: state.turnProofImageB64),
// // // // // // // // // // // // //                 ],
// // // // // // // // // // // // //               ],
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //           ).animate().fadeIn(),
// // // // // // // // // // // // //           const SizedBox(height: 16),

// // // // // // // // // // // // //           // ── Reactions ────────────────────────────────────────────────────────
// // // // // // // // // // // // //           if (reactTally.isNotEmpty)
// // // // // // // // // // // // //             Padding(
// // // // // // // // // // // // //               padding: const EdgeInsets.only(bottom: 8),
// // // // // // // // // // // // //               child: Wrap(
// // // // // // // // // // // // //                 spacing: 8,
// // // // // // // // // // // // //                 runSpacing: 6,
// // // // // // // // // // // // //                 children: reactTally.entries
// // // // // // // // // // // // //                     .map(
// // // // // // // // // // // // //                       (e) => Container(
// // // // // // // // // // // // //                         padding: const EdgeInsets.symmetric(
// // // // // // // // // // // // //                           horizontal: 10,
// // // // // // // // // // // // //                           vertical: 5,
// // // // // // // // // // // // //                         ),
// // // // // // // // // // // // //                         decoration: BoxDecoration(
// // // // // // // // // // // // //                           color: theme.colorScheme.surfaceContainerHighest,
// // // // // // // // // // // // //                           borderRadius: BorderRadius.circular(20),
// // // // // // // // // // // // //                         ),
// // // // // // // // // // // // //                         child: Text(
// // // // // // // // // // // // //                           '${e.key} ${e.value}',
// // // // // // // // // // // // //                           style: const TextStyle(fontSize: 14),
// // // // // // // // // // // // //                         ),
// // // // // // // // // // // // //                       ),
// // // // // // // // // // // // //                     )
// // // // // // // // // // // // //                     .toList(),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //           // Emoji picker
// // // // // // // // // // // // //           if (!myReacted && !isMyTurn) ...[
// // // // // // // // // // // // //             Text('React:', style: theme.textTheme.labelSmall),
// // // // // // // // // // // // //             const SizedBox(height: 4),
// // // // // // // // // // // // //             SizedBox(
// // // // // // // // // // // // //               height: 44,
// // // // // // // // // // // // //               child: ListView(
// // // // // // // // // // // // //                 scrollDirection: Axis.horizontal,
// // // // // // // // // // // // //                 children:
// // // // // // // // // // // // //                     [
// // // // // // // // // // // // //                           '😂',
// // // // // // // // // // // // //                           '🔥',
// // // // // // // // // // // // //                           '💀',
// // // // // // // // // // // // //                           '👏',
// // // // // // // // // // // // //                           '🤣',
// // // // // // // // // // // // //                           '😭',
// // // // // // // // // // // // //                           '🫡',
// // // // // // // // // // // // //                           '💯',
// // // // // // // // // // // // //                           '🤯',
// // // // // // // // // // // // //                           '👑',
// // // // // // // // // // // // //                           '😤',
// // // // // // // // // // // // //                           '🥹',
// // // // // // // // // // // // //                         ]
// // // // // // // // // // // // //                         .map(
// // // // // // // // // // // // //                           (s) => Padding(
// // // // // // // // // // // // //                             padding: const EdgeInsets.only(right: 6),
// // // // // // // // // // // // //                             child: InkWell(
// // // // // // // // // // // // //                               borderRadius: BorderRadius.circular(8),
// // // // // // // // // // // // //                               onTap: () => game.reactToResponse(s),
// // // // // // // // // // // // //                               child: Container(
// // // // // // // // // // // // //                                 width: 40,
// // // // // // // // // // // // //                                 height: 40,
// // // // // // // // // // // // //                                 alignment: Alignment.center,
// // // // // // // // // // // // //                                 decoration: BoxDecoration(
// // // // // // // // // // // // //                                   color:
// // // // // // // // // // // // //                                       theme.colorScheme.surfaceContainerHighest,
// // // // // // // // // // // // //                                   borderRadius: BorderRadius.circular(8),
// // // // // // // // // // // // //                                 ),
// // // // // // // // // // // // //                                 child: Text(
// // // // // // // // // // // // //                                   s,
// // // // // // // // // // // // //                                   style: const TextStyle(fontSize: 20),
// // // // // // // // // // // // //                                 ),
// // // // // // // // // // // // //                               ),
// // // // // // // // // // // // //                             ),
// // // // // // // // // // // // //                           ),
// // // // // // // // // // // // //                         )
// // // // // // // // // // // // //                         .toList(),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //             const SizedBox(height: 8),
// // // // // // // // // // // // //           ],

// // // // // // // // // // // // //           // ── Vote for response ────────────────────────────────────────────────
// // // // // // // // // // // // //           if (!isMyTurn && state.turnResponse.isNotEmpty) ...[
// // // // // // // // // // // // //             if (!myVoted)
// // // // // // // // // // // // //               OutlinedButton.icon(
// // // // // // // // // // // // //                 onPressed: game.voteForResponse,
// // // // // // // // // // // // //                 icon: const Icon(Icons.thumb_up_outlined, size: 16),
// // // // // // // // // // // // //                 label: Text(
// // // // // // // // // // // // //                   '👍 Liked this response '
// // // // // // // // // // // // //                   '(${state.currentVotes.length} vote${state.currentVotes.length != 1 ? 's' : ''})',
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               )
// // // // // // // // // // // // //             else
// // // // // // // // // // // // //               Container(
// // // // // // // // // // // // //                 padding: const EdgeInsets.symmetric(
// // // // // // // // // // // // //                   horizontal: 12,
// // // // // // // // // // // // //                   vertical: 8,
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //                 decoration: BoxDecoration(
// // // // // // // // // // // // //                   color: AppColors.successGreen.withOpacity(0.1),
// // // // // // // // // // // // //                   borderRadius: BorderRadius.circular(8),
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //                 child: Text(
// // // // // // // // // // // // //                   '✓ You voted for this response '
// // // // // // // // // // // // //                   '(${state.currentVotes.length} total)',
// // // // // // // // // // // // //                   style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // // // // //                     color: AppColors.successGreen,
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             const SizedBox(height: 12),
// // // // // // // // // // // // //           ],

// // // // // // // // // // // // //           // ── Scores ───────────────────────────────────────────────────────────
// // // // // // // // // // // // //           _ScoreSummary(state: state, displayNames: displayNames),
// // // // // // // // // // // // //           const SizedBox(height: 20),

// // // // // // // // // // // // //           // ── Next turn controls ───────────────────────────────────────────────
// // // // // // // // // // // // //           if (game.isOwner) ...[
// // // // // // // // // // // // //             JButton(
// // // // // // // // // // // // //               label: 'Next Turn →',
// // // // // // // // // // // // //               onPressed: game.ownerAdvanceTurn,
// // // // // // // // // // // // //               icon: Icons.skip_next_rounded,
// // // // // // // // // // // // //             ).animate(delay: 250.ms).fadeIn(),
// // // // // // // // // // // // //             const SizedBox(height: 10),
// // // // // // // // // // // // //             TextButton(
// // // // // // // // // // // // //               onPressed: () => _confirmEndGame(context),
// // // // // // // // // // // // //               child: const Text('End Game'),
// // // // // // // // // // // // //               style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //           ] else
// // // // // // // // // // // // //             Text(
// // // // // // // // // // // // //               'Waiting for host to start next turn…',
// // // // // // // // // // // // //               textAlign: TextAlign.center,
// // // // // // // // // // // // //               style: theme.textTheme.bodyMedium?.copyWith(
// // // // // // // // // // // // //                 color: theme.colorScheme.onSurfaceVariant,
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ).animate().fadeIn(),
// // // // // // // // // // // // //         ],
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _ScoreSummary extends StatelessWidget {
// // // // // // // // // // // // //   const _ScoreSummary({required this.state, required this.displayNames});
// // // // // // // // // // // // //   final TodState state;
// // // // // // // // // // // // //   final Map<String, String> displayNames;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     final top = state.sortedScores.take(3).toList();
// // // // // // // // // // // // //     if (top.isEmpty) return const SizedBox.shrink();

// // // // // // // // // // // // //     return Column(
// // // // // // // // // // // // //       children: top.asMap().entries.map((e) {
// // // // // // // // // // // // //         final rank = e.key;
// // // // // // // // // // // // //         final score = e.value;
// // // // // // // // // // // // //         final medal = ['🥇', '🥈', '🥉'][rank.clamp(0, 2)];
// // // // // // // // // // // // //         final name =
// // // // // // // // // // // // //             displayNames[score.userId] ??
// // // // // // // // // // // // //             'Player ${score.userId.substring(0, 4)}';
// // // // // // // // // // // // //         return Padding(
// // // // // // // // // // // // //           padding: const EdgeInsets.symmetric(vertical: 2),
// // // // // // // // // // // // //           child: Row(
// // // // // // // // // // // // //             children: [
// // // // // // // // // // // // //               Text(medal, style: const TextStyle(fontSize: 16)),
// // // // // // // // // // // // //               const SizedBox(width: 8),
// // // // // // // // // // // // //               Expanded(child: Text(name, style: context.textTheme.bodyMedium)),
// // // // // // // // // // // // //               Text(
// // // // // // // // // // // // //                 '${score.points} pts',
// // // // // // // // // // // // //                 style: context.textTheme.titleSmall?.copyWith(
// // // // // // // // // // // // //                   fontWeight: FontWeight.w700,
// // // // // // // // // // // // //                   color: context.colorScheme.primary,
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             ],
// // // // // // // // // // // // //           ),
// // // // // // // // // // // // //         );
// // // // // // // // // // // // //       }).toList(),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // // // ── View-once proof image ─────────────────────────────────────────────────────

// // // // // // // // // // // // // class _ViewOnceImage extends StatefulWidget {
// // // // // // // // // // // // //   const _ViewOnceImage({required this.b64});
// // // // // // // // // // // // //   final String b64;
// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   State<_ViewOnceImage> createState() => _ViewOnceImageState();
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _ViewOnceImageState extends State<_ViewOnceImage> {
// // // // // // // // // // // // //   bool _revealed = false;
// // // // // // // // // // // // //   bool _viewed = false;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     if (_viewed) {
// // // // // // // // // // // // //       return Container(
// // // // // // // // // // // // //         height: 80,
// // // // // // // // // // // // //         alignment: Alignment.center,
// // // // // // // // // // // // //         decoration: BoxDecoration(
// // // // // // // // // // // // //           color: Colors.grey.shade200,
// // // // // // // // // // // // //           borderRadius: BorderRadius.circular(12),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //         child: Text(
// // // // // // // // // // // // //           '📷 Proof viewed',
// // // // // // // // // // // // //           style: Theme.of(
// // // // // // // // // // // // //             context,
// // // // // // // // // // // // //           ).textTheme.bodySmall?.copyWith(color: Colors.grey),
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //       );
// // // // // // // // // // // // //     }
// // // // // // // // // // // // //     return GestureDetector(
// // // // // // // // // // // // //       onTap: () {
// // // // // // // // // // // // //         if (!_revealed) {
// // // // // // // // // // // // //           setState(() => _revealed = true);
// // // // // // // // // // // // //         } else {
// // // // // // // // // // // // //           setState(() => _viewed = true);
// // // // // // // // // // // // //         }
// // // // // // // // // // // // //       },
// // // // // // // // // // // // //       child: ClipRRect(
// // // // // // // // // // // // //         borderRadius: BorderRadius.circular(12),
// // // // // // // // // // // // //         child: Stack(
// // // // // // // // // // // // //           alignment: Alignment.center,
// // // // // // // // // // // // //           children: [
// // // // // // // // // // // // //             Image.memory(
// // // // // // // // // // // // //               base64Decode(widget.b64),
// // // // // // // // // // // // //               height: 180,
// // // // // // // // // // // // //               width: double.infinity,
// // // // // // // // // // // // //               fit: BoxFit.cover,
// // // // // // // // // // // // //             ),
// // // // // // // // // // // // //             if (!_revealed)
// // // // // // // // // // // // //               Container(
// // // // // // // // // // // // //                 height: 180,
// // // // // // // // // // // // //                 width: double.infinity,
// // // // // // // // // // // // //                 color: Colors.black87,
// // // // // // // // // // // // //                 alignment: Alignment.center,
// // // // // // // // // // // // //                 child: Column(
// // // // // // // // // // // // //                   mainAxisSize: MainAxisSize.min,
// // // // // // // // // // // // //                   children: [
// // // // // // // // // // // // //                     const Icon(
// // // // // // // // // // // // //                       Icons.visibility_outlined,
// // // // // // // // // // // // //                       color: Colors.white,
// // // // // // // // // // // // //                       size: 32,
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                     const SizedBox(height: 6),
// // // // // // // // // // // // //                     Text(
// // // // // // // // // // // // //                       'Tap to reveal proof photo',
// // // // // // // // // // // // //                       style: const TextStyle(color: Colors.white, fontSize: 13),
// // // // // // // // // // // // //                     ),
// // // // // // // // // // // // //                   ],
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //             if (_revealed)
// // // // // // // // // // // // //               Positioned(
// // // // // // // // // // // // //                 bottom: 6,
// // // // // // // // // // // // //                 right: 6,
// // // // // // // // // // // // //                 child: Container(
// // // // // // // // // // // // //                   padding: const EdgeInsets.symmetric(
// // // // // // // // // // // // //                     horizontal: 10,
// // // // // // // // // // // // //                     vertical: 4,
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                   decoration: BoxDecoration(
// // // // // // // // // // // // //                     color: Colors.black54,
// // // // // // // // // // // // //                     borderRadius: BorderRadius.circular(20),
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                   child: const Text(
// // // // // // // // // // // // //                     'Tap to dismiss',
// // // // // // // // // // // // //                     style: TextStyle(color: Colors.white, fontSize: 11),
// // // // // // // // // // // // //                   ),
// // // // // // // // // // // // //                 ),
// // // // // // // // // // // // //               ),
// // // // // // // // // // // // //           ],
// // // // // // // // // // // // //         ),
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // import 'dart:async';
// // // // // // // // // // // // import 'dart:convert';

// // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // // // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // // // // // // // // // // import 'package:provider/provider.dart';
// // // // // // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // // // // // // // // // import '../../../../../core/di/service_locator.dart';
// // // // // // // // // // // // import '../../../../../core/extensions/context_ext.dart';
// // // // // // // // // // // // import '../../../../../core/providers/auth_provider.dart';
// // // // // // // // // // // // import '../../../../../core/router/route_names.dart';
// // // // // // // // // // // // import '../../../../../core/services/realtime_service.dart';
// // // // // // // // // // // // import '../../../../../core/theme/app_colors.dart';
// // // // // // // // // // // // import '../../../../../shared/widgets/feedback/error_view.dart';
// // // // // // // // // // // // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // // // // // // // // // // // // import '../../engine/base_game_engine.dart';
// // // // // // // // // // // // import '../../domain/tod_models.dart';
// // // // // // // // // // // // import '../../tod_game_provider.dart';
// // // // // // // // // // // // import '../../../../rooms/presentation/room_provider.dart';
// // // // // // // // // // // // import '../../../../rooms/presentation/widgets/chat_panel.dart';
// // // // // // // // // // // // import '../../data/tod_repository.dart';
// // // // // // // // // // // // import 'tod_card_screen.dart';
// // // // // // // // // // // // import 'tod_end_screen.dart';
// // // // // // // // // // // // import 'tod_loading_screen.dart';
// // // // // // // // // // // // import 'tod_punishment_screen.dart';
// // // // // // // // // // // // import '../widgets/tod_hud.dart';

// // // // // // // // // // // // /// Entry point for an active Truth or Dare session.
// // // // // // // // // // // // ///
// // // // // // // // // // // // /// Responsibilities:
// // // // // // // // // // // // ///  - Owns and scopes TodGameProvider for this session
// // // // // // // // // // // // ///  - Wires RealtimeService callbacks → TodGameProvider
// // // // // // // // // // // // ///  - Routes between loading / error / active / game-over screens
// // // // // // // // // // // // ///  - Forwards game_state and player_action from the room Broadcast channel
// // // // // // // // // // // // class TodGameScreen extends StatefulWidget {
// // // // // // // // // // // //   const TodGameScreen({
// // // // // // // // // // // //     super.key,
// // // // // // // // // // // //     required this.roomId,
// // // // // // // // // // // //     required this.config,
// // // // // // // // // // // //     required this.playerIds,
// // // // // // // // // // // //     required this.playerDisplayNames,
// // // // // // // // // // // //     required this.packId,
// // // // // // // // // // // //     required this.isOwner,
// // // // // // // // // // // //     this.sessionId,
// // // // // // // // // // // //     this.isModerator = false,
// // // // // // // // // // // //     this.packCoverUrl,
// // // // // // // // // // // //   });

// // // // // // // // // // // //   final String             roomId;
// // // // // // // // // // // //   final GameConfig         config;
// // // // // // // // // // // //   final List<String>       playerIds;
// // // // // // // // // // // //   final Map<String, String> playerDisplayNames;  // userId → displayName
// // // // // // // // // // // //   final String             packId;
// // // // // // // // // // // //   final bool               isOwner;
// // // // // // // // // // // //   final String?            sessionId;
// // // // // // // // // // // //   final bool               isModerator;
// // // // // // // // // // // //   final String?            packCoverUrl;

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   State<TodGameScreen> createState() => _TodGameScreenState();
// // // // // // // // // // // // }

// // // // // // // // // // // // class _TodGameScreenState extends State<TodGameScreen> {
// // // // // // // // // // // //   late final TodGameProvider _provider;

// // // // // // // // // // // //   // Subscriptions to the room Broadcast channel
// // // // // // // // // // // //   // (channel already open by RoomProvider — we just register callbacks)
// // // // // // // // // // // //   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   void initState() {
// // // // // // // // // // // //     super.initState();

// // // // // // // // // // // //     final auth = context.read<AuthProvider>();
// // // // // // // // // // // //     final user = auth.currentUser!;

// // // // // // // // // // // //     _provider = TodGameProvider(
// // // // // // // // // // // //       realtimeService: sl.realtimeService,
// // // // // // // // // // // //       repository:      TodRepository.instance,
// // // // // // // // // // // //       currentUserId:   user.id,
// // // // // // // // // // // //       currentDisplayName: user.displayName ?? user.username ?? 'Player',
// // // // // // // // // // // //       isModerator:     widget.isModerator,
// // // // // // // // // // // //     );

// // // // // // // // // // // //     // ── Wire Broadcast callbacks ────────────────────────────────────────────
// // // // // // // // // // // //     // The room channel is already subscribed by RoomProvider/LobbyScreen.
// // // // // // // // // // // //     // TodGameScreen registers its own game-specific handlers for game_state
// // // // // // // // // // // //     // and player_action by re-subscribing with extended handlers.
// // // // // // // // // // // //     //
// // // // // // // // // // // //     // We do this by using the RealtimeService._bcast pattern:
// // // // // // // // // // // //     // The channel already has onGameState/onPlayerAction wired to no-ops
// // // // // // // // // // // //     // in RoomProvider. We replace them here by storing callbacks and
// // // // // // // // // // // //     // intercepting from the top-level channel via a dedicated subscription.
// // // // // // // // // // // //     _wireRealtimeCallbacks();

// // // // // // // // // // // //     if (widget.isOwner) {
// // // // // // // // // // // //       _provider.initAsOwner(
// // // // // // // // // // // //         roomId:              widget.roomId,
// // // // // // // // // // // //         config:              widget.config,
// // // // // // // // // // // //         playerIds:           widget.playerIds,
// // // // // // // // // // // //         playerDisplayNames:  widget.playerDisplayNames,
// // // // // // // // // // // //         packId:              widget.packId,
// // // // // // // // // // // //         packCoverUrl:        widget.packCoverUrl,
// // // // // // // // // // // //       );
// // // // // // // // // // // //     } else {
// // // // // // // // // // // //       _provider.initAsFollower(
// // // // // // // // // // // //         roomId:    widget.roomId,
// // // // // // // // // // // //         config:    widget.config,
// // // // // // // // // // // //         sessionId: widget.sessionId,
// // // // // // // // // // // //       );
// // // // // // // // // // // //     }
// // // // // // // // // // // //   }

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   void dispose() {
// // // // // // // // // // // //     _statusSub?.cancel();
// // // // // // // // // // // //     _provider.dispose();
// // // // // // // // // // // //     super.dispose();
// // // // // // // // // // // //   }

// // // // // // // // // // // //   /// Wire game-specific callbacks into the existing room channel.
// // // // // // // // // // // //   ///
// // // // // // // // // // // //   /// Strategy: re-subscribe to the room channel with updated handlers that
// // // // // // // // // // // //   /// forward game_state and player_action to this provider.
// // // // // // // // // // // //   /// The channel is already open; we track callbacks via a thin interceptor.
// // // // // // // // // // // //   void _wireRealtimeCallbacks() {
// // // // // // // // // // // //     // Listen to channel status changes for reconnection awareness
// // // // // // // // // // // //     _statusSub = sl.realtimeService
// // // // // // // // // // // //         .statusStream(widget.roomId)
// // // // // // // // // // // //         ?.listen((status) {
// // // // // // // // // // // //       if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // // // // // // // //           !_provider.hasSyncedState) {
// // // // // // // // // // // //         // Channel reconnected — request state sync
// // // // // // // // // // // //         sl.realtimeService.broadcastSyncRequest(
// // // // // // // // // // // //           widget.roomId,
// // // // // // // // // // // //           context.read<AuthProvider>().currentUser!.id,
// // // // // // // // // // // //           0,
// // // // // // // // // // // //         );
// // // // // // // // // // // //       }
// // // // // // // // // // // //     });

// // // // // // // // // // // //     // Re-subscribe with game handlers added.
// // // // // // // // // // // //     // This safely replaces the channel subscription with game callbacks.
// // // // // // // // // // // //     // (No-op handlers in RoomProvider are replaced with active ones here.)
// // // // // // // // // // // //     _resubscribeWithGameHandlers();
// // // // // // // // // // // //   }

// // // // // // // // // // // //   void _resubscribeWithGameHandlers() {
// // // // // // // // // // // //     final userId = context.read<AuthProvider>().currentUser!.id;

// // // // // // // // // // // //     // Unsubscribe existing channel and re-subscribe with game callbacks merged
// // // // // // // // // // // //     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
// // // // // // // // // // // //       sl.realtimeService.subscribe(
// // // // // // // // // // // //         roomId: widget.roomId,
// // // // // // // // // // // //         // ── Game-specific handlers ─────────────────────────────────────────
// // // // // // // // // // // //         onGameState: (p) => _provider.onStateBroadcast(p),
// // // // // // // // // // // //         onPlayerAction: (p) => _provider.onPlayerAction(p),
// // // // // // // // // // // //         onSyncRequest: (p) => _provider.onSyncRequest(p),
// // // // // // // // // // // //         onGameStarted: (_) {},
// // // // // // // // // // // //         onGameEnded: (_) {},
// // // // // // // // // // // //         // ── Room lifecycle (passthrough — RoomProvider is disposed) ─────────
// // // // // // // // // // // //         onRoomEvent: (_) {},
// // // // // // // // // // // //         onChatMessage: (_) {},
// // // // // // // // // // // //         onModeration: (p) => _handleModerationEvent(p),
// // // // // // // // // // // //         onSettingsChange: (_) {},
// // // // // // // // // // // //         // ── Presence ──────────────────────────────────────────────────────
// // // // // // // // // // // //         onPresenceSync: (_) {},
// // // // // // // // // // // //         onPresenceJoin: (_) {},
// // // // // // // // // // // //         onPresenceLeave: (_) {},
// // // // // // // // // // // //         onStatusChange: (status) {
// // // // // // // // // // // //           if (!mounted) return;
// // // // // // // // // // // //           if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // // // // // // // //               !_provider.hasSyncedState) {
// // // // // // // // // // // //             sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
// // // // // // // // // // // //           }
// // // // // // // // // // // //         },
// // // // // // // // // // // //       );
// // // // // // // // // // // //     });
// // // // // // // // // // // //   }

// // // // // // // // // // // //   void _handleModerationEvent(Map<String, dynamic> p) {
// // // // // // // // // // // //     final type     = p['type'] as String?;
// // // // // // // // // // // //     final targetId = p['target_user_id'] as String?;
// // // // // // // // // // // //     final currentId = context.read<AuthProvider>().currentUser?.id;

// // // // // // // // // // // //     // If kicked or banned, navigate back to lobby
// // // // // // // // // // // //     if ((type == 'kick' || type == 'ban') && targetId == currentId) {
// // // // // // // // // // // //       if (mounted) context.go(RouteNames.home);
// // // // // // // // // // // //     }
// // // // // // // // // // // //   }

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // //     return ChangeNotifierProvider.value(
// // // // // // // // // // // //       value: _provider,
// // // // // // // // // // // //       child: Consumer<TodGameProvider>(
// // // // // // // // // // // //         builder: (ctx, game, _) => _build(ctx, game),
// // // // // // // // // // // //       ),
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }

// // // // // // // // // // // //   Widget _build(BuildContext ctx, TodGameProvider game) {
// // // // // // // // // // // //     if (game.loadState == TodLoadState.loading) {
// // // // // // // // // // // //       return const TodLoadingScreen();
// // // // // // // // // // // //     }

// // // // // // // // // // // //     if (game.loadState == TodLoadState.error) {
// // // // // // // // // // // //       return Scaffold(
// // // // // // // // // // // //         appBar: AppBar(
// // // // // // // // // // // //           leading: BackButton(onPressed: () => ctx.go(RouteNames.home)),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         body: ErrorView(
// // // // // // // // // // // //           message: game.error ?? 'Failed to load game',
// // // // // // // // // // // //           onRetry: () => ctx.go(RouteNames.home),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //       );
// // // // // // // // // // // //     }

// // // // // // // // // // // //     if (game.loadState == TodLoadState.gameOver ||
// // // // // // // // // // // //         (game.state?.isOver ?? false)) {
// // // // // // // // // // // //       return TodEndScreen(
// // // // // // // // // // // //         state:          game.state!,
// // // // // // // // // // // //         displayNames:   widget.playerDisplayNames,
// // // // // // // // // // // //         onLeave:        () => ctx.go(RouteNames.home),
// // // // // // // // // // // //       );
// // // // // // // // // // // //     }

// // // // // // // // // // // //     final state = game.state;
// // // // // // // // // // // //     if (state == null) return const TodLoadingScreen();

// // // // // // // // // // // //     return _TodGameScaffold(
// // // // // // // // // // // //       state:        state,
// // // // // // // // // // // //       game:         game,
// // // // // // // // // // // //       displayNames: widget.playerDisplayNames,
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }

// // // // // // // // // // // // }

// // // // // // // // // // // // // ── Scaffold with history support ─────────────────────────────────────────────

// // // // // // // // // // // // class _TodGameScaffold extends StatefulWidget {
// // // // // // // // // // // //   const _TodGameScaffold({
// // // // // // // // // // // //     required this.state,
// // // // // // // // // // // //     required this.game,
// // // // // // // // // // // //     required this.displayNames,
// // // // // // // // // // // //   });
// // // // // // // // // // // //   final TodState            state;
// // // // // // // // // // // //   final TodGameProvider     game;
// // // // // // // // // // // //   final Map<String, String> displayNames;
// // // // // // // // // // // //   @override State<_TodGameScaffold> createState() => _TodGameScaffoldState();
// // // // // // // // // // // // }

// // // // // // // // // // // // class _TodGameScaffoldState extends State<_TodGameScaffold> {
// // // // // // // // // // // //   bool _showHistory = false;
// // // // // // // // // // // //   bool _showChat    = false;
// // // // // // // // // // // //   int  _unreadChat  = 0;

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // //     final state = widget.state;
// // // // // // // // // // // //     final game  = widget.game;

// // // // // // // // // // // //     if (_showHistory) {
// // // // // // // // // // // //       return Scaffold(
// // // // // // // // // // // //         appBar: AppBar(
// // // // // // // // // // // //           leading: BackButton(onPressed: () => setState(() => _showHistory = false)),
// // // // // // // // // // // //           title: Text('History (${state.history.length} rounds)'),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //         body: _HistoryPanel(
// // // // // // // // // // // //           history:      state.history,
// // // // // // // // // // // //           displayNames: widget.displayNames,
// // // // // // // // // // // //         ),
// // // // // // // // // // // //       );
// // // // // // // // // // // //     }

// // // // // // // // // // // //     return Scaffold(
// // // // // // // // // // // //       appBar: AppBar(
// // // // // // // // // // // //         automaticallyImplyLeading: false,
// // // // // // // // // // // //         actions: [
// // // // // // // // // // // //           // Chat button — accessible during game
// // // // // // // // // // // //           Consumer<RoomProvider>(builder: (_, room, __) {
// // // // // // // // // // // //             final unread = room.chatMessages.length - (_unreadChat > 0 ? 0 : 0);
// // // // // // // // // // // //             return Stack(alignment: Alignment.topRight, children: [
// // // // // // // // // // // //               IconButton(
// // // // // // // // // // // //                 icon: const Icon(Icons.chat_bubble_outline_rounded),
// // // // // // // // // // // //                 tooltip: 'Chat',
// // // // // // // // // // // //                 onPressed: () {
// // // // // // // // // // // //                   setState(() => _unreadChat = room.chatMessages.length);
// // // // // // // // // // // //                   showModalBottomSheet(context: context, isScrollControlled: true,
// // // // // // // // // // // //                     backgroundColor: Colors.transparent,
// // // // // // // // // // // //                     builder: (_) => ChangeNotifierProvider.value(
// // // // // // // // // // // //                         value: room, child: SizedBox(
// // // // // // // // // // // //                           height: MediaQuery.sizeOf(context).height * 0.65,
// // // // // // // // // // // //                           child: ChatPanel(room: room))));
// // // // // // // // // // // //                 }),
// // // // // // // // // // // //               if (room.chatMessages.length > _unreadChat && _unreadChat < room.chatMessages.length)
// // // // // // // // // // // //                 Positioned(top: 8, right: 8, child: Container(
// // // // // // // // // // // //                   width: 8, height: 8,
// // // // // // // // // // // //                   decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
// // // // // // // // // // // //             ]);
// // // // // // // // // // // //           }),
// // // // // // // // // // // //           if (state.history.isNotEmpty)
// // // // // // // // // // // //             IconButton(
// // // // // // // // // // // //               icon: const Icon(Icons.history_rounded),
// // // // // // // // // // // //               tooltip: 'History',
// // // // // // // // // // // //               onPressed: () => setState(() => _showHistory = true),
// // // // // // // // // // // //             ),
// // // // // // // // // // // //         ],
// // // // // // // // // // // //       ),
// // // // // // // // // // // //       body: SafeArea(
// // // // // // // // // // // //         child: Column(
// // // // // // // // // // // //           children: [
// // // // // // // // // // // //             TodHud(
// // // // // // // // // // // //               state: state,
// // // // // // // // // // // //               game:  game,
// // // // // // // // // // // //               displayNames: widget.displayNames,
// // // // // // // // // // // //             ),
// // // // // // // // // // // //             Expanded(
// // // // // // // // // // // //               child: AnimatedSwitcher(
// // // // // // // // // // // //                 duration: const Duration(milliseconds: 300),
// // // // // // // // // // // //                 transitionBuilder: (child, anim) => FadeTransition(
// // // // // // // // // // // //                   opacity: anim,
// // // // // // // // // // // //                   child: SlideTransition(
// // // // // // // // // // // //                     position: Tween<Offset>(
// // // // // // // // // // // //                       begin: const Offset(0, 0.05),
// // // // // // // // // // // //                       end:   Offset.zero,
// // // // // // // // // // // //                     ).animate(CurvedAnimation(
// // // // // // // // // // // //                         parent: anim, curve: Curves.easeOutCubic)),
// // // // // // // // // // // //                     child: child,
// // // // // // // // // // // //                   ),
// // // // // // // // // // // //                 ),
// // // // // // // // // // // //                 child: KeyedSubtree(
// // // // // // // // // // // //                   key: ValueKey('${state.phase}-${state.currentPlayerId}'),
// // // // // // // // // // // //                   child: _phaseWidget(context, game, widget.displayNames, state),
// // // // // // // // // // // //                 ),
// // // // // // // // // // // //               ),
// // // // // // // // // // // //             ),
// // // // // // // // // // // //           ],
// // // // // // // // // // // //         ),
// // // // // // // // // // // //       ),
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }

// // // // // // // // // // // //   Widget _phaseWidget(BuildContext ctx, TodGameProvider game, Map<String, String> displayNames, TodState state) {
// // // // // // // // // // // //     return switch (state.phase) {
// // // // // // // // // // // //       TodTurnPhase.punishmentVoting => TodPunishmentScreen(
// // // // // // // // // // // //           state: state, game: game,
// // // // // // // // // // // //           displayNames: widget.displayNames),
// // // // // // // // // // // //       _ => TodCardScreen(
// // // // // // // // // // // //           state: state, game: game,
// // // // // // // // // // // //           displayNames: widget.displayNames),
// // // // // // // // // // // //     };
// // // // // // // // // // // //   }
// // // // // // // // // // // // }

// // // // // // // // // // // // // ── History panel ─────────────────────────────────────────────────────────────

// // // // // // // // // // // // class _HistoryPanel extends StatelessWidget {
// // // // // // // // // // // //   const _HistoryPanel({required this.history, required this.displayNames});
// // // // // // // // // // // //   final List<TodRoundRecord> history;
// // // // // // // // // // // //   final Map<String, String>  displayNames;

// // // // // // // // // // // //   String _name(String id) => displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // //     final theme = context.theme;
// // // // // // // // // // // //     if (history.isEmpty) {
// // // // // // // // // // // //       return const Center(child: Text('No rounds completed yet.'));
// // // // // // // // // // // //     }
// // // // // // // // // // // //     return ListView.builder(
// // // // // // // // // // // //       padding: const EdgeInsets.all(12),
// // // // // // // // // // // //       itemCount: history.length,
// // // // // // // // // // // //       itemBuilder: (_, i) {
// // // // // // // // // // // //         final round = history[history.length - 1 - i]; // newest first
// // // // // // // // // // // //         final reactTally = <String, int>{};
// // // // // // // // // // // //         for (final r in round.reactions) {
// // // // // // // // // // // //           reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
// // // // // // // // // // // //         }
// // // // // // // // // // // //         return Card(
// // // // // // // // // // // //           margin: const EdgeInsets.only(bottom: 10),
// // // // // // // // // // // //           child: ExpansionTile(
// // // // // // // // // // // //             leading: CircleAvatar(
// // // // // // // // // // // //               backgroundColor: theme.colorScheme.primaryContainer,
// // // // // // // // // // // //               child: Text('${round.roundNumber}',
// // // // // // // // // // // //                   style: theme.textTheme.labelLarge),
// // // // // // // // // // // //             ),
// // // // // // // // // // // //             title: Text(_name(round.playerId),
// // // // // // // // // // // //                 style: theme.textTheme.bodyMedium?.copyWith(
// // // // // // // // // // // //                     fontWeight: FontWeight.w700)),
// // // // // // // // // // // //             subtitle: Text(
// // // // // // // // // // // //               round.card != null
// // // // // // // // // // // //                   ? '${round.card!.type == TodCardType.truth ? "Truth" : "Dare"}: ${round.card!.content}'
// // // // // // // // // // // //                   : 'Skipped',
// // // // // // // // // // // //               maxLines: 1, overflow: TextOverflow.ellipsis,
// // // // // // // // // // // //               style: theme.textTheme.bodySmall,
// // // // // // // // // // // //             ),
// // // // // // // // // // // //             children: [
// // // // // // // // // // // //               Padding(
// // // // // // // // // // // //                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
// // // // // // // // // // // //                 child: Column(
// // // // // // // // // // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // // // // //                     children: [
// // // // // // // // // // // //                   // Card content
// // // // // // // // // // // //                   if (round.card != null)
// // // // // // // // // // // //                     Container(
// // // // // // // // // // // //                       width: double.infinity,
// // // // // // // // // // // //                       padding: const EdgeInsets.all(10),
// // // // // // // // // // // //                       decoration: BoxDecoration(
// // // // // // // // // // // //                         color: round.card!.type == TodCardType.truth
// // // // // // // // // // // //                             ? Colors.blue.withOpacity(0.08)
// // // // // // // // // // // //                             : Colors.orange.withOpacity(0.08),
// // // // // // // // // // // //                         borderRadius: BorderRadius.circular(8),
// // // // // // // // // // // //                       ),
// // // // // // // // // // // //                       child: Text(round.card!.content,
// // // // // // // // // // // //                           style: theme.textTheme.bodyMedium),
// // // // // // // // // // // //                     ),
// // // // // // // // // // // //                   // Response
// // // // // // // // // // // //                   if (round.response.isNotEmpty) ...[
// // // // // // // // // // // //                     const SizedBox(height: 8),
// // // // // // // // // // // //                     Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
// // // // // // // // // // // //                       const Text('💬 ', style: TextStyle(fontSize: 14)),
// // // // // // // // // // // //                       Expanded(child: Text('"${round.response}"',
// // // // // // // // // // // //                           style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // // // //                               fontStyle: FontStyle.italic))),
// // // // // // // // // // // //                     ]),
// // // // // // // // // // // //                   ],
// // // // // // // // // // // //                   // Votes
// // // // // // // // // // // //                   if (round.voteCount > 0) ...[
// // // // // // // // // // // //                     const SizedBox(height: 6),
// // // // // // // // // // // //                     Text('👍 ${round.voteCount} vote${round.voteCount != 1 ? "s" : ""}',
// // // // // // // // // // // //                         style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // // // //                             color: theme.colorScheme.primary,
// // // // // // // // // // // //                             fontWeight: FontWeight.w600)),
// // // // // // // // // // // //                   ],
// // // // // // // // // // // //                   // Proof image
// // // // // // // // // // // //                   if (round.proofImageB64.isNotEmpty) ...[
// // // // // // // // // // // //                     const SizedBox(height: 8),
// // // // // // // // // // // //                     _HistoryViewOnceImage(b64: round.proofImageB64),
// // // // // // // // // // // //                   ],
// // // // // // // // // // // //                   // Reactions
// // // // // // // // // // // //                   if (reactTally.isNotEmpty) ...[
// // // // // // // // // // // //                     const SizedBox(height: 8),
// // // // // // // // // // // //                     Wrap(spacing: 6, runSpacing: 4,
// // // // // // // // // // // //                         children: reactTally.entries.map((e) => Container(
// // // // // // // // // // // //                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // // // // // // // // // // //                           decoration: BoxDecoration(
// // // // // // // // // // // //                             color: theme.colorScheme.surfaceContainerHighest,
// // // // // // // // // // // //                             borderRadius: BorderRadius.circular(16),
// // // // // // // // // // // //                           ),
// // // // // // // // // // // //                           child: Text('${e.key} ${e.value}',
// // // // // // // // // // // //                               style: const TextStyle(fontSize: 13)),
// // // // // // // // // // // //                         )).toList()),
// // // // // // // // // // // //                   ],
// // // // // // // // // // // //                 ]),
// // // // // // // // // // // //               ),
// // // // // // // // // // // //             ],
// // // // // // // // // // // //           ),
// // // // // // // // // // // //         );
// // // // // // // // // // // //       },
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }
// // // // // // // // // // // // }

// // // // // // // // // // // // // View-once image for history (separate state per instance)
// // // // // // // // // // // // class _HistoryViewOnceImage extends StatefulWidget {
// // // // // // // // // // // //   const _HistoryViewOnceImage({required this.b64});
// // // // // // // // // // // //   final String b64;
// // // // // // // // // // // //   @override State<_HistoryViewOnceImage> createState() => _HistoryViewOnceImageState();
// // // // // // // // // // // // }
// // // // // // // // // // // // class _HistoryViewOnceImageState extends State<_HistoryViewOnceImage> {
// // // // // // // // // // // //   bool _revealed = false;
// // // // // // // // // // // //   bool _viewed   = false;
// // // // // // // // // // // //   @override
// // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // //     if (_viewed) {
// // // // // // // // // // // //       return Container(
// // // // // // // // // // // //         height: 48,
// // // // // // // // // // // //         alignment: Alignment.centerLeft,
// // // // // // // // // // // //         child: Text('📷 Proof viewed',
// // // // // // // // // // // //             style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
// // // // // // // // // // // //       );
// // // // // // // // // // // //     }
// // // // // // // // // // // //     if (!_revealed) {
// // // // // // // // // // // //       return GestureDetector(
// // // // // // // // // // // //         onTap: () => setState(() => _revealed = true),
// // // // // // // // // // // //         child: Container(
// // // // // // // // // // // //           height: 60,
// // // // // // // // // // // //           decoration: BoxDecoration(
// // // // // // // // // // // //             color: Colors.grey.shade200,
// // // // // // // // // // // //             borderRadius: BorderRadius.circular(8),
// // // // // // // // // // // //           ),
// // // // // // // // // // // //           alignment: Alignment.center,
// // // // // // // // // // // //           child: const Row(mainAxisSize: MainAxisSize.min, children: [
// // // // // // // // // // // //             Icon(Icons.lock_outline, size: 16),
// // // // // // // // // // // //             SizedBox(width: 6),
// // // // // // // // // // // //             Text('Tap to view proof photo (once)',
// // // // // // // // // // // //                 style: TextStyle(fontSize: 12)),
// // // // // // // // // // // //           ]),
// // // // // // // // // // // //         ),
// // // // // // // // // // // //       );
// // // // // // // // // // // //     }
// // // // // // // // // // // //     return GestureDetector(
// // // // // // // // // // // //       onTap: () => setState(() => _viewed = true),
// // // // // // // // // // // //       child: ClipRRect(
// // // // // // // // // // // //         borderRadius: BorderRadius.circular(8),
// // // // // // // // // // // //         child: Stack(children: [
// // // // // // // // // // // //           Image.memory(base64Decode(widget.b64),
// // // // // // // // // // // //               height: 160, width: double.infinity, fit: BoxFit.cover),
// // // // // // // // // // // //           Positioned(bottom: 6, right: 6,
// // // // // // // // // // // //             child: Container(
// // // // // // // // // // // //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // // // // // // // // // // //               decoration: BoxDecoration(color: Colors.black54,
// // // // // // // // // // // //                   borderRadius: BorderRadius.circular(12)),
// // // // // // // // // // // //               child: const Text('Tap to dismiss',
// // // // // // // // // // // //                   style: TextStyle(color: Colors.white, fontSize: 11)),
// // // // // // // // // // // //             )),
// // // // // // // // // // // //         ]),
// // // // // // // // // // // //       ),
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }
// // // // // // // // // // // // }

// // // // // // // // // // // import 'dart:async';
// // // // // // // // // // // import 'dart:convert';

// // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // // // // // // // // // import 'package:provider/provider.dart';
// // // // // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // // // // // // // // import '../../../../../core/di/service_locator.dart';
// // // // // // // // // // // import '../../../../../core/extensions/context_ext.dart';
// // // // // // // // // // // import '../../../../../core/providers/auth_provider.dart';
// // // // // // // // // // // import '../../../../../core/router/route_names.dart';
// // // // // // // // // // // import '../../../../../core/services/realtime_service.dart';
// // // // // // // // // // // import '../../../../../core/theme/app_colors.dart';
// // // // // // // // // // // import '../../../../../shared/widgets/feedback/error_view.dart';
// // // // // // // // // // // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // // // // // // // // // // // import '../../engine/base_game_engine.dart';
// // // // // // // // // // // import '../../domain/tod_models.dart';
// // // // // // // // // // // import '../../tod_game_provider.dart';
// // // // // // // // // // // import '../../../../rooms/presentation/room_provider.dart';
// // // // // // // // // // // import '../../../../rooms/presentation/widgets/chat_panel.dart';
// // // // // // // // // // // import '../../data/tod_repository.dart';
// // // // // // // // // // // import 'tod_card_screen.dart';
// // // // // // // // // // // import 'tod_end_screen.dart';
// // // // // // // // // // // import 'tod_loading_screen.dart';
// // // // // // // // // // // import 'tod_punishment_screen.dart';
// // // // // // // // // // // import '../widgets/tod_hud.dart';

// // // // // // // // // // // /// Entry point for an active Truth or Dare session.
// // // // // // // // // // // ///
// // // // // // // // // // // /// Responsibilities:
// // // // // // // // // // // ///  - Owns and scopes TodGameProvider for this session
// // // // // // // // // // // ///  - Wires RealtimeService callbacks → TodGameProvider
// // // // // // // // // // // ///  - Routes between loading / error / active / game-over screens
// // // // // // // // // // // ///  - Forwards game_state and player_action from the room Broadcast channel
// // // // // // // // // // // class TodGameScreen extends StatefulWidget {
// // // // // // // // // // //   const TodGameScreen({
// // // // // // // // // // //     super.key,
// // // // // // // // // // //     required this.roomId,
// // // // // // // // // // //     required this.config,
// // // // // // // // // // //     required this.playerIds,
// // // // // // // // // // //     required this.playerDisplayNames,
// // // // // // // // // // //     required this.packId,
// // // // // // // // // // //     required this.isOwner,
// // // // // // // // // // //     this.sessionId,
// // // // // // // // // // //     this.isModerator = false,
// // // // // // // // // // //     this.packCoverUrl,
// // // // // // // // // // //   });

// // // // // // // // // // //   final String roomId;
// // // // // // // // // // //   final GameConfig config;
// // // // // // // // // // //   final List<String> playerIds;
// // // // // // // // // // //   final Map<String, String> playerDisplayNames; // userId → displayName
// // // // // // // // // // //   final String packId;
// // // // // // // // // // //   final bool isOwner;
// // // // // // // // // // //   final String? sessionId;
// // // // // // // // // // //   final bool isModerator;
// // // // // // // // // // //   final String? packCoverUrl;

// // // // // // // // // // //   @override
// // // // // // // // // // //   State<TodGameScreen> createState() => _TodGameScreenState();
// // // // // // // // // // // }

// // // // // // // // // // // class _TodGameScreenState extends State<TodGameScreen> {
// // // // // // // // // // //   late final TodGameProvider _provider;

// // // // // // // // // // //   // Subscriptions to the room Broadcast channel
// // // // // // // // // // //   // (channel already open by RoomProvider — we just register callbacks)
// // // // // // // // // // //   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

// // // // // // // // // // //   @override
// // // // // // // // // // //   void initState() {
// // // // // // // // // // //     super.initState();

// // // // // // // // // // //     final auth = context.read<AuthProvider>();
// // // // // // // // // // //     final user = auth.currentUser!;

// // // // // // // // // // //     _provider = TodGameProvider(
// // // // // // // // // // //       realtimeService: sl.realtimeService,
// // // // // // // // // // //       repository: TodRepository.instance,
// // // // // // // // // // //       currentUserId: user.id,
// // // // // // // // // // //       currentDisplayName: user.displayName ?? user.username ?? 'Player',
// // // // // // // // // // //       isModerator: widget.isModerator,
// // // // // // // // // // //     );

// // // // // // // // // // //     // ── Wire Broadcast callbacks ────────────────────────────────────────────
// // // // // // // // // // //     // The room channel is already subscribed by RoomProvider/LobbyScreen.
// // // // // // // // // // //     // TodGameScreen registers its own game-specific handlers for game_state
// // // // // // // // // // //     // and player_action by re-subscribing with extended handlers.
// // // // // // // // // // //     //
// // // // // // // // // // //     // We do this by using the RealtimeService._bcast pattern:
// // // // // // // // // // //     // The channel already has onGameState/onPlayerAction wired to no-ops
// // // // // // // // // // //     // in RoomProvider. We replace them here by storing callbacks and
// // // // // // // // // // //     // intercepting from the top-level channel via a dedicated subscription.
// // // // // // // // // // //     _wireRealtimeCallbacks();

// // // // // // // // // // //     if (widget.isOwner) {
// // // // // // // // // // //       _provider.initAsOwner(
// // // // // // // // // // //         roomId: widget.roomId,
// // // // // // // // // // //         config: widget.config,
// // // // // // // // // // //         playerIds: widget.playerIds,
// // // // // // // // // // //         playerDisplayNames: widget.playerDisplayNames,
// // // // // // // // // // //         packId: widget.packId,
// // // // // // // // // // //         packCoverUrl: widget.packCoverUrl,
// // // // // // // // // // //       );
// // // // // // // // // // //     } else {
// // // // // // // // // // //       _provider.initAsFollower(
// // // // // // // // // // //         roomId: widget.roomId,
// // // // // // // // // // //         config: widget.config,
// // // // // // // // // // //         sessionId: widget.sessionId,
// // // // // // // // // // //         packCoverUrl: widget.packCoverUrl,
// // // // // // // // // // //       );
// // // // // // // // // // //     }
// // // // // // // // // // //   }

// // // // // // // // // // //   @override
// // // // // // // // // // //   void dispose() {
// // // // // // // // // // //     _statusSub?.cancel();
// // // // // // // // // // //     _provider.dispose();
// // // // // // // // // // //     super.dispose();
// // // // // // // // // // //   }

// // // // // // // // // // //   /// Wire game-specific callbacks into the existing room channel.
// // // // // // // // // // //   ///
// // // // // // // // // // //   /// Strategy: re-subscribe to the room channel with updated handlers that
// // // // // // // // // // //   /// forward game_state and player_action to this provider.
// // // // // // // // // // //   /// The channel is already open; we track callbacks via a thin interceptor.
// // // // // // // // // // //   void _wireRealtimeCallbacks() {
// // // // // // // // // // //     // Listen to channel status changes for reconnection awareness
// // // // // // // // // // //     _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
// // // // // // // // // // //       status,
// // // // // // // // // // //     ) {
// // // // // // // // // // //       if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // // // // // // //           !_provider.hasSyncedState) {
// // // // // // // // // // //         // Channel reconnected — request state sync
// // // // // // // // // // //         sl.realtimeService.broadcastSyncRequest(
// // // // // // // // // // //           widget.roomId,
// // // // // // // // // // //           context.read<AuthProvider>().currentUser!.id,
// // // // // // // // // // //           0,
// // // // // // // // // // //         );
// // // // // // // // // // //       }
// // // // // // // // // // //     });

// // // // // // // // // // //     // Re-subscribe with game handlers added.
// // // // // // // // // // //     // This safely replaces the channel subscription with game callbacks.
// // // // // // // // // // //     // (No-op handlers in RoomProvider are replaced with active ones here.)
// // // // // // // // // // //     _resubscribeWithGameHandlers();
// // // // // // // // // // //   }

// // // // // // // // // // //   void _resubscribeWithGameHandlers() {
// // // // // // // // // // //     final userId = context.read<AuthProvider>().currentUser!.id;

// // // // // // // // // // //     // Unsubscribe existing channel and re-subscribe with game callbacks merged
// // // // // // // // // // //     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
// // // // // // // // // // //       sl.realtimeService.subscribe(
// // // // // // // // // // //         roomId: widget.roomId,
// // // // // // // // // // //         // ── Game-specific handlers ─────────────────────────────────────────
// // // // // // // // // // //         onGameState: (p) => _provider.onStateBroadcast(p),
// // // // // // // // // // //         onPlayerAction: (p) => _provider.onPlayerAction(p),
// // // // // // // // // // //         onSyncRequest: (p) => _provider.onSyncRequest(p),
// // // // // // // // // // //         onGameStarted: (_) {},
// // // // // // // // // // //         onGameEnded: (_) {},
// // // // // // // // // // //         // ── Room lifecycle (passthrough — RoomProvider is disposed) ─────────
// // // // // // // // // // //         onRoomEvent: (_) {},
// // // // // // // // // // //         onChatMessage: (_) {},
// // // // // // // // // // //         onModeration: (p) => _handleModerationEvent(p),
// // // // // // // // // // //         onSettingsChange: (_) {},
// // // // // // // // // // //         // ── Presence ──────────────────────────────────────────────────────
// // // // // // // // // // //         onPresenceSync: (_) {},
// // // // // // // // // // //         onPresenceJoin: (_) {},
// // // // // // // // // // //         onPresenceLeave: (_) {},
// // // // // // // // // // //         onStatusChange: (status) {
// // // // // // // // // // //           if (!mounted) return;
// // // // // // // // // // //           if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // // // // // // //               !_provider.hasSyncedState) {
// // // // // // // // // // //             sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
// // // // // // // // // // //           }
// // // // // // // // // // //         },
// // // // // // // // // // //       );
// // // // // // // // // // //     });
// // // // // // // // // // //   }

// // // // // // // // // // //   void _handleModerationEvent(Map<String, dynamic> p) {
// // // // // // // // // // //     final type = p['type'] as String?;
// // // // // // // // // // //     final targetId = p['target_user_id'] as String?;
// // // // // // // // // // //     final currentId = context.read<AuthProvider>().currentUser?.id;

// // // // // // // // // // //     // If kicked or banned, navigate back to lobby
// // // // // // // // // // //     if ((type == 'kick' || type == 'ban') && targetId == currentId) {
// // // // // // // // // // //       if (mounted) context.go(RouteNames.home);
// // // // // // // // // // //     }
// // // // // // // // // // //   }

// // // // // // // // // // //   @override
// // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // //     return ChangeNotifierProvider.value(
// // // // // // // // // // //       value: _provider,
// // // // // // // // // // //       child: Consumer<TodGameProvider>(
// // // // // // // // // // //         builder: (ctx, game, _) => _build(ctx, game),
// // // // // // // // // // //       ),
// // // // // // // // // // //     );
// // // // // // // // // // //   }

// // // // // // // // // // //   Widget _build(BuildContext ctx, TodGameProvider game) {
// // // // // // // // // // //     if (game.loadState == TodLoadState.loading) {
// // // // // // // // // // //       return const TodLoadingScreen();
// // // // // // // // // // //     }

// // // // // // // // // // //     if (game.loadState == TodLoadState.error) {
// // // // // // // // // // //       return Scaffold(
// // // // // // // // // // //         appBar: AppBar(
// // // // // // // // // // //           leading: BackButton(onPressed: () => ctx.go(RouteNames.home)),
// // // // // // // // // // //         ),
// // // // // // // // // // //         body: ErrorView(
// // // // // // // // // // //           message: game.error ?? 'Failed to load game',
// // // // // // // // // // //           onRetry: () => ctx.go(RouteNames.home),
// // // // // // // // // // //         ),
// // // // // // // // // // //       );
// // // // // // // // // // //     }

// // // // // // // // // // //     if (game.loadState == TodLoadState.gameOver ||
// // // // // // // // // // //         (game.state?.isOver ?? false)) {
// // // // // // // // // // //       return TodEndScreen(
// // // // // // // // // // //         state: game.state!,
// // // // // // // // // // //         displayNames: widget.playerDisplayNames,
// // // // // // // // // // //         onLeave: () => ctx.go(RouteNames.home),
// // // // // // // // // // //       );
// // // // // // // // // // //     }

// // // // // // // // // // //     final state = game.state;
// // // // // // // // // // //     if (state == null) return const TodLoadingScreen();

// // // // // // // // // // //     return _TodGameScaffold(
// // // // // // // // // // //       state: state,
// // // // // // // // // // //       game: game,
// // // // // // // // // // //       displayNames: widget.playerDisplayNames,
// // // // // // // // // // //     );
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // // // ── Scaffold with history support ─────────────────────────────────────────────

// // // // // // // // // // // class _TodGameScaffold extends StatefulWidget {
// // // // // // // // // // //   const _TodGameScaffold({
// // // // // // // // // // //     required this.state,
// // // // // // // // // // //     required this.game,
// // // // // // // // // // //     required this.displayNames,
// // // // // // // // // // //   });
// // // // // // // // // // //   final TodState state;
// // // // // // // // // // //   final TodGameProvider game;
// // // // // // // // // // //   final Map<String, String> displayNames;
// // // // // // // // // // //   @override
// // // // // // // // // // //   State<_TodGameScaffold> createState() => _TodGameScaffoldState();
// // // // // // // // // // // }

// // // // // // // // // // // class _TodGameScaffoldState extends State<_TodGameScaffold> {
// // // // // // // // // // //   bool _showHistory = false;
// // // // // // // // // // //   bool _showChat = false;
// // // // // // // // // // //   int _unreadChat = 0;

// // // // // // // // // // //   @override
// // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // //     final state = widget.state;
// // // // // // // // // // //     final game = widget.game;

// // // // // // // // // // //     if (_showHistory) {
// // // // // // // // // // //       return Scaffold(
// // // // // // // // // // //         appBar: AppBar(
// // // // // // // // // // //           leading: BackButton(
// // // // // // // // // // //             onPressed: () => setState(() => _showHistory = false),
// // // // // // // // // // //           ),
// // // // // // // // // // //           title: Text('History (${state.history.length} rounds)'),
// // // // // // // // // // //         ),
// // // // // // // // // // //         body: _HistoryPanel(
// // // // // // // // // // //           history: state.history,
// // // // // // // // // // //           displayNames: widget.displayNames,
// // // // // // // // // // //         ),
// // // // // // // // // // //       );
// // // // // // // // // // //     }

// // // // // // // // // // //     return Scaffold(
// // // // // // // // // // //       appBar: AppBar(
// // // // // // // // // // //         automaticallyImplyLeading: false,
// // // // // // // // // // //         actions: [
// // // // // // // // // // //           // Chat button — accessible during game
// // // // // // // // // // //           Consumer<RoomProvider>(
// // // // // // // // // // //             builder: (_, room, __) {
// // // // // // // // // // //               final unread =
// // // // // // // // // // //                   room.chatMessages.length - (_unreadChat > 0 ? 0 : 0);
// // // // // // // // // // //               return Stack(
// // // // // // // // // // //                 alignment: Alignment.topRight,
// // // // // // // // // // //                 children: [
// // // // // // // // // // //                   IconButton(
// // // // // // // // // // //                     icon: const Icon(Icons.chat_bubble_outline_rounded),
// // // // // // // // // // //                     tooltip: 'Chat',
// // // // // // // // // // //                     onPressed: () {
// // // // // // // // // // //                       setState(() => _unreadChat = room.chatMessages.length);
// // // // // // // // // // //                       showModalBottomSheet(
// // // // // // // // // // //                         context: context,
// // // // // // // // // // //                         isScrollControlled: true,
// // // // // // // // // // //                         backgroundColor: Colors.transparent,
// // // // // // // // // // //                         builder: (_) => ChangeNotifierProvider.value(
// // // // // // // // // // //                           value: room,
// // // // // // // // // // //                           child: SizedBox(
// // // // // // // // // // //                             height: MediaQuery.sizeOf(context).height * 0.65,
// // // // // // // // // // //                             child: ChatPanel(room: room),
// // // // // // // // // // //                           ),
// // // // // // // // // // //                         ),
// // // // // // // // // // //                       );
// // // // // // // // // // //                     },
// // // // // // // // // // //                   ),
// // // // // // // // // // //                   if (room.chatMessages.length > _unreadChat &&
// // // // // // // // // // //                       _unreadChat < room.chatMessages.length)
// // // // // // // // // // //                     Positioned(
// // // // // // // // // // //                       top: 8,
// // // // // // // // // // //                       right: 8,
// // // // // // // // // // //                       child: Container(
// // // // // // // // // // //                         width: 8,
// // // // // // // // // // //                         height: 8,
// // // // // // // // // // //                         decoration: const BoxDecoration(
// // // // // // // // // // //                           color: Colors.red,
// // // // // // // // // // //                           shape: BoxShape.circle,
// // // // // // // // // // //                         ),
// // // // // // // // // // //                       ),
// // // // // // // // // // //                     ),
// // // // // // // // // // //                 ],
// // // // // // // // // // //               );
// // // // // // // // // // //             },
// // // // // // // // // // //           ),
// // // // // // // // // // //           if (state.history.isNotEmpty)
// // // // // // // // // // //             IconButton(
// // // // // // // // // // //               icon: const Icon(Icons.history_rounded),
// // // // // // // // // // //               tooltip: 'History',
// // // // // // // // // // //               onPressed: () => setState(() => _showHistory = true),
// // // // // // // // // // //             ),
// // // // // // // // // // //         ],
// // // // // // // // // // //       ),
// // // // // // // // // // //       body: SafeArea(
// // // // // // // // // // //         child: Column(
// // // // // // // // // // //           children: [
// // // // // // // // // // //             TodHud(state: state, game: game, displayNames: widget.displayNames),
// // // // // // // // // // //             Expanded(
// // // // // // // // // // //               child: AnimatedSwitcher(
// // // // // // // // // // //                 duration: const Duration(milliseconds: 300),
// // // // // // // // // // //                 transitionBuilder: (child, anim) => FadeTransition(
// // // // // // // // // // //                   opacity: anim,
// // // // // // // // // // //                   child: SlideTransition(
// // // // // // // // // // //                     position:
// // // // // // // // // // //                         Tween<Offset>(
// // // // // // // // // // //                           begin: const Offset(0, 0.05),
// // // // // // // // // // //                           end: Offset.zero,
// // // // // // // // // // //                         ).animate(
// // // // // // // // // // //                           CurvedAnimation(
// // // // // // // // // // //                             parent: anim,
// // // // // // // // // // //                             curve: Curves.easeOutCubic,
// // // // // // // // // // //                           ),
// // // // // // // // // // //                         ),
// // // // // // // // // // //                     child: child,
// // // // // // // // // // //                   ),
// // // // // // // // // // //                 ),
// // // // // // // // // // //                 child: KeyedSubtree(
// // // // // // // // // // //                   key: ValueKey('${state.phase}-${state.currentPlayerId}'),
// // // // // // // // // // //                   child: _phaseWidget(
// // // // // // // // // // //                     context,
// // // // // // // // // // //                     game,
// // // // // // // // // // //                     widget.displayNames,
// // // // // // // // // // //                     state,
// // // // // // // // // // //                   ),
// // // // // // // // // // //                 ),
// // // // // // // // // // //               ),
// // // // // // // // // // //             ),
// // // // // // // // // // //           ],
// // // // // // // // // // //         ),
// // // // // // // // // // //       ),
// // // // // // // // // // //     );
// // // // // // // // // // //   }

// // // // // // // // // // //   Widget _phaseWidget(
// // // // // // // // // // //     BuildContext ctx,
// // // // // // // // // // //     TodGameProvider game,
// // // // // // // // // // //     Map<String, String> displayNames,
// // // // // // // // // // //     TodState state,
// // // // // // // // // // //   ) {
// // // // // // // // // // //     return switch (state.phase) {
// // // // // // // // // // //       TodTurnPhase.punishmentVoting => TodPunishmentScreen(
// // // // // // // // // // //         state: state,
// // // // // // // // // // //         game: game,
// // // // // // // // // // //         displayNames: widget.displayNames,
// // // // // // // // // // //       ),
// // // // // // // // // // //       _ => TodCardScreen(
// // // // // // // // // // //         state: state,
// // // // // // // // // // //         game: game,
// // // // // // // // // // //         displayNames: widget.displayNames,
// // // // // // // // // // //       ),
// // // // // // // // // // //     };
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // // // ── History panel ─────────────────────────────────────────────────────────────

// // // // // // // // // // // class _HistoryPanel extends StatelessWidget {
// // // // // // // // // // //   const _HistoryPanel({required this.history, required this.displayNames});
// // // // // // // // // // //   final List<TodRoundRecord> history;
// // // // // // // // // // //   final Map<String, String> displayNames;

// // // // // // // // // // //   String _name(String id) =>
// // // // // // // // // // //       displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

// // // // // // // // // // //   @override
// // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // //     final theme = context.theme;
// // // // // // // // // // //     if (history.isEmpty) {
// // // // // // // // // // //       return const Center(child: Text('No rounds completed yet.'));
// // // // // // // // // // //     }
// // // // // // // // // // //     return ListView.builder(
// // // // // // // // // // //       padding: const EdgeInsets.all(12),
// // // // // // // // // // //       itemCount: history.length,
// // // // // // // // // // //       itemBuilder: (_, i) {
// // // // // // // // // // //         final round = history[history.length - 1 - i]; // newest first
// // // // // // // // // // //         final reactTally = <String, int>{};
// // // // // // // // // // //         for (final r in round.reactions) {
// // // // // // // // // // //           reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
// // // // // // // // // // //         }
// // // // // // // // // // //         return Card(
// // // // // // // // // // //           margin: const EdgeInsets.only(bottom: 10),
// // // // // // // // // // //           child: ExpansionTile(
// // // // // // // // // // //             leading: CircleAvatar(
// // // // // // // // // // //               backgroundColor: theme.colorScheme.primaryContainer,
// // // // // // // // // // //               child: Text(
// // // // // // // // // // //                 '${round.roundNumber}',
// // // // // // // // // // //                 style: theme.textTheme.labelLarge,
// // // // // // // // // // //               ),
// // // // // // // // // // //             ),
// // // // // // // // // // //             title: Text(
// // // // // // // // // // //               _name(round.playerId),
// // // // // // // // // // //               style: theme.textTheme.bodyMedium?.copyWith(
// // // // // // // // // // //                 fontWeight: FontWeight.w700,
// // // // // // // // // // //               ),
// // // // // // // // // // //             ),
// // // // // // // // // // //             subtitle: Text(
// // // // // // // // // // //               round.card != null
// // // // // // // // // // //                   ? '${round.card!.type == TodCardType.truth ? "Truth" : "Dare"}: ${round.card!.content}'
// // // // // // // // // // //                   : 'Skipped',
// // // // // // // // // // //               maxLines: 1,
// // // // // // // // // // //               overflow: TextOverflow.ellipsis,
// // // // // // // // // // //               style: theme.textTheme.bodySmall,
// // // // // // // // // // //             ),
// // // // // // // // // // //             children: [
// // // // // // // // // // //               Padding(
// // // // // // // // // // //                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
// // // // // // // // // // //                 child: Column(
// // // // // // // // // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // // // //                   children: [
// // // // // // // // // // //                     // Card content
// // // // // // // // // // //                     if (round.card != null)
// // // // // // // // // // //                       Container(
// // // // // // // // // // //                         width: double.infinity,
// // // // // // // // // // //                         padding: const EdgeInsets.all(10),
// // // // // // // // // // //                         decoration: BoxDecoration(
// // // // // // // // // // //                           color: round.card!.type == TodCardType.truth
// // // // // // // // // // //                               ? Colors.blue.withOpacity(0.08)
// // // // // // // // // // //                               : Colors.orange.withOpacity(0.08),
// // // // // // // // // // //                           borderRadius: BorderRadius.circular(8),
// // // // // // // // // // //                         ),
// // // // // // // // // // //                         child: Text(
// // // // // // // // // // //                           round.card!.content,
// // // // // // // // // // //                           style: theme.textTheme.bodyMedium,
// // // // // // // // // // //                         ),
// // // // // // // // // // //                       ),
// // // // // // // // // // //                     // Response
// // // // // // // // // // //                     if (round.response.isNotEmpty) ...[
// // // // // // // // // // //                       const SizedBox(height: 8),
// // // // // // // // // // //                       Row(
// // // // // // // // // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // // // //                         children: [
// // // // // // // // // // //                           const Text('💬 ', style: TextStyle(fontSize: 14)),
// // // // // // // // // // //                           Expanded(
// // // // // // // // // // //                             child: Text(
// // // // // // // // // // //                               '"${round.response}"',
// // // // // // // // // // //                               style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // // //                                 fontStyle: FontStyle.italic,
// // // // // // // // // // //                               ),
// // // // // // // // // // //                             ),
// // // // // // // // // // //                           ),
// // // // // // // // // // //                         ],
// // // // // // // // // // //                       ),
// // // // // // // // // // //                     ],
// // // // // // // // // // //                     // Votes
// // // // // // // // // // //                     if (round.voteCount > 0) ...[
// // // // // // // // // // //                       const SizedBox(height: 6),
// // // // // // // // // // //                       Text(
// // // // // // // // // // //                         '👍 ${round.voteCount} vote${round.voteCount != 1 ? "s" : ""}',
// // // // // // // // // // //                         style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // // //                           color: theme.colorScheme.primary,
// // // // // // // // // // //                           fontWeight: FontWeight.w600,
// // // // // // // // // // //                         ),
// // // // // // // // // // //                       ),
// // // // // // // // // // //                     ],
// // // // // // // // // // //                     // Proof image
// // // // // // // // // // //                     if (round.proofImageB64.isNotEmpty) ...[
// // // // // // // // // // //                       const SizedBox(height: 8),
// // // // // // // // // // //                       _HistoryViewOnceImage(b64: round.proofImageB64),
// // // // // // // // // // //                     ],
// // // // // // // // // // //                     // Reactions
// // // // // // // // // // //                     if (reactTally.isNotEmpty) ...[
// // // // // // // // // // //                       const SizedBox(height: 8),
// // // // // // // // // // //                       Wrap(
// // // // // // // // // // //                         spacing: 6,
// // // // // // // // // // //                         runSpacing: 4,
// // // // // // // // // // //                         children: reactTally.entries
// // // // // // // // // // //                             .map(
// // // // // // // // // // //                               (e) => Container(
// // // // // // // // // // //                                 padding: const EdgeInsets.symmetric(
// // // // // // // // // // //                                   horizontal: 8,
// // // // // // // // // // //                                   vertical: 3,
// // // // // // // // // // //                                 ),
// // // // // // // // // // //                                 decoration: BoxDecoration(
// // // // // // // // // // //                                   color:
// // // // // // // // // // //                                       theme.colorScheme.surfaceContainerHighest,
// // // // // // // // // // //                                   borderRadius: BorderRadius.circular(16),
// // // // // // // // // // //                                 ),
// // // // // // // // // // //                                 child: Text(
// // // // // // // // // // //                                   '${e.key} ${e.value}',
// // // // // // // // // // //                                   style: const TextStyle(fontSize: 13),
// // // // // // // // // // //                                 ),
// // // // // // // // // // //                               ),
// // // // // // // // // // //                             )
// // // // // // // // // // //                             .toList(),
// // // // // // // // // // //                       ),
// // // // // // // // // // //                     ],
// // // // // // // // // // //                   ],
// // // // // // // // // // //                 ),
// // // // // // // // // // //               ),
// // // // // // // // // // //             ],
// // // // // // // // // // //           ),
// // // // // // // // // // //         );
// // // // // // // // // // //       },
// // // // // // // // // // //     );
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // // // View-once image for history (separate state per instance)
// // // // // // // // // // // class _HistoryViewOnceImage extends StatefulWidget {
// // // // // // // // // // //   const _HistoryViewOnceImage({required this.b64});
// // // // // // // // // // //   final String b64;
// // // // // // // // // // //   @override
// // // // // // // // // // //   State<_HistoryViewOnceImage> createState() => _HistoryViewOnceImageState();
// // // // // // // // // // // }

// // // // // // // // // // // class _HistoryViewOnceImageState extends State<_HistoryViewOnceImage> {
// // // // // // // // // // //   bool _revealed = false;
// // // // // // // // // // //   bool _viewed = false;
// // // // // // // // // // //   @override
// // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // //     if (_viewed) {
// // // // // // // // // // //       return Container(
// // // // // // // // // // //         height: 48,
// // // // // // // // // // //         alignment: Alignment.centerLeft,
// // // // // // // // // // //         child: Text(
// // // // // // // // // // //           '📷 Proof viewed',
// // // // // // // // // // //           style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
// // // // // // // // // // //         ),
// // // // // // // // // // //       );
// // // // // // // // // // //     }
// // // // // // // // // // //     if (!_revealed) {
// // // // // // // // // // //       return GestureDetector(
// // // // // // // // // // //         onTap: () => setState(() => _revealed = true),
// // // // // // // // // // //         child: Container(
// // // // // // // // // // //           height: 60,
// // // // // // // // // // //           decoration: BoxDecoration(
// // // // // // // // // // //             color: Colors.grey.shade200,
// // // // // // // // // // //             borderRadius: BorderRadius.circular(8),
// // // // // // // // // // //           ),
// // // // // // // // // // //           alignment: Alignment.center,
// // // // // // // // // // //           child: const Row(
// // // // // // // // // // //             mainAxisSize: MainAxisSize.min,
// // // // // // // // // // //             children: [
// // // // // // // // // // //               Icon(Icons.lock_outline, size: 16),
// // // // // // // // // // //               SizedBox(width: 6),
// // // // // // // // // // //               Text(
// // // // // // // // // // //                 'Tap to view proof photo (once)',
// // // // // // // // // // //                 style: TextStyle(fontSize: 12),
// // // // // // // // // // //               ),
// // // // // // // // // // //             ],
// // // // // // // // // // //           ),
// // // // // // // // // // //         ),
// // // // // // // // // // //       );
// // // // // // // // // // //     }
// // // // // // // // // // //     return GestureDetector(
// // // // // // // // // // //       onTap: () => setState(() => _viewed = true),
// // // // // // // // // // //       child: ClipRRect(
// // // // // // // // // // //         borderRadius: BorderRadius.circular(8),
// // // // // // // // // // //         child: Stack(
// // // // // // // // // // //           children: [
// // // // // // // // // // //             Image.memory(
// // // // // // // // // // //               base64Decode(widget.b64),
// // // // // // // // // // //               height: 160,
// // // // // // // // // // //               width: double.infinity,
// // // // // // // // // // //               fit: BoxFit.cover,
// // // // // // // // // // //             ),
// // // // // // // // // // //             Positioned(
// // // // // // // // // // //               bottom: 6,
// // // // // // // // // // //               right: 6,
// // // // // // // // // // //               child: Container(
// // // // // // // // // // //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // // // // // // // // // //                 decoration: BoxDecoration(
// // // // // // // // // // //                   color: Colors.black54,
// // // // // // // // // // //                   borderRadius: BorderRadius.circular(12),
// // // // // // // // // // //                 ),
// // // // // // // // // // //                 child: const Text(
// // // // // // // // // // //                   'Tap to dismiss',
// // // // // // // // // // //                   style: TextStyle(color: Colors.white, fontSize: 11),
// // // // // // // // // // //                 ),
// // // // // // // // // // //               ),
// // // // // // // // // // //             ),
// // // // // // // // // // //           ],
// // // // // // // // // // //         ),
// // // // // // // // // // //       ),
// // // // // // // // // // //     );
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // import 'dart:async';
// // // // // // // // // // import 'dart:convert';

// // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // // // // // // // // import 'package:provider/provider.dart';
// // // // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // // // // // // // import '../../../../../core/di/service_locator.dart';
// // // // // // // // // // import '../../../../../core/extensions/context_ext.dart';
// // // // // // // // // // import '../../../../../core/providers/auth_provider.dart';
// // // // // // // // // // import '../../../../../core/router/route_names.dart';
// // // // // // // // // // import '../../../../../core/services/realtime_service.dart';
// // // // // // // // // // import '../../../../../core/theme/app_colors.dart';
// // // // // // // // // // import '../../../../../shared/widgets/feedback/error_view.dart';
// // // // // // // // // // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // // // // // // // // // // import '../../engine/base_game_engine.dart';
// // // // // // // // // // import '../../domain/tod_models.dart';
// // // // // // // // // // import '../../tod_game_provider.dart';

// // // // // // // // // // import '../../data/tod_repository.dart';
// // // // // // // // // // import 'tod_card_screen.dart';
// // // // // // // // // // import 'tod_end_screen.dart';
// // // // // // // // // // import 'tod_loading_screen.dart';
// // // // // // // // // // import 'tod_punishment_screen.dart';
// // // // // // // // // // import '../widgets/tod_hud.dart';

// // // // // // // // // // /// Entry point for an active Truth or Dare session.
// // // // // // // // // // ///
// // // // // // // // // // /// Responsibilities:
// // // // // // // // // // ///  - Owns and scopes TodGameProvider for this session
// // // // // // // // // // ///  - Wires RealtimeService callbacks → TodGameProvider
// // // // // // // // // // ///  - Routes between loading / error / active / game-over screens
// // // // // // // // // // ///  - Forwards game_state and player_action from the room Broadcast channel
// // // // // // // // // // class TodGameScreen extends StatefulWidget {
// // // // // // // // // //   const TodGameScreen({
// // // // // // // // // //     super.key,
// // // // // // // // // //     required this.roomId,
// // // // // // // // // //     required this.config,
// // // // // // // // // //     required this.playerIds,
// // // // // // // // // //     required this.playerDisplayNames,
// // // // // // // // // //     required this.packId,
// // // // // // // // // //     required this.isOwner,
// // // // // // // // // //     this.sessionId,
// // // // // // // // // //     this.isModerator = false,
// // // // // // // // // //     this.packCoverUrl,
// // // // // // // // // //   });

// // // // // // // // // //   final String roomId;
// // // // // // // // // //   final GameConfig config;
// // // // // // // // // //   final List<String> playerIds;
// // // // // // // // // //   final Map<String, String> playerDisplayNames; // userId → displayName
// // // // // // // // // //   final String packId;
// // // // // // // // // //   final bool isOwner;
// // // // // // // // // //   final String? sessionId;
// // // // // // // // // //   final bool isModerator;
// // // // // // // // // //   final String? packCoverUrl;

// // // // // // // // // //   @override
// // // // // // // // // //   State<TodGameScreen> createState() => _TodGameScreenState();
// // // // // // // // // // }

// // // // // // // // // // class _TodGameScreenState extends State<TodGameScreen> {
// // // // // // // // // //   late final TodGameProvider _provider;

// // // // // // // // // //   // Subscriptions to the room Broadcast channel
// // // // // // // // // //   // (channel already open by RoomProvider — we just register callbacks)
// // // // // // // // // //   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

// // // // // // // // // //   @override
// // // // // // // // // //   void initState() {
// // // // // // // // // //     super.initState();

// // // // // // // // // //     final auth = context.read<AuthProvider>();
// // // // // // // // // //     final user = auth.currentUser!;

// // // // // // // // // //     _provider = TodGameProvider(
// // // // // // // // // //       realtimeService: sl.realtimeService,
// // // // // // // // // //       repository: TodRepository.instance,
// // // // // // // // // //       currentUserId: user.id,
// // // // // // // // // //       currentDisplayName: user.displayName ?? user.username ?? 'Player',
// // // // // // // // // //       isModerator: widget.isModerator,
// // // // // // // // // //     );

// // // // // // // // // //     // ── Wire Broadcast callbacks ────────────────────────────────────────────
// // // // // // // // // //     // The room channel is already subscribed by RoomProvider/LobbyScreen.
// // // // // // // // // //     // TodGameScreen registers its own game-specific handlers for game_state
// // // // // // // // // //     // and player_action by re-subscribing with extended handlers.
// // // // // // // // // //     //
// // // // // // // // // //     // We do this by using the RealtimeService._bcast pattern:
// // // // // // // // // //     // The channel already has onGameState/onPlayerAction wired to no-ops
// // // // // // // // // //     // in RoomProvider. We replace them here by storing callbacks and
// // // // // // // // // //     // intercepting from the top-level channel via a dedicated subscription.
// // // // // // // // // //     _wireRealtimeCallbacks();

// // // // // // // // // //     if (widget.isOwner) {
// // // // // // // // // //       _provider.initAsOwner(
// // // // // // // // // //         roomId: widget.roomId,
// // // // // // // // // //         config: widget.config,
// // // // // // // // // //         playerIds: widget.playerIds,
// // // // // // // // // //         playerDisplayNames: widget.playerDisplayNames,
// // // // // // // // // //         packId: widget.packId,
// // // // // // // // // //         packCoverUrl: widget.packCoverUrl,
// // // // // // // // // //       );
// // // // // // // // // //     } else {
// // // // // // // // // //       _provider.initAsFollower(
// // // // // // // // // //         roomId: widget.roomId,
// // // // // // // // // //         config: widget.config,
// // // // // // // // // //         sessionId: widget.sessionId,
// // // // // // // // // //         packCoverUrl: widget.packCoverUrl,
// // // // // // // // // //       );
// // // // // // // // // //     }
// // // // // // // // // //   }

// // // // // // // // // //   @override
// // // // // // // // // //   void dispose() {
// // // // // // // // // //     _statusSub?.cancel();
// // // // // // // // // //     _provider.dispose();
// // // // // // // // // //     super.dispose();
// // // // // // // // // //   }

// // // // // // // // // //   /// Wire game-specific callbacks into the existing room channel.
// // // // // // // // // //   ///
// // // // // // // // // //   /// Strategy: re-subscribe to the room channel with updated handlers that
// // // // // // // // // //   /// forward game_state and player_action to this provider.
// // // // // // // // // //   /// The channel is already open; we track callbacks via a thin interceptor.
// // // // // // // // // //   void _wireRealtimeCallbacks() {
// // // // // // // // // //     // Listen to channel status changes for reconnection awareness
// // // // // // // // // //     _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
// // // // // // // // // //       status,
// // // // // // // // // //     ) {
// // // // // // // // // //       if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // // // // // //           !_provider.hasSyncedState) {
// // // // // // // // // //         // Channel reconnected — request state sync
// // // // // // // // // //         sl.realtimeService.broadcastSyncRequest(
// // // // // // // // // //           widget.roomId,
// // // // // // // // // //           context.read<AuthProvider>().currentUser!.id,
// // // // // // // // // //           0,
// // // // // // // // // //         );
// // // // // // // // // //       }
// // // // // // // // // //     });

// // // // // // // // // //     // Re-subscribe with game handlers added.
// // // // // // // // // //     // This safely replaces the channel subscription with game callbacks.
// // // // // // // // // //     // (No-op handlers in RoomProvider are replaced with active ones here.)
// // // // // // // // // //     _resubscribeWithGameHandlers();
// // // // // // // // // //   }

// // // // // // // // // //   void _resubscribeWithGameHandlers() {
// // // // // // // // // //     final userId = context.read<AuthProvider>().currentUser!.id;

// // // // // // // // // //     // Unsubscribe existing channel and re-subscribe with game callbacks merged
// // // // // // // // // //     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
// // // // // // // // // //       sl.realtimeService.subscribe(
// // // // // // // // // //         roomId: widget.roomId,
// // // // // // // // // //         // ── Game-specific handlers ─────────────────────────────────────────
// // // // // // // // // //         onGameState: (p) => _provider.onStateBroadcast(p),
// // // // // // // // // //         onPlayerAction: (p) => _provider.onPlayerAction(p),
// // // // // // // // // //         onSyncRequest: (p) => _provider.onSyncRequest(p),
// // // // // // // // // //         onGameStarted: (_) {},
// // // // // // // // // //         onGameEnded: (_) {},
// // // // // // // // // //         // ── Room lifecycle (passthrough — RoomProvider is disposed) ─────────
// // // // // // // // // //         onRoomEvent: (_) {},
// // // // // // // // // //         onChatMessage: (_) {},
// // // // // // // // // //         onModeration: (p) => _handleModerationEvent(p),
// // // // // // // // // //         onSettingsChange: (_) {},
// // // // // // // // // //         // ── Presence ──────────────────────────────────────────────────────
// // // // // // // // // //         onPresenceSync: (_) {},
// // // // // // // // // //         onPresenceJoin: (_) {},
// // // // // // // // // //         onPresenceLeave: (_) {},
// // // // // // // // // //         onStatusChange: (status) {
// // // // // // // // // //           if (!mounted) return;
// // // // // // // // // //           if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // // // // // //               !_provider.hasSyncedState) {
// // // // // // // // // //             sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
// // // // // // // // // //           }
// // // // // // // // // //         },
// // // // // // // // // //       );
// // // // // // // // // //     });
// // // // // // // // // //   }

// // // // // // // // // //   void _handleModerationEvent(Map<String, dynamic> p) {
// // // // // // // // // //     final type = p['type'] as String?;
// // // // // // // // // //     final targetId = p['target_user_id'] as String?;
// // // // // // // // // //     final currentId = context.read<AuthProvider>().currentUser?.id;

// // // // // // // // // //     // If kicked or banned, navigate back to lobby
// // // // // // // // // //     if ((type == 'kick' || type == 'ban') && targetId == currentId) {
// // // // // // // // // //       if (mounted) context.go(RouteNames.home);
// // // // // // // // // //     }
// // // // // // // // // //   }

// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // //     return ChangeNotifierProvider.value(
// // // // // // // // // //       value: _provider,
// // // // // // // // // //       child: Consumer<TodGameProvider>(
// // // // // // // // // //         builder: (ctx, game, _) => _build(ctx, game),
// // // // // // // // // //       ),
// // // // // // // // // //     );
// // // // // // // // // //   }

// // // // // // // // // //   Widget _build(BuildContext ctx, TodGameProvider game) {
// // // // // // // // // //     if (game.loadState == TodLoadState.loading) {
// // // // // // // // // //       return const TodLoadingScreen();
// // // // // // // // // //     }

// // // // // // // // // //     if (game.loadState == TodLoadState.error) {
// // // // // // // // // //       return Scaffold(
// // // // // // // // // //         appBar: AppBar(
// // // // // // // // // //           leading: BackButton(onPressed: () => ctx.go(RouteNames.home)),
// // // // // // // // // //         ),
// // // // // // // // // //         body: ErrorView(
// // // // // // // // // //           message: game.error ?? 'Failed to load game',
// // // // // // // // // //           onRetry: () => ctx.go(RouteNames.home),
// // // // // // // // // //         ),
// // // // // // // // // //       );
// // // // // // // // // //     }

// // // // // // // // // //     if (game.loadState == TodLoadState.gameOver ||
// // // // // // // // // //         (game.state?.isOver ?? false)) {
// // // // // // // // // //       return TodEndScreen(
// // // // // // // // // //         state: game.state!,
// // // // // // // // // //         displayNames: widget.playerDisplayNames,
// // // // // // // // // //         onLeave: () => ctx.go(RouteNames.home),
// // // // // // // // // //       );
// // // // // // // // // //     }

// // // // // // // // // //     final state = game.state;
// // // // // // // // // //     if (state == null) return const TodLoadingScreen();

// // // // // // // // // //     return _TodGameScaffold(
// // // // // // // // // //       state: state,
// // // // // // // // // //       game: game,
// // // // // // // // // //       displayNames: widget.playerDisplayNames,
// // // // // // // // // //     );
// // // // // // // // // //   }
// // // // // // // // // // }

// // // // // // // // // // // ── Scaffold with history support ─────────────────────────────────────────────

// // // // // // // // // // class _TodGameScaffold extends StatefulWidget {
// // // // // // // // // //   const _TodGameScaffold({
// // // // // // // // // //     required this.state,
// // // // // // // // // //     required this.game,
// // // // // // // // // //     required this.displayNames,
// // // // // // // // // //   });
// // // // // // // // // //   final TodState state;
// // // // // // // // // //   final TodGameProvider game;
// // // // // // // // // //   final Map<String, String> displayNames;
// // // // // // // // // //   @override
// // // // // // // // // //   State<_TodGameScaffold> createState() => _TodGameScaffoldState();
// // // // // // // // // // }

// // // // // // // // // // class _TodGameScaffoldState extends State<_TodGameScaffold> {
// // // // // // // // // //   bool _showHistory = false;
// // // // // // // // // //   bool _showChat = false;
// // // // // // // // // //   int _unreadChat = 0;

// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // //     final state = widget.state;
// // // // // // // // // //     final game = widget.game;

// // // // // // // // // //     if (_showHistory) {
// // // // // // // // // //       return Scaffold(
// // // // // // // // // //         appBar: AppBar(
// // // // // // // // // //           leading: BackButton(
// // // // // // // // // //             onPressed: () => setState(() => _showHistory = false),
// // // // // // // // // //           ),
// // // // // // // // // //           title: Text('History (${state.history.length} rounds)'),
// // // // // // // // // //         ),
// // // // // // // // // //         body: _HistoryPanel(
// // // // // // // // // //           history: state.history,
// // // // // // // // // //           displayNames: widget.displayNames,
// // // // // // // // // //         ),
// // // // // // // // // //       );
// // // // // // // // // //     }

// // // // // // // // // //     return Scaffold(
// // // // // // // // // //       appBar: AppBar(
// // // // // // // // // //         automaticallyImplyLeading: false,
// // // // // // // // // //         title: const Text(
// // // // // // // // // //           '',
// // // // // // // // // //         ), // prevents overflow from unconstrained actions row
// // // // // // // // // //         actions: [
// // // // // // // // // //           if (state.history.isNotEmpty)
// // // // // // // // // //             IconButton(
// // // // // // // // // //               icon: const Icon(Icons.history_rounded),
// // // // // // // // // //               tooltip: 'History',
// // // // // // // // // //               onPressed: () => setState(() => _showHistory = true),
// // // // // // // // // //             ),
// // // // // // // // // //         ],
// // // // // // // // // //       ),
// // // // // // // // // //       body: SafeArea(
// // // // // // // // // //         child: Column(
// // // // // // // // // //           children: [
// // // // // // // // // //             TodHud(state: state, game: game, displayNames: widget.displayNames),
// // // // // // // // // //             Expanded(
// // // // // // // // // //               child: AnimatedSwitcher(
// // // // // // // // // //                 duration: const Duration(milliseconds: 300),
// // // // // // // // // //                 transitionBuilder: (child, anim) => FadeTransition(
// // // // // // // // // //                   opacity: anim,
// // // // // // // // // //                   child: SlideTransition(
// // // // // // // // // //                     position:
// // // // // // // // // //                         Tween<Offset>(
// // // // // // // // // //                           begin: const Offset(0, 0.05),
// // // // // // // // // //                           end: Offset.zero,
// // // // // // // // // //                         ).animate(
// // // // // // // // // //                           CurvedAnimation(
// // // // // // // // // //                             parent: anim,
// // // // // // // // // //                             curve: Curves.easeOutCubic,
// // // // // // // // // //                           ),
// // // // // // // // // //                         ),
// // // // // // // // // //                     child: child,
// // // // // // // // // //                   ),
// // // // // // // // // //                 ),
// // // // // // // // // //                 child: KeyedSubtree(
// // // // // // // // // //                   key: ValueKey('${state.phase}-${state.currentPlayerId}'),
// // // // // // // // // //                   child: _phaseWidget(
// // // // // // // // // //                     context,
// // // // // // // // // //                     game,
// // // // // // // // // //                     widget.displayNames,
// // // // // // // // // //                     state,
// // // // // // // // // //                   ),
// // // // // // // // // //                 ),
// // // // // // // // // //               ),
// // // // // // // // // //             ),
// // // // // // // // // //           ],
// // // // // // // // // //         ),
// // // // // // // // // //       ),
// // // // // // // // // //     );
// // // // // // // // // //   }

// // // // // // // // // //   Widget _phaseWidget(
// // // // // // // // // //     BuildContext ctx,
// // // // // // // // // //     TodGameProvider game,
// // // // // // // // // //     Map<String, String> displayNames,
// // // // // // // // // //     TodState state,
// // // // // // // // // //   ) {
// // // // // // // // // //     return switch (state.phase) {
// // // // // // // // // //       TodTurnPhase.punishmentVoting => TodPunishmentScreen(
// // // // // // // // // //         state: state,
// // // // // // // // // //         game: game,
// // // // // // // // // //         displayNames: widget.displayNames,
// // // // // // // // // //       ),
// // // // // // // // // //       _ => TodCardScreen(
// // // // // // // // // //         state: state,
// // // // // // // // // //         game: game,
// // // // // // // // // //         displayNames: widget.displayNames,
// // // // // // // // // //       ),
// // // // // // // // // //     };
// // // // // // // // // //   }
// // // // // // // // // // }

// // // // // // // // // // // ── History panel ─────────────────────────────────────────────────────────────

// // // // // // // // // // class _HistoryPanel extends StatelessWidget {
// // // // // // // // // //   const _HistoryPanel({required this.history, required this.displayNames});
// // // // // // // // // //   final List<TodRoundRecord> history;
// // // // // // // // // //   final Map<String, String> displayNames;

// // // // // // // // // //   String _name(String id) =>
// // // // // // // // // //       displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // //     final theme = context.theme;
// // // // // // // // // //     if (history.isEmpty) {
// // // // // // // // // //       return const Center(child: Text('No rounds completed yet.'));
// // // // // // // // // //     }
// // // // // // // // // //     return ListView.builder(
// // // // // // // // // //       padding: const EdgeInsets.all(12),
// // // // // // // // // //       itemCount: history.length,
// // // // // // // // // //       itemBuilder: (_, i) {
// // // // // // // // // //         final round = history[history.length - 1 - i]; // newest first
// // // // // // // // // //         final reactTally = <String, int>{};
// // // // // // // // // //         for (final r in round.reactions) {
// // // // // // // // // //           reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
// // // // // // // // // //         }
// // // // // // // // // //         return Card(
// // // // // // // // // //           margin: const EdgeInsets.only(bottom: 10),
// // // // // // // // // //           child: ExpansionTile(
// // // // // // // // // //             leading: CircleAvatar(
// // // // // // // // // //               backgroundColor: theme.colorScheme.primaryContainer,
// // // // // // // // // //               child: Text(
// // // // // // // // // //                 '${round.roundNumber}',
// // // // // // // // // //                 style: theme.textTheme.labelLarge,
// // // // // // // // // //               ),
// // // // // // // // // //             ),
// // // // // // // // // //             title: Text(
// // // // // // // // // //               _name(round.playerId),
// // // // // // // // // //               style: theme.textTheme.bodyMedium?.copyWith(
// // // // // // // // // //                 fontWeight: FontWeight.w700,
// // // // // // // // // //               ),
// // // // // // // // // //             ),
// // // // // // // // // //             subtitle: Text(
// // // // // // // // // //               round.card != null
// // // // // // // // // //                   ? '${round.card!.type == TodCardType.truth ? "Truth" : "Dare"}: ${round.card!.content}'
// // // // // // // // // //                   : 'Skipped',
// // // // // // // // // //               maxLines: 1,
// // // // // // // // // //               overflow: TextOverflow.ellipsis,
// // // // // // // // // //               style: theme.textTheme.bodySmall,
// // // // // // // // // //             ),
// // // // // // // // // //             children: [
// // // // // // // // // //               Padding(
// // // // // // // // // //                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
// // // // // // // // // //                 child: Column(
// // // // // // // // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // // //                   children: [
// // // // // // // // // //                     // Card content
// // // // // // // // // //                     if (round.card != null)
// // // // // // // // // //                       Container(
// // // // // // // // // //                         width: double.infinity,
// // // // // // // // // //                         padding: const EdgeInsets.all(10),
// // // // // // // // // //                         decoration: BoxDecoration(
// // // // // // // // // //                           color: round.card!.type == TodCardType.truth
// // // // // // // // // //                               ? Colors.blue.withOpacity(0.08)
// // // // // // // // // //                               : Colors.orange.withOpacity(0.08),
// // // // // // // // // //                           borderRadius: BorderRadius.circular(8),
// // // // // // // // // //                         ),
// // // // // // // // // //                         child: Text(
// // // // // // // // // //                           round.card!.content,
// // // // // // // // // //                           style: theme.textTheme.bodyMedium,
// // // // // // // // // //                         ),
// // // // // // // // // //                       ),
// // // // // // // // // //                     // Response
// // // // // // // // // //                     if (round.response.isNotEmpty) ...[
// // // // // // // // // //                       const SizedBox(height: 8),
// // // // // // // // // //                       Row(
// // // // // // // // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // // //                         children: [
// // // // // // // // // //                           const Text('💬 ', style: TextStyle(fontSize: 14)),
// // // // // // // // // //                           Expanded(
// // // // // // // // // //                             child: Text(
// // // // // // // // // //                               '"${round.response}"',
// // // // // // // // // //                               style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // //                                 fontStyle: FontStyle.italic,
// // // // // // // // // //                               ),
// // // // // // // // // //                             ),
// // // // // // // // // //                           ),
// // // // // // // // // //                         ],
// // // // // // // // // //                       ),
// // // // // // // // // //                     ],
// // // // // // // // // //                     // Votes
// // // // // // // // // //                     if (round.voteCount > 0) ...[
// // // // // // // // // //                       const SizedBox(height: 6),
// // // // // // // // // //                       Text(
// // // // // // // // // //                         '👍 ${round.voteCount} vote${round.voteCount != 1 ? "s" : ""}',
// // // // // // // // // //                         style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // // //                           color: theme.colorScheme.primary,
// // // // // // // // // //                           fontWeight: FontWeight.w600,
// // // // // // // // // //                         ),
// // // // // // // // // //                       ),
// // // // // // // // // //                     ],
// // // // // // // // // //                     // Proof image
// // // // // // // // // //                     if (round.proofImageB64.isNotEmpty) ...[
// // // // // // // // // //                       const SizedBox(height: 8),
// // // // // // // // // //                       _HistoryViewOnceImage(b64: round.proofImageB64),
// // // // // // // // // //                     ],
// // // // // // // // // //                     // Reactions
// // // // // // // // // //                     if (reactTally.isNotEmpty) ...[
// // // // // // // // // //                       const SizedBox(height: 8),
// // // // // // // // // //                       Wrap(
// // // // // // // // // //                         spacing: 6,
// // // // // // // // // //                         runSpacing: 4,
// // // // // // // // // //                         children: reactTally.entries
// // // // // // // // // //                             .map(
// // // // // // // // // //                               (e) => Container(
// // // // // // // // // //                                 padding: const EdgeInsets.symmetric(
// // // // // // // // // //                                   horizontal: 8,
// // // // // // // // // //                                   vertical: 3,
// // // // // // // // // //                                 ),
// // // // // // // // // //                                 decoration: BoxDecoration(
// // // // // // // // // //                                   color:
// // // // // // // // // //                                       theme.colorScheme.surfaceContainerHighest,
// // // // // // // // // //                                   borderRadius: BorderRadius.circular(16),
// // // // // // // // // //                                 ),
// // // // // // // // // //                                 child: Text(
// // // // // // // // // //                                   '${e.key} ${e.value}',
// // // // // // // // // //                                   style: const TextStyle(fontSize: 13),
// // // // // // // // // //                                 ),
// // // // // // // // // //                               ),
// // // // // // // // // //                             )
// // // // // // // // // //                             .toList(),
// // // // // // // // // //                       ),
// // // // // // // // // //                     ],
// // // // // // // // // //                   ],
// // // // // // // // // //                 ),
// // // // // // // // // //               ),
// // // // // // // // // //             ],
// // // // // // // // // //           ),
// // // // // // // // // //         );
// // // // // // // // // //       },
// // // // // // // // // //     );
// // // // // // // // // //   }
// // // // // // // // // // }

// // // // // // // // // // // View-once image for history (separate state per instance)
// // // // // // // // // // class _HistoryViewOnceImage extends StatefulWidget {
// // // // // // // // // //   const _HistoryViewOnceImage({required this.b64});
// // // // // // // // // //   final String b64;
// // // // // // // // // //   @override
// // // // // // // // // //   State<_HistoryViewOnceImage> createState() => _HistoryViewOnceImageState();
// // // // // // // // // // }

// // // // // // // // // // class _HistoryViewOnceImageState extends State<_HistoryViewOnceImage> {
// // // // // // // // // //   bool _revealed = false;
// // // // // // // // // //   bool _viewed = false;
// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // //     if (_viewed) {
// // // // // // // // // //       return Container(
// // // // // // // // // //         height: 48,
// // // // // // // // // //         alignment: Alignment.centerLeft,
// // // // // // // // // //         child: Text(
// // // // // // // // // //           '📷 Proof viewed',
// // // // // // // // // //           style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
// // // // // // // // // //         ),
// // // // // // // // // //       );
// // // // // // // // // //     }
// // // // // // // // // //     if (!_revealed) {
// // // // // // // // // //       return GestureDetector(
// // // // // // // // // //         onTap: () => setState(() => _revealed = true),
// // // // // // // // // //         child: Container(
// // // // // // // // // //           height: 60,
// // // // // // // // // //           decoration: BoxDecoration(
// // // // // // // // // //             color: Colors.grey.shade200,
// // // // // // // // // //             borderRadius: BorderRadius.circular(8),
// // // // // // // // // //           ),
// // // // // // // // // //           alignment: Alignment.center,
// // // // // // // // // //           child: const Row(
// // // // // // // // // //             mainAxisSize: MainAxisSize.min,
// // // // // // // // // //             children: [
// // // // // // // // // //               Icon(Icons.lock_outline, size: 16),
// // // // // // // // // //               SizedBox(width: 6),
// // // // // // // // // //               Text(
// // // // // // // // // //                 'Tap to view proof photo (once)',
// // // // // // // // // //                 style: TextStyle(fontSize: 12),
// // // // // // // // // //               ),
// // // // // // // // // //             ],
// // // // // // // // // //           ),
// // // // // // // // // //         ),
// // // // // // // // // //       );
// // // // // // // // // //     }
// // // // // // // // // //     return GestureDetector(
// // // // // // // // // //       onTap: () => setState(() => _viewed = true),
// // // // // // // // // //       child: ClipRRect(
// // // // // // // // // //         borderRadius: BorderRadius.circular(8),
// // // // // // // // // //         child: Stack(
// // // // // // // // // //           children: [
// // // // // // // // // //             Image.memory(
// // // // // // // // // //               base64Decode(widget.b64),
// // // // // // // // // //               height: 160,
// // // // // // // // // //               width: double.infinity,
// // // // // // // // // //               fit: BoxFit.cover,
// // // // // // // // // //             ),
// // // // // // // // // //             Positioned(
// // // // // // // // // //               bottom: 6,
// // // // // // // // // //               right: 6,
// // // // // // // // // //               child: Container(
// // // // // // // // // //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // // // // // // // // //                 decoration: BoxDecoration(
// // // // // // // // // //                   color: Colors.black54,
// // // // // // // // // //                   borderRadius: BorderRadius.circular(12),
// // // // // // // // // //                 ),
// // // // // // // // // //                 child: const Text(
// // // // // // // // // //                   'Tap to dismiss',
// // // // // // // // // //                   style: TextStyle(color: Colors.white, fontSize: 11),
// // // // // // // // // //                 ),
// // // // // // // // // //               ),
// // // // // // // // // //             ),
// // // // // // // // // //           ],
// // // // // // // // // //         ),
// // // // // // // // // //       ),
// // // // // // // // // //     );
// // // // // // // // // //   }
// // // // // // // // // // }

// // // // // // // // // import 'dart:async';
// // // // // // // // // import 'dart:convert';

// // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // // // // // // // import 'package:provider/provider.dart';
// // // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // // // // // // import '../../../../../core/di/service_locator.dart';
// // // // // // // // // import '../../../../../core/extensions/context_ext.dart';
// // // // // // // // // import '../../../../../core/providers/auth_provider.dart';
// // // // // // // // // import '../../../../../core/router/route_names.dart';
// // // // // // // // // import '../../../../../core/services/realtime_service.dart';
// // // // // // // // // import '../../../../../core/theme/app_colors.dart';
// // // // // // // // // import '../../../../../shared/widgets/feedback/error_view.dart';
// // // // // // // // // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // // // // // // // // // import '../../engine/base_game_engine.dart';
// // // // // // // // // import '../../domain/tod_models.dart';
// // // // // // // // // import '../../tod_game_provider.dart';

// // // // // // // // // import '../../data/tod_repository.dart';
// // // // // // // // // import 'tod_card_screen.dart';
// // // // // // // // // import 'tod_end_screen.dart';
// // // // // // // // // import 'tod_loading_screen.dart';
// // // // // // // // // import 'tod_punishment_screen.dart';
// // // // // // // // // import '../widgets/tod_hud.dart';

// // // // // // // // // /// Entry point for an active Truth or Dare session.
// // // // // // // // // ///
// // // // // // // // // /// Responsibilities:
// // // // // // // // // ///  - Owns and scopes TodGameProvider for this session
// // // // // // // // // ///  - Wires RealtimeService callbacks → TodGameProvider
// // // // // // // // // ///  - Routes between loading / error / active / game-over screens
// // // // // // // // // ///  - Forwards game_state and player_action from the room Broadcast channel
// // // // // // // // // class TodGameScreen extends StatefulWidget {
// // // // // // // // //   const TodGameScreen({
// // // // // // // // //     super.key,
// // // // // // // // //     required this.roomId,
// // // // // // // // //     required this.config,
// // // // // // // // //     required this.playerIds,
// // // // // // // // //     required this.playerDisplayNames,
// // // // // // // // //     required this.packId,
// // // // // // // // //     required this.isOwner,
// // // // // // // // //     this.sessionId,
// // // // // // // // //     this.isModerator = false,
// // // // // // // // //     this.packCoverUrl,
// // // // // // // // //   });

// // // // // // // // //   final String roomId;
// // // // // // // // //   final GameConfig config;
// // // // // // // // //   final List<String> playerIds;
// // // // // // // // //   final Map<String, String> playerDisplayNames; // userId → displayName
// // // // // // // // //   final String packId;
// // // // // // // // //   final bool isOwner;
// // // // // // // // //   final String? sessionId;
// // // // // // // // //   final bool isModerator;
// // // // // // // // //   final String? packCoverUrl;

// // // // // // // // //   @override
// // // // // // // // //   State<TodGameScreen> createState() => _TodGameScreenState();
// // // // // // // // // }

// // // // // // // // // class _TodGameScreenState extends State<TodGameScreen> {
// // // // // // // // //   late final TodGameProvider _provider;

// // // // // // // // //   // Subscriptions to the room Broadcast channel
// // // // // // // // //   // (channel already open by RoomProvider — we just register callbacks)
// // // // // // // // //   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

// // // // // // // // //   @override
// // // // // // // // //   void initState() {
// // // // // // // // //     super.initState();

// // // // // // // // //     final auth = context.read<AuthProvider>();
// // // // // // // // //     final user = auth.currentUser!;

// // // // // // // // //     _provider = TodGameProvider(
// // // // // // // // //       realtimeService: sl.realtimeService,
// // // // // // // // //       repository: TodRepository.instance,
// // // // // // // // //       currentUserId: user.id,
// // // // // // // // //       currentDisplayName: user.displayName ?? user.username ?? 'Player',
// // // // // // // // //       isModerator: widget.isModerator,
// // // // // // // // //     );

// // // // // // // // //     // ── Wire Broadcast callbacks ────────────────────────────────────────────
// // // // // // // // //     // The room channel is already subscribed by RoomProvider/LobbyScreen.
// // // // // // // // //     // TodGameScreen registers its own game-specific handlers for game_state
// // // // // // // // //     // and player_action by re-subscribing with extended handlers.
// // // // // // // // //     //
// // // // // // // // //     // We do this by using the RealtimeService._bcast pattern:
// // // // // // // // //     // The channel already has onGameState/onPlayerAction wired to no-ops
// // // // // // // // //     // in RoomProvider. We replace them here by storing callbacks and
// // // // // // // // //     // intercepting from the top-level channel via a dedicated subscription.
// // // // // // // // //     _wireRealtimeCallbacks();

// // // // // // // // //     if (widget.isOwner) {
// // // // // // // // //       _provider.initAsOwner(
// // // // // // // // //         roomId: widget.roomId,
// // // // // // // // //         config: widget.config,
// // // // // // // // //         playerIds: widget.playerIds,
// // // // // // // // //         playerDisplayNames: widget.playerDisplayNames,
// // // // // // // // //         packId: widget.packId,
// // // // // // // // //         packCoverUrl: widget.packCoverUrl,
// // // // // // // // //       );
// // // // // // // // //     } else {
// // // // // // // // //       _provider.initAsFollower(
// // // // // // // // //         roomId: widget.roomId,
// // // // // // // // //         config: widget.config,
// // // // // // // // //         sessionId: widget.sessionId,
// // // // // // // // //         packCoverUrl: widget.packCoverUrl,
// // // // // // // // //       );
// // // // // // // // //     }
// // // // // // // // //   }

// // // // // // // // //   @override
// // // // // // // // //   void dispose() {
// // // // // // // // //     _statusSub?.cancel();
// // // // // // // // //     _provider.dispose();
// // // // // // // // //     super.dispose();
// // // // // // // // //   }

// // // // // // // // //   /// Wire game-specific callbacks into the existing room channel.
// // // // // // // // //   ///
// // // // // // // // //   /// Strategy: re-subscribe to the room channel with updated handlers that
// // // // // // // // //   /// forward game_state and player_action to this provider.
// // // // // // // // //   /// The channel is already open; we track callbacks via a thin interceptor.
// // // // // // // // //   void _wireRealtimeCallbacks() {
// // // // // // // // //     // Listen to channel status changes for reconnection awareness
// // // // // // // // //     _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
// // // // // // // // //       status,
// // // // // // // // //     ) {
// // // // // // // // //       if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // // // // //           !_provider.hasSyncedState) {
// // // // // // // // //         // Channel reconnected — request state sync
// // // // // // // // //         sl.realtimeService.broadcastSyncRequest(
// // // // // // // // //           widget.roomId,
// // // // // // // // //           context.read<AuthProvider>().currentUser!.id,
// // // // // // // // //           0,
// // // // // // // // //         );
// // // // // // // // //       }
// // // // // // // // //     });

// // // // // // // // //     // Re-subscribe with game handlers added.
// // // // // // // // //     // This safely replaces the channel subscription with game callbacks.
// // // // // // // // //     // (No-op handlers in RoomProvider are replaced with active ones here.)
// // // // // // // // //     _resubscribeWithGameHandlers();
// // // // // // // // //   }

// // // // // // // // //   void _resubscribeWithGameHandlers() {
// // // // // // // // //     final userId = context.read<AuthProvider>().currentUser!.id;

// // // // // // // // //     // Unsubscribe existing channel and re-subscribe with game callbacks merged
// // // // // // // // //     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
// // // // // // // // //       sl.realtimeService.subscribe(
// // // // // // // // //         roomId: widget.roomId,
// // // // // // // // //         // ── Game-specific handlers ─────────────────────────────────────────
// // // // // // // // //         onGameState: (p) => _provider.onStateBroadcast(p),
// // // // // // // // //         onPlayerAction: (p) => _provider.onPlayerAction(p),
// // // // // // // // //         onSyncRequest: (p) => _provider.onSyncRequest(p),
// // // // // // // // //         onGameStarted: (_) {},
// // // // // // // // //         onGameEnded: (_) {},
// // // // // // // // //         // ── Room lifecycle (passthrough — RoomProvider is disposed) ─────────
// // // // // // // // //         onRoomEvent: (_) {},
// // // // // // // // //         onChatMessage: (_) {},
// // // // // // // // //         onModeration: (p) => _handleModerationEvent(p),
// // // // // // // // //         onSettingsChange: (_) {},
// // // // // // // // //         // ── Presence ──────────────────────────────────────────────────────
// // // // // // // // //         onPresenceSync: (_) {},
// // // // // // // // //         onPresenceJoin: (_) {},
// // // // // // // // //         onPresenceLeave: (_) {},
// // // // // // // // //         onStatusChange: (status) {
// // // // // // // // //           if (!mounted) return;
// // // // // // // // //           if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // // // // //               !_provider.hasSyncedState) {
// // // // // // // // //             sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
// // // // // // // // //           }
// // // // // // // // //         },
// // // // // // // // //       );
// // // // // // // // //     });
// // // // // // // // //   }

// // // // // // // // //   void _handleModerationEvent(Map<String, dynamic> p) {
// // // // // // // // //     final type = p['type'] as String?;
// // // // // // // // //     final targetId = p['target_user_id'] as String?;
// // // // // // // // //     final currentId = context.read<AuthProvider>().currentUser?.id;

// // // // // // // // //     // If kicked or banned, navigate back to lobby
// // // // // // // // //     if ((type == 'kick' || type == 'ban') && targetId == currentId) {
// // // // // // // // //       if (mounted) {
// // // // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // // //           const SnackBar(content: Text('You were removed from the room')),
// // // // // // // // //         );
// // // // // // // // //         context.go(RouteNames.home);
// // // // // // // // //       }
// // // // // // // // //     }
// // // // // // // // //   }

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     return ChangeNotifierProvider.value(
// // // // // // // // //       value: _provider,
// // // // // // // // //       child: Consumer<TodGameProvider>(
// // // // // // // // //         builder: (ctx, game, _) => _build(ctx, game),
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }

// // // // // // // // //   Widget _build(BuildContext ctx, TodGameProvider game) {
// // // // // // // // //     if (game.loadState == TodLoadState.loading) {
// // // // // // // // //       return const TodLoadingScreen();
// // // // // // // // //     }

// // // // // // // // //     if (game.loadState == TodLoadState.error) {
// // // // // // // // //       return Scaffold(
// // // // // // // // //         appBar: AppBar(
// // // // // // // // //           leading: BackButton(onPressed: () => ctx.go(RouteNames.home)),
// // // // // // // // //         ),
// // // // // // // // //         body: ErrorView(
// // // // // // // // //           message: game.error ?? 'Failed to load game',
// // // // // // // // //           onRetry: () => ctx.go(RouteNames.home),
// // // // // // // // //         ),
// // // // // // // // //       );
// // // // // // // // //     }

// // // // // // // // //     if (game.loadState == TodLoadState.gameOver ||
// // // // // // // // //         (game.state?.isOver ?? false)) {
// // // // // // // // //       return TodEndScreen(
// // // // // // // // //         state: game.state!,
// // // // // // // // //         displayNames: widget.playerDisplayNames,
// // // // // // // // //         onLeave: () => ctx.go(RouteNames.home),
// // // // // // // // //       );
// // // // // // // // //     }

// // // // // // // // //     final state = game.state;
// // // // // // // // //     if (state == null) return const TodLoadingScreen();

// // // // // // // // //     return _TodGameScaffold(
// // // // // // // // //       state: state,
// // // // // // // // //       game: game,
// // // // // // // // //       displayNames: widget.playerDisplayNames,
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // // // ── Scaffold with history support ─────────────────────────────────────────────

// // // // // // // // // class _TodGameScaffold extends StatefulWidget {
// // // // // // // // //   const _TodGameScaffold({
// // // // // // // // //     required this.state,
// // // // // // // // //     required this.game,
// // // // // // // // //     required this.displayNames,
// // // // // // // // //   });
// // // // // // // // //   final TodState state;
// // // // // // // // //   final TodGameProvider game;
// // // // // // // // //   final Map<String, String> displayNames;
// // // // // // // // //   @override
// // // // // // // // //   State<_TodGameScaffold> createState() => _TodGameScaffoldState();
// // // // // // // // // }

// // // // // // // // // class _TodGameScaffoldState extends State<_TodGameScaffold> {
// // // // // // // // //   bool _showHistory = false;
// // // // // // // // //   bool _showChat = false;
// // // // // // // // //   int _unreadChat = 0;

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     final state = widget.state;
// // // // // // // // //     final game = widget.game;

// // // // // // // // //     if (_showHistory) {
// // // // // // // // //       return Scaffold(
// // // // // // // // //         appBar: AppBar(
// // // // // // // // //           leading: BackButton(
// // // // // // // // //             onPressed: () => setState(() => _showHistory = false),
// // // // // // // // //           ),
// // // // // // // // //           title: Text('History (${state.history.length} rounds)'),
// // // // // // // // //         ),
// // // // // // // // //         body: _HistoryPanel(
// // // // // // // // //           history: state.history,
// // // // // // // // //           displayNames: widget.displayNames,
// // // // // // // // //         ),
// // // // // // // // //       );
// // // // // // // // //     }

// // // // // // // // //     return Scaffold(
// // // // // // // // //       appBar: AppBar(
// // // // // // // // //         automaticallyImplyLeading: false,
// // // // // // // // //         title: const Text(
// // // // // // // // //           '',
// // // // // // // // //         ), // prevents overflow from unconstrained actions row
// // // // // // // // //         actions: [
// // // // // // // // //           if (state.history.isNotEmpty)
// // // // // // // // //             IconButton(
// // // // // // // // //               icon: const Icon(Icons.history_rounded),
// // // // // // // // //               tooltip: 'History',
// // // // // // // // //               onPressed: () => setState(() => _showHistory = true),
// // // // // // // // //             ),
// // // // // // // // //         ],
// // // // // // // // //       ),
// // // // // // // // //       body: SafeArea(
// // // // // // // // //         child: Column(
// // // // // // // // //           children: [
// // // // // // // // //             TodHud(state: state, game: game, displayNames: widget.displayNames),
// // // // // // // // //             Expanded(
// // // // // // // // //               child: AnimatedSwitcher(
// // // // // // // // //                 duration: const Duration(milliseconds: 300),
// // // // // // // // //                 transitionBuilder: (child, anim) => FadeTransition(
// // // // // // // // //                   opacity: anim,
// // // // // // // // //                   child: SlideTransition(
// // // // // // // // //                     position:
// // // // // // // // //                         Tween<Offset>(
// // // // // // // // //                           begin: const Offset(0, 0.05),
// // // // // // // // //                           end: Offset.zero,
// // // // // // // // //                         ).animate(
// // // // // // // // //                           CurvedAnimation(
// // // // // // // // //                             parent: anim,
// // // // // // // // //                             curve: Curves.easeOutCubic,
// // // // // // // // //                           ),
// // // // // // // // //                         ),
// // // // // // // // //                     child: child,
// // // // // // // // //                   ),
// // // // // // // // //                 ),
// // // // // // // // //                 child: KeyedSubtree(
// // // // // // // // //                   key: ValueKey('${state.phase}-${state.currentPlayerId}'),
// // // // // // // // //                   child: _phaseWidget(
// // // // // // // // //                     context,
// // // // // // // // //                     game,
// // // // // // // // //                     widget.displayNames,
// // // // // // // // //                     state,
// // // // // // // // //                   ),
// // // // // // // // //                 ),
// // // // // // // // //               ),
// // // // // // // // //             ),
// // // // // // // // //           ],
// // // // // // // // //         ),
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }

// // // // // // // // //   Widget _phaseWidget(
// // // // // // // // //     BuildContext ctx,
// // // // // // // // //     TodGameProvider game,
// // // // // // // // //     Map<String, String> displayNames,
// // // // // // // // //     TodState state,
// // // // // // // // //   ) {
// // // // // // // // //     return switch (state.phase) {
// // // // // // // // //       TodTurnPhase.punishmentVoting => TodPunishmentScreen(
// // // // // // // // //         state: state,
// // // // // // // // //         game: game,
// // // // // // // // //         displayNames: widget.displayNames,
// // // // // // // // //       ),
// // // // // // // // //       _ => TodCardScreen(
// // // // // // // // //         state: state,
// // // // // // // // //         game: game,
// // // // // // // // //         displayNames: widget.displayNames,
// // // // // // // // //       ),
// // // // // // // // //     };
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // // // ── History panel ─────────────────────────────────────────────────────────────

// // // // // // // // // class _HistoryPanel extends StatelessWidget {
// // // // // // // // //   const _HistoryPanel({required this.history, required this.displayNames});
// // // // // // // // //   final List<TodRoundRecord> history;
// // // // // // // // //   final Map<String, String> displayNames;

// // // // // // // // //   String _name(String id) =>
// // // // // // // // //       displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     final theme = context.theme;
// // // // // // // // //     if (history.isEmpty) {
// // // // // // // // //       return const Center(child: Text('No rounds completed yet.'));
// // // // // // // // //     }
// // // // // // // // //     return ListView.builder(
// // // // // // // // //       padding: const EdgeInsets.all(12),
// // // // // // // // //       itemCount: history.length,
// // // // // // // // //       itemBuilder: (_, i) {
// // // // // // // // //         final round = history[history.length - 1 - i]; // newest first
// // // // // // // // //         final reactTally = <String, int>{};
// // // // // // // // //         for (final r in round.reactions) {
// // // // // // // // //           reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
// // // // // // // // //         }
// // // // // // // // //         return Card(
// // // // // // // // //           margin: const EdgeInsets.only(bottom: 10),
// // // // // // // // //           child: ExpansionTile(
// // // // // // // // //             leading: CircleAvatar(
// // // // // // // // //               backgroundColor: theme.colorScheme.primaryContainer,
// // // // // // // // //               child: Text(
// // // // // // // // //                 '${round.roundNumber}',
// // // // // // // // //                 style: theme.textTheme.labelLarge,
// // // // // // // // //               ),
// // // // // // // // //             ),
// // // // // // // // //             title: Text(
// // // // // // // // //               _name(round.playerId),
// // // // // // // // //               style: theme.textTheme.bodyMedium?.copyWith(
// // // // // // // // //                 fontWeight: FontWeight.w700,
// // // // // // // // //               ),
// // // // // // // // //             ),
// // // // // // // // //             subtitle: Text(
// // // // // // // // //               round.card != null
// // // // // // // // //                   ? '${round.card!.type == TodCardType.truth ? "Truth" : "Dare"}: ${round.card!.content}'
// // // // // // // // //                   : 'Skipped',
// // // // // // // // //               maxLines: 1,
// // // // // // // // //               overflow: TextOverflow.ellipsis,
// // // // // // // // //               style: theme.textTheme.bodySmall,
// // // // // // // // //             ),
// // // // // // // // //             children: [
// // // // // // // // //               Padding(
// // // // // // // // //                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
// // // // // // // // //                 child: Column(
// // // // // // // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // //                   children: [
// // // // // // // // //                     // Card content
// // // // // // // // //                     if (round.card != null)
// // // // // // // // //                       Container(
// // // // // // // // //                         width: double.infinity,
// // // // // // // // //                         padding: const EdgeInsets.all(10),
// // // // // // // // //                         decoration: BoxDecoration(
// // // // // // // // //                           color: round.card!.type == TodCardType.truth
// // // // // // // // //                               ? Colors.blue.withOpacity(0.08)
// // // // // // // // //                               : Colors.orange.withOpacity(0.08),
// // // // // // // // //                           borderRadius: BorderRadius.circular(8),
// // // // // // // // //                         ),
// // // // // // // // //                         child: Text(
// // // // // // // // //                           round.card!.content,
// // // // // // // // //                           style: theme.textTheme.bodyMedium,
// // // // // // // // //                         ),
// // // // // // // // //                       ),
// // // // // // // // //                     // Response
// // // // // // // // //                     if (round.response.isNotEmpty) ...[
// // // // // // // // //                       const SizedBox(height: 8),
// // // // // // // // //                       Row(
// // // // // // // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // // //                         children: [
// // // // // // // // //                           const Text('💬 ', style: TextStyle(fontSize: 14)),
// // // // // // // // //                           Expanded(
// // // // // // // // //                             child: Text(
// // // // // // // // //                               '"${round.response}"',
// // // // // // // // //                               style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // //                                 fontStyle: FontStyle.italic,
// // // // // // // // //                               ),
// // // // // // // // //                             ),
// // // // // // // // //                           ),
// // // // // // // // //                         ],
// // // // // // // // //                       ),
// // // // // // // // //                     ],
// // // // // // // // //                     // Votes
// // // // // // // // //                     if (round.voteCount > 0) ...[
// // // // // // // // //                       const SizedBox(height: 6),
// // // // // // // // //                       Text(
// // // // // // // // //                         '👍 ${round.voteCount} vote${round.voteCount != 1 ? "s" : ""}',
// // // // // // // // //                         style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // // //                           color: theme.colorScheme.primary,
// // // // // // // // //                           fontWeight: FontWeight.w600,
// // // // // // // // //                         ),
// // // // // // // // //                       ),
// // // // // // // // //                     ],
// // // // // // // // //                     // Proof image
// // // // // // // // //                     if (round.proofImageB64.isNotEmpty) ...[
// // // // // // // // //                       const SizedBox(height: 8),
// // // // // // // // //                       _HistoryViewOnceImage(b64: round.proofImageB64),
// // // // // // // // //                     ],
// // // // // // // // //                     // Reactions
// // // // // // // // //                     if (reactTally.isNotEmpty) ...[
// // // // // // // // //                       const SizedBox(height: 8),
// // // // // // // // //                       Wrap(
// // // // // // // // //                         spacing: 6,
// // // // // // // // //                         runSpacing: 4,
// // // // // // // // //                         children: reactTally.entries
// // // // // // // // //                             .map(
// // // // // // // // //                               (e) => Container(
// // // // // // // // //                                 padding: const EdgeInsets.symmetric(
// // // // // // // // //                                   horizontal: 8,
// // // // // // // // //                                   vertical: 3,
// // // // // // // // //                                 ),
// // // // // // // // //                                 decoration: BoxDecoration(
// // // // // // // // //                                   color:
// // // // // // // // //                                       theme.colorScheme.surfaceContainerHighest,
// // // // // // // // //                                   borderRadius: BorderRadius.circular(16),
// // // // // // // // //                                 ),
// // // // // // // // //                                 child: Text(
// // // // // // // // //                                   '${e.key} ${e.value}',
// // // // // // // // //                                   style: const TextStyle(fontSize: 13),
// // // // // // // // //                                 ),
// // // // // // // // //                               ),
// // // // // // // // //                             )
// // // // // // // // //                             .toList(),
// // // // // // // // //                       ),
// // // // // // // // //                     ],
// // // // // // // // //                   ],
// // // // // // // // //                 ),
// // // // // // // // //               ),
// // // // // // // // //             ],
// // // // // // // // //           ),
// // // // // // // // //         );
// // // // // // // // //       },
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // // // View-once image for history (separate state per instance)
// // // // // // // // // class _HistoryViewOnceImage extends StatefulWidget {
// // // // // // // // //   const _HistoryViewOnceImage({required this.b64});
// // // // // // // // //   final String b64;
// // // // // // // // //   @override
// // // // // // // // //   State<_HistoryViewOnceImage> createState() => _HistoryViewOnceImageState();
// // // // // // // // // }

// // // // // // // // // class _HistoryViewOnceImageState extends State<_HistoryViewOnceImage> {
// // // // // // // // //   bool _revealed = false;
// // // // // // // // //   bool _viewed = false;
// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     if (_viewed) {
// // // // // // // // //       return Container(
// // // // // // // // //         height: 48,
// // // // // // // // //         alignment: Alignment.centerLeft,
// // // // // // // // //         child: Text(
// // // // // // // // //           '📷 Proof viewed',
// // // // // // // // //           style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
// // // // // // // // //         ),
// // // // // // // // //       );
// // // // // // // // //     }
// // // // // // // // //     if (!_revealed) {
// // // // // // // // //       return GestureDetector(
// // // // // // // // //         onTap: () => setState(() => _revealed = true),
// // // // // // // // //         child: Container(
// // // // // // // // //           height: 60,
// // // // // // // // //           decoration: BoxDecoration(
// // // // // // // // //             color: Colors.grey.shade200,
// // // // // // // // //             borderRadius: BorderRadius.circular(8),
// // // // // // // // //           ),
// // // // // // // // //           alignment: Alignment.center,
// // // // // // // // //           child: const Row(
// // // // // // // // //             mainAxisSize: MainAxisSize.min,
// // // // // // // // //             children: [
// // // // // // // // //               Icon(Icons.lock_outline, size: 16),
// // // // // // // // //               SizedBox(width: 6),
// // // // // // // // //               Text(
// // // // // // // // //                 'Tap to view proof photo (once)',
// // // // // // // // //                 style: TextStyle(fontSize: 12),
// // // // // // // // //               ),
// // // // // // // // //             ],
// // // // // // // // //           ),
// // // // // // // // //         ),
// // // // // // // // //       );
// // // // // // // // //     }
// // // // // // // // //     return GestureDetector(
// // // // // // // // //       onTap: () => setState(() => _viewed = true),
// // // // // // // // //       child: ClipRRect(
// // // // // // // // //         borderRadius: BorderRadius.circular(8),
// // // // // // // // //         child: Stack(
// // // // // // // // //           children: [
// // // // // // // // //             Image.memory(
// // // // // // // // //               base64Decode(widget.b64),
// // // // // // // // //               height: 160,
// // // // // // // // //               width: double.infinity,
// // // // // // // // //               fit: BoxFit.cover,
// // // // // // // // //             ),
// // // // // // // // //             Positioned(
// // // // // // // // //               bottom: 6,
// // // // // // // // //               right: 6,
// // // // // // // // //               child: Container(
// // // // // // // // //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // // // // // // // //                 decoration: BoxDecoration(
// // // // // // // // //                   color: Colors.black54,
// // // // // // // // //                   borderRadius: BorderRadius.circular(12),
// // // // // // // // //                 ),
// // // // // // // // //                 child: const Text(
// // // // // // // // //                   'Tap to dismiss',
// // // // // // // // //                   style: TextStyle(color: Colors.white, fontSize: 11),
// // // // // // // // //                 ),
// // // // // // // // //               ),
// // // // // // // // //             ),
// // // // // // // // //           ],
// // // // // // // // //         ),
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // import 'dart:async';
// // // // // // // // import 'dart:convert';

// // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // // // // // // import 'package:provider/provider.dart';
// // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // // // // // import '../../../../../core/di/service_locator.dart';
// // // // // // // // import '../../../../../core/extensions/context_ext.dart';
// // // // // // // // import '../../../../../core/providers/auth_provider.dart';
// // // // // // // // import '../../../../../core/router/route_names.dart';
// // // // // // // // import '../../../../../core/services/realtime_service.dart';
// // // // // // // // import '../../../../../core/theme/app_colors.dart';
// // // // // // // // import '../../../../../shared/widgets/feedback/error_view.dart';
// // // // // // // // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // // // // // // // // import '../../engine/base_game_engine.dart';
// // // // // // // // import '../../domain/tod_models.dart';
// // // // // // // // import '../../tod_game_provider.dart';

// // // // // // // // import '../../data/tod_repository.dart';
// // // // // // // // import 'tod_card_screen.dart';
// // // // // // // // import 'tod_end_screen.dart';
// // // // // // // // import 'tod_loading_screen.dart';
// // // // // // // // import 'tod_punishment_screen.dart';
// // // // // // // // import '../widgets/tod_hud.dart';

// // // // // // // // /// Entry point for an active Truth or Dare session.
// // // // // // // // ///
// // // // // // // // /// Responsibilities:
// // // // // // // // ///  - Owns and scopes TodGameProvider for this session
// // // // // // // // ///  - Wires RealtimeService callbacks → TodGameProvider
// // // // // // // // ///  - Routes between loading / error / active / game-over screens
// // // // // // // // ///  - Forwards game_state and player_action from the room Broadcast channel
// // // // // // // // class TodGameScreen extends StatefulWidget {
// // // // // // // //   const TodGameScreen({
// // // // // // // //     super.key,
// // // // // // // //     required this.roomId,
// // // // // // // //     required this.config,
// // // // // // // //     required this.playerIds,
// // // // // // // //     required this.playerDisplayNames,
// // // // // // // //     required this.packId,
// // // // // // // //     required this.isOwner,
// // // // // // // //     this.sessionId,
// // // // // // // //     this.isModerator = false,
// // // // // // // //     this.packCoverUrl,
// // // // // // // //   });

// // // // // // // //   final String roomId;
// // // // // // // //   final GameConfig config;
// // // // // // // //   final List<String> playerIds;
// // // // // // // //   final Map<String, String> playerDisplayNames; // userId → displayName
// // // // // // // //   final String packId;
// // // // // // // //   final bool isOwner;
// // // // // // // //   final String? sessionId;
// // // // // // // //   final bool isModerator;
// // // // // // // //   final String? packCoverUrl;

// // // // // // // //   @override
// // // // // // // //   State<TodGameScreen> createState() => _TodGameScreenState();
// // // // // // // // }

// // // // // // // // class _TodGameScreenState extends State<TodGameScreen> {
// // // // // // // //   late final TodGameProvider _provider;

// // // // // // // //   // Subscriptions to the room Broadcast channel
// // // // // // // //   // (channel already open by RoomProvider — we just register callbacks)
// // // // // // // //   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

// // // // // // // //   @override
// // // // // // // //   void initState() {
// // // // // // // //     super.initState();

// // // // // // // //     final auth = context.read<AuthProvider>();
// // // // // // // //     final user = auth.currentUser!;

// // // // // // // //     _provider = TodGameProvider(
// // // // // // // //       realtimeService: sl.realtimeService,
// // // // // // // //       repository: TodRepository.instance,
// // // // // // // //       currentUserId: user.id,
// // // // // // // //       currentDisplayName: user.displayName ?? user.username ?? 'Player',
// // // // // // // //       isModerator: widget.isModerator,
// // // // // // // //     );

// // // // // // // //     // ── Wire Broadcast callbacks ────────────────────────────────────────────
// // // // // // // //     // The room channel is already subscribed by RoomProvider/LobbyScreen.
// // // // // // // //     // TodGameScreen registers its own game-specific handlers for game_state
// // // // // // // //     // and player_action by re-subscribing with extended handlers.
// // // // // // // //     //
// // // // // // // //     // We do this by using the RealtimeService._bcast pattern:
// // // // // // // //     // The channel already has onGameState/onPlayerAction wired to no-ops
// // // // // // // //     // in RoomProvider. We replace them here by storing callbacks and
// // // // // // // //     // intercepting from the top-level channel via a dedicated subscription.
// // // // // // // //     _wireRealtimeCallbacks();

// // // // // // // //     if (widget.isOwner) {
// // // // // // // //       _provider.initAsOwner(
// // // // // // // //         roomId: widget.roomId,
// // // // // // // //         config: widget.config,
// // // // // // // //         playerIds: widget.playerIds,
// // // // // // // //         playerDisplayNames: widget.playerDisplayNames,
// // // // // // // //         packId: widget.packId,
// // // // // // // //         packCoverUrl: widget.packCoverUrl,
// // // // // // // //       );
// // // // // // // //     } else {
// // // // // // // //       _provider.initAsFollower(
// // // // // // // //         roomId: widget.roomId,
// // // // // // // //         config: widget.config,
// // // // // // // //         sessionId: widget.sessionId,
// // // // // // // //         packCoverUrl: widget.packCoverUrl,
// // // // // // // //       );
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   @override
// // // // // // // //   void dispose() {
// // // // // // // //     _statusSub?.cancel();
// // // // // // // //     _provider.dispose();
// // // // // // // //     super.dispose();
// // // // // // // //   }

// // // // // // // //   /// Wire game-specific callbacks into the existing room channel.
// // // // // // // //   ///
// // // // // // // //   /// Strategy: re-subscribe to the room channel with updated handlers that
// // // // // // // //   /// forward game_state and player_action to this provider.
// // // // // // // //   /// The channel is already open; we track callbacks via a thin interceptor.
// // // // // // // //   void _wireRealtimeCallbacks() {
// // // // // // // //     // Listen to channel status changes for reconnection awareness
// // // // // // // //     _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
// // // // // // // //       status,
// // // // // // // //     ) {
// // // // // // // //       if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // // // //           !_provider.hasSyncedState) {
// // // // // // // //         // Channel reconnected — request state sync
// // // // // // // //         sl.realtimeService.broadcastSyncRequest(
// // // // // // // //           widget.roomId,
// // // // // // // //           context.read<AuthProvider>().currentUser!.id,
// // // // // // // //           0,
// // // // // // // //         );
// // // // // // // //       }
// // // // // // // //     });

// // // // // // // //     // Re-subscribe with game handlers added.
// // // // // // // //     // This safely replaces the channel subscription with game callbacks.
// // // // // // // //     // (No-op handlers in RoomProvider are replaced with active ones here.)
// // // // // // // //     _resubscribeWithGameHandlers();
// // // // // // // //   }

// // // // // // // //   void _resubscribeWithGameHandlers() {
// // // // // // // //     final userId = context.read<AuthProvider>().currentUser!.id;

// // // // // // // //     // Unsubscribe existing channel and re-subscribe with game callbacks merged
// // // // // // // //     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
// // // // // // // //       sl.realtimeService.subscribe(
// // // // // // // //         roomId: widget.roomId,
// // // // // // // //         // ── Game-specific handlers ─────────────────────────────────────────
// // // // // // // //         onGameState: (p) => _provider.onStateBroadcast(p),
// // // // // // // //         onPlayerAction: (p) => _provider.onPlayerAction(p),
// // // // // // // //         onSyncRequest: (p) => _provider.onSyncRequest(p),
// // // // // // // //         onGameStarted: (_) {},
// // // // // // // //         onGameEnded: (_) {},
// // // // // // // //         // ── Room lifecycle (passthrough — RoomProvider is disposed) ─────────
// // // // // // // //         onRoomEvent: (_) {},
// // // // // // // //         onChatMessage: (_) {},
// // // // // // // //         onModeration: (p) => _handleModerationEvent(p),
// // // // // // // //         onSettingsChange: (_) {},
// // // // // // // //         // ── Presence ──────────────────────────────────────────────────────
// // // // // // // //         onPresenceSync: (_) {},
// // // // // // // //         onPresenceJoin: (_) {},
// // // // // // // //         onPresenceLeave: (_) {},
// // // // // // // //         onStatusChange: (status) {
// // // // // // // //           if (!mounted) return;
// // // // // // // //           if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // // // //               !_provider.hasSyncedState) {
// // // // // // // //             sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
// // // // // // // //           }
// // // // // // // //         },
// // // // // // // //       );
// // // // // // // //     });
// // // // // // // //   }

// // // // // // // //   void _handleModerationEvent(Map<String, dynamic> p) {
// // // // // // // //     final type = p['type'] as String?;
// // // // // // // //     final targetId = p['target_user_id'] as String?;
// // // // // // // //     final currentId = context.read<AuthProvider>().currentUser?.id;

// // // // // // // //     // If kicked or banned, navigate back to lobby
// // // // // // // //     if ((type == 'kick' || type == 'ban') && targetId == currentId) {
// // // // // // // //       if (mounted) {
// // // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // // //           const SnackBar(content: Text('You were removed from the room')),
// // // // // // // //         );
// // // // // // // //         context.go(RouteNames.home);
// // // // // // // //       }
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     return ChangeNotifierProvider.value(
// // // // // // // //       value: _provider,
// // // // // // // //       child: Consumer<TodGameProvider>(
// // // // // // // //         builder: (ctx, game, _) => _build(ctx, game),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }

// // // // // // // //   Widget _build(BuildContext ctx, TodGameProvider game) {
// // // // // // // //     if (game.loadState == TodLoadState.loading) {
// // // // // // // //       return const TodLoadingScreen();
// // // // // // // //     }

// // // // // // // //     if (game.loadState == TodLoadState.error) {
// // // // // // // //       return Scaffold(
// // // // // // // //         appBar: AppBar(
// // // // // // // //           leading: BackButton(onPressed: () => ctx.go(RouteNames.home)),
// // // // // // // //         ),
// // // // // // // //         body: ErrorView(
// // // // // // // //           message: game.error ?? 'Failed to load game',
// // // // // // // //           onRetry: () => ctx.go(RouteNames.home),
// // // // // // // //         ),
// // // // // // // //       );
// // // // // // // //     }

// // // // // // // //     if (game.loadState == TodLoadState.gameOver ||
// // // // // // // //         (game.state?.isOver ?? false)) {
// // // // // // // //       return TodEndScreen(
// // // // // // // //         state: game.state!,
// // // // // // // //         displayNames: widget.playerDisplayNames,
// // // // // // // //         onLeave: () => ctx.go(RouteNames.home),
// // // // // // // //       );
// // // // // // // //     }

// // // // // // // //     final state = game.state;
// // // // // // // //     if (state == null) return const TodLoadingScreen();

// // // // // // // //     return _TodGameScaffold(
// // // // // // // //       state: state,
// // // // // // // //       game: game,
// // // // // // // //       displayNames: widget.playerDisplayNames,
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // // ── Scaffold with history support ─────────────────────────────────────────────

// // // // // // // // class _TodGameScaffold extends StatefulWidget {
// // // // // // // //   const _TodGameScaffold({
// // // // // // // //     required this.state,
// // // // // // // //     required this.game,
// // // // // // // //     required this.displayNames,
// // // // // // // //   });
// // // // // // // //   final TodState state;
// // // // // // // //   final TodGameProvider game;
// // // // // // // //   final Map<String, String> displayNames;
// // // // // // // //   @override
// // // // // // // //   State<_TodGameScaffold> createState() => _TodGameScaffoldState();
// // // // // // // // }

// // // // // // // // class _TodGameScaffoldState extends State<_TodGameScaffold> {
// // // // // // // //   bool _showHistory = false;
// // // // // // // //   bool _showChat = false;
// // // // // // // //   int _unreadChat = 0;

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     final state = widget.state;
// // // // // // // //     final game = widget.game;

// // // // // // // //     if (_showHistory) {
// // // // // // // //       return Scaffold(
// // // // // // // //         appBar: AppBar(
// // // // // // // //           leading: BackButton(
// // // // // // // //             onPressed: () => setState(() => _showHistory = false),
// // // // // // // //           ),
// // // // // // // //           title: Text('History (${state.history.length} rounds)'),
// // // // // // // //         ),
// // // // // // // //         body: _HistoryPanel(
// // // // // // // //           history: state.history,
// // // // // // // //           displayNames: widget.displayNames,
// // // // // // // //         ),
// // // // // // // //       );
// // // // // // // //     }

// // // // // // // //     return Scaffold(
// // // // // // // //       appBar: AppBar(
// // // // // // // //         automaticallyImplyLeading: false,
// // // // // // // //         title: const Text(
// // // // // // // //           '',
// // // // // // // //         ), // prevents overflow from unconstrained actions row
// // // // // // // //         actions: [
// // // // // // // //           if (state.history.isNotEmpty)
// // // // // // // //             IconButton(
// // // // // // // //               icon: const Icon(Icons.history_rounded),
// // // // // // // //               tooltip: 'History',
// // // // // // // //               onPressed: () => setState(() => _showHistory = true),
// // // // // // // //             ),
// // // // // // // //         ],
// // // // // // // //       ),
// // // // // // // //       body: SafeArea(
// // // // // // // //         child: Column(
// // // // // // // //           children: [
// // // // // // // //             TodHud(state: state, game: game, displayNames: widget.displayNames),
// // // // // // // //             Expanded(
// // // // // // // //               child: AnimatedSwitcher(
// // // // // // // //                 duration: const Duration(milliseconds: 300),
// // // // // // // //                 transitionBuilder: (child, anim) => FadeTransition(
// // // // // // // //                   opacity: anim,
// // // // // // // //                   child: SlideTransition(
// // // // // // // //                     position:
// // // // // // // //                         Tween<Offset>(
// // // // // // // //                           begin: const Offset(0, 0.05),
// // // // // // // //                           end: Offset.zero,
// // // // // // // //                         ).animate(
// // // // // // // //                           CurvedAnimation(
// // // // // // // //                             parent: anim,
// // // // // // // //                             curve: Curves.easeOutCubic,
// // // // // // // //                           ),
// // // // // // // //                         ),
// // // // // // // //                     child: child,
// // // // // // // //                   ),
// // // // // // // //                 ),
// // // // // // // //                 child: KeyedSubtree(
// // // // // // // //                   key: ValueKey('${state.phase}-${state.currentPlayerId}'),
// // // // // // // //                   child: _phaseWidget(
// // // // // // // //                     context,
// // // // // // // //                     game,
// // // // // // // //                     widget.displayNames,
// // // // // // // //                     state,
// // // // // // // //                   ),
// // // // // // // //                 ),
// // // // // // // //               ),
// // // // // // // //             ),
// // // // // // // //           ],
// // // // // // // //         ),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }

// // // // // // // //   Widget _phaseWidget(
// // // // // // // //     BuildContext ctx,
// // // // // // // //     TodGameProvider game,
// // // // // // // //     Map<String, String> displayNames,
// // // // // // // //     TodState state,
// // // // // // // //   ) {
// // // // // // // //     return switch (state.phase) {
// // // // // // // //       TodTurnPhase.punishmentVoting => TodPunishmentScreen(
// // // // // // // //         state: state,
// // // // // // // //         game: game,
// // // // // // // //         displayNames: widget.displayNames,
// // // // // // // //       ),
// // // // // // // //       _ => TodCardScreen(
// // // // // // // //         state: state,
// // // // // // // //         game: game,
// // // // // // // //         displayNames: widget.displayNames,
// // // // // // // //       ),
// // // // // // // //     };
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // // ── History panel ─────────────────────────────────────────────────────────────

// // // // // // // // class _HistoryPanel extends StatelessWidget {
// // // // // // // //   const _HistoryPanel({required this.history, required this.displayNames});
// // // // // // // //   final List<TodRoundRecord> history;
// // // // // // // //   final Map<String, String> displayNames;

// // // // // // // //   String _name(String id) =>
// // // // // // // //       displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     final theme = context.theme;
// // // // // // // //     if (history.isEmpty) {
// // // // // // // //       return const Center(child: Text('No rounds completed yet.'));
// // // // // // // //     }
// // // // // // // //     return ListView.builder(
// // // // // // // //       padding: const EdgeInsets.all(12),
// // // // // // // //       itemCount: history.length,
// // // // // // // //       itemBuilder: (_, i) {
// // // // // // // //         final round = history[history.length - 1 - i]; // newest first
// // // // // // // //         final reactTally = <String, int>{};
// // // // // // // //         for (final r in round.reactions) {
// // // // // // // //           reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
// // // // // // // //         }
// // // // // // // //         return Card(
// // // // // // // //           margin: const EdgeInsets.only(bottom: 10),
// // // // // // // //           child: ExpansionTile(
// // // // // // // //             leading: CircleAvatar(
// // // // // // // //               backgroundColor: theme.colorScheme.primaryContainer,
// // // // // // // //               child: Text(
// // // // // // // //                 '${round.roundNumber}',
// // // // // // // //                 style: theme.textTheme.labelLarge,
// // // // // // // //               ),
// // // // // // // //             ),
// // // // // // // //             title: Text(
// // // // // // // //               _name(round.playerId),
// // // // // // // //               style: theme.textTheme.bodyMedium?.copyWith(
// // // // // // // //                 fontWeight: FontWeight.w700,
// // // // // // // //               ),
// // // // // // // //             ),
// // // // // // // //             subtitle: Text(
// // // // // // // //               round.card != null
// // // // // // // //                   ? '${round.card!.type == TodCardType.truth ? "Truth" : "Dare"}: ${round.card!.content}'
// // // // // // // //                   : 'Skipped',
// // // // // // // //               maxLines: 1,
// // // // // // // //               overflow: TextOverflow.ellipsis,
// // // // // // // //               style: theme.textTheme.bodySmall,
// // // // // // // //             ),
// // // // // // // //             children: [
// // // // // // // //               Padding(
// // // // // // // //                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
// // // // // // // //                 child: Column(
// // // // // // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // //                   children: [
// // // // // // // //                     // Card content
// // // // // // // //                     if (round.card != null)
// // // // // // // //                       Container(
// // // // // // // //                         width: double.infinity,
// // // // // // // //                         padding: const EdgeInsets.all(10),
// // // // // // // //                         decoration: BoxDecoration(
// // // // // // // //                           color: round.card!.type == TodCardType.truth
// // // // // // // //                               ? Colors.blue.withOpacity(0.08)
// // // // // // // //                               : Colors.orange.withOpacity(0.08),
// // // // // // // //                           borderRadius: BorderRadius.circular(8),
// // // // // // // //                         ),
// // // // // // // //                         child: Text(
// // // // // // // //                           round.card!.content,
// // // // // // // //                           style: theme.textTheme.bodyMedium,
// // // // // // // //                         ),
// // // // // // // //                       ),
// // // // // // // //                     // Response
// // // // // // // //                     if (round.response.isNotEmpty) ...[
// // // // // // // //                       const SizedBox(height: 8),
// // // // // // // //                       Row(
// // // // // // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // // //                         children: [
// // // // // // // //                           const Text('💬 ', style: TextStyle(fontSize: 14)),
// // // // // // // //                           Expanded(
// // // // // // // //                             child: Text(
// // // // // // // //                               '"${round.response}"',
// // // // // // // //                               style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // //                                 fontStyle: FontStyle.italic,
// // // // // // // //                               ),
// // // // // // // //                             ),
// // // // // // // //                           ),
// // // // // // // //                         ],
// // // // // // // //                       ),
// // // // // // // //                     ],
// // // // // // // //                     // Votes
// // // // // // // //                     if (round.voteCount > 0) ...[
// // // // // // // //                       const SizedBox(height: 6),
// // // // // // // //                       Text(
// // // // // // // //                         '👍 ${round.voteCount} vote${round.voteCount != 1 ? "s" : ""}',
// // // // // // // //                         style: theme.textTheme.bodySmall?.copyWith(
// // // // // // // //                           color: theme.colorScheme.primary,
// // // // // // // //                           fontWeight: FontWeight.w600,
// // // // // // // //                         ),
// // // // // // // //                       ),
// // // // // // // //                     ],
// // // // // // // //                     // Proof image
// // // // // // // //                     if (round.proofImageB64.isNotEmpty) ...[
// // // // // // // //                       const SizedBox(height: 8),
// // // // // // // //                       _HistoryViewOnceImage(b64: round.proofImageB64),
// // // // // // // //                     ],
// // // // // // // //                     // Reactions
// // // // // // // //                     if (reactTally.isNotEmpty) ...[
// // // // // // // //                       const SizedBox(height: 8),
// // // // // // // //                       Wrap(
// // // // // // // //                         spacing: 6,
// // // // // // // //                         runSpacing: 4,
// // // // // // // //                         children: reactTally.entries
// // // // // // // //                             .map(
// // // // // // // //                               (e) => Container(
// // // // // // // //                                 padding: const EdgeInsets.symmetric(
// // // // // // // //                                   horizontal: 8,
// // // // // // // //                                   vertical: 3,
// // // // // // // //                                 ),
// // // // // // // //                                 decoration: BoxDecoration(
// // // // // // // //                                   color:
// // // // // // // //                                       theme.colorScheme.surfaceContainerHighest,
// // // // // // // //                                   borderRadius: BorderRadius.circular(16),
// // // // // // // //                                 ),
// // // // // // // //                                 child: Text(
// // // // // // // //                                   '${e.key} ${e.value}',
// // // // // // // //                                   style: const TextStyle(fontSize: 13),
// // // // // // // //                                 ),
// // // // // // // //                               ),
// // // // // // // //                             )
// // // // // // // //                             .toList(),
// // // // // // // //                       ),
// // // // // // // //                     ],
// // // // // // // //                   ],
// // // // // // // //                 ),
// // // // // // // //               ),
// // // // // // // //             ],
// // // // // // // //           ),
// // // // // // // //         );
// // // // // // // //       },
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // // View-once image for history (separate state per instance)
// // // // // // // // class _HistoryViewOnceImage extends StatefulWidget {
// // // // // // // //   const _HistoryViewOnceImage({required this.b64});
// // // // // // // //   final String b64;
// // // // // // // //   @override
// // // // // // // //   State<_HistoryViewOnceImage> createState() => _HistoryViewOnceImageState();
// // // // // // // // }

// // // // // // // // class _HistoryViewOnceImageState extends State<_HistoryViewOnceImage> {
// // // // // // // //   bool _revealed = false;
// // // // // // // //   bool _viewed = false;
// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     if (_viewed) {
// // // // // // // //       return Container(
// // // // // // // //         height: 48,
// // // // // // // //         alignment: Alignment.centerLeft,
// // // // // // // //         child: Text(
// // // // // // // //           '📷 Proof viewed',
// // // // // // // //           style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
// // // // // // // //         ),
// // // // // // // //       );
// // // // // // // //     }
// // // // // // // //     if (!_revealed) {
// // // // // // // //       return GestureDetector(
// // // // // // // //         onTap: () => setState(() => _revealed = true),
// // // // // // // //         child: Container(
// // // // // // // //           height: 60,
// // // // // // // //           decoration: BoxDecoration(
// // // // // // // //             color: Colors.grey.shade200,
// // // // // // // //             borderRadius: BorderRadius.circular(8),
// // // // // // // //           ),
// // // // // // // //           alignment: Alignment.center,
// // // // // // // //           child: const Row(
// // // // // // // //             mainAxisSize: MainAxisSize.min,
// // // // // // // //             children: [
// // // // // // // //               Icon(Icons.lock_outline, size: 16),
// // // // // // // //               SizedBox(width: 6),
// // // // // // // //               Text(
// // // // // // // //                 'Tap to view proof photo (once)',
// // // // // // // //                 style: TextStyle(fontSize: 12),
// // // // // // // //               ),
// // // // // // // //             ],
// // // // // // // //           ),
// // // // // // // //         ),
// // // // // // // //       );
// // // // // // // //     }
// // // // // // // //     return GestureDetector(
// // // // // // // //       onTap: () => setState(() => _viewed = true),
// // // // // // // //       child: ClipRRect(
// // // // // // // //         borderRadius: BorderRadius.circular(8),
// // // // // // // //         child: Stack(
// // // // // // // //           children: [
// // // // // // // //             Image.memory(
// // // // // // // //               base64Decode(widget.b64),
// // // // // // // //               height: 160,
// // // // // // // //               width: double.infinity,
// // // // // // // //               fit: BoxFit.cover,
// // // // // // // //             ),
// // // // // // // //             Positioned(
// // // // // // // //               bottom: 6,
// // // // // // // //               right: 6,
// // // // // // // //               child: Container(
// // // // // // // //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // // // // // // //                 decoration: BoxDecoration(
// // // // // // // //                   color: Colors.black54,
// // // // // // // //                   borderRadius: BorderRadius.circular(12),
// // // // // // // //                 ),
// // // // // // // //                 child: const Text(
// // // // // // // //                   'Tap to dismiss',
// // // // // // // //                   style: TextStyle(color: Colors.white, fontSize: 11),
// // // // // // // //                 ),
// // // // // // // //               ),
// // // // // // // //             ),
// // // // // // // //           ],
// // // // // // // //         ),
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // import 'dart:async';
// // // // // // // import 'dart:convert';

// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // // // // // import 'package:jma3a/features/rooms/domain/room_entity.dart';
// // // // // // // import 'package:provider/provider.dart';
// // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // // // // import '../../../../../core/di/service_locator.dart';
// // // // // // // import '../../../../../core/extensions/context_ext.dart';
// // // // // // // import '../../../../../core/providers/auth_provider.dart';
// // // // // // // import '../../../../../core/router/route_names.dart';
// // // // // // // import '../../../../../core/services/realtime_service.dart';
// // // // // // // import '../../../../../core/theme/app_colors.dart';
// // // // // // // import '../../../../../shared/widgets/feedback/error_view.dart';
// // // // // // // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // // // // // // // import '../../engine/base_game_engine.dart';
// // // // // // // import '../../domain/tod_models.dart';
// // // // // // // import '../../tod_game_provider.dart';

// // // // // // // import '../../data/tod_repository.dart';
// // // // // // // import 'tod_card_screen.dart';
// // // // // // // import 'tod_end_screen.dart';
// // // // // // // import 'tod_loading_screen.dart';
// // // // // // // import 'tod_punishment_screen.dart';
// // // // // // // import '../widgets/tod_hud.dart';

// // // // // // // /// Entry point for an active Truth or Dare session.
// // // // // // // ///
// // // // // // // /// Responsibilities:
// // // // // // // ///  - Owns and scopes TodGameProvider for this session
// // // // // // // ///  - Wires RealtimeService callbacks → TodGameProvider
// // // // // // // ///  - Routes between loading / error / active / game-over screens
// // // // // // // ///  - Forwards game_state and player_action from the room Broadcast channel
// // // // // // // class TodGameScreen extends StatefulWidget {
// // // // // // //   const TodGameScreen({
// // // // // // //     super.key,
// // // // // // //     required this.roomId,
// // // // // // //     required this.config,
// // // // // // //     required this.playerIds,
// // // // // // //     required this.playerDisplayNames,
// // // // // // //     required this.packId,
// // // // // // //     required this.isOwner,
// // // // // // //     this.sessionId,
// // // // // // //     this.isModerator = false,
// // // // // // //     this.packCoverUrl,
// // // // // // //   });

// // // // // // //   final String roomId;
// // // // // // //   final GameConfig config;
// // // // // // //   final List<String> playerIds;
// // // // // // //   final Map<String, String> playerDisplayNames; // userId → displayName
// // // // // // //   final String packId;
// // // // // // //   final bool isOwner;
// // // // // // //   final String? sessionId;
// // // // // // //   final bool isModerator;
// // // // // // //   final String? packCoverUrl;

// // // // // // //   @override
// // // // // // //   State<TodGameScreen> createState() => _TodGameScreenState();
// // // // // // // }

// // // // // // // class _TodGameScreenState extends State<TodGameScreen> {
// // // // // // //   late final TodGameProvider _provider;

// // // // // // //   // Subscriptions to the room Broadcast channel
// // // // // // //   // (channel already open by RoomProvider — we just register callbacks)
// // // // // // //   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

// // // // // // //   @override
// // // // // // //   void initState() {
// // // // // // //     super.initState();

// // // // // // //     final auth = context.read<AuthProvider>();
// // // // // // //     final user = auth.currentUser!;

// // // // // // //     _provider = TodGameProvider(
// // // // // // //       realtimeService: sl.realtimeService,
// // // // // // //       repository: TodRepository.instance,
// // // // // // //       currentUserId: user.id,
// // // // // // //       currentDisplayName: user.displayName ?? user.username ?? 'Player',
// // // // // // //       isModerator: widget.isModerator,
// // // // // // //     );

// // // // // // //     // ── Wire Broadcast callbacks ────────────────────────────────────────────
// // // // // // //     // The room channel is already subscribed by RoomProvider/LobbyScreen.
// // // // // // //     // TodGameScreen registers its own game-specific handlers for game_state
// // // // // // //     // and player_action by re-subscribing with extended handlers.
// // // // // // //     //
// // // // // // //     // We do this by using the RealtimeService._bcast pattern:
// // // // // // //     // The channel already has onGameState/onPlayerAction wired to no-ops
// // // // // // //     // in RoomProvider. We replace them here by storing callbacks and
// // // // // // //     // intercepting from the top-level channel via a dedicated subscription.
// // // // // // //     _wireRealtimeCallbacks();

// // // // // // //     if (widget.isOwner) {
// // // // // // //       _provider.initAsOwner(
// // // // // // //         roomId: widget.roomId,
// // // // // // //         config: widget.config,
// // // // // // //         playerIds: widget.playerIds,
// // // // // // //         playerDisplayNames: widget.playerDisplayNames,
// // // // // // //         packId: widget.packId,
// // // // // // //         packCoverUrl: widget.packCoverUrl,
// // // // // // //       );
// // // // // // //     } else {
// // // // // // //       _provider.initAsFollower(
// // // // // // //         roomId: widget.roomId,
// // // // // // //         config: widget.config,
// // // // // // //         sessionId: widget.sessionId,
// // // // // // //         packCoverUrl: widget.packCoverUrl,
// // // // // // //       );
// // // // // // //     }
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   void dispose() {
// // // // // // //     _statusSub?.cancel();
// // // // // // //     _provider.dispose();
// // // // // // //     super.dispose();
// // // // // // //   }

// // // // // // //   /// Wire game-specific callbacks into the existing room channel.
// // // // // // //   ///
// // // // // // //   /// Strategy: re-subscribe to the room channel with updated handlers that
// // // // // // //   /// forward game_state and player_action to this provider.
// // // // // // //   /// The channel is already open; we track callbacks via a thin interceptor.
// // // // // // //   void _wireRealtimeCallbacks() {
// // // // // // //     // Listen to channel status changes for reconnection awareness
// // // // // // //     _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
// // // // // // //       status,
// // // // // // //     ) {
// // // // // // //       if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // // //           !_provider.hasSyncedState) {
// // // // // // //         // Channel reconnected — request state sync
// // // // // // //         sl.realtimeService.broadcastSyncRequest(
// // // // // // //           widget.roomId,
// // // // // // //           context.read<AuthProvider>().currentUser!.id,
// // // // // // //           0,
// // // // // // //         );
// // // // // // //       }
// // // // // // //     });

// // // // // // //     // Re-subscribe with game handlers added.
// // // // // // //     // This safely replaces the channel subscription with game callbacks.
// // // // // // //     // (No-op handlers in RoomProvider are replaced with active ones here.)
// // // // // // //     _resubscribeWithGameHandlers();
// // // // // // //   }

// // // // // // //   void _resubscribeWithGameHandlers() {
// // // // // // //     final userId = context.read<AuthProvider>().currentUser!.id;

// // // // // // //     // Unsubscribe existing channel and re-subscribe with game callbacks merged
// // // // // // //     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
// // // // // // //       sl.realtimeService.subscribe(
// // // // // // //         roomId: widget.roomId,
// // // // // // //         // ── Game-specific handlers ─────────────────────────────────────────
// // // // // // //         onGameState: (p) => _provider.onStateBroadcast(p),
// // // // // // //         onPlayerAction: (p) => _provider.onPlayerAction(p),
// // // // // // //         onSyncRequest: (p) => _provider.onSyncRequest(p),
// // // // // // //         onGameStarted: (_) {},
// // // // // // //         onGameEnded: (p) {
// // // // // // //           // Admin ended the game — take everyone back to the lobby
// // // // // // //           if (mounted) {
// // // // // // //             ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //               const SnackBar(content: Text('The host ended the game')),
// // // // // // //             );
// // // // // // //             // Pop back to lobby (the LobbyScreen is still on the stack)
// // // // // // //             if (context.canPop())
// // // // // // //               context.pop();
// // // // // // //             else
// // // // // // //               context.go(RouteNames.home);
// // // // // // //           }
// // // // // // //         },
// // // // // // //         // ── Room lifecycle (passthrough — RoomProvider is disposed) ─────────
// // // // // // //         onRoomEvent: (p) {
// // // // // // //           final type = p['type'] as String?;
// // // // // // //           if (type == 'room_closed' && mounted) {
// // // // // // //             ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //               const SnackBar(content: Text('The room was closed by the host')),
// // // // // // //             );
// // // // // // //             context.go(RouteNames.home);
// // // // // // //           }
// // // // // // //         },
// // // // // // //         onChatMessage: (_) {},
// // // // // // //         onModeration: (p) => _handleModerationEvent(p),
// // // // // // //         onSettingsChange: (_) {},
// // // // // // //         // ── Presence ──────────────────────────────────────────────────────
// // // // // // //         onPresenceSync: (_) {},
// // // // // // //         onPresenceJoin: (_) {},
// // // // // // //         onPresenceLeave: (_) {},
// // // // // // //         onStatusChange: (status) {
// // // // // // //           if (!mounted) return;
// // // // // // //           if (status == RealtimeSubscribeStatus.subscribed &&
// // // // // // //               !_provider.hasSyncedState) {
// // // // // // //             sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
// // // // // // //           }
// // // // // // //         },
// // // // // // //       );
// // // // // // //     });
// // // // // // //   }

// // // // // // //   void _handleModerationEvent(Map<String, dynamic> p) {
// // // // // // //     final type = p['type'] as String?;
// // // // // // //     final targetId = p['target_user_id'] as String?;
// // // // // // //     final currentId = context.read<AuthProvider>().currentUser?.id;

// // // // // // //     // If kicked or banned, navigate back to lobby
// // // // // // //     if ((type == 'kick' || type == 'ban') && targetId == currentId) {
// // // // // // //       if (mounted) {
// // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //           const SnackBar(content: Text('You were removed from the room')),
// // // // // // //         );
// // // // // // //         context.go(RouteNames.home);
// // // // // // //       }
// // // // // // //     }
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     return ChangeNotifierProvider.value(
// // // // // // //       value: _provider,
// // // // // // //       child: Consumer<TodGameProvider>(
// // // // // // //         builder: (ctx, game, _) => _build(ctx, game),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }

// // // // // // //   Widget _build(BuildContext ctx, TodGameProvider game) {
// // // // // // //     if (game.loadState == TodLoadState.loading) {
// // // // // // //       return const TodLoadingScreen();
// // // // // // //     }

// // // // // // //     if (game.loadState == TodLoadState.error) {
// // // // // // //       return Scaffold(
// // // // // // //         appBar: AppBar(
// // // // // // //           leading: BackButton(
// // // // // // //             onPressed: () async {
// // // // // // //               if (widget.isOwner) {
// // // // // // //                 // Owner leaving game → end game for everyone, go back to lobby
// // // // // // //                 try {
// // // // // // //                   await sl.realtimeService.broadcastGameEnded(widget.roomId, {
// // // // // // //                     'reason': 'host_left',
// // // // // // //                   });
// // // // // // //                   await sl.roomRepository.updateStatus(
// // // // // // //                     widget.roomId,
// // // // // // //                     RoomStatus.waiting,
// // // // // // //                   );
// // // // // // //                 } catch (_) {}
// // // // // // //               }
// // // // // // //               if (ctx.mounted) ctx.go(RouteNames.home);
// // // // // // //             },
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //         body: ErrorView(
// // // // // // //           message: game.error ?? 'Failed to load game',
// // // // // // //           onRetry: () => ctx.go(RouteNames.home),
// // // // // // //         ),
// // // // // // //       );
// // // // // // //     }

// // // // // // //     if (game.loadState == TodLoadState.gameOver ||
// // // // // // //         (game.state?.isOver ?? false)) {
// // // // // // //       return TodEndScreen(
// // // // // // //         state: game.state!,
// // // // // // //         displayNames: widget.playerDisplayNames,
// // // // // // //         onLeave: () => ctx.go(RouteNames.home),
// // // // // // //       );
// // // // // // //     }

// // // // // // //     final state = game.state;
// // // // // // //     if (state == null) return const TodLoadingScreen();

// // // // // // //     return _TodGameScaffold(
// // // // // // //       state: state,
// // // // // // //       game: game,
// // // // // // //       displayNames: widget.playerDisplayNames,
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // // ── Scaffold with history support ─────────────────────────────────────────────

// // // // // // // class _TodGameScaffold extends StatefulWidget {
// // // // // // //   const _TodGameScaffold({
// // // // // // //     required this.state,
// // // // // // //     required this.game,
// // // // // // //     required this.displayNames,
// // // // // // //   });
// // // // // // //   final TodState state;
// // // // // // //   final TodGameProvider game;
// // // // // // //   final Map<String, String> displayNames;
// // // // // // //   @override
// // // // // // //   State<_TodGameScaffold> createState() => _TodGameScaffoldState();
// // // // // // // }

// // // // // // // class _TodGameScaffoldState extends State<_TodGameScaffold> {
// // // // // // //   bool _showHistory = false;
// // // // // // //   bool _showChat = false;
// // // // // // //   int _unreadChat = 0;

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     final state = widget.state;
// // // // // // //     final game = widget.game;

// // // // // // //     if (_showHistory) {
// // // // // // //       return Scaffold(
// // // // // // //         appBar: AppBar(
// // // // // // //           leading: BackButton(
// // // // // // //             onPressed: () => setState(() => _showHistory = false),
// // // // // // //           ),
// // // // // // //           title: Text('History (${state.history.length} rounds)'),
// // // // // // //         ),
// // // // // // //         body: _HistoryPanel(
// // // // // // //           history: state.history,
// // // // // // //           displayNames: widget.displayNames,
// // // // // // //         ),
// // // // // // //       );
// // // // // // //     }

// // // // // // //     return Scaffold(
// // // // // // //       appBar: AppBar(
// // // // // // //         automaticallyImplyLeading: false,
// // // // // // //         title: const Text(
// // // // // // //           '',
// // // // // // //         ), // prevents overflow from unconstrained actions row
// // // // // // //         actions: [
// // // // // // //           if (state.history.isNotEmpty)
// // // // // // //             IconButton(
// // // // // // //               icon: const Icon(Icons.history_rounded),
// // // // // // //               tooltip: 'History',
// // // // // // //               onPressed: () => setState(() => _showHistory = true),
// // // // // // //             ),
// // // // // // //         ],
// // // // // // //       ),
// // // // // // //       body: SafeArea(
// // // // // // //         child: Column(
// // // // // // //           children: [
// // // // // // //             TodHud(state: state, game: game, displayNames: widget.displayNames),
// // // // // // //             Expanded(
// // // // // // //               child: AnimatedSwitcher(
// // // // // // //                 duration: const Duration(milliseconds: 300),
// // // // // // //                 transitionBuilder: (child, anim) => FadeTransition(
// // // // // // //                   opacity: anim,
// // // // // // //                   child: SlideTransition(
// // // // // // //                     position:
// // // // // // //                         Tween<Offset>(
// // // // // // //                           begin: const Offset(0, 0.05),
// // // // // // //                           end: Offset.zero,
// // // // // // //                         ).animate(
// // // // // // //                           CurvedAnimation(
// // // // // // //                             parent: anim,
// // // // // // //                             curve: Curves.easeOutCubic,
// // // // // // //                           ),
// // // // // // //                         ),
// // // // // // //                     child: child,
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //                 child: KeyedSubtree(
// // // // // // //                   key: ValueKey('${state.phase}-${state.currentPlayerId}'),
// // // // // // //                   child: _phaseWidget(
// // // // // // //                     context,
// // // // // // //                     game,
// // // // // // //                     widget.displayNames,
// // // // // // //                     state,
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //           ],
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }

// // // // // // //   Widget _phaseWidget(
// // // // // // //     BuildContext ctx,
// // // // // // //     TodGameProvider game,
// // // // // // //     Map<String, String> displayNames,
// // // // // // //     TodState state,
// // // // // // //   ) {
// // // // // // //     return switch (state.phase) {
// // // // // // //       TodTurnPhase.punishmentVoting => TodPunishmentScreen(
// // // // // // //         state: state,
// // // // // // //         game: game,
// // // // // // //         displayNames: widget.displayNames,
// // // // // // //       ),
// // // // // // //       _ => TodCardScreen(
// // // // // // //         state: state,
// // // // // // //         game: game,
// // // // // // //         displayNames: widget.displayNames,
// // // // // // //       ),
// // // // // // //     };
// // // // // // //   }
// // // // // // // }

// // // // // // // // ── History panel ─────────────────────────────────────────────────────────────

// // // // // // // class _HistoryPanel extends StatelessWidget {
// // // // // // //   const _HistoryPanel({required this.history, required this.displayNames});
// // // // // // //   final List<TodRoundRecord> history;
// // // // // // //   final Map<String, String> displayNames;

// // // // // // //   String _name(String id) =>
// // // // // // //       displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     final theme = context.theme;
// // // // // // //     if (history.isEmpty) {
// // // // // // //       return const Center(child: Text('No rounds completed yet.'));
// // // // // // //     }
// // // // // // //     return ListView.builder(
// // // // // // //       padding: const EdgeInsets.all(12),
// // // // // // //       itemCount: history.length,
// // // // // // //       itemBuilder: (_, i) {
// // // // // // //         final round = history[history.length - 1 - i]; // newest first
// // // // // // //         final reactTally = <String, int>{};
// // // // // // //         for (final r in round.reactions) {
// // // // // // //           reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
// // // // // // //         }
// // // // // // //         return Card(
// // // // // // //           margin: const EdgeInsets.only(bottom: 10),
// // // // // // //           child: ExpansionTile(
// // // // // // //             leading: CircleAvatar(
// // // // // // //               backgroundColor: theme.colorScheme.primaryContainer,
// // // // // // //               child: Text(
// // // // // // //                 '${round.roundNumber}',
// // // // // // //                 style: theme.textTheme.labelLarge,
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //             title: Text(
// // // // // // //               _name(round.playerId),
// // // // // // //               style: theme.textTheme.bodyMedium?.copyWith(
// // // // // // //                 fontWeight: FontWeight.w700,
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //             subtitle: Text(
// // // // // // //               round.card != null
// // // // // // //                   ? '${round.card!.type == TodCardType.truth ? "Truth" : "Dare"}: ${round.card!.content}'
// // // // // // //                   : 'Skipped',
// // // // // // //               maxLines: 1,
// // // // // // //               overflow: TextOverflow.ellipsis,
// // // // // // //               style: theme.textTheme.bodySmall,
// // // // // // //             ),
// // // // // // //             children: [
// // // // // // //               Padding(
// // // // // // //                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
// // // // // // //                 child: Column(
// // // // // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // //                   children: [
// // // // // // //                     // Card content
// // // // // // //                     if (round.card != null)
// // // // // // //                       Container(
// // // // // // //                         width: double.infinity,
// // // // // // //                         padding: const EdgeInsets.all(10),
// // // // // // //                         decoration: BoxDecoration(
// // // // // // //                           color: round.card!.type == TodCardType.truth
// // // // // // //                               ? Colors.blue.withOpacity(0.08)
// // // // // // //                               : Colors.orange.withOpacity(0.08),
// // // // // // //                           borderRadius: BorderRadius.circular(8),
// // // // // // //                         ),
// // // // // // //                         child: Text(
// // // // // // //                           round.card!.content,
// // // // // // //                           style: theme.textTheme.bodyMedium,
// // // // // // //                         ),
// // // // // // //                       ),
// // // // // // //                     // Response
// // // // // // //                     if (round.response.isNotEmpty) ...[
// // // // // // //                       const SizedBox(height: 8),
// // // // // // //                       Row(
// // // // // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // //                         children: [
// // // // // // //                           const Text('💬 ', style: TextStyle(fontSize: 14)),
// // // // // // //                           Expanded(
// // // // // // //                             child: Text(
// // // // // // //                               '"${round.response}"',
// // // // // // //                               style: theme.textTheme.bodySmall?.copyWith(
// // // // // // //                                 fontStyle: FontStyle.italic,
// // // // // // //                               ),
// // // // // // //                             ),
// // // // // // //                           ),
// // // // // // //                         ],
// // // // // // //                       ),
// // // // // // //                     ],
// // // // // // //                     // Votes
// // // // // // //                     if (round.voteCount > 0) ...[
// // // // // // //                       const SizedBox(height: 6),
// // // // // // //                       Text(
// // // // // // //                         '👍 ${round.voteCount} vote${round.voteCount != 1 ? "s" : ""}',
// // // // // // //                         style: theme.textTheme.bodySmall?.copyWith(
// // // // // // //                           color: theme.colorScheme.primary,
// // // // // // //                           fontWeight: FontWeight.w600,
// // // // // // //                         ),
// // // // // // //                       ),
// // // // // // //                     ],
// // // // // // //                     // Proof image
// // // // // // //                     if (round.proofImageB64.isNotEmpty) ...[
// // // // // // //                       const SizedBox(height: 8),
// // // // // // //                       _HistoryViewOnceImage(b64: round.proofImageB64),
// // // // // // //                     ],
// // // // // // //                     // Reactions
// // // // // // //                     if (reactTally.isNotEmpty) ...[
// // // // // // //                       const SizedBox(height: 8),
// // // // // // //                       Wrap(
// // // // // // //                         spacing: 6,
// // // // // // //                         runSpacing: 4,
// // // // // // //                         children: reactTally.entries
// // // // // // //                             .map(
// // // // // // //                               (e) => Container(
// // // // // // //                                 padding: const EdgeInsets.symmetric(
// // // // // // //                                   horizontal: 8,
// // // // // // //                                   vertical: 3,
// // // // // // //                                 ),
// // // // // // //                                 decoration: BoxDecoration(
// // // // // // //                                   color:
// // // // // // //                                       theme.colorScheme.surfaceContainerHighest,
// // // // // // //                                   borderRadius: BorderRadius.circular(16),
// // // // // // //                                 ),
// // // // // // //                                 child: Text(
// // // // // // //                                   '${e.key} ${e.value}',
// // // // // // //                                   style: const TextStyle(fontSize: 13),
// // // // // // //                                 ),
// // // // // // //                               ),
// // // // // // //                             )
// // // // // // //                             .toList(),
// // // // // // //                       ),
// // // // // // //                     ],
// // // // // // //                   ],
// // // // // // //                 ),
// // // // // // //               ),
// // // // // // //             ],
// // // // // // //           ),
// // // // // // //         );
// // // // // // //       },
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // // View-once image for history (separate state per instance)
// // // // // // // class _HistoryViewOnceImage extends StatefulWidget {
// // // // // // //   const _HistoryViewOnceImage({required this.b64});
// // // // // // //   final String b64;
// // // // // // //   @override
// // // // // // //   State<_HistoryViewOnceImage> createState() => _HistoryViewOnceImageState();
// // // // // // // }

// // // // // // // class _HistoryViewOnceImageState extends State<_HistoryViewOnceImage> {
// // // // // // //   bool _revealed = false;
// // // // // // //   bool _viewed = false;
// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     if (_viewed) {
// // // // // // //       return Container(
// // // // // // //         height: 48,
// // // // // // //         alignment: Alignment.centerLeft,
// // // // // // //         child: Text(
// // // // // // //           '📷 Proof viewed',
// // // // // // //           style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
// // // // // // //         ),
// // // // // // //       );
// // // // // // //     }
// // // // // // //     if (!_revealed) {
// // // // // // //       return GestureDetector(
// // // // // // //         onTap: () => setState(() => _revealed = true),
// // // // // // //         child: Container(
// // // // // // //           height: 60,
// // // // // // //           decoration: BoxDecoration(
// // // // // // //             color: Colors.grey.shade200,
// // // // // // //             borderRadius: BorderRadius.circular(8),
// // // // // // //           ),
// // // // // // //           alignment: Alignment.center,
// // // // // // //           child: const Row(
// // // // // // //             mainAxisSize: MainAxisSize.min,
// // // // // // //             children: [
// // // // // // //               Icon(Icons.lock_outline, size: 16),
// // // // // // //               SizedBox(width: 6),
// // // // // // //               Text(
// // // // // // //                 'Tap to view proof photo (once)',
// // // // // // //                 style: TextStyle(fontSize: 12),
// // // // // // //               ),
// // // // // // //             ],
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //       );
// // // // // // //     }
// // // // // // //     return GestureDetector(
// // // // // // //       onTap: () => setState(() => _viewed = true),
// // // // // // //       child: ClipRRect(
// // // // // // //         borderRadius: BorderRadius.circular(8),
// // // // // // //         child: Stack(
// // // // // // //           children: [
// // // // // // //             Image.memory(
// // // // // // //               base64Decode(widget.b64),
// // // // // // //               height: 160,
// // // // // // //               width: double.infinity,
// // // // // // //               fit: BoxFit.cover,
// // // // // // //             ),
// // // // // // //             Positioned(
// // // // // // //               bottom: 6,
// // // // // // //               right: 6,
// // // // // // //               child: Container(
// // // // // // //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // // // // // //                 decoration: BoxDecoration(
// // // // // // //                   color: Colors.black54,
// // // // // // //                   borderRadius: BorderRadius.circular(12),
// // // // // // //                 ),
// // // // // // //                 child: const Text(
// // // // // // //                   'Tap to dismiss',
// // // // // // //                   style: TextStyle(color: Colors.white, fontSize: 11),
// // // // // // //                 ),
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //           ],
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // import 'dart:async';
// // // // // // import 'dart:convert';

// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // // import 'package:go_router/go_router.dart';
// // // // // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // // // // import 'package:jma3a/features/rooms/domain/room_entity.dart';
// // // // // // import 'package:provider/provider.dart';
// // // // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // // // import '../../../../../core/di/service_locator.dart';
// // // // // // import '../../../../../core/extensions/context_ext.dart';
// // // // // // import '../../../../../core/providers/auth_provider.dart';
// // // // // // import '../../../../../core/router/route_names.dart';
// // // // // // import '../../../../../core/services/realtime_service.dart';
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
// // // // // //       _provider.initAsOwner(
// // // // // //         roomId: widget.roomId,
// // // // // //         config: widget.config,
// // // // // //         playerIds: widget.playerIds,
// // // // // //         playerDisplayNames: widget.playerDisplayNames,
// // // // // //         packId: widget.packId,
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
// // // // // //     _statusSub?.cancel();
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
// // // // // //           if (type == 'room_closed' && mounted) {
// // // // // //             showDialog(
// // // // // //               context: context,
// // // // // //               barrierDismissible: false,
// // // // // //               builder: (_) => AlertDialog(
// // // // // //                 title: const Text('Room Closed'),
// // // // // //                 content: const Text('The host closed the room.'),
// // // // // //                 actions: [
// // // // // //                   FilledButton(
// // // // // //                     onPressed: () {
// // // // // //                       Navigator.of(context).pop();
// // // // // //                       context.go(RouteNames.home);
// // // // // //                     },
// // // // // //                     child: const Text('OK'),
// // // // // //                   ),
// // // // // //                 ],
// // // // // //               ),
// // // // // //             );
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
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // // ── Scaffold with history support ─────────────────────────────────────────────

// // // // // // class _TodGameScaffold extends StatefulWidget {
// // // // // //   const _TodGameScaffold({
// // // // // //     required this.state,
// // // // // //     required this.game,
// // // // // //     required this.displayNames,
// // // // // //   });
// // // // // //   final TodState state;
// // // // // //   final TodGameProvider game;
// // // // // //   final Map<String, String> displayNames;
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

// // // // // //     return Scaffold(
// // // // // //       appBar: AppBar(
// // // // // //         automaticallyImplyLeading: false,
// // // // // //         title: const Text(
// // // // // //           '',
// // // // // //         ), // prevents overflow from unconstrained actions row
// // // // // //         actions: [
// // // // // //           // Chat button with unread badge
// // // // // //           Consumer<TodGameProvider>(
// // // // // //             builder: (_, g, __) => Stack(
// // // // // //               alignment: Alignment.topRight,
// // // // // //               children: [
// // // // // //                 IconButton(
// // // // // //                   icon: const Icon(Icons.chat_bubble_outline_rounded),
// // // // // //                   onPressed: () {
// // // // // //                     g.clearUnreadChat();
// // // // // //                     showModalBottomSheet(
// // // // // //                       context: context,
// // // // // //                       isScrollControlled: true,
// // // // // //                       backgroundColor: Colors.transparent,
// // // // // //                       builder: (_) =>
// // // // // //                           _InGameChatSheet(game: g, myId: g.currentUserId),
// // // // // //                     );
// // // // // //                   },
// // // // // //                 ),
// // // // // //                 if (g.unreadChat > 0)
// // // // // //                   Positioned(
// // // // // //                     top: 8,
// // // // // //                     right: 8,
// // // // // //                     child: Container(
// // // // // //                       width: 8,
// // // // // //                       height: 8,
// // // // // //                       decoration: const BoxDecoration(
// // // // // //                         color: Colors.red,
// // // // // //                         shape: BoxShape.circle,
// // // // // //                       ),
// // // // // //                     ),
// // // // // //                   ),
// // // // // //               ],
// // // // // //             ),
// // // // // //           ),
// // // // // //           if (state.history.isNotEmpty)
// // // // // //             IconButton(
// // // // // //               icon: const Icon(Icons.history_rounded),
// // // // // //               tooltip: 'History',
// // // // // //               onPressed: () => setState(() => _showHistory = true),
// // // // // //             ),
// // // // // //         ],
// // // // // //       ),
// // // // // //       body: SafeArea(
// // // // // //         child: Column(
// // // // // //           children: [
// // // // // //             TodHud(state: state, game: game, displayNames: widget.displayNames),
// // // // // //             Expanded(
// // // // // //               child: AnimatedSwitcher(
// // // // // //                 duration: const Duration(milliseconds: 300),
// // // // // //                 transitionBuilder: (child, anim) => FadeTransition(
// // // // // //                   opacity: anim,
// // // // // //                   child: SlideTransition(
// // // // // //                     position:
// // // // // //                         Tween<Offset>(
// // // // // //                           begin: const Offset(0, 0.05),
// // // // // //                           end: Offset.zero,
// // // // // //                         ).animate(
// // // // // //                           CurvedAnimation(
// // // // // //                             parent: anim,
// // // // // //                             curve: Curves.easeOutCubic,
// // // // // //                           ),
// // // // // //                         ),
// // // // // //                     child: child,
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 child: KeyedSubtree(
// // // // // //                   key: ValueKey('${state.phase}-${state.currentPlayerId}'),
// // // // // //                   child: _phaseWidget(
// // // // // //                     context,
// // // // // //                     game,
// // // // // //                     widget.displayNames,
// // // // // //                     state,
// // // // // //                   ),
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
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
// // // // // //                     // Proof image
// // // // // //                     if (round.proofImageB64.isNotEmpty) ...[
// // // // // //                       const SizedBox(height: 8),
// // // // // //                       _HistoryViewOnceImage(b64: round.proofImageB64),
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

// // // // // // // View-once image for history (separate state per instance)
// // // // // // class _HistoryViewOnceImage extends StatefulWidget {
// // // // // //   const _HistoryViewOnceImage({required this.b64});
// // // // // //   final String b64;
// // // // // //   @override
// // // // // //   State<_HistoryViewOnceImage> createState() => _HistoryViewOnceImageState();
// // // // // // }

// // // // // // class _HistoryViewOnceImageState extends State<_HistoryViewOnceImage> {
// // // // // //   bool _revealed = false;
// // // // // //   bool _viewed = false;
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     if (_viewed) {
// // // // // //       return Container(
// // // // // //         height: 48,
// // // // // //         alignment: Alignment.centerLeft,
// // // // // //         child: Text(
// // // // // //           '📷 Proof viewed',
// // // // // //           style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
// // // // // //         ),
// // // // // //       );
// // // // // //     }
// // // // // //     if (!_revealed) {
// // // // // //       return GestureDetector(
// // // // // //         onTap: () => setState(() => _revealed = true),
// // // // // //         child: Container(
// // // // // //           height: 60,
// // // // // //           decoration: BoxDecoration(
// // // // // //             color: Colors.grey.shade200,
// // // // // //             borderRadius: BorderRadius.circular(8),
// // // // // //           ),
// // // // // //           alignment: Alignment.center,
// // // // // //           child: const Row(
// // // // // //             mainAxisSize: MainAxisSize.min,
// // // // // //             children: [
// // // // // //               Icon(Icons.lock_outline, size: 16),
// // // // // //               SizedBox(width: 6),
// // // // // //               Text(
// // // // // //                 'Tap to view proof photo (once)',
// // // // // //                 style: TextStyle(fontSize: 12),
// // // // // //               ),
// // // // // //             ],
// // // // // //           ),
// // // // // //         ),
// // // // // //       );
// // // // // //     }
// // // // // //     return GestureDetector(
// // // // // //       onTap: () => setState(() => _viewed = true),
// // // // // //       child: ClipRRect(
// // // // // //         borderRadius: BorderRadius.circular(8),
// // // // // //         child: Stack(
// // // // // //           children: [
// // // // // //             Image.memory(
// // // // // //               base64Decode(widget.b64),
// // // // // //               height: 160,
// // // // // //               width: double.infinity,
// // // // // //               fit: BoxFit.cover,
// // // // // //             ),
// // // // // //             Positioned(
// // // // // //               bottom: 6,
// // // // // //               right: 6,
// // // // // //               child: Container(
// // // // // //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // // // // //                 decoration: BoxDecoration(
// // // // // //                   color: Colors.black54,
// // // // // //                   borderRadius: BorderRadius.circular(12),
// // // // // //                 ),
// // // // // //                 child: const Text(
// // // // // //                   'Tap to dismiss',
// // // // // //                   style: TextStyle(color: Colors.white, fontSize: 11),
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
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

// // // // // import 'dart:async';
// // // // // import 'dart:convert';

// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // // import 'package:go_router/go_router.dart';
// // // // // import 'package:jma3a/core/router/app_router.dart';
// // // // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // // // import 'package:jma3a/features/rooms/domain/room_entity.dart';
// // // // // import 'package:provider/provider.dart';
// // // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // // import '../../../../../core/di/service_locator.dart';
// // // // // import '../../../../../core/extensions/context_ext.dart';
// // // // // import '../../../../../core/providers/auth_provider.dart';
// // // // // import '../../../../../core/router/route_names.dart';
// // // // // import '../../../../../core/services/realtime_service.dart';
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
// // // // //       _provider.initAsOwner(
// // // // //         roomId: widget.roomId,
// // // // //         config: widget.config,
// // // // //         playerIds: widget.playerIds,
// // // // //         playerDisplayNames: widget.playerDisplayNames,
// // // // //         packId: widget.packId,
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
// // // // //     _statusSub?.cancel();
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
// // // // //           if (type == 'room_closed' && mounted) {
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
// // // // //     );
// // // // //   }
// // // // // }

// // // // // // ── Scaffold with history support ─────────────────────────────────────────────

// // // // // class _TodGameScaffold extends StatefulWidget {
// // // // //   const _TodGameScaffold({
// // // // //     required this.state,
// // // // //     required this.game,
// // // // //     required this.displayNames,
// // // // //   });
// // // // //   final TodState state;
// // // // //   final TodGameProvider game;
// // // // //   final Map<String, String> displayNames;
// // // // //   @override
// // // // //   State<_TodGameScaffold> createState() => _TodGameScaffoldState();
// // // // // }

// // // // // class _TodGameScaffoldState extends State<_TodGameScaffold> {
// // // // //   bool _showHistory = false;
// // // // //   bool _showChat = false;
// // // // //   int _unreadChat = 0;

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

// // // // //     return Scaffold(
// // // // //       appBar: AppBar(
// // // // //         automaticallyImplyLeading: false,
// // // // //         title: const Text(
// // // // //           '',
// // // // //         ), // prevents overflow from unconstrained actions row
// // // // //         actions: [
// // // // //           // Chat button with unread badge
// // // // //           Consumer<TodGameProvider>(
// // // // //             builder: (_, g, __) => Stack(
// // // // //               alignment: Alignment.topRight,
// // // // //               children: [
// // // // //                 IconButton(
// // // // //                   icon: const Icon(Icons.chat_bubble_outline_rounded),
// // // // //                   onPressed: () {
// // // // //                     g.clearUnreadChat();
// // // // //                     showModalBottomSheet(
// // // // //                       context: context,
// // // // //                       isScrollControlled: true,
// // // // //                       backgroundColor: Colors.transparent,
// // // // //                       builder: (_) =>
// // // // //                           _InGameChatSheet(game: g, myId: g.currentUserId),
// // // // //                     );
// // // // //                   },
// // // // //                 ),
// // // // //                 if (g.unreadChat > 0)
// // // // //                   Positioned(
// // // // //                     top: 8,
// // // // //                     right: 8,
// // // // //                     child: Container(
// // // // //                       width: 8,
// // // // //                       height: 8,
// // // // //                       decoration: const BoxDecoration(
// // // // //                         color: Colors.red,
// // // // //                         shape: BoxShape.circle,
// // // // //                       ),
// // // // //                     ),
// // // // //                   ),
// // // // //               ],
// // // // //             ),
// // // // //           ),
// // // // //           if (state.history.isNotEmpty)
// // // // //             IconButton(
// // // // //               icon: const Icon(Icons.history_rounded),
// // // // //               tooltip: 'History',
// // // // //               onPressed: () => setState(() => _showHistory = true),
// // // // //             ),
// // // // //         ],
// // // // //       ),
// // // // //       body: SafeArea(
// // // // //         child: Column(
// // // // //           children: [
// // // // //             TodHud(state: state, game: game, displayNames: widget.displayNames),
// // // // //             Expanded(
// // // // //               child: AnimatedSwitcher(
// // // // //                 duration: const Duration(milliseconds: 300),
// // // // //                 transitionBuilder: (child, anim) => FadeTransition(
// // // // //                   opacity: anim,
// // // // //                   child: SlideTransition(
// // // // //                     position:
// // // // //                         Tween<Offset>(
// // // // //                           begin: const Offset(0, 0.05),
// // // // //                           end: Offset.zero,
// // // // //                         ).animate(
// // // // //                           CurvedAnimation(
// // // // //                             parent: anim,
// // // // //                             curve: Curves.easeOutCubic,
// // // // //                           ),
// // // // //                         ),
// // // // //                     child: child,
// // // // //                   ),
// // // // //                 ),
// // // // //                 child: KeyedSubtree(
// // // // //                   key: ValueKey('${state.phase}-${state.currentPlayerId}'),
// // // // //                   child: _phaseWidget(
// // // // //                     context,
// // // // //                     game,
// // // // //                     widget.displayNames,
// // // // //                     state,
// // // // //                   ),
// // // // //                 ),
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //     );
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
// // // // //                     // Proof image
// // // // //                     if (round.proofImageB64.isNotEmpty) ...[
// // // // //                       const SizedBox(height: 8),
// // // // //                       _HistoryViewOnceImage(b64: round.proofImageB64),
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

// // // // // // View-once image for history (separate state per instance)
// // // // // class _HistoryViewOnceImage extends StatefulWidget {
// // // // //   const _HistoryViewOnceImage({required this.b64});
// // // // //   final String b64;
// // // // //   @override
// // // // //   State<_HistoryViewOnceImage> createState() => _HistoryViewOnceImageState();
// // // // // }

// // // // // class _HistoryViewOnceImageState extends State<_HistoryViewOnceImage> {
// // // // //   bool _revealed = false;
// // // // //   bool _viewed = false;
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     if (_viewed) {
// // // // //       return Container(
// // // // //         height: 48,
// // // // //         alignment: Alignment.centerLeft,
// // // // //         child: Text(
// // // // //           '📷 Proof viewed',
// // // // //           style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
// // // // //         ),
// // // // //       );
// // // // //     }
// // // // //     if (!_revealed) {
// // // // //       return GestureDetector(
// // // // //         onTap: () => setState(() => _revealed = true),
// // // // //         child: Container(
// // // // //           height: 60,
// // // // //           decoration: BoxDecoration(
// // // // //             color: Colors.grey.shade200,
// // // // //             borderRadius: BorderRadius.circular(8),
// // // // //           ),
// // // // //           alignment: Alignment.center,
// // // // //           child: const Row(
// // // // //             mainAxisSize: MainAxisSize.min,
// // // // //             children: [
// // // // //               Icon(Icons.lock_outline, size: 16),
// // // // //               SizedBox(width: 6),
// // // // //               Text(
// // // // //                 'Tap to view proof photo (once)',
// // // // //                 style: TextStyle(fontSize: 12),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //         ),
// // // // //       );
// // // // //     }
// // // // //     return GestureDetector(
// // // // //       onTap: () => setState(() => _viewed = true),
// // // // //       child: ClipRRect(
// // // // //         borderRadius: BorderRadius.circular(8),
// // // // //         child: Stack(
// // // // //           children: [
// // // // //             Image.memory(
// // // // //               base64Decode(widget.b64),
// // // // //               height: 160,
// // // // //               width: double.infinity,
// // // // //               fit: BoxFit.cover,
// // // // //             ),
// // // // //             Positioned(
// // // // //               bottom: 6,
// // // // //               right: 6,
// // // // //               child: Container(
// // // // //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // // // //                 decoration: BoxDecoration(
// // // // //                   color: Colors.black54,
// // // // //                   borderRadius: BorderRadius.circular(12),
// // // // //                 ),
// // // // //                 child: const Text(
// // // // //                   'Tap to dismiss',
// // // // //                   style: TextStyle(color: Colors.white, fontSize: 11),
// // // // //                 ),
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
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

// // // // import 'dart:async';
// // // // import 'dart:convert';

// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_animate/flutter_animate.dart';
// // // // import 'package:go_router/go_router.dart';
// // // // import 'package:jma3a/core/router/app_router.dart';
// // // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // // import 'package:jma3a/features/rooms/domain/room_entity.dart';
// // // // import 'package:provider/provider.dart';
// // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // import '../../../../../core/di/service_locator.dart';
// // // // import '../../../../../core/extensions/context_ext.dart';
// // // // import '../../../../../core/providers/auth_provider.dart';
// // // // import '../../../../../core/router/route_names.dart';
// // // // import '../../../../../core/services/realtime_service.dart';
// // // // import '../../../../../core/theme/app_colors.dart';
// // // // import '../../../../../shared/widgets/feedback/error_view.dart';
// // // // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // // // // import '../../engine/base_game_engine.dart';
// // // // import '../../domain/tod_models.dart';
// // // // import '../../tod_game_provider.dart';

// // // // import '../../data/tod_repository.dart';
// // // // import 'tod_card_screen.dart';
// // // // import 'tod_end_screen.dart';
// // // // import 'tod_loading_screen.dart';
// // // // import 'tod_punishment_screen.dart';
// // // // import '../widgets/tod_hud.dart';

// // // // /// Entry point for an active Truth or Dare session.
// // // // ///
// // // // /// Responsibilities:
// // // // ///  - Owns and scopes TodGameProvider for this session
// // // // ///  - Wires RealtimeService callbacks → TodGameProvider
// // // // ///  - Routes between loading / error / active / game-over screens
// // // // ///  - Forwards game_state and player_action from the room Broadcast channel
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

// // // //   final String             roomId;
// // // //   final GameConfig         config;
// // // //   final List<String>       playerIds;
// // // //   final Map<String, String> playerDisplayNames;  // userId → displayName
// // // //   final String             packId;
// // // //   final bool               isOwner;
// // // //   final String?            sessionId;
// // // //   final bool               isModerator;
// // // //   final String?            packCoverUrl;

// // // //   @override
// // // //   State<TodGameScreen> createState() => _TodGameScreenState();
// // // // }

// // // // class _TodGameScreenState extends State<TodGameScreen> {
// // // //   late final TodGameProvider _provider;

// // // //   // Subscriptions to the room Broadcast channel
// // // //   // (channel already open by RoomProvider — we just register callbacks)
// // // //   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();

// // // //     final auth = context.read<AuthProvider>();
// // // //     final user = auth.currentUser!;

// // // //     _provider = TodGameProvider(
// // // //       realtimeService: sl.realtimeService,
// // // //       repository:      TodRepository.instance,
// // // //       currentUserId:   user.id,
// // // //       currentDisplayName: user.displayName ?? user.username ?? 'Player',
// // // //       isModerator:     widget.isModerator,
// // // //     );

// // // //     // ── Wire Broadcast callbacks ────────────────────────────────────────────
// // // //     // The room channel is already subscribed by RoomProvider/LobbyScreen.
// // // //     // TodGameScreen registers its own game-specific handlers for game_state
// // // //     // and player_action by re-subscribing with extended handlers.
// // // //     //
// // // //     // We do this by using the RealtimeService._bcast pattern:
// // // //     // The channel already has onGameState/onPlayerAction wired to no-ops
// // // //     // in RoomProvider. We replace them here by storing callbacks and
// // // //     // intercepting from the top-level channel via a dedicated subscription.
// // // //     _wireRealtimeCallbacks();

// // // //     if (widget.isOwner) {
// // // //       _provider.initAsOwner(
// // // //         roomId:              widget.roomId,
// // // //         config:              widget.config,
// // // //         playerIds:           widget.playerIds,
// // // //         playerDisplayNames:  widget.playerDisplayNames,
// // // //         packId:              widget.packId,
// // // //         packCoverUrl:        widget.packCoverUrl,
// // // //       );
// // // //     } else {
// // // //       _provider.initAsFollower(
// // // //         roomId:       widget.roomId,
// // // //         config:       widget.config,
// // // //         sessionId:    widget.sessionId,
// // // //         packCoverUrl: widget.packCoverUrl,
// // // //       );
// // // //     }
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _statusSub?.cancel();
// // // //     _provider.dispose();
// // // //     super.dispose();
// // // //   }

// // // //   /// Wire game-specific callbacks into the existing room channel.
// // // //   ///
// // // //   /// Strategy: re-subscribe to the room channel with updated handlers that
// // // //   /// forward game_state and player_action to this provider.
// // // //   /// The channel is already open; we track callbacks via a thin interceptor.
// // // //   void _wireRealtimeCallbacks() {
// // // //     // Listen to channel status changes for reconnection awareness
// // // //     _statusSub = sl.realtimeService
// // // //         .statusStream(widget.roomId)
// // // //         ?.listen((status) {
// // // //       if (status == RealtimeSubscribeStatus.subscribed &&
// // // //           !_provider.hasSyncedState) {
// // // //         // Channel reconnected — request state sync
// // // //         sl.realtimeService.broadcastSyncRequest(
// // // //           widget.roomId,
// // // //           context.read<AuthProvider>().currentUser!.id,
// // // //           0,
// // // //         );
// // // //       }
// // // //     });

// // // //     // Re-subscribe with game handlers added.
// // // //     // This safely replaces the channel subscription with game callbacks.
// // // //     // (No-op handlers in RoomProvider are replaced with active ones here.)
// // // //     _resubscribeWithGameHandlers();
// // // //   }

// // // //   void _resubscribeWithGameHandlers() {
// // // //     final userId = context.read<AuthProvider>().currentUser!.id;

// // // //     // Unsubscribe existing channel and re-subscribe with game callbacks merged
// // // //     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
// // // //       sl.realtimeService.subscribe(
// // // //         roomId: widget.roomId,
// // // //         // ── Game-specific handlers ─────────────────────────────────────────
// // // //         onGameState: (p) => _provider.onStateBroadcast(p),
// // // //         onPlayerAction: (p) => _provider.onPlayerAction(p),
// // // //         onSyncRequest: (p) => _provider.onSyncRequest(p),
// // // //         onGameStarted: (_) {},
// // // //         onGameEnded: (p) {
// // // //           // Admin ended the game — take everyone back to the lobby
// // // //           if (mounted) {
// // // //             ScaffoldMessenger.of(context).showSnackBar(
// // // //               const SnackBar(content: Text('The host ended the game')));
// // // //             // Pop back to lobby (the LobbyScreen is still on the stack)
// // // //             if (context.canPop()) context.pop();
// // // //             else context.go(RouteNames.home);
// // // //           }
// // // //         },
// // // //         // ── Room lifecycle (passthrough — RoomProvider is disposed) ─────────
// // // //         onRoomEvent: (p) {
// // // //           final type = p['type'] as String?;
// // // //           if (type == 'game_paused' && mounted) {
// // // //             WidgetsBinding.instance.addPostFrameCallback((_) {
// // // //               if (!mounted) return;
// // // //               showDialog(context: context, barrierDismissible: false,
// // // //                 builder: (ctx2) => AlertDialog(
// // // //                   title: const Text('⏸ Game Paused'),
// // // //                   content: const Text('The host paused the game and will return shortly.'),
// // // //                   actions: [FilledButton(onPressed: () { Navigator.of(ctx2).pop(); AppRouter.router.go(RouteNames.home); }, child: const Text('Leave for Now'))]));
// // // //             });
// // // //           }
// // // //           if (type == 'room_closed' && mounted) {
// // // //             WidgetsBinding.instance.addPostFrameCallback((_) {
// // // //               if (mounted) {
// // // //                 showDialog(context: context, barrierDismissible: false,
// // // //                   builder: (ctx2) => AlertDialog(
// // // //                     title: const Text('Room Closed'),
// // // //                     content: const Text('The host closed the room.'),
// // // //                     actions: [FilledButton(
// // // //                       onPressed: () { Navigator.of(ctx2).pop(); AppRouter.router.go(RouteNames.home); },
// // // //                       child: const Text('OK'))],
// // // //                   ));
// // // //               } else {
// // // //                 AppRouter.router.go(RouteNames.home);
// // // //               }
// // // //             });
// // // //           }
// // // //         },
// // // //         onChatMessage: (p) {
// // // //           final msg = TodChatMsg(
// // // //             senderId:   p['user_id']     as String? ?? '',
// // // //             senderName: p['display_name'] as String? ?? 'Player',
// // // //             text:       p['content']     as String? ?? '',
// // // //             ts: DateTime.fromMillisecondsSinceEpoch(
// // // //                 (p['ts'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
// // // //           );
// // // //           _provider.addChatMessage(msg);
// // // //         },
// // // //         onModeration: (p) => _handleModerationEvent(p),
// // // //         onSettingsChange: (_) {},
// // // //         // ── Presence ──────────────────────────────────────────────────────
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
// // // //     final type     = p['type'] as String?;
// // // //     final targetId = p['target_user_id'] as String?;
// // // //     final currentId = context.read<AuthProvider>().currentUser?.id;

// // // //     // If kicked or banned, navigate back to lobby
// // // //     if ((type == 'kick' || type == 'ban') && targetId == currentId) {
// // // //       if (mounted) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //             const SnackBar(content: Text('You were removed from the room')));
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
// // // //           leading: BackButton(onPressed: () async {
// // // //             if (widget.isOwner) {
// // // //               // Owner leaving game → end game for everyone, go back to lobby
// // // //               try {
// // // //                 await sl.realtimeService.broadcastGameEnded(widget.roomId, {'reason': 'host_left'});
// // // //                 await sl.roomRepository.updateStatus(widget.roomId, RoomStatus.waiting);
// // // //               } catch (_) {}
// // // //             }
// // // //             if (ctx.mounted) ctx.go(RouteNames.home);
// // // //           }),
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
// // // //         state:          game.state!,
// // // //         displayNames:   widget.playerDisplayNames,
// // // //         onLeave:        () => ctx.go(RouteNames.home),
// // // //       );
// // // //     }

// // // //     final state = game.state;
// // // //     if (state == null) return const TodLoadingScreen();

// // // //     return _TodGameScaffold(
// // // //       state:        state,
// // // //       game:         game,
// // // //       displayNames: widget.playerDisplayNames,
// // // //     );
// // // //   }

// // // // }

// // // // // ── Scaffold with history support ─────────────────────────────────────────────

// // // // class _TodGameScaffold extends StatefulWidget {
// // // //   const _TodGameScaffold({
// // // //     required this.state,
// // // //     required this.game,
// // // //     required this.displayNames,
// // // //   });
// // // //   final TodState            state;
// // // //   final TodGameProvider     game;
// // // //   final Map<String, String> displayNames;
// // // //   @override State<_TodGameScaffold> createState() => _TodGameScaffoldState();
// // // // }

// // // // class _TodGameScaffoldState extends State<_TodGameScaffold> {
// // // //   bool _showHistory = false;
// // // //   bool _showChat    = false;
// // // //   int  _unreadChat  = 0;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final state = widget.state;
// // // //     final game  = widget.game;

// // // //     if (_showHistory) {
// // // //       return Scaffold(
// // // //         appBar: AppBar(
// // // //           leading: BackButton(onPressed: () => setState(() => _showHistory = false)),
// // // //           title: Text('History (${state.history.length} rounds)'),
// // // //         ),
// // // //         body: _HistoryPanel(
// // // //           history:      state.history,
// // // //           displayNames: widget.displayNames,
// // // //         ),
// // // //       );
// // // //     }

// // // //     return PopScope(
// // // //       canPop: false,
// // // //       onPopInvoked: (_) => _showLeaveDialog(context, game, state),
// // // //       child: Scaffold(
// // // //       appBar: AppBar(
// // // //         automaticallyImplyLeading: false,
// // // //         title: const Text(''),
// // // //         leading: IconButton(
// // // //           icon: const Icon(Icons.arrow_back),
// // // //           onPressed: () => _showLeaveDialog(context, game, state),
// // // //         ),
// // // //         actions: [
// // // //           // Chat button with unread badge
// // // //           Consumer<TodGameProvider>(builder: (_, g, __) => Stack(
// // // //             alignment: Alignment.topRight,
// // // //             children: [
// // // //               IconButton(
// // // //                 icon: const Icon(Icons.chat_bubble_outline_rounded),
// // // //                 onPressed: () {
// // // //                   g.clearUnreadChat();
// // // //                   showModalBottomSheet(
// // // //                     context: context, isScrollControlled: true,
// // // //                     backgroundColor: Colors.transparent,
// // // //                     builder: (_) => _InGameChatSheet(game: g, myId: g.currentUserId));
// // // //                 }),
// // // //               if (g.unreadChat > 0)
// // // //                 Positioned(top: 8, right: 8, child: Container(
// // // //                   width: 8, height: 8,
// // // //                   decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
// // // //             ],
// // // //           )),
// // // //           if (state.history.isNotEmpty)
// // // //             IconButton(
// // // //               icon: const Icon(Icons.history_rounded),
// // // //               tooltip: 'History',
// // // //               onPressed: () => setState(() => _showHistory = true),
// // // //             ),
// // // //         ],
// // // //       ),
// // // //       body: SafeArea(
// // // //         child: Column(
// // // //           children: [
// // // //             TodHud(
// // // //               state: state,
// // // //               game:  game,
// // // //               displayNames: widget.displayNames,
// // // //             ),
// // // //             Expanded(
// // // //               child: AnimatedSwitcher(
// // // //                 duration: const Duration(milliseconds: 300),
// // // //                 transitionBuilder: (child, anim) => FadeTransition(
// // // //                   opacity: anim,
// // // //                   child: SlideTransition(
// // // //                     position: Tween<Offset>(
// // // //                       begin: const Offset(0, 0.05),
// // // //                       end:   Offset.zero,
// // // //                     ).animate(CurvedAnimation(
// // // //                         parent: anim, curve: Curves.easeOutCubic)),
// // // //                     child: child,
// // // //                   ),
// // // //                 ),
// // // //                 child: KeyedSubtree(
// // // //                   key: ValueKey('${state.phase}-${state.currentPlayerId}'),
// // // //                   child: _phaseWidget(context, game, widget.displayNames, state),
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     ), // end Scaffold (PopScope child)
// // // //     ); // end PopScope
// // // //   }

// // // //   Future<void> _showLeaveDialog(BuildContext ctx, TodGameProvider game, TodState state) async {
// // // //     if (!ctx.mounted) return;
// // // //     final isOwner = widget.game.isOwner;

// // // //     if (isOwner) {
// // // //       // Owner: choose pause or end
// // // //       final choice = await showDialog<String>(
// // // //         context: ctx,
// // // //         builder: (_) => AlertDialog(
// // // //           title: const Text('Leave Game?'),
// // // //           content: const Text("Choose what happens to the game while you're away."),
// // // //           actions: [
// // // //             TextButton(
// // // //               onPressed: () => Navigator.pop(ctx, 'cancel'),
// // // //               child: const Text('Stay')),
// // // //             FilledButton.tonal(
// // // //               onPressed: () => Navigator.pop(ctx, 'pause'),
// // // //               child: const Text('Pause & Return Later')),
// // // //             FilledButton(
// // // //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // // //               onPressed: () => Navigator.pop(ctx, 'end'),
// // // //               child: const Text('End Game for Everyone')),
// // // //           ],
// // // //         ),
// // // //       );
// // // //       if (choice == null || choice == 'cancel' || !ctx.mounted) return;
// // // //       if (choice == 'pause') {
// // // //         try {
// // // //           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // //             'type': 'game_paused', 'reason': 'host_away'});
// // // //           await sl.roomRepository.updateStatus(widget.roomId, RoomStatus.paused);
// // // //         } catch (_) {}
// // // //         if (ctx.mounted) ctx.go(RouteNames.home);
// // // //       } else {
// // // //         // End game — broadcast owner_left so all get the dialog
// // // //         try {
// // // //           await sl.realtimeService.broadcastGameEnded(widget.roomId, {'reason': 'host_ended'});
// // // //           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // // //             'type': 'owner_left', 'reason': 'host_ended'});
// // // //           await sl.roomRepository.updateStatus(widget.roomId, RoomStatus.closed);
// // // //         } catch (_) {}
// // // //         if (ctx.mounted) ctx.go(RouteNames.home);
// // // //       }
// // // //     } else {
// // // //       // Player: choose to leave definitively or come back
// // // //       final choice = await showDialog<String>(
// // // //         context: ctx,
// // // //         builder: (_) => AlertDialog(
// // // //           title: const Text('Leave Game?'),
// // // //           content: const Text('Are you leaving for good or will you come back?'),
// // // //           actions: [
// // // //             TextButton(
// // // //               onPressed: () => Navigator.pop(ctx, 'cancel'),
// // // //               child: const Text('Stay')),
// // // //             FilledButton.tonal(
// // // //               onPressed: () => Navigator.pop(ctx, 'return'),
// // // //               child: const Text("I'll Return")),
// // // //             FilledButton(
// // // //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // // //               onPressed: () => Navigator.pop(ctx, 'definitive'),
// // // //               child: const Text('Leave for Good')),
// // // //           ],
// // // //         ),
// // // //       );
// // // //       if (choice == null || choice == 'cancel' || !ctx.mounted) return;
// // // //       if (choice == 'return') {
// // // //         // Mark as away but keep seat — when they return they rejoin game
// // // //         try {
// // // //           await sl.roomRepository.setMemberAway(widget.roomId, game.currentUserId, away: true);
// // // //         } catch (_) {}
// // // //         if (ctx.mounted) ctx.go(RouteNames.home);
// // // //       } else {
// // // //         // Definitively leave — mark as spectator-only for this room
// // // //         try {
// // // //           await sl.roomRepository.setMemberDefinitiveLeave(widget.roomId, game.currentUserId);
// // // //         } catch (_) {}
// // // //         if (ctx.mounted) ctx.go(RouteNames.home);
// // // //       }
// // // //     }
// // // //   }

// // // //   Widget _phaseWidget(BuildContext ctx, TodGameProvider game, Map<String, String> displayNames, TodState state) {
// // // //     return switch (state.phase) {
// // // //       TodTurnPhase.punishmentVoting => TodPunishmentScreen(
// // // //           state: state, game: game,
// // // //           displayNames: widget.displayNames),
// // // //       _ => TodCardScreen(
// // // //           state: state, game: game,
// // // //           displayNames: widget.displayNames),
// // // //     };
// // // //   }
// // // // }

// // // // // ── History panel ─────────────────────────────────────────────────────────────

// // // // class _HistoryPanel extends StatelessWidget {
// // // //   const _HistoryPanel({required this.history, required this.displayNames});
// // // //   final List<TodRoundRecord> history;
// // // //   final Map<String, String>  displayNames;

// // // //   String _name(String id) => displayNames[id] ?? id.substring(0, id.length.clamp(0, 6));

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
// // // //         final round = history[history.length - 1 - i]; // newest first
// // // //         final reactTally = <String, int>{};
// // // //         for (final r in round.reactions) {
// // // //           reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
// // // //         }
// // // //         return Card(
// // // //           margin: const EdgeInsets.only(bottom: 10),
// // // //           child: ExpansionTile(
// // // //             leading: CircleAvatar(
// // // //               backgroundColor: theme.colorScheme.primaryContainer,
// // // //               child: Text('${round.roundNumber}',
// // // //                   style: theme.textTheme.labelLarge),
// // // //             ),
// // // //             title: Text(_name(round.playerId),
// // // //                 style: theme.textTheme.bodyMedium?.copyWith(
// // // //                     fontWeight: FontWeight.w700)),
// // // //             subtitle: Text(
// // // //               round.card != null
// // // //                   ? '${round.card!.type == TodCardType.truth ? "Truth" : "Dare"}: ${round.card!.content}'
// // // //                   : 'Skipped',
// // // //               maxLines: 1, overflow: TextOverflow.ellipsis,
// // // //               style: theme.textTheme.bodySmall,
// // // //             ),
// // // //             children: [
// // // //               Padding(
// // // //                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
// // // //                 child: Column(
// // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // //                     children: [
// // // //                   // Card content
// // // //                   if (round.card != null)
// // // //                     Container(
// // // //                       width: double.infinity,
// // // //                       padding: const EdgeInsets.all(10),
// // // //                       decoration: BoxDecoration(
// // // //                         color: round.card!.type == TodCardType.truth
// // // //                             ? Colors.blue.withOpacity(0.08)
// // // //                             : Colors.orange.withOpacity(0.08),
// // // //                         borderRadius: BorderRadius.circular(8),
// // // //                       ),
// // // //                       child: Text(round.card!.content,
// // // //                           style: theme.textTheme.bodyMedium),
// // // //                     ),
// // // //                   // Response
// // // //                   if (round.response.isNotEmpty) ...[
// // // //                     const SizedBox(height: 8),
// // // //                     Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
// // // //                       const Text('💬 ', style: TextStyle(fontSize: 14)),
// // // //                       Expanded(child: Text('"${round.response}"',
// // // //                           style: theme.textTheme.bodySmall?.copyWith(
// // // //                               fontStyle: FontStyle.italic))),
// // // //                     ]),
// // // //                   ],
// // // //                   // Votes
// // // //                   if (round.voteCount > 0) ...[
// // // //                     const SizedBox(height: 6),
// // // //                     Text('👍 ${round.voteCount} vote${round.voteCount != 1 ? "s" : ""}',
// // // //                         style: theme.textTheme.bodySmall?.copyWith(
// // // //                             color: theme.colorScheme.primary,
// // // //                             fontWeight: FontWeight.w600)),
// // // //                   ],
// // // //                   // Proof image
// // // //                   if (round.proofImageB64.isNotEmpty) ...[
// // // //                     const SizedBox(height: 8),
// // // //                     _HistoryViewOnceImage(b64: round.proofImageB64),
// // // //                   ],
// // // //                   // Reactions
// // // //                   if (reactTally.isNotEmpty) ...[
// // // //                     const SizedBox(height: 8),
// // // //                     Wrap(spacing: 6, runSpacing: 4,
// // // //                         children: reactTally.entries.map((e) => Container(
// // // //                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // // //                           decoration: BoxDecoration(
// // // //                             color: theme.colorScheme.surfaceContainerHighest,
// // // //                             borderRadius: BorderRadius.circular(16),
// // // //                           ),
// // // //                           child: Text('${e.key} ${e.value}',
// // // //                               style: const TextStyle(fontSize: 13)),
// // // //                         )).toList()),
// // // //                   ],
// // // //                 ]),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         );
// // // //       },
// // // //     );
// // // //   }
// // // // }

// // // // // View-once image for history (separate state per instance)
// // // // class _HistoryViewOnceImage extends StatefulWidget {
// // // //   const _HistoryViewOnceImage({required this.b64});
// // // //   final String b64;
// // // //   @override State<_HistoryViewOnceImage> createState() => _HistoryViewOnceImageState();
// // // // }
// // // // class _HistoryViewOnceImageState extends State<_HistoryViewOnceImage> {
// // // //   bool _revealed = false;
// // // //   bool _viewed   = false;
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     if (_viewed) {
// // // //       return Container(
// // // //         height: 48,
// // // //         alignment: Alignment.centerLeft,
// // // //         child: Text('📷 Proof viewed',
// // // //             style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
// // // //       );
// // // //     }
// // // //     if (!_revealed) {
// // // //       return GestureDetector(
// // // //         onTap: () => setState(() => _revealed = true),
// // // //         child: Container(
// // // //           height: 60,
// // // //           decoration: BoxDecoration(
// // // //             color: Colors.grey.shade200,
// // // //             borderRadius: BorderRadius.circular(8),
// // // //           ),
// // // //           alignment: Alignment.center,
// // // //           child: const Row(mainAxisSize: MainAxisSize.min, children: [
// // // //             Icon(Icons.lock_outline, size: 16),
// // // //             SizedBox(width: 6),
// // // //             Text('Tap to view proof photo (once)',
// // // //                 style: TextStyle(fontSize: 12)),
// // // //           ]),
// // // //         ),
// // // //       );
// // // //     }
// // // //     return GestureDetector(
// // // //       onTap: () => setState(() => _viewed = true),
// // // //       child: ClipRRect(
// // // //         borderRadius: BorderRadius.circular(8),
// // // //         child: Stack(children: [
// // // //           Image.memory(base64Decode(widget.b64),
// // // //               height: 160, width: double.infinity, fit: BoxFit.cover),
// // // //           Positioned(bottom: 6, right: 6,
// // // //             child: Container(
// // // //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // // //               decoration: BoxDecoration(color: Colors.black54,
// // // //                   borderRadius: BorderRadius.circular(12)),
// // // //               child: const Text('Tap to dismiss',
// // // //                   style: TextStyle(color: Colors.white, fontSize: 11)),
// // // //             )),
// // // //         ]),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // // ── In-game chat sheet ─────────────────────────────────────────────────────────
// // // // class _InGameChatSheet extends StatefulWidget {
// // // //   const _InGameChatSheet({required this.game, required this.myId});
// // // //   final TodGameProvider game;
// // // //   final String myId;
// // // //   @override State<_InGameChatSheet> createState() => _InGameChatSheetState();
// // // // }

// // // // class _InGameChatSheetState extends State<_InGameChatSheet> {
// // // //   final _ctrl   = TextEditingController();
// // // //   final _scroll = ScrollController();
// // // //   @override void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

// // // //   void _send() {
// // // //     final t = _ctrl.text.trim(); if (t.isEmpty) return;
// // // //     widget.game.sendChat(t); _ctrl.clear();
// // // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // // //       if (_scroll.hasClients) _scroll.animateTo(
// // // //           _scroll.position.maxScrollExtent, duration: 200.ms, curve: Curves.easeOut);
// // // //     });
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Container(
// // // //       height: MediaQuery.sizeOf(context).height * 0.65,
// // // //       decoration: const BoxDecoration(
// // // //         color: Color(0xFF1A2E45),
// // // //         borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
// // // //       child: Column(children: [
// // // //         Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
// // // //             decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
// // // //         const Text('💬 Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
// // // //         const Divider(color: Colors.white12),
// // // //         Expanded(child: ListenableBuilder(listenable: widget.game, builder: (_, __) {
// // // //           final msgs = widget.game.chatMessages;
// // // //           return msgs.isEmpty
// // // //               ? const Center(child: Text('No messages yet', style: TextStyle(color: Colors.white38)))
// // // //               : ListView.builder(
// // // //                   controller: _scroll,
// // // //                   padding: const EdgeInsets.all(12),
// // // //                   itemCount: msgs.length,
// // // //                   itemBuilder: (_, i) {
// // // //                     final m   = msgs[i];
// // // //                     final isMe = m.senderId == widget.myId;
// // // //                     final color = _kChatColors[m.senderId.hashCode.abs() % _kChatColors.length];
// // // //                     return Padding(
// // // //                       padding: EdgeInsets.only(bottom: 8, left: isMe ? 48 : 0, right: isMe ? 0 : 48),
// // // //                       child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
// // // //                         if (!isMe) Padding(padding: const EdgeInsets.only(left: 4, bottom: 2),
// // // //                             child: Text(m.senderName, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
// // // //                         Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// // // //                           decoration: BoxDecoration(
// // // //                             color: isMe ? const Color(0xFFFFD60A) : color.withOpacity(0.18),
// // // //                             borderRadius: BorderRadius.circular(16).copyWith(
// // // //                                 bottomRight: isMe ? const Radius.circular(4) : null,
// // // //                                 bottomLeft:  isMe ? null : const Radius.circular(4))),
// // // //                           child: Text(m.text, style: TextStyle(
// // // //                               color: isMe ? const Color(0xFF0D1B2A) : Colors.white,
// // // //                               fontWeight: isMe ? FontWeight.w700 : FontWeight.w400))),
// // // //                       ]));
// // // //                   });
// // // //         })),
// // // //         Container(
// // // //           padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.viewInsetsOf(context).bottom + 12),
// // // //           color: const Color(0xFF1A2E45),
// // // //           child: Row(children: [
// // // //             Expanded(child: TextField(
// // // //               controller: _ctrl, style: const TextStyle(color: Colors.white),
// // // //               textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
// // // //               decoration: InputDecoration(hintText: 'Say something…', hintStyle: const TextStyle(color: Colors.white38),
// // // //                   filled: true, fillColor: Colors.white.withOpacity(0.07),
// // // //                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
// // // //                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), isDense: true))),
// // // //             const SizedBox(width: 8),
// // // //             GestureDetector(onTap: _send, child: Container(width: 44, height: 44,
// // // //                 decoration: const BoxDecoration(color: Color(0xFFFFD60A), shape: BoxShape.circle),
// // // //                 child: const Icon(Icons.send_rounded, color: Color(0xFF0D1B2A), size: 20))),
// // // //           ])),
// // // //       ]));
// // // //   }
// // // // }

// // // // const _kChatColors = [
// // // //   Color(0xFF4ECDC4), Color(0xFFA855F7), Color(0xFFFF6B6B),
// // // //   Color(0xFF4ADE80), Color(0xFFFB923C), Color(0xFF60A5FA),
// // // //   Color(0xFFF472B6), Color(0xFFFFD60A), Color(0xFF34D399),
// // // //   Color(0xFFC084FC),
// // // // ];

// // // import 'dart:async';
// // // import 'dart:convert';

// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_animate/flutter_animate.dart';
// // // import 'package:go_router/go_router.dart';
// // // import 'package:jma3a/core/router/app_router.dart';
// // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // import 'package:jma3a/features/rooms/domain/room_entity.dart';
// // // import 'package:provider/provider.dart';
// // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // import '../../../../../core/di/service_locator.dart';
// // // import '../../../../../core/extensions/context_ext.dart';
// // // import '../../../../../core/providers/auth_provider.dart';
// // // import '../../../../../core/router/route_names.dart';
// // // import '../../../../../core/services/realtime_service.dart';
// // // import '../../../../../core/theme/app_colors.dart';
// // // import '../../../../../shared/widgets/feedback/error_view.dart';
// // // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // // // import '../../engine/base_game_engine.dart';
// // // import '../../domain/tod_models.dart';
// // // import '../../tod_game_provider.dart';

// // // import '../../data/tod_repository.dart';
// // // import 'tod_card_screen.dart';
// // // import 'tod_end_screen.dart';
// // // import 'tod_loading_screen.dart';
// // // import 'tod_punishment_screen.dart';
// // // import '../widgets/tod_hud.dart';

// // // /// Entry point for an active Truth or Dare session.
// // // ///
// // // /// Responsibilities:
// // // ///  - Owns and scopes TodGameProvider for this session
// // // ///  - Wires RealtimeService callbacks → TodGameProvider
// // // ///  - Routes between loading / error / active / game-over screens
// // // ///  - Forwards game_state and player_action from the room Broadcast channel
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
// // //   final Map<String, String> playerDisplayNames; // userId → displayName
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

// // //   // Subscriptions to the room Broadcast channel
// // //   // (channel already open by RoomProvider — we just register callbacks)
// // //   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

// // //   @override
// // //   void initState() {
// // //     super.initState();

// // //     final auth = context.read<AuthProvider>();
// // //     final user = auth.currentUser!;

// // //     _provider = TodGameProvider(
// // //       realtimeService: sl.realtimeService,
// // //       repository: TodRepository.instance,
// // //       currentUserId: user.id,
// // //       currentDisplayName: user.displayName ?? user.username ?? 'Player',
// // //       isModerator: widget.isModerator,
// // //     );

// // //     // ── Wire Broadcast callbacks ────────────────────────────────────────────
// // //     // The room channel is already subscribed by RoomProvider/LobbyScreen.
// // //     // TodGameScreen registers its own game-specific handlers for game_state
// // //     // and player_action by re-subscribing with extended handlers.
// // //     //
// // //     // We do this by using the RealtimeService._bcast pattern:
// // //     // The channel already has onGameState/onPlayerAction wired to no-ops
// // //     // in RoomProvider. We replace them here by storing callbacks and
// // //     // intercepting from the top-level channel via a dedicated subscription.
// // //     _wireRealtimeCallbacks();

// // //     if (widget.isOwner) {
// // //       _provider.initAsOwner(
// // //         roomId: widget.roomId,
// // //         config: widget.config,
// // //         playerIds: widget.playerIds,
// // //         playerDisplayNames: widget.playerDisplayNames,
// // //         packId: widget.packId,
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
// // //     _statusSub?.cancel();
// // //     _provider.dispose();
// // //     super.dispose();
// // //   }

// // //   /// Wire game-specific callbacks into the existing room channel.
// // //   ///
// // //   /// Strategy: re-subscribe to the room channel with updated handlers that
// // //   /// forward game_state and player_action to this provider.
// // //   /// The channel is already open; we track callbacks via a thin interceptor.
// // //   void _wireRealtimeCallbacks() {
// // //     // Listen to channel status changes for reconnection awareness
// // //     _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
// // //       status,
// // //     ) {
// // //       if (status == RealtimeSubscribeStatus.subscribed &&
// // //           !_provider.hasSyncedState) {
// // //         // Channel reconnected — request state sync
// // //         sl.realtimeService.broadcastSyncRequest(
// // //           widget.roomId,
// // //           context.read<AuthProvider>().currentUser!.id,
// // //           0,
// // //         );
// // //       }
// // //     });

// // //     // Re-subscribe with game handlers added.
// // //     // This safely replaces the channel subscription with game callbacks.
// // //     // (No-op handlers in RoomProvider are replaced with active ones here.)
// // //     _resubscribeWithGameHandlers();
// // //   }

// // //   void _resubscribeWithGameHandlers() {
// // //     final userId = context.read<AuthProvider>().currentUser!.id;

// // //     // Unsubscribe existing channel and re-subscribe with game callbacks merged
// // //     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
// // //       sl.realtimeService.subscribe(
// // //         roomId: widget.roomId,
// // //         // ── Game-specific handlers ─────────────────────────────────────────
// // //         onGameState: (p) => _provider.onStateBroadcast(p),
// // //         onPlayerAction: (p) => _provider.onPlayerAction(p),
// // //         onSyncRequest: (p) => _provider.onSyncRequest(p),
// // //         onGameStarted: (_) {},
// // //         onGameEnded: (p) {
// // //           // Admin ended the game — take everyone back to the lobby
// // //           if (mounted) {
// // //             ScaffoldMessenger.of(context).showSnackBar(
// // //               const SnackBar(content: Text('The host ended the game')),
// // //             );
// // //             // Pop back to lobby (the LobbyScreen is still on the stack)
// // //             if (context.canPop())
// // //               context.pop();
// // //             else
// // //               context.go(RouteNames.home);
// // //           }
// // //         },
// // //         // ── Room lifecycle (passthrough — RoomProvider is disposed) ─────────
// // //         onRoomEvent: (p) {
// // //           final type = p['type'] as String?;
// // //           if (type == 'game_paused' && mounted) {
// // //             WidgetsBinding.instance.addPostFrameCallback((_) {
// // //               if (!mounted) return;
// // //               showDialog(
// // //                 context: context,
// // //                 barrierDismissible: false,
// // //                 builder: (ctx2) => AlertDialog(
// // //                   title: const Text('⏸ Game Paused'),
// // //                   content: const Text(
// // //                     'The host paused the game and will return shortly.',
// // //                   ),
// // //                   actions: [
// // //                     FilledButton(
// // //                       onPressed: () {
// // //                         Navigator.of(ctx2).pop();
// // //                         AppRouter.router.go(RouteNames.home);
// // //                       },
// // //                       child: const Text('Leave for Now'),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               );
// // //             });
// // //           }
// // //           if (type == 'room_closed' && mounted) {
// // //             WidgetsBinding.instance.addPostFrameCallback((_) {
// // //               if (mounted) {
// // //                 showDialog(
// // //                   context: context,
// // //                   barrierDismissible: false,
// // //                   builder: (ctx2) => AlertDialog(
// // //                     title: const Text('Room Closed'),
// // //                     content: const Text('The host closed the room.'),
// // //                     actions: [
// // //                       FilledButton(
// // //                         onPressed: () {
// // //                           Navigator.of(ctx2).pop();
// // //                           AppRouter.router.go(RouteNames.home);
// // //                         },
// // //                         child: const Text('OK'),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 );
// // //               } else {
// // //                 AppRouter.router.go(RouteNames.home);
// // //               }
// // //             });
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
// // //         // ── Presence ──────────────────────────────────────────────────────
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

// // //     // If kicked or banned, navigate back to lobby
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
// // //                 // Owner leaving game → end game for everyone, go back to lobby
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

// // // // ── Scaffold with history support ─────────────────────────────────────────────

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
// // //       onPopInvoked: (_) => _showLeaveDialog(context, game, state),
// // //       child: Scaffold(
// // //         appBar: AppBar(
// // //           automaticallyImplyLeading: false,
// // //           title: const Text(''),
// // //           leading: IconButton(
// // //             icon: const Icon(Icons.arrow_back),
// // //             onPressed: () => _showLeaveDialog(context, game, state),
// // //           ),
// // //           actions: [
// // //             // Chat button with unread badge
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
// // //       ), // end Scaffold (PopScope child)
// // //     ); // end PopScope
// // //   }

// // //   Future<void> _showLeaveDialog(
// // //     BuildContext ctx,
// // //     TodGameProvider game,
// // //     TodState state,
// // //   ) async {
// // //     if (!ctx.mounted) return;
// // //     final isOwner = widget.isOwner;

// // //     if (isOwner) {
// // //       // Owner: choose pause or end
// // //       final choice = await showDialog<String>(
// // //         context: ctx,
// // //         builder: (_) => AlertDialog(
// // //           title: const Text('Leave Game?'),
// // //           content: const Text(
// // //             "Choose what happens to the game while you're away.",
// // //           ),
// // //           actions: [
// // //             TextButton(
// // //               onPressed: () => Navigator.pop(ctx, 'cancel'),
// // //               child: const Text('Stay'),
// // //             ),
// // //             FilledButton.tonal(
// // //               onPressed: () => Navigator.pop(ctx, 'pause'),
// // //               child: const Text('Pause & Return Later'),
// // //             ),
// // //             FilledButton(
// // //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // //               onPressed: () => Navigator.pop(ctx, 'end'),
// // //               child: const Text('End Game for Everyone'),
// // //             ),
// // //           ],
// // //         ),
// // //       );
// // //       if (choice == null || choice == 'cancel' || !ctx.mounted) return;
// // //       if (choice == 'pause') {
// // //         try {
// // //           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // //             'type': 'game_paused',
// // //             'reason': 'host_away',
// // //           });
// // //           await sl.roomRepository.updateStatus(
// // //             widget.roomId,
// // //             RoomStatus.paused,
// // //           );
// // //         } catch (_) {}
// // //         if (ctx.mounted) ctx.go(RouteNames.home);
// // //       } else {
// // //         // End game — broadcast owner_left so all get the dialog
// // //         try {
// // //           await sl.realtimeService.broadcastGameEnded(widget.roomId, {
// // //             'reason': 'host_ended',
// // //           });
// // //           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// // //             'type': 'owner_left',
// // //             'reason': 'host_ended',
// // //           });
// // //           await sl.roomRepository.updateStatus(
// // //             widget.roomId,
// // //             RoomStatus.closed,
// // //           );
// // //         } catch (_) {}
// // //         if (ctx.mounted) ctx.go(RouteNames.home);
// // //       }
// // //     } else {
// // //       // Player: choose to leave definitively or come back
// // //       final choice = await showDialog<String>(
// // //         context: ctx,
// // //         builder: (_) => AlertDialog(
// // //           title: const Text('Leave Game?'),
// // //           content: const Text(
// // //             'Are you leaving for good or will you come back?',
// // //           ),
// // //           actions: [
// // //             TextButton(
// // //               onPressed: () => Navigator.pop(ctx, 'cancel'),
// // //               child: const Text('Stay'),
// // //             ),
// // //             FilledButton.tonal(
// // //               onPressed: () => Navigator.pop(ctx, 'return'),
// // //               child: const Text("I'll Return"),
// // //             ),
// // //             FilledButton(
// // //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // //               onPressed: () => Navigator.pop(ctx, 'definitive'),
// // //               child: const Text('Leave for Good'),
// // //             ),
// // //           ],
// // //         ),
// // //       );
// // //       if (choice == null || choice == 'cancel' || !ctx.mounted) return;
// // //       if (choice == 'return') {
// // //         // Mark as away but keep seat — when they return they rejoin game
// // //         try {
// // //           await sl.roomRepository.setMemberAway(
// // //             widget.roomId,
// // //             game.currentUserId,
// // //             away: true,
// // //           );
// // //         } catch (_) {}
// // //         if (ctx.mounted) ctx.go(RouteNames.home);
// // //       } else {
// // //         // Definitively leave — mark as spectator-only for this room
// // //         try {
// // //           await sl.roomRepository.setMemberDefinitiveLeave(
// // //             widget.roomId,
// // //             game.currentUserId,
// // //           );
// // //         } catch (_) {}
// // //         if (ctx.mounted) ctx.go(RouteNames.home);
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

// // // // ── History panel ─────────────────────────────────────────────────────────────

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
// // //         final round = history[history.length - 1 - i]; // newest first
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
// // //                     // Card content
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
// // //                     // Response
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
// // //                     // Votes
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
// // //                     // Proof image
// // //                     if (round.proofImageB64.isNotEmpty) ...[
// // //                       const SizedBox(height: 8),
// // //                       _HistoryViewOnceImage(b64: round.proofImageB64),
// // //                     ],
// // //                     // Reactions
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

// // // // View-once image for history (separate state per instance)
// // // class _HistoryViewOnceImage extends StatefulWidget {
// // //   const _HistoryViewOnceImage({required this.b64});
// // //   final String b64;
// // //   @override
// // //   State<_HistoryViewOnceImage> createState() => _HistoryViewOnceImageState();
// // // }

// // // class _HistoryViewOnceImageState extends State<_HistoryViewOnceImage> {
// // //   bool _revealed = false;
// // //   bool _viewed = false;
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     if (_viewed) {
// // //       return Container(
// // //         height: 48,
// // //         alignment: Alignment.centerLeft,
// // //         child: Text(
// // //           '📷 Proof viewed',
// // //           style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
// // //         ),
// // //       );
// // //     }
// // //     if (!_revealed) {
// // //       return GestureDetector(
// // //         onTap: () => setState(() => _revealed = true),
// // //         child: Container(
// // //           height: 60,
// // //           decoration: BoxDecoration(
// // //             color: Colors.grey.shade200,
// // //             borderRadius: BorderRadius.circular(8),
// // //           ),
// // //           alignment: Alignment.center,
// // //           child: const Row(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               Icon(Icons.lock_outline, size: 16),
// // //               SizedBox(width: 6),
// // //               Text(
// // //                 'Tap to view proof photo (once)',
// // //                 style: TextStyle(fontSize: 12),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       );
// // //     }
// // //     return GestureDetector(
// // //       onTap: () => setState(() => _viewed = true),
// // //       child: ClipRRect(
// // //         borderRadius: BorderRadius.circular(8),
// // //         child: Stack(
// // //           children: [
// // //             Image.memory(
// // //               base64Decode(widget.b64),
// // //               height: 160,
// // //               width: double.infinity,
// // //               fit: BoxFit.cover,
// // //             ),
// // //             Positioned(
// // //               bottom: 6,
// // //               right: 6,
// // //               child: Container(
// // //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// // //                 decoration: BoxDecoration(
// // //                   color: Colors.black54,
// // //                   borderRadius: BorderRadius.circular(12),
// // //                 ),
// // //                 child: const Text(
// // //                   'Tap to dismiss',
// // //                   style: TextStyle(color: Colors.white, fontSize: 11),
// // //                 ),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ── In-game chat sheet ─────────────────────────────────────────────────────────
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

// // import 'dart:async';
// // import 'dart:convert';

// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:jma3a/core/router/app_router.dart';
// // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // import 'package:jma3a/features/rooms/domain/room_entity.dart';
// // import 'package:provider/provider.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';

// // import '../../../../../core/di/service_locator.dart';
// // import '../../../../../core/extensions/context_ext.dart';
// // import '../../../../../core/providers/auth_provider.dart';
// // import '../../../../../core/router/route_names.dart';
// // import '../../../../../core/services/realtime_service.dart';
// // import '../../../../../core/theme/app_colors.dart';
// // import '../../../../../shared/widgets/feedback/error_view.dart';
// // import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // // import '../../engine/base_game_engine.dart';
// // import '../../domain/tod_models.dart';
// // import '../../tod_game_provider.dart';

// // import '../../data/tod_repository.dart';
// // import 'tod_card_screen.dart';
// // import 'tod_end_screen.dart';
// // import 'tod_loading_screen.dart';
// // import 'tod_punishment_screen.dart';
// // import '../widgets/tod_hud.dart';

// // /// Entry point for an active Truth or Dare session.
// // ///
// // /// Responsibilities:
// // ///  - Owns and scopes TodGameProvider for this session
// // ///  - Wires RealtimeService callbacks → TodGameProvider
// // ///  - Routes between loading / error / active / game-over screens
// // ///  - Forwards game_state and player_action from the room Broadcast channel
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
// //   final Map<String, String> playerDisplayNames; // userId → displayName
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

// //   // Subscriptions to the room Broadcast channel
// //   // (channel already open by RoomProvider — we just register callbacks)
// //   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

// //   @override
// //   void initState() {
// //     super.initState();

// //     final auth = context.read<AuthProvider>();
// //     final user = auth.currentUser!;

// //     _provider = TodGameProvider(
// //       realtimeService: sl.realtimeService,
// //       repository: TodRepository.instance,
// //       currentUserId: user.id,
// //       currentDisplayName: user.displayName ?? user.username ?? 'Player',
// //       isModerator: widget.isModerator,
// //     );

// //     // ── Wire Broadcast callbacks ────────────────────────────────────────────
// //     // The room channel is already subscribed by RoomProvider/LobbyScreen.
// //     // TodGameScreen registers its own game-specific handlers for game_state
// //     // and player_action by re-subscribing with extended handlers.
// //     //
// //     // We do this by using the RealtimeService._bcast pattern:
// //     // The channel already has onGameState/onPlayerAction wired to no-ops
// //     // in RoomProvider. We replace them here by storing callbacks and
// //     // intercepting from the top-level channel via a dedicated subscription.
// //     _wireRealtimeCallbacks();

// //     if (widget.isOwner) {
// //       _provider.initAsOwner(
// //         roomId: widget.roomId,
// //         config: widget.config,
// //         playerIds: widget.playerIds,
// //         playerDisplayNames: widget.playerDisplayNames,
// //         packId: widget.packId,
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
// //     _statusSub?.cancel();
// //     _provider.dispose();
// //     super.dispose();
// //   }

// //   /// Wire game-specific callbacks into the existing room channel.
// //   ///
// //   /// Strategy: re-subscribe to the room channel with updated handlers that
// //   /// forward game_state and player_action to this provider.
// //   /// The channel is already open; we track callbacks via a thin interceptor.
// //   void _wireRealtimeCallbacks() {
// //     // Listen to channel status changes for reconnection awareness
// //     _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
// //       status,
// //     ) {
// //       if (status == RealtimeSubscribeStatus.subscribed &&
// //           !_provider.hasSyncedState) {
// //         // Channel reconnected — request state sync
// //         sl.realtimeService.broadcastSyncRequest(
// //           widget.roomId,
// //           context.read<AuthProvider>().currentUser!.id,
// //           0,
// //         );
// //       }
// //     });

// //     // Re-subscribe with game handlers added.
// //     // This safely replaces the channel subscription with game callbacks.
// //     // (No-op handlers in RoomProvider are replaced with active ones here.)
// //     _resubscribeWithGameHandlers();
// //   }

// //   void _resubscribeWithGameHandlers() {
// //     final userId = context.read<AuthProvider>().currentUser!.id;

// //     // Unsubscribe existing channel and re-subscribe with game callbacks merged
// //     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
// //       sl.realtimeService.subscribe(
// //         roomId: widget.roomId,
// //         // ── Game-specific handlers ─────────────────────────────────────────
// //         onGameState: (p) => _provider.onStateBroadcast(p),
// //         onPlayerAction: (p) => _provider.onPlayerAction(p),
// //         onSyncRequest: (p) => _provider.onSyncRequest(p),
// //         onGameStarted: (_) {},
// //         onGameEnded: (p) {
// //           // Admin ended the game — take everyone back to the lobby
// //           if (mounted) {
// //             ScaffoldMessenger.of(context).showSnackBar(
// //               const SnackBar(content: Text('The host ended the game')),
// //             );
// //             // Pop back to lobby (the LobbyScreen is still on the stack)
// //             if (context.canPop())
// //               context.pop();
// //             else
// //               context.go(RouteNames.home);
// //           }
// //         },
// //         // ── Room lifecycle (passthrough — RoomProvider is disposed) ─────────
// //         onRoomEvent: (p) {
// //           final type = p['type'] as String?;
// //           if (type == 'game_paused' && mounted) {
// //             WidgetsBinding.instance.addPostFrameCallback((_) {
// //               if (!mounted) return;
// //               showDialog(
// //                 context: context,
// //                 barrierDismissible: false,
// //                 builder: (ctx2) => AlertDialog(
// //                   title: const Text('⏸ Game Paused'),
// //                   content: const Text(
// //                     'The host paused the game and will return shortly.',
// //                   ),
// //                   actions: [
// //                     FilledButton(
// //                       onPressed: () {
// //                         Navigator.of(ctx2).pop();
// //                         AppRouter.router.go(RouteNames.home);
// //                       },
// //                       child: const Text('Leave for Now'),
// //                     ),
// //                   ],
// //                 ),
// //               );
// //             });
// //           }
// //           if ((type == 'room_closed' || type == 'owner_left') && mounted) {
// //             WidgetsBinding.instance.addPostFrameCallback((_) {
// //               if (mounted) {
// //                 showDialog(
// //                   context: context,
// //                   barrierDismissible: false,
// //                   builder: (ctx2) => AlertDialog(
// //                     title: const Text('Room Closed'),
// //                     content: const Text('The host closed the room.'),
// //                     actions: [
// //                       FilledButton(
// //                         onPressed: () {
// //                           Navigator.of(ctx2).pop();
// //                           AppRouter.router.go(RouteNames.home);
// //                         },
// //                         child: const Text('OK'),
// //                       ),
// //                     ],
// //                   ),
// //                 );
// //               } else {
// //                 AppRouter.router.go(RouteNames.home);
// //               }
// //             });
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
// //         // ── Presence ──────────────────────────────────────────────────────
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

// //     // If kicked or banned, navigate back to lobby
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
// //                 // Owner leaving game → end game for everyone, go back to lobby
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

// // // ── Scaffold with history support ─────────────────────────────────────────────

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
// //       onPopInvoked: (_) => _showLeaveDialog(context, game, state),
// //       child: Scaffold(
// //         appBar: AppBar(
// //           automaticallyImplyLeading: false,
// //           title: const Text(''),
// //           leading: IconButton(
// //             icon: const Icon(Icons.arrow_back),
// //             onPressed: () => _showLeaveDialog(context, game, state),
// //           ),
// //           actions: [
// //             // Chat button with unread badge
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
// //       ), // end Scaffold (PopScope child)
// //     ); // end PopScope
// //   }

// //   Future<void> _showLeaveDialog(
// //     BuildContext ctx,
// //     TodGameProvider game,
// //     TodState state,
// //   ) async {
// //     if (!ctx.mounted) return;
// //     final isOwner = widget.isOwner;

// //     if (isOwner) {
// //       // Owner: choose pause or end
// //       final choice = await showDialog<String>(
// //         context: ctx,
// //         builder: (_) => AlertDialog(
// //           title: const Text('Leave Game?'),
// //           content: const Text(
// //             "Choose what happens to the game while you're away.",
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.pop(ctx, 'cancel'),
// //               child: const Text('Stay'),
// //             ),
// //             FilledButton.tonal(
// //               onPressed: () => Navigator.pop(ctx, 'pause'),
// //               child: const Text('Pause & Return Later'),
// //             ),
// //             FilledButton(
// //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// //               onPressed: () => Navigator.pop(ctx, 'end'),
// //               child: const Text('End Game for Everyone'),
// //             ),
// //           ],
// //         ),
// //       );
// //       if (choice == null || choice == 'cancel' || !ctx.mounted) return;
// //       if (choice == 'pause') {
// //         try {
// //           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// //             'type': 'game_paused',
// //             'reason': 'host_away',
// //           });
// //           await sl.roomRepository.updateStatus(
// //             widget.roomId,
// //             RoomStatus.paused,
// //           );
// //         } catch (_) {}
// //         if (ctx.mounted) ctx.go(RouteNames.home);
// //       } else {
// //         // End game — broadcast owner_left so all get the dialog
// //         try {
// //           await sl.realtimeService.broadcastGameEnded(widget.roomId, {
// //             'reason': 'host_ended',
// //           });
// //           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
// //             'type': 'owner_left',
// //             'reason': 'host_ended',
// //           });
// //           await sl.roomRepository.updateStatus(
// //             widget.roomId,
// //             RoomStatus.closed,
// //           );
// //         } catch (_) {}
// //         if (ctx.mounted) ctx.go(RouteNames.home);
// //       }
// //     } else {
// //       // Player: choose to leave definitively or come back
// //       final choice = await showDialog<String>(
// //         context: ctx,
// //         builder: (_) => AlertDialog(
// //           title: const Text('Leave Game?'),
// //           content: const Text(
// //             'Are you leaving for good or will you come back?',
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.pop(ctx, 'cancel'),
// //               child: const Text('Stay'),
// //             ),
// //             FilledButton.tonal(
// //               onPressed: () => Navigator.pop(ctx, 'return'),
// //               child: const Text("I'll Return"),
// //             ),
// //             FilledButton(
// //               style: FilledButton.styleFrom(backgroundColor: Colors.red),
// //               onPressed: () => Navigator.pop(ctx, 'definitive'),
// //               child: const Text('Leave for Good'),
// //             ),
// //           ],
// //         ),
// //       );
// //       if (choice == null || choice == 'cancel' || !ctx.mounted) return;
// //       if (choice == 'return') {
// //         // Mark as away but keep seat — when they return they rejoin game
// //         try {
// //           await sl.roomRepository.setMemberAway(
// //             widget.roomId,
// //             game.currentUserId,
// //             away: true,
// //           );
// //         } catch (_) {}
// //         if (ctx.mounted) ctx.go(RouteNames.home);
// //       } else {
// //         // Definitively leave — mark as spectator-only for this room
// //         try {
// //           await sl.roomRepository.setMemberDefinitiveLeave(
// //             widget.roomId,
// //             game.currentUserId,
// //           );
// //         } catch (_) {}
// //         if (ctx.mounted) ctx.go(RouteNames.home);
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

// // // ── History panel ─────────────────────────────────────────────────────────────

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
// //         final round = history[history.length - 1 - i]; // newest first
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
// //                     // Card content
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
// //                     // Response
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
// //                     // Votes
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
// //                     // Proof image
// //                     if (round.proofImageB64.isNotEmpty) ...[
// //                       const SizedBox(height: 8),
// //                       _HistoryViewOnceImage(b64: round.proofImageB64),
// //                     ],
// //                     // Reactions
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

// // // View-once image for history (separate state per instance)
// // class _HistoryViewOnceImage extends StatefulWidget {
// //   const _HistoryViewOnceImage({required this.b64});
// //   final String b64;
// //   @override
// //   State<_HistoryViewOnceImage> createState() => _HistoryViewOnceImageState();
// // }

// // class _HistoryViewOnceImageState extends State<_HistoryViewOnceImage> {
// //   bool _revealed = false;
// //   bool _viewed = false;
// //   @override
// //   Widget build(BuildContext context) {
// //     if (_viewed) {
// //       return Container(
// //         height: 48,
// //         alignment: Alignment.centerLeft,
// //         child: Text(
// //           '📷 Proof viewed',
// //           style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
// //         ),
// //       );
// //     }
// //     if (!_revealed) {
// //       return GestureDetector(
// //         onTap: () => setState(() => _revealed = true),
// //         child: Container(
// //           height: 60,
// //           decoration: BoxDecoration(
// //             color: Colors.grey.shade200,
// //             borderRadius: BorderRadius.circular(8),
// //           ),
// //           alignment: Alignment.center,
// //           child: const Row(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               Icon(Icons.lock_outline, size: 16),
// //               SizedBox(width: 6),
// //               Text(
// //                 'Tap to view proof photo (once)',
// //                 style: TextStyle(fontSize: 12),
// //               ),
// //             ],
// //           ),
// //         ),
// //       );
// //     }
// //     return GestureDetector(
// //       onTap: () => setState(() => _viewed = true),
// //       child: ClipRRect(
// //         borderRadius: BorderRadius.circular(8),
// //         child: Stack(
// //           children: [
// //             Image.memory(
// //               base64Decode(widget.b64),
// //               height: 160,
// //               width: double.infinity,
// //               fit: BoxFit.cover,
// //             ),
// //             Positioned(
// //               bottom: 6,
// //               right: 6,
// //               child: Container(
// //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// //                 decoration: BoxDecoration(
// //                   color: Colors.black54,
// //                   borderRadius: BorderRadius.circular(12),
// //                 ),
// //                 child: const Text(
// //                   'Tap to dismiss',
// //                   style: TextStyle(color: Colors.white, fontSize: 11),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ── In-game chat sheet ─────────────────────────────────────────────────────────
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

// import 'dart:async';
// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:jma3a/core/router/app_router.dart';
// import 'package:jma3a/features/games/engine/base_game_engine.dart';
// import 'package:jma3a/features/rooms/domain/room_entity.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../../../../core/di/service_locator.dart';
// import '../../../../../core/extensions/context_ext.dart';
// import '../../../../../core/providers/auth_provider.dart';
// import '../../../../../core/router/route_names.dart';
// import '../../../../../core/services/realtime_service.dart';
// import '../../../../../core/theme/app_colors.dart';
// import '../../../../../shared/widgets/feedback/error_view.dart';
// import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// // import '../../engine/base_game_engine.dart';
// import '../../domain/tod_models.dart';
// import '../../tod_game_provider.dart';

// import '../../data/tod_repository.dart';
// import 'tod_card_screen.dart';
// import 'tod_end_screen.dart';
// import 'tod_loading_screen.dart';
// import 'tod_punishment_screen.dart';
// import '../widgets/tod_hud.dart';

// /// Entry point for an active Truth or Dare session.
// ///
// /// Responsibilities:
// ///  - Owns and scopes TodGameProvider for this session
// ///  - Wires RealtimeService callbacks → TodGameProvider
// ///  - Routes between loading / error / active / game-over screens
// ///  - Forwards game_state and player_action from the room Broadcast channel
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
//   final Map<String, String> playerDisplayNames; // userId → displayName
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

//   // Subscriptions to the room Broadcast channel
//   // (channel already open by RoomProvider — we just register callbacks)
//   StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

//   @override
//   void initState() {
//     super.initState();

//     final auth = context.read<AuthProvider>();
//     final user = auth.currentUser!;

//     _provider = TodGameProvider(
//       realtimeService: sl.realtimeService,
//       repository: TodRepository.instance,
//       currentUserId: user.id,
//       currentDisplayName: user.displayName ?? user.username ?? 'Player',
//       isModerator: widget.isModerator,
//     );

//     // ── Wire Broadcast callbacks ────────────────────────────────────────────
//     // The room channel is already subscribed by RoomProvider/LobbyScreen.
//     // TodGameScreen registers its own game-specific handlers for game_state
//     // and player_action by re-subscribing with extended handlers.
//     //
//     // We do this by using the RealtimeService._bcast pattern:
//     // The channel already has onGameState/onPlayerAction wired to no-ops
//     // in RoomProvider. We replace them here by storing callbacks and
//     // intercepting from the top-level channel via a dedicated subscription.
//     _wireRealtimeCallbacks();

//     if (widget.isOwner) {
//       _provider.initAsOwner(
//         roomId: widget.roomId,
//         config: widget.config,
//         playerIds: widget.playerIds,
//         playerDisplayNames: widget.playerDisplayNames,
//         packId: widget.packId,
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
//     _statusSub?.cancel();
//     _provider.dispose();
//     super.dispose();
//   }

//   /// Wire game-specific callbacks into the existing room channel.
//   ///
//   /// Strategy: re-subscribe to the room channel with updated handlers that
//   /// forward game_state and player_action to this provider.
//   /// The channel is already open; we track callbacks via a thin interceptor.
//   void _wireRealtimeCallbacks() {
//     // Listen to channel status changes for reconnection awareness
//     _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
//       status,
//     ) {
//       if (status == RealtimeSubscribeStatus.subscribed &&
//           !_provider.hasSyncedState) {
//         // Channel reconnected — request state sync
//         sl.realtimeService.broadcastSyncRequest(
//           widget.roomId,
//           context.read<AuthProvider>().currentUser!.id,
//           0,
//         );
//       }
//     });

//     // Re-subscribe with game handlers added.
//     // This safely replaces the channel subscription with game callbacks.
//     // (No-op handlers in RoomProvider are replaced with active ones here.)
//     _resubscribeWithGameHandlers();
//   }

//   void _resubscribeWithGameHandlers() {
//     final userId = context.read<AuthProvider>().currentUser!.id;

//     // Unsubscribe existing channel and re-subscribe with game callbacks merged
//     sl.realtimeService.unsubscribe(widget.roomId).then((_) {
//       sl.realtimeService.subscribe(
//         roomId: widget.roomId,
//         // ── Game-specific handlers ─────────────────────────────────────────
//         onGameState: (p) => _provider.onStateBroadcast(p),
//         onPlayerAction: (p) => _provider.onPlayerAction(p),
//         onSyncRequest: (p) => _provider.onSyncRequest(p),
//         onGameStarted: (_) {},
//         onGameEnded: (p) {
//           // Admin ended the game — take everyone back to the lobby
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('The host ended the game')),
//             );
//             // Pop back to lobby (the LobbyScreen is still on the stack)
//             if (context.canPop())
//               context.pop();
//             else
//               context.go(RouteNames.home);
//           }
//         },
//         // ── Room lifecycle (passthrough — RoomProvider is disposed) ─────────
//         onRoomEvent: (p) {
//           final type = p['type'] as String?;
//           if (type == 'game_paused' && mounted) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (!mounted) return;
//               showDialog(
//                 context: context,
//                 barrierDismissible: false,
//                 builder: (ctx2) => AlertDialog(
//                   title: const Text('⏸ Game Paused'),
//                   content: const Text(
//                     'The host paused the game and will return shortly.',
//                   ),
//                   actions: [
//                     FilledButton(
//                       onPressed: () {
//                         Navigator.of(ctx2).pop();
//                         AppRouter.router.go(RouteNames.home);
//                       },
//                       child: const Text('Leave for Now'),
//                     ),
//                   ],
//                 ),
//               );
//             });
//           }
//           if ((type == 'room_closed' || type == 'owner_left') && mounted) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (mounted) {
//                 showDialog(
//                   context: context,
//                   barrierDismissible: false,
//                   builder: (ctx2) => AlertDialog(
//                     title: const Text('Room Closed'),
//                     content: const Text('The host closed the room.'),
//                     actions: [
//                       FilledButton(
//                         onPressed: () {
//                           Navigator.of(ctx2).pop();
//                           AppRouter.router.go(RouteNames.home);
//                         },
//                         child: const Text('OK'),
//                       ),
//                     ],
//                   ),
//                 );
//               } else {
//                 AppRouter.router.go(RouteNames.home);
//               }
//             });
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
//         // ── Presence ──────────────────────────────────────────────────────
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

//     // If kicked or banned, navigate back to lobby
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
//                 // Owner leaving game → end game for everyone, go back to lobby
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

// // ── Scaffold with history support ─────────────────────────────────────────────

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
//       onPopInvoked: (_) => _showLeaveDialog(context, game, state),
//       child: Scaffold(
//         appBar: AppBar(
//           automaticallyImplyLeading: false,
//           title: const Text(''),
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () => _showLeaveDialog(context, game, state),
//           ),
//           actions: [
//             // Chat button with unread badge
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
//       ), // end Scaffold (PopScope child)
//     ); // end PopScope
//   }

//   Future<void> _showLeaveDialog(
//     BuildContext ctx,
//     TodGameProvider game,
//     TodState state,
//   ) async {
//     if (!ctx.mounted) return;
//     final isOwner = widget.isOwner;

//     if (isOwner) {
//       // Owner: choose pause or end
//       final choice = await showDialog<String>(
//         context: ctx,
//         builder: (_) => AlertDialog(
//           title: const Text('Leave Game?'),
//           content: const Text(
//             "Choose what happens to the game while you're away.",
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(ctx, 'cancel'),
//               child: const Text('Stay'),
//             ),
//             FilledButton.tonal(
//               onPressed: () => Navigator.pop(ctx, 'pause'),
//               child: const Text('Pause & Return Later'),
//             ),
//             FilledButton(
//               style: FilledButton.styleFrom(backgroundColor: Colors.red),
//               onPressed: () => Navigator.pop(ctx, 'end'),
//               child: const Text('End Game for Everyone'),
//             ),
//           ],
//         ),
//       );
//       if (choice == null || choice == 'cancel' || !ctx.mounted) return;
//       if (choice == 'pause') {
//         try {
//           // Set paused in DB FIRST so leaveRoom() won't delete the room
//           await sl.roomRepository.updateStatus(
//             widget.roomId,
//             RoomStatus.paused,
//           );
//           // Broadcast so other players see the pause dialog
//           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
//             'type': 'game_paused',
//             'reason': 'host_away',
//           });
//           // Small delay so broadcast reaches clients
//           await Future.delayed(const Duration(milliseconds: 300));
//         } catch (_) {}
//         if (ctx.mounted) ctx.go(RouteNames.home);
//       } else {
//         // End game — broadcast owner_left so all get the dialog
//         try {
//           await sl.realtimeService.broadcastGameEnded(widget.roomId, {
//             'reason': 'host_ended',
//           });
//           await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
//             'type': 'owner_left',
//             'reason': 'host_ended',
//           });
//           await sl.roomRepository.updateStatus(
//             widget.roomId,
//             RoomStatus.closed,
//           );
//         } catch (_) {}
//         if (ctx.mounted) ctx.go(RouteNames.home);
//       }
//     } else {
//       // Player: choose to leave definitively or come back
//       final choice = await showDialog<String>(
//         context: ctx,
//         builder: (_) => AlertDialog(
//           title: const Text('Leave Game?'),
//           content: const Text(
//             'Are you leaving for good or will you come back?',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(ctx, 'cancel'),
//               child: const Text('Stay'),
//             ),
//             FilledButton.tonal(
//               onPressed: () => Navigator.pop(ctx, 'return'),
//               child: const Text("I'll Return"),
//             ),
//             FilledButton(
//               style: FilledButton.styleFrom(backgroundColor: Colors.red),
//               onPressed: () => Navigator.pop(ctx, 'definitive'),
//               child: const Text('Leave for Good'),
//             ),
//           ],
//         ),
//       );
//       if (choice == null || choice == 'cancel' || !ctx.mounted) return;
//       if (choice == 'return') {
//         // Mark as away but keep seat — when they return they rejoin game
//         try {
//           await sl.roomRepository.setMemberAway(
//             widget.roomId,
//             game.currentUserId,
//             away: true,
//           );
//         } catch (_) {}
//         if (ctx.mounted) ctx.go(RouteNames.home);
//       } else {
//         // Definitively leave — mark as spectator-only for this room
//         try {
//           await sl.roomRepository.setMemberDefinitiveLeave(
//             widget.roomId,
//             game.currentUserId,
//           );
//         } catch (_) {}
//         if (ctx.mounted) ctx.go(RouteNames.home);
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

// // ── History panel ─────────────────────────────────────────────────────────────

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
//         final round = history[history.length - 1 - i]; // newest first
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
//                     // Card content
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
//                     // Response
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
//                     // Votes
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
//                     // Proof image
//                     if (round.proofImageB64.isNotEmpty) ...[
//                       const SizedBox(height: 8),
//                       _HistoryViewOnceImage(b64: round.proofImageB64),
//                     ],
//                     // Reactions
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

// // View-once image for history (separate state per instance)
// class _HistoryViewOnceImage extends StatefulWidget {
//   const _HistoryViewOnceImage({required this.b64});
//   final String b64;
//   @override
//   State<_HistoryViewOnceImage> createState() => _HistoryViewOnceImageState();
// }

// class _HistoryViewOnceImageState extends State<_HistoryViewOnceImage> {
//   bool _revealed = false;
//   bool _viewed = false;
//   @override
//   Widget build(BuildContext context) {
//     if (_viewed) {
//       return Container(
//         height: 48,
//         alignment: Alignment.centerLeft,
//         child: Text(
//           '📷 Proof viewed',
//           style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
//         ),
//       );
//     }
//     if (!_revealed) {
//       return GestureDetector(
//         onTap: () => setState(() => _revealed = true),
//         child: Container(
//           height: 60,
//           decoration: BoxDecoration(
//             color: Colors.grey.shade200,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           alignment: Alignment.center,
//           child: const Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(Icons.lock_outline, size: 16),
//               SizedBox(width: 6),
//               Text(
//                 'Tap to view proof photo (once)',
//                 style: TextStyle(fontSize: 12),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//     return GestureDetector(
//       onTap: () => setState(() => _viewed = true),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(8),
//         child: Stack(
//           children: [
//             Image.memory(
//               base64Decode(widget.b64),
//               height: 160,
//               width: double.infinity,
//               fit: BoxFit.cover,
//             ),
//             Positioned(
//               bottom: 6,
//               right: 6,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                 decoration: BoxDecoration(
//                   color: Colors.black54,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Text(
//                   'Tap to dismiss',
//                   style: TextStyle(color: Colors.white, fontSize: 11),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── In-game chat sheet ─────────────────────────────────────────────────────────
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

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:jma3a/core/router/app_router.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../../core/extensions/context_ext.dart';
import '../../../../../core/providers/auth_provider.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/services/realtime_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/feedback/error_view.dart';
import '../../../../../shared/widgets/overlays/confirm_dialog.dart';
// import '../../engine/base_game_engine.dart';
import '../../domain/tod_models.dart';
import '../../tod_game_provider.dart';

import '../../data/tod_repository.dart';
import 'tod_card_screen.dart';
import 'tod_end_screen.dart';
import 'tod_loading_screen.dart';
import 'tod_punishment_screen.dart';
import '../widgets/tod_hud.dart';

/// Entry point for an active Truth or Dare session.
///
/// Responsibilities:
///  - Owns and scopes TodGameProvider for this session
///  - Wires RealtimeService callbacks → TodGameProvider
///  - Routes between loading / error / active / game-over screens
///  - Forwards game_state and player_action from the room Broadcast channel
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
    this.packCoverUrl,
  });

  final String roomId;
  final GameConfig config;
  final List<String> playerIds;
  final Map<String, String> playerDisplayNames; // userId → displayName
  final String packId;
  final bool isOwner;
  final String? sessionId;
  final bool isModerator;
  final String? packCoverUrl;

  @override
  State<TodGameScreen> createState() => _TodGameScreenState();
}

class _TodGameScreenState extends State<TodGameScreen> {
  late final TodGameProvider _provider;

  // Subscriptions to the room Broadcast channel
  // (channel already open by RoomProvider — we just register callbacks)
  StreamSubscription<RealtimeSubscribeStatus>? _statusSub;

  @override
  void initState() {
    super.initState();

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;

    _provider = TodGameProvider(
      realtimeService: sl.realtimeService,
      repository: TodRepository.instance,
      currentUserId: user.id,
      currentDisplayName: user.displayName ?? user.username ?? 'Player',
      isModerator: widget.isModerator,
    );

    // ── Wire Broadcast callbacks ────────────────────────────────────────────
    // The room channel is already subscribed by RoomProvider/LobbyScreen.
    // TodGameScreen registers its own game-specific handlers for game_state
    // and player_action by re-subscribing with extended handlers.
    //
    // We do this by using the RealtimeService._bcast pattern:
    // The channel already has onGameState/onPlayerAction wired to no-ops
    // in RoomProvider. We replace them here by storing callbacks and
    // intercepting from the top-level channel via a dedicated subscription.
    _wireRealtimeCallbacks();

    if (widget.isOwner) {
      _provider.initAsOwner(
        roomId: widget.roomId,
        config: widget.config,
        playerIds: widget.playerIds,
        playerDisplayNames: widget.playerDisplayNames,
        packId: widget.packId,
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
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _provider.dispose();
    super.dispose();
  }

  /// Wire game-specific callbacks into the existing room channel.
  ///
  /// Strategy: re-subscribe to the room channel with updated handlers that
  /// forward game_state and player_action to this provider.
  /// The channel is already open; we track callbacks via a thin interceptor.
  void _wireRealtimeCallbacks() {
    // Listen to channel status changes for reconnection awareness
    _statusSub = sl.realtimeService.statusStream(widget.roomId)?.listen((
      status,
    ) {
      if (status == RealtimeSubscribeStatus.subscribed &&
          !_provider.hasSyncedState) {
        // Channel reconnected — request state sync
        sl.realtimeService.broadcastSyncRequest(
          widget.roomId,
          context.read<AuthProvider>().currentUser!.id,
          0,
        );
      }
    });

    // Re-subscribe with game handlers added.
    // This safely replaces the channel subscription with game callbacks.
    // (No-op handlers in RoomProvider are replaced with active ones here.)
    _resubscribeWithGameHandlers();
  }

  void _resubscribeWithGameHandlers() {
    final userId = context.read<AuthProvider>().currentUser!.id;

    // Unsubscribe existing channel and re-subscribe with game callbacks merged
    sl.realtimeService.unsubscribe(widget.roomId).then((_) {
      sl.realtimeService.subscribe(
        roomId: widget.roomId,
        // ── Game-specific handlers ─────────────────────────────────────────
        onGameState: (p) => _provider.onStateBroadcast(p),
        onPlayerAction: (p) => _provider.onPlayerAction(p),
        onSyncRequest: (p) => _provider.onSyncRequest(p),
        onGameStarted: (_) {},
        onGameEnded: (p) {
          // Admin ended the game — take everyone back to the lobby
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('The host ended the game')),
            );
            // Pop back to lobby (the LobbyScreen is still on the stack)
            if (context.canPop())
              context.pop();
            else
              context.go(RouteNames.home);
          }
        },
        // ── Room lifecycle (passthrough — RoomProvider is disposed) ─────────
        onRoomEvent: (p) {
          final type = p['type'] as String?;
          if (type == 'game_paused' && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx2) => AlertDialog(
                  title: const Text('⏸ Game Paused'),
                  content: const Text(
                    'The host paused the game and will return shortly.',
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () {
                        Navigator.of(ctx2).pop();
                        AppRouter.router.go(RouteNames.home);
                      },
                      child: const Text('Leave for Now'),
                    ),
                  ],
                ),
              );
            });
          }
          if ((type == 'room_closed' || type == 'owner_left') && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
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
              } else {
                AppRouter.router.go(RouteNames.home);
              }
            });
          }
        },
        onChatMessage: (p) {
          final msg = TodChatMsg(
            senderId: p['user_id'] as String? ?? '',
            senderName: p['display_name'] as String? ?? 'Player',
            text: p['content'] as String? ?? '',
            ts: DateTime.fromMillisecondsSinceEpoch(
              (p['ts'] as num?)?.toInt() ??
                  DateTime.now().millisecondsSinceEpoch,
            ),
          );
          _provider.addChatMessage(msg);
        },
        onModeration: (p) => _handleModerationEvent(p),
        onSettingsChange: (_) {},
        // ── Presence ──────────────────────────────────────────────────────
        onPresenceSync: (_) {},
        onPresenceJoin: (_) {},
        onPresenceLeave: (_) {},
        onStatusChange: (status) {
          if (!mounted) return;
          if (status == RealtimeSubscribeStatus.subscribed &&
              !_provider.hasSyncedState) {
            sl.realtimeService.broadcastSyncRequest(widget.roomId, userId, 0);
          }
        },
      );
    });
  }

  void _handleModerationEvent(Map<String, dynamic> p) {
    final type = p['type'] as String?;
    final targetId = p['target_user_id'] as String?;
    final currentId = context.read<AuthProvider>().currentUser?.id;

    // If kicked or banned, navigate back to lobby
    if ((type == 'kick' || type == 'ban') && targetId == currentId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You were removed from the room')),
        );
        context.go(RouteNames.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<TodGameProvider>(
        builder: (ctx, game, _) => _build(ctx, game),
      ),
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
                // Owner leaving game → end game for everyone, go back to lobby
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
        onLeave: () => ctx.go(RouteNames.home),
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

// ── Scaffold with history support ─────────────────────────────────────────────

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
      onPopInvoked: (_) => _showLeaveDialog(context, game, state),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(''),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _showLeaveDialog(context, game, state),
          ),
          actions: [
            // Chat button with unread badge
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
      ), // end Scaffold (PopScope child)
    ); // end PopScope
  }

  Future<void> _showLeaveDialog(
    BuildContext ctx,
    TodGameProvider game,
    TodState state,
  ) async {
    if (!ctx.mounted) return;
    final isOwner = widget.isOwner;

    if (isOwner) {
      // Owner: choose pause or end
      final choice = await showDialog<String>(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text('Leave Game?'),
          content: const Text(
            "Choose what happens to the game while you're away.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Stay'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx, 'pause'),
              child: const Text('Pause & Return Later'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, 'end'),
              child: const Text('End Game for Everyone'),
            ),
          ],
        ),
      );
      if (choice == null || choice == 'cancel' || !ctx.mounted) return;
      if (choice == 'pause') {
        try {
          // Set paused in DB FIRST — this is what leaveRoom() checks to avoid deletion
          await sl.roomRepository.updateStatus(
            widget.roomId,
            RoomStatus.paused,
          );
          // Broadcast pause event so other players see the dialog
          await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
            'type': 'game_paused',
            'reason': 'host_away',
          });
          // Wait for broadcast delivery before navigating
          await Future.delayed(const Duration(milliseconds: 600));
        } catch (_) {}
        // Navigate home — LobbyScreen will dispose RoomProvider, which calls
        // leaveRoom(); since DB status is now 'paused', it won't delete the room.
        if (ctx.mounted) ctx.go(RouteNames.home);
      } else {
        // End game — broadcast owner_left so all get the dialog
        try {
          await sl.realtimeService.broadcastGameEnded(widget.roomId, {
            'reason': 'host_ended',
          });
          await sl.realtimeService.broadcastRoomEvent(widget.roomId, {
            'type': 'owner_left',
            'reason': 'host_ended',
          });
          await sl.roomRepository.updateStatus(
            widget.roomId,
            RoomStatus.closed,
          );
        } catch (_) {}
        if (ctx.mounted) ctx.go(RouteNames.home);
      }
    } else {
      // Player: choose to leave definitively or come back
      final choice = await showDialog<String>(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text('Leave Game?'),
          content: const Text(
            'Are you leaving for good or will you come back?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Stay'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx, 'return'),
              child: const Text("I'll Return"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, 'definitive'),
              child: const Text('Leave for Good'),
            ),
          ],
        ),
      );
      if (choice == null || choice == 'cancel' || !ctx.mounted) return;
      if (choice == 'return') {
        // Mark as away but keep seat — when they return they rejoin game
        try {
          await sl.roomRepository.setMemberAway(
            widget.roomId,
            game.currentUserId,
            away: true,
          );
        } catch (_) {}
        if (ctx.mounted) ctx.go(RouteNames.home);
      } else {
        // Definitively leave — mark as spectator-only for this room
        try {
          await sl.roomRepository.setMemberDefinitiveLeave(
            widget.roomId,
            game.currentUserId,
          );
        } catch (_) {}
        if (ctx.mounted) ctx.go(RouteNames.home);
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

// ── History panel ─────────────────────────────────────────────────────────────

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
        final round = history[history.length - 1 - i]; // newest first
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
                    // Card content
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
                    // Response
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
                    // Votes
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
                    // Proof image
                    if (round.proofImageB64.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _HistoryViewOnceImage(b64: round.proofImageB64),
                    ],
                    // Reactions
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

// View-once image for history (separate state per instance)
class _HistoryViewOnceImage extends StatefulWidget {
  const _HistoryViewOnceImage({required this.b64});
  final String b64;
  @override
  State<_HistoryViewOnceImage> createState() => _HistoryViewOnceImageState();
}

class _HistoryViewOnceImageState extends State<_HistoryViewOnceImage> {
  bool _revealed = false;
  bool _viewed = false;
  @override
  Widget build(BuildContext context) {
    if (_viewed) {
      return Container(
        height: 48,
        alignment: Alignment.centerLeft,
        child: Text(
          '📷 Proof viewed',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      );
    }
    if (!_revealed) {
      return GestureDetector(
        onTap: () => setState(() => _revealed = true),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 16),
              SizedBox(width: 6),
              Text(
                'Tap to view proof photo (once)',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _viewed = true),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Image.memory(
              base64Decode(widget.b64),
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tap to dismiss',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── In-game chat sheet ─────────────────────────────────────────────────────────
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
