// Regression coverage for OtpScreen's back navigation. OtpScreen is
// always reached via context.go() (never push() — see
// otp_navigation_replacement_test.dart, which already pins that the
// stack has nothing left to pop to: Navigator.canPop() is false once
// OtpScreen is showing). That means OtpScreen's own Back action
// (app-bar button AND the system/Android back gesture) previously did
// nothing at all — a plain context.pop() has nowhere to go. The fix
// (_goBack() in otp_screen.dart) explicitly go()es back to whichever
// screen actually led here, derived from the SAME
// pendingPassword/isPasswordRecovery/returnToSettingsOnSuccess args
// already threaded through OtpScreenArgs — no new state introduced.
//
// This drives the REAL LoginScreen/SignupScreen/ForgotPasswordScreen/
// OtpScreen widgets (not stubs), mirroring
// otp_navigation_replacement_test.dart's harness, extended to include a
// real OtpScreen and ForgotPasswordScreen so the actual back button can
// be exercised end to end.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/providers/auth_provider.dart';
import 'package:jma3a/core/router/route_names.dart';
import 'package:jma3a/core/storage/secure_storage_service.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/auth/data/auth_repository.dart';
import 'package:jma3a/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:jma3a/features/auth/presentation/screens/login_screen.dart';
import 'package:jma3a/features/auth/presentation/screens/otp_screen.dart';
import 'package:jma3a/features/auth/presentation/screens/signup_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

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

  Widget wrapWithRouter(GoRouter router) =>
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );

  // Same real-route shape app_router.dart itself uses for these paths
  // (OTP route builder copied verbatim from app_router.dart) — real
  // screens throughout, not stubs, since this test exercises OtpScreen's
  // own back-button wiring, not just the stack shape.
  GoRouter buildRouter() => GoRouter(
    initialLocation: RouteNames.authPasswordLogin,
    routes: [
      GoRoute(
        path: RouteNames.authPasswordLogin,
        builder: (_, state) => LoginScreen(
          prefillIdentifier: state.extra as String?,
        ),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (_, _) => const SignupScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, state) => ForgotPasswordScreen(
          prefillIdentifier: state.extra as String?,
        ),
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
    ],
  );

  // Same RichText-span tap approach as otp_navigation_replacement_test.dart
  // — "Create account" is one TapGestureRecognizer span among several
  // inside a single RichText, so a plain tester.tap() on the whole
  // RichText can miss it.
  void tapRichTextSpan(WidgetTester tester, String text) {
    bool tapped = false;
    bool visitor(InlineSpan span) {
      if (span is TextSpan &&
          span.text == text &&
          span.recognizer is TapGestureRecognizer) {
        (span.recognizer! as TapGestureRecognizer).onTap!();
        tapped = true;
        return false;
      }
      return true;
    }

    for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
      richText.text.visitChildren(visitor);
      if (tapped) return;
    }
    fail('No RichText span with text "$text" and a TapGestureRecognizer was found.');
  }

  testWidgets(
    'Signup -> OTP -> Back returns to Signup (not a dead button, not Login)',
    (tester) async {
      when(() => repo.checkIdentifierExists(any())).thenAnswer((_) async => false);
      when(() => repo.sendPhoneOtp(any())).thenAnswer(
        (_) async => 'new-user@phone.jma3a.internal',
      );

      await tester.pumpWidget(wrapWithRouter(buildRouter()));
      expect(find.byType(LoginScreen), findsOneWidget);

      tapRichTextSpan(tester, 'Create account');
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone'),
        '12345678',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'correcthorse1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'correcthorse1',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(OtpScreen), findsOneWidget);
      expect(find.byType(SignupScreen), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(
        find.byType(SignupScreen),
        findsOneWidget,
        reason: 'Back on an OTP reached from Signup must return to Signup',
      );
      expect(find.byType(OtpScreen), findsNothing);
      expect(find.byType(LoginScreen), findsNothing);
    },
  );

  testWidgets(
    'Login -> Forgot Password -> OTP -> Back returns to Login',
    (tester) async {
      when(() => repo.sendOtp(any())).thenAnswer((_) async {});

      await tester.pumpWidget(wrapWithRouter(buildRouter()));
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email or phone number'),
        'someone@example.com',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send code'));
      await tester.pumpAndSettle();

      expect(find.byType(OtpScreen), findsOneWidget);
      expect(find.byType(ForgotPasswordScreen), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(
        find.byType(LoginScreen),
        findsOneWidget,
        reason: 'Back on an OTP reached from Login\'s Forgot Password must '
            'return to Login',
      );
      expect(find.byType(OtpScreen), findsNothing);
      expect(find.byType(ForgotPasswordScreen), findsNothing);
    },
  );

  testWidgets(
    'the system/Android back gesture behaves the same as the visible back '
    'button (PopScope intercepts it, not just BackButton.onPressed)',
    (tester) async {
      when(() => repo.checkIdentifierExists(any())).thenAnswer((_) async => false);
      when(() => repo.sendPhoneOtp(any())).thenAnswer(
        (_) async => 'new-user@phone.jma3a.internal',
      );

      final router = buildRouter();
      await tester.pumpWidget(wrapWithRouter(router));

      tapRichTextSpan(tester, 'Create account');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone'),
        '12345678',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'correcthorse1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'correcthorse1',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(OtpScreen), findsOneWidget);

      // Simulates the system back gesture/button exactly as Flutter's own
      // test harness does — routes through the same PopScope that
      // guards the visible BackButton above.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.byType(OtpScreen), findsNothing);
    },
  );
}
