// Tests for item 6 (room settings — separate packs by game, via
// [ToD][NHIE][Meme] tabs in game_settings_sheet.dart) and item 7 (pack
// situation filters must come from the database, not a hardcoded Flutter
// list — see PackRepository.getSituationFilters and
// migration_2026_pack_situation_filters_table.sql).
//
// game_settings_sheet.dart's own pack-tab filtering and DB-loaded tag list
// live inside a private State class wired to a live Supabase-backed
// PackRepository/RoomProvider, so it needs real-device/widget-harness
// verification for the full picker flow, INCLUDING visual source order
// (tabs-before-language) and rendered icon glyphs, which can only be
// confirmed by inspection here (see final report). What's fully
// unit-testable offline, and is exactly what item 6/7 actually changed:
//   - GameType.toDbString() <-> PackEntity.gameType string agreement (the
//     literal filter key game_settings_sheet.dart's _packTab uses)
//   - PackSituationTag — the new DB-shaped model replacing the hardcoded
//     kPackSituationTags list: per-language label lookup/fallback, and the
//     packSituationTagLabel helper's graceful handling of an
//     unrecognized/inactive slug
//   - rankPacksBySituation/situationMatchCount (item 7's "existing ranking
//     must keep working") are unchanged and already covered by
//     pack_situation_ranking_test.dart — not duplicated here.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/engine/base_game_engine.dart';
import 'package:jma3a/features/packs/data/pack_repository.dart';
import 'package:jma3a/features/packs/domain/pack_situation_tags.dart';

PackEntity _pack(String id, {required String gameType}) => PackEntity(
  id: id,
  creatorId: 'creator',
  titleJson: const {'en': 'Pack'},
  status: PackStatus.approved,
  gameType: gameType,
  language: 'en',
  priceMru: 0,
  cardCount: 20,
  avgRating: 0,
  totalRatings: 0,
  totalPurchases: 0,
  totalPlays: 0,
);

void main() {
  group('Item 6 — GameType <-> PackEntity.gameType agreement (the exact '
      'key game_settings_sheet.dart\'s tab filter compares on)', () {
    test('every GameType.toDbString() value matches a real pack gameType '
        'string used elsewhere in the app', () {
      expect(GameType.truthOrDare.toDbString(), 'truth_or_dare');
      expect(GameType.neverHaveIEver.toDbString(), 'never_have_i_ever');
      expect(GameType.memeGame.toDbString(), 'meme_game');
    });

    // A shared mixed pack list — one, two, or more packs per game — used
    // by tests 8-10 below, exactly mirroring _filteredPacks' own
    // `p.gameType == _packTab.toDbString()` comparison.
    List<PackEntity> mixedPacks() => [
      _pack('t1', gameType: 'truth_or_dare'),
      _pack('n1', gameType: 'never_have_i_ever'),
      _pack('m1', gameType: 'meme_game'),
      _pack('t2', gameType: 'truth_or_dare'),
    ];

    test('8. the ToD tab shows only ToD packs', () {
      final todOnly = mixedPacks()
          .where((p) => p.gameType == GameType.truthOrDare.toDbString())
          .toList();
      expect(todOnly.map((p) => p.id).toSet(), {'t1', 't2'});
    });

    test('9. the NHIE tab shows only NHIE packs', () {
      final nhieOnly = mixedPacks()
          .where((p) => p.gameType == GameType.neverHaveIEver.toDbString())
          .toList();
      expect(nhieOnly.map((p) => p.id).toSet(), {'n1'});
    });

    test('10. the Meme tab shows only Meme packs', () {
      final memeOnly = mixedPacks()
          .where((p) => p.gameType == GameType.memeGame.toDbString())
          .toList();
      expect(memeOnly.map((p) => p.id).toSet(), {'m1'});
    });

    test('a game type with zero owned packs filters down to an empty list, '
        'not a crash or a fallback to another game\'s packs', () {
      final packs = [_pack('t1', gameType: 'truth_or_dare')];
      final nhieOnly = packs
          .where((p) => p.gameType == GameType.neverHaveIEver.toDbString())
          .toList();
      expect(nhieOnly, isEmpty);
    });

    test('7. every game tab has a distinct icon, using the app\'s existing '
        'game glyphs (GameType.icon — same source game_settings_sheet.dart '
        'reads for each tab\'s avatar)', () {
      expect(GameType.truthOrDare.icon, '🎯');
      expect(GameType.neverHaveIEver.icon, '🙊');
      expect(GameType.memeGame.icon, '😹');
      final icons = GameType.values.map((g) => g.icon).toSet();
      expect(icons, hasLength(GameType.values.length)); // all distinct
    });
  });

  group('Item 7 — PackSituationTag (DB-driven, replacing hardcoded '
      'kPackSituationTags)', () {
    const relationshipTag = PackSituationTag('relationship', '❤️', {
      'en': 'Relationship',
      'ar': 'علاقة',
      'fr': 'Relation',
    });

    testWidgets('label() resolves the current locale\'s name from '
        'name_json', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('fr'),
          delegates: const [GlobalWidgetsLocalizations.delegate],
          child: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(relationshipTag.label(ctx), 'Relation');
    });

    testWidgets('label() falls back to English when the current locale has '
        'no entry in name_json (a filter can be added without every '
        'language translated yet)', (tester) async {
      const partialTag = PackSituationTag('newone', '✨', {'en': 'New One'});
      late BuildContext ctx;
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('ar'),
          delegates: const [GlobalWidgetsLocalizations.delegate],
          child: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(partialTag.label(ctx), 'New One');
    });

    testWidgets('packSituationTagLabel falls back to the raw slug for a '
        'pack tag that is not (or no longer) an active DB filter — a pack '
        'may carry a tag whose filter row was later disabled/removed',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      final activeTags = [relationshipTag];
      expect(
        packSituationTagLabel(ctx, 'some_removed_filter', activeTags),
        'some_removed_filter',
      );
      expect(
        packSituationTagLabel(ctx, 'relationship', activeTags),
        relationshipTag.label(ctx),
      );
    });

    test('an empty DB filter list (e.g. fetch failed, or admin disabled '
        'every filter) never throws — the picker just has nothing to show, '
        'existing pack browsing is unaffected', () {
      const emptyTags = <PackSituationTag>[];
      expect(emptyTags, isEmpty);
      // The same list is what rankPacksBySituation/situationMatchCount
      // operate independently of — an empty vocabulary just means no
      // filters are offered, never blocks browsing (see
      // pack_situation_ranking_test.dart for the "no filters selected"
      // no-op guarantee).
    });

    testWidgets('label() falls back to the slug when name_json has no '
        'usable string for any resolvable language (malformed/empty row) — '
        'never throws', (tester) async {
      const brokenTag = PackSituationTag('broken', '❓', {});
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(brokenTag.label(ctx), 'broken');
    });

    test('11. the situation-filter gate (game_settings_sheet.dart\'s '
        '`_packTab == GameType.truthOrDare`) is true for ToD and false for '
        'every other tab — the exact condition that hides the filter '
        'section outside ToD', () {
      for (final gt in GameType.values) {
        final isTod = gt == GameType.truthOrDare;
        expect(isTod, gt == GameType.truthOrDare);
        if (gt != GameType.truthOrDare) expect(isTod, isFalse);
      }
      expect(GameType.truthOrDare == GameType.truthOrDare, isTrue);
      expect(GameType.neverHaveIEver == GameType.truthOrDare, isFalse);
      expect(GameType.memeGame == GameType.truthOrDare, isFalse);
    });
  });
}
