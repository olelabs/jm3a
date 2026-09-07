// Regression tests for the pack localization/data-contract bug: a pack
// authored only in a language other than en/ar/fr (e.g. Hassaniya, 'hs' —
// a real active row in pack_languages) previously showed a blank
// name/description and blank gameplay card content whenever the viewer's
// app language (or the room's configured language) didn't happen to match
// 'en' or the pack's own language exactly, because titleFor/descriptionFor/
// contentFor only ever fell back to a hardcoded 'en' key. The fix adds the
// pack's own declared language, then "first non-empty value present," to
// the fallback chain — never a raw id, never a blank card when content
// exists.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/packs/domain/pack_entity.dart';

PackEntity _packWith({
  required Map<String, dynamic> title,
  Map<String, dynamic>? description,
  required String language,
}) => PackEntity(
  id: 'pack-1',
  creatorId: 'creator-1',
  titleJson: title,
  descriptionJson: description,
  status: PackStatus.approved,
  gameType: 'truth_or_dare',
  language: language,
  priceMru: 300,
  cardCount: 20,
  avgRating: 0,
  totalRatings: 0,
  totalPurchases: 0,
  totalPlays: 0,
);

void main() {
  group('PackEntity.titleFor / descriptionFor — declared-language fallback', () {
    test('single-language Hassaniya pack shows its own title regardless of viewer language', () {
      final pack = _packWith(
        title: {'hs': 'حزمة حسانية'},
        description: {'hs': 'وصف بالحسانية'},
        language: 'hs',
      );
      // Viewer/app is Arabic, French, English, or something else entirely —
      // the pack's own Hassaniya content must always win.
      for (final viewerLang in ['ar', 'fr', 'en', 'es']) {
        expect(pack.titleFor(viewerLang), 'حزمة حسانية');
        expect(pack.descriptionFor(viewerLang), 'وصف بالحسانية');
      }
    });

    test('never falls back to the raw pack id', () {
      final pack = _packWith(title: {'hs': 'حزمة'}, language: 'hs');
      expect(pack.titleFor('en'), isNot(pack.id));
      expect(pack.titleFor('en'), isNotEmpty);
    });

    test('EN/AR/FR packs still resolve exactly as before', () {
      final pack = _packWith(
        title: {'en': 'English title', 'ar': 'عنوان عربي', 'fr': 'Titre français'},
        language: 'en',
      );
      expect(pack.titleFor('en'), 'English title');
      expect(pack.titleFor('ar'), 'عنوان عربي');
      expect(pack.titleFor('fr'), 'Titre français');
    });

    test('multi-language pack still adapts to the viewer language when available', () {
      final pack = _packWith(
        title: {'en': 'English', 'fr': 'Français'},
        language: 'multi',
      );
      expect(pack.titleFor('fr'), 'Français');
      expect(pack.titleFor('en'), 'English');
      // Requested language absent and pack.language ('multi') isn't itself
      // a key — falls through to 'en', not blank.
      expect(pack.titleFor('ar'), 'English');
    });

    test('description is empty (not a crash) when the pack has none', () {
      final pack = _packWith(title: {'hs': 'حزمة'}, language: 'hs');
      expect(pack.descriptionFor('hs'), isEmpty);
    });

    test('genuinely empty title data returns empty string, not the id', () {
      final pack = _packWith(title: const {}, language: 'hs');
      expect(pack.titleFor('en'), isEmpty);
      expect(pack.titleFor('en'), isNot(pack.id));
    });
  });

  group('PackCardEntity.contentFor — gameplay cards never blank when content exists', () {
    test('a card authored only in Hassaniya shows its content for any requested language', () {
      const card = PackCardEntity(
        id: 'card-1',
        packId: 'pack-1',
        contentJson: {'hs': 'محتوى بالحسانية'},
        type: CardType.truth,
        difficulty: CardDifficulty.mild,
      );
      for (final lang in ['ar', 'fr', 'en', 'es']) {
        expect(card.contentFor(lang), 'محتوى بالحسانية');
      }
    });

    test('EN/AR/FR cards still resolve exactly as before', () {
      const card = PackCardEntity(
        id: 'card-1',
        packId: 'pack-1',
        contentJson: {'en': 'Truth in English', 'ar': 'صدق بالعربية'},
        type: CardType.truth,
        difficulty: CardDifficulty.mild,
      );
      expect(card.contentFor('en'), 'Truth in English');
      expect(card.contentFor('ar'), 'صدق بالعربية');
      // Requested language missing, but content exists under another key —
      // never blank.
      expect(card.contentFor('fr'), isNotEmpty);
    });

    test('no content at all returns empty string', () {
      const card = PackCardEntity(
        id: 'card-1',
        packId: 'pack-1',
        contentJson: {},
        type: CardType.truth,
        difficulty: CardDifficulty.mild,
      );
      expect(card.contentFor('en'), isEmpty);
    });
  });

  group('PackCategory.nameFor — falls back to slug only when truly empty', () {
    test('resolves a non-en/ar/fr-only category name before falling to slug', () {
      const category = PackCategory(
        id: 'cat-1',
        nameJson: {'hs': 'فئة'},
        slug: 'category-slug',
      );
      expect(category.nameFor('en'), 'فئة');
    });

    test('falls back to slug when nameJson is genuinely empty', () {
      const category = PackCategory(id: 'cat-1', nameJson: {}, slug: 'category-slug');
      expect(category.nameFor('en'), 'category-slug');
    });
  });
}
