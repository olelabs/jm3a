// Regression coverage for "BoxConstraints forces an infinite width" when
// opening Friends -> Explore/Blocked.
//
// Root cause: the app's global theme (AppTheme, see app_theme.dart's
// elevatedButtonTheme/filledButtonTheme/outlinedButtonTheme) sets
// `minimumSize: Size(double.infinity, 52)` on every ElevatedButton/
// FilledButton/OutlinedButton, intended for full-width primary CTAs. A
// `Row` gives an UNBOUNDED max-width constraint to any non-Expanded/
// Flexible child (regardless of mainAxisSize) — so any themed button
// placed directly in a Row without a local `minimumSize` override tries
// to satisfy "as wide as possible" against an unbounded constraint and
// throws exactly this error (the 52.0 minimum height in the reported
// BoxConstraints is the theme's own value, confirming this mechanism).
//
// ExplorePersonCard and BlockedUserCard (lib/shared/widgets/cards/) were
// extracted from FriendsScreen's private _ExploreCard/_BlockedTab
// specifically so this test can render the ACTUAL production widgets —
// not a reconstructed approximation — without needing a live
// Supabase-backed FriendsProvider (they take plain callbacks instead).
// _ExploreCard/_BlockedTab are now thin wrappers around these that just
// supply the callbacks from a real FriendsProvider.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/friends/data/friends_repository.dart';
import 'package:jma3a/shared/widgets/cards/blocked_user_card.dart';
import 'package:jma3a/shared/widgets/cards/explore_person_card.dart';

ExplorePerson _person({
  String id = 'u1',
  String displayName = 'Sara',
  String? username = 'sara',
  int honestyPoints = 12,
  int generalScore = 340,
}) => ExplorePerson(
  userId: id,
  username: username,
  displayName: displayName,
  honestyPoints: honestyPoints,
  generalScore: generalScore,
  rankPosition: 1,
  totalEligible: 5,
  discoveryPoolSize: 5,
);

FriendEntity _blockedUser({
  String id = 'u2',
  String displayName = 'Ahmed',
  String? username = 'ahmed',
}) => FriendEntity(
  userId: id,
  displayName: displayName,
  username: username,
  status: FriendshipStatus.accepted,
  isRequester: false,
);

