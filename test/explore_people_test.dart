// Tests for the Explore People client-side model (see
// friends_repository.dart's ExplorePerson and FriendsRepository.
// explorePeople). The actual ranking formula, the >100-eligible 50%
// discovery-pool rule, exclusion enforcement (self/friends/pending/
// blocked/banned/deleted), and keyset pagination correctness are ALL
// enforced server-side in public.explore_people() and are verified
// against a real Postgres instance — see
// supabase/migrations/tests/20260901_honesty_reason_and_explore_people_
// test.sql, which covers exactly those scenarios with deterministic
// fixtures (105 seeded users, exclusion fixtures, page-boundary checks).
// This file only covers what's genuinely Dart-side: safe parsing of the
// RPC's response shape.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/friends/data/friends_repository.dart';

void main() {
  group('ExplorePerson.fromMap', () {
    test('parses a full row', () {
      final p = ExplorePerson.fromMap({
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
      expect(p.userId, 'u1');
      expect(p.username, 'sara');
      expect(p.displayName, 'Sara');
      expect(p.avatarUrl, 'https://example.com/a.png');
      expect(p.honestyPoints, 24);
      expect(p.generalScore, 1420);
      expect(p.rankPosition, 3);
      expect(p.totalEligible, 250);
      expect(p.discoveryPoolSize, 125);
    });

    test('negative honesty_points is preserved, never clamped', () {
      final p = ExplorePerson.fromMap({
        'id': 'u2',
        'display_name': 'Bad Actor',
        'honesty_points': -7,
        'general_score': 500,
        'rank_position': 200,
        'total_eligible': 250,
        'discovery_pool_size': 125,
      });
      expect(p.honestyPoints, -7);
    });

    test('falls back to username when display_name is missing, never '
        'throws', () {
      final p = ExplorePerson.fromMap({
        'id': 'u3',
        'username': 'nodisplayname',
        'honesty_points': 0,
        'general_score': 0,
        'rank_position': 1,
        'total_eligible': 1,
        'discovery_pool_size': 1,
      });
      expect(p.displayName, 'nodisplayname');
    });

    test('missing numeric fields fall back safely, never throws', () {
      final p = ExplorePerson.fromMap({'id': 'u4', 'display_name': 'X'});
      expect(p.honestyPoints, 0);
      expect(p.generalScore, 0);
      expect(p.rankPosition, 0);
      expect(p.totalEligible, 0);
      expect(p.discoveryPoolSize, 0);
    });
  });
}
