// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:jma3a/Sticker.dart';
// // import 'package:jma3a/core/router/app_router.dart';
// // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // import 'package:jma3a/features/games/meme_game/meme_game_engine.dart';
// // import 'package:jma3a/features/games/truth_or_dare/data/tod_repository.dart';
// // import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
// // import 'package:jma3a/features/packs/data/pack_repository.dart';
// // import 'package:jma3a/features/rooms/domain/room_entity.dart';
// // import 'package:provider/provider.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';

// // import '../../../../core/di/service_locator.dart';
// // import '../../../../core/extensions/context_ext.dart';
// // import '../../../../core/providers/auth_provider.dart';
// // import '../../../../core/router/route_names.dart';
// // import '../../../../core/services/realtime_service.dart';
// // import '../../../../core/theme/app_colors.dart';
// // import '../../../../core/utils/app_logger.dart';
// // // import '../../../games/engine/base_game_engine.dart';
// // // import '../../../games/truth_or_dare/data/tod_repository.dart';
// // // import '../../../packs/data/pack_repository.dart';
// // // import '../meme_game_engine.dart';
// // // import '../../../games/shared/stickers.dart';

// // // ── Provider ──────────────────────────────────────────────────────────────────

// // enum MemeLoadState { idle, loading, ready, error, gameOver }

// // class MemeGameProvider extends ChangeNotifier {
// //   MemeGameProvider({
// //     required RealtimeService realtimeService,
// //     required String          userId,
// //     required String          displayName,
// //   })  : _realtime    = realtimeService,
// //         _userId      = userId,
// //         _displayName = displayName;

// //   final RealtimeService _realtime;
// //   final String _userId, _displayName;
// //   MemeGameEngine? _engine;
// //   MemeLoadState _loadState = MemeLoadState.idle;
// //   String?  _roomId;
// //   bool     _isOwner = false;
// //   String   _error   = '';

// //   MemeLoadState get loadState => _loadState;
// //   MemeState?    get state     => _engine?.currentState as MemeState?;
// //   String        get userId    => _userId;
// //   bool          get isOwner   => _isOwner;
// //   String        get error     => _error;

// //   // ── Init ────────────────────────────────────────────────────────────────────

// //   Future<void> initAsOwner({
// //     required String roomId, required String packId,
// //     required List<String> playerIds, required Map<String,String> displayNames,
// //     required GameConfig config,
// //   }) async {
// //     _roomId = roomId; _isOwner = true;
// //     _loadState = MemeLoadState.loading;
// //     notifyListeners();
// //     try {
// //       var todCards = await TodRepository.instance.loadCardsFromCache(
// //           packId: packId, language: config.language);
// //       if (todCards.isEmpty) {
// //         final rows = await Supabase.instance.client
// //             .from('pack_cards')
// //             .select('id, content, card_type, difficulty, sort_order')
// //             .eq('pack_id', packId).order('sort_order');
// //         todCards = (rows as List).map((r) {
// //           String text = '';
// //           final raw = r['content'];
// //           if (raw is Map) {
// //             final m = Map<String, dynamic>.from(raw as Map);
// //             text = (m[config.language] ?? m['en'] ?? m.values.whereType<String>().firstOrNull ?? '') as String;
// //           } else if (raw is String) {
// //             try { final d = jsonDecode(raw); if (d is Map) text = (d[config.language] ?? d['en'] ?? '') as String; else text = raw; } catch (_) { text = raw; }
// //           }
// //           return TodCard(id: r['id'] as String, content: text, type: TodCardType.truth, difficulty: TodDifficulty.mild);
// //         }).toList();
// //       }
// //       final prompts = todCards.map((c) =>
// //           MemePrompt(id: c.id, caption: c.content)).toList();

// //       _engine = MemeGameEngine(config, prompts: prompts);
// //       _engine!.init(playerIds);
// //       _loadState = MemeLoadState.ready;
// //       notifyListeners();
// //       _broadcastState();
// //     } catch (e) {
// //       _error = e.toString(); _loadState = MemeLoadState.error;
// //       AppLogger.error('MemeProvider: init failed', error: e);
// //       notifyListeners();
// //     }
// //   }

// //   void initAsFollower(String roomId) {
// //     _roomId = roomId; _isOwner = false;
// //     _loadState = MemeLoadState.loading;
// //     notifyListeners();
// //   }

// //   // ── Actions ──────────────────────────────────────────────────────────────────

// //   Future<void> submit({String caption = '', String stickerChoice = ''}) =>
// //       _handleAction({'action': 'meme_submit', 'caption': caption, 'sticker_choice': stickerChoice});

// //   Future<void> voteFor(String targetUserId) =>
// //       _handleAction({'action': 'meme_vote', 'target_user_id': targetUserId});

// //   Future<void> reactTo(String targetUserId, String emoji) =>
// //       _handleAction({'action': 'meme_react', 'target_user_id': targetUserId, 'emoji': emoji});

// //   Future<void> ownerAdvanceTurn() async {
// //     if (!_isOwner || _engine == null) return;
// //     _engine!.advanceTurn();
// //     if (_engine!.isGameOver) _loadState = MemeLoadState.gameOver;
// //     notifyListeners();
// //     _broadcastState();
// //   }

// //   // ── Realtime ─────────────────────────────────────────────────────────────────

// //   void onStateBroadcast(Map<String, dynamic> payload) {
// //     if (_isOwner) return;
// //     try {
// //       final snap = (payload['snapshot'] as Map<String, dynamic>?)?['state'] as Map<String, dynamic>?
// //           ?? payload['state'] as Map<String, dynamic>?;
// //       if (snap == null) return;
// //       _engine ??= MemeGameEngine(
// //           const GameConfig(maxRounds: 10, turnTimerSeconds: 60,
// //               allowSkip: false, allowSpicy: false), prompts: []);
// //       _engine!.restoreFromSnapshot(snap);
// //       _loadState = _engine!.isGameOver ? MemeLoadState.gameOver : MemeLoadState.ready;
// //       notifyListeners();
// //     } catch (e) { AppLogger.warning('MemeProvider: restore failed: $e'); }
// //   }

// //   void onPlayerAction(Map<String, dynamic> payload) {
// //     if (!_isOwner || _engine == null) return;
// //     final action = payload['action'] as String?;
// //     final uid    = payload['user_id'] as String?;
// //     final ts     = payload['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
// //     if (uid == null) return;
// //     switch (action) {
// //       case 'meme_submit':
// //         _engine!.handleEvent(MemeSubmitEvent(
// //           userId: uid, ts: ts,
// //           caption:       payload['caption']       as String? ?? '',
// //           stickerChoice: payload['sticker_choice'] as String? ?? '',
// //         ));
// //       case 'meme_vote':
// //         _engine!.handleEvent(MemeVoteEvent(
// //           userId: uid, ts: ts,
// //           targetUserId: payload['target_user_id'] as String? ?? '',
// //         ));
// //       case 'meme_react':
// //         _engine!.handleEvent(MemeReactEvent(
// //           userId: uid, ts: ts,
// //           targetUserId: payload['target_user_id'] as String? ?? '',
// //           emoji:        payload['emoji']          as String? ?? '👍',
// //         ));
// //     }
// //     if (_engine!.isGameOver) _loadState = MemeLoadState.gameOver;
// //     notifyListeners();
// //     _broadcastState();
// //   }

// //   void onSyncRequest(Map<String, dynamic> _) { if (_isOwner) _broadcastState(); }

// //   Future<void> _handleAction(Map<String, dynamic> action) async {
// //     final full = {...action, 'user_id': _userId, 'display_name': _displayName,
// //         'ts': DateTime.now().millisecondsSinceEpoch};
// //     if (_isOwner && _engine != null) onPlayerAction(full);
// //     else if (_roomId != null) await _realtime.broadcastPlayerAction(_roomId!, full);
// //   }

// //   void _broadcastState() {
// //     if (_roomId == null || _engine == null) return;
// //     _realtime.broadcastGameState(_roomId!, {'state': _engine!.serializeState()}, _userId).ignore();
// //   }
// // }

// // // ── Screen ────────────────────────────────────────────────────────────────────

// // Future<void> memeShowLeaveDialog(BuildContext ctx, {required String roomId, required bool isOwner}) async {
// //   if (!ctx.mounted) return;
// //   final isOwner = isOwner;
// //   if (isOwner) {
// //     final choice = await showDialog<String>(
// //       context: ctx,
// //       builder: (d) => AlertDialog(
// //         title: const Text('Leave Game?'),
// //         content: const Text("Choose what happens while you're away."),
// //         actions: [
// //           TextButton(onPressed: () => Navigator.pop(d, 'cancel'), child: const Text('Stay')),
// //           FilledButton.tonal(onPressed: () => Navigator.pop(d, 'pause'), child: const Text('Pause & Return Later')),
// //           FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red),
// //               onPressed: () => Navigator.pop(d, 'end'), child: const Text('End Game for Everyone')),
// //         ],
// //       ),
// //     );
// //     if (choice == null || choice == 'cancel' || !ctx.mounted) return;
// //     if (choice == 'pause') {
// //       try {
// //         await sl.roomRepository.updateStatus(roomId, RoomStatus.paused);
// //         await sl.realtimeService.broadcastRoomEvent(roomId, {'type': 'game_paused', 'reason': 'host_away'});
// //         await Future.delayed(const Duration(milliseconds: 300));
// //       } catch (_) {}
// //       if (ctx.mounted) AppRouter.router.go(RouteNames.home);
// //     } else {
// //       try {
// //         await sl.realtimeService.broadcastGameEnded(roomId, {'reason': 'host_ended'});
// //         await sl.realtimeService.broadcastRoomEvent(roomId, {'type': 'owner_left', 'reason': 'host_ended'});
// //         await sl.roomRepository.updateStatus(roomId, RoomStatus.closed);
// //       } catch (_) {}
// //       if (ctx.mounted) AppRouter.router.go(RouteNames.home);
// //     }
// //   } else {
// //     final choice = await showDialog<String>(
// //       context: ctx,
// //       builder: (d) => AlertDialog(
// //         title: const Text('Leave Game?'),
// //         content: const Text('Are you leaving for good or will you come back?'),
// //         actions: [
// //           TextButton(onPressed: () => Navigator.pop(d, 'cancel'), child: const Text('Stay')),
// //           FilledButton.tonal(onPressed: () => Navigator.pop(d, 'return'), child: const Text("I'll Return")),
// //           FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red),
// //               onPressed: () => Navigator.pop(d, 'definitive'), child: const Text('Leave for Good')),
// //         ],
// //       ),
// //     );
// //     if (choice == null || choice == 'cancel' || !ctx.mounted) return;
// //     try {
// //       final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
// //       if (choice == 'return') {
// //         await sl.roomRepository.setMemberAway(roomId, uid, away: true);
// //       } else {
// //         await sl.roomRepository.setMemberDefinitiveLeave(roomId, uid);
// //       }
// //     } catch (_) {}
// //     if (ctx.mounted) AppRouter.router.go(RouteNames.home);
// //   }
// // }

// // class MemeGameScreen extends StatefulWidget {
// //   const MemeGameScreen({
// //     super.key,
// //     required this.roomId, required this.config, required this.playerIds,
// //     required this.playerDisplayNames, required this.packId,
// //     this.packCoverUrl,
// //     required this.isOwner, this.isModerator = false,
// //   });
// //   final String roomId; final GameConfig config;
// //   final List<String> playerIds; final Map<String,String> playerDisplayNames;
// //   final String packId; final bool isOwner; final bool isModerator;
// //   final String? packCoverUrl;
// //   @override State<MemeGameScreen> createState() => _MemeGameScreenState();
// // }

// // class _MemeGameScreenState extends State<MemeGameScreen> {
// //   late final MemeGameProvider _provider;

// //   @override
// //   void initState() {
// //     super.initState();
// //     final user = context.read<AuthProvider>().currentUser!;
// //     _provider = MemeGameProvider(
// //       realtimeService: sl.realtimeService,
// //       userId:      user.id,
// //       displayName: user.displayName ?? user.username ?? 'Player',
// //     );
// //     // Update callbacks on existing channel — no teardown needed
// //     sl.realtimeService.subscribe(
// //       roomId: widget.roomId,
// //       onGameState:    (p) => _provider.onStateBroadcast(p),
// //       onPlayerAction: (p) => _provider.onPlayerAction(p),
// //       onSyncRequest:  (p) => _provider.onSyncRequest(p),
// //       onGameStarted: (_) {}, onGameEnded: (p) {
// //           // Admin ended the game — take everyone back to the lobby
// //           if (mounted) {
// //             ScaffoldMessenger.of(context).showSnackBar(
// //               const SnackBar(content: Text('The host ended the game')));
// //             // Pop back to lobby (the LobbyScreen is still on the stack)
// //             if (context.canPop()) context.pop();
// //             else WidgetsBinding.instance.addPostFrameCallback((_) {
// //               if (mounted) showDialog(context: context, barrierDismissible: false,
// //                 builder: (ctx2) => AlertDialog(title: const Text('Room Closed'),
// //                   content: const Text('The host closed the room.'),
// //                   actions: [FilledButton(onPressed: () { Navigator.of(ctx2).pop(); AppRouter.router.go(RouteNames.home); }, child: const Text('OK'))]));
// //               else AppRouter.router.go(RouteNames.home);
// //             });
// //           }
// //         }, onRoomEvent: (p) {
// //           final type = p['type'] as String?;
// //           if (type == 'game_paused' && mounted) {
// //             WidgetsBinding.instance.addPostFrameCallback((_) {
// //               if (!mounted) return;
// //               showDialog(context: context, barrierDismissible: false,
// //                 builder: (ctx2) => AlertDialog(
// //                   title: const Text('⏸ Game Paused'),
// //                   content: const Text('The host paused the game and will return shortly.'),
// //                   actions: [FilledButton(onPressed: () { Navigator.of(ctx2).pop(); AppRouter.router.go(RouteNames.home); }, child: const Text('Leave for Now'))]));
// //             });
// //           }
// //           if ((type == 'room_closed' || type == 'owner_left') && mounted) {
// //             WidgetsBinding.instance.addPostFrameCallback((_) {
// //               if (mounted) showDialog(context: context, barrierDismissible: false,
// //                 builder: (ctx2) => AlertDialog(title: const Text('Room Closed'),
// //                   content: const Text('The host closed the room.'),
// //                   actions: [FilledButton(onPressed: () { Navigator.of(ctx2).pop(); AppRouter.router.go(RouteNames.home); }, child: const Text('OK'))]));
// //               else AppRouter.router.go(RouteNames.home);
// //             });
// //           }
// //         },
// //       onChatMessage: (_) {},
// //         onModeration: (p) {
// //           final type     = p['type'] as String?;
// //           final targetId = p['target_user_id'] as String?;
// //           final myId = context.read<AuthProvider>().currentUser?.id;
// //           if ((type == 'kick' || type == 'ban') && targetId == myId && mounted) {
// //             ScaffoldMessenger.of(context).showSnackBar(
// //                 SnackBar(content: Text(type == 'kick'
// //                     ? 'You were removed from the room'
// //                     : 'You were banned from this room')));
// //             context.go(RouteNames.home);
// //           }
// //         },
// //         onSettingsChange: (_) {},
// //       onPresenceSync: (_) {}, onPresenceJoin: (_) {}, onPresenceLeave: (_) {},
// //       onStatusChange: (_) {},
// //     );
// //     if (!widget.isOwner) {
// //       Future.delayed(const Duration(milliseconds: 300), _requestSync);
// //     }
// //     if (widget.isOwner) {
// //       _provider.initAsOwner(
// //         roomId: widget.roomId, packId: widget.packId,
// //         playerIds: widget.playerIds, displayNames: widget.playerDisplayNames,
// //         config: widget.config);
// //     } else {
// //       _provider.initAsFollower(widget.roomId);
// //     }
// //   }

