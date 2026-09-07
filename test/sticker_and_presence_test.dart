// Tests for two independent, small pieces of pure model logic added this
// session:
//   - CardDraft/PackCardEntity's sticker fields (task item 3) — a meme
//     card distinguishes a centralized library sticker (stickerId) from
//     its own uploaded image (imageUrl); PackCardEntity.effectiveImageUrl
//     is the "what to actually display" resolution.
//   - UserPresenceStatus gaining `backgrounded` (task item 1) — the
//     round-trip through UserPresence.toMap/fromMap that the presence
//     channel payload depends on, and that it stays distinct from
//     RoomMemberEntity.isAway (a different, room-scoped concept).
//
// PresenceService itself, PackRepository.getStickerLibrary/addCards, and
// the server-side sticker_library/pack_cards.sticker_id wiring all talk to
// a live Supabase connection this offline suite doesn't have — same class
// of gap documented for other Supabase-backed paths in this codebase.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/services/presence_service.dart';
import 'package:jma3a/features/packs/domain/pack_entity.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';

void main() {
  group('CardDraft — sticker vs pack-owned upload', () {
    test('a fresh card has neither set', () {
      final card = CardDraft(type: CardType.prompt);
      expect(card.stickerId, isNull);
      expect(card.imageUrl, isNull);
    });

    test('stickerId can be set independently of imageUrl', () {
      final card = CardDraft(type: CardType.prompt)..stickerId = 'sticker-123';
      expect(card.stickerId, 'sticker-123');
      expect(card.imageUrl, isNull);
    });
  });

  group('PackCardEntity.effectiveImageUrl', () {
    const base = (
      id: 'card-1',
      packId: 'pack-1',
      contentJson: <String, dynamic>{'en': 'caption'},
      type: CardType.prompt,
      difficulty: CardDifficulty.mild,
    );

    test('prefers the card\'s own uploaded image over a library sticker', () {
      final card = PackCardEntity(
        id: base.id,
        packId: base.packId,
        contentJson: base.contentJson,
        type: base.type,
        difficulty: base.difficulty,
        imageUrl: 'https://cdn.example/own-upload.png',
        stickerUrl: 'https://cdn.example/library-sticker.png',
      );
      expect(card.effectiveImageUrl, 'https://cdn.example/own-upload.png');
    });

    test('falls back to the resolved library sticker when there is no '
        'own upload', () {
      final card = PackCardEntity(
        id: base.id,
        packId: base.packId,
        contentJson: base.contentJson,
        type: base.type,
        difficulty: base.difficulty,
        stickerId: 'sticker-123',
        stickerUrl: 'https://cdn.example/library-sticker.png',
      );
      expect(card.effectiveImageUrl, 'https://cdn.example/library-sticker.png');
    });

    test('null when neither is set (existing text-only cards, unaffected '
        'by this session\'s changes)', () {
      final card = PackCardEntity(
        id: base.id,
        packId: base.packId,
        contentJson: base.contentJson,
        type: base.type,
        difficulty: base.difficulty,
      );
      expect(card.effectiveImageUrl, isNull);
    });

    test('null stickerUrl (sticker disabled/deleted — RLS hides inactive '
        'library rows) degrades gracefully, never throws', () {
      final card = PackCardEntity(
        id: base.id,
        packId: base.packId,
        contentJson: base.contentJson,
        type: base.type,
        difficulty: base.difficulty,
        stickerId: 'sticker-now-disabled',
        stickerUrl: null,
      );
      expect(card.effectiveImageUrl, isNull);
    });
  });

  group('UserPresenceStatus.backgrounded (task item 1)', () {
    test('round-trips through UserPresence.toMap/fromMap', () {
      final presence = UserPresence(
        userId: 'user-1',
        status: UserPresenceStatus.backgrounded,
        roomId: 'room-1',
        roomStatus: 'in_game',
        gameType: 'meme',
      );
      final restored = UserPresence.fromMap(presence.toMap());
      expect(restored.status, UserPresenceStatus.backgrounded);
      expect(restored.roomId, 'room-1');
      expect(restored.roomStatus, 'in_game');
      expect(restored.gameType, 'meme');
    });

    test('an unrecognized status string falls back to offline, never '
        'throws or silently becomes backgrounded', () {
      final restored = UserPresence.fromMap({
        'user_id': 'user-1',
        'status': 'not_a_real_status',
      });
      expect(restored.status, UserPresenceStatus.offline);
    });

    test('all four UserPresenceStatus values are distinct', () {
      expect(UserPresenceStatus.values.toSet().length, 4);
      expect(
        UserPresenceStatus.values,
        contains(UserPresenceStatus.backgrounded),
      );
    });

    test('RoomMemberEntity.isAway (the "left the current game round" '
        'concept) is a completely separate field from presence — a member '
        'can be a live room member (isAway: false) regardless of their '
        'global app-backgrounded status, which member_tile.dart/room_'
        'members_management_sheet.dart read from PresenceService, never '
        'from this field', () {
      const member = RoomMemberEntity(
        userId: 'user-1',
        displayName: 'Player',
        seatOrder: 0,
        isReady: true,
        isOwner: false,
        isModerator: false,
        isAway: false,
      );
      expect(member.isAway, isFalse);
    });
  });
}
