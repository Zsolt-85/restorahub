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
        Appointment(
            id: '1',
            service: 'Massage',
            dateTime: DateTime(2026, 8, 1, 10, 0),
            status: AppointmentStatus.pending),
        Appointment(
            id: '2',
            service: 'Facial',
            dateTime: DateTime(2026, 8, 1, 11, 0),
            status: AppointmentStatus.confirmed),
        Appointment(
            id: '3',
            service: 'Spa',
            dateTime: DateTime(2026, 8, 1, 12, 0),
            status: AppointmentStatus.completed),
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

    test('aggregate counts each paid booking once (payment wins over price)',
        () {
      final appointments = [
        Appointment(
            id: '1',
            service: 'Massage',
            dateTime: DateTime(2026, 8, 1, 10, 0),
            status: AppointmentStatus.completed,
            price: 50.0,
            professionalId: 'p1'),
        Appointment(
            id: '2',
            service: 'Facial',
            dateTime: DateTime(2026, 8, 1, 11, 0),
            status: AppointmentStatus.completed,
            price: 80.0,
            professionalId: 'p2'),
      ];

      final payments = [
        Payment(
            id: 'pay1',
            appointmentId: '1',
            amount: 50.0,
            professionalId: 'p1',
            status: PaymentStatus.completed,
            customerId: 'c1',
            customerName: 'C',
            customerPhone: '555',
            customerEmail: 'c@t.com',
            professionalName: 'P',
            professionalPhone: '555',
            professionalEmail: 'p@t.com',
            service: 'S',
            staffCategory: 'cat',
            appointmentDate: DateTime(2026, 8, 1),
            appointmentTime: '10:00',
            appointmentDurationMinutes: 60),
      ];

      final metrics = AnalyticsService.aggregate(
        appointments: appointments,
        payments: payments,
        staff: const [],
      );

      // Booking 1 paid 50 (price ignored, not added); booking 2 unpaid (80).
      expect(metrics.revenueEstimate, 130.0);
    });

    test('aggregate counts collected cash, not booked totals', () {
      final appointments = [
        Appointment(
            id: '1',
            service: 'Massage',
            dateTime: DateTime(2026, 8, 1, 10, 0),
            status: AppointmentStatus.completed,
            price: 100.0,
            professionalId: 'p1'),
      ];
      final payments = [
        Payment(
            id: 'pay1',
            appointmentId: '1',
            amount: 100.0,
            depositAmount: 30.0,
            professionalId: 'p1',
            status: PaymentStatus.completed,
            customerId: 'c1',
            customerName: 'C',
            customerPhone: '555',
            customerEmail: 'c@t.com',
            professionalName: 'P',
            professionalPhone: '555',
            professionalEmail: 'p@t.com',
            service: 'S',
            staffCategory: 'cat',
            appointmentDate: DateTime(2026, 8, 1),
            appointmentTime: '10:00',
            appointmentDurationMinutes: 60),
      ];

      final metrics = AnalyticsService.aggregate(
        appointments: appointments,
        payments: payments,
        staff: const [],
      );

      // Only the 30 deposit has been collected so far.
      expect(metrics.revenueEstimate, 30.0);
    });

    test('collectedFor counts deposits, not booked totals', () {
      Payment build(double amount, double deposit) => Payment(
            appointmentId: 'a1',
            amount: amount,
            depositAmount: deposit,
            professionalId: 'p1',
            status: PaymentStatus.completed,
            customerId: 'c1',
            customerName: 'C',
            customerPhone: '555',
            customerEmail: 'c@t.com',
            professionalName: 'P',
            professionalPhone: '555',
            professionalEmail: 'p@t.com',
            service: 'S',
            staffCategory: 'cat',
            appointmentDate: DateTime(2026, 8, 1),
            appointmentTime: '10:00',
            appointmentDurationMinutes: 60,
          );

      expect(AnalyticsService.collectedFor(build(100.0, 30.0)), 30.0);
      expect(AnalyticsService.collectedFor(build(100.0, 0.0)), 100.0);
    });

    test('aggregate ignores pending payments and non-completed prices', () {
      final appointments = [
        Appointment(
            id: '1',
            service: 'Massage',
            dateTime: DateTime(2026, 8, 1, 10, 0),
            status: AppointmentStatus.pending,
            price: 50.0,
            professionalId: 'p1'),
      ];
      final payments = [
        Payment(
            id: 'pay1',
            appointmentId: '1',
            amount: 50.0,
            professionalId: 'p1',
            status: PaymentStatus.pending,
            customerId: 'c1',
            customerName: 'C',
            customerPhone: '555',
            customerEmail: 'c@t.com',
            professionalName: 'P',
            professionalPhone: '555',
            professionalEmail: 'p@t.com',
            service: 'S',
            staffCategory: 'cat',
            appointmentDate: DateTime(2026, 8, 1),
            appointmentTime: '10:00',
            appointmentDurationMinutes: 60),
      ];

      final metrics = AnalyticsService.aggregate(
        appointments: appointments,
        payments: payments,
        staff: const [],
      );

      expect(metrics.revenueEstimate, 0.0);
    });

    test('aggregate counts orphan payments outside the appointment range', () {
      final payments = [
        Payment(
            id: 'pay9',
            appointmentId: 'old-9',
            amount: 70.0,
            professionalId: 'p1',
            status: PaymentStatus.completed,
            customerId: 'c1',
            customerName: 'C',
            customerPhone: '555',
            customerEmail: 'c@t.com',
            professionalName: 'P',
            professionalPhone: '555',
            professionalEmail: 'p@t.com',
            service: 'S',
            staffCategory: 'cat',
            appointmentDate: DateTime(2026, 7, 1),
            appointmentTime: '10:00',
            appointmentDurationMinutes: 60),
      ];

      final metrics = AnalyticsService.aggregate(
        appointments: const [],
        payments: payments,
        staff: const [],
      );

      expect(metrics.revenueEstimate, 70.0);
    });

    test('aggregate scopes records by businessId when provided', () {
      Appointment appt(String id, String? businessId) => Appointment(
            id: id,
            service: 'S',
            dateTime: DateTime(2026, 8, 1, 10, 0),
            status: AppointmentStatus.completed,
            price: 100.0,
            professionalId: 'p1',
            businessId: businessId,
          );
      Payment pay(String id, String appointmentId, String? businessId) =>
          Payment(
            id: id,
            appointmentId: appointmentId,
            amount: 100.0,
            professionalId: 'p1',
            status: PaymentStatus.completed,
            customerId: 'c1',
            customerName: 'C',
            customerPhone: '555',
            customerEmail: 'c@t.com',
            professionalName: 'P',
            professionalPhone: '555',
            professionalEmail: 'p@t.com',
            service: 'S',
            staffCategory: 'cat',
            businessId: businessId,
            appointmentDate: DateTime(2026, 8, 1),
            appointmentTime: '10:00',
            appointmentDurationMinutes: 60,
          );

      final metrics = AnalyticsService.aggregate(
        appointments: [appt('1', 'biz-a'), appt('2', 'biz-b')],
        payments: [pay('pay1', '1', 'biz-a'), pay('pay2', '2', 'biz-b')],
        staff: const [],
        businessId: 'biz-a',
      );

      expect(metrics.totalBookings, 1);
      expect(metrics.revenueEstimate, 100.0);
    });

    test('weeklyCapacityFor derives slots from member schedule', () {
      // Defaults 09:00-17:00 at 60min slots: 8/day x 5 days = 40.
      final defaults = User(
        id: 'p1',
        name: 'A',
        email: 'a@t.com',
        phone: '1',
        role: 'staff',
      );
      expect(AnalyticsService.weeklyCapacityFor(defaults), 40);

      final partTime = User(
        id: 'p2',
        name: 'B',
        email: 'b@t.com',
        phone: '2',
        role: 'staff',
        workStartTime: '10:00',
        workEndTime: '12:00',
        slotDurationMinutes: 30,
      );
      expect(AnalyticsService.weeklyCapacityFor(partTime), 20);

      final broken = User(
        id: 'p3',
        name: 'C',
        email: 'c@t.com',
        phone: '3',
        role: 'staff',
        workStartTime: 'nonsense',
        workEndTime: '17:00',
      );
      expect(AnalyticsService.weeklyCapacityFor(broken),
          AnalyticsService.fallbackWeeklySlotsPerStaff);
    });

    test('aggregate uses derived capacities for utilization', () {
      final staff = [
        User(
            id: 'p1',
            name: 'A',
            email: 'a@t.com',
            phone: '1',
            role: 'staff',
            workStartTime: '10:00',
            workEndTime: '12:00',
            slotDurationMinutes: 30),
      ];
      final appointments = [
        Appointment(
            id: '1',
            service: 'S',
            dateTime: DateTime(2026, 8, 1, 10, 0),
            status: AppointmentStatus.completed,
            professionalId: 'p1'),
        Appointment(
            id: '2',
            service: 'S',
            dateTime: DateTime(2026, 8, 1, 11, 0),
            status: AppointmentStatus.completed,
            professionalId: 'p1'),
      ];

      final metrics = AnalyticsService.aggregate(
        appointments: appointments,
        payments: const [],
        staff: staff,
      );

      // 2 bookings against a 20-slot week.
      expect(metrics.staffUtilization['p1'], closeTo(2 / 20.0, 0.001));
      expect(metrics.staffUtilization['overall'], closeTo(2 / 20.0, 0.001));
    });

    test('aggregate computes peak hours', () {
      final appointments = [
        Appointment(
            id: '1',
            service: 'Massage',
            dateTime: DateTime(2026, 8, 1, 9, 0),
            status: AppointmentStatus.pending),
        Appointment(
            id: '2',
            service: 'Facial',
            dateTime: DateTime(2026, 8, 1, 9, 30),
            status: AppointmentStatus.confirmed),
        Appointment(
            id: '3',
            service: 'Spa',
            dateTime: DateTime(2026, 8, 1, 14, 0),
            status: AppointmentStatus.completed),
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
        User(
            id: 'p1',
            name: 'Alice',
            email: 'alice@test.com',
            phone: '5551111',
            role: 'professional'),
        User(
            id: 'p2',
            name: 'Bob',
            email: 'bob@test.com',
            phone: '5552222',
            role: 'professional'),
      ];

      final appointments = [
        Appointment(
            id: '1',
            service: 'Massage',
            dateTime: DateTime(2026, 8, 1, 10, 0),
            status: AppointmentStatus.completed,
            professionalId: 'p1'),
        Appointment(
            id: '2',
            service: 'Facial',
            dateTime: DateTime(2026, 8, 1, 11, 0),
            status: AppointmentStatus.completed,
            professionalId: 'p1'),
        Appointment(
            id: '3',
            service: 'Spa',
            dateTime: DateTime(2026, 8, 1, 12, 0),
            status: AppointmentStatus.cancelledByCustomer,
            professionalId: 'p2'),
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
        Appointment(
            id: '1',
            service: 'Massage',
            dateTime: DateTime(2026, 8, 1, 10, 0),
            status: AppointmentStatus.cancelledByCustomer),
        Appointment(
            id: '2',
            service: 'Facial',
            dateTime: DateTime(2026, 8, 1, 11, 0),
            status: AppointmentStatus.cancelledByProfessional),
        Appointment(
            id: '3',
            service: 'Spa',
            dateTime: DateTime(2026, 8, 1, 12, 0),
            status: AppointmentStatus.noShow),
        Appointment(
            id: '4',
            service: 'Haircut',
            dateTime: DateTime(2026, 8, 1, 13, 0),
            status: AppointmentStatus.pending),
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