// //   void _requestSync() {
// //     if (!mounted) return;
// //     sl.realtimeService.broadcastSyncRequest(widget.roomId, _provider.userId, 0).ignore();
// //     Future.delayed(const Duration(seconds: 1), () {
// //       if (mounted && _provider.loadState == MemeLoadState.loading) {
// //         sl.realtimeService.broadcastSyncRequest(widget.roomId, _provider.userId, 0).ignore();
// //       }
// //     });
// //     Future.delayed(const Duration(seconds: 3), () {
// //       if (mounted && _provider.loadState == MemeLoadState.loading) {
// //         sl.realtimeService.broadcastSyncRequest(widget.roomId, _provider.userId, 0).ignore();
// //       }
// //     });
// //   }

// //   @override void dispose() { _provider.dispose(); super.dispose(); }

// //   @override
// //   Widget build(BuildContext context) {
// //     return PopScope(
// //       canPop: false,
// //       onPopInvoked: (_) => memeShowLeaveDialog(context, roomId: widget.roomId, isOwner: widget.isOwner),
// //       child: ChangeNotifierProvider.value(
// //       value: _provider,
// //       child: Consumer<MemeGameProvider>(builder: (ctx, game, _) {
// //         if (game.loadState == MemeLoadState.loading)
// //           return const Scaffold(body: Center(child: CircularProgressIndicator()));
// //         if (game.loadState == MemeLoadState.error)
// //           return Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24),
// //               child: Text('Error: \${game.error}', textAlign: TextAlign.center))));
// //         if (game.loadState == MemeLoadState.gameOver)
// //           return _GameOverScreen(game: game, displayNames: widget.playerDisplayNames);
// //         final state = game.state;
// //         if (state == null)
// //           return const Scaffold(body: Center(child: CircularProgressIndicator()));
// //         return switch (state.phase) {
// //           MemePhase.submitting => _SubmitScreen(game: game, state: state, displayNames: widget.playerDisplayNames, packId: widget.packId, packCoverUrl: widget.packCoverUrl, roomId: widget.roomId, isOwner: widget.isOwner),
// //           MemePhase.voting     => _VotingScreen(game: game, state: state, displayNames: widget.playerDisplayNames, roomId: widget.roomId, isOwner: widget.isOwner),
// //           MemePhase.results    => _ResultsScreen(game: game, state: state, displayNames: widget.playerDisplayNames),
// //         };
// //       }),
// //       ),
// //     );
// //   }
// // }

// // // ── Shared helpers ────────────────────────────────────────────────────────────

// // String _nameOf(Map<String, String> names, String id) =>
// //     names[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

// // // Emoji reaction bar — uses shared EmojiReactionRow
// // class _ReactionBar extends StatelessWidget {
// //   const _ReactionBar({
// //     required this.targetUserId,
// //     required this.game,
// //     required this.reactions,
// //     required this.myId,
// //   });
// //   final String             targetUserId;
// //   final MemeGameProvider   game;
// //   final List<EmojiReaction> reactions;
// //   final String             myId;

// //   @override
// //   Widget build(BuildContext context) {
// //     final tally = <String, int>{};
// //     for (final r in reactions.where((r) => r.targetUserId == targetUserId)) {
// //       tally[r.emoji] = (tally[r.emoji] ?? 0) + 1;
// //     }
// //     final alreadyReacted = reactions.any(
// //         (r) => r.reactorId == myId && r.targetUserId == targetUserId);
// //     final isOwnSubmission = targetUserId == myId;

// //     return EmojiReactionRow(
// //       reactionsByEmoji: tally,
// //       alreadyReacted: alreadyReacted || isOwnSubmission,
// //       onReact: (emoji) => game.reactTo(targetUserId, emoji),
// //     );
// //   }
// // }

// // // Helper: renders a sticker from either a local asset path or a remote URL
// // Widget _stickerImg(String path, {double? height, BoxFit fit = BoxFit.contain}) {
// //   if (path.startsWith('http')) {
// //     return Image.network(path,
// //         height: height, fit: fit,
// //         errorBuilder: (_, __, ___) =>
// //             const Text('🎭', style: TextStyle(fontSize: 80)));
// //   }
// //   return Image.asset(path,
// //       height: height, fit: fit,
// //       errorBuilder: (_, __, ___) =>
// //           const Text('🎭', style: TextStyle(fontSize: 80)));
// // }

// // // ── Tappable sticker card ─────────────────────────────────────────────────────
// // // Shows sticker at medium size + optional caption. Tap to fullscreen expand.

// // class _TappableStickerCard extends StatefulWidget {
// //   const _TappableStickerCard({required this.assetPath, this.caption = ''});
// //   final String assetPath;
// //   final String caption;
// //   @override State<_TappableStickerCard> createState() => _TappableStickerCardState();
// // }

// // class _TappableStickerCardState extends State<_TappableStickerCard> {
// //   bool _expanded = false;

// //   void _showFullscreen() {
// //     showDialog(
// //       context: context,
// //       barrierColor: Colors.black87,
// //       builder: (_) => GestureDetector(
// //         onTap: () => Navigator.of(context).pop(),
// //         child: Scaffold(
// //           backgroundColor: Colors.transparent,
// //           body: Center(
// //             child: Padding(
// //               padding: const EdgeInsets.all(24),
// //               child: Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 children: [
// //                   ClipRRect(
// //                     borderRadius: BorderRadius.circular(16),
// //                     child: _stickerImg(widget.assetPath, fit: BoxFit.contain),
// //                   ),
// //                   if (widget.caption.isNotEmpty) ...[
// //                     const SizedBox(height: 16),
// //                     Container(
// //                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// //                       decoration: BoxDecoration(
// //                         color: Colors.white,
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       child: Text(widget.caption,
// //                           textAlign: TextAlign.center,
// //                           style: const TextStyle(
// //                               fontSize: 18, fontWeight: FontWeight.w600,
// //                               color: Colors.black87)),
// //                     ),
// //                   ],
// //                   const SizedBox(height: 16),
// //                   const Text('Tap anywhere to close',
// //                       style: TextStyle(color: Colors.white54, fontSize: 13)),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       onTap: _showFullscreen,
// //       child: Container(
// //         width: double.infinity,
// //         decoration: BoxDecoration(
// //           color: Theme.of(context).colorScheme.surfaceContainerHighest,
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         padding: const EdgeInsets.all(8),
// //         child: Column(children: [
// //           ClipRRect(
// //             borderRadius: BorderRadius.circular(8),
// //             child: _stickerImg(widget.assetPath, height: 140),
// //           ),
// //           if (widget.caption.isNotEmpty) ...[
// //             const SizedBox(height: 8),
// //             Text(widget.caption,
// //                 textAlign: TextAlign.center,
// //                 style: const TextStyle(
// //                     fontSize: 15, fontWeight: FontWeight.w600)),
// //           ],
// //           const SizedBox(height: 4),
// //           const Text('Tap to expand', style: TextStyle(fontSize: 11, color: Colors.grey)),
// //         ]),
// //       ),
// //     );
// //   }
// // }

// // // ── Submit screen ─────────────────────────────────────────────────────────────

// // class _SubmitScreen extends StatefulWidget {
// //   const _SubmitScreen({required this.game, required this.state, required this.displayNames, required this.packId, this.packCoverUrl, required this.roomId, required this.isOwner});
// //   final MemeGameProvider game; final MemeState state; final Map<String,String> displayNames;
// //   final String packId;
// //   final String? packCoverUrl;
// //   final String roomId;
// //   final bool   isOwner;
// //   @override State<_SubmitScreen> createState() => _SubmitScreenState();
// // }

// // class _SubmitScreenState extends State<_SubmitScreen> {
// //   final _captionCtrl   = TextEditingController();
// //   String _pickedSticker = '';
// //   List<String> _packReactions = [];  // custom pack reaction URLs
// //   bool _loadingReactions = true;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadPackReactions();
// //   }

// //   Future<void> _loadPackReactions() async {
// //     try {
// //       final urls = await PackRepository.instance.getPackReactions(widget.packId);
// //       AppLogger.info('MemeGame: loaded ${urls.length} pack reactions for ${widget.packId}');
// //       if (mounted) setState(() { _packReactions = urls; _loadingReactions = false; });
// //     } catch (e) {
// //       AppLogger.warning('MemeGame: failed to load pack reactions: $e');
// //       if (mounted) setState(() => _loadingReactions = false);
// //     }
// //   }

// //   @override void dispose() { _captionCtrl.dispose(); super.dispose(); }

// //   bool get _canSubmit => _pickedSticker.isNotEmpty; // sticker required

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme        = context.theme;
// //     final hasSubmitted = widget.state.submissions.containsKey(widget.game.userId);
// //     final submitted    = widget.state.submissions.length;
// //     final total        = widget.state.playerOrder.length;

// //     return Scaffold(
// //       resizeToAvoidBottomInset: false,
// //       appBar: AppBar(
// //         leading: BackButton(onPressed: () => memeShowLeaveDialog(context, roomId: widget.roomId, isOwner: widget.isOwner)),
// //         title: Text('Round ${widget.state.roundNumber} / ${widget.state.maxRounds}'),
// //       ),
// //       body: SingleChildScrollView(
// //         padding: EdgeInsets.fromLTRB(20, 20, 20,
// //             20 + MediaQuery.of(context).viewInsets.bottom),
// //         child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
// //           // Prompt card with background image
// //           ClipRRect(borderRadius: BorderRadius.circular(20), child: SizedBox(
// //             width: double.infinity,
// //             height: 160, child: Stack(fit: StackFit.expand, children: [
// //               Positioned.fill(child: widget.packCoverUrl != null && widget.packCoverUrl!.isNotEmpty
// //                   ? Image.network(widget.packCoverUrl!, fit: BoxFit.cover,
// //                       width: double.infinity, height: double.infinity,
// //                       errorBuilder: (_, __, ___) => Image.asset(
// //                           'assets/images/jma3a_card_background.png',
// //                           fit: BoxFit.cover, width: double.infinity, height: double.infinity))
// //                   : Image.asset('assets/images/jma3a_card_background.png',
// //                       fit: BoxFit.cover, width: double.infinity, height: double.infinity,
// //                       errorBuilder: (_, __, ___) => Container(color: AppColors.purple))),
// //               Positioned.fill(child: Container(decoration: BoxDecoration(
// //                   gradient: LinearGradient(
// //                       colors: [AppColors.purple.withOpacity(0.50),
// //                                const Color(0xFF0D1B2A).withOpacity(0.70)],
// //                       begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
// //               Center(child: Padding(
// //                 padding: const EdgeInsets.all(20),
// //                 child: Column(mainAxisSize: MainAxisSize.min, children: [
// //                   const Text('😂', style: TextStyle(fontSize: 44)),
// //                   const SizedBox(height: 10),
// //                   Text(widget.state.currentPrompt?.caption ?? '…',
// //                       textAlign: TextAlign.center,
// //                       style: const TextStyle(color: Colors.white, fontSize: 18,
// //                           fontWeight: FontWeight.w600, height: 1.4,
// //                           shadows: [Shadow(color: Colors.black54, blurRadius: 8)])),
// //                 ]),
// //               )),
// //             ])),
// //           ),
// //           const SizedBox(height: 12),

// //           Text('$submitted / $total submitted', textAlign: TextAlign.center,
// //               style: theme.textTheme.bodySmall?.copyWith(
// //                   color: theme.colorScheme.onSurfaceVariant)),
// //           const SizedBox(height: 12),

// //           if (!hasSubmitted) ...[
// //             // Sticker picker — required
// //             Text('Pick your sticker:',
// //                 style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
// //             const SizedBox(height: 8),
// //             // Expanded preview when a sticker is selected
// //             if (_pickedSticker.isNotEmpty)
// //               GestureDetector(
// //                 onTap: () => setState(() => _pickedSticker = ''),
// //                 child: Container(
// //                   width: double.infinity,
// //                   height: 200,
// //                   margin: const EdgeInsets.only(bottom: 8),
// //                   decoration: BoxDecoration(
// //                     color: Theme.of(context).colorScheme.surfaceContainerHighest,
// //                     borderRadius: BorderRadius.circular(16),
// //                     border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
// //                   ),
// //                   child: Stack(
// //                     alignment: Alignment.center,
// //                     children: [
// //                       ClipRRect(
// //                         borderRadius: BorderRadius.circular(14),
// //                         child: _stickerImg(_pickedSticker, height: 180),
// //                       ),
// //                       Positioned(top: 8, right: 8,
// //                         child: Container(
// //                           decoration: BoxDecoration(
// //                             color: Colors.black54, borderRadius: BorderRadius.circular(20)),
// //                           padding: const EdgeInsets.all(4),
// //                           child: const Icon(Icons.close, color: Colors.white, size: 18),
// //                         )),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             _loadingReactions
// //                 ? const Center(child: CircularProgressIndicator())
// //                 : StickerPicker(
// //               selected: _pickedSticker.isEmpty ? null : _pickedSticker,
// //               onSelect: (path) => setState(() => _pickedSticker = path),
// //               customUrls: _packReactions.isNotEmpty ? _packReactions : null,
// //               stickerSize: 64,
// //             ),
// //             const SizedBox(height: 12),

// //             // Caption (optional)
// //             TextField(
// //               controller: _captionCtrl,
// //               maxLines: 2, maxLength: 200,
// //               textCapitalization: TextCapitalization.sentences,
// //               decoration: const InputDecoration(
// //                 hintText: 'Add a caption (optional)…',
// //                 border: OutlineInputBorder(), counterText: ''),
// //               onChanged: (_) => setState(() {}),
// //             ),
// //             const SizedBox(height: 16),

// //             SizedBox(height: 52, child: FilledButton(
// //               onPressed: _canSubmit ? () => widget.game.submit(
// //                 caption: _captionCtrl.text.trim(),
// //                 stickerChoice: _pickedSticker,
// //               ) : null,
// //               child: Text(_pickedSticker.isEmpty ? 'Pick a sticker first' : 'Submit Response'),
// //             )),
// //           ] else ...[
// //             const SizedBox(height: 20),
// //             Container(
// //               padding: const EdgeInsets.symmetric(vertical: 24),
// //               decoration: BoxDecoration(
// //                   color: theme.colorScheme.surfaceContainerHighest,
// //                   borderRadius: BorderRadius.circular(12)),
// //               child: Column(children: [
// //                 const SizedBox(width: 24, height: 24,
// //                     child: CircularProgressIndicator(strokeWidth: 2)),
// //                 const SizedBox(height: 12),
// //                 Text('Response submitted! Waiting for others…',
// //                     textAlign: TextAlign.center,
// //                     style: theme.textTheme.bodyMedium),
// //               ]),
// //             ),
// //           ],
// //         ]),
// //       ),
// //     );
// //   }
// // }

// // // ── Voting screen ─────────────────────────────────────────────────────────────

// // class _VotingScreen extends StatelessWidget {
// //   const _VotingScreen({required this.game, required this.state, required this.displayNames, required this.roomId, required this.isOwner});
// //   final MemeGameProvider game; final MemeState state; final Map<String,String> displayNames;
// //   final String roomId; final bool isOwner;

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme    = context.theme;
// //     final hasVoted = state.votes.containsKey(game.userId);
// //     final entries  = state.submissions.entries.toList();

// //     return Scaffold(
// //       appBar: AppBar(
// //         leading: BackButton(onPressed: () => memeShowLeaveDialog(context, roomId: widget.roomId, isOwner: widget.isOwner)),
// //         title: const Text('Vote for the best! 😂'),
// //         bottom: PreferredSize(
// //           preferredSize: const Size.fromHeight(24),
// //           child: Text('${state.votes.length} / ${state.playerOrder.length} voted',
// //               style: theme.textTheme.bodySmall?.copyWith(
// //                   color: theme.colorScheme.onSurfaceVariant)),
// //         ),
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16),
// //         child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
// //           if (hasVoted)
// //             Container(
// //               margin: const EdgeInsets.only(bottom: 12),
// //               padding: const EdgeInsets.all(12),
// //               decoration: BoxDecoration(
// //                   color: theme.colorScheme.surfaceContainerHighest,
// //                   borderRadius: BorderRadius.circular(12)),
// //               child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
// //                 const SizedBox(width: 16, height: 16,
// //                     child: CircularProgressIndicator(strokeWidth: 2)),
// //                 const SizedBox(width: 12),
// //                 Text('Voted! Waiting for others…', style: theme.textTheme.bodyMedium),
// //               ]),
// //             ),
// //           Expanded(
// //             child: ListView.builder(
// //               itemCount: entries.length,
// //               itemBuilder: (_, i) {
// //                 final e       = entries[i];
// //                 final sub     = e.value;
// //                 final isOwn   = e.key == game.userId;
// //                 final isVoted = state.votes[game.userId] == e.key;

