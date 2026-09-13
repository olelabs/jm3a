// Room Settings pack-language/label real-device fixes:
//
// - Item 5: pack names in the Room Settings picker must display in the
//   ROOM's own selected language (RoomEntity.language), not the
//   viewer's own app UI language. _displayTitle (game_settings_sheet.dart)
//   used to call PackEntity.titleFor(Localizations.localeOf(context)...)
//   — this now takes an explicit `lang` param the caller passes
//   (_langFilter, the room's language), covered here directly via
//   PackEntity.titleFor itself (the actual resolution logic
//   _displayTitle delegates to).
// - Item 9: language chips in Room Settings used to always show raw
//   2-letter codes ("EN"/"FR"/"AR") uppercased. languageLabel() now
//   localizes en/ar/fr using the APP's current UI language, while other
//   language codes keep the existing uppercase-code fallback.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/l10n/generated/app_localizations_ar.dart';
import 'package:jma3a/core/l10n/generated/app_localizations_en.dart';
import 'package:jma3a/core/l10n/generated/app_localizations_fr.dart';
import 'package:jma3a/features/packs/domain/pack_entity.dart';
import 'package:jma3a/features/rooms/presentation/widgets/game_settings_sheet.dart';

PackEntity _pack({
  required Map<String, dynamic> titleJson,
  String language = 'en',
  String? categoryId,
}) => PackEntity(
  id: 'p1',
  creatorId: 'c1',
  titleJson: titleJson,
  descriptionJson: const {},
  gameType: 'truth_or_dare',
  language: language,
  isMultilang: titleJson.length > 1,
  availableLanguages: titleJson.keys.toList(),
  status: PackStatus.approved,
  priceMru: 0,
  cardCount: 10,
  avgRating: 0,
  totalRatings: 0,
  totalPurchases: 0,
  totalPlays: 0,
  categoryId: categoryId,
);

void main() {
  group('PackEntity.titleFor — item 5: room language, not viewer locale', () {
    test('a pack with all three translations shows the ROOM language '
        'requested, regardless of what the viewer\'s own app language is', () {
      final pack = _pack(
        titleJson: const {
          'en': 'Ice Breakers',
          'ar': 'كسر الجليد',
          'fr': 'Brise-glace',
        },
      );
      // The room is set to Arabic — an English-speaking admin viewing
      // this screen must still see the Arabic title, since that's what
      // every player in the room actually sees the pack as.
      expect(pack.titleFor('ar'), 'كسر الجليد');
      expect(pack.titleFor('fr'), 'Brise-glace');
      expect(pack.titleFor('en'), 'Ice Breakers');
    });

    test('a pack missing the room\'s requested language falls back '
        'sensibly (declared language, then any available) instead of '
        'showing nothing', () {
      final pack = _pack(titleJson: const {'en': 'Truth Time'}, language: 'en');
      // Room is set to French, but this pack was never translated to
      // French — must not return an empty string.
      expect(pack.titleFor('fr'), 'Truth Time');
    });

    test('mixed-language packs: each pack independently resolves to '
        'whatever the room language actually has for IT', () {
      final enOnly = _pack(titleJson: const {'en': 'English Only'});
      final arOnly = _pack(titleJson: const {'ar': 'عربي فقط'});
      final both = _pack(titleJson: const {'en': 'Both', 'ar': 'كلاهما'});

      const roomLanguage = 'ar';
      expect(enOnly.titleFor(roomLanguage), 'English Only'); // falls back
      expect(arOnly.titleFor(roomLanguage), 'عربي فقط');
      expect(both.titleFor(roomLanguage), 'كلاهما');
    });
  });

  group('languageLabel — item 9', () {
    test('en/ar/fr codes localize to the APP UI language\'s own name '
        'for that language, not a raw code', () {
      final en = AppLocalizationsEn();
      expect(languageLabel(en, 'en'), en.languageEnglish);
      expect(languageLabel(en, 'ar'), en.languageArabic);
      expect(languageLabel(en, 'fr'), en.languageFrench);
    });

    test('when the app UI language is Arabic, en/ar/fr all show their '
        'Arabic-localized names — never a raw code', () {
      final ar = AppLocalizationsAr();
      final enLabel = languageLabel(ar, 'en');
      final arLabel = languageLabel(ar, 'ar');
      final frLabel = languageLabel(ar, 'fr');
      expect(enLabel, ar.languageEnglish);
      expect(arLabel, ar.languageArabic);
      expect(frLabel, ar.languageFrench);
      // Never the bare uppercase code the old behavior always showed.
      expect(enLabel, isNot('EN'));
      expect(arLabel, isNot('AR'));
      expect(frLabel, isNot('FR'));
    });

    test('French app UI language: en/ar/fr show their French-localized '
        'names', () {
      final fr = AppLocalizationsFr();
      expect(languageLabel(fr, 'en'), fr.languageEnglish);
      expect(languageLabel(fr, 'ar'), fr.languageArabic);
      expect(languageLabel(fr, 'fr'), fr.languageFrench);
    });

    test('a language code outside en/ar/fr falls back to the existing '
        'uppercase-code presentation, in every app language', () {
      final en = AppLocalizationsEn();
      final ar = AppLocalizationsAr();
      expect(languageLabel(en, 'es'), 'ES');
      expect(languageLabel(ar, 'es'), 'ES');
    });
  });

  group('packMatchesCategory — item 6', () {
    test('null categoryId ("All") matches every pack, including one with '
        'no category set at all', () {
      final withCategory = _pack(
        titleJson: const {'en': 'A'},
        categoryId: 'relationships-id',
      );
      final noCategory = _pack(titleJson: const {'en': 'B'});
      expect(packMatchesCategory(withCategory, null), isTrue);
      expect(packMatchesCategory(noCategory, null), isTrue);
    });

    test('a specific categoryId matches only packs with that exact id', () {
      final relationships = _pack(
        titleJson: const {'en': 'A'},
        categoryId: 'relationships-id',
      );
      final party = _pack(titleJson: const {'en': 'B'}, categoryId: 'party-id');
      final none = _pack(titleJson: const {'en': 'C'});

      expect(packMatchesCategory(relationships, 'relationships-id'), isTrue);
      expect(packMatchesCategory(party, 'relationships-id'), isFalse);
      expect(packMatchesCategory(none, 'relationships-id'), isFalse);
    });

    test('a category with no matching packs correctly excludes every '
        'pack, never falling back to "show everything"', () {
      final a = _pack(titleJson: const {'en': 'A'});
      final b = _pack(titleJson: const {'en': 'B'});
      for (final p in [a, b]) {
        expect(packMatchesCategory(p, 'no-such-category'), isFalse);
      }
    });
  });
}
