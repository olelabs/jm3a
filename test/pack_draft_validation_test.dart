// Behavior tests for the single authoritative pack-submission validation
// (PackDraft.validationIssues / canPublish). These assert the USER-FACING
// rules — what does and doesn't block "Submit for review" — not internals.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/packs/domain/pack_entity.dart';

/// A ready-to-submit Truth-or-Dare draft in the given [langs] (default French
/// only), with a balanced 20-card deck, price 300, and terms accepted. Tests
/// then break ONE thing at a time and assert the resulting issue.
PackDraft _validTod({List<String> langs = const ['fr']}) {
  String contentFor(String lang) => '$lang content';
  CardDraft card(CardType type) => CardDraft(
        type: type,
        contentEn: langs.contains('en') ? contentFor('en') : '',
        contentAr: langs.contains('ar') ? contentFor('ar') : '',
        contentFr: langs.contains('fr') ? contentFor('fr') : '',
      );
  return PackDraft(
    gameType: 'truth_or_dare',
    selectedLanguages: List<String>.from(langs),
    titles: {for (final l in langs) l: 'Title $l'},
    priceMru: 300,
    termsAccepted: true,
    cards: [
      for (var i = 0; i < 10; i++) card(CardType.truth),
      for (var i = 0; i < 10; i++) card(CardType.dare),
    ],
  );
}

