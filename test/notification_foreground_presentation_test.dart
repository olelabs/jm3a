// Stage C1 — Realtime (CDC) notification presentation is foreground-only.
//
// NotificationProvider.handleRealtimeInsert is exactly what the
// notifications INSERT channel calls for every row. The row always lands
// in the in-app list; the in-app toast + local notification (sound) are
// presented only while Flutter's lifecycle state is `resumed` — otherwise
// OneSignal (the OS) presents the notification, so presenting here too
// would duplicate it. Lifecycle states are driven through the real test
// binding (the same WidgetsBinding.lifecycleState the app reads), and the
// local-notification plugin is replaced by a recorder.
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/services/notification_service.dart';
import 'package:jma3a/features/notifications/data/notification_repository.dart';
import 'package:jma3a/features/notifications/presentation/notification_provider.dart';

class _FakeNotificationRepository implements NotificationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LocalCall {
  _LocalCall(this.title, this.body, this.data);
  final String title;
  final String body;
  final Map<String, dynamic>? data;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => dotenv.testLoad(fileInput: ''));

  late List<_LocalCall> localCalls;
  late NotificationProvider provider;
  var seq = 0;

  Map<String, dynamic> row({
    String type = 'friend_request',
    Map<String, dynamic> data = const {'sender_id': 'user-2'},
  }) {
    seq += 1;
    return {
      'id': 'notif-$seq',
      'type': type,
      'title': {'en': 'New friend request', 'ar': 'طلب صداقة', 'fr': 'Demande'},
      'body': {'en': 'Sara wants to be friends'},
      'data': data,
      'created_at': DateTime.utc(2026, 9, 27, 10).toIso8601String(),
      'expires_at': DateTime.utc(2026, 9, 28, 10).toIso8601String(),
    };
  }

  void setLifecycle(AppLifecycleState state) =>
      binding.handleAppLifecycleStateChanged(state);

  setUp(() {
    localCalls = [];
    provider = NotificationProvider(
      notificationRepository: _FakeNotificationRepository(),
      showLocalNotification: ({required title, required body, data}) async {
        localCalls.add(_LocalCall(title, body, data));
      },
    );
    setLifecycle(AppLifecycleState.resumed);
  });

  tearDown(() => setLifecycle(AppLifecycleState.resumed));

  test('1. resumed: toast AND local notification are presented', () {
    provider.handleRealtimeInsert('user-1', row());

    expect(provider.toastQueue, hasLength(1));
    expect(localCalls, hasLength(1));
    expect(localCalls.single.body, 'Sara wants to be friends');
    expect(provider.notifications, hasLength(1));
    expect(provider.unreadCount, 1);
  });

  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.detached,
  ]) {
    test('2-4. ${state.name}: no toast, no local notification — but the row '
        'is still recorded in the in-app list', () {
      setLifecycle(state);
      provider.handleRealtimeInsert('user-1', row());

      expect(provider.toastQueue, isEmpty);
      expect(localCalls, isEmpty);
      expect(provider.notifications, hasLength(1));
      expect(provider.unreadCount, 1);
    });
  }

  test('5. back to resumed: the next notification is presented normally '
      '(the backgrounded one is not replayed)', () {
    setLifecycle(AppLifecycleState.inactive);
    setLifecycle(AppLifecycleState.hidden);
    setLifecycle(AppLifecycleState.paused);
    provider.handleRealtimeInsert('user-1', row());
    expect(localCalls, isEmpty);

    setLifecycle(AppLifecycleState.hidden);
    setLifecycle(AppLifecycleState.inactive);
    setLifecycle(AppLifecycleState.resumed);
    provider.handleRealtimeInsert('user-1', row());

    expect(provider.toastQueue, hasLength(1));
    expect(localCalls, hasLength(1));
    expect(provider.notifications, hasLength(2));
  });

  test('6. tap routing is unchanged: the local notification carries the '
      'same payload the tap handler routes on', () {
    provider.handleRealtimeInsert(
      'user-1',
      row(type: 'room_invite', data: const {'room_id': 'room-9', 'sender_id': 'user-2'}),
    );

    expect(localCalls.single.data, {'room_id': 'room-9', 'sender_id': 'user-2'});
    expect(provider.toastQueue.single.data['room_id'], 'room-9');
    // Same routing gate as before (NotificationService._routeFromPayload).
    expect(hasNavigableDestination('room_invite'), isTrue);
    expect(hasNavigableDestination('friend_request'), isTrue);
    expect(hasNavigableDestination('system'), isFalse);
  });

  test('7. showsInApp preference is still respected while foregrounded', () {
    provider.debugSetPreferences(const [
      NotificationPreference(type: NotificationType.friendRequest, inApp: false, push: true),
    ]);

    provider.handleRealtimeInsert('user-1', row());
    expect(provider.toastQueue, isEmpty);
    expect(localCalls, isEmpty);
    expect(provider.notifications, hasLength(1));

    provider.handleRealtimeInsert('user-1', row(type: 'follow'));
    expect(provider.toastQueue, hasLength(1)); // other types unaffected
    expect(localCalls, hasLength(1));
  });

  test('a redundant chat notification is still never presented, and pack '
      'entitlement refresh still works while backgrounded', () {
    provider.setActiveChatRoom('room-1');
    provider.handleRealtimeInsert(
      'user-1',
      row(type: 'room_chat_message', data: const {'room_id': 'room-1'}),
    );
    expect(provider.toastQueue, isEmpty);
    expect(localCalls, isEmpty);

    setLifecycle(AppLifecycleState.paused);
    provider.handleRealtimeInsert('user-1', row(type: 'pack_granted', data: const {'pack_id': 'p1'}));
    expect(provider.pendingEntitlementNotification?.data['pack_id'], 'p1');
    expect(localCalls, isEmpty);
  });
}
