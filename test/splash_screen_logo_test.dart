// Item 7 (splash-logo pass) — SplashScreen's logo mark must use
// jma3a_logo.png (the real full-color app icon), not the old
// jma3a_logo_white.png (a mostly-transparent dots-only mark unsuitable
// for a plain white tint — see the widget's own doc comment for why).
//
// SplashScreen needs a real AuthProvider (it reads context.read<
// AuthProvider>() from a post-frame callback) AND a real GoRouter
// ancestor (AuthProvider forces isInitializing false via its own
// internal 5s timeout regardless of what the mocked repository does, at
// which point SplashScreen calls GoRouterState.of(context)/context.go).
// A tiny single-route GoRouter (never redirecting anywhere else) is
// enough to satisfy that without needing this project's full AppRouter
// configuration.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/providers/auth_provider.dart';
import 'package:jma3a/core/storage/secure_storage_service.dart';
import 'package:jma3a/features/auth/data/auth_repository.dart';
import 'package:jma3a/features/auth/domain/entities/user_entity.dart';
import 'package:jma3a/features/auth/presentation/screens/splash_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  testWidgets('renders jma3a_logo.png, never the old jma3a_logo_white.png', (
    tester,
  ) async {
    final repo = _MockAuthRepository();
    when(() => repo.authStateStream).thenAnswer((_) => const Stream.empty());
    // Never resolves on its own — AuthProvider's own 5s internal
    // timeout is what actually completes initialization here (see
    // this file's header comment), not this future.
    when(
      () => repo.restoreSession(),
    ).thenAnswer((_) => Completer<(Session?, UserEntity?)>().future);
    final auth = AuthProvider(
      authRepository: repo,
      secureStorage: _MockSecureStorageService(),
    );
    // ignore: unawaited_futures
    auth.initialize();

    final router = GoRouter(
      initialLocation: '/',
      routes: [GoRoute(path: '/', builder: (_, _) => const SplashScreen())],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/backgrounds/jma3a_logo.png',
    );

    // Flush AuthProvider's 5s init-timeout Timer, SplashScreen's own
    // 8s fallback-navigation Timer, and whatever rebuild cascade those
    // trigger — a bounded number of explicit pumps (not
    // pumpAndSettle, which can time out chasing a rebuild loop this
    // minimal single-route test router isn't set up to fully resolve)
    // is enough to drain every pending Timer flutter_test's teardown
    // invariant checks for, without asserting anything about what the
    // navigation cascade itself does.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  });
}
