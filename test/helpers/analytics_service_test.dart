import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/helpers/analytics_service.dart';
import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/payment.dart';
import 'package:restorahub/models/user.dart';

void main() {
  group('AnalyticsService', () {
    test('aggregate returns zero metrics for empty inputs', () {
      final metrics = AnalyticsService.aggregate(
        appointments: const [],
        payments: const [],
        staff: const [],
      );

      expect(metrics.totalBookings, 0);
      expect(metrics.revenueEstimate, 0.0);
      expect(metrics.peakHours, isEmpty);
      expect(metrics.completedBookings, 0);
      expect(metrics.cancelledBookings, 0);
      expect(metrics.noShowBookings, 0);
      expect(metrics.completionRate, 0.0);
      expect(metrics.cancellationRate, 0.0);
    });

    test('aggregate counts total bookings', () {
      final appointments = [
        Appointment(id: '1', service: 'Massage', dateTime: DateTime(2026, 8, 1, 10, 0), status: AppointmentStatus.pending),
        Appointment(id: '2', service: 'Facial', dateTime: DateTime(2026, 8, 1, 11, 0), status: AppointmentStatus.confirmed),
        Appointment(id: '3', service: 'Spa', dateTime: DateTime(2026, 8, 1, 12, 0), status: AppointmentStatus.completed),
      ];

      final metrics = AnalyticsService.aggregate(
        appointments: appointments,
        payments: const [],
        staff: const [],
      );

      expect(metrics.totalBookings, 3);
      expect(metrics.completedBookings, 1);
      expect(metrics.cancellationRate, 0.0);
      expect(metrics.completionRate, 1 / 3);
    });

    test('aggregate computes revenue from appointments and payments', () {
      final appointments = [
        Appointment(id: '1', service: 'Massage', dateTime: DateTime(2026, 8, 1, 10, 0), status: AppointmentStatus.completed, price: 50.0, professionalId: 'p1'),
        Appointment(id: '2', service: 'Facial', dateTime: DateTime(2026, 8, 1, 11, 0), status: AppointmentStatus.completed, price: 80.0, professionalId: 'p2'),
      ];

      final payments = [
        Payment(id: 'pay1', appointmentId: '1', amount: 50.0, professionalId: 'p1', status: PaymentStatus.completed, customerId: 'c1', customerName: 'C', customerPhone: '555', customerEmail: 'c@t.com', professionalName: 'P', professionalPhone: '555', professionalEmail: 'p@t.com', service: 'S', staffCategory: 'cat', appointmentDate: DateTime(2026, 8, 1), appointmentTime: '10:00', appointmentDurationMinutes: 60),
      ];

      final metrics = AnalyticsService.aggregate(
        appointments: appointments,
        payments: payments,
        staff: const [],
      );

      expect(metrics.revenueEstimate, 180.0);
    });

    test('aggregate computes peak hours', () {
      final appointments = [
        Appointment(id: '1', service: 'Massage', dateTime: DateTime(2026, 8, 1, 9, 0), status: AppointmentStatus.pending),
        Appointment(id: '2', service: 'Facial', dateTime: DateTime(2026, 8, 1, 9, 30), status: AppointmentStatus.confirmed),
        Appointment(id: '3', service: 'Spa', dateTime: DateTime(2026, 8, 1, 14, 0), status: AppointmentStatus.completed),
      ];

      final metrics = AnalyticsService.aggregate(
        appointments: appointments,
        payments: const [],
        staff: const [],
      );

      expect(metrics.peakHours[9], 2);
      expect(metrics.peakHours[14], 1);
    });

    test('aggregate computes staff utilization', () {
      final staff = [
        User(id: 'p1', name: 'Alice', email: 'alice@test.com', phone: '5551111', role: 'professional'),
        User(id: 'p2', name: 'Bob', email: 'bob@test.com', phone: '5552222', role: 'professional'),
      ];

      final appointments = [
        Appointment(id: '1', service: 'Massage', dateTime: DateTime(2026, 8, 1, 10, 0), status: AppointmentStatus.completed, professionalId: 'p1'),
        Appointment(id: '2', service: 'Facial', dateTime: DateTime(2026, 8, 1, 11, 0), status: AppointmentStatus.completed, professionalId: 'p1'),
        Appointment(id: '3', service: 'Spa', dateTime: DateTime(2026, 8, 1, 12, 0), status: AppointmentStatus.cancelledByCustomer, professionalId: 'p2'),
      ];

      final metrics = AnalyticsService.aggregate(
        appointments: appointments,
        payments: const [],
        staff: staff,
      );

      expect(metrics.staffUtilization['p1'], closeTo(2 / 40.0, 0.001));
      expect(metrics.staffUtilization['p2'], closeTo(0 / 40.0, 0.001));
      expect(metrics.staffUtilization['overall'], closeTo(2 / 80.0, 0.001));
    });

    test('aggregate counts cancelled and noShow', () {
      final appointments = [
        Appointment(id: '1', service: 'Massage', dateTime: DateTime(2026, 8, 1, 10, 0), status: AppointmentStatus.cancelledByCustomer),
        Appointment(id: '2', service: 'Facial', dateTime: DateTime(2026, 8, 1, 11, 0), status: AppointmentStatus.cancelledByProfessional),
        Appointment(id: '3', service: 'Spa', dateTime: DateTime(2026, 8, 1, 12, 0), status: AppointmentStatus.noShow),
        Appointment(id: '4', service: 'Haircut', dateTime: DateTime(2026, 8, 1, 13, 0), status: AppointmentStatus.pending),
      ];

      final metrics = AnalyticsService.aggregate(
        appointments: appointments,
        payments: const [],
        staff: const [],
      );

      expect(metrics.cancelledBookings, 2);
      expect(metrics.noShowBookings, 1);
      expect(metrics.cancellationRate, 2 / 4);
    });
  });
}