void main() {
  group('PackDraft — a complete draft is submittable', () {
    test('valid French ToD pack has no issues and can publish', () {
      final d = _validTod();
      expect(d.validationIssues(), isEmpty);
      expect(d.canPublish, isTrue);
    });
  });

  group('Price >= 300 (Part 5)', () {
    for (final invalid in [0, 1, 100, 299]) {
      test('$invalid MRU is invalid', () {
        final d = _validTod()..priceMru = invalid;
        expect(d.hasValidPrice, isFalse);
        expect(d.validationIssues(), contains(PackDraftIssue.price));
      });
    }
    for (final valid in [300, 301, 1000]) {
      test('$valid MRU is valid', () {
        final d = _validTod()..priceMru = valid;
        expect(d.hasValidPrice, isTrue);
        expect(d.validationIssues(), isNot(contains(PackDraftIssue.price)));
      });
    }
  });

  group('Truth/Dare 50-50 balance (Part 4)', () {
    test('equal 10/10 is valid', () {
      final d = _validTod();
      expect(d.truthCount, 10);
      expect(d.dareCount, 10);
      expect(d.hasBalancedTruthDare, isTrue);
      expect(
        d.validationIssues(),
        isNot(contains(PackDraftIssue.truthDareBalance)),
      );
    });

    test('unequal 11/9 blocks submission', () {
      final d = _validTod();
      // Flip one dare into a truth -> 11 truth / 9 dare.
      d.cards[19] = CardDraft(type: CardType.truth, contentFr: 'x');
      expect(d.hasBalancedTruthDare, isFalse);
      expect(
        d.validationIssues(),
        contains(PackDraftIssue.truthDareBalance),
      );
    });

    test('30 cards must be 15/15', () {
      final d = _validTod();
      // 15 truth / 15 dare = balanced.
      d.cards = [
        for (var i = 0; i < 15; i++)
          CardDraft(type: CardType.truth, contentFr: 'x'),
        for (var i = 0; i < 15; i++)
          CardDraft(type: CardType.dare, contentFr: 'x'),
      ];
      expect(d.hasBalancedTruthDare, isTrue);
      // 16/14 = not balanced.
      d.cards[29] = CardDraft(type: CardType.truth, contentFr: 'x');
      expect(d.hasBalancedTruthDare, isFalse);
    });

    test('balance rule does NOT apply to other game types', () {
      final d = _validTod()..gameType = 'never_have_i_ever';
      // Make it wildly unbalanced by type — irrelevant for NHIE.
      d.cards = [
        for (var i = 0; i < 20; i++)
          CardDraft(type: CardType.statement, contentFr: 'x'),
      ];
      expect(d.hasBalancedTruthDare, isTrue);
      expect(
        d.validationIssues(),
        isNot(contains(PackDraftIssue.truthDareBalance)),
      );
    });
  });

  group('Language authority (Parts 6/4 — no forced English)', () {
    test('French-only draft does NOT require English content', () {
      final d = _validTod(langs: ['fr']);
      // No English anywhere; still valid.
      expect(d.selectedLanguages, ['fr']);
      expect(d.hasTitle, isTrue);
      expect(d.hasContentForSelectedLanguages, isTrue);
      expect(d.validationIssues(), isEmpty);
    });

    test('Arabic-only draft requires Arabic, not English', () {
      final d = _validTod(langs: ['ar']);
      expect(d.validationIssues(), isEmpty);
      // Remove Arabic content from one card -> language issue.
      d.cards[0] = CardDraft(type: d.cards[0].type, contentAr: '');
      expect(d.hasContentForSelectedLanguages, isFalse);
      expect(d.validationIssues(), contains(PackDraftIssue.language));
    });

    test('multi-language requires every SELECTED language only', () {
      final d = _validTod(langs: ['en', 'fr']);
      expect(d.validationIssues(), isEmpty);
      // Missing a French title -> title issue for the selected set.
      d.titles.remove('fr');
      expect(d.hasTitle, isFalse);
      expect(d.validationIssues(), contains(PackDraftIssue.title));
      // Adding an UNSELECTED language's absence never matters.
      final d2 = _validTod(langs: ['en']);
      expect(d2.validationIssues(), isEmpty); // no 'ar'/'fr' requirement
    });
  });

  group('Cards minimum & terms & default price', () {
    test('fewer than 20 cards blocks submission', () {
      final d = _validTod();
      d.cards = d.cards.take(10).toList();
      expect(d.hasSufficientCards, isFalse);
      expect(d.validationIssues(), contains(PackDraftIssue.cards));
    });

    test('terms must be accepted (Part 7)', () {
      final d = _validTod()..termsAccepted = false;
      expect(d.validationIssues(), contains(PackDraftIssue.terms));
      expect(d.canPublish, isFalse);
      d.termsAccepted = true;
      expect(d.validationIssues(), isNot(contains(PackDraftIssue.terms)));
    });

    test('a brand-new draft defaults to no language and price 0 (invalid)', () {
      final d = PackDraft();
      expect(d.selectedLanguages, isEmpty); // never forced to ['en']
      expect(d.priceMru, 0);
      expect(d.canPublish, isFalse);
    });
  });

  // A ready-to-submit ToD draft whose cards carry content ONLY in the given
  // dynamic language codes (via the code-keyed content map — no en/ar/fr
  // assumption). Used to prove validation follows the actual selected codes.
  PackDraft validTodInLangs(List<String> langs) {
    CardDraft card(CardType type) =>
        CardDraft(type: type, content: {for (final l in langs) l: '$l text'});
    return PackDraft(
      gameType: 'truth_or_dare',
      selectedLanguages: List<String>.from(langs),
      titles: {for (final l in langs) l: 'Title $l'},
      priceMru: 300,
      termsAccepted: true,
      cards: [
        for (var i = 0; i < 10; i++) card(CardType.truth),
        for (var i = 0; i < 10; i++) card(CardType.dare),
      ],
    );
  }

  group('Dynamic language validation — Hassaniya & no en fallback', () {
    test('a Hassaniya-only (hs) pack validates on its own content', () {
      final d = validTodInLangs(['hs']);
      expect(d.selectedLanguages, ['hs']);
      // Every card has hs content and NO English.
      expect(d.cards.every((c) => c.hasContentFor('hs')), isTrue);
      expect(d.cards.every((c) => c.contentEn.isEmpty), isTrue);
      expect(d.hasContentForSelectedLanguages, isTrue);
      expect(d.validationIssues(), isEmpty);
      expect(d.canPublish, isTrue);
    });

    test('English is NOT required when it was not selected', () {
      final d = validTodInLangs(['hs']);
      // The presence of en content is irrelevant to a non-en selection.
      expect(d.validationIssues(), isNot(contains(PackDraftIssue.language)));
    });

    test('the removed en fallback: unknown-code content no longer masquerades '
        'as satisfying another language', () {
      // A card with ONLY English content must NOT be considered to have hs
      // content (the old `_ => contentEn` switch fallback did exactly that).
      final enOnly = CardDraft(contentEn: 'hello');
      expect(enOnly.hasContentFor('hs'), isFalse);
      expect(enOnly.hasContentFor('ar'), isFalse);
      expect(enOnly.hasContentFor('en'), isTrue);
    });

    test('hs-only pack missing hs content on one card is flagged', () {
      final d = validTodInLangs(['hs']);
      d.cards[0] = CardDraft(type: d.cards[0].type); // no content at all
      expect(d.hasContentForSelectedLanguages, isFalse);
      expect(d.validationIssues(), contains(PackDraftIssue.language));
    });

    test('multi-language incl. hs requires every selected code', () {
      final d = validTodInLangs(['fr', 'hs']);
      expect(d.validationIssues(), isEmpty);
      // Drop hs from one card -> language issue (fr alone is not enough).
      d.cards[5] = CardDraft(type: d.cards[5].type, content: {'fr': 'x'});
      expect(d.cards[5].hasContentFor('hs'), isFalse);
      expect(d.validationIssues(), contains(PackDraftIssue.language));
    });
  });

  group('CardDraft — code-keyed content map', () {
    test('contentJson emits exactly the non-empty selected codes', () {
      final c = CardDraft(content: {'hs': 'salaam', 'fr': '', 'en': '  '});
      // Empty/whitespace entries are never stored or emitted.
      expect(c.contentJson.keys, ['hs']);
      expect(c.contentJson['hs'], 'salaam');
    });

    test('backward-compatible en/ar/fr accessors still work', () {
      final c = CardDraft(contentEn: 'e', contentAr: 'a', contentFr: 'f');
      expect(c.content, {'en': 'e', 'ar': 'a', 'fr': 'f'});
      c.contentAr = 'ar2';
      expect(c.content['ar'], 'ar2');
      c.contentFr = ''; // clearing removes the key
      expect(c.content.containsKey('fr'), isFalse);
    });

    test('setContent adds/updates/clears by dynamic code', () {
      final c = CardDraft();
      c.setContent('hs', 'x');
      expect(c.hasContentFor('hs'), isTrue);
      c.setContent('hs', '   '); // whitespace clears
      expect(c.hasContentFor('hs'), isFalse);
      expect(c.hasContent, isFalse);
    });
  });
}