// //                 return Card(
// //                   margin: const EdgeInsets.only(bottom: 12),
// //                   child: Padding(
// //                     padding: const EdgeInsets.all(16),
// //                     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //                       Text('Response #${i + 1}',
// //                           style: theme.textTheme.labelMedium?.copyWith(
// //                               color: theme.colorScheme.onSurfaceVariant)),
// //                       const SizedBox(height: 8),
// //                       // Sticker choice
// //                       if (sub.stickerChoice.isNotEmpty)
// //                         _TappableStickerCard(
// //                           assetPath: sub.stickerChoice,
// //                           caption: sub.caption,
// //                         ),
// //                       // Caption
// //                       if (sub.caption.isNotEmpty)
// //                         Text(sub.caption,
// //                             style: theme.textTheme.bodyLarge?.copyWith(
// //                                 fontWeight: FontWeight.w600)),
// //                       const SizedBox(height: 12),
// //                       // Reaction bar
// //                       _ReactionBar(
// //                         targetUserId: e.key, game: game,
// //                         reactions: state.reactions, myId: game.userId),
// //                       const SizedBox(height: 10),
// //                       // Vote button
// //                       if (!hasVoted && !isOwn)
// //                         SizedBox(width: double.infinity, height: 42,
// //                           child: FilledButton(
// //                             onPressed: () => game.voteFor(e.key),
// //                             child: const Text('Vote for this 👍'),
// //                           )),
// //                       if (!hasVoted && isOwn)
// //                         Text('Your response', style: theme.textTheme.bodySmall?.copyWith(
// //                             color: theme.colorScheme.onSurfaceVariant)),
// //                       if (hasVoted && isVoted)
// //                         Container(
// //                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
// //                           decoration: BoxDecoration(
// //                             color: AppColors.successGreen.withOpacity(0.1),
// //                             borderRadius: BorderRadius.circular(8)),
// //                           child: const Text('✓ Your vote', style: TextStyle(
// //                               color: AppColors.successGreen, fontWeight: FontWeight.w600))),
// //                     ]),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //         ]),
// //       ),
// //     );
// //   }
// // }

// // // ── Results screen ────────────────────────────────────────────────────────────

// // class _ResultsScreen extends StatefulWidget {
// //   const _ResultsScreen({required this.game, required this.state, required this.displayNames});
// //   final MemeGameProvider game; final MemeState state; final Map<String,String> displayNames;
// //   @override State<_ResultsScreen> createState() => _ResultsScreenState();
// // }

// // class _ResultsScreenState extends State<_ResultsScreen> {
// //   bool _showHistory = false;

// //   @override
// //   Widget build(BuildContext context) {
// //     if (_showHistory) {
// //       return Scaffold(
// //         appBar: AppBar(title: const Text('Game History'),
// //             leading: BackButton(onPressed: () => setState(() => _showHistory = false))),
// //         body: _HistoryPanel(history: widget.state.history,
// //             displayNames: widget.displayNames,
// //             onClose: () => setState(() => _showHistory = false)),
// //       );
// //     }

// //     final theme    = context.theme;
// //     final state    = widget.state;
// //     final game     = widget.game;
// //     final winnerId = state.roundWinnerId;
// //     final tally    = <String, int>{};
// //     for (final t in state.votes.values) tally[t] = (tally[t] ?? 0) + 1;

// //     return Scaffold(
// //       appBar: AppBar(
// //         leading: BackButton(onPressed: () => memeShowLeaveDialog(context, roomId: widget.roomId, isOwner: widget.isOwner)),
// //         title: Text('Round ${state.roundNumber} Results 🏆'),
// //         actions: [
// //           if (state.history.isNotEmpty)
// //             IconButton(icon: const Icon(Icons.history_rounded),
// //                 onPressed: () => setState(() => _showHistory = true)),
// //         ],
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16),
// //         child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
// //           // Winner banner
// //           if (winnerId != null)
// //             Container(
// //               padding: const EdgeInsets.all(16),
// //               margin: const EdgeInsets.only(bottom: 16),
// //               decoration: BoxDecoration(
// //                 color: AppColors.amberOrangeLight.withOpacity(0.12),
// //                 borderRadius: BorderRadius.circular(14),
// //                 border: Border.all(color: AppColors.amberOrangeLight, width: 1.5)),
// //               child: Column(children: [
// //                 const Text('🏆', style: TextStyle(fontSize: 40)),
// //                 Text(_nameOf(widget.displayNames, winnerId),
// //                     style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
// //                 Text('wins this round!',
// //                     style: theme.textTheme.bodyMedium?.copyWith(
// //                         color: theme.colorScheme.onSurfaceVariant)),
// //                 if (state.submissions[winnerId]?.stickerChoice.isNotEmpty == true)
// //                   StickerDisplay(assetPath: state.submissions[winnerId]!.stickerChoice, size: 72),
// //                 if (state.submissions[winnerId]?.caption.isNotEmpty == true) ...[
// //                   const SizedBox(height: 4),
// //                   Text('"${state.submissions[winnerId]!.caption}"',
// //                       textAlign: TextAlign.center,
// //                       style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
// //                 ],
// //               ]),
// //             ),

// //           Expanded(
// //             child: ListView(children: state.submissions.entries.map((e) {
// //               final sub      = e.value;
// //               final votes    = tally[e.key] ?? 0;
// //               final isWinner = e.key == winnerId;
// //               return Card(
// //                 margin: const EdgeInsets.only(bottom: 10),
// //                 color: isWinner ? AppColors.amberOrangeLight.withOpacity(0.06) : null,
// //                 child: Padding(
// //                   padding: const EdgeInsets.all(14),
// //                   child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //                     Row(children: [
// //                       Text(_nameOf(widget.displayNames, e.key),
// //                           style: theme.textTheme.labelLarge?.copyWith(
// //                               fontWeight: FontWeight.w600,
// //                               color: isWinner ? AppColors.amberOrangeLight : null)),
// //                       if (isWinner) ...[const SizedBox(width: 4), const Text('🏆')],
// //                       const Spacer(),
// //                       Text('$votes 👍', style: theme.textTheme.labelLarge?.copyWith(
// //                           fontWeight: FontWeight.w700)),
// //                     ]),
// //                     const SizedBox(height: 8),
// //                     if (sub.stickerChoice.isNotEmpty)
// //                       _TappableStickerCard(assetPath: sub.stickerChoice, caption: sub.caption),
// //                     const SizedBox(height: 8),
// //                     // Reactions
// //                     _ReactionBar(targetUserId: e.key, game: game,
// //                         reactions: state.reactions, myId: game.userId),
// //                   ]),
// //                 ),
// //               );
// //             }).toList()),
// //           ),

// //           const Divider(),
// //           Text('Scores', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
// //           const SizedBox(height: 4),
// //           ...(state.scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
// //               .map((e) => Padding(
// //             padding: const EdgeInsets.symmetric(vertical: 2),
// //             child: Row(children: [
// //               Text(_nameOf(widget.displayNames, e.key), style: theme.textTheme.bodyMedium),
// //               const Spacer(),
// //               Text('${e.value} 🏆', style: theme.textTheme.bodyMedium?.copyWith(
// //                   fontWeight: FontWeight.w600)),
// //             ]),
// //           )),
// //           const SizedBox(height: 12),

// //           if (game.isOwner)
// //             SizedBox(height: 52, child: FilledButton(
// //               onPressed: game.ownerAdvanceTurn,
// //               child: const Text('Next Round →')))
// //           else
// //             Container(
// //               padding: const EdgeInsets.all(12),
// //               decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest,
// //                   borderRadius: BorderRadius.circular(12)),
// //               child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
// //                 const SizedBox(width: 16, height: 16,
// //                     child: CircularProgressIndicator(strokeWidth: 2)),
// //                 const SizedBox(width: 10),
// //                 Text('Waiting for host…', style: theme.textTheme.bodyMedium),
// //               ]),
// //             ),
// //         ]),
// //       ),
// //     );
// //   }
// // }

// // // ── History panel ─────────────────────────────────────────────────────────────

