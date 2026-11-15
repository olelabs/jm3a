import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/errors/failures.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/features/voice/data/voice_repository.dart';
import 'package:jma3a/features/voice/data/voice_room_adapter.dart';
import 'package:jma3a/features/voice/presentation/voice_room_controller.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements VoiceRepository {}

/// Scriptable stand-in for one LiveKit connection.
class _FakeAdapter implements VoiceRoomAdapter {
  final events$ = StreamController<VoiceRoomEvent>.broadcast(sync: true);
  Completer<void>? connectGate;
  Completer<void>? micGate;
  Object? connectError;
  Object? micError;
  final micCalls = <bool>[];
  String? connectedUrl;
  String? connectedToken;
  int disposeCount = 0;

  @override
  Stream<VoiceRoomEvent> get events => events$.stream;

  @override
  Future<void> connect({required String url, required String token}) async {
    connectedUrl = url;
    connectedToken = token;
    if (connectGate != null) await connectGate!.future;
    if (connectError != null) throw connectError!;
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    micCalls.add(enabled);
    if (micGate != null) await micGate!.future;
    if (micError != null) throw micError!;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }

  void emit(VoiceRoomEvent e) => events$.add(e);
}

const _roomId = '3f2b8c1e-9a4d-4e6f-8b2a-1c3d5e7f9a0b';

VoiceTokenGrant _grant(VoiceRole role, {String token = 'tok-1'}) =>
    VoiceTokenGrant(
      token: token,
      livekitUrl: 'ws://localhost:7880',
      roomName: 'jma3a_room_$_roomId',
      identity: 'user-1',
      role: role,
      expiresAt: DateTime.utc(2030),
    );

RoomMemberEntity _member({
  bool isOwner = false,
  bool isModerator = false,
  bool isSpectator = false,
  bool isHiddenSpectator = false,
  bool isMuted = false,
  bool isGameMuted = false,
  bool isAway = false,
  bool leftDefinitively = false,
}) => RoomMemberEntity(
  userId: 'user-1',
  displayName: 'Me',
  seatOrder: 0,
  isReady: false,
  isOwner: isOwner,
  isModerator: isModerator,
  isSpectator: isSpectator,
  isHiddenSpectator: isHiddenSpectator,
  isMuted: isMuted,
  isGameMuted: isGameMuted,
  isAway: isAway,
  leftDefinitively: leftDefinitively,
);

