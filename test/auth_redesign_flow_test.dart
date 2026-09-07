// SetPasswordScreen post-submit routing, and PasswordSettingsScreen's
// Update Password flow.
//
// SetPasswordScreen is reached only from an explicitly-invoked flow
// (password recovery/reset — see set_password_screen.dart's doc), never
// a global router redirect. After a successful submit it explicitly
// routes to onboarding vs. home based on needsOnboarding — this is the
// one part of that ordering that's only provable with a real navigation
// stack, which is what the first group below covers. has_password plays
// no role in login routing anywhere in the app (see auth_redirect_test.
// dart); PasswordSettingsScreen (second group) is a fully self-contained
// Settings-only feature, unaffected by that.
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:jma3a/core/errors/failures.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/providers/auth_provider.dart';
import 'package:jma3a/core/router/route_names.dart';
import 'package:jma3a/core/storage/secure_storage_service.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/auth/data/auth_repository.dart';
import 'package:jma3a/features/auth/domain/entities/user_entity.dart';
import 'package:jma3a/features/auth/presentation/screens/otp_screen.dart';
import 'package:jma3a/features/auth/presentation/screens/set_password_screen.dart';
import 'package:jma3a/features/settings/presentation/screens/password_settings_screen.dart';

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

// A brand-new signup: OTP already verified, no profile yet, no password.
const _newSignupUser = UserEntity(
  id: 'new-user',
  email: 'new@example.com',
  hasPassword: false,
);

// A legacy account: onboarding was done long ago, just has no password.
const _legacyUser = UserEntity(
  id: 'legacy-user',
  email: 'legacy@example.com',
  username: 'legacyuser',
  displayName: 'Legacy User',
  phoneNumber: '+22212345678',
  hasPassword: false,
);

