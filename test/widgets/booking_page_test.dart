import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/models/notification.dart';
import 'package:restorahub/models/service.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/pages/booking_page.dart';
import 'package:restorahub/providers/appointment_provider.dart';
import 'package:restorahub/providers/auth_provider.dart';
import 'package:restorahub/providers/business_provider.dart';
import 'package:restorahub/providers/service_provider.dart';
import 'package:restorahub/repositories/booking_repository.dart';
import 'package:restorahub/repositories/business_repository.dart';
import 'package:restorahub/repositories/notification_repository.dart';
import 'package:restorahub/repositories/service_repository.dart';
import 'package:restorahub/repositories/staff_directory_repository.dart';
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

class FakeServiceRepository implements ServiceRepository {
  final bool failStream;
  final List<Service> services;

  FakeServiceRepository({this.failStream = false, this.services = const []});

  @override
  Future<List<Service>> getServices({String? businessId}) async => services;

  @override
  Stream<List<Service>> watchServices({String? businessId}) =>
      failStream ? Stream.error(Exception('stream failed')) : Stream.value(services);

  @override
  Future<void> createService(Service service) async {}

  @override
  Future<void> updateService(Service service) async {}

  @override
  Future<void> deleteService(String id) async {}
}

class FakeStaffDirectoryRepository implements StaffDirectoryRepository {
  final List<User> entries;

  FakeStaffDirectoryRepository(this.entries);

  @override
  Future<void> upsertEntry(User user) async {}

  @override
  Future<User?> getEntryById(String id) async =>
      entries.where((u) => u.id == id).cast<User?>().firstOrNull;

  @override
  Future<List<User>> getStaff({String? businessId, String? category}) async =>
      entries
          .where((u) =>
              (businessId == null || u.businessId == businessId) &&
              (category == null || u.category == category))
          .toList();

  @override
  Stream<List<User>> watchStaff({String? businessId, String? category}) =>
      Stream.value([]);
}

User _professional(String id, String name) => User(
      id: id,
      name: name,
      email: '$id@test.com',
      phone: '555',
      role: 'staff',
      category: 'Massage',
    );

Future<void> _pumpBookingPage(
  WidgetTester tester, {
  required List<User> professionals,
  bool failServiceStream = false,
  List<Service> services = const [],
  Business? business,
}) async {
  final auth = AuthProvider(userRepository: FakeUserRepository());
  auth.currentUser = User(
    id: 'cust-1',
    name: 'Customer',
    email: 'cust@test.com',
    phone: '555',
    role: 'customer',
  );
  final appointmentProvider = AppointmentProvider(
    bookingRepository: FakeBookingRepository(),
    userRepository: FakeUserRepository(),
    notificationRepository: FakeNotificationRepository(),
    businessRepository: FakeBusinessRepository(),
  );
  appointmentProvider.currentUser = auth.currentUser;

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<AppointmentProvider>.value(
            value: appointmentProvider),
        ChangeNotifierProvider<ServiceProvider>(
            create: (_) => ServiceProvider(
                repository: FakeServiceRepository(
                    failStream: failServiceStream, services: services))),
        ChangeNotifierProvider<BusinessProvider>.value(
            value: BusinessProvider()..setBusiness(business)),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Provider<StaffDirectoryRepository>.value(
            value: FakeStaffDirectoryRepository(professionals),
            child: const BookingPage(category: 'Massage'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('BookingPage staff picker', () {
    testWidgets('uses staff labels, not customer labels', (tester) async {
      await _pumpBookingPage(tester, professionals: [
        _professional('p1', 'Alice'),
        _professional('p2', 'Bob'),
      ]);

      expect(find.text('Select Staff Member'), findsOneWidget);
      expect(find.text('Select Customer'), findsNothing);

      await tester.tap(find.byType(DropdownButtonFormField<User>));
      await tester.pumpAndSettle();
      expect(find.text('Any available'), findsWidgets);
    });

    testWidgets('Any available auto-assigns the first professional',
        (tester) async {
      await _pumpBookingPage(tester, professionals: [
        _professional('p1', 'Alice'),
        _professional('p2', 'Bob'),
      ]);

      await tester.tap(find.byType(DropdownButtonFormField<User>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Any available').last);
      await tester.pumpAndSettle();

      // Dropdown now shows Alice instead of the hint; info card is gone.
      expect(find.text('Any available'), findsNothing);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(
          find.text(
              'Select a staff member to see their offered services, or choose from the business-wide services below.'),
          findsNothing);
    });

    testWidgets('confirm explains the missing step', (tester) async {
      await _pumpBookingPage(tester, professionals: [
        _professional('p1', 'Alice'),
        _professional('p2', 'Bob'),
      ]);

      // Nothing picked yet: the reason names the staff step.
      expect(find.text('Select a staff member to continue'), findsOneWidget);
    });

    testWidgets('genuine empty offers browsing other categories',
        (tester) async {
      await _pumpBookingPage(tester, professionals: []);

      expect(find.text('Browse other categories'), findsOneWidget);
    });

    testWidgets('service stream errors surface with retry', (tester) async {
      await _pumpBookingPage(
        tester,
        professionals: [_professional('p1', 'Alice')],
        failServiceStream: true,
      );

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('deposit notice shows when the business requires one',
        (tester) async {
      await _pumpBookingPage(
        tester,
        professionals: [_professional('p1', 'Alice')],
        business: Business(
          id: 'biz-1',
          name: 'Biz',
          settings: BusinessSettings(
              depositRequired: true, depositPercent: 10.0),
        ),
        services: [Service(name: 'Massage', price: 100.0)],
      );

      await tester.tap(find.text('Massage').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('10% deposit'), findsOneWidget);
    });

    testWidgets('fully booked day says so instead of empty slots',
        (tester) async {
      final pro = User(
        id: 'p1',
        name: 'Alice',
        email: 'p1@test.com',
        phone: '555',
        role: 'staff',
        category: 'Massage',
        workStartTime: '09:00',
        workEndTime: '09:00',
      );
      await _pumpBookingPage(tester, professionals: [pro]);

      // Single pro is auto-selected; pick a date via the date tile.
      await tester.tap(find.text('Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Fully booked for this day — pick another date'),
          findsOneWidget);
    });
  });
}
