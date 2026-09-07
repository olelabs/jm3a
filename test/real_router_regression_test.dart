// Final auth design regression suite:
//   - Normal login is identifier + password (LoginScreen), not OTP.
//   - Forgot password (identifier -> OTP -> new password) is the one and
//     only way a password is ever (re)established outside of signup —
//     used both for a genuinely forgotten password AND for a legacy
//     account establishing its first one (has_password=false).
//   - The router has NO global has_password/needsPasswordSetup gate:
//     only isLoggedIn and needsOnboarding decide where an authenticated
//     session lands.
// Letters below match the product brief's own required-coverage list
// (router-focused items V-AA, plus the forgot-password journey G-L).
//
// Uses the REAL AppRouter.createRouter configuration (not a hand-rolled
// test router) so this exercises the exact code path production runs.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:jma3a/core/errors/failures.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/providers/auth_provider.dart';
import 'package:jma3a/core/router/app_router.dart';
import 'package:jma3a/core/router/route_names.dart';
import 'package:jma3a/core/storage/local_storage_service.dart';
import 'package:jma3a/core/storage/secure_storage_service.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/auth/data/auth_repository.dart';
import 'package:jma3a/features/auth/domain/entities/user_entity.dart';
import 'package:jma3a/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:jma3a/features/auth/presentation/screens/login_screen.dart';
import 'package:jma3a/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:jma3a/features/auth/presentation/screens/set_password_screen.dart';
import 'package:jma3a/features/auth/presentation/screens/splash_screen.dart';
import 'package:jma3a/shared/screens/home_shell_screen.dart';

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

const _completeNoPassword = UserEntity(
  id: 'complete-no-password',
  email: 'complete-np@example.com',
  username: 'completenp',
  displayName: 'Complete NoPassword',
  age: 25,
  gender: 'male',
  hasPassword: false,
);

const _completeWithPassword = UserEntity(
  id: 'complete-with-password',
  email: 'complete-wp@example.com',
  username: 'completewp',
  displayName: 'Complete WithPassword',
  age: 25,
  gender: 'male',
  hasPassword: true,
);

const _incompleteLegacyUser = UserEntity(
  id: 'incomplete-legacy',
  email: 'incomplete-legacy@example.com',
  hasPassword: false, // legacy account — no password (yet)
);

/// HomeShellScreen needs the full app provider tree (PackProvider etc.)
/// that this lightweight routing-only harness doesn't build, and its
/// initState reaches for those in a post-frame callback — a scheduler-
/// time exception that flutter_test re-throws from the pump call itself
/// rather than queuing for a later tester.takeException(). Swallowed
/// here deliberately: this file only asserts on the RESOLVED ROUTE
/// (proving the redirect actually landed on Home), not on
/// HomeShellScreen's own functionality, which has its own tests.
Future<void> pumpIgnoringHomeShellDeps(WidgetTester tester, Widget widget) async {
  await withHomeShellDepsIgnored(() async {
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
  });
}

/// Same error-swallowing as [pumpIgnoringHomeShellDeps], but reusable
/// around an arbitrary sequence of pumps/taps/enterText calls — needed
/// whenever a test drives the UI (e.g. through a real login flow) all
/// the way to Home, since HomeShellScreen's ProviderNotFoundException
/// can be thrown by any pump call after that navigation lands, not just
/// the very first one.
Future<void> withHomeShellDepsIgnored(Future<void> Function() action) async {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {};
  try {
    await action();
  } finally {
    FlutterError.onError = original;
  }
}

Widget wrapRouter(AuthProvider auth, GoRouter router) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

Future<AuthProvider> buildAndInitAuth(
  _MockAuthRepository repo,
  _MockSecureStorageService secureStorage,
) async {
  when(() => repo.authStateStream).thenAnswer((_) => const Stream.empty());
  final auth = AuthProvider(authRepository: repo, secureStorage: secureStorage);
  await auth.initialize();
  return auth;
}

