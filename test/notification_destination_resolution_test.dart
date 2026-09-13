// Item 4 (real-device report) — notifications with no valid destination
// (a closed-room chat notification, a rejected join request, a kick, an
// unrecognized/generic type) must not behave like a navigable
// notification: tapping them must not open an incorrect destination and
// must not loop back into the Notifications Center itself.
//
// hasNavigableDestination (notification_service.dart) is the single,
// testable source of truth NotificationService._routeFromPayload gates
// on before ever entering its type->route switch — this is the pure,
// offline-testable half of the fix; the actual navigation/validation
// (RoomRepository.getInviteInfo-backed _handleRoomDeepLinkTap) needs a
// live GoRouter + Supabase client this suite doesn't have (same
// documented boundary as every other NotificationService test in this
// codebase), so it is NOT claimed as covered here — see this pass's own
// final report for what still needs real-device verification.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/services/notification_service.dart';

void main() {
  group('hasNavigableDestination — item 4', () {
    test('room_join_request_rejected has no destination (the rejection '
        'text already told the whole story)', () {
      expect(hasNavigableDestination('room_join_request_rejected'), isFalse);
    });

    test('room_kicked has no destination', () {
      expect(hasNavigableDestination('room_kicked'), isFalse);
    });

    test('generic/no-target types (achievement, streak_increased, system) '
        'have no destination', () {
      expect(hasNavigableDestination('achievement'), isFalse);
      expect(hasNavigableDestination('streak_increased'), isFalse);
      expect(hasNavigableDestination('system'), isFalse);
    });

    test('null type (malformed/missing payload) has no destination', () {
      expect(hasNavigableDestination(null), isFalse);
    });

    test(
      'an unrecognized/future type not yet wired into the switch fails '
      'closed to "no destination" rather than being treated as navigable',
      () {
        expect(
          hasNavigableDestination('some_future_notification_type'),
          isFalse,
        );
      },
    );

    test('room-targeted types that now go through validated navigation '
        '(room_invite and friends, plus the newly-validated room_started/'
        'game_ended/room_chat_message) are all navigable', () {
      for (final type in [
        'room_invite',
        'room_join_request',
        'room_join_request_accepted',
        'room_started',
        'game_ended',
        'room_chat_message',
      ]) {
        expect(hasNavigableDestination(type), isTrue, reason: type);
      }
    });

    test('every other existing notification type with a real static '
        'destination remains navigable (unaffected by this fix)', () {
      for (final type in [
        'friend_request',
        'friend_accepted',
        'follow',
        'wallet_credit',
        'wallet_debit',
        'pack_sale',
        'pack_expired',
        'physical_pack_status',
        'pack_approved',
        'pack_rejected',
        'pack_review',
        'subscription_started',
        'subscription_expiring_2d',
        'subscription_expiring_1d',
        'subscription_expired',
        'creator_packs_transferred',
        'creator_privileges_removed',
        'creator_recovery_approved',
        'creator_recovery_rejected',
        'moderation',
      ]) {
        expect(hasNavigableDestination(type), isTrue, reason: type);
      }
    });
  });
}
