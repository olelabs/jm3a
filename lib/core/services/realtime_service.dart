// // // // // import 'dart:async';
// // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // import '../utils/app_logger.dart';

// // // // // abstract final class RoomEvent {
// // // // //   static const gameState = 'game_state';
// // // // //   static const playerAction = 'player_action';
// // // // //   static const syncRequest = 'sync_request';
// // // // //   static const roomEvent = 'room_event';
// // // // //   static const chatMessage = 'chat_message';
// // // // //   static const moderation = 'moderation';
// // // // //   static const settingsChange = 'settings_change';
// // // // //   static const gameStarted = 'game_started';
// // // // //   static const gameEnded = 'game_ended';
// // // // // }

// // // // // abstract final class PresenceKey {
// // // // //   static const userId = 'user_id';
// // // // //   static const displayName = 'display_name';
// // // // //   static const avatarUrl = 'avatar_url';
// // // // //   static const seatOrder = 'seat_order';
// // // // //   static const isReady = 'is_ready';
// // // // //   static const joinedAt = 'joined_at';
// // // // // }

// // // // // typedef BroadcastHandler = void Function(Map<String, dynamic> payload);
// // // // // typedef PresenceHandler = void Function(List<Map<String, dynamic>> presences);
// // // // // typedef StatusHandler = void Function(RealtimeSubscribeStatus status);

// // // // // class _ChannelState {
// // // // //   _ChannelState(this.channel);
// // // // //   final RealtimeChannel channel;
// // // // //   RealtimeSubscribeStatus status = RealtimeSubscribeStatus.subscribed;
// // // // //   final ctrl = StreamController<RealtimeSubscribeStatus>.broadcast();
// // // // // }

// // // // // /// Supabase Realtime service — Broadcast + Presence per room channel.
// // // // // class RealtimeService {
// // // // //   RealtimeService._();
// // // // //   static final RealtimeService _instance = RealtimeService._();
// // // // //   static RealtimeService get instance => _instance;

// // // // //   final _supabase = Supabase.instance.client;
// // // // //   final _channels = <String, _ChannelState>{};

// // // // //   Future<void> subscribe({
// // // // //     required String roomId,
// // // // //     required BroadcastHandler onGameState,
// // // // //     required BroadcastHandler onPlayerAction,
// // // // //     required BroadcastHandler onSyncRequest,
// // // // //     required BroadcastHandler onRoomEvent,
// // // // //     required BroadcastHandler onChatMessage,
// // // // //     required BroadcastHandler onModeration,
// // // // //     required BroadcastHandler onSettingsChange,
// // // // //     required BroadcastHandler onGameStarted,
// // // // //     required BroadcastHandler onGameEnded,
// // // // //     required PresenceHandler onPresenceSync,
// // // // //     required PresenceHandler onPresenceJoin,
// // // // //     required PresenceHandler onPresenceLeave,
// // // // //     required StatusHandler onStatusChange,
// // // // //   }) async {
// // // // //     // if (_channels.containsKey(roomId)) return;

// // // // //     // final channel = _supabase
// // // // //     //     .channel(
// // // // //     //       'room:$roomId',
// // // // //     //       opts: const RealtimeChannelConfig(ack: false, self: false),
// // // // //     //     )
// // // // //     if (_channels.containsKey(roomId)) return;

// // // // //     final channel = _supabase
// // // // //         .channel(
// // // // //           'room:$roomId',
// // // // //           opts: const RealtimeChannelConfig(ack: false, self: false),
// // // // //         )
// // // // //         .onBroadcast(
// // // // //           event: RoomEvent.gameState,
// // // // //           callback: (p) => onGameState(_s(p)),
// // // // //         )
// // // // //         .onBroadcast(
// // // // //           event: RoomEvent.playerAction,
// // // // //           callback: (p) => onPlayerAction(_s(p)),
// // // // //         )
// // // // //         .onBroadcast(
// // // // //           event: RoomEvent.syncRequest,
// // // // //           callback: (p) => onSyncRequest(_s(p)),
// // // // //         )
// // // // //         .onBroadcast(
// // // // //           event: RoomEvent.roomEvent,
// // // // //           callback: (p) => onRoomEvent(_s(p)),
// // // // //         )
// // // // //         .onBroadcast(
// // // // //           event: RoomEvent.chatMessage,
// // // // //           callback: (p) => onChatMessage(_s(p)),
// // // // //         )
// // // // //         .onBroadcast(
// // // // //           event: RoomEvent.moderation,
// // // // //           callback: (p) => onModeration(_s(p)),
// // // // //         )
// // // // //         .onBroadcast(
// // // // //           event: RoomEvent.settingsChange,
// // // // //           callback: (p) => onSettingsChange(_s(p)),
// // // // //         )
// // // // //         .onBroadcast(
// // // // //           event: RoomEvent.gameStarted,
// // // // //           callback: (p) => onGameStarted(_s(p)),
// // // // //         )
// // // // //         .onBroadcast(
// // // // //           event: RoomEvent.gameEnded,
// // // // //           callback: (p) => onGameEnded(_s(p)),
// // // // //         )
// // // // //         //   .onPresenceSync((payload) {
// // // // //         //   // payload is RealtimePresenceSyncPayload
// // // // //         //   final presences = <Map<String, dynamic>>[];
// // // // //         //   for (final entry in payload.presences.entries) {
// // // // //         //     final userId = entry.key;
// // // // //         //     for (final data in entry.value) {
// // // // //         //       if (data is Map) {
// // // // //         //         presences.add({
// // // // //         //           'user_id': userId,
// // // // //         //           ...Map<String, dynamic>.from(data),
// // // // //         //         });
// // // // //         //       }
// // // // //         //     }
// // // // //         //   }
// // // // //         //   onPresenceSync(presences);
// // // // //         // })
// // // // //         // .onPresenceJoin((payload) {
// // // // //         //   // payload is RealtimePresenceJoinPayload
// // // // //         //   final joins = <Map<String, dynamic>>[];
// // // // //         //   for (final entry in payload.joins.entries) {
// // // // //         //     final userId = entry.key;
// // // // //         //     for (final data in entry.value) {
// // // // //         //       if (data is Map) {
// // // // //         //         joins.add({
// // // // //         //           'user_id': userId,
// // // // //         //           ...Map<String, dynamic>.from(data),
// // // // //         //         });
// // // // //         //       }
// // // // //         //     }
// // // // //         //   }
// // // // //         //   if (joins.isNotEmpty) onPresenceJoin(joins);
// // // // //         // })
// // // // //         // .onPresenceLeave((payload) {
// // // // //         //   // payload is RealtimePresenceLeavePayload
// // // // //         //   final leaves = <Map<String, dynamic>>[];
// // // // //         //   for (final entry in payload.leaves.entries) {
// // // // //         //     final userId = entry.key;
// // // // //         //     for (final data in entry.value) {
// // // // //         //       if (data is Map) {
// // // // //         //         leaves.add({
// // // // //         //           'user_id': userId,
// // // // //         //           ...Map<String, dynamic>.from(data),
// // // // //         //         });
// // // // //         //       }
// // // // //         //     }
// // // // //         //   }
// // // // //         //   if (leaves.isNotEmpty) onPresenceLeave(leaves);
// // // // //         // })
// // // // //         // .onPresenceSync((payload) {
// // // // //         //   // Convert to a map using toJson()
// // // // //         //   final map = (payload as dynamic).toJson() as Map<String, dynamic>;
// // // // //         //   final presencesMap = map['presences'] as Map<String, dynamic>? ?? {};
// // // // //         //   final result = <Map<String, dynamic>>[];
// // // // //         //   for (final entry in presencesMap.entries) {
// // // // //         //     final userId = entry.key;
// // // // //         //     final list = entry.value as List? ?? [];
// // // // //         //     for (final item in list) {
// // // // //         //       if (item is Map) {
// // // // //         //         result.add({
// // // // //         //           'user_id': userId,
// // // // //         //           ...Map<String, dynamic>.from(item),
// // // // //         //         });
// // // // //         //       }
// // // // //         //     }
// // // // //         //   }
// // // // //         //   onPresenceSync(result);
// // // // //         // })
// // // // //         // .onPresenceJoin((payload) {
// // // // //         //   final map = (payload as dynamic).toJson() as Map<String, dynamic>;
// // // // //         //   final joinsMap = map['newPresences'] as Map<String, dynamic>? ?? {};
// // // // //         //   final result = <Map<String, dynamic>>[];
// // // // //         //   for (final entry in joinsMap.entries) {
// // // // //         //     final userId = entry.key;
// // // // //         //     final list = entry.value as List? ?? [];
// // // // //         //     for (final item in list) {
// // // // //         //       if (item is Map) {
// // // // //         //         result.add({
// // // // //         //           'user_id': userId,
// // // // //         //           ...Map<String, dynamic>.from(item),
// // // // //         //         });
// // // // //         //       }
// // // // //         //     }
// // // // //         //   }
// // // // //         //   if (result.isNotEmpty) onPresenceJoin(result);
// // // // //         // })
// // // // //         // .onPresenceLeave((payload) {
// // // // //         //   final map = (payload as dynamic).toJson() as Map<String, dynamic>;
// // // // //         //   final leavesMap = map['leftPresences'] as Map<String, dynamic>? ?? {};
// // // // //         //   final result = <Map<String, dynamic>>[];
// // // // //         //   for (final entry in leavesMap.entries) {
// // // // //         //     final userId = entry.key;
// // // // //         //     final list = entry.value as List? ?? [];
// // // // //         //     for (final item in list) {
// // // // //         //       if (item is Map) {
// // // // //         //         result.add({
// // // // //         //           'user_id': userId,
// // // // //         //           ...Map<String, dynamic>.from(item),
// // // // //         //         });
// // // // //         //       }
// // // // //         //     }
// // // // //         //   }
// // // // //         //   if (result.isNotEmpty) onPresenceLeave(result);
// // // // //         // })
// // // // //         // .onPresenceSync((_) => onPresenceSync(_snapshot(roomId)))
// // // // //         .onPresenceSync((_) {
// // // // //           if (_channels[roomId]?.status == RealtimeSubscribeStatus.subscribed) {
// // // // //             onPresenceSync(_snapshot(roomId));
// // // // //           }
// // // // //         })
// // // // //         .onPresenceJoin((_) => onPresenceSync(_snapshot(roomId)))
// // // // //         .onPresenceLeave((_) => onPresenceSync(_snapshot(roomId)))
// // // // //         .subscribe((status, err) {
// // // // //           final st = _channels[roomId];
// // // // //           if (st == null) return;
// // // // //           st.status = status;
// // // // //           st.ctrl.add(status);
// // // // //           onStatusChange(status);
// // // // //           if (err != null)
// // // // //             AppLogger.error('Channel $roomId err', error: err);
// // // // //           else
// // // // //             AppLogger.info('Channel room:$roomId → ${status.name}');
// // // // //         });

