// Regression: Settings -> Password & Security showed EVERY account as
// "you haven't set a password yet", regardless of the account's actual
// has_password value.
//
// Root cause: ProfileRepository.rowToEntity (the mapper behind
// createOrUpdateProfile, updateProfile, getProfile, uploadAvatar,
// changeUsername, setThemeBackgroundColor — every profile mutation/read
// in the app) never read row['has_password'] at all, silently falling
// back to UserEntity's own `hasPassword = false` default. Since
// AuthProvider.updateCurrentUser() fully replaces currentUser rather
// than merging fields, that defaulted-false value overwrote whatever
// correct one the account already had (from login/signup) the instant
// ANY profile mutation ran — concretely, completing onboarding
// (OnboardingScreen calls createOrUpdateProfile then
// auth.updateCurrentUser(updated) immediately after) or even just
// reopening the Profile tab (ProfileProvider._refreshAll -> getProfile).
//
// rowToEntity is `static` (see its own doc comment) specifically so this
// pure Map -> UserEntity mapping can be tested directly, without
// constructing a ProfileRepository instance — which requires a real
// Supabase/ApiClient singleton this test suite has no way to provide.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/profile/data/profile_repository.dart';

Map<String, dynamic> _row({bool? hasPassword}) => {
  'id': 'user-1',
  'email': 'user@example.com',
  'username': 'someuser',
  'display_name': 'Some User',
  if (hasPassword != null) 'has_password': hasPassword,
};

void main() {
  group('ProfileRepository.rowToEntity — has_password mapping', () {
    // G/I: has_password=true in the persisted row -> the entity says so.
    test('has_password=true in the row -> UserEntity.hasPassword is true', () {
      final entity = ProfileRepository.rowToEntity(_row(hasPassword: true));
      expect(entity.hasPassword, isTrue);
    });

    // H/I: has_password=false in the persisted row -> the entity says so.
    test('has_password=false in the row -> UserEntity.hasPassword is false', () {
      final entity = ProfileRepository.rowToEntity(_row(hasPassword: false));
      expect(entity.hasPassword, isFalse);
    });

    // J: the specific regression — this mapper must not silently default
    // a KNOWN-true account to false just because some OTHER profile
    // field was what a given call site cared about. Every field this
    // mapper reads is asserted here precisely so a future accidental
    // drop of any of them (not just has_password) fails loudly.
    test('every other mapped field survives the round trip untouched by the has_password fix', () {
      final entity = ProfileRepository.rowToEntity(_row(hasPassword: true));
      expect(entity.id, 'user-1');
      expect(entity.email, 'user@example.com');
      expect(entity.username, 'someuser');
      expect(entity.displayName, 'Some User');
      expect(entity.hasPassword, isTrue);
    });
  });
}
