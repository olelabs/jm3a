// Tests for the real-device bug: replying to a lobby chat message always
// failed ("Failed, try sending a message again"), while a normal message
// always succeeded.
//
// Root cause (see RoomRepository.persistChatMessage's doc comment): the
// client generates its own message id up front (msgId = _uuid.v4()) and
// uses it for BOTH the optimistic local entry AND the realtime broadcast
// payload — every OTHER client's ChatMessageEntity for that message (see
// RoomProvider._handleChatBroadcast) is keyed on that exact id. But the
// INSERT into room_chat_messages never included 'id' at all, so Postgres'
// own DEFAULT gen_random_uuid() assigned a DIFFERENT id to the actual
// persisted row. Swiping to reply to ANY live-received message therefore
// sent reply_to_id = an id that did not exist as any room_chat_messages
// .id, violating room_chat_messages_reply_to_id_fkey (a 23503
// foreign-key-violation) on every attempt. A normal (non-reply) message
// never touches reply_to_id at all, so it was never affected — matching
// exactly the reported "normal message works, reply always fails".
//
// Fixed by explicitly writing 'id': id in the insert (see
// RoomRepository.persistChatMessage / RoomProvider.sendChatMessage),
// making client id == broadcast id == database id unconditionally, for
// every message. A DB-side trigger (see
// migration_2026_room_chat_reply_room_scope_guard.sql) additionally
// rejects a reply_to_id belonging to a message in a DIFFERENT room —
// the original single-column foreign key only checked existence
// anywhere in the table, not same-room membership.
//
// persistChatMessage's actual Supabase insert, and the new
// enforce_room_chat_reply_same_room trigger, both need a live
// Supabase/Postgres connection this offline suite doesn't have — see
// final report for what still needs staging/real-device verification
// (this mirrors lobby_chat_notification_test.dart's identical
// server-trigger boundary). What IS fully offline-testable is the
// ChatMessageEntity invariants the fix depends on: a reply's
// replyToId/replyToContent/replyToDisplayName are preserved intact
// through every local transformation the client applies to a message
// (the "confirmed" transition after a successful send, being an
// anonymous message at the same time), so nothing in the client's own
// data layer can silently drop or corrupt the reply reference the fix
// now correctly threads through.

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/rooms/domain/room_entity.dart';

ChatMessageEntity _reply({bool anonymous = false}) => ChatMessageEntity(
  id: 'reply-id',
  roomId: 'room-1',
  userId: 'u2',
  displayName: anonymous ? 'Anonymous' : 'Bob',
  content: 'nice one',
  createdAt: DateTime(2026, 1, 1),
  isOptimistic: true,
  isAnonymous: anonymous,
  replyToId: 'original-id',
  replyToContent: 'the original message',
  replyToDisplayName: 'Alice',
);

void main() {
  group('9/11 — reply reference survives local transformations', () {
    test('a constructed reply carries all three reply fields, and isReply '
        'reflects that', () {
      final msg = _reply();
      expect(msg.isReply, isTrue);
      expect(msg.replyToId, 'original-id');
      expect(msg.replyToContent, 'the original message');
      expect(msg.replyToDisplayName, 'Alice');
    });

    test('copyWithConfirmed (the optimistic → persisted-confirmed '
        'transition every send goes through) preserves the reply '
        'reference exactly — this is the exact transition '
        'RoomProvider.sendChatMessage applies right after persistence '
        'succeeds', () {
      final optimistic = _reply();
      final confirmed = optimistic.copyWithConfirmed();
      expect(confirmed.isOptimistic, isFalse);
      expect(confirmed.replyToId, optimistic.replyToId);
      expect(confirmed.replyToContent, optimistic.replyToContent);
      expect(confirmed.replyToDisplayName, optimistic.replyToDisplayName);
      expect(confirmed.isReply, isTrue);
    });

    test('a non-reply message has no reply fields at all, and isReply is '
        'false — replying is purely additive, never assumed', () {
      final msg = ChatMessageEntity(
        id: 'm1',
        roomId: 'room-1',
        userId: 'u1',
        displayName: 'Alice',
        content: 'hey',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(msg.isReply, isFalse);
      expect(msg.replyToId, isNull);
      expect(msg.replyToContent, isNull);
      expect(msg.replyToDisplayName, isNull);
    });
  });

  group('13 — anonymous reply', () {
    test('a message can be a reply AND anonymous at the same time — '
        'reply routing and identity-hiding are independent, neither '
        'field conditions the other', () {
      final msg = _reply(anonymous: true);
      expect(msg.isAnonymous, isTrue);
      expect(msg.isReply, isTrue);
      expect(msg.replyToId, 'original-id');
      // The reply snippet/display name are a SNAPSHOT of the ORIGINAL
      // message's own identity — an anonymous REPLY must not anonymize
      // what it's quoting.
      expect(msg.replyToDisplayName, 'Alice');
    });
  });
}