void main() {
  // AppLogger reads AppConfig (dotenv) for its level; load a test value only.
  setUpAll(() => dotenv.testLoad(fileInput: 'APP_ENV=development'));

  late _MockRepository repo;
  late ValueNotifier<VoiceMembership?> membership;
  late List<_FakeAdapter> adapters;
  late VoiceRoomController controller;
  late int notifications;

  VoiceRoomController build({Duration delay = const Duration(seconds: 60)}) {
    final c = VoiceRoomController(
      roomId: _roomId,
      repository: repo,
      membershipSource: membership,
      readMembership: () => membership.value,
      adapterFactory: () {
        final a = _FakeAdapter();
        adapters.add(a);
        return a;
      },
      observeAppLifecycle: false,
      backgroundDisconnectDelay: delay,
    );
    c.addListener(() => notifications++);
    return c;
  }

  void tokenReturns(VoiceRole role) {
    when(
      () => repo.fetchToken(roomId: any(named: 'roomId')),
    ).thenAnswer((_) async => _grant(role));
  }

  void tokenThrows(Object error) {
    when(() => repo.fetchToken(roomId: any(named: 'roomId'))).thenThrow(error);
  }

  setUp(() {
    repo = _MockRepository();
    membership = ValueNotifier(VoiceMembership.fromMember(_member()));
    adapters = [];
    notifications = 0;
    controller = build();
  });

  tearDown(() {
    controller.dispose();
  });

  Future<void> joinAs(VoiceRole role) async {
    tokenReturns(role);
    await controller.join();
    expect(controller.status, VoiceConnectionStatus.connected);
  }

  group('opt-in connection', () {
    test('never requests a token or connects on its own', () async {
      membership.value = VoiceMembership.fromMember(_member(isModerator: true));
      membership.value = VoiceMembership.fromMember(_member());
      controller.handleAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(controller.status, VoiceConnectionStatus.idle);
      expect(adapters, isEmpty);
      verifyNever(() => repo.fetchToken(roomId: any(named: 'roomId')));
    });

    test('join: requestingToken -> connecting -> connected', () async {
      final states = <VoiceConnectionStatus>[];
      controller.addListener(() => states.add(controller.status));
      await joinAs(VoiceRole.speaker);
      expect(
        states,
        containsAllInOrder([
          VoiceConnectionStatus.requestingToken,
          VoiceConnectionStatus.connecting,
          VoiceConnectionStatus.connected,
        ]),
      );
      verify(() => repo.fetchToken(roomId: _roomId)).called(1);
      expect(adapters.single.connectedUrl, 'ws://localhost:7880');
      expect(adapters.single.connectedToken, 'tok-1');
    });

    test('double join while busy makes one request', () async {
      final gate = Completer<VoiceTokenGrant>();
      when(
        () => repo.fetchToken(roomId: any(named: 'roomId')),
      ).thenAnswer((_) => gate.future);
      final first = controller.join();
      await controller.join();
      gate.complete(_grant(VoiceRole.speaker));
      await first;
      verify(() => repo.fetchToken(roomId: _roomId)).called(1);
      expect(adapters, hasLength(1));
    });
  });

  group('roles and microphone', () {
    test('speaker joins muted; mic only on explicit enable', () async {
      await joinAs(VoiceRole.speaker);
      expect(controller.role, VoiceRole.speaker);
      expect(controller.isMicrophoneEnabled, isFalse);
      expect(adapters.single.micCalls, isEmpty);
      expect(controller.canToggleMicrophone, isTrue);

      await controller.setMicrophoneEnabled(true);
      expect(adapters.single.micCalls, [true]);
      expect(controller.isMicrophoneEnabled, isTrue);

      await controller.setMicrophoneEnabled(false);
      expect(adapters.single.micCalls, [true, false]);
      expect(controller.isMicrophoneEnabled, isFalse);
    });

    test('listener (spectator) can never enable the mic', () async {
      membership.value = VoiceMembership.fromMember(_member(isSpectator: true));
      await joinAs(VoiceRole.listener);
      expect(controller.role, VoiceRole.listener);
      expect(controller.canToggleMicrophone, isFalse);
      await controller.setMicrophoneEnabled(true);
      expect(adapters.single.micCalls, isEmpty);
      expect(controller.isMicrophoneEnabled, isFalse);
    });

    test('enable failure -> microphoneUnavailable, stays connected', () async {
      await joinAs(VoiceRole.speaker);
      adapters.single.micError = Exception('permission denied');
      await controller.setMicrophoneEnabled(true);
      expect(controller.isMicrophoneEnabled, isFalse);
      expect(controller.issue, VoiceIssue.microphoneUnavailable);
      expect(controller.status, VoiceConnectionStatus.connected);
    });

    test('mute failure fails closed: session ends', () async {
      await joinAs(VoiceRole.speaker);
      await controller.setMicrophoneEnabled(true);
      adapters.single.micError = Exception('stuck');
      await controller.setMicrophoneEnabled(false);
      expect(controller.status, VoiceConnectionStatus.idle);
      expect(controller.issue, VoiceIssue.failed);
      expect(adapters.single.disposeCount, 1);
    });

    test('mute requested while an enable is in flight wins', () async {
      await joinAs(VoiceRole.speaker);
      final adapter = adapters.single..micGate = Completer<void>();
      final enabling = controller.setMicrophoneEnabled(true);
      // The mute joins the in-flight loop and resolves once it's applied;
      // the UI reflects it immediately.
      final muting = controller.setMicrophoneEnabled(false);
      expect(controller.isMicrophoneEnabled, isFalse);
      adapter.micGate!.complete();
      adapter.micGate = null;
      await enabling;
      await muting;
      await pumpEventQueue();
      expect(adapter.micCalls, [true, false]);
      expect(controller.isMicrophoneEnabled, isFalse);
    });

    test('server revoking publish turns the mic state off', () async {
      await joinAs(VoiceRole.speaker);
      await controller.setMicrophoneEnabled(true);
      adapters.single.emit(
        const VoiceLocalPublishPermissionChanged(canPublish: false),
      );
      expect(controller.isMicrophoneEnabled, isFalse);
    });
  });

  group('local eligibility pre-check (no token request)', () {
    for (final entry in <String, (VoiceMembership?, VoiceIssue)>{
      'no membership': (null, VoiceIssue.notActiveMember),
      'hidden spectator': (
        VoiceMembership.fromMember(
          _member(isSpectator: true, isHiddenSpectator: true),
        ),
        VoiceIssue.hiddenSpectator,
      ),
      'away, awaiting approval': (
        VoiceMembership.fromMember(_member(isAway: true)),
        VoiceIssue.awaitingApproval,
      ),
      'left definitively': (
        VoiceMembership.fromMember(_member(leftDefinitively: true)),
        VoiceIssue.notActiveMember,
      ),
    }.entries) {
      test(entry.key, () async {
        membership.value = entry.value.$1;
        expect(controller.joinBlocker, entry.value.$2);
        await controller.join();
        expect(controller.status, VoiceConnectionStatus.idle);
        expect(controller.issue, entry.value.$2);
        verifyNever(() => repo.fetchToken(roomId: any(named: 'roomId')));
        expect(adapters, isEmpty);
      });
    }

    test('chat mute and game mute do not block joining', () async {
      membership.value = VoiceMembership.fromMember(
        _member(isMuted: true, isGameMuted: true),
      );
      expect(controller.joinBlocker, isNull);
      await joinAs(VoiceRole.speaker);
    });
  });

  group('backend authorization outcomes', () {
    for (final entry in <String, (Failure, VoiceIssue)>{
      'speaker_not_allowed': (
        const ForbiddenFailure(code: 'speaker_not_allowed'),
        VoiceIssue.speakerNotAllowed,
      ),
      'banned_from_room': (
        const ForbiddenFailure(code: 'banned_from_room'),
        VoiceIssue.bannedFromRoom,
      ),
      'not_an_active_member': (
        const ForbiddenFailure(code: 'not_an_active_member'),
        VoiceIssue.notActiveMember,
      ),
      'room_closed': (
        const ForbiddenFailure(code: 'room_closed'),
        VoiceIssue.roomClosed,
      ),
      'other 403': (
        const ForbiddenFailure(code: 'account_suspended'),
        VoiceIssue.notAllowed,
      ),
      'voice unavailable (404)': (
        const NotFoundFailure(code: voiceUnavailableCode),
        VoiceIssue.unavailable,
      ),
      'room_not_found': (
        const NotFoundFailure(code: 'room_not_found'),
        VoiceIssue.roomNotFound,
      ),
      'rate limited': (const RateLimitFailure(), VoiceIssue.rateLimited),
      'offline': (const OfflineFailure(), VoiceIssue.offline),
      'network': (const NetworkFailure(), VoiceIssue.offline),
      'server error': (const ServerFailure(message: 'boom'), VoiceIssue.failed),
    }.entries) {
      test(
        '${entry.key} -> ${entry.value.$2.name}, idle, no connection',
        () async {
          tokenThrows(entry.value.$1);
          await controller.join();
          expect(controller.status, VoiceConnectionStatus.idle);
          expect(controller.issue, entry.value.$2);
          expect(controller.role, isNull);
          expect(adapters, isEmpty);
        },
      );
    }

    test('connect failure -> failed, adapter released', () async {
      tokenReturns(VoiceRole.speaker);
      controller.dispose();
      controller = VoiceRoomController(
        roomId: _roomId,
        repository: repo,
        membershipSource: membership,
        readMembership: () => membership.value,
        adapterFactory: () {
          final a = _FakeAdapter()..connectError = Exception('ws refused');
          adapters.add(a);
          return a;
        },
        observeAppLifecycle: false,
      );
      await controller.join();
      expect(controller.status, VoiceConnectionStatus.idle);
      expect(controller.issue, VoiceIssue.failed);
      await pumpEventQueue();
      expect(adapters.single.disposeCount, 1);
    });

    test('next join clears the previous issue', () async {
      tokenThrows(const RateLimitFailure());
      await controller.join();
      expect(controller.issue, VoiceIssue.rateLimited);
      await joinAs(VoiceRole.speaker);
      expect(controller.issue, isNull);
    });
  });

  group('membership changes while connected', () {
    for (final entry in <String, (VoiceMembership?, VoiceIssue)>{
      'membership disappears': (null, VoiceIssue.membershipLost),
      'becomes hidden': (
        VoiceMembership.fromMember(
          _member(isSpectator: true, isHiddenSpectator: true),
        ),
        VoiceIssue.hiddenSpectator,
      ),
      'becomes away': (
        VoiceMembership.fromMember(_member(isAway: true)),
        VoiceIssue.awaitingApproval,
      ),
      'left definitively': (
        VoiceMembership.fromMember(_member(leftDefinitively: true)),
        VoiceIssue.membershipLost,
      ),
      'speaker becomes spectator': (
        VoiceMembership.fromMember(_member(isSpectator: true)),
        VoiceIssue.roleChanged,
      ),
    }.entries) {
      test('${entry.key} -> disconnect (${entry.value.$2.name})', () async {
        await joinAs(VoiceRole.speaker);
        await controller.setMicrophoneEnabled(true);
        membership.value = entry.value.$1;
        expect(controller.status, VoiceConnectionStatus.idle);
        expect(controller.issue, entry.value.$2);
        expect(controller.isMicrophoneEnabled, isFalse);
        await pumpEventQueue();
        expect(adapters.single.disposeCount, 1);
      });
    }

    test('spectator rejoin after roleChanged gets a fresh token', () async {
      await joinAs(VoiceRole.speaker);
      membership.value = VoiceMembership.fromMember(_member(isSpectator: true));
      expect(controller.issue, VoiceIssue.roleChanged);

      await joinAs(VoiceRole.listener);
      expect(controller.role, VoiceRole.listener);
      verify(() => repo.fetchToken(roomId: _roomId)).called(2);
      expect(adapters, hasLength(2));
    });

    test('listener staying a spectator is unaffected', () async {
      membership.value = VoiceMembership.fromMember(_member(isSpectator: true));
      await joinAs(VoiceRole.listener);
      membership.value = VoiceMembership.fromMember(_member(isSpectator: true));
      expect(controller.status, VoiceConnectionStatus.connected);
    });

    test('chat mute / game mute changes never disconnect or mute', () async {
      await joinAs(VoiceRole.speaker);
      await controller.setMicrophoneEnabled(true);
      membership.value = VoiceMembership.fromMember(_member(isMuted: true));
      membership.value = VoiceMembership.fromMember(_member(isGameMuted: true));
      membership.value = VoiceMembership.fromMember(
        _member(isMuted: true, isGameMuted: true),
      );
      expect(controller.status, VoiceConnectionStatus.connected);
      expect(controller.isMicrophoneEnabled, isTrue);
      expect(adapters.single.micCalls, [true]);
    });

    test(
      'membership lost while the token is in flight -> no connection',
      () async {
        final gate = Completer<VoiceTokenGrant>();
        when(
          () => repo.fetchToken(roomId: any(named: 'roomId')),
        ).thenAnswer((_) => gate.future);
        final joining = controller.join();
        expect(controller.status, VoiceConnectionStatus.requestingToken);
        membership.value = null;
        // Requesting counts as active: the change ends the attempt at once.
        expect(controller.status, VoiceConnectionStatus.idle);
        gate.complete(_grant(VoiceRole.speaker));
        await joining;
        expect(controller.status, VoiceConnectionStatus.idle);
        expect(adapters, isEmpty);
      },
    );

    test(
      'became spectator while token in flight -> speaker grant refused',
      () async {
        final gate = Completer<VoiceTokenGrant>();
        when(
          () => repo.fetchToken(roomId: any(named: 'roomId')),
        ).thenAnswer((_) => gate.future);
        final joining = controller.join();
        membership.value = VoiceMembership.fromMember(
          _member(isSpectator: true),
        );
        expect(controller.status, VoiceConnectionStatus.requestingToken);
        gate.complete(_grant(VoiceRole.speaker));
        await joining;
        expect(controller.status, VoiceConnectionStatus.idle);
        expect(controller.issue, VoiceIssue.roleChanged);
        expect(adapters, isEmpty);
      },
    );
  });

  group('app lifecycle', () {
    test('background mutes immediately; disconnects after 60s', () {
      fakeAsync((async) {
        tokenReturns(VoiceRole.speaker);
        controller.join();
        async.flushMicrotasks();
        controller.setMicrophoneEnabled(true);
        async.flushMicrotasks();
        expect(controller.isMicrophoneEnabled, isTrue);

        controller.handleAppLifecycleState(AppLifecycleState.paused);
        expect(controller.isMicrophoneEnabled, isFalse);
        async.flushMicrotasks();
        expect(adapters.single.micCalls, [true, false]);

        async.elapse(const Duration(seconds: 59));
        expect(controller.status, VoiceConnectionStatus.connected);

        async.elapse(const Duration(seconds: 1));
        expect(controller.status, VoiceConnectionStatus.idle);
        expect(controller.issue, VoiceIssue.backgroundTimeout);
        async.flushMicrotasks();
        expect(adapters.single.disposeCount, 1);
      });
    });

    test('resume within 60s cancels the disconnect and never unmutes', () {
      fakeAsync((async) {
        tokenReturns(VoiceRole.speaker);
        controller.join();
        async.flushMicrotasks();
        controller.setMicrophoneEnabled(true);
        async.flushMicrotasks();

        controller.handleAppLifecycleState(AppLifecycleState.hidden);
        async.elapse(const Duration(seconds: 30));
        controller.handleAppLifecycleState(AppLifecycleState.resumed);
        async.elapse(const Duration(minutes: 5));

        expect(controller.status, VoiceConnectionStatus.connected);
        expect(controller.isMicrophoneEnabled, isFalse);
        expect(adapters.single.micCalls, [true, false]);
        expect(controller.canToggleMicrophone, isTrue);
        verify(() => repo.fetchToken(roomId: _roomId)).called(1);
      });
    });

    test('mic cannot be enabled while in background', () {
      fakeAsync((async) {
        tokenReturns(VoiceRole.speaker);
        controller.join();
        async.flushMicrotasks();
        controller.handleAppLifecycleState(AppLifecycleState.paused);
        expect(controller.canToggleMicrophone, isFalse);
        controller.setMicrophoneEnabled(true);
        async.flushMicrotasks();
        expect(adapters.single.micCalls, isEmpty);
      });
    });

    test('enable in flight when backgrounded ends muted', () {
      fakeAsync((async) {
        tokenReturns(VoiceRole.speaker);
        controller.join();
        async.flushMicrotasks();
        final adapter = adapters.single..micGate = Completer<void>();
        controller.setMicrophoneEnabled(true);
        async.flushMicrotasks();
        controller.handleAppLifecycleState(AppLifecycleState.paused);
        adapter.micGate!.complete();
        adapter.micGate = null;
        async.flushMicrotasks();
        expect(adapter.micCalls, [true, false]);
        expect(controller.isMicrophoneEnabled, isFalse);
      });
    });

    test('backgrounded while connecting still times out', () {
      fakeAsync((async) {
        tokenReturns(VoiceRole.speaker);
        final gate = Completer<void>();
        controller.dispose();
        controller = VoiceRoomController(
          roomId: _roomId,
          repository: repo,
          membershipSource: membership,
          readMembership: () => membership.value,
          adapterFactory: () {
            final a = _FakeAdapter()..connectGate = gate;
            adapters.add(a);
            return a;
          },
          observeAppLifecycle: false,
        );
        controller.join();
        async.flushMicrotasks();
        expect(controller.status, VoiceConnectionStatus.connecting);
        controller.handleAppLifecycleState(AppLifecycleState.paused);
        async.elapse(const Duration(seconds: 30));
        gate.complete();
        async.flushMicrotasks();
        expect(controller.status, VoiceConnectionStatus.connected);
        // 60s are counted from backgrounding, not from connecting.
        async.elapse(const Duration(seconds: 30));
        expect(controller.status, VoiceConnectionStatus.idle);
        expect(controller.issue, VoiceIssue.backgroundTimeout);
      });
    });

    test('background while idle does nothing', () {
      fakeAsync((async) {
        controller.handleAppLifecycleState(AppLifecycleState.paused);
        async.elapse(const Duration(minutes: 2));
        expect(controller.status, VoiceConnectionStatus.idle);
        expect(controller.issue, isNull);
      });
    });

    test('inactive is ignored; detached leaves', () async {
      await joinAs(VoiceRole.speaker);
      await controller.setMicrophoneEnabled(true);
      controller.handleAppLifecycleState(AppLifecycleState.inactive);
      expect(controller.isMicrophoneEnabled, isTrue);
      controller.handleAppLifecycleState(AppLifecycleState.detached);
      expect(controller.status, VoiceConnectionStatus.idle);
    });

    testWidgets('wired to the real app lifecycle when enabled', (tester) async {
      tokenReturns(VoiceRole.speaker);
      final c = VoiceRoomController(
        roomId: _roomId,
        repository: repo,
        membershipSource: membership,
        readMembership: () => membership.value,
        adapterFactory: () {
          final a = _FakeAdapter();
          adapters.add(a);
          return a;
        },
        backgroundDisconnectDelay: const Duration(seconds: 60),
      );
      await tester.runAsync(c.join);
      await tester.runAsync(() => c.setMicrophoneEnabled(true));
      expect(c.isMicrophoneEnabled, isTrue);

      for (final s in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      expect(c.isMicrophoneEnabled, isFalse);
      expect(c.isInBackground, isTrue);

      for (final s in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      expect(c.isInBackground, isFalse);
      expect(c.isMicrophoneEnabled, isFalse);
      c.dispose();
    });
  });

  group('room events', () {
    test('reconnecting / reconnected', () async {
      await joinAs(VoiceRole.speaker);
      adapters.single.emit(const VoiceReconnecting());
      expect(controller.status, VoiceConnectionStatus.reconnecting);
      adapters.single.emit(const VoiceReconnected());
      expect(controller.status, VoiceConnectionStatus.connected);
      verify(() => repo.fetchToken(roomId: _roomId)).called(1);
    });

    for (final entry in <VoiceDisconnectReason, VoiceIssue>{
      VoiceDisconnectReason.duplicateIdentity: VoiceIssue.joinedElsewhere,
      VoiceDisconnectReason.removed: VoiceIssue.removed,
      VoiceDisconnectReason.connectionLost: VoiceIssue.connectionLost,
    }.entries) {
      test(
        'disconnected(${entry.key.name}) -> idle, no auto-reconnect',
        () async {
          await joinAs(VoiceRole.speaker);
          adapters.single.emit(VoiceDisconnected(entry.key));
          expect(controller.status, VoiceConnectionStatus.idle);
          expect(controller.issue, entry.value);
          await pumpEventQueue();
          expect(adapters, hasLength(1));
          verify(() => repo.fetchToken(roomId: _roomId)).called(1);
        },
      );
    }

    test('client-initiated disconnect event is ignored', () async {
      await joinAs(VoiceRole.speaker);
      adapters.single.emit(
        const VoiceDisconnected(VoiceDisconnectReason.clientInitiated),
      );
      expect(controller.status, VoiceConnectionStatus.connected);
    });

    test('active speakers are exposed by identity', () async {
      await joinAs(VoiceRole.listener);
      adapters.single.emit(const VoiceActiveSpeakersChanged({'a', 'b'}));
      expect(controller.activeSpeakerIds, {'a', 'b'});
      await controller.leave();
      expect(controller.activeSpeakerIds, isEmpty);
    });

    test('events from a previous session are ignored', () async {
      await joinAs(VoiceRole.speaker);
      final old = adapters.single;
      await controller.leave();
      await joinAs(VoiceRole.speaker);
      old.emit(const VoiceDisconnected(VoiceDisconnectReason.connectionLost));
      old.emit(const VoiceActiveSpeakersChanged({'ghost'}));
      expect(controller.status, VoiceConnectionStatus.connected);
      expect(controller.activeSpeakerIds, isEmpty);
    });
  });

  group('cleanup', () {
    test('leave releases the adapter; repeated leave is safe', () async {
      await joinAs(VoiceRole.speaker);
      await controller.setMicrophoneEnabled(true);
      await controller.leave();
      await controller.leave();
      await pumpEventQueue();
      expect(controller.status, VoiceConnectionStatus.idle);
      expect(controller.isMicrophoneEnabled, isFalse);
      expect(controller.issue, isNull);
      expect(adapters.single.disposeCount, 1);
    });

    test('leave during token request: late token is discarded', () async {
      final gate = Completer<VoiceTokenGrant>();
      when(
        () => repo.fetchToken(roomId: any(named: 'roomId')),
      ).thenAnswer((_) => gate.future);
      final joining = controller.join();
      await controller.leave();
      gate.complete(_grant(VoiceRole.speaker));
      await joining;
      expect(controller.status, VoiceConnectionStatus.idle);
      expect(adapters, isEmpty);
    });

    test('leave during connect: late connect is discarded', () async {
      tokenReturns(VoiceRole.speaker);
      final gate = Completer<void>();
      controller.dispose();
      controller = VoiceRoomController(
        roomId: _roomId,
        repository: repo,
        membershipSource: membership,
        readMembership: () => membership.value,
        adapterFactory: () {
          final a = _FakeAdapter()..connectGate = gate;
          adapters.add(a);
          return a;
        },
        observeAppLifecycle: false,
      );
      final joining = controller.join();
      await pumpEventQueue();
      expect(controller.status, VoiceConnectionStatus.connecting);
      await controller.leave();
      gate.complete();
      await joining;
      await pumpEventQueue();
      expect(controller.status, VoiceConnectionStatus.idle);
      expect(adapters.single.disposeCount, 1);
    });

    test('dispose releases the adapter once and is idempotent', () async {
      await joinAs(VoiceRole.speaker);
      final before = notifications;
      controller.dispose();
      controller.dispose();
      await pumpEventQueue();
      expect(controller.isDisposed, isTrue);
      expect(adapters.single.disposeCount, 1);
      expect(notifications, before, reason: 'no notify during/after dispose');
    });

    test('dispose during token request: nothing happens afterwards', () async {
      final gate = Completer<VoiceTokenGrant>();
      when(
        () => repo.fetchToken(roomId: any(named: 'roomId')),
      ).thenAnswer((_) => gate.future);
      final joining = controller.join();
      controller.dispose();
      final before = notifications;
      gate.complete(_grant(VoiceRole.speaker));
      await joining;
      expect(adapters, isEmpty);
      expect(notifications, before);
    });

    test('calls after dispose are no-ops', () async {
      await joinAs(VoiceRole.speaker);
      final adapter = adapters.single;
      controller.dispose();
      await controller.join();
      await controller.leave();
      await controller.setMicrophoneEnabled(true);
      controller.handleAppLifecycleState(AppLifecycleState.paused);
      membership.value = null;
      adapter.emit(const VoiceReconnecting());
      expect(adapter.micCalls, isEmpty);
      expect(adapters, hasLength(1));
    });

    test('dispose stops observing membership', () async {
      controller.dispose();
      membership.value = null; // must not throw on a disposed notifier
      expect(controller.isDisposed, isTrue);
    });
  });

  group('LiveKit disconnect reason mapping', () {
    test('maps every reason', () {
      VoiceDisconnectReason map(lk.DisconnectReason? r) =>
          LiveKitVoiceRoomAdapter.mapDisconnectReason(r);
      expect(
        map(lk.DisconnectReason.clientInitiated),
        VoiceDisconnectReason.clientInitiated,
      );
      expect(
        map(lk.DisconnectReason.duplicateIdentity),
        VoiceDisconnectReason.duplicateIdentity,
      );
      expect(
        map(lk.DisconnectReason.participantRemoved),
        VoiceDisconnectReason.removed,
      );
      expect(
        map(lk.DisconnectReason.roomDeleted),
        VoiceDisconnectReason.removed,
      );
      for (final r in [
        null,
        lk.DisconnectReason.unknown,
        lk.DisconnectReason.serverShutdown,
        lk.DisconnectReason.reconnectAttemptsExceeded,
        lk.DisconnectReason.signalingConnectionFailure,
        lk.DisconnectReason.joinFailure,
      ]) {
        expect(map(r), VoiceDisconnectReason.connectionLost, reason: '$r');
      }
    });
  });
}
