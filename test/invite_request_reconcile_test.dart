// Regression tests for the "invitation + existing join request creates a
// duplicate room identity" bug.
//
// Root cause: in an approval-required room, when a user who already had a
// pending join request entered via a valid invitation, the client marked the
// invite accepted and joined, but NEVER reconciled the pending join request —
// leaving the same user_id appearing as both a member and a pending requester.
// The membership row itself was never duplicated (room_members has
// UNIQUE(room_id, user_id) and the client upserts on that key); the defect was
// the orphaned pending request.
//
// The authoritative fix is the atomic SECURITY DEFINER RPC accept_room_invite
// (migration_2026_invite_request_reconcile.sql / schema.sql), which — keyed on
// auth.uid() — validates the invite, reuses-or-creates one membership, resolves
// the pending request, and marks the invite consumed, all in one transaction.
//
// Two testable layers here:
//   A. The client-side canonical-identity guard `dedupeMembersByUserId` (the
//      code RoomProvider actually runs on every member-list assignment).
//   B. The authoritative RPC CONTRACT — asserted by reading the migration SQL
//      and verifying it still contains every reconciliation clause. This can't
//      execute Postgres in `flutter test`, so it guards the source of truth
//      against regression; the actual atomic execution and the concurrency /
//      reconnect / stale-event races (Tests 3, 4, 6) require the live DB and
//      multi-device verification, which this file documents but does not fake.

import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/features/rooms/presentation/room_provider.dart';

RoomMemberEntity _member(
  String id, {
  bool spectator = false,
  bool hidden = false,
  int seat = 0,
  bool ready = false,
}) => RoomMemberEntity(
      userId: id,
      displayName: 'name-$id',
      seatOrder: seat,
      isReady: ready,
      isOwner: false,
      isModerator: false,
      isSpectator: spectator,
      isHiddenSpectator: hidden,
    );

