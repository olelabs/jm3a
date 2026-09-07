// Regression test for the "no game can start" bug.
//
// Root cause: LobbyScreen ran the whole Start-Game sequence (_doStartGame:
// pack checks, the pre-game sheet, broadcasts) using the BuildContext of the
// _BottomActionBar. Making the lobby render the full-screen _GameStartingLock
// as soon as `isStartingGame` became true REPLACED (and therefore unmounted)
// that bar, so the in-flight async sequence hit `if (!ctx.mounted) return;`
// and aborted BEFORE it ever created the game session — for every game.
//
// The fix keeps the bar MOUNTED while starting (it is only rebuilt with the
// button disabled); the full-screen lock is driven by room STATUS, which only
// flips after the context-dependent steps are done. This test reproduces the
// mechanism generically: an async operation kicked off from a child's context
// survives a rebuild that merely DISABLES the child, but NOT one that REPLACES
// it — exactly the difference between the fix and the regression.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors _onStartGame: on tap, capture this widget's context and kick off an
/// async op that, after a delay (the pack-check round-trip), only "starts the
/// game" if the context is still mounted.
class _StartBar extends StatelessWidget {
  const _StartBar({required this.onResult});
  final void Function(bool started) onResult;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final ctx = context; // captured, like _doStartGame's `ctx`
        await Future<void>.delayed(const Duration(milliseconds: 100));
        onResult(ctx.mounted); // "started" iff the context is still valid
      },
      child: const Text('Start'),
    );
  }
}

class _Harness extends StatefulWidget {
  const _Harness({required this.replaceOnStarting, required this.onResult});

  /// true reproduces the REGRESSION (replace the bar with a lock while
  /// starting); false is the FIX (keep the bar, just disable it).
  final bool replaceOnStarting;
  final void Function(bool started) onResult;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () => setState(() => _starting = true),
              child: const Text('BeginStarting'),
            ),
            if (_starting && widget.replaceOnStarting)
              const Text('Preparing the game…') // lock: bar is GONE
            else
              _StartBar(onResult: widget.onResult), // bar stays mounted
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'REGRESSION: replacing the bar while starting unmounts its context → '
    'game never starts',
    (tester) async {
      bool? started;
      await tester.pumpWidget(
        _Harness(replaceOnStarting: true, onResult: (s) => started = s),
      );
      // Tap Start (captures context + begins the async op), then flip to the
      // full-screen lock, which removes the bar.
      await tester.tap(find.text('Start'));
      await tester.tap(find.text('BeginStarting'));
      await tester.pump(); // bar replaced by the lock
      await tester.pump(const Duration(milliseconds: 150)); // op completes
      expect(find.text('Preparing the game…'), findsOneWidget);
      expect(started, isFalse, reason: 'context was unmounted → start aborted');
    },
  );

  testWidgets(
    'FIX: keeping the bar mounted (disabled) while starting preserves its '
    'context → game starts',
    (tester) async {
      bool? started;
      await tester.pumpWidget(
        _Harness(replaceOnStarting: false, onResult: (s) => started = s),
      );
      await tester.tap(find.text('Start'));
      await tester.tap(find.text('BeginStarting'));
      await tester.pump(); // bar rebuilt, still mounted
      await tester.pump(const Duration(milliseconds: 150)); // op completes
      expect(started, isTrue, reason: 'context stayed mounted → start proceeds');
    },
  );
}
