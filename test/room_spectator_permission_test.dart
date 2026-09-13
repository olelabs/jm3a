// Regression coverage for item 5 — the admin spectator toggle's
// permission gating and the isSpectator flip it performs. RoomProvider
// itself pulls in too many live dependencies (realtime, repositories) to
// construct directly in a widget-less test, so this targets the pure
// domain logic RoomProvider.setMemberSpectator/canSetSpectator/
// _handleModeration('set_spectator'/'unset_spectator') actually delegate
// to: RoomMemberEntity.hasPermission and .copyWith(isSpectator: ...).

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';

RoomMemberEntity _member({
  bool isOwner = false,
  bool isModerator = false,
  bool isSpectator = false,
  Set<String> moderatorPermissions = const {},
}) => RoomMemberEntity(
  userId: 'u1',
  displayName: 'Test User',
  seatOrder: 0,
  isReady: false,
  isOwner: isOwner,
  isModerator: isModerator,
  isSpectator: isSpectator,
  moderatorPermissions: moderatorPermissions,
);

void main() {
  group('ModeratorPermission.setSpectator (Item 5)', () {
    test('is a distinct key from every existing permission', () {
      expect(ModeratorPermission.setSpectator, 'set_spectator');
      expect(ModeratorPermission.all.toSet().length, ModeratorPermission.all.length);
    });

    test('is included in the grantable permission set', () {
      expect(ModeratorPermission.all, contains(ModeratorPermission.setSpectator));
    });

    test('start_game/end_game remain excluded (owner-only, unrelated to this item)', () {
      expect(ModeratorPermission.all, isNot(contains(ModeratorPermission.startGame)));
      expect(ModeratorPermission.all, isNot(contains(ModeratorPermission.endGame)));
    });
  });

  group('RoomMemberEntity.hasPermission — set_spectator gating', () {
    test('the room owner always passes, regardless of granted permissions', () {
      final owner = _member(isOwner: true);
      expect(owner.hasPermission(ModeratorPermission.setSpectator), isTrue);
    });

    test('a moderator explicitly granted the permission passes', () {
      final mod = _member(
        isModerator: true,
        moderatorPermissions: {ModeratorPermission.setSpectator},
      );
      expect(mod.hasPermission(ModeratorPermission.setSpectator), isTrue);
    });

    test('a moderator WITHOUT this specific permission is denied', () {
      final mod = _member(
        isModerator: true,
        moderatorPermissions: {ModeratorPermission.mutePlayers},
      );
      expect(mod.hasPermission(ModeratorPermission.setSpectator), isFalse);
    });

    test('a plain member (not owner, not moderator) is denied', () {
      final plain = _member();
      expect(plain.hasPermission(ModeratorPermission.setSpectator), isFalse);
    });
  });

  group('RoomMemberEntity.copyWith(isSpectator:) — the actual state flip', () {
    test('setting a player as a spectator flips isSpectator true', () {
      final player = _member();
      final asSpectator = player.copyWith(isSpectator: true);
      expect(asSpectator.isSpectator, isTrue);
      // Identity and every other field are untouched by the toggle.
      expect(asSpectator.userId, player.userId);
      expect(asSpectator.isOwner, player.isOwner);
    });

    test('reversing (remove spectator) flips it back to an active player', () {
      final spectator = _member(isSpectator: true);
      final asPlayer = spectator.copyWith(isSpectator: false);
      expect(asPlayer.isSpectator, isFalse);
    });

    test('a moderator temporarily made a spectator keeps their permissions '
        '(role tracking is independent of the moderator grant)', () {
      final mod = _member(
        isModerator: true,
        moderatorPermissions: {ModeratorPermission.kickPlayers},
      );
      final asSpectator = mod.copyWith(isSpectator: true);
      expect(asSpectator.isModerator, isTrue);
      expect(asSpectator.hasPermission(ModeratorPermission.kickPlayers), isTrue);
      final restored = asSpectator.copyWith(isSpectator: false);
      expect(restored.hasPermission(ModeratorPermission.kickPlayers), isTrue);
    });
  });
}
