import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:livekit_client/livekit_client.dart' as lk;

/// Why the voice connection ended, reduced to what the controller acts on.
enum VoiceDisconnectReason {
  /// We called disconnect ourselves.
  clientInitiated,

  /// The same account joined voice from another device (same identity).
  duplicateIdentity,

  /// Removed by the server, or the LiveKit room was deleted.
  removed,

  /// Network loss after the SDK's own reconnect attempts, server shutdown,
  /// or anything else unexpected.
  connectionLost,
}

/// Events the controller consumes; a deliberately small subset of LiveKit's.
sealed class VoiceRoomEvent {
  const VoiceRoomEvent();
}

class VoiceReconnecting extends VoiceRoomEvent {
  const VoiceReconnecting();
}

class VoiceReconnected extends VoiceRoomEvent {
  const VoiceReconnected();
}

class VoiceDisconnected extends VoiceRoomEvent {
  const VoiceDisconnected(this.reason);
  final VoiceDisconnectReason reason;
}

/// LiveKit participant identities (= Supabase user ids) currently speaking.
class VoiceActiveSpeakersChanged extends VoiceRoomEvent {
  const VoiceActiveSpeakersChanged(this.identities);
  final Set<String> identities;
}

/// The server changed the local participant's publish permission.
class VoiceLocalPublishPermissionChanged extends VoiceRoomEvent {
  const VoiceLocalPublishPermissionChanged({required this.canPublish});
  final bool canPublish;
}

/// Thin seam over one LiveKit room connection, so [VoiceRoomController]
/// can be unit-tested without a LiveKit server. One instance per
/// connection attempt; it is never reused after [dispose].
abstract class VoiceRoomAdapter {
  Stream<VoiceRoomEvent> get events;

  /// Connects without publishing anything: the microphone stays off until
  /// [setMicrophoneEnabled] is called.
  Future<void> connect({required String url, required String token});

  Future<void> setMicrophoneEnabled(bool enabled);

  /// Leaves the room (notifying the server) and releases audio resources.
  /// Safe to call more than once, and before/without [connect].
  Future<void> dispose();
}

typedef VoiceRoomAdapterFactory = VoiceRoomAdapter Function();

/// [VoiceRoomAdapter] backed by livekit_client 2.13.1.
///
/// Token renewal: the SDK stores server-pushed refresh tokens
/// (SignalTokenUpdatedEvent -> engine.token) and its own resume/restart
/// reconnects use them, so nothing here re-requests a token while
/// connected. Once the SDK gives up and emits RoomDisconnectedEvent, the
/// controller requires an explicit rejoin, which fetches a fresh token from
/// the backend.
class LiveKitVoiceRoomAdapter implements VoiceRoomAdapter {
  LiveKitVoiceRoomAdapter();

  final _events = StreamController<VoiceRoomEvent>.broadcast();
  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _listener;
  bool _disposed = false;

  @override
  Stream<VoiceRoomEvent> get events => _events.stream;

  void _emit(VoiceRoomEvent event) {
    if (!_disposed && !_events.isClosed) _events.add(event);
  }

  @override
  Future<void> connect({required String url, required String token}) async {
    if (_disposed) throw StateError('LiveKitVoiceRoomAdapter is disposed');
    final room = lk.Room(
      roomOptions: const lk.RoomOptions(adaptiveStream: false, dynacast: false),
    );
    _room = room;
    _listener = room.createListener()
      ..on<lk.RoomReconnectingEvent>((_) => _emit(const VoiceReconnecting()))
      ..on<lk.RoomReconnectedEvent>((_) => _emit(const VoiceReconnected()))
      ..on<lk.RoomDisconnectedEvent>(
        (e) => _emit(VoiceDisconnected(mapDisconnectReason(e.reason))),
      )
      ..on<lk.ActiveSpeakersChangedEvent>(
        (e) => _emit(
          VoiceActiveSpeakersChanged({for (final p in e.speakers) p.identity}),
        ),
      )
      ..on<lk.ParticipantPermissionsUpdatedEvent>((e) {
        if (e.participant is lk.LocalParticipant) {
          _emit(
            VoiceLocalPublishPermissionChanged(
              canPublish: e.permissions.canPublish,
            ),
          );
        }
      });
    await room.connect(url, token);
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    final local = _room?.localParticipant;
    if (_disposed || local == null) return;
    await local.setMicrophoneEnabled(enabled);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final room = _room;
    final listener = _listener;
    _room = null;
    _listener = null;
    try {
      await room?.localParticipant?.setMicrophoneEnabled(false);
    } catch (_) {}
    try {
      await room?.disconnect();
    } catch (_) {}
    try {
      await listener?.dispose();
    } catch (_) {}
    try {
      await room?.dispose();
    } catch (_) {}
    await _events.close();
  }

  @visibleForTesting
  static VoiceDisconnectReason mapDisconnectReason(
    lk.DisconnectReason? reason,
  ) => switch (reason) {
    lk.DisconnectReason.clientInitiated =>
      VoiceDisconnectReason.clientInitiated,
    lk.DisconnectReason.duplicateIdentity =>
      VoiceDisconnectReason.duplicateIdentity,
    lk.DisconnectReason.participantRemoved ||
    lk.DisconnectReason.roomDeleted => VoiceDisconnectReason.removed,
    _ => VoiceDisconnectReason.connectionLost,
  };
}