// // // // //     _channels[roomId] = _ChannelState(channel);
// // // // //     //     .onPresenceSync((_) => onPresenceSync(_snapshot(roomId)))
// // // // //     //     // .onPresenceJoin(
// // // // //     //     //   (p) {
// // // // //     //     //     final joins = _extract(p['newPresences']);
// // // // //     //     //     if (joins.isNotEmpty) onPresenceJoin(joins);
// // // // //     //     //   },
// // // // //     //     // )
// // // // //     //     // .onPresenceLeave(
// // // // //     //     //   (p) {
// // // // //     //     //     final leaves = _extract(p['leftPresences']);
// // // // //     //     //     if (leaves.isNotEmpty) onPresenceLeave(leaves);
// // // // //     //     //   },
// // // // //     //     // )
// // // // //     //     .onPresenceJoin((payload) {
// // // // //     //       // Convert payload to map by casting
// // // // //     //       final payloadMap = payload as Map<String, dynamic>;
// // // // //     //       final joins = _extract(payloadMap['newPresences']);
// // // // //     //       if (joins.isNotEmpty) onPresenceJoin(joins);
// // // // //     //     })
// // // // //     //     .onPresenceLeave((payload) {
// // // // //     //       final payloadMap = payload as Map<String, dynamic>;
// // // // //     //       final leaves = _extract(payloadMap['leftPresences']);
// // // // //     //       if (leaves.isNotEmpty) onPresenceLeave(leaves);
// // // // //     //     })
// // // // //     //     .subscribe((status, err) {
// // // // //     //       final st = _channels[roomId];
// // // // //     //       if (st == null) return;
// // // // //     //       st.status = status;
// // // // //     //       st.ctrl.add(status);
// // // // //     //       onStatusChange(status);
// // // // //     //       if (err != null)
// // // // //     //         AppLogger.error('Channel $roomId err', error: err);
// // // // //     //       else
// // // // //     //         AppLogger.info('Channel room:$roomId → ${status.name}');
// // // // //     //     });

// // // // //     // _channels[roomId] = _ChannelState(channel);
// // // // //   }

// // // // //   Future<void> trackPresence(String roomId, Map<String, dynamic> data) async {
// // // // //     try {
// // // // //       await _channels[roomId]?.channel.track(data);
// // // // //     } catch (e) {
// // // // //       AppLogger.warning('trackPresence failed, $e');
// // // // //     }
// // // // //   }

// // // // //   Future<void> untrackPresence(String roomId) async {
// // // // //     try {
// // // // //       await _channels[roomId]?.channel.untrack();
// // // // //     } catch (e) {
// // // // //       AppLogger.warning('untrackPresence failed, $e');
// // // // //     }
// // // // //   }

// // // // //   List<Map<String, dynamic>> presenceSnapshot(String roomId) =>
// // // // //       _snapshot(roomId);

// // // // //   Future<void> broadcastGameState(
// // // // //     String roomId,
// // // // //     Map<String, dynamic> snapshot,
// // // // //     String senderId,
// // // // //   ) => _bcast(roomId, RoomEvent.gameState, {
// // // // //     'sender_id': senderId,
// // // // //     'snapshot': snapshot,
// // // // //     'ts': _ts(),
// // // // //   });

// // // // //   Future<void> broadcastPlayerAction(
// // // // //     String roomId,
// // // // //     Map<String, dynamic> action,
// // // // //   ) => _bcast(roomId, RoomEvent.playerAction, {...action, 'ts': _ts()});

// // // // //   Future<void> broadcastSyncRequest(
// // // // //     String roomId,
// // // // //     String requesterId,
// // // // //     int lastKnownRound,
// // // // //   ) => _bcast(roomId, RoomEvent.syncRequest, {
// // // // //     'requester_id': requesterId,
// // // // //     'last_known_round': lastKnownRound,
// // // // //     'ts': _ts(),
// // // // //   });

// // // // //   Future<void> broadcastRoomEvent(String roomId, Map<String, dynamic> event) =>
// // // // //       _bcast(roomId, RoomEvent.roomEvent, {...event, 'ts': _ts()});

// // // // //   Future<void> broadcastChat(String roomId, Map<String, dynamic> message) =>
// // // // //       _bcast(roomId, RoomEvent.chatMessage, {...message, 'ts': _ts()});

// // // // //   Future<void> broadcastModeration(
// // // // //     String roomId,
// // // // //     Map<String, dynamic> action,
// // // // //   ) => _bcast(roomId, RoomEvent.moderation, {...action, 'ts': _ts()});

// // // // //   Future<void> broadcastSettingsChange(
// // // // //     String roomId,
// // // // //     String field,
// // // // //     dynamic value,
// // // // //   ) => _bcast(roomId, RoomEvent.settingsChange, {
// // // // //     'field': field,
// // // // //     'new_value': value,
// // // // //     'ts': _ts(),
// // // // //   });

// // // // //   Future<void> broadcastGameStarted(
// // // // //     String roomId,
// // // // //     Map<String, dynamic> config,
// // // // //   ) => _bcast(roomId, RoomEvent.gameStarted, {...config, 'ts': _ts()});

// // // // //   Future<void> broadcastGameEnded(
// // // // //     String roomId,
// // // // //     Map<String, dynamic> results,
// // // // //   ) => _bcast(roomId, RoomEvent.gameEnded, {...results, 'ts': _ts()});

// // // // //   Future<void> unsubscribe(String roomId) async {
// // // // //     final st = _channels.remove(roomId);
// // // // //     if (st != null) {
// // // // //       await st.channel.unsubscribe();
// // // // //       await st.ctrl.close();
// // // // //       AppLogger.info('RealtimeService: unsubscribed $roomId');
// // // // //     }
// // // // //   }

// // // // //   Future<void> unsubscribeAll() async {
// // // // //     for (final id in List.of(_channels.keys)) await unsubscribe(id);
// // // // //   }

// // // // //   bool isSubscribed(String roomId) => _channels.containsKey(roomId);
// // // // //   RealtimeSubscribeStatus? statusOf(String roomId) => _channels[roomId]?.status;
// // // // //   Stream<RealtimeSubscribeStatus>? statusStream(String roomId) =>
// // // // //       _channels[roomId]?.ctrl.stream;

// // // // //   Future<void> _bcast(
// // // // //     String roomId,
// // // // //     String event,
// // // // //     Map<String, dynamic> payload,
// // // // //   ) async {
// // // // //     final ch = _channels[roomId]?.channel;
// // // // //     if (ch == null) {
// // // // //       AppLogger.warning('No channel $roomId — drop $event');
// // // // //       return;
// // // // //     }
// // // // //     try {
// // // // //       await ch.sendBroadcastMessage(event: event, payload: payload);
// // // // //     } catch (e) {
// // // // //       AppLogger.error('Broadcast $event failed', error: e);
// // // // //     }
// // // // //   }

// // // // //   // List<Map<String, dynamic>> _snapshot(String roomId) {
// // // // //   //   final ch = _channels[roomId]?.channel;
// // // // //   //   if (ch == null) return [];
// // // // //   //   return ch.presenceState().entries.expand(
// // // // //   //     (e) => e.value.whereType<Map<String, dynamic>>()).toList();
// // // // //   // }

// // // // //   // List<Map<String, dynamic>> _snapshot(String roomId) {
// // // // //   //   final ch = _channels[roomId]?.channel;
// // // // //   //   if (ch == null) return [];
// // // // //   //   final raw = ch.presenceState();
// // // // //   //   final stateMap = raw is Map ? raw : <String, dynamic>{};
// // // // //   //   final result = <Map<String, dynamic>>[];
// // // // //   //   for (final entry in stateMap.entries) {
// // // // //   //     final presences = entry.value;
// // // // //   //     if (presences is List) {
// // // // //   //       for (final p in presences) {
// // // // //   //         if (p is Map<String, dynamic>) result.add(p);
// // // // //   //       }
// // // // //   //     }
// // // // //   //   }
// // // // //   //   return result;
// // // // //   // }
// // // // //   // In RealtimeService.dart - replace the _snapshot method with this:

// // // // //   List<Map<String, dynamic>> _snapshot(String roomId) {
// // // // //     final ch = _channels[roomId]?.channel;
// // // // //     if (ch == null) return [];

// // // // //     try {
// // // // //       final rawState = ch.presenceState();
// // // // //       if (rawState == null) return [];

// // // // //       // Handle the presence state similar to PresenceService
// // // // //       final stateMap = rawState is Map
// // // // //           ? Map<String, dynamic>.from(rawState as Map<dynamic, dynamic>)
// // // // //           : <String, dynamic>{};

// // // // //       final result = <Map<String, dynamic>>[];

// // // // //       for (final entry in stateMap.entries) {
// // // // //         final presences = entry.value;
// // // // //         final list = presences is List ? presences : [presences];

// // // // //         for (final item in list) {
// // // // //           if (item is Map && item.isNotEmpty) {
// // // // //             result.add(Map<String, dynamic>.from(item));
// // // // //           }
// // // // //         }
// // // // //       }

// // // // //       return result;
// // // // //     } catch (e) {
// // // // //       AppLogger.warning('Failed to get presence snapshot: $e');
// // // // //       return [];
// // // // //     }
// // // // //   }

// // // // //   // Also update the _extract method to be consistent:
// // // // //   // List<Map<String, dynamic>> _extract(dynamic raw) {
// // // // //   //   if (raw is List) {
// // // // //   //     return raw.whereType<Map<String, dynamic>>().toList();
// // // // //   //   }
// // // // //   //   if (raw is Map) {
// // // // //   //     // Handle case where raw is a single map
// // // // //   //     return [Map<String, dynamic>.from(raw)];
// // // // //   //   }
// // // // //   //   return [];
// // // // //   // }

// // // // //   List<Map<String, dynamic>> _extract(dynamic raw) =>
// // // // //       raw is List ? raw.whereType<Map<String, dynamic>>().toList() : [];

// // // // //   Map<String, dynamic> _s(dynamic p) => p is Map<String, dynamic> ? p : {};
// // // // //   int _ts() => DateTime.now().millisecondsSinceEpoch;
// // // // // }

// // // // import 'dart:async';
// // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // import '../utils/app_logger.dart';

// // // // abstract final class RoomEvent {
// // // //   static const gameState = 'game_state';
// // // //   static const playerAction = 'player_action';
// // // //   static const syncRequest = 'sync_request';
// // // //   static const roomEvent = 'room_event';
// // // //   static const chatMessage = 'chat_message';
// // // //   static const moderation = 'moderation';
// // // //   static const settingsChange = 'settings_change';
// // // //   static const gameStarted = 'game_started';
// // // //   static const gameEnded = 'game_ended';
// // // // }

// // // // abstract final class PresenceKey {
// // // //   static const userId = 'user_id';
// // // //   static const displayName = 'display_name';
// // // //   static const avatarUrl = 'avatar_url';
// // // //   static const seatOrder = 'seat_order';
// // // //   static const isReady = 'is_ready';
// // // //   static const joinedAt = 'joined_at';
// // // // }

