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
// // import 'package:jma3a/features/settings/presentation/screen_security_service.dart';
// // import 'package:provider/provider.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import '../../../../core/di/service_locator.dart';
// // import '../../../../core/extensions/context_ext.dart';
// // import '../../../../core/providers/auth_provider.dart';
// // import '../../../../core/router/route_names.dart';
// // import '../../../../core/services/realtime_service.dart';
// // // import '../../../../core/services/screen_security_service.dart';
// // import '../../../../core/theme/app_colors.dart';
// // import '../../../../core/utils/app_logger.dart';

// // enum MemeLoadState { idle, loading, ready, error, gameOver }

// // class MemeGameProvider extends ChangeNotifier {
// //   MemeGameProvider({
// //     required RealtimeService realtimeService,
// //     required String userId,
// //     required String displayName,
// //   }) : _realtime = realtimeService,
// //        _userId = userId,
// //        _displayName = displayName;

// //   final RealtimeService _realtime;
// //   final String _userId, _displayName;
// //   MemeGameEngine? _engine;
// //   MemeLoadState _loadState = MemeLoadState.idle;
// //   String? _roomId;
// //   String? _sessionId;
// //   bool _isOwner = false;
// //   String _error = '';
// //   // Away player tracking — filled by player_left broadcasts so the owner
// //   // can auto-skip their turns instead of waiting for them.
// //   final Set<String> _awayPlayerIds = {};

// //   MemeLoadState get loadState => _loadState;
// //   MemeState? get state => _engine?.currentState as MemeState?;
// //   String get userId => _userId;
// //   bool get isOwner => _isOwner;
// //   String get error => _error;
// //   Set<String> get awayPlayerIds => _awayPlayerIds;

// //   void markPlayerAway(String userId, {bool forGood = false}) {
// //     _awayPlayerIds.add(userId);
// //     // Meme is simultaneous — everyone submits at once, so there's no
// //     // single "current submitter" to skip. If the away player hasn't
// //     // submitted yet, auto-submit a blank on their behalf so the round
// //     // isn't stuck waiting for them.
// //     if (_isOwner && _engine != null) {
// //       final s = _engine!.currentState as MemeState?;
// //       if (s != null &&
// //           s.phase == MemePhase.submitting &&
// //           !s.submissions.containsKey(userId)) {
// //         Future.microtask(
// //           () => _handleAction({
// //             'action': 'meme_submit',
// //             'user_id': userId,
// //             'caption': '',
// //             'sticker_choice': '',
// //           }),
// //         );
// //       }
// //     }
// //     notifyListeners();
// //   }

// //   void markPlayerReturned(String userId) {
// //     _awayPlayerIds.remove(userId);
// //     notifyListeners();
// //   }

// //   // ── Init ────────────────────────────────────────────────────────────────────

// //   Future<void> initAsOwner({
// //     required String roomId,
// //     required String packId,
// //     required List<String> playerIds,
// //     required Map<String, String> displayNames,
// //     required GameConfig config,
// //   }) async {
// //     _roomId = roomId;
// //     _isOwner = true;
// //     _loadState = MemeLoadState.loading;
// //     notifyListeners();
// //     try {
// //       var todCards = await TodRepository.instance.loadCardsFromCache(
// //         packId: packId,
// //         language: config.language,
// //       );
// //       if (todCards.isEmpty) {
// //         final rows = await Supabase.instance.client
// //             .from('pack_cards')
// //             .select('id, content, card_type, difficulty, sort_order')
// //             .eq('pack_id', packId)
// //             .order('sort_order');
// //         todCards = (rows as List).map((r) {
// //           String text = '';
// //           final raw = r['content'];
// //           if (raw is Map) {
// //             final m = Map<String, dynamic>.from(raw as Map);
// //             text =
// //                 (m[config.language] ??
// //                         m['en'] ??
// //                         m.values.whereType<String>().firstOrNull ??
// //                         '')
// //                     as String;
// //           } else if (raw is String) {
// //             try {
// //               final d = jsonDecode(raw);
// //               if (d is Map)
// //                 text = (d[config.language] ?? d['en'] ?? '') as String;
// //               else
// //                 text = raw;
// //             } catch (_) {
// //               text = raw;
// //             }
// //           }
// //           // difficulty from DB may be a Map (localized) or String — normalise
// //           final rawDiff = r['difficulty'];
// //           final diffStr = rawDiff is Map
// //               ? (rawDiff['en'] ?? rawDiff.values.first ?? 'mild').toString()
// //               : rawDiff?.toString() ?? 'mild';
// //           return TodCard(
// //             id: r['id'] as String,
// //             content: text,
// //             type: TodCardType.truth,
// //             difficulty: TodDifficulty.values.firstWhere(
// //               (d) => d.name == diffStr,
// //               orElse: () => TodDifficulty.mild,
// //             ),
// //           );
// //         }).toList();
// //       }
// //       final prompts = todCards
// //           .map((c) => MemePrompt(id: c.id, caption: c.content))
// //           .toList();

// //       _engine = MemeGameEngine(config, prompts: prompts);

// //       // ✅ Resume an existing in-progress session if one exists, instead of
// //       // always creating a brand-new one. Without this, re-entering this
// //       // screen (including "Resume Game") silently wiped any prior progress.
// //       final existing = await Supabase.instance.client
// //           .from('game_sessions')
// //           .select('id, state_snapshot, game_type')
// //           .eq('room_id', roomId)
// //           .eq('status', 'active')
// //           .order('started_at', ascending: false)
// //           .limit(1)
// //           .maybeSingle();
// //       final snapshotGameType = existing?['game_type'] as String?;
// //       Map<String, dynamic>? existingSnapshot;
// //       if (snapshotGameType == 'meme_game') {
// //         existingSnapshot = existing?['state_snapshot'] as Map<String, dynamic>?;
// //       }

// //       if (existing != null &&
// //           existingSnapshot != null &&
// //           existingSnapshot.isNotEmpty) {
// //         _sessionId = existing['id'] as String;
// //         _engine!.restoreFromSnapshot(existingSnapshot);
// //         AppLogger.info('MemeProvider: resumed existing session $_sessionId');
// //       } else {
// //         _engine!.init(playerIds);
// //         try {
// //           final inserted = await Supabase.instance.client
// //               .from('game_sessions')
// //               .insert({
// //                 'room_id': roomId,
// //                 'pack_id': packId,
// //                 'game_type': 'meme_game',
// //                 'player_ids': playerIds,
// //                 'owner_id': _userId,
// //                 'state_snapshot': _engine!.serializeState(),
// //                 'max_rounds': config.maxRounds,
// //                 'turn_timer_secs': config.turnTimerSeconds,
// //                 'allow_skip': config.allowSkip,
// //                 'allow_spicy': config.allowSpicy,
// //               })
// //               .select('id')
// //               .single();
// //           _sessionId = inserted['id'] as String;
// //         } catch (e) {
// //           AppLogger.warning('MemeProvider: failed to create session: $e');
// //         }
// //       }

// //       _loadState = MemeLoadState.ready;
// //       notifyListeners();
// //       _broadcastState();
// //     } catch (e) {
// //       _error = e.toString();
// //       _loadState = MemeLoadState.error;
// //       AppLogger.error('MemeProvider: init failed', error: e);
// //       notifyListeners();
// //     }
// //   }

// //   void initAsFollower(String roomId) {
// //     _roomId = roomId;
// //     _isOwner = false;
// //     _loadState = MemeLoadState.loading;
// //     notifyListeners();
// //   }

// //   // ── Actions ──────────────────────────────────────────────────────────────────

// //   Future<void> submit({String caption = '', String stickerChoice = ''}) =>
// //       _handleAction({
// //         'action': 'meme_submit',
// //         'caption': caption,
// //         'sticker_choice': stickerChoice,
// //       });

// //   Future<void> voteFor(String targetUserId) =>
// //       _handleAction({'action': 'meme_vote', 'target_user_id': targetUserId});

// //   Future<void> reactTo(String targetUserId, String emoji) => _handleAction({
// //     'action': 'meme_react',
// //     'target_user_id': targetUserId,
// //     'emoji': emoji,
// //   });

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
// //       final snap =
// //           (payload['snapshot'] as Map<String, dynamic>?)?['state']
// //               as Map<String, dynamic>? ??
// //           payload['state'] as Map<String, dynamic>?;
// //       if (snap == null) return;
// //       _engine ??= MemeGameEngine(
// //         const GameConfig(
// //           maxRounds: 10,
// //           turnTimerSeconds: 60,
// //           allowSkip: false,
// //           allowSpicy: false,
// //         ),
// //         prompts: [],
// //       );
// //       _engine!.restoreFromSnapshot(snap);
// //       _loadState = _engine!.isGameOver
// //           ? MemeLoadState.gameOver
// //           : MemeLoadState.ready;
// //       notifyListeners();
// //     } catch (e) {
// //       AppLogger.warning('MemeProvider: restore failed: $e');
// //     }
// //   }

// //   void onPlayerAction(Map<String, dynamic> payload) {
// //     if (!_isOwner || _engine == null) return;
// //     final action = payload['action'] as String?;
// //     final uid = payload['user_id'] as String?;
// //     final ts = payload['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
// //     if (uid == null) return;
// //     switch (action) {
// //       case 'meme_submit':
// //         _engine!.handleEvent(
// //           MemeSubmitEvent(
// //             userId: uid,
// //             ts: ts,
// //             caption: payload['caption'] as String? ?? '',
// //             stickerChoice: payload['sticker_choice'] as String? ?? '',
// //           ),
// //         );
// //       case 'meme_vote':
// //         _engine!.handleEvent(
// //           MemeVoteEvent(
// //             userId: uid,
// //             ts: ts,
// //             targetUserId: payload['target_user_id'] as String? ?? '',
// //           ),
// //         );
// //       case 'meme_react':
// //         _engine!.handleEvent(
// //           MemeReactEvent(
// //             userId: uid,
// //             ts: ts,
// //             targetUserId: payload['target_user_id'] as String? ?? '',
// //             emoji: payload['emoji'] as String? ?? '👍',
// //           ),
// //         );
// //     }
// //     if (_engine!.isGameOver) _loadState = MemeLoadState.gameOver;
// //     notifyListeners();
// //     _broadcastState();
// //   }

// //   void onSyncRequest(Map<String, dynamic> _) {
// //     if (_isOwner) _broadcastState();
// //   }

// //   Future<void> _handleAction(Map<String, dynamic> action) async {
// //     final full = {
// //       ...action,
// //       'user_id': _userId,
// //       'display_name': _displayName,
// //       'ts': DateTime.now().millisecondsSinceEpoch,
// //     };
// //     if (_isOwner && _engine != null)
// //       onPlayerAction(full);
// //     else if (_roomId != null)
// //       await _realtime.broadcastPlayerAction(_roomId!, full);
// //   }

// //   void _broadcastState() {
// //     if (_roomId == null || _engine == null) return;
// //     final snapshot = _engine!.serializeState();
// //     _realtime.broadcastGameState(_roomId!, {
// //       'state': snapshot,
// //     }, _userId).ignore();

// //     // Persist so a later resume can restore exactly where play left off —
// //     // fire-and-forget, never blocks gameplay on a slow write.
// //     if (_isOwner && _sessionId != null) {
// //       Supabase.instance.client
// //           .from('game_sessions')
// //           .update({
// //             'state_snapshot': snapshot,
// //             'updated_at': DateTime.now().toIso8601String(),
// //             if (_engine!.isGameOver) 'status': 'completed',
// //             if (_engine!.isGameOver)
// //               'ended_at': DateTime.now().toIso8601String(),
// //           })
// //           .eq('id', _sessionId!)
// //           .then(
// //             (_) {},
// //             onError: (e) {
// //               AppLogger.warning('MemeProvider: snapshot save failed: $e');
// //             },
// //           );
// //     }
// //   }
// // }

// // Future<void> memeShowLeaveDialog(
// //   BuildContext ctx, {
// //   required String roomId,
// //   required bool isOwner,
// //   String displayName = 'A player',
// // }) async {
// //   if (!ctx.mounted) return;
// //   final myUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
// //   final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

// //   if (isOwner) {
// //     // Check for moderators who could take over
// //     final mods = await sl.roomRepository
// //         .getRoomModerators(roomId)
// //         .catchError((_) => <Map<String, dynamic>>[]);
// //     final hasMod = mods.isNotEmpty;

// //     final choice = await showDialog<String>(
// //       context: ctx,
// //       builder: (d) => AlertDialog(
// //         title: const Text('Leave Game?'),
// //         content: const Text("Choose what happens while you're away."),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(d, 'cancel'),
// //             child: const Text('Stay'),
// //           ),
// //           if (hasMod)
// //             FilledButton.tonal(
// //               onPressed: () => Navigator.pop(d, 'handoff'),
// //               child: const Text('Play Another & Hand Off'),
// //             ),
// //           FilledButton.tonal(
// //             onPressed: () => Navigator.pop(d, 'quit_lobby'),
// //             child: const Text('Quit to Lobby'),
// //           ),
// //           FilledButton.tonal(
// //             onPressed: () => Navigator.pop(d, 'pause'),
// //             child: const Text('Pause & Return Later'),
// //           ),
// //           FilledButton(
// //             style: FilledButton.styleFrom(backgroundColor: Colors.red),
// //             onPressed: () => Navigator.pop(d, 'end'),
// //             child: const Text('End Room for Everyone'),
// //           ),
// //         ],
// //       ),
// //     );
// //     if (choice == null || choice == 'cancel' || !ctx.mounted) return;

// //     if (choice == 'handoff' && mods.isNotEmpty) {
// //       final newOwner = mods.length == 1
// //           ? mods.first['user_id'] as String
// //           : await showDialog<String>(
// //               context: ctx,
// //               builder: (d) => SimpleDialog(
// //                 title: const Text('Who takes over?'),
// //                 children: mods.map((m) {
// //                   final uid = m['user_id'] as String;
// //                   return SimpleDialogOption(
// //                     onPressed: () => Navigator.pop(d, uid),
// //                     child: Text(uid.substring(0, 8).toUpperCase()),
// //                   );
// //                 }).toList(),
// //               ),
// //             );
// //       if (newOwner == null || !ctx.mounted) return;
// //       try {
// //         await Supabase.instance.client
// //             .from('rooms')
// //             .update({'owner_id': newOwner})
// //             .eq('id', roomId);
// //         await sl.realtimeService.broadcastRoomEvent(roomId, {
// //           'type': 'ownership_transferred',
// //           'new_owner_id': newOwner,
// //           'by': myUserId,
// //         });
// //         await sl.realtimeService.broadcastRoomEvent(roomId, {
// //           'type': 'player_left',
// //           'user_id': myUserId,
// //           'for_good': true,
// //         });
// //       } catch (_) {}
// //       if (ctx.mounted) AppRouter.router.go(RouteNames.home);
// //       return;
// //     }

// //     if (choice == 'quit_lobby') {
// //       try {
// //         await sl.realtimeService.broadcastRoomEvent(roomId, {
// //           'type': 'game_ended',
// //           'reason': 'host_quit_to_lobby',
// //         });
// //         await sl.roomRepository.updateStatus(roomId, RoomStatus.waiting);
// //       } catch (_) {}
// //       if (ctx.mounted) AppRouter.router.go('/home/room/$roomId');
// //       return;
// //     }

// //     if (choice == 'pause') {
// //       try {
// //         await sl.roomRepository.updateStatus(roomId, RoomStatus.paused);
// //         await sl.realtimeService.broadcastRoomEvent(roomId, {
// //           'type': 'game_paused',
// //           'reason': 'host_away',
// //         });
// //         await Future.delayed(const Duration(milliseconds: 300));
// //       } catch (_) {}
// //       if (ctx.mounted) AppRouter.router.go(RouteNames.home);
// //     } else {
// //       try {
// //         await sl.realtimeService.broadcastGameEnded(roomId, {
// //           'reason': 'host_ended',
// //         });
// //         await sl.realtimeService.broadcastRoomEvent(roomId, {
// //           'type': 'owner_left',
// //           'reason': 'host_ended',
// //         });
// //         await sl.roomRepository.updateStatus(roomId, RoomStatus.closed);
// //       } catch (_) {}
// //       if (ctx.mounted) AppRouter.router.go(RouteNames.home);
// //     }
// //   } else {
// //     final returnMins = isPremium ? 10 : 5;
// //     final choice = await showDialog<String>(
// //       context: ctx,
// //       builder: (d) => AlertDialog(
// //         title: const Text('Leave Game?'),
// //         content: Text(
// //           "If you'll return, your turns will be skipped. You have "
// //           '$returnMins minutes — after that your seat is lost.',
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(d, 'cancel'),
// //             child: const Text('Stay'),
// //           ),
// //           FilledButton.tonal(
// //             onPressed: () => Navigator.pop(d, 'return'),
// //             child: Text("I'll Return ($returnMins min)"),
// //           ),
// //           FilledButton(
// //             style: FilledButton.styleFrom(backgroundColor: Colors.red),
// //             onPressed: () => Navigator.pop(d, 'definitive'),
// //             child: const Text('Leave for Good'),
// //           ),
// //         ],
// //       ),
// //     );
// //     if (choice == null || choice == 'cancel' || !ctx.mounted) return;
// //     try {
// //       if (choice == 'return') {
// //         await sl.roomRepository.setMemberAway(roomId, myUserId, away: true);
// //         await sl.roomRepository.setReturnTimer(
// //           roomId: roomId,
// //           userId: myUserId,
// //           isPremium: isPremium,
// //         );
// //         await sl.realtimeService.broadcastRoomEvent(roomId, {
// //           'type': 'player_left',
// //           'user_id': myUserId,
// //           'display_name': displayName,
// //           'for_good': false,
// //           'return_mins': returnMins,
// //         });
// //       } else {
// //         await sl.roomRepository.setMemberDefinitiveLeave(roomId, myUserId);
// //         await sl.realtimeService.broadcastRoomEvent(roomId, {
// //           'type': 'player_left',
// //           'user_id': myUserId,
// //           'display_name': displayName,
// //           'for_good': true,
// //         });
// //       }
// //     } catch (_) {}
// //     if (ctx.mounted) AppRouter.router.go(RouteNames.home);
// //   }
// // }

// // class MemeGameScreen extends StatefulWidget {
// //   const MemeGameScreen({
// //     super.key,
// //     required this.roomId,
// //     required this.config,
// //     required this.playerIds,
// //     required this.playerDisplayNames,
// //     required this.packId,
// //     this.packCoverUrl,
// //     required this.isOwner,
// //     this.isModerator = false,
// //   });
// //   final String roomId;
// //   final GameConfig config;
// //   final List<String> playerIds;
// //   final Map<String, String> playerDisplayNames;
// //   final String packId;
// //   final bool isOwner;
// //   final bool isModerator;
// //   final String? packCoverUrl;
// //   @override
// //   State<MemeGameScreen> createState() => _MemeGameScreenState();
// // }

