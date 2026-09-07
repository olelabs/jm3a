// Tests for the draft-pack profile leak fix (task items 10-11).
//
// Root cause: ProfileProvider's own-profile pack list was populated via
// PackRepository.getMyCreatedPacks(userId), which queries `packs` by
// creator_id with NO status filter — every draft/pending-review/rejected/
// suspended/archived pack the user has ever created showed up on their own
// profile. The fix (profile_provider.dart) switches that call to
// PackRepository.getPublicPacksByCreator(userId) — the same
// already-status='approved'-filtered query already used, unchanged, for
// viewing another user's public profile (user_profile_screen.dart) —
// instead of adding a second, duplicate filtering path.
//
// The pack-creation/resume workflow (my_packs_screen.dart / PackProvider)
// still calls getMyCreatedPacks directly and is untouched, so drafts
// remain fully visible/resumable there exactly as before.
//
// Security (section 11) was independently verified already enforced at
// the RLS level regardless of what any Flutter query sends — packs' SELECT
// policy is `(status = 'approved' AND deleted_at IS NULL) OR (creator_id =
// auth.uid())` (dbf/schema.sql) — so another user's drafts were never
// actually exposed even before this fix; this was purely an own-profile
// query-shape/UX issue. That policy lives in the database and can't be
// exercised by this offline suite (needs a live Supabase/staging
// connection — see final report); what IS testable offline is the
// PackStatus contract the fix's reasoning depends on.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/packs/domain/pack_entity.dart';

void main() {
  group(
    'PackStatus.isPublished — the contract getPublicPacksByCreator\'s '
    "status = 'approved' filter (and the profile fix that now reuses it) "
    'depends on',
    () {
      test('only approved counts as published', () {
        expect(PackStatus.approved.isPublished, isTrue);
        expect(PackStatus.draft.isPublished, isFalse);
        expect(PackStatus.pendingReview.isPublished, isFalse);
        expect(PackStatus.rejected.isPublished, isFalse);
        expect(PackStatus.suspended.isPublished, isFalse);
        expect(PackStatus.archived.isPublished, isFalse);
      });

      test('drafts and rejected packs stay editable/resumable — the '
          'pack-creation workflow this fix leaves untouched', () {
        expect(PackStatus.draft.isEditable, isTrue);
        expect(PackStatus.rejected.isEditable, isTrue);
        expect(PackStatus.approved.isEditable, isFalse);
        expect(PackStatus.pendingReview.isEditable, isFalse);
      });

      test('fromString round-trips every non-default DB status value', () {
        expect(PackStatus.fromString('draft'), PackStatus.draft);
        expect(PackStatus.fromString('pending_review'), PackStatus.pendingReview);
        expect(PackStatus.fromString('rejected'), PackStatus.rejected);
        expect(PackStatus.fromString('suspended'), PackStatus.suspended);
        expect(PackStatus.fromString('archived'), PackStatus.archived);
      });
    },
  );
}
