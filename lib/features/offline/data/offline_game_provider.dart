// // // // import 'dart:async';
// // // // import 'dart:convert';
// // // // import 'dart:io';

// // // // import 'package:flutter/foundation.dart';
// // // // import 'package:jma3a/features/games/truth_or_dare/truth_or_dare_engine.dart';
// // // // import 'package:uuid/uuid.dart';

// // // // import '../../../core/utils/app_logger.dart';
// // // // import '../../games/engine/base_game_engine.dart';
// // // // import '../../games/engine/game_registry.dart';
// // // // import '../../games/truth_or_dare/data/tod_repository.dart';
// // // // import '../../games/truth_or_dare/domain/tod_models.dart';
// // // // import '../../games/never_have_i_ever/never_have_i_ever_engine.dart';
// // // // import '../../games/meme_game/meme_game_engine.dart';
// // // // import '../data/offline_repository.dart';
// // // // import '../domain/offline_session.dart';
// // // // import '../services/lan_service.dart';

// // // // const _uuid = Uuid();

// // // // enum OfflineLoadState { idle, loading, lobby, ready, error, gameOver }

// // // // class LanChatMessage {
// // // //   const LanChatMessage({
// // // //     required this.senderId,
// // // //     required this.senderName,
// // // //     required this.text,
// // // //     required this.ts,
// // // //   });
// // // //   final String senderId;
// // // //   final String senderName;
// // // //   final String text;
// // // //   final DateTime ts;
// // // // }

// // // // class OfflineGameProvider extends ChangeNotifier {
// // // //   OfflineGameProvider({required OfflineRepository repository})
// // // //     : _repo = repository;

// // // //   final OfflineRepository _repo;
// // // //   final _lan = LanService.instance;

// // // //   OfflineSession? _session;
// // // //   BaseGameEngine? _engine;
// // // //   GameEngineState? _state;
// // // //   OfflineLoadState _loadState = OfflineLoadState.idle;
// // // //   String? _error;
// // // //   bool _isLanHost = false;
// // // //   bool _disposed = false;

// // // //   List<LanRoomDescriptor> _discoveredRooms = [];
// // // //   List<LanPeerInfo> _lanPeers = [];
// // // //   bool _lanConnected = false;
// // // //   String? _lanError;
// // // //   String? _clientPlayerId;
// // // //   String? _clientPlayerName;
// // // //   final List<LanChatMessage> _chatMessages = [];
// // // //   Map<String, dynamic>? _pendingSnapshot;
// // // //   bool _clientEngineReady = false; // engine init'd with player IDs

// // // //   StreamSubscription<LanMessage>? _msgSub;
// // // //   StreamSubscription<List<LanPeerInfo>>? _peerSub;
// // // //   StreamSubscription<String>? _disconnSub;
// // // //   Timer? _snapshotTimer;
// // // //   int _eventsSinceSnapshot = 0;
// // // //   static const _snapshotInterval = 10;

// // // //   // ── Getters ────────────────────────────────────────────────────────────────
// // // //   OfflineSession? get session => _session;
// // // //   GameEngineState? get state => _state;
// // // //   OfflineLoadState get loadState => _loadState;
// // // //   String? get error => _error;
// // // //   bool get isReady => _loadState == OfflineLoadState.ready;
// // // //   bool get isLobby => _loadState == OfflineLoadState.lobby;
// // // //   bool get isGameOver => _loadState == OfflineLoadState.gameOver;
// // // //   bool get isLanHost => _isLanHost;
// // // //   List<LanRoomDescriptor> get discoveredRooms => _discoveredRooms;
// // // //   List<LanPeerInfo> get lanPeers => _lanPeers;
// // // //   bool get lanConnected => _lanConnected;
// // // //   String? get lanError => _lanError;
// // // //   List<OfflinePlayer> get players => _session?.players ?? [];
// // // //   GameType? get gameType => _session?.gameType;
// // // //   OfflineMode? get mode => _session?.mode;
// // // //   String? get clientPlayerId => _clientPlayerId;
// // // //   List<LanChatMessage> get chatMessages => List.unmodifiable(_chatMessages);

// // // //   // ── Pass-and-play ──────────────────────────────────────────────────────────
// // // //   Future<void> startPassAndPlay({
// // // //     required GameType gameType,
// // // //     required GameConfig config,
// // // //     required List<String> playerNames,
// // // //     required String packId,
// // // //     required String packName,
// // // //   }) async {
// // // //     _setLoadState(OfflineLoadState.loading);
// // // //     try {
// // // //       final players = playerNames
// // // //           .asMap()
// // // //           .entries
// // // //           .map(
// // // //             (e) =>
// // // //                 OfflinePlayer(id: _uuid.v4(), name: e.value, seatOrder: e.key),
// // // //           )
// // // //           .toList();
// // // //       final session = OfflineSession(
// // // //         id: _uuid.v4(),
// // // //         mode: OfflineMode.passAndPlay,
// // // //         gameType: gameType,
// // // //         config: config,
// // // //         players: players,
// // // //         packId: packId,
// // // //         packName: packName,
// // // //         createdAt: DateTime.now(),
// // // //       );
// // // //       await _initEngine(session, isLanClient: false);
// // // //       _session = session;
// // // //       _state = _engine!.currentState;
// // // //       await _repo.saveSession(session);
// // // //       _startSnapshotTimer();
// // // //       _setLoadState(OfflineLoadState.ready);
// // // //     } catch (e, st) {
// // // //       AppLogger.error('startPassAndPlay failed', error: e, stackTrace: st);
// // // //       _setLoadState(OfflineLoadState.error, error: e.toString());
// // // //     }
// // // //   }

// // // //   // ── Resume ─────────────────────────────────────────────────────────────────
// // // //   Future<bool> resumeActiveSession() async {
// // // //     final session = await _repo.getActiveSession();
// // // //     if (session == null || session.stateSnapshot == null) return false;
// // // //     _setLoadState(OfflineLoadState.loading);
// // // //     try {
// // // //       await _initEngine(session, isLanClient: false);
// // // //       _engine!.restoreFromSnapshot(
// // // //         jsonDecode(session.stateSnapshot!) as Map<String, dynamic>,
// // // //       );
// // // //       _state = _engine!.currentState;
// // // //       _session = session;
// // // //       _startSnapshotTimer();
// // // //       _setLoadState(OfflineLoadState.ready);
// // // //       return true;
// // // //     } catch (e) {
// // // //       _setLoadState(OfflineLoadState.error, error: 'Could not resume.');
// // // //       return false;
// // // //     }
// // // //   }

// // // //   // ── Engine actions ─────────────────────────────────────────────────────────
// // // //   GameEngineState? advanceTurn() {
// // // //     if (_engine == null) return null;
// // // //     _state = _engine!.advanceTurn();
// // // //     _onEngineStateChanged();
// // // //     _scheduleNotify();
// // // //     if (_isLanHost) _broadcastState();
// // // //     return _state;
// // // //   }

// // // //   GameEngineState? handleEvent(GameEngineEvent event) {
// // // //     if (_engine == null) return null;
// // // //     _state = _engine!.handleEvent(event);
// // // //     _onEngineStateChanged();
// // // //     _scheduleNotify();
// // // //     if (_isLanHost) _broadcastState();
// // // //     return _state;
// // // //   }

// // // //   // ── LAN HOST: start ────────────────────────────────────────────────────────
// // // //   Future<void> startLanHost({
// // // //     required GameType gameType,
// // // //     required GameConfig config,
// // // //     required List<String> playerNames,
// // // //     required String packId,
// // // //     required String packName,
// // // //     required String hostName,
// // // //   }) async {
// // // //     _setLoadState(OfflineLoadState.loading);
// // // //     try {
// // // //       final players = playerNames
// // // //           .asMap()
// // // //           .entries
// // // //           .map(
// // // //             (e) =>
// // // //                 OfflinePlayer(id: _uuid.v4(), name: e.value, seatOrder: e.key),
// // // //           )
// // // //           .toList();

// // // //       final sessionId = _uuid.v4();
// // // //       final hostIp = await _resolveLocalIp();

// // // //       final descriptor = LanRoomDescriptor(
// // // //         sessionId: sessionId,
// // // //         hostName: hostName,
// // // //         hostAddress: hostIp,
// // // //         port: _dataPort,
// // // //         gameType: gameType,
// // // //         playerCount: players.length,
// // // //         maxPlayers: 12,
// // // //         packName: packName,
// // // //         advertisedAt: DateTime.now(),
// // // //       );

// // // //       await _lan.startHost(descriptor: descriptor);

// // // //       final session = OfflineSession(
// // // //         id: sessionId,
// // // //         mode: OfflineMode.lan,
// // // //         gameType: gameType,
// // // //         config: config,
// // // //         players: players,
// // // //         packId: packId,
// // // //         packName: packName,
// // // //         createdAt: DateTime.now(),
// // // //       );

// // // //       await _initEngine(session, isLanClient: false);
// // // //       _session = session;
// // // //       _isLanHost = true;
// // // //       _state = null; // will be set when game starts

// // // //       _subscribeLanMessages();
// // // //       _subscribePeers();
// // // //       await _repo.saveSession(session);

// // // //       _setLoadState(OfflineLoadState.lobby);
// // // //       AppLogger.info('LAN host lobby ready: $sessionId');
// // // //     } catch (e, st) {
// // // //       AppLogger.error('startLanHost failed', error: e, stackTrace: st);
// // // //       _setLoadState(OfflineLoadState.error, error: e.toString());
// // // //     }
// // // //   }

// // // //   // ── LAN HOST: start game ───────────────────────────────────────────────────
// // // //   Future<void> startLanGame() async {
// // // //     if (!_isLanHost || _session == null || _engine == null) return;

// // // //     // Engine was already init'd in startLanHost with all players (via _subscribePeers)
// // // //     _state = _engine!.currentState;

// // // //     _lan.broadcastStartGame(_session!.id);
// // // //     _lan.broadcastGameState(_session!.id, _engine!.serializeState());

// // // //     _loadState = OfflineLoadState.ready;
// // // //     _startSnapshotTimer();
// // // //     _scheduleNotify();
// // // //     AppLogger.info('LAN game started with ${_session!.players.length} players');
// // // //   }

// // // //   // ── LAN: discovery ─────────────────────────────────────────────────────────
// // // //   Future<void> startDiscovery() async {
// // // //     _discoveredRooms = [];
// // // //     await _lan.startDiscovery();
// // // //     _lan.roomStream.listen((room) {
// // // //       _discoveredRooms = [
// // // //         ..._discoveredRooms.where(
// // // //           (r) => r.sessionId != room.sessionId && !r.isStale,
// // // //         ),
// // // //         room,
// // // //       ];
// // // //       _scheduleNotify();
// // // //     });
// // // //   }

// // // //   // ── LAN CLIENT: connect ────────────────────────────────────────────────────
// // // //   Future<bool> connectToRoom({
// // // //     required LanRoomDescriptor room,
// // // //     required String playerId,
// // // //     required String playerName,
// // // //   }) async {
// // // //     _setLoadState(OfflineLoadState.loading);
// // // //     _clientPlayerId = playerId;
// // // //     _clientPlayerName = playerName;
// // // //     _isLanHost = false;
// // // //     _lanConnected = false;
// // // //     _clientEngineReady = false;
// // // //     _pendingSnapshot = null;

// // // //     // Subscribe BEFORE connecting so joinAck is never missed
// // // //     _subscribeLanMessages();

// // // //     try {
// // // //       await _lan.connectToHost(
// // // //         room: room,
// // // //         playerId: playerId,
// // // //         playerName: playerName,
// // // //       );
// // // //       _lanConnected = true;
// // // //       AppLogger.info('Connected to ${room.hostName}, waiting for joinAck…');
// // // //       return true;
// // // //     } catch (e) {
// // // //       _lanError = 'Could not connect: $e';
// // // //       _setLoadState(OfflineLoadState.error, error: _lanError!);
// // // //       return false;
// // // //     }
// // // //   }

// // // //   // ── Chat ───────────────────────────────────────────────────────────────────
// // // //   void sendChat(String text) {
// // // //     if (text.trim().isEmpty) return;
// // // //     final myId = _isLanHost
// // // //         ? (_session?.players.firstOrNull?.id ?? '')
// // // //         : (_clientPlayerId ?? '');
// // // //     final myName = _isLanHost
// // // //         ? (_session?.players.firstOrNull?.name ?? 'Host')
// // // //         : (_clientPlayerName ?? 'Player');

// // // //     final msg = LanMessage(
// // // //       type: LanMessageType.chat,
// // // //       senderId: myId,
// // // //       payload: {'name': myName, 'text': text.trim()},
// // // //       ts: DateTime.now().millisecondsSinceEpoch,
// // // //     );

// // // //     // Always add locally immediately
// // // //     _chatMessages.add(
// // // //       LanChatMessage(
// // // //         senderId: myId,
// // // //         senderName: myName,
// // // //         text: text.trim(),
// // // //         ts: DateTime.fromMillisecondsSinceEpoch(msg.ts),
// // // //       ),
// // // //     );

// // // //     if (_isLanHost) {
// // // //       _lan.broadcastMessage(msg); // send to all clients
// // // //     } else {
// // // //       _lan.sendAction(msg); // send to host (host will relay to other clients)
// // // //     }
// // // //     _scheduleNotify();
// // // //   }

// // // //   // ── Message dispatch ───────────────────────────────────────────────────────
// // // //   void _onLanMessage(LanMessage msg) {
// // // //     AppLogger.info('LAN ← ${msg.type} (host=$_isLanHost)');
// // // //     if (_isLanHost) {
// // // //       _onHostReceived(msg);
// // // //     } else {
// // // //       _onClientReceived(msg);
// // // //     }
// // // //   }

// // // //   // ── HOST: handle incoming from clients ─────────────────────────────────────
// // // //   void _onHostReceived(LanMessage msg) {
// // // //     switch (msg.type) {
// // // //       case LanMessageType.playerAction:
// // // //         if (_state == null || _engine == null) return;
// // // //         final ev = msg.payload['event'] as Map<String, dynamic>?;
// // // //         if (ev == null) return;
// // // //         try {
// // // //           final action = ev['action'] as String? ?? ev['type'] as String? ?? '';
// // // //           if (action == 'advance') {
// // // //             _state = _engine!.advanceTurn();
// // // //           } else {
// // // //             final event = _parseEvent(ev);
// // // //             if (event != null) {
// // // //               _state = _engine!.handleEvent(event);
// // // //             } else {
// // // //               AppLogger.warning('Host: unknown action "$action"');
// // // //               return;
// // // //             }
// // // //           }
// // // //           _onEngineStateChanged();
// // // //           _scheduleNotify();
// // // //           _broadcastState();
// // // //         } catch (e) {
// // // //           AppLogger.warning('Host: playerAction error: $e');
// // // //         }

// // // //       case LanMessageType.chat:
// // // //         // Add to host list and relay to other clients
// // // //         final name = msg.payload['name'] as String? ?? 'Player';
// // // //         final text = msg.payload['text'] as String? ?? '';
// // // //         _chatMessages.add(
// // // //           LanChatMessage(
// // // //             senderId: msg.senderId,
// // // //             senderName: name,
// // // //             text: text,
// // // //             ts: DateTime.fromMillisecondsSinceEpoch(msg.ts),
// // // //           ),
// // // //         );
// // // //         _lan.broadcastMessageExcept(msg, msg.senderId);
// // // //         _scheduleNotify();

// // // //       default:
// // // //         break;
// // // //     }
// // // //   }

// // // //   // ── CLIENT: handle incoming from host ──────────────────────────────────────
// // // //   void _onClientReceived(LanMessage msg) {
// // // //     switch (msg.type) {
// // // //       case LanMessageType.joinAck:
// // // //         if (_session != null) return; // already processed
// // // //         try {
// // // //           final d = LanRoomDescriptor.fromJson(msg.payload);
// // // //           _session = OfflineSession(
// // // //             id: d.sessionId,
// // // //             mode: OfflineMode.lan,
// // // //             gameType: d.gameType,
// // // //             config: const GameConfig(
// // // //               maxRounds: 10,
// // // //               turnTimerSeconds: 60,
// // // //               allowSkip: true,
// // // //               allowSpicy: false,
// // // //             ),
// // // //             players: [
// // // //               OfflinePlayer(
// // // //                 id: _clientPlayerId ?? _uuid.v4(),
// // // //                 name: _clientPlayerName ?? 'Player',
// // // //                 seatOrder: 0,
// // // //               ),
// // // //             ],
// // // //             packId: '',
// // // //             packName: d.packName,
// // // //             createdAt: DateTime.now(),
// // // //           );
// // // //           // Init engine without cards (client doesn't have the pack)
// // // //           _initClientEngine(_session!);
// // // //           AppLogger.info('Client: joinAck ok — ${d.gameType} "${d.packName}"');
// // // //         } catch (e) {
// // // //           AppLogger.error('Client: joinAck failed', error: e);
// // // //         }

// // // //       case LanMessageType.lobbyUpdate:
// // // //         final players = (msg.payload['players'] as List? ?? [])
// // // //             .map(
// // // //               (p) => OfflinePlayer(
// // // //                 id: p['id'] as String,
// // // //                 name: p['name'] as String,
// // // //                 seatOrder: p['seat'] as int? ?? 0,
// // // //               ),
// // // //             )
// // // //             .toList();
// // // //         if (_session != null) {
// // // //           _session = _session!.copyWithPlayers(players);
// // // //           AppLogger.info(
// // // //             'Client: lobby has ${players.length} players: ${players.map((p) => p.name).join(', ')}',
// // // //           );
// // // //           // Re-init engine with updated player list if not yet started
// // // //           if (!_clientEngineReady) {
// // // //             _initClientEngineWithIds(players.map((p) => p.id).toList());
// // // //           }
// // // //           // Apply pending snapshot if any
// // // //           if (_pendingSnapshot != null) {
// // // //             _tryApplySnapshot(_pendingSnapshot!);
// // // //           }
// // // //           _scheduleNotify();
// // // //         }

// // // //       case LanMessageType.startGame:
// // // //         // Game state will follow immediately — just log
// // // //         AppLogger.info('Client: startGame signal received');

// // // //       case LanMessageType.gameState:
// // // //         final snap = msg.payload['snapshot'] as Map<String, dynamic>?;
// // // //         if (snap != null) {
// // // //           AppLogger.info('Client: gameState received');
// // // //           _tryApplySnapshot(snap);
// // // //         }

// // // //       case LanMessageType.chat:
// // // //         // Only add if not from myself (already added locally in sendChat)
// // // //         if (msg.senderId == _clientPlayerId) break;
// // // //         final name = msg.payload['name'] as String? ?? 'Player';
// // // //         final text = msg.payload['text'] as String? ?? '';
// // // //         _chatMessages.add(
// // // //           LanChatMessage(
// // // //             senderId: msg.senderId,
// // // //             senderName: name,
// // // //             text: text,
// // // //             ts: DateTime.fromMillisecondsSinceEpoch(msg.ts),
// // // //           ),
// // // //         );
// // // //         _scheduleNotify();

// // // //       case LanMessageType.ping:
// // // //         // Send pong with our playerId so host can find us in _peers
// // // //         _lan.sendPong(_clientPlayerId ?? _session?.id ?? '');

// // // //       default:
// // // //         break;
// // // //     }
// // // //   }

// // // //   // ── Client engine helpers ──────────────────────────────────────────────────

// // // //   /// Create engine without cards. Player IDs will be set when lobbyUpdate arrives.
// // // //   void _initClientEngine(OfflineSession session) {
// // // //     final factory = gameRegistry[session.gameType];
// // // //     if (factory == null) {
// // // //       AppLogger.error('Client: no engine for ${session.gameType}');
// // // //       return;
// // // //     }
// // // //     _engine = factory(session.config, <dynamic>[]);
// // // //     // Don't init player order yet — wait for lobbyUpdate
// // // //     _clientEngineReady = false;
// // // //     _loadState = OfflineLoadState.lobby;
// // // //     _scheduleNotify();
// // // //   }