// // // // typedef BroadcastHandler = void Function(Map<String, dynamic> payload);
// // // // typedef PresenceHandler = void Function(List<Map<String, dynamic>> presences);
// // // // typedef StatusHandler = void Function(RealtimeSubscribeStatus status);

// // // // class _ChannelState {
// // // //   _ChannelState(this.channel);
// // // //   final RealtimeChannel channel;
// // // //   RealtimeSubscribeStatus status = RealtimeSubscribeStatus.subscribed;
// // // //   final ctrl = StreamController<RealtimeSubscribeStatus>.broadcast();
// // // // }

// // // // /// Supabase Realtime service — Broadcast + Presence per room channel.
// // // // class RealtimeService {
// // // //   RealtimeService._();
// // // //   static final RealtimeService _instance = RealtimeService._();
// // // //   static RealtimeService get instance => _instance;

// // // //   final _supabase = Supabase.instance.client;
// // // //   final _channels = <String, _ChannelState>{};

// // // //   Future<void> subscribe({
// // // //     required String roomId,
// // // //     required BroadcastHandler onGameState,
// // // //     required BroadcastHandler onPlayerAction,
// // // //     required BroadcastHandler onSyncRequest,
// // // //     required BroadcastHandler onRoomEvent,
// // // //     required BroadcastHandler onChatMessage,
// // // //     required BroadcastHandler onModeration,
// // // //     required BroadcastHandler onSettingsChange,
// // // //     required BroadcastHandler onGameStarted,
// // // //     required BroadcastHandler onGameEnded,
// // // //     required PresenceHandler onPresenceSync,
// // // //     required PresenceHandler onPresenceJoin,
// // // //     required PresenceHandler onPresenceLeave,
// // // //     required StatusHandler onStatusChange,
// // // //   }) async {
// // // //     if (_channels.containsKey(roomId)) return;

// // // //     final channel = _supabase
// // // //         .channel(
// // // //           'room:$roomId',
// // // //           opts: const RealtimeChannelConfig(ack: false, self: false),
// // // //         )
// // // //         .onBroadcast(
// // // //           event: RoomEvent.gameState,
// // // //           callback: (p) => onGameState(_s(p)),
// // // //         )
// // // //         .onBroadcast(
// // // //           event: RoomEvent.playerAction,
// // // //           callback: (p) => onPlayerAction(_s(p)),
// // // //         )
// // // //         .onBroadcast(
// // // //           event: RoomEvent.syncRequest,
// // // //           callback: (p) => onSyncRequest(_s(p)),
// // // //         )
// // // //         .onBroadcast(
// // // //           event: RoomEvent.roomEvent,
// // // //           callback: (p) => onRoomEvent(_s(p)),
// // // //         )
// // // //         .onBroadcast(
// // // //           event: RoomEvent.chatMessage,
// // // //           callback: (p) => onChatMessage(_s(p)),
// // // //         )
// // // //         .onBroadcast(
// // // //           event: RoomEvent.moderation,
// // // //           callback: (p) => onModeration(_s(p)),
// // // //         )
// // // //         .onBroadcast(
// // // //           event: RoomEvent.settingsChange,
// // // //           callback: (p) => onSettingsChange(_s(p)),
// // // //         )
// // // //         .onBroadcast(
// // // //           event: RoomEvent.gameStarted,
// // // //           callback: (p) => onGameStarted(_s(p)),
// // // //         )
// // // //         .onBroadcast(
// // // //           event: RoomEvent.gameEnded,
// // // //           callback: (p) => onGameEnded(_s(p)),
// // // //         )
// // // //         .onPresenceSync((_) => onPresenceSync(_snapshot(roomId)))
// // // //         .onPresenceJoin((_) => onPresenceSync(_snapshot(roomId)))
// // // //         .onPresenceLeave((_) => onPresenceSync(_snapshot(roomId)))
// // // //         .subscribe((status, err) {
// // // //           final st = _channels[roomId];
// // // //           if (st == null) return;
// // // //           st.status = status;
// // // //           st.ctrl.add(status);
// // // //           onStatusChange(status);
// // // //           if (err != null) {
// // // //             AppLogger.error('Channel $roomId err', error: err);
// // // //           } else {
// // // //             AppLogger.info('Channel room:$roomId → ${status.name}');
// // // //           }
// // // //         });

// // // //     _channels[roomId] = _ChannelState(channel);
// // // //   }

// // // //   Future<void> trackPresence(String roomId, Map<String, dynamic> data) async {
// // // //     try {
// // // //       await _channels[roomId]?.channel.track(data);
// // // //     } catch (e) {
// // // //       AppLogger.warning('trackPresence failed, $e');
// // // //     }
// // // //   }

// // // //   Future<void> untrackPresence(String roomId) async {
// // // //     try {
// // // //       await _channels[roomId]?.channel.untrack();
// // // //     } catch (e) {
// // // //       AppLogger.warning('untrackPresence failed, $e');
// // // //     }
// // // //   }

// // // //   List<Map<String, dynamic>> presenceSnapshot(String roomId) =>
// // // //       _snapshot(roomId);

// // // //   Future<void> broadcastGameState(
// // // //     String roomId,
// // // //     Map<String, dynamic> snapshot,
// // // //     String senderId,
// // // //   ) => _bcast(roomId, RoomEvent.gameState, {
// // // //     'sender_id': senderId,
// // // //     'snapshot': snapshot,
// // // //     'ts': _ts(),
// // // //   });

// // // //   Future<void> broadcastPlayerAction(
// // // //     String roomId,
// // // //     Map<String, dynamic> action,
// // // //   ) => _bcast(roomId, RoomEvent.playerAction, {...action, 'ts': _ts()});

// // // //   Future<void> broadcastSyncRequest(
// // // //     String roomId,
// // // //     String requesterId,
// // // //     int lastKnownRound,
// // // //   ) => _bcast(roomId, RoomEvent.syncRequest, {
// // // //     'requester_id': requesterId,
// // // //     'last_known_round': lastKnownRound,
// // // //     'ts': _ts(),
// // // //   });

// // // //   Future<void> broadcastRoomEvent(String roomId, Map<String, dynamic> event) =>
// // // //       _bcast(roomId, RoomEvent.roomEvent, {...event, 'ts': _ts()});

// // // //   Future<void> broadcastChat(String roomId, Map<String, dynamic> message) =>
// // // //       _bcast(roomId, RoomEvent.chatMessage, {...message, 'ts': _ts()});

// // // //   Future<void> broadcastModeration(
// // // //     String roomId,
// // // //     Map<String, dynamic> action,
// // // //   ) => _bcast(roomId, RoomEvent.moderation, {...action, 'ts': _ts()});

// // // //   Future<void> broadcastSettingsChange(
// // // //     String roomId,
// // // //     String field,
// // // //     dynamic value,
// // // //   ) => _bcast(roomId, RoomEvent.settingsChange, {
// // // //     'field': field,
// // // //     'new_value': value,
// // // //     'ts': _ts(),
// // // //   });

// // // //   Future<void> broadcastGameStarted(
// // // //     String roomId,
// // // //     Map<String, dynamic> config,
// // // //   ) => _bcast(roomId, RoomEvent.gameStarted, {...config, 'ts': _ts()});

// // // //   Future<void> broadcastGameEnded(
// // // //     String roomId,
// // // //     Map<String, dynamic> results,
// // // //   ) => _bcast(roomId, RoomEvent.gameEnded, {...results, 'ts': _ts()});

// // // //   Future<void> unsubscribe(String roomId) async {
// // // //     final st = _channels.remove(roomId);
// // // //     if (st != null) {
// // // //       await st.channel.unsubscribe();
// // // //       await st.ctrl.close();
// // // //       AppLogger.info('RealtimeService: unsubscribed $roomId');
// // // //     }
// // // //   }

// // // //   Future<void> unsubscribeAll() async {
// // // //     for (final id in List.of(_channels.keys)) await unsubscribe(id);
// // // //   }

// // // //   bool isSubscribed(String roomId) => _channels.containsKey(roomId);
// // // //   RealtimeSubscribeStatus? statusOf(String roomId) => _channels[roomId]?.status;
// // // //   Stream<RealtimeSubscribeStatus>? statusStream(String roomId) =>
// // // //       _channels[roomId]?.ctrl.stream;

// // // //   // ── Internals ─────────────────────────────────────────────────────────────

// // // //   Future<void> _bcast(
// // // //     String roomId,
// // // //     String event,
// // // //     Map<String, dynamic> payload,
// // // //   ) async {
// // // //     final ch = _channels[roomId]?.channel;
// // // //     if (ch == null) {
// // // //       AppLogger.warning('No channel $roomId — drop $event');
// // // //       return;
// // // //     }
// // // //     try {
// // // //       await ch.sendBroadcastMessage(event: event, payload: payload);
// // // //     } catch (e) {
// // // //       AppLogger.error('Broadcast $event failed', error: e);
// // // //     }
// // // //   }

// // // //   List<Map<String, dynamic>> _snapshot(String roomId) {
// // // //     final ch = _channels[roomId]?.channel;
// // // //     if (ch == null) return [];
// // // //     try {
// // // //       final raw = ch.presenceState();
// // // //       if (raw == null) return [];
// // // //       final stateMap = raw is Map
// // // //           ? Map<String, dynamic>.from(raw as Map)
// // // //           : <String, dynamic>{};
// // // //       final result = <Map<String, dynamic>>[];
// // // //       for (final entry in stateMap.entries) {
// // // //         final list = entry.value is List ? entry.value as List : [entry.value];
// // // //         for (final item in list) {
// // // //           if (item is Map && item.isNotEmpty) {
// // // //             result.add(Map<String, dynamic>.from(item));
// // // //           }
// // // //         }
// // // //       }
// // // //       return result;
// // // //     } catch (e) {
// // // //       AppLogger.warning('presenceState failed: $e');
// // // //       return [];
// // // //     }
// // // //   }

// // // //   Map<String, dynamic> _s(dynamic p) => p is Map<String, dynamic> ? p : {};
// // // //   int _ts() => DateTime.now().millisecondsSinceEpoch;
// // // // }

// // // import 'dart:async';
// // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // import '../utils/app_logger.dart';

// // // abstract final class RoomEvent {
// // //   static const gameState = 'game_state';
// // //   static const playerAction = 'player_action';
// // //   static const syncRequest = 'sync_request';
// // //   static const roomEvent = 'room_event';
// // //   static const chatMessage = 'chat_message';
// // //   static const moderation = 'moderation';
// // //   static const settingsChange = 'settings_change';
// // //   static const gameStarted = 'game_started';
// // //   static const gameEnded = 'game_ended';
// // // }

