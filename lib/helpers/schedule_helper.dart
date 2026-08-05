import 'package:flutter/material.dart';

import '../models/appointment.dart';

class ScheduleHelper {
  static String parseServiceCategory(String serviceLabel) {
    return serviceLabel.split('\u2014').first.trim();
  }

  static int timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  static TimeOfDay minutesToTime(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  static List<TimeOfDay> generateSlots({
    required TimeOfDay start,
    required TimeOfDay end,
    required int slotMinutes,
    TimeOfDay? breakStart,
    TimeOfDay? breakEnd,
  }) {
    if (slotMinutes <= 0) return [];

    final slots = <TimeOfDay>[];
    var cursor = timeToMinutes(start);
    final endMinutes = timeToMinutes(end);

    while (cursor + slotMinutes <= endMinutes) {
      final slotStartMinutes = cursor;
      final slotEndMinutes = cursor + slotMinutes;

      final overlapsBreak = breakStart != null &&
          breakEnd != null &&
          slotStartMinutes < timeToMinutes(breakEnd) &&
          slotEndMinutes > timeToMinutes(breakStart);

      if (!overlapsBreak) {
        slots.add(minutesToTime(cursor));
      }

      cursor += slotMinutes;
    }

    return slots;
  }

  static bool intervalsOverlap({
    required DateTime startA,
    required int durationA,
    required DateTime startB,
    required int durationB,
  }) {
    final endA = startA.add(Duration(minutes: durationA));
    final endB = startB.add(Duration(minutes: durationB));
    return startA.isBefore(endB) && startB.isBefore(endA);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isSlotAvailable({
    required DateTime slotStart,
    required int slotDuration,
    required String professionalId,
    required List<Appointment> appointments,
    String? excludeAppointmentId,
    int bufferTimeMinutes = 0,
  }) {
    for (final appointment in appointments) {
      if (appointment.id == excludeAppointmentId) continue;
      if (appointment.professionalId != professionalId) continue;
      if (!isSameDay(appointment.dateTime, slotStart)) continue;

      final occupiedDuration = appointment.durationMinutes + bufferTimeMinutes;

      if (intervalsOverlap(
        startA: slotStart,
        durationA: slotDuration,
        startB: appointment.dateTime,
        durationB: occupiedDuration,
      )) {
        return false;
      }
    }

    return true;
  }

  static String? validateWorkSchedule({
    required TimeOfDay workStart,
    required TimeOfDay workEnd,
    required int slotDurationMinutes,
  }) {
    if (timeToMinutes(workEnd) <= timeToMinutes(workStart)) {
      return 'End time must be after start time';
    }

    if (slotDurationMinutes <= 0) {
      return 'Slot length must be greater than zero';
    }

    final availableMinutes =
        timeToMinutes(workEnd) - timeToMinutes(workStart);
    if (slotDurationMinutes > availableMinutes) {
      return 'Slot length cannot exceed working hours';
    }

    return null;
  }
}
