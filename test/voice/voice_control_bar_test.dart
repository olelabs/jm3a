import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/errors/failures.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/app_colors.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/features/rooms/presentation/widgets/member_tile.dart';
import 'package:jma3a/features/voice/data/voice_repository.dart';
import 'package:jma3a/features/voice/data/voice_room_adapter.dart';
import 'package:jma3a/features/voice/presentation/voice_room_controller.dart';
import 'package:jma3a/features/voice/presentation/widgets/voice_control_bar.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements VoiceRepository {}

class _FakeAdapter implements VoiceRoomAdapter {
  final _events = StreamController<VoiceRoomEvent>.broadcast(sync: true);
  final micCalls = <bool>[];
  Object? micError;
  int disposeCount = 0;

  @override
  Stream<VoiceRoomEvent> get events => _events.stream;

  @override
  Future<void> connect({required String url, required String token}) async {}

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    micCalls.add(enabled);
    if (micError != null) throw micError!;
  }

  @override
  Future<void> dispose() async => disposeCount++;

  void emit(VoiceRoomEvent e) => _events.add(e);
}

const _roomId = '3f2b8c1e-9a4d-4e6f-8b2a-1c3d5e7f9a0b';

VoiceTokenGrant _grant(VoiceRole role) => VoiceTokenGrant(
  token: 'tok',
  livekitUrl: 'ws://localhost:7880',
  roomName: 'jma3a_room_$_roomId',
  identity: 'me',
  role: role,
  expiresAt: DateTime.utc(2030),
);