// // // //   /// Init engine player order once we have the full player list from lobbyUpdate.
// // // //   void _initClientEngineWithIds(List<String> ids) {
// // // //     if (_engine == null || ids.isEmpty) return;
// // // //     try {
// // // //       if (_engine is TruthOrDareEngine)
// // // //         (_engine as TruthOrDareEngine).init(playerOrder: ids);
// // // //       else if (_engine is NeverHaveIEverEngine)
// // // //         (_engine as NeverHaveIEverEngine).init(ids);
// // // //       else if (_engine is MemeGameEngine)
// // // //         (_engine as MemeGameEngine).init(ids);
// // // //       _clientEngineReady = true;
// // // //       AppLogger.info('Client engine ready with players: $ids');
// // // //     } catch (e) {
// // // //       AppLogger.warning('Client: engine init failed: $e');
// // // //     }
// // // //   }

// // // //   void _tryApplySnapshot(Map<String, dynamic> snapshot) {
// // // //     if (_engine == null) {
// // // //       _pendingSnapshot = snapshot;
// // // //       AppLogger.warning('Client: engine null, queuing snapshot');
// // // //       return;
// // // //     }

// // // //     // If engine not yet init'd with players, try now
// // // //     if (!_clientEngineReady && _session != null) {
// // // //       final ids = _session!.players.map((p) => p.id).toList();
// // // //       _initClientEngineWithIds(ids);
// // // //     }

// // // //     if (!_clientEngineReady) {
// // // //       _pendingSnapshot = snapshot;
// // // //       AppLogger.warning('Client: engine not ready, queuing snapshot');
// // // //       return;
// // // //     }

// // // //     try {
// // // //       _engine!.restoreFromSnapshot(snapshot);
// // // //       _state = _engine!.currentState;
// // // //       _loadState = OfflineLoadState.ready;
// // // //       _pendingSnapshot = null;
// // // //       _scheduleNotify();
// // // //       AppLogger.info('Client: snapshot applied, state=${_state.runtimeType}');
// // // //     } catch (e, st) {
// // // //       AppLogger.error(
// // // //         'Client: restoreFromSnapshot failed',
// // // //         error: e,
// // // //         stackTrace: st,
// // // //       );
// // // //     }
// // // //   }

// // // //   // ── Client: send action to host ────────────────────────────────────────────
// // // //   Future<void> sendLanAction(Map<String, dynamic> payload) async {
// // // //     if (_isLanHost || !_lanConnected) return;
// // // //     // Wrap in 'event' key for host's _onHostReceived
// // // //     final wrapped = payload.containsKey('event') ? payload : {'event': payload};
// // // //     _lan.sendAction(
// // // //       LanMessage(
// // // //         type: LanMessageType.playerAction,
// // // //         senderId: _clientPlayerId ?? '',
// // // //         payload: wrapped,
// // // //         ts: DateTime.now().millisecondsSinceEpoch,
// // // //       ),
// // // //     );
// // // //   }

// // // //   // ── Parse event ────────────────────────────────────────────────────────────
// // // //   GameEngineEvent? _parseEvent(Map<String, dynamic> m) {
// // // //     final action = m['action'] as String? ?? m['type'] as String? ?? '';
// // // //     final userId = m['user_id'] as String? ?? m['userId'] as String? ?? '';
// // // //     final ts = m['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
// // // //     return switch (action) {
// // // //       'tod_choice' || 'choice' => TodChoiceEvent(
// // // //         userId: userId,
// // // //         ts: ts,
// // // //         cardType: (m['card_type'] ?? m['cardType']) == 'dare'
// // // //             ? TodCardType.dare
// // // //             : TodCardType.truth,
// // // //       ),
// // // //       'tod_complete' || 'complete' => TodCompleteEvent(
// // // //         userId: userId,
// // // //         ts: ts,
// // // //         response: m['response'] as String? ?? '',
// // // //         proofImageB64: m['proof_image'] as String? ?? '',
// // // //       ),
// // // //       'tod_react' || 'react' => TodReactEvent(
// // // //         userId: userId,
// // // //         ts: ts,
// // // //         emoji: m['emoji'] as String? ?? '👍',
// // // //       ),
// // // //       'tod_vote_response' ||
// // // //       'vote_response' => TodVoteResponseEvent(userId: userId, ts: ts),
// // // //       'tod_skip' || 'skip' => TodSkipEvent(userId: userId, ts: ts),
// // // //       _ => null,
// // // //     };
// // // //   }

// // // //   // ── Broadcast state from host ──────────────────────────────────────────────
// // // //   void _broadcastState() {
// // // //     if (!_isLanHost || _engine == null || _session == null) return;
// // // //     _lan.broadcastGameState(_session!.id, _engine!.serializeState());
// // // //   }

// // // //   // ── Engine init (host / pass-and-play) ────────────────────────────────────
// // // //   Future<void> _initEngine(
// // // //     OfflineSession session, {
// // // //     required bool isLanClient,
// // // //   }) async {
// // // //     if (isLanClient) {
// // // //       // Client: create engine without cards, player IDs set later
// // // //       _initClientEngine(session);
// // // //       return;
// // // //     }
// // // //     final cards = await _loadCards(session);
// // // //     final factory = gameRegistry[session.gameType];
// // // //     if (factory == null) throw Exception('No engine for ${session.gameType}');
// // // //     _engine = factory(session.config, cards);
// // // //     final ids = session.players.map((p) => p.id).toList();
// // // //     if (_engine is TruthOrDareEngine)
// // // //       (_engine as TruthOrDareEngine).init(playerOrder: ids);
// // // //     else if (_engine is NeverHaveIEverEngine)
// // // //       (_engine as NeverHaveIEverEngine).init(ids);
// // // //     else if (_engine is MemeGameEngine)
// // // //       (_engine as MemeGameEngine).init(ids);
// // // //   }

// // // //   Future<List<dynamic>> _loadCards(OfflineSession session) async {
// // // //     final todCards = await TodRepository.instance.loadCardsFromCache(
// // // //       packId: session.packId,
// // // //       language: session.config.language,
// // // //       allowSpicy: session.config.allowSpicy,
// // // //     );
// // // //     if (todCards.isEmpty && session.packId.isNotEmpty)
// // // //       throw Exception('No cards for "${session.packName}". Download it first.');
// // // //     return switch (session.gameType) {
// // // //       GameType.neverHaveIEver => todCards.map((c) {
// // // //         var t = c.content;
// // // //         for (final p in ['Never have I ever ', 'never have I ever '])
// // // //           if (t.startsWith(p)) {
// // // //             t = t.substring(p.length);
// // // //             break;
// // // //           }
// // // //         if (t.isNotEmpty) t = t[0].toUpperCase() + t.substring(1);
// // // //         return NhieCard(id: c.id, content: t, difficulty: c.difficulty.name);
// // // //       }).toList(),
// // // //       GameType.memeGame =>
// // // //         todCards.map((c) => MemePrompt(id: c.id, caption: c.content)).toList(),
// // // //       _ => todCards,
// // // //     };
// // // //   }

// // // //   // ── Peer subscription (host only) ─────────────────────────────────────────
// // // //   void _subscribePeers() {
// // // //     _peerSub?.cancel();
// // // //     _peerSub = _lan.peerStream.listen((peers) {
// // // //       _lanPeers = peers;
// // // //       if (_isLanHost && _session != null) {
// // // //         final host = _session!.players.first;
// // // //         final all = [
// // // //           host,
// // // //           ...peers.asMap().entries.map(
// // // //             (e) => OfflinePlayer(
// // // //               id: e.value.playerId,
// // // //               name: e.value.playerName,
// // // //               seatOrder: e.key + 1,
// // // //             ),
// // // //           ),
// // // //         ];
// // // //         _session = _session!.copyWithPlayers(all);

// // // //         // Re-init engine player order if game not started yet
// // // //         if (_state == null && _engine != null) {
// // // //           final ids = all.map((p) => p.id).toList();
// // // //           try {
// // // //             if (_engine is TruthOrDareEngine)
// // // //               (_engine as TruthOrDareEngine).init(playerOrder: ids);
// // // //             else if (_engine is NeverHaveIEverEngine)
// // // //               (_engine as NeverHaveIEverEngine).init(ids);
// // // //             else if (_engine is MemeGameEngine)
// // // //               (_engine as MemeGameEngine).init(ids);
// // // //             AppLogger.info('Host engine re-inited: ${ids.length} players');
// // // //           } catch (e) {
// // // //             AppLogger.warning('Host engine re-init failed: $e');
// // // //           }
// // // //         }

// // // //         _lan.broadcastLobbyUpdate(_session!.id, all);

// // // //         // If game running, send state to new joiner
// // // //         if (_state != null) {
// // // //           Future.delayed(const Duration(milliseconds: 500), _broadcastState);
// // // //         }
// // // //       }
// // // //       _scheduleNotify();
// // // //     });
// // // //   }

// // // //   // ── Message subscription ───────────────────────────────────────────────────
// // // //   void _subscribeLanMessages() {
// // // //     _msgSub?.cancel();
// // // //     _msgSub = _lan.messageStream.listen(
// // // //       _onLanMessage,
// // // //       onError: (e) => AppLogger.warning('LAN stream error: $e'),
// // // //     );

// // // //     _disconnSub?.cancel();
// // // //     _disconnSub = _lan.disconnectStream.listen((playerId) {
// // // //       if (_session != null) {
// // // //         _session = _session!.copyWithPlayers(
// // // //           _session!.players
// // // //               .map((p) => p.id == playerId ? p.copyWith(isConnected: false) : p)
// // // //               .toList(),
// // // //         );
// // // //         _scheduleNotify();
// // // //       }
// // // //     });
// // // //   }

// // // //   // ── Snapshot ───────────────────────────────────────────────────────────────
// // // //   void _onEngineStateChanged() {
// // // //     _eventsSinceSnapshot++;
// // // //     if (_engine?.isGameOver == true) {
// // // //       _loadState = OfflineLoadState.gameOver;
// // // //       _repo.endSession(_session?.id ?? '');
// // // //     }
// // // //     if (_eventsSinceSnapshot >= _snapshotInterval) {
// // // //       _persistSnapshot();
// // // //       _eventsSinceSnapshot = 0;
// // // //     }
// // // //   }

// // // //   void _startSnapshotTimer() {
// // // //     _snapshotTimer?.cancel();
// // // //     _snapshotTimer = Timer.periodic(
// // // //       const Duration(seconds: 15),
// // // //       (_) => _persistSnapshot(),
// // // //     );
// // // //   }

// // // //   Future<void> _persistSnapshot() async {
// // // //     if (_session == null || _engine == null) return;
// // // //     try {
// // // //       await _repo.updateSnapshot(
// // // //         _session!.id,
// // // //         jsonEncode(_engine!.serializeState()),
// // // //       );
// // // //     } catch (_) {}
// // // //   }

// // // //   // ── Notify helpers ─────────────────────────────────────────────────────────

// // // //   /// Schedule notification for next microtask — avoids calling during build.
// // // //   void _scheduleNotify() {
// // // //     if (_disposed) return;
// // // //     // Use microtask so we never call notifyListeners() synchronously
// // // //     // from a socket callback while Flutter is building
// // // //     scheduleMicrotask(() {
// // // //       if (!_disposed) notifyListeners();
// // // //     });
// // // //   }

// // // //   void _setLoadState(OfflineLoadState s, {String? error}) {
// // // //     _loadState = s;
// // // //     _error = error;
// // // //     _scheduleNotify();
// // // //   }

// // // //   // ── Public helpers ─────────────────────────────────────────────────────────
// // // //   void endGame() {
// // // //     _loadState = OfflineLoadState.gameOver;
// // // //     _repo.endSession(_session?.id ?? '');
// // // //     _scheduleNotify();
// // // //   }

// // // //   void reset() {
// // // //     _session = null;
// // // //     _engine = null;
// // // //     _state = null;
// // // //     _loadState = OfflineLoadState.idle;
// // // //     _error = null;
// // // //     _isLanHost = false;
// // // //     _discoveredRooms = [];
// // // //     _lanPeers = [];
// // // //     _lanConnected = false;
// // // //     _chatMessages.clear();
// // // //     _pendingSnapshot = null;
// // // //     _clientEngineReady = false;
// // // //     _scheduleNotify();
// // // //   }

// // // //   // ── Helpers ────────────────────────────────────────────────────────────────
// // // //   Future<String> _resolveLocalIp() async {
// // // //     try {
// // // //       final ifaces = await NetworkInterface.list(
// // // //         type: InternetAddressType.IPv4,
// // // //         includeLinkLocal: false,
// // // //       );
// // // //       for (final iface in ifaces) {
// // // //         final n = iface.name.toLowerCase();
// // // //         if (n.contains('wlan') ||
// // // //             n.contains('wifi') ||
// // // //             n.contains('ap') ||
// // // //             n.contains('en0')) {
// // // //           return iface.addresses.first.address;
// // // //         }
// // // //       }
// // // //       if (ifaces.isNotEmpty) return ifaces.first.addresses.first.address;
// // // //     } catch (_) {}
// // // //     return '0.0.0.0';
// // // //   }

// // // //   static const _dataPort = 47890;

// // // //   @override
// // // //   void dispose() {
// // // //     _disposed = true;
// // // //     _snapshotTimer?.cancel();
// // // //     _msgSub?.cancel();
// // // //     _peerSub?.cancel();
// // // //     _disconnSub?.cancel();
// // // //     _lan.stop().ignore();
// // // //     super.dispose();
// // // //   }
// // // // }

// // // import 'dart:async';
// // // import 'dart:convert';
// // // import 'dart:io';

// // // import 'package:flutter/foundation.dart';
// // // import 'package:jma3a/features/games/truth_or_dare/truth_or_dare_engine.dart';
// // // import 'package:jma3a/features/offline/data/offline_repository.dart';
// // // import 'package:uuid/uuid.dart';

// // // import '../../../core/utils/app_logger.dart';
// // // import '../../games/engine/base_game_engine.dart';
// // // import '../../games/engine/game_registry.dart';
// // // import '../../games/truth_or_dare/data/tod_repository.dart';
// // // import '../../games/truth_or_dare/domain/tod_models.dart';
// // // import '../../games/never_have_i_ever/never_have_i_ever_engine.dart';
// // // import '../../games/meme_game/meme_game_engine.dart';
// // // import '../domain/offline_session.dart';
// // // import '../services/lan_service.dart';

// // // const _uuid = Uuid();

// // // enum OfflineLoadState { idle, loading, lobby, ready, error, gameOver }

// // // class LanChatMessage {
// // //   const LanChatMessage({
// // //     required this.senderId,
// // //     required this.senderName,
// // //     required this.text,
// // //     required this.ts,
// // //   });
// // //   final String senderId;
// // //   final String senderName;
// // //   final String text;
// // //   final DateTime ts;
// // // }

// // // class OfflineGameProvider extends ChangeNotifier {
// // //   OfflineGameProvider({required OfflineRepository repository})
// // //     : _repo = repository;

// // //   final OfflineRepository _repo;
// // //   final _lan = LanService.instance;

// // //   OfflineSession? _session;
// // //   BaseGameEngine? _engine;
// // //   GameEngineState? _state;
// // //   OfflineLoadState _loadState = OfflineLoadState.idle;
// // //   String? _error;
// // //   bool _isLanHost = false;
// // //   bool _disposed = false;

// // //   List<LanRoomDescriptor> _discoveredRooms = [];
// // //   List<LanPeerInfo> _lanPeers = [];
// // //   bool _lanConnected = false;
// // //   String? _lanError;
// // //   String? _clientPlayerId;
// // //   String? _clientPlayerName;
// // //   final List<LanChatMessage> _chatMessages = [];
// // //   Map<String, dynamic>? _pendingSnapshot;
// // //   bool _clientEngineReady = false; // engine init'd with player IDs

// // //   StreamSubscription<LanMessage>? _msgSub;
// // //   StreamSubscription<List<LanPeerInfo>>? _peerSub;
// // //   StreamSubscription<String>? _disconnSub;
// // //   Timer? _snapshotTimer;
// // //   int _eventsSinceSnapshot = 0;
// // //   static const _snapshotInterval = 10;

// // //   // ── Getters ────────────────────────────────────────────────────────────────
// // //   OfflineSession? get session => _session;
// // //   GameEngineState? get state => _state;
// // //   OfflineLoadState get loadState => _loadState;
// // //   String? get error => _error;
// // //   bool get isReady => _loadState == OfflineLoadState.ready;
// // //   bool get isLobby => _loadState == OfflineLoadState.lobby;
// // //   bool get isGameOver => _loadState == OfflineLoadState.gameOver;
// // //   bool get isLanHost => _isLanHost;
// // //   List<LanRoomDescriptor> get discoveredRooms => _discoveredRooms;
// // //   List<LanPeerInfo> get lanPeers => _lanPeers;
// // //   bool get lanConnected => _lanConnected;
// // //   String? get lanError => _lanError;
// // //   List<OfflinePlayer> get players => _session?.players ?? [];
// // //   GameType? get gameType => _session?.gameType;
// // //   OfflineMode? get mode => _session?.mode;
// // //   String? get clientPlayerId => _clientPlayerId;
// // //   List<LanChatMessage> get chatMessages => List.unmodifiable(_chatMessages);

// // //   // ── Pass-and-play ──────────────────────────────────────────────────────────
// // //   Future<void> startPassAndPlay({
// // //     required GameType gameType,
// // //     required GameConfig config,
// // //     required List<String> playerNames,
// // //     required String packId,
// // //     required String packName,
// // //   }) async {
// // //     _setLoadState(OfflineLoadState.loading);
// // //     try {
// // //       final players = playerNames
// // //           .asMap()
// // //           .entries
// // //           .map(
// // //             (e) =>
// // //                 OfflinePlayer(id: _uuid.v4(), name: e.value, seatOrder: e.key),
// // //           )
// // //           .toList();
// // //       final session = OfflineSession(
// // //         id: _uuid.v4(),
// // //         mode: OfflineMode.passAndPlay,
// // //         gameType: gameType,
// // //         config: config,
// // //         players: players,
// // //         packId: packId,
// // //         packName: packName,
// // //         createdAt: DateTime.now(),
// // //       );
// // //       await _initEngine(session, isLanClient: false);
// // //       _session = session;
// // //       _state = _engine!.currentState;
// // //       await _repo.saveSession(session);
// // //       _startSnapshotTimer();
// // //       _setLoadState(OfflineLoadState.ready);
// // //     } catch (e, st) {
// // //       AppLogger.error('startPassAndPlay failed', error: e, stackTrace: st);
// // //       _setLoadState(OfflineLoadState.error, error: e.toString());
// // //     }
// // //   }

// // //   // ── Resume ─────────────────────────────────────────────────────────────────
// // //   Future<bool> resumeActiveSession() async {
// // //     final session = await _repo.getActiveSession();
// // //     if (session == null || session.stateSnapshot == null) return false;
// // //     _setLoadState(OfflineLoadState.loading);
// // //     try {
// // //       await _initEngine(session, isLanClient: false);
// // //       _engine!.restoreFromSnapshot(
// // //         jsonDecode(session.stateSnapshot!) as Map<String, dynamic>,
// // //       );
// // //       _state = _engine!.currentState;
// // //       _session = session;
// // //       _startSnapshotTimer();
// // //       _setLoadState(OfflineLoadState.ready);
// // //       return true;
// // //     } catch (e) {
// // //       _setLoadState(OfflineLoadState.error, error: 'Could not resume.');
// // //       return false;
// // //     }
// // //   }

// // //   // ── Engine actions ─────────────────────────────────────────────────────────
// // //   GameEngineState? advanceTurn() {
// // //     if (_engine == null) return null;
// // //     _state = _engine!.advanceTurn();
// // //     _onEngineStateChanged();
// // //     _scheduleNotify();
// // //     if (_isLanHost) _broadcastState();
// // //     return _state;
// // //   }

