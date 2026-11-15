import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/games/presentation/widgets/game_screen_security_gate.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/features/voice/data/voice_repository.dart';
import 'package:jma3a/features/voice/data/voice_room_adapter.dart';
import 'package:jma3a/features/voice/presentation/voice_room_controller.dart';
import 'package:jma3a/features/voice/presentation/widgets/voice_game_overlay.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements VoiceRepository {}

class _FakeAdapter implements VoiceRoomAdapter {
  final _events = StreamController<VoiceRoomEvent>.broadcast(sync: true);
  final micCalls = <bool>[];
  int disposeCount = 0;

  @override
  Stream<VoiceRoomEvent> get events => _events.stream;

  @override
  Future<void> connect({required String url, required String token}) async {}

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async =>
      micCalls.add(enabled);

  @override
  Future<void> dispose() async => disposeCount++;

  void emit(VoiceRoomEvent e) => _events.add(e);
}

const _roomId = '3f2b8c1e-9a4d-4e6f-8b2a-1c3d5e7f9a0b';

RoomMemberEntity _member({bool isSpectator = false}) => RoomMemberEntity(
  userId: 'me',
  displayName: 'Sara',
  seatOrder: 0,
  isReady: false,
  isOwner: false,
  isModerator: false,
  isSpectator: isSpectator,
);

