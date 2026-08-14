import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification.dart';

abstract class NotificationRepository {
  Future<void> sendNotification(AppNotification notification);
  Future<List<AppNotification>> getNotificationsForUser(String userId);
  Future<int> markAsRead(String notificationId);
  Future<int> markAllAsRead(String userId);
  Stream<QuerySnapshot> getNotificationsStream(String userId);
}