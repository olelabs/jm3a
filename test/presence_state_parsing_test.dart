// Regression test for the presence "appears completely non-functional"
// bug: PresenceService.currentPresence used to treat
// RealtimeChannel.presenceState()'s actual return type — a
// List<SinglePresenceState> in the pinned realtime_client version — as a
// Map, so `rawState is Map` was always false and the getter (and every UI
// surface reading it, via presenceStream) always returned {} regardless of
// who was actually tracked on the channel.
//
// The parsing logic was extracted to the pure top-level function
// parsePresenceState so it's directly testable against real
// SinglePresenceState/Presence value objects — both plain constructible,
// no live Supabase client/channel needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/services/presence_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SinglePresenceState _single(String key, Map<String, dynamic> payload) =>
    SinglePresenceState(
      key: key,
      presences: [Presence(presenceRef: 'ref-$key', payload: payload)],
    );

void main() {
  group('parsePresenceState', () {
    test('parses a realistic multi-user List<SinglePresenceState> into a '
        'userId-keyed map — the exact real-world shape presenceState() '
        'returns, previously always dropped to {}', () {
      final raw = [
        _single('u1', {'user_id': 'u1', 'status': 'online'}),
        _single('u2', {'user_id': 'u2', 'status': 'inGame', 'room_id': 'r1'}),
      ];
      final result = parsePresenceState(raw);
      expect(result.length, 2);
      expect(result['u1']!.status, UserPresenceStatus.online);
      expect(result['u2']!.status, UserPresenceStatus.inGame);
      expect(result['u2']!.roomId, 'r1');
    });

    test('empty raw state (nobody tracked) returns an empty map, not an '
        'error', () {
      expect(parsePresenceState(const []), isEmpty);
    });

    test('a key with an empty presences list (no active payload) is '
        'skipped rather than throwing', () {
      final raw = [SinglePresenceState(key: 'ghost', presences: const [])];
      expect(parsePresenceState(raw), isEmpty);
    });

    test('a payload missing user_id is skipped rather than crashing or '
        'being inserted under a null key', () {
      final raw = [_single('x', {'status': 'online'})];
      expect(parsePresenceState(raw), isEmpty);
    });

    test('when a key somehow has multiple presences (e.g. a stale extra '
        'tab), only the first is used — matches the single-status-per-user '
        'model the rest of this service assumes', () {
      final raw = [
        SinglePresenceState(
          key: 'u1',
          presences: [
            Presence(
              presenceRef: 'a',
              payload: {'user_id': 'u1', 'status': 'online'},
            ),
            Presence(
              presenceRef: 'b',
              payload: {'user_id': 'u1', 'status': 'offline'},
            ),
          ],
        ),
      ];
      final result = parsePresenceState(raw);
      expect(result.length, 1);
      expect(result['u1']!.status, UserPresenceStatus.online);
    });
  });
}
