import 'dart:async';
import 'dart:ui';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/base_provider.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/utils/app_logger.dart';
import '../data/notification_repository.dart';

export '../domain/notification_entity.dart';

const _uuid = Uuid();

/// Item 5 — true when a just-arrived chatMessage notification is for the
/// room the recipient currently has open on its chat tab, and is
/// therefore redundant (they're already seeing the message live in the
/// chat itself). Every other type/room is never redundant. Pure so it's
/// directly testable without a live Supabase CDC channel.
bool isRedundantChatMessageNotification({
  required NotificationType type,
  required String? activeChatRoomId,
  required Map<String, dynamic> data,
}) =>
    type == NotificationType.chatMessage &&
    activeChatRoomId != null &&
    data['room_id'] == activeChatRoomId;

/// Manages in-app notification state + preferences + toast queue.
///
/// CDC (Postgres Changes) on the notifications table delivers new
/// notifications instantly without polling. When a notification arrives
/// while the app is active, it's added to the toast queue for display.
///
/// Toast queue: FIFO, max 3 simultaneous toasts. Auto-dismiss timing and
/// exit animation are owned by InAppToastOverlay, not this provider.
class NotificationProvider extends BaseProvider {
  NotificationProvider({required NotificationRepository notificationRepository})
    : _repo = notificationRepository;

  final NotificationRepository _repo;

  // ── State ──────────────────────────────────────────────────────────────────
  List<NotificationEntity> _notifications = [];
  List<NotificationPreference> _preferences = [];
  List<InAppToast> _toastQueue = [];
  bool _hasMore = true;
  int _page = 0;
  bool _isLoadingMore = false;

  RealtimeChannel? _cdcChannel;

  // Item 5 — the room whose chat tab is CURRENTLY the visible one, if any.
  // Set/cleared by the lobby screen as its chat tab is entered/left (see
  // LobbyScreen's TabController listener). Used only to suppress a
  // redundant in-app chatMessage notification for a room the recipient is
  // already looking at — every other notification type/room is
  // unaffected. This is a client-only signal; the server has no notion of
  // which screen a device is showing, so the notification row is still
  // created (e.g. for a later push if the app backgrounds), just not
  // surfaced as unread/toasted here.
  String? _activeChatRoomId;
  void setActiveChatRoom(String? roomId) => _activeChatRoomId = roomId;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<NotificationEntity> get notifications => _notifications;
  List<NotificationPreference> get preferences => _preferences;
  List<InAppToast> get toastQueue => _toastQueue;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  /// Whether to show in-app toast for a notification type.
  bool showsInApp(NotificationType type) =>
      _preferences
          .cast<NotificationPreference?>()
          .firstWhere((p) => p?.type == type, orElse: () => null)
          ?.inApp ??
      true;

  /// Whether push is enabled for a notification type.
  bool pushEnabled(NotificationType type) =>
      _preferences
          .cast<NotificationPreference?>()
          .firstWhere((p) => p?.type == type, orElse: () => null)
          ?.push ??
      true;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onUserLoggedIn(String userId) {
    runAsync(() async {
      await Future.wait([
        _loadNotifications(userId, reset: true),
        _loadPreferences(userId),
      ]);
      _subscribeCDC(userId);
    });
  }

  @override
  void onUserLoggedOut() {
    _cdcChannel?.unsubscribe();
    _notifications = [];
    _preferences = [];
    _toastQueue = [];
    _page = 0;
    _hasMore = true;
    super.onUserLoggedOut();
  }

  @override
  void dispose() {
    _cdcChannel?.unsubscribe();
    super.dispose();
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> _loadNotifications(String userId, {bool reset = false}) async {
    if (reset) {
      _page = 0;
      _hasMore = true;
      _notifications = [];
    }
    if (!_hasMore) return;

    final batch = await _repo.getNotifications(
      userId,
      limit: 40,
      offset: _page * 40,
    );
    _notifications = reset ? batch : [..._notifications, ...batch];
    _hasMore = batch.length == 40;
    _page++;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || currentUserId == null) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      await _loadNotifications(currentUserId!);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (currentUserId == null) return;
    await _loadNotifications(currentUserId!, reset: true);
  }

  Future<void> _loadPreferences(String userId) async {
    _preferences = await _repo.getPreferences(userId);
    notifyListeners();
  }

