// Tests for PackCreationStatus (pack-creation audit task) — the pure
// model parsed from get_pack_creation_status()'s one-round-trip JSON
// response. This is a UX pre-check only — submit_pack_for_review() itself
// is the actual (SQL, untestable offline) enforcement of the 15-day
// rolling-gap free allowance, the verified-creator gate, and the
// database-configured paid fee; see the final report for how that was
// verified instead (dry-run against the live linked Supabase project,
// plus reading the live pg_get_functiondef before and after the fix).
//
// What matters most here: PackCreationStatus.fromMap must correctly
// reflect a PURE 15-day gap, never a calendar-month reset — these tests
// exercise exactly the "Day 1 submit -> Day 1-15 blocked -> Day 16 free
// again" contract the task describes, at the model-parsing level.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/packs/domain/pack_entity.dart';

void main() {
  group('PackCreationStatus.fromMap', () {
    test('parses a normal, free-available response', () {
      final status = PackCreationStatus.fromMap({
        'is_verified_creator': true,
        'has_active_draft': false,
        'can_submit_free': true,
        'next_free_at': null,
        'min_gap_days': 15,
        'extra_pack_price_mru': 300,
        'currency': 'MRU',
      });
      expect(status.isVerifiedCreator, isTrue);
      expect(status.hasActiveDraft, isFalse);
      expect(status.canSubmitFree, isTrue);
      expect(status.nextFreeAt, isNull);
      expect(status.minGapDays, 15);
      expect(status.extraPackPriceMru, 300);
    });

    test('parses a within-15-days response (paid option required)', () {
      final status = PackCreationStatus.fromMap({
        'is_verified_creator': true,
        'has_active_draft': false,
        'can_submit_free': false,
        'next_free_at': '2026-02-15T00:00:00Z',
        'min_gap_days': 15,
        'extra_pack_price_mru': 300,
      });
      expect(status.canSubmitFree, isFalse);
      expect(status.nextFreeAt, DateTime.parse('2026-02-15T00:00:00Z'));
    });

    test('missing fields fall back safely (never throws)', () {
      final status = PackCreationStatus.fromMap(const {});
      expect(status.isVerifiedCreator, isFalse);
      expect(status.hasActiveDraft, isFalse);
      expect(status.canSubmitFree, isFalse);
      expect(status.nextFreeAt, isNull);
      expect(status.minGapDays, 15);
      expect(status.extraPackPriceMru, 0);
    });

    test('a non-verified creator can still be parsed (the UI, not this '
        'model, decides what to show) — is_verified_creator is a plain '
        'passthrough flag', () {
      final status = PackCreationStatus.fromMap({
        'is_verified_creator': false,
        'has_active_draft': false,
        'can_submit_free': true,
      });
      expect(status.isVerifiedCreator, isFalse);
    });

    test('has_active_draft true is reflected regardless of free/paid '
        'eligibility — the one-draft rule and the 15-day rule are '
        'independent axes', () {
      final status = PackCreationStatus.fromMap({
        'has_active_draft': true,
        'can_submit_free': true,
      });
      expect(status.hasActiveDraft, isTrue);
      expect(status.canSubmitFree, isTrue);
    });
  });

  group('15-day gap semantics (documented via the fromMap contract — the '
      'actual gap arithmetic lives in submit_pack_for_review()/'
      'get_pack_creation_status(), SQL, not exercisable offline)', () {
    test('day 1: just submitted -> next_free_at is set, can_submit_free '
        'is false (mirrors "Day 1-15 blocked")', () {
      final status = PackCreationStatus.fromMap({
        'can_submit_free': false,
        'next_free_at': '2026-01-16T00:00:00Z',
        'min_gap_days': 15,
      });
      expect(status.canSubmitFree, isFalse);
      expect(status.nextFreeAt, isNotNull);
    });

    test('day 16: gap satisfied -> can_submit_free true, next_free_at '
        'null (mirrors "Day 16 available again")', () {
      final status = PackCreationStatus.fromMap({
        'can_submit_free': true,
        'next_free_at': null,
        'min_gap_days': 15,
      });
      expect(status.canSubmitFree, isTrue);
      expect(status.nextFreeAt, isNull);
    });

    test('a brand-new creator with no submission history ever is free '
        'immediately — never blocked by a calendar-month reset that '
        'would otherwise show a spurious next_free_at', () {
      final status = PackCreationStatus.fromMap({
        'can_submit_free': true,
        'next_free_at': null,
      });
      expect(status.canSubmitFree, isTrue);
      expect(status.nextFreeAt, isNull);
    });
  });
}
