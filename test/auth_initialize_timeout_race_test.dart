// Splash-flash fix regression (real-device report): for an already
// logged-in user, Splash sometimes disappeared too early and the Login
// screen flashed briefly before landing on the authenticated Home.
//
// Root cause (see AuthProvider.initialize()'s own doc comment): the
// method used to race TWO independent async paths against the same
// state — a bare `Timer(const Duration(seconds: 5), ...)` that forced
// `_isInitializing = false` unconditionally, and the actual
// `restoreSession()` await, which does a real network profile fetch and
// can legitimately take longer than 5s on a slow/real-device network.
// If the timer won the race, the router read "not initializing, not
// logged in" as FINAL and redirected Splash -> Login — then bounced
// back to Home a moment later once restoreSession() actually resolved
// with the real (logged-in) result. The fix wraps the SAME awaited
// future in `.timeout()` instead of racing it with a separate Timer, so
// `_isInitializing` only ever flips to false ONCE, atomically together
// with whichever result (real or fallback) actually won.
//
// This test proves the property that matters: no matter how long
// restoreSession() takes (as long as it completes before the 10s hard
// cutoff), AuthProvider must never report "not initializing" before the
// real result is in hand — there is no longer a second, independent
// clock that can force that state early. Uses fake_async to advance
// time deterministically without a real multi-second wait.
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:jma3a/core/providers/auth_provider.dart';
import 'package:jma3a/core/storage/secure_storage_service.dart';
import 'package:jma3a/features/auth/data/auth_repository.dart';
import 'package:jma3a/features/auth/domain/entities/user_entity.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

Session _fakeSession(String userId) => Session(
  accessToken: 'access-$userId',
  tokenType: 'bearer',
  refreshToken: 'refresh-$userId',
  user: User(
    id: userId,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: DateTime(2026).toIso8601String(),
  ),
);

// Explicit return-type annotation matters here: AuthRepository.restoreSession
// is declared to return Future<(Session?, UserEntity?)> (nullable record
// fields), but a record literal built from non-null locals infers the
// NARROWER Future<(Session, UserEntity)> unless the enclosing function's
// return type forces the nullable one — and Future.timeout()'s generic
// type parameter is bound to the Future's own (reified) runtime type
// argument, not the interface's static declaration, so a mismatch here
// would make .timeout() itself throw a spurious TypeError in the fake
// slow/fast-restore tests below.
Future<(Session?, UserEntity?)> _slowRestore(
  Session session,
  UserEntity user,
  Duration delay,
) async {
  await Future<void>.delayed(delay);
  return (session, user);
}

Future<(Session?, UserEntity?)> _fastRestore(
  Session session,
  UserEntity user,
) async => (session, user);

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '');
  });

  test('a slow (but eventually successful) restoreSession — e.g. 7s, '
      'realistic on a slow real-device network — never has isInitializing '
      'flip to false before the real result lands: there is no longer a '
      'separate, shorter timer racing it', () {
    fakeAsync((async) {
      final repo = _MockAuthRepository();
      when(() => repo.authStateStream).thenAnswer((_) => const Stream.empty());
      const user = UserEntity(id: 'u1', email: 'a@b.com', hasPassword: true);
      final session = _fakeSession('u1');

      when(() => repo.restoreSession()).thenAnswer(
        (_) => _slowRestore(session, user, const Duration(seconds: 7)),
      );

      final auth = AuthProvider(
        authRepository: repo,
        secureStorage: _MockSecureStorageService(),
      );

      auth.initialize();

      async.elapse(const Duration(seconds: 4));
      expect(auth.isInitializing, isTrue);
      expect(auth.isLoggedIn, isFalse);

      // Past where the OLD bug's 5s timer would already have forced
      // isInitializing=false with isLoggedIn still false — exactly the
      // state that used to leak to the router and cause the Login
      // flash. Must still be initializing.
      async.elapse(const Duration(seconds: 2)); // now at 6s total
      expect(auth.isInitializing, isTrue);
      expect(auth.isLoggedIn, isFalse);

      async.elapse(const Duration(seconds: 2)); // now at 8s, past the 7s result
      expect(auth.isInitializing, isFalse);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser, user);
    });
  });

  test('restoreSession() that genuinely hangs forever is force-completed at '
      'the 10s hard cutoff, as logged out (fallback) — not stuck forever, '
      'and not forced early either', () {
    fakeAsync((async) {
      final repo = _MockAuthRepository();
      when(() => repo.authStateStream).thenAnswer((_) => const Stream.empty());
      when(
        () => repo.restoreSession(),
      ).thenAnswer((_) => Completer<(Session?, UserEntity?)>().future);

      final auth = AuthProvider(
        authRepository: repo,
        secureStorage: _MockSecureStorageService(),
      );

      auth.initialize();

      async.elapse(const Duration(seconds: 9));
      expect(auth.isInitializing, isTrue);

      async.elapse(const Duration(seconds: 2)); // now at 11s
      expect(auth.isInitializing, isFalse);
      expect(auth.isLoggedIn, isFalse);
    });
  });

  test('a fast restoreSession (normal case) still completes correctly, '
      'unaffected by the timeout mechanism', () {
    fakeAsync((async) {
      final repo = _MockAuthRepository();
      when(() => repo.authStateStream).thenAnswer((_) => const Stream.empty());
      const user = UserEntity(id: 'u2', email: 'c@d.com', hasPassword: true);
      final session = _fakeSession('u2');
      when(
        () => repo.restoreSession(),
      ).thenAnswer((_) => _fastRestore(session, user));

      final auth = AuthProvider(
        authRepository: repo,
        secureStorage: _MockSecureStorageService(),
      );

      auth.initialize();
      async.flushMicrotasks();

      expect(auth.isInitializing, isFalse);
      expect(auth.isLoggedIn, isTrue);
    });
  });
}