  // ── CDC subscription ───────────────────────────────────────────────────────
  /// Subscribes to INSERT events on the notifications table.
  /// New notifications appear instantly without polling.
  void _subscribeCDC(String userId) {
    _cdcChannel?.unsubscribe();

    _cdcChannel = Supabase.instance.client
        .channel('notifs-cdc-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            final type = NotificationType.fromString(
              row['type'] as String? ?? 'system',
            );

            final data = (row['data'] as Map?)?.cast<String, dynamic>() ?? {};

            final isRedundantChatNotif = isRedundantChatMessageNotification(
              type: type,
              activeChatRoomId: _activeChatRoomId,
              data: data,
            );

            final entity = NotificationEntity(
              id: row['id'] as String,
              userId: userId,
              type: type,
              titleJson: parseLocalizedJson(row['title']),
              bodyJson: parseLocalizedJson(row['body']),
              data: data,
              isRead: isRedundantChatNotif,
              createdAt: DateTime.parse(row['created_at'] as String),
              expiresAt: row['expires_at'] != null
                  ? DateTime.tryParse(row['expires_at'] as String)
                  : null,
            );

            // Prepend to list
            _notifications = [entity, ..._notifications];

            // Show in-app toast if user is in the app and preference is on
            if (!isRedundantChatNotif && showsInApp(type)) {
              _enqueueToast(entity);
            }

            notifyListeners();
            AppLogger.debug('NotificationProvider: new ${type.name}');
          },
        )
        .subscribe();
  }

  // ── Toast queue ────────────────────────────────────────────────────────────
  /// Add a toast to the front of the queue (max 3 visible at once).
  ///
  /// Auto-dismiss timing/animation is owned by the banner widget itself
  /// (InAppToastOverlay), not here — this keeps the provider a plain data
  /// queue and lets the widget play a proper exit animation before the
  /// entry is actually removed via [dismissToast].
  void _enqueueToast(NotificationEntity notif) {
    final toast = InAppToast(
      id: _uuid.v4(),
      type: notif.type,
      titleJson: notif.titleJson,
      bodyJson: notif.bodyJson,
      data: notif.data,
      createdAt: DateTime.now(),
      avatarUrl: notif.data['avatar_url'] as String?,
    );

    if (_toastQueue.length >= 3) {
      _toastQueue = [toast, ..._toastQueue.take(2)];
    } else {
      _toastQueue = [toast, ..._toastQueue];
    }
    notifyListeners();

    // Every shown toast gets a real, system-routed notification sound —
    // this is the ONLY thing this local notification is for now (see
    // LocalNotificationService's channel: Default importance, so it plays
    // sound + lands in the shade without popping its own heads-up banner
    // over the toast above). Tied to the same showsInApp(type) gate the
    // toast itself already passed through, so "in-app" and "sound" always
    // agree with each other and with the user's own preference.
    final lang = PlatformDispatcher.instance.locale.languageCode;
    LocalNotificationService.instance.show(
      title: toast.titleFor(lang),
      body: toast.bodyFor(lang),
      data: toast.data,
    );
  }

  void dismissToast(String toastId) {
    _toastQueue = _toastQueue.where((t) => t.id != toastId).toList();
    notifyListeners();
  }

  void clearAllToasts() {
    _toastQueue = [];
    notifyListeners();
  }

  // ── Read / delete ──────────────────────────────────────────────────────────

  Future<void> markRead(String notificationId) async {
    await _repo.markRead(notificationId);
    _notifications = _notifications
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    if (currentUserId == null) return;
    await _repo.markAllRead(currentUserId!);
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _repo.deleteNotification(notificationId);
    _notifications = _notifications
        .where((n) => n.id != notificationId)
        .toList();
    notifyListeners();
  }

  // ── Preferences ───────────────────────────────────────────────────────────

  Future<void> updatePreference({
    required NotificationType type,
    required bool inApp,
    required bool push,
  }) async {
    if (currentUserId == null) return;
    await _repo.updatePreference(
      userId: currentUserId!,
      type: type,
      inApp: inApp,
      push: push,
    );
    _preferences = _preferences
        .map((p) => p.type == type ? p.copyWith(inApp: inApp, push: push) : p)
        .toList();
    notifyListeners();
  }
}