// // // abstract final class PresenceKey {
// // //   static const userId = 'user_id';
// // //   static const displayName = 'display_name';
// // //   static const avatarUrl = 'avatar_url';
// // //   static const seatOrder = 'seat_order';
// // //   static const isReady = 'is_ready';
// // //   static const joinedAt = 'joined_at';
// // // }

// // // typedef BroadcastHandler = void Function(Map<String, dynamic> payload);
// // // typedef PresenceHandler = void Function(List<Map<String, dynamic>> presences);
// // // typedef StatusHandler = void Function(RealtimeSubscribeStatus status);

// // // class _ChannelState {
// // //   _ChannelState(this.channel);
// // //   final RealtimeChannel channel;
// // //   RealtimeSubscribeStatus status = RealtimeSubscribeStatus.subscribed;
// // //   final ctrl = StreamController<RealtimeSubscribeStatus>.broadcast();
// // //   // Own presence map: userId → tracked payload (the data we pass to track())
// // //   final presences = <String, Map<String, dynamic>>{};
// // // }

// // // /// Supabase Realtime service — Broadcast + Presence per room channel.
// // // class RealtimeService {
// // //   RealtimeService._();
// // //   static final RealtimeService _instance = RealtimeService._();
// // //   static RealtimeService get instance => _instance;

// // //   final _supabase = Supabase.instance.client;
// // //   final _channels = <String, _ChannelState>{};

// // //   Future<void> subscribe({
// // //     required String roomId,
// // //     required BroadcastHandler onGameState,
// // //     required BroadcastHandler onPlayerAction,
// // //     required BroadcastHandler onSyncRequest,
// // //     required BroadcastHandler onRoomEvent,
// // //     required BroadcastHandler onChatMessage,
// // //     required BroadcastHandler onModeration,
// // //     required BroadcastHandler onSettingsChange,
// // //     required BroadcastHandler onGameStarted,
// // //     required BroadcastHandler onGameEnded,
// // //     required PresenceHandler onPresenceSync,
// // //     required PresenceHandler onPresenceJoin,
// // //     required PresenceHandler onPresenceLeave,
// // //     required StatusHandler onStatusChange,
// // //   }) async {
// // //     if (_channels.containsKey(roomId)) return;

// // //     final state = _ChannelState(
// // //       _supabase.channel(
// // //         'room:$roomId',
// // //         opts: const RealtimeChannelConfig(ack: false, self: false),
// // //       ),
// // //     );

// // //     state.channel
// // //         .onBroadcast(
// // //           event: RoomEvent.gameState,
// // //           callback: (p) => onGameState(_s(p)),
// // //         )
// // //         .onBroadcast(
// // //           event: RoomEvent.playerAction,
// // //           callback: (p) => onPlayerAction(_s(p)),
// // //         )
// // //         .onBroadcast(
// // //           event: RoomEvent.syncRequest,
// // //           callback: (p) => onSyncRequest(_s(p)),
// // //         )
// // //         .onBroadcast(
// // //           event: RoomEvent.roomEvent,
// // //           callback: (p) => onRoomEvent(_s(p)),
// // //         )
// // //         .onBroadcast(
// // //           event: RoomEvent.chatMessage,
// // //           callback: (p) => onChatMessage(_s(p)),
// // //         )
// // //         .onBroadcast(
// // //           event: RoomEvent.moderation,
// // //           callback: (p) => onModeration(_s(p)),
// // //         )
// // //         .onBroadcast(
// // //           event: RoomEvent.settingsChange,
// // //           callback: (p) => onSettingsChange(_s(p)),
// // //         )
// // //         .onBroadcast(
// // //           event: RoomEvent.gameStarted,
// // //           callback: (p) => onGameStarted(_s(p)),
// // //         )
// // //         .onBroadcast(
// // //           event: RoomEvent.gameEnded,
// // //           callback: (p) => onGameEnded(_s(p)),
// // //         )
// // //         .onPresenceSync((_) {
// // //           print('=== PRESENCE SYNC fired ===');
// // //           // Full snapshot — rebuild from raw presenceState map
// // //           _rebuildPresences(roomId, state);
// // //           AppLogger.debug(
// // //             'PresenceSync: \${state.presences.length} online in \$roomId',
// // //           );
// // //           print(
// // //             '=== PRESENCE SYNC: ${state.presences.length} users: ${state.presences.keys.toList()}',
// // //           );
// // //           onPresenceSync(state.presences.values.toList());
// // //         })
// // //         .onPresenceJoin((payload) {
// // //           print(
// // //             '=== PRESENCE JOIN fired, newPresences count: ${payload.newPresences.length}',
// // //           );
// // //           // payload.newPresences is List<Presence> — each has .payload Map
// // //           final joined = _extractPresences(payload.newPresences);
// // //           for (final p in joined) {
// // //             final uid = p[PresenceKey.userId] as String?;
// // //             if (uid != null) state.presences[uid] = p;
// // //           }
// // //           AppLogger.debug(
// // //             'PresenceJoin: \${joined.length} joined, total=\${state.presences.length}',
// // //           );
// // //           print(
// // //             '=== JOIN extracted: ${joined.map((p) => p["user_id"]).toList()}',
// // //           );
// // //           onPresenceSync(state.presences.values.toList());
// // //         })
// // //         .onPresenceLeave((payload) {
// // //           final left = _extractPresences(payload.leftPresences);
// // //           for (final p in left) {
// // //             final uid = p[PresenceKey.userId] as String?;
// // //             if (uid != null) state.presences.remove(uid);
// // //           }
// // //           AppLogger.debug(
// // //             'PresenceLeave: ${left.length} left, total=${state.presences.length}',
// // //           );
// // //           onPresenceSync(state.presences.values.toList());
// // //         })
// // //         .subscribe((status, err) {
// // //           final st = _channels[roomId];
// // //           if (st == null) return;
// // //           st.status = status;
// // //           st.ctrl.add(status);
// // //           onStatusChange(status);
// // //           if (err != null) {
// // //             AppLogger.error('Channel $roomId err', error: err);
// // //           } else {
// // //             AppLogger.info('Channel room:$roomId → ${status.name}');
// // //           }
// // //         });

// // //     _channels[roomId] = state;
// // //   }

// // //   Future<void> trackPresence(String roomId, Map<String, dynamic> data) async {
// // //     try {
// // //       await _channels[roomId]?.channel.track(data);
// // //       // Also store locally so our own presence is in the snapshot
// // //       final uid = data[PresenceKey.userId] as String?;
// // //       if (uid != null) _channels[roomId]?.presences[uid] = data;
// // //     } catch (e) {
// // //       AppLogger.warning('trackPresence failed: $e');
// // //     }
// // //   }

// // //   Future<void> untrackPresence(String roomId) async {
// // //     try {
// // //       await _channels[roomId]?.channel.untrack();
// // //     } catch (e) {
// // //       AppLogger.warning('untrackPresence failed: $e');
// // //     }
// // //   }

// // //   List<Map<String, dynamic>> presenceSnapshot(String roomId) =>
// // //       _channels[roomId]?.presences.values.toList() ?? [];

// // //   Future<void> broadcastGameState(
// // //     String roomId,
// // //     Map<String, dynamic> snapshot,
// // //     String senderId,
// // //   ) => _bcast(roomId, RoomEvent.gameState, {
// // //     'sender_id': senderId,
// // //     'snapshot': snapshot,
// // //     'ts': _ts(),
// // //   });

// // //   Future<void> broadcastPlayerAction(
// // //     String roomId,
// // //     Map<String, dynamic> action,
// // //   ) => _bcast(roomId, RoomEvent.playerAction, {...action, 'ts': _ts()});

// // //   Future<void> broadcastSyncRequest(
// // //     String roomId,
// // //     String requesterId,
// // //     int lastKnownRound,
// // //   ) => _bcast(roomId, RoomEvent.syncRequest, {
// // //     'requester_id': requesterId,
// // //     'last_known_round': lastKnownRound,
// // //     'ts': _ts(),
// // //   });

// // //   Future<void> broadcastRoomEvent(String roomId, Map<String, dynamic> event) =>
// // //       _bcast(roomId, RoomEvent.roomEvent, {...event, 'ts': _ts()});

// // //   Future<void> broadcastChat(String roomId, Map<String, dynamic> message) =>
// // //       _bcast(roomId, RoomEvent.chatMessage, {...message, 'ts': _ts()});

// // //   Future<void> broadcastModeration(
// // //     String roomId,
// // //     Map<String, dynamic> action,
// // //   ) => _bcast(roomId, RoomEvent.moderation, {...action, 'ts': _ts()});

// // //   Future<void> broadcastSettingsChange(
// // //     String roomId,
// // //     String field,
// // //     dynamic value,
// // //   ) => _bcast(roomId, RoomEvent.settingsChange, {
// // //     'field': field,
// // //     'new_value': value,
// // //     'ts': _ts(),
// // //   });

// // //   Future<void> broadcastGameStarted(
// // //     String roomId,
// // //     Map<String, dynamic> config,
// // //   ) => _bcast(roomId, RoomEvent.gameStarted, {...config, 'ts': _ts()});

// // //   Future<void> broadcastGameEnded(
// // //     String roomId,
// // //     Map<String, dynamic> results,
// // //   ) => _bcast(roomId, RoomEvent.gameEnded, {...results, 'ts': _ts()});

// // //   Future<void> unsubscribe(String roomId) async {
// // //     final st = _channels.remove(roomId);
// // //     if (st != null) {
// // //       await st.channel.unsubscribe();
// // //       await st.ctrl.close();
// // //       AppLogger.info('RealtimeService: unsubscribed $roomId');
// // //     }
// // //   }

// // //   Future<void> unsubscribeAll() async {
// // //     for (final id in List.of(_channels.keys)) await unsubscribe(id);
// // //   }

// // //   bool isSubscribed(String roomId) => _channels.containsKey(roomId);
// // //   RealtimeSubscribeStatus? statusOf(String roomId) => _channels[roomId]?.status;
// // //   Stream<RealtimeSubscribeStatus>? statusStream(String roomId) =>
// // //       _channels[roomId]?.ctrl.stream;

// // //   // ── Internals ─────────────────────────────────────────────────────────────

// // //   Future<void> _bcast(
// // //     String roomId,
// // //     String event,
// // //     Map<String, dynamic> payload,
// // //   ) async {
// // //     final ch = _channels[roomId]?.channel;
// // //     if (ch == null) {
// // //       AppLogger.warning('No channel $roomId — drop $event');
// // //       return;
// // //     }
// // //     try {
// // //       await ch.sendBroadcastMessage(event: event, payload: payload);
// // //     } catch (e) {
// // //       AppLogger.error('Broadcast $event failed', error: e);
// // //     }
// // //   }

