import 'package:dio/dio.dart';

import '../../../core/data/base_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';

/// Role the client asks for. The backend decides the final role: `auto`
/// yields speaker for host/player/moderator and listener for spectators.
enum VoiceRequestedRole { auto, speaker, listener }

/// Role granted by the backend for this token.
enum VoiceRole { speaker, listener }

/// Code on the [NotFoundFailure] thrown when POST /v1/voice/token isn't
/// mounted (voice disabled on this API, or not configured). A 404 for a
/// missing room keeps its own `room_not_found` code.
const voiceUnavailableCode = 'voice_unavailable';

/// A short-lived LiveKit grant from POST /v1/voice/token. [toString]
/// deliberately omits [token] so it can never end up in a log line.
class VoiceTokenGrant {
  const VoiceTokenGrant({
    required this.token,
    required this.livekitUrl,
    required this.roomName,
    required this.identity,
    required this.role,
    required this.expiresAt,
    this.voiceMuted = false,
  });

  final String token;
  final String livekitUrl;
  final String roomName;
  final String identity;
  final VoiceRole role;
  final DateTime expiresAt;

  /// Admin voice mute at issue time: the grant itself carries no publish
  /// permission then. UI hint only — LiveKit enforces the grant.
  final bool voiceMuted;

  /// Parses the response envelope's `data` object. Throws [FormatException]
  /// on any missing/invalid field — a half-valid grant is never used.
  factory VoiceTokenGrant.fromJson(Map<String, dynamic> json) {
    String str(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty) {
        throw FormatException('voice token response: invalid $key');
      }
      return value;
    }

    final role = switch (json['role']) {
      'speaker' => VoiceRole.speaker,
      'listener' => VoiceRole.listener,
      _ => throw const FormatException('voice token response: invalid role'),
    };
    final url = str('livekit_url');
    final scheme = Uri.tryParse(url)?.scheme;
    if (scheme != 'ws' && scheme != 'wss') {
      throw const FormatException('voice token response: invalid livekit_url');
    }
    final expiresAt = DateTime.tryParse(str('expires_at'));
    if (expiresAt == null) {
      throw const FormatException('voice token response: invalid expires_at');
    }
    return VoiceTokenGrant(
      token: str('token'),
      livekitUrl: url,
      roomName: str('room_name'),
      identity: str('identity'),
      role: role,
      expiresAt: expiresAt,
      voiceMuted: json['voice_muted'] == true,
    );
  }

  @override
  String toString() =>
      'VoiceTokenGrant(room: $roomName, identity: $identity, role: ${role.name}, '
      'voiceMuted: $voiceMuted, expiresAt: ${expiresAt.toIso8601String()})';
}

/// Fetches LiveKit tokens from jma3a-api. Identity, display name, room
/// name and grants are all decided server-side; the client only names the
/// room and an optional role preference.
class VoiceRepository extends BaseRepository {
  VoiceRepository({ApiClient? apiClient, super.connectivityService})
    : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  Future<VoiceTokenGrant> fetchToken({
    required String roomId,
    VoiceRequestedRole requestedRole = VoiceRequestedRole.auto,
  }) => guardedCall(
    operationName: 'fetchVoiceToken',
    operation: () async {
      final Response<Map<String, dynamic>> resp;
      try {
        resp = await _api.post<Map<String, dynamic>>(
          '/v1/voice/token',
          data: {'room_id': roomId, 'requested_role': requestedRole.name},
        );
      } on DioException catch (e) {
        final failure = _voiceFailure(e);
        if (failure != null) throw failure;
        rethrow;
      }
      final data = resp.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ServerFailure(message: 'Invalid voice token response.');
      }
      try {
        return VoiceTokenGrant.fromJson(data);
      } on FormatException {
        throw const ServerFailure(message: 'Invalid voice token response.');
      }
    },
  );

  /// Turns the room's voice chat on or off (owner, or a moderator with
  /// manage_settings). The backend enforces permissions and the Basic-tier
  /// daily allowance; a refusal surfaces as a [ForbiddenFailure] whose code
  /// is e.g. `voice_daily_limit_reached` or `permission_denied`.
  Future<bool> setRoomVoiceEnabled({
    required String roomId,
    required bool enabled,
  }) => guardedCall(
    operationName: 'setRoomVoiceEnabled',
    operation: () async {
      final Response<Map<String, dynamic>> resp;
      try {
        resp = await _api.post<Map<String, dynamic>>(
          '/v1/voice/rooms/$roomId/enabled',
          data: {'enabled': enabled},
        );
      } on DioException catch (e) {
        final failure = _voiceFailure(e);
        if (failure != null) throw failure;
        rethrow;
      }
      final data = resp.data?['data'];
      if (data is! Map || data['voice_enabled'] is! bool) {
        throw const ServerFailure(message: 'Invalid voice setting response.');
      }
      return data['voice_enabled'] as bool;
    },
  );

  /// Admin voice mute/unmute of another member's microphone (requires the
  /// mute_voice permission). Independent of chat and game mutes.
  Future<void> setMemberVoiceMuted({
    required String roomId,
    required String userId,
    required bool muted,
  }) => guardedCall(
    operationName: 'setMemberVoiceMuted',
    operation: () async {
      try {
        await _api.post<Map<String, dynamic>>(
          '/v1/voice/rooms/$roomId/members/$userId/voice-mute',
          data: {'muted': muted},
        );
      } on DioException catch (e) {
        final failure = _voiceFailure(e);
        if (failure != null) throw failure;
        rethrow;
      }
    },
  );

  /// Voice-specific mapping for the two statuses the shared ErrorHandler
  /// flattens: 403 (it drops the backend's code, which the voice UI needs to
  /// tell spectator/banned/inactive apart) and a 404 for the unmounted
  /// route. Everything else (400, 429, 5xx, timeouts) is left to the shared
  /// ErrorHandler via guardedCall, exactly like every other API call.
  static Failure? _voiceFailure(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    final rawError = body is Map ? body['error'] : null;
    final error = rawError is Map ? rawError : null;
    final code = error?['code'] as String?;
    final message = error?['message'] as String?;

    if (status == 403) {
      return ForbiddenFailure(
        message: message ?? 'You can\'t join voice in this room.',
        code: code,
      );
    }
    if (status == 404) {
      if (code == 'room_not_found' || code == 'member_not_found') {
        return NotFoundFailure(
          message: message ?? 'Room not found.',
          code: code,
        );
      }
      return const NotFoundFailure(
        message: 'Voice chat is not available.',
        code: voiceUnavailableCode,
      );
    }
    return null;
  }
}
