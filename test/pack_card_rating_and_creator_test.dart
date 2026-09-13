// Regression coverage for items 11 & 12 — the Packs screen's PackCard
// (marketplace grid) must show rating (+ count) and creator avatar/name
// directly on the card, without opening the pack first. Both fields were
// already fetched by the marketplace query onto PackEntity
// (avgRating/totalRatings/creatorName/creatorAvatarUrl) — this only
// verifies the CARD actually renders them, and degrades safely when
// they're absent (no ratings yet / no creator info returned).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/core/theme/app_theme.dart';
import 'package:jma3a/features/packs/domain/pack_entity.dart';
import 'package:jma3a/features/packs/presentation/widgets/pack_card_widget.dart';
import 'package:jma3a/shared/widgets/cards/user_avatar.dart';

PackEntity _pack({
  double avgRating = 0,
  int totalRatings = 0,
  String? creatorName,
  String? creatorAvatarUrl,
}) => PackEntity(
  id: 'p1',
  creatorId: 'c1',
  titleJson: const {'en': 'Test Pack'},
  status: PackStatus.approved,
  gameType: 'truth_or_dare',
  language: 'en',
  priceMru: 0,
  cardCount: 50,
  avgRating: avgRating,
  totalRatings: totalRatings,
  totalPurchases: 0,
  totalPlays: 0,
  creatorName: creatorName,
  creatorAvatarUrl: creatorAvatarUrl,
);

// PackCard's own Expanded(child: Stack(...)) cover image requires a
// BOUNDED-height ancestor to lay out at all (exactly like its real
// marketplace usage — a GridView cell, never a standalone/loose context).
// Mirrors marketplace_screen.dart's own grid exactly (2 columns,
// childAspectRatio: 0.68) rather than an ad-hoc SizedBox, so this test
// exercises the true available width/height a real card gets.
// UserAvatar (used by the creator-info row) reads its colors via
// context.jColors, a custom ThemeExtension only present on the app's real
// theme — a bare MaterialApp() without `theme:` makes that lookup null and
// throws. AppTheme.light() is the same pattern other widget tests in this
// suite use (see auth_redesign_widgets_test.dart) to render theme-dependent
// widgets successfully.
Widget _harness(PackEntity pack) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.68,
      children: [PackCard(pack: pack, onTap: () {})],
    ),
  ),
);

void main() {
  group('11 — rating on the card', () {
    testWidgets('shows average + count when both are present', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(_pack(avgRating: 4.8, totalRatings: 23)),
      );
      expect(find.text('4.8 (23)'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('shows just the average when count is somehow zero but '
        'avgRating is positive (defensive — never invents a count)', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(_pack(avgRating: 4.0, totalRatings: 0)));
      expect(find.text('4.0'), findsOneWidget);
      expect(find.textContaining('('), findsNothing);
    });

    testWidgets('never rated yet: no star, no fabricated "0.0" rating', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(_pack()));
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.textContaining('0.0'), findsNothing);
    });
  });

  group('12 — creator info on the card', () {
    testWidgets('shows the creator name when present', (tester) async {
      await tester.pumpWidget(_harness(_pack(creatorName: 'Ahmed')));
      expect(find.text('Ahmed'), findsOneWidget);
    });

    testWidgets('a very long creator name is ellipsized to one line, never '
        'overflows the card', (tester) async {
      final longName = 'A very long creator display name that would '
          'overflow a narrow pack card if not constrained' * 2;
      await tester.pumpWidget(_harness(_pack(creatorName: longName)));
      await tester.pump();

      expect(tester.takeException(), isNull);
      final textWidget = tester.widget<Text>(find.text(longName));
      expect(textWidget.maxLines, 1);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('no creator data at all: the creator row is simply omitted, '
        'not a fabricated placeholder', (tester) async {
      await tester.pumpWidget(_harness(_pack()));
      expect(find.byType(UserAvatar), findsNothing);
    });
  });
}
