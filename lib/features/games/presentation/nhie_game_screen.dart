// // // import 'dart:convert';
// // // import 'package:flutter/material.dart';
// // // import 'package:go_router/go_router.dart';
// // // import 'package:jma3a/Sticker.dart';
// // // import 'package:jma3a/core/router/app_router.dart';
// // // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // // import 'package:jma3a/features/games/never_have_i_ever/never_have_i_ever_engine.dart';
// // // import 'package:jma3a/features/games/truth_or_dare/data/tod_repository.dart';
// // // import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
// // // import 'package:jma3a/features/rooms/domain/room_entity.dart';
// // // import 'package:jma3a/features/settings/presentation/screen_security_service.dart';
// // // import 'package:provider/provider.dart';
// // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // import '../../../../core/di/service_locator.dart';
// // // import '../../../../core/extensions/context_ext.dart';
// // // import '../../../../core/providers/auth_provider.dart';
// // // import '../../../../core/router/route_names.dart';
// // // import '../../../../core/services/realtime_service.dart';
// // // // import '../../../../core/services/screen_security_service.dart';
// // // import '../../../../core/theme/app_colors.dart';
// // // import '../../../../core/utils/app_logger.dart';

// // // // ── Provider ──────────────────────────────────────────────────────────────────

// // // enum NhieLoadState { idle, loading, ready, error, gameOver }

// // // class NhieGameProvider extends ChangeNotifier {
// // //   NhieGameProvider({
// // //     required RealtimeService realtimeService,
// // //     required String userId,
// // //     required String displayName,
// // //   }) : _realtime = realtimeService,
// // //        _userId = userId,
// // //        _displayName = displayName;

// // //   final RealtimeService _realtime;
// // //   final String _userId, _displayName;
// // //   NeverHaveIEverEngine? _engine;
// // //   NhieLoadState _loadState = NhieLoadState.idle;
// // //   String? _roomId;
// // //   String? _sessionId;
// // //   bool _isOwner = false;
// // //   String _error = '';
// // //   // Away player tracking — auto-submits a neutral "have I" vote for away
// // //   // players so the round isn't stuck waiting for someone who left.
// // //   final Set<String> _awayPlayerIds = {};

// // //   NhieLoadState get loadState => _loadState;
// // //   NhieState? get state => _engine?.currentState as NhieState?;
// // //   String get userId => _userId;
// // //   bool get isOwner => _isOwner;
// // //   String get error => _error;
// // //   Set<String> get awayPlayerIds => _awayPlayerIds;

// // //   void markPlayerAway(String userId, {bool forGood = false}) {
// // //     _awayPlayerIds.add(userId);
// // //     // Auto-submit a neutral vote for this player so the round isn't
// // //     // stuck waiting for them. Only the owner does this to avoid
// // //     // duplicate events.
// // //     if (_isOwner && _engine != null) {
// // //       final s = _engine!.currentState as NhieState?;
// // //       if (s != null && s.isVotingOpen && !s.voteEntries.containsKey(userId)) {
// // //         _engine!.handleEvent(
// // //           NhieVoteEvent(
// // //             userId: userId,
// // //             ts: DateTime.now().millisecondsSinceEpoch,
// // //             haveI: false, // neutral — absent player counts as "have not"
// // //           ),
// // //         );
// // //         notifyListeners();
// // //         _broadcastState();
// // //       }
// // //     }
// // //     notifyListeners();
// // //   }

// // //   void markPlayerReturned(String userId) {
// // //     _awayPlayerIds.remove(userId);
// // //     notifyListeners();
// // //   }

// // //   Future<void> initAsOwner({
// // //     required String roomId,
// // //     required String packId,
// // //     required List<String> playerIds,
// // //     required Map<String, String> displayNames,
// // //     required GameConfig config,
// // //   }) async {
// // //     _roomId = roomId;
// // //     _isOwner = true;
// // //     _loadState = NhieLoadState.loading;
// // //     notifyListeners();
// // //     try {
// // //       var todCards = await TodRepository.instance.loadCardsFromCache(
// // //         packId: packId,
// // //         language: config.language,
// // //       );
// // //       if (todCards.isEmpty) {
// // //         final rows = await Supabase.instance.client
// // //             .from('pack_cards')
// // //             .select('id, content, card_type, difficulty, sort_order')
// // //             .eq('pack_id', packId)
// // //             .order('sort_order');
// // //         todCards = (rows as List).map((r) {
// // //           String text = '';
// // //           final raw = r['content'];
// // //           if (raw is Map) {
// // //             final m = Map<String, dynamic>.from(raw as Map);
// // //             text =
// // //                 (m[config.language] ??
// // //                         m['en'] ??
// // //                         m.values.whereType<String>().firstOrNull ??
// // //                         '')
// // //                     as String;
// // //           } else if (raw is String) {
// // //             try {
// // //               final d = jsonDecode(raw);
// // //               if (d is Map)
// // //                 text = (d[config.language] ?? d['en'] ?? '') as String;
// // //               else
// // //                 text = raw;
// // //             } catch (_) {
// // //               text = raw;
// // //             }
// // //           }
// // //           // difficulty from DB may be a Map (localized) or String — normalise
// // //           final rawDiff = r['difficulty'];
// // //           final diffStr = rawDiff is Map
// // //               ? (rawDiff['en'] ?? rawDiff.values.first ?? 'mild').toString()
// // //               : rawDiff?.toString() ?? 'mild';
// // //           return TodCard(
// // //             id: r['id'] as String,
// // //             content: text,
// // //             type: TodCardType.truth,
// // //             difficulty: TodDifficulty.values.firstWhere(
// // //               (d) => d.name == diffStr,
// // //               orElse: () => TodDifficulty.mild,
// // //             ),
// // //           );
// // //         }).toList();
// // //       }
// // //       final cards = todCards.map((c) {
// // //         var t = c.content;
// // //         for (final p in ['Never have I ever ', 'never have I ever ']) {
// // //           if (t.startsWith(p)) {
// // //             t = t.substring(p.length);
// // //             break;
// // //           }
// // //         }
// // //         if (t.isNotEmpty) t = t[0].toUpperCase() + t.substring(1);
// // //         return NhieCard(id: c.id, content: t, difficulty: c.difficulty.name);
// // //       }).toList();
// // //       _engine = NeverHaveIEverEngine(config, cards: cards);

// // //       // ✅ Resume an existing in-progress session if one exists, instead of
// // //       // always creating a brand-new one — same fix as ToD/meme.
// // //       final existing = await Supabase.instance.client
// // //           .from('game_sessions')
// // //           .select('id, state_snapshot, game_type')
// // //           .eq('room_id', roomId)
// // //           .eq('status', 'active')
// // //           .order('started_at', ascending: false)
// // //           .limit(1)
// // //           .maybeSingle();
// // //       // Only restore snapshots from the same game type — a meme or ToD
// // //       // session snapshot will have incompatible structure and cause cast errors.
// // //       final snapshotGameType = existing?['game_type'] as String?;
// // //       Map<String, dynamic>? existingSnapshot;
// // //       if (snapshotGameType == 'never_have_i_ever') {
// // //         existingSnapshot = existing?['state_snapshot'] as Map<String, dynamic>?;
// // //       }

// // //       if (existing != null &&
// // //           existingSnapshot != null &&
// // //           existingSnapshot.isNotEmpty) {
// // //         // Sanitize scores — Supabase JSONB may return nested maps for int
// // //         // values if the snapshot was written with wrong types. Force-flatten.
// // //         final raw = existingSnapshot;
// // //         if (raw['scores'] is Map) {
// // //           raw['scores'] = (raw['scores'] as Map).map(
// // //             (k, v) => MapEntry(k as String, v is num ? v.toInt() : 0),
// // //           );
// // //         }
// // //         _sessionId = existing['id'] as String;
// // //         _engine!.restoreFromSnapshot(raw);
// // //         AppLogger.info('NhieProvider: resumed existing session $_sessionId');
// // //       } else {
// // //         _engine!.init(playerIds);
// // //         try {
// // //           final inserted = await Supabase.instance.client
// // //               .from('game_sessions')
// // //               .insert({
// // //                 'room_id': roomId,
// // //                 'pack_id': packId,
// // //                 'game_type': 'never_have_i_ever',
// // //                 'player_ids': playerIds,
// // //                 'owner_id': _userId,
// // //                 'state_snapshot': _engine!.serializeState(),
// // //                 'max_rounds': config.maxRounds,
// // //                 'turn_timer_secs': config.turnTimerSeconds,
// // //                 'allow_skip': config.allowSkip,
// // //                 'allow_spicy': config.allowSpicy,
// // //               })
// // //               .select('id')
// // //               .single();
// // //           _sessionId = inserted['id'] as String;
// // //         } catch (e) {
// // //           AppLogger.warning('NhieProvider: failed to create session: $e');
// // //         }
// // //       }

// // //       _loadState = NhieLoadState.ready;
// // //       notifyListeners();
// // //       _broadcastState();
// // //     } catch (e) {
// // //       _error = e.toString();
// // //       _loadState = NhieLoadState.error;
// // //       AppLogger.error('NhieProvider: init failed', error: e);
// // //       notifyListeners();
// // //     }
// // //   }

// // //   void initAsFollower(String roomId) {
// // //     _roomId = roomId;
// // //     _isOwner = false;
// // //     _loadState = NhieLoadState.loading;
// // //     notifyListeners();
// // //   }

// // //   Future<void> vote(bool haveI, {String message = ''}) => _handleAction({
// // //     'action': 'nhie_vote',
// // //     'have_i': haveI,
// // //     'message': message,
// // //   });
// // //   Future<void> sendReaction(String emoji) =>
// // //       _handleAction({'action': 'nhie_reaction', 'sticker': emoji});
// // //   Future<void> ownerAdvanceTurn() async {
// // //     if (!_isOwner || _engine == null) return;
// // //     _engine!.advanceTurn();
// // //     if (_engine!.isGameOver) _loadState = NhieLoadState.gameOver;
// // //     notifyListeners();
// // //     _broadcastState();
// // //   }

// // //   void onStateBroadcast(Map<String, dynamic> payload) {
// // //     if (_isOwner) return;
// // //     try {
// // //       final snap =
// // //           (payload['snapshot'] as Map<String, dynamic>?)?['state']
// // //               as Map<String, dynamic>? ??
// // //           payload['state'] as Map<String, dynamic>?;
// // //       if (snap == null) return;
// // //       _engine ??= NeverHaveIEverEngine(
// // //         const GameConfig(
// // //           maxRounds: 10,
// // //           turnTimerSeconds: 60,
// // //           allowSkip: false,
// // //           allowSpicy: false,
// // //         ),
// // //         cards: [],
// // //       );
// // //       _engine!.restoreFromSnapshot(snap);
// // //       _loadState = _engine!.isGameOver
// // //           ? NhieLoadState.gameOver
// // //           : NhieLoadState.ready;
// // //       notifyListeners();
// // //     } catch (e) {
// // //       AppLogger.warning('NhieProvider: restore failed: $e');
// // //     }
// // //   }

// // //   void onPlayerAction(Map<String, dynamic> payload) {
// // //     if (!_isOwner || _engine == null) return;
// // //     final action = payload['action'] as String?;
// // //     final uid = payload['user_id'] as String?;
// // //     final ts = payload['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
// // //     if (uid == null) return;
// // //     if (action == 'nhie_vote') {
// // //       _engine!.handleEvent(
// // //         NhieVoteEvent(
// // //           userId: uid,
// // //           ts: ts,
// // //           haveI: payload['have_i'] as bool? ?? false,
// // //           message: payload['message'] as String? ?? '',
// // //         ),
// // //       );
// // //     } else if (action == 'nhie_reaction') {
// // //       _engine!.handleEvent(
// // //         NhieReactionEvent(
// // //           userId: uid,
// // //           ts: ts,
// // //           sticker: payload['sticker'] as String? ?? '😂',
// // //         ),
// // //       );
// // //     }
// // //     if (_engine!.isGameOver) _loadState = NhieLoadState.gameOver;
// // //     notifyListeners();
// // //     _broadcastState();
// // //   }

// // //   void onSyncRequest(Map<String, dynamic> _) {
// // //     if (_isOwner) _broadcastState();
// // //   }

// // //   Future<void> _handleAction(Map<String, dynamic> action) async {
// // //     final full = {
// // //       ...action,
// // //       'user_id': _userId,
// // //       'display_name': _displayName,
// // //       'ts': DateTime.now().millisecondsSinceEpoch,
// // //     };
// // //     if (_isOwner && _engine != null)
// // //       onPlayerAction(full);
// // //     else if (_roomId != null)
// // //       await _realtime.broadcastPlayerAction(_roomId!, full);
// // //   }

// // //   void _broadcastState() {
// // //     if (_roomId == null || _engine == null) return;
// // //     final snapshot = _engine!.serializeState();
// // //     _realtime.broadcastGameState(_roomId!, {
// // //       'state': snapshot,
// // //     }, _userId).ignore();

// // //     if (_isOwner && _sessionId != null) {
// // //       Supabase.instance.client
// // //           .from('game_sessions')
// // //           .update({
// // //             'state_snapshot': snapshot,
// // //             'updated_at': DateTime.now().toIso8601String(),
// // //             if (_engine!.isGameOver) 'status': 'completed',
// // //             if (_engine!.isGameOver)
// // //               'ended_at': DateTime.now().toIso8601String(),
// // //           })
// // //           .eq('id', _sessionId!)
// // //           .then(
// // //             (_) {},
// // //             onError: (e) {
// // //               AppLogger.warning('NhieProvider: snapshot save failed: $e');
// // //             },
// // //           );
// // //     }
// // //   }
// // // }

// // // // ── Confirm leave dialog ──────────────────────────────────────────────────────

// // // Future<void> nhieShowLeaveDialog(
// // //   BuildContext ctx, {
// // //   required String roomId,
// // //   required bool isOwners,
// // //   String displayName = 'A player',
// // // }) async {
// // //   if (!ctx.mounted) return;
// // //   final isOwner = isOwners;
// // //   final myUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
// // //   final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

// // //   if (isOwner) {
// // //     final mods = await sl.roomRepository
// // //         .getRoomModerators(roomId)
// // //         .catchError((_) => <Map<String, dynamic>>[]);
// // //     final hasMod = mods.isNotEmpty;

// // //     final choice = await showDialog<String>(
// // //       context: ctx,
// // //       builder: (d) => AlertDialog(
// // //         title: const Text('Leave Game?'),
// // //         content: const Text("Choose what happens while you're away."),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Navigator.pop(d, 'cancel'),
// // //             child: const Text('Stay'),
// // //           ),
// // //           if (hasMod)
// // //             FilledButton.tonal(
// // //               onPressed: () => Navigator.pop(d, 'handoff'),
// // //               child: const Text('Play Another & Hand Off'),
// // //             ),
// // //           FilledButton.tonal(
// // //             onPressed: () => Navigator.pop(d, 'quit_lobby'),
// // //             child: const Text('Quit to Lobby'),
// // //           ),
// // //           FilledButton.tonal(
// // //             onPressed: () => Navigator.pop(d, 'pause'),
// // //             child: const Text('Pause & Return Later'),
// // //           ),
// // //           FilledButton(
// // //             style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // //             onPressed: () => Navigator.pop(d, 'end'),
// // //             child: const Text('End Room for Everyone'),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //     if (choice == null || choice == 'cancel' || !ctx.mounted) return;

// // //     if (choice == 'handoff' && mods.isNotEmpty) {
// // //       final newOwner = mods.length == 1
// // //           ? mods.first['user_id'] as String
// // //           : await showDialog<String>(
// // //               context: ctx,
// // //               builder: (d) => SimpleDialog(
// // //                 title: const Text('Who takes over?'),
// // //                 children: mods.map((m) {
// // //                   final uid = m['user_id'] as String;
// // //                   return SimpleDialogOption(
// // //                     onPressed: () => Navigator.pop(d, uid),
// // //                     child: Text(uid.substring(0, 8).toUpperCase()),
// // //                   );
// // //                 }).toList(),
// // //               ),
// // //             );
// // //       if (newOwner == null || !ctx.mounted) return;
// // //       try {
// // //         await Supabase.instance.client
// // //             .from('rooms')
// // //             .update({'owner_id': newOwner})
// // //             .eq('id', roomId);
// // //         await sl.realtimeService.broadcastRoomEvent(roomId, {
// // //           'type': 'ownership_transferred',
// // //           'new_owner_id': newOwner,
// // //           'by': myUserId,
// // //         });
// // //         await sl.realtimeService.broadcastRoomEvent(roomId, {
// // //           'type': 'player_left',
// // //           'user_id': myUserId,
// // //           'for_good': true,
// // //         });
// // //       } catch (_) {}
// // //       if (ctx.mounted) AppRouter.router.go(RouteNames.home);
// // //       return;
// // //     }

// // //     if (choice == 'quit_lobby') {
// // //       try {
// // //         await sl.realtimeService.broadcastRoomEvent(roomId, {
// // //           'type': 'game_ended',
// // //           'reason': 'host_quit_to_lobby',
// // //         });
// // //         await sl.roomRepository.updateStatus(roomId, RoomStatus.waiting);
// // //       } catch (_) {}
// // //       if (ctx.mounted) AppRouter.router.go('/home/room/$roomId');
// // //       return;
// // //     }

