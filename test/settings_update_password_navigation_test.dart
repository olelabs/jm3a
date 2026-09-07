// Settings -> Update Password, end to end against the REAL router: this
// flow must never send an OTP, and must return to Settings (never Home,
// never Login, never an error route) after a successful change. See
// auth_redirect_test.dart for computeAccountStateRedirect's own
// exhaustive coverage; this file proves the flow at the level the
// original OTP-based version of this bug actually occurred at.
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/providers/auth_provider.dart';
import 'package:jma3a/core/router/auth_redirect.dart';
import 'package:jma3a/core/router/route_names.dart';
import 'package:jma3a/core/storage/secure_storage_service.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/auth/data/auth_repository.dart';
import 'package:jma3a/features/auth/domain/entities/user_entity.dart';
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

const _readyUser = UserEntity(
  id: 'ready-user',
  email: 'ready@example.com',
  username: 'readyuser',
  displayName: 'Ready User',
  phoneNumber: '+22212345678',
  hasPassword: true,
);

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '');
  });

  Future<AuthProvider> buildAuth(_MockAuthRepository repo) async {
    final secureStorage = _MockSecureStorageService();
    when(() => repo.authStateStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.restoreSession()).thenAnswer(
      (_) async => (_fakeSession(_readyUser.id), _readyUser),
    );
    final auth = AuthProvider(authRepository: repo, secureStorage: secureStorage);
    await auth.initialize();
    return auth;
  }

  GoRouter buildRouter(AuthProvider auth) => GoRouter(
    initialLocation: RouteNames.passwordSettings,
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.uri.toString();
      final alwaysPublic = [RouteNames.authOtp, RouteNames.authPasswordLogin];
      final appRoutes = [RouteNames.home, RouteNames.settings];
      return computeAccountStateRedirect(
        isLoggedIn: auth.isLoggedIn,
        needsOnboarding: auth.needsOnboarding,
        loc: loc,
        isPublicRoute: alwaysPublic.any((r) => loc.startsWith(r)),
        isAppRoute: appRoutes.any((r) => loc.startsWith(r)),
      );
    },
    routes: [
      GoRoute(
        path: RouteNames.passwordSettings,
        builder: (_, __) => const PasswordSettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (_, __) => const Text('SETTINGS_STUB'),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (_, __) => const Text('HOME_STUB'),
      ),
      GoRoute(
        path: RouteNames.authPasswordLogin,
        builder: (_, __) => const Text('LOGIN_STUB'),
      ),
    ],
    errorBuilder: (_, __) => const Text('ERROR_ROUTE'),
  );

  testWidgets(
    'Update Password: verify current -> new password -> Change Password, no OTP, returns to Settings, never Home or Login',
    (tester) async {
      final repo = _MockAuthRepository();
      final auth = await buildAuth(repo);
      when(() => repo.verifyCurrentPassword(any())).thenAnswer((_) async {});
      when(() => repo.changePassword(any(), any(), any())).thenAnswer((_) async {});

      final router = buildRouter(auth);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 6)); // flush init timeout Timer

      // Step 1: current password.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Current password'),
        'CorrectCurrent1',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify Current Password'));
      await tester.pumpAndSettle();

      expect(find.text('ERROR_ROUTE'), findsNothing);
      expect(find.text('HOME_STUB'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'New password'), findsOneWidget);

      // Step 2: new password + confirm -> changes directly, no OTP.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New password'),
        'NewStr0ngPass1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        'NewStr0ngPass1',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Change Password'));
      await tester.pumpAndSettle();

      // THE regression: must land back on Settings, never Home, never
      // Login, never the error route, and never via an OTP screen.
      expect(find.text('ERROR_ROUTE'), findsNothing);
      expect(find.text('HOME_STUB'), findsNothing);
      expect(find.text('LOGIN_STUB'), findsNothing);
      expect(find.byType(PasswordSettingsScreen), findsNothing);
      expect(find.text('SETTINGS_STUB'), findsOneWidget);
      verify(() => repo.changePassword('CorrectCurrent1', 'NewStr0ngPass1', 'NewStr0ngPass1'))
          .called(1);
      verifyNever(() => repo.sendOtp(any()));
      verifyNever(() => repo.sendPhoneOtp(any()));
    },
  );
}
