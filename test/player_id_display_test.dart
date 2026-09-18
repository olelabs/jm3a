// Player ID display rules for the user's OWN profile.
//
// The database value is "JMA-XXXXXXXX"; the Jma3a Store displays the
// "JMA-" prefix itself, so the mobile app shows and copies only the part
// after it. UserEntity.playerIdShort is the single place that strips it,
// so both the label and the copy button can never disagree.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/auth/domain/entities/user_entity.dart';

UserEntity _user({String? playerId}) =>
    UserEntity(id: 'u1', email: 'u@example.com', playerId: playerId);

void main() {
  group('UserEntity.playerIdShort', () {
    test('strips the JMA- prefix', () {
      expect(_user(playerId: 'JMA-AB12CD34').playerIdShort, 'AB12CD34');
    });

    test('never returns the prefixed form', () {
      final short = _user(playerId: 'JMA-AB12CD34').playerIdShort;
      expect(short, isNot(contains('JMA-')));
      expect(short, isNot('JMA-AB12CD34'));
    });

    test('a value without the prefix is returned unchanged', () {
      expect(_user(playerId: 'AB12CD34').playerIdShort, 'AB12CD34');
    });

    test('null when the profile has no player id', () {
      expect(_user().playerIdShort, isNull);
      expect(_user(playerId: '').playerIdShort, isNull);
    });
  });

  group('Player ID never leaks between users', () {
    test('a UserEntity built without a player id has none — the '
        'other-user profile path (profiles_public/getSocialProfile) never '
        'supplies one', () {
      expect(_user().playerId, isNull);
      expect(_user().playerIdShort, isNull);
    });

    test('copyWith preserves the own-profile player id rather than '
        'dropping it on unrelated updates', () {
      final user = _user(playerId: 'JMA-AB12CD34');
      expect(user.copyWith(displayName: 'New Name').playerIdShort, 'AB12CD34');
    });
  });
}