/// Stand-in game screen with a control near the overlay's edge and one in
/// the middle, to prove touches outside the overlay still reach the game.
class _FakeGame extends StatelessWidget {
  const _FakeGame({required this.onAction});
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Game')),
    body: Center(
      child: ElevatedButton(
        key: const Key('game_action'),
        style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
        onPressed: onAction,
        child: const Text('Action'),
      ),
    ),
  );
}

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'APP_ENV=development'));

  // No screen_protector plugin under `flutter test`: answer the gate's
  // outgoing calls (enable/addListener/...) so they don't surface as
  // MissingPluginException. Incoming 'onScreenRecord' events are unaffected.
  const protectorChannel = MethodChannel('screen_protector');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(protectorChannel, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(protectorChannel, null);
  });

  late _MockRepository repo;
  late ValueNotifier<VoiceMembership?> membership;
  late List<_FakeAdapter> adapters;
  late VoiceRoomController controller;
  late AppLocalizations en;
  late int gameActions;

  setUp(() async {
    repo = _MockRepository();
    membership = ValueNotifier(VoiceMembership.fromMember(_member()));
    adapters = [];
    gameActions = 0;
    controller = VoiceRoomController(
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
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  tearDown(() => controller.dispose());

  void grants(VoiceRole role) =>
      when(() => repo.fetchToken(roomId: any(named: 'roomId'))).thenAnswer(
        (_) async => VoiceTokenGrant(
          token: 'tok',
          livekitUrl: 'ws://localhost:7880',
          roomName: 'jma3a_room_$_roomId',
          identity: 'me',
          role: role,
          expiresAt: DateTime.utc(2030),
        ),
      );

  Future<void> pumpGate(
    WidgetTester tester, {
    VoiceRoomController? voice,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreenSecurityGate(
          voiceController: voice,
          child: _FakeGame(onAction: () => gameActions++),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> connectAs(WidgetTester tester, VoiceRole role) async {
    grants(role);
    await tester.runAsync(controller.join);
    await tester.pump();
    expect(controller.status, VoiceConnectionStatus.connected);
  }

  /// Simulates iOS reporting screen recording, through the same platform
  /// channel screen_protector listens on — this is what makes the gate swap
  /// its child for the recording Stack.
  Future<void> setRecording(WidgetTester tester, bool recording) async {
    final msg = const StandardMethodCodec().encodeMethodCall(
      MethodCall('onScreenRecord', recording),
    );
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'screen_protector',
      msg,
      (_) {},
    );
    await tester.pump();
  }

  group('mounting', () {
    testWidgets('null controller: no overlay, game renders as before', (
      tester,
    ) async {
      await pumpGate(tester);
      expect(find.byType(VoiceGameOverlay), findsNothing);
      expect(find.byKey(const Key('game_action')), findsOneWidget);
    });

    testWidgets('controller but no voice session: nothing visible', (
      tester,
    ) async {
      await pumpGate(tester, voice: controller);
      expect(find.byType(VoiceGameOverlay), findsOneWidget);
      expect(find.byKey(VoiceGameOverlay.buttonKey), findsNothing);
      expect(find.byKey(VoiceGameOverlay.pillKey), findsNothing);
    });

    testWidgets('appears when voice connects, disappears when it ends', (
      tester,
    ) async {
      await pumpGate(tester, voice: controller);
      await connectAs(tester, VoiceRole.speaker);
      expect(find.byKey(VoiceGameOverlay.buttonKey), findsOneWidget);

      adapters.single.emit(
        const VoiceDisconnected(VoiceDisconnectReason.connectionLost),
      );
      await tester.pump();
      expect(find.byKey(VoiceGameOverlay.buttonKey), findsNothing);
    });

    testWidgets('touches outside the overlay still reach the game', (
      tester,
    ) async {
      await pumpGate(tester, voice: controller);
      await connectAs(tester, VoiceRole.speaker);
      await tester.tap(find.byKey(const Key('game_action')));
      await tester.pump();
      expect(gameActions, 1);
    });
  });

  group('speaker', () {
    testWidgets('collapsed shows muted mic; expands to mic + leave', (
      tester,
    ) async {
      await pumpGate(tester, voice: controller);
      await connectAs(tester, VoiceRole.speaker);
      expect(
        find.descendant(
          of: find.byKey(VoiceGameOverlay.buttonKey),
          matching: find.byIcon(Icons.mic_off_rounded),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(VoiceGameOverlay.buttonKey));
      await tester.pumpAndSettle();
      expect(find.byKey(VoiceGameOverlay.pillKey), findsOneWidget);
      expect(find.text(en.voiceSpeaking), findsOneWidget);
      expect(adapters.single.micCalls, isEmpty, reason: 'still muted');

      await tester.tap(find.byKey(VoiceGameOverlay.micKey));
      await tester.pumpAndSettle();
      expect(adapters.single.micCalls, [true]);
      expect(controller.isMicrophoneEnabled, isTrue);
      expect(find.byTooltip(en.voiceMicOn), findsOneWidget);

      await tester.tap(find.byKey(VoiceGameOverlay.micKey));
      await tester.pumpAndSettle();
      expect(adapters.single.micCalls, [true, false]);
    });

    testWidgets('leave disconnects and hides the overlay', (tester) async {
      await pumpGate(tester, voice: controller);
      await connectAs(tester, VoiceRole.speaker);
      await tester.tap(find.byKey(VoiceGameOverlay.buttonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(VoiceGameOverlay.leaveKey));
      await tester.pumpAndSettle();
      expect(controller.status, VoiceConnectionStatus.idle);
      expect(find.byKey(VoiceGameOverlay.pillKey), findsNothing);
      expect(find.byKey(VoiceGameOverlay.buttonKey), findsNothing);
      await tester.runAsync(pumpEventQueue);
      expect(adapters.single.disposeCount, 1);
    });

    testWidgets('reconnecting: progress shown, mic disabled', (tester) async {
      await pumpGate(tester, voice: controller);
      await connectAs(tester, VoiceRole.speaker);
      await tester.tap(find.byKey(VoiceGameOverlay.buttonKey));
      await tester.pumpAndSettle();
      adapters.single.emit(const VoiceReconnecting());
      await tester.pump();
      expect(find.text(en.voiceReconnecting), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final mic = tester.widget<IconButton>(
        find.byKey(VoiceGameOverlay.micKey),
      );
      expect(mic.onPressed, isNull);
    });
  });

  group('spectator', () {
    testWidgets('listening status only, never mic controls', (tester) async {
      membership.value = VoiceMembership.fromMember(_member(isSpectator: true));
      await pumpGate(tester, voice: controller);
      await connectAs(tester, VoiceRole.listener);

      expect(find.byIcon(Icons.mic_rounded), findsNothing);
      expect(find.byIcon(Icons.mic_off_rounded), findsNothing);
      expect(find.byIcon(Icons.headset_rounded), findsOneWidget);

      await tester.tap(find.byKey(VoiceGameOverlay.buttonKey));
      await tester.pumpAndSettle();
      expect(find.text(en.voiceListening), findsOneWidget);
      expect(find.byKey(VoiceGameOverlay.micKey), findsNothing);
      expect(find.byKey(VoiceGameOverlay.leaveKey), findsOneWidget);
    });
  });

  group('security gate child changes', () {
    testWidgets('overlay stays mounted (state kept) across recording flips', (
      tester,
    ) async {
      await pumpGate(tester, voice: controller);
      await connectAs(tester, VoiceRole.speaker);
      await tester.tap(find.byKey(VoiceGameOverlay.buttonKey));
      await tester.pumpAndSettle();
      final before = tester.state(find.byType(VoiceGameOverlay));

      await setRecording(tester, true);
      expect(find.byIcon(Icons.videocam_off_rounded), findsOneWidget);
      expect(
        identical(tester.state(find.byType(VoiceGameOverlay)), before),
        isTrue,
      );
      expect(find.byKey(VoiceGameOverlay.pillKey), findsOneWidget);

      await setRecording(tester, false);
      expect(find.byIcon(Icons.videocam_off_rounded), findsNothing);
      expect(
        identical(tester.state(find.byType(VoiceGameOverlay)), before),
        isTrue,
      );
      expect(find.byKey(VoiceGameOverlay.pillKey), findsOneWidget);
      expect(controller.status, VoiceConnectionStatus.connected);
    });

    testWidgets('recording blackout still covers the game with voice on', (
      tester,
    ) async {
      await pumpGate(tester, voice: controller);
      await connectAs(tester, VoiceRole.speaker);
      await setRecording(tester, true);
      expect(find.byIcon(Icons.videocam_off_rounded), findsOneWidget);
      // The overlay is drawn above the blackout, but only its own button.
      expect(find.byKey(VoiceGameOverlay.buttonKey), findsOneWidget);
      await setRecording(tester, false);
    });
  });

  group('layout', () {
    for (final locale in const [Locale('ar'), Locale('fr')]) {
      testWidgets(
        'renders expanded in ${locale.languageCode} without overflow',
        (tester) async {
          final l = await AppLocalizations.delegate.load(locale);
          await tester.binding.setSurfaceSize(const Size(320, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await pumpGate(tester, voice: controller, locale: locale);
          await connectAs(tester, VoiceRole.speaker);
          await tester.tap(find.byKey(VoiceGameOverlay.buttonKey));
          await tester.pumpAndSettle();
          expect(find.text(l.voiceSpeaking), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('sits inside the safe area on the start edge', (tester) async {
      await pumpGate(tester, voice: controller);
      await connectAs(tester, VoiceRole.speaker);
      expect(
        find.ancestor(
          of: find.byKey(VoiceGameOverlay.buttonKey),
          matching: find.byType(SafeArea),
        ),
        findsOneWidget,
      );
      final rect = tester.getRect(find.byKey(VoiceGameOverlay.buttonKey));
      final screen = tester.getSize(find.byType(GameScreenSecurityGate));
      expect(rect.left, lessThan(screen.width / 4));
      expect(rect.top, greaterThan(kToolbarHeight));
      expect(rect.bottom, lessThan(screen.height - 80));
    });
  });
}
