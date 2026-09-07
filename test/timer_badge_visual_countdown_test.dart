// Tests for the real-device follow-up timer fix (see nhie_game_screen.dart's
// _NhieTimerBadge / meme_game_screen.dart's _MemeTimerBadge doc comments):
// the countdown display used to be driven entirely by the PROVIDER's own
// Timer.periodic calling notifyListeners(), which on-device left the
// number frozen at its initial value until some unrelated interaction
// caused a rebuild — even though the provider's own ticker (and the
// eventual authoritative timeout) kept running correctly underneath. The
// fix made the badge own a second, PURELY PRESENTATIONAL Timer.periodic
// that only ever calls setState() to redraw, recomputing `remaining`
// fresh from the authoritative deadline every second — independent of
// however/whenever the provider's own notifications land.
//
// _NhieTimerBadge/_MemeTimerBadge are private to their own screen files
// (Dart privacy is per-file, not per-package) and can't be imported here,
// so this exercises a minimal widget built from the exact same pattern —
// a StatefulWidget whose own local ticker recomputes `deadline - now` and
// calls setState(), never touching any external provider/engine — to
// prove that PATTERN genuinely redraws every second with zero outside
// interaction, and behaves correctly across deadline changes and
// disposal. The two real badges are structurally identical (same
// initState/didUpdateWidget/dispose/_seconds shape), just with their own
// medal-badge chrome layered on top.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TickerBadge extends StatefulWidget {
  const _TickerBadge({required this.deadlineMs, required this.totalSeconds});
  final int? deadlineMs;
  final int totalSeconds;

  @override
  State<_TickerBadge> createState() => _TickerBadgeState();
}

class _TickerBadgeState extends State<_TickerBadge> {
  Timer? _ticker;
  int _tickCount = 0;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant _TickerBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadlineMs != widget.deadlineMs) _restart();
  }

  void _restart() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _tickCount++);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int get _seconds {
    final deadline = widget.deadlineMs;
    if (deadline == null || widget.totalSeconds <= 0) return 0;
    final elapsed = (DateTime.now().millisecondsSinceEpoch - deadline) ~/ 1000;
    return (widget.totalSeconds - elapsed).clamp(0, widget.totalSeconds);
  }

  @override
  Widget build(BuildContext context) => Text('$_seconds');
}

void main() {
  group('Timer visual countdown (real-device follow-up)', () {
    testWidgets(
      '1/2. the displayed number updates every second with ZERO external '
      'interaction — no tap, no provider notifyListeners(), nothing but '
      'time passing',
      (tester) async {
        // _seconds recomputes from real DateTime.now() every tick — the
        // same as the two real badges — so exercising it faithfully needs
        // real wall-clock time to actually pass, not flutter_test's fake
        // scheduler clock (tester.pump(duration) advances THAT clock, not
        // DateTime.now(), so a Timer.periodic fired via a fake pump would
        // recompute against an unmoved "now" and look like nothing
        // changed — runAsync steps outside the fake zone for real delays).
        await tester.runAsync(() async {
          final now = DateTime.now().millisecondsSinceEpoch;
          await tester.pumpWidget(
            MaterialApp(
              home: _TickerBadge(deadlineMs: now, totalSeconds: 30),
            ),
          );

          int shown() =>
              int.parse((tester.widget(find.byType(Text)) as Text).data!);

          final start = shown();
          expect(start, anyOf(29, 30));

          await Future<void>.delayed(const Duration(milliseconds: 1400));
          await tester.pump();
          expect(shown(), lessThanOrEqualTo(start - 1));

          await Future<void>.delayed(const Duration(milliseconds: 1400));
          await tester.pump();
          expect(shown(), lessThanOrEqualTo(start - 2));
        });
      },
    );

    testWidgets(
      '3. remaining time is recomputed fresh from the authoritative '
      'deadline every tick, not decremented from a locally-cached count — '
      'a widget mounted midway through an already-running deadline shows '
      'the correct already-elapsed value immediately, on its very first '
      'build, before its own ticker has fired even once',
      (tester) async {
        final tenSecondsAgo =
            DateTime.now().millisecondsSinceEpoch - 10000;
        await tester.pumpWidget(
          MaterialApp(
            home: _TickerBadge(deadlineMs: tenSecondsAgo, totalSeconds: 30),
          ),
        );
        final shown = int.parse(
          (tester.widget(find.byType(Text)) as Text).data!,
        );
        // ~10s already elapsed against a 30s deadline → ~20 remaining;
        // tolerant of the same sub-second settle timing as the test above.
        expect(shown, anyOf(19, 20));
      },
    );

    testWidgets(
      '3. a brand new deadline (next round) resets the displayed '
      'countdown to the new round\'s full duration, not a continuation '
      'of the old one',
      (tester) async {
        await tester.runAsync(() async {
          int shown() =>
              int.parse((tester.widget(find.byType(Text)) as Text).data!);

          final firstDeadline = DateTime.now().millisecondsSinceEpoch;
          await tester.pumpWidget(
            MaterialApp(
              home: _TickerBadge(deadlineMs: firstDeadline, totalSeconds: 30),
            ),
          );
          final start = shown();

          await Future<void>.delayed(const Duration(milliseconds: 2400));
          await tester.pump();
          // ~2s ticked off the FIRST deadline/duration pair.
          expect(shown(), lessThanOrEqualTo(start - 2));

          final secondDeadline = DateTime.now().millisecondsSinceEpoch;
          await tester.pumpWidget(
            MaterialApp(
              home: _TickerBadge(deadlineMs: secondDeadline, totalSeconds: 15),
            ),
          );
          // A genuinely NEW deadline+duration — must read close to the new
          // 15s total, not "~27 remaining" (30 - 2 - 1) as it would if the
          // widget kept counting down the OLD round instead of resetting.
          expect(shown(), anyOf(14, 15));
        });
      },
    );

    testWidgets(
      '4. reaching zero clamps at zero and never goes negative — the '
      'presentational ticker keeps running (still purely cosmetic) past '
      'expiry without crashing or wrapping around',
      (tester) async {
        final longAgo = DateTime.now().millisecondsSinceEpoch - 60000;
        await tester.pumpWidget(
          MaterialApp(home: _TickerBadge(deadlineMs: longAgo, totalSeconds: 5)),
        );
        expect(find.text('0'), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('0'), findsOneWidget);
      },
    );

    testWidgets(
      '5. the ticker is cancelled on dispose — no pending timer, no '
      'exception, when the widget unmounts mid-countdown',
      (tester) async {
        final now = DateTime.now().millisecondsSinceEpoch;
        await tester.pumpWidget(
          MaterialApp(home: _TickerBadge(deadlineMs: now, totalSeconds: 30)),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        // If dispose() failed to cancel the Timer.periodic, flutter_test's
        // own pending-timer check at tearDown would fail this test.
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'null deadline (timer disabled) renders 0 and starts no meaningful '
      'countdown — matches "timer OFF: no countdown" requirement',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: _TickerBadge(deadlineMs: null, totalSeconds: 30),
          ),
        );
        expect(find.text('0'), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('0'), findsOneWidget);
      },
    );
  });
}
