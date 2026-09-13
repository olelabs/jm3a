// PlayerProfileCard — the compact avatar+badges profile preview shown
// from a game reaction/player tap (see lib/shared/widgets/cards/
// player_profile_card.dart). Score and honesty come straight from the
// RoomMemberEntity passed in — no fetch, no live provider needed to test
// them. Streak needs an extra FriendsProvider.getSocialProfile call this
// offline suite doesn't wire up a real backend for; the widget's own
// try/catch means that call simply fails quietly here, which is exactly
// the "no confirmed streak value yet" case — the perfect natural
// reproduction of "never show a fake/zero streak badge" without needing
// to mock the network call at all.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/j_theme_extension.dart';
import 'package:jma3a/features/friends/presentation/screens/user_profile_screen.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/shared/widgets/cards/player_profile_card.dart';

RoomMemberEntity _member({int generalScore = 0, int honestyPoints = 0}) =>
    RoomMemberEntity(
      userId: 'u1',
      displayName: 'Ahmed',
      seatOrder: 0,
      isReady: false,
      isOwner: false,
      isModerator: false,
      generalScore: generalScore,
      honestyPoints: honestyPoints,
    );

Future<void> _pumpCard(WidgetTester tester, RoomMemberEntity member) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [JThemeExtension.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: PlayerProfileCard(member: member)),
      ),
    ),
  );
  await tester.pump();
  // Let the streak fetch attempt (and fail, absent a real FriendsProvider)
  // settle before asserting.
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('shows the player name', (tester) async {
    await _pumpCard(tester, _member());
    expect(find.text('Ahmed'), findsOneWidget);
  });

  testWidgets(
    'shows the score badge using the member\'s existing generalScore',
    (tester) async {
      await _pumpCard(tester, _member(generalScore: 1420));
      expect(find.text('1420'), findsOneWidget);
    },
  );

  testWidgets(
    'shows the honesty badge using the member\'s existing honestyPoints, '
    'signed',
    (tester) async {
      await _pumpCard(tester, _member(honestyPoints: 24));
      expect(find.text('+24'), findsOneWidget);
    },
  );

  testWidgets('a negative honestyPoints value is shown as-is, not clamped', (
    tester,
  ) async {
    await _pumpCard(tester, _member(honestyPoints: -5));
    expect(find.text('-5'), findsOneWidget);
  });

  testWidgets(
    'never shows a streak badge when no streak value could be confirmed '
    '(no fake/zero streak)',
    (tester) async {
      await _pumpCard(tester, _member());
      expect(find.text('🔥'), findsNothing);
    },
  );

  testWidgets('tapping the card opens the full profile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [JThemeExtension.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(child: PlayerProfileCard(member: _member())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the name text (unambiguous content inside the card) rather than
    // the outer StatefulWidget's own bounding box, which the entrance
    // animation's Transform.scale can offset hit-testing against.
    await tester.tap(find.text('Ahmed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // A new route carrying UserProfileScreen was pushed on top — not
    // asserting on ITS own rendered content, which needs its own live
    // provider stack this offline test doesn't set up (any error from
    // UserProfileScreen trying to build without that is swallowed below;
    // what matters here is that the navigation actually happened).
    tester.takeException();
    expect(find.byType(UserProfileScreen), findsOneWidget);
  });
}
