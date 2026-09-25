import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/exceptions/app_exception.dart';
import 'package:restorahub/helpers/notification_schedule_helper.dart';
import 'package:restorahub/models/notification.dart';
import 'package:restorahub/providers/notification_provider.dart';
import 'package:restorahub/repositories/notification_repository.dart';

class FakeNotificationRepository implements NotificationRepository {
  final List<AppNotification> stored = [];

  @override
  Future<void> sendNotification(AppNotification notification,
      {String? businessId}) async {
    stored.add(notification);
  }

  @override
  Future<List<AppNotification>> getNotificationsForUser(String userId,
      {String? businessId}) async {
    return stored
        .where((n) => n.receiverId == userId)
        .where((n) => businessId == null || n.businessId == businessId)
        .toList();
  }

  @override
  Future<int> markAsRead(String notificationId) async => 1;

  @override
  Future<int> markAllAsRead(String userId, {String? businessId}) async => 0;

  @override
  Stream<List<AppNotification>> watchNotifications(String userId,
          {String? businessId}) =>
      Stream.value([]);
}

class FailingNotificationRepository implements NotificationRepository {
  @override
  Future<void> sendNotification(AppNotification notification,
      {String? businessId}) async {
    throw const AppException('send failed');
  }

  @override
  Future<List<AppNotification>> getNotificationsForUser(String userId,
      {String? businessId}) async {
    throw const AppException('load failed');
  }

  @override
  Future<int> markAsRead(String notificationId) async {
    throw const AppException('update failed');
  }

  @override
  Future<int> markAllAsRead(String userId, {String? businessId}) async {
    throw const AppException('update failed');
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId,
          {String? businessId}) =>
      Stream.value([]);
}

AppNotification _notification(String id, String receiverId,
    {NotificationStatus status = NotificationStatus.unread}) {
  return AppNotification(
    id: id,
    type: NotificationType.bookingRequested,
    title: 'Test',
    message: 'Test message',
    receiverId: receiverId,
    senderId: 'sender-1',
    status: status,
  );
}

void main() {
  group('NotificationProvider loading/error contract', () {
    test('initial state is idle with no error', () {
      final provider =
          NotificationProvider(repository: FakeNotificationRepository());
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.notifications, isEmpty);
      expect(provider.unreadCount, 0);
    });

    test('loadNotifications populates list and clears loading', () async {
      final repository = FakeNotificationRepository();
      repository.stored.add(_notification('n1', 'user-1'));
      repository.stored
          .add(_notification('n2', 'user-1', status: NotificationStatus.read));
      final provider = NotificationProvider(repository: repository);

      await provider.loadNotifications('user-1');

      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.notifications.length, 2);
      expect(provider.unreadCount, 1);
    });

    test('loadNotifications surfaces repository errors', () async {
      final provider =
          NotificationProvider(repository: FailingNotificationRepository());

      await provider.loadNotifications('user-1');

      expect(provider.isLoading, isFalse);
      expect(provider.error, 'load failed');
      expect(provider.notifications, isEmpty);
    });
  });

  group('NotificationProvider web reminder fallback', () {
    setUp(() {
      NotificationScheduleHelper.debugForceWebFallback = true;
      NotificationScheduleHelper.drainWebReminders();
    });

    tearDown(() {
      NotificationScheduleHelper.debugForceWebFallback = null;
      NotificationScheduleHelper.drainWebReminders();
    });

    test('queued web reminders surface as in-app upcoming items', () async {
      await NotificationScheduleHelper.scheduleUpcomingReminder(
        appointmentId: 'a1',
        title: 'Appointment reminder',
        body: 'Massage is in 1 hour',
        scheduledTime: DateTime(2030, 5, 1, 9, 0),
      );
      final provider =
          NotificationProvider(repository: FakeNotificationRepository());

      await provider.loadNotifications('user-1');

      final reminders = provider.notifications
          .where((n) => n.type == NotificationType.upcomingReminder)
          .toList();
      expect(reminders.length, 1);
      expect(reminders.first.appointmentId, 'a1');
      expect(reminders.first.receiverId, 'user-1');
      expect(provider.unreadCount, 1);
      // One-shot: a second load does not duplicate them.
      await provider.loadNotifications('user-1');
      expect(
          provider.notifications
              .where((n) => n.type == NotificationType.upcomingReminder)
              .length,
          1);
    });
  });

  group('NotificationProvider web reminder persistence', () {
    setUp(() {
      NotificationScheduleHelper.debugForceWebFallback = true;
      NotificationScheduleHelper.drainWebReminders();
    });

    tearDown(() {
      NotificationScheduleHelper.debugForceWebFallback = null;
      NotificationScheduleHelper.drainWebReminders();
    });

    test('markAllAsRead stays read after reload (no resurrection)', () async {
      await NotificationScheduleHelper.scheduleUpcomingReminder(
        appointmentId: 'a1',
        title: 'Appointment reminder',
        body: 'Massage is in 1 hour',
        scheduledTime: DateTime(2030, 5, 1, 9, 0),
      );
      final provider =
          NotificationProvider(repository: FakeNotificationRepository());
      await provider.loadNotifications('user-1');
      await provider.markAllAsRead('user-1');
      await provider.loadNotifications('user-1');

      final reminders = provider.notifications
          .where((n) => n.type == NotificationType.upcomingReminder)
          .toList();
      expect(reminders.length, 1);
      expect(reminders.first.status, NotificationStatus.read);
      expect(provider.unreadCount, 0);
    });

    test('rescheduled reminder replaces the pending one', () async {
      await NotificationScheduleHelper.scheduleUpcomingReminder(
        appointmentId: 'a1',
        title: 'Appointment reminder',
        body: 'Old time',
        scheduledTime: DateTime(2030, 5, 1, 9, 0),
      );
      await NotificationScheduleHelper.scheduleUpcomingReminder(
        appointmentId: 'a1',
        title: 'Appointment reminder',
        body: 'New time',
        scheduledTime: DateTime(2030, 5, 2, 9, 0),
      );
      final provider =
          NotificationProvider(repository: FakeNotificationRepository());
      await provider.loadNotifications('user-1');

      final reminders = provider.notifications
          .where((n) => n.type == NotificationType.upcomingReminder)
          .toList();
      expect(reminders.length, 1);
      expect(reminders.first.message, 'New time');
    });
  });

  group('NotificationProvider read state', () {
    test('markAsRead flips status without mutating the original', () async {
      final repository = FakeNotificationRepository();
      final original = _notification('n1', 'user-1');
      repository.stored.add(original);
      final provider = NotificationProvider(repository: repository);
      await provider.loadNotifications('user-1');

      await provider.markAsRead('n1');

      expect(provider.notifications.first.status, NotificationStatus.read);
      expect(provider.unreadCount, 0);
      // Original instance untouched: copyWith was used.
      expect(original.status, NotificationStatus.unread);
      expect(provider.error, isNull);
    });

    test('markAllAsRead flips every notification', () async {
      final repository = FakeNotificationRepository();
      repository.stored.add(_notification('n1', 'user-1'));
      repository.stored.add(_notification('n2', 'user-1'));
      final provider = NotificationProvider(repository: repository);
      await provider.loadNotifications('user-1');

      await provider.markAllAsRead('user-1');

      expect(provider.unreadCount, 0);
      expect(
          provider.notifications
              .every((n) => n.status == NotificationStatus.read),
          isTrue);
    });

    test('markAsRead records error on failure', () async {
      final provider =
          NotificationProvider(repository: FailingNotificationRepository());

      await provider.markAsRead('missing');

      expect(provider.error, 'update failed');
    });
  });
}
