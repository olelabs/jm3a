// Normal login (identifier + password) and its supporting widgets.
//
// Covers the pieces that are feasible to test without a live Supabase
// client:
//   - AuthMethodSelector: selection toggling and semantics.
//   - LoginScreen: has both an identifier and a password field; a wrong
//     password shows a plain error and stays on Login; a KNOWN account
//     with has_password=false (password_not_set) shows the inline
//     "no password yet" banner, which points at Forgot password rather
//     than starting any separate "legacy setup" flow.
//
// Same mocktail-over-concrete-classes approach used throughout —
// AuthRepository/SecureStorageService have no existing test doubles/
// interfaces in this codebase.
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:jma3a/core/errors/failures.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/providers/auth_provider.dart';
import 'package:jma3a/core/router/route_names.dart';
import 'package:jma3a/core/storage/secure_storage_service.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/auth/data/auth_repository.dart';
import 'package:jma3a/features/auth/presentation/screens/login_screen.dart';
import 'package:jma3a/features/auth/presentation/widgets/auth_method_selector.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

Widget _wrap(Widget child, {required AuthProvider auth}) {
  final router = GoRouter(
    initialLocation: '/login-under-test',
    routes: [
      GoRoute(
        path: '/login-under-test',
        builder: (_, __) => child,
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, state) => Text('FORGOT_PASSWORD_STUB identifier=${state.extra}'),
      ),
      GoRoute(
        path: RouteNames.offline,
        builder: (_, __) => const Text('OFFLINE_STUB'),
      ),
    ],
  );

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

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '');
    registerFallbackValue('');
  });

  group('AuthMethodSelector', () {
    testWidgets('tapping the email card selects it and deselects phone', (
      tester,
    ) async {
      var selected = AuthMethod.phone;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => AuthMethodSelector(
                selected: selected,
                onChanged: (m) => setState(() => selected = m),
              ),
            ),
          ),
        ),
      );

      // Each card is wrapped in its own button-role Semantics node with a
      // `selected` flag — the actual "visually/programmatically distinct
      // selected state" requirement (section 8) — checked structurally
      // rather than by exact merged label text, which Flutter concatenates
      // with the card's own descendant Text nodes unpredictably.
      final cardsBeforeTap = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.button == true)
          .toList();
      expect(cardsBeforeTap.length, 2);
      expect(cardsBeforeTap.where((s) => s.properties.selected == true).length, 1);

      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);

      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();

      expect(selected, AuthMethod.email);

      final cardsAfterTap = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.button == true)
          .toList();
      expect(cardsAfterTap.where((s) => s.properties.selected == true).length, 1);
    });
  });

  group('LoginScreen — identifier + password', () {
    late _MockAuthRepository repo;
    late AuthProvider auth;

    setUp(() {
      repo = _MockAuthRepository();
      final secureStorage = _MockSecureStorageService();
      when(() => repo.authStateStream).thenAnswer((_) => const Stream.empty());
      auth = AuthProvider(authRepository: repo, secureStorage: secureStorage);
    });

    // A: Login screen contains identifier + password.
    testWidgets('A: has both an identifier and a password field', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), auth: auth));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Email or phone number'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Log in'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Forgot password?'), findsOneWidget);
    });

    // D: Wrong password -> stays Login, shows a normal invalid-credentials
    // error, never sends an OTP.
    testWidgets(
      'D: a plain wrong password shows a snackbar and stays on Login, never the legacy banner',
      (tester) async {
        when(() => repo.loginWithPassword(any(), any())).thenThrow(
          const AuthFailure(
            message: 'Incorrect email/phone or password.',
            code: 'invalid_credentials',
          ),
        );

        await tester.pumpWidget(_wrap(const LoginScreen(), auth: auth));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email or phone number'),
          'someone@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'wrongpassword1',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
        await tester.pumpAndSettle();

        expect(find.text('Incorrect email/phone or password.'), findsOneWidget);
        expect(find.text('No password yet'), findsNothing);
        expect(find.byType(LoginScreen), findsOneWidget);
        verifyNever(() => repo.sendOtp(any()));
        verifyNever(() => repo.sendPhoneOtp(any()));
      },
    );

    // E: existing account with has_password=false -> password_not_set.
    testWidgets(
      'E: a password_not_set error shows the inline "no password yet" banner',
      (tester) async {
        when(() => repo.loginWithPassword(any(), any())).thenThrow(
          const AuthFailure(
            message: "This account doesn't have a password yet.",
            code: 'password_not_set',
          ),
        );

        await tester.pumpWidget(_wrap(const LoginScreen(), auth: auth));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email or phone number'),
          'legacy@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'whatever123',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
        await tester.pumpAndSettle();

        expect(find.text('No password yet'), findsOneWidget);
      },
    );

    // F: password_not_set -> user can choose Forgot Password, prefilled
    // with the identifier they just typed — never a separate "legacy
    // setup"/OTP path started automatically.
    testWidgets(
      'F: the banner\'s Forgot password button navigates to Forgot Password, identifier prefilled',
      (tester) async {
        when(() => repo.loginWithPassword(any(), any())).thenThrow(
          const AuthFailure(
            message: "This account doesn't have a password yet.",
            code: 'password_not_set',
          ),
        );

        await tester.pumpWidget(_wrap(const LoginScreen(), auth: auth));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email or phone number'),
          'legacy@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'whatever123',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
        await tester.pumpAndSettle();

        // Two "Forgot password?" affordances exist once the banner shows
        // (the persistent link, and the banner's own CTA) — tap the
        // banner's, which is the one styled as a JButton.
        await tester.tap(find.widgetWithText(OutlinedButton, 'Forgot password?'));
        await tester.pumpAndSettle();

        expect(
          find.text('FORGOT_PASSWORD_STUB identifier=legacy@example.com'),
          findsOneWidget,
        );
        verifyNever(() => repo.sendOtp(any()));
        verifyNever(() => repo.sendPhoneOtp(any()));
      },
    );

    testWidgets(
      'reached from Signup with an existing identifier: shows the account-exists banner, prefilled',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const LoginScreen(prefillIdentifier: 'existing@example.com'),
            auth: auth,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('An account with this phone/email already exists. Please log in.'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextFormField, 'Email or phone number').evaluate().single
              .widget,
          isA<TextFormField>().having(
            (f) => f.controller?.text,
            'controller.text',
            'existing@example.com',
          ),
        );
      },
    );
  });
}
