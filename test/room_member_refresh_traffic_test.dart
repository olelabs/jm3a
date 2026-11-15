// Room/game traffic Stage A.
//
// Root cause: every touch_room_presence heartbeat updates
// room_members.last_seen_at, every such UPDATE reached every client's
// room_members Realtime subscription, and each one ran a full 3-request
// _refreshMembers (rooms, room_members+profiles, room_moderators). An
// unfiltered `profiles` subscription did the same for every profile update
// in the database. Triggers arriving together each ran their own fetch.
//
// Fix, exercised here: the pure static decisions RoomProvider applies to
// each member event (RoomProvider.isHeartbeatOnlyMemberUpdate /
// periodicMemberRefreshActive), the CoalescedRunner every _refreshMembers
// goes through, and — structurally, since RoomProvider needs a live
// Supabase client — the subscription wiring and disposal.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/utils/coalesced_runner.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/features/rooms/presentation/room_provider.dart';

Map<String, dynamic> _row({
  String id = 'row-1',
  String userId = 'u1',
  String role = 'player',
  int seatOrder = 0,
  bool isReady = false,
  bool isMuted = false,
  bool isGameMuted = false,
  bool isAway = false,
  bool leftDefinitively = false,
  bool isHiddenSpectator = false,
  String? leftAt,
  String? kickedAt,
  String joinedAt = '2026-09-28T10:00:00+00:00',
  String lastSeenAt = '2026-09-28T10:00:00+00:00',
}) => {
  'id': id,
  'room_id': 'room-1',
  'user_id': userId,
  'role': role,
  'seat_order': seatOrder,
  'is_ready': isReady,
  'is_muted': isMuted,
  'is_game_muted': isGameMuted,
  'joined_at': joinedAt,
  'left_at': leftAt,
  'kicked_at': kickedAt,
  'is_away': isAway,
  'left_definitively': leftDefinitively,
  'is_hidden_spectator': isHiddenSpectator,
  'last_seen_at': lastSeenAt,
};

bool _heartbeatOnly(Map<String, dynamic>? previous, Map<String, dynamic> current) =>
    RoomProvider.isHeartbeatOnlyMemberUpdate(previous: previous, current: current);

const _t1 = '2026-09-28T10:00:10+00:00';

String _src(String path) => File(path).readAsStringSync();

