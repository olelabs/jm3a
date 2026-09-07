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
import '../../features/friends/presentation/screens/friends_screen.dart';
import '../../features/notifications/domain/notification_entity.dart';
import '../../features/rooms/data/room_repository.dart';
import '../../features/rooms/presentation/widgets/active_room_conflict_dialog.dart';
import 'local_notification_service.dart';

/// Bridges OneSignal ↔ the app.
///
/// Foreground: suppress OS banner → NotificationProvider's own Postgres CDC
/// subscription (on the `notifications` table insert that always precedes
/// the push) feeds the modern in-app toast (InAppToastOverlay), which also
/// triggers a real notification sound via LocalNotificationService.
/// Background/killed: OneSignal handles display (incl. sound) entirely
/// natively; tap routes via _routeFromPayload.
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  Future<void> initialize({required String appId}) async {
    OneSignal.initialize(appId);
    await OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addForegroundWillDisplayListener(_handleForeground);
    OneSignal.Notifications.addClickListener(_handleTap);

    // LocalNotificationService (awesome_notifications) sets up Android/iOS
    // permissions + a Default-importance channel. Its .show() is called
    // from NotificationProvider._enqueueToast (not from _handleForeground
    // below) — it exists purely to give the in-app toast a real,
    // system-routed notification sound, not to show its own banner.
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
    // Prevent OS from showing its own (OneSignal) banner while the app is
    // open — the modern in-app toast (InAppToastOverlay, mounted once at
    // the app root above the Navigator) owns foreground display instead.
    // OneSignal remains the delivery transport only; it still handles
    // background/terminated delivery entirely natively, untouched by
    // anything here.
    event.preventDefault();

    final data = event.notification.additionalData ?? {};
    final type = NotificationType.fromString(
      data['type'] as String? ?? 'system',
    );

    AppLogger.debug('Foreground notification: ${type.name}');

    // Not injecting a toast (or its accompanying notification sound) here:
    // every push that reaches this handler was preceded by a
    // `notifications` row insert on the backend (sendNotification/
    // sendBulkNotification always write the DB row before sending the
    // push), and NotificationProvider's own CDC subscription already turns
    // that insert into an in-app toast (with a real notification sound via
    // LocalNotificationService, see _enqueueToast) — with a showsInApp(type)
    // preference check this path doesn't have. Doing it here too would
    // show/sound it twice for the same event.
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
    final senderId = data['sender_id'] as String?;
    final packId = data['pack_id'] as String?;

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
      case 'room_join_request':
      case 'room_join_request_accepted':
        await _handleRoomInviteTap(router, roomId);
      case 'room_started':
      case 'game_ended':
        // Unlike room_invite, the recipient is already a member of this
        // room (they were playing) — no need for the
        // already-own-a-room conflict check _handleRoomInviteTap does
        // for a genuinely new room.
        if (roomId != null) {
          _pushDetail(router, '${RouteNames.home}/room/$roomId');
        } else {
          _pushDetail(router, RouteNames.notifications);
        }
      case 'friend_request':
        // Pending incoming requests are content at the TOP of the Friends
        // tab itself now (no separate Requests tab) — see FriendsScreen's
        // 3-tab layout. Friends is a primary bottom-nav destination (like
        // Home), so .go() — not a drill-down needing a way back — is
        // correct here, unlike the cases below.
        FriendsScreen.selectTab(FriendsScreen.tabFriends);
        router.go(RouteNames.friends);
      case 'friend_accepted':
        // Friends tab — the person who accepted is now a friend, visible
        // in the main list.
        FriendsScreen.selectTab(FriendsScreen.tabFriends);
        router.go(RouteNames.friends);
      case 'follow':
        // A follow isn't part of the friend request/accept flow — goes
        // straight to the person who followed you.
        if (senderId != null) {
          _pushDetail(router, '/user/$senderId');
        } else {
          router.go(RouteNames.friends);
        }
      case 'wallet_credit':
      case 'wallet_debit':
        _pushDetail(router, RouteNames.wallet);
      case 'pack_sale':
      case 'pack_expired':
      case 'physical_pack_status':
        // Pack the recipient bought (or, for pack_sale, sold) — the
        // specific pack's detail page, not the generic marketplace list.
        if (packId != null) {
          _pushDetail(router, '/marketplace/pack/$packId');
        } else {
          router.go(RouteNames.marketplace);
        }
      case 'pack_approved':
      case 'pack_rejected':
      case 'pack_review':
        // About the recipient's OWN pack as its creator — the creator
        // dashboard, where moderation/review outcomes actually live.
        _pushDetail(router, '/creator');
      case 'subscription_started':
      case 'subscription_expiring_2d':
      case 'subscription_expiring_1d':
      case 'subscription_expired':
        _pushDetail(router, RouteNames.premium);
      case 'creator_packs_transferred':
      case 'creator_privileges_removed':
        // About the recipient's own creator status/packs — same
        // destination as pack_approved/pack_rejected/pack_review above.
        _pushDetail(router, '/creator');
      case 'creator_recovery_approved':
      case 'creator_recovery_rejected':
        // The complaint's own outcome/detail lives on the recovery screen
        // itself, not the creator dashboard — approved: shows the restored
        // state; rejected: shows the admin's note and lets them resubmit.
        _pushDetail(router, RouteNames.creatorRecoveryComplaint);
      case 'moderation':
        // Home is a primary bottom-nav root, not a drill-down — same
        // reasoning as the Friends-tab cases above.
        router.go(RouteNames.home);
      case 'room_join_request_rejected':
      case 'room_kicked':
        _pushDetail(router, RouteNames.notifications);
      default:
        _pushDetail(router, RouteNames.notifications);
    }
  }

  /// Every one of these destinations (room, user profile, wallet, pack
  /// detail, creator dashboard, premium, notifications) is a "drill-down"
  /// screen — reached everywhere ELSE in this app via push (see
  /// RouteNames.wallet/.premium/.notifications and pack-detail/room-entry
  /// call sites throughout the UI), never via go(), specifically because
  /// go() replaces the router's entire location/history instead of
  /// stacking on top of it. Using go() here (the previous behavior) is
  /// exactly what left a notification-opened screen with no AppBar back
  /// button and no history for the system back gesture to pop — it
  /// wasn't merely visually missing a back arrow, there was genuinely
  /// nothing behind it to go back to. push() targets the same root
  /// Navigator every one of these GoRoutes is already registered under
  /// (parentNavigatorKey: AppRouter.rootKey), so it stacks correctly
  /// above whatever the user was already looking at — Home, another tab,
  /// or nothing yet (cold start), in which case go_router's own
  /// `redirect` callback (already re-evaluated on every navigation,
  /// push included) still applies the same logged-in/logged-out guard it
  /// always has.
  void _pushDetail(GoRouter router, String location) {
    final currentLocation = router.routerDelegate.currentConfiguration.uri
        .toString();
    if (currentLocation == location) {
      // Already there (e.g. a second tap on the same notification) —
      // pushing an identical duplicate screen on top would just be a
      // wasted extra back-press for no visible change.
      return;
    }
    router.push(location);
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
  ///
  /// Before any of that: runs the exact same "do you already own/belong to
  /// an open room" guard that room CREATION uses
  /// (RoomRepository.getActiveMembership + resolveActiveRoomConflict —
  /// see RoomBrowserScreen._doCreateRoom, the original source of this
  /// check). Previously this method skipped straight to the join pipeline,
  /// silently dropping a user into a second room while their first stayed
  /// open server-side.
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

    if (userId != null) {
      final active = await RoomRepository.instance.getActiveMembership(
        userId,
      );
      if (active != null && active['room_id'] != roomId) {
        final conflictContext = AppRouter.rootKey.currentContext;
        if (conflictContext != null) {
          final result = await resolveActiveRoomConflict(
            conflictContext,
            active,
          );
          if (result != ActiveRoomConflictResult.closedAndProceed) {
            // Either sent back to their existing room, or cancelled —
            // either way, don't also navigate into the invited room.
            return;
          }
        }
      }
    }

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
    _pushDetail(router, '${RouteNames.home}/room/$roomId');
  }
}
