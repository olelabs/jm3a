// Tests for the shared honesty-voting client-side pieces (see
// core/data/honesty_vote_repository.dart) — the ONE mechanism reused by
// ToD, NHIE, and Meme Game. The server (cast_honesty_vote RPC) is the
// real authority for every rule below; canCastHonestyVote only mirrors
// those rules client-side so the UI can hide/disable ineligible buttons
// instead of round-tripping to get rejected — verified separately against
// a real Postgres instance (see the migration's own test coverage).

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/data/honesty_vote_repository.dart';

void main() {
  group('canCastHonestyVote', () {
    const participants = ['p1', 'p2', 'p3'];

    test('a genuine participant voting on another participant, not yet '
        'voted, is eligible', () {
      expect(
        canCastHonestyVote(
          voterId: 'p1',
          targetUserId: 'p2',
          participantIds: participants,
          alreadyVoted: false,
        ),
        isTrue,
      );
    });

    test('voting on yourself is never eligible', () {
      expect(
        canCastHonestyVote(
          voterId: 'p1',
          targetUserId: 'p1',
          participantIds: participants,
          alreadyVoted: false,
        ),
        isFalse,
      );
    });

    test('a non-participant (spectator/outsider) voter is never eligible',
        () {
      expect(
        canCastHonestyVote(
          voterId: 'spectator1',
          targetUserId: 'p2',
          participantIds: participants,
          alreadyVoted: false,
        ),
        isFalse,
      );
    });

    test('a target who is not a participant is never eligible', () {
      expect(
        canCastHonestyVote(
          voterId: 'p1',
          targetUserId: 'outsider',
          participantIds: participants,
          alreadyVoted: false,
        ),
        isFalse,
      );
    });

    test('already having voted makes it ineligible, regardless of '
        'participant status', () {
      expect(
        canCastHonestyVote(
          voterId: 'p1',
          targetUserId: 'p2',
          participantIds: participants,
          alreadyVoted: true,
        ),
        isFalse,
      );
    });

    test('empty voter or target id is never eligible', () {
      expect(
        canCastHonestyVote(
          voterId: '',
          targetUserId: 'p2',
          participantIds: participants,
          alreadyVoted: false,
        ),
        isFalse,
      );
      expect(
        canCastHonestyVote(
          voterId: 'p1',
          targetUserId: '',
          participantIds: participants,
          alreadyVoted: false,
        ),
        isFalse,
      );
    });
  });

  group('HonestyVoteResult.fromMap', () {
    test('parses a newly-applied vote', () {
      final r = HonestyVoteResult.fromMap({
        'applied': true,
        'vote_id': 'v1',
        'is_honest': true,
        'points': 2,
      });
      expect(r.applied, isTrue);
      expect(r.voteId, 'v1');
      expect(r.isHonest, isTrue);
      expect(r.points, 2);
    });

    test('parses a not-honest vote with a negative point delta', () {
      final r = HonestyVoteResult.fromMap({
        'applied': true,
        'vote_id': 'v2',
        'is_honest': false,
        'points': -2,
      });
      expect(r.isHonest, isFalse);
      expect(r.points, -2);
    });

    test('a duplicate/no-op response has applied:false and no points key',
        () {
      final r = HonestyVoteResult.fromMap({
        'applied': false,
        'vote_id': 'v1',
        'is_honest': true,
      });
      expect(r.applied, isFalse);
      expect(r.points, isNull);
    });

    test('missing fields fall back safely, never throws', () {
      final r = HonestyVoteResult.fromMap(const {});
      expect(r.applied, isFalse);
      expect(r.voteId, isEmpty);
      expect(r.isHonest, isFalse);
      expect(r.points, isNull);
    });

    // 20260901090000_honesty_vote_reason.sql — dishonest-reason requirement.
    test('parses a not-honest vote with its reason', () {
      final r = HonestyVoteResult.fromMap({
        'applied': true,
        'vote_id': 'v3',
        'is_honest': false,
        'points': -2,
        'reason': 'You changed your answer mid-round',
      });
      expect(r.reason, 'You changed your answer mid-round');
    });

    test('an honest vote has a null reason', () {
      final r = HonestyVoteResult.fromMap({
        'applied': true,
        'vote_id': 'v4',
        'is_honest': true,
        'points': 2,
        'reason': null,
      });
      expect(r.reason, isNull);
    });

    test('a duplicate dishonest vote returns the ORIGINAL reason, not a '
        'new one this call attempted to send', () {
      final r = HonestyVoteResult.fromMap({
        'applied': false,
        'vote_id': 'v3',
        'is_honest': false,
        'reason': 'the first reason ever given',
      });
      expect(r.applied, isFalse);
      expect(r.reason, 'the first reason ever given');
    });
  });

  group('HonestyVoteReason.fromMap', () {
    test('parses reason + createdAt, never exposes a voter identity field', () {
      final r = HonestyVoteReason.fromMap({
        'reason': 'You said something different earlier',
        'created_at': '2026-09-01T12:00:00.000Z',
      });
      expect(r.reason, 'You said something different earlier');
      expect(r.createdAt, DateTime.parse('2026-09-01T12:00:00.000Z'));
    });

    test('missing reason falls back to empty string, never throws', () {
      final r = HonestyVoteReason.fromMap({
        'created_at': '2026-09-01T12:00:00.000Z',
      });
      expect(r.reason, isEmpty);
    });
  });
}