void main() {
  group('member Realtime events — heartbeat-only detection', () {
    test('1. a last_seen_at-only update is heartbeat-only (no refresh)', () {
      expect(_heartbeatOnly(_row(), _row(lastSeenAt: _t1)), isTrue);
    });

    test('2. is_ready change is meaningful', () {
      expect(_heartbeatOnly(_row(), _row(isReady: true, lastSeenAt: _t1)), isFalse);
      expect(_heartbeatOnly(_row(isReady: true), _row(isReady: false)), isFalse);
    });

    test('3. membership changes are meaningful (seat, rejoin, hidden spectator)', () {
      expect(_heartbeatOnly(_row(), _row(seatOrder: 2)), isFalse);
      expect(_heartbeatOnly(_row(), _row(joinedAt: _t1)), isFalse);
      expect(_heartbeatOnly(_row(), _row(isHiddenSpectator: true)), isFalse);
    });

    test('4. role change is meaningful', () {
      expect(_heartbeatOnly(_row(), _row(role: 'spectator')), isFalse);
    });

    test('5. mute / game-mute / away changes are meaningful', () {
      expect(_heartbeatOnly(_row(), _row(isMuted: true)), isFalse);
      expect(_heartbeatOnly(_row(), _row(isGameMuted: true)), isFalse);
      expect(_heartbeatOnly(_row(), _row(isAway: true)), isFalse);
      expect(_heartbeatOnly(_row(isAway: true), _row(isAway: true, leftDefinitively: true)), isFalse);
    });

    test('6. leave / kick / removal are meaningful', () {
      expect(_heartbeatOnly(_row(), _row(leftAt: _t1)), isFalse);
      expect(_heartbeatOnly(_row(), _row(kickedAt: _t1)), isFalse);
    });

    test('7. any other column change (incl. ownership-related user/room ids) is meaningful', () {
      expect(_heartbeatOnly(_row(), _row(userId: 'u2')), isFalse);
      final moved = _row()..['room_id'] = 'room-2';
      expect(_heartbeatOnly(_row(), moved), isFalse);
      final extra = _row(lastSeenAt: _t1)..['future_column'] = 1;
      expect(_heartbeatOnly(_row(), extra), isFalse); // unknown new column -> refresh
    });

    test('no previous record (first event for the row / after resubscribe) always refreshes', () {
      expect(_heartbeatOnly(null, _row(lastSeenAt: _t1)), isFalse);
    });

    test('a column missing from one payload is never treated as unchanged', () {
      final partial = _row(lastSeenAt: _t1)..remove('is_ready');
      expect(_heartbeatOnly(_row(), partial), isFalse);
    });

    test('a missed event still shows up: heartbeat after an unseen is_ready change refreshes', () {
      // previous stored = not ready; the is_ready=true event was missed; the
      // next heartbeat carries is_ready=true -> differs -> refresh.
      expect(_heartbeatOnly(_row(), _row(isReady: true, lastSeenAt: _t1)), isFalse);
    });
  });

  group('member Realtime events — skipped only while a periodic re-fetch runs', () {
    bool covers(RoomStatus? s, {bool ready = false, bool reconcile = false}) =>
        RoomProvider.periodicMemberRefreshActive(status: s, readyPollActive: ready, reconcileActive: reconcile);

    test('lobby: only while the ready poll runs', () {
      expect(covers(RoomStatus.waiting, ready: true, reconcile: true), isTrue);
      // back in the lobby after a game: ready poll not re-armed -> keep refreshing
      expect(covers(RoomStatus.waiting, ready: false, reconcile: true), isFalse);
    });

    test('game: only while the reconcile tick runs', () {
      for (final s in [RoomStatus.starting, RoomStatus.inGame, RoomStatus.paused]) {
        expect(covers(s, reconcile: true), isTrue, reason: '$s');
        expect(covers(s, ready: true, reconcile: false), isFalse, reason: '$s');
      }
    });

    test('ended / closed / unknown: never skipped', () {
      for (final s in [RoomStatus.ended, RoomStatus.closed, null]) {
        expect(covers(s, ready: true, reconcile: true), isFalse, reason: '$s');
      }
    });
  });

  group('CoalescedRunner (every _refreshMembers goes through it)', () {
    test('10/11. a burst while running collapses into one current + one trailing run', () async {
      final gates = <Completer<void>>[];
      final args = <String>[];
      var active = 0;
      var maxActive = 0;
      final runner = CoalescedRunner<String>((arg) async {
        args.add(arg);
        active++;
        maxActive = active > maxActive ? active : maxActive;
        final gate = Completer<void>();
        gates.add(gate);
        await gate.future;
        active--;
      });

      final first = runner.request('a');
      final burst = [for (var i = 0; i < 10; i++) runner.request('b$i')];
      expect(args, ['a']);
      gates[0].complete();
      await Future<void>.delayed(Duration.zero);
      expect(args, ['a', 'b9']); // one trailing run, latest argument
      gates[1].complete();
      await Future.wait([first, ...burst]);
      expect(args, hasLength(2));
      expect(maxActive, 1); // never concurrent
      expect(runner.isRunning, isFalse);
    });

    test('two requests while the first runs produce at most two runs', () async {
      var runs = 0;
      final gate = Completer<void>();
      final runner = CoalescedRunner<String>((_) async {
        runs++;
        if (runs == 1) await gate.future;
      });
      final a = runner.request('r');
      final b = runner.request('r');
      final c = runner.request('r');
      gate.complete();
      await Future.wait([a, b, c]);
      expect(runs, 2);
    });

    test('12. runs are strictly sequential, so an older fetch can never land after a newer one', () async {
      final order = <String>[];
      final gate = Completer<void>();
      final runner = CoalescedRunner<String>((arg) async {
        order.add('start $arg');
        if (arg == 'old') await gate.future;
        order.add('end $arg');
      });
      final old = runner.request('old');
      final newer = runner.request('new');
      gate.complete();
      await Future.wait([old, newer]);
      expect(order, ['start old', 'end old', 'start new', 'end new']);
    });

    test('a request made mid-flight completes only after a run that started after it', () async {
      final gate = Completer<void>();
      var runs = 0;
      final runner = CoalescedRunner<String>((_) async {
        runs++;
        if (runs == 1) await gate.future;
      });
      runner.request('x');
      var midFlightDone = false;
      runner.request('x').then((_) => midFlightDone = true);
      gate.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(runs, 2);
      expect(midFlightDone, isTrue);
    });

    test('13/14. a failing run is reported, runs the trailing request, and never blocks later requests', () async {
      final errors = <Object>[];
      var calls = 0;
      final gate = Completer<void>();
      final runner = CoalescedRunner<String>((_) async {
        calls++;
        if (calls == 1) {
          await gate.future;
          throw StateError('network');
        }
      }, onError: (e, _) => errors.add(e));
      final a = runner.request('r');
      final b = runner.request('r');
      gate.complete();
      await Future.wait([a, b]);
      expect(calls, 2);
      expect(errors, hasLength(1));
      expect(runner.isRunning, isFalse);
      await runner.request('r');
      expect(calls, 3);
    });

    test('sequential requests (no overlap) each run', () async {
      var runs = 0;
      final runner = CoalescedRunner<String>((_) async => runs++);
      await runner.request('r');
      await runner.request('r');
      expect(runs, 2);
    });
  });

  group('RoomProvider wiring (structural)', () {
    final provider = _src('lib/features/rooms/presentation/room_provider.dart');
    final code = provider.split('\n').where((l) => !l.trimLeft().startsWith('//')).join('\n');

    test('15/17. no profiles subscription remains in the room', () {
      expect(RegExp(r"table:\s*'profiles'").hasMatch(code), isFalse);
      expect(RegExp(r"\.channel\('room_members_cdc:").allMatches(code), hasLength(1));
    });

    test('member events go through the heartbeat filter, not straight to _refreshMembers', () {
      expect(code, contains('callback: (payload) => _handleMemberCdcEvent(roomId, payload)'));
      expect(code, isNot(contains('callback: (_) => _refreshMembers(roomId)')));
    });

    test('every _refreshMembers call is coalesced; the sequence guard and NotFound streak remain', () {
      expect(code, contains('_membersRefresher.request(roomId)'));
      expect(code, contains('final mySeq = ++_refreshMembersSeq;'));
      expect(code, contains('if (mySeq != _refreshMembersSeq) return;'));
      expect(code, contains('_consecutiveRoomNotFoundCount'));
      expect(code, contains('Future<void> _runRefreshMembers(String roomId) async {\n    if (_disposed) return;'));
    });

    test('9/20. (re)subscribing replaces the channel and forgets stored rows', () {
      final sub = code.substring(code.indexOf('Future<void> _subscribeChannel('));
      final body = sub.substring(0, sub.indexOf('.subscribe();'));
      expect(body.indexOf('_memberCdcChannel?.unsubscribe();'), lessThan(body.indexOf('_memberCdcChannel = _supabase')));
      expect(body, contains('_lastMemberCdcRows.clear();'));
    });

    test('18/19. dispose still cancels every timer and both channels', () {
      final dispose = code.substring(code.indexOf('  void dispose() {'));
      final body = dispose.substring(0, dispose.indexOf('super.dispose();'));
      for (final s in [
        '_readyPollTimer?.cancel();',
        '_gameReconcileTimer?.cancel();',
        '_heartbeatTimer?.cancel();',
        '_memberCdcChannel?.unsubscribe();',
        '_targetedChatCdcChannel?.unsubscribe();',
      ]) {
        expect(body, contains(s));
      }
    });

    test('16. profile display fields are still loaded by every member refresh', () {
      final repo = _src('lib/features/rooms/data/room_repository.dart');
      expect(repo, contains(
        "'*, profiles(id, username, display_name, avatar_url, avatar_config, is_premium, premium_tier, honesty_points, general_score)'",
      ));
    });

    test('8. initial load still fetches the room and subscribes', () {
      final init = code.substring(code.indexOf('Future<void> initialize(String roomId'));
      final body = init.substring(0, init.indexOf('Future<void> _subscribeChannel('));
      expect(body, contains('_repo.getRoomWithDetails('));
      expect(body, contains('await _subscribeChannel(roomId);'));
    });

    test('the heartbeat and owner-staleness timing are unchanged', () {
      expect(code, contains('static const _heartbeatInterval = Duration(seconds: 10);'));
      expect(code, contains('static const _ownerStaleThreshold = Duration(seconds: 20);'));
      expect(code, contains('Timer.periodic(const Duration(seconds: 5), (_) {'));
      expect(code, contains('Timer.periodic(const Duration(seconds: 2), (_) {'));
    });
  });
}
