import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/notification.dart';
import '../repositories/notification_repository.dart';
import '../utils/app_logger.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required NotificationRepository repository})
      : _repository = repository;

  final NotificationRepository _repository;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  StreamSubscription<QuerySnapshot>? _subscription;

  Future<void> loadNotifications(String userId) async {
    await stopRealtimeNotifications();
    try {
      _notifications = await _repository.getNotificationsForUser(userId);
      _unreadCount =
          _notifications.where((n) => n.status == NotificationStatus.unread).length;
      notifyListeners();
    } catch (e) {
      AppLogger.error('NotificationProvider.loadNotifications error: $e');
    }
  }

  void startRealtimeNotifications(String userId) {
    stopRealtimeNotifications();
    _subscription = _repository.getNotificationsStream(userId).listen(
      (snapshot) {
        final notifications = <AppNotification>[];
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          notifications.add(AppNotification.fromMap(data));
        }
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _notifications = notifications;
        _unreadCount =
            notifications.where((n) => n.status == NotificationStatus.unread).length;
        notifyListeners();
      },
      onError: (e) {
        AppLogger.error('NotificationProvider.startRealtimeNotifications error: $e');
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
        _notifications[index].status = NotificationStatus.read;
        _unreadCount = _notifications
            .where((n) => n.status == NotificationStatus.unread)
            .length;
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('NotificationProvider.markAsRead error: $e');
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
      AppLogger.error('NotificationProvider.markAllAsRead error: $e');
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