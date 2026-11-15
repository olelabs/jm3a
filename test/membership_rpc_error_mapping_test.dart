// Phase 1C-B-2 — exact mapping of the B-1 membership RPC error codes
// (RAISE EXCEPTION '<code>', SQLSTATE P0001) to the app's Failure types.
// membershipRpcFailure is pure, so every code is checked without a database.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/errors/failures.dart';
import 'package:jma3a/features/rooms/data/room_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

PostgrestException _rpcError(String message, {String? code = 'P0001'}) =>
    PostgrestException(message: message, code: code);

void main() {
  group('membershipRpcFailure — every B-1 code maps exactly', () {
    const expected = <String, Type>{
      'not_authenticated': AuthFailure,
      'invalid_mode': ValidationFailure,
      'invalid_argument': ValidationFailure,
      'invalid_target': ValidationFailure,
      'room_not_found': NotFoundFailure,
      'room_closed': NotFoundFailure,
      'kicked': ForbiddenFailure,
      'banned': ForbiddenFailure,
      'owner_absent': NotFoundFailure,
      'spectators_not_allowed': ForbiddenFailure,
      'anonymous_spectators_not_allowed': ForbiddenFailure,
      'premium_required': ForbiddenFailure,
      'approval_required': ConflictFailure,
      'spectator_approval_required': ConflictFailure,
      'rejoin_approval_required': ConflictFailure,
      'owner_seat_unavailable': ConflictFailure,
      'room_full': ConflictFailure,
      'resume_not_allowed': ForbiddenFailure,
      'owner_must_close': ForbiddenFailure,
      'not_a_member': ForbiddenFailure,
      'cannot_evict_owner': ForbiddenFailure,
      'room_paused': ConflictFailure,
      'target_not_stale': ConflictFailure,
    };

    test('the known code set is exactly the B-1 set', () {
      expect(membershipRpcErrorCodes, expected.keys.toSet());
    });

    for (final entry in expected.entries) {
      test('${entry.key} -> ${entry.value} carrying the code', () {
        final failure = membershipRpcFailure(_rpcError(entry.key));
        expect(failure, isNotNull);
        expect(failure.runtimeType, entry.value);
        expect(failure!.code, entry.key);
      });
    }
  });

  group('membershipRpcFailure — approval codes are never conflated', () {
    test('rejoin_/spectator_approval_required keep their own code', () {
      expect(
        membershipRpcFailure(_rpcError('rejoin_approval_required'))!.code,
        'rejoin_approval_required',
      );
      expect(
        membershipRpcFailure(_rpcError('spectator_approval_required'))!.code,
        'spectator_approval_required',
      );
      expect(
        membershipRpcFailure(_rpcError('approval_required'))!.code,
        'approval_required',
      );
    });
  });

  group('membershipRpcFailure — non-B-1 errors are not mapped', () {
    test('substring / padded / prefixed messages are rejected', () {
      for (final message in [
        'xroom_full',
        'room_full ',
        'error: room_full',
        'ROOM_FULL',
        'new row for relation "rooms" violates check constraint "chk_player_count"',
      ]) {
        expect(membershipRpcFailure(_rpcError(message)), isNull, reason: message);
      }
    });

    test('a known code with a non-P0001 SQLSTATE is not mapped', () {
      expect(membershipRpcFailure(_rpcError('room_full', code: '23514')), isNull);
      expect(membershipRpcFailure(_rpcError('room_full', code: null)), isNull);
    });
  });

  group('messages the old direct-write join path produced are unchanged', () {
    const verbatim = {
      'room_not_found': 'Room not found or no longer available.',
      'room_closed': 'This room has been closed by the host.',
      'owner_absent': 'The host has left. This room is no longer available.',
      'room_full': 'Room is full.',
      'banned': 'You are banned from this room.',
    };
    for (final entry in verbatim.entries) {
      test(entry.key, () {
        expect(membershipRpcFailure(_rpcError(entry.key))!.message, entry.value);
      });
    }
  });

  group('membershipTerminalJoinRefusals', () {
    test('is exactly B-1\'s new terminal join refusals', () {
      expect(membershipTerminalJoinRefusals, {
        'kicked',
        'owner_seat_unavailable',
        'premium_required',
        'spectators_not_allowed',
        'anonymous_spectators_not_allowed',
        'invalid_mode',
      });
    });

    test('contains no routing code and no pre-B-1 refusal', () {
      for (final code in [
        'approval_required',
        'spectator_approval_required',
        'rejoin_approval_required',
        'room_full',
        'banned',
        'room_closed',
        'room_not_found',
        'owner_absent',
      ]) {
        expect(membershipTerminalJoinRefusals.contains(code), isFalse,
            reason: code);
      }
    });
  });
}