// // class _HistoryPanel extends StatelessWidget {
// //   const _HistoryPanel({required this.history, required this.displayNames, required this.onClose});
// //   final List<MemeRoundRecord> history;
// //   final Map<String, String>   displayNames;
// //   final VoidCallback          onClose;

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     return Column(children: [
// //       ListTile(
// //         leading: const Icon(Icons.history_rounded),
// //         title: Text('History (${history.length} rounds)',
// //             style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
// //         trailing: IconButton(icon: const Icon(Icons.close), onPressed: onClose),
// //       ),
// //       const Divider(height: 0),
// //       Expanded(
// //         child: ListView.builder(
// //           padding: const EdgeInsets.all(12),
// //           itemCount: history.length,
// //           itemBuilder: (_, i) {
// //             final round = history[history.length - 1 - i];
// //             return Card(
// //               margin: const EdgeInsets.only(bottom: 12),
// //               child: ExpansionTile(
// //                 leading: CircleAvatar(
// //                   backgroundColor: theme.colorScheme.primaryContainer,
// //                   child: Text('${round.roundNumber}', style: theme.textTheme.labelLarge)),
// //                 title: Text(round.prompt.caption,
// //                     style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
// //                     maxLines: 2, overflow: TextOverflow.ellipsis),
// //                 subtitle: Text('Winner: ${round.winnerId != null ? _nameOf(displayNames, round.winnerId!) : 'Tie'}',
// //                     style: theme.textTheme.bodySmall),
// //                 children: [
// //                   Padding(
// //                     padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: round.submissions.entries.map((e) {
// //                         final sub = e.value;
// //                         final reacts = round.reactions.where((r) => r.targetUserId == e.key).toList();
// //                         final reactTally = <String, int>{};
// //                         for (final r in reacts) reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
// //                         final isWinner = e.key == round.winnerId;
// //                         return Padding(
// //                           padding: const EdgeInsets.only(bottom: 10),
// //                           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //                             Row(children: [
// //                               Text(_nameOf(displayNames, e.key),
// //                                   style: theme.textTheme.bodySmall?.copyWith(
// //                                       fontWeight: FontWeight.w700,
// //                                       color: isWinner ? AppColors.amberOrangeLight : null)),
// //                               if (isWinner) const Text(' 🏆'),
// //                             ]),
// //                             if (sub.stickerChoice.isNotEmpty)
// //                               StickerDisplay(assetPath: sub.stickerChoice, size: 48),
// //                             if (sub.caption.isNotEmpty)
// //                               Text('"${sub.caption}"',
// //                                   style: theme.textTheme.bodySmall?.copyWith(
// //                                       fontStyle: FontStyle.italic)),
// //                             if (reactTally.isNotEmpty)
// //                               Padding(
// //                                 padding: const EdgeInsets.only(top: 4),
// //                                 child: Wrap(spacing: 4,
// //                                     children: reactTally.entries.map((r) =>
// //                                         Text('${r.key}${r.value}',
// //                                             style: const TextStyle(fontSize: 14))).toList()),
// //                               ),
// //                           ]),
// //                         );
// //                       }).toList(),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             );
// //           },
// //         ),
// //       ),
// //     ]);
// //   }
// // }

// // // ── Game over ─────────────────────────────────────────────────────────────────

// // class _GameOverScreen extends StatefulWidget {
// //   const _GameOverScreen({required this.game, required this.displayNames});
// //   final MemeGameProvider game; final Map<String,String> displayNames;
// //   @override State<_GameOverScreen> createState() => _GameOverScreenState();
// // }

// // class _GameOverScreenState extends State<_GameOverScreen> {
// //   bool _showHistory = false;

// //   @override
// //   Widget build(BuildContext context) {
// //     final scores  = widget.game.state?.scores ?? {};
// //     final history = widget.game.state?.history ?? [];
// //     final sorted  = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
// //     const medals  = ['🥇','🥈','🥉'];

// //     if (_showHistory) {
// //       return Scaffold(
// //         appBar: AppBar(title: const Text('Game History'),
// //             leading: BackButton(onPressed: () => setState(() => _showHistory = false))),
// //         body: _HistoryPanel(history: history, displayNames: widget.displayNames,
// //             onClose: () => setState(() => _showHistory = false)),
// //       );
// //     }

// //     return Scaffold(
// //       body: SafeArea(
// //         child: Padding(
// //           padding: const EdgeInsets.all(24),
// //           child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
// //             const Text('😂🏆', textAlign: TextAlign.center,
// //                 style: TextStyle(fontSize: 64)),
// //             Text('Game Over!', textAlign: TextAlign.center,
// //                 style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
// //             Text('Funniest player wins!', textAlign: TextAlign.center,
// //                 style: context.textTheme.bodyLarge?.copyWith(
// //                     color: context.colorScheme.onSurfaceVariant)),
// //             const SizedBox(height: 20),
// //             Expanded(child: ListView.builder(
// //               itemCount: sorted.length,
// //               itemBuilder: (_, i) {
// //                 final e = sorted[i];
// //                 return ListTile(
// //                   leading: Text(i < medals.length ? medals[i] : '${i+1}.',
// //                       style: const TextStyle(fontSize: 24)),
// //                   title: Text(_nameOf(widget.displayNames, e.key),
// //                       style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
// //                   trailing: Text('${e.value} 🏆',
// //                       style: context.textTheme.titleMedium?.copyWith(
// //                           color: AppColors.amberOrangeLight, fontWeight: FontWeight.w700)),
// //                 );
// //               },
// //             )),
// //             if (history.isNotEmpty) ...[
// //               OutlinedButton.icon(
// //                 onPressed: () => setState(() => _showHistory = true),
// //                 icon: const Icon(Icons.history_rounded),
// //                 label: Text('View History (${history.length} rounds)'),
// //               ),
// //               const SizedBox(height: 10),
// //             ],
// //             SizedBox(height: 52, child: FilledButton(
// //                 onPressed: () => context.go(RouteNames.home),
// //                 child: const Text('Back to Home'))),
// //           ]),
// //         ),
// //       ),
// //     );
// //   }
// // }

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:jma3a/Sticker.dart';
// import 'package:jma3a/core/router/app_router.dart';
// import 'package:jma3a/features/games/engine/base_game_engine.dart';
// import 'package:jma3a/features/games/meme_game/meme_game_engine.dart';
// import 'package:jma3a/features/games/truth_or_dare/data/tod_repository.dart';
// import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
// import 'package:jma3a/features/packs/data/pack_repository.dart';
// import 'package:jma3a/features/rooms/domain/room_entity.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../../../core/di/service_locator.dart';
// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/providers/auth_provider.dart';
// import '../../../../core/router/route_names.dart';
// import '../../../../core/services/realtime_service.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/utils/app_logger.dart';

// enum MemeLoadState { idle, loading, ready, error, gameOver }

// class MemeGameProvider extends ChangeNotifier {
//   MemeGameProvider({
//     required RealtimeService realtimeService,
//     required String          userId,
//     required String          displayName,
//   })  : _realtime    = realtimeService,
//         _userId      = userId,
//         _displayName = displayName;

//   final RealtimeService _realtime;
//   final String _userId, _displayName;
//   MemeGameEngine? _engine;
//   MemeLoadState _loadState = MemeLoadState.idle;
//   String?  _roomId;
//   bool     _isOwner = false;
//   String   _error   = '';

//   MemeLoadState get loadState => _loadState;
//   MemeState?    get state     => _engine?.currentState as MemeState?;
//   String        get userId    => _userId;
//   bool          get isOwner   => _isOwner;
//   String        get error     => _error;

//   // ── Init ────────────────────────────────────────────────────────────────────

//   Future<void> initAsOwner({
//     required String roomId, required String packId,
//     required List<String> playerIds, required Map<String,String> displayNames,
//     required GameConfig config,
//   }) async {
//     _roomId = roomId; _isOwner = true;
//     _loadState = MemeLoadState.loading;
//     notifyListeners();
//     try {
//       var todCards = await TodRepository.instance.loadCardsFromCache(
//           packId: packId, language: config.language);
//       if (todCards.isEmpty) {
//         final rows = await Supabase.instance.client
//             .from('pack_cards')
//             .select('id, content, card_type, difficulty, sort_order')
//             .eq('pack_id', packId).order('sort_order');
//         todCards = (rows as List).map((r) {
//           String text = '';
//           final raw = r['content'];
//           if (raw is Map) {
//             final m = Map<String, dynamic>.from(raw as Map);
//             text = (m[config.language] ?? m['en'] ?? m.values.whereType<String>().firstOrNull ?? '') as String;
//           } else if (raw is String) {
//             try { final d = jsonDecode(raw); if (d is Map) text = (d[config.language] ?? d['en'] ?? '') as String; else text = raw; } catch (_) { text = raw; }
//           }
//           return TodCard(id: r['id'] as String, content: text, type: TodCardType.truth, difficulty: TodDifficulty.mild);
//         }).toList();
//       }
//       final prompts = todCards.map((c) =>
//           MemePrompt(id: c.id, caption: c.content)).toList();

//       _engine = MemeGameEngine(config, prompts: prompts);
//       _engine!.init(playerIds);
//       _loadState = MemeLoadState.ready;
//       notifyListeners();
//       _broadcastState();
//     } catch (e) {
//       _error = e.toString(); _loadState = MemeLoadState.error;
//       AppLogger.error('MemeProvider: init failed', error: e);
//       notifyListeners();
//     }
//   }

//   void initAsFollower(String roomId) {
//     _roomId = roomId; _isOwner = false;
//     _loadState = MemeLoadState.loading;
//     notifyListeners();
//   }

//   // ── Actions ──────────────────────────────────────────────────────────────────

//   Future<void> submit({String caption = '', String stickerChoice = ''}) =>
//       _handleAction({'action': 'meme_submit', 'caption': caption, 'sticker_choice': stickerChoice});

//   Future<void> voteFor(String targetUserId) =>
//       _handleAction({'action': 'meme_vote', 'target_user_id': targetUserId});

//   Future<void> reactTo(String targetUserId, String emoji) =>
//       _handleAction({'action': 'meme_react', 'target_user_id': targetUserId, 'emoji': emoji});

//   Future<void> ownerAdvanceTurn() async {
//     if (!_isOwner || _engine == null) return;
//     _engine!.advanceTurn();
//     if (_engine!.isGameOver) _loadState = MemeLoadState.gameOver;
//     notifyListeners();
//     _broadcastState();
//   }

//   // ── Realtime ─────────────────────────────────────────────────────────────────

//   void onStateBroadcast(Map<String, dynamic> payload) {
//     if (_isOwner) return;
//     try {
//       final snap = (payload['snapshot'] as Map<String, dynamic>?)?['state'] as Map<String, dynamic>?
//           ?? payload['state'] as Map<String, dynamic>?;
//       if (snap == null) return;
//       _engine ??= MemeGameEngine(
//           const GameConfig(maxRounds: 10, turnTimerSeconds: 60,
//               allowSkip: false, allowSpicy: false), prompts: []);
//       _engine!.restoreFromSnapshot(snap);
//       _loadState = _engine!.isGameOver ? MemeLoadState.gameOver : MemeLoadState.ready;
//       notifyListeners();
//     } catch (e) { AppLogger.warning('MemeProvider: restore failed: $e'); }
//   }

//   void onPlayerAction(Map<String, dynamic> payload) {
//     if (!_isOwner || _engine == null) return;
//     final action = payload['action'] as String?;
//     final uid    = payload['user_id'] as String?;
//     final ts     = payload['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
//     if (uid == null) return;
//     switch (action) {
//       case 'meme_submit':
//         _engine!.handleEvent(MemeSubmitEvent(
//           userId: uid, ts: ts,
//           caption:       payload['caption']       as String? ?? '',
//           stickerChoice: payload['sticker_choice'] as String? ?? '',
//         ));
//       case 'meme_vote':
//         _engine!.handleEvent(MemeVoteEvent(
//           userId: uid, ts: ts,
//           targetUserId: payload['target_user_id'] as String? ?? '',
//         ));
//       case 'meme_react':
//         _engine!.handleEvent(MemeReactEvent(
//           userId: uid, ts: ts,
//           targetUserId: payload['target_user_id'] as String? ?? '',
//           emoji:        payload['emoji']          as String? ?? '👍',
//         ));
//     }
//     if (_engine!.isGameOver) _loadState = MemeLoadState.gameOver;
//     notifyListeners();
//     _broadcastState();
//   }

//   void onSyncRequest(Map<String, dynamic> _) { if (_isOwner) _broadcastState(); }

//   Future<void> _handleAction(Map<String, dynamic> action) async {
//     final full = {...action, 'user_id': _userId, 'display_name': _displayName,
//         'ts': DateTime.now().millisecondsSinceEpoch};
//     if (_isOwner && _engine != null) onPlayerAction(full);
//     else if (_roomId != null) await _realtime.broadcastPlayerAction(_roomId!, full);
//   }

//   void _broadcastState() {
//     if (_roomId == null || _engine == null) return;
//     _realtime.broadcastGameState(_roomId!, {'state': _engine!.serializeState()}, _userId).ignore();
//   }
// }

// Future<void> memeShowLeaveDialog(BuildContext ctx, {required String roomId, required bool isOwner}) async {
//   if (!ctx.mounted) return;
//   if (isOwner) {
//     final choice = await showDialog<String>(
//       context: ctx,
//       builder: (d) => AlertDialog(
//         title: const Text('Leave Game?'),
//         content: const Text("Choose what happens while you're away."),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(d, 'cancel'), child: const Text('Stay')),
//           FilledButton.tonal(onPressed: () => Navigator.pop(d, 'pause'), child: const Text('Pause & Return Later')),
//           FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red),
//               onPressed: () => Navigator.pop(d, 'end'), child: const Text('End Game for Everyone')),
//         ],
//       ),
//     );
//     if (choice == null || choice == 'cancel' || !ctx.mounted) return;
//     if (choice == 'pause') {
//       try {
//         await sl.roomRepository.updateStatus(roomId, RoomStatus.paused);
//         await sl.realtimeService.broadcastRoomEvent(roomId, {'type': 'game_paused', 'reason': 'host_away'});
//         await Future.delayed(const Duration(milliseconds: 300));
//       } catch (_) {}
//       if (ctx.mounted) AppRouter.router.go(RouteNames.home);
//     } else {
//       try {
//         await sl.realtimeService.broadcastGameEnded(roomId, {'reason': 'host_ended'});
//         await sl.realtimeService.broadcastRoomEvent(roomId, {'type': 'owner_left', 'reason': 'host_ended'});
//         await sl.roomRepository.updateStatus(roomId, RoomStatus.closed);
//       } catch (_) {}
//       if (ctx.mounted) AppRouter.router.go(RouteNames.home);
//     }
//   } else {
//     final choice = await showDialog<String>(
//       context: ctx,
//       builder: (d) => AlertDialog(
//         title: const Text('Leave Game?'),
//         content: const Text('Are you leaving for good or will you come back?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(d, 'cancel'), child: const Text('Stay')),
//           FilledButton.tonal(onPressed: () => Navigator.pop(d, 'return'), child: const Text("I'll Return")),
//           FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red),
//               onPressed: () => Navigator.pop(d, 'definitive'), child: const Text('Leave for Good')),
//         ],
//       ),
//     );
//     if (choice == null || choice == 'cancel' || !ctx.mounted) return;
//     try {
//       final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
//       if (choice == 'return') {
//         await sl.roomRepository.setMemberAway(roomId, uid, away: true);
//       } else {
//         await sl.roomRepository.setMemberDefinitiveLeave(roomId, uid);
//       }
//     } catch (_) {}
//     if (ctx.mounted) AppRouter.router.go(RouteNames.home);
//   }
// }

// class MemeGameScreen extends StatefulWidget {
//   const MemeGameScreen({
//     super.key,
//     required this.roomId, required this.config, required this.playerIds,
//     required this.playerDisplayNames, required this.packId,
//     this.packCoverUrl,
//     required this.isOwner, this.isModerator = false,
//   });
//   final String roomId; final GameConfig config;
//   final List<String> playerIds; final Map<String,String> playerDisplayNames;
//   final String packId; final bool isOwner; final bool isModerator;
//   final String? packCoverUrl;
//   @override State<MemeGameScreen> createState() => _MemeGameScreenState();
// }

// class _MemeGameScreenState extends State<MemeGameScreen> {
//   late final MemeGameProvider _provider;

//   @override
//   void initState() {
//     super.initState();
//     final user = context.read<AuthProvider>().currentUser!;
//     _provider = MemeGameProvider(
//       realtimeService: sl.realtimeService,
//       userId:      user.id,
//       displayName: user.displayName ?? user.username ?? 'Player',
//     );
//     // Update callbacks on existing channel — no teardown needed
//     sl.realtimeService.subscribe(
//       roomId: widget.roomId,
//       onGameState:    (p) => _provider.onStateBroadcast(p),
//       onPlayerAction: (p) => _provider.onPlayerAction(p),
//       onSyncRequest:  (p) => _provider.onSyncRequest(p),
//       onGameStarted: (_) {}, onGameEnded: (p) {
//           // Admin ended the game — take everyone back to the lobby
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('The host ended the game')));
//             // Pop back to lobby (the LobbyScreen is still on the stack)
//             if (context.canPop()) context.pop();
//             else WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (mounted) showDialog(context: context, barrierDismissible: false,
//                 builder: (ctx2) => AlertDialog(title: const Text('Room Closed'),
//                   content: const Text('The host closed the room.'),
//                   actions: [FilledButton(onPressed: () { Navigator.of(ctx2).pop(); AppRouter.router.go(RouteNames.home); }, child: const Text('OK'))]));
//               else AppRouter.router.go(RouteNames.home);
//             });
//           }
//         }, onRoomEvent: (p) {
//           final type = p['type'] as String?;
//           if (type == 'game_paused' && mounted) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (!mounted) return;
//               showDialog(context: context, barrierDismissible: false,
//                 builder: (ctx2) => AlertDialog(
//                   title: const Text('⏸ Game Paused'),
//                   content: const Text('The host paused the game and will return shortly.'),
//                   actions: [FilledButton(onPressed: () { Navigator.of(ctx2).pop(); AppRouter.router.go(RouteNames.home); }, child: const Text('Leave for Now'))]));
//             });
//           }
//           if ((type == 'room_closed' || type == 'owner_left') && mounted) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (mounted) showDialog(context: context, barrierDismissible: false,
//                 builder: (ctx2) => AlertDialog(title: const Text('Room Closed'),
//                   content: const Text('The host closed the room.'),
//                   actions: [FilledButton(onPressed: () { Navigator.of(ctx2).pop(); AppRouter.router.go(RouteNames.home); }, child: const Text('OK'))]));
//               else AppRouter.router.go(RouteNames.home);
//             });
//           }
//         },
//       onChatMessage: (_) {},
//         onModeration: (p) {
//           final type     = p['type'] as String?;
//           final targetId = p['target_user_id'] as String?;
//           final myId = context.read<AuthProvider>().currentUser?.id;
//           if ((type == 'kick' || type == 'ban') && targetId == myId && mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text(type == 'kick'
//                     ? 'You were removed from the room'
//                     : 'You were banned from this room')));
//             context.go(RouteNames.home);
//           }
//         },
//         onSettingsChange: (_) {},
//       onPresenceSync: (_) {}, onPresenceJoin: (_) {}, onPresenceLeave: (_) {},
//       onStatusChange: (_) {},
//     );
//     if (!widget.isOwner) {
//       Future.delayed(const Duration(milliseconds: 300), _requestSync);
//     }
//     if (widget.isOwner) {
//       _provider.initAsOwner(
//         roomId: widget.roomId, packId: widget.packId,
//         playerIds: widget.playerIds, displayNames: widget.playerDisplayNames,
//         config: widget.config);
//     } else {
//       _provider.initAsFollower(widget.roomId);
//     }
//   }

