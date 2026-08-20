import 'package:cloud_firestore/cloud_firestore.dart';

import '../exceptions/app_exception.dart';
import '../models/notification.dart';
import '../utils/app_logger.dart';
import 'notification_repository.dart';

class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository._();
  static final FirestoreNotificationRepository instance =
      FirestoreNotificationRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsCol =>
      _firestore.collection('notifications');

  @override
  Future<void> sendNotification(AppNotification notification, {String? businessId}) async {
    try {
      final docRef = _notificationsCol.doc();
      notification.id = docRef.id;
      final data = Map<String, dynamic>.from(notification.toMap());
      if ((notification.businessId == null || notification.businessId!.isEmpty) &&
          businessId != null && businessId.isNotEmpty) {
        data['businessId'] = businessId;
      }
      await docRef.set(data);
    } catch (e, stack) {
      AppLogger.error('FirestoreNotificationRepository.sendNotification error: $e\n$stack');
      throw AppException('Failed to send notification', cause: e);
    }
  }

  @override
  Future<List<AppNotification>> getNotificationsForUser(String userId, {String? businessId}) async {
    try {
      Query<Map<String, dynamic>> query = _notificationsCol
          .where('receiverId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);
      if (businessId != null && businessId.isNotEmpty) {
        query = query.where('businessId', isEqualTo: businessId);
      }
      final snapshot = await query.get();
      final notifications = <AppNotification>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        notifications.add(AppNotification.fromMap(data));
      }
      return notifications;
    } catch (e, stack) {
      AppLogger.error('FirestoreNotificationRepository.getNotificationsForUser error: $e\n$stack');
      throw AppException('Failed to load notifications', cause: e);
    }
  }

  @override
  Future<int> markAsRead(String notificationId) async {
    try {
      await _notificationsCol.doc(notificationId).update({
        'status': NotificationStatus.read.name,
      });
      return 1;
    } catch (e, stack) {
      AppLogger.error('FirestoreNotificationRepository.markAsRead error: $e\n$stack');
      throw AppException('Failed to mark notification as read', cause: e);
    }
  }

  @override
  Future<int> markAllAsRead(String userId, {String? businessId}) async {
    try {
      Query<Map<String, dynamic>> query = _notificationsCol
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: NotificationStatus.unread.name);
      if (businessId != null && businessId.isNotEmpty) {
        query = query.where('businessId', isEqualTo: businessId);
      }
      final snapshot = await query.get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': NotificationStatus.read.name,
        });
      }
      await batch.commit();
      return snapshot.docs.length;
    } catch (e, stack) {
      AppLogger.error('FirestoreNotificationRepository.markAllAsRead error: $e\n$stack');
      throw AppException('Failed to mark notifications as read', cause: e);
    }
  }

  @override
  Stream<QuerySnapshot> getNotificationsStream(String userId, {String? businessId}) {
    Query<Map<String, dynamic>> query = _notificationsCol
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);
    if (businessId != null && businessId.isNotEmpty) {
      query = query.where('businessId', isEqualTo: businessId);
    }
    return query.snapshots();
  }
}