// // //     if (choice == 'pause') {
// // //       try {
// // //         await sl.roomRepository.updateStatus(roomId, RoomStatus.paused);
// // //         await sl.realtimeService.broadcastRoomEvent(roomId, {
// // //           'type': 'game_paused',
// // //           'reason': 'host_away',
// // //         });
// // //         await Future.delayed(const Duration(milliseconds: 300));
// // //       } catch (_) {}
// // //       if (ctx.mounted) AppRouter.router.go(RouteNames.home);
// // //     } else {
// // //       try {
// // //         await sl.realtimeService.broadcastGameEnded(roomId, {
// // //           'reason': 'host_ended',
// // //         });
// // //         await sl.realtimeService.broadcastRoomEvent(roomId, {
// // //           'type': 'owner_left',
// // //           'reason': 'host_ended',
// // //         });
// // //         await sl.roomRepository.updateStatus(roomId, RoomStatus.closed);
// // //       } catch (_) {}
// // //       if (ctx.mounted) AppRouter.router.go(RouteNames.home);
// // //     }
// // //   } else {
// // //     final returnMins = isPremium ? 10 : 5;
// // //     final choice = await showDialog<String>(
// // //       context: ctx,
// // //       builder: (d) => AlertDialog(
// // //         title: const Text('Leave Game?'),
// // //         content: Text(
// // //           "If you'll return, your turns will be skipped. You have "
// // //           '$returnMins minutes — after that your seat is lost.',
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Navigator.pop(d, 'cancel'),
// // //             child: const Text('Stay'),
// // //           ),
// // //           FilledButton.tonal(
// // //             onPressed: () => Navigator.pop(d, 'return'),
// // //             child: Text("I'll Return ($returnMins min)"),
// // //           ),
// // //           FilledButton(
// // //             style: FilledButton.styleFrom(backgroundColor: Colors.red),
// // //             onPressed: () => Navigator.pop(d, 'definitive'),
// // //             child: const Text('Leave for Good'),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //     if (choice == null || choice == 'cancel' || !ctx.mounted) return;
// // //     try {
// // //       if (choice == 'return') {
// // //         await sl.roomRepository.setMemberAway(roomId, myUserId, away: true);
// // //         await sl.roomRepository.setReturnTimer(
// // //           roomId: roomId,
// // //           userId: myUserId,
// // //           isPremium: isPremium,
// // //         );
// // //         await sl.realtimeService.broadcastRoomEvent(roomId, {
// // //           'type': 'player_left',
// // //           'user_id': myUserId,
// // //           'display_name': displayName,
// // //           'for_good': false,
// // //           'return_mins': returnMins,
// // //         });
// // //       } else {
// // //         await sl.roomRepository.setMemberDefinitiveLeave(roomId, myUserId);
// // //         await sl.realtimeService.broadcastRoomEvent(roomId, {
// // //           'type': 'player_left',
// // //           'user_id': myUserId,
// // //           'display_name': displayName,
// // //           'for_good': true,
// // //         });
// // //       }
// // //     } catch (_) {}
// // //     if (ctx.mounted) AppRouter.router.go(RouteNames.home);
// // //   }
// // // }

// // // // ── Screen ────────────────────────────────────────────────────────────────────

// // // class NhieGameScreen extends StatefulWidget {
// // //   const NhieGameScreen({
// // //     super.key,
// // //     required this.roomId,
// // //     required this.config,
// // //     required this.playerIds,
// // //     required this.playerDisplayNames,
// // //     required this.packId,
// // //     this.packCoverUrl,
// // //     required this.isOwner,
// // //     this.isModerator = false,
// // //   });
// // //   final String roomId;
// // //   final GameConfig config;
// // //   final List<String> playerIds;
// // //   final Map<String, String> playerDisplayNames;
// // //   final String packId;
// // //   final bool isOwner;
// // //   final bool isModerator;
// // //   final String? packCoverUrl;
// // //   @override
// // //   State<NhieGameScreen> createState() => _NhieGameScreenState();
// // // }

// // // class _NhieGameScreenState extends State<NhieGameScreen> {
// // //   late final NhieGameProvider _provider;

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
// // //     final user = context.read<AuthProvider>().currentUser!;
// // //     _provider = NhieGameProvider(
// // //       realtimeService: sl.realtimeService,
// // //       userId: user.id,
// // //       displayName: user.displayName ?? user.username ?? 'Player',
// // //     );
// // //     // Update callbacks on existing channel (no teardown needed)
// // //     sl.realtimeService.subscribe(
// // //       roomId: widget.roomId,
// // //       onGameState: (p) => _provider.onStateBroadcast(p),
// // //       onPlayerAction: (p) => _provider.onPlayerAction(p),
// // //       onSyncRequest: (p) => _provider.onSyncRequest(p),
// // //       onGameStarted: (_) {},
// // //       onGameEnded: (p) {
// // //         if (mounted) {
// // //           ScaffoldMessenger.of(context).showSnackBar(
// // //             const SnackBar(content: Text('The host ended the game')),
// // //           );
// // //           if (context.canPop())
// // //             context.pop();
// // //           else
// // //             context.go(RouteNames.home);
// // //         }
// // //       },
// // //       onRoomEvent: (p) {
// // //         final evType = p['type'] as String?;
// // //         if (evType == 'screenshot_taken') {
// // //           final shooterId = p['user_id'] as String?;
// // //           final myId = context.read<AuthProvider>().currentUser?.id;
// // //           if (shooterId != null && shooterId != myId && mounted) {
// // //             ScaffoldMessenger.of(context).showSnackBar(
// // //               SnackBar(
// // //                 content: Text(
// // //                   '📸 ${widget.playerDisplayNames[shooterId] ?? 'Someone'} took a screenshot',
// // //                 ),
// // //                 backgroundColor: Colors.black87,
// // //               ),
// // //             );
// // //           }
// // //           return;
// // //         }
// // //         if (evType == 'game_ended' && mounted) {
// // //           if ((p['reason'] as String?) == 'host_quit_to_lobby') {
// // //             WidgetsBinding.instance.addPostFrameCallback((_) {
// // //               if (!mounted) return;
// // //               sl.realtimeService.unsubscribe(widget.roomId);
// // //               ScaffoldMessenger.of(context).showSnackBar(
// // //                 const SnackBar(
// // //                   content: Text('🔄 Host ended the game — back to lobby'),
// // //                   duration: Duration(seconds: 3),
// // //                 ),
// // //               );
// // //               if (context.canPop()) {
// // //                 context.pop();
// // //               } else {
// // //                 AppRouter.router.go('/home/room/${widget.roomId}');
// // //               }
// // //             });
// // //           }
// // //           return;
// // //         }
// // //         if (evType == 'player_left' && mounted) {
// // //           final name = p['display_name'] as String? ?? 'A player';
// // //           final forGood = p['for_good'] as bool? ?? true;
// // //           final leavingId = p['user_id'] as String?;
// // //           final returnMins = p['return_mins'] as int?;
// // //           if (leavingId != null && _provider.isOwner) {
// // //             _provider.markPlayerAway(leavingId, forGood: forGood);
// // //           }
// // //           ScaffoldMessenger.of(context).showSnackBar(
// // //             SnackBar(
// // //               content: Text(
// // //                 forGood
// // //                     ? '👋 $name left the game'
// // //                     : '🕐 $name stepped away (${returnMins != null ? 'back in ${returnMins}m' : 'coming back'})',
// // //               ),
// // //               backgroundColor: forGood
// // //                   ? Colors.red.shade700
// // //                   : Colors.orange.shade700,
// // //               duration: const Duration(seconds: 4),
// // //             ),
// // //           );
// // //           return;
// // //         }
// // //         if (evType == 'ownership_transferred' && mounted) {
// // //           final myId = context.read<AuthProvider>().currentUser?.id;
// // //           if (p['new_owner_id'] == myId) {
// // //             ScaffoldMessenger.of(context).showSnackBar(
// // //               const SnackBar(
// // //                 content: Text('👑 You are now the game host!'),
// // //                 backgroundColor: Colors.purple,
// // //               ),
// // //             );
// // //           }
// // //           return;
// // //         }
// // //         if ((p['type'] as String?) == 'game_paused' && mounted) {
// // //           WidgetsBinding.instance.addPostFrameCallback((_) {
// // //             if (!mounted) return;
// // //             showDialog(
// // //               context: context,
// // //               barrierDismissible: false,
// // //               barrierColor: Colors.black.withOpacity(0.85),
// // //               builder: (_) => _MemeNhiePausedOverlay(
// // //                 onLeave: () {
// // //                   Navigator.of(context).pop();
// // //                   AppRouter.router.go(RouteNames.home);
// // //                 },
// // //               ),
// // //             );
// // //           });
// // //         }
// // //         if (((p['type'] as String?) == 'room_closed' ||
// // //             (p['type'] as String?) == 'owner_left')) {
// // //           WidgetsBinding.instance.addPostFrameCallback((_) {
// // //             if (mounted)
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
// // //             else
// // //               AppRouter.router.go(RouteNames.home);
// // //           });
// // //         }
// // //       },
// // //       onChatMessage: (_) {},
// // //       onModeration: (p) {
// // //         final type = p['type'] as String?;
// // //         final targetId = p['target_user_id'] as String?;
// // //         final myId = context.read<AuthProvider>().currentUser?.id;
// // //         if ((type == 'kick' || type == 'ban') && targetId == myId && mounted) {
// // //           ScaffoldMessenger.of(context).showSnackBar(
// // //             SnackBar(
// // //               content: Text(
// // //                 type == 'kick'
// // //                     ? 'You were removed from the room'
// // //                     : 'You were banned from this room',
// // //               ),
// // //             ),
// // //           );
// // //           context.go(RouteNames.home);
// // //         }
// // //       },
// // //       onSettingsChange: (_) {},
// // //       onPresenceSync: (_) {},
// // //       onPresenceJoin: (_) {},
// // //       onPresenceLeave: (_) {},
// // //       onStatusChange: (_) {},
// // //     );
// // //     // Send sync request after short delay so owner's response arrives on active channel
// // //     if (!widget.isOwner) {
// // //       Future.delayed(const Duration(milliseconds: 300), _requestSync);
// // //     }
// // //     if (widget.isOwner) {
// // //       _provider.initAsOwner(
// // //         roomId: widget.roomId,
// // //         packId: widget.packId,
// // //         playerIds: widget.playerIds,
// // //         displayNames: widget.playerDisplayNames,
// // //         config: widget.config,
// // //       );
// // //     } else {
// // //       _provider.initAsFollower(widget.roomId);
// // //     }
// // //   }

// // //   void _requestSync() {
// // //     if (!mounted) return;
// // //     // Send immediately, then retry after 1s and 3s in case owner missed it
// // //     sl.realtimeService
// // //         .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
// // //         .ignore();
// // //     Future.delayed(const Duration(seconds: 1), () {
// // //       if (mounted && _provider.loadState == NhieLoadState.loading) {
// // //         sl.realtimeService
// // //             .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
// // //             .ignore();
// // //       }
// // //     });
// // //     Future.delayed(const Duration(seconds: 3), () {
// // //       if (mounted && _provider.loadState == NhieLoadState.loading) {
// // //         sl.realtimeService
// // //             .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
// // //             .ignore();
// // //       }
// // //     });
// // //   }

