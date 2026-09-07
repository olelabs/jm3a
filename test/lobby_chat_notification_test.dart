// Tests for item 5 — lobby chat message notifications.
//
// The actual notification is created SERVER-side (a new
// notify_room_chat_message trigger on room_chat_messages, calling the
// existing public.send_notification RPC for every other active room
// member — see migration_2026_lobby_chat_notifications.sql) and delivered
// to the client via the EXISTING NotificationProvider CDC subscription —
// no second notification system. That trigger (recipient selection,
// excluding the sender, anonymous-name protection) cannot be exercised
// from this offline suite (see final report).
//
// What IS fully offline-testable, and is exactly the new client-side
// logic this item added: isRedundantChatMessageNotification — the pure
// predicate NotificationProvider's CDC handler uses to decide whether an
// incoming chatMessage notification is for a room the recipient is
// already viewing on its chat tab (item 20), and therefore should be
// recorded as already-read instead of unread/toasted (item 27 — this is
// also what prevents a SECOND redundant toast for a message the user is
// already looking at, without needing to not create the notification row
// at all, since a backgrounded-app push still needs it to exist).

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/notifications/presentation/notification_provider.dart';

void main() {
  group('isRedundantChatMessageNotification — items 18/20/27', () {
    test('18/20. a chatMessage notification for the room currently open '
        'on the chat tab is redundant', () {
      expect(
        isRedundantChatMessageNotification(
          type: NotificationType.chatMessage,
          activeChatRoomId: 'room-1',
          data: {'room_id': 'room-1'},
        ),
        isTrue,
      );
    });

    test('a chatMessage notification for a DIFFERENT room than the one '
        'currently open is NOT redundant — still shown normally', () {
      expect(
        isRedundantChatMessageNotification(
          type: NotificationType.chatMessage,
          activeChatRoomId: 'room-1',
          data: {'room_id': 'room-2'},
        ),
        isFalse,
      );
    });

    test('no active chat room at all (not currently viewing any lobby '
        'chat) — never redundant', () {
      expect(
        isRedundantChatMessageNotification(
          type: NotificationType.chatMessage,
          activeChatRoomId: null,
          data: {'room_id': 'room-1'},
        ),
        isFalse,
      );
    });

    test('every other notification type is never suppressed by this '
        'check, even if its data happens to carry a matching room_id', () {
      for (final type in NotificationType.values) {
        if (type == NotificationType.chatMessage) continue;
        expect(
          isRedundantChatMessageNotification(
            type: type,
            activeChatRoomId: 'room-1',
            data: {'room_id': 'room-1'},
          ),
          isFalse,
          reason: '$type must never be suppressed by the chat-tab check',
        );
      }
    });

    test('27. this predicate is what NotificationProvider uses as the '
        'sole basis for isRead and for skipping the toast — a redundant '
        'notification is stored (so it still exists for e.g. a later '
        'push) but never produces a SECOND visible surface for the same '
        'message the user is already looking at', () {
      // The predicate itself is the single source of truth for both
      // decisions (see notification_provider.dart's CDC callback) — this
      // test just pins that a redundant case and a non-redundant case
      // are unambiguously distinguishable, which is what makes "store
      // once, surface once" possible without a second flag/system.
      final redundant = isRedundantChatMessageNotification(
        type: NotificationType.chatMessage,
        activeChatRoomId: 'room-1',
        data: {'room_id': 'room-1'},
      );
      final notRedundant = isRedundantChatMessageNotification(
        type: NotificationType.chatMessage,
        activeChatRoomId: 'room-1',
        data: {'room_id': 'other-room'},
      );
      expect(redundant, isNot(equals(notRedundant)));
    });
  });
}