// // //   GameEngineState? handleEvent(GameEngineEvent event) {
// // //     if (_engine == null) return null;
// // //     _state = _engine!.handleEvent(event);
// // //     _onEngineStateChanged();
// // //     _scheduleNotify();
// // //     if (_isLanHost) _broadcastState();
// // //     return _state;
// // //   }

// // //   // ── LAN HOST: start ────────────────────────────────────────────────────────
// // //   Future<void> startLanHost({
// // //     required GameType gameType,
// // //     required GameConfig config,
// // //     required List<String> playerNames,
// // //     required String packId,
// // //     required String packName,
// // //     required String hostName,
// // //   }) async {
// // //     _setLoadState(OfflineLoadState.loading);
// // //     try {
// // //       final players = playerNames
// // //           .asMap()
// // //           .entries
// // //           .map(
// // //             (e) =>
// // //                 OfflinePlayer(id: _uuid.v4(), name: e.value, seatOrder: e.key),
// // //           )
// // //           .toList();

// // //       final sessionId = _uuid.v4();
// // //       final hostIp = await _resolveLocalIp();

// // //       final descriptor = LanRoomDescriptor(
// // //         sessionId: sessionId,
// // //         hostName: hostName,
// // //         hostAddress: hostIp,
// // //         port: _dataPort,
// // //         gameType: gameType,
// // //         playerCount: players.length,
// // //         maxPlayers: 12,
// // //         packName: packName,
// // //         advertisedAt: DateTime.now(),
// // //       );

// // //       await _lan.startHost(descriptor: descriptor);

// // //       final session = OfflineSession(
// // //         id: sessionId,
// // //         mode: OfflineMode.lan,
// // //         gameType: gameType,
// // //         config: config,
// // //         players: players,
// // //         packId: packId,
// // //         packName: packName,
// // //         createdAt: DateTime.now(),
// // //       );

// // //       await _initEngine(session, isLanClient: false);
// // //       _session = session;
// // //       _isLanHost = true;
// // //       _state = null; // will be set when game starts

// // //       _subscribeLanMessages();
// // //       _subscribePeers();
// // //       await _repo.saveSession(session);

// // //       _setLoadState(OfflineLoadState.lobby);
// // //       AppLogger.info('LAN host lobby ready: $sessionId');
// // //     } catch (e, st) {
// // //       AppLogger.error('startLanHost failed', error: e, stackTrace: st);
// // //       _setLoadState(OfflineLoadState.error, error: e.toString());
// // //     }
// // //   }

// // //   // ── LAN HOST: start game ───────────────────────────────────────────────────
// // //   Future<void> startLanGame() async {
// // //     if (!_isLanHost || _session == null || _engine == null) return;

// // //     // Engine was already init'd in startLanHost with all players (via _subscribePeers)
// // //     _state = _engine!.currentState;

// // //     _lan.broadcastStartGame(_session!.id);
// // //     _lan.broadcastGameState(_session!.id, _engine!.serializeState());

// // //     _loadState = OfflineLoadState.ready;
// // //     _startSnapshotTimer();
// // //     _scheduleNotify();
// // //     AppLogger.info('LAN game started with ${_session!.players.length} players');
// // //   }

// // //   // ── LAN: discovery ─────────────────────────────────────────────────────────
// // //   Future<void> startDiscovery() async {
// // //     _discoveredRooms = [];
// // //     await _lan.startDiscovery();
// // //     _lan.roomStream.listen((room) {
// // //       _discoveredRooms = [
// // //         ..._discoveredRooms.where(
// // //           (r) => r.sessionId != room.sessionId && !r.isStale,
// // //         ),
// // //         room,
// // //       ];
// // //       _scheduleNotify();
// // //     });
// // //   }

// // //   // ── LAN CLIENT: connect ────────────────────────────────────────────────────
// // //   Future<bool> connectToRoom({
// // //     required LanRoomDescriptor room,
// // //     required String playerId,
// // //     required String playerName,
// // //   }) async {
// // //     _setLoadState(OfflineLoadState.loading);
// // //     _clientPlayerId = playerId;
// // //     _clientPlayerName = playerName;
// // //     _isLanHost = false;
// // //     _lanConnected = false;
// // //     _clientEngineReady = false;
// // //     _pendingSnapshot = null;

// // //     // Subscribe BEFORE connecting so joinAck is never missed
// // //     _subscribeLanMessages();

// // //     try {
// // //       await _lan.connectToHost(
// // //         room: room,
// // //         playerId: playerId,
// // //         playerName: playerName,
// // //       );
// // //       _lanConnected = true;
// // //       AppLogger.info('Connected to ${room.hostName}, waiting for joinAck…');
// // //       return true;
// // //     } catch (e) {
// // //       _lanError = 'Could not connect: $e';
// // //       _setLoadState(OfflineLoadState.error, error: _lanError!);
// // //       return false;
// // //     }
// // //   }

// // //   // ── Chat ───────────────────────────────────────────────────────────────────
// // //   void sendChat(String text) {
// // //     if (text.trim().isEmpty) return;
// // //     final myId = _isLanHost
// // //         ? (_session?.players.firstOrNull?.id ?? '')
// // //         : (_clientPlayerId ?? '');
// // //     final myName = _isLanHost
// // //         ? (_session?.players.firstOrNull?.name ?? 'Host')
// // //         : (_clientPlayerName ?? 'Player');

// // //     final msg = LanMessage(
// // //       type: LanMessageType.chat,
// // //       senderId: myId,
// // //       payload: {'name': myName, 'text': text.trim()},
// // //       ts: DateTime.now().millisecondsSinceEpoch,
// // //     );

// // //     // Always add locally immediately
// // //     _chatMessages.add(
// // //       LanChatMessage(
// // //         senderId: myId,
// // //         senderName: myName,
// // //         text: text.trim(),
// // //         ts: DateTime.fromMillisecondsSinceEpoch(msg.ts),
// // //       ),
// // //     );

// // //     if (_isLanHost) {
// // //       _lan.broadcastMessage(msg); // send to all clients
// // //     } else {
// // //       _lan.sendAction(msg); // send to host (host will relay to other clients)
// // //     }
// // //     _scheduleNotify();
// // //   }

// // //   // ── Message dispatch ───────────────────────────────────────────────────────
// // //   void _onLanMessage(LanMessage msg) {
// // //     AppLogger.info('LAN ← ${msg.type} (host=$_isLanHost)');
// // //     if (_isLanHost) {
// // //       _onHostReceived(msg);
// // //     } else {
// // //       _onClientReceived(msg);
// // //     }
// // //   }

// // //   // ── HOST: handle incoming from clients ─────────────────────────────────────
// // //   void _onHostReceived(LanMessage msg) {
// // //     switch (msg.type) {
// // //       case LanMessageType.playerAction:
// // //         if (_state == null || _engine == null) return;
// // //         final ev = msg.payload['event'] as Map<String, dynamic>?;
// // //         if (ev == null) return;
// // //         try {
// // //           final action = ev['action'] as String? ?? ev['type'] as String? ?? '';
// // //           if (action == 'advance') {
// // //             _state = _engine!.advanceTurn();
// // //           } else {
// // //             final event = _parseEvent(ev);
// // //             if (event != null) {
// // //               _state = _engine!.handleEvent(event);
// // //             } else {
// // //               AppLogger.warning('Host: unknown action "$action"');
// // //               return;
// // //             }
// // //           }
// // //           _onEngineStateChanged();
// // //           _scheduleNotify();
// // //           _broadcastState();
// // //         } catch (e) {
// // //           AppLogger.warning('Host: playerAction error: $e');
// // //         }

// // //       case LanMessageType.chat:
// // //         // Add to host list and relay to other clients
// // //         final name = msg.payload['name'] as String? ?? 'Player';
// // //         final text = msg.payload['text'] as String? ?? '';
// // //         _chatMessages.add(
// // //           LanChatMessage(
// // //             senderId: msg.senderId,
// // //             senderName: name,
// // //             text: text,
// // //             ts: DateTime.fromMillisecondsSinceEpoch(msg.ts),
// // //           ),
// // //         );
// // //         _lan.broadcastMessageExcept(msg, msg.senderId);
// // //         _scheduleNotify();

// // //       default:
// // //         break;
// // //     }
// // //   }

// // //   // ── CLIENT: handle incoming from host ──────────────────────────────────────
// // //   void _onClientReceived(LanMessage msg) {
// // //     switch (msg.type) {
// // //       case LanMessageType.joinAck:
// // //         if (_session != null) return; // already processed
// // //         try {
// // //           final d = LanRoomDescriptor.fromJson(msg.payload);
// // //           _session = OfflineSession(
// // //             id: d.sessionId,
// // //             mode: OfflineMode.lan,
// // //             gameType: d.gameType,
// // //             config: const GameConfig(
// // //               maxRounds: 10,
// // //               turnTimerSeconds: 60,
// // //               allowSkip: true,
// // //               allowSpicy: false,
// // //             ),
// // //             players: [
// // //               OfflinePlayer(
// // //                 id: _clientPlayerId ?? _uuid.v4(),
// // //                 name: _clientPlayerName ?? 'Player',
// // //                 seatOrder: 0,
// // //               ),
// // //             ],
// // //             packId: '',
// // //             packName: d.packName,
// // //             createdAt: DateTime.now(),
// // //           );
// // //           // Init engine without cards (client doesn't have the pack)
// // //           _initClientEngine(_session!);
// // //           AppLogger.info('Client: joinAck ok — ${d.gameType} "${d.packName}"');
// // //         } catch (e) {
// // //           AppLogger.error('Client: joinAck failed', error: e);
// // //         }

// // //       case LanMessageType.lobbyUpdate:
// // //         final players = (msg.payload['players'] as List? ?? [])
// // //             .map(
// // //               (p) => OfflinePlayer(
// // //                 id: p['id'] as String,
// // //                 name: p['name'] as String,
// // //                 seatOrder: p['seat'] as int? ?? 0,
// // //               ),
// // //             )
// // //             .toList();
// // //         if (_session != null) {
// // //           _session = _session!.copyWithPlayers(players);

// // //           // Adopt the UUID the host assigned us (matched by name)
// // //           // The host creates players with uuid.v4() — we must use that
// // //           // ID as our identity so isMyTurn works correctly
// // //           final myEntry = players.firstWhere(
// // //             (p) => p.name == _clientPlayerName,
// // //             orElse: () =>
// // //                 players.lastOrNull ??
// // //                 OfflinePlayer(
// // //                   id: _clientPlayerId ?? '',
// // //                   name: '',
// // //                   seatOrder: 0,
// // //                 ),
// // //           );
// // //           if (myEntry.id != _clientPlayerId) {
// // //             AppLogger.info(
// // //               'Client: adopting host-assigned ID '
// // //               '${myEntry.id} (was $_clientPlayerId)',
// // //             );
// // //             _clientPlayerId = myEntry.id;
// // //           }

// // //           AppLogger.info(
// // //             'Client: lobby has ${players.length} players: '
// // //             '${players.map((p) => p.name).join(', ')}',
// // //           );

// // //           if (!_clientEngineReady) {
// // //             _initClientEngineWithIds(players.map((p) => p.id).toList());
// // //           }
// // //           if (_pendingSnapshot != null) {
// // //             _tryApplySnapshot(_pendingSnapshot!);
// // //           }
// // //           _scheduleNotify();
// // //         }

// // //       case LanMessageType.startGame:
// // //         // Game state will follow immediately — just log
// // //         AppLogger.info('Client: startGame signal received');

// // //       case LanMessageType.gameState:
// // //         final snap = msg.payload['snapshot'] as Map<String, dynamic>?;
// // //         if (snap != null) {
// // //           AppLogger.info('Client: gameState received');
// // //           _tryApplySnapshot(snap);
// // //         }

// // //       case LanMessageType.chat:
// // //         // Only add if not from myself (already added locally in sendChat)
// // //         if (msg.senderId == _clientPlayerId) break;
// // //         final name = msg.payload['name'] as String? ?? 'Player';
// // //         final text = msg.payload['text'] as String? ?? '';
// // //         _chatMessages.add(
// // //           LanChatMessage(
// // //             senderId: msg.senderId,
// // //             senderName: name,
// // //             text: text,
// // //             ts: DateTime.fromMillisecondsSinceEpoch(msg.ts),
// // //           ),
// // //         );
// // //         _scheduleNotify();

// // //       case LanMessageType.ping:
// // //         // Send pong with our playerId so host can find us in _peers
// // //         _lan.sendPong(_clientPlayerId ?? _session?.id ?? '');

// // //       default:
// // //         break;
// // //     }
// // //   }

// // //   // ── Client engine helpers ──────────────────────────────────────────────────

// // //   /// Create engine without cards. Player IDs will be set when lobbyUpdate arrives.
// // //   void _initClientEngine(OfflineSession session) {
// // //     final factory = gameRegistry[session.gameType];
// // //     if (factory == null) {
// // //       AppLogger.error('Client: no engine for ${session.gameType}');
// // //       return;
// // //     }
// // //     _engine = factory(session.config, <dynamic>[]);
// // //     // Don't init player order yet — wait for lobbyUpdate
// // //     _clientEngineReady = false;
// // //     _loadState = OfflineLoadState.lobby;
// // //     _scheduleNotify();
// // //   }

// // //   /// Init engine player order once we have the full player list from lobbyUpdate.
// // //   void _initClientEngineWithIds(List<String> ids) {
// // //     if (_engine == null || ids.isEmpty) return;
// // //     try {
// // //       if (_engine is TruthOrDareEngine)
// // //         (_engine as TruthOrDareEngine).init(playerOrder: ids);
// // //       else if (_engine is NeverHaveIEverEngine)
// // //         (_engine as NeverHaveIEverEngine).init(ids);
// // //       else if (_engine is MemeGameEngine)
// // //         (_engine as MemeGameEngine).init(ids);
// // //       _clientEngineReady = true;
// // //       AppLogger.info('Client engine ready with players: $ids');
// // //     } catch (e) {
// // //       AppLogger.warning('Client: engine init failed: $e');
// // //     }
// // //   }

// // //   void _tryApplySnapshot(Map<String, dynamic> snapshot) {
// // //     if (_engine == null) {
// // //       _pendingSnapshot = snapshot;
// // //       AppLogger.warning('Client: engine null, queuing snapshot');
// // //       return;
// // //     }

// // //     // If engine not yet init'd with players, try now
// // //     if (!_clientEngineReady && _session != null) {
// // //       final ids = _session!.players.map((p) => p.id).toList();
// // //       _initClientEngineWithIds(ids);
// // //     }

// // //     if (!_clientEngineReady) {
// // //       _pendingSnapshot = snapshot;
// // //       AppLogger.warning('Client: engine not ready, queuing snapshot');
// // //       return;
// // //     }

// // //     try {
// // //       _engine!.restoreFromSnapshot(snapshot);
// // //       _state = _engine!.currentState;
// // //       _loadState = OfflineLoadState.ready;
// // //       _pendingSnapshot = null;
// // //       _scheduleNotify();
// // //       AppLogger.info('Client: snapshot applied, state=${_state.runtimeType}');
// // //     } catch (e, st) {
// // //       AppLogger.error(
// // //         'Client: restoreFromSnapshot failed',
// // //         error: e,
// // //         stackTrace: st,
// // //       );
// // //     }
// // //   }

// // //   // ── Client: send action to host ────────────────────────────────────────────
// // //   Future<void> sendLanAction(Map<String, dynamic> payload) async {
// // //     if (_isLanHost || !_lanConnected) return;
// // //     // Wrap in 'event' key for host's _onHostReceived
// // //     final wrapped = payload.containsKey('event') ? payload : {'event': payload};
// // //     _lan.sendAction(
// // //       LanMessage(
// // //         type: LanMessageType.playerAction,
// // //         senderId: _clientPlayerId ?? '',
// // //         payload: wrapped,
// // //         ts: DateTime.now().millisecondsSinceEpoch,
// // //       ),
// // //     );
// // //   }

// // //   // ── Parse event ────────────────────────────────────────────────────────────
// // //   GameEngineEvent? _parseEvent(Map<String, dynamic> m) {
// // //     final action = m['action'] as String? ?? m['type'] as String? ?? '';
// // //     final userId = m['user_id'] as String? ?? m['userId'] as String? ?? '';
// // //     final ts = m['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
// // //     return switch (action) {
// // //       // ── ToD ──────────────────────────────────────────────────────────────
// // //       'tod_choice' || 'choice' => TodChoiceEvent(
// // //         userId: userId,
// // //         ts: ts,
// // //         cardType: (m['card_type'] ?? m['cardType']) == 'dare'
// // //             ? TodCardType.dare
// // //             : TodCardType.truth,
// // //       ),
// // //       'tod_complete' || 'complete' => TodCompleteEvent(
// // //         userId: userId,
// // //         ts: ts,
// // //         response: m['response'] as String? ?? '',
// // //         proofImageB64: m['proof_image'] as String? ?? '',
// // //       ),
// // //       'tod_react' || 'react' => TodReactEvent(
// // //         userId: userId,
// // //         ts: ts,
// // //         emoji: m['emoji'] as String? ?? '👍',
// // //       ),
// // //       'tod_vote_response' ||
// // //       'vote_response' => TodVoteResponseEvent(userId: userId, ts: ts),
// // //       'tod_skip' || 'skip' => TodSkipEvent(userId: userId, ts: ts),
// // //       // ── NHIE ─────────────────────────────────────────────────────────────
// // //       'nhie_vote' => NhieVoteEvent(
// // //         userId: userId,
// // //         ts: ts,
// // //         haveI: m['have_i'] as bool? ?? false,
// // //         message: m['message'] as String? ?? '',
// // //       ),
// // //       'nhie_react' => NhieReactionEvent(
// // //         userId: userId,
// // //         ts: ts,
// // //         sticker: m['sticker'] as String? ?? '',
// // //       ),
// // //       // ── Meme ─────────────────────────────────────────────────────────────
// // //       'meme_submit' => MemeSubmitEvent(
// // //         userId: userId,
// // //         ts: ts,
// // //         caption: m['caption'] as String? ?? '',
// // //         stickerChoice: m['sticker_choice'] as String? ?? '',
// // //       ),
// // //       'meme_vote' => MemeVoteEvent(
// // //         userId: userId,
// // //         ts: ts,
// // //         targetUserId: m['target_user_id'] as String? ?? '',
// // //       ),
// // //       'meme_react' => MemeReactEvent(
// // //         userId: userId,
// // //         ts: ts,
// // //         targetUserId: m['target_user_id'] as String? ?? '',
// // //         emoji: m['emoji'] as String? ?? '👍',
// // //       ),
// // //       _ => null,
// // //     };
// // //   }

// // //   // ── Broadcast state from host ──────────────────────────────────────────────
// // //   void _broadcastState() {
// // //     if (!_isLanHost || _engine == null || _session == null) return;
// // //     _lan.broadcastGameState(_session!.id, _engine!.serializeState());
// // //   }

// // //   // ── Engine init (host / pass-and-play) ────────────────────────────────────
// // //   Future<void> _initEngine(
// // //     OfflineSession session, {
// // //     required bool isLanClient,
// // //   }) async {
// // //     if (isLanClient) {
// // //       // Client: create engine without cards, player IDs set later
// // //       _initClientEngine(session);
// // //       return;
// // //     }
// // //     final cards = await _loadCards(session);
// // //     final factory = gameRegistry[session.gameType];
// // //     if (factory == null) throw Exception('No engine for ${session.gameType}');
// // //     _engine = factory(session.config, cards);
// // //     final ids = session.players.map((p) => p.id).toList();
// // //     if (_engine is TruthOrDareEngine)
// // //       (_engine as TruthOrDareEngine).init(playerOrder: ids);
// // //     else if (_engine is NeverHaveIEverEngine)
// // //       (_engine as NeverHaveIEverEngine).init(ids);
// // //     else if (_engine is MemeGameEngine)
// // //       (_engine as MemeGameEngine).init(ids);
// // //   }

