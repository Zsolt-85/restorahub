import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/models/notification.dart';
import 'package:restorahub/models/payment.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/pages/add_payment_page.dart';
import 'package:restorahub/providers/appointment_provider.dart';
import 'package:restorahub/providers/business_provider.dart';
import 'package:restorahub/providers/payment_provider.dart';
import 'package:restorahub/repositories/booking_repository.dart';
import 'package:restorahub/repositories/business_repository.dart';
import 'package:restorahub/repositories/notification_repository.dart';
import 'package:restorahub/repositories/payment_repository.dart';
import 'package:restorahub/repositories/user_repository.dart';

class FakeBookingRepository implements BookingRepository {
  @override
  Future<List<Appointment>> getAppointmentsForCustomer(String customerId,
          {String? businessId}) async =>
      [];

  @override
  Future<List<Appointment>> getAppointmentsForProfessional(
          String professionalId,
          {String? businessId,
          String? professionalEmail}) async =>
      [];

  @override
  Future<List<Appointment>> getAppointmentsForBusiness(String businessId,
          {DateTime? startDate,
          DateTime? endDate,
          int? limit,
          String? startAfterDocumentId}) async =>
      [];

  @override
  Future<List<Appointment>> getAppointmentsForBusinessInRange(
          String businessId, DateTime start, DateTime end,
          {String? professionalId}) async =>
      [];

  @override
  Future<bool> checkProfessionalAvailability(
          {required String professionalId,
          required DateTime dateTime,
          required int slotDurationMinutes,
          int bufferTimeMinutes = 0,
          String? businessId,
          String? professionalEmail}) async =>
      true;

  @override
  Future<String> createAppointmentAtomic(Appointment appointment) async =>
      'a1';

  @override
  Future<int> updateAppointment(Appointment appointment) async => 1;

  @override
  Future<int> deleteAppointment(String id) async => 1;

  @override
  Stream<List<Appointment>> watchAppointmentsForCustomer(String customerId,
          {String? businessId}) =>
      Stream.value([]);

  @override
  Stream<List<Appointment>> watchAppointmentsForProfessional(
          String professionalId,
          {String? businessId,
          String? professionalEmail}) =>
      Stream.value([]);

  @override
  Stream<List<Appointment>> watchAppointmentsForBusiness(String businessId,
          {DateTime? startDate, DateTime? endDate}) =>
      Stream.value([]);

  @override
  Future<Appointment?> getAppointmentById(String id) async => null;
}

class FakeUserRepository implements UserRepository {
  @override
  Future<User?> getUserById(String id) async => null;

  @override
  Future<bool> isEmailTaken(String email, {String? excludeUserId}) async =>
      false;

  @override
  Future<int> insertUser(User user) async => 1;

  @override
  Future<int> updateUser(User user) async => 1;

  @override
  Future<void> syncUserInAppointments(User user) async {}

  @override
  Future<List<User>> getProfessionalsByCategory(String category,
          {String? businessId}) async =>
      [];

  @override
  Future<List<User>> getProfessionals({String? businessId}) async => [];

  @override
  Future<List<User>> getProfessionalsByBusiness(String businessId) async => [];

  @override
  Future<List<User>> getCustomers({String? businessId}) async => [];
}

class FakeNotificationRepository implements NotificationRepository {
  @override
  Future<void> sendNotification(AppNotification notification,
          {String? businessId}) async {}

  @override
  Future<List<AppNotification>> getNotificationsForUser(String userId,
          {String? businessId}) async =>
      [];

  @override
  Future<int> markAsRead(String notificationId) async => 1;

  @override
  Future<int> markAllAsRead(String userId, {String? businessId}) async => 0;

  @override
  Stream<List<AppNotification>> watchNotifications(String userId,
          {String? businessId}) =>
      Stream.value([]);
}

class FakeBusinessRepository implements BusinessRepository {
  @override
  Future<Business?> getBusinessById(String businessId) async => null;

  @override
  Future<void> updateBusiness(Business business) async {}
}

class FakePaymentRepository implements PaymentRepository {
  @override
  Future<Payment?> getPaymentByAppointment(String appointmentId,
          {String? businessId}) async =>
      null;

  @override
  Future<List<Payment>> getPaymentsByProfessional(String professionalId,
          {String? businessId}) async =>
      [];

  @override
  Future<List<Payment>> getPaymentsByProfessionalInRange(
          String? professionalId, DateTime start, DateTime end,
          {String? businessId}) async =>
      [];

  @override
  Future<String> recordPayment(Payment payment) async => 'pay-1';

  @override
  Future<int> updatePayment(Payment payment) async => 0;

  @override
  Future<int> updatePaymentStatus(
          String paymentId, PaymentStatus status) async =>
      0;
}

Appointment _appointment() => Appointment(
      id: 'a1',
      service: 'Massage',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      durationMinutes: 60,
      customerId: 'cust-1',
      customerName: 'Customer',
      professionalId: 'prof-1',
      professionalName: 'Pro',
      businessId: 'biz-1',
    );

Future<void> _pumpPage(
  WidgetTester tester, {
  BusinessSettings? settings,
}) async {
  final businessProvider = BusinessProvider()
    ..setBusiness(Business(id: 'biz-1', name: 'Biz', settings: settings));
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppointmentProvider>(
          create: (_) => AppointmentProvider(
            bookingRepository: FakeBookingRepository(),
            userRepository: FakeUserRepository(),
            notificationRepository: FakeNotificationRepository(),
            businessRepository: FakeBusinessRepository(),
          ),
        ),
        ChangeNotifierProvider<BusinessProvider>.value(
            value: businessProvider),
        ChangeNotifierProvider<PaymentProvider>(
          create: (_) =>
              PaymentProvider(repository: FakePaymentRepository()),
        ),
      ],
      child: MaterialApp(home: AddPaymentPage(appointment: _appointment())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AddPaymentPage deposit policy', () {
    testWidgets('prefills deposit from business policy', (tester) async {
      await _pumpPage(
        tester,
        settings: BusinessSettings(
            depositRequired: true, depositPercent: 10.0),
      );

      await tester.enterText(find.byType(TextFormField).first, '100');
      await tester.pump();

      final depositField = tester.widget<TextFormField>(
          find.byType(TextFormField).at(1));
      expect(depositField.controller?.text, '10.00');
    });

    testWidgets('leaves deposit empty without a policy', (tester) async {
      await _pumpPage(tester);

      await tester.enterText(find.byType(TextFormField).first, '100');
      await tester.pump();

      final depositField = tester.widget<TextFormField>(
          find.byType(TextFormField).at(1));
      expect(depositField.controller?.text ?? '', isEmpty);
    });

    testWidgets('never overwrites a staff-entered deposit', (tester) async {
      await _pumpPage(
        tester,
        settings: BusinessSettings(
            depositRequired: true, depositPercent: 10.0),
      );

      await tester.enterText(find.byType(TextFormField).at(1), '5');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).first, '100');
      await tester.pump();

      final depositField = tester.widget<TextFormField>(
          find.byType(TextFormField).at(1));
      expect(depositField.controller?.text, '5');
    });
  });
}
