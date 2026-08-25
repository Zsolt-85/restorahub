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

  static bool rangesOverlap({
    required int startA,
    required int endA,
    required int startB,
    required int endB,
  }) {
    return startA < endB && startB < endA;
  }

  static bool isWithinOperatingHours({
    required TimeOfDay start,
    required int durationMinutes,
    required TimeOfDay workStart,
    required TimeOfDay workEnd,
  }) {
    final startMinutes = timeToMinutes(start);
    final endMinutes = startMinutes + durationMinutes;
    return startMinutes >= timeToMinutes(workStart) &&
        endMinutes <= timeToMinutes(workEnd);
  }

  static List<TimeOfDay> generateStartTimes({
    required TimeOfDay workStart,
    required TimeOfDay workEnd,
    int incrementMinutes = 15,
  }) {
    if (incrementMinutes <= 0) return [];

    final startMinutes = timeToMinutes(workStart);
    final endMinutes = timeToMinutes(workEnd);
    if (endMinutes < startMinutes) return [];

    final times = <TimeOfDay>[];
    var cursor = startMinutes;
    while (cursor <= endMinutes) {
      times.add(minutesToTime(cursor));
      cursor += incrementMinutes;
    }
    return times;
  }

  static TimeOfDay? computeEndTime({
    required TimeOfDay start,
    required int durationMinutes,
  }) {
    if (durationMinutes < 0) return null;
    return minutesToTime(timeToMinutes(start) + durationMinutes);
  }

  static bool isRangeAvailable({
    required DateTime start,
    required int durationMinutes,
    required TimeOfDay workStart,
    required TimeOfDay workEnd,
    required List<Appointment> appointments,
    required String professionalId,
    String? excludeAppointmentId,
    int bufferTimeMinutes = 0,
    TimeOfDay? breakStart,
    TimeOfDay? breakEnd,
  }) {
    if (durationMinutes <= 0) return false;

    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = startMinutes + durationMinutes;

    if (!isWithinOperatingHours(
      start: TimeOfDay(hour: start.hour, minute: start.minute),
      durationMinutes: durationMinutes,
      workStart: workStart,
      workEnd: workEnd,
    )) {
      return false;
    }

    if (breakStart != null && breakEnd != null) {
      final breakStartMinutes = timeToMinutes(breakStart);
      final breakEndMinutes = timeToMinutes(breakEnd);
      if (rangesOverlap(
        startA: startMinutes,
        endA: endMinutes,
        startB: breakStartMinutes,
        endB: breakEndMinutes,
      )) {
        return false;
      }
    }

    for (final appointment in appointments) {
      if (appointment.id == excludeAppointmentId) continue;
      if (appointment.professionalId != professionalId) continue;
      if (!isSameDay(appointment.dateTime, start)) continue;

      final occupiedDuration = appointment.durationMinutes + bufferTimeMinutes;
      final apptStart = appointment.dateTime.hour * 60 + appointment.dateTime.minute;
      final apptEnd = apptStart + occupiedDuration;

      if (rangesOverlap(
        startA: startMinutes,
        endA: endMinutes,
        startB: apptStart,
        endB: apptEnd,
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