// // //   Future<List<dynamic>> _loadCards(OfflineSession session) async {
// // //     final todCards = await TodRepository.instance.loadCardsFromCache(
// // //       packId: session.packId,
// // //       language: session.config.language,
// // //       allowSpicy: session.config.allowSpicy,
// // //     );
// // //     if (todCards.isEmpty && session.packId.isNotEmpty)
// // //       throw Exception('No cards for "${session.packName}". Download it first.');
// // //     return switch (session.gameType) {
// // //       GameType.neverHaveIEver => todCards.map((c) {
// // //         var t = c.content;
// // //         for (final p in ['Never have I ever ', 'never have I ever '])
// // //           if (t.startsWith(p)) {
// // //             t = t.substring(p.length);
// // //             break;
// // //           }
// // //         if (t.isNotEmpty) t = t[0].toUpperCase() + t.substring(1);
// // //         return NhieCard(id: c.id, content: t, difficulty: c.difficulty.name);
// // //       }).toList(),
// // //       GameType.memeGame =>
// // //         todCards.map((c) => MemePrompt(id: c.id, caption: c.content)).toList(),
// // //       _ => todCards,
// // //     };
// // //   }

// // //   // ── Peer subscription (host only) ─────────────────────────────────────────
// // //   void _subscribePeers() {
// // //     _peerSub?.cancel();
// // //     _peerSub = _lan.peerStream.listen((peers) {
// // //       _lanPeers = peers;
// // //       if (_isLanHost && _session != null) {
// // //         final host = _session!.players.first;
// // //         final all = [
// // //           host,
// // //           ...peers.asMap().entries.map(
// // //             (e) => OfflinePlayer(
// // //               id: e.value.playerId,
// // //               name: e.value.playerName,
// // //               seatOrder: e.key + 1,
// // //             ),
// // //           ),
// // //         ];
// // //         _session = _session!.copyWithPlayers(all);

// // //         // Re-init engine player order if game not started yet
// // //         if (_state == null && _engine != null) {
// // //           final ids = all.map((p) => p.id).toList();
// // //           try {
// // //             if (_engine is TruthOrDareEngine)
// // //               (_engine as TruthOrDareEngine).init(playerOrder: ids);
// // //             else if (_engine is NeverHaveIEverEngine)
// // //               (_engine as NeverHaveIEverEngine).init(ids);
// // //             else if (_engine is MemeGameEngine)
// // //               (_engine as MemeGameEngine).init(ids);
// // //             AppLogger.info('Host engine re-inited: ${ids.length} players');
// // //           } catch (e) {
// // //             AppLogger.warning('Host engine re-init failed: $e');
// // //           }
// // //         }

// // //         _lan.broadcastLobbyUpdate(_session!.id, all);

// // //         // If game running, send state to new joiner
// // //         if (_state != null) {
// // //           Future.delayed(const Duration(milliseconds: 500), _broadcastState);
// // //         }
// // //       }
// // //       _scheduleNotify();
// // //     });
// // //   }

// // //   // ── Message subscription ───────────────────────────────────────────────────
// // //   void _subscribeLanMessages() {
// // //     _msgSub?.cancel();
// // //     _msgSub = _lan.messageStream.listen(
// // //       _onLanMessage,
// // //       onError: (e) => AppLogger.warning('LAN stream error: $e'),
// // //     );

// // //     _disconnSub?.cancel();
// // //     _disconnSub = _lan.disconnectStream.listen((playerId) {
// // //       if (_session != null) {
// // //         _session = _session!.copyWithPlayers(
// // //           _session!.players
// // //               .map((p) => p.id == playerId ? p.copyWith(isConnected: false) : p)
// // //               .toList(),
// // //         );
// // //         _scheduleNotify();
// // //       }
// // //     });
// // //   }

// // //   // ── Snapshot ───────────────────────────────────────────────────────────────
// // //   void _onEngineStateChanged() {
// // //     _eventsSinceSnapshot++;
// // //     if (_engine?.isGameOver == true) {
// // //       _loadState = OfflineLoadState.gameOver;
// // //       _repo.endSession(_session?.id ?? '');
// // //     }
// // //     if (_eventsSinceSnapshot >= _snapshotInterval) {
// // //       _persistSnapshot();
// // //       _eventsSinceSnapshot = 0;
// // //     }
// // //   }

// // //   void _startSnapshotTimer() {
// // //     _snapshotTimer?.cancel();
// // //     _snapshotTimer = Timer.periodic(
// // //       const Duration(seconds: 15),
// // //       (_) => _persistSnapshot(),
// // //     );
// // //   }

// // //   Future<void> _persistSnapshot() async {
// // //     if (_session == null || _engine == null) return;
// // //     try {
// // //       await _repo.updateSnapshot(
// // //         _session!.id,
// // //         jsonEncode(_engine!.serializeState()),
// // //       );
// // //     } catch (_) {}
// // //   }

// // //   // ── Notify helpers ─────────────────────────────────────────────────────────

// // //   /// Schedule notification for next microtask — avoids calling during build.
// // //   void _scheduleNotify() {
// // //     if (_disposed) return;
// // //     // Use microtask so we never call notifyListeners() synchronously
// // //     // from a socket callback while Flutter is building
// // //     scheduleMicrotask(() {
// // //       if (!_disposed) notifyListeners();
// // //     });
// // //   }

// // //   void _setLoadState(OfflineLoadState s, {String? error}) {
// // //     _loadState = s;
// // //     _error = error;
// // //     _scheduleNotify();
// // //   }

// // //   // ── Public helpers ─────────────────────────────────────────────────────────
// // //   void endGame() {
// // //     _loadState = OfflineLoadState.gameOver;
// // //     _repo.endSession(_session?.id ?? '');
// // //     _scheduleNotify();
// // //   }

// // //   void reset() {
// // //     _session = null;
// // //     _engine = null;
// // //     _state = null;
// // //     _loadState = OfflineLoadState.idle;
// // //     _error = null;
// // //     _isLanHost = false;
// // //     _discoveredRooms = [];
// // //     _lanPeers = [];
// // //     _lanConnected = false;
// // //     _chatMessages.clear();
// // //     _pendingSnapshot = null;
// // //     _clientEngineReady = false;
// // //     _scheduleNotify();
// // //   }

// // //   // ── Helpers ────────────────────────────────────────────────────────────────
// // //   Future<String> _resolveLocalIp() async {
// // //     try {
// // //       final ifaces = await NetworkInterface.list(
// // //         type: InternetAddressType.IPv4,
// // //         includeLinkLocal: false,
// // //       );
// // //       for (final iface in ifaces) {
// // //         final n = iface.name.toLowerCase();
// // //         if (n.contains('wlan') ||
// // //             n.contains('wifi') ||
// // //             n.contains('ap') ||
// // //             n.contains('en0')) {
// // //           return iface.addresses.first.address;
// // //         }
// // //       }
// // //       if (ifaces.isNotEmpty) return ifaces.first.addresses.first.address;
// // //     } catch (_) {}
// // //     return '0.0.0.0';
// // //   }

// // //   static const _dataPort = 47890;

// // //   @override
// // //   void dispose() {
// // //     _disposed = true;
// // //     _snapshotTimer?.cancel();
// // //     _msgSub?.cancel();
// // //     _peerSub?.cancel();
// // //     _disconnSub?.cancel();
// // //     _lan.stop().ignore();
// // //     super.dispose();
// // //   }
// // // }

// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:io';

// // import 'package:flutter/foundation.dart';
// // import 'package:jma3a/features/games/truth_or_dare/truth_or_dare_engine.dart';
// // import 'package:jma3a/features/offline/data/offline_repository.dart';
// // import 'package:uuid/uuid.dart';

// // import '../../../core/utils/app_logger.dart';
// // import '../../games/engine/base_game_engine.dart';
// // import '../../games/engine/game_registry.dart';
// // import '../../games/truth_or_dare/data/tod_repository.dart';
// // import '../../games/truth_or_dare/domain/tod_models.dart';
// // import '../../games/never_have_i_ever/never_have_i_ever_engine.dart';
// // import '../../games/meme_game/meme_game_engine.dart';
// // import '../domain/offline_session.dart';
// // import '../services/lan_service.dart';

// // const _uuid = Uuid();

// // enum OfflineLoadState { idle, loading, lobby, ready, error, gameOver }

// // class LanChatMessage {
// //   const LanChatMessage({
// //     required this.senderId,
// //     required this.senderName,
// //     required this.text,
// //     required this.ts,
// //   });
// //   final String senderId;
// //   final String senderName;
// //   final String text;
// //   final DateTime ts;
// // }

// // class OfflineGameProvider extends ChangeNotifier {
// //   OfflineGameProvider({required OfflineRepository repository})
// //     : _repo = repository;

// //   final OfflineRepository _repo;
// //   final _lan = LanService.instance;

// //   OfflineSession? _session;
// //   BaseGameEngine? _engine;
// //   GameEngineState? _state;
// //   OfflineLoadState _loadState = OfflineLoadState.idle;
// //   String? _error;
// //   bool _isLanHost = false;
// //   bool _disposed = false;

// //   List<LanRoomDescriptor> _discoveredRooms = [];
// //   List<LanPeerInfo> _lanPeers = [];
// //   bool _lanConnected = false;
// //   String? _lanError;
// //   String? _clientPlayerId;
// //   String? _clientPlayerName;
// //   final List<LanChatMessage> _chatMessages = [];
// //   int _unreadChatCount = 0;
// //   Map<String, dynamic>? _pendingSnapshot;
// //   bool _clientEngineReady = false; // engine init'd with player IDs

// //   StreamSubscription<LanMessage>? _msgSub;
// //   StreamSubscription<List<LanPeerInfo>>? _peerSub;
// //   StreamSubscription<String>? _disconnSub;
// //   Timer? _snapshotTimer;
// //   int _eventsSinceSnapshot = 0;
// //   static const _snapshotInterval = 10;

// //   // ── Getters ────────────────────────────────────────────────────────────────
// //   OfflineSession? get session => _session;
// //   GameEngineState? get state => _state;
// //   OfflineLoadState get loadState => _loadState;
// //   String? get error => _error;
// //   bool get isReady => _loadState == OfflineLoadState.ready;
// //   bool get isLobby => _loadState == OfflineLoadState.lobby;
// //   bool get isGameOver => _loadState == OfflineLoadState.gameOver;
// //   bool get isLanHost => _isLanHost;
// //   List<LanRoomDescriptor> get discoveredRooms => _discoveredRooms;
// //   List<LanPeerInfo> get lanPeers => _lanPeers;
// //   bool get lanConnected => _lanConnected;
// //   String? get lanError => _lanError;
// //   List<OfflinePlayer> get players => _session?.players ?? [];
// //   GameType? get gameType => _session?.gameType;
// //   OfflineMode? get mode => _session?.mode;
// //   String? get clientPlayerId => _clientPlayerId;
// //   List<LanChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
// //   int get unreadChatCount => _unreadChatCount;

// //   // ── Pass-and-play ──────────────────────────────────────────────────────────
// //   Future<void> startPassAndPlay({
// //     required GameType gameType,
// //     required GameConfig config,
// //     required List<String> playerNames,
// //     required String packId,
// //     required String packName,
// //   }) async {
// //     _setLoadState(OfflineLoadState.loading);
// //     try {
// //       final players = playerNames
// //           .asMap()
// //           .entries
// //           .map(
// //             (e) =>
// //                 OfflinePlayer(id: _uuid.v4(), name: e.value, seatOrder: e.key),
// //           )
// //           .toList();
// //       final session = OfflineSession(
// //         id: _uuid.v4(),
// //         mode: OfflineMode.passAndPlay,
// //         gameType: gameType,
// //         config: config,
// //         players: players,
// //         packId: packId,
// //         packName: packName,
// //         createdAt: DateTime.now(),
// //       );
// //       await _initEngine(session, isLanClient: false);
// //       _session = session;
// //       _state = _engine!.currentState;
// //       await _repo.saveSession(session);
// //       _startSnapshotTimer();
// //       _setLoadState(OfflineLoadState.ready);
// //     } catch (e, st) {
// //       AppLogger.error('startPassAndPlay failed', error: e, stackTrace: st);
// //       _setLoadState(OfflineLoadState.error, error: e.toString());
// //     }
// //   }

// //   // ── Resume ─────────────────────────────────────────────────────────────────
// //   Future<bool> resumeActiveSession() async {
// //     final session = await _repo.getActiveSession();
// //     if (session == null || session.stateSnapshot == null) return false;
// //     _setLoadState(OfflineLoadState.loading);
// //     try {
// //       await _initEngine(session, isLanClient: false);
// //       _engine!.restoreFromSnapshot(
// //         jsonDecode(session.stateSnapshot!) as Map<String, dynamic>,
// //       );
// //       _state = _engine!.currentState;
// //       _session = session;
// //       _startSnapshotTimer();
// //       _setLoadState(OfflineLoadState.ready);
// //       return true;
// //     } catch (e) {
// //       _setLoadState(OfflineLoadState.error, error: 'Could not resume.');
// //       return false;
// //     }
// //   }

// //   // ── Engine actions ─────────────────────────────────────────────────────────
// //   GameEngineState? advanceTurn() {
// //     if (_engine == null) return null;
// //     _state = _engine!.advanceTurn();
// //     _onEngineStateChanged();
// //     _scheduleNotify();
// //     if (_isLanHost) _broadcastState();
// //     return _state;
// //   }

// //   GameEngineState? handleEvent(GameEngineEvent event) {
// //     if (_engine == null) return null;
// //     _state = _engine!.handleEvent(event);
// //     _onEngineStateChanged();
// //     _scheduleNotify();
// //     if (_isLanHost) _broadcastState();
// //     return _state;
// //   }

// //   // ── LAN HOST: start ────────────────────────────────────────────────────────
// //   Future<void> startLanHost({
// //     required GameType gameType,
// //     required GameConfig config,
// //     required List<String> playerNames,
// //     required String packId,
// //     required String packName,
// //     required String hostName,
// //   }) async {
// //     _setLoadState(OfflineLoadState.loading);
// //     try {
// //       final players = playerNames
// //           .asMap()
// //           .entries
// //           .map(
// //             (e) =>
// //                 OfflinePlayer(id: _uuid.v4(), name: e.value, seatOrder: e.key),
// //           )
// //           .toList();

// //       final sessionId = _uuid.v4();
// //       final hostIp = await _resolveLocalIp();

// //       final descriptor = LanRoomDescriptor(
// //         sessionId: sessionId,
// //         hostName: hostName,
// //         hostAddress: hostIp,
// //         port: _dataPort,
// //         gameType: gameType,
// //         playerCount: players.length,
// //         maxPlayers: 12,
// //         packName: packName,
// //         advertisedAt: DateTime.now(),
// //         maxRounds: config.maxRounds,
// //         turnTimerSeconds: config.turnTimerSeconds,
// //         allowSpicy: config.allowSpicy,
// //         allowSkip: config.allowSkip,
// //       );

// //       await _lan.startHost(descriptor: descriptor);

// //       final session = OfflineSession(
// //         id: sessionId,
// //         mode: OfflineMode.lan,
// //         gameType: gameType,
// //         config: config,
// //         players: players,
// //         packId: packId,
// //         packName: packName,
// //         createdAt: DateTime.now(),
// //       );

// //       await _initEngine(session, isLanClient: false);
// //       _session = session;
// //       _isLanHost = true;
// //       _state = null; // will be set when game starts

// //       _subscribeLanMessages();
// //       _subscribePeers();
// //       await _repo.saveSession(session);

// //       _setLoadState(OfflineLoadState.lobby);
// //       AppLogger.info('LAN host lobby ready: $sessionId');
// //     } catch (e, st) {
// //       AppLogger.error('startLanHost failed', error: e, stackTrace: st);
// //       _setLoadState(OfflineLoadState.error, error: e.toString());
// //     }
// //   }

// //   // ── LAN HOST: start game ───────────────────────────────────────────────────
// //   Future<void> startLanGame() async {
// //     if (!_isLanHost || _session == null || _engine == null) return;

// //     // Engine was already init'd in startLanHost with all players (via _subscribePeers)
// //     _state = _engine!.currentState;

// //     _lan.broadcastStartGame(_session!.id);
// //     _lan.broadcastGameState(_session!.id, _engine!.serializeState());

// //     _loadState = OfflineLoadState.ready;
// //     _startSnapshotTimer();
// //     _scheduleNotify();
// //     AppLogger.info('LAN game started with ${_session!.players.length} players');
// //   }

// //   // ── LAN: discovery ─────────────────────────────────────────────────────────
// //   Future<void> startDiscovery() async {
// //     _discoveredRooms = [];
// //     await _lan.startDiscovery();
// //     _lan.roomStream.listen((room) {
// //       _discoveredRooms = [
// //         ..._discoveredRooms.where(
// //           (r) => r.sessionId != room.sessionId && !r.isStale,
// //         ),
// //         room,
// //       ];
// //       _scheduleNotify();
// //     });
// //   }

// //   // ── LAN CLIENT: connect ────────────────────────────────────────────────────
// //   Future<bool> connectToRoom({
// //     required LanRoomDescriptor room,
// //     required String playerId,
// //     required String playerName,
// //   }) async {
// //     _setLoadState(OfflineLoadState.loading);
// //     _clientPlayerId = playerId;
// //     _clientPlayerName = playerName;
// //     _isLanHost = false;
// //     _lanConnected = false;
// //     _clientEngineReady = false;
// //     _pendingSnapshot = null;

// //     // Subscribe BEFORE connecting so joinAck is never missed
// //     _subscribeLanMessages();

// //     try {
// //       await _lan.connectToHost(
// //         room: room,
// //         playerId: playerId,
// //         playerName: playerName,
// //       );
// //       _lanConnected = true;
// //       AppLogger.info('Connected to ${room.hostName}, waiting for joinAck…');
// //       return true;
// //     } catch (e) {
// //       _lanError = 'Could not connect: $e';
// //       _setLoadState(OfflineLoadState.error, error: _lanError!);
// //       return false;
// //     }
// //   }

// //   // ── Chat ───────────────────────────────────────────────────────────────────
// //   void sendChat(String text) {
// //     if (text.trim().isEmpty) return;
// //     final myId = _isLanHost
// //         ? (_session?.players.firstOrNull?.id ?? '')
// //         : (_clientPlayerId ?? '');
// //     final myName = _isLanHost
// //         ? (_session?.players.firstOrNull?.name ?? 'Host')
// //         : (_clientPlayerName ?? 'Player');

// //     final msg = LanMessage(
// //       type: LanMessageType.chat,
// //       senderId: myId,
// //       payload: {'name': myName, 'text': text.trim()},
// //       ts: DateTime.now().millisecondsSinceEpoch,
// //     );

// //     // Always add locally immediately (not incoming, so don't increment unread)
// //     _addChat(
// //       myId,
// //       myName,
// //       text.trim(),
// //       DateTime.fromMillisecondsSinceEpoch(msg.ts),
// //       isIncoming: false,
// //     );

// //     if (_isLanHost) {
// //       _lan.broadcastMessage(msg);
// //     } else {
// //       _lan.sendAction(msg);
// //     }
// //   }

// //   void _addChat(
// //     String id,
// //     String name,
// //     String text,
// //     DateTime ts, {
// //     bool isIncoming = false,
// //   }) {
// //     _chatMessages.add(
// //       LanChatMessage(senderId: id, senderName: name, text: text, ts: ts),
// //     );
// //     if (isIncoming) _unreadChatCount++;
// //     _scheduleNotify();
// //   }

// //   void clearUnreadChat() {
// //     _unreadChatCount = 0;
// //     _scheduleNotify();
// //   }

