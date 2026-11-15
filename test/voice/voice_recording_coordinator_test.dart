import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/features/games/presentation/widgets/game_screen_security_gate.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/features/voice/data/voice_repository.dart';
import 'package:jma3a/features/voice/data/voice_room_adapter.dart';
import 'package:jma3a/features/voice/presentation/voice_recording_coordinator.dart';
import 'package:jma3a/features/voice/presentation/voice_room_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements VoiceRepository {}

class _FakeAdapter implements VoiceRoomAdapter {
  final _events = StreamController<VoiceRoomEvent>.broadcast(sync: true);
  final micCalls = <bool>[];
  Completer<void>? micGate;
  Completer<void>? disposeGate;
  Object? muteError;
  int disposeCount = 0;

  @override
  Stream<VoiceRoomEvent> get events => _events.stream;

  @override
  Future<void> connect({required String url, required String token}) async {}

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    micCalls.add(enabled);
    if (micGate != null) await micGate!.future;
    if (!enabled && muteError != null) throw muteError!;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
    if (disposeGate != null) await disposeGate!.future;
  }
}

const _roomId = '3f2b8c1e-9a4d-4e6f-8b2a-1c3d5e7f9a0b';

RoomMemberEntity _member({bool isMuted = false, bool isGameMuted = false}) =>
    RoomMemberEntity(
      userId: 'me',
      displayName: 'Sara',
      seatOrder: 0,
      isReady: false,
      isOwner: false,
      isModerator: false,
      isMuted: isMuted,
      isGameMuted: isGameMuted,
    );

/// Records the order of recorder actions, standing in for AudioRecorder.
class _FakeRecorder {
  final log = <String>[];
  bool recording = false;
  void start() {
    log.add('start');
    recording = true;
  }

