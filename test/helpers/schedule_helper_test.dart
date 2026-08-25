import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/helpers/schedule_helper.dart';
import 'package:restorahub/models/appointment.dart';

void main() {
  group('ScheduleHelper', () {
    test('parseServiceCategory extracts base service', () {
      expect(
        ScheduleHelper.parseServiceCategory('Massage — Full Body'),
        'Massage',
      );
    });

    test('generateSlots respects duration and work hours', () {
      final slots = ScheduleHelper.generateSlots(
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 11, minute: 0),
        slotMinutes: 30,
      );

      expect(slots.length, 4);
      expect(slots.first, const TimeOfDay(hour: 9, minute: 0));
      expect(slots.last, const TimeOfDay(hour: 10, minute: 30));
    });

    test('generateSlots excludes break time slots', () {
      final slots = ScheduleHelper.generateSlots(
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 13, minute: 0),
        slotMinutes: 60,
        breakStart: const TimeOfDay(hour: 11, minute: 30),
        breakEnd: const TimeOfDay(hour: 12, minute: 30),
      );

      expect(slots.length, 2);
      expect(slots.first, const TimeOfDay(hour: 9, minute: 0));
      expect(slots.last, const TimeOfDay(hour: 10, minute: 0));
    });

    test('intervalsOverlap detects overlapping appointments', () {
      final start = DateTime(2026, 6, 9, 10, 0);

      expect(
        ScheduleHelper.intervalsOverlap(
          startA: start,
          durationA: 60,
          startB: start.add(const Duration(minutes: 30)),
          durationB: 60,
        ),
        isTrue,
      );

      expect(
        ScheduleHelper.intervalsOverlap(
          startA: start,
          durationA: 60,
          startB: start.add(const Duration(minutes: 60)),
          durationB: 60,
        ),
        isFalse,
      );
    });

    test('isSlotAvailable ignores excluded appointment while rescheduling', () {
      final day = DateTime(2026, 6, 9, 10, 0);
      final appointments = [
        Appointment(
          id: '42',
          service: 'Massage — Full Body',
          dateTime: day,
          durationMinutes: 60,
          professionalId: '7',
        ),
      ];

      expect(
        ScheduleHelper.isSlotAvailable(
          slotStart: day,
          slotDuration: 60,
          professionalId: '7',
          appointments: appointments,
          excludeAppointmentId: '42',
        ),
        isTrue,
      );
    });

    test('isSlotAvailable rejects conflicting professional slots', () {
      final day = DateTime(2026, 6, 9, 10, 0);
      final appointments = [
        Appointment(
          id: '1',
          service: 'Massage — Full Body',
          dateTime: day,
          durationMinutes: 60,
          professionalId: '7',
        ),
      ];

      expect(
        ScheduleHelper.isSlotAvailable(
          slotStart: day.add(const Duration(minutes: 30)),
          slotDuration: 60,
          professionalId: '7',
          appointments: appointments,
        ),
        isFalse,
      );

      expect(
        ScheduleHelper.isSlotAvailable(
          slotStart: day.add(const Duration(hours: 2)),
          slotDuration: 60,
          professionalId: '7',
          appointments: appointments,
        ),
        isTrue,
      );
    });

    test('isSlotAvailable respects buffer time between appointments', () {
      final day = DateTime(2026, 6, 9, 10, 0);
      final appointments = [
        Appointment(
          id: '1',
          service: 'Massage — Full Body',
          dateTime: day,
          durationMinutes: 60,
          professionalId: '7',
        ),
      ];

      expect(
        ScheduleHelper.isSlotAvailable(
          slotStart: day.add(const Duration(hours: 1)),
          slotDuration: 60,
          professionalId: '7',
          appointments: appointments,
          bufferTimeMinutes: 15,
        ),
        isFalse,
      );

      expect(
        ScheduleHelper.isSlotAvailable(
          slotStart: day.add(const Duration(hours: 1, minutes: 15)),
          slotDuration: 60,
          professionalId: '7',
          appointments: appointments,
          bufferTimeMinutes: 15,
        ),
        isTrue,
      );
    });

    test('validateWorkSchedule catches invalid ranges', () {
      expect(
        ScheduleHelper.validateWorkSchedule(
          workStart: const TimeOfDay(hour: 17, minute: 0),
          workEnd: const TimeOfDay(hour: 9, minute: 0),
          slotDurationMinutes: 30,
        ),
        isNotNull,
      );
    });

    test('generateStartTimes produces 15-minute increments', () {
      final times = ScheduleHelper.generateStartTimes(
        workStart: const TimeOfDay(hour: 9, minute: 0),
        workEnd: const TimeOfDay(hour: 10, minute: 0),
      );

      expect(times.length, 5);
      expect(times.first, const TimeOfDay(hour: 9, minute: 0));
      expect(times.last, const TimeOfDay(hour: 10, minute: 0));
    });

    test('computeEndTime adds duration to start', () {
      expect(
        ScheduleHelper.computeEndTime(
          start: const TimeOfDay(hour: 14, minute: 15),
          durationMinutes: 90,
        ),
        const TimeOfDay(hour: 15, minute: 45),
      );
    });

    test('isRangeAvailable requires range within operating hours', () {
      final day = DateTime(2026, 6, 9, 16, 30);
      final appointments = <Appointment>[];

      expect(
        ScheduleHelper.isRangeAvailable(
          start: day,
          durationMinutes: 60,
          workStart: const TimeOfDay(hour: 9, minute: 0),
          workEnd: const TimeOfDay(hour: 17, minute: 0),
          appointments: appointments,
          professionalId: '7',
        ),
        isFalse,
      );
    });

    test('isRangeAvailable rejects collision with existing appointment', () {
      final day = DateTime(2026, 6, 9, 10, 0);
      final appointments = [
        Appointment(
          id: '1',
          service: 'Massage — Full Body',
          dateTime: day,
          durationMinutes: 60,
          professionalId: '7',
        ),
      ];

      expect(
        ScheduleHelper.isRangeAvailable(
          start: DateTime(2026, 6, 9, 10, 30),
          durationMinutes: 60,
          workStart: const TimeOfDay(hour: 9, minute: 0),
          workEnd: const TimeOfDay(hour: 17, minute: 0),
          appointments: appointments,
          professionalId: '7',
        ),
        isFalse,
      );

      expect(
        ScheduleHelper.isRangeAvailable(
          start: DateTime(2026, 6, 9, 11, 0),
          durationMinutes: 60,
          workStart: const TimeOfDay(hour: 9, minute: 0),
          workEnd: const TimeOfDay(hour: 17, minute: 0),
          appointments: appointments,
          professionalId: '7',
        ),
        isTrue,
      );
    });

    test('isRangeAvailable ignores excluded appointment', () {
      final day = DateTime(2026, 6, 9, 10, 0);
      final appointments = [
        Appointment(
          id: '42',
          service: 'Massage — Full Body',
          dateTime: day,
          durationMinutes: 60,
          professionalId: '7',
        ),
      ];

      expect(
        ScheduleHelper.isRangeAvailable(
          start: day,
          durationMinutes: 60,
          workStart: const TimeOfDay(hour: 9, minute: 0),
          workEnd: const TimeOfDay(hour: 17, minute: 0),
          appointments: appointments,
          professionalId: '7',
          excludeAppointmentId: '42',
        ),
        isTrue,
      );
    });
  });
}