// //   /// Host: disconnect a player from the lobby.
// //   void kickLanPlayer(String playerId) {
// //     if (!_isLanHost) return;
// //     _lan.kickPeer(playerId);
// //   }

// //   // ── Message dispatch ───────────────────────────────────────────────────────
// //   void _onLanMessage(LanMessage msg) {
// //     AppLogger.info('LAN ← ${msg.type} (host=$_isLanHost)');
// //     if (_isLanHost) {
// //       _onHostReceived(msg);
// //     } else {
// //       _onClientReceived(msg);
// //     }
// //   }

// //   // ── HOST: handle incoming from clients ─────────────────────────────────────
// //   void _onHostReceived(LanMessage msg) {
// //     switch (msg.type) {
// //       case LanMessageType.playerAction:
// //         if (_state == null || _engine == null) return;
// //         final ev = msg.payload['event'] as Map<String, dynamic>?;
// //         if (ev == null) return;
// //         try {
// //           final action = ev['action'] as String? ?? ev['type'] as String? ?? '';
// //           if (action == 'advance') {
// //             _state = _engine!.advanceTurn();
// //           } else {
// //             final event = _parseEvent(ev);
// //             if (event != null) {
// //               _state = _engine!.handleEvent(event);
// //             } else {
// //               AppLogger.warning('Host: unknown action "$action"');
// //               return;
// //             }
// //           }
// //           _onEngineStateChanged();
// //           _scheduleNotify();
// //           _broadcastState();
// //         } catch (e) {
// //           AppLogger.warning('Host: playerAction error: $e');
// //         }

// //       case LanMessageType.chat:
// //         // Add to host list and relay to other clients
// //         final name = msg.payload['name'] as String? ?? 'Player';
// //         final text = msg.payload['text'] as String? ?? '';
// //         _addChat(
// //           msg.senderId,
// //           name,
// //           text,
// //           DateTime.fromMillisecondsSinceEpoch(msg.ts),
// //           isIncoming: true,
// //         );
// //         _lan.broadcastMessageExcept(msg, msg.senderId);

// //       default:
// //         break;
// //     }
// //   }

// //   // ── CLIENT: handle incoming from host ──────────────────────────────────────
// //   void _onClientReceived(LanMessage msg) {
// //     switch (msg.type) {
// //       case LanMessageType.joinAck:
// //         if (_session != null) return; // already processed
// //         try {
// //           final d = LanRoomDescriptor.fromJson(msg.payload);
// //           _session = OfflineSession(
// //             id: d.sessionId,
// //             mode: OfflineMode.lan,
// //             gameType: d.gameType,
// //             config: GameConfig(
// //               maxRounds: d.maxRounds,
// //               turnTimerSeconds: d.turnTimerSeconds,
// //               allowSkip: d.allowSkip,
// //               allowSpicy: d.allowSpicy,
// //             ),
// //             players: [
// //               OfflinePlayer(
// //                 id: _clientPlayerId ?? _uuid.v4(),
// //                 name: _clientPlayerName ?? 'Player',
// //                 seatOrder: 0,
// //               ),
// //             ],
// //             packId: '',
// //             packName: d.packName,
// //             createdAt: DateTime.now(),
// //           );
// //           // Init engine without cards (client doesn't have the pack)
// //           _initClientEngine(_session!);
// //           AppLogger.info('Client: joinAck ok — ${d.gameType} "${d.packName}"');
// //         } catch (e) {
// //           AppLogger.error('Client: joinAck failed', error: e);
// //         }

// //       case LanMessageType.lobbyUpdate:
// //         final players = (msg.payload['players'] as List? ?? [])
// //             .map(
// //               (p) => OfflinePlayer(
// //                 id: p['id'] as String,
// //                 name: p['name'] as String,
// //                 seatOrder: p['seat'] as int? ?? 0,
// //               ),
// //             )
// //             .toList();
// //         if (_session != null) {
// //           _session = _session!.copyWithPlayers(players);

// //           // Adopt the UUID the host assigned us (matched by name)
// //           // The host creates players with uuid.v4() — we must use that
// //           // ID as our identity so isMyTurn works correctly
// //           final myEntry = players.firstWhere(
// //             (p) => p.name == _clientPlayerName,
// //             orElse: () =>
// //                 players.lastOrNull ??
// //                 OfflinePlayer(
// //                   id: _clientPlayerId ?? '',
// //                   name: '',
// //                   seatOrder: 0,
// //                 ),
// //           );
// //           if (myEntry.id != _clientPlayerId) {
// //             AppLogger.info(
// //               'Client: adopting host-assigned ID '
// //               '${myEntry.id} (was $_clientPlayerId)',
// //             );
// //             _clientPlayerId = myEntry.id;
// //           }

// //           AppLogger.info(
// //             'Client: lobby has ${players.length} players: '
// //             '${players.map((p) => p.name).join(', ')}',
// //           );

// //           if (!_clientEngineReady) {
// //             _initClientEngineWithIds(players.map((p) => p.id).toList());
// //           }
// //           if (_pendingSnapshot != null) {
// //             _tryApplySnapshot(_pendingSnapshot!);
// //           }
// //           _scheduleNotify();
// //         }

// //       case LanMessageType.startGame:
// //         // Game state will follow immediately — just log
// //         AppLogger.info('Client: startGame signal received');

// //       case LanMessageType.gameState:
// //         final snap = msg.payload['snapshot'] as Map<String, dynamic>?;
// //         if (snap != null) {
// //           AppLogger.info('Client: gameState received');
// //           _tryApplySnapshot(snap);
// //         }

// //       case LanMessageType.chat:
// //         // Only add if not from myself (already added locally in sendChat)
// //         if (msg.senderId == _clientPlayerId) break;
// //         final name = msg.payload['name'] as String? ?? 'Player';
// //         final text = msg.payload['text'] as String? ?? '';
// //         _addChat(
// //           msg.senderId,
// //           name,
// //           text,
// //           DateTime.fromMillisecondsSinceEpoch(msg.ts),
// //           isIncoming: true,
// //         );

// //       case LanMessageType.ping:
// //         // Send pong with our playerId so host can find us in _peers
// //         _lan.sendPong(_clientPlayerId ?? _session?.id ?? '');

// //       case LanMessageType.leave:
// //         // Host kicked us
// //         _setLoadState(
// //           OfflineLoadState.error,
// //           error: 'You were removed from the room by the host.',
// //         );

// //       default:
// //         break;
// //     }
// //   }

// //   // ── Client engine helpers ──────────────────────────────────────────────────

// //   /// Create engine without cards. Player IDs will be set when lobbyUpdate arrives.
// //   void _initClientEngine(OfflineSession session) {
// //     final factory = gameRegistry[session.gameType];
// //     if (factory == null) {
// //       AppLogger.error('Client: no engine for ${session.gameType}');
// //       return;
// //     }
// //     _engine = factory(session.config, <dynamic>[]);
// //     // Don't init player order yet — wait for lobbyUpdate
// //     _clientEngineReady = false;
// //     _loadState = OfflineLoadState.lobby;
// //     _scheduleNotify();
// //   }

// //   /// Init engine player order once we have the full player list from lobbyUpdate.
// //   void _initClientEngineWithIds(List<String> ids) {
// //     if (_engine == null || ids.isEmpty) return;
// //     try {
// //       if (_engine is TruthOrDareEngine)
// //         (_engine as TruthOrDareEngine).init(playerOrder: ids);
// //       else if (_engine is NeverHaveIEverEngine)
// //         (_engine as NeverHaveIEverEngine).init(ids);
// //       else if (_engine is MemeGameEngine)
// //         (_engine as MemeGameEngine).init(ids);
// //       _clientEngineReady = true;
// //       AppLogger.info('Client engine ready with players: $ids');
// //     } catch (e) {
// //       AppLogger.warning('Client: engine init failed: $e');
// //     }
// //   }

// //   void _tryApplySnapshot(Map<String, dynamic> snapshot) {
// //     if (_engine == null) {
// //       _pendingSnapshot = snapshot;
// //       AppLogger.warning('Client: engine null, queuing snapshot');
// //       return;
// //     }

// //     // If engine not yet init'd with players, try now
// //     if (!_clientEngineReady && _session != null) {
// //       final ids = _session!.players.map((p) => p.id).toList();
// //       _initClientEngineWithIds(ids);
// //     }

// //     if (!_clientEngineReady) {
// //       _pendingSnapshot = snapshot;
// //       AppLogger.warning('Client: engine not ready, queuing snapshot');
// //       return;
// //     }

// //     try {
// //       _engine!.restoreFromSnapshot(snapshot);
// //       _state = _engine!.currentState;
// //       _loadState = OfflineLoadState.ready;
// //       _pendingSnapshot = null;
// //       _scheduleNotify();
// //       AppLogger.info('Client: snapshot applied, state=${_state.runtimeType}');
// //     } catch (e, st) {
// //       AppLogger.error(
// //         'Client: restoreFromSnapshot failed',
// //         error: e,
// //         stackTrace: st,
// //       );
// //     }
// //   }

// //   // ── Client: send action to host ────────────────────────────────────────────
// //   Future<void> sendLanAction(Map<String, dynamic> payload) async {
// //     if (_isLanHost || !_lanConnected) return;
// //     // Wrap in 'event' key for host's _onHostReceived
// //     final wrapped = payload.containsKey('event') ? payload : {'event': payload};
// //     _lan.sendAction(
// //       LanMessage(
// //         type: LanMessageType.playerAction,
// //         senderId: _clientPlayerId ?? '',
// //         payload: wrapped,
// //         ts: DateTime.now().millisecondsSinceEpoch,
// //       ),
// //     );
// //   }

// //   // ── Parse event ────────────────────────────────────────────────────────────
// //   GameEngineEvent? _parseEvent(Map<String, dynamic> m) {
// //     final action = m['action'] as String? ?? m['type'] as String? ?? '';
// //     final userId = m['user_id'] as String? ?? m['userId'] as String? ?? '';
// //     final ts = m['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
// //     return switch (action) {
// //       // ── ToD ──────────────────────────────────────────────────────────────
// //       'tod_choice' || 'choice' => TodChoiceEvent(
// //         userId: userId,
// //         ts: ts,
// //         cardType: (m['card_type'] ?? m['cardType']) == 'dare'
// //             ? TodCardType.dare
// //             : TodCardType.truth,
// //       ),
// //       'tod_complete' || 'complete' => TodCompleteEvent(
// //         userId: userId,
// //         ts: ts,
// //         response: m['response'] as String? ?? '',
// //         proofImageB64: m['proof_image'] as String? ?? '',
// //       ),
// //       'tod_react' || 'react' => TodReactEvent(
// //         userId: userId,
// //         ts: ts,
// //         emoji: m['emoji'] as String? ?? '👍',
// //       ),
// //       'tod_vote_response' ||
// //       'vote_response' => TodVoteResponseEvent(userId: userId, ts: ts),
// //       'tod_skip' || 'skip' => TodSkipEvent(userId: userId, ts: ts),
// //       // ── NHIE ─────────────────────────────────────────────────────────────
// //       'nhie_vote' => NhieVoteEvent(
// //         userId: userId,
// //         ts: ts,
// //         haveI: m['have_i'] as bool? ?? false,
// //         message: m['message'] as String? ?? '',
// //       ),
// //       'nhie_react' => NhieReactionEvent(
// //         userId: userId,
// //         ts: ts,
// //         sticker: m['sticker'] as String? ?? '',
// //       ),
// //       // ── Meme ─────────────────────────────────────────────────────────────
// //       'meme_submit' => MemeSubmitEvent(
// //         userId: userId,
// //         ts: ts,
// //         caption: m['caption'] as String? ?? '',
// //         stickerChoice: m['sticker_choice'] as String? ?? '',
// //       ),
// //       'meme_vote' => MemeVoteEvent(
// //         userId: userId,
// //         ts: ts,
// //         targetUserId: m['target_user_id'] as String? ?? '',
// //       ),
// //       'meme_react' => MemeReactEvent(
// //         userId: userId,
// //         ts: ts,
// //         targetUserId: m['target_user_id'] as String? ?? '',
// //         emoji: m['emoji'] as String? ?? '👍',
// //       ),
// //       _ => null,
// //     };
// //   }

// //   // ── Broadcast state from host ──────────────────────────────────────────────
// //   void _broadcastState() {
// //     if (!_isLanHost || _engine == null || _session == null) return;
// //     _lan.broadcastGameState(_session!.id, _engine!.serializeState());
// //   }

// //   // ── Engine init (host / pass-and-play) ────────────────────────────────────
// //   Future<void> _initEngine(
// //     OfflineSession session, {
// //     required bool isLanClient,
// //   }) async {
// //     if (isLanClient) {
// //       // Client: create engine without cards, player IDs set later
// //       _initClientEngine(session);
// //       return;
// //     }
// //     final cards = await _loadCards(session);
// //     final factory = gameRegistry[session.gameType];
// //     if (factory == null) throw Exception('No engine for ${session.gameType}');
// //     _engine = factory(session.config, cards);
// //     final ids = session.players.map((p) => p.id).toList();
// //     if (_engine is TruthOrDareEngine)
// //       (_engine as TruthOrDareEngine).init(playerOrder: ids);
// //     else if (_engine is NeverHaveIEverEngine)
// //       (_engine as NeverHaveIEverEngine).init(ids);
// //     else if (_engine is MemeGameEngine)
// //       (_engine as MemeGameEngine).init(ids);
// //   }

// //   Future<List<dynamic>> _loadCards(OfflineSession session) async {
// //     final todCards = await TodRepository.instance.loadCardsFromCache(
// //       packId: session.packId,
// //       language: session.config.language,
// //       allowSpicy: session.config.allowSpicy,
// //     );
// //     if (todCards.isEmpty && session.packId.isNotEmpty)
// //       throw Exception('No cards for "${session.packName}". Download it first.');
// //     return switch (session.gameType) {
// //       GameType.neverHaveIEver => todCards.map((c) {
// //         var t = c.content;
// //         for (final p in ['Never have I ever ', 'never have I ever '])
// //           if (t.startsWith(p)) {
// //             t = t.substring(p.length);
// //             break;
// //           }
// //         if (t.isNotEmpty) t = t[0].toUpperCase() + t.substring(1);
// //         return NhieCard(id: c.id, content: t, difficulty: c.difficulty.name);
// //       }).toList(),
// //       GameType.memeGame =>
// //         todCards.map((c) => MemePrompt(id: c.id, caption: c.content)).toList(),
// //       _ => todCards,
// //     };
// //   }

// //   // ── Peer subscription (host only) ─────────────────────────────────────────
// //   void _subscribePeers() {
// //     _peerSub?.cancel();
// //     _peerSub = _lan.peerStream.listen((peers) {
// //       _lanPeers = peers;
// //       if (_isLanHost && _session != null) {
// //         final host = _session!.players.first;
// //         final all = [
// //           host,
// //           ...peers.asMap().entries.map(
// //             (e) => OfflinePlayer(
// //               id: e.value.playerId,
// //               name: e.value.playerName,
// //               seatOrder: e.key + 1,
// //             ),
// //           ),
// //         ];
// //         _session = _session!.copyWithPlayers(all);

// //         // Re-init engine player order if game not started yet
// //         if (_state == null && _engine != null) {
// //           final ids = all.map((p) => p.id).toList();
// //           try {
// //             if (_engine is TruthOrDareEngine)
// //               (_engine as TruthOrDareEngine).init(playerOrder: ids);
// //             else if (_engine is NeverHaveIEverEngine)
// //               (_engine as NeverHaveIEverEngine).init(ids);
// //             else if (_engine is MemeGameEngine)
// //               (_engine as MemeGameEngine).init(ids);
// //             AppLogger.info('Host engine re-inited: ${ids.length} players');
// //           } catch (e) {
// //             AppLogger.warning('Host engine re-init failed: $e');
// //           }
// //         }

// //         _lan.broadcastLobbyUpdate(_session!.id, all);

// //         // If game running, send state to new joiner
// //         if (_state != null) {
// //           Future.delayed(const Duration(milliseconds: 500), _broadcastState);
// //         }
// //       }
// //       _scheduleNotify();
// //     });
// //   }

// //   // ── Message subscription ───────────────────────────────────────────────────
// //   void _subscribeLanMessages() {
// //     _msgSub?.cancel();
// //     _msgSub = _lan.messageStream.listen(
// //       _onLanMessage,
// //       onError: (e) => AppLogger.warning('LAN stream error: $e'),
// //     );

// //     _disconnSub?.cancel();
// //     _disconnSub = _lan.disconnectStream.listen((playerId) {
// //       if (_session != null) {
// //         _session = _session!.copyWithPlayers(
// //           _session!.players
// //               .map((p) => p.id == playerId ? p.copyWith(isConnected: false) : p)
// //               .toList(),
// //         );
// //         _scheduleNotify();
// //       }
// //     });
// //   }

// //   // ── Snapshot ───────────────────────────────────────────────────────────────
// //   void _onEngineStateChanged() {
// //     _eventsSinceSnapshot++;
// //     if (_engine?.isGameOver == true) {
// //       _loadState = OfflineLoadState.gameOver;
// //       _repo.endSession(_session?.id ?? '');
// //     }
// //     if (_eventsSinceSnapshot >= _snapshotInterval) {
// //       _persistSnapshot();
// //       _eventsSinceSnapshot = 0;
// //     }
// //   }

// //   void _startSnapshotTimer() {
// //     _snapshotTimer?.cancel();
// //     _snapshotTimer = Timer.periodic(
// //       const Duration(seconds: 15),
// //       (_) => _persistSnapshot(),
// //     );
// //   }

// //   Future<void> _persistSnapshot() async {
// //     if (_session == null || _engine == null) return;
// //     try {
// //       await _repo.updateSnapshot(
// //         _session!.id,
// //         jsonEncode(_engine!.serializeState()),
// //       );
// //     } catch (_) {}
// //   }

// //   // ── Notify helpers ─────────────────────────────────────────────────────────

// //   /// Schedule notification for next microtask — avoids calling during build.
// //   void _scheduleNotify() {
// //     if (_disposed) return;
// //     // Use microtask so we never call notifyListeners() synchronously
// //     // from a socket callback while Flutter is building
// //     scheduleMicrotask(() {
// //       if (!_disposed) notifyListeners();
// //     });
// //   }

// //   void _setLoadState(OfflineLoadState s, {String? error}) {
// //     _loadState = s;
// //     _error = error;
// //     _scheduleNotify();
// //   }

// //   // ── Public helpers ─────────────────────────────────────────────────────────
// //   void endGame() {
// //     _loadState = OfflineLoadState.gameOver;
// //     _repo.endSession(_session?.id ?? '');
// //     _scheduleNotify();
// //   }

// //   void reset() {
// //     _session = null;
// //     _engine = null;
// //     _state = null;
// //     _loadState = OfflineLoadState.idle;
// //     _error = null;
// //     _isLanHost = false;
// //     _discoveredRooms = [];
// //     _lanPeers = [];
// //     _lanConnected = false;
// //     _chatMessages.clear();
// //     _unreadChatCount = 0;
// //     _pendingSnapshot = null;
// //     _clientEngineReady = false;
// //     _scheduleNotify();
// //   }

// //   // ── Helpers ────────────────────────────────────────────────────────────────
// //   Future<String> _resolveLocalIp() async {
// //     try {
// //       final ifaces = await NetworkInterface.list(
// //         type: InternetAddressType.IPv4,
// //         includeLinkLocal: false,
// //       );
// //       for (final iface in ifaces) {
// //         final n = iface.name.toLowerCase();
// //         if (n.contains('wlan') ||
// //             n.contains('wifi') ||
// //             n.contains('ap') ||
// //             n.contains('en0')) {
// //           return iface.addresses.first.address;
// //         }
// //       }
// //       if (ifaces.isNotEmpty) return ifaces.first.addresses.first.address;
// //     } catch (_) {}
// //     return '0.0.0.0';
// //   }