/// Mirrors the REAL ancestor chain each card actually renders inside
/// (Scaffold.body -> ... -> ListView.builder -> item), not just a bare
/// Padding — Column's mainAxisSize doesn't affect the width constraints
/// its children receive, but a ListView's default cross-axis behavior
/// does bound width to the ListView's own width, which is what this test
/// deliberately exercises to match production exactly.
Widget _wrapInList(
  List<Widget> items, {
  double width = 390,
  TextDirection direction = TextDirection.ltr,
}) => MediaQuery(
  data: MediaQueryData(size: Size(width, 800)),
  child: Directionality(
    textDirection: direction,
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: direction == TextDirection.rtl ? const Locale('ar') : null,
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: items,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  group('ExplorePersonCard — real production widget, narrow widths', () {
    for (final width in [320.0, 360.0, 390.0]) {
      testWidgets('renders without exception at ${width}px (Add Friend '
          'state)', (tester) async {
        await tester.pumpWidget(
          _wrapInList([
            ExplorePersonCard(
              person: _person(),
              hasSentRequest: false,
              onAddFriend: () {},
            ),
          ], width: width),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders without exception at ${width}px (Request Sent '
          'state)', (tester) async {
        await tester.pumpWidget(
          _wrapInList([
            ExplorePersonCard(
              person: _person(),
              hasSentRequest: true,
              onAddFriend: () {},
            ),
          ], width: width),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a full list of multiple real cards renders without '
        'exception (matches ListView.builder with several results)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapInList([
          for (var i = 0; i < 6; i++)
            ExplorePersonCard(
              person: _person(id: 'u$i', displayName: 'Person $i'),
              hasSentRequest: i.isEven,
              onAddFriend: () {},
            ),
        ], width: 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping the card opens the profile (onTap fires) — the '
        'previously-missing entry point for viewing a non-friend\'s '
        'profile from Explore', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrapInList([
          ExplorePersonCard(
            person: _person(),
            hasSentRequest: false,
            onAddFriend: () {},
            onTap: () => tapped = true,
          ),
        ], width: 360),
      );
      await tester.pump();
      // Tap the name text, not the Add Friend button — proves the CARD
      // itself is tappable, distinct from the button's own onPressed.
      await tester.tap(find.text('Sara'));
      await tester.pump();
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping the Add Friend button fires onAddFriend, not '
        'onTap — nested tappables resolve independently', (tester) async {
      var addFriendTapped = false;
      var cardTapped = false;
      await tester.pumpWidget(
        _wrapInList([
          ExplorePersonCard(
            person: _person(),
            hasSentRequest: false,
            onAddFriend: () => addFriendTapped = true,
            onTap: () => cardTapped = true,
          ),
        ], width: 360),
      );
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(addFriendTapped, isTrue);
      expect(cardTapped, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception in Arabic RTL', (tester) async {
      await tester.pumpWidget(
        _wrapInList([
          ExplorePersonCard(
            person: _person(displayName: 'سارة', username: 'sara'),
            hasSentRequest: false,
            onAddFriend: () {},
          ),
        ], width: 360, direction: TextDirection.rtl),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception with a long display name at '
        'the narrowest reported width', (tester) async {
      await tester.pumpWidget(
        _wrapInList([
          ExplorePersonCard(
            person: _person(
              displayName: 'A Very Long Display Name That Could Wrap',
              username: 'a_very_long_username_handle',
            ),
            hasSentRequest: false,
            onAddFriend: () {},
          ),
        ], width: 320),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('negative honesty points (sign-colored, longer text) '
        'still renders without exception', (tester) async {
      await tester.pumpWidget(
        _wrapInList([
          ExplorePersonCard(
            person: _person(honestyPoints: -48, generalScore: 12000),
            hasSentRequest: false,
            onAddFriend: () {},
          ),
        ], width: 320),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Add Friend invokes the callback exactly once', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrapInList([
          ExplorePersonCard(
            person: _person(),
            hasSentRequest: false,
            onAddFriend: () => taps++,
          ),
        ]),
      );
      await tester.tap(find.text('Add Friend'), warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(taps, 1);
    });
  });

  group('BlockedUserCard — real production widget, narrow widths', () {
    for (final width in [320.0, 360.0, 390.0]) {
      testWidgets('renders without exception at ${width}px', (tester) async {
        await tester.pumpWidget(
          _wrapInList([
            BlockedUserCard(user: _blockedUser(), onUnblock: () {}),
          ], width: width),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a full list of multiple real cards renders without '
        'exception', (tester) async {
      await tester.pumpWidget(
        _wrapInList([
          for (var i = 0; i < 5; i++)
            BlockedUserCard(
              user: _blockedUser(id: 'u$i', displayName: 'Blocked $i'),
              onUnblock: () {},
            ),
        ], width: 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception in Arabic RTL', (tester) async {
      await tester.pumpWidget(
        _wrapInList([
          BlockedUserCard(
            user: _blockedUser(displayName: 'أحمد', username: 'ahmed'),
            onUnblock: () {},
          ),
        ], width: 360, direction: TextDirection.rtl),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception with a long display name at '
        'the narrowest reported width', (tester) async {
      await tester.pumpWidget(
        _wrapInList([
          BlockedUserCard(
            user: _blockedUser(
              displayName: 'A Very Long Display Name That Could Wrap',
              username: 'a_very_long_username_handle',
            ),
            onUnblock: () {},
          ),
        ], width: 320),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('sanity check: proves this suite actually catches the regression '
      '(not trivially passing)', () {
    // The exact broken shape — no minimumSize override — reproduced
    // standalone under the real theme, to demonstrate the fixed widgets
    // above are not passing merely because the theme is somehow benign.
    testWidgets('an UNFIXED FilledButton as a bare Row child throws under '
        'the real app theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Row(
              children: [
                const Expanded(child: Text('name')),
                FilledButton.tonal(onPressed: () {}, child: const Text('Add')),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNotNull);
    });
  });
}
