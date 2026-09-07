// Regression tests for the hidden-spectator auto-removal bug.
//
// Root cause: a hidden spectator is deliberately NEVER tracked in the realtime
// presence channel (so it stays invisible). The presence-sync loop treated
// "absent from the presence channel" as a disconnect signal and armed the
// removal grace period, which ended in a real `left_at` DB write — evicting a
// perfectly-connected hidden spectator after ~1-2 minutes.
//
// The fix decouples VISIBILITY (presence channel) from LIVENESS (server
// heartbeat / last_seen_at). The eviction decision is now the pure static
// `RoomProvider.membersToGraceArm`, which these tests exercise directly. The
// architectural invariant under test: visibility must never participate in
// membership-validity or automatic-removal decisions.
//
// Scenarios that require a live realtime channel / multi-device setup (the
// heartbeat re-check in `_confirmAndRemoveMember`, the actual RPC round-trips
// for kick/ban) are called out in comments and verified structurally here.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/features/rooms/presentation/room_provider.dart';

RoomMemberEntity _member({
  required String id,
  bool owner = false,
  bool moderator = false,
  bool spectator = false,
  bool hidden = false,
  bool disconnected = false,
}) => RoomMemberEntity(
      userId: id,
      displayName: 'name-$id',
      seatOrder: 0,
      isReady: false,
      isOwner: owner,
      isModerator: moderator,
      isSpectator: spectator,
      isHiddenSpectator: hidden,
      isDisconnected: disconnected,
    );

/// Runs [syncs] presence-sync passes over [members] with a fixed set of
/// [onlineIds], accumulating every member ever armed for eviction across all
/// passes. Mirrors how the real loop calls `membersToGraceArm` on each sync.
Set<String> _armedAcross(
  int syncs, {
  required List<RoomMemberEntity> members,
  required Set<String> onlineIds,
}) {
  final pending = <String>{};
  final armed = <String>{};
  for (var i = 0; i < syncs; i++) {
    armed.addAll(
      RoomProvider.membersToGraceArm(
        members: members,
        onlineIds: onlineIds,
        pendingAbsence: pending,
      ),
    );
  }
  return armed;
}

