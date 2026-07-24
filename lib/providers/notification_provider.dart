import 'package:flutter/material.dart';

import '../models/notification.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository.instance;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> loadNotifications(String userId) async {
    try {
      _notifications = await _repository.getNotificationsForUser(userId);
      _unreadCount = _notifications.where((n) => n.status == NotificationStatus.unread).length;
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider.loadNotifications error: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index].status = NotificationStatus.read;
        _unreadCount = _notifications.where((n) => n.status == NotificationStatus.unread).length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('NotificationProvider.markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _repository.markAllAsRead(userId);
      for (final n in _notifications) {
        n.status = NotificationStatus.read;
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider.markAllAsRead error: $e');
    }
  }

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    if (notification.status == NotificationStatus.unread) {
      _unreadCount++;
    }
    notifyListeners();
  }
}