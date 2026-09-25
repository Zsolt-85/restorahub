import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:restorahub/helpers/appointment_actions.dart';
import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/models/notification.dart';
import 'package:restorahub/models/payment.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/providers/appointment_provider.dart';
import 'package:restorahub/providers/business_provider.dart';
import 'package:restorahub/providers/payment_provider.dart';
import 'package:restorahub/repositories/booking_repository.dart';
import 'package:restorahub/repositories/business_repository.dart';
import 'package:restorahub/repositories/payment_repository.dart';
import 'package:restorahub/repositories/notification_repository.dart';
import 'package:restorahub/repositories/user_repository.dart';

class FakeBookingRepository implements BookingRepository {
  final List<Appointment> appointments = [];

  @override
  Future<List<Appointment>> getAppointmentsForCustomer(String customerId,
          {String? businessId}) async =>
      appointments.where((a) => a.customerId == customerId).toList();

  @override
  Future<List<Appointment>> getAppointmentsForProfessional(
          String professionalId,
          {String? businessId,
          String? professionalEmail}) async =>
      appointments.where((a) => a.professionalId == professionalId).toList();

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
  Future<String> createAppointmentAtomic(Appointment appointment) async {
    final stored = appointment.copyWith(id: 'a1');
    appointments.add(stored);
    return stored.id!;
  }

  @override
  Future<int> updateAppointment(Appointment appointment) async {
    final idx = appointments.indexWhere((a) => a.id == appointment.id);
    if (idx != -1) appointments[idx] = appointment;
    return 1;
  }

  @override
  Future<int> deleteAppointment(String id) async => 0;

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

Appointment _appointment() => Appointment(
      id: 'a1',
      service: 'Massage',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      durationMinutes: 60,
      customerId: 'cust-1',
      professionalId: 'prof-1',
    );

Future<void> _pumpActionHarness(
  WidgetTester tester,
  AppointmentProvider provider,
  Appointment appointment,
  Future<void> Function(BuildContext) action,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppointmentProvider>.value(
      value: provider,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => action(context),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pump();
}

void main() {
  group('AppointmentActions.confirmCancel', () {
    late FakeBookingRepository bookingRepository;
    late AppointmentProvider provider;

    setUp(() {
      bookingRepository = FakeBookingRepository();
      provider = AppointmentProvider(
        bookingRepository: bookingRepository,
        userRepository: FakeUserRepository(),
        notificationRepository: FakeNotificationRepository(),
        businessRepository: FakeBusinessRepository(),
      );
      provider.currentUser = User(
        id: 'cust-1',
        name: 'Customer',
        email: 'cust@test.com',
        phone: '555-0100',
        role: 'customer',
      );
    });

    testWidgets('confirming cancels the booking with feedback', (tester) async {
      bookingRepository.appointments.add(_appointment());
      await provider.loadAppointments();

      await _pumpActionHarness(
          tester,
          provider,
          _appointment(),
          (context) =>
              AppointmentActions.confirmCancel(context, _appointment()));
      await tester.tap(find.widgetWithText(TextButton, 'Cancel booking'));
      await tester.pumpAndSettle();

      expect(bookingRepository.appointments.first.status,
          AppointmentStatus.cancelledByCustomer);
      expect(find.text('Booking cancelled'), findsOneWidget);
    });

    testWidgets('keeping leaves the booking untouched', (tester) async {
      bookingRepository.appointments.add(_appointment());
      await provider.loadAppointments();

      await _pumpActionHarness(
          tester,
          provider,
          _appointment(),
          (context) =>
              AppointmentActions.confirmCancel(context, _appointment()));
      await tester.tap(find.text('Keep booking'));
      await tester.pumpAndSettle();

      expect(bookingRepository.appointments.first.status,
          AppointmentStatus.pending);
      expect(find.text('Booking cancelled'), findsNothing);
    });
  });

  group('AppointmentActions.markNoShow', () {
    late FakeBookingRepository bookingRepository;
    late AppointmentProvider appointmentProvider;
    late BusinessProvider businessProvider;
    late FakePaymentRepository paymentRepository;
    late PaymentProvider paymentProvider;

    Appointment pastConfirmed() => Appointment(
          id: 'ns1',
          service: 'Massage',
          dateTime: DateTime.now().subtract(const Duration(days: 1)),
          durationMinutes: 60,
          status: AppointmentStatus.confirmed,
          customerId: 'cust-1',
          professionalId: 'prof-1',
          businessId: 'biz-1',
        );

    setUp(() {
      bookingRepository = FakeBookingRepository();
      paymentRepository = FakePaymentRepository();
      appointmentProvider = AppointmentProvider(
        bookingRepository: bookingRepository,
        userRepository: FakeUserRepository(),
        notificationRepository: FakeNotificationRepository(),
        businessRepository: FakeBusinessRepository(),
      );
      appointmentProvider.currentUser = User(
        id: 'prof-1',
        name: 'Pro',
        email: 'prof@test.com',
        phone: '555',
        role: 'staff',
        businessId: 'biz-1',
      );
      businessProvider = BusinessProvider()
        ..setBusiness(Business(
          id: 'biz-1',
          name: 'Biz',
          settings: BusinessSettings(noShowFeeAmount: 25.0),
        ));
      paymentProvider = PaymentProvider(repository: paymentRepository);
    });

    Future<void> pumpNoShow(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppointmentProvider>.value(
                value: appointmentProvider),
            ChangeNotifierProvider<BusinessProvider>.value(
                value: businessProvider),
            ChangeNotifierProvider<PaymentProvider>.value(
                value: paymentProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => AppointmentActions.markNoShow(
                      context, pastConfirmed()),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    }

    testWidgets('records no-show plus pending fee payment', (tester) async {
      bookingRepository.appointments.add(pastConfirmed());
      await appointmentProvider.loadAppointments();

      await pumpNoShow(tester);

      expect(bookingRepository.appointments.first.status,
          AppointmentStatus.noShow);
      expect(paymentRepository.payments.length, 1);
      expect(paymentRepository.payments.first.amount, 25.0);
      expect(paymentRepository.payments.first.status, PaymentStatus.pending);
      expect(paymentRepository.payments.first.noShowFee, 25.0);
      expect(find.text('Marked as no-show'), findsOneWidget);
    });

    testWidgets('skips fee payment when none configured', (tester) async {
      businessProvider.setBusiness(Business(id: 'biz-1', name: 'Biz'));
      bookingRepository.appointments.add(pastConfirmed());
      await appointmentProvider.loadAppointments();

      await pumpNoShow(tester);

      expect(bookingRepository.appointments.first.status,
          AppointmentStatus.noShow);
      expect(paymentRepository.payments, isEmpty);
      expect(find.text('Marked as no-show'), findsOneWidget);
    });
  });
}

class FakePaymentRepository implements PaymentRepository {
  final List<Payment> payments = [];

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
  Future<String> recordPayment(Payment payment) async {
    final stored = payment.copyWith(id: 'pay-1');
    payments.add(stored);
    return stored.id!;
  }

  @override
  Future<int> updatePayment(Payment payment) async => 0;

  @override
  Future<int> updatePaymentStatus(
          String paymentId, PaymentStatus status) async =>
      0;
}