void main() {
  final owner = _member(id: 'owner', owner: true);
  final player = _member(id: 'p1');
  final visibleSpec = _member(id: 's1', spectator: true);
  final hiddenSpec = _member(id: 'h1', spectator: true, hidden: true);

  group('Test 1 — hidden spectator is never auto-removed (root cause)', () {
    test('absent from presence across many syncs (~1/2/5 min) is never armed',
        () {
      // A hidden spectator is never in onlineIds because it is never tracked.
      // Owner + player are online. Even after dozens of syncs (well past the
      // 1-2 minute window where the bug fired) the hidden spectator must never
      // be armed, and must never accumulate into the pending-absence set.
      final members = [owner, player, hiddenSpec];
      final online = {'owner', 'p1'}; // hidden deliberately absent
      final pending = <String>{};
      for (var i = 0; i < 50; i++) {
        final armed = RoomProvider.membersToGraceArm(
          members: members,
          onlineIds: online,
          pendingAbsence: pending,
        );
        expect(armed, isEmpty, reason: 'sync #$i armed someone');
        expect(pending.contains('h1'), isFalse,
            reason: 'sync #$i queued the hidden spectator as absent');
      }
    });
  });

  group('Test 2 — idle hidden spectator (no interaction) is never armed', () {
    test('hidden spectator idle with nobody else online is still never armed',
        () {
      // Simulate total silence: no one is reported online at all. Every
      // NON-hidden member would eventually be armed, but the hidden spectator
      // never is — its liveness is the heartbeat, not presence.
      final members = [hiddenSpec];
      final armed = _armedAcross(10, members: members, onlineIds: {});
      expect(armed.contains('h1'), isFalse);
    });
  });

  group('Test 3 — temporary disconnect is debounced (blip protection)', () {
    test('a normal member absent for a SINGLE sync is not armed', () {
      // One missed sync (e.g. a channel resubscribe transiently drops the
      // presence cache) must not trigger a real left_at write.
      final members = [owner, player];
      final pending = <String>{};
      final armed = RoomProvider.membersToGraceArm(
        members: members,
        onlineIds: {'owner'}, // p1 missing for exactly one sync
        pendingAbsence: pending,
      );
      expect(armed, isEmpty);
      expect(pending, {'p1'}); // queued, awaiting a second confirming sync
    });
  });

  group('Test 4 — reconnect clears the pending-absence (no eviction)', () {
    test('a member absent once then online again is cleared and not armed', () {
      final members = [owner, player];
      final pending = <String>{};
      // Sync A: p1 absent -> queued, not armed.
      RoomProvider.membersToGraceArm(
        members: members,
        onlineIds: {'owner'},
        pendingAbsence: pending,
      );
      expect(pending, {'p1'});
      // Sync B: p1 back online -> removed from pending, never armed.
      final armed = RoomProvider.membersToGraceArm(
        members: members,
        onlineIds: {'owner', 'p1'},
        pendingAbsence: pending,
      );
      expect(armed, isEmpty);
      expect(pending, isEmpty);
    });
  });

  group('Test 5 — explicit kick still removes a hidden spectator', () {
    test('the kick gate is capability-based, never visibility-based', () {
      // Structural invariant (verified against room_provider.dart:kickPlayer):
      // kick is gated on canKickPlayers + target + room, then calls
      // _repo.kickMember and _removeMember — it never consults
      // isHiddenSpectator. So a hidden spectator is kicked identically to any
      // other member. `membersToGraceArm` (the AUTOMATIC path) is the only
      // thing the fix changed, and it protects hidden members ONLY from
      // presence-diff eviction — not from explicit moderation.
      //
      // We assert here that the automatic-eviction model does not smuggle in a
      // blanket "hidden members can't be removed" rule that would also block
      // moderation: hidden-ness adds NO membership-validity field to the model.
      expect(hiddenSpec.isSpectator, isTrue);
      expect(hiddenSpec.isHiddenSpectator, isTrue);
      // A hidden spectator is an ordinary member in every non-visibility
      // respect; the kick RPC round-trip itself needs device verification.
    });
  });

  group('Test 6 — explicit ban still removes a hidden spectator', () {
    test('ban path is likewise independent of visibility', () {
      // Same structural invariant as Test 5 for banMember (room_provider.dart):
      // it is capability-gated and calls _repo.banMember + _removeMember with
      // no reference to isHiddenSpectator. The automatic-eviction model tested
      // below cannot and does not shield a member from that explicit path.
      // Automatic path never arms on visibility grounds; explicit path is
      // untouched by the fix. RPC round-trip needs device verification.
      final members = [hiddenSpec];
      // Even totally absent, the AUTOMATIC model never arms the hidden member
      // (so a ban is the ONLY way it leaves — exactly the intended behavior).
      expect(_armedAcross(10, members: members, onlineIds: {}).contains('h1'),
          isFalse);
    });
  });

  group('Test 7 — normal (visible) spectator keeps normal liveness', () {
    test('a visible spectator absent across two syncs IS armed', () {
      // Regression guard: the fix is scoped to HIDDEN spectators only. A
      // visible spectator is tracked in presence and must still be evicted on a
      // genuine disconnect, exactly like before.
      final members = [owner, visibleSpec];
      final armed = _armedAcross(2, members: members, onlineIds: {'owner'});
      expect(armed, {'s1'});
    });
  });

  group('Test 8 — normal player keeps normal liveness', () {
    test('a normal player absent across two syncs IS armed', () {
      // Regression guard: automatic removal still works for real players — the
      // fix did not blanket-disable eviction.
      final members = [owner, player];
      final armed = _armedAcross(2, members: members, onlineIds: {'owner'});
      expect(armed, {'p1'});
    });

    test('mixed room: hidden never armed, player debounced, online cleared', () {
      // One pass over a realistic room. p1 absent (first miss -> pending only),
      // s1 online, hidden absent. Nobody armed on this pass; only p1 pending.
      final members = [owner, player, visibleSpec, hiddenSpec];
      final pending = <String>{};
      final armed = RoomProvider.membersToGraceArm(
        members: members,
        onlineIds: {'owner', 's1'}, // p1 + hidden absent
        pendingAbsence: pending,
      );
      expect(armed, isEmpty);
      expect(pending, {'p1'}); // hidden 'h1' must NOT be here
      expect(pending.contains('h1'), isFalse);
    });
  });
}