//   void _requestSync() {
//     if (!mounted) return;
//     sl.realtimeService.broadcastSyncRequest(widget.roomId, _provider.userId, 0).ignore();
//     Future.delayed(const Duration(seconds: 1), () {
//       if (mounted && _provider.loadState == MemeLoadState.loading) {
//         sl.realtimeService.broadcastSyncRequest(widget.roomId, _provider.userId, 0).ignore();
//       }
//     });
//     Future.delayed(const Duration(seconds: 3), () {
//       if (mounted && _provider.loadState == MemeLoadState.loading) {
//         sl.realtimeService.broadcastSyncRequest(widget.roomId, _provider.userId, 0).ignore();
//       }
//     });
//   }

//   @override void dispose() { _provider.dispose(); super.dispose(); }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvoked: (_) => memeShowLeaveDialog(context, roomId: widget.roomId, isOwner: widget.isOwner),
//       child: ChangeNotifierProvider.value(
//       value: _provider,
//       child: Consumer<MemeGameProvider>(builder: (ctx, game, _) {
//         if (game.loadState == MemeLoadState.loading)
//           return const Scaffold(body: Center(child: CircularProgressIndicator()));
//         if (game.loadState == MemeLoadState.error)
//           return Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24),
//               child: Text('Error: \${game.error}', textAlign: TextAlign.center))));
//         if (game.loadState == MemeLoadState.gameOver)
//           return _GameOverScreen(game: game, displayNames: widget.playerDisplayNames);
//         final state = game.state;
//         if (state == null)
//           return const Scaffold(body: Center(child: CircularProgressIndicator()));
//         return switch (state.phase) {
//           MemePhase.submitting => _SubmitScreen(game: game, state: state, displayNames: widget.playerDisplayNames, packId: widget.packId, packCoverUrl: widget.packCoverUrl, roomId: widget.roomId, isOwner: widget.isOwner),
//           MemePhase.voting     => _VotingScreen(game: game, state: state, displayNames: widget.playerDisplayNames, roomId: widget.roomId, isOwner: widget.isOwner),
//           MemePhase.results    => _ResultsScreen(game: game, state: state, displayNames: widget.playerDisplayNames, roomId: widget.roomId, isOwner: widget.isOwner),
//         };
//       }),
//       ),
//     );
//   }
// }

// // ── Shared helpers ────────────────────────────────────────────────────────────

// String _nameOf(Map<String, String> names, String id) =>
//     names[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

// // Emoji reaction bar — uses shared EmojiReactionRow
// class _ReactionBar extends StatelessWidget {
//   const _ReactionBar({
//     required this.targetUserId,
//     required this.game,
//     required this.reactions,
//     required this.myId,
//   });
//   final String             targetUserId;
//   final MemeGameProvider   game;
//   final List<EmojiReaction> reactions;
//   final String             myId;

//   @override
//   Widget build(BuildContext context) {
//     final tally = <String, int>{};
//     for (final r in reactions.where((r) => r.targetUserId == targetUserId)) {
//       tally[r.emoji] = (tally[r.emoji] ?? 0) + 1;
//     }
//     final alreadyReacted = reactions.any(
//         (r) => r.reactorId == myId && r.targetUserId == targetUserId);
//     final isOwnSubmission = targetUserId == myId;

//     return EmojiReactionRow(
//       reactionsByEmoji: tally,
//       alreadyReacted: alreadyReacted || isOwnSubmission,
//       onReact: (emoji) => game.reactTo(targetUserId, emoji),
//     );
//   }
// }

// // Helper: renders a sticker from either a local asset path or a remote URL
// Widget _stickerImg(String path, {double? height, BoxFit fit = BoxFit.contain}) {
//   if (path.startsWith('http')) {
//     return Image.network(path,
//         height: height, fit: fit,
//         errorBuilder: (_, __, ___) =>
//             const Text('🎭', style: TextStyle(fontSize: 80)));
//   }
//   return Image.asset(path,
//       height: height, fit: fit,
//       errorBuilder: (_, __, ___) =>
//           const Text('🎭', style: TextStyle(fontSize: 80)));
// }

// // ── Tappable sticker card ─────────────────────────────────────────────────────
// // Shows sticker at medium size + optional caption. Tap to fullscreen expand.

// class _TappableStickerCard extends StatefulWidget {
//   const _TappableStickerCard({required this.assetPath, this.caption = ''});
//   final String assetPath;
//   final String caption;
//   @override State<_TappableStickerCard> createState() => _TappableStickerCardState();
// }

// class _TappableStickerCardState extends State<_TappableStickerCard> {
//   bool _expanded = false;

//   void _showFullscreen() {
//     showDialog(
//       context: context,
//       barrierColor: Colors.black87,
//       builder: (_) => GestureDetector(
//         onTap: () => Navigator.of(context).pop(),
//         child: Scaffold(
//           backgroundColor: Colors.transparent,
//           body: Center(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: _stickerImg(widget.assetPath, fit: BoxFit.contain),
//                   ),
//                   if (widget.caption.isNotEmpty) ...[
//                     const SizedBox(height: 16),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(widget.caption,
//                           textAlign: TextAlign.center,
//                           style: const TextStyle(
//                               fontSize: 18, fontWeight: FontWeight.w600,
//                               color: Colors.black87)),
//                     ),
//                   ],
//                   const SizedBox(height: 16),
//                   const Text('Tap anywhere to close',
//                       style: TextStyle(color: Colors.white54, fontSize: 13)),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _showFullscreen,
//       child: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: Theme.of(context).colorScheme.surfaceContainerHighest,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         padding: const EdgeInsets.all(8),
//         child: Column(children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: _stickerImg(widget.assetPath, height: 140),
//           ),
//           if (widget.caption.isNotEmpty) ...[
//             const SizedBox(height: 8),
//             Text(widget.caption,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                     fontSize: 15, fontWeight: FontWeight.w600)),
//           ],
//           const SizedBox(height: 4),
//           const Text('Tap to expand', style: TextStyle(fontSize: 11, color: Colors.grey)),
//         ]),
//       ),
//     );
//   }
// }

// // ── Submit screen ─────────────────────────────────────────────────────────────

// class _SubmitScreen extends StatefulWidget {
//   const _SubmitScreen({required this.game, required this.state, required this.displayNames, required this.packId, this.packCoverUrl, required this.roomId, required this.isOwner});
//   final MemeGameProvider game; final MemeState state; final Map<String,String> displayNames;
//   final String packId;
//   final String? packCoverUrl;
//   final String roomId;
//   final bool   isOwner;
//   @override State<_SubmitScreen> createState() => _SubmitScreenState();
// }

// class _SubmitScreenState extends State<_SubmitScreen> {
//   final _captionCtrl   = TextEditingController();
//   String _pickedSticker = '';
//   List<String> _packReactions = [];  // custom pack reaction URLs
//   bool _loadingReactions = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadPackReactions();
//   }

//   Future<void> _loadPackReactions() async {
//     try {
//       final urls = await PackRepository.instance.getPackReactions(widget.packId);
//       AppLogger.info('MemeGame: loaded ${urls.length} pack reactions for ${widget.packId}');
//       if (mounted) setState(() { _packReactions = urls; _loadingReactions = false; });
//     } catch (e) {
//       AppLogger.warning('MemeGame: failed to load pack reactions: $e');
//       if (mounted) setState(() => _loadingReactions = false);
//     }
//   }

//   @override void dispose() { _captionCtrl.dispose(); super.dispose(); }

//   bool get _canSubmit => _pickedSticker.isNotEmpty; // sticker required

//   @override
//   Widget build(BuildContext context) {
//     final theme        = context.theme;
//     final hasSubmitted = widget.state.submissions.containsKey(widget.game.userId);
//     final submitted    = widget.state.submissions.length;
//     final total        = widget.state.playerOrder.length;

//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       appBar: AppBar(
//         leading: BackButton(onPressed: () => memeShowLeaveDialog(context, roomId: widget.roomId, isOwner: widget.isOwner)),
//         title: Text('Round ${widget.state.roundNumber} / ${widget.state.maxRounds}'),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.fromLTRB(20, 20, 20,
//             20 + MediaQuery.of(context).viewInsets.bottom),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
//           // Prompt card with background image
//           ClipRRect(borderRadius: BorderRadius.circular(20), child: SizedBox(
//             width: double.infinity,
//             height: 160, child: Stack(fit: StackFit.expand, children: [
//               Positioned.fill(child: widget.packCoverUrl != null && widget.packCoverUrl!.isNotEmpty
//                   ? Image.network(widget.packCoverUrl!, fit: BoxFit.cover,
//                       width: double.infinity, height: double.infinity,
//                       errorBuilder: (_, __, ___) => Image.asset(
//                           'assets/images/jma3a_card_background.png',
//                           fit: BoxFit.cover, width: double.infinity, height: double.infinity))
//                   : Image.asset('assets/images/jma3a_card_background.png',
//                       fit: BoxFit.cover, width: double.infinity, height: double.infinity,
//                       errorBuilder: (_, __, ___) => Container(color: AppColors.purple))),
//               Positioned.fill(child: Container(decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                       colors: [AppColors.purple.withOpacity(0.50),
//                                const Color(0xFF0D1B2A).withOpacity(0.70)],
//                       begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
//               Center(child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(mainAxisSize: MainAxisSize.min, children: [
//                   const Text('😂', style: TextStyle(fontSize: 44)),
//                   const SizedBox(height: 10),
//                   Text(widget.state.currentPrompt?.caption ?? '…',
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(color: Colors.white, fontSize: 18,
//                           fontWeight: FontWeight.w600, height: 1.4,
//                           shadows: [Shadow(color: Colors.black54, blurRadius: 8)])),
//                 ]),
//               )),
//             ])),
//           ),
//           const SizedBox(height: 12),

//           Text('$submitted / $total submitted', textAlign: TextAlign.center,
//               style: theme.textTheme.bodySmall?.copyWith(
//                   color: theme.colorScheme.onSurfaceVariant)),
//           const SizedBox(height: 12),

//           if (!hasSubmitted) ...[
//             // Sticker picker — required
//             Text('Pick your sticker:',
//                 style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
//             const SizedBox(height: 8),
//             // Expanded preview when a sticker is selected
//             if (_pickedSticker.isNotEmpty)
//               GestureDetector(
//                 onTap: () => setState(() => _pickedSticker = ''),
//                 child: Container(
//                   width: double.infinity,
//                   height: 200,
//                   margin: const EdgeInsets.only(bottom: 8),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).colorScheme.surfaceContainerHighest,
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
//                   ),
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(14),
//                         child: _stickerImg(_pickedSticker, height: 180),
//                       ),
//                       Positioned(top: 8, right: 8,
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color: Colors.black54, borderRadius: BorderRadius.circular(20)),
//                           padding: const EdgeInsets.all(4),
//                           child: const Icon(Icons.close, color: Colors.white, size: 18),
//                         )),
//                     ],
//                   ),
//                 ),
//               ),
//             _loadingReactions
//                 ? const Center(child: CircularProgressIndicator())
//                 : StickerPicker(
//               selected: _pickedSticker.isEmpty ? null : _pickedSticker,
//               onSelect: (path) => setState(() => _pickedSticker = path),
//               customUrls: _packReactions.isNotEmpty ? _packReactions : null,
//               stickerSize: 64,
//             ),
//             const SizedBox(height: 12),

