import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../helpers/app_exception.dart';
import '../models/notification.dart';

class NotificationRepository {
  NotificationRepository._();
  static final NotificationRepository instance = NotificationRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsCol =>
      _firestore.collection('notifications');

  Future<void> sendNotification(AppNotification notification) async {
    try {
      final docRef = _notificationsCol.doc();
      notification.id = docRef.id;
      await docRef.set(notification.toMap());
    } catch (e, stack) {
      debugPrint('NotificationRepository.sendNotification error: $e\n$stack');
      throw AppException('Failed to send notification', cause: e);
    }
  }

  Future<List<AppNotification>> getNotificationsForUser(String userId) async {
    try {
      final query = await _notificationsCol
          .where('receiverId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      final notifications = <AppNotification>[];
      for (final doc in query.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        notifications.add(AppNotification.fromMap(data));
      }
      return notifications;
    } catch (e, stack) {
      debugPrint('NotificationRepository.getNotificationsForUser error: $e\n$stack');
      throw AppException('Failed to load notifications', cause: e);
    }
  }

  Future<int> markAsRead(String notificationId) async {
    try {
      await _notificationsCol.doc(notificationId).update({
        'status': NotificationStatus.read.name,
      });
      return 1;
    } catch (e, stack) {
      debugPrint('NotificationRepository.markAsRead error: $e\n$stack');
      throw AppException('Failed to mark notification as read', cause: e);
    }
  }

  Future<int> markAllAsRead(String userId) async {
    try {
      final query = await _notificationsCol
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: NotificationStatus.unread.name)
          .get();
      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'status': NotificationStatus.read.name,
        });
      }
      await batch.commit();
      return query.docs.length;
    } catch (e, stack) {
      debugPrint('NotificationRepository.markAllAsRead error: $e\n$stack');
      throw AppException('Failed to mark notifications as read', cause: e);
    }
  }

  Stream<QuerySnapshot> getNotificationsStream(String userId) {
    return _notificationsCol
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}