// Regression test for "the lobby flashes during game-start initialization".
//
// Root cause: the local "Preparing" lock was cleared the instant the start
// operation's own async work (pack check, game_started broadcast, the
// rooms.status='starting' write) RETURNED — not when the room's
// AUTHORITATIVE status actually caught up locally. The initiating client
// only learns its own write succeeded via a SEPARATE, LATER signal (a
// realtime broadcast self-echo or the periodic reconcile poll), which can
// lag the write by anywhere from tens of milliseconds to several seconds.
// Clearing the lock on the operation's return — rather than on that later
// authoritative signal — opened a window where neither the local lock nor
// the authoritative status held: the ordinary (lobby) UI rendered.
//
// The fix: the local lock is cleared ONLY on a genuine failure, or once the
// game route has actually been entered and popped back. It is never
// cleared just because the start operation returned, and a stale/delayed/
// regressed authoritative read can only ever confirm the transition or
// leave the lock exactly as it was — never regress back to "lobby".
//
// This test reproduces the mechanism generically (two independent booleans
// — a local "operation accepted" flag and a separately-arriving
// "authoritative" flag — feeding one derived three-state phase), mirroring
// LobbyScreen._gameStartPhase / _showPreparingLock without depending on the
// full app's routing/provider graph.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Phase { lobby, preparing, enteringGame }

class _Harness extends StatefulWidget {
  const _Harness({
    required this.clearLockOnOperationReturn,
    this.operationFails = false,
  });

  /// true reproduces the REGRESSION: the local lock is cleared as soon as
  /// the start operation's own async work finishes, regardless of whether
  /// the authoritative signal has arrived yet. false is the FIX: the lock
  /// is cleared only on failure, never merely because the operation
  /// returned.
  final bool clearLockOnOperationReturn;
  final bool operationFails;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  bool _localLock = false;
  bool _authoritative = false;

  _Phase get _phase {
    if (_authoritative) return _Phase.enteringGame;
    if (_localLock) return _Phase.preparing;
    return _Phase.lobby;
  }

  Future<void> _start() async {
    setState(() => _localLock = true);
    try {
      // The start operation's own network calls (pack check, broadcast,
      // status write) — resolves quickly.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (widget.operationFails) {
        throw StateError('start failed');
      }
      // The AUTHORITATIVE signal (realtime self-echo / reconcile poll)
      // arrives independently and much later — this is what a slow
      // connection or a disabled self-echo looks like.
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _authoritative = true);
      });
    } catch (_) {
      if (mounted) setState(() => _localLock = false);
      return;
    } finally {
      if (widget.clearLockOnOperationReturn && mounted) {
        setState(() => _localLock = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            ElevatedButton(onPressed: _start, child: const Text('Start')),
            switch (_phase) {
              _Phase.lobby => const Text('Lobby'),
              _Phase.preparing => const Text('Preparing'),
              _Phase.enteringGame => const Text('In Game'),
            },
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'REGRESSION: clearing the lock on operation-return flashes the lobby '
    'before the authoritative signal arrives',
    (tester) async {
      await tester.pumpWidget(
        const _Harness(clearLockOnOperationReturn: true),
      );
      await tester.tap(find.text('Start'));
      await tester.pump(); // lock engaged
      expect(find.text('Preparing'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 60)); // op returns
      expect(
        find.text('Lobby'),
        findsOneWidget,
        reason: 'operation finished but authoritative signal has not — '
            'this is the lobby-flash bug',
      );

      await tester.pump(const Duration(milliseconds: 300)); // authoritative
      expect(find.text('In Game'), findsOneWidget);
    },
  );

  testWidgets(
    'FIX: the lock stays up continuously from tap until the authoritative '
    'signal arrives — the lobby never renders',
    (tester) async {
      await tester.pumpWidget(
        const _Harness(clearLockOnOperationReturn: false),
      );
      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(find.text('Preparing'), findsOneWidget);

      // Poll frame-by-frame through the entire window — Lobby must never
      // appear, not even for a single frame.
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        expect(find.text('Lobby'), findsNothing);
      }
      expect(find.text('In Game'), findsOneWidget);
    },
  );

  testWidgets(
    'FIX: a genuine failure clears the lock and returns to Lobby (never '
    'silent — the button is tappable again)',
    (tester) async {
      await tester.pumpWidget(
        const _Harness(
          clearLockOnOperationReturn: false,
          operationFails: true,
        ),
      );
      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(find.text('Preparing'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('Lobby'), findsOneWidget);
    },
  );

  testWidgets(
    'FIX: a stale/regressed authoritative read while the lock is up must '
    'not be able to force a return to Lobby',
    (tester) async {
      await tester.pumpWidget(
        const _Harness(clearLockOnOperationReturn: false),
      );
      final state = tester.state<_HarnessState>(find.byType(_Harness));
      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(find.text('Preparing'), findsOneWidget);

      // Simulate a stale poll response regressing the authoritative flag
      // back to false mid-flight — the derived phase must fall back to
      // Preparing (the local lock), never Lobby.
      // ignore: invalid_use_of_protected_member
      state.setState(() => state._authoritative = false);
      await tester.pump();
      expect(find.text('Preparing'), findsOneWidget);
      expect(find.text('Lobby'), findsNothing);

      // Drain the still-pending "authoritative signal arrives" timer (fires
      // ~350ms after _start began: 50ms op + 300ms signal delay) so it
      // doesn't fire after the test (and widget tree) has torn down.
      await tester.pump(const Duration(milliseconds: 1000));
    },
  );
}
