// import 'package:jma3a/core/config/app_config.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart';

// import '../router/app_router.dart';
// import '../router/route_names.dart';
// import '../utils/app_logger.dart';
// import '../../features/notifications/domain/notification_entity.dart';

// /// Bridges OneSignal ↔ the app.
// ///
// /// Foreground: suppress OS banner → inject InAppToast via NotificationProvider.
// /// Background/killed: OS handles display; tap routes via _routeFromPayload.
// class NotificationService {
//   NotificationService._();
//   static final NotificationService _instance = NotificationService._();
//   static NotificationService get instance => _instance;

//   // Injected by main.dart after provider tree is ready
//   void Function(NotificationType, String, String, Map<String, dynamic>)?
//   _onForeground;

//   Future<void> initialize({required String appId}) async {
//     OneSignal.initialize(appId);
//     await OneSignal.Notifications.requestPermission(true);

//     OneSignal.Notifications.addForegroundWillDisplayListener(_handleForeground);
//     OneSignal.Notifications.addClickListener(_handleTap);

//     AppLogger.info('NotificationService: initialized');
//     print("OS App ID: ${AppConfig.oneSignalAppId}");
//     print("Push ID: ${OneSignal.User.pushSubscription.id}");
//     print("Token: ${OneSignal.User.pushSubscription.token}");
//     print("OptedIn: ${OneSignal.User.pushSubscription.optedIn}");
//   }

//   /// Called after the provider tree is built.
//   /// Passes the toast injection callback from NotificationProvider.
//   void registerForegroundHandler(
//     void Function(NotificationType, String, String, Map<String, dynamic>)
//     handler,
//   ) {
//     _onForeground = handler;
//   }

//   void setExternalUserId(String userId) {
//     OneSignal.login(userId);
//     AppLogger.info('OneSignal: logged in as $userId');
//   }

//   void logout() {
//     OneSignal.logout();
//   }

//   // ── Foreground ─────────────────────────────────────────────────────────────
//   void _handleForeground(OSNotificationWillDisplayEvent event) {
//     // Prevent OS from showing its own banner
//     event.preventDefault();

//     final data = event.notification.additionalData ?? {};
//     final title = event.notification.title ?? '';
//     final body = event.notification.body ?? '';
//     final type = NotificationType.fromString(
//       data['type'] as String? ?? 'system',
//     );

//     AppLogger.debug('Foreground notification: ${type.name}');

//     // Inject into NotificationProvider's toast queue
//     _onForeground?.call(type, title, body, Map<String, dynamic>.from(data));
//   }

//   // ── Tap ────────────────────────────────────────────────────────────────────
//   void _handleTap(OSNotificationClickEvent event) {
//     final data = event.notification.additionalData ?? {};
//     AppLogger.info('Notification tap: $data');
//     _routeFromPayload(Map<String, dynamic>.from(data));
//   }

//   void routeFromPayload(Map<String, dynamic> data) {
//     _routeFromPayload(data);
//   }

//   void _routeFromPayload(Map<String, dynamic> data) {
//     final type = data['type'] as String?;
//     final roomId = data['room_id'] as String?;
//     final router = AppRouter.router;

//     switch (type) {
//       case 'room_invite':
//         if (roomId != null) {
//           router.go('${RouteNames.home}/room/$roomId');
//         } else {
//           router.go(RouteNames.home);
//         }
//       case 'friend_request':
//       case 'friend_accepted':
//         router.go(RouteNames.friends);
//       case 'wallet_credit':
//       case 'wallet_debit':
//         router.go(RouteNames.wallet);
//       case 'pack_sale':
//       case 'pack_approved':
//       case 'pack_rejected':
//         router.go(RouteNames.marketplace);
//       case 'moderation':
//         router.go(RouteNames.home);
//       default:
//         router.go(RouteNames.notifications);
//     }
//   }
// }

import 'package:jma3a/core/config/app_config.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../extensions/context_ext.dart';
import '../router/app_router.dart';
import '../router/route_names.dart';
import '../utils/app_logger.dart';
import '../../features/notifications/domain/notification_entity.dart';
import '../../features/rooms/data/room_repository.dart';
import 'local_notification_service.dart';

