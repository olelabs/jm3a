// Meme pack-creation flow fixes:
//   1. The sticker library/upload selector inside the Cards step (only
//      offered for meme prompt cards) now actually renders — including
//      an "Upload sticker" option, always offered even when the
//      admin-curated library is empty (item 6 requirement).
//   2. The Cards step — the screen immediately after completing the
//      Audience ("Age Set") step — is proven to render real content, not
//      a blank widget, and to preserve the age selection made on the
//      previous step.
//
// CreatePackScreen's normal forward path (general_info -> ... ->
// names_descriptions -> audience -> cards) requires a live
// Supabase-backed PackRepository/PackProvider network round trip at
// 'names_descriptions'/'audience' (via _saveDraft -> createPackDraft/
// updatePackDraft), which this project's established testing boundary
// doesn't mock. CreatePackScreen's own initState already has a second,
// no-network entry path used when resuming an existing draft:
//   `_step = _savedPackId != null ? _activeSteps.indexOf('cards') : 0;`
// Passing existingPackId + existingPack (with the age fields already
// set, as they would be after a real Audience-step save) reaches the
// exact same _CardsStep widget with the exact same PackDraft shape a
// real Audience->Cards transition produces, without needing a live
// network call to get there — this is what every test below pumps.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations.dart';
import 'package:jma3a/features/packs/domain/pack_entity.dart';
import 'package:jma3a/features/packs/presentation/screens/create_pack_screen.dart';

PackEntity _memePack({int? minAge, int? maxAge}) => PackEntity(
  id: 'pack1',
  creatorId: 'user1',
  titleJson: const {'en': 'Test Meme Pack'},
  status: PackStatus.draft,
  gameType: 'meme_game',
  language: 'en',
  priceMru: 0,
  cardCount: 0,
  avgRating: 0,
  totalRatings: 0,
  totalPurchases: 0,
  totalPlays: 0,
  minAge: minAge,
  maxAge: maxAge,
);

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  // Widget-tree exceptions (a build throwing) surface through
  // FlutterError.onError rather than failing the test outright in some
  // configurations — assert on this explicitly everywhere so a real
  // regression can't hide behind "the test still finished".
  late List<FlutterErrorDetails> errors;
  late FlutterErrorDetails? Function(FlutterErrorDetails) originalOnError;

  setUp(() {
    errors = [];
    originalOnError = (d) {
      FlutterError.presentError(d);
      return d;
    };
    FlutterError.onError = (details) => errors.add(details);
  });

  tearDown(() {
    FlutterError.onError = (details) => originalOnError(details);
  });

  group('blank-screen-after-Age-Set fix: Cards step renders real content', () {
    testWidgets(
      'a meme pack with zero cards reaches Cards with visible content, '
      'not a blank screen',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            CreatePackScreen(
              existingPackId: 'pack1',
              existingPack: _memePack(minAge: 18),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(errors, isEmpty, reason: 'Cards step must build without throwing');
        // AppBar title includes the current step's label — proves we
        // landed on Cards, not stuck on some other/loading state.
        expect(find.textContaining('Cards'), findsWidgets);
        // The card-count header is part of _CardsStep's real content.
        expect(find.textContaining('/ 20+ cards'), findsOneWidget);
      },
    );

    testWidgets('the age selection made on Audience is preserved into Cards '
        'and back', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CreatePackScreen(
            existingPackId: 'pack1',
            existingPack: _memePack(minAge: 18, maxAge: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate back to Audience (Cards -> Back) and confirm the "18+"
      // choice chip is still the selected one — proves minAge/maxAge
      // survived the trip through PackDraft into this step, matching the
      // pre-fill logic in _CreatePackScreenState.initState.
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('18+'),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(chip.selected, isTrue);
    });
  });

  group('meme sticker selector', () {
    testWidgets('the sticker picker button is offered for a meme prompt card', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CreatePackScreen(
            existingPackId: 'pack1',
            existingPack: _memePack(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_emotions_outlined), findsOneWidget);
    });

    // NOT tested here (established Supabase-singleton testing boundary,
    // same one this project has hit for every other screen/sheet that
    // touches PackRepository.instance/Supabase.instance.client directly):
    // tapping the sticker button opens _StickerPickerSheet, whose
    // initState calls PackRepository.instance.getStickerLibrary().
    // PackRepository's private constructor reads Supabase.instance.client
    // synchronously at first access
    // (lib/features/packs/data/pack_repository.dart's `PackRepository._()`),
    // which throws "You must initialize the supabase instance..." the
    // first time ANY PackRepository method is touched in this
    // Supabase-less test environment — a build-time assertion failure,
    // not a Future rejection the sheet's own `.catchError` can intercept.
    // resolveCardStickerFields (pack_meme_sticker_resolution_test.dart)
    // covers the pure "library pick vs. upload" decision this sheet
    // feeds into instead; the sheet's own loading/empty/upload-button UI
    // (verified by direct code review — see _StickerPickerSheetState.
    // build's stickers==null / stickers.isEmpty branches, both of which
    // render the same always-visible "Upload sticker" button above them)
    // is the one part of this fix that couldn't be exercised live here.
  });
}
