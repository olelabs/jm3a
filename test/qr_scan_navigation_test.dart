// Regression coverage for the QR-scanner navigation bug: repeatedly
// re-opening the last scanned profile every time Back was pressed.
//
// Root cause (see qr_scan_screen.dart's own doc comments): _onDetect used
// to call the raw `Navigator.of(context).pop()` immediately followed by
// GoRouter's own `context.push(route)` — two separate, non-atomic calls
// that could leave GoRouter's own match list and the real Navigator out
// of sync, resurrecting the (still camera-active) scanner screen
// underneath the pushed destination. The fix replaces that pair with a
// single atomic `context.pushReplacement(route)`, plus an explicit
// `_controller.stop()` the moment a valid code is handled and a
// `_handled` one-shot guard that blocks any further onDetect calls until
// a fresh scanner screen is opened again.
//
// These tests drive `_onDetect` directly via the `onDetect` callback the
// widget hands to `MobileScanner` (a public field, even though it points
// at a private method) — the exact same function a real barcode
// detection invokes — rather than trying to fake the platform camera.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/features/rooms/presentation/screens/qr_scan_screen.dart';

/// mobile_scanner's own async camera start-up (MethodChannelMobileScanner)
/// has no plugin registered in the widget-test environment and throws a
/// MissingPluginException on an unawaited Future — irrelevant noise for
/// what these tests actually exercise (onDetect -> navigation), and
/// already how this codebase's own router tests swallow other unrelated
/// async widget dependencies (see real_router_regression_test.dart's
/// withHomeShellDepsIgnored).
Future<void> _ignoringCameraPluginErrors(Future<void> Function() action) async {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {};
  try {
    await action();
  } finally {
    FlutterError.onError = original;
  }
}

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

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const _HomeScreen()),
      GoRoute(path: '/scan', builder: (_, _) => const QrScanScreen()),
      GoRoute(
        path: '/u/:username',
        builder: (_, state) =>
            _DestScreen('profile:${state.pathParameters['username']}'),
      ),
      GoRoute(
        path: '/user/:userId',
        builder: (_, state) =>
            _DestScreen('legacy:${state.pathParameters['userId']}'),
      ),
      GoRoute(
        path: '/join',
        builder: (_, state) =>
            _DestScreen('join:${state.uri.queryParameters['code']}'),
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

BarcodeCapture _capture(String rawValue) =>
    BarcodeCapture(barcodes: [Barcode(rawValue: rawValue)]);

/// The exact same function a real detection event invokes — grabbed off
/// the currently-mounted MobileScanner widget's public `onDetect` field
/// (which is `_QrScanScreenState._onDetect`'s own bound tear-off).
void Function(BarcodeCapture) _currentOnDetect(WidgetTester tester) {
  return tester.widget<MobileScanner>(find.byType(MobileScanner)).onDetect!;
}

void main() {
  testWidgets(
    '1&2: a successful scan navigates exactly once, and repeated onDetect '
    'events for the same/other codes afterward do not navigate again',
    (tester) async {
      await _ignoringCameraPluginErrors(() async {
        final router = _buildTestRouter();
        await tester.pumpWidget(_wrap(router));
        await tester.pumpAndSettle();

        router.push('/scan');
        await tester.pump();
        await tester.pump();
        expect(find.byType(QrScanScreen), findsOneWidget);

        final onDetect = _currentOnDetect(tester);

        // Simulate MobileScanner firing onDetect more than once for the
        // same in-view barcode before the camera actually stops —
        // exactly the window the _handled guard exists for.
        onDetect(_capture('jma3a://u/alex'));
        onDetect(_capture('jma3a://u/alex'));
        onDetect(_capture('jma3a://u/someone_else'));
        await tester.pumpAndSettle();

        expect(find.text('profile:alex'), findsOneWidget);
        expect(find.byType(QrScanScreen), findsNothing);
        // The destination REPLACED the scanner entry (home stays
        // underneath) rather than being stacked ON TOP of a still-alive
        // scanner — that would leave three matches (home, scan, u/alex)
        // instead of two.
        final matches = router
            .routerDelegate
            .currentConfiguration
            .matches
            .map((m) => m.matchedLocation)
            .toList();
        expect(matches, ['/home', '/u/alex']);

        // Back returns to whatever screen opened the scanner — never a
        // resurrected, still-listening scanner screen.
        router.pop();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('home-screen')), findsOneWidget);
        expect(find.byType(QrScanScreen), findsNothing);
      });
    },
  );

  testWidgets(
    '3: opening the scanner again after a completed scan processes a new '
    'QR normally (the one-shot guard resets on a fresh scanner instance)',
    (tester) async {
      await _ignoringCameraPluginErrors(() async {
        final router = _buildTestRouter();
        await tester.pumpWidget(_wrap(router));
        await tester.pumpAndSettle();

        router.push('/scan');
        await tester.pump();
        await tester.pump();
        _currentOnDetect(tester)(_capture('jma3a://u/alex'));
        await tester.pumpAndSettle();
        expect(find.text('profile:alex'), findsOneWidget);

        router.pop();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('home-screen')), findsOneWidget);

        // Reopen: a fresh QrScanScreen/_QrScanScreenState, _handled reset.
        router.push('/scan');
        await tester.pump();
        await tester.pump();
        expect(find.byType(QrScanScreen), findsOneWidget);

        _currentOnDetect(tester)(_capture('jma3a://join?code=NEWCODE'));
        await tester.pumpAndSettle();

        expect(find.text('join:NEWCODE'), findsOneWidget);
        expect(find.byType(QrScanScreen), findsNothing);
      });
    },
  );

  testWidgets(
    '8: an invalid/unrecognized QR shows an inline error and stays on the '
    'scanner — never navigates, never leaves the scanner unexpectedly',
    (tester) async {
      await _ignoringCameraPluginErrors(() async {
        final router = _buildTestRouter();
        await tester.pumpWidget(_wrap(router));
        await tester.pumpAndSettle();

        router.push('/scan');
        await tester.pump();
        await tester.pump();

        _currentOnDetect(tester)(_capture('not a jma3a link at all'));
        await tester.pumpAndSettle();

        expect(find.byType(QrScanScreen), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);

        // A subsequent valid scan after the error still works — Try
        // Again resets _handled/_showInvalid rather than stranding the
        // user on a dead scanner.
        await tester.tap(find.byType(FilledButton));
        await tester.pump();
        _currentOnDetect(tester)(_capture('jma3a://u/alex'));
        await tester.pumpAndSettle();
        expect(find.text('profile:alex'), findsOneWidget);
      });
    },
  );

  testWidgets('room QR still resolves through the existing join flow', (
    tester,
  ) async {
    await _ignoringCameraPluginErrors(() async {
      final router = _buildTestRouter();
      await tester.pumpWidget(_wrap(router));
      await tester.pumpAndSettle();

      router.push('/scan');
      await tester.pump();
      await tester.pump();
      _currentOnDetect(tester)(
        _capture('https://jma3a.com/join?code=ABC123&invited_by=user-1'),
      );
      await tester.pumpAndSettle();

      expect(find.text('join:ABC123'), findsOneWidget);
    });
  });
}
