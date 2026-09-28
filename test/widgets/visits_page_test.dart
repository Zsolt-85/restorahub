import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:restorahub/constants/routes.dart';
import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/models/notification.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/pages/visits_page.dart';
import 'package:restorahub/providers/appointment_provider.dart';
import 'package:restorahub/repositories/booking_repository.dart';
import 'package:restorahub/repositories/business_repository.dart';
import 'package:restorahub/repositories/notification_repository.dart';
import 'package:restorahub/repositories/user_repository.dart';

class FakeBookingRepository implements BookingRepository {
  final List<Appointment> appointments = [];

  /// Test-only seeding (mirrors appointment_provider_test pattern).
  Future<void> seedAppointment(Appointment appointment) async {
    appointments.add(appointment);
  }

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
  Future<String> createAppointmentAtomic(Appointment appointment) async =>
      'a1';

  @override
  Future<int> updateAppointment(Appointment appointment) async => 0;

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

User _customer() => User(
      id: 'cust-1',
      name: 'Customer',
      email: 'cust@test.com',
      phone: '555',
      role: 'customer',
    );

Future<AppointmentProvider> _providerWith(List<Appointment> seed) async {
  final repo = FakeBookingRepository();
  for (final a in seed) {
    await repo.seedAppointment(a);
  }
  final provider = AppointmentProvider(
    bookingRepository: repo,
    userRepository: FakeUserRepository(),
    notificationRepository: FakeNotificationRepository(),
    businessRepository: FakeBusinessRepository(),
  );
  provider.currentUser = _customer();
  await provider.loadAppointments();
  return provider;
}

Future<void> _pumpVisits(
  WidgetTester tester,
  AppointmentProvider provider,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppointmentProvider>.value(value: provider),
      ],
      child: MaterialApp(
        routes: {
          Routes.pastAppointments: (_) =>
              const Scaffold(body: Text('history-dest')),
        },
        home: const Scaffold(body: VisitsPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('VisitsPage', () {
    testWidgets('shows upcoming service and history link', (tester) async {
      final provider = await _providerWith([
        Appointment(
          id: 'v1',
          service: 'Massage',
          dateTime: DateTime.now().add(const Duration(days: 1)),
          durationMinutes: 60,
          customerId: 'cust-1',
          professionalId: 'prof-1',
        ),
      ]);
      await _pumpVisits(tester, provider);

      expect(find.text('Massage'), findsOneWidget);
      expect(find.text('View history'), findsOneWidget);
    });

    testWidgets('tapping history pushes pastAppointments route',
        (tester) async {
      final provider = await _providerWith([
        Appointment(
          id: 'v1',
          service: 'Massage',
          dateTime: DateTime.now().add(const Duration(days: 1)),
          durationMinutes: 60,
          customerId: 'cust-1',
          professionalId: 'prof-1',
        ),
      ]);
      await _pumpVisits(tester, provider);

      await tester.tap(find.text('View history'));
      await tester.pumpAndSettle();

      expect(find.text('history-dest'), findsOneWidget);
    });

    testWidgets('empty state offers booking', (tester) async {
      final provider = await _providerWith([]);
      await _pumpVisits(tester, provider);

      expect(find.text('No upcoming visits'), findsOneWidget);
      expect(find.text('Book now'), findsOneWidget);
    });
  });
}