// // //   /// Extract payloads from a typed List<Presence> (supabase_flutter v2).
// // //   /// Each Presence has a .payload property that is Map<String, dynamic>.
// // //   List<Map<String, dynamic>> _extractPresences(List<dynamic> presences) {
// // //     final result = <Map<String, dynamic>>[];
// // //     for (final p in presences) {
// // //       try {
// // //         // Try accessing .payload (typed Presence object)
// // //         final payload = (p as dynamic).payload;
// // //         if (payload is Map) {
// // //           result.add(Map<String, dynamic>.from(payload));
// // //         }
// // //       } catch (_) {
// // //         // Fallback: p itself might be the map
// // //         if (p is Map) result.add(Map<String, dynamic>.from(p));
// // //       }
// // //     }
// // //     return result;
// // //   }

// // //   /// Rebuild presence map from presenceState() — used on full sync.
// // //   void _rebuildPresences(String roomId, _ChannelState state) {
// // //     try {
// // //       final raw = state.channel.presenceState();
// // //       // presenceState() returns Map<String, List<Presence>>
// // //       // key = presence key (auto), value = list of Presence objects
// // //       if (raw is! Map) return;
// // //       final newPresences = <String, Map<String, dynamic>>{};
// // //       for (final entry in (raw as Map).entries) {
// // //         final list = entry.value is List ? entry.value as List : [entry.value];
// // //         for (final item in list) {
// // //           Map<String, dynamic>? payload;
// // //           try {
// // //             final p = (item as dynamic).payload;
// // //             if (p is Map) payload = Map<String, dynamic>.from(p);
// // //           } catch (_) {
// // //             if (item is Map) payload = Map<String, dynamic>.from(item);
// // //           }
// // //           if (payload != null) {
// // //             final uid = payload[PresenceKey.userId] as String?;
// // //             if (uid != null) newPresences[uid] = payload;
// // //           }
// // //         }
// // //       }
// // //       state.presences
// // //         ..clear()
// // //         ..addAll(newPresences);
// // //     } catch (e) {
// // //       AppLogger.warning('_rebuildPresences failed: $e');
// // //     }
// // //   }

// // //   Map<String, dynamic> _s(dynamic p) => p is Map<String, dynamic> ? p : {};
// // //   int _ts() => DateTime.now().millisecondsSinceEpoch;
// // // }

// // import 'dart:async';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import '../utils/app_logger.dart';

// // abstract final class RoomEvent {
// //   static const gameState = 'game_state';
// //   static const playerAction = 'player_action';
// //   static const syncRequest = 'sync_request';
// //   static const roomEvent = 'room_event';
// //   static const chatMessage = 'chat_message';
// //   static const moderation = 'moderation';
// //   static const settingsChange = 'settings_change';
// //   static const gameStarted = 'game_started';
// //   static const gameEnded = 'game_ended';
// // }

// // abstract final class PresenceKey {
// //   static const userId = 'user_id';
// //   static const displayName = 'display_name';
// //   static const avatarUrl = 'avatar_url';
// //   static const seatOrder = 'seat_order';
// //   static const isReady = 'is_ready';
// //   static const joinedAt = 'joined_at';
// // }

// // typedef BroadcastHandler = void Function(Map<String, dynamic> payload);
// // typedef PresenceHandler = void Function(List<Map<String, dynamic>> presences);
// // typedef StatusHandler = void Function(RealtimeSubscribeStatus status);

// // class _ChannelState {
// //   _ChannelState(this.channel);
// //   final RealtimeChannel channel;
// //   RealtimeSubscribeStatus status = RealtimeSubscribeStatus.subscribed;
// //   final ctrl = StreamController<RealtimeSubscribeStatus>.broadcast();
// //   // Own presence map: userId → tracked payload (the data we pass to track())
// //   final presences = <String, Map<String, dynamic>>{};
// // }

// // /// Supabase Realtime service — Broadcast + Presence per room channel.
// // class RealtimeService {
// //   RealtimeService._();
// //   static final RealtimeService _instance = RealtimeService._();
// //   static RealtimeService get instance => _instance;

// //   final _supabase = Supabase.instance.client;
// //   final _channels = <String, _ChannelState>{};

// //   Future<void> subscribe({
// //     required String roomId,
// //     required BroadcastHandler onGameState,
// //     required BroadcastHandler onPlayerAction,
// //     required BroadcastHandler onSyncRequest,
// //     required BroadcastHandler onRoomEvent,
// //     required BroadcastHandler onChatMessage,
// //     required BroadcastHandler onModeration,
// //     required BroadcastHandler onSettingsChange,
// //     required BroadcastHandler onGameStarted,
// //     required BroadcastHandler onGameEnded,
// //     required PresenceHandler onPresenceSync,
// //     required PresenceHandler onPresenceJoin,
// //     required PresenceHandler onPresenceLeave,
// //     required StatusHandler onStatusChange,
// //   }) async {
// //     // If already subscribed, unsubscribe first so new callbacks are registered
// //     if (_channels.containsKey(roomId)) {
// //       await unsubscribe(roomId);
// //     }

// //     final state = _ChannelState(
// //       _supabase.channel(
// //         'room:$roomId',
// //         opts: const RealtimeChannelConfig(ack: false, self: false),
// //       ),
// //     );

// //     state.channel
// //         .onBroadcast(
// //           event: RoomEvent.gameState,
// //           callback: (p) => onGameState(_s(p)),
// //         )
// //         .onBroadcast(
// //           event: RoomEvent.playerAction,
// //           callback: (p) => onPlayerAction(_s(p)),
// //         )
// //         .onBroadcast(
// //           event: RoomEvent.syncRequest,
// //           callback: (p) => onSyncRequest(_s(p)),
// //         )
// //         .onBroadcast(
// //           event: RoomEvent.roomEvent,
// //           callback: (p) => onRoomEvent(_s(p)),
// //         )
// //         .onBroadcast(
// //           event: RoomEvent.chatMessage,
// //           callback: (p) => onChatMessage(_s(p)),
// //         )
// //         .onBroadcast(
// //           event: RoomEvent.moderation,
// //           callback: (p) => onModeration(_s(p)),
// //         )
// //         .onBroadcast(
// //           event: RoomEvent.settingsChange,
// //           callback: (p) => onSettingsChange(_s(p)),
// //         )
// //         .onBroadcast(
// //           event: RoomEvent.gameStarted,
// //           callback: (p) => onGameStarted(_s(p)),
// //         )
// //         .onBroadcast(
// //           event: RoomEvent.gameEnded,
// //           callback: (p) => onGameEnded(_s(p)),
// //         )
// //         .onPresenceSync((_) {
// //           // Full snapshot — rebuild from raw presenceState map
// //           _rebuildPresences(roomId, state);
// //           AppLogger.debug(
// //             'PresenceSync: ${state.presences.length} online in $roomId',
// //           );
// //           onPresenceSync(state.presences.values.toList());
// //         })
// //         .onPresenceJoin((payload) {
// //           // payload.newPresences is List<Presence> — each has .payload Map
// //           final joined = _extractPresences(payload.newPresences);
// //           for (final p in joined) {
// //             final uid = p[PresenceKey.userId] as String?;
// //             if (uid != null) state.presences[uid] = p;
// //           }
// //           AppLogger.debug(
// //             'PresenceJoin: ${joined.length} joined, total=${state.presences.length}',
// //           );
// //           onPresenceSync(state.presences.values.toList());
// //         })
// //         .onPresenceLeave((payload) {
// //           final left = _extractPresences(payload.leftPresences);
// //           for (final p in left) {
// //             final uid = p[PresenceKey.userId] as String?;
// //             if (uid != null) state.presences.remove(uid);
// //           }
// //           AppLogger.debug(
// //             'PresenceLeave: ${left.length} left, total=${state.presences.length}',
// //           );
// //           onPresenceSync(state.presences.values.toList());
// //         })
// //         .subscribe((status, err) {
// //           final st = _channels[roomId];
// //           if (st == null) return;
// //           st.status = status;
// //           st.ctrl.add(status);
// //           onStatusChange(status);
// //           if (err != null) {
// //             AppLogger.error('Channel $roomId err', error: err);
// //           } else {
// //             AppLogger.info('Channel room:$roomId → ${status.name}');
// //           }
// //         });

// //     _channels[roomId] = state;
// //   }

// //   Future<void> trackPresence(String roomId, Map<String, dynamic> data) async {
// //     try {
// //       await _channels[roomId]?.channel.track(data);
// //       // Also store locally so our own presence is in the snapshot
// //       final uid = data[PresenceKey.userId] as String?;
// //       if (uid != null) _channels[roomId]?.presences[uid] = data;
// //     } catch (e) {
// //       AppLogger.warning('trackPresence failed: $e');
// //     }
// //   }

// //   Future<void> untrackPresence(String roomId) async {
// //     try {
// //       await _channels[roomId]?.channel.untrack();
// //     } catch (e) {
// //       AppLogger.warning('untrackPresence failed: $e');
// //     }
// //   }

// //   List<Map<String, dynamic>> presenceSnapshot(String roomId) =>
// //       _channels[roomId]?.presences.values.toList() ?? [];

// //   Future<void> broadcastGameState(
// //     String roomId,
// //     Map<String, dynamic> snapshot,
// //     String senderId,
// //   ) => _bcast(roomId, RoomEvent.gameState, {
// //     'sender_id': senderId,
// //     'snapshot': snapshot,
// //     'ts': _ts(),
// //   });

// //   Future<void> broadcastPlayerAction(
// //     String roomId,
// //     Map<String, dynamic> action,
// //   ) => _bcast(roomId, RoomEvent.playerAction, {...action, 'ts': _ts()});

// //   Future<void> broadcastSyncRequest(
// //     String roomId,
// //     String requesterId,
// //     int lastKnownRound,
// //   ) => _bcast(roomId, RoomEvent.syncRequest, {
// //     'requester_id': requesterId,
// //     'last_known_round': lastKnownRound,
// //     'ts': _ts(),
// //   });

// //   Future<void> broadcastRoomEvent(String roomId, Map<String, dynamic> event) =>
// //       _bcast(roomId, RoomEvent.roomEvent, {...event, 'ts': _ts()});

// //   Future<void> broadcastChat(String roomId, Map<String, dynamic> message) =>
// //       _bcast(roomId, RoomEvent.chatMessage, {...message, 'ts': _ts()});

// //   Future<void> broadcastModeration(
// //     String roomId,
// //     Map<String, dynamic> action,
// //   ) => _bcast(roomId, RoomEvent.moderation, {...action, 'ts': _ts()});

// //   Future<void> broadcastSettingsChange(
// //     String roomId,
// //     String field,
// //     dynamic value,
// //   ) => _bcast(roomId, RoomEvent.settingsChange, {
// //     'field': field,
// //     'new_value': value,
// //     'ts': _ts(),
// //   });

// //   Future<void> broadcastGameStarted(
// //     String roomId,
// //     Map<String, dynamic> config,
// //   ) => _bcast(roomId, RoomEvent.gameStarted, {...config, 'ts': _ts()});