// // class _MemeGameScreenState extends State<MemeGameScreen> {
// //   late final MemeGameProvider _provider;

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
// //     final user = context.read<AuthProvider>().currentUser!;
// //     _provider = MemeGameProvider(
// //       realtimeService: sl.realtimeService,
// //       userId: user.id,
// //       displayName: user.displayName ?? user.username ?? 'Player',
// //     );
// //     // Update callbacks on existing channel — no teardown needed
// //     sl.realtimeService.subscribe(
// //       roomId: widget.roomId,
// //       onGameState: (p) => _provider.onStateBroadcast(p),
// //       onPlayerAction: (p) => _provider.onPlayerAction(p),
// //       onSyncRequest: (p) => _provider.onSyncRequest(p),
// //       onGameStarted: (_) {},
// //       onGameEnded: (p) {
// //         // Admin ended the game — take everyone back to the lobby
// //         if (mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             const SnackBar(content: Text('The host ended the game')),
// //           );
// //           // Pop back to lobby (the LobbyScreen is still on the stack)
// //           if (context.canPop())
// //             context.pop();
// //           else
// //             WidgetsBinding.instance.addPostFrameCallback((_) {
// //               if (mounted)
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
// //               else
// //                 AppRouter.router.go(RouteNames.home);
// //             });
// //         }
// //       },
// //       onRoomEvent: (p) {
// //         final type = p['type'] as String?;
// //         if (type == 'screenshot_taken') {
// //           final shooterId = p['user_id'] as String?;
// //           final myId = context.read<AuthProvider>().currentUser?.id;
// //           if (shooterId != null && shooterId != myId && mounted) {
// //             ScaffoldMessenger.of(context).showSnackBar(
// //               SnackBar(
// //                 content: Text(
// //                   '📸 ${widget.playerDisplayNames[shooterId] ?? 'Someone'} took a screenshot',
// //                 ),
// //                 backgroundColor: Colors.black87,
// //               ),
// //             );
// //           }
// //           return;
// //         }
// //         if (type == 'game_ended' && mounted) {
// //           if ((p['reason'] as String?) == 'host_quit_to_lobby') {
// //             WidgetsBinding.instance.addPostFrameCallback((_) {
// //               if (!mounted) return;
// //               // Unsubscribe before navigating so this handler doesn't fire
// //               // again when the lobby re-subscribes to the same channel.
// //               sl.realtimeService.unsubscribe(widget.roomId);
// //               ScaffoldMessenger.of(context).showSnackBar(
// //                 const SnackBar(
// //                   content: Text('🔄 Host ended the game — back to lobby'),
// //                   duration: Duration(seconds: 3),
// //                 ),
// //               );
// //               if (context.canPop()) {
// //                 context.pop();
// //               } else {
// //                 AppRouter.router.go('/home/room/${widget.roomId}');
// //               }
// //             });
// //           }
// //           return;
// //         }
// //         if (type == 'player_left' && mounted) {
// //           final name = p['display_name'] as String? ?? 'A player';
// //           final forGood = p['for_good'] as bool? ?? true;
// //           final leavingId = p['user_id'] as String?;
// //           final returnMins = p['return_mins'] as int?;
// //           // Tell the provider so the owner auto-skips this player's turns
// //           if (leavingId != null && _provider.isOwner) {
// //             _provider.markPlayerAway(leavingId, forGood: forGood);
// //           }
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(
// //               content: Text(
// //                 forGood
// //                     ? '👋 $name left the game'
// //                     : '🕐 $name stepped away (${returnMins != null ? 'back in ${returnMins}m' : 'coming back'})',
// //               ),
// //               backgroundColor: forGood
// //                   ? Colors.red.shade700
// //                   : Colors.orange.shade700,
// //               duration: const Duration(seconds: 4),
// //             ),
// //           );
// //           return;
// //         }
// //         if (type == 'ownership_transferred' && mounted) {
// //           final myId = context.read<AuthProvider>().currentUser?.id;
// //           if (p['new_owner_id'] == myId) {
// //             ScaffoldMessenger.of(context).showSnackBar(
// //               const SnackBar(
// //                 content: Text('👑 You are now the game host!'),
// //                 backgroundColor: Colors.purple,
// //               ),
// //             );
// //           }
// //           return;
// //         }
// //         if (type == 'game_paused' && mounted) {
// //           WidgetsBinding.instance.addPostFrameCallback((_) {
// //             if (!mounted) return;
// //             showDialog(
// //               context: context,
// //               barrierDismissible: false,
// //               barrierColor: Colors.black.withOpacity(0.85),
// //               builder: (_) => _MemeNhiePausedOverlay(
// //                 onLeave: () {
// //                   Navigator.of(context).pop();
// //                   AppRouter.router.go(RouteNames.home);
// //                 },
// //               ),
// //             );
// //           });
// //         }
// //         if ((type == 'room_closed' || type == 'owner_left') && mounted) {
// //           WidgetsBinding.instance.addPostFrameCallback((_) {
// //             if (mounted)
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
// //             else
// //               AppRouter.router.go(RouteNames.home);
// //           });
// //         }
// //       },
// //       onChatMessage: (_) {},
// //       onModeration: (p) {
// //         final type = p['type'] as String?;
// //         final targetId = p['target_user_id'] as String?;
// //         final myId = context.read<AuthProvider>().currentUser?.id;
// //         if ((type == 'kick' || type == 'ban') && targetId == myId && mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(
// //               content: Text(
// //                 type == 'kick'
// //                     ? 'You were removed from the room'
// //                     : 'You were banned from this room',
// //               ),
// //             ),
// //           );
// //           context.go(RouteNames.home);
// //         }
// //       },
// //       onSettingsChange: (_) {},
// //       onPresenceSync: (_) {},
// //       onPresenceJoin: (_) {},
// //       onPresenceLeave: (_) {},
// //       onStatusChange: (_) {},
// //     );
// //     if (!widget.isOwner) {
// //       Future.delayed(const Duration(milliseconds: 300), _requestSync);
// //     }
// //     if (widget.isOwner) {
// //       _provider.initAsOwner(
// //         roomId: widget.roomId,
// //         packId: widget.packId,
// //         playerIds: widget.playerIds,
// //         displayNames: widget.playerDisplayNames,
// //         config: widget.config,
// //       );
// //     } else {
// //       _provider.initAsFollower(widget.roomId);
// //     }
// //   }

// //   void _requestSync() {
// //     if (!mounted) return;
// //     sl.realtimeService
// //         .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
// //         .ignore();
// //     Future.delayed(const Duration(seconds: 1), () {
// //       if (mounted && _provider.loadState == MemeLoadState.loading) {
// //         sl.realtimeService
// //             .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
// //             .ignore();
// //       }
// //     });
// //     Future.delayed(const Duration(seconds: 3), () {
// //       if (mounted && _provider.loadState == MemeLoadState.loading) {
// //         sl.realtimeService
// //             .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
// //             .ignore();
// //       }
// //     });
// //   }

// //   @override
// //   void dispose() {
// //     ScreenSecurityService.instance.disable();
// //     _provider.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return PopScope(
// //       canPop: false,
// //       onPopInvoked: (_) => memeShowLeaveDialog(
// //         context,
// //         roomId: widget.roomId,
// //         isOwner: widget.isOwner,
// //         displayName:
// //             widget.playerDisplayNames[Supabase
// //                     .instance
// //                     .client
// //                     .auth
// //                     .currentUser
// //                     ?.id ??
// //                 ''] ??
// //             'A player',
// //       ),
// //       child: ChangeNotifierProvider.value(
// //         value: _provider,
// //         child: Consumer<MemeGameProvider>(
// //           builder: (ctx, game, _) {
// //             if (game.loadState == MemeLoadState.loading)
// //               return const Scaffold(
// //                 body: Center(child: CircularProgressIndicator()),
// //               );
// //             if (game.loadState == MemeLoadState.error)
// //               return Scaffold(
// //                 body: Center(
// //                   child: Padding(
// //                     padding: const EdgeInsets.all(24),
// //                     child: Text(
// //                       'Error: \${game.error}',
// //                       textAlign: TextAlign.center,
// //                     ),
// //                   ),
// //                 ),
// //               );
// //             if (game.loadState == MemeLoadState.gameOver)
// //               return _GameOverScreen(
// //                 game: game,
// //                 displayNames: widget.playerDisplayNames,
// //               );
// //             final state = game.state;
// //             if (state == null)
// //               return const Scaffold(
// //                 body: Center(child: CircularProgressIndicator()),
// //               );
// //             return switch (state.phase) {
// //               MemePhase.submitting => _SubmitScreen(
// //                 game: game,
// //                 state: state,
// //                 displayNames: widget.playerDisplayNames,
// //                 packId: widget.packId,
// //                 packCoverUrl: widget.packCoverUrl,
// //                 roomId: widget.roomId,
// //                 isOwner: widget.isOwner,
// //               ),
// //               MemePhase.voting => _VotingScreen(
// //                 game: game,
// //                 state: state,
// //                 displayNames: widget.playerDisplayNames,
// //                 roomId: widget.roomId,
// //                 isOwner: widget.isOwner,
// //               ),
// //               MemePhase.results => _ResultsScreen(
// //                 game: game,
// //                 state: state,
// //                 displayNames: widget.playerDisplayNames,
// //                 roomId: widget.roomId,
// //                 isOwner: widget.isOwner,
// //               ),
// //             };
// //           },
// //         ),
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
// //   final String targetUserId;
// //   final MemeGameProvider game;
// //   final List<EmojiReaction> reactions;
// //   final String myId;

// //   @override
// //   Widget build(BuildContext context) {
// //     final tally = <String, int>{};
// //     for (final r in reactions.where((r) => r.targetUserId == targetUserId)) {
// //       tally[r.emoji] = (tally[r.emoji] ?? 0) + 1;
// //     }
// //     final alreadyReacted = reactions.any(
// //       (r) => r.reactorId == myId && r.targetUserId == targetUserId,
// //     );
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
// //     return Image.network(
// //       path,
// //       height: height,
// //       fit: fit,
// //       errorBuilder: (_, __, ___) =>
// //           const Text('🎭', style: TextStyle(fontSize: 80)),
// //     );
// //   }
// //   return Image.asset(
// //     path,
// //     height: height,
// //     fit: fit,
// //     errorBuilder: (_, __, ___) =>
// //         const Text('🎭', style: TextStyle(fontSize: 80)),
// //   );
// // }

// // // ── Hidden-until-tapped reaction reveal ───────────────────────────────────────
// // // Other players' submissions stay covered ("🎭 Tap to see their reaction")
// // // until tapped, then reveal full-screen as a surprise. After that first
// // // reveal, the response shows normally inline (matching expand-on-tap
// // // behavior from then on) — only the FIRST view is the surprise.
// // class _HiddenReactionCard extends StatefulWidget {
// //   const _HiddenReactionCard({
// //     required this.stickerChoice,
// //     required this.caption,
// //     required this.isOwn,
// //   });
// //   final String stickerChoice;
// //   final String caption;
// //   final bool isOwn;

// //   @override
// //   State<_HiddenReactionCard> createState() => _HiddenReactionCardState();
// // }

// // class _HiddenReactionCardState extends State<_HiddenReactionCard> {
// //   // Own submissions are never hidden from yourself.
// //   late bool _revealed = widget.isOwn;

// //   Future<void> _reveal() async {
// //     await showDialog(
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
// //                   if (widget.stickerChoice.isNotEmpty)
// //                     ClipRRect(
// //                       borderRadius: BorderRadius.circular(16),
// //                       child: _stickerImg(
// //                         widget.stickerChoice,
// //                         fit: BoxFit.contain,
// //                       ),
// //                     ),
// //                   if (widget.caption.isNotEmpty) ...[
// //                     const SizedBox(height: 16),
// //                     Container(
// //                       padding: const EdgeInsets.symmetric(
// //                         horizontal: 20,
// //                         vertical: 12,
// //                       ),
// //                       decoration: BoxDecoration(
// //                         color: Colors.white,
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       child: Text(
// //                         widget.caption,
// //                         textAlign: TextAlign.center,
// //                         style: const TextStyle(
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.w600,
// //                           color: Colors.black87,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                   const SizedBox(height: 16),
// //                   const Text(
// //                     'Tap anywhere to close',
// //                     style: TextStyle(color: Colors.white54, fontSize: 13),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //     if (mounted) setState(() => _revealed = true);
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (_revealed) {
// //       // Already seen once — show normally (reuses the existing
// //       // tap-to-expand sticker card for subsequent views).
// //       if (widget.stickerChoice.isEmpty) {
// //         return widget.caption.isEmpty
// //             ? const SizedBox.shrink()
// //             : Text(
// //                 widget.caption,
// //                 style: Theme.of(
// //                   context,
// //                 ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
// //               );
// //       }
// //       return _TappableStickerCard(
// //         assetPath: widget.stickerChoice,
// //         caption: widget.caption,
// //       );
// //     }

// //     return GestureDetector(
// //       onTap: _reveal,
// //       child: Container(
// //         width: double.infinity,
// //         height: 140,
// //         decoration: BoxDecoration(
// //           color: Theme.of(context).colorScheme.surfaceContainerHighest,
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: const [
// //             Text('🎭', style: TextStyle(fontSize: 40)),
// //             SizedBox(height: 8),
// //             Text(
// //               'Tap to see their reaction',
// //               style: TextStyle(fontWeight: FontWeight.w600),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ── Tappable sticker card ─────────────────────────────────────────────────────
// // // Shows sticker at medium size + optional caption. Tap to fullscreen expand.

// // class _TappableStickerCard extends StatefulWidget {
// //   const _TappableStickerCard({required this.assetPath, this.caption = ''});
// //   final String assetPath;
// //   final String caption;
// //   @override
// //   State<_TappableStickerCard> createState() => _TappableStickerCardState();
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
// //                       padding: const EdgeInsets.symmetric(
// //                         horizontal: 20,
// //                         vertical: 12,
// //                       ),
// //                       decoration: BoxDecoration(
// //                         color: Colors.white,
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       child: Text(
// //                         widget.caption,
// //                         textAlign: TextAlign.center,
// //                         style: const TextStyle(
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.w600,
// //                           color: Colors.black87,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                   const SizedBox(height: 16),
// //                   const Text(
// //                     'Tap anywhere to close',
// //                     style: TextStyle(color: Colors.white54, fontSize: 13),
// //                   ),
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
// //         child: Column(
// //           children: [
// //             ClipRRect(
// //               borderRadius: BorderRadius.circular(8),
// //               child: _stickerImg(widget.assetPath, height: 140),
// //             ),
// //             if (widget.caption.isNotEmpty) ...[
// //               const SizedBox(height: 8),
// //               Text(
// //                 widget.caption,
// //                 textAlign: TextAlign.center,
// //                 style: const TextStyle(
// //                   fontSize: 15,
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //             ],
// //             const SizedBox(height: 4),
// //             const Text(
// //               'Tap to expand',
// //               style: TextStyle(fontSize: 11, color: Colors.grey),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ── Submit screen ─────────────────────────────────────────────────────────────

// // class _SubmitScreen extends StatefulWidget {
// //   const _SubmitScreen({
// //     required this.game,
// //     required this.state,
// //     required this.displayNames,
// //     required this.packId,
// //     this.packCoverUrl,
// //     required this.roomId,
// //     required this.isOwner,
// //   });
// //   final MemeGameProvider game;
// //   final MemeState state;
// //   final Map<String, String> displayNames;
// //   final String packId;
// //   final String? packCoverUrl;
// //   final String roomId;
// //   final bool isOwner;
// //   @override
// //   State<_SubmitScreen> createState() => _SubmitScreenState();
// // }

// // class _SubmitScreenState extends State<_SubmitScreen> {
// //   final _captionCtrl = TextEditingController();
// //   String _pickedSticker = '';
// //   List<String> _packReactions = []; // custom pack reaction URLs
// //   bool _loadingReactions = true;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadPackReactions();
// //   }

// //   Future<void> _loadPackReactions() async {
// //     try {
// //       final urls = await PackRepository.instance.getPackReactions(
// //         widget.packId,
// //       );
// //       AppLogger.info(
// //         'MemeGame: loaded ${urls.length} pack reactions for ${widget.packId}',
// //       );
// //       if (mounted)
// //         setState(() {
// //           _packReactions = urls;
// //           _loadingReactions = false;
// //         });
// //     } catch (e) {
// //       AppLogger.warning('MemeGame: failed to load pack reactions: $e');
// //       if (mounted) setState(() => _loadingReactions = false);
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     _captionCtrl.dispose();
// //     super.dispose();
// //   }

// //   bool get _canSubmit => _pickedSticker.isNotEmpty; // sticker required

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     final hasSubmitted = widget.state.submissions.containsKey(
// //       widget.game.userId,
// //     );
// //     final submitted = widget.state.submissions.length;
// //     final total = widget.state.playerOrder.length;

// //     return Scaffold(
// //       resizeToAvoidBottomInset: false,
// //       appBar: AppBar(
// //         leading: BackButton(
// //           onPressed: () => memeShowLeaveDialog(
// //             context,
// //             roomId: widget.roomId,
// //             isOwner: widget.isOwner,
// //             displayName:
// //                 widget.displayNames[Supabase
// //                         .instance
// //                         .client
// //                         .auth
// //                         .currentUser
// //                         ?.id ??
// //                     ''] ??
// //                 'A player',
// //           ),
// //         ),
// //         title: Text(
// //           'Round ${widget.state.roundNumber} / ${widget.state.maxRounds}',
// //         ),
// //       ),
// //       body: SingleChildScrollView(
// //         padding: EdgeInsets.fromLTRB(
// //           20,
// //           20,
// //           20,
// //           20 + MediaQuery.of(context).viewInsets.bottom,
// //         ),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.stretch,
// //           children: [
// //             // Prompt card with background image
// //             ClipRRect(
// //               borderRadius: BorderRadius.circular(20),
// //               child: SizedBox(
// //                 width: double.infinity,
// //                 height: 160,
// //                 child: Stack(
// //                   fit: StackFit.expand,
// //                   children: [
// //                     Positioned.fill(
// //                       child:
// //                           widget.packCoverUrl != null &&
// //                               widget.packCoverUrl!.isNotEmpty
// //                           ? Image.network(
// //                               widget.packCoverUrl!,
// //                               fit: BoxFit.cover,
// //                               width: double.infinity,
// //                               height: double.infinity,
// //                               errorBuilder: (_, __, ___) => Image.asset(
// //                                 'assets/images/jma3a_card_background.png',
// //                                 fit: BoxFit.cover,
// //                                 width: double.infinity,
// //                                 height: double.infinity,
// //                               ),
// //                             )
// //                           : Image.asset(
// //                               'assets/images/jma3a_card_background.png',
// //                               fit: BoxFit.cover,
// //                               width: double.infinity,
// //                               height: double.infinity,
// //                               errorBuilder: (_, __, ___) =>
// //                                   Container(color: AppColors.purple),
// //                             ),
// //                     ),
// //                     Positioned.fill(
// //                       child: Container(
// //                         decoration: BoxDecoration(
// //                           gradient: LinearGradient(
// //                             colors: [
// //                               AppColors.purple.withOpacity(0.50),
// //                               const Color(0xFF0D1B2A).withOpacity(0.70),
// //                             ],
// //                             begin: Alignment.topCenter,
// //                             end: Alignment.bottomCenter,
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     Center(
// //                       child: Padding(
// //                         padding: const EdgeInsets.all(20),
// //                         child: Column(
// //                           mainAxisSize: MainAxisSize.min,
// //                           children: [
// //                             const Text('😂', style: TextStyle(fontSize: 44)),
// //                             const SizedBox(height: 10),
// //                             Text(
// //                               widget.state.currentPrompt?.caption ?? '…',
// //                               textAlign: TextAlign.center,
// //                               style: const TextStyle(
// //                                 color: Colors.white,
// //                                 fontSize: 18,
// //                                 fontWeight: FontWeight.w600,
// //                                 height: 1.4,
// //                                 shadows: [
// //                                   Shadow(color: Colors.black54, blurRadius: 8),
// //                                 ],
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //             const SizedBox(height: 12),

// //             Text(
// //               '$submitted / $total submitted',
// //               textAlign: TextAlign.center,
// //               style: theme.textTheme.bodySmall?.copyWith(
// //                 color: theme.colorScheme.onSurfaceVariant,
// //               ),
// //             ),
// //             const SizedBox(height: 12),

// //             if (!hasSubmitted) ...[
// //               // Sticker picker — required
// //               Text(
// //                 'Pick your sticker:',
// //                 style: theme.textTheme.labelMedium?.copyWith(
// //                   fontWeight: FontWeight.w700,
// //                 ),
// //               ),
// //               const SizedBox(height: 8),
// //               // Expanded preview when a sticker is selected
// //               if (_pickedSticker.isNotEmpty)
// //                 GestureDetector(
// //                   onTap: () => setState(() => _pickedSticker = ''),
// //                   child: Container(
// //                     width: double.infinity,
// //                     height: 200,
// //                     margin: const EdgeInsets.only(bottom: 8),
// //                     decoration: BoxDecoration(
// //                       color: Theme.of(
// //                         context,
// //                       ).colorScheme.surfaceContainerHighest,
// //                       borderRadius: BorderRadius.circular(16),
// //                       border: Border.all(
// //                         color: Theme.of(context).colorScheme.primary,
// //                         width: 2,
// //                       ),
// //                     ),
// //                     child: Stack(
// //                       alignment: Alignment.center,
// //                       children: [
// //                         ClipRRect(
// //                           borderRadius: BorderRadius.circular(14),
// //                           child: _stickerImg(_pickedSticker, height: 180),
// //                         ),
// //                         Positioned(
// //                           top: 8,
// //                           right: 8,
// //                           child: Container(
// //                             decoration: BoxDecoration(
// //                               color: Colors.black54,
// //                               borderRadius: BorderRadius.circular(20),
// //                             ),
// //                             padding: const EdgeInsets.all(4),
// //                             child: const Icon(
// //                               Icons.close,
// //                               color: Colors.white,
// //                               size: 18,
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               _loadingReactions
// //                   ? const Center(child: CircularProgressIndicator())
// //                   : StickerPicker(
// //                       selected: _pickedSticker.isEmpty ? null : _pickedSticker,
// //                       onSelect: (path) => setState(() => _pickedSticker = path),
// //                       customUrls: _packReactions.isNotEmpty
// //                           ? _packReactions
// //                           : null,
// //                       stickerSize: 64,
// //                     ),
// //               const SizedBox(height: 12),

// //               // Caption (optional)
// //               TextField(
// //                 controller: _captionCtrl,
// //                 maxLines: 2,
// //                 maxLength: 200,
// //                 textCapitalization: TextCapitalization.sentences,
// //                 decoration: const InputDecoration(
// //                   hintText: 'Add a caption (optional)…',
// //                   border: OutlineInputBorder(),
// //                   counterText: '',
// //                 ),
// //                 onChanged: (_) => setState(() {}),
// //               ),
// //               const SizedBox(height: 16),

// //               SizedBox(
// //                 height: 52,
// //                 child: FilledButton(
// //                   onPressed: _canSubmit
// //                       ? () => widget.game.submit(
// //                           caption: _captionCtrl.text.trim(),
// //                           stickerChoice: _pickedSticker,
// //                         )
// //                       : null,
// //                   child: Text(
// //                     _pickedSticker.isEmpty
// //                         ? 'Pick a sticker first'
// //                         : 'Submit Response',
// //                   ),
// //                 ),
// //               ),
// //             ] else ...[
// //               const SizedBox(height: 20),
// //               Container(
// //                 padding: const EdgeInsets.symmetric(vertical: 24),
// //                 decoration: BoxDecoration(
// //                   color: theme.colorScheme.surfaceContainerHighest,
// //                   borderRadius: BorderRadius.circular(12),
// //                 ),
// //                 child: Column(
// //                   children: [
// //                     const SizedBox(
// //                       width: 24,
// //                       height: 24,
// //                       child: CircularProgressIndicator(strokeWidth: 2),
// //                     ),
// //                     const SizedBox(height: 12),
// //                     Text(
// //                       'Response submitted! Waiting for others…',
// //                       textAlign: TextAlign.center,
// //                       style: theme.textTheme.bodyMedium,
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ── Voting screen ─────────────────────────────────────────────────────────────

// // class _VotingScreen extends StatelessWidget {
// //   const _VotingScreen({
// //     required this.game,
// //     required this.state,
// //     required this.displayNames,
// //     required this.roomId,
// //     required this.isOwner,
// //   });
// //   final MemeGameProvider game;
// //   final MemeState state;
// //   final Map<String, String> displayNames;
// //   final String roomId;
// //   final bool isOwner;

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     final hasVoted = state.votes.containsKey(game.userId);
// //     final entries = state.submissions.entries.toList();

// //     return Scaffold(
// //       appBar: AppBar(
// //         leading: BackButton(
// //           onPressed: () =>
// //               memeShowLeaveDialog(context, roomId: roomId, isOwner: isOwner),
// //         ),
// //         title: const Text('Vote for the best! 😂'),
// //         bottom: PreferredSize(
// //           preferredSize: const Size.fromHeight(24),
// //           child: Text(
// //             '${state.votes.length} / ${state.playerOrder.length} voted',
// //             style: theme.textTheme.bodySmall?.copyWith(
// //               color: theme.colorScheme.onSurfaceVariant,
// //             ),
// //           ),
// //         ),
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.stretch,
// //           children: [
// //             if (hasVoted)
// //               Container(
// //                 margin: const EdgeInsets.only(bottom: 12),
// //                 padding: const EdgeInsets.all(12),
// //                 decoration: BoxDecoration(
// //                   color: theme.colorScheme.surfaceContainerHighest,
// //                   borderRadius: BorderRadius.circular(12),
// //                 ),
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     const SizedBox(
// //                       width: 16,
// //                       height: 16,
// //                       child: CircularProgressIndicator(strokeWidth: 2),
// //                     ),
// //                     const SizedBox(width: 12),
// //                     Text(
// //                       'Voted! Waiting for others…',
// //                       style: theme.textTheme.bodyMedium,
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             Expanded(
// //               child: ListView.builder(
// //                 itemCount: entries.length,
// //                 itemBuilder: (_, i) {
// //                   final e = entries[i];
// //                   final sub = e.value;
// //                   final isOwn = e.key == game.userId;
// //                   final isVoted = state.votes[game.userId] == e.key;

// //                   return Card(
// //                     margin: const EdgeInsets.only(bottom: 12),
// //                     child: Padding(
// //                       padding: const EdgeInsets.all(16),
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Text(
// //                             'Response #${i + 1}',
// //                             style: theme.textTheme.labelMedium?.copyWith(
// //                               color: theme.colorScheme.onSurfaceVariant,
// //                             ),
// //                           ),
// //                           const SizedBox(height: 8),
// //                           // Sticker/caption — hidden until tapped for
// //                           // everyone else's submissions (surprise reveal),
// //                           // shown immediately for your own.
// //                           _HiddenReactionCard(
// //                             stickerChoice: sub.stickerChoice,
// //                             caption: sub.caption,
// //                             isOwn: isOwn,
// //                           ),
// //                           const SizedBox(height: 12),
// //                           // Reaction bar
// //                           _ReactionBar(
// //                             targetUserId: e.key,
// //                             game: game,
// //                             reactions: state.reactions,
// //                             myId: game.userId,
// //                           ),
// //                           const SizedBox(height: 10),
// //                           // Vote button
// //                           if (!hasVoted && !isOwn)
// //                             SizedBox(
// //                               width: double.infinity,
// //                               height: 42,
// //                               child: FilledButton(
// //                                 onPressed: () => game.voteFor(e.key),
// //                                 child: const Text('Vote for this 👍'),
// //                               ),
// //                             ),
// //                           if (!hasVoted && isOwn)
// //                             Text(
// //                               'Your response',
// //                               style: theme.textTheme.bodySmall?.copyWith(
// //                                 color: theme.colorScheme.onSurfaceVariant,
// //                               ),
// //                             ),
// //                           if (hasVoted && isVoted)
// //                             Container(
// //                               padding: const EdgeInsets.symmetric(
// //                                 horizontal: 10,
// //                                 vertical: 4,
// //                               ),
// //                               decoration: BoxDecoration(
// //                                 color: AppColors.successGreen.withOpacity(0.1),
// //                                 borderRadius: BorderRadius.circular(8),
// //                               ),
// //                               child: const Text(
// //                                 '✓ Your vote',
// //                                 style: TextStyle(
// //                                   color: AppColors.successGreen,
// //                                   fontWeight: FontWeight.w600,
// //                                 ),
// //                               ),
// //                             ),
// //                         ],
// //                       ),
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ── Results screen ────────────────────────────────────────────────────────────

// // class _ResultsScreen extends StatefulWidget {
// //   const _ResultsScreen({
// //     required this.game,
// //     required this.state,
// //     required this.displayNames,
// //     required this.roomId,
// //     required this.isOwner,
// //   });
// //   final MemeGameProvider game;
// //   final MemeState state;
// //   final Map<String, String> displayNames;
// //   final String roomId;
// //   final bool isOwner;
// //   @override
// //   State<_ResultsScreen> createState() => _ResultsScreenState();
// // }

// // class _ResultsScreenState extends State<_ResultsScreen> {
// //   bool _showHistory = false;

// //   @override
// //   Widget build(BuildContext context) {
// //     if (_showHistory) {
// //       return Scaffold(
// //         appBar: AppBar(
// //           title: const Text('Game History'),
// //           leading: BackButton(
// //             onPressed: () => setState(() => _showHistory = false),
// //           ),
// //         ),
// //         body: _HistoryPanel(
// //           history: widget.state.history,
// //           displayNames: widget.displayNames,
// //           onClose: () => setState(() => _showHistory = false),
// //         ),
// //       );
// //     }

// //     final theme = context.theme;
// //     final state = widget.state;
// //     final game = widget.game;
// //     final winnerId = state.roundWinnerId;
// //     final tally = <String, int>{};
// //     for (final t in state.votes.values) tally[t] = (tally[t] ?? 0) + 1;

// //     return Scaffold(
// //       appBar: AppBar(
// //         leading: BackButton(
// //           onPressed: () => memeShowLeaveDialog(
// //             context,
// //             roomId: widget.roomId,
// //             isOwner: widget.isOwner,
// //             displayName:
// //                 widget.displayNames[Supabase
// //                         .instance
// //                         .client
// //                         .auth
// //                         .currentUser
// //                         ?.id ??
// //                     ''] ??
// //                 'A player',
// //           ),
// //         ),
// //         title: Text('Round ${state.roundNumber} Results 🏆'),
// //         actions: [
// //           if (state.history.isNotEmpty)
// //             IconButton(
// //               icon: const Icon(Icons.history_rounded),
// //               onPressed: () => setState(() => _showHistory = true),
// //             ),
// //         ],
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.stretch,
// //           children: [
// //             // Winner banner
// //             if (winnerId != null)
// //               Container(
// //                 padding: const EdgeInsets.all(16),
// //                 margin: const EdgeInsets.only(bottom: 16),
// //                 decoration: BoxDecoration(
// //                   color: AppColors.amberOrangeLight.withOpacity(0.12),
// //                   borderRadius: BorderRadius.circular(14),
// //                   border: Border.all(
// //                     color: AppColors.amberOrangeLight,
// //                     width: 1.5,
// //                   ),
// //                 ),
// //                 child: Column(
// //                   children: [
// //                     const Text('🏆', style: TextStyle(fontSize: 40)),
// //                     Text(
// //                       _nameOf(widget.displayNames, winnerId),
// //                       style: theme.textTheme.titleLarge?.copyWith(
// //                         fontWeight: FontWeight.w800,
// //                       ),
// //                     ),
// //                     Text(
// //                       'wins this round!',
// //                       style: theme.textTheme.bodyMedium?.copyWith(
// //                         color: theme.colorScheme.onSurfaceVariant,
// //                       ),
// //                     ),
// //                     if (state.submissions[winnerId]?.stickerChoice.isNotEmpty ==
// //                         true)
// //                       StickerDisplay(
// //                         assetPath: state.submissions[winnerId]!.stickerChoice,
// //                         size: 72,
// //                       ),
// //                     if (state.submissions[winnerId]?.caption.isNotEmpty ==
// //                         true) ...[
// //                       const SizedBox(height: 4),
// //                       Text(
// //                         '"${state.submissions[winnerId]!.caption}"',
// //                         textAlign: TextAlign.center,
// //                         style: theme.textTheme.bodyMedium?.copyWith(
// //                           fontStyle: FontStyle.italic,
// //                         ),
// //                       ),
// //                     ],
// //                   ],
// //                 ),
// //               ),

// //             Expanded(
// //               child: ListView(
// //                 children: state.submissions.entries.map((e) {
// //                   final sub = e.value;
// //                   final votes = tally[e.key] ?? 0;
// //                   final isWinner = e.key == winnerId;
// //                   return Card(
// //                     margin: const EdgeInsets.only(bottom: 10),
// //                     color: isWinner
// //                         ? AppColors.amberOrangeLight.withOpacity(0.06)
// //                         : null,
// //                     child: Padding(
// //                       padding: const EdgeInsets.all(14),
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Row(
// //                             children: [
// //                               Text(
// //                                 _nameOf(widget.displayNames, e.key),
// //                                 style: theme.textTheme.labelLarge?.copyWith(
// //                                   fontWeight: FontWeight.w600,
// //                                   color: isWinner
// //                                       ? AppColors.amberOrangeLight
// //                                       : null,
// //                                 ),
// //                               ),
// //                               if (isWinner) ...[
// //                                 const SizedBox(width: 4),
// //                                 const Text('🏆'),
// //                               ],
// //                               const Spacer(),
// //                               Text(
// //                                 '$votes 👍',
// //                                 style: theme.textTheme.labelLarge?.copyWith(
// //                                   fontWeight: FontWeight.w700,
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                           const SizedBox(height: 8),
// //                           if (sub.stickerChoice.isNotEmpty)
// //                             _TappableStickerCard(
// //                               assetPath: sub.stickerChoice,
// //                               caption: sub.caption,
// //                             ),
// //                           const SizedBox(height: 8),
// //                           // Reactions
// //                           _ReactionBar(
// //                             targetUserId: e.key,
// //                             game: game,
// //                             reactions: state.reactions,
// //                             myId: game.userId,
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   );
// //                 }).toList(),
// //               ),
// //             ),

// //             const Divider(),
// //             Text(
// //               'Scores',
// //               style: theme.textTheme.labelLarge?.copyWith(
// //                 fontWeight: FontWeight.w700,
// //               ),
// //             ),
// //             const SizedBox(height: 4),
// //             ...(state.scores.entries.toList()
// //                   ..sort((a, b) => b.value.compareTo(a.value)))
// //                 .map(
// //                   (e) => Padding(
// //                     padding: const EdgeInsets.symmetric(vertical: 2),
// //                     child: Row(
// //                       children: [
// //                         Text(
// //                           _nameOf(widget.displayNames, e.key),
// //                           style: theme.textTheme.bodyMedium,
// //                         ),
// //                         const Spacer(),
// //                         Text(
// //                           '${e.value} 🏆',
// //                           style: theme.textTheme.bodyMedium?.copyWith(
// //                             fontWeight: FontWeight.w600,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //             const SizedBox(height: 12),

// //             if (game.isOwner)
// //               SizedBox(
// //                 height: 52,
// //                 child: FilledButton(
// //                   onPressed: game.ownerAdvanceTurn,
// //                   child: const Text('Next Round →'),
// //                 ),
// //               )
// //             else
// //               Container(
// //                 padding: const EdgeInsets.all(12),
// //                 decoration: BoxDecoration(
// //                   color: theme.colorScheme.surfaceContainerHighest,
// //                   borderRadius: BorderRadius.circular(12),
// //                 ),
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     const SizedBox(
// //                       width: 16,
// //                       height: 16,
// //                       child: CircularProgressIndicator(strokeWidth: 2),
// //                     ),
// //                     const SizedBox(width: 10),
// //                     Text(
// //                       'Waiting for host…',
// //                       style: theme.textTheme.bodyMedium,
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ── History panel ─────────────────────────────────────────────────────────────

// // class _HistoryPanel extends StatelessWidget {
// //   const _HistoryPanel({
// //     required this.history,
// //     required this.displayNames,
// //     required this.onClose,
// //   });
// //   final List<MemeRoundRecord> history;
// //   final Map<String, String> displayNames;
// //   final VoidCallback onClose;

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     return Column(
// //       children: [
// //         ListTile(
// //           leading: const Icon(Icons.history_rounded),
// //           title: Text(
// //             'History (${history.length} rounds)',
// //             style: theme.textTheme.titleMedium?.copyWith(
// //               fontWeight: FontWeight.w700,
// //             ),
// //           ),
// //           trailing: IconButton(
// //             icon: const Icon(Icons.close),
// //             onPressed: onClose,
// //           ),
// //         ),
// //         const Divider(height: 0),
// //         Expanded(
// //           child: ListView.builder(
// //             padding: const EdgeInsets.all(12),
// //             itemCount: history.length,
// //             itemBuilder: (_, i) {
// //               final round = history[history.length - 1 - i];
// //               return Card(
// //                 margin: const EdgeInsets.only(bottom: 12),
// //                 child: ExpansionTile(
// //                   leading: CircleAvatar(
// //                     backgroundColor: theme.colorScheme.primaryContainer,
// //                     child: Text(
// //                       '${round.roundNumber}',
// //                       style: theme.textTheme.labelLarge,
// //                     ),
// //                   ),
// //                   title: Text(
// //                     round.prompt.caption,
// //                     style: theme.textTheme.bodyMedium?.copyWith(
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                     maxLines: 2,
// //                     overflow: TextOverflow.ellipsis,
// //                   ),
// //                   subtitle: Text(
// //                     'Winner: ${round.winnerId != null ? _nameOf(displayNames, round.winnerId!) : 'Tie'}',
// //                     style: theme.textTheme.bodySmall,
// //                   ),
// //                   children: [
// //                     Padding(
// //                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: round.submissions.entries.map((e) {
// //                           final sub = e.value;
// //                           final reacts = round.reactions
// //                               .where((r) => r.targetUserId == e.key)
// //                               .toList();
// //                           final reactTally = <String, int>{};
// //                           for (final r in reacts)
// //                             reactTally[r.emoji] =
// //                                 (reactTally[r.emoji] ?? 0) + 1;
// //                           final isWinner = e.key == round.winnerId;
// //                           return Padding(
// //                             padding: const EdgeInsets.only(bottom: 10),
// //                             child: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 Row(
// //                                   children: [
// //                                     Text(
// //                                       _nameOf(displayNames, e.key),
// //                                       style: theme.textTheme.bodySmall
// //                                           ?.copyWith(
// //                                             fontWeight: FontWeight.w700,
// //                                             color: isWinner
// //                                                 ? AppColors.amberOrangeLight
// //                                                 : null,
// //                                           ),
// //                                     ),
// //                                     if (isWinner) const Text(' 🏆'),
// //                                   ],
// //                                 ),
// //                                 if (sub.stickerChoice.isNotEmpty)
// //                                   StickerDisplay(
// //                                     assetPath: sub.stickerChoice,
// //                                     size: 48,
// //                                   ),
// //                                 if (sub.caption.isNotEmpty)
// //                                   Text(
// //                                     '"${sub.caption}"',
// //                                     style: theme.textTheme.bodySmall?.copyWith(
// //                                       fontStyle: FontStyle.italic,
// //                                     ),
// //                                   ),
// //                                 if (reactTally.isNotEmpty)
// //                                   Padding(
// //                                     padding: const EdgeInsets.only(top: 4),
// //                                     child: Wrap(
// //                                       spacing: 4,
// //                                       children: reactTally.entries
// //                                           .map(
// //                                             (r) => Text(
// //                                               '${r.key}${r.value}',
// //                                               style: const TextStyle(
// //                                                 fontSize: 14,
// //                                               ),
// //                                             ),
// //                                           )
// //                                           .toList(),
// //                                     ),
// //                                   ),
// //                               ],
// //                             ),
// //                           );
// //                         }).toList(),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               );
// //             },
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }

// // // ── Game over ─────────────────────────────────────────────────────────────────

// // class _GameOverScreen extends StatefulWidget {
// //   const _GameOverScreen({required this.game, required this.displayNames});
// //   final MemeGameProvider game;
// //   final Map<String, String> displayNames;
// //   @override
// //   State<_GameOverScreen> createState() => _GameOverScreenState();
// // }

// // class _GameOverScreenState extends State<_GameOverScreen> {
// //   bool _showHistory = false;

// //   @override
// //   Widget build(BuildContext context) {
// //     final scores = widget.game.state?.scores ?? {};
// //     final history = widget.game.state?.history ?? [];
// //     final sorted = scores.entries.toList()
// //       ..sort((a, b) => b.value.compareTo(a.value));
// //     const medals = ['🥇', '🥈', '🥉'];

// //     if (_showHistory) {
// //       return Scaffold(
// //         appBar: AppBar(
// //           title: const Text('Game History'),
// //           leading: BackButton(
// //             onPressed: () => setState(() => _showHistory = false),
// //           ),
// //         ),
// //         body: _HistoryPanel(
// //           history: history,
// //           displayNames: widget.displayNames,
// //           onClose: () => setState(() => _showHistory = false),
// //         ),
// //       );
// //     }

// //     return Scaffold(
// //       body: SafeArea(
// //         child: Padding(
// //           padding: const EdgeInsets.all(24),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.stretch,
// //             children: [
// //               const Text(
// //                 '😂🏆',
// //                 textAlign: TextAlign.center,
// //                 style: TextStyle(fontSize: 64),
// //               ),
// //               Text(
// //                 'Game Over!',
// //                 textAlign: TextAlign.center,
// //                 style: context.textTheme.headlineMedium?.copyWith(
// //                   fontWeight: FontWeight.w800,
// //                 ),
// //               ),
// //               Text(
// //                 'Funniest player wins!',
// //                 textAlign: TextAlign.center,
// //                 style: context.textTheme.bodyLarge?.copyWith(
// //                   color: context.colorScheme.onSurfaceVariant,
// //                 ),
// //               ),
// //               const SizedBox(height: 20),
// //               Expanded(
// //                 child: ListView.builder(
// //                   itemCount: sorted.length,
// //                   itemBuilder: (_, i) {
// //                     final e = sorted[i];
// //                     return ListTile(
// //                       leading: Text(
// //                         i < medals.length ? medals[i] : '${i + 1}.',
// //                         style: const TextStyle(fontSize: 24),
// //                       ),
// //                       title: Text(
// //                         _nameOf(widget.displayNames, e.key),
// //                         style: context.textTheme.titleMedium?.copyWith(
// //                           fontWeight: FontWeight.w700,
// //                         ),
// //                       ),
// //                       trailing: Text(
// //                         '${e.value} 🏆',
// //                         style: context.textTheme.titleMedium?.copyWith(
// //                           color: AppColors.amberOrangeLight,
// //                           fontWeight: FontWeight.w700,
// //                         ),
// //                       ),
// //                     );
// //                   },
// //                 ),
// //               ),
// //               if (history.isNotEmpty) ...[
// //                 OutlinedButton.icon(
// //                   onPressed: () => setState(() => _showHistory = true),
// //                   icon: const Icon(Icons.history_rounded),
// //                   label: Text('View History (${history.length} rounds)'),
// //                 ),
// //                 const SizedBox(height: 10),
// //               ],
// //               SizedBox(
// //                 height: 52,
// //                 child: FilledButton(
// //                   onPressed: () => context.go(RouteNames.home),
// //                   child: const Text('Back to Home'),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ── Shared paused overlay for meme/nhie ──────────────────────────────────────
// // class _MemeNhiePausedOverlay extends StatefulWidget {
// //   const _MemeNhiePausedOverlay({required this.onLeave});
// //   final VoidCallback onLeave;
// //   @override
// //   State<_MemeNhiePausedOverlay> createState() => _MemeNhiePausedOverlayState();
// // }

// // class _MemeNhiePausedOverlayState extends State<_MemeNhiePausedOverlay>
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
// //   Widget build(BuildContext context) => Dialog.fullscreen(
// //     backgroundColor: Colors.transparent,
// //     child: Scaffold(
// //       backgroundColor: Colors.transparent,
// //       body: Center(
// //         child: Padding(
// //           padding: const EdgeInsets.all(32),
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               AnimatedBuilder(
// //                 animation: _pulse,
// //                 builder: (_, child) =>
// //                     Opacity(opacity: 0.6 + _pulse.value * 0.4, child: child),
// //                 child: const Text('⏸', style: TextStyle(fontSize: 72)),
// //               ),
// //               const SizedBox(height: 24),
// //               const Text(
// //                 'Game Paused',
// //                 style: TextStyle(
// //                   color: Colors.white,
// //                   fontSize: 28,
// //                   fontWeight: FontWeight.w800,
// //                 ),
// //               ),
// //               const SizedBox(height: 12),
// //               const Text(
// //                 'The host stepped away and will\nreturn shortly.',
// //                 textAlign: TextAlign.center,
// //                 style: TextStyle(
// //                   color: Colors.white70,
// //                   fontSize: 16,
// //                   height: 1.5,
// //                 ),
// //               ),
// //               const SizedBox(height: 40),
// //               OutlinedButton(
// //                 style: OutlinedButton.styleFrom(
// //                   foregroundColor: Colors.white,
// //                   side: const BorderSide(color: Colors.white38),
// //                   padding: const EdgeInsets.symmetric(
// //                     horizontal: 32,
// //                     vertical: 14,
// //                   ),
// //                 ),
// //                 onPressed: widget.onLeave,
// //                 child: const Text('Leave for Now'),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     ),
// //   );
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
// import 'package:jma3a/features/settings/presentation/screen_security_service.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../../../core/di/service_locator.dart';
// import '../../../../core/extensions/context_ext.dart';
// import '../../../../core/providers/auth_provider.dart';
// import '../../../../core/router/route_names.dart';
// import '../../../../core/services/realtime_service.dart';
// // import '../../../../core/services/screen_security_service.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/utils/app_logger.dart';

// enum MemeLoadState { idle, loading, ready, error, gameOver }

// class MemeGameProvider extends ChangeNotifier {
//   MemeGameProvider({
//     required RealtimeService realtimeService,
//     required String userId,
//     required String displayName,
//   }) : _realtime = realtimeService,
//        _userId = userId,
//        _displayName = displayName;

//   final RealtimeService _realtime;
//   final String _userId, _displayName;
//   MemeGameEngine? _engine;
//   MemeLoadState _loadState = MemeLoadState.idle;
//   String? _roomId;
//   String? _sessionId;
//   bool _isOwner = false;
//   String _error = '';
//   // Away player tracking — filled by player_left broadcasts so the owner
//   // can auto-skip their turns instead of waiting for them.
//   final Set<String> _awayPlayerIds = {};

//   MemeLoadState get loadState => _loadState;
//   MemeState? get state => _engine?.currentState as MemeState?;
//   String get userId => _userId;
//   bool get isOwner => _isOwner;

//   bool get allPlayersVoted {
//     final s = state;
//     if (s == null) return true;
//     return s.votes.length >= s.playerOrder.length;
//   }

//   int get votedCount => state?.votes.length ?? 0;
//   int get playerCount => state?.playerOrder.length ?? 1;
//   String get error => _error;
//   Set<String> get awayPlayerIds => _awayPlayerIds;

//   void markPlayerAway(String userId, {bool forGood = false}) {
//     _awayPlayerIds.add(userId);
//     // Meme is simultaneous — everyone submits at once, so there's no
//     // single "current submitter" to skip. If the away player hasn't
//     // submitted yet, auto-submit a blank on their behalf so the round
//     // isn't stuck waiting for them.
//     if (_isOwner && _engine != null) {
//       final s = _engine!.currentState as MemeState?;
//       if (s != null &&
//           s.phase == MemePhase.submitting &&
//           !s.submissions.containsKey(userId)) {
//         Future.microtask(
//           () => _handleAction({
//             'action': 'meme_submit',
//             'user_id': userId,
//             'caption': '',
//             'sticker_choice': '',
//           }),
//         );
//       }
//     }
//     notifyListeners();
//   }

//   void markPlayerReturned(String userId) {
//     _awayPlayerIds.remove(userId);
//     notifyListeners();
//   }

//   // ── Init ────────────────────────────────────────────────────────────────────

//   Future<void> initAsOwner({
//     required String roomId,
//     required String packId,
//     required List<String> playerIds,
//     required Map<String, String> displayNames,
//     required GameConfig config,
//   }) async {
//     _roomId = roomId;
//     _isOwner = true;
//     _loadState = MemeLoadState.loading;
//     notifyListeners();
//     try {
//       var todCards = await TodRepository.instance.loadCardsFromCache(
//         packId: packId,
//         language: config.language,
//       );
//       if (todCards.isEmpty) {
//         final rows = await Supabase.instance.client
//             .from('pack_cards')
//             .select('id, content, card_type, difficulty, sort_order')
//             .eq('pack_id', packId)
//             .order('sort_order');
//         todCards = (rows as List).map((r) {
//           String text = '';
//           final raw = r['content'];
//           if (raw is Map) {
//             final m = Map<String, dynamic>.from(raw as Map);
//             text =
//                 (m[config.language] ??
//                         m['en'] ??
//                         m.values.whereType<String>().firstOrNull ??
//                         '')
//                     as String;
//           } else if (raw is String) {
//             try {
//               final d = jsonDecode(raw);
//               if (d is Map)
//                 text = (d[config.language] ?? d['en'] ?? '') as String;
//               else
//                 text = raw;
//             } catch (_) {
//               text = raw;
//             }
//           }
//           // difficulty from DB may be a Map (localized) or String — normalise
//           final rawDiff = r['difficulty'];
//           final diffStr = rawDiff is Map
//               ? (rawDiff['en'] ?? rawDiff.values.first ?? 'mild').toString()
//               : rawDiff?.toString() ?? 'mild';
//           return TodCard(
//             id: r['id'] as String,
//             content: text,
//             type: TodCardType.truth,
//             difficulty: TodDifficulty.values.firstWhere(
//               (d) => d.name == diffStr,
//               orElse: () => TodDifficulty.mild,
//             ),
//           );
//         }).toList();
//       }
//       final prompts = todCards
//           .map((c) => MemePrompt(id: c.id, caption: c.content))
//           .toList();

//       _engine = MemeGameEngine(config, prompts: prompts);

//       // ✅ Resume an existing in-progress session if one exists, instead of
//       // always creating a brand-new one. Without this, re-entering this
//       // screen (including "Resume Game") silently wiped any prior progress.
//       final existing = await Supabase.instance.client
//           .from('game_sessions')
//           .select('id, state_snapshot, game_type')
//           .eq('room_id', roomId)
//           .eq('status', 'active')
//           .order('started_at', ascending: false)
//           .limit(1)
//           .maybeSingle();
//       final snapshotGameType = existing?['game_type'] as String?;
//       Map<String, dynamic>? existingSnapshot;
//       if (snapshotGameType == 'meme_game') {
//         existingSnapshot = existing?['state_snapshot'] as Map<String, dynamic>?;
//       }

//       if (existing != null &&
//           existingSnapshot != null &&
//           existingSnapshot.isNotEmpty) {
//         _sessionId = existing['id'] as String;
//         _engine!.restoreFromSnapshot(existingSnapshot);
//         AppLogger.info('MemeProvider: resumed existing session $_sessionId');
//       } else {
//         _engine!.init(playerIds);
//         try {
//           final inserted = await Supabase.instance.client
//               .from('game_sessions')
//               .insert({
//                 'room_id': roomId,
//                 'pack_id': packId,
//                 'game_type': 'meme_game',
//                 'player_ids': playerIds,
//                 'owner_id': _userId,
//                 'state_snapshot': _engine!.serializeState(),
//                 'max_rounds': config.maxRounds,
//                 'turn_timer_secs': config.turnTimerSeconds,
//                 'allow_skip': config.allowSkip,
//                 'allow_spicy': config.allowSpicy,
//               })
//               .select('id')
//               .single();
//           _sessionId = inserted['id'] as String;
//         } catch (e) {
//           AppLogger.warning('MemeProvider: failed to create session: $e');
//         }
//       }

//       _loadState = MemeLoadState.ready;
//       notifyListeners();
//       _broadcastState();
//     } catch (e) {
//       _error = e.toString();
//       _loadState = MemeLoadState.error;
//       AppLogger.error('MemeProvider: init failed', error: e);
//       notifyListeners();
//     }
//   }

//   void initAsFollower(String roomId) {
//     _roomId = roomId;
//     _isOwner = false;
//     _loadState = MemeLoadState.loading;
//     notifyListeners();
//   }

//   // ── Actions ──────────────────────────────────────────────────────────────────

//   Future<void> submit({String caption = '', String stickerChoice = ''}) =>
//       _handleAction({
//         'action': 'meme_submit',
//         'caption': caption,
//         'sticker_choice': stickerChoice,
//       });

//   Future<void> voteFor(String targetUserId) =>
//       _handleAction({'action': 'meme_vote', 'target_user_id': targetUserId});

//   Future<void> reactTo(String targetUserId, String emoji) => _handleAction({
//     'action': 'meme_react',
//     'target_user_id': targetUserId,
//     'emoji': emoji,
//   });

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
//       final snap =
//           (payload['snapshot'] as Map<String, dynamic>?)?['state']
//               as Map<String, dynamic>? ??
//           payload['state'] as Map<String, dynamic>?;
//       if (snap == null) return;
//       _engine ??= MemeGameEngine(
//         const GameConfig(
//           maxRounds: 10,
//           turnTimerSeconds: 60,
//           allowSkip: false,
//           allowSpicy: false,
//         ),
//         prompts: [],
//       );
//       _engine!.restoreFromSnapshot(snap);
//       _loadState = _engine!.isGameOver
//           ? MemeLoadState.gameOver
//           : MemeLoadState.ready;
//       notifyListeners();
//     } catch (e) {
//       AppLogger.warning('MemeProvider: restore failed: $e');
//     }
//   }

//   void onPlayerAction(Map<String, dynamic> payload) {
//     if (!_isOwner || _engine == null) return;
//     final action = payload['action'] as String?;
//     final uid = payload['user_id'] as String?;
//     final ts = payload['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
//     if (uid == null) return;
//     switch (action) {
//       case 'meme_submit':
//         _engine!.handleEvent(
//           MemeSubmitEvent(
//             userId: uid,
//             ts: ts,
//             caption: payload['caption'] as String? ?? '',
//             stickerChoice: payload['sticker_choice'] as String? ?? '',
//           ),
//         );
//       case 'meme_vote':
//         _engine!.handleEvent(
//           MemeVoteEvent(
//             userId: uid,
//             ts: ts,
//             targetUserId: payload['target_user_id'] as String? ?? '',
//           ),
//         );
//       case 'meme_react':
//         _engine!.handleEvent(
//           MemeReactEvent(
//             userId: uid,
//             ts: ts,
//             targetUserId: payload['target_user_id'] as String? ?? '',
//             emoji: payload['emoji'] as String? ?? '👍',
//           ),
//         );
//     }
//     if (_engine!.isGameOver) _loadState = MemeLoadState.gameOver;
//     notifyListeners();
//     _broadcastState();
//   }

//   void onSyncRequest(Map<String, dynamic> _) {
//     if (_isOwner) _broadcastState();
//   }

//   Future<void> _handleAction(Map<String, dynamic> action) async {
//     final full = {
//       ...action,
//       'user_id': _userId,
//       'display_name': _displayName,
//       'ts': DateTime.now().millisecondsSinceEpoch,
//     };
//     if (_isOwner && _engine != null)
//       onPlayerAction(full);
//     else if (_roomId != null)
//       await _realtime.broadcastPlayerAction(_roomId!, full);
//   }

//   void _broadcastState() {
//     if (_roomId == null || _engine == null) return;
//     final snapshot = _engine!.serializeState();
//     _realtime.broadcastGameState(_roomId!, {
//       'state': snapshot,
//     }, _userId).ignore();

//     // Persist so a later resume can restore exactly where play left off —
//     // fire-and-forget, never blocks gameplay on a slow write.
//     if (_isOwner && _sessionId != null) {
//       Supabase.instance.client
//           .from('game_sessions')
//           .update({
//             'state_snapshot': snapshot,
//             'updated_at': DateTime.now().toIso8601String(),
//             if (_engine!.isGameOver) 'status': 'completed',
//             if (_engine!.isGameOver)
//               'ended_at': DateTime.now().toIso8601String(),
//           })
//           .eq('id', _sessionId!)
//           .then(
//             (_) {},
//             onError: (e) {
//               AppLogger.warning('MemeProvider: snapshot save failed: $e');
//             },
//           );
//     }
//   }
// }

// Future<void> memeShowLeaveDialog(
//   BuildContext ctx, {
//   required String roomId,
//   required bool isOwner,
//   String displayName = 'A player',
// }) async {
//   if (!ctx.mounted) return;
//   final myUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
//   final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

//   if (isOwner) {
//     // Check for moderators who could take over
//     final mods = await sl.roomRepository
//         .getRoomModerators(roomId)
//         .catchError((_) => <Map<String, dynamic>>[]);
//     final hasMod = mods.isNotEmpty;

//     final choice = await showDialog<String>(
//       context: ctx,
//       builder: (d) => AlertDialog(
//         title: const Text('Leave Game?'),
//         content: const Text("Choose what happens while you're away."),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(d, 'cancel'),
//             child: const Text('Stay'),
//           ),
//           if (hasMod)
//             FilledButton.tonal(
//               onPressed: () => Navigator.pop(d, 'handoff'),
//               child: const Text('Play Another & Hand Off'),
//             ),
//           FilledButton.tonal(
//             onPressed: () => Navigator.pop(d, 'quit_lobby'),
//             child: const Text('Quit to Lobby'),
//           ),
//           FilledButton.tonal(
//             onPressed: () => Navigator.pop(d, 'pause'),
//             child: const Text('Pause & Return Later'),
//           ),
//           FilledButton(
//             style: FilledButton.styleFrom(backgroundColor: Colors.red),
//             onPressed: () => Navigator.pop(d, 'end'),
//             child: const Text('End Room for Everyone'),
//           ),
//         ],
//       ),
//     );
//     if (choice == null || choice == 'cancel' || !ctx.mounted) return;

//     if (choice == 'handoff' && mods.isNotEmpty) {
//       final newOwner = mods.length == 1
//           ? mods.first['user_id'] as String
//           : await showDialog<String>(
//               context: ctx,
//               builder: (d) => SimpleDialog(
//                 title: const Text('Who takes over?'),
//                 children: mods.map((m) {
//                   final uid = m['user_id'] as String;
//                   return SimpleDialogOption(
//                     onPressed: () => Navigator.pop(d, uid),
//                     child: Text(uid.substring(0, 8).toUpperCase()),
//                   );
//                 }).toList(),
//               ),
//             );
//       if (newOwner == null || !ctx.mounted) return;
//       try {
//         await Supabase.instance.client
//             .from('rooms')
//             .update({'owner_id': newOwner})
//             .eq('id', roomId);
//         await sl.realtimeService.broadcastRoomEvent(roomId, {
//           'type': 'ownership_transferred',
//           'new_owner_id': newOwner,
//           'by': myUserId,
//         });
//         await sl.realtimeService.broadcastRoomEvent(roomId, {
//           'type': 'player_left',
//           'user_id': myUserId,
//           'for_good': true,
//         });
//       } catch (_) {}
//       if (ctx.mounted) AppRouter.router.go(RouteNames.home);
//       return;
//     }

//     if (choice == 'quit_lobby') {
//       try {
//         await sl.realtimeService.broadcastRoomEvent(roomId, {
//           'type': 'game_ended',
//           'reason': 'host_quit_to_lobby',
//         });
//         await sl.roomRepository.updateStatus(roomId, RoomStatus.waiting);
//       } catch (_) {}
//       if (ctx.mounted) AppRouter.router.go('/home/room/$roomId');
//       return;
//     }

//     if (choice == 'pause') {
//       try {
//         await sl.roomRepository.updateStatus(roomId, RoomStatus.paused);
//         await sl.realtimeService.broadcastRoomEvent(roomId, {
//           'type': 'game_paused',
//           'reason': 'host_away',
//         });
//         await Future.delayed(const Duration(milliseconds: 300));
//       } catch (_) {}
//       if (ctx.mounted) AppRouter.router.go(RouteNames.home);
//     } else {
//       try {
//         await sl.realtimeService.broadcastGameEnded(roomId, {
//           'reason': 'host_ended',
//         });
//         await sl.realtimeService.broadcastRoomEvent(roomId, {
//           'type': 'owner_left',
//           'reason': 'host_ended',
//         });
//         await sl.roomRepository.updateStatus(roomId, RoomStatus.closed);
//       } catch (_) {}
//       if (ctx.mounted) AppRouter.router.go(RouteNames.home);
//     }
//   } else {
//     final returnMins = isPremium ? 10 : 5;
//     final choice = await showDialog<String>(
//       context: ctx,
//       builder: (d) => AlertDialog(
//         title: const Text('Leave Game?'),
//         content: Text(
//           "If you'll return, your turns will be skipped. You have "
//           '$returnMins minutes — after that your seat is lost.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(d, 'cancel'),
//             child: const Text('Stay'),
//           ),
//           FilledButton.tonal(
//             onPressed: () => Navigator.pop(d, 'return'),
//             child: Text("I'll Return ($returnMins min)"),
//           ),
//           FilledButton(
//             style: FilledButton.styleFrom(backgroundColor: Colors.red),
//             onPressed: () => Navigator.pop(d, 'definitive'),
//             child: const Text('Leave for Good'),
//           ),
//         ],
//       ),
//     );
//     if (choice == null || choice == 'cancel' || !ctx.mounted) return;
//     try {
//       if (choice == 'return') {
//         await sl.roomRepository.setMemberAway(roomId, myUserId, away: true);
//         await sl.roomRepository.setReturnTimer(
//           roomId: roomId,
//           userId: myUserId,
//           isPremium: isPremium,
//         );
//         await sl.realtimeService.broadcastRoomEvent(roomId, {
//           'type': 'player_left',
//           'user_id': myUserId,
//           'display_name': displayName,
//           'for_good': false,
//           'return_mins': returnMins,
//         });
//       } else {
//         await sl.roomRepository.setMemberDefinitiveLeave(roomId, myUserId);
//         await sl.realtimeService.broadcastRoomEvent(roomId, {
//           'type': 'player_left',
//           'user_id': myUserId,
//           'display_name': displayName,
//           'for_good': true,
//         });
//       }
//     } catch (_) {}
//     if (ctx.mounted) AppRouter.router.go(RouteNames.home);
//   }
// }

// class MemeGameScreen extends StatefulWidget {
//   const MemeGameScreen({
//     super.key,
//     required this.roomId,
//     required this.config,
//     required this.playerIds,
//     required this.playerDisplayNames,
//     required this.packId,
//     this.packCoverUrl,
//     required this.isOwner,
//     this.isModerator = false,
//   });
//   final String roomId;
//   final GameConfig config;
//   final List<String> playerIds;
//   final Map<String, String> playerDisplayNames;
//   final String packId;
//   final bool isOwner;
//   final bool isModerator;
//   final String? packCoverUrl;
//   @override
//   State<MemeGameScreen> createState() => _MemeGameScreenState();
// }

// class _MemeGameScreenState extends State<MemeGameScreen> {
//   late final MemeGameProvider _provider;

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
//     final user = context.read<AuthProvider>().currentUser!;
//     _provider = MemeGameProvider(
//       realtimeService: sl.realtimeService,
//       userId: user.id,
//       displayName: user.displayName ?? user.username ?? 'Player',
//     );
//     // Update callbacks on existing channel — no teardown needed
//     sl.realtimeService.subscribe(
//       roomId: widget.roomId,
//       onGameState: (p) => _provider.onStateBroadcast(p),
//       onPlayerAction: (p) => _provider.onPlayerAction(p),
//       onSyncRequest: (p) => _provider.onSyncRequest(p),
//       onGameStarted: (_) {},
//       onGameEnded: (p) {
//         // Admin ended the game — take everyone back to the lobby
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('The host ended the game')),
//           );
//           // Pop back to lobby (the LobbyScreen is still on the stack)
//           if (context.canPop())
//             context.pop();
//           else
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (mounted)
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
//               else
//                 AppRouter.router.go(RouteNames.home);
//             });
//         }
//       },
//       onRoomEvent: (p) {
//         final type = p['type'] as String?;
//         if (type == 'screenshot_taken') {
//           final shooterId = p['user_id'] as String?;
//           final myId = context.read<AuthProvider>().currentUser?.id;
//           if (shooterId != null && shooterId != myId && mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                   '📸 ${widget.playerDisplayNames[shooterId] ?? 'Someone'} took a screenshot',
//                 ),
//                 backgroundColor: Colors.black87,
//               ),
//             );
//           }
//           return;
//         }
//         if (type == 'game_ended' && mounted) {
//           if ((p['reason'] as String?) == 'host_quit_to_lobby') {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (!mounted) return;
//               // Unsubscribe before navigating so this handler doesn't fire
//               // again when the lobby re-subscribes to the same channel.
//               sl.realtimeService.unsubscribe(widget.roomId);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('🔄 Host ended the game — back to lobby'),
//                   duration: Duration(seconds: 3),
//                 ),
//               );
//               if (context.canPop()) {
//                 context.pop();
//               } else {
//                 AppRouter.router.go('/home/room/${widget.roomId}');
//               }
//             });
//           }
//           return;
//         }
//         if (type == 'player_left' && mounted) {
//           final name = p['display_name'] as String? ?? 'A player';
//           final forGood = p['for_good'] as bool? ?? true;
//           final leavingId = p['user_id'] as String?;
//           final returnMins = p['return_mins'] as int?;
//           // Tell the provider so the owner auto-skips this player's turns
//           if (leavingId != null && _provider.isOwner) {
//             _provider.markPlayerAway(leavingId, forGood: forGood);
//           }
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 forGood
//                     ? '👋 $name left the game'
//                     : '🕐 $name stepped away (${returnMins != null ? 'back in ${returnMins}m' : 'coming back'})',
//               ),
//               backgroundColor: forGood
//                   ? Colors.red.shade700
//                   : Colors.orange.shade700,
//               duration: const Duration(seconds: 4),
//             ),
//           );
//           return;
//         }
//         if (type == 'ownership_transferred' && mounted) {
//           final myId = context.read<AuthProvider>().currentUser?.id;
//           if (p['new_owner_id'] == myId) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('👑 You are now the game host!'),
//                 backgroundColor: Colors.purple,
//               ),
//             );
//           }
//           return;
//         }
//         if (type == 'game_paused' && mounted) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (!mounted) return;
//             showDialog(
//               context: context,
//               barrierDismissible: false,
//               barrierColor: Colors.black.withOpacity(0.85),
//               builder: (_) => _MemeNhiePausedOverlay(
//                 onLeave: () {
//                   Navigator.of(context).pop();
//                   AppRouter.router.go(RouteNames.home);
//                 },
//               ),
//             );
//           });
//         }
//         if ((type == 'room_closed' || type == 'owner_left') && mounted) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (mounted)
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
//             else
//               AppRouter.router.go(RouteNames.home);
//           });
//         }
//       },
//       onChatMessage: (_) {},
//       onModeration: (p) {
//         final type = p['type'] as String?;
//         final targetId = p['target_user_id'] as String?;
//         final myId = context.read<AuthProvider>().currentUser?.id;
//         if ((type == 'kick' || type == 'ban') && targetId == myId && mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 type == 'kick'
//                     ? 'You were removed from the room'
//                     : 'You were banned from this room',
//               ),
//             ),
//           );
//           context.go(RouteNames.home);
//         }
//       },
//       onSettingsChange: (_) {},
//       onPresenceSync: (_) {},
//       onPresenceJoin: (_) {},
//       onPresenceLeave: (_) {},
//       onStatusChange: (_) {},
//     );
//     if (!widget.isOwner) {
//       Future.delayed(const Duration(milliseconds: 300), _requestSync);
//     }
//     if (widget.isOwner) {
//       _provider.initAsOwner(
//         roomId: widget.roomId,
//         packId: widget.packId,
//         playerIds: widget.playerIds,
//         displayNames: widget.playerDisplayNames,
//         config: widget.config,
//       );
//     } else {
//       _provider.initAsFollower(widget.roomId);
//     }
//   }

//   void _requestSync() {
//     if (!mounted) return;
//     sl.realtimeService
//         .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
//         .ignore();
//     Future.delayed(const Duration(seconds: 1), () {
//       if (mounted && _provider.loadState == MemeLoadState.loading) {
//         sl.realtimeService
//             .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
//             .ignore();
//       }
//     });
//     Future.delayed(const Duration(seconds: 3), () {
//       if (mounted && _provider.loadState == MemeLoadState.loading) {
//         sl.realtimeService
//             .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
//             .ignore();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     ScreenSecurityService.instance.disable();
//     _provider.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvoked: (_) => memeShowLeaveDialog(
//         context,
//         roomId: widget.roomId,
//         isOwner: widget.isOwner,
//         displayName:
//             widget.playerDisplayNames[Supabase
//                     .instance
//                     .client
//                     .auth
//                     .currentUser
//                     ?.id ??
//                 ''] ??
//             'A player',
//       ),
//       child: ChangeNotifierProvider.value(
//         value: _provider,
//         child: Consumer<MemeGameProvider>(
//           builder: (ctx, game, _) {
//             if (game.loadState == MemeLoadState.loading)
//               return const Scaffold(
//                 body: Center(child: CircularProgressIndicator()),
//               );
//             if (game.loadState == MemeLoadState.error)
//               return Scaffold(
//                 body: Center(
//                   child: Padding(
//                     padding: const EdgeInsets.all(24),
//                     child: Text(
//                       'Error: \${game.error}',
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 ),
//               );
//             if (game.loadState == MemeLoadState.gameOver)
//               return _GameOverScreen(
//                 game: game,
//                 displayNames: widget.playerDisplayNames,
//               );
//             final state = game.state;
//             if (state == null)
//               return const Scaffold(
//                 body: Center(child: CircularProgressIndicator()),
//               );
//             return switch (state.phase) {
//               MemePhase.submitting => _SubmitScreen(
//                 game: game,
//                 state: state,
//                 displayNames: widget.playerDisplayNames,
//                 packId: widget.packId,
//                 packCoverUrl: widget.packCoverUrl,
//                 roomId: widget.roomId,
//                 isOwner: widget.isOwner,
//               ),
//               MemePhase.voting => _VotingScreen(
//                 game: game,
//                 state: state,
//                 displayNames: widget.playerDisplayNames,
//                 roomId: widget.roomId,
//                 isOwner: widget.isOwner,
//               ),
//               MemePhase.results => _ResultsScreen(
//                 game: game,
//                 state: state,
//                 displayNames: widget.playerDisplayNames,
//                 roomId: widget.roomId,
//                 isOwner: widget.isOwner,
//               ),
//             };
//           },
//         ),
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
//   final String targetUserId;
//   final MemeGameProvider game;
//   final List<EmojiReaction> reactions;
//   final String myId;

//   @override
//   Widget build(BuildContext context) {
//     final tally = <String, int>{};
//     for (final r in reactions.where((r) => r.targetUserId == targetUserId)) {
//       tally[r.emoji] = (tally[r.emoji] ?? 0) + 1;
//     }
//     final alreadyReacted = reactions.any(
//       (r) => r.reactorId == myId && r.targetUserId == targetUserId,
//     );
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
//     return Image.network(
//       path,
//       height: height,
//       fit: fit,
//       errorBuilder: (_, __, ___) =>
//           const Text('🎭', style: TextStyle(fontSize: 80)),
//     );
//   }
//   return Image.asset(
//     path,
//     height: height,
//     fit: fit,
//     errorBuilder: (_, __, ___) =>
//         const Text('🎭', style: TextStyle(fontSize: 80)),
//   );
// }

// // ── Hidden-until-tapped reaction reveal ───────────────────────────────────────
// // Other players' submissions stay covered ("🎭 Tap to see their reaction")
// // until tapped, then reveal full-screen as a surprise. After that first
// // reveal, the response shows normally inline (matching expand-on-tap
// // behavior from then on) — only the FIRST view is the surprise.
// class _HiddenReactionCard extends StatefulWidget {
//   const _HiddenReactionCard({
//     required this.stickerChoice,
//     required this.caption,
//     required this.isOwn,
//   });
//   final String stickerChoice;
//   final String caption;
//   final bool isOwn;

//   @override
//   State<_HiddenReactionCard> createState() => _HiddenReactionCardState();
// }

// class _HiddenReactionCardState extends State<_HiddenReactionCard> {
//   // Own submissions are never hidden from yourself.
//   late bool _revealed = widget.isOwn;

//   Future<void> _reveal() async {
//     await showDialog(
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
//                   if (widget.stickerChoice.isNotEmpty)
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(16),
//                       child: _stickerImg(
//                         widget.stickerChoice,
//                         fit: BoxFit.contain,
//                       ),
//                     ),
//                   if (widget.caption.isNotEmpty) ...[
//                     const SizedBox(height: 16),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 12,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         widget.caption,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ),
//                   ],
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Tap anywhere to close',
//                     style: TextStyle(color: Colors.white54, fontSize: 13),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//     if (mounted) setState(() => _revealed = true);
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_revealed) {
//       // Already seen once — show normally (reuses the existing
//       // tap-to-expand sticker card for subsequent views).
//       if (widget.stickerChoice.isEmpty) {
//         return widget.caption.isEmpty
//             ? const SizedBox.shrink()
//             : Text(
//                 widget.caption,
//                 style: Theme.of(
//                   context,
//                 ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
//               );
//       }
//       return _TappableStickerCard(
//         assetPath: widget.stickerChoice,
//         caption: widget.caption,
//       );
//     }

//     return GestureDetector(
//       onTap: _reveal,
//       child: Container(
//         width: double.infinity,
//         height: 140,
//         decoration: BoxDecoration(
//           color: Theme.of(context).colorScheme.surfaceContainerHighest,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: const [
//             Text('🎭', style: TextStyle(fontSize: 40)),
//             SizedBox(height: 8),
//             Text(
//               'Tap to see their reaction',
//               style: TextStyle(fontWeight: FontWeight.w600),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Tappable sticker card ─────────────────────────────────────────────────────
// // Shows sticker at medium size + optional caption. Tap to fullscreen expand.

// class _TappableStickerCard extends StatefulWidget {
//   const _TappableStickerCard({required this.assetPath, this.caption = ''});
//   final String assetPath;
//   final String caption;
//   @override
//   State<_TappableStickerCard> createState() => _TappableStickerCardState();
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
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 12,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         widget.caption,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ),
//                   ],
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Tap anywhere to close',
//                     style: TextStyle(color: Colors.white54, fontSize: 13),
//                   ),
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
//         child: Column(
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: _stickerImg(widget.assetPath, height: 140),
//             ),
//             if (widget.caption.isNotEmpty) ...[
//               const SizedBox(height: 8),
//               Text(
//                 widget.caption,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//             const SizedBox(height: 4),
//             const Text(
//               'Tap to expand',
//               style: TextStyle(fontSize: 11, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Submit screen ─────────────────────────────────────────────────────────────

// class _SubmitScreen extends StatefulWidget {
//   const _SubmitScreen({
//     required this.game,
//     required this.state,
//     required this.displayNames,
//     required this.packId,
//     this.packCoverUrl,
//     required this.roomId,
//     required this.isOwner,
//   });
//   final MemeGameProvider game;
//   final MemeState state;
//   final Map<String, String> displayNames;
//   final String packId;
//   final String? packCoverUrl;
//   final String roomId;
//   final bool isOwner;
//   @override
//   State<_SubmitScreen> createState() => _SubmitScreenState();
// }

// class _SubmitScreenState extends State<_SubmitScreen> {
//   final _captionCtrl = TextEditingController();
//   String _pickedSticker = '';
//   List<String> _packReactions = []; // custom pack reaction URLs
//   bool _loadingReactions = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadPackReactions();
//   }

//   Future<void> _loadPackReactions() async {
//     try {
//       final urls = await PackRepository.instance.getPackReactions(
//         widget.packId,
//       );
//       AppLogger.info(
//         'MemeGame: loaded ${urls.length} pack reactions for ${widget.packId}',
//       );
//       if (mounted)
//         setState(() {
//           _packReactions = urls;
//           _loadingReactions = false;
//         });
//     } catch (e) {
//       AppLogger.warning('MemeGame: failed to load pack reactions: $e');
//       if (mounted) setState(() => _loadingReactions = false);
//     }
//   }

//   @override
//   void dispose() {
//     _captionCtrl.dispose();
//     super.dispose();
//   }

//   bool get _canSubmit => _pickedSticker.isNotEmpty; // sticker required

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final hasSubmitted = widget.state.submissions.containsKey(
//       widget.game.userId,
//     );
//     final submitted = widget.state.submissions.length;
//     final total = widget.state.playerOrder.length;

//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       appBar: AppBar(
//         leading: BackButton(
//           onPressed: () => memeShowLeaveDialog(
//             context,
//             roomId: widget.roomId,
//             isOwner: widget.isOwner,
//             displayName:
//                 widget.displayNames[Supabase
//                         .instance
//                         .client
//                         .auth
//                         .currentUser
//                         ?.id ??
//                     ''] ??
//                 'A player',
//           ),
//         ),
//         title: Text(
//           'Round ${widget.state.roundNumber} / ${widget.state.maxRounds}',
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.fromLTRB(
//           20,
//           20,
//           20,
//           20 + MediaQuery.of(context).viewInsets.bottom,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Prompt card with background image
//             ClipRRect(
//               borderRadius: BorderRadius.circular(20),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 160,
//                 child: Stack(
//                   fit: StackFit.expand,
//                   children: [
//                     Positioned.fill(
//                       child:
//                           widget.packCoverUrl != null &&
//                               widget.packCoverUrl!.isNotEmpty
//                           ? Image.network(
//                               widget.packCoverUrl!,
//                               fit: BoxFit.cover,
//                               width: double.infinity,
//                               height: double.infinity,
//                               errorBuilder: (_, __, ___) => Image.asset(
//                                 'assets/images/jma3a_card_background.png',
//                                 fit: BoxFit.cover,
//                                 width: double.infinity,
//                                 height: double.infinity,
//                               ),
//                             )
//                           : Image.asset(
//                               'assets/images/jma3a_card_background.png',
//                               fit: BoxFit.cover,
//                               width: double.infinity,
//                               height: double.infinity,
//                               errorBuilder: (_, __, ___) =>
//                                   Container(color: AppColors.purple),
//                             ),
//                     ),
//                     Positioned.fill(
//                       child: Container(
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [
//                               AppColors.purple.withOpacity(0.50),
//                               const Color(0xFF0D1B2A).withOpacity(0.70),
//                             ],
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                           ),
//                         ),
//                       ),
//                     ),
//                     Center(
//                       child: Padding(
//                         padding: const EdgeInsets.all(20),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const Text('😂', style: TextStyle(fontSize: 44)),
//                             const SizedBox(height: 10),
//                             Text(
//                               widget.state.currentPrompt?.caption ?? '…',
//                               textAlign: TextAlign.center,
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w600,
//                                 height: 1.4,
//                                 shadows: [
//                                   Shadow(color: Colors.black54, blurRadius: 8),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),

//             Text(
//               '$submitted / $total submitted',
//               textAlign: TextAlign.center,
//               style: theme.textTheme.bodySmall?.copyWith(
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//             ),
//             const SizedBox(height: 12),

//             if (!hasSubmitted) ...[
//               // Sticker picker — required
//               Text(
//                 'Pick your sticker:',
//                 style: theme.textTheme.labelMedium?.copyWith(
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               // Expanded preview when a sticker is selected
//               if (_pickedSticker.isNotEmpty)
//                 GestureDetector(
//                   onTap: () => setState(() => _pickedSticker = ''),
//                   child: Container(
//                     width: double.infinity,
//                     height: 200,
//                     margin: const EdgeInsets.only(bottom: 8),
//                     decoration: BoxDecoration(
//                       color: Theme.of(
//                         context,
//                       ).colorScheme.surfaceContainerHighest,
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(
//                         color: Theme.of(context).colorScheme.primary,
//                         width: 2,
//                       ),
//                     ),
//                     child: Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(14),
//                           child: _stickerImg(_pickedSticker, height: 180),
//                         ),
//                         Positioned(
//                           top: 8,
//                           right: 8,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: Colors.black54,
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             padding: const EdgeInsets.all(4),
//                             child: const Icon(
//                               Icons.close,
//                               color: Colors.white,
//                               size: 18,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               _loadingReactions
//                   ? const Center(child: CircularProgressIndicator())
//                   : StickerPicker(
//                       selected: _pickedSticker.isEmpty ? null : _pickedSticker,
//                       onSelect: (path) => setState(() => _pickedSticker = path),
//                       customUrls: _packReactions.isNotEmpty
//                           ? _packReactions
//                           : null,
//                       stickerSize: 64,
//                     ),
//               const SizedBox(height: 12),

//               // Caption (optional)
//               TextField(
//                 controller: _captionCtrl,
//                 maxLines: 2,
//                 maxLength: 200,
//                 textCapitalization: TextCapitalization.sentences,
//                 decoration: const InputDecoration(
//                   hintText: 'Add a caption (optional)…',
//                   border: OutlineInputBorder(),
//                   counterText: '',
//                 ),
//                 onChanged: (_) => setState(() {}),
//               ),
//               const SizedBox(height: 16),

//               SizedBox(
//                 height: 52,
//                 child: FilledButton(
//                   onPressed: _canSubmit
//                       ? () => widget.game.submit(
//                           caption: _captionCtrl.text.trim(),
//                           stickerChoice: _pickedSticker,
//                         )
//                       : null,
//                   child: Text(
//                     _pickedSticker.isEmpty
//                         ? 'Pick a sticker first'
//                         : 'Submit Response',
//                   ),
//                 ),
//               ),
//             ] else ...[
//               const SizedBox(height: 20),
//               Container(
//                 padding: const EdgeInsets.symmetric(vertical: 24),
//                 decoration: BoxDecoration(
//                   color: theme.colorScheme.surfaceContainerHighest,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   children: [
//                     const SizedBox(
//                       width: 24,
//                       height: 24,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       'Response submitted! Waiting for others…',
//                       textAlign: TextAlign.center,
//                       style: theme.textTheme.bodyMedium,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Voting screen ─────────────────────────────────────────────────────────────

// class _VotingScreen extends StatelessWidget {
//   const _VotingScreen({
//     required this.game,
//     required this.state,
//     required this.displayNames,
//     required this.roomId,
//     required this.isOwner,
//   });
//   final MemeGameProvider game;
//   final MemeState state;
//   final Map<String, String> displayNames;
//   final String roomId;
//   final bool isOwner;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final hasVoted = state.votes.containsKey(game.userId);
//     final entries = state.submissions.entries.toList();

//     return Scaffold(
//       appBar: AppBar(
//         leading: BackButton(
//           onPressed: () =>
//               memeShowLeaveDialog(context, roomId: roomId, isOwner: isOwner),
//         ),
//         title: const Text('Vote for the best! 😂'),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(24),
//           child: Text(
//             '${state.votes.length} / ${state.playerOrder.length} voted',
//             style: theme.textTheme.bodySmall?.copyWith(
//               color: theme.colorScheme.onSurfaceVariant,
//             ),
//           ),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             if (hasVoted)
//               Container(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: theme.colorScheme.surfaceContainerHighest,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                     const SizedBox(width: 12),
//                     Text(
//                       'Voted! Waiting for others…',
//                       style: theme.textTheme.bodyMedium,
//                     ),
//                   ],
//                 ),
//               ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: entries.length,
//                 itemBuilder: (_, i) {
//                   final e = entries[i];
//                   final sub = e.value;
//                   final isOwn = e.key == game.userId;
//                   final isVoted = state.votes[game.userId] == e.key;

//                   return Card(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Response #${i + 1}',
//                             style: theme.textTheme.labelMedium?.copyWith(
//                               color: theme.colorScheme.onSurfaceVariant,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           // Sticker/caption — hidden until tapped for
//                           // everyone else's submissions (surprise reveal),
//                           // shown immediately for your own.
//                           _HiddenReactionCard(
//                             stickerChoice: sub.stickerChoice,
//                             caption: sub.caption,
//                             isOwn: isOwn,
//                           ),
//                           const SizedBox(height: 12),
//                           // Reaction bar
//                           _ReactionBar(
//                             targetUserId: e.key,
//                             game: game,
//                             reactions: state.reactions,
//                             myId: game.userId,
//                           ),
//                           const SizedBox(height: 10),
//                           // Vote button
//                           if (!hasVoted && !isOwn)
//                             SizedBox(
//                               width: double.infinity,
//                               height: 42,
//                               child: FilledButton(
//                                 onPressed: () => game.voteFor(e.key),
//                                 child: const Text('Vote for this 👍'),
//                               ),
//                             ),
//                           if (!hasVoted && isOwn)
//                             Text(
//                               'Your response',
//                               style: theme.textTheme.bodySmall?.copyWith(
//                                 color: theme.colorScheme.onSurfaceVariant,
//                               ),
//                             ),
//                           if (hasVoted && isVoted)
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 10,
//                                 vertical: 4,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: AppColors.successGreen.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: const Text(
//                                 '✓ Your vote',
//                                 style: TextStyle(
//                                   color: AppColors.successGreen,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Results screen ────────────────────────────────────────────────────────────

// class _ResultsScreen extends StatefulWidget {
//   const _ResultsScreen({
//     required this.game,
//     required this.state,
//     required this.displayNames,
//     required this.roomId,
//     required this.isOwner,
//   });
//   final MemeGameProvider game;
//   final MemeState state;
//   final Map<String, String> displayNames;
//   final String roomId;
//   final bool isOwner;
//   @override
//   State<_ResultsScreen> createState() => _ResultsScreenState();
// }

// class _ResultsScreenState extends State<_ResultsScreen> {
//   bool _showHistory = false;

//   @override
//   Widget build(BuildContext context) {
//     if (_showHistory) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('Game History'),
//           leading: BackButton(
//             onPressed: () => setState(() => _showHistory = false),
//           ),
//         ),
//         body: _HistoryPanel(
//           history: widget.state.history,
//           displayNames: widget.displayNames,
//           onClose: () => setState(() => _showHistory = false),
//         ),
//       );
//     }

//     final theme = context.theme;
//     final state = widget.state;
//     final game = widget.game;
//     final winnerId = state.roundWinnerId;
//     final tally = <String, int>{};
//     for (final t in state.votes.values) tally[t] = (tally[t] ?? 0) + 1;

//     return Scaffold(
//       appBar: AppBar(
//         leading: BackButton(
//           onPressed: () => memeShowLeaveDialog(
//             context,
//             roomId: widget.roomId,
//             isOwner: widget.isOwner,
//             displayName:
//                 widget.displayNames[Supabase
//                         .instance
//                         .client
//                         .auth
//                         .currentUser
//                         ?.id ??
//                     ''] ??
//                 'A player',
//           ),
//         ),
//         title: Text('Round ${state.roundNumber} Results 🏆'),
//         actions: [
//           if (state.history.isNotEmpty)
//             IconButton(
//               icon: const Icon(Icons.history_rounded),
//               onPressed: () => setState(() => _showHistory = true),
//             ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Winner banner
//             if (winnerId != null)
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 margin: const EdgeInsets.only(bottom: 16),
//                 decoration: BoxDecoration(
//                   color: AppColors.amberOrangeLight.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(14),
//                   border: Border.all(
//                     color: AppColors.amberOrangeLight,
//                     width: 1.5,
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     const Text('🏆', style: TextStyle(fontSize: 40)),
//                     Text(
//                       _nameOf(widget.displayNames, winnerId),
//                       style: theme.textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                     Text(
//                       'wins this round!',
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         color: theme.colorScheme.onSurfaceVariant,
//                       ),
//                     ),
//                     if (state.submissions[winnerId]?.stickerChoice.isNotEmpty ==
//                         true)
//                       StickerDisplay(
//                         assetPath: state.submissions[winnerId]!.stickerChoice,
//                         size: 72,
//                       ),
//                     if (state.submissions[winnerId]?.caption.isNotEmpty ==
//                         true) ...[
//                       const SizedBox(height: 4),
//                       Text(
//                         '"${state.submissions[winnerId]!.caption}"',
//                         textAlign: TextAlign.center,
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           fontStyle: FontStyle.italic,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),

//             Expanded(
//               child: ListView(
//                 children: state.submissions.entries.map((e) {
//                   final sub = e.value;
//                   final votes = tally[e.key] ?? 0;
//                   final isWinner = e.key == winnerId;
//                   return Card(
//                     margin: const EdgeInsets.only(bottom: 10),
//                     color: isWinner
//                         ? AppColors.amberOrangeLight.withOpacity(0.06)
//                         : null,
//                     child: Padding(
//                       padding: const EdgeInsets.all(14),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Text(
//                                 _nameOf(widget.displayNames, e.key),
//                                 style: theme.textTheme.labelLarge?.copyWith(
//                                   fontWeight: FontWeight.w600,
//                                   color: isWinner
//                                       ? AppColors.amberOrangeLight
//                                       : null,
//                                 ),
//                               ),
//                               if (isWinner) ...[
//                                 const SizedBox(width: 4),
//                                 const Text('🏆'),
//                               ],
//                               const Spacer(),
//                               Text(
//                                 '$votes 👍',
//                                 style: theme.textTheme.labelLarge?.copyWith(
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 8),
//                           if (sub.stickerChoice.isNotEmpty)
//                             _TappableStickerCard(
//                               assetPath: sub.stickerChoice,
//                               caption: sub.caption,
//                             ),
//                           const SizedBox(height: 8),
//                           // Reactions
//                           _ReactionBar(
//                             targetUserId: e.key,
//                             game: game,
//                             reactions: state.reactions,
//                             myId: game.userId,
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),

//             const Divider(),
//             Text(
//               'Scores',
//               style: theme.textTheme.labelLarge?.copyWith(
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const SizedBox(height: 4),
//             ...(state.scores.entries.toList()
//                   ..sort((a, b) => b.value.compareTo(a.value)))
//                 .map(
//                   (e) => Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 2),
//                     child: Row(
//                       children: [
//                         Text(
//                           _nameOf(widget.displayNames, e.key),
//                           style: theme.textTheme.bodyMedium,
//                         ),
//                         const Spacer(),
//                         Text(
//                           '${e.value} 🏆',
//                           style: theme.textTheme.bodyMedium?.copyWith(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//             const SizedBox(height: 12),

//             if (game.isOwner) ...[
//               if (!game.allPlayersVoted)
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 6),
//                   child: Text(
//                     '${game.votedCount}/${game.activePlayerCount} players voted',
//                     style: theme.textTheme.bodySmall?.copyWith(
//                       color: theme.colorScheme.onSurfaceVariant,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               SizedBox(
//                 height: 52,
//                 child: FilledButton(
//                   onPressed: game.allPlayersVoted
//                       ? game.ownerAdvanceTurn
//                       : null,
//                   child: const Text('Next Round →'),
//                 ),
//               ),
//             ] else
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: theme.colorScheme.surfaceContainerHighest,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                     const SizedBox(width: 10),
//                     Text(
//                       'Waiting for host…',
//                       style: theme.textTheme.bodyMedium,
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── History panel ─────────────────────────────────────────────────────────────

// class _HistoryPanel extends StatelessWidget {
//   const _HistoryPanel({
//     required this.history,
//     required this.displayNames,
//     required this.onClose,
//   });
//   final List<MemeRoundRecord> history;
//   final Map<String, String> displayNames;
//   final VoidCallback onClose;

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     return Column(
//       children: [
//         ListTile(
//           leading: const Icon(Icons.history_rounded),
//           title: Text(
//             'History (${history.length} rounds)',
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           trailing: IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: onClose,
//           ),
//         ),
//         const Divider(height: 0),
//         Expanded(
//           child: ListView.builder(
//             padding: const EdgeInsets.all(12),
//             itemCount: history.length,
//             itemBuilder: (_, i) {
//               final round = history[history.length - 1 - i];
//               return Card(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 child: ExpansionTile(
//                   leading: CircleAvatar(
//                     backgroundColor: theme.colorScheme.primaryContainer,
//                     child: Text(
//                       '${round.roundNumber}',
//                       style: theme.textTheme.labelLarge,
//                     ),
//                   ),
//                   title: Text(
//                     round.prompt.caption,
//                     style: theme.textTheme.bodyMedium?.copyWith(
//                       fontWeight: FontWeight.w600,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   subtitle: Text(
//                     'Winner: ${round.winnerId != null ? _nameOf(displayNames, round.winnerId!) : 'Tie'}',
//                     style: theme.textTheme.bodySmall,
//                   ),
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: round.submissions.entries.map((e) {
//                           final sub = e.value;
//                           final reacts = round.reactions
//                               .where((r) => r.targetUserId == e.key)
//                               .toList();
//                           final reactTally = <String, int>{};
//                           for (final r in reacts)
//                             reactTally[r.emoji] =
//                                 (reactTally[r.emoji] ?? 0) + 1;
//                           final isWinner = e.key == round.winnerId;
//                           return Padding(
//                             padding: const EdgeInsets.only(bottom: 10),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Text(
//                                       _nameOf(displayNames, e.key),
//                                       style: theme.textTheme.bodySmall
//                                           ?.copyWith(
//                                             fontWeight: FontWeight.w700,
//                                             color: isWinner
//                                                 ? AppColors.amberOrangeLight
//                                                 : null,
//                                           ),
//                                     ),
//                                     if (isWinner) const Text(' 🏆'),
//                                   ],
//                                 ),
//                                 if (sub.stickerChoice.isNotEmpty)
//                                   StickerDisplay(
//                                     assetPath: sub.stickerChoice,
//                                     size: 48,
//                                   ),
//                                 if (sub.caption.isNotEmpty)
//                                   Text(
//                                     '"${sub.caption}"',
//                                     style: theme.textTheme.bodySmall?.copyWith(
//                                       fontStyle: FontStyle.italic,
//                                     ),
//                                   ),
//                                 if (reactTally.isNotEmpty)
//                                   Padding(
//                                     padding: const EdgeInsets.only(top: 4),
//                                     child: Wrap(
//                                       spacing: 4,
//                                       children: reactTally.entries
//                                           .map(
//                                             (r) => Text(
//                                               '${r.key}${r.value}',
//                                               style: const TextStyle(
//                                                 fontSize: 14,
//                                               ),
//                                             ),
//                                           )
//                                           .toList(),
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ── Game over ─────────────────────────────────────────────────────────────────

// class _GameOverScreen extends StatefulWidget {
//   const _GameOverScreen({required this.game, required this.displayNames});
//   final MemeGameProvider game;
//   final Map<String, String> displayNames;
//   @override
//   State<_GameOverScreen> createState() => _GameOverScreenState();
// }

// class _GameOverScreenState extends State<_GameOverScreen> {
//   bool _showHistory = false;

//   @override
//   Widget build(BuildContext context) {
//     final scores = widget.game.state?.scores ?? {};
//     final history = widget.game.state?.history ?? [];
//     final sorted = scores.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));
//     const medals = ['🥇', '🥈', '🥉'];

//     if (_showHistory) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('Game History'),
//           leading: BackButton(
//             onPressed: () => setState(() => _showHistory = false),
//           ),
//         ),
//         body: _HistoryPanel(
//           history: history,
//           displayNames: widget.displayNames,
//           onClose: () => setState(() => _showHistory = false),
//         ),
//       );
//     }

//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const Text(
//                 '😂🏆',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 64),
//               ),
//               Text(
//                 'Game Over!',
//                 textAlign: TextAlign.center,
//                 style: context.textTheme.headlineMedium?.copyWith(
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//               Text(
//                 'Funniest player wins!',
//                 textAlign: TextAlign.center,
//                 style: context.textTheme.bodyLarge?.copyWith(
//                   color: context.colorScheme.onSurfaceVariant,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: sorted.length,
//                   itemBuilder: (_, i) {
//                     final e = sorted[i];
//                     return ListTile(
//                       leading: Text(
//                         i < medals.length ? medals[i] : '${i + 1}.',
//                         style: const TextStyle(fontSize: 24),
//                       ),
//                       title: Text(
//                         _nameOf(widget.displayNames, e.key),
//                         style: context.textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       trailing: Text(
//                         '${e.value} 🏆',
//                         style: context.textTheme.titleMedium?.copyWith(
//                           color: AppColors.amberOrangeLight,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               if (history.isNotEmpty) ...[
//                 OutlinedButton.icon(
//                   onPressed: () => setState(() => _showHistory = true),
//                   icon: const Icon(Icons.history_rounded),
//                   label: Text('View History (${history.length} rounds)'),
//                 ),
//                 const SizedBox(height: 10),
//               ],
//               SizedBox(
//                 height: 52,
//                 child: FilledButton(
//                   onPressed: () => context.go(RouteNames.home),
//                   child: const Text('Back to Home'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ── Shared paused overlay for meme/nhie ──────────────────────────────────────
// class _MemeNhiePausedOverlay extends StatefulWidget {
//   const _MemeNhiePausedOverlay({required this.onLeave});
//   final VoidCallback onLeave;
//   @override
//   State<_MemeNhiePausedOverlay> createState() => _MemeNhiePausedOverlayState();
// }

// class _MemeNhiePausedOverlayState extends State<_MemeNhiePausedOverlay>
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
//   Widget build(BuildContext context) => Dialog.fullscreen(
//     backgroundColor: Colors.transparent,
//     child: Scaffold(
//       backgroundColor: Colors.transparent,
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               AnimatedBuilder(
//                 animation: _pulse,
//                 builder: (_, child) =>
//                     Opacity(opacity: 0.6 + _pulse.value * 0.4, child: child),
//                 child: const Text('⏸', style: TextStyle(fontSize: 72)),
//               ),
//               const SizedBox(height: 24),
//               const Text(
//                 'Game Paused',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 28,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               const Text(
//                 'The host stepped away and will\nreturn shortly.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: Colors.white70,
//                   fontSize: 16,
//                   height: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 40),
//               OutlinedButton(
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: Colors.white,
//                   side: const BorderSide(color: Colors.white38),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 32,
//                     vertical: 14,
//                   ),
//                 ),
//                 onPressed: widget.onLeave,
//                 child: const Text('Leave for Now'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
// }

import 'dart:async';
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
import 'package:jma3a/features/rooms/presentation/room_provider.dart';
import 'package:jma3a/features/settings/presentation/screen_security_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jma3a/core/services/image_cache_service.dart';
import 'package:jma3a/shared/widgets/animated_reaction_overlay.dart';
import 'package:jma3a/shared/widgets/game_rules_sheet.dart';
import 'package:jma3a/shared/widgets/no_active_players_banner.dart';
import 'package:jma3a/shared/widgets/join_requests_panel.dart';
import 'package:jma3a/shared/widgets/room_members_management_sheet.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/realtime_service.dart';
// import '../../../../core/services/screen_security_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/game_end_navigation.dart';

enum MemeLoadState { idle, loading, ready, error, gameOver }

class MemeGameProvider extends ChangeNotifier {
  MemeGameProvider({
    required RealtimeService realtimeService,
    required String userId,
    required String displayName,
    this.isModerator = false,
  }) : _realtime = realtimeService,
       _userId = userId,
       _displayName = displayName;

  final RealtimeService _realtime;
  final String _userId, _displayName;
  final bool isModerator;

  /// Set by the screen (which owns the RoomProvider reference) — lets the
  /// owner's client validate a moderator-delegated advance-turn action
  /// sent by someone else's client before executing it.
  bool Function(String userId, String permissionKey)? permissionChecker;

  bool _isAllowed(String? uid, String permissionKey) =>
      permissionChecker == null ||
      (uid != null && permissionChecker!(uid, permissionKey));

  /// Set by the screen right after construction, same as [permissionChecker]
  /// — gives this provider read access to the room's durable, backend-synced
  /// member list so ready/vote logic never has to trust its own ephemeral,
  /// broadcast-only away-tracking alone (see [_effectiveAwayIds]).
  RoomProvider? roomProvider;

  bool get canAdvanceTurnHere =>
      _isOwner ||
      (permissionChecker?.call(_userId, 'advance_turn') ?? false) ||
      (permissionChecker?.call(_userId, 'skip_turn') ?? false);

  MemeGameEngine? _engine;
  MemeLoadState _loadState = MemeLoadState.idle;
  String? _roomId;
  String? _sessionId;
  bool _isOwner = false;
  String _error = '';
  final Set<String> _awayPlayerIds = {};
  final Set<String> _readyForNext = {};

  // Shared between _MemeGameScreenState (owns the realtime listeners) and
  // memeShowLeaveDialog (called from PopScope and various back buttons) via
  // this single provider instance, so a programmatic pop triggered by a
  // realtime event (e.g. onGameEnded) doesn't get misread by PopScope as
  // the user backing out, which would incorrectly open the Quit Game
  // confirmation dialog.
  bool isNavigatingAway = false;

  MemeLoadState get loadState => _loadState;
  MemeState? get state => _engine?.currentState as MemeState?;
  String get userId => _userId;
  bool get isOwner => _isOwner;
  bool get canModerate => _isOwner || isModerator;

  bool get allPlayersVoted {
    final s = state;
    if (s == null) return true;
    return s.votes.length >= s.playerOrder.length;
  }

  int get votedCount => state?.votes.length ?? 0;
  int get playerCount => state?.playerOrder.length ?? 1;

  /// Live count of players still actually in the game (excludes
  /// kicked/banned/left players) — unlike [playerCount], which is frozen at
  /// game start since `playerOrder` never shrinks for the life of a session.
  int get activePlayerCount => (state?.playerOrder ?? const <String>[])
      .where((id) => !_effectiveAwayIds.contains(id))
      .length;
  String get error => _error;
  Set<String> get awayPlayerIds => _effectiveAwayIds;

  /// Away/gone ids derived from the room's durable, backend-synced member
  /// list — see the identical getter in TodGameProvider for the full
  /// rationale. Unlike [_awayPlayerIds] (fed only by a one-shot moderation
  /// broadcast this specific client happened to be connected for), this
  /// reflects a fresh fetch + realtime `room_members` subscription.
  Set<String> get _durableAwayIds {
    final rp = roomProvider;
    final order = state?.playerOrder;
    if (rp == null || order == null) return const {};
    final members = {for (final m in rp.members) m.userId: m};
    return order.where((id) {
      final m = members[id];
      return m == null || m.isAway || m.isDisconnected;
    }).toSet();
  }

  Set<String> get _effectiveAwayIds => _awayPlayerIds.union(_durableAwayIds);

  Set<String> get readyForNext => Set.unmodifiable(_readyForNext);
  bool get hasMarkedReady => _readyForNext.contains(_userId);

  // See the identical getter in TodGameProvider for the full rationale —
  // exempts a permissioned moderator from being counted among "others who
  // must ready up", symmetric with the owner's own existing exemption.
  // Must explicitly exclude the owner since memberHasPermission already
  // ORs in isOwner.
  bool _isExemptModerator(String id) {
    final rp = roomProvider;
    if (rp == null || id == rp.room?.ownerId) return false;
    return rp.memberHasPermission(id, 'advance_turn') ||
        rp.memberHasPermission(id, 'skip_turn');
  }

  bool get allOthersReady {
    final others = (state?.playerOrder ?? const <String>[])
        .where(
          (id) =>
              id != _userId &&
              !_effectiveAwayIds.contains(id) &&
              !_isExemptModerator(id),
        )
        .toSet();
    final result = others.isEmpty || _readyForNext.containsAll(others);
    AppLogger.debug(
      '[READY-DEBUG][meme] allOthersReady: others=$others '
      'readyForNext=$_readyForNext away=$_effectiveAwayIds -> $result',
    );
    return result;
  }

  void markPlayerAway(String userId, {bool forGood = false}) {
    _awayPlayerIds.add(userId);
    if (_isOwner && _engine != null) {
      Future.microtask(_autoFillAwayPlayers);
    }
    notifyListeners();
  }

  /// playerOrder is fixed for the life of the session — a kicked/left
  /// player is never removed from it, only added to _awayPlayerIds.
  /// Submission/vote completion is a simple count against
  /// playerOrder.length, so an away player who never acts would otherwise
  /// block every round from here on (not just the one they left during).
  /// Auto-fills on their behalf, bounded so it can't loop forever, and
  /// re-reads state each step since one fill can cascade into the next
  /// phase needing a fill too (e.g. the away player's auto-submission is
  /// the last one needed, flipping the round straight to voting).
  bool _autoFilling = false;
  void _autoFillAwayPlayers() {
    if (_autoFilling ||
        !_isOwner ||
        _engine == null ||
        _effectiveAwayIds.isEmpty) {
      return;
    }
    _autoFilling = true;
    final away = _effectiveAwayIds;
    final maxSteps = away.length * 2 + 1;
    for (var i = 0; i < maxSteps; i++) {
      final s = _engine!.currentState as MemeState;
      if (s.phase == MemePhase.submitting) {
        final uid = away.firstWhere(
          (id) => !s.submissions.containsKey(id),
          orElse: () => '',
        );
        if (uid.isNotEmpty) {
          onPlayerAction({
            'action': 'meme_submit',
            'user_id': uid,
            'caption': '',
            'sticker_choice': '',
            'ts': DateTime.now().millisecondsSinceEpoch,
          });
          continue;
        }
      } else if (s.phase == MemePhase.voting) {
        final uid = away.firstWhere(
          (id) => !s.votes.containsKey(id),
          orElse: () => '',
        );
        if (uid.isNotEmpty) {
          final target = s.playerOrder.firstWhere(
            (id) => id != uid,
            orElse: () => uid,
          );
          onPlayerAction({
            'action': 'meme_vote',
            'user_id': uid,
            'target_user_id': target,
            'ts': DateTime.now().millisecondsSinceEpoch,
          });
          continue;
        }
      }
      break;
    }
    _autoFilling = false;
  }

  void markPlayerReturned(String userId) {
    _awayPlayerIds.remove(userId);
    notifyListeners();
  }

  /// Owner-only early termination (e.g. every other player has left the
  /// game) — forces the engine to game-over and lets the existing
  /// `_broadcastState` isGameOver branch persist/notify as usual.
  Future<void> endGame() async {
    if (!_isOwner || _engine == null) return;
    _engine!.forceEnd();
    _broadcastState();
    notifyListeners();
  }

  Future<void> kickPlayerFromGame(String targetUserId) async {
    if (!canModerate || _roomId == null) return;
    markPlayerAway(targetUserId, forGood: true);
    // Persist durably so every client (including one that reconnects,
    // briefly drops, or joins after this specific broadcast) derives the
    // correct active-player set via roomProvider.members — see
    // _durableAwayIds.
    await sl.roomRepository
        .markMemberAwayInGame(_roomId!, targetUserId, away: true)
        .catchError((_) {});
    await _realtime.broadcastModeration(_roomId!, {
      'type': 'game_kick',
      'target_user_id': targetUserId,
      'by': _userId,
    });
  }

  Future<void> banPlayerFromGame(String targetUserId, {String? reason}) async {
    if (!canModerate || _roomId == null) return;
    markPlayerAway(targetUserId, forGood: true);
    await sl.roomRepository.banMember(
      roomId: _roomId!,
      targetUserId: targetUserId,
      bannedBy: _userId,
      reason: reason,
    );
    await _realtime.broadcastModeration(_roomId!, {
      'type': 'ban',
      'target_user_id': targetUserId,
      'reason': reason,
    });
  }

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
          final rawDiff = r['difficulty'];
          final diffStr = rawDiff is Map
              ? (rawDiff['en'] ?? rawDiff.values.first ?? 'mild').toString()
              : rawDiff?.toString() ?? 'mild';
          return TodCard(
            id: r['id'] as String,
            content: text,
            type: TodCardType.truth,
            difficulty: TodDifficulty.values.firstWhere(
              (d) => d.name == diffStr,
              orElse: () => TodDifficulty.mild,
            ),
          );
        }).toList();
      }
      final prompts = todCards
          .map((c) => MemePrompt(id: c.id, caption: c.content))
          .toList();

      _engine = MemeGameEngine(config, prompts: prompts);

      var existing = await Supabase.instance.client
          .from('game_sessions')
          .select('id, state_snapshot, game_type')
          .eq('room_id', roomId)
          .eq('status', 'active')
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
      // Nothing active — a reconnecting owner whose game already ended
      // should still land on the results screen for that session, not
      // silently start a brand-new game.
      existing ??= await Supabase.instance.client
          .from('game_sessions')
          .select('id, state_snapshot, game_type')
          .eq('room_id', roomId)
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final snapshotGameType = existing?['game_type'] as String?;
      Map<String, dynamic>? existingSnapshot;
      if (snapshotGameType == 'meme_game') {
        existingSnapshot = existing?['state_snapshot'] as Map<String, dynamic>?;
      }

      if (existing != null &&
          existingSnapshot != null &&
          existingSnapshot.isNotEmpty) {
        _sessionId = existing['id'] as String;
        _engine!.restoreFromSnapshot(existingSnapshot);
        AppLogger.info('MemeProvider: resumed existing session $_sessionId');
      } else {
        _engine!.init(playerIds);
        try {
          // game_sessions has no permissive INSERT policy — creation only
          // ever happens through this SECURITY DEFINER RPC, which also
          // enforces that the caller is the room owner or an
          // explicitly-permitted moderator.
          final id = await Supabase.instance.client.rpc(
            'create_game_session',
            params: {
              'p_room_id': roomId,
              'p_pack_id': packId,
              'p_game_type': 'meme_game',
              'p_player_ids': playerIds,
              'p_max_rounds': config.maxRounds,
              'p_turn_timer_secs': config.turnTimerSeconds,
              'p_allow_skip': config.allowSkip,
              'p_allow_spicy': config.allowSpicy,
              'p_state_snapshot': _engine!.serializeState(),
            },
          );
          _sessionId = id as String;
        } catch (e) {
          AppLogger.warning('MemeProvider: failed to create session: $e');
        }
      }

      if (_sessionId != null) {
        try {
          final customCards = await TodRepository.instance.loadCustomCards(
            _sessionId!,
          );
          for (final c in customCards) {
            _engine!.injectCard(MemePrompt(id: c.id, caption: c.content));
          }
          if (customCards.isNotEmpty) {
            AppLogger.info(
              'MemeProvider: merged ${customCards.length} custom cards into deck',
            );
          }
        } catch (e) {
          AppLogger.warning('MemeProvider: custom card load failed: $e');
        }
      }

      _loadState = _engine!.isGameOver
          ? MemeLoadState.gameOver
          : MemeLoadState.ready;
      notifyListeners();
      _broadcastState();
    } catch (e) {
      _error = e.toString();
      _loadState = MemeLoadState.error;
      AppLogger.error('MemeProvider: init failed', error: e);
      notifyListeners();
    }
  }

  Timer? _syncTimeoutTimer;
  String? _packId;
  GameConfig? _config;
  GameConfig? get config => _config;

  // See the identical watchdog in TodGameProvider for the full rationale:
  // realtime broadcast has no delivery guarantee, and nothing previously
  // detected a *missing* update on an otherwise-healthy socket — a
  // follower just stayed stuck. This self-heals via resync request, then a
  // direct DB read if that doesn't land either.
  DateTime _lastStateReceivedAt = DateTime.now();
  Timer? _staleWatchdog;
  DateTime? _lastStaleRecoveryAttempt;
  static const _staleThreshold = Duration(seconds: 15);
  static const _staleRecoveryCooldown = Duration(seconds: 10);

  void _startStaleWatchdog() {
    _staleWatchdog?.cancel();
    _staleWatchdog = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_isOwner || state == null || _roomId == null) return;
      if (_engine != null && _engine!.isGameOver) return;
      final sinceLastState = DateTime.now().difference(_lastStateReceivedAt);
      if (sinceLastState <= _staleThreshold) return;

      final lastAttempt = _lastStaleRecoveryAttempt;
      if (lastAttempt != null &&
          DateTime.now().difference(lastAttempt) < _staleRecoveryCooldown) {
        return;
      }
      _lastStaleRecoveryAttempt = DateTime.now();
      AppLogger.warning(
        'MemeProvider: no state broadcast for ${sinceLastState.inSeconds}s — requesting resync',
      );
      _realtime.broadcastSyncRequest(_roomId!, _userId, 0).ignore();

      Timer(const Duration(seconds: 4), () {
        if (DateTime.now().difference(_lastStateReceivedAt) > _staleThreshold) {
          AppLogger.warning(
            'MemeProvider: resync request unanswered — reading state from DB',
          );
          _tryLoadSnapshotFromDb(_roomId!);
        }
      });
    });
  }

  void initAsFollower(String roomId, {String? packId, GameConfig? config}) {
    _roomId = roomId;
    _packId = packId;
    _config = config;
    _isOwner = false;
    _loadState = MemeLoadState.loading;
    _syncTimeoutTimer?.cancel();
    _syncTimeoutTimer = Timer(const Duration(seconds: 8), () async {
      if (state == null) await _tryLoadSnapshotFromDb(roomId);
    });
    _lastStateReceivedAt = DateTime.now();
    _startStaleWatchdog();
    notifyListeners();
  }

  /// Called when [RoomProvider.isOwner] changes mid-game (room ownership
  /// transferred). A follower never runs a local [_engine] — it only tracks
  /// [state] from broadcasts — so becoming the new authoritative owner
  /// means constructing one from the last-synced state before this provider
  /// can start applying/broadcasting actions.
  Future<void> applyOwnershipChange(bool amOwner) async {
    if (amOwner == _isOwner) return;
    if (!amOwner) {
      _isOwner = false;
      _lastStateReceivedAt = DateTime.now();
      _startStaleWatchdog();
      notifyListeners();
      return;
    }
    if (_engine == null ||
        state == null ||
        _packId == null ||
        _config == null) {
      return;
    }
    try {
      final prompts = await _loadPrompts(_packId!, _config!);
      _engine = MemeGameEngine(_config!, prompts: prompts);
      _engine!.restoreFromSnapshot(state!.toMap());
    } catch (e) {
      AppLogger.error(
        'MemeProvider: ownership handoff engine build failed: $e',
      );
      return;
    }
    _isOwner = true;
    notifyListeners();
  }

  /// Loads this pack's deck as [MemePrompt]s — the same conversion
  /// [initAsOwner] performs, reused here for the ownership mid-game handoff.
  Future<List<MemePrompt>> _loadPrompts(
    String packId,
    GameConfig config,
  ) async {
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
        final rawDiff = r['difficulty'];
        final diffStr = rawDiff is Map
            ? (rawDiff['en'] ?? rawDiff.values.first ?? 'mild').toString()
            : rawDiff?.toString() ?? 'mild';
        return TodCard(
          id: r['id'] as String,
          content: text,
          type: TodCardType.truth,
          difficulty: TodDifficulty.values.firstWhere(
            (d) => d.name == diffStr,
            orElse: () => TodDifficulty.mild,
          ),
        );
      }).toList();
    }
    return todCards
        .map((c) => MemePrompt(id: c.id, caption: c.content))
        .toList();
  }

  /// DB-fallback for a follower that never received a state broadcast
  /// (e.g. the owner was also offline) — without this, a reconnecting
  /// follower could be stuck on the loading screen indefinitely.
  Future<void> _tryLoadSnapshotFromDb(String roomId) async {
    try {
      final row = await Supabase.instance.client
          .from('game_sessions')
          .select('id, state_snapshot, game_type')
          .eq('room_id', roomId)
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final snapshotGameType = row?['game_type'] as String?;
      final Map<String, dynamic>? snapshot = snapshotGameType == 'meme_game'
          ? (row?['state_snapshot'] as Map<String, dynamic>?)
          : null;
      if (snapshot == null || snapshot.isEmpty) {
        _error = 'Could not recover session state. Please rejoin the room.';
        _loadState = MemeLoadState.error;
        notifyListeners();
        return;
      }
      // Only apply if actually newer — this is also called by the
      // staleness watchdog, where a race against a broadcast landing at
      // the same moment shouldn't regress state.
      final incomingTs = snapshot['snapshot_at'] as int? ?? 0;
      if (state != null && incomingTs <= (state!.snapshotAt)) {
        _lastStateReceivedAt = DateTime.now();
        return;
      }
      _sessionId = row!['id'] as String;
      _engine ??= MemeGameEngine(
        const GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 60,
          allowSkip: false,
          allowSpicy: false,
        ),
        prompts: [],
      );
      _engine!.restoreFromSnapshot(snapshot);
      _loadState = _engine!.isGameOver
          ? MemeLoadState.gameOver
          : MemeLoadState.ready;
      _lastStateReceivedAt = DateTime.now();
      notifyListeners();
    } catch (e) {
      _error = 'Reconnection failed: ${e.toString()}';
      _loadState = MemeLoadState.error;
      AppLogger.warning('MemeProvider: DB fallback load failed: $e');
      notifyListeners();
    }
  }

  Future<({bool success, String? error})> addCustomCard({
    required String content,
  }) async {
    if (_sessionId == null || _roomId == null) {
      return (success: false, error: 'Game not started yet');
    }
    if (_engine == null) {
      return (success: false, error: 'Game not ready');
    }
    try {
      final card = await TodRepository.instance.addCustomCard(
        sessionId: _sessionId!,
        roomId: _roomId!,
        addedBy: _userId,
        type: TodCardType.truth,
        content: content.trim(),
        difficulty: TodDifficulty.mild,
      );
      _engine?.injectCard(MemePrompt(id: card.id, caption: card.content));
      notifyListeners();
      _broadcastState();
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

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

  bool _advancing = false;

  Future<void> ownerAdvanceTurn({bool force = false}) async {
    if (!_isOwner || _engine == null) return;
    if (!force && !allOthersReady) return;
    // Explicit re-entrancy guard against a rapid double-tap triggering two
    // engine advances back to back.
    if (_advancing) return;
    _advancing = true;
    try {
      _readyForNext.clear();
      _myReadyIntent = false;
      _engine!.advanceTurn();
      _autoFillAwayPlayers();
      if (_engine!.isGameOver) _loadState = MemeLoadState.gameOver;
      notifyListeners();
      _broadcastState();
    } finally {
      _advancing = false;
    }
  }

  /// Advance the round, delegating to the owner's client if the caller
  /// isn't the owner — used by a moderator granted 'advance_turn'.
  Future<void> requestAdvanceTurn({bool force = false}) async {
    if (_isOwner) {
      await ownerAdvanceTurn(force: force);
      return;
    }
    if (_roomId == null) return;
    await _realtime.broadcastPlayerAction(_roomId!, {
      'action': 'meme_mod_advance_turn',
      'force': force,
      'user_id': _userId,
      'display_name': _displayName,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Durable "I intend to be ready for the current round" flag — unlike
  // _readyForNext (wholesale overwritten by each authoritative
  // meme_ready_count broadcast), this survives a broadcast that never
  // reached the owner, so onReadyCountUpdate can detect the mismatch and
  // resend instead of leaving the presser stuck forever.
  bool _myReadyIntent = false;

  Future<void> markReadyForNext() {
    final isPlayer = state?.playerOrder.contains(_userId) ?? false;
    AppLogger.debug(
      '[READY-DEBUG][meme] markReadyForNext called by $_userId '
      'isPlayer=$isPlayer hasMarkedReady=$hasMarkedReady',
    );
    if (_userId.isEmpty || hasMarkedReady || !isPlayer) return Future.value();
    _myReadyIntent = true;
    _readyForNext.add(_userId);
    notifyListeners();
    return _handleAction({'action': 'meme_ready_next'});
  }

  int _lastReadyCountTs = 0;

  void onReadyCountUpdate(
    List<String> readyUserIds, {
    int? ts,
    int? roundNumber,
  }) {
    AppLogger.debug('[READY-DEBUG][meme] onReadyCountUpdate: $readyUserIds');
    // A ready_count broadcast is only meaningful for the round it was
    // computed for. State-broadcast and ready-count travel as two separate
    // messages with no ordering guarantee between them — the very last
    // ready_count of a round (the one that made everyone ready and caused
    // the advance) can arrive AFTER the new round's state broadcast already
    // reset _readyForNext, and since its ts is not necessarily older than
    // _lastReadyCountTs it would otherwise slip past the ts guard below and
    // re-populate the stale, already-complete list for the round that just
    // ended. Tagging every ready_count with the round it belongs to and
    // rejecting a mismatch closes that gap regardless of ts ordering.
    if (roundNumber != null &&
        state?.roundNumber != null &&
        roundNumber != state!.roundNumber) {
      return;
    }
    // Multiple players marking ready in quick succession fires multiple
    // ready_count broadcasts back to back — with no delivery-order
    // guarantee, an older one arriving after a newer one would otherwise
    // silently un-ready someone who already marked ready.
    if (ts != null && ts < _lastReadyCountTs) return;
    if (ts != null) _lastReadyCountTs = ts;
    _readyForNext
      ..clear()
      ..addAll(readyUserIds);
    // Self-heal a lost meme_ready_next broadcast: if I intended to be
    // ready for this round but the owner's authoritative list doesn't
    // have me, resend rather than leaving myself and the host stuck.
    if (_myReadyIntent && !_readyForNext.contains(_userId)) {
      _readyForNext.add(_userId);
      _handleAction({'action': 'meme_ready_next'}).ignore();
    }
    notifyListeners();
  }

  void onStateBroadcast(Map<String, dynamic> payload) {
    if (_isOwner) return;
    try {
      final snap =
          (payload['snapshot'] as Map<String, dynamic>?)?['state']
              as Map<String, dynamic>? ??
          payload['state'] as Map<String, dynamic>?;
      if (snap == null) return;
      // Realtime broadcast has no ordering/delivery guarantee — an older
      // snapshot arriving after a newer one (e.g. a retried/delayed packet
      // during a brief reconnect) would otherwise silently revert the
      // round/phase with nothing to warn about it.
      final incomingTs = snap['snapshot_at'] as int? ?? 0;
      final currentTs = state?.snapshotAt ?? 0;
      if (state != null && incomingTs <= currentTs) {
        AppLogger.debug(
          'MemeProvider: stale broadcast ts=$incomingTs discarded',
        );
        return;
      }
      final previousRound = state?.roundNumber;
      _syncTimeoutTimer?.cancel();
      _lastStateReceivedAt = DateTime.now();
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
      if (previousRound != null && state?.roundNumber != previousRound) {
        _readyForNext.clear();
        _myReadyIntent = false;
      }
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
    if (action == 'meme_mod_advance_turn') {
      if (_isAllowed(uid, 'advance_turn')) {
        ownerAdvanceTurn(force: payload['force'] as bool? ?? false);
      }
      return;
    }
    if (action == 'meme_ready_next') {
      final isPlayer = state?.playerOrder.contains(uid) ?? false;
      AppLogger.debug(
        '[READY-DEBUG][meme] onPlayerAction ready_next from $uid '
        'isPlayer=$isPlayer current=$_readyForNext',
      );
      if (isPlayer && _readyForNext.add(uid)) {
        AppLogger.debug(
          '[READY-DEBUG][meme] rebroadcasting ready_count: $_readyForNext',
        );
        notifyListeners();
        final broadcastTs = DateTime.now().millisecondsSinceEpoch;
        _lastReadyCountTs = broadcastTs;
        _realtime.broadcastRoomEvent(_roomId ?? '', {
          'type': 'meme_ready_count',
          'ready_user_ids': _readyForNext.toList(),
          'ts': broadcastTs,
          'round_number': state?.roundNumber,
        }).ignore();
      }
      return;
    }
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
    // A real action here can flip the phase (e.g. the last real submission
    // opens voting) — re-check for any away player who now needs an
    // auto-fill in the new phase.
    _autoFillAwayPlayers();
    if (_engine!.isGameOver) _loadState = MemeLoadState.gameOver;
    notifyListeners();
    _broadcastState();
  }

  void onSyncRequest(Map<String, dynamic> _) {
    if (!_isOwner) return;
    _broadcastState();
    // The ready list is broadcast separately from game state (as a room
    // event, not part of the snapshot) — resend it here too so a client
    // that reconnected mid-round doesn't miss it and get stuck waiting.
    final broadcastTs = DateTime.now().millisecondsSinceEpoch;
    _lastReadyCountTs = broadcastTs;
    _realtime.broadcastRoomEvent(_roomId ?? '', {
      'type': 'meme_ready_count',
      'ready_user_ids': _readyForNext.toList(),
      'ts': broadcastTs,
      'round_number': state?.roundNumber,
    }).ignore();
  }

  Future<void> _handleAction(Map<String, dynamic> action) async {
    // A kicked/banned/left player must not be able to act again even in the
    // brief window before their client has processed the moderation
    // broadcast and navigated away.
    if (_effectiveAwayIds.contains(_userId)) return;
    // Moderator-imposed game mute (RoomMemberEntity.isGameMuted, distinct
    // from chat mute) — muted players can still watch but not act.
    if (roomProvider?.currentMember?.isGameMuted ?? false) return;
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

  bool _gameEndedNotified = false;

  void _broadcastState() {
    if (_roomId == null || _engine == null) return;
    final snapshot = _engine!.serializeState();
    _realtime.broadcastGameState(_roomId!, {
      'state': snapshot,
    }, _userId).ignore();

    if (_isOwner && _sessionId != null) {
      Supabase.instance.client
          .from('game_sessions')
          .update({
            'state_snapshot': snapshot,
            'updated_at': DateTime.now().toIso8601String(),
            if (_engine!.isGameOver) 'status': 'completed',
            if (_engine!.isGameOver)
              'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _sessionId!)
          .then(
            (_) {},
            onError: (e) {
              AppLogger.warning('MemeProvider: snapshot save failed: $e');
            },
          );
    }
    if (_isOwner && _engine!.isGameOver && !_gameEndedNotified) {
      _gameEndedNotified = true;
      sl.roomRepository.notifyGameEnded(_roomId!).ignore();
    }
  }

  @override
  void dispose() {
    _syncTimeoutTimer?.cancel();
    _staleWatchdog?.cancel();
    super.dispose();
  }
}

void _showAddCustomCardSheet(BuildContext ctx, MemeGameProvider game) {
  final ctrl = TextEditingController();
  bool submitting = false;

  showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (_, setS) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(sheetCtx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_card_outlined),
                  const SizedBox(width: 8),
                  const Text(
                    'Add Custom Card',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const Spacer(),
                  const Text(
                    '✨ Premium',
                    style: TextStyle(color: Colors.amber, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'This prompt will be added to the deck for this session only.',
                style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(sheetCtx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLength: 300,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Write your meme prompt…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: submitting
                    ? null
                    : () async {
                        if (ctrl.text.trim().length < 5) return;
                        setS(() => submitting = true);
                        final result = await game.addCustomCard(
                          content: ctrl.text.trim(),
                        );
                        if (sheetCtx.mounted) {
                          Navigator.of(sheetCtx).pop();
                          if (!result.success && ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(result.error ?? 'Failed')),
                            );
                          } else if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Custom card added to deck!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                child: submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add Card to Deck'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> memeShowLeaveDialog(
  BuildContext ctx, {
  required String roomId,
  required bool isOwner,
  String displayName = 'A player',
  MemeGameProvider? game,
}) async {
  if (!ctx.mounted) return;
  final myUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
  final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

  final confirmed = await showDialog<bool>(
    context: ctx,
    builder: (d) => AlertDialog(
      title: const Text('Quit Game?'),
      content: const Text('Leave the current game?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(d, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(d, true),
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
      await sl.realtimeService.broadcastGameEnded(roomId, {
        'reason': 'host_quit_to_lobby',
      });
      await sl.roomRepository.updateStatus(roomId, RoomStatus.waiting);
    } catch (_) {}
    if (ctx.mounted) {
      // Mark this as a programmatic exit before popping, so PopScope
      // (which shares this same MemeGameProvider instance) doesn't
      // mistake it for the user backing out and open Quit Game again.
      game?.isNavigatingAway = true;
      if (ctx.canPop()) {
        ctx.pop();
      } else {
        AppRouter.router.go('/home/room/$roomId');
      }
    }
    return;
  }
  // A normal player/spectator quitting the game also leaves the room
  // entirely (frees their slot, updates counts) — for_good:true tells
  // every client's RoomProvider to remove them from the member list.
  try {
    await sl.roomRepository.setMemberDefinitiveLeave(roomId, myUserId);
    await sl.realtimeService.broadcastRoomEvent(roomId, {
      'type': 'player_left',
      'user_id': myUserId,
      'display_name': displayName,
      'for_good': true,
    });
  } catch (_) {}
  if (ctx.mounted) AppRouter.router.go(RouteNames.home);
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
    this.isSpectator = false,
    this.roomProvider,
  });
  final String roomId;
  final GameConfig config;
  final List<String> playerIds;
  final Map<String, String> playerDisplayNames;
  final String packId;
  final bool isOwner;
  final bool isModerator;
  final bool isSpectator;
  final String? packCoverUrl;
  final RoomProvider? roomProvider;
  @override
  State<MemeGameScreen> createState() => _MemeGameScreenState();
}

class _MemeGameScreenState extends State<MemeGameScreen> {
  late final MemeGameProvider _provider;

  // Tracks whether we've reached `subscribed` before, so a later reconnect
  // (network drop, backgrounding) also triggers a fresh sync request —
  // Realtime Broadcast has no delivery guarantee or replay, so state
  // broadcasts sent while disconnected are permanently missed otherwise.
  bool _hasEverSubscribed = false;

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
    final user = context.read<AuthProvider>().currentUser!;
    _provider = MemeGameProvider(
      realtimeService: sl.realtimeService,
      userId: user.id,
      displayName: user.displayName ?? user.username ?? 'Player',
      isModerator: widget.isModerator,
    );
    // subscriberId: 'game' — registers alongside RoomProvider's own 'room'
    // listener on the shared channel; does not displace it.
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
          // Mark this as a programmatic exit before popping, so PopScope
          // (which shares this same MemeGameProvider instance) doesn't
          // mistake it for the user backing out and open Quit Game.
          _provider.isNavigatingAway = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The host ended the game')),
          );
          if (context.canPop())
            context.pop();
          else
            AppRouter.router.go(RouteNames.home);
        }
      },
      onRoomEvent: (p) {
        final type = p['type'] as String?;
        if (type == 'meme_ready_count') {
          final ids = (p['ready_user_ids'] as List?)?.cast<String>() ?? [];
          _provider.onReadyCountUpdate(
            ids,
            ts: p['ts'] as int?,
            roundNumber: p['round_number'] as int?,
          );
          return;
        }
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
        if (type == 'game_ended' && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx2) => AlertDialog(
                title: const Text('Game Ended'),
                content: const Text('The host ended the game.'),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx2).pop();
                      if (context.canPop())
                        context.pop();
                      else
                        AppRouter.router.go('/home/room/${widget.roomId}');
                    },
                    child: const Text('Go to Lobby'),
                  ),
                ],
              ),
            );
          });
          return;
        }
        if (type == 'player_left' && mounted) {
          final name = p['display_name'] as String? ?? 'A player';
          final leavingId = p['user_id'] as String?;
          if (leavingId != null && _provider.isOwner) {
            _provider.markPlayerAway(leavingId, forGood: true);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('👋 $name left the game'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
        // RoomProvider's manual-transfer and automatic-failover paths both
        // broadcast 'ownership_transfer' (see room_provider.dart) — this
        // previously only matched 'ownership_transferred', so it never
        // fired for either of those.
        if ((type == 'ownership_transferred' || type == 'ownership_transfer') &&
            mounted) {
          final myId = context.read<AuthProvider>().currentUser?.id;
          if (p['new_owner_id'] == myId) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('👑 You are now the game host!'),
                backgroundColor: Colors.purple,
              ),
            );
          }
          return;
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
        if (type == 'game_kick' && targetId != null) {
          _provider.markPlayerAway(targetId, forGood: true);
          if (targetId == myId && mounted) {
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
          // Room-level kick/ban previously only told the TARGET's own
          // client to leave — every other client's game provider never
          // learned the target was gone, so it kept waiting on their
          // vote/submission indefinitely even though they'd already been
          // removed from the room. Mark them away for everyone.
          _provider.markPlayerAway(targetId, forGood: true);
          if (targetId == myId && mounted) {
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
        }
      },
      onSettingsChange: (_) {},
      onPresenceSync: (_) {},
      onStatusChange: (status) {
        if (!mounted) return;
        if (status == RealtimeSubscribeStatus.subscribed) {
          if (_hasEverSubscribed) _requestSync();
          _hasEverSubscribed = true;
        }
      },
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
      _provider.initAsFollower(
        widget.roomId,
        packId: widget.packId,
        config: widget.config,
      );
    }

    _lastKnownRoomOwner = widget.isOwner;
    widget.roomProvider?.addListener(_onRoomOwnershipChanged);
    _provider.permissionChecker = widget.roomProvider?.memberHasPermission;
    _provider.roomProvider = widget.roomProvider;

    widget.roomProvider?.addListener(_syncAwayFromPresence);
    _provider.addListener(_syncAwayFromPresence);
    _lifecycleSub = widget.roomProvider?.lifecycleEvents.listen(
      _onRoomLifecycleEvent,
    );
  }

  bool? _lastKnownRoomOwner;

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
        // stays mounted underneath this pushed route. This screen
        // previously ALSO reacted to roomClosed with its own snackbar +
        // AppRouter.router.go(), racing against LobbyScreen's showDialog
        // for the same broadcast event — go() replacing the entire route
        // stack while the lobby's AlertDialog was still mid-transition left
        // a semantics-blocking barrier that never cleanly rejoined the
        // tree, producing a permanently corrupted semantics node (repeating
        // '!semantics.parentDataDirty' assertion every frame thereafter).
        // roomClosed now has exactly one owner, same as the other three.
        break;
      case RoomLifecycleEvent.memberLeft:
        final name = widget.roomProvider?.lastDepartedMemberName;
        if (name != null && name.isNotEmpty) {
          context.showSnackBar('$name left the game');
        }
    }
  }

  // Single presence pipeline: RoomProvider already tracks connected/
  // disconnected members reliably via its own debounced presence sync.
  // Reacting to that (instead of the dead RealtimeService presence
  // callbacks) is the one source of truth for away/return in-game.
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

  void _onRoomOwnershipChanged() {
    final rp = widget.roomProvider;
    if (rp == null) return;
    final amOwner = rp.isOwner;
    if (_lastKnownRoomOwner == amOwner) return;
    _lastKnownRoomOwner = amOwner;
    _provider.applyOwnershipChange(amOwner);
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
    widget.roomProvider?.removeListener(_onRoomOwnershipChanged);
    widget.roomProvider?.removeListener(_syncAwayFromPresence);
    _provider.removeListener(_syncAwayFromPresence);
    _lifecycleSub?.cancel();
    // ScreenSecurityService.instance.disable();
    // Only removes this screen's own 'game' listener — the room channel,
    // RoomProvider's 'room' listener, and presence tracking are untouched.
    sl.realtimeService.unsubscribeListener(
      widget.roomId,
      RoomChannelSubscriber.game,
    );
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Stacked so the members management entry point stays reachable across
    // every phase this screen can render (submitting/voting/results) without
    // needing to be threaded into each phase's own Scaffold individually.
    return Stack(
      children: [
        _buildContent(context),
        RoomMembersFab(
          roomProvider: widget.roomProvider,
          gameKickPlayer: _provider.kickPlayerFromGame,
          gameBanPlayer: _provider.banPlayerFromGame,
          heroTag: 'meme_members_${widget.roomId}',
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
          child: Consumer<MemeGameProvider>(
            builder: (ctx, game, _) => AnimatedReactionOverlay(
              reactions: (game.state?.reactions ?? const [])
                  .map((r) => (emoji: r.emoji, ts: r.ts))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) {
        if (_provider.isNavigatingAway) return;
        memeShowLeaveDialog(
          context,
          roomId: widget.roomId,
          isOwner: widget.isOwner,
          game: _provider,
          displayName:
              widget.playerDisplayNames[Supabase
                      .instance
                      .client
                      .auth
                      .currentUser
                      ?.id ??
                  ''] ??
              'A player',
        );
      },
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
                roomId: widget.roomId,
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
                isSpectator: widget.isSpectator,
              ),
              MemePhase.voting => _VotingScreen(
                game: game,
                state: state,
                displayNames: widget.playerDisplayNames,
                roomId: widget.roomId,
                isOwner: widget.isOwner,
                isSpectator: widget.isSpectator,
              ),
              MemePhase.results => _ResultsScreen(
                game: game,
                state: state,
                displayNames: widget.playerDisplayNames,
                roomId: widget.roomId,
                isOwner: widget.isOwner,
                isSpectator: widget.isSpectator,
              ),
            };
          },
        ),
      ),
    );
  }
}

