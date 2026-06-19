// // // // import 'dart:async';
// // // // import 'dart:convert';
// // // // import 'dart:io';

// // // // import '../../../core/utils/app_logger.dart';
// // // // import '../domain/offline_session.dart';

// // // // const _discoveryGroup = '239.255.255.250';
// // // // const _discoveryPort = 47889;
// // // // const _dataPort = 47890;
// // // // const _maxMessageBytes = 64 * 1024;

// // // // enum LanRole { host, client, none }

// // // // class LanPeerInfo {
// // // //   LanPeerInfo({
// // // //     required this.playerId,
// // // //     required this.playerName,
// // // //     required this.address,
// // // //     this.socket,
// // // //   });
// // // //   final String playerId;
// // // //   final String playerName;
// // // //   final InternetAddress address;
// // // //   Socket? socket;
// // // //   bool isConnected = true;
// // // //   DateTime lastSeen = DateTime.now();
// // // //   void touch() => lastSeen = DateTime.now();
// // // // }

// // // // class LanService {
// // // //   LanService._();
// // // //   static final LanService _instance = LanService._();
// // // //   static LanService get instance => _instance;

// // // //   LanRole _role = LanRole.none;
// // // //   bool get isHost => _role == LanRole.host;
// // // //   bool get isClient => _role == LanRole.client;
// // // //   bool get isRunning => _role != LanRole.none;

// // // //   ServerSocket? _server;
// // // //   Timer? _advertisingTimer;
// // // //   Timer? _pingTimer;
// // // //   final Map<String, LanPeerInfo> _peers = {};
// // // //   LanRoomDescriptor? _descriptor;

// // // //   Socket? _hostSocket;
// // // //   RawDatagramSocket? _listenSocket;

// // // //   // Fresh stream controllers — recreated on each start
// // // //   StreamController<LanRoomDescriptor> _roomCtrl = StreamController.broadcast();
// // // //   StreamController<LanMessage> _messageCtrl = StreamController.broadcast();
// // // //   StreamController<List<LanPeerInfo>> _peerCtrl = StreamController.broadcast();
// // // //   StreamController<String> _disconnectCtrl = StreamController.broadcast();

// // // //   Stream<LanRoomDescriptor> get roomStream => _roomCtrl.stream;
// // // //   Stream<LanMessage> get messageStream => _messageCtrl.stream;
// // // //   Stream<List<LanPeerInfo>> get peerStream => _peerCtrl.stream;
// // // //   Stream<String> get disconnectStream => _disconnectCtrl.stream;

// // // //   List<LanPeerInfo> get peers => List.unmodifiable(_peers.values);

// // // //   // ── Reset streams (called before each new session) ─────────────────────────
// // // //   void _resetStreams() {
// // // //     if (!_roomCtrl.isClosed) _roomCtrl.close().ignore();
// // // //     if (!_messageCtrl.isClosed) _messageCtrl.close().ignore();
// // // //     if (!_peerCtrl.isClosed) _peerCtrl.close().ignore();
// // // //     if (!_disconnectCtrl.isClosed) _disconnectCtrl.close().ignore();

// // // //     _roomCtrl = StreamController.broadcast();
// // // //     _messageCtrl = StreamController.broadcast();
// // // //     _peerCtrl = StreamController.broadcast();
// // // //     _disconnectCtrl = StreamController.broadcast();
// // // //   }

// // // //   // ── HOST: start ────────────────────────────────────────────────────────────
// // // //   Future<void> startHost({required LanRoomDescriptor descriptor}) async {
// // // //     await _cleanup();
// // // //     _resetStreams();
// // // //     _role = LanRole.host;
// // // //     _descriptor = descriptor;

// // // //     _server = await ServerSocket.bind(
// // // //       InternetAddress.anyIPv4,
// // // //       _dataPort,
// // // //       shared: true,
// // // //     );
// // // //     _server!.listen(
// // // //       _onClientConnected,
// // // //       onError: (e) => AppLogger.error('LanService server error', error: e),
// // // //     );

// // // //     _startAdvertising(descriptor);

// // // //     _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
// // // //       _sendToPeers(
// // // //         LanMessage(
// // // //           type: LanMessageType.ping,
// // // //           senderId: descriptor.sessionId,
// // // //           payload: {},
// // // //           ts: _ts(),
// // // //         ),
// // // //       );
// // // //       _reapStalePeers();
// // // //     });

// // // //     AppLogger.info('LanService: hosting on port $_dataPort');
// // // //   }

// // // //   // ── HOST: broadcast ────────────────────────────────────────────────────────
// // // //   void broadcastGameState(String sessionId, Map<String, dynamic> snapshot) {
// // // //     _sendToPeers(
// // // //       LanMessage(
// // // //         type: LanMessageType.gameState,
// // // //         senderId: sessionId,
// // // //         payload: {'snapshot': snapshot},
// // // //         ts: _ts(),
// // // //       ),
// // // //     );
// // // //   }

// // // //   void broadcastStartGame(String sessionId) {
// // // //     _sendToPeers(
// // // //       LanMessage(
// // // //         type: LanMessageType.startGame,
// // // //         senderId: sessionId,
// // // //         payload: {},
// // // //         ts: _ts(),
// // // //       ),
// // // //     );
// // // //   }

// // // //   void broadcastLobbyUpdate(String sessionId, List<OfflinePlayer> players) {
// // // //     _sendToPeers(
// // // //       LanMessage(
// // // //         type: LanMessageType.lobbyUpdate,
// // // //         senderId: sessionId,
// // // //         payload: {
// // // //           'players': players
// // // //               .map((p) => {'id': p.id, 'name': p.name, 'seat': p.seatOrder})
// // // //               .toList(),
// // // //         },
// // // //         ts: _ts(),
// // // //       ),
// // // //     );
// // // //   }

// // // //   void broadcastMessage(LanMessage msg) => _sendToPeers(msg);

// // // //   void broadcastMessageExcept(LanMessage msg, String excludeId) {
// // // //     for (final peer in _peers.values.toList()) {
// // // //       if (peer.playerId != excludeId) _sendToPeer(peer, msg);
// // // //     }
// // // //   }

// // // //   // ── HOST: internal ─────────────────────────────────────────────────────────
// // // //   void _onClientConnected(Socket socket) {
// // // //     AppLogger.info(
// // // //       'LanService: client connected from ${socket.remoteAddress.address}',
// // // //     );
// // // //     final buf = StringBuffer();

// // // //     socket.listen(
// // // //       (data) {
// // // //         buf.write(utf8.decode(data, allowMalformed: true));
// // // //         final raw = buf.toString();
// // // //         final lines = raw.split('\n');
// // // //         for (var i = 0; i < lines.length - 1; i++) {
// // // //           final line = lines[i].trim();
// // // //           if (line.isEmpty || line.length > _maxMessageBytes) continue;
// // // //           final msg = LanMessage.fromJson(line);
// // // //           if (msg == null) continue;

// // // //           if (msg.type == LanMessageType.join) {
// // // //             final pid = msg.payload['player_id'] as String? ?? '';
// // // //             final name = msg.payload['player_name'] as String? ?? 'Player';
// // // //             final peer = LanPeerInfo(
// // // //               playerId: pid,
// // // //               playerName: name,
// // // //               address: socket.remoteAddress,
// // // //               socket: socket,
// // // //             );
// // // //             _peers[pid] = peer;
// // // //             if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
// // // //             AppLogger.info('LanService: $name ($pid) joined');

// // // //             // Send joinAck immediately
// // // //             _sendToPeer(
// // // //               peer,
// // // //               LanMessage(
// // // //                 type: LanMessageType.joinAck,
// // // //                 senderId: _descriptor?.sessionId ?? '',
// // // //                 payload: _descriptor?.toJson() ?? {},
// // // //                 ts: _ts(),
// // // //               ),
// // // //             );
// // // //           } else if (msg.type == LanMessageType.pong) {
// // // //             _peers[msg.senderId]?.touch();
// // // //           } else {
// // // //             if (!_messageCtrl.isClosed) _messageCtrl.add(msg);
// // // //           }
// // // //         }
// // // //         buf.clear();
// // // //         if (lines.isNotEmpty) buf.write(lines.last);
// // // //       },
// // // //       onError: (_) => _handleDisconnect(socket),
// // // //       onDone: () => _handleDisconnect(socket),
// // // //       cancelOnError: false,
// // // //     );
// // // //   }

// // // //   void _handleDisconnect(Socket socket) {
// // // //     final entry = _peers.entries
// // // //         .where((e) => e.value.socket == socket)
// // // //         .firstOrNull;
// // // //     if (entry != null) {
// // // //       AppLogger.info('LanService: ${entry.value.playerName} disconnected');
// // // //       entry.value.isConnected = false;
// // // //       _peers.remove(entry.key);
// // // //       if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(entry.key);
// // // //       if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
// // // //     }
// // // //     try {
// // // //       socket.destroy();
// // // //     } catch (_) {}
// // // //   }

// // // //   void _sendToPeers(LanMessage msg) {
// // // //     for (final peer in _peers.values.toList()) _sendToPeer(peer, msg);
// // // //   }

// // // //   void _sendToPeer(LanPeerInfo peer, LanMessage msg) {
// // // //     try {
// // // //       peer.socket?.add(utf8.encode('${msg.toJson()}\n'));
// // // //     } catch (e) {
// // // //       AppLogger.warning('LanService: send to ${peer.playerName} failed: $e');
// // // //       _peers.remove(peer.playerId);
// // // //       if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
// // // //     }
// // // //   }

// // // //   void _reapStalePeers() {
// // // //     final stale = _peers.entries
// // // //         .where(
// // // //           (e) => DateTime.now().difference(e.value.lastSeen).inSeconds > 30,
// // // //         )
// // // //         .map((e) => e.key)
// // // //         .toList();
// // // //     for (final id in stale) {
// // // //       AppLogger.info('LanService: reaping stale peer $id');
// // // //       _peers.remove(id);
// // // //       if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(id);
// // // //     }
// // // //     if (stale.isNotEmpty && !_peerCtrl.isClosed) _peerCtrl.add(peers);
// // // //   }