  void stop() {
    log.add('stop');
    recording = false;
  }
}

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'APP_ENV=development'));

  late _MockRepository repo;
  late ValueNotifier<VoiceMembership?> membership;
  late List<_FakeAdapter> adapters;
  late VoiceRoomController controller;

  VoiceRoomController buildController() => VoiceRoomController(
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
  );

  setUp(() {
    repo = _MockRepository();
    membership = ValueNotifier(VoiceMembership.fromMember(_member()));
    adapters = [];
    controller = buildController();
    when(() => repo.fetchToken(roomId: any(named: 'roomId'))).thenAnswer(
      (_) async => VoiceTokenGrant(
        token: 'tok',
        livekitUrl: 'ws://localhost:7880',
        roomName: 'jma3a_room_$_roomId',
        identity: 'me',
        role: VoiceRole.speaker,
        expiresAt: DateTime.utc(2030),
      ),
    );
  });

  tearDown(() {
    if (!controller.isDisposed) controller.dispose();
  });

  Future<_FakeAdapter> connectWithMic({required bool micOn}) async {
    await controller.join();
    expect(controller.status, VoiceConnectionStatus.connected);
    if (micOn) {
      await controller.setMicrophoneEnabled(true);
      expect(controller.isMicrophoneEnabled, isTrue);
    }
    return adapters.single;
  }

  /// The same sequence tod_card_screen's proof sheet runs: prepare, record
  /// only on `ready`, release on stop.
  Future<VoiceRecordingReadiness> recordOnce(
    VoiceRecordingCoordinator c,
    _FakeRecorder r,
  ) async {
    final readiness = await c.prepareToRecord();
    if (readiness != VoiceRecordingReadiness.ready) return readiness;
    r.start();
    r.stop();
    c.recordingEnded();
    return readiness;
  }

  group('no voice (existing behaviour unchanged)', () {
    test('no controller in the game: ready immediately, all no-ops', () async {
      final c = VoiceRecordingCoordinator(null);
      final r = _FakeRecorder();
      expect(await recordOnce(c, r), VoiceRecordingReadiness.ready);
      expect(r.log, ['start', 'stop']);
      c.recordingEnded();
      c.close();
      expect(c.isHoldingMicrophone, isFalse);
    });

    test('voice disconnected: ready, no LiveKit calls', () async {
      final c = VoiceRecordingCoordinator(controller);
      expect(await c.prepareToRecord(), VoiceRecordingReadiness.ready);
      expect(adapters, isEmpty);
      expect(controller.isMicrophoneHeld, isTrue);
      c.recordingEnded();
      expect(controller.isMicrophoneHeld, isFalse);
      expect(controller.status, VoiceConnectionStatus.idle);
    });
  });

  group('voice connected', () {
    test('mic enabled: muted and confirmed BEFORE recording starts', () async {
      final adapter = await connectWithMic(micOn: true);
      final c = VoiceRecordingCoordinator(controller);
      final r = _FakeRecorder();

      final readiness = await c.prepareToRecord();
      expect(readiness, VoiceRecordingReadiness.ready);
      expect(adapter.micCalls, [true, false]);
      expect(controller.isMicrophoneEnabled, isFalse);
      expect(r.log, isEmpty, reason: 'nothing recorded yet');
      r.start();
      expect(r.recording, isTrue);
      r.stop();
      c.recordingEnded();
    });

    test('mic already muted: no extra LiveKit call, ready', () async {
      final adapter = await connectWithMic(micOn: false);
      final c = VoiceRecordingCoordinator(controller);
      expect(await c.prepareToRecord(), VoiceRecordingReadiness.ready);
      expect(adapter.micCalls, isEmpty);
      c.recordingEnded();
    });

    test('mic cannot be re-enabled while recording', () async {
      final adapter = await connectWithMic(micOn: true);
      final c = VoiceRecordingCoordinator(controller);
      await c.prepareToRecord();
      expect(controller.canToggleMicrophone, isFalse);
      await controller.setMicrophoneEnabled(true);
      expect(adapter.micCalls, [true, false]);
      expect(controller.isMicrophoneEnabled, isFalse);
      c.recordingEnded();
    });

    test(
      'mic stays muted after recording; user may re-enable manually',
      () async {
        final adapter = await connectWithMic(micOn: true);
        final c = VoiceRecordingCoordinator(controller);
        await recordOnce(c, _FakeRecorder());
        await pumpEventQueue();

        expect(controller.isMicrophoneEnabled, isFalse);
        expect(adapter.micCalls, [true, false], reason: 'never auto-restored');
        expect(controller.canToggleMicrophone, isTrue);

        await controller.setMicrophoneEnabled(true);
        expect(adapter.micCalls, [true, false, true]);
      },
    );

    test('mute in flight: recording waits for the confirmation', () async {
      final adapter = await connectWithMic(micOn: true);
      adapter.micGate = Completer<void>();
      final c = VoiceRecordingCoordinator(controller);
      var done = false;
      final preparing = c.prepareToRecord().then((v) {
        done = true;
        return v;
      });
      await pumpEventQueue();
      expect(done, isFalse, reason: 'must not record before mute confirmed');
      adapter.micGate!.complete();
      adapter.micGate = null;
      expect(await preparing, VoiceRecordingReadiness.ready);
      c.recordingEnded();
    });

    test('chat/game mute flags play no part', () async {
      membership.value = VoiceMembership.fromMember(
        _member(isMuted: true, isGameMuted: true),
      );
      final adapter = await connectWithMic(micOn: true);
      final c = VoiceRecordingCoordinator(controller);
      expect(await c.prepareToRecord(), VoiceRecordingReadiness.ready);
      expect(adapter.micCalls, [true, false]);
      c.recordingEnded();
    });
  });

  group('mute cannot be confirmed -> no recording', () {
    test('mute failure: busy, nothing recorded, voice fails closed', () async {
      final adapter = await connectWithMic(micOn: true);
      adapter.muteError = Exception('stuck');
      final c = VoiceRecordingCoordinator(controller);
      final r = _FakeRecorder();

      expect(await recordOnce(c, r), VoiceRecordingReadiness.microphoneBusy);
      expect(r.log, isEmpty);
      expect(c.isHoldingMicrophone, isFalse);
      expect(controller.isMicrophoneHeld, isFalse);
      expect(controller.status, VoiceConnectionStatus.idle);
      expect(controller.issue, VoiceIssue.failed);
    });

    test(
      'retry after a failed mute succeeds once voice is torn down',
      () async {
        final adapter = await connectWithMic(micOn: true);
        adapter.muteError = Exception('stuck');
        final c = VoiceRecordingCoordinator(controller);
        expect(
          await c.prepareToRecord(),
          VoiceRecordingReadiness.microphoneBusy,
        );
        await pumpEventQueue();
        expect(adapter.disposeCount, 1);
        expect(await c.prepareToRecord(), VoiceRecordingReadiness.ready);
        c.recordingEnded();
      },
    );

    test('mute never confirmed: busy after the timeout', () {
      fakeAsync((async) {
        controller.join();
        async.flushMicrotasks();
        controller.setMicrophoneEnabled(true);
        async.flushMicrotasks();
        adapters.single.micGate = Completer<void>(); // mute hangs
        final c = VoiceRecordingCoordinator(controller);
        VoiceRecordingReadiness? result;
        c.prepareToRecord().then((v) => result = v);
        async.elapse(
          VoiceRoomController.microphoneHoldTimeout -
              const Duration(milliseconds: 1),
        );
        expect(result, isNull);
        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
        expect(result, VoiceRecordingReadiness.microphoneBusy);
        expect(controller.isMicrophoneHeld, isFalse);
        expect(controller.isMicrophoneEnabled, isFalse);
      });
    });

    test('just left voice: waits until LiveKit released the mic', () async {
      final adapter = await connectWithMic(micOn: true);
      adapter.disposeGate = Completer<void>();
      await controller.leave();
      final c = VoiceRecordingCoordinator(controller);
      var done = false;
      final preparing = c.prepareToRecord().then((v) {
        done = true;
        return v;
      });
      await pumpEventQueue();
      expect(done, isFalse);
      adapter.disposeGate!.complete();
      expect(await preparing, VoiceRecordingReadiness.ready);
      c.recordingEnded();
    });

    test('LiveKit teardown hangs: busy after the timeout', () {
      fakeAsync((async) {
        controller.join();
        async.flushMicrotasks();
        adapters.single.disposeGate = Completer<void>();
        controller.leave();
        final c = VoiceRecordingCoordinator(controller);
        VoiceRecordingReadiness? result;
        c.prepareToRecord().then((v) => result = v);
        async.elapse(VoiceRoomController.microphoneHoldTimeout);
        async.flushMicrotasks();
        expect(result, VoiceRecordingReadiness.microphoneBusy);
      });
    });
  });

  group('every exit releases the hold (mic stays muted)', () {
    test('completion', () async {
      await connectWithMic(micOn: true);
      final c = VoiceRecordingCoordinator(controller);
      await c.prepareToRecord();
      c.recordingEnded();
      expect(controller.isMicrophoneHeld, isFalse);
      expect(controller.isMicrophoneEnabled, isFalse);
    });

    test('cancellation (sheet closed) refuses further recording', () async {
      await connectWithMic(micOn: true);
      final c = VoiceRecordingCoordinator(controller);
      await c.prepareToRecord();
      c.close();
      expect(controller.isMicrophoneHeld, isFalse);
      expect(await c.prepareToRecord(), VoiceRecordingReadiness.closed);
      expect(controller.isMicrophoneHeld, isFalse);
    });

    test('exception while starting the recorder', () async {
      await connectWithMic(micOn: true);
      final c = VoiceRecordingCoordinator(controller);
      Future<void> startRecording() async {
        if (await c.prepareToRecord() != VoiceRecordingReadiness.ready) return;
        try {
          throw Exception('recorder.start failed');
        } catch (_) {
          c.recordingEnded();
          rethrow;
        }
      }

      await expectLater(startRecording(), throwsException);
      expect(controller.isMicrophoneHeld, isFalse);
      expect(controller.isMicrophoneEnabled, isFalse);
    });

    test('closed while the mute is still in flight', () async {
      final adapter = await connectWithMic(micOn: true);
      adapter.micGate = Completer<void>();
      final c = VoiceRecordingCoordinator(controller);
      final preparing = c.prepareToRecord();
      c.close();
      adapter.micGate!.complete();
      adapter.micGate = null;
      expect(await preparing, VoiceRecordingReadiness.closed);
      await pumpEventQueue();
      expect(controller.isMicrophoneHeld, isFalse);
      expect(controller.isMicrophoneEnabled, isFalse);
    });

    test('repeated release/close is safe', () async {
      await connectWithMic(micOn: false);
      final c = VoiceRecordingCoordinator(controller);
      await c.prepareToRecord();
      c.recordingEnded();
      c.recordingEnded();
      c.close();
      c.close();
      expect(controller.isMicrophoneHeld, isFalse);
    });

    test('a second prepare does not leak a hold', () async {
      await connectWithMic(micOn: false);
      final c = VoiceRecordingCoordinator(controller);
      await c.prepareToRecord();
      await c.prepareToRecord();
      c.recordingEnded();
      expect(controller.isMicrophoneHeld, isFalse);
    });

    test('controller disposed while held: release is safe', () async {
      await connectWithMic(micOn: true);
      final c = VoiceRecordingCoordinator(controller);
      await c.prepareToRecord();
      controller.dispose();
      c.close();
      expect(c.isHoldingMicrophone, isFalse);
    });

    test('rejoining while recording stays muted until the hold ends', () async {
      final c = VoiceRecordingCoordinator(controller);
      await c.prepareToRecord(); // idle -> hold granted
      await controller.join();
      expect(controller.canToggleMicrophone, isFalse);
      await controller.setMicrophoneEnabled(true);
      expect(adapters.single.micCalls, isEmpty);
      c.recordingEnded();
      expect(controller.canToggleMicrophone, isTrue);
    });
  });

  group('widget disposal / navigation', () {
    testWidgets('VoiceRecordingCleanup closes the coordinator on removal', (
      tester,
    ) async {
      await tester.runAsync(() => connectWithMic(micOn: true));
      final c = VoiceRecordingCoordinator(controller);
      await tester.runAsync(c.prepareToRecord);
      expect(controller.isMicrophoneHeld, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceRecordingCleanup(
            coordinator: c,
            child: const Text('proof sheet'),
          ),
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: Text('elsewhere')));

      expect(c.isClosed, isTrue);
      expect(controller.isMicrophoneHeld, isFalse);
      expect(controller.isMicrophoneEnabled, isFalse);
    });

    testWidgets('modal sheet dismissed by route removal releases the hold', (
      tester,
    ) async {
      await tester.runAsync(() => connectWithMic(micOn: true));
      final c = VoiceRecordingCoordinator(controller);
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navKey, home: const Text('game')),
      );
      showModalBottomSheet<void>(
        context: navKey.currentContext!,
        builder: (_) => VoiceRecordingCleanup(
          coordinator: c,
          child: const SizedBox(height: 200, child: Text('proof sheet')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(c.prepareToRecord);
      expect(controller.isMicrophoneHeld, isTrue);

      // Navigation away tears the whole stack down (e.g. kicked -> home).
      navKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const Text('home')),
        (_) => false,
      );
      await tester.pumpAndSettle();
      expect(controller.isMicrophoneHeld, isFalse);
      expect(c.isClosed, isTrue);
    });
  });

  group('VoiceSessionScope via the game route gate', () {
    const protector = MethodChannel('screen_protector');
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(protector, (_) async => null);
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(protector, null);
    });

    Future<VoiceRoomController?> lookup(
      WidgetTester tester,
      VoiceRoomController? voice,
    ) async {
      VoiceRoomController? found;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreenSecurityGate(
            voiceController: voice,
            child: Builder(
              builder: (context) {
                found = VoiceSessionScope.maybeOf(context);
                return const Scaffold(body: Text('game'));
              },
            ),
          ),
        ),
      );
      return found;
    }

    testWidgets('game screens find the controller', (tester) async {
      expect(await lookup(tester, controller), same(controller));
    });

    testWidgets('no controller -> null (recording unchanged)', (tester) async {
      expect(await lookup(tester, null), isNull);
    });
  });
}
