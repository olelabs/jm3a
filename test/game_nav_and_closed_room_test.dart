// Tests for the two fixes in "Game Navigation & Closed Room":
//   1. Closed-room reconnect — the authoritative session-participant rule that
//      decides who may return to (and not be bounced from) a closed room, and
//      who stays blocked. Exercises RoomProvider.computeSessionParticipant, the
//      single source of truth used by both the closed-room entry gate and
//      joinRoom's closed-status bypass.
//   2. Active-game back guard — the GameBackController registry that
//      GameScreenSecurityGate uses as the ONE route-level back handler for
//      every game, so no back path can escape an active game to Browse.
//
// The full UI wiring (PopScope interception, the per-game leave dialogs, the
// relaunch/reconnect flow) needs real-device/multi-device verification; these
// cover the deterministic decision logic those layers delegate to.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/games/presentation/widgets/game_screen_security_gate.dart';
import 'package:jma3a/features/rooms/presentation/room_provider.dart';

void main() {
  group('Closed-room reconnect — computeSessionParticipant', () {
    const me = 'u1';
    const players = ['u1', 'u2', 'u3'];

    bool participant({
      List<String> ids = players,
      String user = me,
      bool hasRow = true,
      bool kicked = false,
      bool left = false,
    }) => RoomProvider.computeSessionParticipant(
      sessionPlayerIds: ids,
      userId: user,
      hasMemberRow: hasRow,
      isKicked: kicked,
      leftDefinitively: left,
    );

    test('a valid participant of the session may return', () {
      expect(participant(), isTrue);
    });

    test('a grace-evicted participant (not kicked, not permanent-left) still '
        'counts — they are resuming, not re-joining', () {
      // left_at being set is represented upstream; what matters here is that
      // kicked_at is null and left_definitively is false.
      expect(participant(kicked: false, left: false), isTrue);
    });

    test('a user not in the session player_ids is NOT a participant', () {
      expect(participant(user: 'stranger'), isFalse);
      expect(participant(ids: ['u2', 'u3']), isFalse);
    });

    test('a kicked user is blocked even if still in player_ids', () {
      expect(participant(kicked: true), isFalse);
    });

    test('a permanent leaver is blocked', () {
      expect(participant(left: true), isFalse);
    });

    test('no member row at all means not a participant', () {
      expect(participant(hasRow: false), isFalse);
    });

    test('an empty session (no game ever) yields no participants', () {
      expect(participant(ids: const []), isFalse);
    });
  });

  group('Active-game back guard — GameBackController', () {
    test('a registered handler is the one the gate will call', () async {
      final c = GameBackController();
      var called = 0;
      Future<bool> handler() async {
        called++;
        return true;
      }

      expect(c.handler, isNull);
      c.register(handler);
      expect(c.handler, isNotNull);
      // The gate delegates to whatever handler is registered.
      final consumed = await c.handler!();
      expect(consumed, isTrue);
      expect(called, 1);
    });

    test('registering a new handler replaces the previous one (only one game '
        'route is mounted at a time)', () {
      final c = GameBackController();
      Future<bool> a() async => true;
      Future<bool> b() async => true;
      c.register(a);
      c.register(b);
      expect(identical(c.handler, b), isTrue);
    });

    test('unregister only clears the slot if it still owns it', () {
      final c = GameBackController();
      Future<bool> a() async => true;
      Future<bool> b() async => true;
      c.register(a);
      // A stale unregister (e.g. an old screen disposing after a new one
      // registered) must NOT wipe the current handler.
      c.register(b);
      c.unregister(a);
      expect(identical(c.handler, b), isTrue);
      // The owner's own unregister clears it.
      c.unregister(b);
      expect(c.handler, isNull);
    });
  });
}