void main() {
  // dedupeMembersByUserId logs DUPLICATE_ROOM_MEMBER via AppLogger on a
  // collision, and AppLogger reads AppConfig (dotenv) for its level — load a
  // minimal env so those diagnostic logs don't throw in the bare test VM.
  setUpAll(() => dotenv.testLoad(fileInput: 'APP_ENV=development'));

  // ── Layer A: canonical identity in the client member list ────────────────
  group('dedupeMembersByUserId — (room_id, user_id) is one member', () {
    test('the same user_id never appears twice; later entry wins', () {
      // Simulate a member list accidentally combined from two sources for the
      // same user (e.g. request path + invitation path).
      final requestView = _member('u1', seat: 3, ready: false);
      final invitationView = _member('u1', seat: 0, ready: true);
      final result = RoomProvider.dedupeMembersByUserId([
        requestView,
        _member('owner'),
        invitationView,
      ]);
      expect(result.where((m) => m.userId == 'u1').length, 1);
      expect(result.length, 2); // u1 + owner
      // Later (authoritative/fresh) entry wins.
      final u1 = result.firstWhere((m) => m.userId == 'u1');
      expect(u1.isReady, isTrue);
      expect(u1.seatOrder, 0);
    });

    test('Test 12 — a user is never player + spectator at once', () {
      // Same user entered once as a player and once as a spectator via a
      // different flow. The canonical identity collapses to exactly one role
      // (the later/authoritative one).
      final asPlayer = _member('u9', spectator: false);
      final asSpectator = _member('u9', spectator: true, hidden: true);
      final result = RoomProvider.dedupeMembersByUserId([asPlayer, asSpectator]);
      expect(result.length, 1);
      expect(result.single.userId, 'u9');
      // Exactly one role — not both.
      expect(result.single.isSpectator, isTrue); // later entry
    });

    test('Test 5 — reconnect: same membership listed twice collapses to one',
        () {
      // A reconnect that momentarily merges the cached row with the freshly
      // fetched row must not produce two copies.
      final result = RoomProvider.dedupeMembersByUserId([
        _member('owner'),
        _member('u2'),
        _member('u2'), // duplicate from a merge/reconnect
      ]);
      expect(result.length, 2);
      expect(result.map((m) => m.userId).toList(), ['owner', 'u2']);
    });

    test('an already-clean list is returned unchanged in order', () {
      final input = [_member('a'), _member('b'), _member('c')];
      final result = RoomProvider.dedupeMembersByUserId(input);
      expect(result.map((m) => m.userId).toList(), ['a', 'b', 'c']);
    });

    test('empty list stays empty', () {
      expect(RoomProvider.dedupeMembersByUserId(const []), isEmpty);
    });
  });

  // ── Layer B: the authoritative RPC contract (source-of-truth guard) ──────
  group('accept_room_invite RPC contract (authoritative reconciliation)', () {
    late String sql;

    setUpAll(() {
      // Read from the project root (flutter test runs with the package root as
      // the working directory).
      sql = File('migration_2026_invite_request_reconcile.sql').readAsStringSync();
    });

    test('exists as a SECURITY DEFINER function', () {
      expect(sql, contains('FUNCTION public.accept_room_invite(p_room_id uuid)'));
      expect(sql, contains('SECURITY DEFINER'));
    });

    test('Tests 1 & 9 — resolves the pending join request to approved', () {
      // The exact clause that fixes the bug: a pending request for the SAME
      // user_id is fulfilled, not left pending.
      expect(sql, contains('UPDATE public.room_join_requests'));
      expect(sql, contains("SET status = 'approved'"));
      expect(
        sql,
        contains('WHERE room_id = p_room_id AND user_id = v_uid AND status = '
            "'pending'"),
      );
    });

    test('Tests 2, 3, 4 — membership is reuse-or-create, race-safe on the '
        'unique key (never a second membership)', () {
      expect(sql, contains('INSERT INTO public.room_members'));
      expect(sql, contains('ON CONFLICT (room_id, user_id) DO UPDATE'));
      // Reuse clears the soft-removed markers instead of inserting a new row.
      expect(sql, contains('SET left_at = NULL'));
    });

    test('Test 7 — invitation only authorizes the invited user_id '
        '(invited_user = auth.uid())', () {
      expect(sql, contains('v_uid uuid := auth.uid()'));
      expect(sql, contains('invited_user = v_uid'));
      expect(sql, contains('no_valid_invite'));
    });

    test('Test 8 — an invitation never overrides a ban', () {
      expect(sql, contains('room_bans'));
      expect(sql, contains("RAISE EXCEPTION 'banned'"));
    });

    test('marks the invitation consumed', () {
      expect(sql, contains('UPDATE public.room_invites'));
      expect(sql, contains('accepted_at = now()'));
    });

    test('capacity is enforced for a newly-admitted player', () {
      expect(sql, contains("RAISE EXCEPTION 'room_full'"));
    });
  });

  // ── Documented invariant (not executable here) ───────────────────────────
  //
  // For every room, (room_id, user_id) identifies exactly one logical room
  // membership. A join request, invitation, notification, reconnect, or device
  // is never a separate member identity. Successful room entry reconciles all
  // pending access mechanisms for that same user and room.
  //
  // Tests requiring the live DB / multiple devices (NOT faked here):
  //  - Test 3: two simultaneous invitation accepts -> one membership
  //            (guaranteed by ON CONFLICT on the unique key, asserted above).
  //  - Test 4: request-approval and invitation-acceptance nearly simultaneously
  //            -> one membership (both funnel through the same unique key).
  //  - Test 6: a stale pending-request realtime event after acceptance -> the
  //            request stays approved (the admin panel polls the authoritative
  //            room_join_requests.status, which is now 'approved'; there is no
  //            realtime subscription that could revive it as pending).
  //  - Test 10: normal approval flow with no invitation still works
  //            (unchanged decide_join_request path).
}
