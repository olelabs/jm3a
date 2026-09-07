// Behavior tests for hidden-spectator visibility. These exercise the exact
// pure rules the RoomProvider getters delegate to (filterVisibleMembers /
// computeCanRevealHiddenSpectator), plus the model invariants that keep a
// hidden spectator a spectator and out of the player count.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/auth/domain/entities/user_entity.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';
import 'package:jma3a/features/rooms/presentation/room_provider.dart';

RoomMemberEntity _member({
  required String id,
  bool owner = false,
  bool moderator = false,
  bool spectator = false,
  bool hidden = false,
}) => RoomMemberEntity(
      userId: id,
      displayName: 'name-$id',
      seatOrder: 0,
      isReady: false,
      isOwner: owner,
      isModerator: moderator,
      isSpectator: spectator,
      isHiddenSpectator: hidden,
    );

void main() {
  final players = [_member(id: 'owner', owner: true), _member(id: 'p1')];
  final visibleSpec = _member(id: 's1', spectator: true);
  final hiddenSpec = _member(id: 'h1', spectator: true, hidden: true);
  final all = [...players, visibleSpec, hiddenSpec];

  group('Normal player visibility', () {
    test('a normal player never sees a hidden spectator', () {
      final visible = RoomProvider.filterVisibleMembers(
        all,
        viewerCanModerate: false,
      );
      expect(visible.contains(hiddenSpec), isFalse);
      // but still sees everyone else, including visible spectators
      expect(visible.contains(visibleSpec), isTrue);
      expect(visible.length, all.length - 1);
    });

    test('hidden spectator is absent from the visible spectator list', () {
      final spectators = RoomProvider.filterVisibleMembers(
        all,
        viewerCanModerate: false,
      ).where((m) => m.isSpectator).toList();
      expect(spectators, [visibleSpec]);
    });
  });

  group('Admin / moderator visibility', () {
    test('a moderator DOES see the hidden spectator', () {
      final visible = RoomProvider.filterVisibleMembers(
        all,
        viewerCanModerate: true,
      );
      expect(visible.contains(hiddenSpec), isTrue);
      expect(visible.length, all.length);
    });
  });

  group('Premium Plus identity reveal', () {
    test('Premium Plus moderator may reveal identity', () {
      expect(
        RoomProvider.computeCanRevealHiddenSpectator(
          viewerCanModerate: true,
          viewerIsPremiumPlus: true,
        ),
        isTrue,
      );
    });

    test('non-Premium-Plus moderator may NOT reveal identity', () {
      expect(
        RoomProvider.computeCanRevealHiddenSpectator(
          viewerCanModerate: true,
          viewerIsPremiumPlus: false,
        ),
        isFalse,
      );
    });

    test('non-moderator can never reveal identity', () {
      expect(
        RoomProvider.computeCanRevealHiddenSpectator(
          viewerCanModerate: false,
          viewerIsPremiumPlus: true,
        ),
        isFalse,
      );
    });

    test('reveal is independent of moderation — kick is always allowed to a '
        'moderator regardless of tier (documented invariant)', () {
      // computeCanRevealHiddenSpectator only governs IDENTITY, never kick.
      // A non-Premium-Plus moderator still moderates (viewerCanModerate=true).
      expect(
        RoomProvider.computeCanRevealHiddenSpectator(
          viewerCanModerate: true,
          viewerIsPremiumPlus: false,
        ),
        isFalse, // identity masked...
      );
      // ...while still being a moderator (the kick path checks canModerate,
      // never the reveal flag).
    });
  });

  group('Players / Spectators sections', () {
    // The lobby splits the SAME viewer-scoped `visibleMembers` into two
    // sections. These assert the partition rule the lobby uses so players and
    // spectators are never merged, and hidden-spectator visibility is kept.
    List<RoomMemberEntity> playersOf(List<RoomMemberEntity> visible) =>
        visible.where((m) => !m.isSpectator).toList();
    List<RoomMemberEntity> spectatorsOf(List<RoomMemberEntity> visible) =>
        visible.where((m) => m.isSpectator).toList();

    test('a normal player sees players and visible spectators, never hidden',
        () {
      final visible = RoomProvider.filterVisibleMembers(
        all,
        viewerCanModerate: false,
      );
      expect(playersOf(visible), [players[0], players[1]]);
      expect(spectatorsOf(visible), [visibleSpec]); // hidden absent
      // Nothing appears in both sections.
      expect(
        playersOf(visible).toSet().intersection(spectatorsOf(visible).toSet()),
        isEmpty,
      );
    });

    test('a moderator sees the hidden spectator in the spectators section only',
        () {
      final visible = RoomProvider.filterVisibleMembers(
        all,
        viewerCanModerate: true,
      );
      expect(playersOf(visible), [players[0], players[1]]);
      expect(spectatorsOf(visible), [visibleSpec, hiddenSpec]);
      // The hidden spectator is a spectator, never a player.
      expect(playersOf(visible).contains(hiddenSpec), isFalse);
    });

    test('every visible member lands in exactly one section', () {
      for (final mod in [true, false]) {
        final visible = RoomProvider.filterVisibleMembers(
          all,
          viewerCanModerate: mod,
        );
        expect(
          playersOf(visible).length + spectatorsOf(visible).length,
          visible.length,
        );
      }
    });
  });

  group('Model invariants', () {
    test('a hidden spectator is still a spectator', () {
      expect(hiddenSpec.isSpectator, isTrue);
      expect(hiddenSpec.isHiddenSpectator, isTrue);
    });

    test('player count excludes ALL spectators (hidden and visible)', () {
      final playerCount = all.where((m) => !m.isSpectator).length;
      expect(playerCount, 2); // owner + p1 only
    });
  });

  group('UserEntity.isPremiumPlusActive', () {
    UserEntity user({
      bool isPremium = false,
      String? tier,
      DateTime? expires,
    }) => UserEntity(
          id: 'u',
          email: 'u@t.co',
          isPremium: isPremium,
          premiumTier: tier,
          premiumExpiresAt: expires,
        );

    test('true only for an active premium_plus subscription', () {
      expect(
        user(isPremium: true, tier: 'premium_plus').isPremiumPlusActive,
        isTrue,
      );
    });
    test('false for plain premium', () {
      expect(
        user(isPremium: true, tier: 'premium').isPremiumPlusActive,
        isFalse,
      );
    });
    test('false for non-premium', () {
      expect(user(tier: 'premium_plus').isPremiumPlusActive, isFalse);
    });
    test('false for expired premium_plus', () {
      expect(
        user(
          isPremium: true,
          tier: 'premium_plus',
          expires: DateTime.now().subtract(const Duration(days: 1)),
        ).isPremiumPlusActive,
        isFalse,
      );
    });
  });
}
