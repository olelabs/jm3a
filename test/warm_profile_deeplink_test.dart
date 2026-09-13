// Regression coverage for the warm/background QR-scan navigation loop:
//
//   Jma3a already running -> native Camera scans a profile QR
//   -> app resumes -> "Loading profile..." -> profile -> Back
//   -> "Loading profile..." -> the SAME profile again -> repeats forever.
//
// Root cause: TWO independent systems were reacting to the same incoming
// Universal Link. DeepLinkService (app_links' getInitialLink/
// uriLinkStream) is the app's own, intentional deep-link path — it
// resolves the link and app.dart's _onProfileLink does one real,
// additive GoRouter push(). But Flutter's OWN engine-level deep-link
// routing (FlutterDeepLinkingEnabled — defaults to ON when absent from
// Info.plist, confirmed in the iOS engine's
// FlutterSharedApplicationTest.mm) ALSO fires for the exact same URL,
// completely independently: the app_links iOS plugin always returns
// `false` from its continueUserActivity/openURL delegate methods (see
// AppLinksIosPlugin.swift) — it only observes the link for its own Dart
// stream, it never tells the engine "handled" — so the engine's own
// fallback ALSO sends the raw URL to the framework via the
// `flutter/navigation` platform channel's pushRouteInformation method.
//
// go_router's GoRouteInformationProvider is a WidgetsBindingObserver
// that reacts to that platform push by treating it as NavigatingType.go
// (see go_router's information_provider.dart) — a full location
// replace, landing on the real, registered `/u/:username` route
// (UsernameProfileResolverScreen, "Loading profile..."). That screen
// used to hand off to the real profile via a RAW
// `Navigator.of(context).pushReplacement(...)` — bypassing GoRouter
// entirely, so GoRouter's OWN idea of "the current location" stayed
// stuck on `/u/:username` even after the visible screen moved on. Any
// subsequent GoRouter-driven stack reconciliation (Back included) could
// then resurrect the resolver from that stale state, re-running its
// network lookup and re-doing the same raw hand-off — the infinite loop.
//
// The fix has two parts:
//   1. ios/Runner/Info.plist now sets FlutterDeepLinkingEnabled=false,
//      so the engine's own competing pushRouteInformation call never
//      fires in the first place — DeepLinkService remains the ONE
//      authoritative path, for cold start AND warm/background alike.
//   2. UsernameProfileResolverScreen's hand-off now uses GoRouter's own
//      context.pushReplacement(...) instead of a raw Navigator op, so
//      GoRouter's state is never allowed to drift from the visible
//      screen — belt-and-suspenders, independent of platform/OS.
//
// Part 1 is native-only behavior (gated by an Info.plist key the iOS
// engine reads before Dart ever runs) and cannot be exercised by
// `flutter test`, which never touches the real native embedder. What
// CAN be verified here, precisely, is part 2: this file drives GoRouter
// through the exact same platform channel call
// (`WidgetsBinding.handlePushRoute`, the very method go_router's
// GoRouteInformationProvider reacts to) that the engine used to send —
// i.e. it reproduces the scenario Info.plist now prevents from ever
// reaching Dart — and proves the fixed hand-off pattern does not loop
// even if that event still fired.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/deep_links.dart';

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();
  @override
  Widget build(BuildContext _) => const Scaffold(
    body: Center(child: Text('home-screen', key: Key('home-screen'))),
  );
}

class _DestScreen extends StatelessWidget {
  const _DestScreen(this.label);
  final String label;
  @override
  Widget build(BuildContext _) =>
      Scaffold(body: Center(child: Text(label)));
}

/// Mirrors UsernameProfileResolverScreen's exact shape (async lookup in
/// initState, then a hand-off to the resolved profile) without a live
/// network/Supabase dependency — a deterministic username -> id mapping
/// stands in for ProfileRepository.getProfileByUsername.
class _FakeUsernameResolverScreen extends StatefulWidget {
  const _FakeUsernameResolverScreen({required this.username});
  final String username;

  @override
  State<_FakeUsernameResolverScreen> createState() =>
      _FakeUsernameResolverScreenState();
}

class _FakeUsernameResolverScreenState
    extends State<_FakeUsernameResolverScreen> {
  static int resolveCount = 0;

  @override
  void initState() {
    super.initState();
    resolveCount++;
    _resolve();
  }

  Future<void> _resolve() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    // The fixed pattern: GoRouter's own pushReplacement, never a raw
    // Navigator op — see username_profile_resolver_screen.dart.
    context.pushReplacement('/user/resolved-${widget.username}');
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Loading profile…')));
}

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const _HomeScreen()),
      GoRoute(
        path: '/u/:username',
        builder: (_, state) => _FakeUsernameResolverScreen(
          username: state.pathParameters['username']!,
        ),
      ),
      GoRoute(
        path: '/user/:userId',
        builder: (_, state) =>
            _DestScreen('user:${state.pathParameters['userId']}'),
      ),
    ],
  );
}