// //   static const _dataPort = 47890;

// //   @override
// //   void dispose() {
// //     _disposed = true;
// //     _snapshotTimer?.cancel();
// //     _msgSub?.cancel();
// //     _peerSub?.cancel();
// //     _disconnSub?.cancel();
// //     _lan.stop().ignore();
// //     super.dispose();
// //   }
// // }

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';

// import 'package:flutter/foundation.dart';
// import 'package:jma3a/features/games/truth_or_dare/truth_or_dare_engine.dart';
// import 'package:jma3a/features/offline/data/offline_repository.dart';
// import 'package:uuid/uuid.dart';

// import '../../../core/utils/app_logger.dart';
// import '../../games/engine/base_game_engine.dart';
// import '../../games/engine/game_registry.dart';
// import '../../games/truth_or_dare/data/tod_repository.dart';
// import '../../games/truth_or_dare/domain/tod_models.dart';
// import '../../games/never_have_i_ever/never_have_i_ever_engine.dart';
// import '../../games/meme_game/meme_game_engine.dart';
// import '../domain/offline_session.dart';
// import '../services/lan_service.dart';

// const _uuid = Uuid();

// enum OfflineLoadState { idle, loading, lobby, ready, error, gameOver }

// class LanChatMessage {
//   const LanChatMessage({
//     required this.senderId,
//     required this.senderName,
//     required this.text,
//     required this.ts,
//   });
//   final String senderId;
//   final String senderName;
//   final String text;
//   final DateTime ts;
// }

// class OfflineGameProvider extends ChangeNotifier {
//   OfflineGameProvider({required OfflineRepository repository})
//     : _repo = repository;

//   final OfflineRepository _repo;
//   final _lan = LanService.instance;

//   OfflineSession? _session;
//   BaseGameEngine? _engine;
//   GameEngineState? _state;
//   OfflineLoadState _loadState = OfflineLoadState.idle;
//   String? _error;
//   bool _isLanHost = false;
//   bool _disposed = false;

//   List<LanRoomDescriptor> _discoveredRooms = [];
//   List<LanPeerInfo> _lanPeers = [];
//   bool _lanConnected = false;
//   String? _lanError;
//   String? _clientPlayerId;
//   String? _clientPlayerName;
//   final List<LanChatMessage> _chatMessages = [];
//   int _unreadChatCount = 0;
//   Map<String, dynamic>? _pendingSnapshot;
//   bool _clientEngineReady = false; // engine init'd with player IDs

//   StreamSubscription<LanMessage>? _msgSub;
//   StreamSubscription<List<LanPeerInfo>>? _peerSub;
//   StreamSubscription<String>? _disconnSub;
//   Timer? _snapshotTimer;
//   int _eventsSinceSnapshot = 0;
//   static const _snapshotInterval = 10;

//   // ── Getters ────────────────────────────────────────────────────────────────
//   OfflineSession? get session => _session;
//   GameEngineState? get state => _state;
//   OfflineLoadState get loadState => _loadState;
//   String? get error => _error;
//   bool get isReady => _loadState == OfflineLoadState.ready;
//   bool get isLobby => _loadState == OfflineLoadState.lobby;
//   bool get isGameOver => _loadState == OfflineLoadState.gameOver;
//   bool get isLanHost => _isLanHost;
//   List<LanRoomDescriptor> get discoveredRooms => _discoveredRooms;
//   List<LanPeerInfo> get lanPeers => _lanPeers;
//   bool get lanConnected => _lanConnected;
//   String? get lanError => _lanError;
//   List<OfflinePlayer> get players => _session?.players ?? [];
//   GameType? get gameType => _session?.gameType;
//   OfflineMode? get mode => _session?.mode;
//   String? get clientPlayerId => _clientPlayerId;
//   List<LanChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
//   int get unreadChatCount => _unreadChatCount;

//   // ── Pass-and-play ──────────────────────────────────────────────────────────
//   Future<void> startPassAndPlay({
//     required GameType gameType,
//     required GameConfig config,
//     required List<String> playerNames,
//     required String packId,
//     required String packName,
//     String? packCoverUrl,
//   }) async {
//     _setLoadState(OfflineLoadState.loading);
//     try {
//       final players = playerNames
//           .asMap()
//           .entries
//           .map(
//             (e) =>
//                 OfflinePlayer(id: _uuid.v4(), name: e.value, seatOrder: e.key),
//           )
//           .toList();
//       final session = OfflineSession(
//         id: _uuid.v4(),
//         mode: OfflineMode.passAndPlay,
//         gameType: gameType,
//         config: config,
//         players: players,
//         packId: packId,
//         packName: packName,
//         packCoverUrl: packCoverUrl,
//         createdAt: DateTime.now(),
//       );
//       await _initEngine(session, isLanClient: false);
//       _session = session;
//       _state = _engine!.currentState;
//       await _repo.saveSession(session);
//       _startSnapshotTimer();
//       _setLoadState(OfflineLoadState.ready);
//     } catch (e, st) {
//       AppLogger.error('startPassAndPlay failed', error: e, stackTrace: st);
//       _setLoadState(OfflineLoadState.error, error: e.toString());
//     }
//   }

//   // ── Resume ─────────────────────────────────────────────────────────────────
//   Future<bool> resumeActiveSession() async {
//     final session = await _repo.getActiveSession();
//     if (session == null || session.stateSnapshot == null) return false;
//     _setLoadState(OfflineLoadState.loading);
//     try {
//       await _initEngine(session, isLanClient: false);
//       _engine!.restoreFromSnapshot(
//         jsonDecode(session.stateSnapshot!) as Map<String, dynamic>,
//       );
//       _state = _engine!.currentState;
//       _session = session;
//       _startSnapshotTimer();
//       _setLoadState(OfflineLoadState.ready);
//       return true;
//     } catch (e) {
//       _setLoadState(OfflineLoadState.error, error: 'Could not resume.');
//       return false;
//     }
//   }

//   // ── Engine actions ─────────────────────────────────────────────────────────
//   GameEngineState? advanceTurn() {
//     if (_engine == null) return null;
//     _state = _engine!.advanceTurn();
//     _onEngineStateChanged();
//     _scheduleNotify();
//     if (_isLanHost) _broadcastState();
//     return _state;
//   }

//   GameEngineState? handleEvent(GameEngineEvent event) {
//     if (_engine == null) return null;
//     _state = _engine!.handleEvent(event);
//     _onEngineStateChanged();
//     _scheduleNotify();
//     if (_isLanHost) _broadcastState();
//     return _state;
//   }

//   // ── LAN HOST: start ────────────────────────────────────────────────────────
//   Future<void> startLanHost({
//     required GameType gameType,
//     required GameConfig config,
//     required List<String> playerNames,
//     required String packId,
//     required String packName,
//     required String hostName,
//     String? packCoverUrl,
//   }) async {
//     _setLoadState(OfflineLoadState.loading);
//     try {
//       final players = playerNames
//           .asMap()
//           .entries
//           .map(
//             (e) =>
//                 OfflinePlayer(id: _uuid.v4(), name: e.value, seatOrder: e.key),
//           )
//           .toList();

//       final sessionId = _uuid.v4();
//       final hostIp = await _resolveLocalIp();

//       final descriptor = LanRoomDescriptor(
//         sessionId: sessionId,
//         hostName: hostName,
//         hostAddress: hostIp,
//         port: _dataPort,
//         gameType: gameType,
//         playerCount: players.length,
//         maxPlayers: 12,
//         packName: packName,
//         advertisedAt: DateTime.now(),
//         maxRounds: config.maxRounds,
//         turnTimerSeconds: config.turnTimerSeconds,
//         allowSpicy: config.allowSpicy,
//         allowSkip: config.allowSkip,
//       );

//       await _lan.startHost(descriptor: descriptor);

//       final session = OfflineSession(
//         id: sessionId,
//         mode: OfflineMode.lan,
//         gameType: gameType,
//         config: config,
//         players: players,
//         packId: packId,
//         packName: packName,
//         packCoverUrl: packCoverUrl,
//         createdAt: DateTime.now(),
//       );

//       await _initEngine(session, isLanClient: false);
//       _session = session;
//       _isLanHost = true;
//       _state = null; // will be set when game starts

//       _subscribeLanMessages();
//       _subscribePeers();
//       await _repo.saveSession(session);

//       _setLoadState(OfflineLoadState.lobby);
//       AppLogger.info('LAN host lobby ready: $sessionId');
//     } catch (e, st) {
//       AppLogger.error('startLanHost failed', error: e, stackTrace: st);
//       _setLoadState(OfflineLoadState.error, error: e.toString());
//     }
//   }

//   // ── LAN HOST: start game ───────────────────────────────────────────────────
//   Future<void> startLanGame() async {
//     if (!_isLanHost || _session == null || _engine == null) return;

//     // Engine was already init'd in startLanHost with all players (via _subscribePeers)
//     _state = _engine!.currentState;

//     _lan.broadcastStartGame(_session!.id);
//     _lan.broadcastGameState(_session!.id, _engine!.serializeState());

//     _loadState = OfflineLoadState.ready;
//     _startSnapshotTimer();
//     _scheduleNotify();
//     AppLogger.info('LAN game started with ${_session!.players.length} players');
//   }

//   // ── LAN: discovery ─────────────────────────────────────────────────────────
//   Future<void> startDiscovery() async {
//     _discoveredRooms = [];
//     await _lan.startDiscovery();
//     _lan.roomStream.listen((room) {
//       _discoveredRooms = [
//         ..._discoveredRooms.where(
//           (r) => r.sessionId != room.sessionId && !r.isStale,
//         ),
//         room,
//       ];
//       _scheduleNotify();
//     });
//   }

//   // ── LAN CLIENT: connect ────────────────────────────────────────────────────
//   Future<bool> connectToRoom({
//     required LanRoomDescriptor room,
//     required String playerId,
//     required String playerName,
//   }) async {
//     _setLoadState(OfflineLoadState.loading);
//     _clientPlayerId = playerId;
//     _clientPlayerName = playerName;
//     _isLanHost = false;
//     _lanConnected = false;
//     _clientEngineReady = false;
//     _pendingSnapshot = null;

//     // Subscribe BEFORE connecting so joinAck is never missed
//     _subscribeLanMessages();

//     try {
//       await _lan.connectToHost(
//         room: room,
//         playerId: playerId,
//         playerName: playerName,
//       );
//       _lanConnected = true;
//       AppLogger.info('Connected to ${room.hostName}, waiting for joinAck…');
//       return true;
//     } catch (e) {
//       _lanError = 'Could not connect: $e';
//       _setLoadState(OfflineLoadState.error, error: _lanError!);
//       return false;
//     }
//   }

//   // ── Chat ───────────────────────────────────────────────────────────────────
//   void sendChat(String text) {
//     if (text.trim().isEmpty) return;
//     final myId = _isLanHost
//         ? (_session?.players.firstOrNull?.id ?? '')
//         : (_clientPlayerId ?? '');
//     final myName = _isLanHost
//         ? (_session?.players.firstOrNull?.name ?? 'Host')
//         : (_clientPlayerName ?? 'Player');

//     final msg = LanMessage(
//       type: LanMessageType.chat,
//       senderId: myId,
//       payload: {'name': myName, 'text': text.trim()},
//       ts: DateTime.now().millisecondsSinceEpoch,
//     );

//     // Always add locally immediately (not incoming, so don't increment unread)
//     _addChat(
//       myId,
//       myName,
//       text.trim(),
//       DateTime.fromMillisecondsSinceEpoch(msg.ts),
//       isIncoming: false,
//     );

//     if (_isLanHost) {
//       _lan.broadcastMessage(msg);
//     } else {
//       _lan.sendAction(msg);
//     }
//   }

//   void _addChat(
//     String id,
//     String name,
//     String text,
//     DateTime ts, {
//     bool isIncoming = false,
//   }) {
//     _chatMessages.add(
//       LanChatMessage(senderId: id, senderName: name, text: text, ts: ts),
//     );
//     if (isIncoming) _unreadChatCount++;
//     _scheduleNotify();
//   }

//   void clearUnreadChat() {
//     _unreadChatCount = 0;
//     _scheduleNotify();
//   }

//   /// Host: disconnect a player from the lobby.
//   void kickLanPlayer(String playerId) {
//     if (!_isLanHost) return;
//     _lan.kickPeer(playerId);
//   }

//   // ── Message dispatch ───────────────────────────────────────────────────────
//   void _onLanMessage(LanMessage msg) {
//     AppLogger.info('LAN ← ${msg.type} (host=$_isLanHost)');
//     if (_isLanHost) {
//       _onHostReceived(msg);
//     } else {
//       _onClientReceived(msg);
//     }
//   }

//   // ── HOST: handle incoming from clients ─────────────────────────────────────
//   void _onHostReceived(LanMessage msg) {
//     switch (msg.type) {
//       case LanMessageType.playerAction:
//         if (_state == null || _engine == null) return;
//         final ev = msg.payload['event'] as Map<String, dynamic>?;
//         if (ev == null) return;
//         try {
//           final action = ev['action'] as String? ?? ev['type'] as String? ?? '';
//           if (action == 'advance') {
//             _state = _engine!.advanceTurn();
//           } else {
//             final event = _parseEvent(ev);
//             if (event != null) {
//               _state = _engine!.handleEvent(event);
//             } else {
//               AppLogger.warning('Host: unknown action "$action"');
//               return;
//             }
//           }
//           _onEngineStateChanged();
//           _scheduleNotify();
//           _broadcastState();
//         } catch (e) {
//           AppLogger.warning('Host: playerAction error: $e');
//         }

//       case LanMessageType.chat:
//         // Add to host list and relay to other clients
//         final name = msg.payload['name'] as String? ?? 'Player';
//         final text = msg.payload['text'] as String? ?? '';
//         _addChat(
//           msg.senderId,
//           name,
//           text,
//           DateTime.fromMillisecondsSinceEpoch(msg.ts),
//           isIncoming: true,
//         );
//         _lan.broadcastMessageExcept(msg, msg.senderId);

//       default:
//         break;
//     }
//   }

//   // ── CLIENT: handle incoming from host ──────────────────────────────────────
//   void _onClientReceived(LanMessage msg) {
//     switch (msg.type) {
//       case LanMessageType.joinAck:
//         if (_session != null) return; // already processed
//         try {
//           final d = LanRoomDescriptor.fromJson(msg.payload);
//           _session = OfflineSession(
//             id: d.sessionId,
//             mode: OfflineMode.lan,
//             gameType: d.gameType,
//             config: GameConfig(
//               maxRounds: d.maxRounds,
//               turnTimerSeconds: d.turnTimerSeconds,
//               allowSkip: d.allowSkip,
//               allowSpicy: d.allowSpicy,
//             ),
//             players: [
//               OfflinePlayer(
//                 id: _clientPlayerId ?? _uuid.v4(),
//                 name: _clientPlayerName ?? 'Player',
//                 seatOrder: 0,
//               ),
//             ],
//             packId: '',
//             packName: d.packName,
//             createdAt: DateTime.now(),
//           );
//           // Init engine without cards (client doesn't have the pack)
//           _initClientEngine(_session!);
//           AppLogger.info('Client: joinAck ok — ${d.gameType} "${d.packName}"');
//         } catch (e) {
//           AppLogger.error('Client: joinAck failed', error: e);
//         }

//       case LanMessageType.lobbyUpdate:
//         final players = (msg.payload['players'] as List? ?? [])
//             .map(
//               (p) => OfflinePlayer(
//                 id: p['id'] as String,
//                 name: p['name'] as String,
//                 seatOrder: p['seat'] as int? ?? 0,
//               ),
//             )
//             .toList();
//         if (_session != null) {
//           _session = _session!.copyWithPlayers(players);

//           // Adopt the UUID the host assigned us (matched by name)
//           // The host creates players with uuid.v4() — we must use that
//           // ID as our identity so isMyTurn works correctly
//           final myEntry = players.firstWhere(
//             (p) => p.name == _clientPlayerName,
//             orElse: () =>
//                 players.lastOrNull ??
//                 OfflinePlayer(
//                   id: _clientPlayerId ?? '',
//                   name: '',
//                   seatOrder: 0,
//                 ),
//           );
//           if (myEntry.id != _clientPlayerId) {
//             AppLogger.info(
//               'Client: adopting host-assigned ID '
//               '${myEntry.id} (was $_clientPlayerId)',
//             );
//             _clientPlayerId = myEntry.id;
//           }

//           AppLogger.info(
//             'Client: lobby has ${players.length} players: '
//             '${players.map((p) => p.name).join(', ')}',
//           );

//           if (!_clientEngineReady) {
//             _initClientEngineWithIds(players.map((p) => p.id).toList());
//           }
//           if (_pendingSnapshot != null) {
//             _tryApplySnapshot(_pendingSnapshot!);
//           }
//           _scheduleNotify();
//         }

//       case LanMessageType.startGame:
//         // Game state will follow immediately — just log
//         AppLogger.info('Client: startGame signal received');

//       case LanMessageType.gameState:
//         final snap = msg.payload['snapshot'] as Map<String, dynamic>?;
//         if (snap != null) {
//           AppLogger.info('Client: gameState received');
//           _tryApplySnapshot(snap);
//         }

//       case LanMessageType.chat:
//         // Only add if not from myself (already added locally in sendChat)
//         if (msg.senderId == _clientPlayerId) break;
//         final name = msg.payload['name'] as String? ?? 'Player';
//         final text = msg.payload['text'] as String? ?? '';
//         _addChat(
//           msg.senderId,
//           name,
//           text,
//           DateTime.fromMillisecondsSinceEpoch(msg.ts),
//           isIncoming: true,
//         );

//       case LanMessageType.ping:
//         // Send pong with our playerId so host can find us in _peers
//         _lan.sendPong(_clientPlayerId ?? _session?.id ?? '');

//       case LanMessageType.leave:
//         // Host kicked us
//         _setLoadState(
//           OfflineLoadState.error,
//           error: 'You were removed from the room by the host.',
//         );

//       default:
//         break;
//     }
//   }

//   // ── Client engine helpers ──────────────────────────────────────────────────

//   /// Create engine without cards. Player IDs will be set when lobbyUpdate arrives.
//   void _initClientEngine(OfflineSession session) {
//     final factory = gameRegistry[session.gameType];
//     if (factory == null) {
//       AppLogger.error('Client: no engine for ${session.gameType}');
//       return;
//     }
//     _engine = factory(session.config, <dynamic>[]);
//     // Don't init player order yet — wait for lobbyUpdate
//     _clientEngineReady = false;
//     _loadState = OfflineLoadState.lobby;
//     _scheduleNotify();
//   }

//   /// Init engine player order once we have the full player list from lobbyUpdate.
//   void _initClientEngineWithIds(List<String> ids) {
//     if (_engine == null || ids.isEmpty) return;
//     try {
//       if (_engine is TruthOrDareEngine)
//         (_engine as TruthOrDareEngine).init(playerOrder: ids);
//       else if (_engine is NeverHaveIEverEngine)
//         (_engine as NeverHaveIEverEngine).init(ids);
//       else if (_engine is MemeGameEngine)
//         (_engine as MemeGameEngine).init(ids);
//       _clientEngineReady = true;
//       AppLogger.info('Client engine ready with players: $ids');
//     } catch (e) {
//       AppLogger.warning('Client: engine init failed: $e');
//     }
//   }

//   void _tryApplySnapshot(Map<String, dynamic> snapshot) {
//     if (_engine == null) {
//       _pendingSnapshot = snapshot;
//       AppLogger.warning('Client: engine null, queuing snapshot');
//       return;
//     }

//     // If engine not yet init'd with players, try now
//     if (!_clientEngineReady && _session != null) {
//       final ids = _session!.players.map((p) => p.id).toList();
//       _initClientEngineWithIds(ids);
//     }

