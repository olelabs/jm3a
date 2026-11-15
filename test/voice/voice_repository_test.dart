import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/errors/failures.dart';
import 'package:jma3a/core/network/api_client.dart';
import 'package:jma3a/core/services/connectivity_service.dart';
import 'package:jma3a/features/voice/data/voice_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockConnectivity extends Mock implements ConnectivityService {}

const _roomId = '3f2b8c1e-9a4d-4e6f-8b2a-1c3d5e7f9a0b';
const _token = 'eyJhbGciOiJIUzI1NiJ9.test-payload.test-signature';

Map<String, dynamic> _grantJson({
  String role = 'speaker',
  String url = 'ws://localhost:7880',
}) => {
  'token': _token,
  'livekit_url': url,
  'room_name': 'jma3a_room_$_roomId',
  'identity': 'user-1',
  'role': role,
  'expires_at': '2026-10-19T12:10:00.000Z',
};

final _request = RequestOptions(path: '/v1/voice/token');

DioException _httpError(int status, [Map<String, dynamic>? error]) =>
    DioException(
      requestOptions: _request,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: _request,
        statusCode: status,
        data: {'success': false, 'error': ?error},
      ),
    );

void main() {
  // AppLogger reads AppConfig (dotenv) for its level; load a test value only.
  setUpAll(() => dotenv.testLoad(fileInput: 'APP_ENV=development'));

  late _MockApiClient api;
  late _MockConnectivity connectivity;
  late VoiceRepository repo;

  setUp(() {
    api = _MockApiClient();
    connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenReturn(true);
    repo = VoiceRepository(apiClient: api, connectivityService: connectivity);
  });

  void respond(Map<String, dynamic> data) {
    when(
      () => api.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: _request,
        statusCode: 200,
        data: {'success': true, 'data': data},
      ),
    );
  }

  void fail(Object error) {
    when(
      () => api.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
    ).thenThrow(error);
  }

  group('success', () {
    test('posts only room_id and requested_role, parses the grant', () async {
      respond(_grantJson());
      final grant = await repo.fetchToken(roomId: _roomId);

      final captured = verify(
        () => api.post<Map<String, dynamic>>(
          '/v1/voice/token',
          data: captureAny(named: 'data'),
        ),
      ).captured.single;
      expect(captured, {'room_id': _roomId, 'requested_role': 'auto'});

      expect(grant.token, _token);
      expect(grant.livekitUrl, 'ws://localhost:7880');
      expect(grant.roomName, 'jma3a_room_$_roomId');
      expect(grant.identity, 'user-1');
      expect(grant.role, VoiceRole.speaker);
      expect(grant.expiresAt, DateTime.utc(2026, 10, 19, 12, 10));
    });

    test('explicit role preference is sent as-is', () async {
      respond(_grantJson(role: 'listener'));
      final grant = await repo.fetchToken(
        roomId: _roomId,
        requestedRole: VoiceRequestedRole.listener,
      );
      expect(grant.role, VoiceRole.listener);
      final data =
          verify(
                () => api.post<Map<String, dynamic>>(
                  any(),
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map;
      expect(data['requested_role'], 'listener');
    });

    test('toString never contains the token', () async {
      respond(_grantJson());
      final grant = await repo.fetchToken(roomId: _roomId);
      expect(grant.toString(), isNot(contains(_token)));
      expect(grant.toString(), isNot(contains('test-signature')));
    });

    test('wss URLs are accepted', () async {
      respond(_grantJson(url: 'wss://voice.example.test'));
      expect(
        (await repo.fetchToken(roomId: _roomId)).livekitUrl,
        'wss://voice.example.test',
      );
    });
  });

  group('malformed responses -> ServerFailure', () {
    for (final entry in <String, Map<String, dynamic>>{
      'missing token': {..._grantJson()}..remove('token'),
      'empty token': {..._grantJson(), 'token': ''},
      'unknown role': {..._grantJson(), 'role': 'admin'},
      'http url': _grantJson(url: 'http://localhost:7880'),
      'bad expiry': {..._grantJson(), 'expires_at': 'soon'},
    }.entries) {
      test(entry.key, () async {
        respond(entry.value);
        await expectLater(
          repo.fetchToken(roomId: _roomId),
          throwsA(isA<ServerFailure>()),
        );
      });
    }

    test('missing data envelope', () async {
      when(
        () => api.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _request,
          statusCode: 200,
          data: {'success': true},
        ),
      );
      await expectLater(
        repo.fetchToken(roomId: _roomId),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('failure mapping', () {
    for (final code in [
      'speaker_not_allowed',
      'banned_from_room',
      'not_an_active_member',
      'room_closed',
      'account_suspended',
    ]) {
      test('403 $code keeps its code and message', () async {
        fail(_httpError(403, {'code': code, 'message': 'msg for $code'}));
        await expectLater(
          repo.fetchToken(roomId: _roomId),
          throwsA(
            isA<ForbiddenFailure>()
                .having((f) => f.code, 'code', code)
                .having((f) => f.message, 'message', 'msg for $code'),
          ),
        );
      });
    }

    test('403 without a body still maps to ForbiddenFailure', () async {
      fail(_httpError(403));
      await expectLater(
        repo.fetchToken(roomId: _roomId),
        throwsA(isA<ForbiddenFailure>().having((f) => f.code, 'code', isNull)),
      );
    });

    test('404 from the unmounted route -> voice unavailable', () async {
      fail(
        _httpError(404, {'code': 'not_found', 'message': 'Route not found'}),
      );
      await expectLater(
        repo.fetchToken(roomId: _roomId),
        throwsA(
          isA<NotFoundFailure>().having(
            (f) => f.code,
            'code',
            voiceUnavailableCode,
          ),
        ),
      );
    });

    test('404 room_not_found keeps its own code', () async {
      fail(
        _httpError(404, {
          'code': 'room_not_found',
          'message': 'Room not found.',
        }),
      );
      await expectLater(
        repo.fetchToken(roomId: _roomId),
        throwsA(
          isA<NotFoundFailure>().having(
            (f) => f.code,
            'code',
            'room_not_found',
          ),
        ),
      );
    });

    test('429 -> RateLimitFailure with retry_after (shared mapping)', () async {
      fail(
        _httpError(429, {
          'code': 'rate_limit_exceeded',
          'message': 'Too many',
          'retry_after': 60,
        }),
      );
      await expectLater(
        repo.fetchToken(roomId: _roomId),
        throwsA(
          isA<RateLimitFailure>().having(
            (f) => f.retryAfterSeconds,
            'retryAfterSeconds',
            60,
          ),
        ),
      );
    });

    test('400 -> ValidationFailure (shared mapping)', () async {
      fail(_httpError(400, {'code': 'invalid_request', 'message': 'bad'}));
      await expectLater(
        repo.fetchToken(roomId: _roomId),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('500 -> ServerFailure (shared mapping)', () async {
      fail(_httpError(500, {'code': 'voice_check_failed', 'message': 'x'}));
      await expectLater(
        repo.fetchToken(roomId: _roomId),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('timeout -> NetworkFailure (shared mapping)', () async {
      fail(
        DioException(
          requestOptions: _request,
          type: DioExceptionType.connectionTimeout,
        ),
      );
      await expectLater(
        repo.fetchToken(roomId: _roomId),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('offline -> OfflineFailure without calling the API', () async {
      when(() => connectivity.isOnline).thenReturn(false);
      await expectLater(
        repo.fetchToken(roomId: _roomId),
        throwsA(isA<OfflineFailure>()),
      );
      verifyNever(
        () => api.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      );
    });
  });
}