RoomMemberEntity _member({
  String userId = 'me',
  bool isOwner = false,
  bool isModerator = false,
  bool isSpectator = false,
  bool isHiddenSpectator = false,
  bool isAway = false,
  bool isMuted = false,
  bool isGameMuted = false,
}) => RoomMemberEntity(
  userId: userId,
  displayName: 'Sara',
  seatOrder: 0,
  isReady: false,
  isOwner: isOwner,
  isModerator: isModerator,
  isSpectator: isSpectator,
  isHiddenSpectator: isHiddenSpectator,
  isAway: isAway,
  isMuted: isMuted,
  isGameMuted: isGameMuted,
);

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  theme: AppTheme.light(),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'APP_ENV=development'));

  late _MockRepository repo;
  late ValueNotifier<VoiceMembership?> membership;
  late List<_FakeAdapter> adapters;
  late VoiceRoomController controller;
  late AppLocalizations en;

  setUp(() async {
    repo = _MockRepository();
    membership = ValueNotifier(VoiceMembership.fromMember(_member()));
    adapters = [];
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

  void grants(VoiceRole role) => when(
    () => repo.fetchToken(roomId: any(named: 'roomId')),
  ).thenAnswer((_) async => _grant(role));

  void refuses(Failure f) =>
      when(() => repo.fetchToken(roomId: any(named: 'roomId'))).thenThrow(f);

  Future<void> pumpBar(WidgetTester tester) async {
    await tester.pumpWidget(_wrap(VoiceControlBar(controller: controller)));
  }

  Future<void> tapJoin(WidgetTester tester) async {
    await tester.tap(find.byKey(VoiceControlBar.joinKey));
    await tester.pumpAndSettle();
  }

  String issueText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(VoiceControlBar.issueKey)).data!;

  group('opt-in', () {
    testWidgets('idle shows only Join; nothing connects until tapped', (
      tester,
    ) async {
      await pumpBar(tester);
      expect(find.byKey(VoiceControlBar.joinKey), findsOneWidget);
      expect(find.text(en.voiceJoin), findsOneWidget);
      expect(find.byKey(VoiceControlBar.leaveKey), findsNothing);
      expect(find.byKey(VoiceControlBar.micKey), findsNothing);
      expect(find.byKey(VoiceControlBar.issueKey), findsNothing);
      verifyNever(() => repo.fetchToken(roomId: any(named: 'roomId')));
    });

    testWidgets('loading: connecting state with Leave, no mic', (tester) async {
      final gate = Completer<VoiceTokenGrant>();
      when(
        () => repo.fetchToken(roomId: any(named: 'roomId')),
      ).thenAnswer((_) => gate.future);
      await pumpBar(tester);
      await tester.tap(find.byKey(VoiceControlBar.joinKey));
      await tester.pump();

      expect(find.text(en.voiceConnecting), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(VoiceControlBar.leaveKey), findsOneWidget);
      expect(find.byKey(VoiceControlBar.micKey), findsNothing);

      await tester.tap(find.byKey(VoiceControlBar.leaveKey));
      await tester.pump();
      gate.complete(_grant(VoiceRole.speaker));
      await tester.pumpAndSettle();
      expect(find.byKey(VoiceControlBar.joinKey), findsOneWidget);
      expect(adapters, isEmpty);
    });
  });

  group('roles', () {
    for (final entry in {
      'host': _member(isOwner: true),
      'player': _member(),
      'moderator': _member(isModerator: true),
    }.entries) {
      testWidgets('${entry.key}: speaker, joins muted, mic toggles', (
        tester,
      ) async {
        membership.value = VoiceMembership.fromMember(entry.value);
        grants(VoiceRole.speaker);
        await pumpBar(tester);
        await tapJoin(tester);

        expect(find.text(en.voiceSpeaking), findsOneWidget);
        expect(find.byKey(VoiceControlBar.micKey), findsOneWidget);
        expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
        expect(find.byTooltip(en.voiceMicOff), findsOneWidget);
        expect(adapters.single.micCalls, isEmpty, reason: 'joins muted');

        await tester.tap(find.byKey(VoiceControlBar.micKey));
        await tester.pumpAndSettle();
        expect(adapters.single.micCalls, [true]);
        expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
        expect(find.byTooltip(en.voiceMicOn), findsOneWidget);

        await tester.tap(find.byKey(VoiceControlBar.micKey));
        await tester.pumpAndSettle();
        expect(adapters.single.micCalls, [true, false]);

        await tester.tap(find.byKey(VoiceControlBar.leaveKey));
        await tester.pumpAndSettle();
        expect(find.byKey(VoiceControlBar.joinKey), findsOneWidget);
        expect(adapters.single.disposeCount, 1);
      });
    }

    testWidgets('spectator: listener, never sees mic controls', (tester) async {
      membership.value = VoiceMembership.fromMember(_member(isSpectator: true));
      grants(VoiceRole.listener);
      await pumpBar(tester);
      await tapJoin(tester);

      expect(find.text(en.voiceListening), findsOneWidget);
      expect(find.text(en.voiceListenOnlyNotice), findsOneWidget);
      expect(find.byKey(VoiceControlBar.micKey), findsNothing);
      expect(find.byIcon(Icons.mic_rounded), findsNothing);
      expect(find.byIcon(Icons.mic_off_rounded), findsNothing);
    });

    testWidgets('moderator who is a spectator: still listen-only', (
      tester,
    ) async {
      membership.value = VoiceMembership.fromMember(
        _member(isModerator: true, isSpectator: true),
      );
      grants(VoiceRole.listener);
      await pumpBar(tester);
      await tapJoin(tester);
      expect(find.byKey(VoiceControlBar.micKey), findsNothing);
    });

    testWidgets('hidden spectator: no voice controls at all', (tester) async {
      membership.value = VoiceMembership.fromMember(
        _member(isSpectator: true, isHiddenSpectator: true),
      );
      await pumpBar(tester);
      expect(find.byKey(VoiceControlBar.joinKey), findsNothing);
      expect(find.byKey(VoiceControlBar.statusKey), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('no membership yet: renders nothing', (tester) async {
      membership.value = null;
      await pumpBar(tester);
      expect(find.byKey(VoiceControlBar.joinKey), findsNothing);
    });

    testWidgets('chat/game muted member can still join and speak', (
      tester,
    ) async {
      membership.value = VoiceMembership.fromMember(
        _member(isMuted: true, isGameMuted: true),
      );
      grants(VoiceRole.speaker);
      await pumpBar(tester);
      await tapJoin(tester);
      expect(find.byKey(VoiceControlBar.micKey), findsOneWidget);
    });
  });

  group('away / awaiting approval', () {
    testWidgets('Join disabled with an explanation', (tester) async {
      membership.value = VoiceMembership.fromMember(_member(isAway: true));
      await pumpBar(tester);
      final join = tester.widget<ButtonStyleButton>(
        find.byKey(VoiceControlBar.joinKey),
      );
      expect(join.onPressed, isNull);
      expect(issueText(tester), en.voiceAwayPendingApproval);
    });
  });

  group('errors', () {
    for (final entry in <String, (Failure, String Function(AppLocalizations))>{
      'unavailable': (
        const NotFoundFailure(code: voiceUnavailableCode),
        (l) => l.voiceUnavailable,
      ),
      'rate limited': (
        const RateLimitFailure(),
        (l) => l.voiceErrorRateLimited,
      ),
      'banned': (
        const ForbiddenFailure(code: 'banned_from_room'),
        (l) => l.voiceErrorNotAllowed,
      ),
      'room closed': (
        const ForbiddenFailure(code: 'room_closed'),
        (l) => l.voiceErrorNotAllowed,
      ),
      'offline': (const OfflineFailure(), (l) => l.noInternetConnection),
      'server error': (
        const ServerFailure(message: 'x'),
        (l) => l.voiceErrorFailed,
      ),
    }.entries) {
      testWidgets('${entry.key} -> message, back to Join', (tester) async {
        refuses(entry.value.$1);
        await pumpBar(tester);
        await tapJoin(tester);
        expect(issueText(tester), entry.value.$2(en));
        expect(find.byKey(VoiceControlBar.joinKey), findsOneWidget);
        expect(find.byKey(VoiceControlBar.micKey), findsNothing);
      });
    }

    testWidgets('microphone failure shows a message, stays connected', (
      tester,
    ) async {
      grants(VoiceRole.speaker);
      await pumpBar(tester);
      await tapJoin(tester);
      adapters.single.micError = Exception('denied');
      await tester.tap(find.byKey(VoiceControlBar.micKey));
      await tester.pumpAndSettle();
      expect(issueText(tester), en.voiceMicPermissionDenied);
      expect(find.byKey(VoiceControlBar.leaveKey), findsOneWidget);
      expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
    });
  });

  group('disconnected states', () {
    testWidgets('reconnecting shows progress, mic disabled', (tester) async {
      grants(VoiceRole.speaker);
      await pumpBar(tester);
      await tapJoin(tester);
      adapters.single.emit(const VoiceReconnecting());
      await tester.pump();
      expect(find.text(en.voiceReconnecting), findsOneWidget);
      final mic = tester.widget<IconButton>(find.byKey(VoiceControlBar.micKey));
      expect(mic.onPressed, isNull);
    });

    for (final entry
        in <String, (VoiceDisconnectReason, String Function(AppLocalizations))>{
          'connection lost': (
            VoiceDisconnectReason.connectionLost,
            (l) => l.voiceDisconnected,
          ),
          'joined elsewhere': (
            VoiceDisconnectReason.duplicateIdentity,
            (l) => l.voiceDisconnectedElsewhere,
          ),
        }.entries) {
      testWidgets('${entry.key} -> message and Rejoin', (tester) async {
        grants(VoiceRole.speaker);
        await pumpBar(tester);
        await tapJoin(tester);
        adapters.single.emit(VoiceDisconnected(entry.value.$1));
        await tester.pumpAndSettle();
        expect(issueText(tester), entry.value.$2(en));
        expect(find.text(en.voiceRejoin), findsOneWidget);
        expect(find.byKey(VoiceControlBar.micKey), findsNothing);
      });
    }

    testWidgets('speaker made spectator -> disconnected, rejoin to listen', (
      tester,
    ) async {
      grants(VoiceRole.speaker);
      await pumpBar(tester);
      await tapJoin(tester);
      membership.value = VoiceMembership.fromMember(_member(isSpectator: true));
      await tester.pumpAndSettle();
      expect(issueText(tester), en.voiceRoleChangedListenOnly);
      expect(find.text(en.voiceRejoin), findsOneWidget);
      expect(find.byKey(VoiceControlBar.micKey), findsNothing);

      grants(VoiceRole.listener);
      await tapJoin(tester);
      expect(find.text(en.voiceListening), findsOneWidget);
      expect(find.byKey(VoiceControlBar.micKey), findsNothing);
    });

    testWidgets('background timeout -> disconnected message', (tester) async {
      grants(VoiceRole.speaker);
      final c = VoiceRoomController(
        roomId: _roomId,
        repository: repo,
        membershipSource: membership,
        readMembership: () => membership.value,
        adapterFactory: () => _FakeAdapter(),
        observeAppLifecycle: false,
        backgroundDisconnectDelay: const Duration(seconds: 1),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(_wrap(VoiceControlBar(controller: c)));
      await tapJoin(tester);
      c.handleAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(VoiceControlBar.issueKey)).data,
        en.voiceDisconnected,
      );
      expect(find.text(en.voiceRejoin), findsOneWidget);
    });
  });

  group('localization', () {
    for (final locale in const [Locale('fr'), Locale('ar')]) {
      testWidgets('renders in ${locale.languageCode}', (tester) async {
        final l = await AppLocalizations.delegate.load(locale);
        grants(VoiceRole.speaker);
        await tester.pumpWidget(
          _wrap(VoiceControlBar(controller: controller), locale: locale),
        );
        expect(find.text(l.voiceJoin), findsOneWidget);
        await tapJoin(tester);
        expect(find.text(l.voiceSpeaking), findsOneWidget);
        expect(find.byTooltip(l.voiceMicOff), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('MemberTile speaking ring', () {
    BoxDecoration? avatarDecoration(WidgetTester tester) {
      final container = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(MemberTile),
              matching: find.byType(Container),
            ),
          )
          .firstWhere(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).shape == BoxShape.circle &&
                c.constraints?.maxWidth == 36,
          );
      return container.decoration as BoxDecoration?;
    }

    testWidgets('speaking draws a green ring', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MemberTile(
            member: _member(userId: 'u1'),
            isCurrentUser: false,
            canModerate: false,
            isSpeaking: true,
          ),
        ),
      );
      final border = avatarDecoration(tester)!.border! as Border;
      expect(border.top.color, AppColors.successGreen);
      expect(border.top.width, 2.5);
    });

    testWidgets('not speaking: no ring (default)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MemberTile(
            member: _member(userId: 'u1'),
            isCurrentUser: false,
            canModerate: false,
          ),
        ),
      );
      expect(avatarDecoration(tester)!.border, isNull);
    });

    testWidgets('ring is independent of the chat-mute badge', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MemberTile(
            member: _member(userId: 'u1', isMuted: true),
            isCurrentUser: false,
            canModerate: false,
            isSpeaking: true,
          ),
        ),
      );
      expect(find.byIcon(Icons.notifications_off_rounded), findsOneWidget);
      expect(avatarDecoration(tester)!.border, isNotNull);
      expect(find.byIcon(Icons.mic_rounded), findsNothing);
    });
  });
}
