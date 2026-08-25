import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../models/appointment.dart';
import '../models/user.dart';

class CalendarHelper {
  static Future<void> addToNativeCalendar(
    Appointment appointment,
    User professional,
  ) async {
    if (kIsWeb) return;

    final event = Event(
      title: 'RestoraHub: ${appointment.service} with ${professional.name}',
      description: _buildDescription(appointment, professional),
      location: professional.category,
      startDate: appointment.dateTime,
      endDate: appointment.endTime,
      iosParams: const IOSParams(
        reminder: Duration(hours: 1),
      ),
      androidParams: const AndroidParams(
        emailInvites: [],
      ),
    );

    try {
      await Add2Calendar.addEvent2Cal(event);
    } on PlatformException catch (_) {
      throw const CalendarException(
        'Unable to add event to calendar. Please ensure you have a calendar app installed.',
      );
    } catch (_) {
      throw const CalendarException(
        'Unable to add event to calendar. Please try again.',
      );
    }
  }

  static String _buildDescription(Appointment appointment, User professional) {
    final buffer = StringBuffer();
    buffer.writeln('RestoraHub Booking Confirmation');
    buffer.writeln('');
    buffer.writeln('Service: ${appointment.service}');
    buffer.writeln('Professional: ${professional.name}');
    buffer.writeln('Category: ${professional.category}');
    buffer.writeln('Date: ${_formatDate(appointment.dateTime)}');
    buffer.writeln('Time: ${_formatTime(appointment.dateTime)}');
    buffer.writeln('Duration: ${appointment.durationMinutes} minutes');
    buffer.writeln('');
    if (appointment.customerName != null) {
      buffer.writeln('Customer: ${appointment.customerName}');
    }
    if (appointment.customerPhone != null) {
      buffer.writeln('Customer Phone: ${appointment.customerPhone}');
    }
    if (professional.phone.isNotEmpty) {
      buffer.writeln('Professional Phone: ${professional.phone}');
    }
    if (professional.email.isNotEmpty) {
      buffer.writeln('Professional Email: ${professional.email}');
    }
    buffer.writeln('');
    buffer.writeln('Please arrive a few minutes before your scheduled time.');
    return buffer.toString().trim();
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class CalendarException implements Exception {
  final String message;
  const CalendarException(this.message);

  @override
  String toString() => 'CalendarException: $message';
}