//     if (!_clientEngineReady) {
//       _pendingSnapshot = snapshot;
//       AppLogger.warning('Client: engine not ready, queuing snapshot');
//       return;
//     }

//     try {
//       _engine!.restoreFromSnapshot(snapshot);
//       _state = _engine!.currentState;
//       _loadState = OfflineLoadState.ready;
//       _pendingSnapshot = null;
//       _scheduleNotify();
//       AppLogger.info('Client: snapshot applied, state=${_state.runtimeType}');
//     } catch (e, st) {
//       AppLogger.error(
//         'Client: restoreFromSnapshot failed',
//         error: e,
//         stackTrace: st,
//       );
//     }
//   }

//   // ── Client: send action to host ────────────────────────────────────────────
//   Future<void> sendLanAction(Map<String, dynamic> payload) async {
//     if (_isLanHost || !_lanConnected) return;
//     // Wrap in 'event' key for host's _onHostReceived
//     final wrapped = payload.containsKey('event') ? payload : {'event': payload};
//     _lan.sendAction(
//       LanMessage(
//         type: LanMessageType.playerAction,
//         senderId: _clientPlayerId ?? '',
//         payload: wrapped,
//         ts: DateTime.now().millisecondsSinceEpoch,
//       ),
//     );
//   }

//   // ── Parse event ────────────────────────────────────────────────────────────
//   GameEngineEvent? _parseEvent(Map<String, dynamic> m) {
//     final action = m['action'] as String? ?? m['type'] as String? ?? '';
//     final userId = m['user_id'] as String? ?? m['userId'] as String? ?? '';
//     final ts = m['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
//     return switch (action) {
//       // ── ToD ──────────────────────────────────────────────────────────────
//       'tod_choice' || 'choice' => TodChoiceEvent(
//         userId: userId,
//         ts: ts,
//         cardType: (m['card_type'] ?? m['cardType']) == 'dare'
//             ? TodCardType.dare
//             : TodCardType.truth,
//       ),
//       'tod_complete' || 'complete' => TodCompleteEvent(
//         userId: userId,
//         ts: ts,
//         response: m['response'] as String? ?? '',
//         proofImageB64: m['proof_image'] as String? ?? '',
//       ),
//       'tod_react' || 'react' => TodReactEvent(
//         userId: userId,
//         ts: ts,
//         emoji: m['emoji'] as String? ?? '👍',
//       ),
//       'tod_vote_response' ||
//       'vote_response' => TodVoteResponseEvent(userId: userId, ts: ts),
//       'tod_skip' || 'skip' => TodSkipEvent(userId: userId, ts: ts),
//       // ── NHIE ─────────────────────────────────────────────────────────────
//       'nhie_vote' => NhieVoteEvent(
//         userId: userId,
//         ts: ts,
//         haveI: m['have_i'] as bool? ?? false,
//         message: m['message'] as String? ?? '',
//       ),
//       'nhie_react' => NhieReactionEvent(
//         userId: userId,
//         ts: ts,
//         sticker: m['sticker'] as String? ?? '',
//       ),
//       // ── Meme ─────────────────────────────────────────────────────────────
//       'meme_submit' => MemeSubmitEvent(
//         userId: userId,
//         ts: ts,
//         caption: m['caption'] as String? ?? '',
//         stickerChoice: m['sticker_choice'] as String? ?? '',
//       ),
//       'meme_vote' => MemeVoteEvent(
//         userId: userId,
//         ts: ts,
//         targetUserId: m['target_user_id'] as String? ?? '',
//       ),
//       'meme_react' => MemeReactEvent(
//         userId: userId,
//         ts: ts,
//         targetUserId: m['target_user_id'] as String? ?? '',
//         emoji: m['emoji'] as String? ?? '👍',
//       ),
//       _ => null,
//     };
//   }

//   // ── Broadcast state from host ──────────────────────────────────────────────
//   void _broadcastState() {
//     if (!_isLanHost || _engine == null || _session == null) return;
//     _lan.broadcastGameState(_session!.id, _engine!.serializeState());
//   }

//   // ── Engine init (host / pass-and-play) ────────────────────────────────────
//   Future<void> _initEngine(
//     OfflineSession session, {
//     required bool isLanClient,
//   }) async {
//     if (isLanClient) {
//       // Client: create engine without cards, player IDs set later
//       _initClientEngine(session);
//       return;
//     }
//     final cards = await _loadCards(session);
//     final factory = gameRegistry[session.gameType];
//     if (factory == null) throw Exception('No engine for ${session.gameType}');
//     _engine = factory(session.config, cards);
//     final ids = session.players.map((p) => p.id).toList();
//     if (_engine is TruthOrDareEngine)
//       (_engine as TruthOrDareEngine).init(playerOrder: ids);
//     else if (_engine is NeverHaveIEverEngine)
//       (_engine as NeverHaveIEverEngine).init(ids);
//     else if (_engine is MemeGameEngine)
//       (_engine as MemeGameEngine).init(ids);
//   }

//   Future<List<dynamic>> _loadCards(OfflineSession session) async {
//     final todCards = await TodRepository.instance.loadCardsFromCache(
//       packId: session.packId,
//       language: session.config.language,
//       allowSpicy: session.config.allowSpicy,
//     );
//     if (todCards.isEmpty && session.packId.isNotEmpty)
//       throw Exception('No cards for "${session.packName}". Download it first.');
//     return switch (session.gameType) {
//       GameType.neverHaveIEver => todCards.map((c) {
//         var t = c.content;
//         for (final p in ['Never have I ever ', 'never have I ever '])
//           if (t.startsWith(p)) {
//             t = t.substring(p.length);
//             break;
//           }
//         if (t.isNotEmpty) t = t[0].toUpperCase() + t.substring(1);
//         return NhieCard(id: c.id, content: t, difficulty: c.difficulty.name);
//       }).toList(),
//       GameType.memeGame =>
//         todCards.map((c) => MemePrompt(id: c.id, caption: c.content)).toList(),
//       _ => todCards,
//     };
//   }

//   // ── Peer subscription (host only) ─────────────────────────────────────────
//   void _subscribePeers() {
//     _peerSub?.cancel();
//     _peerSub = _lan.peerStream.listen((peers) {
//       _lanPeers = peers;
//       if (_isLanHost && _session != null) {
//         final host = _session!.players.first;
//         final all = [
//           host,
//           ...peers.asMap().entries.map(
//             (e) => OfflinePlayer(
//               id: e.value.playerId,
//               name: e.value.playerName,
//               seatOrder: e.key + 1,
//             ),
//           ),
//         ];
//         _session = _session!.copyWithPlayers(all);

//         // Re-init engine player order if game not started yet
//         if (_state == null && _engine != null) {
//           final ids = all.map((p) => p.id).toList();
//           try {
//             if (_engine is TruthOrDareEngine)
//               (_engine as TruthOrDareEngine).init(playerOrder: ids);
//             else if (_engine is NeverHaveIEverEngine)
//               (_engine as NeverHaveIEverEngine).init(ids);
//             else if (_engine is MemeGameEngine)
//               (_engine as MemeGameEngine).init(ids);
//             AppLogger.info('Host engine re-inited: ${ids.length} players');
//           } catch (e) {
//             AppLogger.warning('Host engine re-init failed: $e');
//           }
//         }

//         _lan.broadcastLobbyUpdate(_session!.id, all);

//         // If game running, send state to new joiner
//         if (_state != null) {
//           Future.delayed(const Duration(milliseconds: 500), _broadcastState);
//         }
//       }
//       _scheduleNotify();
//     });
//   }

//   // ── Message subscription ───────────────────────────────────────────────────
//   void _subscribeLanMessages() {
//     _msgSub?.cancel();
//     _msgSub = _lan.messageStream.listen(
//       _onLanMessage,
//       onError: (e) => AppLogger.warning('LAN stream error: $e'),
//     );

//     _disconnSub?.cancel();
//     _disconnSub = _lan.disconnectStream.listen((playerId) {
//       if (_session != null) {
//         _session = _session!.copyWithPlayers(
//           _session!.players
//               .map((p) => p.id == playerId ? p.copyWith(isConnected: false) : p)
//               .toList(),
//         );
//         _scheduleNotify();
//       }
//     });
//   }

//   // ── Snapshot ───────────────────────────────────────────────────────────────
//   void _onEngineStateChanged() {
//     _eventsSinceSnapshot++;
//     if (_engine?.isGameOver == true) {
//       _loadState = OfflineLoadState.gameOver;
//       _repo.endSession(_session?.id ?? '');
//     }
//     if (_eventsSinceSnapshot >= _snapshotInterval) {
//       _persistSnapshot();
//       _eventsSinceSnapshot = 0;
//     }
//   }

//   void _startSnapshotTimer() {
//     _snapshotTimer?.cancel();
//     _snapshotTimer = Timer.periodic(
//       const Duration(seconds: 15),
//       (_) => _persistSnapshot(),
//     );
//   }

//   Future<void> _persistSnapshot() async {
//     if (_session == null || _engine == null) return;
//     try {
//       await _repo.updateSnapshot(
//         _session!.id,
//         jsonEncode(_engine!.serializeState()),
//       );
//     } catch (_) {}
//   }

//   // ── Notify helpers ─────────────────────────────────────────────────────────

//   /// Schedule notification for next microtask — avoids calling during build.
//   void _scheduleNotify() {
//     if (_disposed) return;
//     // Use microtask so we never call notifyListeners() synchronously
//     // from a socket callback while Flutter is building
//     scheduleMicrotask(() {
//       if (!_disposed) notifyListeners();
//     });
//   }

//   void _setLoadState(OfflineLoadState s, {String? error}) {
//     _loadState = s;
//     _error = error;
//     _scheduleNotify();
//   }

//   // ── Public helpers ─────────────────────────────────────────────────────────
//   void endGame() {
//     _loadState = OfflineLoadState.gameOver;
//     _repo.endSession(_session?.id ?? '');
//     _scheduleNotify();
//   }

//   void reset() {
//     _session = null;
//     _engine = null;
//     _state = null;
//     _loadState = OfflineLoadState.idle;
//     _error = null;
//     _isLanHost = false;
//     _discoveredRooms = [];
//     _lanPeers = [];
//     _lanConnected = false;
//     _chatMessages.clear();
//     _unreadChatCount = 0;
//     _pendingSnapshot = null;
//     _clientEngineReady = false;
//     _scheduleNotify();
//   }

//   // ── Helpers ────────────────────────────────────────────────────────────────
//   Future<String> _resolveLocalIp() async {
//     try {
//       final ifaces = await NetworkInterface.list(
//         type: InternetAddressType.IPv4,
//         includeLinkLocal: false,
//       );
//       for (final iface in ifaces) {
//         final n = iface.name.toLowerCase();
//         if (n.contains('wlan') ||
//             n.contains('wifi') ||
//             n.contains('ap') ||
//             n.contains('en0')) {
//           return iface.addresses.first.address;
//         }
//       }
//       if (ifaces.isNotEmpty) return ifaces.first.addresses.first.address;
//     } catch (_) {}
//     return '0.0.0.0';
//   }

//   static const _dataPort = 47890;

//   @override
//   void dispose() {
//     _disposed = true;
//     _snapshotTimer?.cancel();
//     _msgSub?.cancel();
//     _peerSub?.cancel();
//     _disconnSub?.cancel();
//     _lan.stop().ignore();
//     super.dispose();
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:jma3a/features/games/truth_or_dare/truth_or_dare_engine.dart';
import 'package:jma3a/features/offline/data/offline_repository.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/app_logger.dart';
import '../../games/engine/base_game_engine.dart';
import '../../games/engine/game_registry.dart';
import '../../games/truth_or_dare/data/tod_repository.dart';
import '../../games/truth_or_dare/domain/tod_models.dart';
import '../../games/never_have_i_ever/never_have_i_ever_engine.dart';
import '../../games/meme_game/meme_game_engine.dart';
import '../domain/offline_session.dart';
import '../services/lan_service.dart';

const _uuid = Uuid();

enum OfflineLoadState { idle, loading, lobby, ready, error, gameOver }

class LanChatMessage {
  const LanChatMessage({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.ts,
  });
  final String senderId;
  final String senderName;
  final String text;
  final DateTime ts;
}

class OfflineGameProvider extends ChangeNotifier {
  OfflineGameProvider({required OfflineRepository repository})
    : _repo = repository;

  final OfflineRepository _repo;
  final _lan = LanService.instance;

  OfflineSession? _session;
  BaseGameEngine? _engine;
  GameEngineState? _state;
  OfflineLoadState _loadState = OfflineLoadState.idle;
  String? _error;
  bool _isLanHost = false;
  bool _disposed = false;

  List<LanRoomDescriptor> _discoveredRooms = [];
  List<LanPeerInfo> _lanPeers = [];
  bool _lanConnected = false;
  String? _lanError;
  String? _clientPlayerId;
  String? _clientPlayerName;
  final List<LanChatMessage> _chatMessages = [];
  int _unreadChatCount = 0;
  Map<String, dynamic>? _pendingSnapshot;
  bool _clientEngineReady = false; // engine init'd with player IDs

  StreamSubscription<LanMessage>? _msgSub;
  StreamSubscription<List<LanPeerInfo>>? _peerSub;
  StreamSubscription<String>? _disconnSub;
  Timer? _snapshotTimer;
  int _eventsSinceSnapshot = 0;
  static const _snapshotInterval = 10;

  // ── Getters ────────────────────────────────────────────────────────────────
  OfflineSession? get session => _session;
  GameEngineState? get state => _state;
  OfflineLoadState get loadState => _loadState;
  String? get error => _error;
  bool get isReady => _loadState == OfflineLoadState.ready;
  bool get isLobby => _loadState == OfflineLoadState.lobby;
  bool get isGameOver => _loadState == OfflineLoadState.gameOver;
  bool get isLanHost => _isLanHost;
  List<LanRoomDescriptor> get discoveredRooms => _discoveredRooms;
  List<LanPeerInfo> get lanPeers => _lanPeers;
  bool get lanConnected => _lanConnected;
  String? get lanError => _lanError;
  List<OfflinePlayer> get players => _session?.players ?? [];
  GameType? get gameType => _session?.gameType;
  OfflineMode? get mode => _session?.mode;
  String? get clientPlayerId => _clientPlayerId;
  List<LanChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  int get unreadChatCount => _unreadChatCount;

  // ── Pass-and-play ──────────────────────────────────────────────────────────
  Future<void> startPassAndPlay({
    required GameType gameType,
    required GameConfig config,
    required List<String> playerNames,
    required String packId,
    required String packName,
    String? packCoverUrl,
  }) async {
    _setLoadState(OfflineLoadState.loading);
    try {
      final players = playerNames
          .asMap()
          .entries
          .map(
            (e) =>
                OfflinePlayer(id: _uuid.v4(), name: e.value, seatOrder: e.key),
          )
          .toList();
      final session = OfflineSession(
        id: _uuid.v4(),
        mode: OfflineMode.passAndPlay,
        gameType: gameType,
        config: config,
        players: players,
        packId: packId,
        packName: packName,
        packCoverUrl: packCoverUrl,
        createdAt: DateTime.now(),
      );
      await _initEngine(session, isLanClient: false);
      _session = session;
      _state = _engine!.currentState;
      await _repo.saveSession(session);
      _startSnapshotTimer();
      _setLoadState(OfflineLoadState.ready);
    } catch (e, st) {
      AppLogger.error('startPassAndPlay failed', error: e, stackTrace: st);
      _setLoadState(OfflineLoadState.error, error: e.toString());
    }
  }

  // ── Resume ─────────────────────────────────────────────────────────────────
  Future<bool> resumeActiveSession() async {
    final session = await _repo.getActiveSession();
    if (session == null || session.stateSnapshot == null) return false;
    _setLoadState(OfflineLoadState.loading);
    try {
      await _initEngine(session, isLanClient: false);
      _engine!.restoreFromSnapshot(
        jsonDecode(session.stateSnapshot!) as Map<String, dynamic>,
      );
      _state = _engine!.currentState;
      _session = session;
      _startSnapshotTimer();
      _setLoadState(OfflineLoadState.ready);
      return true;
    } catch (e) {
      _setLoadState(OfflineLoadState.error, error: 'Could not resume.');
      return false;
    }
  }

  // ── Engine actions ─────────────────────────────────────────────────────────
  GameEngineState? advanceTurn() {
    if (_engine == null) return null;
    _state = _engine!.advanceTurn();
    _onEngineStateChanged();
    _scheduleNotify();
    if (_isLanHost) _broadcastState();
    return _state;
  }

  GameEngineState? handleEvent(GameEngineEvent event) {
    if (_engine == null) return null;
    _state = _engine!.handleEvent(event);
    _onEngineStateChanged();
    _scheduleNotify();
    if (_isLanHost) _broadcastState();
    return _state;
  }

  // ── LAN HOST: start ────────────────────────────────────────────────────────
  Future<void> startLanHost({
    required GameType gameType,
    required GameConfig config,
    required List<String> playerNames,
    required String packId,
    required String packName,
    required String hostName,
    String? packCoverUrl,
  }) async {
    _setLoadState(OfflineLoadState.loading);
    try {
      final players = playerNames
          .asMap()
          .entries
          .map(
            (e) =>
                OfflinePlayer(id: _uuid.v4(), name: e.value, seatOrder: e.key),
          )
          .toList();

      final sessionId = _uuid.v4();
      final hostIp = await _resolveLocalIp();

      final descriptor = LanRoomDescriptor(
        sessionId: sessionId,
        hostName: hostName,
        hostAddress: hostIp,
        port: _dataPort,
        gameType: gameType,
        playerCount: players.length,
        maxPlayers: 12,
        packName: packName,
        advertisedAt: DateTime.now(),
        maxRounds: config.maxRounds,
        turnTimerSeconds: config.turnTimerSeconds,
        allowSpicy: config.allowSpicy,
        allowSkip: config.allowSkip,
      );

      await _lan.startHost(descriptor: descriptor);

      final session = OfflineSession(
        id: sessionId,
        mode: OfflineMode.lan,
        gameType: gameType,
        config: config,
        players: players,
        packId: packId,
        packName: packName,
        packCoverUrl: packCoverUrl,
        createdAt: DateTime.now(),
      );

      await _initEngine(session, isLanClient: false);
      _session = session;
      _isLanHost = true;
      _state = null; // will be set when game starts

      _subscribeLanMessages();
      _subscribePeers();
      await _repo.saveSession(session);

      _setLoadState(OfflineLoadState.lobby);
      AppLogger.info('LAN host lobby ready: $sessionId');
    } catch (e, st) {
      AppLogger.error('startLanHost failed', error: e, stackTrace: st);
      _setLoadState(OfflineLoadState.error, error: e.toString());
    }
  }

  // ── LAN HOST: start game ───────────────────────────────────────────────────
  Future<void> startLanGame() async {
    if (!_isLanHost || _session == null || _engine == null) return;

    // Engine was already init'd in startLanHost with all players (via _subscribePeers)
    _state = _engine!.currentState;

    _lan.broadcastStartGame(_session!.id);
    _lan.broadcastGameState(_session!.id, _engine!.serializeState());

    _loadState = OfflineLoadState.ready;
    _startSnapshotTimer();
    _scheduleNotify();
    AppLogger.info('LAN game started with ${_session!.players.length} players');
  }

  // ── LAN: discovery ─────────────────────────────────────────────────────────
  Future<void> startDiscovery() async {
    _discoveredRooms = [];
    await _lan.startDiscovery();
    _lan.roomStream.listen((room) {
      _discoveredRooms = [
        ..._discoveredRooms.where(
          (r) => r.sessionId != room.sessionId && !r.isStale,
        ),
        room,
      ];
      _scheduleNotify();
    });
  }