Widget _wrapWithRouter(GoRouter router, {required AuthProvider auth}) =>
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '');
  });

  late _MockAuthRepository repo;
  late AuthProvider auth;

  setUp(() {
    repo = _MockAuthRepository();
    final secureStorage = _MockSecureStorageService();
    when(() => repo.authStateStream).thenAnswer((_) => const Stream.empty());
    auth = AuthProvider(authRepository: repo, secureStorage: secureStorage);
  });

  Future<void> signIn(UserEntity user) async {
    when(() => repo.restoreSession()).thenAnswer(
      (_) async => (_fakeSession(user.id), user),
    );
    await auth.initialize();
  }

  group('SetPasswordScreen — post-submit navigation', () {
    testWidgets(
      'a brand-new signup (needsOnboarding still true) goes to onboarding, not home',
      (tester) async {
        await signIn(_newSignupUser);
        expect(auth.needsOnboarding, isTrue);

        when(() => repo.setPassword(any(), any()))
            .thenAnswer((_) async => _fakeSession(_newSignupUser.id));

        final router = GoRouter(
          initialLocation: RouteNames.setPassword,
          routes: [
            GoRoute(
              path: RouteNames.setPassword,
              builder: (_, __) => const SetPasswordScreen(),
            ),
            GoRoute(
              path: RouteNames.onboarding,
              builder: (_, __) => const Text('ONBOARDING_STUB'),
            ),
            GoRoute(
              path: RouteNames.home,
              builder: (_, __) => const Text('HOME_STUB'),
            ),
          ],
        );

        await tester.pumpWidget(_wrapWithRouter(router, auth: auth));
        // Flush AuthProvider.initialize()'s own 5s init-timeout Timer — a
        // no-op by this point (isInitializing is already false), but
        // flutter_test's fake-async binding fails the test if any Timer
        // is still pending when it ends.
        await tester.pump(const Duration(seconds: 6));

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'Str0ngPass',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'),
          'Str0ngPass',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Start playing'));
        await tester.pumpAndSettle();

        expect(find.text('ONBOARDING_STUB'), findsOneWidget);
        expect(find.text('HOME_STUB'), findsNothing);
      },
    );

    testWidgets(
      'a legacy account (onboarding already done) goes straight to home',
      (tester) async {
        await signIn(_legacyUser);
        expect(auth.needsOnboarding, isFalse);

        when(() => repo.setPassword(any(), any()))
            .thenAnswer((_) async => _fakeSession(_legacyUser.id));

        final router = GoRouter(
          initialLocation: RouteNames.setPassword,
          routes: [
            GoRoute(
              path: RouteNames.setPassword,
              builder: (_, __) => const SetPasswordScreen(),
            ),
            GoRoute(
              path: RouteNames.onboarding,
              builder: (_, __) => const Text('ONBOARDING_STUB'),
            ),
            GoRoute(
              path: RouteNames.home,
              builder: (_, __) => const Text('HOME_STUB'),
            ),
          ],
        );

        await tester.pumpWidget(_wrapWithRouter(router, auth: auth));
        // Flush AuthProvider.initialize()'s own 5s init-timeout Timer — a
        // no-op by this point (isInitializing is already false), but
        // flutter_test's fake-async binding fails the test if any Timer
        // is still pending when it ends.
        await tester.pump(const Duration(seconds: 6));

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'Str0ngPass',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'),
          'Str0ngPass',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Start playing'));
        await tester.pumpAndSettle();

        expect(find.text('HOME_STUB'), findsOneWidget);
        expect(find.text('ONBOARDING_STUB'), findsNothing);
      },
    );
  });

  group('PasswordSettingsScreen — Update Password (authenticated, no OTP)', () {
    // Deliberately no /auth/otp route here at all — Update Password never
    // navigates there. RouteNames.settings is included so a successful
    // change's "return to Settings" navigation resolves to something.
    GoRouter buildRouter() => GoRouter(
      initialLocation: RouteNames.passwordSettings,
      routes: [
        GoRoute(
          path: RouteNames.passwordSettings,
          builder: (_, __) => const PasswordSettingsScreen(),
        ),
        GoRoute(
          path: RouteNames.settings,
          builder: (_, __) => const Text('SETTINGS_STUB'),
        ),
      ],
    );

    // Opening Update Password immediately shows Current Password + a
    // Forgot password link — no OTP button anywhere on this initial
    // screen, for EITHER has_password value (the screen is identical;
    // only the body text above it differs).
    testWidgets(
      'opening Update Password shows Current Password + Forgot password, no OTP button — has_password=true',
      (tester) async {
        await signIn(_legacyUser.copyWith(hasPassword: true));

        await tester.pumpWidget(_wrapWithRouter(buildRouter(), auth: auth));
        await tester.pump(const Duration(seconds: 6));

        expect(find.text('Your password is set.'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Current password'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'New password'), findsNothing);
        expect(find.widgetWithText(TextFormField, 'Confirm new password'), findsNothing);
        expect(find.textContaining('OTP'), findsNothing);
        expect(find.widgetWithText(TextButton, 'Forgot password?'), findsOneWidget);
      },
    );

    testWidgets(
      'opening Update Password shows Current Password + Forgot password, no OTP button — has_password=false',
      (tester) async {
        await signIn(_legacyUser.copyWith(hasPassword: false));

        await tester.pumpWidget(_wrapWithRouter(buildRouter(), auth: auth));
        await tester.pump(const Duration(seconds: 6));

        expect(find.text("You haven't set a password yet."), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Current password'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'New password'), findsNothing);
        expect(find.textContaining('OTP'), findsNothing);
        expect(find.widgetWithText(TextButton, 'Forgot password?'), findsOneWidget);
      },
    );

    // B: wrong current password stays on the verification step, never
    // reveals the new-password fields, never sends anything.
    testWidgets(
      'B: wrong current password shows an error, stays on this step, new-password fields stay hidden',
      (tester) async {
        await signIn(_legacyUser.copyWith(hasPassword: true));
        when(() => repo.verifyCurrentPassword(any())).thenThrow(
          const AuthFailure(
            message: 'Current password is incorrect.',
            code: 'invalid_current_password',
          ),
        );

        await tester.pumpWidget(_wrapWithRouter(buildRouter(), auth: auth));
        await tester.pump(const Duration(seconds: 6));

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Current password'),
          'wrongold1',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Verify Current Password'));
        await tester.pumpAndSettle();

        expect(find.text('Current password is incorrect.'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'New password'), findsNothing);
        expect(find.byType(PasswordSettingsScreen), findsOneWidget);
        verifyNever(() => repo.sendPhoneOtp(any()));
        verifyNever(() => repo.sendOtp(any()));
        verifyNever(() => repo.changePassword(any(), any(), any()));
      },
    );

    // A/C/F/G: correct current password reveals New Password + Confirm;
    // confirming changes the password directly (no OTP), then returns to
    // Settings.
    testWidgets(
      'A/C/F/G: correct current password reveals new-password fields; confirming changes the password with no OTP, then returns to Settings',
      (tester) async {
        await signIn(_legacyUser.copyWith(hasPassword: true));
        when(() => repo.verifyCurrentPassword(any())).thenAnswer((_) async {});
        when(() => repo.changePassword(any(), any(), any())).thenAnswer((_) async {});

        await tester.pumpWidget(_wrapWithRouter(buildRouter(), auth: auth));
        await tester.pump(const Duration(seconds: 6));

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Current password'),
          'correcthorse1',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Verify Current Password'));
        await tester.pumpAndSettle();

        // C
        expect(find.widgetWithText(TextFormField, 'New password'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Confirm new password'), findsOneWidget);
        expect(find.textContaining('OTP'), findsNothing);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'New password'),
          'newpassword2',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm new password'),
          'newpassword2',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Change Password'));
        await tester.pumpAndSettle();

        // A/F: changed with no OTP ever sent, and the exact current/new
        // passwords the user typed are what's sent through (D/E's
        // "old stops working, new works" is a backend-verified guarantee
        // — see passwordAuth.test.js's verifyPasswordGrant coverage —
        // this is the app-layer half: no swap/mixup of which password is
        // which).
        verify(() => repo.changePassword('correcthorse1', 'newpassword2', 'newpassword2')).called(1);
        verifyNever(() => repo.sendPhoneOtp(any()));
        verifyNever(() => repo.sendOtp(any()));

        // G: back in Settings, not Home, not Login.
        expect(find.text('SETTINGS_STUB'), findsOneWidget);
        expect(find.byType(PasswordSettingsScreen), findsNothing);
      },
    );
  });

  group('PasswordSettingsScreen — "Forgot password?" recovery (separate from Update Password)', () {
    // Uses the REAL OtpScreen and SetPasswordScreen — this is exactly the
    // level Bug 3 (recovery OTP navigating straight into the app) and the
    // "Settings forgot-password must return to Settings, not Home"
    // requirement actually occur at.
    GoRouter buildRouter() => GoRouter(
      initialLocation: RouteNames.passwordSettings,
      routes: [
        GoRoute(
          path: RouteNames.passwordSettings,
          builder: (_, __) => const PasswordSettingsScreen(),
        ),
        GoRoute(
          path: RouteNames.authOtp,
          builder: (_, state) {
            final args = state.extra as OtpScreenArgs?;
            return OtpScreen(
              identifier: args?.identifier ?? '',
              phoneNumber: args?.phoneNumber,
              isPasswordRecovery: args?.isPasswordRecovery ?? false,
              pendingPassword: args?.pendingPassword,
              returnToSettingsOnSuccess: args?.returnToSettingsOnSuccess ?? false,
            );
          },
        ),
        GoRoute(
          path: RouteNames.setPassword,
          builder: (_, state) {
            final args = state.extra as SetPasswordScreenArgs?;
            return SetPasswordScreen(
              isRecovery: args?.isRecovery ?? false,
              returnToSettingsOnSuccess: args?.returnToSettingsOnSuccess ?? false,
            );
          },
        ),
        GoRoute(
          path: RouteNames.settings,
          builder: (_, __) => const Text('SETTINGS_STUB'),
        ),
        GoRoute(
          path: RouteNames.home,
          builder: (_, __) => const Text('HOME_STUB'),
        ),
      ],
    );

    Future<void> tapForgotPassword(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(TextButton, 'Forgot password?'));
      await tester.pumpAndSettle();
    }

    // H/I: works for a has_password=false account, and sends OTP to the
    // ALREADY-authenticated identifier — never asks the user to type one.
    testWidgets(
      'H/I: has_password=false — tapping Forgot password sends OTP to the authenticated email, no identifier prompt',
      (tester) async {
        await signIn(_legacyUser.copyWith(hasPassword: false));
        when(() => repo.sendPhoneOtp('+22212345678')).thenAnswer((_) async => 'legacy-synthetic@phone.jma3a.internal');

        await tester.pumpWidget(_wrapWithRouter(buildRouter(), auth: auth));
        await tester.pump(const Duration(seconds: 6));

        expect(find.widgetWithText(TextFormField, 'Email or phone number'), findsNothing);
        await tapForgotPassword(tester);

        verify(() => repo.sendPhoneOtp('+22212345678')).called(1);
        expect(find.byType(OtpScreen), findsOneWidget);
      },
    );

    // J/K: OTP verification leads to New Password, never straight back
    // into the app — and creates the account's FIRST password.
    testWidgets(
      'J/K: has_password=false — OTP verified -> New Password (never straight into the app) -> creates the first password -> back to Settings',
      (tester) async {
        await signIn(_legacyUser.copyWith(hasPassword: false));
        when(() => repo.sendPhoneOtp('+22212345678')).thenAnswer((_) async => 'legacy-synthetic@phone.jma3a.internal');
        when(() => repo.verifyOtp('legacy-synthetic@phone.jma3a.internal', '123456')).thenAnswer(
          (_) async => (_fakeSession(_legacyUser.id), _legacyUser.copyWith(hasPassword: false)),
        );
        when(() => repo.setPassword('FirstPass1', 'FirstPass1'))
            .thenAnswer((_) async => _fakeSession(_legacyUser.id));

        await tester.pumpWidget(_wrapWithRouter(buildRouter(), auth: auth));
        await tester.pump(const Duration(seconds: 6));
        await tapForgotPassword(tester);

        await tester.enterText(find.byType(TextFormField).first, '123456');
        await tester.pumpAndSettle();

        // J: never Home, never back on PasswordSettingsScreen directly —
        // must land on the new-password step.
        expect(find.text('HOME_STUB'), findsNothing);
        expect(find.byType(PasswordSettingsScreen), findsNothing);
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

        // K: first password created, and back on Password & Security —
        // never Home.
        verify(() => repo.setPassword('FirstPass1', 'FirstPass1')).called(1);
        expect(find.text('HOME_STUB'), findsNothing);
        expect(find.byType(PasswordSettingsScreen), findsOneWidget);
      },
    );

    // L: the same recovery flow replaces an EXISTING password just as
    // well — has_password plays no role in which path this takes.
    testWidgets(
      'L: has_password=true — the same recovery flow replaces the existing password, then returns to Settings',
      (tester) async {
        await signIn(_legacyUser.copyWith(hasPassword: true));
        when(() => repo.sendPhoneOtp('+22212345678')).thenAnswer((_) async => 'legacy-synthetic@phone.jma3a.internal');
        when(() => repo.verifyOtp('legacy-synthetic@phone.jma3a.internal', '123456')).thenAnswer(
          (_) async => (_fakeSession(_legacyUser.id), _legacyUser.copyWith(hasPassword: true)),
        );
        when(() => repo.setPassword('ReplacedPass1', 'ReplacedPass1'))
            .thenAnswer((_) async => _fakeSession(_legacyUser.id));

        await tester.pumpWidget(_wrapWithRouter(buildRouter(), auth: auth));
        await tester.pump(const Duration(seconds: 6));
        await tapForgotPassword(tester);

        await tester.enterText(find.byType(TextFormField).first, '123456');
        await tester.pumpAndSettle();
        expect(find.byType(SetPasswordScreen), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'ReplacedPass1',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'),
          'ReplacedPass1',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Reset password'));
        await tester.pumpAndSettle();

        verify(() => repo.setPassword('ReplacedPass1', 'ReplacedPass1')).called(1);
        expect(find.text('HOME_STUB'), findsNothing);
        expect(find.byType(PasswordSettingsScreen), findsOneWidget);
      },
    );
  });
}
