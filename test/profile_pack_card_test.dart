// Regression coverage for item 2 (this pass) — the pack name must remain
// INSIDE the pack card (its own card section below the cover, with a
// visible card container/border around both), never a separate widget
// rendered below the card and never a background-behind-text overlay.
// Also covers item 11 — narrow-phone layout safety for this card, which
// is now shared by both ProfileScreen (own profile) and UserProfileScreen
// (another user's profile) — see profile_pack_card.dart's own doc comment.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/features/packs/domain/pack_entity.dart';
import 'package:jma3a/shared/widgets/cards/j_card.dart';
import 'package:jma3a/shared/widgets/cards/profile_pack_card.dart';

PackEntity _pack({String title = 'Test Pack', String? coverImageUrl}) =>
    PackEntity(
      id: 'p1',
      creatorId: 'u1',
      titleJson: {'en': title},
      status: PackStatus.approved,
      gameType: 'truth_or_dare',
      language: 'en',
      priceMru: 0,
      cardCount: 50,
      avgRating: 4.5,
      totalRatings: 10,
      totalPurchases: 5,
      totalPlays: 42,
      coverImageUrl: coverImageUrl,
    );

Widget _wrap(Widget child, {double width = 390}) => MediaQuery(
  data: MediaQueryData(size: Size(width, 800)),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Align(alignment: Alignment.topLeft, child: child),
    ),
  ),
);

void main() {
  testWidgets(
    'the pack name renders inside the same JCard as the cover — not a '
    'separate widget below the card',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfilePackCard(
            pack: _pack(title: 'My Cool Pack'),
            onTap: () {},
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      // The JCard must be an ANCESTOR of the title text — proving the name
      // is inside the card's own container, not a sibling underneath it.
      final cardFinder = find.byType(JCard);
      final textFinder = find.text('My Cool Pack');
      expect(cardFinder, findsOneWidget);
      expect(textFinder, findsOneWidget);
      expect(
        find.descendant(of: cardFinder, matching: textFinder),
        findsOneWidget,
      );
    },
  );

  testWidgets('a very long pack name is ellipsized, never overflows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ProfilePackCard(
          pack: _pack(
            title:
                'An Extremely Long Pack Name That Would Never Fit On One Or Even Two Lines Of A Small Card',
          ),
          onTap: () {},
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final textWidget = tester.widget<Text>(
      find.textContaining('An Extremely Long Pack Name'),
    );
    expect(textWidget.maxLines, 2);
    expect(textWidget.overflow, TextOverflow.ellipsis);
  });

  testWidgets('renders without exception at narrow phone widths', (
    tester,
  ) async {
    for (final width in [320.0, 360.0, 390.0]) {
      await tester.pumpWidget(
        _wrap(
          ProfilePackCard(pack: _pack(), onTap: () {}, showStats: true),
          width: width,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'width=$width');
    }
  });

  testWidgets('tapping the card invokes onTap exactly once', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(ProfilePackCard(pack: _pack(), onTap: () => taps++)),
    );
    await tester.pump();
    await tester.tap(find.byType(ProfilePackCard));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('showStats:false (own-profile mock) hides rating/plays; '
      'showStats:true (other-user profile) shows them', (tester) async {
    await tester.pumpWidget(
      _wrap(ProfilePackCard(pack: _pack(), onTap: () {})),
    );
    await tester.pump();
    expect(find.byIcon(Icons.star_rounded), findsNothing);

    await tester.pumpWidget(
      _wrap(ProfilePackCard(pack: _pack(), onTap: () {}, showStats: true)),
    );
    await tester.pump();
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('missing cover image falls back gracefully, no exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(ProfilePackCard(pack: _pack(coverImageUrl: null), onTap: () {})),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