Widget _wrap(GoRouter router) {
  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  setUp(() {
    _FakeUsernameResolverScreenState.resolveCount = 0;
    DeepLinkService.instance.clearPendingProfile();
    DeepLinkService.instance.clearPendingInvite();
  });

  group('DeepLinkService pending-profile consumption', () {
    test('a stashed profile link starts out available and is cleared '
        'exactly by clearPendingProfile — the one consumption point '
        '_onProfileLink and AppRouter\'s redirect resume both call', () {
      expect(DeepLinkService.instance.pendingProfile, isNull);

      DeepLinkService.instance.pendingProfile = const ProfileLinkPayload(
        userId: 'scanned-user-1',
      );
      expect(DeepLinkService.instance.pendingProfile?.userId, 'scanned-user-1');

      DeepLinkService.instance.clearPendingProfile();
      expect(DeepLinkService.instance.pendingProfile, isNull);

      // Clearing again (e.g. a second, late consumer) is a no-op, not an
      // error — consuming an already-consumed link must never crash or
      // resurrect it.
      DeepLinkService.instance.clearPendingProfile();
      expect(DeepLinkService.instance.pendingProfile, isNull);
    });

    test('pendingInvite has the same clear-once contract', () {
      DeepLinkService.instance.pendingInvite = const RoomInvitePayload(
        code: 'ABC123',
      );
      expect(DeepLinkService.instance.pendingInvite?.code, 'ABC123');
      DeepLinkService.instance.clearPendingInvite();
      expect(DeepLinkService.instance.pendingInvite, isNull);
    });
  });

  testWidgets(
    'a platform-delivered deep link (the engine\'s own pushRouteInformation '
    '— what a warm/background Universal Link tap used to also trigger, '
    'before FlutterDeepLinkingEnabled=false stopped the engine from ever '
    'sending it) resolves to the profile exactly once and does not loop',
    (tester) async {
      final router = _buildTestRouter();
      await tester.pumpWidget(_wrap(router));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-screen')), findsOneWidget);

      // Exactly what FlutterEngine.sendDeepLinkToFramework does on the
      // native side: invoke the flutter/navigation channel's
      // pushRouteInformation with the full incoming URL. go_router's
      // GoRouteInformationProvider treats this as NavigatingType.go — a
      // full location replace, same as the real engine call — which is
      // *why* there's nothing left beneath it to pop back to here; that
      // "return to the exact previous screen" guarantee comes from
      // Info.plist stopping this event from ever firing at all (so only
      // _onProfileLink's own additive push ever runs — see the
      // "in-app navigation" case below for that shape). What matters
      // here is that if it DID fire, the fixed hand-off doesn't loop.
      await tester.binding.handlePushRoute(
        'https://www.moujgroup.jma3a.com/u/alex',
      );
      await tester.pumpAndSettle();

      expect(_FakeUsernameResolverScreenState.resolveCount, 1);
      expect(find.text('user:resolved-alex'), findsOneWidget);
      expect(find.text('Loading profile…'), findsNothing);

      // GoRouter's OWN state must have actually advanced past
      // /u/:username — this is precisely what a raw Navigator hand-off
      // failed to do, leaving GoRouter's match list stuck pointing at
      // the resolver underneath the (imperatively pushed) profile.
      final matches = router.routerDelegate.currentConfiguration.matches
          .map((m) => m.matchedLocation)
          .toList();
      expect(matches.last, '/user/resolved-alex');
      expect(matches, isNot(contains('/u/:username')));

      // Nothing left to pop to (a full platform replace, not an
      // additive push) — but critically, GoRouter no longer believes
      // the resolver is part of the stack, so there is nothing for a
      // later rebuild to resurrect.
      expect(router.canPop(), isFalse);
    },
  );

  testWidgets(
    'a second, duplicate platform deep-link delivery for the same profile '
    'after it is already showing does not loop either',
    (tester) async {
      final router = _buildTestRouter();
      await tester.pumpWidget(_wrap(router));
      await tester.pumpAndSettle();

      await tester.binding.handlePushRoute(
        'https://www.moujgroup.jma3a.com/u/alex',
      );
      await tester.pumpAndSettle();
      expect(find.text('user:resolved-alex'), findsOneWidget);

      // Simulates the platform re-delivering the same (or a stale)
      // event — must resolve cleanly again, not compound into a
      // growing/looping stack.
      await tester.binding.handlePushRoute(
        'https://www.moujgroup.jma3a.com/u/alex',
      );
      await tester.pumpAndSettle();

      expect(find.text('user:resolved-alex'), findsOneWidget);
      expect(find.text('Loading profile…'), findsNothing);
      expect(_FakeUsernameResolverScreenState.resolveCount, 2);
    },
  );

  testWidgets(
    'in-app navigation to /u/:username (e.g. the QR scanner scanning a '
    'username-form profile QR) still resolves via the same fixed '
    'pushReplacement hand-off, with normal Back semantics preserved',
    (tester) async {
      final router = _buildTestRouter();
      await tester.pumpWidget(_wrap(router));
      await tester.pumpAndSettle();

      // An ordinary in-app push (e.g. from the scanner's own
      // pushReplacement, or any other in-app entry point) — additive,
      // not a platform replace.
      router.push('/u/alex');
      await tester.pumpAndSettle();

      expect(find.text('user:resolved-alex'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-screen')), findsOneWidget);
      expect(find.text('Loading profile…'), findsNothing);
    },
  );
}
