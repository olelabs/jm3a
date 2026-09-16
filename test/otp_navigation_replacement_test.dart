// Navigation-fix regression: SignupScreen's OTP navigation used to be
// context.push(RouteNames.authOtp, ...), which left LoginScreen AND
// SignupScreen both sitting underneath OtpScreen in the Navigator stack —
// three screens deep. OtpScreen's own Back action then revealed Signup
// (with Login still further beneath that) instead of OTP being the sole
// active authentication step, exactly the "OTP screen left underneath/
// alongside the login screen" report. Now context.go(...), mirroring
// ForgotPasswordScreen's already-correct navigation to the same route.
//
// This drives the ACTUAL screen transition — Login's real "Create
// account" tap, then the real SignupScreen's own submit — rather than
// jumping straight to router.go(RouteNames.authOtp) the way
// signup_otp_navigation_test.dart does (that file tests OtpScreen's own
// post-verification behavior in isolation and is unaffected by this fix).
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
import 'package:jma3a/features/auth/presentation/screens/login_screen.dart';
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

  // Starts at the REAL LoginScreen — the only way in per the app's own
  // architecture (LoginScreen's own doc: "Normal login never routes
  // through [Signup]... the only way in"). The OTP destination is a
  // minimal stub: this test's whole point is the STACK SHAPE produced by
  // getting there, not OtpScreen's own internals (covered elsewhere).
  GoRouter buildRouter() => GoRouter(
    initialLocation: RouteNames.authPasswordLogin,
    routes: [
      GoRoute(
        path: RouteNames.authPasswordLogin,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: RouteNames.authOtp,
        builder: (_, state) {
          final args = state.extra as ({
            String identifier,
            String? phoneNumber,
            bool isPasswordRecovery,
            String? pendingPassword,
            bool returnToSettingsOnSuccess,
          })?;
          return Text('OTP_STUB pending=${args?.pendingPassword}');
        },
      ),
    ],
  );

  // "Create account" is a TapGestureRecognizer on one TextSpan among
  // several inside a single RichText ("Don't have an account? Create
  // account") — tester.tap() taps at the CENTER of the whole RichText's
  // render box, which (given "Don't have an account? " is the longer,
  // non-tappable leading span) can land outside "Create account"'s own
  // glyph region entirely and silently do nothing. Invoking the
  // recognizer directly sidesteps hit-testing geometry altogether.
  void tapRichTextSpan(WidgetTester tester, String text) {
    bool tapped = false;
    // InlineSpan.visitChildren already performs the full pre-order walk
    // (it invokes the visitor on the span itself before descending into
    // its children) — it must be used directly as the visitor, not
    // wrapped in a second manual recursion, or every leaf span re-invokes
    // the visitor on itself forever.
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

  Future<void> goToSignupFromLogin(WidgetTester tester) async {
    tapRichTextSpan(tester, 'Create account');
    await tester.pumpAndSettle();
    expect(find.byType(SignupScreen), findsOneWidget);
  }

  Future<void> fillSignupForm(
    WidgetTester tester, {
    required String phoneDigits,
    required String password,
    required String confirm,
  }) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone'),
      phoneDigits,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      password,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      confirm,
    );
  }

  testWidgets(
    'navigation fix: Login -> Signup -> successful OTP request replaces '
    'the WHOLE stack (go, not push) — Login and Signup are both gone, '
    'not just hidden underneath OtpScreen',
    (tester) async {
      when(() => repo.checkIdentifierExists(any())).thenAnswer((_) async => false);
      when(() => repo.sendPhoneOtp(any())).thenAnswer(
        (_) async => 'new-user@phone.jma3a.internal',
      );

      await tester.pumpWidget(wrapWithRouter(buildRouter()));
      expect(find.byType(LoginScreen), findsOneWidget);

      await goToSignupFromLogin(tester);
      await fillSignupForm(
        tester,
        phoneDigits: '12345678',
        password: 'correcthorse1',
        confirm: 'correcthorse1',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      // OTP is showing (the request succeeded and navigated).
      expect(find.text('OTP_STUB pending=correcthorse1'), findsOneWidget);

      // Neither Login nor Signup is still mounted underneath it.
      expect(
        find.byType(LoginScreen),
        findsNothing,
        reason: 'push() would have left LoginScreen mounted at the bottom '
            'of the stack; go() replaces the whole stack, so it must not '
            'exist at all any more',
      );
      expect(
        find.byType(SignupScreen),
        findsNothing,
        reason: 'push() would have left SignupScreen mounted directly '
            'underneath OtpScreen; go() replaces it too',
      );

      // And there is nothing left for OtpScreen's Back action to reveal.
      final otpElement = tester.element(find.text('OTP_STUB pending=correcthorse1'));
      expect(
        Navigator.of(otpElement).canPop(),
        isFalse,
        reason: 'the OTP destination must be the ONLY entry in the stack',
      );
    },
  );

  testWidgets(
    'the Login -> Signup push() itself is unchanged: Signup can still be '
    'popped back to Login (this fix only touches the Signup -> OTP hop)',
    (tester) async {
      await tester.pumpWidget(wrapWithRouter(buildRouter()));
      await goToSignupFromLogin(tester);

      final signupElement = tester.element(find.byType(SignupScreen));
      expect(
        Navigator.of(signupElement).canPop(),
        isTrue,
        reason: 'Login -> Signup must still be a normal push(), explicitly '
            'required to remain unchanged by this fix',
      );
    },
  );
}
