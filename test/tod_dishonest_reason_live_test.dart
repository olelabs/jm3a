// Regression tests for "ToD dishonest reason — immediate visibility +
// private history": a dishonest vote's reason must reach the affected
// player's reveal screen live (no refresh/reconnect), via a realtime
// signal that is deliberately content-free — it carries no reason text and
// no voter identity, so the anonymity guarantee can never leak over the
// realtime layer. The receiving client always re-fetches the real data
// through the existing RLS-backed, anonymous
// HonestyVoteRepository.getDishonestReasons() — these two pure functions
// are the entire live-update mechanism and are fully testable without a
// live TodGameProvider/Supabase client (this codebase's established
// "no injectable mock seam" constraint).
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/truth_or_dare/domain/tod_models.dart';

void main() {
  group('buildDishonestReasonBroadcastPayload — anonymity over the wire', () {
    test('carries only type/response_key/target_user_id/ts — nothing else', () {
      final payload = buildDishonestReasonBroadcastPayload(
        responseKey: 'round:3',
        targetUserId: 'target-1',
      );
      expect(
        payload.keys.toSet(),
        {'type', 'response_key', 'target_user_id', 'ts'},
      );
      expect(payload['type'], 'dishonest_reason_added');
      expect(payload['response_key'], 'round:3');
      expect(payload['target_user_id'], 'target-1');
    });

    test('never contains a reason field under any spelling', () {
      final payload = buildDishonestReasonBroadcastPayload(
        responseKey: 'round:1',
        targetUserId: 'u',
      );
      for (final key in payload.keys) {
        expect(key.toLowerCase(), isNot(contains('reason')));
      }
    });

    test('never contains voter identity under any spelling', () {
      final payload = buildDishonestReasonBroadcastPayload(
        responseKey: 'round:1',
        targetUserId: 'u',
      );
      for (final key in payload.keys) {
        expect(key.toLowerCase(), isNot(contains('voter')));
      }
    });
  });

  group('applyDishonestReasonSignal — live re-fetch trigger', () {
    test('first signal for a round bumps its generation from 0 to 1', () {
      final result = applyDishonestReasonSignal(const {}, {
        'response_key': 'round:2',
      });
      expect(result['round:2'], 1);
    });

    test('second and third reason arriving live keep incrementing', () {
      var generations = <String, int>{};
      generations = applyDishonestReasonSignal(generations, {
        'response_key': 'round:5',
      });
      generations = applyDishonestReasonSignal(generations, {
        'response_key': 'round:5',
      });
      generations = applyDishonestReasonSignal(generations, {
        'response_key': 'round:5',
      });
      expect(generations['round:5'], 3);
    });

    test('a signal for one round never bumps a different round', () {
      var generations = <String, int>{'round:1': 4};
      generations = applyDishonestReasonSignal(generations, {
        'response_key': 'round:2',
      });
      expect(generations['round:1'], 4);
      expect(generations['round:2'], 1);
    });

    test('missing response_key is a no-op, never throws', () {
      const original = {'round:1': 2};
      final result = applyDishonestReasonSignal(original, {});
      expect(result, original);
    });

    test('empty response_key is a no-op', () {
      const original = {'round:1': 2};
      final result = applyDishonestReasonSignal(original, {
        'response_key': '',
      });
      expect(result, original);
    });

    test('does not mutate the input map (pure)', () {
      final original = {'round:1': 1};
      final result = applyDishonestReasonSignal(original, {
        'response_key': 'round:1',
      });
      expect(original['round:1'], 1);
      expect(result['round:1'], 2);
    });
  });
}