//             // Caption (optional)
//             TextField(
//               controller: _captionCtrl,
//               maxLines: 2, maxLength: 200,
//               textCapitalization: TextCapitalization.sentences,
//               decoration: const InputDecoration(
//                 hintText: 'Add a caption (optional)…',
//                 border: OutlineInputBorder(), counterText: ''),
//               onChanged: (_) => setState(() {}),
//             ),
//             const SizedBox(height: 16),

//             SizedBox(height: 52, child: FilledButton(
//               onPressed: _canSubmit ? () => widget.game.submit(
//                 caption: _captionCtrl.text.trim(),
//                 stickerChoice: _pickedSticker,
//               ) : null,
//               child: Text(_pickedSticker.isEmpty ? 'Pick a sticker first' : 'Submit Response'),
//             )),
//           ] else ...[
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.symmetric(vertical: 24),
//               decoration: BoxDecoration(
//                   color: theme.colorScheme.surfaceContainerHighest,
//                   borderRadius: BorderRadius.circular(12)),
//               child: Column(children: [
//                 const SizedBox(width: 24, height: 24,
//                     child: CircularProgressIndicator(strokeWidth: 2)),
//                 const SizedBox(height: 12),
//                 Text('Response submitted! Waiting for others…',
//                     textAlign: TextAlign.center,
//                     style: theme.textTheme.bodyMedium),
//               ]),
//             ),
//           ],
//         ]),
//       ),
//     );
//   }
// }

// // ── Voting screen ─────────────────────────────────────────────────────────────

// class _VotingScreen extends StatelessWidget {
//   const _VotingScreen({required this.game, required this.state, required this.displayNames, required this.roomId, required this.isOwner});
//   final MemeGameProvider game; final MemeState state; final Map<String,String> displayNames;
//   final String roomId; final bool isOwner;

//   @override
//   Widget build(BuildContext context) {
//     final theme    = context.theme;
//     final hasVoted = state.votes.containsKey(game.userId);
//     final entries  = state.submissions.entries.toList();

//     return Scaffold(
//       appBar: AppBar(
//         leading: BackButton(onPressed: () => memeShowLeaveDialog(context, roomId: widget.roomId, isOwner: widget.isOwner)),
//         title: const Text('Vote for the best! 😂'),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(24),
//           child: Text('${state.votes.length} / ${state.playerOrder.length} voted',
//               style: theme.textTheme.bodySmall?.copyWith(
//                   color: theme.colorScheme.onSurfaceVariant)),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
//           if (hasVoted)
//             Container(
//               margin: const EdgeInsets.only(bottom: 12),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                   color: theme.colorScheme.surfaceContainerHighest,
//                   borderRadius: BorderRadius.circular(12)),
//               child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//                 const SizedBox(width: 16, height: 16,
//                     child: CircularProgressIndicator(strokeWidth: 2)),
//                 const SizedBox(width: 12),
//                 Text('Voted! Waiting for others…', style: theme.textTheme.bodyMedium),
//               ]),
//             ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: entries.length,
//               itemBuilder: (_, i) {
//                 final e       = entries[i];
//                 final sub     = e.value;
//                 final isOwn   = e.key == game.userId;
//                 final isVoted = state.votes[game.userId] == e.key;

//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                       Text('Response #${i + 1}',
//                           style: theme.textTheme.labelMedium?.copyWith(
//                               color: theme.colorScheme.onSurfaceVariant)),
//                       const SizedBox(height: 8),
//                       // Sticker choice
//                       if (sub.stickerChoice.isNotEmpty)
//                         _TappableStickerCard(
//                           assetPath: sub.stickerChoice,
//                           caption: sub.caption,
//                         ),
//                       // Caption
//                       if (sub.caption.isNotEmpty)
//                         Text(sub.caption,
//                             style: theme.textTheme.bodyLarge?.copyWith(
//                                 fontWeight: FontWeight.w600)),
//                       const SizedBox(height: 12),
//                       // Reaction bar
//                       _ReactionBar(
//                         targetUserId: e.key, game: game,
//                         reactions: state.reactions, myId: game.userId),
//                       const SizedBox(height: 10),
//                       // Vote button
//                       if (!hasVoted && !isOwn)
//                         SizedBox(width: double.infinity, height: 42,
//                           child: FilledButton(
//                             onPressed: () => game.voteFor(e.key),
//                             child: const Text('Vote for this 👍'),
//                           )),
//                       if (!hasVoted && isOwn)
//                         Text('Your response', style: theme.textTheme.bodySmall?.copyWith(
//                             color: theme.colorScheme.onSurfaceVariant)),
//                       if (hasVoted && isVoted)
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: AppColors.successGreen.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(8)),
//                           child: const Text('✓ Your vote', style: TextStyle(
//                               color: AppColors.successGreen, fontWeight: FontWeight.w600))),
//                     ]),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ]),
//       ),
//     );
//   }
// }

// // ── Results screen ────────────────────────────────────────────────────────────

// class _ResultsScreen extends StatefulWidget {
//   const _ResultsScreen({required this.game, required this.state, required this.displayNames, required this.roomId, required this.isOwner});
//   final MemeGameProvider game; final MemeState state; final Map<String,String> displayNames;
//   final String roomId; final bool isOwner;
//   @override State<_ResultsScreen> createState() => _ResultsScreenState();
// }

// class _ResultsScreenState extends State<_ResultsScreen> {
//   bool _showHistory = false;

//   @override
//   Widget build(BuildContext context) {
//     if (_showHistory) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Game History'),
//             leading: BackButton(onPressed: () => setState(() => _showHistory = false))),
//         body: _HistoryPanel(history: widget.state.history,
//             displayNames: widget.displayNames,
//             onClose: () => setState(() => _showHistory = false)),
//       );
//     }

//     final theme    = context.theme;
//     final state    = widget.state;
//     final game     = widget.game;
//     final winnerId = state.roundWinnerId;
//     final tally    = <String, int>{};
//     for (final t in state.votes.values) tally[t] = (tally[t] ?? 0) + 1;

//     return Scaffold(
//       appBar: AppBar(
//         leading: BackButton(onPressed: () => memeShowLeaveDialog(context, roomId: widget.roomId, isOwner: widget.isOwner)),
//         title: Text('Round ${state.roundNumber} Results 🏆'),
//         actions: [
//           if (state.history.isNotEmpty)
//             IconButton(icon: const Icon(Icons.history_rounded),
//                 onPressed: () => setState(() => _showHistory = true)),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
//           // Winner banner
//           if (winnerId != null)
//             Container(
//               padding: const EdgeInsets.all(16),
//               margin: const EdgeInsets.only(bottom: 16),
//               decoration: BoxDecoration(
//                 color: AppColors.amberOrangeLight.withOpacity(0.12),
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(color: AppColors.amberOrangeLight, width: 1.5)),
//               child: Column(children: [
//                 const Text('🏆', style: TextStyle(fontSize: 40)),
//                 Text(_nameOf(widget.displayNames, winnerId),
//                     style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
//                 Text('wins this round!',
//                     style: theme.textTheme.bodyMedium?.copyWith(
//                         color: theme.colorScheme.onSurfaceVariant)),
//                 if (state.submissions[winnerId]?.stickerChoice.isNotEmpty == true)
//                   StickerDisplay(assetPath: state.submissions[winnerId]!.stickerChoice, size: 72),
//                 if (state.submissions[winnerId]?.caption.isNotEmpty == true) ...[
//                   const SizedBox(height: 4),
//                   Text('"${state.submissions[winnerId]!.caption}"',
//                       textAlign: TextAlign.center,
//                       style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
//                 ],
//               ]),
//             ),

//           Expanded(
//             child: ListView(children: state.submissions.entries.map((e) {
//               final sub      = e.value;
//               final votes    = tally[e.key] ?? 0;
//               final isWinner = e.key == winnerId;
//               return Card(
//                 margin: const EdgeInsets.only(bottom: 10),
//                 color: isWinner ? AppColors.amberOrangeLight.withOpacity(0.06) : null,
//                 child: Padding(
//                   padding: const EdgeInsets.all(14),
//                   child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                     Row(children: [
//                       Text(_nameOf(widget.displayNames, e.key),
//                           style: theme.textTheme.labelLarge?.copyWith(
//                               fontWeight: FontWeight.w600,
//                               color: isWinner ? AppColors.amberOrangeLight : null)),
//                       if (isWinner) ...[const SizedBox(width: 4), const Text('🏆')],
//                       const Spacer(),
//                       Text('$votes 👍', style: theme.textTheme.labelLarge?.copyWith(
//                           fontWeight: FontWeight.w700)),
//                     ]),
//                     const SizedBox(height: 8),
//                     if (sub.stickerChoice.isNotEmpty)
//                       _TappableStickerCard(assetPath: sub.stickerChoice, caption: sub.caption),
//                     const SizedBox(height: 8),
//                     // Reactions
//                     _ReactionBar(targetUserId: e.key, game: game,
//                         reactions: state.reactions, myId: game.userId),
//                   ]),
//                 ),
//               );
//             }).toList()),
//           ),

//           const Divider(),
//           Text('Scores', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
//           const SizedBox(height: 4),
//           ...(state.scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
//               .map((e) => Padding(
//             padding: const EdgeInsets.symmetric(vertical: 2),
//             child: Row(children: [
//               Text(_nameOf(widget.displayNames, e.key), style: theme.textTheme.bodyMedium),
//               const Spacer(),
//               Text('${e.value} 🏆', style: theme.textTheme.bodyMedium?.copyWith(
//                   fontWeight: FontWeight.w600)),
//             ]),
//           )),
//           const SizedBox(height: 12),

//           if (game.isOwner)
//             SizedBox(height: 52, child: FilledButton(
//               onPressed: game.ownerAdvanceTurn,
//               child: const Text('Next Round →')))
//           else
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest,
//                   borderRadius: BorderRadius.circular(12)),
//               child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//                 const SizedBox(width: 16, height: 16,
//                     child: CircularProgressIndicator(strokeWidth: 2)),
//                 const SizedBox(width: 10),
//                 Text('Waiting for host…', style: theme.textTheme.bodyMedium),
//               ]),
//             ),
//         ]),
//       ),
//     );
//   }
// }

// // ── History panel ─────────────────────────────────────────────────────────────

