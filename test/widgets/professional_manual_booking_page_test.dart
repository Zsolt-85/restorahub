import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/pages/professional_manual_booking_page.dart';
import 'package:restorahub/providers/appointment_provider.dart';
import 'package:restorahub/providers/auth_provider.dart';
import 'package:restorahub/repositories/booking_repository.dart';
import 'package:restorahub/repositories/user_repository.dart';

class FakeBookingRepository implements BookingRepository {
  final List<Appointment> appointments = [];

  @override
  Future<List<Appointment>> getAppointmentsForCustomer(String customerId, {String? businessId}) async =>
      appointments.where((a) => a.customerId == customerId).toList();

  @override
  Future<List<Appointment>> getAppointmentsForProfessional(String professionalId, {String? businessId, String? professionalEmail}) async =>
      appointments.where((a) => a.professionalId == professionalId).toList();

  @override
  Future<List<Appointment>> getAppointmentsForBusiness(String businessId, {DateTime? startDate, DateTime? endDate}) async =>
      appointments.where((a) => a.customerId != null || a.professionalId != null).toList();

  @override
  Future<bool> checkProfessionalAvailability({required String professionalId, required DateTime dateTime, required int slotDurationMinutes, int bufferTimeMinutes = 0, String? businessId, String? professionalEmail}) async =>
      true;