// // // //   // ── HOST: UDP advertising ──────────────────────────────────────────────────
// // // //   void _startAdvertising(LanRoomDescriptor descriptor) {
// // // //     _advertisingTimer?.cancel();
// // // //     _advertisingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
// // // //       RawDatagramSocket? sock;
// // // //       try {
// // // //         sock = await RawDatagramSocket.bind(
// // // //           InternetAddress.anyIPv4,
// // // //           0,
// // // //           reuseAddress: true,
// // // //           reusePort: false,
// // // //         );
// // // //         sock.broadcastEnabled = true;
// // // //         final bytes = utf8.encode(jsonEncode(descriptor.toJson()));
// // // //         try {
// // // //           sock.send(bytes, InternetAddress(_discoveryGroup), _discoveryPort);
// // // //         } catch (_) {}
// // // //         sock.send(bytes, InternetAddress('255.255.255.255'), _discoveryPort);
// // // //       } catch (e) {
// // // //         AppLogger.warning('LanService: advertising failed: $e');
// // // //       } finally {
// // // //         sock?.close();
// // // //       }
// // // //     });
// // // //   }

// // // //   // ── CLIENT: discovery ──────────────────────────────────────────────────────
// // // //   Future<void> startDiscovery() async {
// // // //     _resetStreams();
// // // //     // Close any existing listen socket before binding
// // // //     try {
// // // //       _listenSocket?.close();
// // // //     } catch (_) {}
// // // //     _listenSocket = null;

// // // //     // Try binding with reusePort, fallback without
// // // //     for (final reusePort in [true, false]) {
// // // //       try {
// // // //         _listenSocket = await RawDatagramSocket.bind(
// // // //           InternetAddress.anyIPv4,
// // // //           _discoveryPort,
// // // //           reuseAddress: true,
// // // //           reusePort: reusePort,
// // // //         );
// // // //         break;
// // // //       } catch (e) {
// // // //         AppLogger.warning(
// // // //           'LanService: bind attempt (reusePort=$reusePort) failed: $e',
// // // //         );
// // // //       }
// // // //     }

// // // //     if (_listenSocket == null) {
// // // //       AppLogger.error(
// // // //         'LanService: could not bind discovery port $_discoveryPort',
// // // //       );
// // // //       return;
// // // //     }

// // // //     try {
// // // //       _listenSocket!.joinMulticast(InternetAddress(_discoveryGroup));
// // // //     } catch (_) {}
// // // //     try {
// // // //       _listenSocket!.broadcastEnabled = true;
// // // //     } catch (_) {}

// // // //     _listenSocket!.listen((event) {
// // // //       if (event != RawSocketEvent.read) return;
// // // //       final dg = _listenSocket?.receive();
// // // //       if (dg == null || dg.data.length > _maxMessageBytes) return;
// // // //       try {
// // // //         final j = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
// // // //         var room = LanRoomDescriptor.fromJson(j);
// // // //         room = room.copyWith(hostAddress: dg.address.address);
// // // //         if (!room.isStale && !_roomCtrl.isClosed) _roomCtrl.add(room);
// // // //       } catch (_) {}
// // // //     });
// // // //     AppLogger.info('LanService: discovery started');
// // // //   }

// // // //   // ── CLIENT: connect ────────────────────────────────────────────────────────
// // // //   Future<void> connectToHost({
// // // //     required LanRoomDescriptor room,
// // // //     required String playerId,
// // // //     required String playerName,
// // // //   }) async {
// // // //     _role = LanRole.client;
// // // //     _hostSocket?.destroy();
// // // //     _hostSocket = await Socket.connect(
// // // //       room.hostAddress,
// // // //       room.port,
// // // //       timeout: const Duration(seconds: 10),
// // // //     );

// // // //     final buf = StringBuffer();
// // // //     _hostSocket!.listen(
// // // //       (data) {
// // // //         buf.write(utf8.decode(data, allowMalformed: true));
// // // //         final raw = buf.toString();
// // // //         final lines = raw.split('\n');
// // // //         for (var i = 0; i < lines.length - 1; i++) {
// // // //           final line = lines[i].trim();
// // // //           if (line.isEmpty) continue;
// // // //           final msg = LanMessage.fromJson(line);
// // // //           if (msg != null && !_messageCtrl.isClosed) {
// // // //             AppLogger.info('Client received: ${msg.type}');
// // // //             _messageCtrl.add(msg);
// // // //           }
// // // //         }
// // // //         buf.clear();
// // // //         if (lines.isNotEmpty) buf.write(lines.last);
// // // //       },
// // // //       onError: (e) {
// // // //         AppLogger.warning('Client socket error: $e');
// // // //         if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(playerId);
// // // //       },
// // // //       onDone: () {
// // // //         AppLogger.warning('Client socket closed');
// // // //         if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(playerId);
// // // //       },
// // // //       cancelOnError: false,
// // // //     );

// // // //     _hostSocket!.add(
// // // //       utf8.encode(
// // // //         '${LanMessage(type: LanMessageType.join, senderId: playerId, payload: {'player_id': playerId, 'player_name': playerName}, ts: _ts()).toJson()}\n',
// // // //       ),
// // // //     );

// // // //     AppLogger.info(
// // // //       'LanService: connected to ${room.hostAddress}:${room.port} as $playerName',
// // // //     );
// // // //   }

// // // //   // ── CLIENT: send ───────────────────────────────────────────────────────────
// // // //   void sendAction(LanMessage msg) {
// // // //     try {
// // // //       _hostSocket?.add(utf8.encode('${msg.toJson()}\n'));
// // // //     } catch (e) {
// // // //       AppLogger.error('LanService: sendAction failed', error: e);
// // // //     }
// // // //   }

// // // //   void sendPong(String sessionId) {
// // // //     sendAction(
// // // //       LanMessage(
// // // //         type: LanMessageType.pong,
// // // //         senderId: sessionId,
// // // //         payload: {},
// // // //         ts: _ts(),
// // // //       ),
// // // //     );
// // // //   }

// // // //   /// Stop only UDP discovery (client-side). Does not close TCP connection.
// // // //   void stopDiscovery() {
// // // //     _listenSocket?.close();
// // // //     _listenSocket = null;
// // // //   }

// // // //   // ── Cleanup ────────────────────────────────────────────────────────────────
// // // //   Future<void> _cleanup() async {
// // // //     _advertisingTimer?.cancel();
// // // //     _pingTimer?.cancel();
// // // //     _advertisingTimer = null;
// // // //     _pingTimer = null;

// // // //     _listenSocket?.close();
// // // //     _listenSocket = null;

// // // //     for (final p in _peers.values) {
// // // //       try {
// // // //         p.socket?.destroy();
// // // //       } catch (_) {}
// // // //     }
// // // //     _peers.clear();

// // // //     _hostSocket?.destroy();
// // // //     _hostSocket = null;

// // // //     try {
// // // //       await _server?.close();
// // // //     } catch (_) {}
// // // //     _server = null;

// // // //     _descriptor = null;
// // // //     _role = LanRole.none;
// // // //   }

// // // //   Future<void> stop() async {
// // // //     await _cleanup();
// // // //     AppLogger.info('LanService: stopped');
// // // //   }

// // // //   int _ts() => DateTime.now().millisecondsSinceEpoch;
// // // // }

// // // import 'dart:async';
// // // import 'dart:convert';
// // // import 'dart:io';

// // // import '../../../core/utils/app_logger.dart';
// // // import '../domain/offline_session.dart';

// // // const _discoveryGroup = '239.255.255.250';
// // // const _discoveryPort = 47889;
// // // const _dataPort = 47890;
// // // const _maxMessageBytes = 64 * 1024;

// // // enum LanRole { host, client, none }

// // // class LanPeerInfo {
// // //   LanPeerInfo({
// // //     required this.playerId,
// // //     required this.playerName,
// // //     required this.address,
// // //     this.socket,
// // //   });
// // //   final String playerId;
// // //   final String playerName;
// // //   final InternetAddress address;
// // //   Socket? socket;
// // //   bool isConnected = true;
// // //   DateTime lastSeen = DateTime.now();
// // //   void touch() => lastSeen = DateTime.now();
// // // }

// // // class LanService {
// // //   LanService._();
// // //   static final LanService _instance = LanService._();
// // //   static LanService get instance => _instance;

// // //   LanRole _role = LanRole.none;
// // //   bool get isHost => _role == LanRole.host;
// // //   bool get isClient => _role == LanRole.client;
// // //   bool get isRunning => _role != LanRole.none;

// // //   ServerSocket? _server;
// // //   Timer? _advertisingTimer;
// // //   Timer? _pingTimer;
// // //   final Map<String, LanPeerInfo> _peers = {};
// // //   LanRoomDescriptor? _descriptor;

// // //   Socket? _hostSocket;
// // //   RawDatagramSocket? _listenSocket;

// // //   // Fresh stream controllers — recreated on each start
// // //   StreamController<LanRoomDescriptor> _roomCtrl = StreamController.broadcast();
// // //   StreamController<LanMessage> _messageCtrl = StreamController.broadcast();
// // //   StreamController<List<LanPeerInfo>> _peerCtrl = StreamController.broadcast();
// // //   StreamController<String> _disconnectCtrl = StreamController.broadcast();

// // //   Stream<LanRoomDescriptor> get roomStream => _roomCtrl.stream;
// // //   Stream<LanMessage> get messageStream => _messageCtrl.stream;
// // //   Stream<List<LanPeerInfo>> get peerStream => _peerCtrl.stream;
// // //   Stream<String> get disconnectStream => _disconnectCtrl.stream;

// // //   List<LanPeerInfo> get peers => List.unmodifiable(_peers.values);

// // //   // ── Reset streams (called before each new session) ─────────────────────────
// // //   void _resetStreams() {
// // //     if (!_roomCtrl.isClosed) _roomCtrl.close().ignore();
// // //     if (!_messageCtrl.isClosed) _messageCtrl.close().ignore();
// // //     if (!_peerCtrl.isClosed) _peerCtrl.close().ignore();
// // //     if (!_disconnectCtrl.isClosed) _disconnectCtrl.close().ignore();

// // //     _roomCtrl = StreamController.broadcast();
// // //     _messageCtrl = StreamController.broadcast();
// // //     _peerCtrl = StreamController.broadcast();
// // //     _disconnectCtrl = StreamController.broadcast();
// // //   }

// // //   // ── HOST: start ────────────────────────────────────────────────────────────
// // //   Future<void> startHost({required LanRoomDescriptor descriptor}) async {
// // //     await _cleanup();
// // //     _resetStreams();
// // //     _role = LanRole.host;
// // //     _descriptor = descriptor;