// class _HistoryPanel extends StatelessWidget {
//   const _HistoryPanel({required this.history, required this.displayNames, required this.onClose});
//   final List<MemeRoundRecord> history;
//   final Map<String, String>   displayNames;
//   final VoidCallback          onClose;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     return Column(children: [
//       ListTile(
//         leading: const Icon(Icons.history_rounded),
//         title: Text('History (${history.length} rounds)',
//             style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
//         trailing: IconButton(icon: const Icon(Icons.close), onPressed: onClose),
//       ),
//       const Divider(height: 0),
//       Expanded(
//         child: ListView.builder(
//           padding: const EdgeInsets.all(12),
//           itemCount: history.length,
//           itemBuilder: (_, i) {
//             final round = history[history.length - 1 - i];
//             return Card(
//               margin: const EdgeInsets.only(bottom: 12),
//               child: ExpansionTile(
//                 leading: CircleAvatar(
//                   backgroundColor: theme.colorScheme.primaryContainer,
//                   child: Text('${round.roundNumber}', style: theme.textTheme.labelLarge)),
//                 title: Text(round.prompt.caption,
//                     style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
//                     maxLines: 2, overflow: TextOverflow.ellipsis),
//                 subtitle: Text('Winner: ${round.winnerId != null ? _nameOf(displayNames, round.winnerId!) : 'Tie'}',
//                     style: theme.textTheme.bodySmall),
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: round.submissions.entries.map((e) {
//                         final sub = e.value;
//                         final reacts = round.reactions.where((r) => r.targetUserId == e.key).toList();
//                         final reactTally = <String, int>{};
//                         for (final r in reacts) reactTally[r.emoji] = (reactTally[r.emoji] ?? 0) + 1;
//                         final isWinner = e.key == round.winnerId;
//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 10),
//                           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                             Row(children: [
//                               Text(_nameOf(displayNames, e.key),
//                                   style: theme.textTheme.bodySmall?.copyWith(
//                                       fontWeight: FontWeight.w700,
//                                       color: isWinner ? AppColors.amberOrangeLight : null)),
//                               if (isWinner) const Text(' 🏆'),
//                             ]),
//                             if (sub.stickerChoice.isNotEmpty)
//                               StickerDisplay(assetPath: sub.stickerChoice, size: 48),
//                             if (sub.caption.isNotEmpty)
//                               Text('"${sub.caption}"',
//                                   style: theme.textTheme.bodySmall?.copyWith(
//                                       fontStyle: FontStyle.italic)),
//                             if (reactTally.isNotEmpty)
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 4),
//                                 child: Wrap(spacing: 4,
//                                     children: reactTally.entries.map((r) =>
//                                         Text('${r.key}${r.value}',
//                                             style: const TextStyle(fontSize: 14))).toList()),
//                               ),
//                           ]),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     ]);
//   }
// }

// // ── Game over ─────────────────────────────────────────────────────────────────

// class _GameOverScreen extends StatefulWidget {
//   const _GameOverScreen({required this.game, required this.displayNames});
//   final MemeGameProvider game; final Map<String,String> displayNames;
//   @override State<_GameOverScreen> createState() => _GameOverScreenState();
// }

// class _GameOverScreenState extends State<_GameOverScreen> {
//   bool _showHistory = false;

//   @override
//   Widget build(BuildContext context) {
//     final scores  = widget.game.state?.scores ?? {};
//     final history = widget.game.state?.history ?? [];
//     final sorted  = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
//     const medals  = ['🥇','🥈','🥉'];

//     if (_showHistory) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Game History'),
//             leading: BackButton(onPressed: () => setState(() => _showHistory = false))),
//         body: _HistoryPanel(history: history, displayNames: widget.displayNames,
//             onClose: () => setState(() => _showHistory = false)),
//       );
//     }

//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
//             const Text('😂🏆', textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 64)),
//             Text('Game Over!', textAlign: TextAlign.center,
//                 style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
//             Text('Funniest player wins!', textAlign: TextAlign.center,
//                 style: context.textTheme.bodyLarge?.copyWith(
//                     color: context.colorScheme.onSurfaceVariant)),
//             const SizedBox(height: 20),
//             Expanded(child: ListView.builder(
//               itemCount: sorted.length,
//               itemBuilder: (_, i) {
//                 final e = sorted[i];
//                 return ListTile(
//                   leading: Text(i < medals.length ? medals[i] : '${i+1}.',
//                       style: const TextStyle(fontSize: 24)),
//                   title: Text(_nameOf(widget.displayNames, e.key),
//                       style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
//                   trailing: Text('${e.value} 🏆',
//                       style: context.textTheme.titleMedium?.copyWith(
//                           color: AppColors.amberOrangeLight, fontWeight: FontWeight.w700)),
//                 );
//               },
//             )),
//             if (history.isNotEmpty) ...[
//               OutlinedButton.icon(
//                 onPressed: () => setState(() => _showHistory = true),
//                 icon: const Icon(Icons.history_rounded),
//                 label: Text('View History (${history.length} rounds)'),
//               ),
//               const SizedBox(height: 10),
//             ],
//             SizedBox(height: 52, child: FilledButton(
//                 onPressed: () => context.go(RouteNames.home),
//                 child: const Text('Back to Home'))),
//           ]),
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jma3a/Sticker.dart';
import 'package:jma3a/core/router/app_router.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/meme_game/meme_game_engine.dart';
import 'package:jma3a/features/games/truth_or_dare/data/tod_repository.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
import 'package:jma3a/features/packs/data/pack_repository.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_logger.dart';

enum MemeLoadState { idle, loading, ready, error, gameOver }

class MemeGameProvider extends ChangeNotifier {
  MemeGameProvider({
    required RealtimeService realtimeService,
    required String userId,
    required String displayName,
  }) : _realtime = realtimeService,
       _userId = userId,
       _displayName = displayName;

  final RealtimeService _realtime;
  final String _userId, _displayName;
  MemeGameEngine? _engine;
  MemeLoadState _loadState = MemeLoadState.idle;
  String? _roomId;
  bool _isOwner = false;
  String _error = '';

  MemeLoadState get loadState => _loadState;
  MemeState? get state => _engine?.currentState as MemeState?;
  String get userId => _userId;
  bool get isOwner => _isOwner;
  String get error => _error;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> initAsOwner({
    required String roomId,
    required String packId,
    required List<String> playerIds,
    required Map<String, String> displayNames,
    required GameConfig config,
  }) async {
    _roomId = roomId;
    _isOwner = true;
    _loadState = MemeLoadState.loading;
    notifyListeners();
    try {
      var todCards = await TodRepository.instance.loadCardsFromCache(
        packId: packId,
        language: config.language,
      );
      if (todCards.isEmpty) {
        final rows = await Supabase.instance.client
            .from('pack_cards')
            .select('id, content, card_type, difficulty, sort_order')
            .eq('pack_id', packId)
            .order('sort_order');
        todCards = (rows as List).map((r) {
          String text = '';
          final raw = r['content'];
          if (raw is Map) {
            final m = Map<String, dynamic>.from(raw as Map);
            text =
                (m[config.language] ??
                        m['en'] ??
                        m.values.whereType<String>().firstOrNull ??
                        '')
                    as String;
          } else if (raw is String) {
            try {
              final d = jsonDecode(raw);
              if (d is Map)
                text = (d[config.language] ?? d['en'] ?? '') as String;
              else
                text = raw;
            } catch (_) {
              text = raw;
            }
          }
          return TodCard(
            id: r['id'] as String,
            content: text,
            type: TodCardType.truth,
            difficulty: TodDifficulty.mild,
          );
        }).toList();
      }
      final prompts = todCards
          .map((c) => MemePrompt(id: c.id, caption: c.content))
          .toList();

      _engine = MemeGameEngine(config, prompts: prompts);
      _engine!.init(playerIds);
      _loadState = MemeLoadState.ready;
      notifyListeners();
      _broadcastState();
    } catch (e) {
      _error = e.toString();
      _loadState = MemeLoadState.error;
      AppLogger.error('MemeProvider: init failed', error: e);
      notifyListeners();
    }
  }

  void initAsFollower(String roomId) {
    _roomId = roomId;
    _isOwner = false;
    _loadState = MemeLoadState.loading;
    notifyListeners();
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> submit({String caption = '', String stickerChoice = ''}) =>
      _handleAction({
        'action': 'meme_submit',
        'caption': caption,
        'sticker_choice': stickerChoice,
      });

  Future<void> voteFor(String targetUserId) =>
      _handleAction({'action': 'meme_vote', 'target_user_id': targetUserId});

  Future<void> reactTo(String targetUserId, String emoji) => _handleAction({
    'action': 'meme_react',
    'target_user_id': targetUserId,
    'emoji': emoji,
  });

  Future<void> ownerAdvanceTurn() async {
    if (!_isOwner || _engine == null) return;
    _engine!.advanceTurn();
    if (_engine!.isGameOver) _loadState = MemeLoadState.gameOver;
    notifyListeners();
    _broadcastState();
  }

  // ── Realtime ─────────────────────────────────────────────────────────────────

  void onStateBroadcast(Map<String, dynamic> payload) {
    if (_isOwner) return;
    try {
      final snap =
          (payload['snapshot'] as Map<String, dynamic>?)?['state']
              as Map<String, dynamic>? ??
          payload['state'] as Map<String, dynamic>?;
      if (snap == null) return;
      _engine ??= MemeGameEngine(
        const GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 60,
          allowSkip: false,
          allowSpicy: false,
        ),
        prompts: [],
      );
      _engine!.restoreFromSnapshot(snap);
      _loadState = _engine!.isGameOver
          ? MemeLoadState.gameOver
          : MemeLoadState.ready;
      notifyListeners();
    } catch (e) {
      AppLogger.warning('MemeProvider: restore failed: $e');
    }
  }

  void onPlayerAction(Map<String, dynamic> payload) {
    if (!_isOwner || _engine == null) return;
    final action = payload['action'] as String?;
    final uid = payload['user_id'] as String?;
    final ts = payload['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    if (uid == null) return;
    switch (action) {
      case 'meme_submit':
        _engine!.handleEvent(
          MemeSubmitEvent(
            userId: uid,
            ts: ts,
            caption: payload['caption'] as String? ?? '',
            stickerChoice: payload['sticker_choice'] as String? ?? '',
          ),
        );
      case 'meme_vote':
        _engine!.handleEvent(
          MemeVoteEvent(
            userId: uid,
            ts: ts,
            targetUserId: payload['target_user_id'] as String? ?? '',
          ),
        );
      case 'meme_react':
        _engine!.handleEvent(
          MemeReactEvent(
            userId: uid,
            ts: ts,
            targetUserId: payload['target_user_id'] as String? ?? '',
            emoji: payload['emoji'] as String? ?? '👍',
          ),
        );
    }
    if (_engine!.isGameOver) _loadState = MemeLoadState.gameOver;
    notifyListeners();
    _broadcastState();
  }

  void onSyncRequest(Map<String, dynamic> _) {
    if (_isOwner) _broadcastState();
  }

  Future<void> _handleAction(Map<String, dynamic> action) async {
    final full = {
      ...action,
      'user_id': _userId,
      'display_name': _displayName,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    if (_isOwner && _engine != null)
      onPlayerAction(full);
    else if (_roomId != null)
      await _realtime.broadcastPlayerAction(_roomId!, full);
  }

  void _broadcastState() {
    if (_roomId == null || _engine == null) return;
    _realtime.broadcastGameState(_roomId!, {
      'state': _engine!.serializeState(),
    }, _userId).ignore();
  }
}

Future<void> memeShowLeaveDialog(
  BuildContext ctx, {
  required String roomId,
  required bool isOwner,
}) async {
  if (!ctx.mounted) return;
  if (isOwner) {
    final choice = await showDialog<String>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Leave Game?'),
        content: const Text("Choose what happens while you're away."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, 'cancel'),
            child: const Text('Stay'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(d, 'pause'),
            child: const Text('Pause & Return Later'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(d, 'end'),
            child: const Text('End Game for Everyone'),
          ),
        ],
      ),
    );
    if (choice == null || choice == 'cancel' || !ctx.mounted) return;
    if (choice == 'pause') {
      try {
        await sl.roomRepository.updateStatus(roomId, RoomStatus.paused);
        await sl.realtimeService.broadcastRoomEvent(roomId, {
          'type': 'game_paused',
          'reason': 'host_away',
        });
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (_) {}
      if (ctx.mounted) AppRouter.router.go(RouteNames.home);
    } else {
      try {
        await sl.realtimeService.broadcastGameEnded(roomId, {
          'reason': 'host_ended',
        });
        await sl.realtimeService.broadcastRoomEvent(roomId, {
          'type': 'owner_left',
          'reason': 'host_ended',
        });
        await sl.roomRepository.updateStatus(roomId, RoomStatus.closed);
      } catch (_) {}
      if (ctx.mounted) AppRouter.router.go(RouteNames.home);
    }
  } else {
    final choice = await showDialog<String>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Leave Game?'),
        content: const Text('Are you leaving for good or will you come back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, 'cancel'),
            child: const Text('Stay'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(d, 'return'),
            child: const Text("I'll Return"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(d, 'definitive'),
            child: const Text('Leave for Good'),
          ),
        ],
      ),
    );
    if (choice == null || choice == 'cancel' || !ctx.mounted) return;
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
      if (choice == 'return') {
        await sl.roomRepository.setMemberAway(roomId, uid, away: true);
      } else {
        await sl.roomRepository.setMemberDefinitiveLeave(roomId, uid);
      }
    } catch (_) {}
    if (ctx.mounted) AppRouter.router.go(RouteNames.home);
  }
}

class MemeGameScreen extends StatefulWidget {
  const MemeGameScreen({
    super.key,
    required this.roomId,
    required this.config,
    required this.playerIds,
    required this.playerDisplayNames,
    required this.packId,
    this.packCoverUrl,
    required this.isOwner,
    this.isModerator = false,
  });
  final String roomId;
  final GameConfig config;
  final List<String> playerIds;
  final Map<String, String> playerDisplayNames;
  final String packId;
  final bool isOwner;
  final bool isModerator;
  final String? packCoverUrl;
  @override
  State<MemeGameScreen> createState() => _MemeGameScreenState();
}