// // //   @override
// // //   void dispose() {
// // //     ScreenSecurityService.instance.disable();
// // //     _provider.dispose();
// // //     super.dispose();
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return ChangeNotifierProvider.value(
// // //       value: _provider,
// // //       child: Consumer<NhieGameProvider>(
// // //         builder: (ctx, game, _) {
// // //           if (game.loadState == NhieLoadState.loading)
// // //             return const Scaffold(
// // //               body: Center(child: CircularProgressIndicator()),
// // //             );
// // //           if (game.loadState == NhieLoadState.error)
// // //             return Scaffold(
// // //               body: Center(
// // //                 child: Padding(
// // //                   padding: const EdgeInsets.all(24),
// // //                   child: Text(
// // //                     'Error: ${game.error}',
// // //                     textAlign: TextAlign.center,
// // //                   ),
// // //                 ),
// // //               ),
// // //             );
// // //           if (game.loadState == NhieLoadState.gameOver)
// // //             return _GameOverScreen(
// // //               game: game,
// // //               displayNames: widget.playerDisplayNames,
// // //             );
// // //           final state = game.state;
// // //           if (state == null)
// // //             return const Scaffold(
// // //               body: Center(child: CircularProgressIndicator()),
// // //             );
// // //           return _GameBody(
// // //             game: game,
// // //             state: state,
// // //             displayNames: widget.playerDisplayNames,
// // //             packCoverUrl: widget.packCoverUrl,
// // //             roomId: widget.roomId,
// // //             isOwner: widget.isOwner,
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ── Game body ─────────────────────────────────────────────────────────────────

// // // class _GameBody extends StatefulWidget {
// // //   const _GameBody({
// // //     required this.game,
// // //     required this.state,
// // //     required this.displayNames,
// // //     this.packCoverUrl,
// // //     required this.roomId,
// // //     required this.isOwner,
// // //   });
// // //   final NhieGameProvider game;
// // //   final NhieState state;
// // //   final Map<String, String> displayNames;
// // //   final String? packCoverUrl;
// // //   final String roomId;
// // //   final bool isOwner;
// // //   @override
// // //   State<_GameBody> createState() => _GameBodyState();
// // // }

// // // class _GameBodyState extends State<_GameBody> {
// // //   final _msgCtrl = TextEditingController();
// // //   bool _showHistory = false;

// // //   @override
// // //   void dispose() {
// // //     _msgCtrl.dispose();
// // //     super.dispose();
// // //   }

// // //   String _name(String id) =>
// // //       widget.displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;
// // //     final state = widget.state;
// // //     final game = widget.game;
// // //     final hasVoted = state.voteEntries.containsKey(game.userId);
// // //     final allVoted = state.playerOrder.every(
// // //       (id) => state.voteEntries.containsKey(id),
// // //     );
// // //     final hasReacted = state.reactions.any((r) => r.userId == game.userId);
// // //     final reactionTally = <String, int>{};
// // //     for (final r in state.reactions) {
// // //       reactionTally[r.sticker] = (reactionTally[r.sticker] ?? 0) + 1;
// // //     }

// // //     return PopScope(
// // //       canPop: false,
// // //       onPopInvokedWithResult: (didPop, _) async {
// // //         if (didPop) return;
// // //         await nhieShowLeaveDialog(
// // //           context,
// // //           roomId: widget.roomId,
// // //           isOwners: widget.isOwner,
// // //           displayName:
// // //               widget.displayNames[Supabase
// // //                       .instance
// // //                       .client
// // //                       .auth
// // //                       .currentUser
// // //                       ?.id ??
// // //                   ''] ??
// // //               'A player',
// // //         );
// // //       },
// // //       child: Scaffold(
// // //         resizeToAvoidBottomInset: true,
// // //         appBar: AppBar(
// // //           leading: IconButton(
// // //             icon: const Icon(Icons.arrow_back),
// // //             onPressed: () => nhieShowLeaveDialog(
// // //               context,
// // //               roomId: widget.roomId,
// // //               isOwners: widget.isOwner,
// // //               displayName:
// // //                   widget.displayNames[Supabase
// // //                           .instance
// // //                           .client
// // //                           .auth
// // //                           .currentUser
// // //                           ?.id ??
// // //                       ''] ??
// // //                   'A player',
// // //             ),
// // //           ),
// // //           title: Text('Round ${state.roundNumber} / ${state.maxRounds}'),
// // //           actions: [
// // //             if (state.history.isNotEmpty)
// // //               IconButton(
// // //                 icon: const Icon(Icons.history_rounded),
// // //                 onPressed: () => setState(() => _showHistory = !_showHistory),
// // //               ),
// // //             Padding(
// // //               padding: const EdgeInsets.only(right: 12),
// // //               child: Center(
// // //                 child: Text(
// // //                   '🍹 ${state.scores.values.fold(0, (a, b) => a + b)}',
// // //                   style: theme.textTheme.titleSmall?.copyWith(
// // //                     fontWeight: FontWeight.w700,
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //         body: _showHistory
// // //             ? _HistoryPanel(
// // //                 history: state.history,
// // //                 displayNames: widget.displayNames,
// // //                 onClose: () => setState(() => _showHistory = false),
// // //               )
// // //             : SafeArea(
// // //                 child: Padding(
// // //                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.stretch,
// // //                     children: [
// // //                       // ── Voting progress (NOT a turn — everyone answers every card) ──
// // //                       Text(
// // //                         '${state.votes.length}/${state.playerOrder.length} answered',
// // //                         textAlign: TextAlign.center,
// // //                         style: theme.textTheme.titleSmall?.copyWith(
// // //                           fontWeight: FontWeight.w700,
// // //                           color: theme.colorScheme.primary,
// // //                         ),
// // //                       ),
// // //                       const SizedBox(height: 8),

// // //                       // ── Card with background image ─────────────────────
// // //                       Expanded(
// // //                         child: LayoutBuilder(
// // //                           builder: (context, constraints) {
// // //                             return ClipRRect(
// // //                               borderRadius: BorderRadius.circular(20),
// // //                               child: SizedBox(
// // //                                 width: constraints.maxWidth,
// // //                                 height: constraints.maxHeight,
// // //                                 child: Stack(
// // //                                   fit: StackFit.expand,
// // //                                   children: [
// // //                                     // Background
// // //                                     Positioned.fill(
// // //                                       child:
// // //                                           widget.packCoverUrl != null &&
// // //                                               widget.packCoverUrl!.isNotEmpty
// // //                                           ? Image.network(
// // //                                               widget.packCoverUrl!,
// // //                                               fit: BoxFit.cover,
// // //                                               width: double.infinity,
// // //                                               height: double.infinity,
// // //                                               errorBuilder: (_, __, ___) =>
// // //                                                   Image.asset(
// // //                                                     'assets/images/jma3a_card_background.png',
// // //                                                     fit: BoxFit.cover,
// // //                                                     width: double.infinity,
// // //                                                     height: double.infinity,
// // //                                                   ),
// // //                                             )
// // //                                           : Image.asset(
// // //                                               'assets/images/jma3a_card_background.png',
// // //                                               fit: BoxFit.cover,
// // //                                               width: double.infinity,
// // //                                               height: double.infinity,
// // //                                               errorBuilder: (_, __, ___) =>
// // //                                                   Container(
// // //                                                     color: AppColors.tealGreen,
// // //                                                   ),
// // //                                             ),
// // //                                     ),
// // //                                     // Tint overlay
// // //                                     Positioned.fill(
// // //                                       child: Container(
// // //                                         decoration: BoxDecoration(
// // //                                           gradient: LinearGradient(
// // //                                             colors: [
// // //                                               AppColors.tealGreen.withOpacity(
// // //                                                 0.45,
// // //                                               ),
// // //                                               const Color(
// // //                                                 0xFF0D1B2A,
// // //                                               ).withOpacity(0.65),
// // //                                             ],
// // //                                             begin: Alignment.topCenter,
// // //                                             end: Alignment.bottomCenter,
// // //                                           ),
// // //                                         ),
// // //                                       ),
// // //                                     ),
// // //                                     // Content
// // //                                     Padding(
// // //                                       padding: const EdgeInsets.symmetric(
// // //                                         horizontal: 24,
// // //                                         vertical: 20,
// // //                                       ),
// // //                                       child: Column(
// // //                                         mainAxisAlignment:
// // //                                             MainAxisAlignment.center,
// // //                                         children: [
// // //                                           const Text(
// // //                                             '🍹',
// // //                                             style: TextStyle(fontSize: 56),
// // //                                           ),
// // //                                           const SizedBox(height: 12),
// // //                                           const Text(
// // //                                             'Never Have I Ever…',
// // //                                             style: TextStyle(
// // //                                               color: Colors.white,
// // //                                               fontSize: 18,
// // //                                               fontWeight: FontWeight.w800,
// // //                                               shadows: [
// // //                                                 Shadow(
// // //                                                   color: Colors.black54,
// // //                                                   blurRadius: 6,
// // //                                                 ),
// // //                                               ],
// // //                                             ),
// // //                                           ),
// // //                                           const SizedBox(height: 14),
// // //                                           Text(
// // //                                             state.currentCard?.content ?? '…',
// // //                                             textAlign: TextAlign.center,
// // //                                             style: const TextStyle(
// // //                                               color: Colors.white,
// // //                                               fontSize: 22,
// // //                                               fontWeight: FontWeight.w600,
// // //                                               height: 1.5,
// // //                                               shadows: [
// // //                                                 Shadow(
// // //                                                   color: Colors.black54,
// // //                                                   blurRadius: 8,
// // //                                                 ),
// // //                                               ],
// // //                                             ),
// // //                                           ),
// // //                                         ],
// // //                                       ),
// // //                                     ),
// // //                                   ],
// // //                                 ),
// // //                               ),
// // //                             );
// // //                           },
// // //                         ),
// // //                       ),
// // //                       const SizedBox(height: 12),

// // //                       // ── Vote / waiting / results ─────────────────────────
// // //                       if (!hasVoted && state.isVotingOpen) ...[
// // //                         TextField(
// // //                           controller: _msgCtrl,
// // //                           maxLength: 120,
// // //                           maxLines: 1,
// // //                           textInputAction: TextInputAction.done,
// // //                           onSubmitted: (_) => FocusScope.of(context).unfocus(),
// // //                           decoration: const InputDecoration(
// // //                             hintText: 'Add a comment (optional)…',
// // //                             border: OutlineInputBorder(),
// // //                             isDense: true,
// // //                             counterText: '',
// // //                           ),
// // //                         ),
// // //                         const SizedBox(height: 8),
// // //                         Row(
// // //                           children: [
// // //                             Expanded(
// // //                               child: SizedBox(
// // //                                 height: 50,
// // //                                 child: FilledButton.icon(
// // //                                   onPressed: () => game.vote(
// // //                                     true,
// // //                                     message: _msgCtrl.text.trim(),
// // //                                   ),
// // //                                   icon: const Text('✋'),
// // //                                   label: const Text(
// // //                                     'I HAVE',
// // //                                     style: TextStyle(
// // //                                       fontWeight: FontWeight.w800,
// // //                                     ),
// // //                                   ),
// // //                                   style: FilledButton.styleFrom(
// // //                                     backgroundColor: AppColors.errorRed,
// // //                                   ),
// // //                                 ),
// // //                               ),
// // //                             ),
// // //                             const SizedBox(width: 10),
// // //                             Expanded(
// // //                               child: SizedBox(
// // //                                 height: 50,
// // //                                 child: FilledButton.icon(
// // //                                   onPressed: () => game.vote(
// // //                                     false,
// // //                                     message: _msgCtrl.text.trim(),
// // //                                   ),
// // //                                   icon: const Text('🙅'),
// // //                                   label: const Text(
// // //                                     'NEVER',
// // //                                     style: TextStyle(
// // //                                       fontWeight: FontWeight.w800,
// // //                                     ),
// // //                                   ),
// // //                                   style: FilledButton.styleFrom(
// // //                                     backgroundColor:
// // //                                         theme.colorScheme.secondary,
// // //                                   ),
// // //                                 ),
// // //                               ),
// // //                             ),
// // //                           ],
// // //                         ),
// // //                       ] else if (!allVoted && hasVoted) ...[
// // //                         Container(
// // //                           padding: const EdgeInsets.symmetric(vertical: 12),
// // //                           decoration: BoxDecoration(
// // //                             color: theme.colorScheme.surfaceContainerHighest,
// // //                             borderRadius: BorderRadius.circular(12),
// // //                           ),
// // //                           child: Row(
// // //                             mainAxisAlignment: MainAxisAlignment.center,
// // //                             children: [
// // //                               const SizedBox(
// // //                                 width: 14,
// // //                                 height: 14,
// // //                                 child: CircularProgressIndicator(
// // //                                   strokeWidth: 2,
// // //                                 ),
// // //                               ),
// // //                               const SizedBox(width: 10),
// // //                               Text(
// // //                                 'Waiting… ${state.voteEntries.length}/${state.playerOrder.length}',
// // //                                 style: theme.textTheme.bodyMedium,
// // //                               ),
// // //                             ],
// // //                           ),
// // //                         ),
// // //                       ] else if (allVoted) ...[
// // //                         ...state.voteEntries.entries.map(
// // //                           (e) => Padding(
// // //                             padding: const EdgeInsets.symmetric(vertical: 3),
// // //                             child: Row(
// // //                               crossAxisAlignment: CrossAxisAlignment.start,
// // //                               children: [
// // //                                 Text(
// // //                                   _name(e.key),
// // //                                   style: theme.textTheme.bodyMedium?.copyWith(
// // //                                     fontWeight: FontWeight.w600,
// // //                                     color: e.key == game.userId
// // //                                         ? theme.colorScheme.primary
// // //                                         : null,
// // //                                   ),
// // //                                 ),
// // //                                 const Spacer(),
// // //                                 Column(
// // //                                   crossAxisAlignment: CrossAxisAlignment.end,
// // //                                   children: [
// // //                                     Text(
// // //                                       e.value.haveI ? '✋ I have' : '🙅 Never',
// // //                                       style: theme.textTheme.bodyMedium
// // //                                           ?.copyWith(
// // //                                             fontWeight: FontWeight.w700,
// // //                                             color: e.value.haveI
// // //                                                 ? AppColors.errorRed
// // //                                                 : AppColors.tealGreen,
// // //                                           ),
// // //                                     ),
// // //                                     if (e.value.message.isNotEmpty)
// // //                                       Text(
// // //                                         '"${e.value.message}"',
// // //                                         style: theme.textTheme.bodySmall
// // //                                             ?.copyWith(
// // //                                               fontStyle: FontStyle.italic,
// // //                                               color: theme
// // //                                                   .colorScheme
// // //                                                   .onSurfaceVariant,
// // //                                             ),
// // //                                       ),
// // //                                   ],
// // //                                 ),
// // //                               ],
// // //                             ),
// // //                           ),
// // //                         ),
// // //                         const SizedBox(height: 8),
// // //                         if (game.isOwner)
// // //                           SizedBox(
// // //                             height: 46,
// // //                             child: FilledButton(
// // //                               onPressed: game.ownerAdvanceTurn,
// // //                               child: const Text('Next Card →'),
// // //                             ),
// // //                           )
// // //                         else
// // //                           Text(
// // //                             'Waiting for host…',
// // //                             textAlign: TextAlign.center,
// // //                             style: theme.textTheme.bodySmall?.copyWith(
// // //                               color: theme.colorScheme.onSurfaceVariant,
// // //                             ),
// // //                           ),
// // //                       ],

// // //                       // ── Reactions — pinned to bottom ─────────────────────
// // //                       const SizedBox(height: 8),
// // //                       if (reactionTally.isNotEmpty)
// // //                         Padding(
// // //                           padding: const EdgeInsets.only(bottom: 4),
// // //                           child: Wrap(
// // //                             spacing: 6,
// // //                             runSpacing: 4,
// // //                             children: reactionTally.entries
// // //                                 .map(
// // //                                   (e) => Container(
// // //                                     padding: const EdgeInsets.symmetric(
// // //                                       horizontal: 8,
// // //                                       vertical: 3,
// // //                                     ),
// // //                                     decoration: BoxDecoration(
// // //                                       color: theme
// // //                                           .colorScheme
// // //                                           .surfaceContainerHighest,
// // //                                       borderRadius: BorderRadius.circular(20),
// // //                                     ),
// // //                                     child: Text(
// // //                                       '${e.key} ${e.value}',
// // //                                       style: const TextStyle(fontSize: 13),
// // //                                     ),
// // //                                   ),
// // //                                 )
// // //                                 .toList(),
// // //                           ),
// // //                         ),
// // //                       EmojiReactionRow(
// // //                         reactionsByEmoji: const {},
// // //                         alreadyReacted: hasReacted,
// // //                         onReact: game.sendReaction,
// // //                       ),
// // //                       const SizedBox(height: 8),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ── History panel ─────────────────────────────────────────────────────────────

// // // class _HistoryPanel extends StatelessWidget {
// // //   const _HistoryPanel({
// // //     required this.history,
// // //     required this.displayNames,
// // //     required this.onClose,
// // //   });
// // //   final List<NhieRoundRecord> history;
// // //   final Map<String, String> displayNames;
// // //   final VoidCallback onClose;

// // //   String _name(String id) =>
// // //       displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = context.theme;
// // //     return Column(
// // //       children: [
// // //         ListTile(
// // //           leading: const Icon(Icons.history_rounded),
// // //           title: Text(
// // //             'History (${history.length} rounds)',
// // //             style: theme.textTheme.titleMedium?.copyWith(
// // //               fontWeight: FontWeight.w700,
// // //             ),
// // //           ),
// // //           trailing: IconButton(
// // //             icon: const Icon(Icons.close),
// // //             onPressed: onClose,
// // //           ),
// // //         ),
// // //         const Divider(height: 0),
// // //         Expanded(
// // //           child: ListView.builder(
// // //             padding: const EdgeInsets.all(12),
// // //             itemCount: history.length,
// // //             itemBuilder: (_, i) {
// // //               final round = history[history.length - 1 - i];
// // //               final haves = round.votes.values.where((v) => v.haveI).length;
// // //               final nevers = round.votes.values.where((v) => !v.haveI).length;
// // //               // Reaction tally
// // //               final rt = <String, int>{};
// // //               for (final r in round.reactions)
// // //                 rt[r.sticker] = (rt[r.sticker] ?? 0) + 1;
// // //               return Card(
// // //                 margin: const EdgeInsets.only(bottom: 10),
// // //                 child: ExpansionTile(
// // //                   leading: CircleAvatar(
// // //                     backgroundColor: theme.colorScheme.primaryContainer,
// // //                     child: Text(
// // //                       '${round.roundNumber}',
// // //                       style: theme.textTheme.labelLarge,
// // //                     ),
// // //                   ),
// // //                   title: Text(
// // //                     round.card.content,
// // //                     style: theme.textTheme.bodyMedium?.copyWith(
// // //                       fontWeight: FontWeight.w600,
// // //                     ),
// // //                     maxLines: 2,
// // //                     overflow: TextOverflow.ellipsis,
// // //                   ),
// // //                   subtitle: Text(
// // //                     '✋ $haves  •  🙅 $nevers  ${rt.isNotEmpty ? '• ' + rt.entries.map((e) => '${e.key}${e.value}').join(' ') : ''}',
// // //                     style: theme.textTheme.bodySmall,
// // //                   ),
// // //                   children: [
// // //                     Padding(
// // //                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
// // //                       child: Column(
// // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // //                         children: round.votes.entries
// // //                             .map(
// // //                               (e) => Padding(
// // //                                 padding: const EdgeInsets.symmetric(
// // //                                   vertical: 3,
// // //                                 ),
// // //                                 child: Row(
// // //                                   children: [
// // //                                     Text(
// // //                                       _name(e.key),
// // //                                       style: theme.textTheme.bodySmall
// // //                                           ?.copyWith(
// // //                                             fontWeight: FontWeight.w600,
// // //                                           ),
// // //                                     ),
// // //                                     const SizedBox(width: 6),
// // //                                     Text(e.value.haveI ? '✋' : '🙅'),
// // //                                     if (e.value.message.isNotEmpty) ...[
// // //                                       const SizedBox(width: 4),
// // //                                       Expanded(
// // //                                         child: Text(
// // //                                           '"${e.value.message}"',
// // //                                           style: theme.textTheme.bodySmall
// // //                                               ?.copyWith(
// // //                                                 fontStyle: FontStyle.italic,
// // //                                                 color: theme
// // //                                                     .colorScheme
// // //                                                     .onSurfaceVariant,
// // //                                               ),
// // //                                           overflow: TextOverflow.ellipsis,
// // //                                         ),
// // //                                       ),
// // //                                     ],
// // //                                   ],
// // //                                 ),
// // //                               ),
// // //                             )
// // //                             .toList(),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               );
// // //             },
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // }

// // // // ── Game over ─────────────────────────────────────────────────────────────────

// // // class _GameOverScreen extends StatefulWidget {
// // //   const _GameOverScreen({required this.game, required this.displayNames});
// // //   final NhieGameProvider game;
// // //   final Map<String, String> displayNames;
// // //   @override
// // //   State<_GameOverScreen> createState() => _GameOverScreenState();
// // // }

// // // class _GameOverScreenState extends State<_GameOverScreen> {
// // //   bool _showHistory = false;
// // //   String _name(String id) =>
// // //       widget.displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final scores = widget.game.state?.scores ?? {};
// // //     final history = widget.game.state?.history ?? [];
// // //     final sorted = scores.entries.toList()
// // //       ..sort((a, b) => b.value.compareTo(a.value));
// // //     const medals = ['🥇', '🥈', '🥉'];

// // //     if (_showHistory)
// // //       return Scaffold(
// // //         appBar: AppBar(
// // //           title: const Text('Game History'),
// // //           leading: BackButton(
// // //             onPressed: () => setState(() => _showHistory = false),
// // //           ),
// // //         ),
// // //         body: _HistoryPanel(
// // //           history: history,
// // //           displayNames: widget.displayNames,
// // //           onClose: () => setState(() => _showHistory = false),
// // //         ),
// // //       );

// // //     return Scaffold(
// // //       body: SafeArea(
// // //         child: Padding(
// // //           padding: const EdgeInsets.all(24),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.stretch,
// // //             children: [
// // //               const Text(
// // //                 '🏆',
// // //                 textAlign: TextAlign.center,
// // //                 style: TextStyle(fontSize: 72),
// // //               ),
// // //               Text(
// // //                 'Game Over!',
// // //                 textAlign: TextAlign.center,
// // //                 style: context.textTheme.headlineMedium?.copyWith(
// // //                   fontWeight: FontWeight.w800,
// // //                 ),
// // //               ),
// // //               Text(
// // //                 'Most 🍹 drinks wins!',
// // //                 textAlign: TextAlign.center,
// // //                 style: context.textTheme.bodyLarge?.copyWith(
// // //                   color: context.colorScheme.onSurfaceVariant,
// // //                 ),
// // //               ),
// // //               const SizedBox(height: 20),
// // //               Expanded(
// // //                 child: ListView.builder(
// // //                   itemCount: sorted.length,
// // //                   itemBuilder: (_, i) {
// // //                     final e = sorted[i];
// // //                     return ListTile(
// // //                       leading: Text(
// // //                         i < medals.length ? medals[i] : '${i + 1}.',
// // //                         style: const TextStyle(fontSize: 24),
// // //                       ),
// // //                       title: Text(
// // //                         _name(e.key),
// // //                         style: context.textTheme.titleMedium?.copyWith(
// // //                           fontWeight: FontWeight.w700,
// // //                         ),
// // //                       ),
// // //                       trailing: Text(
// // //                         '${e.value} 🍹',
// // //                         style: context.textTheme.titleMedium?.copyWith(
// // //                           color: AppColors.errorRed,
// // //                           fontWeight: FontWeight.w700,
// // //                         ),
// // //                       ),
// // //                     );
// // //                   },
// // //                 ),
// // //               ),
// // //               if (history.isNotEmpty) ...[
// // //                 OutlinedButton.icon(
// // //                   onPressed: () => setState(() => _showHistory = true),
// // //                   icon: const Icon(Icons.history_rounded),
// // //                   label: Text('View History (${history.length} rounds)'),
// // //                 ),
// // //                 const SizedBox(height: 10),
// // //               ],
// // //               SizedBox(
// // //                 height: 52,
// // //                 child: FilledButton(
// // //                   onPressed: () => context.go(RouteNames.home),
// // //                   child: const Text('Back to Home'),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ── Paused overlay ────────────────────────────────────────────────────────────
// // // class _MemeNhiePausedOverlay extends StatefulWidget {
// // //   const _MemeNhiePausedOverlay({required this.onLeave});
// // //   final VoidCallback onLeave;
// // //   @override
// // //   State<_MemeNhiePausedOverlay> createState() => _MemeNhiePausedOverlayState();
// // // }

// // // class _MemeNhiePausedOverlayState extends State<_MemeNhiePausedOverlay>
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
// // //   Widget build(BuildContext context) => Dialog.fullscreen(
// // //     backgroundColor: Colors.transparent,
// // //     child: Scaffold(
// // //       backgroundColor: Colors.transparent,
// // //       body: Center(
// // //         child: Padding(
// // //           padding: const EdgeInsets.all(32),
// // //           child: Column(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               AnimatedBuilder(
// // //                 animation: _pulse,
// // //                 builder: (_, child) =>
// // //                     Opacity(opacity: 0.6 + _pulse.value * 0.4, child: child),
// // //                 child: const Text('⏸', style: TextStyle(fontSize: 72)),
// // //               ),
// // //               const SizedBox(height: 24),
// // //               const Text(
// // //                 'Game Paused',
// // //                 style: TextStyle(
// // //                   color: Colors.white,
// // //                   fontSize: 28,
// // //                   fontWeight: FontWeight.w800,
// // //                 ),
// // //               ),
// // //               const SizedBox(height: 12),
// // //               const Text(
// // //                 'The host stepped away and will\nreturn shortly.',
// // //                 textAlign: TextAlign.center,
// // //                 style: TextStyle(
// // //                   color: Colors.white70,
// // //                   fontSize: 16,
// // //                   height: 1.5,
// // //                 ),
// // //               ),
// // //               const SizedBox(height: 40),
// // //               OutlinedButton(
// // //                 style: OutlinedButton.styleFrom(
// // //                   foregroundColor: Colors.white,
// // //                   side: const BorderSide(color: Colors.white38),
// // //                   padding: const EdgeInsets.symmetric(
// // //                     horizontal: 32,
// // //                     vertical: 14,
// // //                   ),
// // //                 ),
// // //                 onPressed: widget.onLeave,
// // //                 child: const Text('Leave for Now'),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     ),
// // //   );
// // // }

// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:jma3a/Sticker.dart';
// // import 'package:jma3a/core/router/app_router.dart';
// // import 'package:jma3a/features/games/engine/base_game_engine.dart';
// // import 'package:jma3a/features/games/never_have_i_ever/never_have_i_ever_engine.dart';
// // import 'package:jma3a/features/games/truth_or_dare/data/tod_repository.dart';
// // import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
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

// // // ── Provider ──────────────────────────────────────────────────────────────────

// // enum NhieLoadState { idle, loading, ready, error, gameOver }

// // class NhieGameProvider extends ChangeNotifier {
// //   NhieGameProvider({
// //     required RealtimeService realtimeService,
// //     required String userId,
// //     required String displayName,
// //   }) : _realtime = realtimeService,
// //        _userId = userId,
// //        _displayName = displayName;

// //   final RealtimeService _realtime;
// //   final String _userId, _displayName;
// //   NeverHaveIEverEngine? _engine;
// //   NhieLoadState _loadState = NhieLoadState.idle;
// //   String? _roomId;
// //   String? _sessionId;
// //   bool _isOwner = false;
// //   String _error = '';
// //   // Away player tracking — auto-submits a neutral "have I" vote for away
// //   // players so the round isn't stuck waiting for someone who left.
// //   final Set<String> _awayPlayerIds = {};

// //   NhieLoadState get loadState => _loadState;
// //   NhieState? get state => _engine?.currentState as NhieState?;
// //   String get userId => _userId;
// //   bool get isOwner => _isOwner;

// //   bool get allPlayersVoted {
// //     final s = state;
// //     if (s == null) return true;
// //     return s.votes.length >= s.playerOrder.length;
// //   }

// //   int get votedCount => state?.votes.length ?? 0;
// //   int get playerCount => state?.playerOrder.length ?? 1;
// //   String get error => _error;
// //   Set<String> get awayPlayerIds => _awayPlayerIds;

// //   void markPlayerAway(String userId, {bool forGood = false}) {
// //     _awayPlayerIds.add(userId);
// //     // Auto-submit a neutral vote for this player so the round isn't
// //     // stuck waiting for them. Only the owner does this to avoid
// //     // duplicate events.
// //     if (_isOwner && _engine != null) {
// //       final s = _engine!.currentState as NhieState?;
// //       if (s != null && s.isVotingOpen && !s.voteEntries.containsKey(userId)) {
// //         _engine!.handleEvent(
// //           NhieVoteEvent(
// //             userId: userId,
// //             ts: DateTime.now().millisecondsSinceEpoch,
// //             haveI: false, // neutral — absent player counts as "have not"
// //           ),
// //         );
// //         notifyListeners();
// //         _broadcastState();
// //       }
// //     }
// //     notifyListeners();
// //   }

// //   void markPlayerReturned(String userId) {
// //     _awayPlayerIds.remove(userId);
// //     notifyListeners();
// //   }

// //   Future<void> initAsOwner({
// //     required String roomId,
// //     required String packId,
// //     required List<String> playerIds,
// //     required Map<String, String> displayNames,
// //     required GameConfig config,
// //   }) async {
// //     _roomId = roomId;
// //     _isOwner = true;
// //     _loadState = NhieLoadState.loading;
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
// //       final cards = todCards.map((c) {
// //         var t = c.content;
// //         for (final p in ['Never have I ever ', 'never have I ever ']) {
// //           if (t.startsWith(p)) {
// //             t = t.substring(p.length);
// //             break;
// //           }
// //         }
// //         if (t.isNotEmpty) t = t[0].toUpperCase() + t.substring(1);
// //         return NhieCard(id: c.id, content: t, difficulty: c.difficulty.name);
// //       }).toList();
// //       _engine = NeverHaveIEverEngine(config, cards: cards);

// //       // ✅ Resume an existing in-progress session if one exists, instead of
// //       // always creating a brand-new one — same fix as ToD/meme.
// //       final existing = await Supabase.instance.client
// //           .from('game_sessions')
// //           .select('id, state_snapshot, game_type')
// //           .eq('room_id', roomId)
// //           .eq('status', 'active')
// //           .order('started_at', ascending: false)
// //           .limit(1)
// //           .maybeSingle();
// //       // Only restore snapshots from the same game type — a meme or ToD
// //       // session snapshot will have incompatible structure and cause cast errors.
// //       final snapshotGameType = existing?['game_type'] as String?;
// //       Map<String, dynamic>? existingSnapshot;
// //       if (snapshotGameType == 'never_have_i_ever') {
// //         existingSnapshot = existing?['state_snapshot'] as Map<String, dynamic>?;
// //       }

// //       if (existing != null &&
// //           existingSnapshot != null &&
// //           existingSnapshot.isNotEmpty) {
// //         // Sanitize scores — Supabase JSONB may return nested maps for int
// //         // values if the snapshot was written with wrong types. Force-flatten.
// //         final raw = existingSnapshot;
// //         if (raw['scores'] is Map) {
// //           raw['scores'] = (raw['scores'] as Map).map(
// //             (k, v) => MapEntry(k as String, v is num ? v.toInt() : 0),
// //           );
// //         }
// //         _sessionId = existing['id'] as String;
// //         _engine!.restoreFromSnapshot(raw);
// //         AppLogger.info('NhieProvider: resumed existing session $_sessionId');
// //       } else {
// //         _engine!.init(playerIds);
// //         try {
// //           final inserted = await Supabase.instance.client
// //               .from('game_sessions')
// //               .insert({
// //                 'room_id': roomId,
// //                 'pack_id': packId,
// //                 'game_type': 'never_have_i_ever',
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
// //           AppLogger.warning('NhieProvider: failed to create session: $e');
// //         }
// //       }

// //       _loadState = NhieLoadState.ready;
// //       notifyListeners();
// //       _broadcastState();
// //     } catch (e) {
// //       _error = e.toString();
// //       _loadState = NhieLoadState.error;
// //       AppLogger.error('NhieProvider: init failed', error: e);
// //       notifyListeners();
// //     }
// //   }

// //   void initAsFollower(String roomId) {
// //     _roomId = roomId;
// //     _isOwner = false;
// //     _loadState = NhieLoadState.loading;
// //     notifyListeners();
// //   }

// //   Future<void> vote(bool haveI, {String message = ''}) => _handleAction({
// //     'action': 'nhie_vote',
// //     'have_i': haveI,
// //     'message': message,
// //   });
// //   Future<void> sendReaction(String emoji) =>
// //       _handleAction({'action': 'nhie_reaction', 'sticker': emoji});
// //   Future<void> ownerAdvanceTurn() async {
// //     if (!_isOwner || _engine == null) return;
// //     _engine!.advanceTurn();
// //     if (_engine!.isGameOver) _loadState = NhieLoadState.gameOver;
// //     notifyListeners();
// //     _broadcastState();
// //   }

// //   void onStateBroadcast(Map<String, dynamic> payload) {
// //     if (_isOwner) return;
// //     try {
// //       final snap =
// //           (payload['snapshot'] as Map<String, dynamic>?)?['state']
// //               as Map<String, dynamic>? ??
// //           payload['state'] as Map<String, dynamic>?;
// //       if (snap == null) return;
// //       _engine ??= NeverHaveIEverEngine(
// //         const GameConfig(
// //           maxRounds: 10,
// //           turnTimerSeconds: 60,
// //           allowSkip: false,
// //           allowSpicy: false,
// //         ),
// //         cards: [],
// //       );
// //       _engine!.restoreFromSnapshot(snap);
// //       _loadState = _engine!.isGameOver
// //           ? NhieLoadState.gameOver
// //           : NhieLoadState.ready;
// //       notifyListeners();
// //     } catch (e) {
// //       AppLogger.warning('NhieProvider: restore failed: $e');
// //     }
// //   }

// //   void onPlayerAction(Map<String, dynamic> payload) {
// //     if (!_isOwner || _engine == null) return;
// //     final action = payload['action'] as String?;
// //     final uid = payload['user_id'] as String?;
// //     final ts = payload['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
// //     if (uid == null) return;
// //     if (action == 'nhie_vote') {
// //       _engine!.handleEvent(
// //         NhieVoteEvent(
// //           userId: uid,
// //           ts: ts,
// //           haveI: payload['have_i'] as bool? ?? false,
// //           message: payload['message'] as String? ?? '',
// //         ),
// //       );
// //     } else if (action == 'nhie_reaction') {
// //       _engine!.handleEvent(
// //         NhieReactionEvent(
// //           userId: uid,
// //           ts: ts,
// //           sticker: payload['sticker'] as String? ?? '😂',
// //         ),
// //       );
// //     }
// //     if (_engine!.isGameOver) _loadState = NhieLoadState.gameOver;
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
// //               AppLogger.warning('NhieProvider: snapshot save failed: $e');
// //             },
// //           );
// //     }
// //   }
// // }

// // // ── Confirm leave dialog ──────────────────────────────────────────────────────

// // Future<void> nhieShowLeaveDialog(
// //   BuildContext ctx, {
// //   required String roomId,
// //   required bool isOwners,
// //   String displayName = 'A player',
// // }) async {
// //   if (!ctx.mounted) return;
// //   final isOwner = isOwners;
// //   final myUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
// //   final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

// //   if (isOwner) {
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

// // // ── Screen ────────────────────────────────────────────────────────────────────

// // class NhieGameScreen extends StatefulWidget {
// //   const NhieGameScreen({
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
// //   State<NhieGameScreen> createState() => _NhieGameScreenState();
// // }

// // class _NhieGameScreenState extends State<NhieGameScreen> {
// //   late final NhieGameProvider _provider;

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
// //     _provider = NhieGameProvider(
// //       realtimeService: sl.realtimeService,
// //       userId: user.id,
// //       displayName: user.displayName ?? user.username ?? 'Player',
// //     );
// //     // Update callbacks on existing channel (no teardown needed)
// //     sl.realtimeService.subscribe(
// //       roomId: widget.roomId,
// //       onGameState: (p) => _provider.onStateBroadcast(p),
// //       onPlayerAction: (p) => _provider.onPlayerAction(p),
// //       onSyncRequest: (p) => _provider.onSyncRequest(p),
// //       onGameStarted: (_) {},
// //       onGameEnded: (p) {
// //         if (mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             const SnackBar(content: Text('The host ended the game')),
// //           );
// //           if (context.canPop())
// //             context.pop();
// //           else
// //             context.go(RouteNames.home);
// //         }
// //       },
// //       onRoomEvent: (p) {
// //         final evType = p['type'] as String?;
// //         if (evType == 'screenshot_taken') {
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
// //         if (evType == 'game_ended' && mounted) {
// //           if ((p['reason'] as String?) == 'host_quit_to_lobby') {
// //             WidgetsBinding.instance.addPostFrameCallback((_) {
// //               if (!mounted) return;
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
// //         if (evType == 'player_left' && mounted) {
// //           final name = p['display_name'] as String? ?? 'A player';
// //           final forGood = p['for_good'] as bool? ?? true;
// //           final leavingId = p['user_id'] as String?;
// //           final returnMins = p['return_mins'] as int?;
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
// //         if (evType == 'ownership_transferred' && mounted) {
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
// //         if ((p['type'] as String?) == 'game_paused' && mounted) {
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
// //         if (((p['type'] as String?) == 'room_closed' ||
// //             (p['type'] as String?) == 'owner_left')) {
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
// //     // Send sync request after short delay so owner's response arrives on active channel
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
// //     // Send immediately, then retry after 1s and 3s in case owner missed it
// //     sl.realtimeService
// //         .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
// //         .ignore();
// //     Future.delayed(const Duration(seconds: 1), () {
// //       if (mounted && _provider.loadState == NhieLoadState.loading) {
// //         sl.realtimeService
// //             .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
// //             .ignore();
// //       }
// //     });
// //     Future.delayed(const Duration(seconds: 3), () {
// //       if (mounted && _provider.loadState == NhieLoadState.loading) {
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
// //     return ChangeNotifierProvider.value(
// //       value: _provider,
// //       child: Consumer<NhieGameProvider>(
// //         builder: (ctx, game, _) {
// //           if (game.loadState == NhieLoadState.loading)
// //             return const Scaffold(
// //               body: Center(child: CircularProgressIndicator()),
// //             );
// //           if (game.loadState == NhieLoadState.error)
// //             return Scaffold(
// //               body: Center(
// //                 child: Padding(
// //                   padding: const EdgeInsets.all(24),
// //                   child: Text(
// //                     'Error: ${game.error}',
// //                     textAlign: TextAlign.center,
// //                   ),
// //                 ),
// //               ),
// //             );
// //           if (game.loadState == NhieLoadState.gameOver)
// //             return _GameOverScreen(
// //               game: game,
// //               displayNames: widget.playerDisplayNames,
// //             );
// //           final state = game.state;
// //           if (state == null)
// //             return const Scaffold(
// //               body: Center(child: CircularProgressIndicator()),
// //             );
// //           return _GameBody(
// //             game: game,
// //             state: state,
// //             displayNames: widget.playerDisplayNames,
// //             packCoverUrl: widget.packCoverUrl,
// //             roomId: widget.roomId,
// //             isOwner: widget.isOwner,
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }

// // // ── Game body ─────────────────────────────────────────────────────────────────

// // class _GameBody extends StatefulWidget {
// //   const _GameBody({
// //     required this.game,
// //     required this.state,
// //     required this.displayNames,
// //     this.packCoverUrl,
// //     required this.roomId,
// //     required this.isOwner,
// //   });
// //   final NhieGameProvider game;
// //   final NhieState state;
// //   final Map<String, String> displayNames;
// //   final String? packCoverUrl;
// //   final String roomId;
// //   final bool isOwner;
// //   @override
// //   State<_GameBody> createState() => _GameBodyState();
// // }

// // class _GameBodyState extends State<_GameBody> {
// //   final _msgCtrl = TextEditingController();
// //   bool _showHistory = false;

// //   @override
// //   void dispose() {
// //     _msgCtrl.dispose();
// //     super.dispose();
// //   }

// //   String _name(String id) =>
// //       widget.displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = context.theme;
// //     final state = widget.state;
// //     final game = widget.game;
// //     final hasVoted = state.voteEntries.containsKey(game.userId);
// //     final allVoted = state.playerOrder.every(
// //       (id) => state.voteEntries.containsKey(id),
// //     );
// //     final hasReacted = state.reactions.any((r) => r.userId == game.userId);
// //     final reactionTally = <String, int>{};
// //     for (final r in state.reactions) {
// //       reactionTally[r.sticker] = (reactionTally[r.sticker] ?? 0) + 1;
// //     }

