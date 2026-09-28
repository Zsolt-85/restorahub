import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restorahub/models/appointment.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/models/notification.dart';
import 'package:restorahub/models/user.dart';
import 'package:restorahub/pages/past_appointments_page.dart';
import 'package:restorahub/providers/appointment_provider.dart';
import 'package:restorahub/providers/auth_provider.dart';
import 'package:restorahub/repositories/booking_repository.dart';
import 'package:restorahub/repositories/business_repository.dart';
import 'package:restorahub/repositories/notification_repository.dart';
import 'package:restorahub/repositories/user_repository.dart';

class _FakeBookingRepository implements BookingRepository {
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

class _FakeUserRepository implements UserRepository {
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

class _FakeNotificationRepository implements NotificationRepository {
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

class _FakeBusinessRepository implements BusinessRepository {
  @override
  Future<Business?> getBusinessById(String businessId) async => null;

  @override
  Future<void> updateBusiness(Business business) async {}
}

void main() {
  group('PastAppointmentsPage empty state', () {
    testWidgets('uses warm salon copy', (tester) async {
      final auth = AuthProvider(userRepository: _FakeUserRepository());
      auth.currentUser = User(
        id: 'cust-1',
        name: 'Customer',
        email: 'cust@test.com',
        phone: '555',
        role: 'customer',
      );
      final appointmentProvider = AppointmentProvider(
        bookingRepository: _FakeBookingRepository(),
        userRepository: _FakeUserRepository(),
        notificationRepository: _FakeNotificationRepository(),
        businessRepository: _FakeBusinessRepository(),
      );
      appointmentProvider.currentUser = auth.currentUser;
      await appointmentProvider.loadAppointments();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<AppointmentProvider>.value(
              value: appointmentProvider,
            ),
          ],
          child: const MaterialApp(home: PastAppointmentsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No past appointments'), findsOneWidget);
      expect(find.text('Your completed bookings will show up here.'),
          findsOneWidget);
    });
  });
}