// // //     _server = await ServerSocket.bind(
// // //       InternetAddress.anyIPv4,
// // //       _dataPort,
// // //       shared: true,
// // //     );
// // //     _server!.listen(
// // //       _onClientConnected,
// // //       onError: (e) => AppLogger.error('LanService server error', error: e),
// // //     );

// // //     _startAdvertising(descriptor);

// // //     _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
// // //       _sendToPeers(
// // //         LanMessage(
// // //           type: LanMessageType.ping,
// // //           senderId: descriptor.sessionId,
// // //           payload: {},
// // //           ts: _ts(),
// // //         ),
// // //       );
// // //       _reapStalePeers();
// // //     });

// // //     AppLogger.info('LanService: hosting on port $_dataPort');
// // //   }

// // //   // ── HOST: broadcast ────────────────────────────────────────────────────────
// // //   void broadcastGameState(String sessionId, Map<String, dynamic> snapshot) {
// // //     _sendToPeers(
// // //       LanMessage(
// // //         type: LanMessageType.gameState,
// // //         senderId: sessionId,
// // //         payload: {'snapshot': snapshot},
// // //         ts: _ts(),
// // //       ),
// // //     );
// // //   }

// // //   void broadcastStartGame(String sessionId) {
// // //     _sendToPeers(
// // //       LanMessage(
// // //         type: LanMessageType.startGame,
// // //         senderId: sessionId,
// // //         payload: {},
// // //         ts: _ts(),
// // //       ),
// // //     );
// // //   }

// // //   void broadcastLobbyUpdate(String sessionId, List<OfflinePlayer> players) {
// // //     _sendToPeers(
// // //       LanMessage(
// // //         type: LanMessageType.lobbyUpdate,
// // //         senderId: sessionId,
// // //         payload: {
// // //           'players': players
// // //               .map((p) => {'id': p.id, 'name': p.name, 'seat': p.seatOrder})
// // //               .toList(),
// // //         },
// // //         ts: _ts(),
// // //       ),
// // //     );
// // //   }

// // //   void broadcastMessage(LanMessage msg) => _sendToPeers(msg);

// // //   void broadcastMessageExcept(LanMessage msg, String excludeId) {
// // //     for (final peer in _peers.values.toList()) {
// // //       if (peer.playerId != excludeId) _sendToPeer(peer, msg);
// // //     }
// // //   }

// // //   // ── HOST: internal ─────────────────────────────────────────────────────────
// // //   void _onClientConnected(Socket socket) {
// // //     AppLogger.info(
// // //       'LanService: client connected from ${socket.remoteAddress.address}',
// // //     );
// // //     final buf = StringBuffer();

// // //     socket.listen(
// // //       (data) {
// // //         buf.write(utf8.decode(data, allowMalformed: true));
// // //         final raw = buf.toString();
// // //         final lines = raw.split('\n');
// // //         for (var i = 0; i < lines.length - 1; i++) {
// // //           final line = lines[i].trim();
// // //           if (line.isEmpty || line.length > _maxMessageBytes) continue;
// // //           final msg = LanMessage.fromJson(line);
// // //           if (msg == null) continue;

// // //           if (msg.type == LanMessageType.join) {
// // //             final pid = msg.payload['player_id'] as String? ?? '';
// // //             final name = msg.payload['player_name'] as String? ?? 'Player';
// // //             final peer = LanPeerInfo(
// // //               playerId: pid,
// // //               playerName: name,
// // //               address: socket.remoteAddress,
// // //               socket: socket,
// // //             );
// // //             _peers[pid] = peer;
// // //             if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
// // //             AppLogger.info('LanService: $name ($pid) joined');

// // //             // Send joinAck immediately
// // //             _sendToPeer(
// // //               peer,
// // //               LanMessage(
// // //                 type: LanMessageType.joinAck,
// // //                 senderId: _descriptor?.sessionId ?? '',
// // //                 payload: _descriptor?.toJson() ?? {},
// // //                 ts: _ts(),
// // //               ),
// // //             );
// // //           } else if (msg.type == LanMessageType.pong) {
// // //             _peers[msg.senderId]?.touch();
// // //           } else {
// // //             if (!_messageCtrl.isClosed) _messageCtrl.add(msg);
// // //           }
// // //         }
// // //         buf.clear();
// // //         if (lines.isNotEmpty) buf.write(lines.last);
// // //       },
// // //       onError: (_) => _handleDisconnect(socket),
// // //       onDone: () => _handleDisconnect(socket),
// // //       cancelOnError: false,
// // //     );
// // //   }

// // //   void _handleDisconnect(Socket socket) {
// // //     final entry = _peers.entries
// // //         .where((e) => e.value.socket == socket)
// // //         .firstOrNull;
// // //     if (entry != null) {
// // //       AppLogger.info('LanService: ${entry.value.playerName} disconnected');
// // //       entry.value.isConnected = false;
// // //       _peers.remove(entry.key);
// // //       if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(entry.key);
// // //       if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
// // //     }
// // //     try {
// // //       socket.destroy();
// // //     } catch (_) {}
// // //   }

// // //   void _sendToPeers(LanMessage msg) {
// // //     for (final peer in _peers.values.toList()) _sendToPeer(peer, msg);
// // //   }

// // //   void _sendToPeer(LanPeerInfo peer, LanMessage msg) {
// // //     try {
// // //       peer.socket?.add(utf8.encode('${msg.toJson()}\n'));
// // //     } catch (e) {
// // //       AppLogger.warning('LanService: send to ${peer.playerName} failed: $e');
// // //       _peers.remove(peer.playerId);
// // //       if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
// // //     }
// // //   }

// // //   void _reapStalePeers() {
// // //     final stale = _peers.entries
// // //         .where(
// // //           (e) => DateTime.now().difference(e.value.lastSeen).inSeconds > 30,
// // //         )
// // //         .map((e) => e.key)
// // //         .toList();
// // //     for (final id in stale) {
// // //       AppLogger.info('LanService: reaping stale peer $id');
// // //       _peers.remove(id);
// // //       if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(id);
// // //     }
// // //     if (stale.isNotEmpty && !_peerCtrl.isClosed) _peerCtrl.add(peers);
// // //   }

// // //   // ── HOST: UDP advertising ──────────────────────────────────────────────────
// // //   void _startAdvertising(LanRoomDescriptor descriptor) {
// // //     _advertisingTimer?.cancel();
// // //     _advertisingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
// // //       RawDatagramSocket? sock;
// // //       try {
// // //         sock = await RawDatagramSocket.bind(
// // //           InternetAddress.anyIPv4,
// // //           0,
// // //           reuseAddress: true,
// // //           reusePort: false,
// // //         );
// // //         sock.broadcastEnabled = true;
// // //         final bytes = utf8.encode(jsonEncode(descriptor.toJson()));
// // //         try {
// // //           sock.send(bytes, InternetAddress(_discoveryGroup), _discoveryPort);
// // //         } catch (_) {}
// // //         sock.send(bytes, InternetAddress('255.255.255.255'), _discoveryPort);
// // //       } catch (e) {
// // //         AppLogger.warning('LanService: advertising failed: $e');
// // //       } finally {
// // //         sock?.close();
// // //       }
// // //     });
// // //   }

// // //   // ── CLIENT: discovery ──────────────────────────────────────────────────────
// // //   Future<void> startDiscovery() async {
// // //     _resetStreams();
// // //     // Close any existing listen socket before binding
// // //     try {
// // //       _listenSocket?.close();
// // //     } catch (_) {}
// // //     _listenSocket = null;

// // //     // Try binding with reusePort, fallback without
// // //     for (final reusePort in [true, false]) {
// // //       try {
// // //         _listenSocket = await RawDatagramSocket.bind(
// // //           InternetAddress.anyIPv4,
// // //           _discoveryPort,
// // //           reuseAddress: true,
// // //           reusePort: reusePort,
// // //         );
// // //         break;
// // //       } catch (e) {
// // //         AppLogger.warning(
// // //           'LanService: bind attempt (reusePort=$reusePort) failed: $e',
// // //         );
// // //       }
// // //     }

// // //     if (_listenSocket == null) {
// // //       AppLogger.error(
// // //         'LanService: could not bind discovery port $_discoveryPort',
// // //       );
// // //       return;
// // //     }

// // //     try {
// // //       _listenSocket!.joinMulticast(InternetAddress(_discoveryGroup));
// // //     } catch (_) {}
// // //     try {
// // //       _listenSocket!.broadcastEnabled = true;
// // //     } catch (_) {}

// // //     _listenSocket!.listen((event) {
// // //       if (event != RawSocketEvent.read) return;
// // //       final dg = _listenSocket?.receive();
// // //       if (dg == null || dg.data.length > _maxMessageBytes) return;
// // //       try {
// // //         final j = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
// // //         var room = LanRoomDescriptor.fromJson(j);
// // //         room = room.copyWith(hostAddress: dg.address.address);
// // //         if (!room.isStale && !_roomCtrl.isClosed) _roomCtrl.add(room);
// // //       } catch (_) {}
// // //     });
// // //     AppLogger.info('LanService: discovery started');
// // //   }

// // //   // ── CLIENT: connect ────────────────────────────────────────────────────────
// // //   Future<void> connectToHost({
// // //     required LanRoomDescriptor room,
// // //     required String playerId,
// // //     required String playerName,
// // //   }) async {
// // //     _role = LanRole.client;
// // //     _hostSocket?.destroy();
// // //     _hostSocket = await Socket.connect(
// // //       room.hostAddress,
// // //       room.port,
// // //       timeout: const Duration(seconds: 10),
// // //     );

// // //     final buf = StringBuffer();
// // //     _hostSocket!.listen(
// // //       (data) {
// // //         buf.write(utf8.decode(data, allowMalformed: true));
// // //         final raw = buf.toString();
// // //         final lines = raw.split('\n');
// // //         for (var i = 0; i < lines.length - 1; i++) {
// // //           final line = lines[i].trim();
// // //           if (line.isEmpty) continue;
// // //           final msg = LanMessage.fromJson(line);
// // //           if (msg != null && !_messageCtrl.isClosed) {
// // //             AppLogger.info('Client received: ${msg.type}');
// // //             _messageCtrl.add(msg);
// // //           }
// // //         }
// // //         buf.clear();
// // //         if (lines.isNotEmpty) buf.write(lines.last);
// // //       },
// // //       onError: (e) {
// // //         AppLogger.warning('Client socket error: $e');
// // //         if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(playerId);
// // //       },
// // //       onDone: () {
// // //         AppLogger.warning('Client socket closed');
// // //         if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(playerId);
// // //       },
// // //       cancelOnError: false,
// // //     );

