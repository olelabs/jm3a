// Auth redesign — signup required order (brief section 1):
// identifier -> password -> confirm -> check account doesn't already
// exist -> OTP -> verify -> account is password-ready immediately.
//
// These tests prove the ordering itself: checkIdentifierExists is never
// called with an invalid password on the form, and sendPhoneOtp/sendOtp
// are never called at all until checkIdentifierExists has already come
// back false. An existing account is routed to Login instead, with no
// OTP ever sent.
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

  Widget wrapWithRouter(GoRouter router) => ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );

  GoRouter buildRouter() => GoRouter(
    initialLocation: RouteNames.signup,
    routes: [
      GoRoute(
        path: RouteNames.signup,
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: RouteNames.authPasswordLogin,
        builder: (_, state) => Text('LOGIN_STUB identifier=${state.extra}'),
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

  Future<void> fillForm(
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
    'new account: checkIdentifierExists(false) -> OTP sent -> pendingPassword carried through',
    (tester) async {
      when(() => repo.checkIdentifierExists(any())).thenAnswer((_) async => false);
      when(() => repo.sendPhoneOtp(any())).thenAnswer(
        (_) async => 'new-user@phone.jma3a.internal',
      );

      await tester.pumpWidget(wrapWithRouter(buildRouter()));
      await fillForm(
        tester,
        phoneDigits: '12345678',
        password: 'correcthorse1',
        confirm: 'correcthorse1',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      verify(() => repo.checkIdentifierExists('+22212345678')).called(1);
      verify(() => repo.sendPhoneOtp('+22212345678')).called(1);
      expect(find.text('OTP_STUB pending=correcthorse1'), findsOneWidget);
    },
  );

  testWidgets(
    'existing account: checkIdentifierExists(true) -> routed to Login, OTP never sent',
    (tester) async {
      when(() => repo.checkIdentifierExists(any())).thenAnswer((_) async => true);

      await tester.pumpWidget(wrapWithRouter(buildRouter()));
      await fillForm(
        tester,
        phoneDigits: '12345678',
        password: 'correcthorse1',
        confirm: 'correcthorse1',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      verify(() => repo.checkIdentifierExists('+22212345678')).called(1);
      verifyNever(() => repo.sendPhoneOtp(any()));
      verifyNever(() => repo.sendOtp(any()));
      expect(
        find.text('LOGIN_STUB identifier=+22212345678'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'password/confirmation mismatch: checkIdentifierExists is never called',
    (tester) async {
      await tester.pumpWidget(wrapWithRouter(buildRouter()));
      await fillForm(
        tester,
        phoneDigits: '12345678',
        password: 'correcthorse1',
        confirm: 'differenthorse2',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.checkIdentifierExists(any()));
      verifyNever(() => repo.sendPhoneOtp(any()));
    },
  );

  testWidgets(
    'weak password (no digit): checkIdentifierExists is never called, OTP never sent',
    (tester) async {
      await tester.pumpWidget(wrapWithRouter(buildRouter()));
      await fillForm(
        tester,
        phoneDigits: '12345678',
        password: 'onlylettersnodigits',
        confirm: 'onlylettersnodigits',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.checkIdentifierExists(any()));
      verifyNever(() => repo.sendPhoneOtp(any()));
    },
  );
}
