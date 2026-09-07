// Bug 2 regression — end-to-end: a successful signup OTP verification
// must never land on an error route or Home; it must let the router's
// redirect carry it into onboarding, driven by the SAME
// computeAccountStateRedirect the real AppRouter uses (see
// auth_redirect_test.dart for that function's own exhaustive coverage).
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
import 'package:jma3a/features/auth/presentation/screens/otp_screen.dart';

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
  });

  testWidgets(
    'signup OTP verification: success routes to onboarding — never an error route, never Home',
    (tester) async {
      final repo = _MockAuthRepository();
      final secureStorage = _MockSecureStorageService();
      when(() => repo.authStateStream).thenAnswer((_) => const Stream.empty());
      final auth = AuthProvider(authRepository: repo, secureStorage: secureStorage);

      const newSignupUser = UserEntity(
        id: 'new-user',
        email: 'new@example.com',
        hasPassword: false,
      );
      when(() => repo.verifyOtp('new@example.com', '123456')).thenAnswer(
        (_) async => (_fakeSession(newSignupUser.id), newSignupUser),
      );
      when(() => repo.setPassword('Str0ngPass1', 'Str0ngPass1'))
          .thenAnswer((_) async => _fakeSession(newSignupUser.id));

      final router = GoRouter(
        initialLocation: RouteNames.authOtp,
        refreshListenable: auth,
        redirect: (context, state) {
          final loc = state.uri.toString();
          final alwaysPublic = [RouteNames.authOtp, RouteNames.authPasswordLogin];
          final appRoutes = [RouteNames.home];
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
            path: RouteNames.authOtp,
            builder: (_, state) {
              final args = state.extra as ({
                String identifier,
                String? phoneNumber,
                bool isPasswordRecovery,
                String? pendingPassword,
                bool returnToSettingsOnSuccess,
              })?;
              return OtpScreen(
                identifier: args?.identifier ?? 'new@example.com',
                pendingPassword: args?.pendingPassword,
              );
            },
          ),
          GoRoute(
            path: RouteNames.setPassword,
            builder: (_, __) => const Text('SET_PASSWORD_STUB'),
          ),
          GoRoute(
            path: RouteNames.onboarding,
            builder: (_, __) => const Text('ONBOARDING_STUB'),
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

      router.go(
        RouteNames.authOtp,
        extra: (
          identifier: 'new@example.com',
          phoneNumber: null,
          isPasswordRecovery: false,
          pendingPassword: 'Str0ngPass1',
          returnToSettingsOnSuccess: false,
        ),
      );
      await tester.pumpAndSettle();

      // OtpScreen's boxes support full paste — entering all 6 digits into
      // the first box distributes them and auto-submits once complete.
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.pumpAndSettle();

      expect(find.text('ERROR_ROUTE'), findsNothing);
      expect(find.text('HOME_STUB'), findsNothing);
      expect(find.text('ONBOARDING_STUB'), findsOneWidget);
      verify(() => repo.setPassword('Str0ngPass1', 'Str0ngPass1')).called(1);
    },
  );
}