// //     return PopScope(
// //       canPop: false,
// //       onPopInvokedWithResult: (didPop, _) async {
// //         if (didPop) return;
// //         await nhieShowLeaveDialog(
// //           context,
// //           roomId: widget.roomId,
// //           isOwners: widget.isOwner,
// //           displayName:
// //               widget.displayNames[Supabase
// //                       .instance
// //                       .client
// //                       .auth
// //                       .currentUser
// //                       ?.id ??
// //                   ''] ??
// //               'A player',
// //         );
// //       },
// //       child: Scaffold(
// //         resizeToAvoidBottomInset: true,
// //         appBar: AppBar(
// //           leading: IconButton(
// //             icon: const Icon(Icons.arrow_back),
// //             onPressed: () => nhieShowLeaveDialog(
// //               context,
// //               roomId: widget.roomId,
// //               isOwners: widget.isOwner,
// //               displayName:
// //                   widget.displayNames[Supabase
// //                           .instance
// //                           .client
// //                           .auth
// //                           .currentUser
// //                           ?.id ??
// //                       ''] ??
// //                   'A player',
// //             ),
// //           ),
// //           title: Text('Round ${state.roundNumber} / ${state.maxRounds}'),
// //           actions: [
// //             if (state.history.isNotEmpty)
// //               IconButton(
// //                 icon: const Icon(Icons.history_rounded),
// //                 onPressed: () => setState(() => _showHistory = !_showHistory),
// //               ),
// //             Padding(
// //               padding: const EdgeInsets.only(right: 12),
// //               child: Center(
// //                 child: Text(
// //                   '🍹 ${state.scores.values.fold(0, (a, b) => a + b)}',
// //                   style: theme.textTheme.titleSmall?.copyWith(
// //                     fontWeight: FontWeight.w700,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //         body: _showHistory
// //             ? _HistoryPanel(
// //                 history: state.history,
// //                 displayNames: widget.displayNames,
// //                 onClose: () => setState(() => _showHistory = false),
// //               )
// //             : SafeArea(
// //                 child: Padding(
// //                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.stretch,
// //                     children: [
// //                       // ── Voting progress (NOT a turn — everyone answers every card) ──
// //                       Text(
// //                         '${state.votes.length}/${state.playerOrder.length} answered',
// //                         textAlign: TextAlign.center,
// //                         style: theme.textTheme.titleSmall?.copyWith(
// //                           fontWeight: FontWeight.w700,
// //                           color: theme.colorScheme.primary,
// //                         ),
// //                       ),
// //                       const SizedBox(height: 8),

// //                       // ── Card with background image ─────────────────────
// //                       Expanded(
// //                         child: LayoutBuilder(
// //                           builder: (context, constraints) {
// //                             return ClipRRect(
// //                               borderRadius: BorderRadius.circular(20),
// //                               child: SizedBox(
// //                                 width: constraints.maxWidth,
// //                                 height: constraints.maxHeight,
// //                                 child: Stack(
// //                                   fit: StackFit.expand,
// //                                   children: [
// //                                     // Background
// //                                     Positioned.fill(
// //                                       child:
// //                                           widget.packCoverUrl != null &&
// //                                               widget.packCoverUrl!.isNotEmpty
// //                                           ? Image.network(
// //                                               widget.packCoverUrl!,
// //                                               fit: BoxFit.cover,
// //                                               width: double.infinity,
// //                                               height: double.infinity,
// //                                               errorBuilder: (_, __, ___) =>
// //                                                   Image.asset(
// //                                                     'assets/images/jma3a_card_background.png',
// //                                                     fit: BoxFit.cover,
// //                                                     width: double.infinity,
// //                                                     height: double.infinity,
// //                                                   ),
// //                                             )
// //                                           : Image.asset(
// //                                               'assets/images/jma3a_card_background.png',
// //                                               fit: BoxFit.cover,
// //                                               width: double.infinity,
// //                                               height: double.infinity,
// //                                               errorBuilder: (_, __, ___) =>
// //                                                   Container(
// //                                                     color: AppColors.tealGreen,
// //                                                   ),
// //                                             ),
// //                                     ),
// //                                     // Tint overlay
// //                                     Positioned.fill(
// //                                       child: Container(
// //                                         decoration: BoxDecoration(
// //                                           gradient: LinearGradient(
// //                                             colors: [
// //                                               AppColors.tealGreen.withOpacity(
// //                                                 0.45,
// //                                               ),
// //                                               const Color(
// //                                                 0xFF0D1B2A,
// //                                               ).withOpacity(0.65),
// //                                             ],
// //                                             begin: Alignment.topCenter,
// //                                             end: Alignment.bottomCenter,
// //                                           ),
// //                                         ),
// //                                       ),
// //                                     ),
// //                                     // Content
// //                                     Padding(
// //                                       padding: const EdgeInsets.symmetric(
// //                                         horizontal: 24,
// //                                         vertical: 20,
// //                                       ),
// //                                       child: Column(
// //                                         mainAxisAlignment:
// //                                             MainAxisAlignment.center,
// //                                         children: [
// //                                           const Text(
// //                                             '🍹',
// //                                             style: TextStyle(fontSize: 56),
// //                                           ),
// //                                           const SizedBox(height: 12),
// //                                           const Text(
// //                                             'Never Have I Ever…',
// //                                             style: TextStyle(
// //                                               color: Colors.white,
// //                                               fontSize: 18,
// //                                               fontWeight: FontWeight.w800,
// //                                               shadows: [
// //                                                 Shadow(
// //                                                   color: Colors.black54,
// //                                                   blurRadius: 6,
// //                                                 ),
// //                                               ],
// //                                             ),
// //                                           ),
// //                                           const SizedBox(height: 14),
// //                                           Text(
// //                                             state.currentCard?.content ?? '…',
// //                                             textAlign: TextAlign.center,
// //                                             style: const TextStyle(
// //                                               color: Colors.white,
// //                                               fontSize: 22,
// //                                               fontWeight: FontWeight.w600,
// //                                               height: 1.5,
// //                                               shadows: [
// //                                                 Shadow(
// //                                                   color: Colors.black54,
// //                                                   blurRadius: 8,
// //                                                 ),
// //                                               ],
// //                                             ),
// //                                           ),
// //                                         ],
// //                                       ),
// //                                     ),
// //                                   ],
// //                                 ),
// //                               ),
// //                             );
// //                           },
// //                         ),
// //                       ),
// //                       const SizedBox(height: 12),

// //                       // ── Vote / waiting / results ─────────────────────────
// //                       if (!hasVoted && state.isVotingOpen) ...[
// //                         TextField(
// //                           controller: _msgCtrl,
// //                           maxLength: 120,
// //                           maxLines: 1,
// //                           textInputAction: TextInputAction.done,
// //                           onSubmitted: (_) => FocusScope.of(context).unfocus(),
// //                           decoration: const InputDecoration(
// //                             hintText: 'Add a comment (optional)…',
// //                             border: OutlineInputBorder(),
// //                             isDense: true,
// //                             counterText: '',
// //                           ),
// //                         ),
// //                         const SizedBox(height: 8),
// //                         Row(
// //                           children: [
// //                             Expanded(
// //                               child: SizedBox(
// //                                 height: 50,
// //                                 child: FilledButton.icon(
// //                                   onPressed: () => game.vote(
// //                                     true,
// //                                     message: _msgCtrl.text.trim(),
// //                                   ),
// //                                   icon: const Text('✋'),
// //                                   label: const Text(
// //                                     'I HAVE',
// //                                     style: TextStyle(
// //                                       fontWeight: FontWeight.w800,
// //                                     ),
// //                                   ),
// //                                   style: FilledButton.styleFrom(
// //                                     backgroundColor: AppColors.errorRed,
// //                                   ),
// //                                 ),
// //                               ),
// //                             ),
// //                             const SizedBox(width: 10),
// //                             Expanded(
// //                               child: SizedBox(
// //                                 height: 50,
// //                                 child: FilledButton.icon(
// //                                   onPressed: () => game.vote(
// //                                     false,
// //                                     message: _msgCtrl.text.trim(),
// //                                   ),
// //                                   icon: const Text('🙅'),
// //                                   label: const Text(
// //                                     'NEVER',
// //                                     style: TextStyle(
// //                                       fontWeight: FontWeight.w800,
// //                                     ),
// //                                   ),
// //                                   style: FilledButton.styleFrom(
// //                                     backgroundColor:
// //                                         theme.colorScheme.secondary,
// //                                   ),
// //                                 ),
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ] else if (!allVoted && hasVoted) ...[
// //                         Container(
// //                           padding: const EdgeInsets.symmetric(vertical: 12),
// //                           decoration: BoxDecoration(
// //                             color: theme.colorScheme.surfaceContainerHighest,
// //                             borderRadius: BorderRadius.circular(12),
// //                           ),
// //                           child: Row(
// //                             mainAxisAlignment: MainAxisAlignment.center,
// //                             children: [
// //                               const SizedBox(
// //                                 width: 14,
// //                                 height: 14,
// //                                 child: CircularProgressIndicator(
// //                                   strokeWidth: 2,
// //                                 ),
// //                               ),
// //                               const SizedBox(width: 10),
// //                               Text(
// //                                 'Waiting… ${state.voteEntries.length}/${state.playerOrder.length}',
// //                                 style: theme.textTheme.bodyMedium,
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ] else if (allVoted) ...[
// //                         ...state.voteEntries.entries.map(
// //                           (e) => Padding(
// //                             padding: const EdgeInsets.symmetric(vertical: 3),
// //                             child: Row(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 Text(
// //                                   _name(e.key),
// //                                   style: theme.textTheme.bodyMedium?.copyWith(
// //                                     fontWeight: FontWeight.w600,
// //                                     color: e.key == game.userId
// //                                         ? theme.colorScheme.primary
// //                                         : null,
// //                                   ),
// //                                 ),
// //                                 const Spacer(),
// //                                 Column(
// //                                   crossAxisAlignment: CrossAxisAlignment.end,
// //                                   children: [
// //                                     Text(
// //                                       e.value.haveI ? '✋ I have' : '🙅 Never',
// //                                       style: theme.textTheme.bodyMedium
// //                                           ?.copyWith(
// //                                             fontWeight: FontWeight.w700,
// //                                             color: e.value.haveI
// //                                                 ? AppColors.errorRed
// //                                                 : AppColors.tealGreen,
// //                                           ),
// //                                     ),
// //                                     if (e.value.message.isNotEmpty)
// //                                       Text(
// //                                         '"${e.value.message}"',
// //                                         style: theme.textTheme.bodySmall
// //                                             ?.copyWith(
// //                                               fontStyle: FontStyle.italic,
// //                                               color: theme
// //                                                   .colorScheme
// //                                                   .onSurfaceVariant,
// //                                             ),
// //                                       ),
// //                                   ],
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                         ),
// //                         const SizedBox(height: 8),
// //                         if (game.isOwner) ...[
// //                           if (!game.allPlayersVoted)
// //                             Text(
// //                               '${game.votedCount}/${game.playerCount} answered',
// //                               style: theme.textTheme.bodySmall?.copyWith(
// //                                 color: theme.colorScheme.onSurfaceVariant,
// //                               ),
// //                               textAlign: TextAlign.center,
// //                             ),
// //                           SizedBox(
// //                             height: 46,
// //                             child: FilledButton(
// //                               onPressed: game.allPlayersVoted
// //                                   ? game.ownerAdvanceTurn
// //                                   : null,
// //                               child: const Text('Next Card →'),
// //                             ),
// //                           ),
// //                         ] else
// //                           Text(
// //                             'Waiting for host…',
// //                             textAlign: TextAlign.center,
// //                             style: theme.textTheme.bodySmall?.copyWith(
// //                               color: theme.colorScheme.onSurfaceVariant,
// //                             ),
// //                           ),
// //                       ],

// //                       // ── Reactions — pinned to bottom ─────────────────────
// //                       const SizedBox(height: 8),
// //                       if (reactionTally.isNotEmpty)
// //                         Padding(
// //                           padding: const EdgeInsets.only(bottom: 4),
// //                           child: Wrap(
// //                             spacing: 6,
// //                             runSpacing: 4,
// //                             children: reactionTally.entries
// //                                 .map(
// //                                   (e) => Container(
// //                                     padding: const EdgeInsets.symmetric(
// //                                       horizontal: 8,
// //                                       vertical: 3,
// //                                     ),
// //                                     decoration: BoxDecoration(
// //                                       color: theme
// //                                           .colorScheme
// //                                           .surfaceContainerHighest,
// //                                       borderRadius: BorderRadius.circular(20),
// //                                     ),
// //                                     child: Text(
// //                                       '${e.key} ${e.value}',
// //                                       style: const TextStyle(fontSize: 13),
// //                                     ),
// //                                   ),
// //                                 )
// //                                 .toList(),
// //                           ),
// //                         ),
// //                       EmojiReactionRow(
// //                         reactionsByEmoji: const {},
// //                         alreadyReacted: hasReacted,
// //                         onReact: game.sendReaction,
// //                       ),
// //                       const SizedBox(height: 8),
// //                     ],
// //                   ),
// //                 ),
// //               ),
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
// //   final List<NhieRoundRecord> history;
// //   final Map<String, String> displayNames;
// //   final VoidCallback onClose;

// //   String _name(String id) =>
// //       displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

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
// //               final haves = round.votes.values.where((v) => v.haveI).length;
// //               final nevers = round.votes.values.where((v) => !v.haveI).length;
// //               // Reaction tally
// //               final rt = <String, int>{};
// //               for (final r in round.reactions)
// //                 rt[r.sticker] = (rt[r.sticker] ?? 0) + 1;
// //               return Card(
// //                 margin: const EdgeInsets.only(bottom: 10),
// //                 child: ExpansionTile(
// //                   leading: CircleAvatar(
// //                     backgroundColor: theme.colorScheme.primaryContainer,
// //                     child: Text(
// //                       '${round.roundNumber}',
// //                       style: theme.textTheme.labelLarge,
// //                     ),
// //                   ),
// //                   title: Text(
// //                     round.card.content,
// //                     style: theme.textTheme.bodyMedium?.copyWith(
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                     maxLines: 2,
// //                     overflow: TextOverflow.ellipsis,
// //                   ),
// //                   subtitle: Text(
// //                     '✋ $haves  •  🙅 $nevers  ${rt.isNotEmpty ? '• ' + rt.entries.map((e) => '${e.key}${e.value}').join(' ') : ''}',
// //                     style: theme.textTheme.bodySmall,
// //                   ),
// //                   children: [
// //                     Padding(
// //                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: round.votes.entries
// //                             .map(
// //                               (e) => Padding(
// //                                 padding: const EdgeInsets.symmetric(
// //                                   vertical: 3,
// //                                 ),
// //                                 child: Row(
// //                                   children: [
// //                                     Text(
// //                                       _name(e.key),
// //                                       style: theme.textTheme.bodySmall
// //                                           ?.copyWith(
// //                                             fontWeight: FontWeight.w600,
// //                                           ),
// //                                     ),
// //                                     const SizedBox(width: 6),
// //                                     Text(e.value.haveI ? '✋' : '🙅'),
// //                                     if (e.value.message.isNotEmpty) ...[
// //                                       const SizedBox(width: 4),
// //                                       Expanded(
// //                                         child: Text(
// //                                           '"${e.value.message}"',
// //                                           style: theme.textTheme.bodySmall
// //                                               ?.copyWith(
// //                                                 fontStyle: FontStyle.italic,
// //                                                 color: theme
// //                                                     .colorScheme
// //                                                     .onSurfaceVariant,
// //                                               ),
// //                                           overflow: TextOverflow.ellipsis,
// //                                         ),
// //                                       ),
// //                                     ],
// //                                   ],
// //                                 ),
// //                               ),
// //                             )
// //                             .toList(),
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
// //   final NhieGameProvider game;
// //   final Map<String, String> displayNames;
// //   @override
// //   State<_GameOverScreen> createState() => _GameOverScreenState();
// // }

// // class _GameOverScreenState extends State<_GameOverScreen> {
// //   bool _showHistory = false;
// //   String _name(String id) =>
// //       widget.displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

// //   @override
// //   Widget build(BuildContext context) {
// //     final scores = widget.game.state?.scores ?? {};
// //     final history = widget.game.state?.history ?? [];
// //     final sorted = scores.entries.toList()
// //       ..sort((a, b) => b.value.compareTo(a.value));
// //     const medals = ['🥇', '🥈', '🥉'];

// //     if (_showHistory)
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

// //     return Scaffold(
// //       body: SafeArea(
// //         child: Padding(
// //           padding: const EdgeInsets.all(24),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.stretch,
// //             children: [
// //               const Text(
// //                 '🏆',
// //                 textAlign: TextAlign.center,
// //                 style: TextStyle(fontSize: 72),
// //               ),
// //               Text(
// //                 'Game Over!',
// //                 textAlign: TextAlign.center,
// //                 style: context.textTheme.headlineMedium?.copyWith(
// //                   fontWeight: FontWeight.w800,
// //                 ),
// //               ),
// //               Text(
// //                 'Most 🍹 drinks wins!',
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
// //                         _name(e.key),
// //                         style: context.textTheme.titleMedium?.copyWith(
// //                           fontWeight: FontWeight.w700,
// //                         ),
// //                       ),
// //                       trailing: Text(
// //                         '${e.value} 🍹',
// //                         style: context.textTheme.titleMedium?.copyWith(
// //                           color: AppColors.errorRed,
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

// // // ── Paused overlay ────────────────────────────────────────────────────────────
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
// import 'package:jma3a/features/games/never_have_i_ever/never_have_i_ever_engine.dart';
// import 'package:jma3a/features/games/truth_or_dare/data/tod_repository.dart';
// import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
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

// enum NhieLoadState { idle, loading, ready, error, gameOver }

// class NhieGameProvider extends ChangeNotifier {
//   NhieGameProvider({
//     required RealtimeService realtimeService,
//     required String userId,
//     required String displayName,
//   }) : _realtime = realtimeService,
//        _userId = userId,
//        _displayName = displayName;

//   final RealtimeService _realtime;
//   final String _userId, _displayName;
//   NeverHaveIEverEngine? _engine;
//   NhieLoadState _loadState = NhieLoadState.idle;
//   String? _roomId;
//   String? _sessionId;
//   bool _isOwner = false;
//   String _error = '';
//   final Set<String> _awayPlayerIds = {};

//   NhieLoadState get loadState => _loadState;
//   NhieState? get state => _engine?.currentState as NhieState?;
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
//     if (_isOwner && _engine != null) {
//       final s = _engine!.currentState as NhieState?;
//       if (s != null && s.isVotingOpen && !s.voteEntries.containsKey(userId)) {
//         _engine!.handleEvent(
//           NhieVoteEvent(
//             userId: userId,
//             ts: DateTime.now().millisecondsSinceEpoch,
//             haveI: false,
//           ),
//         );
//         notifyListeners();
//         _broadcastState();
//       }
//     }
//     notifyListeners();
//   }