String _nameOf(Map<String, String> names, String id) =>
    names[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

class _ReactionBar extends StatelessWidget {
  const _ReactionBar({
    required this.targetUserId,
    required this.game,
    required this.reactions,
    required this.myId,
    this.isSpectator = false,
  });
  final String targetUserId;
  final MemeGameProvider game;
  final List<EmojiReaction> reactions;
  final String myId;
  final bool isSpectator;

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
      // Spectators can see the tally (unconditionally rendered above) but
      // never trigger a reaction — reuse the "already reacted" flag to hide
      // just the tap-to-react row, same idiom as hasVoted elsewhere.
      alreadyReacted: isSpectator || alreadyReacted || isOwnSubmission,
      onReact: (emoji) => game.reactTo(targetUserId, emoji),
    );
  }
}

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

class _HiddenReactionCard extends StatefulWidget {
  const _HiddenReactionCard({
    required this.stickerChoice,
    required this.caption,
    required this.isOwn,
  });
  final String stickerChoice;
  final String caption;
  final bool isOwn;

  @override
  State<_HiddenReactionCard> createState() => _HiddenReactionCardState();
}

class _HiddenReactionCardState extends State<_HiddenReactionCard> {
  late bool _revealed = widget.isOwn;

  Future<void> _reveal() async {
    await showDialog(
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
                  if (widget.stickerChoice.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _stickerImg(
                        widget.stickerChoice,
                        fit: BoxFit.contain,
                      ),
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
    if (mounted) setState(() => _revealed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_revealed) {
      if (widget.stickerChoice.isEmpty) {
        return widget.caption.isEmpty
            ? const SizedBox.shrink()
            : Text(
                widget.caption,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              );
      }
      return _TappableStickerCard(
        assetPath: widget.stickerChoice,
        caption: widget.caption,
      );
    }

    return GestureDetector(
      onTap: _reveal,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🎭', style: TextStyle(fontSize: 40)),
            SizedBox(height: 8),
            Text(
              'Tap to see their reaction',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _SubmitScreen extends StatefulWidget {
  const _SubmitScreen({
    required this.game,
    required this.state,
    required this.displayNames,
    required this.packId,
    this.packCoverUrl,
    required this.roomId,
    required this.isOwner,
    this.isSpectator = false,
  });
  final MemeGameProvider game;
  final MemeState state;
  final Map<String, String> displayNames;
  final String packId;
  final String? packCoverUrl;
  final String roomId;
  final bool isOwner;
  final bool isSpectator;
  @override
  State<_SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<_SubmitScreen> {
  final _captionCtrl = TextEditingController();
  String _pickedSticker = '';
  List<String> _packReactions = [];
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

  bool get _canSubmit => _pickedSticker.isNotEmpty && !widget.isSpectator;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final hasSubmitted = widget.state.submissions.containsKey(
      widget.game.userId,
    );
    final submitted = widget.state.submissions.length;
    final total = widget.game.activePlayerCount;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => memeShowLeaveDialog(
            context,
            roomId: widget.roomId,
            isOwner: widget.isOwner,
            game: widget.game,
            displayName:
                widget.displayNames[Supabase
                        .instance
                        .client
                        .auth
                        .currentUser
                        ?.id ??
                    ''] ??
                'A player',
          ),
        ),
        title: Text(
          'Round ${widget.state.roundNumber} / ${widget.state.maxRounds}',
        ),
        actions: [
          RulesButton(gameType: GameType.memeGame, config: widget.game.config),
        ],
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
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: double.infinity,
                height: 190,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child:
                          widget.packCoverUrl != null &&
                              widget.packCoverUrl!.isNotEmpty
                          ? ImageCacheService.instance.packCover(
                              url: widget.packCoverUrl,
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: 0,
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
                              AppColors.purple.withOpacity(0.55),
                              const Color(0xFF0D1B2A).withOpacity(0.78),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ROUND ${widget.state.roundNumber}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
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
                            const Text(
                              '😂',
                              style: TextStyle(fontSize: 44),
                            ).animate().scale(
                              begin: const Offset(0, 0),
                              end: const Offset(1, 1),
                              duration: 400.ms,
                              curve: Curves.elasticOut,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.state.currentPrompt?.caption ?? '…',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
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
            ).animate().fadeIn().slideY(begin: -0.05, end: 0),
            const SizedBox(height: 14),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: total == 0 ? 0 : submitted / total),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: AppColors.purple,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$submitted / $total submitted',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            if (!hasSubmitted && !widget.isSpectator) ...[
              Text(
                'Pick your sticker:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
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
            ] else if (widget.isSpectator) ...[
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
                      'Spectating — waiting for players to submit…',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
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

class _VotingScreen extends StatelessWidget {
  const _VotingScreen({
    required this.game,
    required this.state,
    required this.displayNames,
    required this.roomId,
    required this.isOwner,
    this.isSpectator = false,
  });
  final MemeGameProvider game;
  final MemeState state;
  final Map<String, String> displayNames;
  final String roomId;
  final bool isOwner;
  final bool isSpectator;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // Spectators can watch voting but never cast one themselves.
    final hasVoted = isSpectator || state.votes.containsKey(game.userId);
    final entries = state.submissions.entries.toList();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => memeShowLeaveDialog(
            context,
            roomId: roomId,
            isOwner: isOwner,
            game: game,
          ),
        ),
        title: const Text('Vote for the best! 😂'),
        actions: [
          RulesButton(gameType: GameType.memeGame, config: game.config),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: game.activePlayerCount == 0
                          ? 0
                          : state.votes.length / game.activePlayerCount,
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 5,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: AppColors.purple,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.votes.length} / ${game.activePlayerCount} voted',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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
                        shape: isVoted
                            ? RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: AppColors.successGreen,
                                  width: 1.5,
                                ),
                              )
                            : null,
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
                              _HiddenReactionCard(
                                stickerChoice: sub.stickerChoice,
                                caption: sub.caption,
                                isOwn: isOwn,
                              ),
                              const SizedBox(height: 12),
                              _ReactionBar(
                                targetUserId: e.key,
                                game: game,
                                reactions: state.reactions,
                                myId: game.userId,
                                isSpectator: isSpectator,
                              ),
                              const SizedBox(height: 10),
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
                                    color: AppColors.successGreen.withOpacity(
                                      0.1,
                                    ),
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
                      )
                      .animate(delay: (i * 70).ms)
                      .fadeIn()
                      .slideY(begin: 0.04, end: 0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsScreen extends StatefulWidget {
  const _ResultsScreen({
    required this.game,
    required this.state,
    required this.displayNames,
    required this.roomId,
    required this.isOwner,
    this.isSpectator = false,
  });
  final MemeGameProvider game;
  final MemeState state;
  final Map<String, String> displayNames;
  final String roomId;
  final bool isOwner;
  final bool isSpectator;
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
            game: widget.game,
            displayName:
                widget.displayNames[Supabase
                        .instance
                        .client
                        .auth
                        .currentUser
                        ?.id ??
                    ''] ??
                'A player',
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
            if (winnerId != null)
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.amberOrangeLight.withOpacity(0.22),
                      AppColors.amberOrangeLight.withOpacity(0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.amberOrangeLight,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amberOrangeLight.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '🏆',
                      style: TextStyle(fontSize: 48),
                    ).animate().scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 450.ms,
                      curve: Curves.elasticOut,
                    ),
                    Text(
                      _nameOf(widget.displayNames, winnerId),
                      style: theme.textTheme.headlineSmall?.copyWith(
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
                            assetPath:
                                state.submissions[winnerId]!.stickerChoice,
                            size: 80,
                          )
                          .animate(delay: 150.ms)
                          .fadeIn()
                          .scale(
                            begin: const Offset(0.7, 0.7),
                            end: const Offset(1, 1),
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
              ).animate().fadeIn().slideY(begin: -0.08, end: 0),

            Expanded(
              child: ListView(
                children: state.submissions.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((indexed) {
                      final i = indexed.key;
                      final e = indexed.value;
                      final sub = e.value;
                      final votes = tally[e.key] ?? 0;
                      final isWinner = e.key == winnerId;
                      return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: isWinner
                                ? AppColors.amberOrangeLight.withOpacity(0.08)
                                : null,
                            shape: isWinner
                                ? RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: AppColors.amberOrangeLight
                                          .withOpacity(0.5),
                                    ),
                                  )
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
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
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
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
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
                                  _ReactionBar(
                                    targetUserId: e.key,
                                    game: game,
                                    reactions: state.reactions,
                                    myId: game.userId,
                                    isSpectator: widget.isSpectator,
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate(delay: (i * 60).ms)
                          .fadeIn()
                          .slideX(begin: 0.05, end: 0);
                    })
                    .toList(),
              ),
            ),

            const Divider(),
            Text(
              'Leaderboard',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _Leaderboard(
              scores: state.scores,
              displayNames: widget.displayNames,
              myId: game.userId,
            ),
            const SizedBox(height: 12),

            if (game.canAdvanceTurnHere) ...[
              if (!game.allPlayersVoted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${game.votedCount}/${game.activePlayerCount} players voted',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (!game.allOthersReady)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Waiting for players to be ready…',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: (game.allPlayersVoted && game.allOthersReady)
                      ? () => game.requestAdvanceTurn()
                      : null,
                  child: const Text('Next Round →'),
                ),
              ),
              if (game.isOwner)
                Builder(
                  builder: (ctx) {
                    final isPremium =
                        ctx.read<AuthProvider>().currentUser?.isPremium ??
                        false;
                    if (!isPremium) return const SizedBox.shrink();
                    return TextButton.icon(
                      onPressed: () => _showAddCustomCardSheet(ctx, game),
                      icon: const Icon(Icons.add_card_outlined, size: 16),
                      label: const Text('Add custom card'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
            ] else if (widget.isSpectator)
              Text(
                'Spectating — waiting for the host to continue…',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else if (game.hasMarkedReady)
              Text(
                "✓ You're ready — waiting for the host to continue…",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.successGreen,
                ),
              )
            else
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: game.markReadyForNext,
                  child: const Text("I'm Ready for Next Round"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Ranked score list with medal badges and a proportional bar per player,
/// replacing a flat "name — number" text list — the point is to make
/// standing at a glance obvious, reinforcing the competitive framing the
/// redesign asked for.
class _Leaderboard extends StatelessWidget {
  const _Leaderboard({
    required this.scores,
    required this.displayNames,
    required this.myId,
  });
  final Map<String, int> scores;
  final Map<String, String> displayNames;
  final String myId;

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxScore = ranked.isEmpty ? 1 : ranked.first.value.clamp(1, 1 << 30);

    return Column(
      children: ranked.asMap().entries.map((indexed) {
        final rank = indexed.key;
        final e = indexed.value;
        final isMe = e.key == myId;
        final fraction = e.value / maxScore;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  rank < _medals.length ? _medals[rank] : '${rank + 1}',
                  style: theme.textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _nameOf(displayNames, e.key) +
                                (isMe ? ' (You)' : ''),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isMe
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${e.value}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: fraction.toDouble()),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: rank == 0
                              ? AppColors.amberOrangeLight
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate(delay: (rank * 80).ms).fadeIn().slideX(begin: -0.03, end: 0);
      }).toList(),
    );
  }
}

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

class _GameOverScreen extends StatefulWidget {
  const _GameOverScreen({
    required this.game,
    required this.displayNames,
    required this.roomId,
  });
  final MemeGameProvider game;
  final Map<String, String> displayNames;
  final String roomId;
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
                  onPressed: () => goToLobbyOrHome(context, widget.roomId),
                  child: const Text('Go to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemeNhiePausedOverlay extends StatefulWidget {
  const _MemeNhiePausedOverlay({required this.onLeave});
  final VoidCallback onLeave;
  @override
  State<_MemeNhiePausedOverlay> createState() => _MemeNhiePausedOverlayState();
}

class _MemeNhiePausedOverlayState extends State<_MemeNhiePausedOverlay>
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
  Widget build(BuildContext context) => Dialog.fullscreen(
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
