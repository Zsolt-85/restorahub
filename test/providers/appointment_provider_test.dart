import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/helpers/app_exception.dart';
import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/providers/appointment_provider.dart';
import 'package:restorahub/repositories/booking_repository.dart';

class FakeBookingRepository implements BookingRepository {
  final List<Appointment> appointments = [];
  final Map<String, User> users = {};

  @override
  Future<User?> getUserById(String id) async => users[id];

  @override
  Future<bool> isEmailTaken(String email, {String? excludeUserId}) async {
    return users.values.any((u) => u.email == email && u.id != excludeUserId);
  }

  @override
  Future<int> insertUser(User user) async {
    users[user.id!] = user;
    return 1;
  }

  @override
  Future<int> updateUser(User user) async {
    users[user.id!] = user;
    return 1;
  }

  @override
  Future<void> syncUserInAppointments(User user) async {
    for (var i = 0; i < appointments.length; i++) {
      if (appointments[i].customerId == user.id) {
        appointments[i] = appointments[i].copyWith(
          customerName: user.name,
          customerPhone: user.phone,
          customerEmail: user.email,
        );
      }
      if (appointments[i].professionalId == user.id) {
        appointments[i] = appointments[i].copyWith(
          professionalName: user.name,
          professionalPhone: user.phone,
          professionalEmail: user.email,
        );
      }
    }
  }

