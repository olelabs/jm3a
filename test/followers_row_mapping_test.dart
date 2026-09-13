// Item 8 (followers investigation pass) — regression coverage for the
// actual root cause found: FriendsRepository.getFollowers/getFollowing
// used `rows.map(_toFollowEntity).toList()` directly. `.map().toList()`
// evaluates EAGERLY, so a single malformed row (e.g. a legacy row whose
// avatar_config isn't actually a JSON object — the exact shape
// `_toFollowEntity`'s `Map<String, dynamic>.from(profile['avatar_config']
// as Map)` cast assumes) throws, and that ONE throw discards the ENTIRE
// list via guardedCall's own catch converting it to a Failure — not just
// that one row. From FollowersScreen's point of view, one bad follower
// row makes ALL of a real user's followers disappear behind the error
// state, exactly matching "I have followers but the screen shows
// nothing". mapFollowRowsSafely (friends_repository.dart) is the fix:
// per-row isolation, a bad row is skipped and logged, every other row
// still renders.
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/friends/data/friends_repository.dart';

FollowEntity _entity(String id) => FollowEntity(
  userId: id,
  displayName: 'User $id',
  followedAt: DateTime(2026),
);

/// Mirrors _toFollowEntity's real, exact failure mode: a legacy/malformed
/// avatar_config that isn't a JSON object (e.g. stored as a JSON array or
/// a raw string) makes `Map<String, dynamic>.from(... as Map)` throw a
/// real TypeError — not a null, not a caught/defaulted value.
FollowEntity _realisticToEntity(Map<String, dynamic> row) {
  final profile = row['profiles'] as Map<String, dynamic>? ?? {};
  final avatarConfigRaw = profile['avatar_config'];
  final avatarConfig = avatarConfigRaw != null
      ? Map<String, dynamic>.from(avatarConfigRaw as Map)
      : null;
  return FollowEntity(
    userId: profile['id'] as String? ?? '',
    displayName: profile['display_name'] as String? ?? 'User',
    avatarConfig: avatarConfig,
    followedAt: DateTime.parse(row['created_at'] as String),
  );
}

void main() {
  // AppLogger (called internally by mapFollowRowsSafely when a row
  // fails) reads AppConfig.isDevelopment -> dotenv, never loaded in a
  // bare unit test otherwise.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  group(
    'mapFollowRowsSafely — per-row isolation (item 8 root cause + fix)',
    () {
      test('every row maps normally when nothing is malformed', () {
        final rows = [
          {'follower_id': 'a'},
          {'follower_id': 'b'},
          {'follower_id': 'c'},
        ];
        final result = mapFollowRowsSafely(
          rows,
          operationName: 'test',
          toEntity: (row) => _entity(row['follower_id'] as String),
        );
        expect(result.map((e) => e.userId), ['a', 'b', 'c']);
      });

      test('empty input produces an empty list, not an error', () {
        final result = mapFollowRowsSafely(
          const [],
          operationName: 'test',
          toEntity: (row) => _entity(row['follower_id'] as String),
        );
        expect(result, isEmpty);
      });

      test('ONE malformed row is skipped — every OTHER row still maps '
          'correctly (the exact fix for the reported symptom: before this, '
          'this exact scenario returned an EMPTY list / a thrown Failure '
          'for the whole batch, not just the bad row)', () {
        final rows = [
          {'follower_id': 'a'},
          {'follower_id': 'BAD'}, // toEntity throws for this one below
          {'follower_id': 'c'},
        ];
        final result = mapFollowRowsSafely(
          rows,
          operationName: 'test',
          toEntity: (row) {
            final id = row['follower_id'] as String;
            if (id == 'BAD') throw const FormatException('bad row');
            return _entity(id);
          },
        );
        expect(result.map((e) => e.userId), ['a', 'c']);
      });

      test('every row malformed still returns an empty list, never throws', () {
        final result = mapFollowRowsSafely(
          [
            {'x': 1},
            {'x': 2},
          ],
          operationName: 'test',
          toEntity: (row) => throw StateError('always fails'),
        );
        expect(result, isEmpty);
      });

      test('reproduces the REAL bug with realistic PostgREST-shaped rows: a '
          'legacy row whose avatar_config is a JSON array (not an object) '
          'no longer takes down two perfectly good rows around it', () {
        final rows = [
          {
            'follower_id': 'good-1',
            'created_at': '2026-01-01T00:00:00Z',
            'profiles': {'id': 'good-1', 'display_name': 'Amina'},
          },
          {
            'follower_id': 'legacy-bad',
            'created_at': '2026-01-02T00:00:00Z',
            // A malformed avatar_config: a JSON array, not an object —
            // `Map<String, dynamic>.from(... as Map)` throws a real
            // TypeError for exactly this shape.
            'profiles': {
              'id': 'legacy-bad',
              'display_name': 'Legacy',
              'avatar_config': [1, 2, 3],
            },
          },
          {
            'follower_id': 'good-2',
            'created_at': '2026-01-03T00:00:00Z',
            'profiles': {'id': 'good-2', 'display_name': 'Youssef'},
          },
        ];

        final result = mapFollowRowsSafely(
          rows,
          operationName: 'getFollowers',
          toEntity: _realisticToEntity,
        );

        expect(result.map((e) => e.userId), ['good-1', 'good-2']);
      });
    },
  );
}
