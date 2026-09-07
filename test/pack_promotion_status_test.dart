// Server-authoritative promotion eligibility (item 3 of the pack audit):
// promote_pack() now rejects a second promotion for a pack that already has
// one active (verified live via a rolled-back dry run against the real DB —
// see 20260901090200_promote_pack_active_guard.sql), and
// get_pack_promotion_status() is the read side the UI uses to decide
// whether to show "Promote" or "Promotion active, ends ...". The RPC calls
// themselves aren't testable here (no injectable mock seam — PackRepository
// is a Supabase-backed singleton), so this covers the one piece of pure,
// extractable logic: parsing the RPC's jsonb response.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/packs/data/pack_repository.dart';

void main() {
  group('PackPromotionStatus.fromMap', () {
    test('active promotion with an end time', () {
      final status = PackPromotionStatus.fromMap({
        'active': true,
        'ends_at': '2026-09-05T12:00:00Z',
      });
      expect(status.active, isTrue);
      expect(status.endsAt, DateTime.parse('2026-09-05T12:00:00Z'));
    });

    test('no active promotion has a null endsAt', () {
      final status = PackPromotionStatus.fromMap({'active': false});
      expect(status.active, isFalse);
      expect(status.endsAt, isNull);
    });

    test('missing "active" key defaults to false rather than throwing', () {
      final status = PackPromotionStatus.fromMap({});
      expect(status.active, isFalse);
      expect(status.endsAt, isNull);
    });
  });
}