// //   Future<void> broadcastGameEnded(
// //     String roomId,
// //     Map<String, dynamic> results,
// //   ) => _bcast(roomId, RoomEvent.gameEnded, {...results, 'ts': _ts()});

// //   Future<void> unsubscribe(String roomId) async {
// //     final st = _channels.remove(roomId);
// //     if (st != null) {
// //       await st.channel.unsubscribe();
// //       await st.ctrl.close();
// //       AppLogger.info('RealtimeService: unsubscribed $roomId');
// //     }
// //   }

// //   Future<void> unsubscribeAll() async {
// //     for (final id in List.of(_channels.keys)) await unsubscribe(id);
// //   }

// //   bool isSubscribed(String roomId) => _channels.containsKey(roomId);
// //   RealtimeSubscribeStatus? statusOf(String roomId) => _channels[roomId]?.status;
// //   Stream<RealtimeSubscribeStatus>? statusStream(String roomId) =>
// //       _channels[roomId]?.ctrl.stream;

// //   // ── Internals ─────────────────────────────────────────────────────────────

// //   Future<void> _bcast(
// //     String roomId,
// //     String event,
// //     Map<String, dynamic> payload,
// //   ) async {
// //     final ch = _channels[roomId]?.channel;
// //     if (ch == null) {
// //       AppLogger.warning('No channel $roomId — drop $event');
// //       return;
// //     }
// //     try {
// //       await ch.sendBroadcastMessage(event: event, payload: payload);
// //     } catch (e) {
// //       AppLogger.error('Broadcast $event failed', error: e);
// //     }
// //   }

// //   /// Extract payloads from a typed List<Presence> (supabase_flutter v2).
// //   /// Each Presence has a .payload property that is Map<String, dynamic>.
// //   List<Map<String, dynamic>> _extractPresences(List<dynamic> presences) {
// //     final result = <Map<String, dynamic>>[];
// //     for (final p in presences) {
// //       try {
// //         // Try accessing .payload (typed Presence object)
// //         final payload = (p as dynamic).payload;
// //         if (payload is Map) {
// //           result.add(Map<String, dynamic>.from(payload));
// //         }
// //       } catch (_) {
// //         // Fallback: p itself might be the map
// //         if (p is Map) result.add(Map<String, dynamic>.from(p));
// //       }
// //     }
// //     return result;
// //   }

// //   /// Rebuild presence map from presenceState() — used on full sync.
// //   void _rebuildPresences(String roomId, _ChannelState state) {
// //     try {
// //       final raw = state.channel.presenceState();
// //       // presenceState() returns Map<String, List<Presence>>
// //       // key = presence key (auto), value = list of Presence objects
// //       if (raw is! Map) return;
// //       final newPresences = <String, Map<String, dynamic>>{};
// //       for (final entry in (raw as Map).entries) {
// //         final list = entry.value is List ? entry.value as List : [entry.value];
// //         for (final item in list) {
// //           Map<String, dynamic>? payload;
// //           try {
// //             final p = (item as dynamic).payload;
// //             if (p is Map) payload = Map<String, dynamic>.from(p);
// //           } catch (_) {
// //             if (item is Map) payload = Map<String, dynamic>.from(item);
// //           }
// //           if (payload != null) {
// //             final uid = payload[PresenceKey.userId] as String?;
// //             if (uid != null) newPresences[uid] = payload;
// //           }
// //         }
// //       }
// //       state.presences
// //         ..clear()
// //         ..addAll(newPresences);
// //     } catch (e) {
// //       AppLogger.warning('_rebuildPresences failed: $e');
// //     }
// //   }

// //   Map<String, dynamic> _s(dynamic p) => p is Map<String, dynamic> ? p : {};
// //   int _ts() => DateTime.now().millisecondsSinceEpoch;
// // }

// import 'dart:async';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../utils/app_logger.dart';

// abstract final class RoomEvent {
//   static const gameState = 'game_state';
//   static const playerAction = 'player_action';
//   static const syncRequest = 'sync_request';
//   static const roomEvent = 'room_event';
//   static const chatMessage = 'chat_message';
//   static const moderation = 'moderation';
//   static const settingsChange = 'settings_change';
//   static const gameStarted = 'game_started';
//   static const gameEnded = 'game_ended';
// }

// abstract final class PresenceKey {
//   static const userId = 'user_id';
//   static const displayName = 'display_name';
//   static const avatarUrl = 'avatar_url';
//   static const seatOrder = 'seat_order';
//   static const isReady = 'is_ready';
//   static const joinedAt = 'joined_at';
// }

// typedef BroadcastHandler = void Function(Map<String, dynamic> payload);
// typedef PresenceHandler = void Function(List<Map<String, dynamic>> presences);
// typedef StatusHandler = void Function(RealtimeSubscribeStatus status);

// /// Mutable callback holder — stored per channel so callbacks can be
// /// updated when a new RoomProvider subscribes to the same room without
// /// tearing down and rebuilding the Supabase channel.
// class _Callbacks {
//   BroadcastHandler onGameState;
//   BroadcastHandler onPlayerAction;
//   BroadcastHandler onSyncRequest;
//   BroadcastHandler onRoomEvent;
//   BroadcastHandler onChatMessage;
//   BroadcastHandler onModeration;
//   BroadcastHandler onSettingsChange;
//   BroadcastHandler onGameStarted;
//   BroadcastHandler onGameEnded;
//   PresenceHandler onPresenceSync;
//   StatusHandler onStatusChange;

//   _Callbacks({
//     required this.onGameState,
//     required this.onPlayerAction,
//     required this.onSyncRequest,
//     required this.onRoomEvent,
//     required this.onChatMessage,
//     required this.onModeration,
//     required this.onSettingsChange,
//     required this.onGameStarted,
//     required this.onGameEnded,
//     required this.onPresenceSync,
//     required this.onStatusChange,
//   });
// }

// class _ChannelState {
//   _ChannelState(this.channel, this.callbacks);
//   final RealtimeChannel channel;
//   final _Callbacks callbacks;
//   RealtimeSubscribeStatus status = RealtimeSubscribeStatus.subscribed;
//   final ctrl = StreamController<RealtimeSubscribeStatus>.broadcast();
//   final presences = <String, Map<String, dynamic>>{};
// }

// class RealtimeService {
//   RealtimeService._();
//   static final RealtimeService _instance = RealtimeService._();
//   static RealtimeService get instance => _instance;

//   final _supabase = Supabase.instance.client;
//   final _channels = <String, _ChannelState>{};

//   Future<void> subscribe({
//     required String roomId,
//     required BroadcastHandler onGameState,
//     required BroadcastHandler onPlayerAction,
//     required BroadcastHandler onSyncRequest,
//     required BroadcastHandler onRoomEvent,
//     required BroadcastHandler onChatMessage,
//     required BroadcastHandler onModeration,
//     required BroadcastHandler onSettingsChange,
//     required BroadcastHandler onGameStarted,
//     required BroadcastHandler onGameEnded,
//     required PresenceHandler onPresenceSync,
//     required PresenceHandler onPresenceJoin,
//     required PresenceHandler onPresenceLeave,
//     required StatusHandler onStatusChange,
//   }) async {
//     // If channel already exists, just update the callbacks in place.
//     // This avoids tearing down and rebuilding the Supabase channel when
//     // a new RoomProvider instance subscribes (e.g. after a widget rebuild).
//     if (_channels.containsKey(roomId)) {
//       final st = _channels[roomId]!;
//       st.callbacks
//         ..onGameState = onGameState
//         ..onPlayerAction = onPlayerAction
//         ..onSyncRequest = onSyncRequest
//         ..onRoomEvent = onRoomEvent
//         ..onChatMessage = onChatMessage
//         ..onModeration = onModeration
//         ..onSettingsChange = onSettingsChange
//         ..onGameStarted = onGameStarted
//         ..onGameEnded = onGameEnded
//         ..onPresenceSync = onPresenceSync
//         ..onStatusChange = onStatusChange;
//       AppLogger.debug('RealtimeService: updated callbacks for room $roomId');
//       // Immediately deliver current presence snapshot to new subscriber
//       if (st.presences.isNotEmpty) {
//         onPresenceSync(st.presences.values.toList());
//       }
//       return;
//     }

//     final cb = _Callbacks(
//       onGameState: onGameState,
//       onPlayerAction: onPlayerAction,
//       onSyncRequest: onSyncRequest,
//       onRoomEvent: onRoomEvent,
//       onChatMessage: onChatMessage,
//       onModeration: onModeration,
//       onSettingsChange: onSettingsChange,
//       onGameStarted: onGameStarted,
//       onGameEnded: onGameEnded,
//       onPresenceSync: onPresenceSync,
//       onStatusChange: onStatusChange,
//     );

//     final channel = _supabase.channel(
//       'room:$roomId',
//       opts: const RealtimeChannelConfig(ack: false, self: false),
//     );

//     final state = _ChannelState(channel, cb);
//     _channels[roomId] = state; // register early so callbacks resolve

//     channel
//         .onBroadcast(
//           event: RoomEvent.gameState,
//           callback: (p) => state.callbacks.onGameState(_s(p)),
//         )
//         .onBroadcast(
//           event: RoomEvent.playerAction,
//           callback: (p) => state.callbacks.onPlayerAction(_s(p)),
//         )
//         .onBroadcast(
//           event: RoomEvent.syncRequest,
//           callback: (p) => state.callbacks.onSyncRequest(_s(p)),
//         )
//         .onBroadcast(
//           event: RoomEvent.roomEvent,
//           callback: (p) => state.callbacks.onRoomEvent(_s(p)),
//         )
//         .onBroadcast(
//           event: RoomEvent.chatMessage,
//           callback: (p) => state.callbacks.onChatMessage(_s(p)),
//         )
//         .onBroadcast(
//           event: RoomEvent.moderation,
//           callback: (p) => state.callbacks.onModeration(_s(p)),
//         )
//         .onBroadcast(
//           event: RoomEvent.settingsChange,
//           callback: (p) => state.callbacks.onSettingsChange(_s(p)),
//         )
//         .onBroadcast(
//           event: RoomEvent.gameStarted,
//           callback: (p) => state.callbacks.onGameStarted(_s(p)),
//         )
//         .onBroadcast(
//           event: RoomEvent.gameEnded,
//           callback: (p) => state.callbacks.onGameEnded(_s(p)),
//         )
//         .onPresenceSync((_) {
//           _rebuildPresences(roomId, state);
//           AppLogger.debug(
//             'PresenceSync: ${state.presences.length} online in $roomId',
//           );
//           state.callbacks.onPresenceSync(state.presences.values.toList());
//         })
//         .onPresenceJoin((payload) {
//           final joined = _extractPresences(payload.newPresences);
//           for (final p in joined) {
//             final uid = p[PresenceKey.userId] as String?;
//             if (uid != null) state.presences[uid] = p;
//           }
//           AppLogger.debug(
//             'PresenceJoin: ${joined.length} joined, total=${state.presences.length}',
//           );
//           state.callbacks.onPresenceSync(state.presences.values.toList());
//         })
//         .onPresenceLeave((payload) {
//           final left = _extractPresences(payload.leftPresences);
//           for (final p in left) {
//             final uid = p[PresenceKey.userId] as String?;
//             if (uid != null) state.presences.remove(uid);
//           }
//           AppLogger.debug(
//             'PresenceLeave: ${left.length} left, total=${state.presences.length}',
//           );
//           state.callbacks.onPresenceSync(state.presences.values.toList());
//         })
//         .subscribe((status, err) {
//           final st = _channels[roomId];
//           if (st == null) return;
//           st.status = status;
//           st.ctrl.add(status);
//           st.callbacks.onStatusChange(status);
//           if (err != null) {
//             AppLogger.error('Channel $roomId err', error: err);
//           } else {
//             AppLogger.info('Channel room:$roomId → ${status.name}');
//           }
//         });
//   }