// // //     _hostSocket!.add(
// // //       utf8.encode(
// // //         '${LanMessage(type: LanMessageType.join, senderId: playerId, payload: {'player_id': playerId, 'player_name': playerName}, ts: _ts()).toJson()}\n',
// // //       ),
// // //     );

// // //     AppLogger.info(
// // //       'LanService: connected to ${room.hostAddress}:${room.port} as $playerName',
// // //     );
// // //   }

// // //   // ── CLIENT: send ───────────────────────────────────────────────────────────
// // //   void sendAction(LanMessage msg) {
// // //     try {
// // //       _hostSocket?.add(utf8.encode('${msg.toJson()}\n'));
// // //     } catch (e) {
// // //       AppLogger.error('LanService: sendAction failed', error: e);
// // //     }
// // //   }

// // //   void sendPong(String sessionId) {
// // //     sendAction(
// // //       LanMessage(
// // //         type: LanMessageType.pong,
// // //         senderId: sessionId,
// // //         payload: {},
// // //         ts: _ts(),
// // //       ),
// // //     );
// // //   }

// // //   /// Stop only UDP discovery (client-side). Does not close TCP connection.
// // //   void stopDiscovery() {
// // //     _listenSocket?.close();
// // //     _listenSocket = null;
// // //   }

// // //   /// Host: forcibly disconnect a peer.
// // //   void kickPeer(String playerId) {
// // //     final peer = _peers[playerId];
// // //     if (peer == null) return;
// // //     // Send a kick message so client knows they were removed
// // //     _sendToPeer(
// // //       peer,
// // //       LanMessage(
// // //         type: LanMessageType.leave,
// // //         senderId: 'host',
// // //         payload: {'reason': 'kicked'},
// // //         ts: _ts(),
// // //       ),
// // //     );
// // //     Future.delayed(const Duration(milliseconds: 200), () {
// // //       try {
// // //         peer.socket?.destroy();
// // //       } catch (_) {}
// // //       _peers.remove(playerId);
// // //       if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(playerId);
// // //       if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
// // //     });
// // //   }

// // //   // ── Cleanup ────────────────────────────────────────────────────────────────
// // //   Future<void> _cleanup() async {
// // //     _advertisingTimer?.cancel();
// // //     _pingTimer?.cancel();
// // //     _advertisingTimer = null;
// // //     _pingTimer = null;

// // //     _listenSocket?.close();
// // //     _listenSocket = null;

// // //     for (final p in _peers.values) {
// // //       try {
// // //         p.socket?.destroy();
// // //       } catch (_) {}
// // //     }
// // //     _peers.clear();

// // //     _hostSocket?.destroy();
// // //     _hostSocket = null;

// // //     try {
// // //       await _server?.close();
// // //     } catch (_) {}
// // //     _server = null;

// // //     _descriptor = null;
// // //     _role = LanRole.none;
// // //   }

// // //   Future<void> stop() async {
// // //     await _cleanup();
// // //     AppLogger.info('LanService: stopped');
// // //   }

// // //   int _ts() => DateTime.now().millisecondsSinceEpoch;
// // // }

// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:io';

// // import '../../../core/utils/app_logger.dart';
// // import '../domain/offline_session.dart';

// // const _discoveryGroup = '239.255.255.250';
// // const _discoveryPort = 47889;
// // const _dataPort = 47890;
// // const _maxMessageBytes = 64 * 1024;

// // enum LanRole { host, client, none }

// // class LanPeerInfo {
// //   LanPeerInfo({
// //     required this.playerId,
// //     required this.playerName,
// //     required this.address,
// //     this.socket,
// //   });
// //   final String playerId;
// //   final String playerName;
// //   final InternetAddress address;
// //   Socket? socket;
// //   bool isConnected = true;
// //   DateTime lastSeen = DateTime.now();
// //   void touch() => lastSeen = DateTime.now();
// // }

// // class LanService {
// //   LanService._();
// //   static final LanService _instance = LanService._();
// //   static LanService get instance => _instance;

// //   LanRole _role = LanRole.none;
// //   bool get isHost => _role == LanRole.host;
// //   bool get isClient => _role == LanRole.client;
// //   bool get isRunning => _role != LanRole.none;

// //   ServerSocket? _server;
// //   Timer? _advertisingTimer;
// //   Timer? _pingTimer;
// //   final Map<String, LanPeerInfo> _peers = {};
// //   LanRoomDescriptor? _descriptor;

// //   Socket? _hostSocket;
// //   RawDatagramSocket? _listenSocket;

// //   // Fresh stream controllers — recreated on each start
// //   StreamController<LanRoomDescriptor> _roomCtrl = StreamController.broadcast();
// //   StreamController<LanMessage> _messageCtrl = StreamController.broadcast();
// //   StreamController<List<LanPeerInfo>> _peerCtrl = StreamController.broadcast();
// //   StreamController<String> _disconnectCtrl = StreamController.broadcast();

// //   Stream<LanRoomDescriptor> get roomStream => _roomCtrl.stream;
// //   Stream<LanMessage> get messageStream => _messageCtrl.stream;
// //   Stream<List<LanPeerInfo>> get peerStream => _peerCtrl.stream;
// //   Stream<String> get disconnectStream => _disconnectCtrl.stream;

// //   List<LanPeerInfo> get peers => List.unmodifiable(_peers.values);

// //   // ── Reset streams (called before each new session) ─────────────────────────
// //   void _resetStreams() {
// //     if (!_roomCtrl.isClosed) _roomCtrl.close().ignore();
// //     if (!_messageCtrl.isClosed) _messageCtrl.close().ignore();
// //     if (!_peerCtrl.isClosed) _peerCtrl.close().ignore();
// //     if (!_disconnectCtrl.isClosed) _disconnectCtrl.close().ignore();

// //     _roomCtrl = StreamController.broadcast();
// //     _messageCtrl = StreamController.broadcast();
// //     _peerCtrl = StreamController.broadcast();
// //     _disconnectCtrl = StreamController.broadcast();
// //   }

// //   // ── HOST: start ────────────────────────────────────────────────────────────
// //   Future<void> startHost({required LanRoomDescriptor descriptor}) async {
// //     await _cleanup();
// //     _resetStreams();
// //     _role = LanRole.host;
// //     _descriptor = descriptor;

// //     _server = await ServerSocket.bind(
// //       InternetAddress.anyIPv4,
// //       _dataPort,
// //       shared: true,
// //     );
// //     _server!.listen(
// //       _onClientConnected,
// //       onError: (e) => AppLogger.error('LanService server error', error: e),
// //     );

// //     _startAdvertising(descriptor);

// //     _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
// //       _sendToPeers(
// //         LanMessage(
// //           type: LanMessageType.ping,
// //           senderId: descriptor.sessionId,
// //           payload: {},
// //           ts: _ts(),
// //         ),
// //       );
// //       _reapStalePeers();
// //     });

// //     AppLogger.info('LanService: hosting on port $_dataPort');
// //   }

// //   // ── HOST: broadcast ────────────────────────────────────────────────────────
// //   void broadcastGameState(String sessionId, Map<String, dynamic> snapshot) {
// //     _sendToPeers(
// //       LanMessage(
// //         type: LanMessageType.gameState,
// //         senderId: sessionId,
// //         payload: {'snapshot': snapshot},
// //         ts: _ts(),
// //       ),
// //     );
// //   }

// //   void broadcastStartGame(String sessionId) {
// //     _sendToPeers(
// //       LanMessage(
// //         type: LanMessageType.startGame,
// //         senderId: sessionId,
// //         payload: {},
// //         ts: _ts(),
// //       ),
// //     );
// //   }

// //   void broadcastLobbyUpdate(String sessionId, List<OfflinePlayer> players) {
// //     _sendToPeers(
// //       LanMessage(
// //         type: LanMessageType.lobbyUpdate,
// //         senderId: sessionId,
// //         payload: {
// //           'players': players
// //               .map((p) => {'id': p.id, 'name': p.name, 'seat': p.seatOrder})
// //               .toList(),
// //         },
// //         ts: _ts(),
// //       ),
// //     );
// //   }

// //   void broadcastMessage(LanMessage msg) => _sendToPeers(msg);

// //   void broadcastMessageExcept(LanMessage msg, String excludeId) {
// //     for (final peer in _peers.values.toList()) {
// //       if (peer.playerId != excludeId) _sendToPeer(peer, msg);
// //     }
// //   }

// //   // ── HOST: internal ─────────────────────────────────────────────────────────
// //   void _onClientConnected(Socket socket) {
// //     AppLogger.info(
// //       'LanService: client connected from ${socket.remoteAddress.address}',
// //     );
// //     final buf = StringBuffer();

// //     socket.listen(
// //       (data) {
// //         buf.write(utf8.decode(data, allowMalformed: true));
// //         final raw = buf.toString();
// //         final lines = raw.split('\n');
// //         for (var i = 0; i < lines.length - 1; i++) {
// //           final line = lines[i].trim();
// //           if (line.isEmpty || line.length > _maxMessageBytes) continue;
// //           final msg = LanMessage.fromJson(line);
// //           if (msg == null) continue;

// //           if (msg.type == LanMessageType.join) {
// //             final pid = msg.payload['player_id'] as String? ?? '';
// //             final name = msg.payload['player_name'] as String? ?? 'Player';
// //             final peer = LanPeerInfo(
// //               playerId: pid,
// //               playerName: name,
// //               address: socket.remoteAddress,
// //               socket: socket,
// //             );
// //             _peers[pid] = peer;
// //             if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
// //             AppLogger.info('LanService: $name ($pid) joined');

// //             // Send joinAck immediately
// //             _sendToPeer(
// //               peer,
// //               LanMessage(
// //                 type: LanMessageType.joinAck,
// //                 senderId: _descriptor?.sessionId ?? '',
// //                 payload: _descriptor?.toJson() ?? {},
// //                 ts: _ts(),
// //               ),
// //             );
// //           } else if (msg.type == LanMessageType.pong) {
// //             _peers[msg.senderId]?.touch();
// //           } else {
// //             if (!_messageCtrl.isClosed) _messageCtrl.add(msg);
// //           }
// //         }
// //         buf.clear();
// //         if (lines.isNotEmpty) buf.write(lines.last);
// //       },
// //       onError: (_) => _handleDisconnect(socket),
// //       onDone: () => _handleDisconnect(socket),
// //       cancelOnError: false,
// //     );
// //   }

