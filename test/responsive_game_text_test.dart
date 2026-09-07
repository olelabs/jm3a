// Sanity checks for item 18.3's ResponsiveGameText, written and run before
// the full test suite below to catch a real overflow/sizing bug early
// (the same reason the pack-preview work's own widget test caught a real
// GameCardPreview overflow earlier in this project).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/shared/widgets/game/responsive_game_text.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child, {double width = 300}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: width, height: 200, child: child),
          ),
        ),
      );

  testWidgets('18. short text renders at the full requested font size',
      (tester) async {
    await pump(
      tester,
      const ResponsiveGameText('Hi', style: TextStyle(fontSize: 24)),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style!.fontSize, 24);
  });

  testWidgets(
    '19/20. very long text scales down below the requested size and never '
    'overflows',
    (tester) async {
      final longText = 'word ' * 200;
      await pump(
        tester,
        ResponsiveGameText(
          longText,
          maxLines: 4,
          style: const TextStyle(fontSize: 24),
        ),
        width: 200,
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.fontSize, lessThan(24));
    },
  );

  testWidgets('never shrinks below minFontSize even for extreme content',
      (tester) async {
    final extremeText = 'x' * 5000;
    await pump(
      tester,
      ResponsiveGameText(
        extremeText,
        minFontSize: 10,
        maxLines: 2,
        style: const TextStyle(fontSize: 30),
      ),
      width: 150,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style!.fontSize, 10);
  });

  testWidgets('21/22. Arabic RTL and French/English text render without '
      'throwing', (tester) async {
    for (final locale in [
      const Locale('ar'),
      const Locale('fr'),
      const Locale('en'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: const Scaffold(
              body: SizedBox(
                width: 250,
                height: 150,
                child: ResponsiveGameText(
                  'مرحبا بكم في هذه اللعبة الممتعة جدا والطويلة',
                  maxLines: 3,
                  style: TextStyle(fontSize: 22),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });
}