//   Future<void> trackPresence(String roomId, Map<String, dynamic> data) async {
//     try {
//       await _channels[roomId]?.channel.track(data);
//       final uid = data[PresenceKey.userId] as String?;
//       if (uid != null) _channels[roomId]?.presences[uid] = data;
//     } catch (e) {
//       AppLogger.warning('trackPresence failed: $e');
//     }
//   }

//   Future<void> untrackPresence(String roomId) async {
//     try {
//       await _channels[roomId]?.channel.untrack();
//     } catch (e) {
//       AppLogger.warning('untrackPresence failed: $e');
//     }
//   }

//   List<Map<String, dynamic>> presenceSnapshot(String roomId) =>
//       _channels[roomId]?.presences.values.toList() ?? [];

//   Future<void> broadcastGameState(
//     String roomId,
//     Map<String, dynamic> snapshot,
//     String senderId,
//   ) => _bcast(roomId, RoomEvent.gameState, {
//     'sender_id': senderId,
//     'snapshot': snapshot,
//     'ts': _ts(),
//   });
//   Future<void> broadcastPlayerAction(
//     String roomId,
//     Map<String, dynamic> action,
//   ) => _bcast(roomId, RoomEvent.playerAction, {...action, 'ts': _ts()});
//   Future<void> broadcastSyncRequest(
//     String roomId,
//     String requesterId,
//     int lastKnownRound,
//   ) => _bcast(roomId, RoomEvent.syncRequest, {
//     'requester_id': requesterId,
//     'last_known_round': lastKnownRound,
//     'ts': _ts(),
//   });
//   Future<void> broadcastRoomEvent(String roomId, Map<String, dynamic> event) =>
//       _bcast(roomId, RoomEvent.roomEvent, {...event, 'ts': _ts()});
//   Future<void> broadcastChat(String roomId, Map<String, dynamic> message) =>
//       _bcast(roomId, RoomEvent.chatMessage, {...message, 'ts': _ts()});
//   Future<void> broadcastModeration(
//     String roomId,
//     Map<String, dynamic> action,
//   ) => _bcast(roomId, RoomEvent.moderation, {...action, 'ts': _ts()});
//   Future<void> broadcastSettingsChange(
//     String roomId,
//     String field,
//     dynamic value,
//   ) => _bcast(roomId, RoomEvent.settingsChange, {
//     'field': field,
//     'new_value': value,
//     'ts': _ts(),
//   });
//   Future<void> broadcastGameStarted(
//     String roomId,
//     Map<String, dynamic> config,
//   ) => _bcast(roomId, RoomEvent.gameStarted, {...config, 'ts': _ts()});
//   Future<void> broadcastGameEnded(
//     String roomId,
//     Map<String, dynamic> results,
//   ) => _bcast(roomId, RoomEvent.gameEnded, {...results, 'ts': _ts()});

//   Future<void> unsubscribe(String roomId) async {
//     final st = _channels.remove(roomId);
//     if (st != null) {
//       await st.channel.unsubscribe();
//       await st.ctrl.close();
//       AppLogger.info('RealtimeService: unsubscribed $roomId');
//     }
//   }

//   Future<void> unsubscribeAll() async {
//     for (final id in List.of(_channels.keys)) await unsubscribe(id);
//   }

//   bool isSubscribed(String roomId) => _channels.containsKey(roomId);
//   RealtimeSubscribeStatus? statusOf(String roomId) => _channels[roomId]?.status;
//   Stream<RealtimeSubscribeStatus>? statusStream(String roomId) =>
//       _channels[roomId]?.ctrl.stream;

//   // ── Internals ─────────────────────────────────────────────────────────────

//   Future<void> _bcast(
//     String roomId,
//     String event,
//     Map<String, dynamic> payload,
//   ) async {
//     final ch = _channels[roomId]?.channel;
//     if (ch == null) {
//       AppLogger.warning('No channel $roomId — drop $event');
//       return;
//     }
//     try {
//       await ch.sendBroadcastMessage(event: event, payload: payload);
//     } catch (e) {
//       AppLogger.error('Broadcast $event failed', error: e);
//     }
//   }

//   List<Map<String, dynamic>> _extractPresences(List<dynamic> presences) {
//     final result = <Map<String, dynamic>>[];
//     for (final p in presences) {
//       try {
//         final payload = (p as dynamic).payload;
//         if (payload is Map) result.add(Map<String, dynamic>.from(payload));
//       } catch (_) {
//         if (p is Map) result.add(Map<String, dynamic>.from(p));
//       }
//     }
//     return result;
//   }

//   void _rebuildPresences(String roomId, _ChannelState state) {
//     try {
//       final raw = state.channel.presenceState();
//       if (raw is! Map) return;
//       final newPresences = <String, Map<String, dynamic>>{};
//       for (final entry in (raw as Map).entries) {
//         final list = entry.value is List ? entry.value as List : [entry.value];
//         for (final item in list) {
//           Map<String, dynamic>? payload;
//           try {
//             final p = (item as dynamic).payload;
//             if (p is Map) payload = Map<String, dynamic>.from(p);
//           } catch (_) {
//             if (item is Map) payload = Map<String, dynamic>.from(item);
//           }
//           if (payload != null) {
//             final uid = payload[PresenceKey.userId] as String?;
//             if (uid != null) newPresences[uid] = payload;
//           }
//         }
//       }
//       state.presences
//         ..clear()
//         ..addAll(newPresences);
//     } catch (e) {
//       AppLogger.warning('_rebuildPresences failed: $e');
//     }
//   }

//   Map<String, dynamic> _s(dynamic p) => p is Map<String, dynamic> ? p : {};
//   int _ts() => DateTime.now().millisecondsSinceEpoch;
// }

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

abstract final class RoomEvent {
  static const gameState = 'game_state';
  static const playerAction = 'player_action';
  static const syncRequest = 'sync_request';
  static const roomEvent = 'room_event';
  static const chatMessage = 'chat_message';
  static const moderation = 'moderation';
  static const settingsChange = 'settings_change';
  static const gameStarted = 'game_started';
  static const gameEnded = 'game_ended';
}

abstract final class PresenceKey {
  static const userId = 'user_id';
  static const displayName = 'display_name';
  static const avatarUrl = 'avatar_url';
  static const seatOrder = 'seat_order';
  static const isReady = 'is_ready';
  static const joinedAt = 'joined_at';
}

/// Well-known keys for the multiple independent listeners a room channel
/// can carry at once (see `RealtimeService`). `room` is RoomProvider's
/// listener (lives for the whole room visit); `game` is whichever game
/// screen is currently mounted (comes and goes as rounds start/end).
abstract final class RoomChannelSubscriber {
  static const room = 'room';
  static const game = 'game';
}

typedef BroadcastHandler = void Function(Map<String, dynamic> payload);
typedef PresenceHandler = void Function(List<Map<String, dynamic>> presences);
typedef StatusHandler = void Function(RealtimeSubscribeStatus status);

/// Mutable callback holder — stored per channel so callbacks can be
/// updated when a new RoomProvider subscribes to the same room without
/// tearing down and rebuilding the Supabase channel.
class _Callbacks {
  BroadcastHandler onGameState;
  BroadcastHandler onPlayerAction;
  BroadcastHandler onSyncRequest;
  BroadcastHandler onRoomEvent;
  BroadcastHandler onChatMessage;
  BroadcastHandler onModeration;
  BroadcastHandler onSettingsChange;
  BroadcastHandler onGameStarted;
  BroadcastHandler onGameEnded;
  PresenceHandler onPresenceSync;
  StatusHandler onStatusChange;

  _Callbacks({
    required this.onGameState,
    required this.onPlayerAction,
    required this.onSyncRequest,
    required this.onRoomEvent,
    required this.onChatMessage,
    required this.onModeration,
    required this.onSettingsChange,
    required this.onGameStarted,
    required this.onGameEnded,
    required this.onPresenceSync,
    required this.onStatusChange,
  });
}

class _ChannelState {
  _ChannelState(this.channel);
  final RealtimeChannel channel;
  RealtimeSubscribeStatus status = RealtimeSubscribeStatus.subscribed;
  final ctrl = StreamController<RealtimeSubscribeStatus>.broadcast();
  final presences = <String, Map<String, dynamic>>{};
  // Multiple independent listeners fan out from one shared channel, keyed
  // by subscriberId (see RoomChannelSubscriber) so e.g. a game screen
  // subscribing/disposing never touches RoomProvider's own listener.
  final listeners = <String, _Callbacks>{};
}

class RealtimeService {
  RealtimeService._();
  static final RealtimeService _instance = RealtimeService._();
  static RealtimeService get instance => _instance;

  final _supabase = Supabase.instance.client;
  final _channels = <String, _ChannelState>{};

