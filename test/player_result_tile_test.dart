// Widget tests for PlayerResultTile — the shared per-player result row
// used by NHIE's inline results view and Meme's results/history screens
// (items 4/5, result-screen pass). Provider-free, l10n-backed public
// widget — pumped directly here, matching the established pattern for
// other shared game widgets in this codebase (see game_flip_card_test.dart's
// own header comment).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/j_theme_extension.dart';
import 'package:jma3a/shared/widgets/game/player_result_tile.dart';

// UserAvatar (rendered by every PlayerResultTile) reads
// context.jColors (Theme.of(context).extension<JThemeExtension>()!) —
// a bare MaterialApp() theme doesn't register that extension, which
// throws a null-check failure. Matches the identical fix already
// established in animated_reaction_overlay_test.dart/game_flip_card_test.dart
// for the same dependency.
ThemeData _testTheme() => ThemeData(extensions: const [JThemeExtension.light]);

Widget _wrap(Widget child, {double width = 375}) => MaterialApp(
  theme: _testTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SizedBox(
      width: width,
      child: SingleChildScrollView(child: child),
    ),
  ),
);

void main() {
  group('PlayerResultTile — status distinction (item 4)', () {
    testWidgets('a responded row shows the response content, no status label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const PlayerResultTile(
            avatarUrl: null,
            avatarConfig: null,
            isPremium: false,
            displayName: 'Sara',
            status: PlayerResultStatus.responded,
            responseContent: Text('a real answer'),
          ),
        ),
      );
      expect(find.text('Sara'), findsOneWidget);
      expect(find.text('a real answer'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_bottom_rounded), findsNothing);
      expect(find.byIcon(Icons.skip_next_rounded), findsNothing);
    });

    testWidgets('a timed-out row shows "Did not respond in time", never the '
        'responseContent even if one is (incorrectly) supplied', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const PlayerResultTile(
            avatarUrl: null,
            avatarConfig: null,
            isPremium: false,
            displayName: 'Omar',
            status: PlayerResultStatus.timedOut,
            responseContent: Text('should never show'),
          ),
        ),
      );
      expect(find.text('Did not respond in time'), findsOneWidget);
      expect(find.text('should never show'), findsNothing);
      expect(find.byIcon(Icons.hourglass_bottom_rounded), findsOneWidget);
    });

    testWidgets('a skipped row shows "Skipped", distinct from timed-out', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const PlayerResultTile(
            avatarUrl: null,
            avatarConfig: null,
            isPremium: false,
            displayName: 'Lina',
            status: PlayerResultStatus.skipped,
          ),
        ),
      );
      expect(find.text('Skipped'), findsOneWidget);
      expect(find.text('Did not respond in time'), findsNothing);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
    });

    testWidgets(
      'renders correctly under Arabic RTL for every status, no overflow',
      (tester) async {
        for (final status in PlayerResultStatus.values) {
          await tester.pumpWidget(
            MaterialApp(
              theme: _testTheme(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('ar'),
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: SizedBox(
                    width: 340,
                    child: PlayerResultTile(
                      avatarUrl: null,
                      avatarConfig: null,
                      isPremium: false,
                      displayName: 'مستخدم',
                      status: status,
                      responseContent: const Text(
                        'رد طويل جداً رد طويل جداً رد طويل جداً',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull, reason: status.name);
        }
      },
    );
  });

  group('PlayerResultTile — responsive/narrow width', () {
    testWidgets('a very long name and response never overflow at 280px', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const PlayerResultTile(
            avatarUrl: null,
            avatarConfig: null,
            isPremium: false,
            displayName: 'A Very Long Display Name That Keeps Going',
            status: PlayerResultStatus.responded,
            responseContent: Text(
              'An extremely long response that should wrap or ellipsize '
              'instead of overflowing the available width of this tile '
              'on a narrow phone screen.',
            ),
          ),
          width: 280,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a timed-out row with a long name never overflows at 280px', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const PlayerResultTile(
            avatarUrl: null,
            avatarConfig: null,
            isPremium: false,
            displayName: 'Another Extremely Long Player Display Name',
            status: PlayerResultStatus.timedOut,
          ),
          width: 280,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('with a trailing widget present, still no overflow at 320px', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const PlayerResultTile(
            avatarUrl: null,
            avatarConfig: null,
            isPremium: false,
            displayName: 'Karim',
            status: PlayerResultStatus.responded,
            responseContent: Text('yes'),
            trailing: SizedBox(
              width: 70,
              height: 32,
              child: ColoredBox(color: Colors.red),
            ),
          ),
          width: 320,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('PlayerResultTile — viewer highlight', () {
    testWidgets('isViewer:true renders a star marker next to the name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const PlayerResultTile(
            avatarUrl: null,
            avatarConfig: null,
            isPremium: false,
            displayName: 'You',
            status: PlayerResultStatus.responded,
            isViewer: true,
            responseContent: Text('yes'),
          ),
        ),
      );
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('isViewer:false (default) shows no star marker', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const PlayerResultTile(
            avatarUrl: null,
            avatarConfig: null,
            isPremium: false,
            displayName: 'Other',
            status: PlayerResultStatus.responded,
            responseContent: Text('yes'),
          ),
        ),
      );
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });
  });

  group('ResultCompletionChip', () {
    testWidgets('shows the responded/total count', (tester) async {
      await tester.pumpWidget(
        _wrap(const ResultCompletionChip(responded: 3, total: 5)),
      );
      expect(find.text('3/5'), findsOneWidget);
    });

    testWidgets('renders without exception when complete (responded==total)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const ResultCompletionChip(responded: 4, total: 4)),
      );
      expect(find.text('4/4'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