// //   void _handleDisconnect(Socket socket) {
// //     final entry = _peers.entries
// //         .where((e) => e.value.socket == socket)
// //         .firstOrNull;
// //     if (entry != null) {
// //       AppLogger.info('LanService: ${entry.value.playerName} disconnected');
// //       entry.value.isConnected = false;
// //       _peers.remove(entry.key);
// //       if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(entry.key);
// //       if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
// //     }
// //     try {
// //       socket.destroy();
// //     } catch (_) {}
// //   }

// //   void _sendToPeers(LanMessage msg) {
// //     for (final peer in _peers.values.toList()) _sendToPeer(peer, msg);
// //   }

// //   void _sendToPeer(LanPeerInfo peer, LanMessage msg) {
// //     try {
// //       peer.socket?.add(utf8.encode('${msg.toJson()}\n'));
// //     } catch (e) {
// //       AppLogger.warning('LanService: send to ${peer.playerName} failed: $e');
// //       _peers.remove(peer.playerId);
// //       if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
// //     }
// //   }

// //   void _reapStalePeers() {
// //     final stale = _peers.entries
// //         .where(
// //           (e) => DateTime.now().difference(e.value.lastSeen).inSeconds > 30,
// //         )
// //         .map((e) => e.key)
// //         .toList();
// //     for (final id in stale) {
// //       AppLogger.info('LanService: reaping stale peer $id');
// //       _peers.remove(id);
// //       if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(id);
// //     }
// //     if (stale.isNotEmpty && !_peerCtrl.isClosed) _peerCtrl.add(peers);
// //   }

// //   // ── HOST: UDP advertising ──────────────────────────────────────────────────
// //   Future<List<String>> _subnetBroadcasts() async {
// //     final result = <String>[];
// //     try {
// //       final interfaces = await NetworkInterface.list(
// //         type: InternetAddressType.IPv4,
// //         includeLinkLocal: false,
// //       );
// //       for (final iface in interfaces) {
// //         for (final addr in iface.addresses) {
// //           final parts = addr.address.split('.');
// //           if (parts.length == 4)
// //             result.add('\${parts[0]}.\${parts[1]}.\${parts[2]}.255');
// //         }
// //       }
// //     } catch (_) {}
// //     return result;
// //   }

// //   void _startAdvertising(LanRoomDescriptor descriptor) {
// //     _advertisingTimer?.cancel();
// //     _advertisingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
// //       RawDatagramSocket? sock;
// //       try {
// //         sock = await RawDatagramSocket.bind(
// //           InternetAddress.anyIPv4,
// //           0,
// //           reuseAddress: true,
// //           reusePort: false,
// //         );
// //         sock.broadcastEnabled = true;
// //         final bytes = utf8.encode(jsonEncode(descriptor.toJson()));
// //         // 1. Multicast
// //         try {
// //           sock.send(bytes, InternetAddress(_discoveryGroup), _discoveryPort);
// //         } catch (_) {}
// //         // 2. Global broadcast (Android)
// //         try {
// //           sock.send(bytes, InternetAddress('255.255.255.255'), _discoveryPort);
// //         } catch (_) {}
// //         // 3. Subnet broadcast (iOS — global broadcast is blocked)
// //         final subnets = await _subnetBroadcasts();
// //         for (final sb in subnets) {
// //           try {
// //             sock.send(bytes, InternetAddress(sb), _discoveryPort);
// //           } catch (_) {}
// //         }
// //       } catch (e) {
// //         AppLogger.warning('LanService: advertising failed: $e');
// //       } finally {
// //         sock?.close();
// //       }
// //     });
// //   }

// //   // ── CLIENT: discovery ──────────────────────────────────────────────────────
// //   Future<void> startDiscovery() async {
// //     _resetStreams();
// //     // Close any existing listen socket before binding
// //     try {
// //       _listenSocket?.close();
// //     } catch (_) {}
// //     _listenSocket = null;

// //     // Try binding with reusePort, fallback without
// //     for (final reusePort in [true, false]) {
// //       try {
// //         _listenSocket = await RawDatagramSocket.bind(
// //           InternetAddress.anyIPv4,
// //           _discoveryPort,
// //           reuseAddress: true,
// //           reusePort: reusePort,
// //         );
// //         break;
// //       } catch (e) {
// //         AppLogger.warning(
// //           'LanService: bind attempt (reusePort=$reusePort) failed: $e',
// //         );
// //       }
// //     }

// //     if (_listenSocket == null) {
// //       AppLogger.error(
// //         'LanService: could not bind discovery port $_discoveryPort',
// //       );
// //       return;
// //     }

// //     try {
// //       _listenSocket!.joinMulticast(InternetAddress(_discoveryGroup));
// //     } catch (_) {}
// //     try {
// //       _listenSocket!.broadcastEnabled = true;
// //     } catch (_) {}

// //     _listenSocket!.listen((event) {
// //       if (event != RawSocketEvent.read) return;
// //       final dg = _listenSocket?.receive();
// //       if (dg == null || dg.data.length > _maxMessageBytes) return;
// //       try {
// //         final j = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
// //         var room = LanRoomDescriptor.fromJson(j);
// //         room = room.copyWith(hostAddress: dg.address.address);
// //         if (!room.isStale && !_roomCtrl.isClosed) _roomCtrl.add(room);
// //       } catch (_) {}
// //     });
// //     AppLogger.info('LanService: discovery started');
// //   }

// //   // ── CLIENT: connect ────────────────────────────────────────────────────────
// //   Future<void> connectToHost({
// //     required LanRoomDescriptor room,
// //     required String playerId,
// //     required String playerName,
// //   }) async {
// //     _role = LanRole.client;
// //     _hostSocket?.destroy();
// //     _hostSocket = await Socket.connect(
// //       room.hostAddress,
// //       room.port,
// //       timeout: const Duration(seconds: 10),
// //     );

// //     final buf = StringBuffer();
// //     _hostSocket!.listen(
// //       (data) {
// //         buf.write(utf8.decode(data, allowMalformed: true));
// //         final raw = buf.toString();
// //         final lines = raw.split('\n');
// //         for (var i = 0; i < lines.length - 1; i++) {
// //           final line = lines[i].trim();
// //           if (line.isEmpty) continue;
// //           final msg = LanMessage.fromJson(line);
// //           if (msg != null && !_messageCtrl.isClosed) {
// //             AppLogger.info('Client received: ${msg.type}');
// //             _messageCtrl.add(msg);
// //           }
// //         }
// //         buf.clear();
// //         if (lines.isNotEmpty) buf.write(lines.last);
// //       },
// //       onError: (e) {
// //         AppLogger.warning('Client socket error: $e');
// //         if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(playerId);
// //       },
// //       onDone: () {
// //         AppLogger.warning('Client socket closed');
// //         if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(playerId);
// //       },
// //       cancelOnError: false,
// //     );

// //     _hostSocket!.add(
// //       utf8.encode(
// //         '${LanMessage(type: LanMessageType.join, senderId: playerId, payload: {'player_id': playerId, 'player_name': playerName}, ts: _ts()).toJson()}\n',
// //       ),
// //     );

// //     AppLogger.info(
// //       'LanService: connected to ${room.hostAddress}:${room.port} as $playerName',
// //     );
// //   }

// //   // ── CLIENT: send ───────────────────────────────────────────────────────────
// //   void sendAction(LanMessage msg) {
// //     try {
// //       _hostSocket?.add(utf8.encode('${msg.toJson()}\n'));
// //     } catch (e) {
// //       AppLogger.error('LanService: sendAction failed', error: e);
// //     }
// //   }

// //   void sendPong(String sessionId) {
// //     sendAction(
// //       LanMessage(
// //         type: LanMessageType.pong,
// //         senderId: sessionId,
// //         payload: {},
// //         ts: _ts(),
// //       ),
// //     );
// //   }

// //   /// Stop only UDP discovery (client-side). Does not close TCP connection.
// //   void stopDiscovery() {
// //     _listenSocket?.close();
// //     _listenSocket = null;
// //   }

// //   /// Host: forcibly disconnect a peer.
// //   void kickPeer(String playerId) {
// //     final peer = _peers[playerId];
// //     if (peer == null) return;
// //     // Send a kick message so client knows they were removed
// //     _sendToPeer(
// //       peer,
// //       LanMessage(
// //         type: LanMessageType.leave,
// //         senderId: 'host',
// //         payload: {'reason': 'kicked'},
// //         ts: _ts(),
// //       ),
// //     );
// //     Future.delayed(const Duration(milliseconds: 200), () {
// //       try {
// //         peer.socket?.destroy();
// //       } catch (_) {}
// //       _peers.remove(playerId);
// //       if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(playerId);
// //       if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
// //     });
// //   }

// //   // ── Cleanup ────────────────────────────────────────────────────────────────
// //   Future<void> _cleanup() async {
// //     _advertisingTimer?.cancel();
// //     _pingTimer?.cancel();
// //     _advertisingTimer = null;
// //     _pingTimer = null;

// //     _listenSocket?.close();
// //     _listenSocket = null;

// //     for (final p in _peers.values) {
// //       try {
// //         p.socket?.destroy();
// //       } catch (_) {}
// //     }
// //     _peers.clear();

// //     _hostSocket?.destroy();
// //     _hostSocket = null;

// //     try {
// //       await _server?.close();
// //     } catch (_) {}
// //     _server = null;

// //     _descriptor = null;
// //     _role = LanRole.none;
// //   }

// //   Future<void> stop() async {
// //     await _cleanup();
// //     AppLogger.info('LanService: stopped');
// //   }

// //   int _ts() => DateTime.now().millisecondsSinceEpoch;
// // }

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';

// import '../../../core/utils/app_logger.dart';
// import '../domain/offline_session.dart';

// const _discoveryGroup = '239.255.255.250';
// const _discoveryPort = 47889;
// const _dataPort = 47890;
// const _maxMessageBytes = 64 * 1024;

// enum LanRole { host, client, none }

// class LanPeerInfo {
//   LanPeerInfo({
//     required this.playerId,
//     required this.playerName,
//     required this.address,
//     this.socket,
//   });
//   final String playerId;
//   final String playerName;
//   final InternetAddress address;
//   Socket? socket;
//   bool isConnected = true;
//   DateTime lastSeen = DateTime.now();
//   void touch() => lastSeen = DateTime.now();
// }

