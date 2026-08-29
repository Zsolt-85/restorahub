import '../models/notification.dart';

abstract class NotificationRepository {
  Future<void> sendNotification(AppNotification notification, {String? businessId});
  Future<List<AppNotification>> getNotificationsForUser(String userId, {String? businessId});
  Future<int> markAsRead(String notificationId);
  Future<int> markAllAsRead(String userId, {String? businessId});
  Stream<List<AppNotification>> watchNotifications(String userId, {String? businessId});
}
