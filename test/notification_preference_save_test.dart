// Notification settings: a toggle must only change once the server stored
// it, and a failed save must be reported (it used to escape as an
// unhandled async error from the Switch callback).

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/errors/failures.dart';
import 'package:jma3a/features/notifications/data/notification_repository.dart';
import 'package:jma3a/features/notifications/domain/notification_entity.dart';
import 'package:jma3a/features/notifications/presentation/notification_provider.dart';

class _FakeRepo implements NotificationRepository {
  bool fail = false;
  final saved = <(NotificationType, bool, bool)>[];

  @override
  Future<void> updatePreference({
    required String userId,
    required NotificationType type,
    required bool inApp,
    required bool push,
  }) async {
    if (fail) throw const NetworkFailure();
    saved.add((type, inApp, push));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _Provider extends NotificationProvider {
  _Provider(NotificationRepository repo)
    : super(
        notificationRepository: repo,
        showLocalNotification: ({required title, required body, data}) async {},
      );

  @override
  void onUserLoggedIn(String userId) {}
}

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  const pref = NotificationPreference(
    type: NotificationType.friendRequest,
    inApp: true,
    push: true,
  );

  test('successful save updates the toggle state', () async {
    final repo = _FakeRepo();
    final p = _Provider(repo)
      ..onAuthChanged('u')
      ..debugSetPreferences([pref]);
    final ok = await p.updatePreference(
      type: NotificationType.friendRequest,
      inApp: true,
      push: false,
    );
    expect(ok, isTrue);
    expect(repo.saved.single, (NotificationType.friendRequest, true, false));
    expect(p.pushEnabled(NotificationType.friendRequest), isFalse);
  });

  test('failed save returns false and leaves the toggle unchanged', () async {
    final repo = _FakeRepo()..fail = true;
    final p = _Provider(repo)
      ..onAuthChanged('u')
      ..debugSetPreferences([pref]);
    final ok = await p.updatePreference(
      type: NotificationType.friendRequest,
      inApp: true,
      push: false,
    );
    expect(ok, isFalse);
    expect(p.pushEnabled(NotificationType.friendRequest), isTrue);
  });

  test('signed out → nothing saved', () async {
    final repo = _FakeRepo();
    expect(
      await _Provider(repo).updatePreference(
        type: NotificationType.friendRequest,
        inApp: false,
        push: false,
      ),
      isFalse,
    );
    expect(repo.saved, isEmpty);
  });
}
