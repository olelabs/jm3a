// Regression coverage for the iOS report: "every time the user enters a
// number the OTP input appears to rebuild — the keyboard closes and then
// reopens after each digit".
//
// ROOT CAUSE: OtpScreen rendered SIX separate TextFormFields, each owning
// its own TextEditingController and FocusNode, and _onChanged moved focus
// on every keystroke (`_focusNodes[index + 1].requestFocus()`). Moving
// focus between two distinct text fields tears the platform text-input
// connection down and opens a new one (TextInput.clearClient followed by
// setClient/show); on iOS that resigns and re-acquires first responder,
// which visibly dismisses and re-presents the keyboard — once per digit.
// Two screen-wide setStates made it worse: one fired unconditionally on
// every keystroke, and the resend countdown fired another every second.
//
// THE FIX: one always-mounted TextField holds the whole code, with the six
// boxes reduced to pure presentation rendered from its text. Focus never
// moves while typing, so the input connection is never torn down.
//
// These tests assert the lifecycle invariants that fix guarantees, at the
// layer the bug actually lived in — no re-focus hack, no delay, and no
// platform channel needed. `EditableText` is Flutter's own text-input
// primitive: exactly one of them, whose State/controller/focus node are
// identical objects before and after each digit, IS the statement "the
// input was never recreated and focus never moved".

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/providers/auth_provider.dart';
import 'package:jma3a/core/storage/secure_storage_service.dart';
import 'package:jma3a/features/auth/data/auth_repository.dart';
import 'package:jma3a/features/auth/presentation/screens/otp_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

/// Pumps the real OtpScreen on a realistic phone viewport. Deliberately NOT
/// wrapped in a GoRouter: these tests never complete the 6th digit, so
/// _submit()'s navigation is never reached and the screen can be exercised
/// in isolation.
Future<void> _pumpOtpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final repo = _MockAuthRepository();
  final secureStorage = _MockSecureStorageService();
  when(() => repo.authStateStream).thenAnswer((_) => const Stream.empty());

  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: AuthProvider(authRepository: repo, secureStorage: secureStorage),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OtpScreen(identifier: 'someone@example.com'),
      ),
    ),
  );
  // Lets initState's post-frame requestFocus land.
  await tester.pump();
}

/// The screen legitimately owns long-lived timers — the 60-second resend
/// countdown, plus flutter_animate's entry-animation delays. Run them out
/// so neither trips the binding's "a Timer is still pending" invariant.
Future<void> _drainTimers(WidgetTester tester) async =>
    tester.pump(const Duration(seconds: 61));

/// The single text-input primitive behind the six boxes.
EditableTextState _input(WidgetTester tester) =>
    tester.state<EditableTextState>(find.byType(EditableText));

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  testWidgets(
    'the whole code lives in exactly ONE text input — not one per box, '
    'which is what made every digit move focus between fields',
    (tester) async {
      await _pumpOtpScreen(tester);

      expect(
        find.byType(EditableText),
        findsOneWidget,
        reason:
            'six EditableTexts is the original bug: with one per box, '
            'auto-advance necessarily moves focus across the platform '
            'text-input connection on every keystroke',
      );

      await _drainTimers(tester);
    },
  );

  testWidgets(
    'entering digits 1..5 never recreates the input, its controller, or '
    'its focus node — and focus never leaves it (the keyboard stays up)',
    (tester) async {
      await _pumpOtpScreen(tester);

      final initial = _input(tester);
      final controller = initial.widget.controller;
      final focusNode = initial.widget.focusNode;
      expect(
        focusNode.hasFocus,
        isTrue,
        reason: 'initState focuses the field so the keyboard opens',
      );

      // enterText replaces the field's whole contents, so a keystroke is
      // modelled as the cumulative code after it. Deliberately stops at 5
      // digits: the 6th auto-submits, a separate (and intended) path. The
      // reported bug is about every digit DURING entry.
      for (final typedSoFar in ['1', '12', '123', '1234', '12345']) {
        await tester.enterText(find.byType(EditableText), typedSoFar);
        await tester.pump();

        final current = _input(tester);
        expect(
          identical(current, initial),
          isTrue,
          reason:
              'a different EditableTextState means the input was torn down '
              'and rebuilt at "$typedSoFar" — exactly what dismissed the '
              'iOS keyboard',
        );
        expect(
          identical(current.widget.controller, controller),
          isTrue,
          reason: 'the controller must outlive every keystroke',
        );
        expect(
          identical(current.widget.focusNode, focusNode),
          isTrue,
          reason:
              'a different FocusNode is the literal focus move that closed '
              'the keyboard',
        );
        expect(
          focusNode.hasFocus,
          isTrue,
          reason: 'focus must stay on the code field at "$typedSoFar"',
        );
      }

      expect(controller.text, '12345');

      await _drainTimers(tester);
    },
  );

  testWidgets(
    'the six boxes render the typed digits — presentation preserved now '
    'that they are no longer text fields themselves',
    (tester) async {
      await _pumpOtpScreen(tester);

      await tester.enterText(find.byType(EditableText), '123');
      await tester.pump();

      for (final digit in ['1', '2', '3']) {
        expect(
          find.text(digit),
          findsOneWidget,
          reason: 'digit "$digit" must be visible in its box',
        );
      }

      await _drainTimers(tester);
    },
  );

  testWidgets(
    'a screen-wide rebuild driven by the resend countdown does not recreate '
    'the input or drop focus — state changes elsewhere must not touch it',
    (tester) async {
      await _pumpOtpScreen(tester);

      final before = _input(tester);
      final controller = before.widget.controller;
      final focusNode = before.widget.focusNode;

      await tester.enterText(find.byType(EditableText), '12');
      await tester.pump();

      // Let the 1-second resend countdown tick several times mid-entry.
      await tester.pump(const Duration(seconds: 3));

      final after = _input(tester);
      expect(identical(after, before), isTrue);
      expect(identical(after.widget.controller, controller), isTrue);
      expect(identical(after.widget.focusNode, focusNode), isTrue);
      expect(focusNode.hasFocus, isTrue);
      expect(
        controller.text,
        '12',
        reason: 'the countdown must not disturb what has been typed',
      );

      await _drainTimers(tester);
    },
  );
}
