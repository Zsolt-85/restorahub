import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Reminder queued on platforms without OS scheduling (web). Surfaced
/// in-app by [NotificationProvider] instead of being silently dropped.
class WebReminder {
  final String appointmentId;
  final String title;
  final String body;
  final DateTime scheduledTime;

  const WebReminder({
    required this.appointmentId,
    required this.title,
    required this.body,
    required this.scheduledTime,
  });
}

class NotificationScheduleHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Test-only override for the platform check (tests run on VM, never web).
  @visibleForTesting
  static bool? debugForceWebFallback;

  /// False on web, where OS-level scheduling is unavailable.
  static bool get isSupported {
    if (debugForceWebFallback != null) return !debugForceWebFallback!;
    return !kIsWeb;
  }

  /// Deterministic, non-negative id for an appointment's reminder.
  ///
  /// Replaces `appointmentId.hashCode`, which can be negative and is not
  /// guaranteed stable across restarts — orphaning notifications so they can
  /// never be cancelled. FNV-1a over a namespaced key is stable everywhere.
  static int notificationIdFor(String appointmentId) {
    const fnvPrime = 0x01000193;
    var hash = 0x811C9DC5;
    final key = 'reminder:$appointmentId';
    for (var i = 0; i < key.length; i++) {
      hash ^= key.codeUnitAt(i);
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  static final List<WebReminder> _webOutbox = [];

  /// Pending web reminders (read-only view, mainly for tests).
  static List<WebReminder> get webOutbox => List.unmodifiable(_webOutbox);

  /// Drains the web outbox; consumed by the in-app notification list.
  static List<WebReminder> drainWebReminders() {
    final reminders = List<WebReminder>.of(_webOutbox);
    _webOutbox.clear();
    return reminders;
  }

  static Future<void> initialize() async {
    if (!isSupported) return;
    tz.initializeTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  static Future<void> scheduleUpcomingReminder({
    required String appointmentId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!isSupported) {
      _webOutbox.add(WebReminder(
        appointmentId: appointmentId,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
      ));
      return;
    }
    await _plugin.zonedSchedule(
      notificationIdFor(appointmentId),
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'upcoming_reminders',
          'Upcoming Appointment Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelScheduledNotification(String appointmentId) async {
    if (!isSupported) {
      _webOutbox.removeWhere((r) => r.appointmentId == appointmentId);
      return;
    }
    await _plugin.cancel(notificationIdFor(appointmentId));
  }

  static Future<void> cancelAllScheduledNotifications() async {
    if (!isSupported) {
      _webOutbox.clear();
      return;
    }
    await _plugin.cancelAll();
  }
}