// class LanService {
//   LanService._();
//   static final LanService _instance = LanService._();
//   static LanService get instance => _instance;

//   LanRole _role = LanRole.none;
//   bool get isHost => _role == LanRole.host;
//   bool get isClient => _role == LanRole.client;
//   bool get isRunning => _role != LanRole.none;

//   ServerSocket? _server;
//   Timer? _advertisingTimer;
//   Timer? _pingTimer;
//   final Map<String, LanPeerInfo> _peers = {};
//   LanRoomDescriptor? _descriptor;

//   Socket? _hostSocket;
//   RawDatagramSocket? _listenSocket;

//   // Fresh stream controllers — recreated on each start
//   StreamController<LanRoomDescriptor> _roomCtrl = StreamController.broadcast();
//   StreamController<LanMessage> _messageCtrl = StreamController.broadcast();
//   StreamController<List<LanPeerInfo>> _peerCtrl = StreamController.broadcast();
//   StreamController<String> _disconnectCtrl = StreamController.broadcast();

//   Stream<LanRoomDescriptor> get roomStream => _roomCtrl.stream;
//   Stream<LanMessage> get messageStream => _messageCtrl.stream;
//   Stream<List<LanPeerInfo>> get peerStream => _peerCtrl.stream;
//   Stream<String> get disconnectStream => _disconnectCtrl.stream;

//   List<LanPeerInfo> get peers => List.unmodifiable(_peers.values);

//   // ── Reset streams (called before each new session) ─────────────────────────
//   void _resetStreams() {
//     if (!_roomCtrl.isClosed) _roomCtrl.close().ignore();
//     if (!_messageCtrl.isClosed) _messageCtrl.close().ignore();
//     if (!_peerCtrl.isClosed) _peerCtrl.close().ignore();
//     if (!_disconnectCtrl.isClosed) _disconnectCtrl.close().ignore();

//     _roomCtrl = StreamController.broadcast();
//     _messageCtrl = StreamController.broadcast();
//     _peerCtrl = StreamController.broadcast();
//     _disconnectCtrl = StreamController.broadcast();
//   }

//   // ── HOST: start ────────────────────────────────────────────────────────────
//   Future<void> startHost({required LanRoomDescriptor descriptor}) async {
//     await _cleanup();
//     _resetStreams();
//     _role = LanRole.host;
//     _descriptor = descriptor;

//     _server = await ServerSocket.bind(
//       InternetAddress.anyIPv4,
//       _dataPort,
//       shared: true,
//     );
//     _server!.listen(
//       _onClientConnected,
//       onError: (e) => AppLogger.error('LanService server error', error: e),
//     );

//     _startAdvertising(descriptor);

//     _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
//       _sendToPeers(
//         LanMessage(
//           type: LanMessageType.ping,
//           senderId: descriptor.sessionId,
//           payload: {},
//           ts: _ts(),
//         ),
//       );
//       _reapStalePeers();
//     });

//     AppLogger.info('LanService: hosting on port $_dataPort');
//   }

//   // ── HOST: broadcast ────────────────────────────────────────────────────────
//   void broadcastGameState(String sessionId, Map<String, dynamic> snapshot) {
//     _sendToPeers(
//       LanMessage(
//         type: LanMessageType.gameState,
//         senderId: sessionId,
//         payload: {'snapshot': snapshot},
//         ts: _ts(),
//       ),
//     );
//   }

//   void broadcastStartGame(String sessionId) {
//     _sendToPeers(
//       LanMessage(
//         type: LanMessageType.startGame,
//         senderId: sessionId,
//         payload: {},
//         ts: _ts(),
//       ),
//     );
//   }

//   void broadcastLobbyUpdate(String sessionId, List<OfflinePlayer> players) {
//     _sendToPeers(
//       LanMessage(
//         type: LanMessageType.lobbyUpdate,
//         senderId: sessionId,
//         payload: {
//           'players': players
//               .map((p) => {'id': p.id, 'name': p.name, 'seat': p.seatOrder})
//               .toList(),
//         },
//         ts: _ts(),
//       ),
//     );
//   }

//   void broadcastMessage(LanMessage msg) => _sendToPeers(msg);

//   void broadcastMessageExcept(LanMessage msg, String excludeId) {
//     for (final peer in _peers.values.toList()) {
//       if (peer.playerId != excludeId) _sendToPeer(peer, msg);
//     }
//   }

//   // ── HOST: internal ─────────────────────────────────────────────────────────
//   void _onClientConnected(Socket socket) {
//     AppLogger.info(
//       'LanService: client connected from ${socket.remoteAddress.address}',
//     );
//     final buf = StringBuffer();

//     socket.listen(
//       (data) {
//         buf.write(utf8.decode(data, allowMalformed: true));
//         final raw = buf.toString();
//         final lines = raw.split('\n');
//         for (var i = 0; i < lines.length - 1; i++) {
//           final line = lines[i].trim();
//           if (line.isEmpty || line.length > _maxMessageBytes) continue;
//           final msg = LanMessage.fromJson(line);
//           if (msg == null) continue;

//           if (msg.type == LanMessageType.join) {
//             final pid = msg.payload['player_id'] as String? ?? '';
//             final name = msg.payload['player_name'] as String? ?? 'Player';
//             final peer = LanPeerInfo(
//               playerId: pid,
//               playerName: name,
//               address: socket.remoteAddress,
//               socket: socket,
//             );
//             _peers[pid] = peer;
//             if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
//             AppLogger.info('LanService: $name ($pid) joined');

//             // Send joinAck immediately
//             _sendToPeer(
//               peer,
//               LanMessage(
//                 type: LanMessageType.joinAck,
//                 senderId: _descriptor?.sessionId ?? '',
//                 payload: _descriptor?.toJson() ?? {},
//                 ts: _ts(),
//               ),
//             );
//           } else if (msg.type == LanMessageType.pong) {
//             _peers[msg.senderId]?.touch();
//           } else {
//             if (!_messageCtrl.isClosed) _messageCtrl.add(msg);
//           }
//         }
//         buf.clear();
//         if (lines.isNotEmpty) buf.write(lines.last);
//       },
//       onError: (_) => _handleDisconnect(socket),
//       onDone: () => _handleDisconnect(socket),
//       cancelOnError: false,
//     );
//   }

//   void _handleDisconnect(Socket socket) {
//     final entry = _peers.entries
//         .where((e) => e.value.socket == socket)
//         .firstOrNull;
//     if (entry != null) {
//       AppLogger.info('LanService: ${entry.value.playerName} disconnected');
//       entry.value.isConnected = false;
//       _peers.remove(entry.key);
//       if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(entry.key);
//       if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
//     }
//     try {
//       socket.destroy();
//     } catch (_) {}
//   }

//   void _sendToPeers(LanMessage msg) {
//     for (final peer in _peers.values.toList()) _sendToPeer(peer, msg);
//   }

//   void _sendToPeer(LanPeerInfo peer, LanMessage msg) {
//     try {
//       peer.socket?.add(utf8.encode('${msg.toJson()}\n'));
//     } catch (e) {
//       AppLogger.warning('LanService: send to ${peer.playerName} failed: $e');
//       _peers.remove(peer.playerId);
//       if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
//     }
//   }

//   void _reapStalePeers() {
//     final stale = _peers.entries
//         .where(
//           (e) => DateTime.now().difference(e.value.lastSeen).inSeconds > 30,
//         )
//         .map((e) => e.key)
//         .toList();
//     for (final id in stale) {
//       AppLogger.info('LanService: reaping stale peer $id');
//       _peers.remove(id);
//       if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(id);
//     }
//     if (stale.isNotEmpty && !_peerCtrl.isClosed) _peerCtrl.add(peers);
//   }

//   // ── HOST: UDP advertising ──────────────────────────────────────────────────
//   Future<List<String>> _subnetBroadcasts() async {
//     final result = <String>[];
//     try {
//       final interfaces = await NetworkInterface.list(
//         type: InternetAddressType.IPv4,
//         includeLinkLocal: false,
//       );
//       for (final iface in interfaces) {
//         for (final addr in iface.addresses) {
//           final parts = addr.address.split('.');
//           if (parts.length == 4)
//             result.add('\${parts[0]}.\${parts[1]}.\${parts[2]}.255');
//         }
//       }
//     } catch (_) {}
//     return result;
//   }

//   /// Get all own IPv4 addresses (for displaying to users as manual fallback)
//   Future<List<String>> getOwnAddresses() async {
//     final result = <String>[];
//     try {
//       final interfaces = await NetworkInterface.list(
//         type: InternetAddressType.IPv4,
//         includeLinkLocal: false,
//       );
//       for (final iface in interfaces)
//         for (final addr in iface.addresses)
//           if (!addr.address.startsWith('127.')) result.add(addr.address);
//     } catch (_) {}
//     return result;
//   }

//   void _startAdvertising(LanRoomDescriptor descriptor) {
//     _advertisingTimer?.cancel();
//     // Advertise every 1s so clients find host quickly
//     _advertisingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
//       RawDatagramSocket? sock;
//       try {
//         sock = await RawDatagramSocket.bind(
//           InternetAddress.anyIPv4,
//           0,
//           reuseAddress: true,
//           reusePort: false,
//         );
//         sock.broadcastEnabled = true;
//         final bytes = utf8.encode(jsonEncode(descriptor.toJson()));
//         // 1. Multicast
//         try {
//           sock.send(bytes, InternetAddress(_discoveryGroup), _discoveryPort);
//         } catch (_) {}
//         // 2. Global broadcast (Android)
//         try {
//           sock.send(bytes, InternetAddress('255.255.255.255'), _discoveryPort);
//         } catch (_) {}
//         // 3. Subnet broadcast (iOS — global broadcast is blocked)
//         final subnets = await _subnetBroadcasts();
//         for (final sb in subnets) {
//           try {
//             sock.send(bytes, InternetAddress(sb), _discoveryPort);
//           } catch (_) {}
//         }
//       } catch (e) {
//         AppLogger.warning('LanService: advertising failed: $e');
//       } finally {
//         sock?.close();
//       }
//     });
//   }

//   // ── CLIENT: discovery ──────────────────────────────────────────────────────
//   Future<void> startDiscovery() async {
//     _resetStreams();
//     // Close any existing listen socket before binding
//     try {
//       _listenSocket?.close();
//     } catch (_) {}
//     _listenSocket = null;