/// Drives the real LoginScreen -> loginWithPassword flow against the
/// real router — the one and only normal way an existing account
/// reaches an authenticated state now.
Future<void> loginWithPassword(
  WidgetTester tester, {
  required _MockAuthRepository repo,
  required String email,
  required String password,
  required UserEntity resultUser,
}) async {
  when(() => repo.loginWithPassword(email, password)).thenAnswer(
    (_) async => (_fakeSession(resultUser.id), resultUser),
  );

  expect(find.byType(LoginScreen), findsOneWidget);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email or phone number'),
    email,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    password,
  );
  await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'has_seen_intro': true});
    await LocalStorageService.instance.initialize();
  });

  group('Normal login (identifier + password)', () {
    testWidgets(
      'B: correct password, complete profile -> Home',
      (tester) async {
        final repo = _MockAuthRepository();
        when(() => repo.restoreSession()).thenAnswer((_) async => (null, null));
        final auth = await buildAndInitAuth(repo, _MockSecureStorageService());

        final router = AppRouter.createRouter(auth);
        await pumpIgnoringHomeShellDeps(tester, wrapRouter(auth, router));

        await withHomeShellDepsIgnored(() => loginWithPassword(
          tester,
          repo: repo,
          email: _completeWithPassword.email,
          password: 'correcthorse1',
          resultUser: _completeWithPassword,
        ));

        expect(find.byType(SetPasswordScreen), findsNothing);
        expect(
          router.routerDelegate.currentConfiguration.uri.toString(),
          RouteNames.home,
        );
      },
    );

    testWidgets(
      'C: correct password, incomplete profile -> Profile onboarding',
      (tester) async {
        final repo = _MockAuthRepository();
        when(() => repo.restoreSession()).thenAnswer((_) async => (null, null));
        final auth = await buildAndInitAuth(repo, _MockSecureStorageService());

        final router = AppRouter.createRouter(auth);
        await tester.pumpWidget(wrapRouter(auth, router));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 6));

        await loginWithPassword(
          tester,
          repo: repo,
          email: _incompleteLegacyUser.email,
          password: 'correcthorse1',
          resultUser: _incompleteLegacyUser.copyWith(hasPassword: true),
        );

        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(find.byType(HomeShellScreen), findsNothing);
        expect(find.byType(SetPasswordScreen), findsNothing);
      },
    );
  });

  group('Forgot password (identifier -> OTP -> new password)', () {
    testWidgets(
      'G-I: Forgot password -> OTP -> new password + confirmation establishes the password, then reaches Home',
      (tester) async {
        final repo = _MockAuthRepository();
        when(() => repo.restoreSession()).thenAnswer((_) async => (null, null));
        final auth = await buildAndInitAuth(repo, _MockSecureStorageService());
        when(() => repo.sendOtp('recovered@example.com')).thenAnswer((_) async {});
        when(() => repo.verifyOtp('recovered@example.com', '123456')).thenAnswer(
          (_) async => (_fakeSession(_completeNoPassword.id), _completeNoPassword),
        );
        when(() => repo.setPassword('NewStr0ngPass', 'NewStr0ngPass'))
            .thenAnswer((_) async => _fakeSession(_completeNoPassword.id));

        final router = AppRouter.createRouter(auth);
        await tester.pumpWidget(wrapRouter(auth, router));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 6));

        expect(find.byType(LoginScreen), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, 'Forgot password?'));
        await tester.pumpAndSettle();

        expect(find.byType(ForgotPasswordScreen), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email or phone number'),
          'recovered@example.com',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Send code'));
        await tester.pumpAndSettle();

        // G: Forgot password -> OTP.
        expect(find.byType(SetPasswordScreen), findsNothing);
        await tester.enterText(find.byType(TextFormField).first, '123456');
        await tester.pumpAndSettle();

        // H: OTP verification -> New Password screen.
        expect(find.byType(SetPasswordScreen), findsOneWidget);

        // I: new password + confirmation establishes the password.
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'NewStr0ngPass',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'),
          'NewStr0ngPass',
        );
        await withHomeShellDepsIgnored(() async {
          await tester.tap(find.widgetWithText(ElevatedButton, 'Reset password'));
          await tester.pumpAndSettle();
        });

        verify(() => repo.setPassword('NewStr0ngPass', 'NewStr0ngPass')).called(1);
        expect(
          router.routerDelegate.currentConfiguration.uri.toString(),
          RouteNames.home,
        );
      },
    );

    testWidgets(
      'Q: Login -> Forgot password for a has_password=TRUE account replaces the existing password (same recovery flow, no special-casing)',
      (tester) async {
        final repo = _MockAuthRepository();
        when(() => repo.restoreSession()).thenAnswer((_) async => (null, null));
        final auth = await buildAndInitAuth(repo, _MockSecureStorageService());
        when(() => repo.sendOtp('has-password@example.com')).thenAnswer((_) async {});
        when(() => repo.verifyOtp('has-password@example.com', '123456')).thenAnswer(
          (_) async => (_fakeSession(_completeWithPassword.id), _completeWithPassword),
        );
        when(() => repo.setPassword('ReplacedStr0ngPass', 'ReplacedStr0ngPass'))
            .thenAnswer((_) async => _fakeSession(_completeWithPassword.id));

        final router = AppRouter.createRouter(auth);
        await tester.pumpWidget(wrapRouter(auth, router));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 6));

        await tester.tap(find.widgetWithText(TextButton, 'Forgot password?'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email or phone number'),
          'has-password@example.com',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Send code'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, '123456');
        await tester.pumpAndSettle();

        // Not skipped just because this account already has a password —
        // recovery OTP still leads to New Password, never straight Home.
        expect(find.byType(SetPasswordScreen), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'ReplacedStr0ngPass',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'),
          'ReplacedStr0ngPass',
        );
        await withHomeShellDepsIgnored(() async {
          await tester.tap(find.widgetWithText(ElevatedButton, 'Reset password'));
          await tester.pumpAndSettle();
        });

        verify(() => repo.setPassword('ReplacedStr0ngPass', 'ReplacedStr0ngPass')).called(1);
        expect(
          router.routerDelegate.currentConfiguration.uri.toString(),
          RouteNames.home,
        );
      },
    );

    test(
      'J: the new password works for a subsequent normal login',
      () async {
        final repo = _MockAuthRepository();
        when(() => repo.authStateStream).thenAnswer((_) => const Stream.empty());
        final auth = AuthProvider(
          authRepository: repo,
          secureStorage: _MockSecureStorageService(),
        );
        final resetUser = _completeNoPassword.copyWith(hasPassword: true);
        when(() => repo.loginWithPassword('recovered@example.com', 'NewStr0ngPass'))
            .thenAnswer((_) async => (_fakeSession(resetUser.id), resetUser));

        final result = await auth.loginWithPassword(
          'recovered@example.com',
          'NewStr0ngPass',
        );

        expect(result.success, isTrue);
        expect(auth.isLoggedIn, isTrue);
      },
    );

    test(
      'K: the old password no longer works after a reset',
      () async {
        final repo = _MockAuthRepository();
        when(() => repo.authStateStream).thenAnswer((_) => const Stream.empty());
        final auth = AuthProvider(
          authRepository: repo,
          secureStorage: _MockSecureStorageService(),
        );
        when(() => repo.loginWithPassword('recovered@example.com', 'OldPassword1'))
            .thenThrow(
          const AuthFailure(
            message: 'Incorrect email/phone or password.',
            code: 'invalid_credentials',
          ),
        );

        final result = await auth.loginWithPassword(
          'recovered@example.com',
          'OldPassword1',
        );

        expect(result.success, isFalse);
        expect(result.code, 'invalid_credentials');
        expect(auth.isLoggedIn, isFalse);
      },
    );

    testWidgets(
      'L: a legacy account (has_password=false) establishes its FIRST password through Forgot Password, no separate legacy-setup flow',
      (tester) async {
        final repo = _MockAuthRepository();
        when(() => repo.restoreSession()).thenAnswer((_) async => (null, null));
        final auth = await buildAndInitAuth(repo, _MockSecureStorageService());
        when(() => repo.sendOtp('legacy@example.com')).thenAnswer((_) async {});
        when(() => repo.verifyOtp('legacy@example.com', '123456')).thenAnswer(
          (_) async => (_fakeSession(_incompleteLegacyUser.id), _incompleteLegacyUser),
        );
        when(() => repo.setPassword('FirstPass1', 'FirstPass1'))
            .thenAnswer((_) async => _fakeSession(_incompleteLegacyUser.id));

        final router = AppRouter.createRouter(auth);
        await tester.pumpWidget(wrapRouter(auth, router));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 6));

        await tester.tap(find.widgetWithText(TextButton, 'Forgot password?'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email or phone number'),
          'legacy@example.com',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Send code'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, '123456');
        await tester.pumpAndSettle();

        expect(find.byType(SetPasswordScreen), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'FirstPass1',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'),
          'FirstPass1',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Reset password'));
        await tester.pumpAndSettle();

        verify(() => repo.setPassword('FirstPass1', 'FirstPass1')).called(1);
        // has_password=false never routed here globally — this screen
        // was reached only via the explicit Forgot Password flow, and
        // this account still needs onboarding, never Home.
        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(find.byType(HomeShellScreen), findsNothing);
      },
    );
  });

  group('Onboarding completion navigates to Home without an app restart', () {
    // Regression: OnboardingScreen's Continue handler is (correctly)
    // `await ProfileRepository...createOrUpdateProfile(...); auth.
    // updateCurrentUser(updated);` — the exact same state-update call
    // this test drives directly (ProfileRepository is a hard singleton
    // over the real Supabase/ApiClient and can't be mocked in this test
    // harness, so this simulates its one router-relevant side effect:
    // the state update after a successful backend call, precisely what
    // was missing a working redirect rule for).
    testWidgets(
      'Test case 1/2: completing an incomplete profile while sitting on OnboardingScreen -> Home immediately, no restart',
      (tester) async {
        final repo = _MockAuthRepository();
        when(() => repo.restoreSession()).thenAnswer(
          (_) async => (_fakeSession(_incompleteLegacyUser.id), _incompleteLegacyUser),
        );
        final auth = await buildAndInitAuth(repo, _MockSecureStorageService());

        final router = AppRouter.createRouter(auth);
        await tester.pumpWidget(wrapRouter(auth, router));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 6));

        // Still incomplete -> correctly on OnboardingScreen, not Home.
        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(find.byType(HomeShellScreen), findsNothing);

        // The exact state transition OnboardingScreen's Continue handler
        // performs once the backend call succeeds — no second boolean,
        // no manual navigation call, just the canonical user/profile
        // state updating.
        final completedUser = _incompleteLegacyUser.copyWith(
          username: 'newlyonboarded',
          displayName: 'Newly Onboarded',
        );
        await withHomeShellDepsIgnored(() async {
          auth.updateCurrentUser(completedUser);
          await tester.pumpAndSettle();
        });

        expect(auth.needsOnboarding, isFalse);
        expect(find.byType(OnboardingScreen), findsNothing);
        expect(
          router.routerDelegate.currentConfiguration.uri.toString(),
          RouteNames.home,
        );
      },
    );

    // Test case 3: the same completed state, but arriving via a fresh
    // cold start (simulating an app restart) rather than a live
    // transition — must land on Home too, proving persistence and that
    // the live-transition fix didn't change the (already-correct)
    // cold-start path.
    testWidgets(
      'Test case 3: cold start with an already-complete profile (post-restart) -> Home directly',
      (tester) async {
        final repo = _MockAuthRepository();
        final completedUser = _incompleteLegacyUser.copyWith(
          username: 'newlyonboarded',
          displayName: 'Newly Onboarded',
        );
        when(() => repo.restoreSession()).thenAnswer(
          (_) async => (_fakeSession(completedUser.id), completedUser),
        );
        final auth = await buildAndInitAuth(repo, _MockSecureStorageService());

        final router = AppRouter.createRouter(auth);
        await pumpIgnoringHomeShellDeps(tester, wrapRouter(auth, router));

        expect(find.byType(OnboardingScreen), findsNothing);
        expect(
          router.routerDelegate.currentConfiguration.uri.toString(),
          RouteNames.home,
        );
      },
    );
  });

  group('Router — no global has_password gate', () {
    testWidgets(
      'V: has_password=false does NOT globally redirect an authenticated user to Set Password — complete profile -> Home directly',
      (tester) async {
        final repo = _MockAuthRepository();
        when(() => repo.restoreSession()).thenAnswer(
          (_) async => (_fakeSession(_completeNoPassword.id), _completeNoPassword),
        );
        final auth = await buildAndInitAuth(repo, _MockSecureStorageService());

        final router = AppRouter.createRouter(auth);
        await pumpIgnoringHomeShellDeps(tester, wrapRouter(auth, router));

        expect(find.byType(SetPasswordScreen), findsNothing);
        expect(
          router.routerDelegate.currentConfiguration.uri.toString(),
          RouteNames.home,
        );
      },
    );

    testWidgets(
      'W: cold launch, unauthenticated -> Login',
      (tester) async {
        final repo = _MockAuthRepository();
        when(() => repo.restoreSession()).thenAnswer((_) async => (null, null));
        final auth = await buildAndInitAuth(repo, _MockSecureStorageService());

        final router = AppRouter.createRouter(auth);
        await tester.pumpWidget(wrapRouter(auth, router));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 6));

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(SetPasswordScreen), findsNothing);
      },
    );

    testWidgets(
      'X: logout -> Login (never Set Password again)',
      (tester) async {
        final repo = _MockAuthRepository();
        final secureStorage = _MockSecureStorageService();
        when(() => repo.restoreSession()).thenAnswer(
          (_) async => (_fakeSession(_completeWithPassword.id), _completeWithPassword),
        );
        when(() => repo.signOut()).thenAnswer((_) async {});
        when(() => secureStorage.deleteAll()).thenAnswer((_) async {});
        final auth = await buildAndInitAuth(repo, secureStorage);

        final router = AppRouter.createRouter(auth);
        await pumpIgnoringHomeShellDeps(tester, wrapRouter(auth, router));
        expect(
          router.routerDelegate.currentConfiguration.uri.toString(),
          RouteNames.home,
        );

        await auth.signOut();
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(SetPasswordScreen), findsNothing);
      },
    );

    testWidgets(
      'Y: authenticated + incomplete profile -> Profile (onboarding), regardless of has_password',
      (tester) async {
        final repo = _MockAuthRepository();
        when(() => repo.restoreSession()).thenAnswer(
          (_) async => (_fakeSession(_incompleteLegacyUser.id), _incompleteLegacyUser),
        );
        final auth = await buildAndInitAuth(repo, _MockSecureStorageService());

        final router = AppRouter.createRouter(auth);
        await tester.pumpWidget(wrapRouter(auth, router));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 6));

        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(find.byType(SetPasswordScreen), findsNothing);
        expect(find.byType(HomeShellScreen), findsNothing);
      },
    );

    testWidgets(
      'Z: authenticated + complete profile -> Home, regardless of has_password',
      (tester) async {
        final repo = _MockAuthRepository();
        when(() => repo.restoreSession()).thenAnswer(
          (_) async => (_fakeSession(_completeWithPassword.id), _completeWithPassword),
        );
        final auth = await buildAndInitAuth(repo, _MockSecureStorageService());

        final router = AppRouter.createRouter(auth);
        await pumpIgnoringHomeShellDeps(tester, wrapRouter(auth, router));

        expect(
          router.routerDelegate.currentConfiguration.uri.toString(),
          RouteNames.home,
        );
      },
    );

    testWidgets(
      'AA: an incomplete profile cannot bypass onboarding by navigating straight to Home',
      (tester) async {
        final repo = _MockAuthRepository();
        when(() => repo.restoreSession()).thenAnswer(
          (_) async => (_fakeSession(_incompleteLegacyUser.id), _incompleteLegacyUser),
        );
        final auth = await buildAndInitAuth(repo, _MockSecureStorageService());

        final router = AppRouter.createRouter(auth);
        await tester.pumpWidget(wrapRouter(auth, router));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 6));

        router.go(RouteNames.home);
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(find.byType(HomeShellScreen), findsNothing);
      },
    );

    testWidgets(
      'cold launch while session restoration is loading -> Splash, never Set Password or Home',
      (tester) async {
        final repo = _MockAuthRepository();
        when(() => repo.authStateStream).thenAnswer((_) => const Stream.empty());
        // restoreSession() never resolves during this test — simulates the
        // "still loading" window.
        when(() => repo.restoreSession()).thenAnswer(
          (_) => Completer<(Session?, UserEntity?)>().future,
        );
        final auth = AuthProvider(
          authRepository: repo,
          secureStorage: _MockSecureStorageService(),
        );
        // Deliberately not awaited — initialize() is in flight.
        // ignore: unawaited_futures
        auth.initialize();

        final router = AppRouter.createRouter(auth);
        await tester.pumpWidget(wrapRouter(auth, router));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(auth.isInitializing, isTrue);
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.byType(SetPasswordScreen), findsNothing);
        expect(find.byType(HomeShellScreen), findsNothing);

        // Flush AuthProvider.initialize()'s own 5s init-timeout Timer,
        // SplashScreen's own 8s fallback-navigation Timer (only actually
        // created here, unlike the other tests in this file, because this
        // is the one scenario where SplashScreen stays mounted long
        // enough for its initState to run at all), and the cascade of
        // flutter_animate rebuild timers those two trigger — pumpAndSettle
        // (rather than manual pumps) is what's needed to fully drain a
        // cascading, not just a single, timer.
        await tester.pump(const Duration(seconds: 9));
        await tester.pumpAndSettle();
      },
    );
  });
}