  // ── LAN CLIENT: connect ────────────────────────────────────────────────────
  Future<bool> connectToRoom({
    required LanRoomDescriptor room,
    required String playerId,
    required String playerName,
  }) async {
    _setLoadState(OfflineLoadState.loading);
    _clientPlayerId = playerId;
    _clientPlayerName = playerName;
    _isLanHost = false;
    _lanConnected = false;
    _clientEngineReady = false;
    _pendingSnapshot = null;

    // Subscribe BEFORE connecting so joinAck is never missed
    _subscribeLanMessages();

    try {
      await _lan.connectToHost(
        room: room,
        playerId: playerId,
        playerName: playerName,
      );
      _lanConnected = true;
      AppLogger.info('Connected to ${room.hostName}, waiting for joinAck…');
      return true;
    } catch (e) {
      _lanError = 'Could not connect: $e';
      _setLoadState(OfflineLoadState.error, error: _lanError!);
      return false;
    }
  }

  // ── Chat ───────────────────────────────────────────────────────────────────
  void sendChat(String text) {
    if (text.trim().isEmpty) return;
    final myId = _isLanHost
        ? (_session?.players.firstOrNull?.id ?? '')
        : (_clientPlayerId ?? '');
    final myName = _isLanHost
        ? (_session?.players.firstOrNull?.name ?? 'Host')
        : (_clientPlayerName ?? 'Player');

    final msg = LanMessage(
      type: LanMessageType.chat,
      senderId: myId,
      payload: {'name': myName, 'text': text.trim()},
      ts: DateTime.now().millisecondsSinceEpoch,
    );

    // Always add locally immediately (not incoming, so don't increment unread)
    _addChat(
      myId,
      myName,
      text.trim(),
      DateTime.fromMillisecondsSinceEpoch(msg.ts),
      isIncoming: false,
    );

    if (_isLanHost) {
      _lan.broadcastMessage(msg);
    } else {
      _lan.sendAction(msg);
    }
  }

  void _addChat(
    String id,
    String name,
    String text,
    DateTime ts, {
    bool isIncoming = false,
  }) {
    _chatMessages.add(
      LanChatMessage(senderId: id, senderName: name, text: text, ts: ts),
    );
    if (isIncoming) _unreadChatCount++;
    _scheduleNotify();
  }

  void clearUnreadChat() {
    _unreadChatCount = 0;
    _scheduleNotify();
  }

  /// Host: disconnect a player from the lobby.
  void kickLanPlayer(String playerId) {
    if (!_isLanHost) return;
    _lan.kickPeer(playerId);
  }

  // ── Message dispatch ───────────────────────────────────────────────────────
  void _onLanMessage(LanMessage msg) {
    AppLogger.info('LAN ← ${msg.type} (host=$_isLanHost)');
    if (_isLanHost) {
      _onHostReceived(msg);
    } else {
      _onClientReceived(msg);
    }
  }

  // ── HOST: handle incoming from clients ─────────────────────────────────────
  void _onHostReceived(LanMessage msg) {
    switch (msg.type) {
      case LanMessageType.playerAction:
        if (_state == null || _engine == null) return;
        final ev = msg.payload['event'] as Map<String, dynamic>?;
        if (ev == null) return;
        try {
          final action = ev['action'] as String? ?? ev['type'] as String? ?? '';
          if (action == 'advance') {
            _state = _engine!.advanceTurn();
          } else {
            final event = _parseEvent(ev);
            if (event != null) {
              _state = _engine!.handleEvent(event);
            } else {
              AppLogger.warning('Host: unknown action "$action"');
              return;
            }
          }
          _onEngineStateChanged();
          _scheduleNotify();
          _broadcastState();
        } catch (e) {
          AppLogger.warning('Host: playerAction error: $e');
        }

      case LanMessageType.chat:
        // Add to host list and relay to other clients
        final name = msg.payload['name'] as String? ?? 'Player';
        final text = msg.payload['text'] as String? ?? '';
        _addChat(
          msg.senderId,
          name,
          text,
          DateTime.fromMillisecondsSinceEpoch(msg.ts),
          isIncoming: true,
        );
        _lan.broadcastMessageExcept(msg, msg.senderId);

      default:
        break;
    }
  }

  // ── CLIENT: handle incoming from host ──────────────────────────────────────
  void _onClientReceived(LanMessage msg) {
    switch (msg.type) {
      case LanMessageType.joinAck:
        if (_session != null) return; // already processed
        try {
          final d = LanRoomDescriptor.fromJson(msg.payload);
          _session = OfflineSession(
            id: d.sessionId,
            mode: OfflineMode.lan,
            gameType: d.gameType,
            config: GameConfig(
              maxRounds: d.maxRounds,
              turnTimerSeconds: d.turnTimerSeconds,
              allowSkip: d.allowSkip,
              allowSpicy: d.allowSpicy,
            ),
            players: [
              OfflinePlayer(
                id: _clientPlayerId ?? _uuid.v4(),
                name: _clientPlayerName ?? 'Player',
                seatOrder: 0,
              ),
            ],
            packId: '',
            packName: d.packName,
            createdAt: DateTime.now(),
          );
          // Init engine without cards (client doesn't have the pack)
          _initClientEngine(_session!);
          AppLogger.info('Client: joinAck ok — ${d.gameType} "${d.packName}"');
        } catch (e) {
          AppLogger.error('Client: joinAck failed', error: e);
        }

      case LanMessageType.lobbyUpdate:
        final players = (msg.payload['players'] as List? ?? [])
            .map(
              (p) => OfflinePlayer(
                id: p['id'] as String,
                name: p['name'] as String,
                seatOrder: p['seat'] as int? ?? 0,
              ),
            )
            .toList();
        if (_session != null) {
          _session = _session!.copyWithPlayers(players);

          // Adopt the UUID the host assigned us (matched by name)
          // The host creates players with uuid.v4() — we must use that
          // ID as our identity so isMyTurn works correctly
          final myEntry = players.firstWhere(
            (p) => p.name == _clientPlayerName,
            orElse: () =>
                players.lastOrNull ??
                OfflinePlayer(
                  id: _clientPlayerId ?? '',
                  name: '',
                  seatOrder: 0,
                ),
          );
          if (myEntry.id != _clientPlayerId) {
            AppLogger.info(
              'Client: adopting host-assigned ID '
              '${myEntry.id} (was $_clientPlayerId)',
            );
            _clientPlayerId = myEntry.id;
          }

          AppLogger.info(
            'Client: lobby has ${players.length} players: '
            '${players.map((p) => p.name).join(', ')}',
          );

          if (!_clientEngineReady) {
            _initClientEngineWithIds(players.map((p) => p.id).toList());
          }
          if (_pendingSnapshot != null) {
            _tryApplySnapshot(_pendingSnapshot!);
          }
          _scheduleNotify();
        }

      case LanMessageType.startGame:
        // Game state will follow immediately — just log
        AppLogger.info('Client: startGame signal received');

      case LanMessageType.gameState:
        final snap = msg.payload['snapshot'] as Map<String, dynamic>?;
        if (snap != null) {
          AppLogger.info('Client: gameState received');
          _tryApplySnapshot(snap);
        }

      case LanMessageType.chat:
        // Only add if not from myself (already added locally in sendChat)
        if (msg.senderId == _clientPlayerId) break;
        final name = msg.payload['name'] as String? ?? 'Player';
        final text = msg.payload['text'] as String? ?? '';
        _addChat(
          msg.senderId,
          name,
          text,
          DateTime.fromMillisecondsSinceEpoch(msg.ts),
          isIncoming: true,
        );

      case LanMessageType.ping:
        // Send pong with our playerId so host can find us in _peers
        _lan.sendPong(_clientPlayerId ?? _session?.id ?? '');

      case LanMessageType.leave:
        final reason = msg.payload['reason'] as String? ?? '';
        if (reason == 'host_quit') {
          _setLoadState(
            OfflineLoadState.error,
            error: 'The host left the game.',
          );
        } else {
          _setLoadState(
            OfflineLoadState.error,
            error: 'You were removed from the room by the host.',
          );
        }

      default:
        break;
    }
  }

  // ── Client engine helpers ──────────────────────────────────────────────────

  /// Create engine without cards. Player IDs will be set when lobbyUpdate arrives.
  void _initClientEngine(OfflineSession session) {
    final factory = gameRegistry[session.gameType];
    if (factory == null) {
      AppLogger.error('Client: no engine for ${session.gameType}');
      return;
    }
    _engine = factory(session.config, <dynamic>[]);
    // Don't init player order yet — wait for lobbyUpdate
    _clientEngineReady = false;
    _loadState = OfflineLoadState.lobby;
    _scheduleNotify();
  }

  /// Init engine player order once we have the full player list from lobbyUpdate.
  void _initClientEngineWithIds(List<String> ids) {
    if (_engine == null || ids.isEmpty) return;
    try {
      if (_engine is TruthOrDareEngine)
        (_engine as TruthOrDareEngine).init(playerOrder: ids);
      else if (_engine is NeverHaveIEverEngine)
        (_engine as NeverHaveIEverEngine).init(ids);
      else if (_engine is MemeGameEngine)
        (_engine as MemeGameEngine).init(ids);
      _clientEngineReady = true;
      AppLogger.info('Client engine ready with players: $ids');
    } catch (e) {
      AppLogger.warning('Client: engine init failed: $e');
    }
  }

  void _tryApplySnapshot(Map<String, dynamic> snapshot) {
    if (_engine == null) {
      _pendingSnapshot = snapshot;
      AppLogger.warning('Client: engine null, queuing snapshot');
      return;
    }

    // If engine not yet init'd with players, try now
    if (!_clientEngineReady && _session != null) {
      final ids = _session!.players.map((p) => p.id).toList();
      _initClientEngineWithIds(ids);
    }

    if (!_clientEngineReady) {
      _pendingSnapshot = snapshot;
      AppLogger.warning('Client: engine not ready, queuing snapshot');
      return;
    }

    try {
      _engine!.restoreFromSnapshot(snapshot);
      _state = _engine!.currentState;
      _loadState = OfflineLoadState.ready;
      _pendingSnapshot = null;
      _scheduleNotify();
      AppLogger.info('Client: snapshot applied, state=${_state.runtimeType}');
    } catch (e, st) {
      AppLogger.error(
        'Client: restoreFromSnapshot failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  // ── Client: send action to host ────────────────────────────────────────────
  Future<void> sendLanAction(Map<String, dynamic> payload) async {
    if (_isLanHost || !_lanConnected) return;
    // Wrap in 'event' key for host's _onHostReceived
    final wrapped = payload.containsKey('event') ? payload : {'event': payload};
    _lan.sendAction(
      LanMessage(
        type: LanMessageType.playerAction,
        senderId: _clientPlayerId ?? '',
        payload: wrapped,
        ts: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  // ── Parse event ────────────────────────────────────────────────────────────
  GameEngineEvent? _parseEvent(Map<String, dynamic> m) {
    final action = m['action'] as String? ?? m['type'] as String? ?? '';
    final userId = m['user_id'] as String? ?? m['userId'] as String? ?? '';
    final ts = m['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    return switch (action) {
      // ── ToD ──────────────────────────────────────────────────────────────
      'tod_choice' || 'choice' => TodChoiceEvent(
        userId: userId,
        ts: ts,
        cardType: (m['card_type'] ?? m['cardType']) == 'dare'
            ? TodCardType.dare
            : TodCardType.truth,
      ),
      'tod_complete' || 'complete' => TodCompleteEvent(
        userId: userId,
        ts: ts,
        response: m['response'] as String? ?? '',
        proofImageB64: m['proof_image'] as String? ?? '',
      ),
      'tod_react' || 'react' => TodReactEvent(
        userId: userId,
        ts: ts,
        emoji: m['emoji'] as String? ?? '👍',
      ),
      'tod_vote_response' ||
      'vote_response' => TodVoteResponseEvent(userId: userId, ts: ts),
      'tod_skip' || 'skip' => TodSkipEvent(userId: userId, ts: ts),
      // ── NHIE ─────────────────────────────────────────────────────────────
      'nhie_vote' => NhieVoteEvent(
        userId: userId,
        ts: ts,
        haveI: m['have_i'] as bool? ?? false,
        message: m['message'] as String? ?? '',
      ),
      'nhie_react' => NhieReactionEvent(
        userId: userId,
        ts: ts,
        sticker: m['sticker'] as String? ?? '',
      ),
      // ── Meme ─────────────────────────────────────────────────────────────
      'meme_submit' => MemeSubmitEvent(
        userId: userId,
        ts: ts,
        caption: m['caption'] as String? ?? '',
        stickerChoice: m['sticker_choice'] as String? ?? '',
      ),
      'meme_vote' => MemeVoteEvent(
        userId: userId,
        ts: ts,
        targetUserId: m['target_user_id'] as String? ?? '',
      ),
      'meme_react' => MemeReactEvent(
        userId: userId,
        ts: ts,
        targetUserId: m['target_user_id'] as String? ?? '',
        emoji: m['emoji'] as String? ?? '👍',
      ),
      _ => null,
    };
  }

  // ── Broadcast state from host ──────────────────────────────────────────────
  void _broadcastState() {
    if (!_isLanHost || _engine == null || _session == null) return;
    _lan.broadcastGameState(_session!.id, _engine!.serializeState());
  }

  // ── Engine init (host / pass-and-play) ────────────────────────────────────
  Future<void> _initEngine(
    OfflineSession session, {
    required bool isLanClient,
  }) async {
    if (isLanClient) {
      // Client: create engine without cards, player IDs set later
      _initClientEngine(session);
      return;
    }
    final cards = await _loadCards(session);
    final factory = gameRegistry[session.gameType];
    if (factory == null) throw Exception('No engine for ${session.gameType}');
    _engine = factory(session.config, cards);
    final ids = session.players.map((p) => p.id).toList();
    if (_engine is TruthOrDareEngine)
      (_engine as TruthOrDareEngine).init(playerOrder: ids);
    else if (_engine is NeverHaveIEverEngine)
      (_engine as NeverHaveIEverEngine).init(ids);
    else if (_engine is MemeGameEngine)
      (_engine as MemeGameEngine).init(ids);
  }

  Future<List<dynamic>> _loadCards(OfflineSession session) async {
    final todCards = await TodRepository.instance.loadCardsFromCache(
      packId: session.packId,
      language: session.config.language,
      allowSpicy: session.config.allowSpicy,
    );
    if (todCards.isEmpty && session.packId.isNotEmpty)
      throw Exception('No cards for "${session.packName}". Download it first.');
    return switch (session.gameType) {
      GameType.neverHaveIEver => todCards.map((c) {
        var t = c.content;
        for (final p in ['Never have I ever ', 'never have I ever '])
          if (t.startsWith(p)) {
            t = t.substring(p.length);
            break;
          }
        if (t.isNotEmpty) t = t[0].toUpperCase() + t.substring(1);
        return NhieCard(id: c.id, content: t, difficulty: c.difficulty.name);
      }).toList(),
      GameType.memeGame =>
        todCards.map((c) => MemePrompt(id: c.id, caption: c.content)).toList(),
      _ => todCards,
    };
  }

  // ── Peer subscription (host only) ─────────────────────────────────────────
  void _subscribePeers() {
    _peerSub?.cancel();
    _peerSub = _lan.peerStream.listen((peers) {
      _lanPeers = peers;
      if (_isLanHost && _session != null) {
        final host = _session!.players.first;
        final all = [
          host,
          ...peers.asMap().entries.map(
            (e) => OfflinePlayer(
              id: e.value.playerId,
              name: e.value.playerName,
              seatOrder: e.key + 1,
            ),
          ),
        ];
        _session = _session!.copyWithPlayers(all);

        // Re-init engine player order if game not started yet
        if (_state == null && _engine != null) {
          final ids = all.map((p) => p.id).toList();
          try {
            if (_engine is TruthOrDareEngine)
              (_engine as TruthOrDareEngine).init(playerOrder: ids);
            else if (_engine is NeverHaveIEverEngine)
              (_engine as NeverHaveIEverEngine).init(ids);
            else if (_engine is MemeGameEngine)
              (_engine as MemeGameEngine).init(ids);
            AppLogger.info('Host engine re-inited: ${ids.length} players');
          } catch (e) {
            AppLogger.warning('Host engine re-init failed: $e');
          }
        }

        _lan.broadcastLobbyUpdate(_session!.id, all);

        // If game running, send state to new joiner
        if (_state != null) {
          Future.delayed(const Duration(milliseconds: 500), _broadcastState);
        }
      }
      _scheduleNotify();
    });
  }

  // ── Message subscription ───────────────────────────────────────────────────
  void _subscribeLanMessages() {
    _msgSub?.cancel();
    _msgSub = _lan.messageStream.listen(
      _onLanMessage,
      onError: (e) => AppLogger.warning('LAN stream error: $e'),
    );

    _disconnSub?.cancel();
    _disconnSub = _lan.disconnectStream.listen((playerId) {
      if (_session != null) {
        _session = _session!.copyWithPlayers(
          _session!.players
              .map((p) => p.id == playerId ? p.copyWith(isConnected: false) : p)
              .toList(),
        );
        _scheduleNotify();
      }
    });
  }

  // ── Snapshot ───────────────────────────────────────────────────────────────
  void _onEngineStateChanged() {
    _eventsSinceSnapshot++;
    if (_engine?.isGameOver == true) {
      _loadState = OfflineLoadState.gameOver;
      _repo.endSession(_session?.id ?? '');
    }
    if (_eventsSinceSnapshot >= _snapshotInterval) {
      _persistSnapshot();
      _eventsSinceSnapshot = 0;
    }
  }

  void _startSnapshotTimer() {
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _persistSnapshot(),
    );
  }

  Future<void> _persistSnapshot() async {
    if (_session == null || _engine == null) return;
    try {
      await _repo.updateSnapshot(
        _session!.id,
        jsonEncode(_engine!.serializeState()),
      );
    } catch (_) {}
  }

  // ── Notify helpers ─────────────────────────────────────────────────────────

  /// Schedule notification for next microtask — avoids calling during build.
  void _scheduleNotify() {
    if (_disposed) return;
    // Use microtask so we never call notifyListeners() synchronously
    // from a socket callback while Flutter is building
    scheduleMicrotask(() {
      if (!_disposed) notifyListeners();
    });
  }

  void _setLoadState(OfflineLoadState s, {String? error}) {
    _loadState = s;
    _error = error;
    _scheduleNotify();
  }

  // ── Public helpers ─────────────────────────────────────────────────────────
  void endGame() {
    _loadState = OfflineLoadState.gameOver;
    _repo.endSession(_session?.id ?? '');
    _scheduleNotify();
  }

  void reset() {
    _session = null;
    _engine = null;
    _state = null;
    _loadState = OfflineLoadState.idle;
    _error = null;
    _isLanHost = false;
    _discoveredRooms = [];
    _lanPeers = [];
    _lanConnected = false;
    _chatMessages.clear();
    _unreadChatCount = 0;
    _pendingSnapshot = null;
    _clientEngineReady = false;
    _scheduleNotify();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Future<String> _resolveLocalIp() async {
    try {
      final ifaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in ifaces) {
        final n = iface.name.toLowerCase();
        if (n.contains('wlan') ||
            n.contains('wifi') ||
            n.contains('ap') ||
            n.contains('en0')) {
          return iface.addresses.first.address;
        }
      }
      if (ifaces.isNotEmpty) return ifaces.first.addresses.first.address;
    } catch (_) {}
    return '0.0.0.0';
  }

  static const _dataPort = 47890;

  @override
  void dispose() {
    _disposed = true;
    _snapshotTimer?.cancel();
    // If we're the host, broadcast quit so all clients know to leave
    if (_isLanHost && _session != null) {
      try {
        _lan.broadcastMessage(
          LanMessage(
            type: LanMessageType.leave,
            senderId: 'host',
            payload: {'reason': 'host_quit'},
            ts: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } catch (_) {}
    }
    _msgSub?.cancel();
    _peerSub?.cancel();
    _disconnSub?.cancel();
    _lan.stop().ignore();
    super.dispose();
  }
}