//   void markPlayerReturned(String userId) {
//     _awayPlayerIds.remove(userId);
//     notifyListeners();
//   }

//   Future<void> initAsOwner({
//     required String roomId,
//     required String packId,
//     required List<String> playerIds,
//     required Map<String, String> displayNames,
//     required GameConfig config,
//   }) async {
//     _roomId = roomId;
//     _isOwner = true;
//     _loadState = NhieLoadState.loading;
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
//       final cards = todCards.map((c) {
//         var t = c.content;
//         for (final p in ['Never have I ever ', 'never have I ever ']) {
//           if (t.startsWith(p)) {
//             t = t.substring(p.length);
//             break;
//           }
//         }
//         if (t.isNotEmpty) t = t[0].toUpperCase() + t.substring(1);
//         return NhieCard(id: c.id, content: t, difficulty: c.difficulty.name);
//       }).toList();
//       _engine = NeverHaveIEverEngine(config, cards: cards);

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
//       if (snapshotGameType == 'never_have_i_ever') {
//         existingSnapshot = existing?['state_snapshot'] as Map<String, dynamic>?;
//       }

//       if (existing != null &&
//           existingSnapshot != null &&
//           existingSnapshot.isNotEmpty) {
//         final raw = existingSnapshot;
//         if (raw['scores'] is Map) {
//           raw['scores'] = (raw['scores'] as Map).map(
//             (k, v) => MapEntry(k as String, v is num ? v.toInt() : 0),
//           );
//         }
//         _sessionId = existing['id'] as String;
//         _engine!.restoreFromSnapshot(raw);
//         AppLogger.info('NhieProvider: resumed existing session $_sessionId');
//       } else {
//         _engine!.init(playerIds);
//         try {
//           final inserted = await Supabase.instance.client
//               .from('game_sessions')
//               .insert({
//                 'room_id': roomId,
//                 'pack_id': packId,
//                 'game_type': 'never_have_i_ever',
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
//           AppLogger.warning('NhieProvider: failed to create session: $e');
//         }
//       }

//       _loadState = NhieLoadState.ready;
//       notifyListeners();
//       _broadcastState();
//     } catch (e) {
//       _error = e.toString();
//       _loadState = NhieLoadState.error;
//       AppLogger.error('NhieProvider: init failed', error: e);
//       notifyListeners();
//     }
//   }

//   void initAsFollower(String roomId) {
//     _roomId = roomId;
//     _isOwner = false;
//     _loadState = NhieLoadState.loading;
//     notifyListeners();
//   }

//   Future<void> vote(bool haveI, {String message = ''}) => _handleAction({
//     'action': 'nhie_vote',
//     'have_i': haveI,
//     'message': message,
//   });
//   Future<void> sendReaction(String emoji) =>
//       _handleAction({'action': 'nhie_reaction', 'sticker': emoji});
//   Future<void> ownerAdvanceTurn() async {
//     if (!_isOwner || _engine == null) return;
//     _engine!.advanceTurn();
//     if (_engine!.isGameOver) _loadState = NhieLoadState.gameOver;
//     notifyListeners();
//     _broadcastState();
//   }

//   void onStateBroadcast(Map<String, dynamic> payload) {
//     if (_isOwner) return;
//     try {
//       final snap =
//           (payload['snapshot'] as Map<String, dynamic>?)?['state']
//               as Map<String, dynamic>? ??
//           payload['state'] as Map<String, dynamic>?;
//       if (snap == null) return;
//       _engine ??= NeverHaveIEverEngine(
//         const GameConfig(
//           maxRounds: 10,
//           turnTimerSeconds: 60,
//           allowSkip: false,
//           allowSpicy: false,
//         ),
//         cards: [],
//       );
//       _engine!.restoreFromSnapshot(snap);
//       _loadState = _engine!.isGameOver
//           ? NhieLoadState.gameOver
//           : NhieLoadState.ready;
//       notifyListeners();
//     } catch (e) {
//       AppLogger.warning('NhieProvider: restore failed: $e');
//     }
//   }

//   void onPlayerAction(Map<String, dynamic> payload) {
//     if (!_isOwner || _engine == null) return;
//     final action = payload['action'] as String?;
//     final uid = payload['user_id'] as String?;
//     final ts = payload['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
//     if (uid == null) return;
//     if (action == 'nhie_vote') {
//       _engine!.handleEvent(
//         NhieVoteEvent(
//           userId: uid,
//           ts: ts,
//           haveI: payload['have_i'] as bool? ?? false,
//           message: payload['message'] as String? ?? '',
//         ),
//       );
//     } else if (action == 'nhie_reaction') {
//       _engine!.handleEvent(
//         NhieReactionEvent(
//           userId: uid,
//           ts: ts,
//           sticker: payload['sticker'] as String? ?? '😂',
//         ),
//       );
//     }
//     if (_engine!.isGameOver) _loadState = NhieLoadState.gameOver;
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
//               AppLogger.warning('NhieProvider: snapshot save failed: $e');
//             },
//           );
//     }
//   }
// }

// Future<void> nhieShowLeaveDialog(
//   BuildContext ctx, {
//   required String roomId,
//   required bool isOwners,
//   String displayName = 'A player',
// }) async {
//   if (!ctx.mounted) return;
//   final isOwner = isOwners;
//   final myUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
//   final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

//   if (isOwner) {
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

//     {
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
//     final confirmed = await showDialog<bool>(
//       context: ctx,
//       builder: (d) => AlertDialog(
//         title: const Text('Leave Game?'),
//         content: const Text('You will be removed from the game.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(d, false),
//             child: const Text('Stay'),
//           ),
//           FilledButton(
//             style: FilledButton.styleFrom(backgroundColor: Colors.red),
//             onPressed: () => Navigator.pop(d, true),
//             child: const Text('Quit Game'),
//           ),
//         ],
//       ),
//     );
//     if (confirmed != true || !ctx.mounted) return;
//     try {
//       await sl.roomRepository.setMemberDefinitiveLeave(roomId, myUserId);
//       await sl.realtimeService.broadcastRoomEvent(roomId, {
//         'type': 'player_left',
//         'user_id': myUserId,
//         'display_name': displayName,
//         'for_good': true,
//       });
//     } catch (_) {}
//     if (ctx.mounted) AppRouter.router.go('/home/room/$roomId');
//   }
// }

// class NhieGameScreen extends StatefulWidget {
//   const NhieGameScreen({
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
//   State<NhieGameScreen> createState() => _NhieGameScreenState();
// }

// class _NhieGameScreenState extends State<NhieGameScreen> {
//   late final NhieGameProvider _provider;

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
//     _provider = NhieGameProvider(
//       realtimeService: sl.realtimeService,
//       userId: user.id,
//       displayName: user.displayName ?? user.username ?? 'Player',
//     );
//     sl.realtimeService.subscribe(
//       roomId: widget.roomId,
//       onGameState: (p) => _provider.onStateBroadcast(p),
//       onPlayerAction: (p) => _provider.onPlayerAction(p),
//       onSyncRequest: (p) => _provider.onSyncRequest(p),
//       onGameStarted: (_) {},
//       onGameEnded: (p) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('The host ended the game')),
//           );
//           if (context.canPop())
//             context.pop();
//           else
//             context.go(RouteNames.home);
//         }
//       },
//       onRoomEvent: (p) {
//         final evType = p['type'] as String?;
//         if (evType == 'screenshot_taken') {
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
//         if (evType == 'game_ended' && mounted) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (!mounted) return;
//             showDialog(
//               context: context,
//               barrierDismissible: false,
//               builder: (ctx2) => AlertDialog(
//                 title: const Text('Game Ended'),
//                 content: const Text('The host ended the game.'),
//                 actions: [
//                   FilledButton(
//                     onPressed: () {
//                       Navigator.of(ctx2).pop();
//                       if (context.canPop())
//                         context.pop();
//                       else
//                         AppRouter.router.go('/home/room/${widget.roomId}');
//                     },
//                     child: const Text('Go to Lobby'),
//                   ),
//                 ],
//               ),
//             );
//           });
//           return;
//         }
//         if (evType == 'player_left' && mounted) {
//           final name = p['display_name'] as String? ?? 'A player';
//           final leavingId = p['user_id'] as String?;
//           if (leavingId != null && _provider.isOwner) {
//             _provider.markPlayerAway(leavingId, forGood: true);
//           }
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('👋 $name left the game'),
//               backgroundColor: Colors.red.shade700,
//               behavior: SnackBarBehavior.fixed,
//               duration: const Duration(seconds: 3),
//             ),
//           );
//           return;
//         }
//         if (evType == 'ownership_transferred' && mounted) {
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

//         if (((p['type'] as String?) == 'room_closed' ||
//             (p['type'] as String?) == 'owner_left')) {
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
//       if (mounted && _provider.loadState == NhieLoadState.loading) {
//         sl.realtimeService
//             .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
//             .ignore();
//       }
//     });
//     Future.delayed(const Duration(seconds: 3), () {
//       if (mounted && _provider.loadState == NhieLoadState.loading) {
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
//     return ChangeNotifierProvider.value(
//       value: _provider,
//       child: Consumer<NhieGameProvider>(
//         builder: (ctx, game, _) {
//           if (game.loadState == NhieLoadState.loading)
//             return const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             );
//           if (game.loadState == NhieLoadState.error)
//             return Scaffold(
//               body: Center(
//                 child: Padding(
//                   padding: const EdgeInsets.all(24),
//                   child: Text(
//                     'Error: ${game.error}',
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//             );
//           if (game.loadState == NhieLoadState.gameOver)
//             return _GameOverScreen(
//               game: game,
//               displayNames: widget.playerDisplayNames,
//             );
//           final state = game.state;
//           if (state == null)
//             return const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             );
//           return _GameBody(
//             game: game,
//             state: state,
//             displayNames: widget.playerDisplayNames,
//             packCoverUrl: widget.packCoverUrl,
//             roomId: widget.roomId,
//             isOwner: widget.isOwner,
//           );
//         },
//       ),
//     );
//   }
// }

// class _GameBody extends StatefulWidget {
//   const _GameBody({
//     required this.game,
//     required this.state,
//     required this.displayNames,
//     this.packCoverUrl,
//     required this.roomId,
//     required this.isOwner,
//   });
//   final NhieGameProvider game;
//   final NhieState state;
//   final Map<String, String> displayNames;
//   final String? packCoverUrl;
//   final String roomId;
//   final bool isOwner;
//   @override
//   State<_GameBody> createState() => _GameBodyState();
// }

// class _GameBodyState extends State<_GameBody> {
//   final _msgCtrl = TextEditingController();
//   bool _showHistory = false;

//   @override
//   void dispose() {
//     _msgCtrl.dispose();
//     super.dispose();
//   }

//   String _name(String id) =>
//       widget.displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     final state = widget.state;
//     final game = widget.game;
//     final hasVoted = state.voteEntries.containsKey(game.userId);
//     final allVoted = state.playerOrder.every(
//       (id) => state.voteEntries.containsKey(id),
//     );
//     final hasReacted = state.reactions.any((r) => r.userId == game.userId);
//     final reactionTally = <String, int>{};
//     for (final r in state.reactions) {
//       reactionTally[r.sticker] = (reactionTally[r.sticker] ?? 0) + 1;
//     }