  /// Registers [subscriberId]'s callbacks on the shared channel for
  /// [roomId]. Multiple independent subscribers (see [RoomChannelSubscriber])
  /// can hold listeners on the same room channel at once — subscribing under
  /// one id never touches another id's callbacks, and the underlying
  /// Supabase channel + presence tracking is created only once per room.
  Future<void> subscribe({
    required String roomId,
    required String subscriberId,
    required BroadcastHandler onGameState,
    required BroadcastHandler onPlayerAction,
    required BroadcastHandler onSyncRequest,
    required BroadcastHandler onRoomEvent,
    required BroadcastHandler onChatMessage,
    required BroadcastHandler onModeration,
    required BroadcastHandler onSettingsChange,
    required BroadcastHandler onGameStarted,
    required BroadcastHandler onGameEnded,
    required PresenceHandler onPresenceSync,
    required StatusHandler onStatusChange,
  }) async {
    final cb = _Callbacks(
      onGameState: onGameState,
      onPlayerAction: onPlayerAction,
      onSyncRequest: onSyncRequest,
      onRoomEvent: onRoomEvent,
      onChatMessage: onChatMessage,
      onModeration: onModeration,
      onSettingsChange: onSettingsChange,
      onGameStarted: onGameStarted,
      onGameEnded: onGameEnded,
      onPresenceSync: onPresenceSync,
      onStatusChange: onStatusChange,
    );

    // If the channel already exists, just add/replace this subscriber's
    // entry. This avoids tearing down and rebuilding the Supabase channel
    // — and avoids disturbing any *other* subscriber already registered —
    // whether it's the same RoomProvider re-subscribing after a rebuild, or
    // a game screen registering its own 'game' listener alongside 'room'.
    if (_channels.containsKey(roomId)) {
      final st = _channels[roomId]!;
      st.listeners[subscriberId] = cb;
      AppLogger.debug(
        'RealtimeService: listener "$subscriberId" registered for room '
        '$roomId (${st.listeners.length} active)',
      );
      // Immediately deliver current presence snapshot to new subscriber
      if (st.presences.isNotEmpty) {
        onPresenceSync(st.presences.values.toList());
      }
      return;
    }

    final channel = _supabase.channel(
      'room:$roomId',
      opts: const RealtimeChannelConfig(ack: false, self: false),
    );

    final state = _ChannelState(channel);
    state.listeners[subscriberId] = cb;
    _channels[roomId] = state; // register early so callbacks resolve

    channel
        .onBroadcast(
          event: RoomEvent.gameState,
          callback: (p) => _fanOut(state, (c) => c.onGameState, _s(p)),
        )
        .onBroadcast(
          event: RoomEvent.playerAction,
          callback: (p) => _fanOut(state, (c) => c.onPlayerAction, _s(p)),
        )
        .onBroadcast(
          event: RoomEvent.syncRequest,
          callback: (p) => _fanOut(state, (c) => c.onSyncRequest, _s(p)),
        )
        .onBroadcast(
          event: RoomEvent.roomEvent,
          callback: (p) => _fanOut(state, (c) => c.onRoomEvent, _s(p)),
        )
        .onBroadcast(
          event: RoomEvent.chatMessage,
          callback: (p) => _fanOut(state, (c) => c.onChatMessage, _s(p)),
        )
        .onBroadcast(
          event: RoomEvent.moderation,
          callback: (p) => _fanOut(state, (c) => c.onModeration, _s(p)),
        )
        .onBroadcast(
          event: RoomEvent.settingsChange,
          callback: (p) => _fanOut(state, (c) => c.onSettingsChange, _s(p)),
        )
        .onBroadcast(
          event: RoomEvent.gameStarted,
          callback: (p) => _fanOut(state, (c) => c.onGameStarted, _s(p)),
        )
        .onBroadcast(
          event: RoomEvent.gameEnded,
          callback: (p) => _fanOut(state, (c) => c.onGameEnded, _s(p)),
        )
        .onPresenceSync((_) {
          _rebuildPresences(roomId, state);
          AppLogger.debug(
            'PresenceSync: ${state.presences.length} online in $roomId',
          );
          _fanOutPresence(state, state.presences.values.toList());
        })
        .onPresenceJoin((payload) {
          final joined = _extractPresences(payload.newPresences);
          for (final p in joined) {
            final uid = p[PresenceKey.userId] as String?;
            if (uid != null) state.presences[uid] = p;
          }
          AppLogger.debug(
            'PresenceJoin: ${joined.length} joined, total=${state.presences.length}',
          );
          _fanOutPresence(state, state.presences.values.toList());
        })
        .onPresenceLeave((payload) {
          final left = _extractPresences(payload.leftPresences);
          for (final p in left) {
            final uid = p[PresenceKey.userId] as String?;
            if (uid != null) state.presences.remove(uid);
          }
          AppLogger.debug(
            'PresenceLeave: ${left.length} left, total=${state.presences.length}',
          );
          _fanOutPresence(state, state.presences.values.toList());
        })
        .subscribe((status, err) {
          final st = _channels[roomId];
          if (st == null) return;
          st.status = status;
          st.ctrl.add(status);
          for (final cb in st.listeners.values.toList()) {
            cb.onStatusChange(status);
          }
          if (err != null) {
            AppLogger.error('Channel $roomId err', error: err);
          } else {
            AppLogger.info('Channel room:$roomId → ${status.name}');
          }
        });
  }

  /// Removes only [subscriberId]'s callbacks from [roomId]'s channel — the
  /// channel itself, presence tracking, and any other subscriber's
  /// callbacks are left untouched. Use this (not [unsubscribe]) when a
  /// single screen (e.g. a game screen) is done listening but other
  /// subscribers (e.g. RoomProvider) are still using the room.
  void unsubscribeListener(String roomId, String subscriberId) {
    final st = _channels[roomId];
    if (st == null) return;
    st.listeners.remove(subscriberId);
    AppLogger.debug(
      'RealtimeService: listener "$subscriberId" removed from room '
      '$roomId (${st.listeners.length} remaining)',
    );
  }

  Future<void> trackPresence(String roomId, Map<String, dynamic> data) async {
    try {
      await _channels[roomId]?.channel.track(data);
      final uid = data[PresenceKey.userId] as String?;
      if (uid != null) _channels[roomId]?.presences[uid] = data;
    } catch (e) {
      AppLogger.warning('trackPresence failed: $e');
    }
  }

  Future<void> untrackPresence(String roomId) async {
    try {
      await _channels[roomId]?.channel.untrack();
    } catch (e) {
      AppLogger.warning('untrackPresence failed: $e');
    }
  }

  List<Map<String, dynamic>> presenceSnapshot(String roomId) =>
      _channels[roomId]?.presences.values.toList() ?? [];

  Future<void> broadcastGameState(
    String roomId,
    Map<String, dynamic> snapshot,
    String senderId,
  ) => _bcast(roomId, RoomEvent.gameState, {
    'sender_id': senderId,
    'snapshot': snapshot,
    'ts': _ts(),
  });
  Future<void> broadcastPlayerAction(
    String roomId,
    Map<String, dynamic> action,
  ) => _bcast(roomId, RoomEvent.playerAction, {...action, 'ts': _ts()});
  Future<void> broadcastSyncRequest(
    String roomId,
    String requesterId,
    int lastKnownRound,
  ) => _bcast(roomId, RoomEvent.syncRequest, {
    'requester_id': requesterId,
    'last_known_round': lastKnownRound,
    'ts': _ts(),
  });
  Future<void> broadcastRoomEvent(String roomId, Map<String, dynamic> event) =>
      _bcast(roomId, RoomEvent.roomEvent, {...event, 'ts': _ts()});
  Future<void> broadcastChat(String roomId, Map<String, dynamic> message) =>
      _bcast(roomId, RoomEvent.chatMessage, {...message, 'ts': _ts()});
  Future<void> broadcastModeration(
    String roomId,
    Map<String, dynamic> action,
  ) => _bcast(roomId, RoomEvent.moderation, {...action, 'ts': _ts()});
  Future<void> broadcastSettingsChange(
    String roomId,
    String field,
    dynamic value,
  ) => _bcast(roomId, RoomEvent.settingsChange, {
    'field': field,
    'new_value': value,
    'ts': _ts(),
  });
  Future<void> broadcastGameStarted(
    String roomId,
    Map<String, dynamic> config,
  ) => _bcast(roomId, RoomEvent.gameStarted, {...config, 'ts': _ts()});
  Future<void> broadcastGameEnded(
    String roomId,
    Map<String, dynamic> results,
  ) => _bcast(roomId, RoomEvent.gameEnded, {...results, 'ts': _ts()});

  Future<void> unsubscribe(String roomId) async {
    final st = _channels.remove(roomId);
    if (st != null) {
      await st.channel.unsubscribe();
      await st.ctrl.close();
      AppLogger.info('RealtimeService: unsubscribed $roomId');
    }
  }

  Future<void> unsubscribeAll() async {
    for (final id in List.of(_channels.keys)) await unsubscribe(id);
  }

  bool isSubscribed(String roomId) => _channels.containsKey(roomId);
  RealtimeSubscribeStatus? statusOf(String roomId) => _channels[roomId]?.status;
  Stream<RealtimeSubscribeStatus>? statusStream(String roomId) =>
      _channels[roomId]?.ctrl.stream;

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Dispatches a broadcast payload to every registered listener's handler
  /// picked out by [selector]. Snapshots the listener list first so a
  /// handler that synchronously subscribes/unsubscribes (e.g. disposing a
  /// game screen mid-callback) can't cause a concurrent-modification error.
  void _fanOut(
    _ChannelState state,
    BroadcastHandler Function(_Callbacks) selector,
    Map<String, dynamic> payload,
  ) {
    for (final cb in state.listeners.values.toList()) {
      try {
        selector(cb)(payload);
      } catch (e) {
        AppLogger.error('RealtimeService: listener callback threw', error: e);
      }
    }
  }

  void _fanOutPresence(_ChannelState state, List<Map<String, dynamic>> snapshot) {
    for (final cb in state.listeners.values.toList()) {
      try {
        cb.onPresenceSync(snapshot);
      } catch (e) {
        AppLogger.error('RealtimeService: presence callback threw', error: e);
      }
    }
  }

  Future<void> _bcast(
    String roomId,
    String event,
    Map<String, dynamic> payload,
  ) async {
    final ch = _channels[roomId]?.channel;
    if (ch == null) {
      AppLogger.warning('No channel $roomId — drop $event');
      return;
    }
    try {
      await ch.sendBroadcastMessage(event: event, payload: payload);
    } catch (e) {
      AppLogger.error('Broadcast $event failed', error: e);
    }
  }

  List<Map<String, dynamic>> _extractPresences(List<dynamic> presences) {
    final result = <Map<String, dynamic>>[];
    for (final p in presences) {
      try {
        final payload = (p as dynamic).payload;
        if (payload is Map) result.add(Map<String, dynamic>.from(payload));
      } catch (_) {
        if (p is Map) result.add(Map<String, dynamic>.from(p));
      }
    }
    return result;
  }

  void _rebuildPresences(String roomId, _ChannelState state) {
    try {
      final raw = state.channel.presenceState();
      if (raw is! Map) return;
      final newPresences = <String, Map<String, dynamic>>{};
      for (final entry in (raw as Map).entries) {
        final list = entry.value is List ? entry.value as List : [entry.value];
        for (final item in list) {
          Map<String, dynamic>? payload;
          try {
            final p = (item as dynamic).payload;
            if (p is Map) payload = Map<String, dynamic>.from(p);
          } catch (_) {
            if (item is Map) payload = Map<String, dynamic>.from(item);
          }
          if (payload != null) {
            final uid = payload[PresenceKey.userId] as String?;
            if (uid != null) newPresences[uid] = payload;
          }
        }
      }
      state.presences
        ..clear()
        ..addAll(newPresences);
    } catch (e) {
      AppLogger.warning('_rebuildPresences failed: $e');
    }
  }

  Map<String, dynamic> _s(dynamic p) => p is Map<String, dynamic> ? p : {};
  int _ts() => DateTime.now().millisecondsSinceEpoch;
}
