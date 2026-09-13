// Regression coverage for:
// - item 8 (prior pass): Discover Friends must never show an incomplete
//   account. Mirrors the EXISTING completion criteria
//   (UserEntity.hasCompletedProfile: `username != null && displayName !=
//   null`), not a newly-invented definition.
// - item 1 (this pass): Jma3a Official must be completely excluded from
//   Discover Friends — not specially presented, not shown at all. See
//   ExplorePerson.isDiscoverable's own doc comment: this is the actual
//   predicate FriendsProvider/ExplorePersonCard filter on.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/friends/data/friends_repository.dart';

ExplorePerson _person({
  String? username = 'sara_99',
  String displayName = 'Sara',
  bool isOfficial = false,
}) => ExplorePerson(
  userId: 'u1',
  username: username,
  displayName: displayName,
  honestyPoints: 0,
  generalScore: 0,
  rankPosition: 1,
  totalEligible: 1,
  discoveryPoolSize: 1,
  isOfficial: isOfficial,
);

void main() {
  group('ExplorePerson.hasCompletedProfile', () {
    test('true when both username and display name are present', () {
      expect(_person().hasCompletedProfile, isTrue);
    });

    test('false when username is null (mirrors hasCompletedProfile\'s '
        'username != null check)', () {
      expect(_person(username: null).hasCompletedProfile, isFalse);
    });

    test('false when username is an empty string', () {
      expect(_person(username: '').hasCompletedProfile, isFalse);
    });

    test('false when display name is empty (fromMap\'s null -> "" collapse '
        'is treated the same as a null display name)', () {
      expect(_person(displayName: '').hasCompletedProfile, isFalse);
    });
  });

  group(
    'ExplorePerson.isDiscoverable — the actual Discover-visibility gate',
    () {
      test('true for a normal, complete, non-official profile', () {
        expect(_person().isDiscoverable, isTrue);
      });

      test('false for an incomplete profile (no username)', () {
        expect(_person(username: null).isDiscoverable, isFalse);
      });

      test('false for the official Jma3a account, even with a complete '
          'profile — item 1: must be fully excluded from Discover, no '
          'special-cased exemption like the old hasCompletedProfile had', () {
        expect(_person(isOfficial: true).isDiscoverable, isFalse);
      });

      test('false for the official Jma3a account with no username too — '
          'excluded either way, not "shown because it is official"', () {
        expect(
          _person(username: null, isOfficial: true).isDiscoverable,
          isFalse,
        );
      });
    },
  );

  group('searchRowIsOfficialAccount — item 1: search results also exclude '
      'Jma3a Official', () {
    test('true for a raw profiles row with is_official_account: true', () {
      expect(searchRowIsOfficialAccount({'is_official_account': true}), isTrue);
    });

    test('false for a normal row (is_official_account: false)', () {
      expect(
        searchRowIsOfficialAccount({'is_official_account': false}),
        isFalse,
      );
    });

    test('false when is_official_account is absent/null (pre-existing rows '
        'default to not-official, never excluded by omission)', () {
      expect(searchRowIsOfficialAccount({}), isFalse);
      expect(
        searchRowIsOfficialAccount({'is_official_account': null}),
        isFalse,
      );
    });
  });

  group('parseOfficialAccountIdValue — item 2 (real-device report: still '
      'visible after re-running the setup script)', () {
    test('a plain string value (the actual shape the setup script writes) '
        'is used directly', () {
      expect(parseOfficialAccountIdValue('official-id-123'), 'official-id-123');
    });

    test('null/missing value returns null', () {
      expect(parseOfficialAccountIdValue(null), isNull);
    });

    test('an empty string returns null, not an empty-but-truthy id', () {
      expect(parseOfficialAccountIdValue(''), isNull);
    });

    test('a nested {id: ...} shape is still recovered defensively', () {
      expect(
        parseOfficialAccountIdValue({'id': 'official-id-456'}),
        'official-id-456',
      );
    });

    test('a nested {value: ...} shape is still recovered defensively', () {
      expect(
        parseOfficialAccountIdValue({'value': 'official-id-789'}),
        'official-id-789',
      );
    });

    test('an unrecognized shape (e.g. a List, or a Map with neither id nor '
        'value) returns null rather than throwing', () {
      expect(parseOfficialAccountIdValue([1, 2, 3]), isNull);
      expect(parseOfficialAccountIdValue({'unrelated': 'x'}), isNull);
    });
  });

  group('isOfficialAccountRow — item 2: combined flag + id-pointer check', () {
    test('true when the boolean flag alone says official', () {
      expect(
        isOfficialAccountRow({
          'id': 'u1',
          'is_official_account': true,
        }, officialAccountId: null),
        isTrue,
      );
    });

    test('true when the flag is false/missing but the id matches the '
        'app_settings pointer — the exact scenario this pass exists for', () {
      expect(
        isOfficialAccountRow({
          'id': 'official-id',
          'is_official_account': false,
        }, officialAccountId: 'official-id'),
        isTrue,
      );
    });

    test('false for an ordinary row matching neither check', () {
      expect(
        isOfficialAccountRow({
          'id': 'someone-else',
          'is_official_account': false,
        }, officialAccountId: 'official-id'),
        isFalse,
      );
    });
  });

  group('applyOfficialIds / ExplorePerson.copyWithOfficial — item 1 '
      '(Discover-exclusion re-investigation pass): the actual root cause', () {
    test('ExplorePerson.fromMap on a REAL explore_people() row shape (no '
        'is_official_account column at all — matches '
        'test/explore_people_test.dart\'s own fixture) always parses '
        'isOfficial as false, proving the RPC never carries this flag', () {
      final p = ExplorePerson.fromMap({
        'id': 'the-official-account-id',
        'username': 'jma3a_official',
        'display_name': 'Jma3a Official',
        'honesty_points': 0,
        'general_score': 0,
        'rank_position': 1,
        'total_eligible': 1,
        'discovery_pool_size': 1,
      });
      expect(p.isOfficial, isFalse);
      // ... which is exactly why isDiscoverable alone could never
      // have excluded it — the flag it depends on was never true.
      expect(p.isDiscoverable, isTrue);
    });

    test('applyOfficialIds corrects isOfficial for exactly the matching '
        'id(s), leaving every other row untouched', () {
      final people = [
        _person(),
        ExplorePerson.fromMap({
          'id': 'official-id',
          'username': 'jma3a_official',
          'display_name': 'Jma3a Official',
          'honesty_points': 0,
          'general_score': 0,
          'rank_position': 2,
          'total_eligible': 2,
          'discovery_pool_size': 2,
        }),
      ];
      final corrected = applyOfficialIds(people, {'official-id'});

      expect(corrected[0].isOfficial, isFalse);
      expect(corrected[0].isDiscoverable, isTrue);
      expect(corrected[1].isOfficial, isTrue);
      expect(corrected[1].isDiscoverable, isFalse);
    });

    test('an empty officialIds set returns the list unchanged', () {
      final people = [_person()];
      final result = applyOfficialIds(people, const {});
      expect(result, same(people));
    });

    test('copyWithOfficial changes only isOfficial — every other field is '
        'preserved exactly', () {
      final original = ExplorePerson.fromMap({
        'id': 'u1',
        'username': 'sara',
        'display_name': 'Sara',
        'avatar_url': 'https://example.com/a.png',
        'honesty_points': 24,
        'general_score': 1420,
        'rank_position': 3,
        'total_eligible': 250,
        'discovery_pool_size': 125,
      });
      final marked = original.copyWithOfficial(true);

      expect(marked.isOfficial, isTrue);
      expect(marked.userId, original.userId);
      expect(marked.username, original.username);
      expect(marked.displayName, original.displayName);
      expect(marked.avatarUrl, original.avatarUrl);
      expect(marked.honestyPoints, original.honestyPoints);
      expect(marked.generalScore, original.generalScore);
      expect(marked.rankPosition, original.rankPosition);
      expect(marked.totalEligible, original.totalEligible);
      expect(marked.discoveryPoolSize, original.discoveryPoolSize);
    });
  });
}