  @override
  Future<void> createAppointmentAtomic(Appointment appointment) async {
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
  Stream<List<Appointment>> watchAppointmentsForCustomer(String customerId, {String? businessId}) =>
      Stream.value(appointments.where((a) => a.customerId == customerId).toList());

  @override
  Stream<List<Appointment>> watchAppointmentsForProfessional(String professionalId, {String? businessId, String? professionalEmail}) =>
      Stream.value(appointments.where((a) => a.professionalId == professionalId).toList());

  @override
  Stream<List<Appointment>> watchAppointmentsForBusiness(String businessId, {DateTime? startDate, DateTime? endDate}) =>
      Stream.value(appointments.where((a) => a.customerId != null || a.professionalId != null).toList());

  @override
  Stream<Appointment?> watchAppointment(String id) =>
      Stream.value(appointments.where((a) => a.id == id).cast<Appointment?>().firstOrNull);

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
  final List<User> users = [];

  @override
  Future<User?> getUserById(String id) async =>
      users.where((u) => u.id == id).cast<User?>().firstOrNull;

  @override
  Future<bool> isEmailTaken(String email, {String? excludeUserId}) async =>
      users.any((u) => u.email == email && u.id != excludeUserId);

  @override
  Future<int> insertUser(User user) async {
    users.add(user);
    return 1;
  }

  @override
  Future<int> updateUser(User user) async {
    final idx = users.indexWhere((u) => u.id == user.id);
    if (idx != -1) users[idx] = user;
    return 1;
  }

  @override
  Future<void> syncUserInAppointments(User user) async {}

  @override
  Future<List<User>> getProfessionalsBySpecialty(String specialty) async =>
      users.where((u) => u.role == 'professional' && u.specialty == specialty).toList();

  @override
  Future<List<User>> getProfessionals({String? businessId}) async =>
      users
          .where((u) => u.role == 'professional')
          .where((u) => businessId == null || u.businessId == businessId)
          .toList();

  @override
  Stream<List<User>> watchProfessionals({String? businessId}) =>
      Stream.value(
        users
            .where((u) => u.role == 'professional')
            .where((u) => businessId == null || u.businessId == businessId)
            .toList(),
      );

  @override
  Future<List<User>> getCustomers() async =>
      users.where((u) => u.role == 'customer').toList();
}

void main() {
  group('ProfessionalManualBookingPage', () {
    late FakeBookingRepository bookingRepo;
    late FakeUserRepository userRepo;
    late AppointmentProvider appointmentProvider;
    late AuthProvider authProvider;

    setUp(() {
      bookingRepo = FakeBookingRepository();
      userRepo = FakeUserRepository();
      appointmentProvider = AppointmentProvider(
        bookingRepository: bookingRepo,
        userRepository: userRepo,
      );
      authProvider = AuthProvider(userRepository: userRepo);
       authProvider.currentUser = User(
        id: 'prof-1',
        name: 'Prof. Test',
        email: 'prof@example.com',
        phone: '555-0200',
        role: 'professional',
        specialty: 'Massage',
      );
    });

    testWidgets('renders form fields', (tester) async {
      userRepo.users.addAll([
        User(
          id: 'prof-1',
          name: 'Prof. Test',
          email: 'prof@example.com',
          phone: '555-0200',
          role: 'professional',
          specialty: 'Massage',
        ),
        User(
          id: 'cust-1',
          name: 'Customer A',
          email: 'cust@example.com',
          phone: '555-0100',
          role: 'customer',
        ),
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<AppointmentProvider>.value(
              value: appointmentProvider,
            ),
            Provider<UserRepository>.value(value: userRepo),
          ],
          child: const MaterialApp(
            home: ProfessionalManualBookingPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Select Customer'), findsOneWidget);
      expect(find.text('Select Service'), findsOneWidget);
      expect(find.text('Select Date'), findsOneWidget);
      expect(find.text('Available slots'), findsNothing);
      expect(find.text('Create Booking'), findsOneWidget);
    });

    testWidgets('opens customer picker and shows customers', (tester) async {
      userRepo.users.addAll([
        User(
          id: 'prof-1',
          name: 'Prof. Test',
          email: 'prof@example.com',
          phone: '555-0200',
          role: 'professional',
          specialty: 'Massage',
        ),
        User(
          id: 'cust-1',
          name: 'Customer A',
          email: 'cust@example.com',
          phone: '555-0100',
          role: 'customer',
        ),
        User(
          id: 'cust-2',
          name: 'Customer B',
          email: 'cust2@example.com',
          phone: '555-0101',
          role: 'customer',
        ),
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<AppointmentProvider>.value(
              value: appointmentProvider,
            ),
            Provider<UserRepository>.value(value: userRepo),
          ],
          child: const MaterialApp(
            home: ProfessionalManualBookingPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final customerField = find.byType(TextFormField).first;
      await tester.tap(customerField);
      await tester.pumpAndSettle();

      expect(find.text('Customer A'), findsOneWidget);
      expect(find.text('Customer B'), findsOneWidget);
    });

    testWidgets('search filters customer list by phone number', (tester) async {
      userRepo.users.addAll([
        User(
          id: 'prof-1',
          name: 'Prof. Test',
          email: 'prof@example.com',
          phone: '555-0200',
          role: 'professional',
          specialty: 'Massage',
        ),
        User(
          id: 'cust-1',
          name: 'Customer A',
          email: 'cust@example.com',
          phone: '555-0100',
          role: 'customer',
        ),
        User(
          id: 'cust-2',
          name: 'Customer B',
          email: 'cust2@example.com',
          phone: '555-0999',
          role: 'customer',
        ),
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<AppointmentProvider>.value(
              value: appointmentProvider,
            ),
            Provider<UserRepository>.value(value: userRepo),
          ],
          child: const MaterialApp(
            home: ProfessionalManualBookingPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final customerField = find.byType(TextFormField).first;
      await tester.tap(customerField);
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('search_customers'));
      expect(searchField, findsOneWidget);
      await tester.tap(searchField);
      await tester.pump();
      tester.testTextInput.enterText('555-0999');
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Customer A'), findsNothing);
      expect(find.text('Customer B'), findsOneWidget);
    });

    testWidgets('shows preview card and phone after selecting a customer', (tester) async {
      userRepo.users.addAll([
        User(
          id: 'prof-1',
          name: 'Prof. Test',
          email: 'prof@example.com',
          phone: '555-0200',
          role: 'professional',
          specialty: 'Massage',
        ),
        User(
          id: 'cust-1',
          name: 'Customer A',
          email: 'cust@example.com',
          phone: '555-0100',
          role: 'customer',
        ),
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<AppointmentProvider>.value(
              value: appointmentProvider,
            ),
            Provider<UserRepository>.value(value: userRepo),
          ],
          child: const MaterialApp(
            home: ProfessionalManualBookingPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('555-0100'), findsNothing);

      final customerField = find.byType(TextFormField).first;
      await tester.tap(customerField);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Customer A'));
      await tester.pumpAndSettle();

      expect(find.text('555-0100'), findsOneWidget);
      expect(find.text('cust@example.com'), findsOneWidget);
    });

    testWidgets('clear button removes selected customer', (tester) async {
      userRepo.users.addAll([
        User(
          id: 'prof-1',
          name: 'Prof. Test',
          email: 'prof@example.com',
          phone: '555-0200',
          role: 'professional',
          specialty: 'Massage',
        ),
        User(
          id: 'cust-1',
          name: 'Customer A',
          email: 'cust@example.com',
          phone: '555-0100',
          role: 'customer',
        ),
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<AppointmentProvider>.value(
              value: appointmentProvider,
            ),
            Provider<UserRepository>.value(value: userRepo),
          ],
          child: const MaterialApp(
            home: ProfessionalManualBookingPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final customerField = find.byType(TextFormField).first;
      await tester.tap(customerField);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Customer A'));
      await tester.pumpAndSettle();

      expect(find.text('555-0100'), findsOneWidget);

      final clearButton = find.descendant(
        of: find.byType(Card),
        matching: find.byIcon(Icons.clear),
      );
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('555-0100'), findsNothing);
    });

    testWidgets('does not create appointment when fields are empty', (tester) async {
      userRepo.users.addAll([
        User(
          id: 'prof-1',
          name: 'Prof. Test',
          email: 'prof@example.com',
          phone: '555-0200',
          role: 'professional',
          specialty: 'Massage',
        ),
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<AppointmentProvider>.value(
              value: appointmentProvider,
            ),
            Provider<UserRepository>.value(value: userRepo),
          ],
          child: const MaterialApp(
            home: ProfessionalManualBookingPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Booking'));
      await tester.pumpAndSettle();

      expect(bookingRepo.appointments, isEmpty);
    });

    testWidgets('creates appointment with correct customer and professional IDs', (tester) async {
      final appt = Appointment(
        service: 'Massage',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        status: AppointmentStatus.confirmed,
        customerId: 'cust-1',
        customerName: 'Customer A',
        customerPhone: '555-0100',
        customerEmail: 'cust@example.com',
        professionalId: 'prof-1',
        professionalName: 'Prof. Test',
        professionalPhone: '555-0200',
        professionalEmail: 'prof@example.com',
      );

      await appointmentProvider.addAppointment(appt);

      expect(bookingRepo.appointments.length, 1);
      expect(bookingRepo.appointments.first.service, 'Massage');
      expect(bookingRepo.appointments.first.customerId, 'cust-1');
      expect(bookingRepo.appointments.first.professionalId, 'prof-1');
      expect(bookingRepo.appointments.first.status, AppointmentStatus.confirmed);
    });
  });
}
