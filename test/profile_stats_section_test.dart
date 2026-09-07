// Tests for item 2's redesigned profile statistics section
// (ProfileStatsSection, profile_screen.dart) — the score hero card +
// Games/Friends/Packs/Followers mini-stat row that replaced the old
// 5-identical-boxes _StatsRow.
//
// ProfileStatsSection is deliberately a plain, provider-free, l10n-free
// public widget (unlike every other widget in profile_screen.dart) so it
// can be pumped directly here with no ProfileProvider/AuthProvider/
// go_router setup — see the class doc comment in profile_screen.dart for
// why. The `_StatsRow` wrapper that actually binds it to ProfileProvider
// in the real screen is private and untestable in isolation, matching how
// this suite's sibling game_card_preview_test.dart already handles the
// same constraint for other private/public widget pairs in this codebase.
//
// This suite is specifically the regression guard for the bug that was
// just fixed: an Expanded-inside-a-horizontally-scrolling-
// SingleChildScrollView combination in the old _StatsRow threw
// "RenderFlex children have non-zero flex but incoming width constraints
// are unbounded" on every layout, which (because ProfileScreen is a
// permanent IndexedStack sibling of RoomBrowserScreen) surfaced as
// unrelated "child._parent == this" / "!semantics.parentDataDirty"
// assertions elsewhere in the app. Every test here pumps at a real,
// finite width and asserts tester.takeException() is null — the same
// class of failure would reproduce here as a widget-test exception if it
// were reintroduced.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/features/profile/presentation/screens/profile_screen.dart';

const _labels = (
  score: 'Score',
  games: 'Games',
  friends: 'Friends',
  packs: 'Packs',
  followers: 'Followers',
);

Widget _harness({
  required Widget child,
  double width = 375,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1.0,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: SizedBox(width: width, child: SingleChildScrollView(child: child)),
        ),
      ),
    ),
  );
}

ProfileStatsSection _section({
  bool loaded = true,
  int score = 12450,
  int games = 42,
  int friends = 18,
  int packs = 7,
  int followers = 124,
}) => ProfileStatsSection(
  loaded: loaded,
  score: score,
  scoreLabel: _labels.score,
  games: games,
  gamesLabel: _labels.games,
  friends: friends,
  friendsLabel: _labels.friends,
  packs: packs,
  packsLabel: _labels.packs,
  followers: followers,
  followersLabel: _labels.followers,
);

void main() {
  testWidgets('normal score/stat display renders every label and a '
      'thousands-grouped score', (tester) async {
    await tester.pumpWidget(_harness(child: _section()));
    await tester.pump(const Duration(milliseconds: 950)); // let count-up finish

    expect(find.text('12,450'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('124'), findsOneWidget);
    expect(find.text(_labels.score), findsOneWidget);
    expect(find.text(_labels.games), findsOneWidget);
    expect(find.text(_labels.friends), findsOneWidget);
    expect(find.text(_labels.packs), findsOneWidget);
    expect(find.text(_labels.followers), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long score value renders without overflowing', (tester) async {
    await tester.pumpWidget(
      _harness(child: _section(score: 123456789), width: 320),
    );
    await tester.pump(const Duration(milliseconds: 950));

    expect(find.text('123,456,789'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero values render as "0", not blank or a dash', (tester) async {
    await tester.pumpWidget(
      _harness(
        child: _section(score: 0, games: 0, friends: 0, packs: 0, followers: 0),
      ),
    );
    await tester.pump(const Duration(milliseconds: 950));

    expect(find.text('0'), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('not-yet-loaded shows a placeholder dash instead of a false '
      'zero for every value', (tester) async {
    await tester.pumpWidget(_harness(child: _section(loaded: false)));
    await tester.pump();

    expect(find.text('—'), findsNWidgets(5));
    expect(find.text('0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders correctly under Arabic RTL with no overflow',
      (tester) async {
    await tester.pumpWidget(
      _harness(child: _section(), direction: TextDirection.rtl),
    );
    await tester.pump(const Duration(milliseconds: 950));

    expect(find.text(_labels.score), findsOneWidget);
    expect(find.text(_labels.followers), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow on a narrow small-Android width',
      (tester) async {
    await tester.pumpWidget(_harness(child: _section(), width: 320));
    await tester.pump(const Duration(milliseconds: 950));

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow at a very narrow width with long '
      'values together — the combined stress case', (tester) async {
    await tester.pumpWidget(
      _harness(
        child: _section(score: 9999999, followers: 123456),
        width: 280,
      ),
    );
    await tester.pump(const Duration(milliseconds: 950));

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow at 2x text scaling (accessibility)',
      (tester) async {
    await tester.pumpWidget(
      _harness(child: _section(), width: 320, textScale: 2.0),
    );
    await tester.pump(const Duration(milliseconds: 950));

    expect(tester.takeException(), isNull);
  });

  testWidgets('the followers tile is tappable and calls onFollowersTap',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 375,
            child: ProfileStatsSection(
              loaded: true,
              score: 100,
              scoreLabel: _labels.score,
              games: 1,
              gamesLabel: _labels.games,
              friends: 1,
              friendsLabel: _labels.friends,
              packs: 1,
              packsLabel: _labels.packs,
              followers: 1,
              followersLabel: _labels.followers,
              onFollowersTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 950));

    await tester.tap(find.text(_labels.followers));
    await tester.pump();
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });
}