/// Bridges OneSignal ↔ the app.
///
/// Foreground: suppress OS banner → show via LocalNotificationService
/// (awesome_notifications) → also feed InAppToast via NotificationProvider.
/// Background/killed: OneSignal handles display entirely natively;
/// tap routes via _routeFromPayload.
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  Future<void> initialize({required String appId}) async {
    OneSignal.initialize(appId);
    await OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addForegroundWillDisplayListener(_handleForeground);
    OneSignal.Notifications.addClickListener(_handleTap);

    // Foreground = LocalNotificationService (awesome_notifications).
    // Background/terminated = OneSignal handles delivery natively, no app
    // code involved at all in that case.
    await LocalNotificationService.instance.initialize();
    LocalNotificationService.instance.onTap = _routeFromPayload;

    AppLogger.info('NotificationService: initialized');
    print("OS App ID: ${AppConfig.oneSignalAppId}");
    print("Push ID: ${OneSignal.User.pushSubscription.id}");
    print("Token: ${OneSignal.User.pushSubscription.token}");
    print("OptedIn: ${OneSignal.User.pushSubscription.optedIn}");
  }

  void setExternalUserId(String userId) {
    OneSignal.login(userId);
    AppLogger.info('OneSignal: logged in as $userId');
  }

  void logout() {
    OneSignal.logout();
  }

  // ── Foreground ─────────────────────────────────────────────────────────────
  void _handleForeground(OSNotificationWillDisplayEvent event) {
    // Prevent OS from showing its own (OneSignal) banner — while the app is
    // open, LocalNotificationService (awesome_notifications) owns display
    // instead. OneSignal is only the delivery transport here; it still
    // handles background/terminated delivery entirely on its own,
    // untouched by anything below.
    event.preventDefault();

    final data = event.notification.additionalData ?? {};
    final title = event.notification.title ?? '';
    final body = event.notification.body ?? '';
    final type = NotificationType.fromString(
      data['type'] as String? ?? 'system',
    );

    AppLogger.debug('Foreground notification: ${type.name}');

    // Show a real local notification (awesome_notifications) — this is
    // what the user actually sees while the app is foregrounded now,
    // instead of relying on OneSignal's suppressed banner.
    //
    // Not also calling _onForeground/pushToast here: every push that
    // reaches this handler was preceded by a `notifications` row insert on
    // the backend (sendNotification/sendBulkNotification always write the
    // DB row before sending the push), and NotificationProvider's own CDC
    // subscription already turns that insert into an in-app toast — with a
    // showsInApp(type) preference check this path doesn't have. Calling
    // both here produced two toasts (plus this Awesome notification) for
    // one event.
    LocalNotificationService.instance.show(
      title: title,
      body: body,
      data: {'type': data['type'] ?? 'system', ...data},
    );
  }

  // ── Tap ────────────────────────────────────────────────────────────────────
  void _handleTap(OSNotificationClickEvent event) {
    final data = event.notification.additionalData ?? {};
    AppLogger.info('Notification tap: $data');
    _routeFromPayload(Map<String, dynamic>.from(data));
  }

  void routeFromPayload(Map<String, dynamic> data) {
    _routeFromPayload(data);
  }

  Future<void> _routeFromPayload(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    final roomId = data['room_id'] as String?;

    // A notification click (especially a cold-start OneSignal replay,
    // which can fire before runApp()/AppRouter.createRouter() has ever
    // run — this was the root cause of taps not navigating on iOS) can
    // arrive before the router exists. Wait for it rather than crashing
    // into AppRouter.router's null-check — this makes navigation
    // deterministic for terminated, background, and foreground taps alike,
    // on both platforms.
    if (!AppRouter.isReady) {
      AppLogger.info(
        'NotificationService: router not ready yet, waiting to route '
        'type=$type roomId=$roomId',
      );
    }
    await AppRouter.ready;
    final router = AppRouter.router;
    AppLogger.info(
      'NotificationService: routing notification type=$type roomId=$roomId',
    );

    switch (type) {
      case 'room_invite':
        await _handleRoomInviteTap(router, roomId);
      case 'friend_request':
      case 'friend_accepted':
        router.go(RouteNames.friends);
      case 'wallet_credit':
      case 'wallet_debit':
        router.go(RouteNames.wallet);
      case 'pack_sale':
      case 'pack_approved':
      case 'pack_rejected':
        router.go(RouteNames.marketplace);
      case 'moderation':
        router.go(RouteNames.home);
      default:
        router.go(RouteNames.notifications);
    }
  }

  /// Single source of truth for a room-invite notification tap — reached
  /// identically from the OneSignal click listener, a foreground local
  /// notification, an in-app toast tap, and a Notification Center row tap
  /// (all four funnel through _routeFromPayload above into this one
  /// method) — also reused directly by PendingInvitesSection's "View"
  /// button (via routeFromPayload), so every room-invite entry point in
  /// the app shares this exact logic.
  ///
  /// No intermediate screen: validates the invite/room first
  /// (RoomRepository.getInviteInfo, the same single validator used
  /// everywhere), then either navigates straight into the room — reusing
  /// the existing room-join pipeline (LobbyScreen/RoomProvider.initialize,
  /// the same one invite links, the room browser, and friend invitations
  /// already use) to restore the correct state — or shows a friendly
  /// snackbar and returns Home. Without a room_id (payload missing it
  /// entirely) it goes straight Home.
  Future<void> _handleRoomInviteTap(GoRouter router, String? roomId) async {
    if (roomId == null) {
      AppLogger.info(
        'NotificationService: room_invite tap had no room_id in payload — '
        'routing Home',
      );
      router.go(RouteNames.home);
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    final info = userId == null
        ? null
        : await RoomRepository.instance.getInviteInfo(
            userId: userId,
            roomId: roomId,
          );

    if (info == null) {
      AppLogger.info(
        'NotificationService: room_invite tap for room $roomId — invite/'
        'room no longer available, routing Home',
      );
      router.go(RouteNames.home);
      AppRouter.rootKey.currentContext?.showErrorSnackBar(
        'This invitation is no longer available.',
      );
      return;
    }

    AppLogger.info(
      'NotificationService: room_invite tap for room $roomId — entering '
      'room directly',
    );
    router.go('${RouteNames.home}/room/$roomId');
  }
}