//     // Try binding with reusePort, fallback without
//     for (final reusePort in [true, false]) {
//       try {
//         _listenSocket = await RawDatagramSocket.bind(
//           InternetAddress.anyIPv4,
//           _discoveryPort,
//           reuseAddress: true,
//           reusePort: reusePort,
//         );
//         break;
//       } catch (e) {
//         AppLogger.warning(
//           'LanService: bind attempt (reusePort=$reusePort) failed: $e',
//         );
//       }
//     }

//     if (_listenSocket == null) {
//       AppLogger.error(
//         'LanService: could not bind discovery port $_discoveryPort',
//       );
//       return;
//     }

//     try {
//       _listenSocket!.joinMulticast(InternetAddress(_discoveryGroup));
//     } catch (_) {}
//     try {
//       _listenSocket!.broadcastEnabled = true;
//     } catch (_) {}

//     _listenSocket!.listen((event) {
//       if (event != RawSocketEvent.read) return;
//       final dg = _listenSocket?.receive();
//       if (dg == null || dg.data.length > _maxMessageBytes) return;
//       try {
//         final j = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
//         var room = LanRoomDescriptor.fromJson(j);
//         room = room.copyWith(hostAddress: dg.address.address);
//         if (!room.isStale && !_roomCtrl.isClosed) _roomCtrl.add(room);
//       } catch (_) {}
//     });
//     AppLogger.info('LanService: discovery started');
//   }

//   // ── CLIENT: connect ────────────────────────────────────────────────────────
//   Future<void> connectToHost({
//     required LanRoomDescriptor room,
//     required String playerId,
//     required String playerName,
//   }) async {
//     _role = LanRole.client;
//     _hostSocket?.destroy();
//     _hostSocket = await Socket.connect(
//       room.hostAddress,
//       room.port,
//       timeout: const Duration(seconds: 10),
//     );

//     final buf = StringBuffer();
//     _hostSocket!.listen(
//       (data) {
//         buf.write(utf8.decode(data, allowMalformed: true));
//         final raw = buf.toString();
//         final lines = raw.split('\n');
//         for (var i = 0; i < lines.length - 1; i++) {
//           final line = lines[i].trim();
//           if (line.isEmpty) continue;
//           final msg = LanMessage.fromJson(line);
//           if (msg != null && !_messageCtrl.isClosed) {
//             AppLogger.info('Client received: ${msg.type}');
//             _messageCtrl.add(msg);
//           }
//         }
//         buf.clear();
//         if (lines.isNotEmpty) buf.write(lines.last);
//       },
//       onError: (e) {
//         AppLogger.warning('Client socket error: $e');
//         if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(playerId);
//       },
//       onDone: () {
//         AppLogger.warning('Client socket closed');
//         if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(playerId);
//       },
//       cancelOnError: false,
//     );

//     _hostSocket!.add(
//       utf8.encode(
//         '${LanMessage(type: LanMessageType.join, senderId: playerId, payload: {'player_id': playerId, 'player_name': playerName}, ts: _ts()).toJson()}\n',
//       ),
//     );

//     AppLogger.info(
//       'LanService: connected to ${room.hostAddress}:${room.port} as $playerName',
//     );
//   }

//   // ── CLIENT: send ───────────────────────────────────────────────────────────
//   void sendAction(LanMessage msg) {
//     try {
//       _hostSocket?.add(utf8.encode('${msg.toJson()}\n'));
//     } catch (e) {
//       AppLogger.error('LanService: sendAction failed', error: e);
//     }
//   }

//   void sendPong(String sessionId) {
//     sendAction(
//       LanMessage(
//         type: LanMessageType.pong,
//         senderId: sessionId,
//         payload: {},
//         ts: _ts(),
//       ),
//     );
//   }

//   /// Stop only UDP discovery (client-side). Does not close TCP connection.
//   void stopDiscovery() {
//     _listenSocket?.close();
//     _listenSocket = null;
//   }

//   /// Host: forcibly disconnect a peer.
//   void kickPeer(String playerId) {
//     final peer = _peers[playerId];
//     if (peer == null) return;
//     // Send a kick message so client knows they were removed
//     _sendToPeer(
//       peer,
//       LanMessage(
//         type: LanMessageType.leave,
//         senderId: 'host',
//         payload: {'reason': 'kicked'},
//         ts: _ts(),
//       ),
//     );
//     Future.delayed(const Duration(milliseconds: 200), () {
//       try {
//         peer.socket?.destroy();
//       } catch (_) {}
//       _peers.remove(playerId);
//       if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(playerId);
//       if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
//     });
//   }

//   // ── Cleanup ────────────────────────────────────────────────────────────────
//   Future<void> _cleanup() async {
//     _advertisingTimer?.cancel();
//     _pingTimer?.cancel();
//     _advertisingTimer = null;
//     _pingTimer = null;

//     _listenSocket?.close();
//     _listenSocket = null;

//     for (final p in _peers.values) {
//       try {
//         p.socket?.destroy();
//       } catch (_) {}
//     }
//     _peers.clear();

//     _hostSocket?.destroy();
//     _hostSocket = null;

//     try {
//       await _server?.close();
//     } catch (_) {}
//     _server = null;

//     _descriptor = null;
//     _role = LanRole.none;
//   }

//   Future<void> stop() async {
//     await _cleanup();
//     AppLogger.info('LanService: stopped');
//   }

//   int _ts() => DateTime.now().millisecondsSinceEpoch;
// }

import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';

import '../../../core/utils/app_logger.dart';
import '../domain/offline_session.dart';

const _discoveryGroup = '239.255.255.250';
const _discoveryPort = 47889;
const _dataPort = 47890;
const _maxMessageBytes = 64 * 1024;

enum LanRole { host, client, none }

class LanPeerInfo {
  LanPeerInfo({
    required this.playerId,
    required this.playerName,
    required this.address,
    this.socket,
  });
  final String playerId;
  final String playerName;
  final InternetAddress address;
  Socket? socket;
  bool isConnected = true;
  DateTime lastSeen = DateTime.now();
  void touch() => lastSeen = DateTime.now();
}

class LanService {
  LanService._();
  static final LanService _instance = LanService._();
  static LanService get instance => _instance;

  LanRole _role = LanRole.none;
  bool get isHost => _role == LanRole.host;
  bool get isClient => _role == LanRole.client;
  bool get isRunning => _role != LanRole.none;

  ServerSocket? _server;
  Timer? _advertisingTimer;
  Timer? _pingTimer;
  final Map<String, LanPeerInfo> _peers = {};
  LanRoomDescriptor? _descriptor;

  Socket? _hostSocket;
  RawDatagramSocket? _listenSocket;

  // Fresh stream controllers — recreated on each start
  StreamController<LanRoomDescriptor> _roomCtrl = StreamController.broadcast();
  StreamController<LanMessage> _messageCtrl = StreamController.broadcast();
  StreamController<List<LanPeerInfo>> _peerCtrl = StreamController.broadcast();
  StreamController<String> _disconnectCtrl = StreamController.broadcast();

  Stream<LanRoomDescriptor> get roomStream => _roomCtrl.stream;
  Stream<LanMessage> get messageStream => _messageCtrl.stream;
  Stream<List<LanPeerInfo>> get peerStream => _peerCtrl.stream;
  Stream<String> get disconnectStream => _disconnectCtrl.stream;

  List<LanPeerInfo> get peers => List.unmodifiable(_peers.values);

  // ── Reset streams (called before each new session) ─────────────────────────
  void _resetStreams() {
    if (!_roomCtrl.isClosed) _roomCtrl.close().ignore();
    if (!_messageCtrl.isClosed) _messageCtrl.close().ignore();
    if (!_peerCtrl.isClosed) _peerCtrl.close().ignore();
    if (!_disconnectCtrl.isClosed) _disconnectCtrl.close().ignore();

    _roomCtrl = StreamController.broadcast();
    _messageCtrl = StreamController.broadcast();
    _peerCtrl = StreamController.broadcast();
    _disconnectCtrl = StreamController.broadcast();
  }

