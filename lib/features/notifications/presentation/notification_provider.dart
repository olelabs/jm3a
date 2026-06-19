import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/base_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../data/notification_repository.dart';
import '../domain/notification_entity.dart';

export '../domain/notification_entity.dart';

const _uuid = Uuid();

/// Manages in-app notification state + preferences + toast queue.
///
/// CDC (Postgres Changes) on the notifications table delivers new
/// notifications instantly without polling. When a notification arrives
/// while the app is active, it's added to the toast queue for display.
///
/// Toast queue: FIFO, max 3 simultaneous toasts. Each auto-dismisses
/// after 4 seconds unless tapped.
class NotificationProvider extends BaseProvider {
  NotificationProvider({required NotificationRepository notificationRepository})
      : _repo = notificationRepository;

  final NotificationRepository _repo;

  // ── State ──────────────────────────────────────────────────────────────────
  List<NotificationEntity>    _notifications = [];
  List<NotificationPreference> _preferences  = [];
  List<InAppToast>            _toastQueue    = [];
  bool                        _hasMore       = true;
  int                         _page          = 0;
  bool                        _isLoadingMore = false;

  RealtimeChannel? _cdcChannel;
  Timer?           _toastTimer;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<NotificationEntity>    get notifications => _notifications;
  List<NotificationPreference> get preferences  => _preferences;
  List<InAppToast>            get toastQueue    => _toastQueue;
  int                         get unreadCount   =>
      _notifications.where((n) => !n.isRead).length;
  bool                        get hasMore       => _hasMore;
  bool                        get isLoadingMore => _isLoadingMore;

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
    _toastTimer?.cancel();
    _notifications = [];
    _preferences   = [];
    _toastQueue    = [];
    _page          = 0;
    _hasMore       = true;
    super.onUserLoggedOut();
  }

  @override
  void dispose() {
    _cdcChannel?.unsubscribe();
    _toastTimer?.cancel();
    super.dispose();
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> _loadNotifications(String userId, {bool reset = false}) async {
    if (reset) { _page = 0; _hasMore = true; _notifications = []; }
    if (!_hasMore) return;

    final batch = await _repo.getNotifications(userId,
        limit: 40, offset: _page * 40);
    _notifications = reset ? batch : [..._notifications, ...batch];
    _hasMore = batch.length == 40;
    _page++;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || currentUserId == null) return;
    _isLoadingMore = true;
    notifyListeners();
    try { await _loadNotifications(currentUserId!); }
    finally { _isLoadingMore = false; notifyListeners(); }
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
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'notifications',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'user_id',
            value:  userId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            final type = NotificationType.fromString(
                row['type'] as String? ?? 'system');

            final entity = NotificationEntity(
              id:        row['id']      as String,
              userId:    userId,
              type:      type,
              titleJson: (row['title'] as Map?)?.cast<String, dynamic>() ?? {},
              bodyJson:  (row['body']  as Map?)?.cast<String, dynamic>() ?? {},
              data:      (row['data']  as Map?)?.cast<String, dynamic>() ?? {},
              isRead:    false,
              createdAt: DateTime.parse(row['created_at'] as String),
              expiresAt: row['expires_at'] != null
                  ? DateTime.tryParse(row['expires_at'] as String) : null,
            );

            // Prepend to list
            _notifications = [entity, ..._notifications];

            // Show in-app toast if user is in the app and preference is on
            if (showsInApp(type)) {
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
  void _enqueueToast(NotificationEntity notif) {
    final toast = InAppToast(
      id:        _uuid.v4(),
      type:      notif.type,
      title:     notif.titleFor('en'),
      body:      notif.bodyFor('en'),
      data:      notif.data,
      createdAt: DateTime.now(),
    );

    if (_toastQueue.length >= 3) {
      _toastQueue = [toast, ..._toastQueue.take(2)];
    } else {
      _toastQueue = [toast, ..._toastQueue];
    }
    notifyListeners();

    // Schedule auto-dismiss after 4 seconds
    Timer(const Duration(seconds: 4), () => dismissToast(toast.id));
  }

  /// Inject a toast externally (from NotificationService foreground handler).
  void pushToast({
    required NotificationType type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    _enqueueToast(NotificationEntity(
      id:        _uuid.v4(),
      userId:    currentUserId ?? '',
      type:      type,
      titleJson: {'en': title},
      bodyJson:  {'en': body},
      data:      data,
      isRead:    false,
      createdAt: DateTime.now(),
    ));
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
      userId: currentUserId!, type: type, inApp: inApp, push: push);
    _preferences = _preferences
        .map((p) => p.type == type ? p.copyWith(inApp: inApp, push: push) : p)
        .toList();
    notifyListeners();
  }
}
