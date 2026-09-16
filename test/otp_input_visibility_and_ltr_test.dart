// Regression coverage for two OTP screen UI bugs, both in the same
// [_OtpInput] widget the iOS keyboard-stability fix already covers (see
// otp_input_stability_test.dart):
//
// BUG 1 — a visible input control appearing over the OTP boxes.
// ROOT CAUSE: the app's global InputDecorationTheme (app_theme.dart's
// AppTheme._build) sets filled:true/fillColor plus enabledBorder/
// focusedBorder/errorBorder/focusedErrorBorder for every ordinary text
// field in the app. The OTP field's own InputDecoration only overrode the
// generic `border` property — Flutter's InputDecoration.applyDefaults()
// fills every OTHER unset field (filled, fillColor, enabledBorder,
// focusedBorder, ...) from the theme independently, and the state-specific
// borders (enabledBorder/focusedBorder/etc.) take precedence over the
// generic `border` fallback whenever the theme sets them — so overriding
// only `border: InputBorder.none` never actually suppressed the theme's
// filled rectangle or its borders. The fix sets filled:false and every
// border variant explicitly.
//
// BUG 2 — the OTP digits (and box order) following the ambient RTL
// direction in Arabic. ROOT CAUSE: nothing on this screen overrode
// Directionality, so Arabic's app-wide RTL reached the Row of six boxes
// (Row lays children out along the ambient text direction) and the
// TextField's own cursor/selection movement. The fix wraps the whole
// input in an explicit `Directionality(textDirection: TextDirection.ltr)`
// and additionally sets the TextField's own `textDirection: ltr`.
//
// These tests pump the REAL app theme (AppTheme.light()) — not a bare
// default ThemeData, which wouldn't reproduce bug 1 at all, since default
// ThemeData's InputDecorationTheme sets neither filled nor borders.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/providers/auth_provider.dart';
import 'package:jma3a/core/storage/secure_storage_service.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/auth/data/auth_repository.dart';
import 'package:jma3a/features/auth/presentation/screens/otp_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

/// Pumps the real OtpScreen with the app's REAL production theme and a
/// chosen locale, on a realistic phone viewport.
Future<void> _pumpOtpScreen(WidgetTester tester, {Locale? locale}) async {
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
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OtpScreen(identifier: 'someone@example.com'),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _drainTimers(WidgetTester tester) async =>
    tester.pump(const Duration(seconds: 61));

TextField _otpTextField(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  group('BUG 1 — no visible input chrome leaks from the app theme', () {
    testWidgets('filled is off and every border variant is explicitly '
        'suppressed — not just the generic `border` field', (tester) async {
      await _pumpOtpScreen(tester);

      final decoration = _otpTextField(tester).decoration;
      expect(decoration, isNotNull);
      expect(decoration!.filled, isFalse,
          reason: 'the theme sets filled:true — this field must opt out '
              'explicitly, "border: none" alone does not do that');
      expect(decoration.border, InputBorder.none);
      expect(decoration.enabledBorder, InputBorder.none,
          reason: 'the theme sets its own enabledBorder, which otherwise '
              'wins over the generic `border` fallback');
      expect(decoration.focusedBorder, InputBorder.none);
      expect(decoration.errorBorder, InputBorder.none);
      expect(decoration.focusedErrorBorder, InputBorder.none);
      expect(decoration.disabledBorder, InputBorder.none);

      await _drainTimers(tester);
    });

    testWidgets('resolving this decoration against the real app theme '
        'paints no fill color and no border — an actual, not just '
        'field-by-field, proof the theme cannot leak through',
        (tester) async {
      await _pumpOtpScreen(tester);

      final theme = Theme.of(tester.element(find.byType(TextField)));
      final resolved = _otpTextField(tester)
          .decoration!
          .applyDefaults(theme.inputDecorationTheme);

      expect(resolved.filled, isFalse);
      expect(resolved.enabledBorder, InputBorder.none);
      expect(resolved.focusedBorder, InputBorder.none);

      await _drainTimers(tester);
    });
  });

  group('BUG 2 — OTP input stays LTR regardless of app locale', () {
    testWidgets('in Arabic, the six boxes still lay out left-to-right — '
        'box 0 (first digit) stays left of box 5 (last digit), not '
        'reversed by the ambient RTL direction', (tester) async {
      await _pumpOtpScreen(tester, locale: const Locale('ar'));

      // Confirms the ambient direction really is RTL at this screen —
      // otherwise this test would trivially pass for the wrong reason.
      final ambientDirection = Directionality.of(
        tester.element(find.byType(OtpScreen)),
      );
      expect(ambientDirection, TextDirection.rtl);

      // 5 digits, not 6 — _submit() auto-fires at the full length and
      // would reach the (unstubbed) AuthProvider.verifyOtp here; box
      // ordering is already fully proven without ever completing the code.
      await tester.enterText(find.byType(TextField), '12345');
      await tester.pump();

      final firstBoxLeft = tester.getTopLeft(find.text('1')).dx;
      final lastBoxLeft = tester.getTopLeft(find.text('5')).dx;
      expect(
        firstBoxLeft,
        lessThan(lastBoxLeft),
        reason: 'the first-typed digit must render on the left and the '
            'last-typed digit on the right, even in Arabic — Row lays '
            'children out along the ambient direction unless overridden, '
            'which is exactly the bug this pins',
      );

      await _drainTimers(tester);
    });

    testWidgets('the Directionality immediately wrapping the OTP input is '
        'explicitly LTR even under an RTL ancestor', (tester) async {
      await _pumpOtpScreen(tester, locale: const Locale('ar'));

      final textFieldDirection = Directionality.of(
        tester.element(find.byType(TextField)),
      );
      expect(textFieldDirection, TextDirection.ltr);

      await _drainTimers(tester);
    });

    testWidgets('the TextField itself also declares LTR explicitly — '
        'defense in depth alongside the wrapping Directionality',
        (tester) async {
      await _pumpOtpScreen(tester, locale: const Locale('ar'));

      expect(_otpTextField(tester).textDirection, TextDirection.ltr);

      await _drainTimers(tester);
    });

    testWidgets('English and French stay LTR as before — this fix does not '
        'change behavior for the two locales that were already correct',
        (tester) async {
      for (final locale in [const Locale('en'), const Locale('fr')]) {
        await _pumpOtpScreen(tester, locale: locale);
        expect(
          Directionality.of(tester.element(find.byType(TextField))),
          TextDirection.ltr,
        );
        await _drainTimers(tester);
      }
    });
  });

  group('digits-only enforcement (already correct; pinned so it cannot '
      'regress alongside this fix)', () {
    testWidgets('letters, punctuation, spaces and Arabic-Indic digits are '
        'all rejected — only ASCII 0-9 ever reaches the controller',
        (tester) async {
      await _pumpOtpScreen(tester);

      // ٠١٢٣٤٥ = Arabic-Indic digits 0-5 (U+0660-U+0665) — a real risk on
      // a device with an Arabic numeral keyboard, distinct from the
      // English-letter/punctuation risk.
      await tester.enterText(
        find.byType(TextField),
        'a1 2-٣b٤5!6ع',
      );
      await tester.pump();

      final controller = tester.state<EditableTextState>(
        find.byType(EditableText),
      ).widget.controller;

      expect(
        controller.text,
        '1256',
        reason: 'only the literal ASCII digits (1, 2, 5, 6) from the mixed '
            'input should survive; letters, Arabic-Indic digits (٣, ٤), '
            'punctuation and spaces must all be filtered out',
      );

      await _drainTimers(tester);
    });
  });
}