  // ── HOST: start ────────────────────────────────────────────────────────────
  Future<void> startHost({required LanRoomDescriptor descriptor}) async {
    await _cleanup();
    _resetStreams();
    _role = LanRole.host;
    _descriptor = descriptor;

    _server = await ServerSocket.bind(
      InternetAddress.anyIPv4,
      _dataPort,
      shared: true,
    );
    _server!.listen(
      _onClientConnected,
      onError: (e) => AppLogger.error('LanService server error', error: e),
    );

    _startAdvertising(descriptor);

    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _sendToPeers(
        LanMessage(
          type: LanMessageType.ping,
          senderId: descriptor.sessionId,
          payload: {},
          ts: _ts(),
        ),
      );
      _reapStalePeers();
    });

    AppLogger.info('LanService: hosting on port $_dataPort');
  }

  // ── HOST: broadcast ────────────────────────────────────────────────────────
  void broadcastGameState(String sessionId, Map<String, dynamic> snapshot) {
    _sendToPeers(
      LanMessage(
        type: LanMessageType.gameState,
        senderId: sessionId,
        payload: {'snapshot': snapshot},
        ts: _ts(),
      ),
    );
  }

  void broadcastStartGame(String sessionId) {
    _sendToPeers(
      LanMessage(
        type: LanMessageType.startGame,
        senderId: sessionId,
        payload: {},
        ts: _ts(),
      ),
    );
  }

  void broadcastLobbyUpdate(String sessionId, List<OfflinePlayer> players) {
    _sendToPeers(
      LanMessage(
        type: LanMessageType.lobbyUpdate,
        senderId: sessionId,
        payload: {
          'players': players
              .map((p) => {'id': p.id, 'name': p.name, 'seat': p.seatOrder})
              .toList(),
        },
        ts: _ts(),
      ),
    );
  }

  void broadcastMessage(LanMessage msg) => _sendToPeers(msg);

  void broadcastMessageExcept(LanMessage msg, String excludeId) {
    for (final peer in _peers.values.toList()) {
      if (peer.playerId != excludeId) _sendToPeer(peer, msg);
    }
  }

  // ── HOST: internal ─────────────────────────────────────────────────────────
  void _onClientConnected(Socket socket) {
    AppLogger.info(
      'LanService: client connected from ${socket.remoteAddress.address}',
    );
    final buf = StringBuffer();

    socket.listen(
      (data) {
        buf.write(utf8.decode(data, allowMalformed: true));
        final raw = buf.toString();
        final lines = raw.split('\n');
        for (var i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isEmpty || line.length > _maxMessageBytes) continue;
          final msg = LanMessage.fromJson(line);
          if (msg == null) continue;

          if (msg.type == LanMessageType.join) {
            final pid = msg.payload['player_id'] as String? ?? '';
            final name = msg.payload['player_name'] as String? ?? 'Player';
            final peer = LanPeerInfo(
              playerId: pid,
              playerName: name,
              address: socket.remoteAddress,
              socket: socket,
            );
            _peers[pid] = peer;
            if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
            AppLogger.info('LanService: $name ($pid) joined');

            // Send joinAck immediately
            _sendToPeer(
              peer,
              LanMessage(
                type: LanMessageType.joinAck,
                senderId: _descriptor?.sessionId ?? '',
                payload: _descriptor?.toJson() ?? {},
                ts: _ts(),
              ),
            );
          } else if (msg.type == LanMessageType.pong) {
            _peers[msg.senderId]?.touch();
          } else {
            if (!_messageCtrl.isClosed) _messageCtrl.add(msg);
          }
        }
        buf.clear();
        if (lines.isNotEmpty) buf.write(lines.last);
      },
      onError: (_) => _handleDisconnect(socket),
      onDone: () => _handleDisconnect(socket),
      cancelOnError: false,
    );
  }

  void _handleDisconnect(Socket socket) {
    final entry = _peers.entries
        .where((e) => e.value.socket == socket)
        .firstOrNull;
    if (entry != null) {
      AppLogger.info('LanService: ${entry.value.playerName} disconnected');
      entry.value.isConnected = false;
      _peers.remove(entry.key);
      if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(entry.key);
      if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
    }
    try {
      socket.destroy();
    } catch (_) {}
  }

  void _sendToPeers(LanMessage msg) {
    for (final peer in _peers.values.toList()) _sendToPeer(peer, msg);
  }

  void _sendToPeer(LanPeerInfo peer, LanMessage msg) {
    try {
      peer.socket?.add(utf8.encode('${msg.toJson()}\n'));
    } catch (e) {
      AppLogger.warning('LanService: send to ${peer.playerName} failed: $e');
      _peers.remove(peer.playerId);
      if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
    }
  }

  void _reapStalePeers() {
    final stale = _peers.entries
        .where(
          (e) => DateTime.now().difference(e.value.lastSeen).inSeconds > 30,
        )
        .map((e) => e.key)
        .toList();
    for (final id in stale) {
      AppLogger.info('LanService: reaping stale peer $id');
      _peers.remove(id);
      if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(id);
    }
    if (stale.isNotEmpty && !_peerCtrl.isClosed) _peerCtrl.add(peers);
  }

  // ── HOST: UDP advertising ──────────────────────────────────────────────────
  Future<List<String>> _subnetBroadcasts() async {
    final result = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final parts = addr.address.split('.');
          if (parts.length == 4)
            result.add('\${parts[0]}.\${parts[1]}.\${parts[2]}.255');
        }
      }
    } catch (_) {}
    return result;
  }

  /// Get all own IPv4 addresses (for displaying to users as manual fallback)
  Future<List<String>> getOwnAddresses() async {
    final result = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces)
        for (final addr in iface.addresses)
          if (!addr.address.startsWith('127.')) result.add(addr.address);
    } catch (_) {}
    return result;
  }

  void _startAdvertising(LanRoomDescriptor descriptor) {
    _advertisingTimer?.cancel();
    // Advertise every 1s so clients find host quickly
    _advertisingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      RawDatagramSocket? sock;
      try {
        sock = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          0,
          reuseAddress: true,
          reusePort: false,
        );
        sock.broadcastEnabled = true;
        final bytes = utf8.encode(jsonEncode(descriptor.toJson()));
        // 1. Multicast
        try {
          sock.send(bytes, InternetAddress(_discoveryGroup), _discoveryPort);
        } catch (_) {}
        // 2. Global broadcast (Android)
        try {
          sock.send(bytes, InternetAddress('255.255.255.255'), _discoveryPort);
        } catch (_) {}
        // 3. Subnet broadcast (iOS — global broadcast is blocked)
        final subnets = await _subnetBroadcasts();
        for (final sb in subnets) {
          try {
            sock.send(bytes, InternetAddress(sb), _discoveryPort);
          } catch (_) {}
        }
        // 4. Also try sending to all /24 addresses near our own IP (iOS unicast scan)
        try {
          final ownAddrs = await getOwnAddresses();
          for (final own in ownAddrs) {
            final parts = own.split('.');
            if (parts.length == 4) {
              // Scan 10 addresses around own IP on the subnet
              final base = int.tryParse(parts[3]) ?? 0;
              for (
                int i = math.max(1, base - 5);
                i <= math.min(254, base + 10);
                i++
              ) {
                if (i == base) continue;
                final target = '${parts[0]}.${parts[1]}.${parts[2]}.$i';
                try {
                  sock.send(bytes, InternetAddress(target), _discoveryPort);
                } catch (_) {}
              }
            }
          }
        } catch (_) {}
      } catch (e) {
        AppLogger.warning('LanService: advertising failed: $e');
      } finally {
        sock?.close();
      }
    });
  }

  // ── CLIENT: discovery ──────────────────────────────────────────────────────
  Future<void> startDiscovery() async {
    _resetStreams();
    // Close any existing listen socket before binding
    try {
      _listenSocket?.close();
    } catch (_) {}
    _listenSocket = null;

    // Try binding with reusePort, fallback without
    for (final reusePort in [true, false]) {
      try {
        _listenSocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          _discoveryPort,
          reuseAddress: true,
          reusePort: reusePort,
        );
        break;
      } catch (e) {
        AppLogger.warning(
          'LanService: bind attempt (reusePort=$reusePort) failed: $e',
        );
      }
    }

    if (_listenSocket == null) {
      AppLogger.error(
        'LanService: could not bind discovery port $_discoveryPort',
      );
      return;
    }

    // Enable broadcast BEFORE joining multicast (iOS requirement)
    try {
      _listenSocket!.broadcastEnabled = true;
    } catch (_) {}
    try {
      _listenSocket!.joinMulticast(InternetAddress(_discoveryGroup));
    } catch (_) {}
    // iOS: also bind on each interface address to receive subnet broadcasts
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          try {
            _listenSocket!.joinMulticast(
              InternetAddress(_discoveryGroup),
              iface,
            );
          } catch (_) {}
        }
      }
    } catch (_) {}

    _listenSocket!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = _listenSocket?.receive();
      if (dg == null || dg.data.length > _maxMessageBytes) return;
      try {
        final j = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
        var room = LanRoomDescriptor.fromJson(j);
        room = room.copyWith(hostAddress: dg.address.address);
        if (!room.isStale && !_roomCtrl.isClosed) _roomCtrl.add(room);
      } catch (_) {}
    });
    AppLogger.info('LanService: discovery started');
  }

  // ── CLIENT: connect ────────────────────────────────────────────────────────
  Future<void> connectToHost({
    required LanRoomDescriptor room,
    required String playerId,
    required String playerName,
  }) async {
    _role = LanRole.client;
    _hostSocket?.destroy();
    _hostSocket = await Socket.connect(
      room.hostAddress,
      room.port,
      timeout: const Duration(seconds: 10),
    );

    final buf = StringBuffer();
    _hostSocket!.listen(
      (data) {
        buf.write(utf8.decode(data, allowMalformed: true));
        final raw = buf.toString();
        final lines = raw.split('\n');
        for (var i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final msg = LanMessage.fromJson(line);
          if (msg != null && !_messageCtrl.isClosed) {
            AppLogger.info('Client received: ${msg.type}');
            _messageCtrl.add(msg);
          }
        }
        buf.clear();
        if (lines.isNotEmpty) buf.write(lines.last);
      },
      onError: (e) {
        AppLogger.warning('Client socket error: $e');
        if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(playerId);
      },
      onDone: () {
        AppLogger.warning('Client socket closed');
        if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(playerId);
      },
      cancelOnError: false,
    );

    _hostSocket!.add(
      utf8.encode(
        '${LanMessage(type: LanMessageType.join, senderId: playerId, payload: {'player_id': playerId, 'player_name': playerName}, ts: _ts()).toJson()}\n',
      ),
    );

    AppLogger.info(
      'LanService: connected to ${room.hostAddress}:${room.port} as $playerName',
    );
  }

  // ── CLIENT: send ───────────────────────────────────────────────────────────
  void sendAction(LanMessage msg) {
    try {
      _hostSocket?.add(utf8.encode('${msg.toJson()}\n'));
    } catch (e) {
      AppLogger.error('LanService: sendAction failed', error: e);
    }
  }

  void sendPong(String sessionId) {
    sendAction(
      LanMessage(
        type: LanMessageType.pong,
        senderId: sessionId,
        payload: {},
        ts: _ts(),
      ),
    );
  }

  /// Stop only UDP discovery (client-side). Does not close TCP connection.
  void stopDiscovery() {
    _listenSocket?.close();
    _listenSocket = null;
  }

  /// Host: forcibly disconnect a peer.
  void kickPeer(String playerId) {
    final peer = _peers[playerId];
    if (peer == null) return;
    // Send a kick message so client knows they were removed
    _sendToPeer(
      peer,
      LanMessage(
        type: LanMessageType.leave,
        senderId: 'host',
        payload: {'reason': 'kicked'},
        ts: _ts(),
      ),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      try {
        peer.socket?.destroy();
      } catch (_) {}
      _peers.remove(playerId);
      if (!_disconnectCtrl.isClosed) _disconnectCtrl.add(playerId);
      if (!_peerCtrl.isClosed) _peerCtrl.add(peers);
    });
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────
  Future<void> _cleanup() async {
    _advertisingTimer?.cancel();
    _pingTimer?.cancel();
    _advertisingTimer = null;
    _pingTimer = null;

    _listenSocket?.close();
    _listenSocket = null;

    for (final p in _peers.values) {
      try {
        p.socket?.destroy();
      } catch (_) {}
    }
    _peers.clear();

    _hostSocket?.destroy();
    _hostSocket = null;

    try {
      await _server?.close();
    } catch (_) {}
    _server = null;

    _descriptor = null;
    _role = LanRole.none;
  }

  Future<void> stop() async {
    await _cleanup();
    AppLogger.info('LanService: stopped');
  }

  int _ts() => DateTime.now().millisecondsSinceEpoch;
}