//     return PopScope(
//       canPop: false,
//       onPopInvokedWithResult: (didPop, _) async {
//         if (didPop) return;
//         await nhieShowLeaveDialog(
//           context,
//           roomId: widget.roomId,
//           isOwners: widget.isOwner,
//           displayName:
//               widget.displayNames[Supabase
//                       .instance
//                       .client
//                       .auth
//                       .currentUser
//                       ?.id ??
//                   ''] ??
//               'A player',
//         );
//       },
//       child: Scaffold(
//         resizeToAvoidBottomInset: true,
//         appBar: AppBar(
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () => nhieShowLeaveDialog(
//               context,
//               roomId: widget.roomId,
//               isOwners: widget.isOwner,
//               displayName:
//                   widget.displayNames[Supabase
//                           .instance
//                           .client
//                           .auth
//                           .currentUser
//                           ?.id ??
//                       ''] ??
//                   'A player',
//             ),
//           ),
//           title: Text('Round ${state.roundNumber} / ${state.maxRounds}'),
//           actions: [
//             if (state.history.isNotEmpty)
//               IconButton(
//                 icon: const Icon(Icons.history_rounded),
//                 onPressed: () => setState(() => _showHistory = !_showHistory),
//               ),
//             Padding(
//               padding: const EdgeInsets.only(right: 12),
//               child: Center(
//                 child: Text(
//                   '🍹 ${state.scores.values.fold(0, (a, b) => a + b)}',
//                   style: theme.textTheme.titleSmall?.copyWith(
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         body: _showHistory
//             ? _HistoryPanel(
//                 history: state.history,
//                 displayNames: widget.displayNames,
//                 onClose: () => setState(() => _showHistory = false),
//               )
//             : SafeArea(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       Text(
//                         '${state.votes.length}/${state.playerOrder.length} answered',
//                         textAlign: TextAlign.center,
//                         style: theme.textTheme.titleSmall?.copyWith(
//                           fontWeight: FontWeight.w700,
//                           color: theme.colorScheme.primary,
//                         ),
//                       ),
//                       const SizedBox(height: 8),

//                       Expanded(
//                         child: LayoutBuilder(
//                           builder: (context, constraints) {
//                             return ClipRRect(
//                               borderRadius: BorderRadius.circular(20),
//                               child: SizedBox(
//                                 width: constraints.maxWidth,
//                                 height: constraints.maxHeight,
//                                 child: Stack(
//                                   fit: StackFit.expand,
//                                   children: [
//                                     Positioned.fill(
//                                       child:
//                                           widget.packCoverUrl != null &&
//                                               widget.packCoverUrl!.isNotEmpty
//                                           ? Image.network(
//                                               widget.packCoverUrl!,
//                                               fit: BoxFit.cover,
//                                               width: double.infinity,
//                                               height: double.infinity,
//                                               errorBuilder: (_, __, ___) =>
//                                                   Image.asset(
//                                                     'assets/images/jma3a_card_background.png',
//                                                     fit: BoxFit.cover,
//                                                     width: double.infinity,
//                                                     height: double.infinity,
//                                                   ),
//                                             )
//                                           : Image.asset(
//                                               'assets/images/jma3a_card_background.png',
//                                               fit: BoxFit.cover,
//                                               width: double.infinity,
//                                               height: double.infinity,
//                                               errorBuilder: (_, __, ___) =>
//                                                   Container(
//                                                     color: AppColors.tealGreen,
//                                                   ),
//                                             ),
//                                     ),
//                                     Positioned.fill(
//                                       child: Container(
//                                         decoration: BoxDecoration(
//                                           gradient: LinearGradient(
//                                             colors: [
//                                               AppColors.tealGreen.withOpacity(
//                                                 0.45,
//                                               ),
//                                               const Color(
//                                                 0xFF0D1B2A,
//                                               ).withOpacity(0.65),
//                                             ],
//                                             begin: Alignment.topCenter,
//                                             end: Alignment.bottomCenter,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     Padding(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 24,
//                                         vertical: 20,
//                                       ),
//                                       child: Column(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           const Text(
//                                             '🍹',
//                                             style: TextStyle(fontSize: 56),
//                                           ),
//                                           const SizedBox(height: 12),
//                                           const Text(
//                                             'Never Have I Ever…',
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 18,
//                                               fontWeight: FontWeight.w800,
//                                               shadows: [
//                                                 Shadow(
//                                                   color: Colors.black54,
//                                                   blurRadius: 6,
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                           const SizedBox(height: 14),
//                                           Text(
//                                             state.currentCard?.content ?? '…',
//                                             textAlign: TextAlign.center,
//                                             style: const TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 22,
//                                               fontWeight: FontWeight.w600,
//                                               height: 1.5,
//                                               shadows: [
//                                                 Shadow(
//                                                   color: Colors.black54,
//                                                   blurRadius: 8,
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       const SizedBox(height: 12),

//                       if (!hasVoted && state.isVotingOpen) ...[
//                         TextField(
//                           controller: _msgCtrl,
//                           maxLength: 120,
//                           maxLines: 1,
//                           textInputAction: TextInputAction.done,
//                           onSubmitted: (_) => FocusScope.of(context).unfocus(),
//                           decoration: const InputDecoration(
//                             hintText: 'Add a comment (optional)…',
//                             border: OutlineInputBorder(),
//                             isDense: true,
//                             counterText: '',
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: SizedBox(
//                                 height: 50,
//                                 child: FilledButton.icon(
//                                   onPressed: () => game.vote(
//                                     true,
//                                     message: _msgCtrl.text.trim(),
//                                   ),
//                                   icon: const Text('✋'),
//                                   label: const Text(
//                                     'I HAVE',
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.w800,
//                                     ),
//                                   ),
//                                   style: FilledButton.styleFrom(
//                                     backgroundColor: AppColors.errorRed,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: SizedBox(
//                                 height: 50,
//                                 child: FilledButton.icon(
//                                   onPressed: () => game.vote(
//                                     false,
//                                     message: _msgCtrl.text.trim(),
//                                   ),
//                                   icon: const Text('🙅'),
//                                   label: const Text(
//                                     'NEVER',
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.w800,
//                                     ),
//                                   ),
//                                   style: FilledButton.styleFrom(
//                                     backgroundColor:
//                                         theme.colorScheme.secondary,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ] else if (!allVoted && hasVoted) ...[
//                         Container(
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           decoration: BoxDecoration(
//                             color: theme.colorScheme.surfaceContainerHighest,
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               const SizedBox(
//                                 width: 14,
//                                 height: 14,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                 ),
//                               ),
//                               const SizedBox(width: 10),
//                               Text(
//                                 'Waiting… ${state.voteEntries.length}/${state.playerOrder.length}',
//                                 style: theme.textTheme.bodyMedium,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ] else if (allVoted) ...[
//                         ...state.voteEntries.entries.map(
//                           (e) => Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 3),
//                             child: Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   _name(e.key),
//                                   style: theme.textTheme.bodyMedium?.copyWith(
//                                     fontWeight: FontWeight.w600,
//                                     color: e.key == game.userId
//                                         ? theme.colorScheme.primary
//                                         : null,
//                                   ),
//                                 ),
//                                 const Spacer(),
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.end,
//                                   children: [
//                                     Text(
//                                       e.value.haveI ? '✋ I have' : '🙅 Never',
//                                       style: theme.textTheme.bodyMedium
//                                           ?.copyWith(
//                                             fontWeight: FontWeight.w700,
//                                             color: e.value.haveI
//                                                 ? AppColors.errorRed
//                                                 : AppColors.tealGreen,
//                                           ),
//                                     ),
//                                     if (e.value.message.isNotEmpty)
//                                       Text(
//                                         '"${e.value.message}"',
//                                         style: theme.textTheme.bodySmall
//                                             ?.copyWith(
//                                               fontStyle: FontStyle.italic,
//                                               color: theme
//                                                   .colorScheme
//                                                   .onSurfaceVariant,
//                                             ),
//                                       ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         if (game.isOwner) ...[
//                           if (!game.allPlayersVoted)
//                             Text(
//                               '${game.votedCount}/${game.playerCount} answered',
//                               style: theme.textTheme.bodySmall?.copyWith(
//                                 color: theme.colorScheme.onSurfaceVariant,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           SizedBox(
//                             height: 46,
//                             child: FilledButton(
//                               onPressed: game.allPlayersVoted
//                                   ? game.ownerAdvanceTurn
//                                   : null,
//                               child: const Text('Next Card →'),
//                             ),
//                           ),
//                         ] else
//                           Text(
//                             'Waiting for host…',
//                             textAlign: TextAlign.center,
//                             style: theme.textTheme.bodySmall?.copyWith(
//                               color: theme.colorScheme.onSurfaceVariant,
//                             ),
//                           ),
//                       ],

//                       const SizedBox(height: 8),
//                       if (reactionTally.isNotEmpty)
//                         Padding(
//                           padding: const EdgeInsets.only(bottom: 4),
//                           child: Wrap(
//                             spacing: 6,
//                             runSpacing: 4,
//                             children: reactionTally.entries
//                                 .map(
//                                   (e) => Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 8,
//                                       vertical: 3,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: theme
//                                           .colorScheme
//                                           .surfaceContainerHighest,
//                                       borderRadius: BorderRadius.circular(20),
//                                     ),
//                                     child: Text(
//                                       '${e.key} ${e.value}',
//                                       style: const TextStyle(fontSize: 13),
//                                     ),
//                                   ),
//                                 )
//                                 .toList(),
//                           ),
//                         ),
//                       EmojiReactionRow(
//                         reactionsByEmoji: const {},
//                         alreadyReacted: hasReacted,
//                         onReact: game.sendReaction,
//                       ),
//                       const SizedBox(height: 8),
//                     ],
//                   ),
//                 ),
//               ),
//       ),
//     );
//   }
// }

// class _HistoryPanel extends StatelessWidget {
//   const _HistoryPanel({
//     required this.history,
//     required this.displayNames,
//     required this.onClose,
//   });
//   final List<NhieRoundRecord> history;
//   final Map<String, String> displayNames;
//   final VoidCallback onClose;

//   String _name(String id) =>
//       displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

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
//               final haves = round.votes.values.where((v) => v.haveI).length;
//               final nevers = round.votes.values.where((v) => !v.haveI).length;
//               final rt = <String, int>{};
//               for (final r in round.reactions)
//                 rt[r.sticker] = (rt[r.sticker] ?? 0) + 1;
//               return Card(
//                 margin: const EdgeInsets.only(bottom: 10),
//                 child: ExpansionTile(
//                   leading: CircleAvatar(
//                     backgroundColor: theme.colorScheme.primaryContainer,
//                     child: Text(
//                       '${round.roundNumber}',
//                       style: theme.textTheme.labelLarge,
//                     ),
//                   ),
//                   title: Text(
//                     round.card.content,
//                     style: theme.textTheme.bodyMedium?.copyWith(
//                       fontWeight: FontWeight.w600,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   subtitle: Text(
//                     '✋ $haves  •  🙅 $nevers  ${rt.isNotEmpty ? '• ' + rt.entries.map((e) => '${e.key}${e.value}').join(' ') : ''}',
//                     style: theme.textTheme.bodySmall,
//                   ),
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: round.votes.entries
//                             .map(
//                               (e) => Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 3,
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     Text(
//                                       _name(e.key),
//                                       style: theme.textTheme.bodySmall
//                                           ?.copyWith(
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                     ),
//                                     const SizedBox(width: 6),
//                                     Text(e.value.haveI ? '✋' : '🙅'),
//                                     if (e.value.message.isNotEmpty) ...[
//                                       const SizedBox(width: 4),
//                                       Expanded(
//                                         child: Text(
//                                           '"${e.value.message}"',
//                                           style: theme.textTheme.bodySmall
//                                               ?.copyWith(
//                                                 fontStyle: FontStyle.italic,
//                                                 color: theme
//                                                     .colorScheme
//                                                     .onSurfaceVariant,
//                                               ),
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ),
//                                     ],
//                                   ],
//                                 ),
//                               ),
//                             )
//                             .toList(),
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

// class _GameOverScreen extends StatefulWidget {
//   const _GameOverScreen({required this.game, required this.displayNames});
//   final NhieGameProvider game;
//   final Map<String, String> displayNames;
//   @override
//   State<_GameOverScreen> createState() => _GameOverScreenState();
// }

// class _GameOverScreenState extends State<_GameOverScreen> {
//   bool _showHistory = false;
//   String _name(String id) =>
//       widget.displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

//   @override
//   Widget build(BuildContext context) {
//     final scores = widget.game.state?.scores ?? {};
//     final history = widget.game.state?.history ?? [];
//     final sorted = scores.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));
//     const medals = ['🥇', '🥈', '🥉'];

//     if (_showHistory)
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

//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const Text(
//                 '🏆',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 72),
//               ),
//               Text(
//                 'Game Over!',
//                 textAlign: TextAlign.center,
//                 style: context.textTheme.headlineMedium?.copyWith(
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//               Text(
//                 'Most 🍹 drinks wins!',
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
//                         _name(e.key),
//                         style: context.textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       trailing: Text(
//                         '${e.value} 🍹',
//                         style: context.textTheme.titleMedium?.copyWith(
//                           color: AppColors.errorRed,
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
import 'package:jma3a/features/settings/presentation/screen_security_service.dart';
import '../../avatar/presentation/avatar_creator_screen.dart';
import 'package:jma3a/core/router/app_router.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/games/never_have_i_ever/never_have_i_ever_engine.dart';
import 'package:jma3a/features/games/truth_or_dare/data/tod_repository.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/features/rooms/presentation/room_provider.dart';
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

enum NhieLoadState { idle, loading, ready, error, gameOver }

class NhieGameProvider extends ChangeNotifier {
  NhieGameProvider({
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

  NeverHaveIEverEngine? _engine;
  NhieLoadState _loadState = NhieLoadState.idle;
  String? _roomId;
  String? _sessionId;
  bool _isOwner = false;
  String _error = '';
  final Set<String> _awayPlayerIds = {};
  final Set<String> _readyForNext = {};

  // Shared between _NhieGameScreenState (owns the realtime listeners) and
  // _GameBodyState (owns the PopScope) via this single provider instance,
  // so a programmatic pop triggered by a realtime event (e.g. onGameEnded)
  // doesn't get misread by PopScope as the user backing out, which would
  // incorrectly open the Quit Game confirmation dialog.
  bool isNavigatingAway = false;

  NhieLoadState get loadState => _loadState;
  NhieState? get state => _engine?.currentState as NhieState?;
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
      '[READY-DEBUG][nhie] allOthersReady: others=$others '
      'readyForNext=$_readyForNext away=$_effectiveAwayIds -> $result',
    );
    return result;
  }

  void markPlayerAway(String userId, {bool forGood = false}) {
    _awayPlayerIds.add(userId);
    if (_isOwner && _engine != null) {
      _autoFillAwayPlayers();
      notifyListeners();
      _broadcastState();
    }
    notifyListeners();
  }

  /// playerOrder is fixed for the life of the session — a kicked/left
  /// player is never removed from it, only added to _awayPlayerIds. Vote
  /// completion is a simple count against playerOrder.length, so an away
  /// player who never votes would otherwise block every round from here on
  /// (not just the one they left during). Auto-casts on their behalf each
  /// round; _handleVote itself is idempotent per user, so calling this
  /// repeatedly across rounds is safe.
  void _autoFillAwayPlayers() {
    if (!_isOwner || _engine == null || _effectiveAwayIds.isEmpty) return;
    final s = _engine!.currentState as NhieState;
    if (!s.isVotingOpen) return;
    for (final uid in _effectiveAwayIds) {
      if (!s.voteEntries.containsKey(uid)) {
        _engine!.handleEvent(
          NhieVoteEvent(
            userId: uid,
            ts: DateTime.now().millisecondsSinceEpoch,
            haveI: false,
          ),
        );
      }
    }
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
    _loadState = NhieLoadState.loading;
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
      final cards = todCards.map((c) {
        var t = c.content;
        for (final p in ['Never have I ever ', 'never have I ever ']) {
          if (t.startsWith(p)) {
            t = t.substring(p.length);
            break;
          }
        }
        if (t.isNotEmpty) t = t[0].toUpperCase() + t.substring(1);
        return NhieCard(id: c.id, content: t, difficulty: c.difficulty.name);
      }).toList();
      _engine = NeverHaveIEverEngine(config, cards: cards);

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
      if (snapshotGameType == 'never_have_i_ever') {
        existingSnapshot = existing?['state_snapshot'] as Map<String, dynamic>?;
      }

      if (existing != null &&
          existingSnapshot != null &&
          existingSnapshot.isNotEmpty) {
        final raw = existingSnapshot;
        if (raw['scores'] is Map) {
          raw['scores'] = (raw['scores'] as Map).map(
            (k, v) => MapEntry(k as String, v is num ? v.toInt() : 0),
          );
        }
        _sessionId = existing['id'] as String;
        _engine!.restoreFromSnapshot(raw);
        AppLogger.info('NhieProvider: resumed existing session $_sessionId');
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
              'p_game_type': 'never_have_i_ever',
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
          AppLogger.warning('NhieProvider: failed to create session: $e');
        }
      }

      if (_sessionId != null) {
        try {
          final customCards = await TodRepository.instance.loadCustomCards(
            _sessionId!,
          );
          for (final c in customCards) {
            _engine!.injectCard(
              NhieCard(id: c.id, content: c.content, difficulty: 'mild'),
            );
          }
          if (customCards.isNotEmpty) {
            AppLogger.info(
              'NhieProvider: merged ${customCards.length} custom cards into deck',
            );
          }
        } catch (e) {
          AppLogger.warning('NhieProvider: custom card load failed: $e');
        }
      }

      _loadState = _engine!.isGameOver
          ? NhieLoadState.gameOver
          : NhieLoadState.ready;
      notifyListeners();
      _broadcastState();
    } catch (e) {
      _error = e.toString();
      _loadState = NhieLoadState.error;
      AppLogger.error('NhieProvider: init failed', error: e);
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
        'NhieProvider: no state broadcast for ${sinceLastState.inSeconds}s — requesting resync',
      );
      _realtime.broadcastSyncRequest(_roomId!, _userId, 0).ignore();

      Timer(const Duration(seconds: 4), () {
        if (DateTime.now().difference(_lastStateReceivedAt) > _staleThreshold) {
          AppLogger.warning(
            'NhieProvider: resync request unanswered — reading state from DB',
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
    _loadState = NhieLoadState.loading;
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
      final cards = await _loadCards(_packId!, _config!);
      _engine = NeverHaveIEverEngine(_config!, cards: cards);
      _engine!.restoreFromSnapshot(state!.toMap());
    } catch (e) {
      AppLogger.error(
        'NhieProvider: ownership handoff engine build failed: $e',
      );
      return;
    }
    _isOwner = true;
    notifyListeners();
  }

  /// Loads this pack's deck as [NhieCard]s — the same conversion
  /// [initAsOwner] performs, reused here for the ownership mid-game handoff.
  Future<List<NhieCard>> _loadCards(String packId, GameConfig config) async {
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
    return todCards.map((c) {
      var t = c.content;
      for (final p in ['Never have I ever ', 'never have I ever ']) {
        if (t.startsWith(p)) {
          t = t.substring(p.length);
          break;
        }
      }
      if (t.isNotEmpty) t = t[0].toUpperCase() + t.substring(1);
      return NhieCard(id: c.id, content: t, difficulty: c.difficulty.name);
    }).toList();
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
      final Map<String, dynamic>? snapshot =
          snapshotGameType == 'never_have_i_ever'
          ? (row?['state_snapshot'] as Map<String, dynamic>?)
          : null;
      if (snapshot == null || snapshot.isEmpty) {
        _error = 'Could not recover session state. Please rejoin the room.';
        _loadState = NhieLoadState.error;
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
      if (snapshot['scores'] is Map) {
        snapshot['scores'] = (snapshot['scores'] as Map).map(
          (k, v) => MapEntry(k as String, v is num ? v.toInt() : 0),
        );
      }
      _sessionId = row!['id'] as String;
      _engine ??= NeverHaveIEverEngine(
        const GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 60,
          allowSkip: false,
          allowSpicy: false,
        ),
        cards: const [],
      );
      _engine!.restoreFromSnapshot(snapshot);
      _loadState = _engine!.isGameOver
          ? NhieLoadState.gameOver
          : NhieLoadState.ready;
      _lastStateReceivedAt = DateTime.now();
      notifyListeners();
    } catch (e) {
      _error = 'Reconnection failed: ${e.toString()}';
      _loadState = NhieLoadState.error;
      AppLogger.warning('NhieProvider: DB fallback load failed: $e');
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
      _engine?.injectCard(
        NhieCard(id: card.id, content: card.content, difficulty: 'mild'),
      );
      notifyListeners();
      _broadcastState();
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  Future<void> vote(bool haveI, {String message = ''}) => _handleAction({
    'action': 'nhie_vote',
    'have_i': haveI,
    'message': message,
  });
  Future<void> sendReaction(String emoji) =>
      _handleAction({'action': 'nhie_reaction', 'sticker': emoji});
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
      if (_engine!.isGameOver) _loadState = NhieLoadState.gameOver;
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
      'action': 'nhie_mod_advance_turn',
      'force': force,
      'user_id': _userId,
      'display_name': _displayName,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Durable "I intend to be ready for the current round" flag — unlike
  // _readyForNext (wholesale overwritten by each authoritative
  // nhie_ready_count broadcast), this survives a broadcast that never
  // reached the owner, so onReadyCountUpdate can detect the mismatch and
  // resend instead of leaving the presser stuck forever.
  bool _myReadyIntent = false;

  Future<void> markReadyForNext() {
    final isPlayer = state?.playerOrder.contains(_userId) ?? false;
    AppLogger.debug(
      '[READY-DEBUG][nhie] markReadyForNext called by $_userId '
      'isPlayer=$isPlayer hasMarkedReady=$hasMarkedReady',
    );
    if (_userId.isEmpty || hasMarkedReady || !isPlayer) return Future.value();
    _myReadyIntent = true;
    _readyForNext.add(_userId);
    notifyListeners();
    return _handleAction({'action': 'nhie_ready_next'});
  }

  int _lastReadyCountTs = 0;

  void onReadyCountUpdate(
    List<String> readyUserIds, {
    int? ts,
    int? playerIndex,
  }) {
    AppLogger.debug('[READY-DEBUG][nhie] onReadyCountUpdate: $readyUserIds');
    // A ready_count broadcast is only meaningful for the turn it was
    // computed for. State-broadcast and ready-count travel as two separate
    // messages with no ordering guarantee between them — the very last
    // ready_count of a turn (the one that made everyone ready and caused
    // the advance) can arrive AFTER the new turn's state broadcast already
    // reset _readyForNext, and since its ts is not necessarily older than
    // _lastReadyCountTs it would otherwise slip past the ts guard below and
    // re-populate the stale, already-complete list for the turn that just
    // ended — this is what made the Ready button get stuck forever. Tagging
    // every ready_count with the turn it belongs to (currentPlayerIndex) and
    // rejecting a mismatch closes that gap regardless of ts ordering.
    if (playerIndex != null &&
        state?.currentPlayerIndex != null &&
        playerIndex != state!.currentPlayerIndex) {
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
    // Self-heal a lost nhie_ready_next broadcast: if I intended to be
    // ready for this round but the owner's authoritative list doesn't
    // have me, resend rather than leaving myself and the host stuck.
    if (_myReadyIntent && !_readyForNext.contains(_userId)) {
      _readyForNext.add(_userId);
      _handleAction({'action': 'nhie_ready_next'}).ignore();
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
          'NhieProvider: stale broadcast ts=$incomingTs discarded',
        );
        return;
      }
      // Ready state must reset every TURN, not every ROUND — roundNumber
      // only increments when the turn index wraps back to 0 across the
      // full player order, but the owner's `_readyForNext` is cleared on
      // every single turn advance. Using roundNumber here left a
      // follower's stale "already marked ready" flag in place for every
      // non-wrapping turn, permanently blocking their next ready press.
      // currentPlayerIndex changes on every advanceTurn() call, unlike
      // roundNumber (NHIE's engine has no dedicated turnStartedAt field).
      final previousPlayerIndex = state?.currentPlayerIndex;
      _syncTimeoutTimer?.cancel();
      _lastStateReceivedAt = DateTime.now();
      _engine ??= NeverHaveIEverEngine(
        const GameConfig(
          maxRounds: 10,
          turnTimerSeconds: 60,
          allowSkip: false,
          allowSpicy: false,
        ),
        cards: [],
      );
      _engine!.restoreFromSnapshot(snap);
      _loadState = _engine!.isGameOver
          ? NhieLoadState.gameOver
          : NhieLoadState.ready;
      if (previousPlayerIndex != null &&
          state?.currentPlayerIndex != previousPlayerIndex) {
        _readyForNext.clear();
        _myReadyIntent = false;
      }
      notifyListeners();
    } catch (e) {
      AppLogger.warning('NhieProvider: restore failed: $e');
    }
  }

  void onPlayerAction(Map<String, dynamic> payload) {
    if (!_isOwner || _engine == null) return;
    final action = payload['action'] as String?;
    final uid = payload['user_id'] as String?;
    final ts = payload['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    if (uid == null) return;
    if (action == 'nhie_mod_advance_turn') {
      if (_isAllowed(uid, 'advance_turn')) {
        ownerAdvanceTurn(force: payload['force'] as bool? ?? false);
      }
      return;
    }
    if (action == 'nhie_ready_next') {
      final isPlayer = state?.playerOrder.contains(uid) ?? false;
      AppLogger.debug(
        '[READY-DEBUG][nhie] onPlayerAction ready_next from $uid '
        'isPlayer=$isPlayer current=$_readyForNext',
      );
      if (isPlayer && _readyForNext.add(uid)) {
        AppLogger.debug(
          '[READY-DEBUG][nhie] rebroadcasting ready_count: $_readyForNext',
        );
        notifyListeners();
        final broadcastTs = DateTime.now().millisecondsSinceEpoch;
        _lastReadyCountTs = broadcastTs;
        _realtime.broadcastRoomEvent(_roomId ?? '', {
          'type': 'nhie_ready_count',
          'ready_user_ids': _readyForNext.toList(),
          'ts': broadcastTs,
          'player_index': state?.currentPlayerIndex,
        }).ignore();
      }
      return;
    }
    if (action == 'nhie_vote') {
      _engine!.handleEvent(
        NhieVoteEvent(
          userId: uid,
          ts: ts,
          haveI: payload['have_i'] as bool? ?? false,
          message: payload['message'] as String? ?? '',
        ),
      );
    } else if (action == 'nhie_reaction') {
      _engine!.handleEvent(
        NhieReactionEvent(
          userId: uid,
          ts: ts,
          sticker: payload['sticker'] as String? ?? '😂',
        ),
      );
    }
    if (_engine!.isGameOver) _loadState = NhieLoadState.gameOver;
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
      'type': 'nhie_ready_count',
      'ready_user_ids': _readyForNext.toList(),
      'ts': broadcastTs,
      'player_index': state?.currentPlayerIndex,
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
              AppLogger.warning('NhieProvider: snapshot save failed: $e');
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

Future<void> nhieShowLeaveDialog(
  BuildContext ctx, {
  required String roomId,
  required bool isOwners,
  String displayName = 'A player',
  NhieGameProvider? game,
}) async {
  if (!ctx.mounted) return;
  final isOwner = isOwners;
  final myUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
  final isPremium = ctx.read<AuthProvider>().currentUser?.isPremium ?? false;

  if (isOwner) {
    final mods = await sl.roomRepository
        .getRoomModerators(roomId)
        .catchError((_) => <Map<String, dynamic>>[]);
    final hasMod = mods.isNotEmpty;

    // Quit Game only ends the current game session — it must NOT close or
    // delete the room. Closing the room is a separate action, only
    // available from LobbyScreen's room management. Handing ownership off
    // to someone else first remains a separate, unrelated option.
    final choice = await showDialog<String>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Quit Game?'),
        content: const Text('Leave the current game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, 'cancel'),
            child: const Text('Cancel'),
          ),
          if (hasMod)
            FilledButton.tonal(
              onPressed: () => Navigator.pop(d, 'handoff'),
              child: const Text('Play Another & Hand Off'),
            ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(d, 'end'),
            child: const Text('Quit Game'),
          ),
        ],
      ),
    );
    if (choice == null || choice == 'cancel' || !ctx.mounted) return;

    if (choice == 'handoff' && mods.isNotEmpty) {
      final newOwner = mods.length == 1
          ? mods.first['user_id'] as String
          : await showDialog<String>(
              context: ctx,
              builder: (d) => SimpleDialog(
                title: const Text('Who takes over?'),
                children: mods.map((m) {
                  final uid = m['user_id'] as String;
                  return SimpleDialogOption(
                    onPressed: () => Navigator.pop(d, uid),
                    child: Text(uid.substring(0, 8).toUpperCase()),
                  );
                }).toList(),
              ),
            );
      if (newOwner == null || !ctx.mounted) return;
      try {
        await Supabase.instance.client
            .from('rooms')
            .update({'owner_id': newOwner})
            .eq('id', roomId);
        await sl.realtimeService.broadcastRoomEvent(roomId, {
          'type': 'ownership_transferred',
          'new_owner_id': newOwner,
          'by': myUserId,
        });
        await sl.realtimeService.broadcastRoomEvent(roomId, {
          'type': 'player_left',
          'user_id': myUserId,
          'for_good': true,
        });
      } catch (_) {}
      if (ctx.mounted) AppRouter.router.go(RouteNames.home);
      return;
    }

    // Use the dedicated game-ended broadcast (not 'owner_left') so every
    // player's existing onGameEnded handler fires immediately and pops
    // back to this same room's lobby — no dialog required on the
    // receiving end.
    try {
      await sl.realtimeService.broadcastGameEnded(roomId, {
        'reason': 'host_quit_to_lobby',
      });
      await sl.roomRepository.updateStatus(roomId, RoomStatus.waiting);
    } catch (_) {}
    if (ctx.mounted) {
      // Mark this as a programmatic exit before popping, so PopScope
      // (which shares this same NhieGameProvider instance) doesn't
      // mistake it for the user backing out and open Quit Game again.
      game?.isNavigatingAway = true;
      if (ctx.canPop()) {
        ctx.pop();
      } else {
        AppRouter.router.go('/home/room/$roomId');
      }
    }
  } else {
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
}

class NhieGameScreen extends StatefulWidget {
  const NhieGameScreen({
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
  State<NhieGameScreen> createState() => _NhieGameScreenState();
}

class _NhieGameScreenState extends State<NhieGameScreen> {
  late final NhieGameProvider _provider;

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
    _provider = NhieGameProvider(
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
          // Mark this as a programmatic exit before popping, so
          // _GameBody's PopScope (which shares this same NhieGameProvider
          // instance) doesn't mistake it for the user backing out and
          // open the Quit Game dialog on top of it.
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
        final evType = p['type'] as String?;
        if (evType == 'nhie_ready_count') {
          final ids = (p['ready_user_ids'] as List?)?.cast<String>() ?? [];
          _provider.onReadyCountUpdate(
            ids,
            ts: p['ts'] as int?,
            playerIndex: p['player_index'] as int?,
          );
          return;
        }
        if (evType == 'screenshot_taken') {
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
        if (evType == 'game_ended' && mounted) {
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
        if (evType == 'player_left' && mounted) {
          final name = p['display_name'] as String? ?? 'A player';
          final leavingId = p['user_id'] as String?;
          if (leavingId != null && _provider.isOwner) {
            _provider.markPlayerAway(leavingId, forGood: true);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('👋 $name left the game'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.fixed,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
        if (evType == 'ownership_transferred' && mounted) {
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

        if (((p['type'] as String?) == 'room_closed' ||
            (p['type'] as String?) == 'owner_left')) {
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
          // vote indefinitely even though they'd already been removed
          // from the room. Mark them away for everyone.
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
      if (mounted && _provider.loadState == NhieLoadState.loading) {
        sl.realtimeService
            .broadcastSyncRequest(widget.roomId, _provider.userId, 0)
            .ignore();
      }
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _provider.loadState == NhieLoadState.loading) {
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
    // every phase this screen can render (loading/error/gameOver/active
    // round) without needing to be threaded into each one individually.
    return Stack(
      children: [
        _buildContent(context),
        RoomMembersFab(
          roomProvider: widget.roomProvider,
          gameKickPlayer: _provider.kickPlayerFromGame,
          gameBanPlayer: _provider.banPlayerFromGame,
          heroTag: 'nhie_members_${widget.roomId}',
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
          child: Consumer<NhieGameProvider>(
            builder: (ctx, game, _) => AnimatedReactionOverlay(
              reactions: (game.state?.reactions ?? const [])
                  .map((r) => (emoji: r.sticker, ts: r.ts))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<NhieGameProvider>(
        builder: (ctx, game, _) {
          if (game.loadState == NhieLoadState.loading)
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          if (game.loadState == NhieLoadState.error)
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error: ${game.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          if (game.loadState == NhieLoadState.gameOver)
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
          return _GameBody(
            game: game,
            state: state,
            displayNames: widget.playerDisplayNames,
            packCoverUrl: widget.packCoverUrl,
            roomId: widget.roomId,
            isOwner: widget.isOwner,
            isSpectator: widget.isSpectator,
          );
        },
      ),
    );
  }
}

class _GameBody extends StatefulWidget {
  const _GameBody({
    required this.game,
    required this.state,
    required this.displayNames,
    this.packCoverUrl,
    required this.roomId,
    required this.isOwner,
    this.isSpectator = false,
  });
  final NhieGameProvider game;
  final NhieState state;
  final Map<String, String> displayNames;
  final String? packCoverUrl;
  final String roomId;
  final bool isOwner;
  final bool isSpectator;
  @override
  State<_GameBody> createState() => _GameBodyState();
}

class _GameBodyState extends State<_GameBody> {
  final _msgCtrl = TextEditingController();
  bool _showHistory = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  String _name(String id) =>
      widget.displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final state = widget.state;
    final game = widget.game;
    // Spectators can watch voting but never cast one themselves.
    final hasVoted =
        widget.isSpectator || state.voteEntries.containsKey(game.userId);
    final allVoted = state.playerOrder.every(
      (id) => state.voteEntries.containsKey(id),
    );
    final hasReacted =
        widget.isSpectator ||
        state.reactions.any((r) => r.userId == game.userId);
    final reactionTally = <String, int>{};
    for (final r in state.reactions) {
      reactionTally[r.sticker] = (reactionTally[r.sticker] ?? 0) + 1;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (widget.game.isNavigatingAway) return;
        await nhieShowLeaveDialog(
          context,
          roomId: widget.roomId,
          isOwners: widget.isOwner,
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
        );
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => nhieShowLeaveDialog(
              context,
              roomId: widget.roomId,
              isOwners: widget.isOwner,
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
          title: Text('Round ${state.roundNumber} / ${state.maxRounds}'),
          actions: [
            if (state.history.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.history_rounded),
                onPressed: () => setState(() => _showHistory = !_showHistory),
              ),
            RulesButton(
              gameType: GameType.neverHaveIEver,
              config: widget.game.config,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '🍹 ${state.scores.values.fold(0, (a, b) => a + b)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _showHistory
            ? _HistoryPanel(
                history: state.history,
                displayNames: widget.displayNames,
                onClose: () => setState(() => _showHistory = false),
              )
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${state.votes.length}/${game.activePlayerCount} answered',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: SizedBox(
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
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
                                              errorBuilder: (_, __, ___) =>
                                                  Image.asset(
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
                                                  Container(
                                                    color: AppColors.tealGreen,
                                                  ),
                                            ),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.tealGreen.withOpacity(
                                                0.45,
                                              ),
                                              const Color(
                                                0xFF0D1B2A,
                                              ).withOpacity(0.65),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 20,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            '🍹',
                                            style: TextStyle(fontSize: 56),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Never Have I Ever…',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black54,
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            state.currentCard?.content ?? '…',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w600,
                                              height: 1.5,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black54,
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (!hasVoted && state.isVotingOpen) ...[
                        TextField(
                          controller: _msgCtrl,
                          maxLength: 120,
                          maxLines: 1,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment (optional)…',
                            border: OutlineInputBorder(),
                            isDense: true,
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: FilledButton.icon(
                                  onPressed: () => game.vote(
                                    true,
                                    message: _msgCtrl.text.trim(),
                                  ),
                                  icon: const Text('✋'),
                                  label: const Text(
                                    'I HAVE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.errorRed,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: FilledButton.icon(
                                  onPressed: () => game.vote(
                                    false,
                                    message: _msgCtrl.text.trim(),
                                  ),
                                  icon: const Text('🙅'),
                                  label: const Text(
                                    'NEVER',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        theme.colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (!allVoted && hasVoted) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Waiting… ${state.voteEntries.length}/${game.activePlayerCount}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ] else if (allVoted) ...[
                        ...state.voteEntries.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name(e.key),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: e.key == game.userId
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      e.value.haveI ? '✋ I have' : '🙅 Never',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: e.value.haveI
                                                ? AppColors.errorRed
                                                : AppColors.tealGreen,
                                          ),
                                    ),
                                    if (e.value.message.isNotEmpty)
                                      Text(
                                        '"${e.value.message}"',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontStyle: FontStyle.italic,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (game.canAdvanceTurnHere) ...[
                          if (!game.allPlayersVoted)
                            Text(
                              '${game.votedCount}/${game.activePlayerCount} answered',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            )
                          else if (!game.allOthersReady)
                            Text(
                              'Waiting for players to be ready…',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 46,
                            child: FilledButton(
                              onPressed:
                                  (game.allPlayersVoted && game.allOthersReady)
                                  ? () => game.requestAdvanceTurn()
                                  : null,
                              child: const Text('Next Card →'),
                            ),
                          ),
                          if (game.isOwner)
                            Builder(
                              builder: (ctx) {
                                final isPremium =
                                    ctx
                                        .read<AuthProvider>()
                                        .currentUser
                                        ?.isPremium ??
                                    false;
                                if (!isPremium) return const SizedBox.shrink();
                                return TextButton.icon(
                                  onPressed: () =>
                                      _showAddCustomCardSheet(ctx, game),
                                  icon: const Icon(
                                    Icons.add_card_outlined,
                                    size: 16,
                                  ),
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
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        else if (game.hasMarkedReady)
                          Text(
                            "✓ You're ready — waiting for the host to continue…",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.tealGreen,
                            ),
                          )
                        else
                          SizedBox(
                            height: 46,
                            child: FilledButton(
                              onPressed: game.markReadyForNext,
                              child: const Text("I'm Ready for Next Round"),
                            ),
                          ),
                      ],

                      const SizedBox(height: 8),
                      if (reactionTally.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: reactionTally.entries
                                .map(
                                  (e) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ReactionDisplay(
                                          value: e.key,
                                          size: 13,
                                          avatarConfig:
                                              AvatarConfig.isAvatarReaction(
                                                e.key,
                                              )
                                              ? context
                                                    .read<AuthProvider>()
                                                    .currentUser
                                                    ?.avatarConfig
                                              : null,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${e.value}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      EmojiReactionRow(
                        reactionsByEmoji: const {},
                        alreadyReacted: hasReacted,
                        onReact: game.sendReaction,
                        useAvatarMode:
                            context
                                .read<AuthProvider>()
                                .currentUser
                                ?.isPremiumActive ??
                            false,
                        ownAvatarConfig: context
                            .read<AuthProvider>()
                            .currentUser
                            ?.avatarConfig,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

void _showAddCustomCardSheet(BuildContext ctx, NhieGameProvider game) {
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
                'This card will be added to the deck for this session only.',
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
                  hintText: 'Never have I ever…',
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

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.history,
    required this.displayNames,
    required this.onClose,
  });
  final List<NhieRoundRecord> history;
  final Map<String, String> displayNames;
  final VoidCallback onClose;

  String _name(String id) =>
      displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

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
              final haves = round.votes.values.where((v) => v.haveI).length;
              final nevers = round.votes.values.where((v) => !v.haveI).length;
              final rt = <String, int>{};
              for (final r in round.reactions)
                rt[r.sticker] = (rt[r.sticker] ?? 0) + 1;
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
                    round.card.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '✋ $haves  •  🙅 $nevers  ${rt.isNotEmpty ? '• ' + rt.entries.map((e) => '${e.key}${e.value}').join(' ') : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: round.votes.entries
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _name(e.key),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(e.value.haveI ? '✋' : '🙅'),
                                    if (e.value.message.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '"${e.value.message}"',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontStyle: FontStyle.italic,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                            .toList(),
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
  final NhieGameProvider game;
  final Map<String, String> displayNames;
  final String roomId;
  @override
  State<_GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<_GameOverScreen> {
  bool _showHistory = false;
  String _name(String id) =>
      widget.displayNames[id] ?? (id.length > 6 ? id.substring(0, 6) : id);

  @override
  Widget build(BuildContext context) {
    final scores = widget.game.state?.scores ?? {};
    final history = widget.game.state?.history ?? [];
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    const medals = ['🥇', '🥈', '🥉'];

    if (_showHistory)
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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '🏆',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 72),
              ),
              Text(
                'Game Over!',
                textAlign: TextAlign.center,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Most 🍹 drinks wins!',
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
                        _name(e.key),
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: Text(
                        '${e.value} 🍹',
                        style: context.textTheme.titleMedium?.copyWith(
                          color: AppColors.errorRed,
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