class _MemeGameScreenState extends State<MemeGameScreen> {
  late final MemeGameProvider _provider;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser!;
    _provider = MemeGameProvider(
      realtimeService: sl.realtimeService,
      userId: user.id,
      displayName: user.displayName ?? user.username ?? 'Player',
    );
    // Update callbacks on existing channel — no teardown needed
    sl.realtimeService.subscribe(
      roomId: widget.roomId,
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted)
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
              else
                AppRouter.router.go(RouteNames.home);
            });
        }
      },
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
            if (mounted)
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
            else
              AppRouter.router.go(RouteNames.home);
          });
        }
      },
      onChatMessage: (_) {},
      onModeration: (p) {
        final type = p['type'] as String?;
        final targetId = p['target_user_id'] as String?;
        final myId = context.read<AuthProvider>().currentUser?.id;
        if ((type == 'kick' || type == 'ban') && targetId == myId && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                type == 'kick'
                    ? 'You were removed from the room'
                    : 'You were banned from this room',
              ),
            ),
          );
          context.go(RouteNames.home);
        }
      },
      onSettingsChange: (_) {},
      onPresenceSync: (_) {},
      onPresenceJoin: (_) {},
      onPresenceLeave: (_) {},
      onStatusChange: (_) {},
    );
    if (!widget.isOwner) {
      Future.delayed(const Duration(milliseconds: 300), _requestSync);
    }
    if (widget.isOwner) {
      _provider.initAsOwner(
        roomId: widget.roomId,
        packId: widget.packId,
        playerIds: widget.playerIds,
        displayNames: widget.playerDisplayNames,
        config: widget.config,
      );
    } else {
      _provider.initAsFollower(widget.roomId);
    }
  }

  void _requestSync() {
    if (!mounted) return;
    sl.realtimeService
        .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
        .ignore();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _provider.loadState == MemeLoadState.loading) {
        sl.realtimeService
            .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
            .ignore();
      }
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _provider.loadState == MemeLoadState.loading) {
        sl.realtimeService
            .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
            .ignore();
      }
    });
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) => memeShowLeaveDialog(
        context,
        roomId: widget.roomId,
        isOwner: widget.isOwner,
      ),
      child: ChangeNotifierProvider.value(
        value: _provider,
        child: Consumer<MemeGameProvider>(
          builder: (ctx, game, _) {
            if (game.loadState == MemeLoadState.loading)
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            if (game.loadState == MemeLoadState.error)
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: \${game.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            if (game.loadState == MemeLoadState.gameOver)
              return _GameOverScreen(
                game: game,
                displayNames: widget.playerDisplayNames,
              );
            final state = game.state;
            if (state == null)
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            return switch (state.phase) {
              MemePhase.submitting => _SubmitScreen(
                game: game,
                state: state,
                displayNames: widget.playerDisplayNames,
                packId: widget.packId,
                packCoverUrl: widget.packCoverUrl,
                roomId: widget.roomId,
                isOwner: widget.isOwner,
              ),
              MemePhase.voting => _VotingScreen(
                game: game,
                state: state,
                displayNames: widget.playerDisplayNames,
                roomId: widget.roomId,
                isOwner: widget.isOwner,
              ),
              MemePhase.results => _ResultsScreen(
                game: game,
                state: state,
                displayNames: widget.playerDisplayNames,
                roomId: widget.roomId,
                isOwner: widget.isOwner,
              ),
            };
          },
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

String _nameOf(Map<String, String> names, String id) =>
    names[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

// Emoji reaction bar — uses shared EmojiReactionRow
class _ReactionBar extends StatelessWidget {
  const _ReactionBar({
    required this.targetUserId,
    required this.game,
    required this.reactions,
    required this.myId,
  });
  final String targetUserId;
  final MemeGameProvider game;
  final List<EmojiReaction> reactions;
  final String myId;

  @override
  Widget build(BuildContext context) {
    final tally = <String, int>{};
    for (final r in reactions.where((r) => r.targetUserId == targetUserId)) {
      tally[r.emoji] = (tally[r.emoji] ?? 0) + 1;
    }
    final alreadyReacted = reactions.any(
      (r) => r.reactorId == myId && r.targetUserId == targetUserId,
    );
    final isOwnSubmission = targetUserId == myId;

    return EmojiReactionRow(
      reactionsByEmoji: tally,
      alreadyReacted: alreadyReacted || isOwnSubmission,
      onReact: (emoji) => game.reactTo(targetUserId, emoji),
    );
  }
}

// Helper: renders a sticker from either a local asset path or a remote URL
Widget _stickerImg(String path, {double? height, BoxFit fit = BoxFit.contain}) {
  if (path.startsWith('http')) {
    return Image.network(
      path,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          const Text('🎭', style: TextStyle(fontSize: 80)),
    );
  }
  return Image.asset(
    path,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) =>
        const Text('🎭', style: TextStyle(fontSize: 80)),
  );
}

// ── Tappable sticker card ─────────────────────────────────────────────────────
// Shows sticker at medium size + optional caption. Tap to fullscreen expand.

class _TappableStickerCard extends StatefulWidget {
  const _TappableStickerCard({required this.assetPath, this.caption = ''});
  final String assetPath;
  final String caption;
  @override
  State<_TappableStickerCard> createState() => _TappableStickerCardState();
}

class _TappableStickerCardState extends State<_TappableStickerCard> {
  bool _expanded = false;

  void _showFullscreen() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _stickerImg(widget.assetPath, fit: BoxFit.contain),
                  ),
                  if (widget.caption.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.caption,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Tap anywhere to close',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showFullscreen,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _stickerImg(widget.assetPath, height: 140),
            ),
            if (widget.caption.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.caption,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 4),
            const Text(
              'Tap to expand',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Submit screen ─────────────────────────────────────────────────────────────

class _SubmitScreen extends StatefulWidget {
  const _SubmitScreen({
    required this.game,
    required this.state,
    required this.displayNames,
    required this.packId,
    this.packCoverUrl,
    required this.roomId,
    required this.isOwner,
  });
  final MemeGameProvider game;
  final MemeState state;
  final Map<String, String> displayNames;
  final String packId;
  final String? packCoverUrl;
  final String roomId;
  final bool isOwner;
  @override
  State<_SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<_SubmitScreen> {
  final _captionCtrl = TextEditingController();
  String _pickedSticker = '';
  List<String> _packReactions = []; // custom pack reaction URLs
  bool _loadingReactions = true;

  @override
  void initState() {
    super.initState();
    _loadPackReactions();
  }

  Future<void> _loadPackReactions() async {
    try {
      final urls = await PackRepository.instance.getPackReactions(
        widget.packId,
      );
      AppLogger.info(
        'MemeGame: loaded ${urls.length} pack reactions for ${widget.packId}',
      );
      if (mounted)
        setState(() {
          _packReactions = urls;
          _loadingReactions = false;
        });
    } catch (e) {
      AppLogger.warning('MemeGame: failed to load pack reactions: $e');
      if (mounted) setState(() => _loadingReactions = false);
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => _pickedSticker.isNotEmpty; // sticker required

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final hasSubmitted = widget.state.submissions.containsKey(
      widget.game.userId,
    );
    final submitted = widget.state.submissions.length;
    final total = widget.state.playerOrder.length;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => memeShowLeaveDialog(
            context,
            roomId: widget.roomId,
            isOwner: widget.isOwner,
          ),
        ),
        title: Text(
          'Round ${widget.state.roundNumber} / ${widget.state.maxRounds}',
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prompt card with background image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: double.infinity,
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child:
                          widget.packCoverUrl != null &&
                              widget.packCoverUrl!.isNotEmpty
                          ? Image.network(
                              widget.packCoverUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/jma3a_card_background.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                          : Image.asset(
                              'assets/images/jma3a_card_background.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: AppColors.purple),
                            ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.purple.withOpacity(0.50),
                              const Color(0xFF0D1B2A).withOpacity(0.70),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('😂', style: TextStyle(fontSize: 44)),
                            const SizedBox(height: 10),
                            Text(
                              widget.state.currentPrompt?.caption ?? '…',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              '$submitted / $total submitted',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            if (!hasSubmitted) ...[
              // Sticker picker — required
              Text(
                'Pick your sticker:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              // Expanded preview when a sticker is selected
              if (_pickedSticker.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _pickedSticker = ''),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _stickerImg(_pickedSticker, height: 180),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              _loadingReactions
                  ? const Center(child: CircularProgressIndicator())
                  : StickerPicker(
                      selected: _pickedSticker.isEmpty ? null : _pickedSticker,
                      onSelect: (path) => setState(() => _pickedSticker = path),
                      customUrls: _packReactions.isNotEmpty
                          ? _packReactions
                          : null,
                      stickerSize: 64,
                    ),
              const SizedBox(height: 12),

              // Caption (optional)
              TextField(
                controller: _captionCtrl,
                maxLines: 2,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Add a caption (optional)…',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _canSubmit
                      ? () => widget.game.submit(
                          caption: _captionCtrl.text.trim(),
                          stickerChoice: _pickedSticker,
                        )
                      : null,
                  child: Text(
                    _pickedSticker.isEmpty
                        ? 'Pick a sticker first'
                        : 'Submit Response',
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Response submitted! Waiting for others…',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Voting screen ─────────────────────────────────────────────────────────────

class _VotingScreen extends StatelessWidget {
  const _VotingScreen({
    required this.game,
    required this.state,
    required this.displayNames,
    required this.roomId,
    required this.isOwner,
  });
  final MemeGameProvider game;
  final MemeState state;
  final Map<String, String> displayNames;
  final String roomId;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final hasVoted = state.votes.containsKey(game.userId);
    final entries = state.submissions.entries.toList();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              memeShowLeaveDialog(context, roomId: roomId, isOwner: isOwner),
        ),
        title: const Text('Vote for the best! 😂'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Text(
            '${state.votes.length} / ${state.playerOrder.length} voted',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasVoted)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Voted! Waiting for others…',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (_, i) {
                  final e = entries[i];
                  final sub = e.value;
                  final isOwn = e.key == game.userId;
                  final isVoted = state.votes[game.userId] == e.key;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Response #${i + 1}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Sticker choice
                          if (sub.stickerChoice.isNotEmpty)
                            _TappableStickerCard(
                              assetPath: sub.stickerChoice,
                              caption: sub.caption,
                            ),
                          // Caption
                          if (sub.caption.isNotEmpty)
                            Text(
                              sub.caption,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const SizedBox(height: 12),
                          // Reaction bar
                          _ReactionBar(
                            targetUserId: e.key,
                            game: game,
                            reactions: state.reactions,
                            myId: game.userId,
                          ),
                          const SizedBox(height: 10),
                          // Vote button
                          if (!hasVoted && !isOwn)
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: FilledButton(
                                onPressed: () => game.voteFor(e.key),
                                child: const Text('Vote for this 👍'),
                              ),
                            ),
                          if (!hasVoted && isOwn)
                            Text(
                              'Your response',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          if (hasVoted && isVoted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.successGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '✓ Your vote',
                                style: TextStyle(
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Results screen ────────────────────────────────────────────────────────────

class _ResultsScreen extends StatefulWidget {
  const _ResultsScreen({
    required this.game,
    required this.state,
    required this.displayNames,
    required this.roomId,
    required this.isOwner,
  });
  final MemeGameProvider game;
  final MemeState state;
  final Map<String, String> displayNames;
  final String roomId;
  final bool isOwner;
  @override
  State<_ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<_ResultsScreen> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    if (_showHistory) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Game History'),
          leading: BackButton(
            onPressed: () => setState(() => _showHistory = false),
          ),
        ),
        body: _HistoryPanel(
          history: widget.state.history,
          displayNames: widget.displayNames,
          onClose: () => setState(() => _showHistory = false),
        ),
      );
    }

    final theme = context.theme;
    final state = widget.state;
    final game = widget.game;
    final winnerId = state.roundWinnerId;
    final tally = <String, int>{};
    for (final t in state.votes.values) tally[t] = (tally[t] ?? 0) + 1;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => memeShowLeaveDialog(
            context,
            roomId: widget.roomId,
            isOwner: widget.isOwner,
          ),
        ),
        title: Text('Round ${state.roundNumber} Results 🏆'),
        actions: [
          if (state.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history_rounded),
              onPressed: () => setState(() => _showHistory = true),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Winner banner
            if (winnerId != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.amberOrangeLight.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.amberOrangeLight,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 40)),
                    Text(
                      _nameOf(widget.displayNames, winnerId),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'wins this round!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (state.submissions[winnerId]?.stickerChoice.isNotEmpty ==
                        true)
                      StickerDisplay(
                        assetPath: state.submissions[winnerId]!.stickerChoice,
                        size: 72,
                      ),
                    if (state.submissions[winnerId]?.caption.isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 4),
                      Text(
                        '"${state.submissions[winnerId]!.caption}"',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            Expanded(
              child: ListView(
                children: state.submissions.entries.map((e) {
                  final sub = e.value;
                  final votes = tally[e.key] ?? 0;
                  final isWinner = e.key == winnerId;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: isWinner
                        ? AppColors.amberOrangeLight.withOpacity(0.06)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _nameOf(widget.displayNames, e.key),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isWinner
                                      ? AppColors.amberOrangeLight
                                      : null,
                                ),
                              ),
                              if (isWinner) ...[
                                const SizedBox(width: 4),
                                const Text('🏆'),
                              ],
                              const Spacer(),
                              Text(
                                '$votes 👍',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (sub.stickerChoice.isNotEmpty)
                            _TappableStickerCard(
                              assetPath: sub.stickerChoice,
                              caption: sub.caption,
                            ),
                          const SizedBox(height: 8),
                          // Reactions
                          _ReactionBar(
                            targetUserId: e.key,
                            game: game,
                            reactions: state.reactions,
                            myId: game.userId,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(),
            Text(
              'Scores',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            ...(state.scores.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          _nameOf(widget.displayNames, e.key),
                          style: theme.textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Text(
                          '${e.value} 🏆',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 12),

            if (game.isOwner)
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: game.ownerAdvanceTurn,
                  child: const Text('Next Round →'),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Waiting for host…',
                      style: theme.textTheme.bodyMedium,
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

// ── History panel ─────────────────────────────────────────────────────────────

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.history,
    required this.displayNames,
    required this.onClose,
  });
  final List<MemeRoundRecord> history;
  final Map<String, String> displayNames;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.history_rounded),
          title: Text(
            'History (${history.length} rounds)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ),
        const Divider(height: 0),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: history.length,
            itemBuilder: (_, i) {
              final round = history[history.length - 1 - i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      '${round.roundNumber}',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  title: Text(
                    round.prompt.caption,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Winner: ${round.winnerId != null ? _nameOf(displayNames, round.winnerId!) : 'Tie'}',
                    style: theme.textTheme.bodySmall,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: round.submissions.entries.map((e) {
                          final sub = e.value;
                          final reacts = round.reactions
                              .where((r) => r.targetUserId == e.key)
                              .toList();
                          final reactTally = <String, int>{};
                          for (final r in reacts)
                            reactTally[r.emoji] =
                                (reactTally[r.emoji] ?? 0) + 1;
                          final isWinner = e.key == round.winnerId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _nameOf(displayNames, e.key),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: isWinner
                                                ? AppColors.amberOrangeLight
                                                : null,
                                          ),
                                    ),
                                    if (isWinner) const Text(' 🏆'),
                                  ],
                                ),
                                if (sub.stickerChoice.isNotEmpty)
                                  StickerDisplay(
                                    assetPath: sub.stickerChoice,
                                    size: 48,
                                  ),
                                if (sub.caption.isNotEmpty)
                                  Text(
                                    '"${sub.caption}"',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                if (reactTally.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Wrap(
                                      spacing: 4,
                                      children: reactTally.entries
                                          .map(
                                            (r) => Text(
                                              '${r.key}${r.value}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Game over ─────────────────────────────────────────────────────────────────

class _GameOverScreen extends StatefulWidget {
  const _GameOverScreen({required this.game, required this.displayNames});
  final MemeGameProvider game;
  final Map<String, String> displayNames;
  @override
  State<_GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<_GameOverScreen> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final scores = widget.game.state?.scores ?? {};
    final history = widget.game.state?.history ?? [];
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    const medals = ['🥇', '🥈', '🥉'];

    if (_showHistory) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Game History'),
          leading: BackButton(
            onPressed: () => setState(() => _showHistory = false),
          ),
        ),
        body: _HistoryPanel(
          history: history,
          displayNames: widget.displayNames,
          onClose: () => setState(() => _showHistory = false),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '😂🏆',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 64),
              ),
              Text(
                'Game Over!',
                textAlign: TextAlign.center,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Funniest player wins!',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final e = sorted[i];
                    return ListTile(
                      leading: Text(
                        i < medals.length ? medals[i] : '${i + 1}.',
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        _nameOf(widget.displayNames, e.key),
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: Text(
                        '${e.value} 🏆',
                        style: context.textTheme.titleMedium?.copyWith(
                          color: AppColors.amberOrangeLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (history.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showHistory = true),
                  icon: const Icon(Icons.history_rounded),
                  label: Text('View History (${history.length} rounds)'),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => context.go(RouteNames.home),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
