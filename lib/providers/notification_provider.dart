import 'dart:async';

import 'package:flutter/material.dart';

import '../exceptions/app_exception.dart';
import '../helpers/notification_schedule_helper.dart';
import '../models/notification.dart';
import '../repositories/notification_repository.dart';
import '../utils/app_logger.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required NotificationRepository repository})
      : _repository = repository;

  final NotificationRepository _repository;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  // Session-scoped web reminders (never persisted to Firestore).
  final List<AppNotification> _pendingWebReminders = [];

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _beginLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _endLoading([String? error]) {
    _isLoading = false;
    _error = error;
    notifyListeners();
  }

  StreamSubscription<List<AppNotification>>? _subscription;

  Future<void> loadNotifications(String userId, {String? businessId}) async {
    await stopRealtimeNotifications();
    _beginLoading();
    try {
      _notifications = await _repository.getNotificationsForUser(userId,
          businessId: businessId);
      // Web fallback: OS scheduling is unavailable, so reminders queued by
      // [NotificationScheduleHelper] surface here as in-app items. They are
      // never written to Firestore and persist for the session so a refresh
      // does not drop them before they fire.
      for (final reminder in NotificationScheduleHelper.drainWebReminders()) {
        // Replace (not skip) any pending reminder for the same appointment:
        // a reschedule queues a newer fire time for the same id.
        _pendingWebReminders
            .removeWhere((n) => n.appointmentId == reminder.appointmentId);
        _pendingWebReminders.add(AppNotification(
          type: NotificationType.upcomingReminder,
          title: reminder.title,
          message: reminder.body,
          appointmentId: reminder.appointmentId,
          receiverId: userId,
          senderId: 'system',
          createdAt: reminder.scheduledTime,
        ));
      }
      _notifications = [..._notifications, ..._pendingWebReminders];
      _unreadCount = _notifications
          .where((n) => n.status == NotificationStatus.unread)
          .length;
      _endLoading();
    } on AppException catch (e) {
      AppLogger.error('NotificationProvider.loadNotifications error: $e');
      _endLoading(e.message);
    } catch (e) {
      AppLogger.error('NotificationProvider.loadNotifications error: $e');
      _endLoading('Unexpected error loading notifications');
    }
  }

  void startRealtimeNotifications(String userId, {String? businessId}) {
    stopRealtimeNotifications();
    _subscription =
        _repository.watchNotifications(userId, businessId: businessId).listen(
      (notifications) {
        final sortedNotifications = List<AppNotification>.from(notifications);
        sortedNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _notifications = sortedNotifications;
        _unreadCount = sortedNotifications
            .where((n) => n.status == NotificationStatus.unread)
            .length;
        notifyListeners();
      },
      onError: (e) {
        AppLogger.error(
            'NotificationProvider.startRealtimeNotifications error: $e');
      },
    );
  }

  Future<void> stopRealtimeNotifications() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] =
            _notifications[index].copyWith(status: NotificationStatus.read);
        _unreadCount = _notifications
            .where((n) => n.status == NotificationStatus.unread)
            .length;
        notifyListeners();
      }
    } on AppException catch (e) {
      AppLogger.error('NotificationProvider.markAsRead error: $e');
      _error = e.message;
      notifyListeners();
    } catch (e) {
      AppLogger.error('NotificationProvider.markAsRead error: $e');
      _error = 'Unexpected error updating notification';
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String userId, {String? businessId}) async {
    try {
      await _repository.markAllAsRead(userId, businessId: businessId);
      _notifications = [
        for (final n in _notifications)
          n.copyWith(status: NotificationStatus.read),
      ];
      // Web reminders live in a session buffer outside _notifications:
      // mark the originals too or the next load resurrects them as unread.
      for (var i = 0; i < _pendingWebReminders.length; i++) {
        _pendingWebReminders[i] =
            _pendingWebReminders[i].copyWith(status: NotificationStatus.read);
      }
      _unreadCount = 0;
      notifyListeners();
    } on AppException catch (e) {
      AppLogger.error('NotificationProvider.markAllAsRead error: $e');
      _error = e.message;
      notifyListeners();
    } catch (e) {
      AppLogger.error('NotificationProvider.markAllAsRead error: $e');
      _error = 'Unexpected error updating notifications';
      notifyListeners();
    }
  }
}