  @override
  Future<List<User>> getProfessionalsBySpecialty(String specialty) async {
    return users.values.where((u) => u.role == 'professional' && u.specialty == specialty).toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsForCustomer(String customerId) async {
    return appointments.where((a) => a.customerId == customerId).toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsForProfessional(String professionalId) async {
    return appointments.where((a) => a.professionalId == professionalId).toList();
  }

  @override
  Future<bool> checkProfessionalAvailability({required String professionalId, required DateTime dateTime, required int slotDurationMinutes, int bufferTimeMinutes = 0}) async {
    final slotEnd = dateTime.add(Duration(minutes: slotDurationMinutes));
    return !appointments.any((a) {
      if (a.professionalId != professionalId) return false;
      if (a.isCancelled) return false;
      if (!a.dateTime.isBefore(slotEnd)) return false;
      final occupiedDuration = a.durationMinutes + bufferTimeMinutes;
      final apptEnd = a.dateTime.add(Duration(minutes: occupiedDuration));
      return apptEnd.isAfter(dateTime);
    });
  }

  @override
  Future<void> createAppointmentAtomic(Appointment appointment) async {
    if (appointment.professionalId != null) {
      final slotStart = appointment.dateTime;
      final slotEnd = slotStart.add(Duration(minutes: appointment.durationMinutes));

      final hasOverlap = appointments.any((a) {
        if (a.professionalId != appointment.professionalId) return false;
        if (a.status != AppointmentStatus.pending && a.status != AppointmentStatus.confirmed) return false;
        final apptEnd = a.dateTime.add(Duration(minutes: a.durationMinutes));
        return slotStart.isBefore(apptEnd) && slotEnd.isAfter(a.dateTime);
      });

      if (hasOverlap) {
        throw AppException('This time slot is no longer available', code: 'SLOT_TAKEN');
      }
    }

    appointment.id ??= (appointments.length + 1).toString();
    appointments.add(appointment);
  }

  @override
  Future<int> insertAppointment(Appointment appointment) async {
    appointment.id ??= (appointments.length + 1).toString();
    appointments.add(appointment);
    return 1;
  }

  @override
  Future<int> updateAppointment(Appointment appointment) async {
    final idx = appointments.indexWhere((a) => a.id == appointment.id);
    if (idx != -1) {
      appointments[idx] = appointment;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> deleteAppointment(String id) async {
    final lengthBefore = appointments.length;
    appointments.removeWhere((a) => a.id == id);
    return appointments.length < lengthBefore ? 1 : 0;
  }

  @override
  Stream<List<Appointment>> watchAppointmentsForCustomer(String customerId) {
    final controller = StreamController<List<Appointment>>();
    controller.add(appointments.where((a) => a.customerId == customerId).toList());
    return controller.stream;
  }

  @override
  Stream<List<Appointment>> watchAppointmentsForProfessional(String professionalId) {
    final controller = StreamController<List<Appointment>>();
    controller.add(appointments.where((a) => a.professionalId == professionalId).toList());
    return controller.stream;
  }

  @override
  Stream<Appointment?> watchAppointment(String id) {
    final controller = StreamController<Appointment?>();
    final appt = appointments.where((a) => a.id == id).firstOrNull;
    controller.add(appt);
    return controller.stream;
  }
}

void main() {
  group('AppointmentProvider Tests', () {
    late FakeBookingRepository repository;
    late AppointmentProvider provider;

    setUp(() {
      repository = FakeBookingRepository();
      provider = AppointmentProvider(repository: repository);
      provider.currentUser = User(
        id: 'cust-1',
        name: 'Test User',
        email: 'test@example.com',
        phone: '555-0100',
        role: 'customer',
      );
    });

    test('Initial loading state and loadAppointments success', () async {
      expect(provider.isLoading, isFalse);
      expect(provider.appointments, isEmpty);

      final appt = Appointment(
        id: '1',
        service: 'Massage',
        dateTime: DateTime(2026, 8, 1, 10, 0),
        durationMinutes: 60,
        customerId: 'cust-1',
      );
      await repository.insertAppointment(appt);

      await provider.loadAppointments();

      expect(provider.isLoading, isFalse);
      expect(provider.appointments.length, 1);
      expect(provider.appointments.first.service, 'Massage');
    });

    test('addAppointment adds to repository and reloads list', () async {
      final appt = Appointment(
        service: 'Facial',
        dateTime: DateTime(2026, 8, 1, 11, 0),
        customerId: 'cust-1',
      );

      await provider.addAppointment(appt);

      expect(provider.appointments.length, 1);
      expect(provider.appointments.first.service, 'Facial');
      expect(provider.appointments.first.id, isNotNull);
    });

    test('updateAppointment modifies existing appointment and reloads', () async {
      final appt = Appointment(
        id: '1',
        service: 'Massage',
        dateTime: DateTime(2026, 8, 1, 10, 0),
        customerId: 'cust-1',
      );
      await provider.addAppointment(appt);

      final updated = provider.appointments.first.copyWith(service: 'Deep Tissue Massage');
      await provider.updateAppointment(updated);

      expect(provider.appointments.first.service, 'Deep Tissue Massage');
    });

    test('deleteAppointment removes from list', () async {
      final appt = Appointment(
        id: '1',
        service: 'Massage',
        dateTime: DateTime(2026, 8, 1, 10, 0),
        customerId: 'cust-1',
      );
      await provider.addAppointment(appt);
      expect(provider.appointments.length, 1);

      await provider.deleteAppointment('1');
      expect(provider.appointments, isEmpty);
    });

    test('linkPaymentToAppointment links payment ID and marks completed', () async {
      final appt = Appointment(
        id: '10',
        service: 'Massage',
        dateTime: DateTime(2026, 8, 1, 10, 0),
        status: AppointmentStatus.confirmed,
        customerId: 'cust-1',
      );
      await provider.addAppointment(appt);

      await provider.linkPaymentToAppointment('10', 'PAY-999');

      final updatedAppt = provider.appointments.firstWhere((a) => a.id == '10');
      expect(updatedAppt.paymentId, 'PAY-999');
      expect(updatedAppt.status, AppointmentStatus.completed);
    });

    test('rescheduleAppointment works correctly if slot is available', () async {
      final appt = Appointment(
        id: '1',
        service: 'Massage',
        dateTime: DateTime(2026, 8, 1, 10, 0),
        durationMinutes: 60,
        professionalId: 'prof-1',
        customerId: 'cust-1',
      );
      await provider.addAppointment(appt);

      final newTime = DateTime(2026, 8, 1, 14, 0);
      final error = await provider.rescheduleAppointment(
        appointment: provider.appointments.first,
        newDateTime: newTime,
      );

      expect(error, isNull);
      expect(provider.appointments.first.dateTime, newTime);
    });

    test('rescheduleAppointment fails if slot is already taken', () async {
      final appt1 = Appointment(
        id: '1',
        service: 'Massage',
        dateTime: DateTime(2026, 8, 1, 10, 0),
        durationMinutes: 60,
        professionalId: 'prof-1',
        customerId: 'cust-1',
      );
      final appt2 = Appointment(
        id: '2',
        service: 'Facial',
        dateTime: DateTime(2026, 8, 1, 10, 0),
        durationMinutes: 60,
        professionalId: 'prof-1',
        customerId: 'cust-1',
      );
      await provider.addAppointment(appt1);
      await provider.addAppointment(appt2);

      // Try to reschedule appt1 to the exact same time as appt2
      final error = await provider.rescheduleAppointment(
        appointment: provider.appointments.firstWhere((a) => a.id == '1'),
        newDateTime: DateTime(2026, 8, 1, 10, 0),
      );

      expect(error, 'This time slot is no longer available');
    });

    test('addAppointment rejects booking when slot is unavailable', () async {
      final existingAppt = Appointment(
        id: '1',
        service: 'Massage',
        dateTime: DateTime(2026, 8, 1, 10, 0),
        durationMinutes: 60,
        professionalId: 'prof-1',
        customerId: 'cust-1',
      );
      await repository.insertAppointment(existingAppt);

      final newAppt = Appointment(
        service: 'Facial',
        dateTime: DateTime(2026, 8, 1, 10, 0),
        durationMinutes: 60,
        professionalId: 'prof-1',
        customerId: 'cust-1',
      );

      await provider.addAppointment(newAppt);

      expect(provider.appointments.length, 0);
      expect(provider.error, 'This time slot is no longer available');
    });

    group('Cancellation Policy', () {
      test('cancelAppointment fails within 2-hour window', () async {
        final appt = Appointment(
          id: '1',
          service: 'Massage',
          dateTime: DateTime.now().add(const Duration(hours: 1)),
          customerId: 'cust-1',
        );
        await provider.addAppointment(appt);

        final error = await provider.cancelAppointment('1');
        expect(error, 'Appointments cannot be cancelled less than 2 hours before the start time.');
      });

      test('cancelAppointment succeeds outside 2-hour window', () async {
        final appt = Appointment(
          id: '1',
          service: 'Massage',
          dateTime: DateTime.now().add(const Duration(days: 1)),
          customerId: 'cust-1',
        );
        await provider.addAppointment(appt);

        final error = await provider.cancelAppointment('1');
        expect(error, isNull);
        expect(provider.appointments.length, 1);
        expect(provider.appointments.first.status, AppointmentStatus.cancelledByCustomer);
      });
    });

    group('State Machine Transitions', () {
      test('updateAppointmentStatus rejects terminal to non-terminal transition', () async {
        final appt = Appointment(
          id: '1',
          service: 'Massage',
          dateTime: DateTime.now().add(const Duration(days: 1)),
          status: AppointmentStatus.completed,
          customerId: 'cust-1',
        );
        await provider.addAppointment(appt);

        await provider.updateAppointmentStatus('1', AppointmentStatus.pending);
        expect(provider.error, contains('Invalid status transition'));
      });

      test('rescheduleAppointment rejects terminal status', () async {
        final appt = Appointment(
          id: '1',
          service: 'Massage',
          dateTime: DateTime.now().add(const Duration(days: 1)),
          status: AppointmentStatus.completed,
          customerId: 'cust-1',
        );
        await provider.addAppointment(appt);

        final error = await provider.rescheduleAppointment(
          appointment: provider.appointments.first,
          newDateTime: DateTime.now().add(const Duration(days: 2)),
        );
        expect(error, 'This appointment cannot be rescheduled');
      });
    });

    group('Real-Time Streams', () {
      test('startRealtimeAppointments sets up stream', () async {
        provider.startRealtimeAppointments();
        expect(provider.appointmentsStream, isNotNull);
        provider.stopRealtimeAppointments();
      });
    });
  });
}
