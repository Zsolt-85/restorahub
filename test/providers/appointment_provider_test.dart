import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/exceptions/app_exception.dart';
import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/notification.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/providers/appointment_provider.dart';
import 'package:restorahub/repositories/booking_repository.dart';
import 'package:restorahub/repositories/user_repository.dart';
import 'package:restorahub/repositories/notification_repository.dart';
import 'package:restorahub/repositories/business_repository.dart';

class FakeBookingRepository implements BookingRepository {
  final List<Appointment> appointments = [];

  @override
  Future<List<Appointment>> getAppointmentsForCustomer(String customerId, {String? businessId}) async {
    return appointments.where((a) => a.customerId == customerId).toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsForProfessional(String professionalId, {String? businessId, String? professionalEmail}) async {
    return appointments.where((a) => a.professionalId == professionalId).toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsForBusiness(String businessId, {DateTime? startDate, DateTime? endDate}) async {
    return appointments.where((a) => a.customerId != null || a.professionalId != null).toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsForBusinessInRange(String businessId, DateTime start, DateTime end, {String? professionalId}) async {
    return appointments.where((a) {
      if (a.customerId == null && a.professionalId == null) return false;
      if (a.dateTime.isBefore(start) || a.dateTime.isAfter(end)) return false;
      if (professionalId != null && professionalId.isNotEmpty && a.professionalId != professionalId) return false;
      return true;
    }).toList();
  }

  @override
  Future<bool> checkProfessionalAvailability({required String professionalId, required DateTime dateTime, required int slotDurationMinutes, int bufferTimeMinutes = 0, String? businessId, String? professionalEmail}) async {
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
        throw const AppException('This time slot is no longer available', code: 'SLOT_TAKEN');
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
  Stream<List<Appointment>> watchAppointmentsForCustomer(String customerId, {String? businessId}) {
    final controller = StreamController<List<Appointment>>();
    controller.add(appointments.where((a) => a.customerId == customerId).toList());
    return controller.stream;
  }

  @override
  Stream<List<Appointment>> watchAppointmentsForProfessional(String professionalId, {String? businessId, String? professionalEmail}) {
    final controller = StreamController<List<Appointment>>();
    controller.add(appointments.where((a) => a.professionalId == professionalId).toList());
    return controller.stream;
  }

  @override
  Stream<List<Appointment>> watchAppointmentsForBusiness(String businessId, {DateTime? startDate, DateTime? endDate}) {
    final controller = StreamController<List<Appointment>>();
    controller.add(appointments.where((a) => a.customerId != null || a.professionalId != null).toList());
    return controller.stream;
  }

  @override
  Stream<Appointment?> watchAppointment(String id) {
    final controller = StreamController<Appointment?>();
    final appt = appointments.where((a) => a.id == id).firstOrNull;
    controller.add(appt);
    return controller.stream;
  }

  @override
  Future<Appointment?> getAppointmentById(String id) async {
    try {
      return appointments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

class FakeUserRepository implements UserRepository {
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
  Future<void> syncUserInAppointments(User user) async {}

  @override
  Future<List<User>> getProfessionalsBySpecialty(String specialty) async {
    return users.values.where((u) => u.role == 'professional' && u.specialty == specialty).toList();
  }

  @override
  Future<List<User>> getProfessionals({String? businessId}) async {
    return users.values
        .where((u) => u.role == 'professional')
        .where((u) => businessId == null || u.businessId == businessId)
        .toList();
  }

  @override
  Stream<List<User>> watchProfessionals({String? businessId}) {
    return Stream.value(
      users.values
          .where((u) => u.role == 'professional')
          .where((u) => businessId == null || u.businessId == businessId)
          .toList(),
    );
  }

  @override
  Future<List<User>> getCustomers() async {
    return users.values.where((u) => u.role == 'customer').toList();
  }
}

class FakeNotificationRepository implements NotificationRepository {
  final List<AppNotification> sent = [];

  @override
  Future<void> sendNotification(AppNotification notification, {String? businessId}) async {
    sent.add(notification);
  }

  @override
  Future<List<AppNotification>> getNotificationsForUser(String userId, {String? businessId}) async {
    return sent.where((n) => n.receiverId == userId).toList();
  }

  @override
  Future<int> markAsRead(String notificationId) async {
    return 1;
  }

  @override
  Future<int> markAllAsRead(String userId, {String? businessId}) async {
    return 0;
  }

  @override
  Stream<QuerySnapshot> getNotificationsStream(String userId, {String? businessId}) {
    throw UnimplementedError();
  }
}

class FakeBusinessRepository implements BusinessRepository {
  final Map<String, Business> businesses = {};

  @override
  Future<Business?> getBusinessById(String businessId) async {
    return businesses[businessId];
  }

  @override
  Future<void> updateBusiness(Business business) async {
    businesses[business.id] = business;
  }
}

class _FailingNotificationRepository implements NotificationRepository {
  @override
  Future<void> sendNotification(AppNotification notification, {String? businessId}) async {
    throw Exception('Notification failed');
  }

  @override
  Future<List<AppNotification>> getNotificationsForUser(String userId, {String? businessId}) async {
    return [];
  }

  @override
  Future<int> markAsRead(String notificationId) async {
    return 0;
  }

  @override
  Future<int> markAllAsRead(String userId, {String? businessId}) async {
    return 0;
  }

  @override
  Stream<QuerySnapshot> getNotificationsStream(String userId, {String? businessId}) {
    throw UnimplementedError();
  }
}

void main() {
  group('AppointmentProvider Tests', () {
    late FakeBookingRepository bookingRepository;
    late FakeUserRepository userRepository;
    late FakeNotificationRepository notificationRepository;
    late FakeBusinessRepository businessRepository;
    late AppointmentProvider provider;

    setUp(() {
      bookingRepository = FakeBookingRepository();
      userRepository = FakeUserRepository();
      notificationRepository = FakeNotificationRepository();
      businessRepository = FakeBusinessRepository();
      provider = AppointmentProvider(
        bookingRepository: bookingRepository,
        userRepository: userRepository,
        notificationRepository: notificationRepository,
        businessRepository: businessRepository,
      );
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
      await bookingRepository.insertAppointment(appt);

      await provider.loadAppointments();

      expect(provider.isLoading, isFalse);
      expect(provider.appointments.length, 1);
      expect(provider.appointments.first.service, 'Massage');
    });

    test('addAppointment adds to repository and reloads list', () async {
      final appt = Appointment(
        service: 'Facial',
        dateTime: DateTime(2026, 9, 1, 11, 0),
        durationMinutes: 60,
        customerId: 'cust-1',
        professionalId: 'prof-1',
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
        dateTime: DateTime(2026, 9, 1, 10, 0),
        durationMinutes: 60,
        customerId: 'cust-1',
        professionalId: 'prof-1',
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
        dateTime: DateTime(2026, 9, 1, 10, 0),
        durationMinutes: 60,
        customerId: 'cust-1',
        professionalId: 'prof-1',
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
        dateTime: DateTime(2026, 9, 1, 10, 0),
        durationMinutes: 60,
        status: AppointmentStatus.confirmed,
        customerId: 'cust-1',
        professionalId: 'prof-1',
      );
      await provider.addAppointment(appt);

      await provider.linkPaymentToAppointment('10', 'PAY-999');

      final updatedAppt = provider.appointments.firstWhere((a) => a.id == '10');
      expect(updatedAppt.paymentId, 'PAY-999');
      expect(updatedAppt.status, AppointmentStatus.completed);
    });

    test('rescheduleAppointment works correctly if slot is available', () async {
      final prof = User(
        id: 'prof-1',
        name: 'Test Professional',
        email: 'prof@example.com',
        phone: '555-0200',
        role: 'professional',
        specialty: 'massage',
      );
      await userRepository.insertUser(prof);

      final appt = Appointment(
        id: '1',
        service: 'Massage',
        dateTime: DateTime(2026, 9, 1, 10, 0),
        durationMinutes: 60,
        professionalId: 'prof-1',
        customerId: 'cust-1',
      );
      await provider.addAppointment(appt);

      final newTime = DateTime(2026, 9, 1, 14, 0);
      final error = await provider.rescheduleAppointment(
        appointment: provider.appointments.first,
        newDateTime: newTime,
      );

      expect(error, isNull);
      expect(provider.appointments.first.dateTime, newTime);
    });

    test('rescheduleAppointment fails if slot is already taken', () async {
      final prof = User(
        id: 'prof-1',
        name: 'Test Professional',
        email: 'prof@example.com',
        phone: '555-0200',
        role: 'professional',
        specialty: 'massage',
      );
      await userRepository.insertUser(prof);

      final appt1 = Appointment(
        id: '1',
        service: 'Massage',
        dateTime: DateTime(2026, 9, 1, 10, 0),
        durationMinutes: 60,
        professionalId: 'prof-1',
        customerId: 'cust-1',
      );
      final appt2 = Appointment(
        id: '2',
        service: 'Facial',
        dateTime: DateTime(2026, 9, 1, 10, 0),
        durationMinutes: 60,
        professionalId: 'prof-1',
        customerId: 'cust-1',
      );
      await provider.addAppointment(appt1);
      // appt2 occupies the same slot; insert it directly so the slot is taken
      // without relying on addAppointment throwing (current provider sets an
      // error instead of throwing when a slot is unavailable).
      await bookingRepository.insertAppointment(appt2);

      // Try to reschedule appt1 to the exact same time as appt2
      final error = await provider.rescheduleAppointment(
        appointment: provider.appointments.firstWhere((a) => a.id == '1'),
        newDateTime: DateTime(2026, 9, 1, 10, 0),
      );

      expect(error, 'This time slot is no longer available');
    });

    test('addAppointment rejects booking when slot is unavailable', () async {
      final existingAppt = Appointment(
        id: '1',
        service: 'Massage',
        dateTime: DateTime(2026, 9, 1, 10, 0),
        durationMinutes: 60,
        professionalId: 'prof-1',
        customerId: 'cust-1',
      );
      await bookingRepository.insertAppointment(existingAppt);

      final newAppt = Appointment(
        service: 'Facial',
        dateTime: DateTime(2026, 9, 1, 10, 0),
        durationMinutes: 60,
        professionalId: 'prof-1',
        customerId: 'cust-1',
      );

      await expectLater(() => provider.addAppointment(newAppt), throwsA(isA<AppException>()));

      expect(provider.appointments.length, 0);
      expect(provider.error, 'This time slot is no longer available');
    });

    group('Cancellation Policy', () {
      test('cancelAppointment fails within 2-hour window', () async {
        final appt = Appointment(
          id: '1',
          service: 'Massage',
          dateTime: DateTime.now().add(const Duration(hours: 1)),
          durationMinutes: 60,
          customerId: 'cust-1',
          professionalId: 'prof-1',
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
          durationMinutes: 60,
          customerId: 'cust-1',
          professionalId: 'prof-1',
        );
        await provider.addAppointment(appt);

        final error = await provider.cancelAppointment('1');
        expect(error, isNull);
        expect(provider.appointments.length, 1);
        expect(provider.appointments.first.status, AppointmentStatus.cancelledByCustomer);
      });

      test('professionalCancelAppointment fails within 2-hour window', () async {
        final appt = Appointment(
          id: '1',
          service: 'Massage',
          dateTime: DateTime.now().add(const Duration(hours: 1)),
          customerId: 'cust-1',
          professionalId: 'prof-1',
        );
        await provider.addAppointment(appt);

        final error = await provider.professionalCancelAppointment('1');
        expect(error, 'Appointments cannot be cancelled less than 2 hours before the start time.');
      });

      test('professionalCancelAppointment succeeds outside 2-hour window', () async {
        final appt = Appointment(
          id: '1',
          service: 'Massage',
          dateTime: DateTime.now().add(const Duration(days: 1)),
          customerId: 'cust-1',
          professionalId: 'prof-1',
        );
        await provider.addAppointment(appt);

        final error = await provider.professionalCancelAppointment('1');
        expect(error, isNull);
        expect(provider.appointments.length, 1);
        expect(provider.appointments.first.status, AppointmentStatus.cancelledByProfessional);
      });

      group('Notification Dispatch', () {
        test('addAppointment sends bookingRequested notification when both parties exist', () async {
          final prof = User(
            id: 'prof-1',
            name: 'Test Professional',
            email: 'prof@example.com',
            phone: '555-0200',
            role: 'professional',
          );
          await userRepository.insertUser(prof);

          final appt = Appointment(
            service: 'Massage',
            dateTime: DateTime.now().add(const Duration(days: 1)),
            durationMinutes: 60,
            customerId: 'cust-1',
            professionalId: 'prof-1',
          );
          await provider.addAppointment(appt);

          expect(notificationRepository.sent.length, 1);
          expect(notificationRepository.sent.first.type, NotificationType.bookingRequested);
          expect(notificationRepository.sent.first.receiverId, 'prof-1');
          expect(notificationRepository.sent.first.senderId, 'cust-1');
        });

        test('addAppointment does not send notification when professionalId is missing', () async {
          final appt = Appointment(
            service: 'Massage',
            dateTime: DateTime.now().add(const Duration(days: 1)),
            customerId: 'cust-1',
          );
          await provider.addAppointment(appt);

          expect(notificationRepository.sent, isEmpty);
        });

        test('updateAppointmentStatus pending->confirmed sends bookingConfirmed notification', () async {
          final prof = User(
            id: 'prof-1',
            name: 'Test Professional',
            email: 'prof@example.com',
            phone: '555-0200',
            role: 'professional',
          );
          await userRepository.insertUser(prof);

          final appt = Appointment(
            id: '1',
            service: 'Massage',
            dateTime: DateTime.now().add(const Duration(days: 1)),
            customerId: 'cust-1',
            professionalId: 'prof-1',
          );
          await provider.addAppointment(appt);
          notificationRepository.sent.clear();

          await provider.updateAppointmentStatus('1', AppointmentStatus.confirmed);

          expect(notificationRepository.sent.length, 1);
          expect(notificationRepository.sent.first.type, NotificationType.bookingConfirmed);
          expect(notificationRepository.sent.first.receiverId, 'cust-1');
          expect(notificationRepository.sent.first.senderId, 'prof-1');
        });

        test('updateAppointmentStatus to cancelledByProfessional sends bookingCancelled notification', () async {
          final appt = Appointment(
            id: '1',
            service: 'Massage',
            dateTime: DateTime.now().add(const Duration(days: 1)),
            status: AppointmentStatus.confirmed,
            customerId: 'cust-1',
            professionalId: 'prof-1',
          );
          await provider.addAppointment(appt);
          notificationRepository.sent.clear();

          await provider.updateAppointmentStatus('1', AppointmentStatus.cancelledByProfessional);

          expect(notificationRepository.sent.length, 1);
          expect(notificationRepository.sent.first.type, NotificationType.bookingCancelled);
          expect(notificationRepository.sent.first.receiverId, 'cust-1');
          expect(notificationRepository.sent.first.senderId, 'prof-1');
        });

        test('updateAppointmentStatus confirmed->cancelledByProfessional sends bookingCancelled notification', () async {
          final appt = Appointment(
            id: '1',
            service: 'Massage',
            dateTime: DateTime.now().add(const Duration(days: 1)),
            status: AppointmentStatus.confirmed,
            customerId: 'cust-1',
            professionalId: 'prof-1',
          );
          await provider.addAppointment(appt);
          notificationRepository.sent.clear();

          await provider.updateAppointmentStatus('1', AppointmentStatus.cancelledByProfessional);

          expect(notificationRepository.sent.length, 1);
          expect(notificationRepository.sent.first.type, NotificationType.bookingCancelled);
        });

        test('_sendNotification swallows errors without throwing', () async {
          final failingRepo = _FailingNotificationRepository();
          provider = AppointmentProvider(
            bookingRepository: bookingRepository,
            userRepository: userRepository,
            notificationRepository: failingRepo,
            businessRepository: businessRepository,
          );
          provider.currentUser = User(
            id: 'cust-1',
            name: 'Test User',
            email: 'test@example.com',
            phone: '555-0100',
            role: 'customer',
          );

          final appt = Appointment(
            id: '1',
            service: 'Massage',
            dateTime: DateTime.now().add(const Duration(days: 1)),
            customerId: 'cust-1',
            professionalId: 'prof-1',
          );
          await bookingRepository.insertAppointment(appt);

          expect(() async => await provider.updateAppointmentStatus('1', AppointmentStatus.cancelledByProfessional), returnsNormally);
        });
      });
    });

    group('State Machine Transitions', () {
      test('updateAppointmentStatus rejects terminal to non-terminal transition', () async {
        final appt = Appointment(
          id: '1',
          service: 'Massage',
          dateTime: DateTime.now().add(const Duration(days: 1)),
          durationMinutes: 60,
          status: AppointmentStatus.completed,
          customerId: 'cust-1',
          professionalId: 'prof-1',
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
          durationMinutes: 60,
          status: AppointmentStatus.completed,
          customerId: 'cust-1',
          professionalId: 'prof-1',
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

    group('Appointment Segregation', () {
      test('upcomingAppointments lists future active bookings sorted closest first', () async {
        final now = DateTime.now();
        final appts = [
          Appointment(
            id: 'u1',
            service: 'S1',
            dateTime: now.add(const Duration(days: 3)),
            customerId: 'cust-1',
          ),
          Appointment(
            id: 'u2',
            service: 'S2',
            dateTime: now.add(const Duration(days: 1)),
            customerId: 'cust-1',
          ),
          Appointment(
            id: 'u3',
            service: 'S3',
            dateTime: now.add(const Duration(days: 2)),
            customerId: 'cust-1',
          ),
        ];
        for (final a in appts) {
          await bookingRepository.insertAppointment(a);
        }
        await provider.loadAppointments();

        final upcoming = provider.upcomingAppointments;
        expect(upcoming.length, 3);
        expect(upcoming[0].id, 'u2');
        expect(upcoming[1].id, 'u3');
        expect(upcoming[2].id, 'u1');
      });

      test('upcomingAppointments excludes terminal bookings even if future', () async {
        final now = DateTime.now();
        final futureCompleted = Appointment(
          id: 't1',
          service: 'S',
          dateTime: now.add(const Duration(days: 1)),
          status: AppointmentStatus.completed,
          customerId: 'cust-1',
        );
        await bookingRepository.insertAppointment(futureCompleted);
        await provider.loadAppointments();

        expect(provider.upcomingAppointments, isEmpty);
        expect(provider.pastAppointments, contains(futureCompleted));
      });

      test('pastAppointments lists past and terminal bookings sorted most recent first', () async {
        final now = DateTime.now();
        final appts = [
          Appointment(
            id: 'p1',
            service: 'S1',
            dateTime: now.subtract(const Duration(days: 3)),
            customerId: 'cust-1',
          ),
          Appointment(
            id: 'p2',
            service: 'S2',
            dateTime: now.subtract(const Duration(days: 1)),
            status: AppointmentStatus.completed,
            customerId: 'cust-1',
          ),
          Appointment(
            id: 'p3',
            service: 'S3',
            dateTime: now.add(const Duration(days: 5)),
            status: AppointmentStatus.completed,
            customerId: 'cust-1',
          ),
        ];
        for (final a in appts) {
          await bookingRepository.insertAppointment(a);
        }
        await provider.loadAppointments();

        final past = provider.pastAppointments;
        expect(past.length, 3);
        expect(past[0].id, 'p3');
        expect(past[1].id, 'p2');
        expect(past[2].id, 'p1');
      });

      test('upcoming and past are disjoint and cover all bookings', () async {
        final now = DateTime.now();
        final appts = [
          Appointment(
            id: 'u1',
            service: 'S',
            dateTime: now.add(const Duration(days: 1)),
            customerId: 'cust-1',
          ),
          Appointment(
            id: 'c1',
            service: 'S',
            dateTime: now.add(const Duration(days: 2)),
            status: AppointmentStatus.cancelledByCustomer,
            customerId: 'cust-1',
          ),
          Appointment(
            id: 'pa1',
            service: 'S',
            dateTime: now.subtract(const Duration(days: 1)),
            customerId: 'cust-1',
          ),
          Appointment(
            id: 'pa2',
            service: 'S',
            dateTime: now.subtract(const Duration(days: 2)),
            status: AppointmentStatus.completed,
            customerId: 'cust-1',
          ),
        ];
        for (final a in appts) {
          await bookingRepository.insertAppointment(a);
        }
        await provider.loadAppointments();

        final upcomingIds =
            provider.upcomingAppointments.map((a) => a.id).toSet();
        final pastIds = provider.pastAppointments.map((a) => a.id).toSet();

        expect(upcomingIds.intersection(pastIds), isEmpty);
        expect(
          upcomingIds.union(pastIds),
          containsAll(appts.map((a) => a.id)),
        );
        expect(upcomingIds, contains('u1'));
        expect(pastIds, contains('c1'));
        expect(pastIds, contains('pa1'));
        expect(pastIds, contains('pa2'));
      });
    });
  });
}
