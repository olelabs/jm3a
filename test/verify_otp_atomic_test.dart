// Bug 2 fix — signup OTP must never lose its continuation destination.
//
// Root cause it fixes: OTP verification alone always yields
// has_password=false for a brand-new signup. If that intermediate state
// were ever broadcast on its own (verify, THEN separately call
// setPassword from the screen), a listener reacting to it immediately —
// before the screen's own follow-up call ever ran — could unmount the
// OTP screen mid-flight and lose track of the in-progress signup.
// AuthProvider.verifyOtp now applies pendingPassword atomically, in the
// SAME call, before ever notifying listeners, so nothing ever observes
// that intermediate state.
//
// Also covers the "interrupted signup / returning user" requirement:
// onboarding-completeness is derived fresh from persisted profile
// fields on every session restore — never from an in-memory flag — so
// a user who closes the app mid-signup and logs back in with their
// password resumes onboarding, never Home.
//
// Also guards the "setup-profile 401 right after signup" regression at
// the one layer this file's mocking style CAN observe it at: setPassword
// revokes the session verifyOtp just established (Supabase's own
// behavior on any password change — see AuthRepository.setPassword's
// own doc) and returns a freshly-minted replacement, which
// AuthProvider.verifyOtp must adopt as its OWN current session rather
// than keeping the stale pre-password one it already had in hand — the
// "new signup success" test below asserts auth.session is exactly the
// session setPassword returned. AuthRepository's own Supabase-facing
// setSession(...) call (which is what actually keeps ApiClient's
// interceptor in sync, since it reads Supabase.instance.client.auth.
// currentSession live) has no live/fake backend to run against in this
// test suite and is mocked away here like everywhere else in this file
// — that half of the fix is regression-tested at the backend instead
// (jma3a-api/tests/passwordAuth.test.js — "returns a freshly-minted
// session... since updateUserById revokes the caller's current one"),
// which is where the actual bug was: the old /v1/auth/set-password
// response never included the new tokens at all.
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:jma3a/core/errors/failures.dart';
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

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '');
    registerFallbackValue('');
  });

  late _MockAuthRepository repo;
  late AuthProvider auth;

  setUp(() {
    repo = _MockAuthRepository();
    final secureStorage = _MockSecureStorageService();
    when(() => repo.authStateStream).thenAnswer((_) => const Stream.empty());
    auth = AuthProvider(authRepository: repo, secureStorage: secureStorage);
  });

  group('AuthProvider.verifyOtp — atomic pendingPassword application', () {
    const newSignupUser = UserEntity(
      id: 'new-user',
      email: 'new@example.com',
      hasPassword: false,
    );

    test(
      'new signup success: has_password becomes true, needsOnboarding stays true, '
      'AND AuthProvider adopts the POST-password session (not the stale pre-password one) — item 8/9/10/11',
      () async {
        when(() => repo.verifyOtp('new@example.com', '123456')).thenAnswer(
          (_) async => (_fakeSession(newSignupUser.id), newSignupUser),
        );
        // Distinct token from _fakeSession(newSignupUser.id) above —
        // simulates the backend minting a genuinely different session
        // once setPassword's updateUserById call revokes the one
        // verifyOtp just established (see AuthRepository.setPassword's
        // own doc for why). This is the regression: AuthProvider must
        // end up holding THIS session, not the one from verifyOtp.
        final postPasswordSession = Session(
          accessToken: 'post-password-access-token',
          tokenType: 'bearer',
          refreshToken: 'post-password-refresh-token',
          user: User(
            id: newSignupUser.id,
            appMetadata: const {},
            userMetadata: const {},
            aud: 'authenticated',
            createdAt: DateTime(2026).toIso8601String(),
          ),
        );
        when(() => repo.setPassword('Str0ngPass', 'Str0ngPass'))
            .thenAnswer((_) async => postPasswordSession);

        final result = await auth.verifyOtp(
          'new@example.com',
          '123456',
          pendingPassword: 'Str0ngPass',
        );

        expect(result.success, isTrue);
        expect(result.otpVerified, isTrue);
        expect(result.passwordApplied, isTrue);
        expect(auth.isLoggedIn, isTrue);
        expect(auth.currentUser?.hasPassword, isTrue);
        // This brand-new account has no username/displayName yet —
        // onboarding must still be required. Home must never be
        // reachable from here.
        expect(auth.needsOnboarding, isTrue);
        // THE regression this test guards: AuthProvider.session must be
        // the fresh, post-password session setPassword returned — not
        // the stale one verifyOtp originally established (which is
        // already revoked server-side by the time this call returns).
        // Any subsequent authenticated request (e.g. onboarding's own
        // POST /setup-profile) reads its token from whatever Supabase's
        // session currently is, which AuthRepository.setPassword already
        // resynchronizes independently — this assertion additionally
        // locks in that AuthProvider's own session field tracks the same
        // truth, deterministically, not via eventual stream consistency.
        expect(auth.session?.accessToken, 'post-password-access-token');
      },
    );

    test(
      'new signup: wrong/expired OTP never reaches the password step — otpVerified is false',
      () async {
        when(() => repo.verifyOtp(any(), any())).thenThrow(
          const OtpFailure(message: 'Incorrect code.', code: 'otp_invalid'),
        );

        final result = await auth.verifyOtp(
          'new@example.com',
          '000000',
          pendingPassword: 'Str0ngPass',
        );

        expect(result.success, isFalse);
        expect(result.otpVerified, isFalse);
        verifyNever(() => repo.setPassword(any(), any()));
        expect(auth.isLoggedIn, isFalse);
      },
    );

    test(
      'new signup: OTP verifies but the password step fails — session is rolled back entirely, never left half-finished',
      () async {
        when(() => repo.verifyOtp('new@example.com', '123456')).thenAnswer(
          (_) async => (_fakeSession(newSignupUser.id), newSignupUser),
        );
        when(() => repo.setPassword(any(), any())).thenThrow(
          const ServerFailure(message: 'Failed to set password.'),
        );
        when(() => repo.signOut()).thenAnswer((_) async {});

        final result = await auth.verifyOtp(
          'new@example.com',
          '123456',
          pendingPassword: 'Str0ngPass',
        );

        expect(result.success, isFalse);
        expect(result.otpVerified, isTrue); // the code itself was correct
        expect(result.passwordApplied, isFalse);
        // Brief: "must not be allowed to continue into the authenticated
        // onboarding flow" — verified by a full rollback, not a
        // half-authenticated has_password=false session.
        expect(auth.isLoggedIn, isFalse);
        expect(auth.currentUser, isNull);
        verify(() => repo.signOut()).called(1);
      },
    );

    test(
      'Settings Update Password flow: OTP verifies but re-applying fails — existing password is untouched, session still committed',
      () async {
        const alreadyHasPassword = UserEntity(
          id: 'existing-user',
          email: 'existing@example.com',
          username: 'existing',
          displayName: 'Existing User',
          hasPassword: true,
        );
        when(() => repo.verifyOtp('existing@example.com', '123456')).thenAnswer(
          (_) async => (_fakeSession(alreadyHasPassword.id), alreadyHasPassword),
        );
        when(() => repo.setPassword(any(), any())).thenThrow(
          const ServerFailure(message: 'Failed to set password.'),
        );

        final result = await auth.verifyOtp(
          'existing@example.com',
          '123456',
          pendingPassword: 'NewStr0ngPass',
        );

        expect(result.success, isFalse);
        expect(result.otpVerified, isTrue);
        // Unlike the brand-new-signup case, this account already had a
        // real password before this attempt — never sign it out or
        // discard the session over a failed CHANGE attempt.
        expect(auth.isLoggedIn, isTrue);
        expect(auth.currentUser?.hasPassword, isTrue);
        verifyNever(() => repo.signOut());
      },
    );

    test('a normal OTP verification without pendingPassword is unaffected', () async {
      const legacyUser = UserEntity(
        id: 'legacy',
        email: 'legacy@example.com',
        username: 'legacy',
        displayName: 'Legacy',
        hasPassword: false,
      );
      when(() => repo.verifyOtp('legacy@example.com', '123456')).thenAnswer(
        (_) async => (_fakeSession(legacyUser.id), legacyUser),
      );

      final result = await auth.verifyOtp('legacy@example.com', '123456');

      expect(result.success, isTrue);
      expect(result.passwordApplied, isFalse);
      verifyNever(() => repo.setPassword(any(), any()));
      expect(auth.currentUser?.hasPassword, isFalse);
    });
  });

  group('Interrupted signup / returning user — resume, never Home', () {
    test(
      'account created, OTP verified, password set, but profile never finished: '
      'the next OTP login still reports needsOnboarding=true, never "ready" — item H',
      () async {
        // Simulates: user signed up, verified OTP, set a password, then
        // closed the app before finishing onboarding. They come back and
        // log in the normal way — identifier -> OTP, exactly like every
        // other account, password or no password — and this fresh
        // verifyOtp call re-derives state from the (simulated) persisted
        // profile row, not from any in-memory flag left over from the
        // earlier session, since this is a fresh AuthProvider instance
        // with no memory of the earlier signup at all.
        const interruptedUser = UserEntity(
          id: 'interrupted-user',
          email: 'interrupted@example.com',
          hasPassword: true, // password step completed and persisted
          // username/displayName intentionally left unset — profile
          // creation was never finished.
        );
        when(() => repo.verifyOtp('interrupted@example.com', '123456'))
            .thenAnswer(
          (_) async => (_fakeSession(interruptedUser.id), interruptedUser),
        );

        final result = await auth.verifyOtp(
          'interrupted@example.com',
          '123456',
        );

        expect(result.success, isTrue);
        expect(auth.isLoggedIn, isTrue);
        // The critical assertion: never "ready" for Home while required
        // profile information is still missing, regardless of
        // has_password.
        expect(auth.needsOnboarding, isTrue);
      },
    );

    test(
      'a fresh app start (new AuthProvider) restoring an interrupted account also reports needsOnboarding=true — never derived from an in-memory flag',
      () async {
        const interruptedUser = UserEntity(
          id: 'interrupted-user-2',
          email: 'interrupted2@example.com',
          hasPassword: true,
        );
        when(() => repo.restoreSession()).thenAnswer(
          (_) async => (_fakeSession(interruptedUser.id), interruptedUser),
        );

        // A brand-new AuthProvider — nothing carried over in memory from
        // any earlier session, exactly like a real app cold start.
        final freshAuth = AuthProvider(
          authRepository: repo,
          secureStorage: _MockSecureStorageService(),
        );
        await freshAuth.initialize();

        expect(freshAuth.isLoggedIn, isTrue);
        expect(freshAuth.needsOnboarding, isTrue);
      },
    );
  });
}
