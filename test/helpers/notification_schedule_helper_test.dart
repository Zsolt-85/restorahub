import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/helpers/notification_schedule_helper.dart';

void main() {
  group('notificationIdFor', () {
    test('is deterministic across calls', () {
      expect(NotificationScheduleHelper.notificationIdFor('appt-1'),
          NotificationScheduleHelper.notificationIdFor('appt-1'));
    });

    test('is always non-negative', () {
      for (final id in ['a', 'appt-1', '', 'x' * 200, 'ü-🚀']) {
        expect(NotificationScheduleHelper.notificationIdFor(id),
            greaterThanOrEqualTo(0),
            reason: 'id $id');
      }
    });

    test('differs per appointment', () {
      expect(NotificationScheduleHelper.notificationIdFor('appt-1'),
          isNot(NotificationScheduleHelper.notificationIdFor('appt-2')));
    });
  });

  group('web fallback outbox', () {
    setUp(() {
      NotificationScheduleHelper.debugForceWebFallback = true;
      NotificationScheduleHelper.drainWebReminders();
    });

    tearDown(() {
      NotificationScheduleHelper.debugForceWebFallback = null;
      NotificationScheduleHelper.drainWebReminders();
    });

    test('schedule on unsupported platform queues instead of dropping',
        () async {
      expect(NotificationScheduleHelper.isSupported, isFalse);

      await NotificationScheduleHelper.scheduleUpcomingReminder(
        appointmentId: 'a1',
        title: 'Reminder',
        body: 'Service in 1 hour',
        scheduledTime: DateTime(2030, 5, 1, 9, 0),
      );

      expect(NotificationScheduleHelper.webOutbox.length, 1);
      expect(NotificationScheduleHelper.webOutbox.first.appointmentId, 'a1');
    });

    test('drain returns and clears the outbox', () async {
      await NotificationScheduleHelper.scheduleUpcomingReminder(
        appointmentId: 'a1',
        title: 'Reminder',
        body: 'Body',
        scheduledTime: DateTime(2030, 5, 1, 9, 0),
      );

      final drained = NotificationScheduleHelper.drainWebReminders();

      expect(drained.length, 1);
      expect(NotificationScheduleHelper.webOutbox, isEmpty);
    });

    test('cancel removes the queued reminder', () async {
      await NotificationScheduleHelper.scheduleUpcomingReminder(
        appointmentId: 'a1',
        title: 'Reminder',
        body: 'Body',
        scheduledTime: DateTime(2030, 5, 1, 9, 0),
      );
      await NotificationScheduleHelper.scheduleUpcomingReminder(
        appointmentId: 'a2',
        title: 'Reminder',
        body: 'Body',
        scheduledTime: DateTime(2030, 5, 1, 10, 0),
      );

      await NotificationScheduleHelper.cancelScheduledNotification('a1');

      expect(
          NotificationScheduleHelper.webOutbox
              .every((r) => r.appointmentId != 'a1'),
          isTrue);
      expect(NotificationScheduleHelper.webOutbox.length, 1);
    });

    test('cancelAll clears the outbox', () async {
      await NotificationScheduleHelper.scheduleUpcomingReminder(
        appointmentId: 'a1',
        title: 'Reminder',
        body: 'Body',
        scheduledTime: DateTime(2030, 5, 1, 9, 0),
      );

      await NotificationScheduleHelper.cancelAllScheduledNotifications();

      expect(NotificationScheduleHelper.webOutbox, isEmpty);
    });
  });
}
